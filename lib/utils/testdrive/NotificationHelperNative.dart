// Create this new file

import 'dart:io';
import 'package:flutter/services.dart';

class NotificationHelper {
  static const platform = MethodChannel('com.smartassist/notifications');

  /// Force clear all notifications using native Android API
  static Future<bool> clearAllNotifications() async {
    if (!Platform.isAndroid) {
      print('⚠️ clearAllNotifications only works on Android');
      return false;
    }

    try {
      final bool result = await platform.invokeMethod('clearAllNotifications');
      print('✅ Native notification clear: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to clear notifications natively: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error clearing notifications: $e');
      return false;
    }
  }

  /// Cancel a specific notification by ID
  static Future<bool> cancelNotification(int notificationId) async {
    if (!Platform.isAndroid) {
      print('⚠️ cancelNotification only works on Android');
      return false;
    }

    try {
      final bool result = await platform.invokeMethod('cancelNotification', {
        'id': notificationId,
      });
      print('✅ Cancelled notification $notificationId: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to cancel notification $notificationId: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error cancelling notification: $e');
      return false;
    }
  }

  /// Cancel multiple notification IDs
  static Future<void> cancelMultipleNotifications(
    List<int> notificationIds,
  ) async {
    for (final id in notificationIds) {
      await cancelNotification(id);
      // Small delay between cancellations
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
