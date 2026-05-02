import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../logger/app_logger.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const _tag = 'PermissionService';

  Future<void> init() async {
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
  }

  Future<void> _requestAndroidPermissions() async {
    // Android 13+ requires explicit notification permission for foreground services
    if (await Permission.notification.isDenied) {
      AppLogger.i(_tag, 'Requesting notification permission (Android 13+)');
      final status = await Permission.notification.request();
      AppLogger.i(_tag, 'Notification status: $status');
    }
  }

  Future<void> _requestIOSPermissions() async {
    if (await Permission.notification.isDenied) {
      AppLogger.i(_tag, 'Requesting notification permission (iOS)');
      final status = await Permission.notification.request();
      AppLogger.i(_tag, 'Notification status: $status');
    }
  }

  /// Use for downloading if user wants to save to generic downloads folder later.
  /// Currently using app-specific storage which doesn't need this.
  /// For external directories on Android 11+ (API 30+), users may need
  /// MANAGE_EXTERNAL_STORAGE or SAF (handled by file_picker).
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), users may need MANAGE_EXTERNAL_STORAGE
      if (await Permission.manageExternalStorage.isDenied) {
        AppLogger.i(_tag, 'Requesting Manage External Storage (Android 11+)');
        await Permission.manageExternalStorage.request();
      }
      
      try {
        await Permission.storage.request();
      } catch (e) {
        AppLogger.w(_tag, 'Permission request failed: $e');
      }
    }
    return true;
  }
}
