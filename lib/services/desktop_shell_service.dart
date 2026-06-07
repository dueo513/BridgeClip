import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_tray_listener.dart';
import 'localization.dart';
import 'platform_service.dart';

class DesktopShellService {
  static Future<void> setup() async {
    if (!PlatformService.isDesktop) return;

    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(800, 600),
        center: true,
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.normal,
        title: 'BridgeClip',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      if (Platform.isWindows) {
        launchAtStartup.setup(
          appName: 'BridgeClip',
          appPath: Platform.resolvedExecutable,
        );
        await launchAtStartup.enable();
        await trayManager.setIcon(PlatformService.windowsTrayIconPath());
      }

      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(
              key: 'show_window',
              label: LocalizationService.get('tray_show'),
            ),
            MenuItem(
              key: 'auto_start',
              label: LocalizationService.get('tray_ready'),
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'exit_app',
              label: LocalizationService.get('tray_exit'),
            ),
          ],
        ),
      );
      trayManager.addListener(desktopTrayListener);
    } catch (e) {
      debugPrint('Desktop shell setup failed: $e');
    }
  }
}
