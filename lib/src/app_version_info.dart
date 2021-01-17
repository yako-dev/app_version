part of 'app_version.dart';

class AppVersionInfo {
  final Version localVersion;

  final Version storeVersion;

  final String appStoreLink;

  final AppVersionStatus status;

  AppVersionInfo({
    this.localVersion,
    this.storeVersion,
    this.appStoreLink,
    this.status,
  });

  AppVersionInfo _copyWith({
    Version localVersion,
    Version storeVersion,
    String appStoreLink,
    AppVersionStatus status,
  }) {
    return AppVersionInfo(
      localVersion: localVersion ?? this.localVersion,
      storeVersion: storeVersion ?? this.storeVersion,
      appStoreLink: appStoreLink ?? this.appStoreLink,
      status: status ?? this.status,
    );
  }

  AppVersionInfo get _onlyLocal => AppVersionInfo(localVersion: localVersion);
}
