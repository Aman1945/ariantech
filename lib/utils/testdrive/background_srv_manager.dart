// utils/background_service_manager.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class TestDriveBackgroundServiceManager {
  static const _androidChannel = MethodChannel('testdrive_native_service');
  static const _iosChannel = MethodChannel('testdrive_ios_service');

  static bool _isServiceRunning = false;
  static Timer? _healthCheckTimer;

  // Initialize background service configuration
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'testdrive_tracking',
        initialNotificationTitle: 'Test Drive Service',
        initialNotificationContent: 'Preparing location tracking...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  // Start background service
  static Future<bool> startBackgroundService(
    String eventId,
    double totalDistance,
  ) async {
    try {
      if (_isServiceRunning) {
        print('⚠️ Background service already running');
        return true;
      }

      print('🚀 Starting background service for event: $eventId');
      final service = FlutterBackgroundService();

      bool isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        await Future.delayed(Duration(seconds: 2));
      }

      service.invoke('start_tracking', {
        'eventId': eventId,
        'totalDistance': totalDistance,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _isServiceRunning = true;
      _startHealthCheck();
      print('✅ Background service started successfully');
      return true;
    } catch (e) {
      print('❌ Failed to start background service: $e');
      return false;
    }
  }

  // Stop background service
  static Future<void> stopBackgroundService() async {
    try {
      print('🛑 Stopping background service');

      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;

      final service = FlutterBackgroundService();
      service.invoke('stop_tracking');

      // Stop native services
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('stopBackgroundService');
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('stopTracking');
      }

      _isServiceRunning = false;
      print('✅ Background service stopped');
    } catch (e) {
      print('❌ Error stopping background service: $e');
    }
  }

  // Start native background service for app backgrounding
  static Future<void> startNativeService(
    String eventId,
    double totalDistance,
  ) async {
    try {
      print('🚀 Starting native background service');

      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('startBackgroundService', {
          'eventId': eventId,
          'totalDistance': totalDistance,
        });
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('startTracking', {
          'eventId': eventId,
          'distance': totalDistance,
        });
      }

      print('✅ Native background service started');
    } catch (e) {
      print('❌ Failed to start native background service: $e');
    }
  }

  // Stop native background service
  static Future<void> stopNativeService() async {
    try {
      print('🛑 Stopping native background service');

      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('stopBackgroundService');
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('stopTracking');
      }

      print('✅ Native background service stopped');
    } catch (e) {
      print('❌ Failed to stop native background service: $e');
    }
  }

  // Setup iOS location listener
  static void setupiOSLocationListener(
    Function(Map<String, dynamic>) onLocationUpdate,
  ) {
    if (Platform.isIOS) {
      _iosChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'location_update':
            try {
              final arguments = call.arguments as Map<dynamic, dynamic>;
              final locationData = {
                'latitude': arguments['latitude'] as double,
                'longitude': arguments['longitude'] as double,
                'distance': arguments['distance'] as double,
                'duration': arguments['duration'] as int,
                'accuracy': arguments['accuracy'] as double,
              };
              onLocationUpdate(locationData);
            } catch (e) {
              print('❌ Error processing iOS location update: $e');
            }
            break;
        }
      });
    }
  }

  // Start health check timer
  static void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkServiceHealth();
    });
  }

  // Check if background service is still running
  static void _checkServiceHealth() {
    if (!_isServiceRunning) return;

    final service = FlutterBackgroundService();
    service.invoke('get_data');

    service.on('data_response').listen((event) {
      bool isRunning = event?['isRunning'] ?? false;
      if (!isRunning) {
        print('⚠️ Background service not running, attempting restart');
        _restartService();
      }
    });
  }

  // Restart background service if it stops unexpectedly
  static void _restartService() {
    print('🔄 Restarting background service');
    // This would need access to current drive data to restart properly
    // Implementation depends on how you want to handle service recovery
  }

  // Background service entry point
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Ensure plugins are initialized
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Test Drive Service',
        content: 'Initializing...',
      );
      service.setAsForegroundService();
    }

    String? eventId;
    double totalDistance = 0.0;

    // Listen for tracking start command
    service.on('start_tracking').listen((event) async {
      if (event != null) {
        eventId = event['eventId'];
        totalDistance = event['totalDistance']?.toDouble() ?? 0.0;

        print('📍 Starting background tracking for: $eventId');

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Test Drive Active',
            content: 'Tracking location...',
          );
        }

        // Start location tracking timer
        Timer.periodic(Duration(seconds: 10), (timer) async {
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            // Send location update to main app
            service.invoke('location_update', {
              'position': {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'accuracy': position.accuracy,
              },
              'totalDistance': totalDistance,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });

            print(
              '📍 Background location: ${position.latitude}, ${position.longitude}',
            );
          } catch (e) {
            print('❌ Background location error: $e');
          }
        });
      }
    });

    // Listen for stop tracking command
    service.on('stop_tracking').listen((event) {
      print('🛑 Stopping background service');
      service.stopSelf();
    });

    // Health check response
    service.on('get_data').listen((event) {
      service.invoke('data_response', {
        'isRunning': true,
        'eventId': eventId,
        'totalDistance': totalDistance,
      });
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    // iOS background service handler
    return true;
  }

  // Cleanup resources
  static void dispose() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _isServiceRunning = false;
  }

  // Getters
  static bool get isServiceRunning => _isServiceRunning;
}
