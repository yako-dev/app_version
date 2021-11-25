import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http show get;
import 'package:package_info/package_info.dart';
import 'package:version/version.dart';

import 'app_version_status.dart';

part 'app_version_info.dart';

class AppVersion {
  final String? androidPackageName;
  final String? iosPackageName;
  final Version? minVersion;

  AppVersionInfo? _info;

  AppVersionInfo? get info => _info;

  AppVersion({
    this.minVersion,
    this.androidPackageName,
    this.iosPackageName,
  });

  Future<AppVersionInfo?> calculateInfo() async {
    await _calculateVersionInfo();
    if (_info!.storeVersion != null
        ? _info!.localVersion!.compareTo(_info!.storeVersion) >= 0
        : true) {
      _info = _info!._copyWith(status: AppVersionStatus.latest);
    } else {
      if (minVersion == null) {
        _info = _info!._copyWith(status: AppVersionStatus.canUpdate);
      } else {
        if (_info!.localVersion!.compareTo(minVersion) < 0) {
          _info = _info!._copyWith(status: AppVersionStatus.haveToUpdate);
        } else {
          _info = _info!._copyWith(status: AppVersionStatus.canUpdate);
        }
      }
    }
    return _info;
  }

  bool get _isAndroid => Platform.isAndroid;

  Future<void> _calculateVersionInfo() async {
    String? packageName;
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _info = AppVersionInfo(localVersion: Version.parse(packageInfo.version));

      if (_isAndroid) {
        packageName = androidPackageName ?? packageInfo.packageName;
      } else if (Platform.isIOS) {
        packageName = iosPackageName ?? packageInfo.packageName;
      }
      await _getStoreVersion(packageName!);
    } catch (e) {
      print(_getErrorText(packageName));
      _resetInfo();
    }
  }

  Future<void> _getStoreVersion(String packageName) async {
    try {
      final url = _isAndroid
          ? 'https://play.google.com/store/apps/details?id=$packageName'
          : 'https://itunes.apple.com/lookup?bundleId=$packageName';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 4),
          );
      if (response.statusCode != 200) {
        print(_getErrorText(packageName));
        _resetInfo();
        return;
      }
      if (_isAndroid) {
        final Document document = parse(response.body);
        final List<Element> elements = document.getElementsByClassName('hAyfc');
        final versionElement = elements.firstWhere(
          (elm) => elm.querySelector('.BgcNfc')!.text == 'Current Version',
        );

        _info = _info!._copyWith(
          storeVersion:
              Version.parse(versionElement.querySelector('.htlgb')!.text),
          appStoreLink: url,
        );
      } else {
        final responseJson = jsonDecode(response.body);
        if (responseJson['results']?.isEmpty ?? true) {
          print(_getErrorText(packageName));
          return;
        }

        _info = _info!._copyWith(
          storeVersion: Version.parse(responseJson['results'][0]['version']),
          appStoreLink: responseJson['results'][0]['trackViewUrl'],
        );
      }
    } catch (e) {
      print(
        'Failed to lookup an ${_isAndroid ? 'Android' : 'iOS'} store app '
        'version: ${e.toString()}',
      );
    }
  }

  String _getErrorText(String? packageName) {
    late final String storeName;
    if (_isAndroid) {
      storeName = 'Google Play Store';
    } else {
      storeName = 'App Store';
    }
    return 'Could not find an app with provided package name in the $storeName';
  }

  void _resetInfo() => _info = _info!._onlyLocal;
}
