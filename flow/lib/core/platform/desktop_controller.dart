import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../logger/app_logger.dart';

class DesktopController {
  DesktopController._();
  static final DesktopController instance = DesktopController._();

  static const _tag = 'DesktopController';
  static const Size _miniPlayerSize = Size(350, 180);
  static const Size _normalSize = Size(1000, 800);

  final ValueNotifier<bool> isMiniNotifier = ValueNotifier(false);
  bool get isMini => isMiniNotifier.value;

  Future<void> init() async {
    if (kIsWeb || !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    try {
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: _normalSize,
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      AppLogger.e(_tag, 'Failed to init window manager', e);
    }
  }

  Future<void> toggleMiniPlayer() async {
    isMiniNotifier.value = !isMiniNotifier.value;
    
    if (isMiniNotifier.value) {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(_miniPlayerSize);
      await windowManager.setResizable(false);
      // Optional: set to bottom right of screen
    } else {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSize(_normalSize);
      await windowManager.setResizable(true);
      await windowManager.center();
    }
  }
}

