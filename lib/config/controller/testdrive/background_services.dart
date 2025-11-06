import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isInitialized = false;
  bool _isInitializing = false;
  final Completer<bool> _initCompleter = Completer<bool>();

  // Create notification channel FIRST
  Future<void> _createNotificationChannel() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'testdrive_tracking', // Must match your config
      'Test Drive Tracking',
      description: 'Tracks location during test drive',
      importance: Importance.high,
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print('✅ Notification channel created');
  }

  // Ensure all permissions are granted
  Future<bool> _ensurePermissions() async {
    try {
      // Location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied');
        return false;
      }

      // Notification permission (Android 13+)
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          print('⚠️ Notification permission denied');
          // Continue anyway - not critical
        }
      }

      // Background location (if needed)
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }

      // ✅ Request battery optimization exemption (critical for background service)
      try {
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          final status = await Permission.ignoreBatteryOptimizations.request();
          if (!status.isGranted) {
            print(
              '⚠️ Battery optimization not disabled - service may be killed',
            );
          } else {
            print('✅ Battery optimization disabled');
          }
        }
      } catch (e) {
        print('⚠️ Could not check battery optimization: $e');
      }

      print('✅ All permissions checked');
      return true;
    } catch (e) {
      print('❌ Permission check error: $e');
      return false;
    }
  }

  Future<bool> initialize() async {
    // Prevent concurrent initialization
    if (_isInitializing) {
      print('⏳ Already initializing, waiting...');
      return await _initCompleter.future;
    }

    if (_isInitialized) {
      print('✅ Already initialized');
      return true;
    }

    _isInitializing = true;

    try {
      print('🚀 Starting background service initialization...');

      // Step 1: Create notification channel
      await _createNotificationChannel();

      // Step 2: Check permissions
      final hasPermissions = await _ensurePermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Step 3: Configure service
      await _service.configure(
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          isForegroundMode: true, // ✅ CRITICAL: Must be true
          autoStart: false,
          autoStartOnBoot: false,
          notificationChannelId: 'testdrive_tracking',
          initialNotificationTitle: 'Test Drive Active',
          initialNotificationContent: 'Initializing location tracking...',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
          // ✅ ADDED: These prevent service from being killed
          // autoStartOnBootMode: AutoStartOnBootMode.nothing,
        ),
      );

      // Step 4: Verify service is ready
      await Future.delayed(const Duration(milliseconds: 500));

      _isInitialized = true;
      _isInitializing = false;
      _initCompleter.complete(true);

      print('✅ Background service initialized successfully');
      return true;
    } catch (e) {
      print('❌ Failed to initialize background service: $e');
      _isInitializing = false;
      _isInitialized = false;
      _initCompleter.complete(false);
      return false;
    }
  }

  Future<bool> startTracking() async {
    try {
      print('🎯 Starting tracking...');

      // Ensure initialized
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          throw Exception('Failed to initialize service');
        }
      }

      // Verify service is not already running
      final isRunning = await _service.isRunning();
      if (isRunning) {
        print('⚠️ Service already running');
        return true;
      }

      // Start service
      final started = await _service.startService();

      if (!started) {
        print('❌ Failed to start service');

        // Retry once
        await Future.delayed(const Duration(seconds: 1));
        final retryStarted = await _service.startService();

        if (!retryStarted) {
          throw Exception('Service failed to start after retry');
        }
      }

      // Verify service started
      await Future.delayed(const Duration(milliseconds: 500));
      final isNowRunning = await _service.isRunning();

      if (!isNowRunning) {
        throw Exception('Service started but not running');
      }

      print('✅ Tracking started successfully');
      return true;
    } catch (e) {
      print('❌ Error starting tracking: $e');
      return false;
    }
  }

  Future<void> stopTracking() async {
    try {
      print('🛑 Stopping tracking...');

      final isRunning = await _service.isRunning();
      if (!isRunning) {
        print('⚠️ Service not running');
        return;
      }

      _service.invoke('stopService');

      // Wait for stop
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ Tracking stopped');
    } catch (e) {
      print('❌ Error stopping tracking: $e');
    }
  }

  void listenToUpdates(Function(Map<String, dynamic>) onUpdate) {
    _service.on('location_update').listen((event) {
      if (event != null) {
        try {
          onUpdate(event as Map<String, dynamic>);
        } catch (e) {
          print('❌ Error processing location update: $e');
        }
      }
    });
  }

  // Reset service (for debugging)
  Future<void> reset() async {
    print('🔄 Resetting service...');
    await stopTracking();
    _isInitialized = false;
    _isInitializing = false;
    await Future.delayed(const Duration(seconds: 1));
    await initialize();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  print('🔵 Background service started');

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) async {
    print('🔴 Stop service requested');

    if (service is AndroidServiceInstance) {
      try {
        await service.setForegroundNotificationInfo(title: '', content: '');
      } catch (e) {
        print('⚠️ Error clearing notification: $e');
      }
    }

    service.stopSelf();
  });

  // Location tracking loop with error recovery
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      try {
        final isForeground = await service.isForegroundService();
        if (!isForeground) {
          service.setAsForegroundService();
          print('⚠️ Service not in foreground mode');
          return;
        }

        // Get location with timeout
        Position position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            ).timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Location request timed out');
              },
            );

        // Update notification
        await service.setForegroundNotificationInfo(
          title: 'Test Drive Active',
          content:
              'Distance tracking in progress\nLat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
        );

        // Send update to UI
        service.invoke('location_update', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'timestamp': DateTime.now().toIso8601String(),
        });

        print(
          '📍 Background update: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (±${position.accuracy.toStringAsFixed(1)}m)',
        );
      } catch (e) {
        print('❌ Background location error: $e');

        // Keep notification alive even on error
        try {
          await service.setForegroundNotificationInfo(
            title: 'Test Drive Active',
            content: 'Tracking in progress...',
          );
        } catch (notifError) {
          print('❌ Failed to update notification: $notifError');
        }
      }
    }
  });

  print('✅ Background service loop started');
}

// working fine 
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';

// class BackgroundLocationService {
//   static final BackgroundLocationService _instance =
//       BackgroundLocationService._internal();
//   factory BackgroundLocationService() => _instance;
//   BackgroundLocationService._internal();

//   final FlutterBackgroundService _service = FlutterBackgroundService();
//   bool _isInitialized = false;
//   bool _isInitializing = false;
//   final Completer<bool> _initCompleter = Completer<bool>();

//   // Create notification channel FIRST
//   Future<void> _createNotificationChannel() async {
//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'testdrive_tracking', // Must match your config
//       'Test Drive Tracking',
//       description: 'Tracks location during test drive',
//       importance: Importance.high,
//       enableVibration: false,
//       playSound: false,
//       showBadge: false,
//     );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);

//     print('✅ Notification channel created');
//   }

//   // Ensure all permissions are granted
//   Future<bool> _ensurePermissions() async {
//     try {
//       // Location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         print('❌ Location permission denied');
//         return false;
//       }

//       // Notification permission (Android 13+)
//       if (await Permission.notification.isDenied) {
//         final status = await Permission.notification.request();
//         if (!status.isGranted) {
//           print('⚠️ Notification permission denied');
//           // Continue anyway - not critical
//         }
//       }

//       // Background location (if needed)
//       if (await Permission.locationAlways.isDenied) {
//         await Permission.locationAlways.request();
//       }

//       // ✅ Request battery optimization exemption (critical for background service)
//       try {
//         if (await Permission.ignoreBatteryOptimizations.isDenied) {
//           final status = await Permission.ignoreBatteryOptimizations.request();
//           if (!status.isGranted) {
//             print(
//               '⚠️ Battery optimization not disabled - service may be killed',
//             );
//           } else {
//             print('✅ Battery optimization disabled');
//           }
//         }
//       } catch (e) {
//         print('⚠️ Could not check battery optimization: $e');
//       }

//       print('✅ All permissions checked');
//       return true;
//     } catch (e) {
//       print('❌ Permission check error: $e');
//       return false;
//     }
//   }

//   Future<bool> initialize() async {
//     // Prevent concurrent initialization
//     if (_isInitializing) {
//       print('⏳ Already initializing, waiting...');
//       return await _initCompleter.future;
//     }

//     if (_isInitialized) {
//       print('✅ Already initialized');
//       return true;
//     }

//     _isInitializing = true;

//     try {
//       print('🚀 Starting background service initialization...');

//       // Step 1: Create notification channel
//       await _createNotificationChannel();

//       // Step 2: Check permissions
//       final hasPermissions = await _ensurePermissions();
//       if (!hasPermissions) {
//         throw Exception('Required permissions not granted');
//       }

//       // Step 3: Configure service
//       await _service.configure(
//         iosConfiguration: IosConfiguration(
//           autoStart: false,
//           onForeground: onStart,
//           onBackground: onIosBackground,
//         ),
//         androidConfiguration: AndroidConfiguration(
//           onStart: onStart,
//           isForegroundMode: true,
//           autoStart: false,
//           autoStartOnBoot: false,
//           notificationChannelId: 'testdrive_tracking',
//           initialNotificationTitle: 'Test Drive Active',
//           initialNotificationContent: 'Initializing location tracking...',
//           foregroundServiceNotificationId: 888,
//           foregroundServiceTypes: [AndroidForegroundType.location],
//           // autoStartOnBootMode: AutoStartOnBootMode.nothing,
        
//         ),
//       );

//       // Step 4: Verify service is ready
//       await Future.delayed(const Duration(milliseconds: 500));

//       _isInitialized = true;
//       _isInitializing = false;
//       _initCompleter.complete(true);

//       print('✅ Background service initialized successfully');
//       return true;
//     } catch (e) {
//       print('❌ Failed to initialize background service: $e');
//       _isInitializing = false;
//       _isInitialized = false;
//       _initCompleter.complete(false);
//       return false;
//     }
//   }

//   Future<bool> startTracking() async {
//     try {
//       print('🎯 Starting tracking...');

//       // Ensure initialized
//       if (!_isInitialized) {
//         final initialized = await initialize();
//         if (!initialized) {
//           throw Exception('Failed to initialize service');
//         }
//       }

//       // Verify service is not already running
//       final isRunning = await _service.isRunning();
//       if (isRunning) {
//         print('⚠️ Service already running');
//         return true;
//       }

//       // Start service
//       final started = await _service.startService();

//       if (!started) {
//         print('❌ Failed to start service');

//         // Retry once
//         await Future.delayed(const Duration(seconds: 1));
//         final retryStarted = await _service.startService();

//         if (!retryStarted) {
//           throw Exception('Service failed to start after retry');
//         }
//       }

//       // Verify service started
//       await Future.delayed(const Duration(milliseconds: 500));
//       final isNowRunning = await _service.isRunning();

//       if (!isNowRunning) {
//         throw Exception('Service started but not running');
//       }

//       print('✅ Tracking started successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error starting tracking: $e');
//       return false;
//     }
//   }

//   Future<void> stopTracking() async {
//     try {
//       print('🛑 Stopping tracking...');

//       final isRunning = await _service.isRunning();
//       if (!isRunning) {
//         print('⚠️ Service not running');
//         return;
//       }

//       _service.invoke('stopService');

//       // Wait for stop
//       await Future.delayed(const Duration(milliseconds: 500));

//       print('✅ Tracking stopped');
//     } catch (e) {
//       print('❌ Error stopping tracking: $e');
//     }
//   }

//   void listenToUpdates(Function(Map<String, dynamic>) onUpdate) {
//     _service.on('location_update').listen((event) {
//       if (event != null) {
//         try {
//           onUpdate(event as Map<String, dynamic>);
//         } catch (e) {
//           print('❌ Error processing location update: $e');
//         }
//       }
//     });
//   }

//   // Reset service (for debugging)
//   Future<void> reset() async {
//     print('🔄 Resetting service...');
//     await stopTracking();
//     _isInitialized = false;
//     _isInitializing = false;
//     await Future.delayed(const Duration(seconds: 1));
//     await initialize();
//   }
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   print('🔵 Background service started');

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   service.on('stopService').listen((event) async {
//     print('🔴 Stop service requested');

//     if (service is AndroidServiceInstance) {
//       try {
//         await service.setForegroundNotificationInfo(title: '', content: '');
//       } catch (e) {
//         print('⚠️ Error clearing notification: $e');
//       }
//     }

//     service.stopSelf();
//   });

//   // Location tracking loop with error recovery
//   Timer.periodic(const Duration(seconds: 30), (timer) async {
//     if (service is AndroidServiceInstance) {
//       try {
//         final isForeground = await service.isForegroundService();
//         if (!isForeground) {
//           print('⚠️ Service not in foreground mode');
//           return;
//         }

//         // Get location with timeout
//         Position position =
//             await Geolocator.getCurrentPosition(
//               desiredAccuracy: LocationAccuracy.high,
//               timeLimit: const Duration(seconds: 10),
//             ).timeout(
//               const Duration(seconds: 15),
//               onTimeout: () {
//                 throw TimeoutException('Location request timed out');
//               },
//             );

//         // Update notification
//         await service.setForegroundNotificationInfo(
//           title: 'Test Drive Active',
//           content:
//               'Distance tracking in progress\nLat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
//         );

//         // Send update to UI
//         service.invoke('location_update', {
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'accuracy': position.accuracy,
//           'speed': position.speed,
//           'timestamp': DateTime.now().toIso8601String(),
//         });

//         print(
//           '📍 Background update: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (±${position.accuracy.toStringAsFixed(1)}m)',
//         );
//       } catch (e) {
//         print('❌ Background location error: $e');

//         // Keep notification alive even on error
//         try {
//           await service.setForegroundNotificationInfo(
//             title: 'Test Drive Active',
//             content: 'Tracking in progress...',
//           );
//         } catch (notifError) {
//           print('❌ Failed to update notification: $notifError');
//         }
//       }
//     }
//   });

//   print('✅ Background service loop started');
// }

// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';

// class BackgroundLocationService {
//   static final BackgroundLocationService _instance =
//       BackgroundLocationService._internal();
//   factory BackgroundLocationService() => _instance;
//   BackgroundLocationService._internal();

//   final FlutterBackgroundService _service = FlutterBackgroundService();
//   bool _isInitialized = false;
//   bool _isInitializing = false;
//   final Completer<bool> _initCompleter = Completer<bool>();

//   // Create notification channel FIRST
//   Future<void> _createNotificationChannel() async {
//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'testdrive_tracking', // Must match your config
//       'Test Drive Tracking',
//       description: 'Tracks location during test drive',
//       importance: Importance.high,
//       enableVibration: false,
//       playSound: false,
//       showBadge: false,
//     );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);

//     print('✅ Notification channel created');
//   }

//   // Ensure all permissions are granted
//   Future<bool> _ensurePermissions() async {
//     try {
//       // Location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         print('❌ Location permission denied');
//         return false;
//       }

//       // Notification permission (Android 13+)
//       if (await Permission.notification.isDenied) {
//         final status = await Permission.notification.request();
//         if (!status.isGranted) {
//           print('⚠️ Notification permission denied');
//           // Continue anyway - not critical
//         }
//       }

//       // Background location (if needed)
//       if (await Permission.locationAlways.isDenied) {
//         await Permission.locationAlways.request();
//       }

//       print('✅ All permissions checked');
//       return true;
//     } catch (e) {
//       print('❌ Permission check error: $e');
//       return false;
//     }
//   }

//   Future<bool> initialize() async {
//     // Prevent concurrent initialization
//     if (_isInitializing) {
//       print('⏳ Already initializing, waiting...');
//       return await _initCompleter.future;
//     }

//     if (_isInitialized) {
//       print('✅ Already initialized');
//       return true;
//     }

//     _isInitializing = true;

//     try {
//       print('🚀 Starting background service initialization...');

//       // Step 1: Create notification channel
//       await _createNotificationChannel();

//       // Step 2: Check permissions
//       final hasPermissions = await _ensurePermissions();
//       if (!hasPermissions) {
//         throw Exception('Required permissions not granted');
//       }

//       // Step 3: Configure service
//       await _service.configure(
//         iosConfiguration: IosConfiguration(
//           autoStart: false,
//           onForeground: onStart,
//           onBackground: onIosBackground,
//         ),
//         androidConfiguration: AndroidConfiguration(
//           onStart: onStart,
//           isForegroundMode: true,
//           autoStart: false,
//           autoStartOnBoot: false,
//           notificationChannelId: 'testdrive_tracking',
//           initialNotificationTitle: 'Test Drive Active',
//           initialNotificationContent: 'Initializing location tracking...',
//           foregroundServiceNotificationId: 888,
//           foregroundServiceTypes: [AndroidForegroundType.location],
//         ),
//       );

//       // Step 4: Verify service is ready
//       await Future.delayed(const Duration(milliseconds: 500));

//       _isInitialized = true;
//       _isInitializing = false;
//       _initCompleter.complete(true);

//       print('✅ Background service initialized successfully');
//       return true;
//     } catch (e) {
//       print('❌ Failed to initialize background service: $e');
//       _isInitializing = false;
//       _isInitialized = false;
//       _initCompleter.complete(false);
//       return false;
//     }
//   }

//   Future<bool> startTracking() async {
//     try {
//       print('🎯 Starting tracking...');

//       // Ensure initialized
//       if (!_isInitialized) {
//         final initialized = await initialize();
//         if (!initialized) {
//           throw Exception('Failed to initialize service');
//         }
//       }

//       // Verify service is not already running
//       final isRunning = await _service.isRunning();
//       if (isRunning) {
//         print('⚠️ Service already running');
//         return true;
//       }

//       // Start service
//       final started = await _service.startService();

//       if (!started) {
//         print('❌ Failed to start service');

//         // Retry once
//         await Future.delayed(const Duration(seconds: 1));
//         final retryStarted = await _service.startService();

//         if (!retryStarted) {
//           throw Exception('Service failed to start after retry');
//         }
//       }

//       // Verify service started
//       await Future.delayed(const Duration(milliseconds: 500));
//       final isNowRunning = await _service.isRunning();

//       if (!isNowRunning) {
//         throw Exception('Service started but not running');
//       }

//       print('✅ Tracking started successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error starting tracking: $e');
//       return false;
//     }
//   }

//   Future<void> stopTracking() async {
//     try {
//       print('🛑 Stopping tracking...');

//       final isRunning = await _service.isRunning();
//       if (!isRunning) {
//         print('⚠️ Service not running');
//         return;
//       }

//       _service.invoke('stopService');

//       // Wait for stop
//       await Future.delayed(const Duration(milliseconds: 500));

//       print('✅ Tracking stopped');
//     } catch (e) {
//       print('❌ Error stopping tracking: $e');
//     }
//   }

//   void listenToUpdates(Function(Map<String, dynamic>) onUpdate) {
//     _service.on('location_update').listen((event) {
//       if (event != null) {
//         try {
//           onUpdate(event as Map<String, dynamic>);
//         } catch (e) {
//           print('❌ Error processing location update: $e');
//         }
//       }
//     });
//   }

//   // Reset service (for debugging)
//   Future<void> reset() async {
//     print('🔄 Resetting service...');
//     await stopTracking();
//     _isInitialized = false;
//     _isInitializing = false;
//     await Future.delayed(const Duration(seconds: 1));
//     await initialize();
//   }
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   print('🔵 Background service started');

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   service.on('stopService').listen((event) async {
//     print('🔴 Stop service requested');

//     if (service is AndroidServiceInstance) {
//       try {
//         await service.setForegroundNotificationInfo(title: '', content: '');
//       } catch (e) {
//         print('⚠️ Error clearing notification: $e');
//       }
//     }

//     service.stopSelf();
//   });

//   // Location tracking loop with error recovery
//   Timer.periodic(const Duration(seconds: 30), (timer) async {
//     if (service is AndroidServiceInstance) {
//       try {
//         final isForeground = await service.isForegroundService();
//         if (!isForeground) {
//           print('⚠️ Service not in foreground mode');
//           return;
//         }

//         // Get location with timeout
//         Position position =
//             await Geolocator.getCurrentPosition(
//               desiredAccuracy: LocationAccuracy.high,
//               timeLimit: const Duration(seconds: 10),
//             ).timeout(
//               const Duration(seconds: 15),
//               onTimeout: () {
//                 throw TimeoutException('Location request timed out');
//               },
//             );

//         // Update notification
//         await service.setForegroundNotificationInfo(
//           title: 'Test Drive Active',
//           content:
//               'Distance tracking in progress\nLat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
//         );

//         // Send update to UI
//         service.invoke('location_update', {
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'accuracy': position.accuracy,
//           'speed': position.speed,
//           'timestamp': DateTime.now().toIso8601String(),
//         });

//         print(
//           '📍 Background update: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (±${position.accuracy.toStringAsFixed(1)}m)',
//         );
//       } catch (e) {
//         print('❌ Background location error: $e');

//         // Keep notification alive even on error
//         try {
//           await service.setForegroundNotificationInfo(
//             title: 'Test Drive Active',
//             content: 'Tracking in progress...',
//           );
//         } catch (notifError) {
//           print('❌ Failed to update notification: $notifError');
//         }
//       }
//     }
//   });

//   print('✅ Background service loop started');
// }


// import 'dart:ui';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// // import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:smartassist/config/model/testdrive/location_point.dart';
// // import 'package:smartassist/models/location_point.dart';

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       isForegroundMode: true,
//       autoStart: false,
//       notificationChannelId: 'testdrive_tracking',
//       initialNotificationTitle: 'Test Drive',
//       initialNotificationContent: 'Tracking your test drive...',
//       foregroundServiceNotificationId: 888,
//       foregroundServiceTypes: [AndroidForegroundType.location],
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // Initialize Hive in background isolate
//   await Hive.initFlutter();
//   Hive.registerAdapter(LocationPointAdapter());
//   Hive.registerAdapter(DriveSessionAdapter());

//   final locationsBox = await Hive.openBox<LocationPoint>('locations');
//   final drivesBox = await Hive.openBox<DriveSession>('drives');
//   final settingsBox = await Hive.openBox('settings');

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   // Track location updates
//   int pointsCollected = 0;
//   String? currentDriveId;

//   service.on('start_tracking').listen((event) async {
//     if (event != null) {
//       currentDriveId = event['driveId'] as String?;
//       pointsCollected = event['pointsCollected'] as int? ?? 0;

//       print(
//         '📍 Background service: Starting tracking for drive $currentDriveId',
//       );

//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: 'Test Drive Active',
//           content: 'Points: $pointsCollected',
//         );
//       }
//     }
//   });

//   // Location tracking timer
//   Timer.periodic(Duration(seconds: 10), (timer) async {
//     try {
//       if (currentDriveId == null) return;

//       final isTracking = settingsBox.get('is_tracking', defaultValue: false);
//       if (!isTracking) {
//         timer.cancel();
//         service.stopSelf();
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: Duration(seconds: 10),
//       );

//       pointsCollected++;

//       // Save to Hive
//       final point = LocationPoint(
//         latitude: position.latitude,
//         longitude: position.longitude,
//         timestamp: DateTime.now(),
//         accuracy: position.accuracy,
//       );

//       await locationsBox.add(point);

//       // Update drive session
//       final drive = drivesBox.get(currentDriveId);
//       if (drive != null) {
//         drive.points.add(point);
//         await drive.save();
//       }

//       // Update notification
//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: 'Test Drive Active',
//           content:
//               'Points: $pointsCollected | ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
//         );
//       }

//       // Send update to UI
//       service.invoke('location_update', {
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'points': pointsCollected,
//         'accuracy': position.accuracy,
//       });

//       print('📍 Background: ${position.latitude}, ${position.longitude}');
//     } catch (e) {
//       print('❌ Background location error: $e');
//     }
//   });
// }
