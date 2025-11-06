import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
    debugPrint('✅ Local notifications initialized');
  }

  Future<void> showDriveTrackingNotification({
    bool isSilentUpdate = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'testdrive_tracking',
      'Test Drive Tracking',
      channelDescription: 'Active test drive tracking notifications',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
      playSound: !isSilentUpdate,
      enableVibration: !isSilentUpdate,
      styleInformation: BigTextStyleInformation(
        'Test Drive is Ongoing in the background',
        contentTitle: 'Test Drive Active',
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: !isSilentUpdate,
      presentBadge: false,
      presentSound: !isSilentUpdate,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Test Drive Active',
      'Test Drive is Ongoing in the background',
      details,
      payload: 'testdrive_tracking',
    );
  }

  // ✅ IMPROVED: Cancel with multiple strategies
  Future<void> cancelDriveNotification() async {
    try {
      debugPrint('🔔 Cancelling drive notifications...');

      // Cancel specific notification IDs
      await _notifications.cancel(1); // Your tracking notification
      await _notifications.cancel(888); // Background service notification
      await _notifications.cancel(999); // Any other notification

      // Small delay to ensure cancellation is processed
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('✅ Drive notification cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling drive notification: $e');
    }
  }

  // ✅ NEW: Force clear all notifications
  Future<void> cancelAll() async {
    try {
      debugPrint('🔔 Cancelling ALL notifications...');
      await _notifications.cancelAll();
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  // ✅ NEW: Complete cleanup method
  Future<void> clearAllTestDriveNotifications() async {
    try {
      debugPrint('🧹 Clearing all test drive notifications...');

      // Cancel all known notification IDs
      final notificationIds = [1, 888, 999];
      for (final id in notificationIds) {
        await _notifications.cancel(id);
      }

      // Also cancel all as fallback
      await _notifications.cancelAll();

      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('✅ All test drive notifications cleared');
    } catch (e) {
      debugPrint('❌ Error clearing test drive notifications: $e');
    }
  }
}

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/foundation.dart';
// import 'dart:io';

// class LocalNotificationService {
//   static final LocalNotificationService _instance =
//       LocalNotificationService._internal();
//   factory LocalNotificationService() => _instance;
//   LocalNotificationService._internal();

//   final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();
//   bool _initialized = false;

//   Future<void> initialize() async {
//     if (_initialized) return;

//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );

//     final iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       // onDidReceiveLocalNotification: (id, title, body, payload) async {
//       //   // Handle iOS foreground notification
//       //   debugPrint('iOS notification received: $title');
//       // },
//     );

//     final settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _notifications.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (details) {
//         debugPrint('Notification tapped: ${details.payload}');
//       },
//     );

//     // Request permissions
//     if (Platform.isAndroid) {
//       await _notifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.requestNotificationsPermission();
//     } else if (Platform.isIOS) {
//       await _notifications
//           .resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin
//           >()
//           ?.requestPermissions(alert: true, badge: true, sound: true);
//     }

//     _initialized = true;
//     debugPrint('✅ Local notifications initialized');
//   }

//   // Future<void> showDriveTrackingNotification({
//   //   // required double distance,
//   //   // required int duration,
//   //   bool isSilentUpdate = false, // 🔑
//   // }) async {
//   //   final androidDetails = AndroidNotificationDetails(
//   //     'testdrive_tracking',
//   //     'Test Drive Tracking',
//   //     channelDescription: 'Active test drive tracking notifications',
//   //     importance: Importance.high,
//   //     priority: Priority.high,
//   //     ongoing: true,
//   //     autoCancel: false,
//   //     showWhen: false,
//   //     playSound: !isSilentUpdate, // sound only first time
//   //     enableVibration: !isSilentUpdate,
//   //     styleInformation: BigTextStyleInformation(
//   //       // 🔑 like Uber style
//   //       // 'Distance: ${distance.toStringAsFixed(2)} km | Duration: $duration mins',
//   //       'Distance: Test Drive is Ongoing in the background' ,
//   //       contentTitle: 'Test Drive Active',
//   //     ),
//   //   );

//   //   final iosDetails = DarwinNotificationDetails(
//   //     presentAlert: !isSilentUpdate,
//   //     presentBadge: false,
//   //     presentSound: !isSilentUpdate,
//   //   );

//   //   final details = NotificationDetails(
//   //     android: androidDetails,
//   //     iOS: iosDetails,
//   //   );

//   //   await _notifications.show(
//   //     1,
//   //     'Test Drive Active',
//   //             'Distance: Test Drive is Ongoing in the background',
//   //     // 'Distance: ${distance.toStringAsFixed(2)} km | Duration: $duration mins',
//   //     details,
//   //     payload: 'testdrive_tracking',
//   //   );
//   // }

//   Future<void> showDriveTrackingNotification({
//     bool isSilentUpdate = false,
//   }) async {
//     final androidDetails = AndroidNotificationDetails(
//       'testdrive_tracking',
//       'Test Drive Tracking',
//       channelDescription: 'Active test drive tracking notifications',
//       importance: Importance.high,
//       priority: Priority.high,
//       ongoing: true,
//       autoCancel: false,
//       showWhen: false,
//       onlyAlertOnce: true,
//       category: AndroidNotificationCategory.service,
//       visibility: NotificationVisibility.public,
//       playSound: !isSilentUpdate,
//       enableVibration: !isSilentUpdate,
//       styleInformation: BigTextStyleInformation(
//         'Test Drive is Ongoing in the background',
//         contentTitle: 'Test Drive Active',
//       ),
//     );

//     final iosDetails = DarwinNotificationDetails(
//       presentAlert: !isSilentUpdate,
//       presentBadge: false,
//       presentSound: !isSilentUpdate,
//     );

//     final details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notifications.show(
//       1,
//       'Test Drive Active',
//       'Test Drive is Ongoing in the background',
//       details,
//       payload: 'testdrive_tracking',
//     );
//   }

//   Future<void> cancelDriveNotification() async {
//     await _notifications.cancel(1);
//     debugPrint('✅ Drive notification cancelled');
//   }

//   Future<void> cancelAll() async {
//     await _notifications.cancelAll();
//   }
// }
