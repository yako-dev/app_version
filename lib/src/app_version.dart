import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:package_info/package_info.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http show get;

import 'app_version_status.dart';

part 'app_version_info.dart';

class AppVersion {
  final String androidPackageName;
  final String iosPackageName;
  final Version minVersion;

  AppVersionInfo _info;

  AppVersionInfo get info => _info;

  AppVersion({
    this.minVersion,
    this.androidPackageName,
    this.iosPackageName,
  });

  Future<AppVersionInfo> calculateInfo() async {
    await _calculateVersionInfo();
    if (_info.storeVersion != null) {
      if (_info.localVersion.compareTo(_info.storeVersion) >= 0) {
        _info = _info._copyWith(status: AppVersionStatus.latest);
      } else {
        if (minVersion == null) {
          _info = _info._copyWith(status: AppVersionStatus.canUpdate);
        } else {
          if (_info.localVersion.compareTo(minVersion) < 0) {
            _info = _info._copyWith(status: AppVersionStatus.shouldUpdate);
          }
          _info = _info._copyWith(status: AppVersionStatus.canUpdate);
        }
      }
    }
    return _info;
  }

  Future<void> _calculateVersionInfo() async {
    String packageName;
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _info = AppVersionInfo(localVersion: Version.parse(packageInfo.version));

      if (Platform.isAndroid) {
        packageName = androidPackageName ?? packageInfo.packageName;
        await _getAndroidStoreVersion(packageName);
      } else if (Platform.isIOS) {
        packageName = iosPackageName ?? packageInfo.packageName;
        await _getIosStoreVersion(packageName);
      } else {
        print('This target platform is not yet supported by this package.');
      }
    } catch (e) {
      print(_getErrorText(packageName));
      _resetInfo();
    }
  }

  Future<void> _getIosStoreVersion(String packageName) async {
    final url = 'https://itunes.apple.com/lookup?bundleId=$packageName';
    final response = await http.get(url);
    if (response.statusCode != 200) {
      print(_getErrorText(packageName));
      _resetInfo();
      return;
    }
    final responseJson = jsonDecode(response.body);
    if (responseJson['results']?.isEmpty ?? true) {
      print(_getErrorText(packageName));
      return;
    }

    _info = _info._copyWith(
      storeVersion: Version.parse(responseJson['results'][0]['version']),
      appStoreLink: responseJson['results'][0]['trackViewUrl'],
    );
  }

  Future<void> _getAndroidStoreVersion(String packageName) async {
    final url = 'https://play.google.com/store/apps/details?id=$packageName';
    final response = await http.get(url);
    if (response.statusCode != 200) {
      print(_getErrorText(packageName));
      _resetInfo();
      return;
    }
    final Document document = parse(response.body);
    final List<Element> elements = document.getElementsByClassName('hAyfc');
    final versionElement = elements.firstWhere(
      (elm) => elm.querySelector('.BgcNfc').text == 'Current Version',
    );

    _info = _info._copyWith(
      storeVersion: Version.parse(versionElement.querySelector('.htlgb').text),
      appStoreLink: url,
    );
  }

  String _getErrorText(String packageName) {
    String storeName;
    if (Platform.isIOS) {
      storeName = 'App Store';
    } else {
      storeName = 'Google Play Store';
    }
    return 'Could not find an app with provided package name in the $storeName';
  }

  void _resetInfo() => _info = _info._onlyLocal;
}
