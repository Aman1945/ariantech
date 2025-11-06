// 📁 lib/utils/notification_helper.dart (or wherever your existing one is)
// REPLACE your entire existing NotificationHelper with this merged version

import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ✅ ADDED: Platform channel for native Android notification clearing
  static const platform = MethodChannel('com.smartassist/notifications');

  static Future<void> setupNotificationChannels() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.actionId}');
      },
    );

    // Request notification permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Create HIGH PRIORITY notification channel for background service
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'testdrive_channel',
      'Test Drive Tracking',
      description: 'Live tracking for test drive with distance updates',
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: true,
      enableLights: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print('✅ High priority notification channel created');
  }

  static Future<void> requestNotificationPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      print('📱 Notification permission granted: $granted');

      // Also request exact alarm permission if needed
      final bool? exactAlarmGranted = await androidImplementation
          .requestExactAlarmsPermission();
      print('⏰ Exact alarm permission granted: $exactAlarmGranted');
    }
  }

  // Create a persistent, ongoing notification like Google Maps
  static Future<void> showTestDriveNotification({
    required double distance,
    required int duration,
  }) async {
    String distanceText = _formatDistance(distance);
    String durationText = _formatDuration(duration);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'testdrive_channel',
          'Test Drive Tracking',
          channelDescription: 'Live tracking for test drive',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true, // Makes it persistent like Google Maps
          autoCancel: false, // Prevents dismissal by swipe
          showWhen: false, // Hide timestamp
          usesChronometer: false,
          playSound: false,
          enableVibration: false,
          enableLights: false,
          category: AndroidNotificationCategory.navigation,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2196F3), // Blue color
          styleInformation: BigTextStyleInformation(
            '$distanceText • $durationText\nTap to return to SmartAssist',
            htmlFormatBigText: false,
            contentTitle: 'Test Drive Active',
            htmlFormatContentTitle: false,
            summaryText: 'SmartAssist',
            htmlFormatSummaryText: false,
          ),
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      888, // Same ID as service notification
      'Test Drive Active',
      '$distanceText • $durationText',
      notificationDetails,
    );
  }

  // Format distance to show appropriate precision
  static String _formatDistance(double distance) {
    if (distance < 0.01) {
      return '0.0 km';
    } else if (distance < 0.1) {
      return '${(distance * 1000).round()} m';
    } else if (distance < 1.0) {
      return '${distance.toStringAsFixed(2)} km';
    } else if (distance < 10.0) {
      return '${distance.toStringAsFixed(1)} km';
    } else {
      return '${distance.round()} km';
    }
  }

  // Format duration in a readable way
  static String _formatDuration(int minutes) {
    if (minutes < 1) {
      return '0m';
    } else if (minutes < 60) {
      return '${minutes}m';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  // ✅ EXISTING: Cancel single notification using Flutter plugin
  static Future<void> cancelNotification() async {
    await _notifications.cancel(888);
    print('✅ Notification 888 cancelled via Flutter');
  }

  // ✅ NEW: Cancel all notifications using Flutter plugin
  static Future<void> cancelAllFlutterNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ All Flutter notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling Flutter notifications: $e');
    }
  }

  // ✅ NEW: Force clear all notifications using native Android API
  static Future<bool> clearAllNotifications() async {
    if (!Platform.isAndroid) {
      print('⚠️ clearAllNotifications only works on Android');
      return false;
    }

    try {
      // First try Flutter plugin
      await cancelAllFlutterNotifications();

      // Then force clear via native Android
      final bool result = await platform.invokeMethod('clearAllNotifications');
      print('✅ Native Android notification clear: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to clear notifications natively: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error clearing notifications: $e');
      return false;
    }
  }

  // ✅ NEW: Cancel specific notification by ID using native Android
  static Future<bool> cancelNotificationById(int notificationId) async {
    if (!Platform.isAndroid) {
      print('⚠️ cancelNotificationById only works on Android');
      return false;
    }

    try {
      // Cancel via Flutter plugin first
      await _notifications.cancel(notificationId);

      // Then force cancel via native Android
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

  // ✅ NEW: Comprehensive cleanup - use this in your cleanup code
  static Future<void> clearAllTestDriveNotifications() async {
    try {
      print('🧹 Clearing all test drive notifications...');

      // 1. Cancel specific IDs via Flutter
      await _notifications.cancel(1);
      await _notifications.cancel(888);
      await _notifications.cancel(999);

      // 2. Cancel all via Flutter
      await _notifications.cancelAll();

      // 3. Force clear via native Android (most reliable)
      if (Platform.isAndroid) {
        await clearAllNotifications();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ All test drive notifications cleared');
    } catch (e) {
      print('❌ Error clearing test drive notifications: $e');
    }
  }
}

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationHelper {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> setupNotificationChannels() async {
//     // Request notification permissions for Android 13+
//     await _notifications
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.requestNotificationsPermission();

//     // Create notification channel for background service
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'testdrive_channel', // Must match the ID in BackgroundService
//       'Test Drive Tracking',
//       description: 'Notifications for test drive tracking service',
//       importance: Importance.high,
//       playSound: false,
//       enableVibration: false,
//       showBadge: true,
//     );

//     await _notifications
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);

//     print('✅ Notification channel created: testdrive_channel');
//   }

//   static Future<void> requestNotificationPermissions() async {
//     final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//         _notifications
//             .resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin
//             >();

//     if (androidImplementation != null) {
//       final bool? granted = await androidImplementation
//           .requestNotificationsPermission();
//       print('📱 Notification permission granted: $granted');
//     }
//   }
// }
