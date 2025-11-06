// utils/permission_handler.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';  
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class TestDrivePermissionHandler {
  static Future<PermissionResult> requestLocationPermissions(
    BuildContext context,
  ) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return PermissionResult.locationServiceDisabled();
      }

      // Check current permission
      LocationPermission currentPermission = await Geolocator.checkPermission();
      if (currentPermission == LocationPermission.whileInUse ||
          currentPermission == LocationPermission.always) {
        print('✅ Already have permission: $currentPermission');
        return PermissionResult.granted(currentPermission);
      }

      // Platform-specific permission handling
      if (Platform.isIOS) {
        return await _handleiOSPermissions(context);
      } else if (Platform.isAndroid) {
        return await _handleAndroidPermissions(context);
      }

      return PermissionResult.unsupportedPlatform();
    } catch (e) {
      print('❌ Error in requestLocationPermissions: $e');
      return PermissionResult.error(e.toString());
    }
  }

  static Future<PermissionResult> _handleiOSPermissions(
    BuildContext context,
  ) async {
    print('📍 Handling iOS permissions...');
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current iOS permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 iOS permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        return PermissionResult.denied();
      }

      if (permission == LocationPermission.deniedForever) {
        return PermissionResult.permanentlyDenied();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print(
          '✅ iOS basic permission granted, requesting always permission...',
        );
        await _requestiOSAlwaysPermission(context);
        return PermissionResult.granted(permission);
      }

      return PermissionResult.denied();
    } catch (e) {
      print('❌ Error handling iOS permissions: $e');
      return PermissionResult.error(e.toString());
    }
  }

  static Future<PermissionResult> _handleAndroidPermissions(
    BuildContext context,
  ) async {
    print('📍 Handling Android permissions...');
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current Android permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 Android permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        return PermissionResult.denied();
      }

      if (permission == LocationPermission.deniedForever) {
        return PermissionResult.permanentlyDenied();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('✅ Android basic permission granted');
        await _tryRequestAndroidBackgroundPermission(context);
        return PermissionResult.granted(permission);
      }

      return PermissionResult.denied();
    } catch (e) {
      print('❌ Error handling Android permissions: $e');
      return PermissionResult.error(e.toString());
    }
  }

  static Future<void> _requestiOSAlwaysPermission(BuildContext context) async {
    if (Platform.isIOS) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse) {
          _showAlwaysPermissionDialog(context);
        }
        print('✅ iOS always permission requested');
      } catch (e) {
        print('❌ Failed to request iOS always permission: $e');
      }
    }
  }

  static Future<void> _tryRequestAndroidBackgroundPermission(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) return;

    try {
      if (await Permission.locationAlways.status.isDenied) {
        print('📍 Requesting Android background location permission...');
        PermissionStatus backgroundPermission = await Permission.locationAlways
            .request();
        print(
          '📍 Android background location permission: $backgroundPermission',
        );

        if (backgroundPermission.isDenied) {
          print(
            '⚠️ Android background location denied, but continuing with foreground only',
          );
          _showBackgroundPermissionInfo(context);
        } else if (backgroundPermission.isGranted) {
          print('✅ Android background location granted');
        }
      }
    } catch (e) {
      print('❌ Error requesting Android background permission: $e');
    }
  }

  static void _showAlwaysPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Background Location'),
          content: Text(
            'For the best test drive tracking experience, please choose "Change to Always Allow" when prompted. This allows accurate tracking even when the app is minimized.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void _showBackgroundPermissionInfo(BuildContext context) {
    Future.delayed(Duration(seconds: 1), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'For best tracking when app is minimized, enable "Allow all the time" in location settings',
            ),
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
      }
    });
  }

  // Permission dialog builders
  static void showPermissionDialog(
    BuildContext context, {
    required VoidCallback onGrantPressed,
    required VoidCallback onCancelPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location Permission Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app needs location access to track your test drive.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              if (Platform.isIOS) ...[
                Text(
                  'iOS Instructions:\n'
                  '• Tap "Grant Permission" below\n'
                  '• Choose "Allow While Using App" first\n'
                  '• Later you\'ll be asked to "Change to Always Allow" for background tracking',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ] else if (Platform.isAndroid) ...[
                Text(
                  'Android Instructions:\n'
                  '• Tap "Grant Permission" below\n'
                  '• Choose "While using the app" or "Only this time"\n'
                  '• You can change this later in settings',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: onCancelPressed, child: Text('Cancel')),
            ElevatedButton(
              onPressed: onGrantPressed,
              child: Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  static void showLocationServiceDialog(
    BuildContext context, {
    required VoidCallback onExitPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Location Services Disabled'),
            ],
          ),
          content: Text(
            'Location services are turned off. Please enable location services to track your test drive.',
          ),
          actions: [
            TextButton(onPressed: onExitPressed, child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                Future.delayed(Duration(seconds: 2), () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tap "Try Again" after enabling location services',
                        ),
                        action: SnackBarAction(
                          label: 'Try Again',
                          onPressed: () => requestLocationPermissions(context),
                        ),
                      ),
                    );
                  }
                });
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static void showPermanentlyDeniedDialog(
    BuildContext context, {
    required VoidCallback onExitPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.red),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location permission was permanently denied. Please enable it manually in app settings.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              if (Platform.isIOS) ...[
                Text(
                  'Steps:\n1. Tap "Open Settings"\n2. Find this app\n3. Tap "Location"\n4. Choose "Always" or "While Using App"',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ] else if (Platform.isAndroid) ...[
                Text(
                  'Steps:\n1. Tap "Open Settings"\n2. Go to "Permissions"\n3. Tap "Location"\n4. Choose "Allow only while using the app"',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: onExitPressed, child: Text('Exit')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'After enabling permissions, tap "Try Again"',
                    ),
                    duration: Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Try Again',
                      onPressed: () => requestLocationPermissions(context),
                    ),
                  ),
                );
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static void showExitOrRetryDialog(
    BuildContext context, {
    required VoidCallback onExitPressed,
    required VoidCallback onRetryPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Required'),
          content: Text(
            'Test drive tracking requires location access. Would you like to try again or exit?',
          ),
          actions: [
            TextButton(
              onPressed: onExitPressed,
              child: Text('Exit Test Drive'),
            ),
            ElevatedButton(onPressed: onRetryPressed, child: Text('Try Again')),
          ],
        );
      },
    );
  }
}

// Result class for permission operations
class PermissionResult {
  final TestDrivePermissionStatus status;
  final String? errorMessage;
  final LocationPermission? locationPermission;

  const PermissionResult._({
    required this.status,
    this.errorMessage,
    this.locationPermission,
  });

  factory PermissionResult.granted(LocationPermission permission) {
    return PermissionResult._(
      status: TestDrivePermissionStatus.granted,
      locationPermission: permission,
    );
  }

  factory PermissionResult.denied() {
    return PermissionResult._(status: TestDrivePermissionStatus.denied);
  }

  factory PermissionResult.permanentlyDenied() {
    return PermissionResult._(
      status: TestDrivePermissionStatus.permanentlyDenied,
    );
  }

  factory PermissionResult.locationServiceDisabled() {
    return PermissionResult._(
      status: TestDrivePermissionStatus.denied,
      errorMessage: 'Location services are disabled',
    );
  }

  factory PermissionResult.unsupportedPlatform() {
    return PermissionResult._(
      status: TestDrivePermissionStatus.denied,
      errorMessage: 'Unsupported platform',
    );
  }

  factory PermissionResult.error(String message) {
    return PermissionResult._(
      status: TestDrivePermissionStatus.denied,
      errorMessage: message,
    );
  }

  bool get isGranted => status == TestDrivePermissionStatus.granted;
  bool get isDenied => status == TestDrivePermissionStatus.denied;
  bool get isPermanentlyDenied =>
      status == TestDrivePermissionStatus.permanentlyDenied;
  bool get hasError => errorMessage != null;
}

enum TestDrivePermissionStatus { granted, denied, permanentlyDenied }
