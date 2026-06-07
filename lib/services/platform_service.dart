import 'dart:io' show File, Platform;

import 'device_identity_service.dart';

class PlatformService {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static String windowsTrayIconPath() {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    return '$executableDir\\data\\flutter_assets\\assets\\app_icon.ico';
  }

  static String defaultDeviceName() {
    return DeviceIdentityService.defaultDeviceName();
  }

  static String platformName() {
    return DeviceIdentityService.platformName();
  }
}
