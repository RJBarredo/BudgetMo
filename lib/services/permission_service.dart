import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper so features can ask for OS permission at the moment the
/// user turns them on — the way most apps do. No-ops on web.
class PermissionService {
  static Future<bool> requestNotifications() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isNotificationsPermanentlyDenied() async {
    if (kIsWeb) return false;
    try {
      return (await Permission.notification.status).isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Photos/gallery access. Android 13+ uses the photos permission;
  /// older Android falls back to storage.
  static Future<bool> requestPhotos() async {
    if (kIsWeb) return true;
    try {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestCamera() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    if (kIsWeb) return;
    try {
      await openAppSettings();
    } catch (_) {}
  }
}
