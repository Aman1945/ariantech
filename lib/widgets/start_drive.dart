import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/feedback.dart';
import 'package:smartassist/widgets/testdrive_summary.dart';
import 'package:geolocator/geolocator.dart';

// Enhanced Distance Calculator with better accuracy
class ImprovedDistanceCalculator {
  // Enhanced constants for better accuracy
  static const double MIN_ACCURACY_THRESHOLD =
      20.0; // 20 meters max GPS accuracy
  static const double MAX_SPEED_THRESHOLD =
      120.0; // 120 km/h max realistic speed
  static const double MIN_MOVEMENT_THRESHOLD =
      2.0; // 2 meters minimum movement in meters
  static const int MAX_LOCATION_AGE_SECONDS = 15; // 15 seconds max age
  static const double NOISE_FILTER_RADIUS = 5.0; // 5 meters noise filter

  // Track accumulated small movements
  static double _accumulatedSmallMovements = 0.0;
  static LatLng? _lastAccumulatedPosition;

  // Calculate distance using Haversine formula (most accurate)
  static double calculateDistanceHaversine(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000.0; // Earth's radius in meters

    double lat1Rad = point1.latitude * (pi / 180.0);
    double lat2Rad = point2.latitude * (pi / 180.0);
    double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180.0);
    double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180.0);

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in meters
  }

  // Enhanced validation with better logic
  static LocationValidationResult validateLocationUpdate(
    Position position,
    LatLng? lastLocation,
    DateTime? lastTime,
  ) {
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    // Check GPS accuracy first
    if (position.accuracy > MIN_ACCURACY_THRESHOLD) {
      return LocationValidationResult(
        isValid: false,
        reason: 'Poor GPS accuracy: ${position.accuracy.toStringAsFixed(1)}m',
        distanceMeters: 0,
      );
    }

    // Check location age
    if (position.timestamp != null) {
      int locationAge = DateTime.now()
          .difference(position.timestamp!)
          .inSeconds;
      if (locationAge > MAX_LOCATION_AGE_SECONDS) {
        return LocationValidationResult(
          isValid: false,
          reason: 'Location too old: ${locationAge}s',
          distanceMeters: 0,
        );
      }
    }

    // First location is always valid
    if (lastLocation == null || lastTime == null) {
      return LocationValidationResult(
        isValid: true,
        reason: 'First location',
        distanceMeters: 0,
      );
    }

    // Calculate distance moved
    double distanceMeters = calculateDistanceHaversine(
      lastLocation,
      currentLocation,
    );

    // Check for unrealistic speed (GPS jumps)
    double timeElapsedSeconds = DateTime.now()
        .difference(lastTime)
        .inSeconds
        .toDouble();
    if (timeElapsedSeconds > 0) {
      double speedKmh = (distanceMeters / timeElapsedSeconds) * 3.6;
      if (speedKmh > MAX_SPEED_THRESHOLD) {
        return LocationValidationResult(
          isValid: false,
          reason: 'Unrealistic speed: ${speedKmh.toStringAsFixed(1)} km/h',
          distanceMeters: distanceMeters,
        );
      }
    }

    // Handle small movements with accumulation
    if (distanceMeters < MIN_MOVEMENT_THRESHOLD) {
      _accumulatedSmallMovements += distanceMeters;
      _lastAccumulatedPosition = currentLocation;

      return LocationValidationResult(
        isValid: false,
        reason:
            'Small movement accumulated: ${distanceMeters.toStringAsFixed(1)}m (total: ${_accumulatedSmallMovements.toStringAsFixed(1)}m)',
        distanceMeters: distanceMeters,
        accumulatedDistance: _accumulatedSmallMovements,
      );
    }

    // Valid movement - add any accumulated small movements
    double totalDistance = distanceMeters + _accumulatedSmallMovements;
    _accumulatedSmallMovements = 0.0; // Reset accumulation
    _lastAccumulatedPosition = null;

    return LocationValidationResult(
      isValid: true,
      reason: 'Valid movement: ${distanceMeters.toStringAsFixed(1)}m',
      distanceMeters: totalDistance,
    );
  }

  // Check if accumulated small movements should be added
  static LocationValidationResult checkAccumulatedMovements(
    LatLng? lastValidLocation,
  ) {
    if (_accumulatedSmallMovements >= MIN_MOVEMENT_THRESHOLD &&
        _lastAccumulatedPosition != null &&
        lastValidLocation != null) {
      double totalAccumulated = _accumulatedSmallMovements;
      _accumulatedSmallMovements = 0.0;
      _lastAccumulatedPosition = null;

      return LocationValidationResult(
        isValid: true,
        reason:
            'Accumulated movements released: ${totalAccumulated.toStringAsFixed(1)}m',
        distanceMeters: totalAccumulated,
      );
    }

    return LocationValidationResult(
      isValid: false,
      reason: 'No accumulated movements to release',
      distanceMeters: 0,
    );
  }

  // Reset accumulation (call when drive ends)
  static void resetAccumulation() {
    _accumulatedSmallMovements = 0.0;
    _lastAccumulatedPosition = null;
  }

  // Get current accumulated distance
  static double getCurrentAccumulation() {
    return _accumulatedSmallMovements;
  }
}

// Result class for validation
class LocationValidationResult {
  final bool isValid;
  final String reason;
  final double distanceMeters;
  final double? accumulatedDistance;

  const LocationValidationResult({
    required this.isValid,
    required this.reason,
    required this.distanceMeters,
    this.accumulatedDistance,
  });

  double get distanceKm => distanceMeters / 1000.0;
}

class StartDriveMap extends StatefulWidget {
  final String eventId;
  final String leadId;
  const StartDriveMap({super.key, required this.eventId, required this.leadId});

  @override
  State<StartDriveMap> createState() => _StartDriveMapState();
}

class _StartDriveMapState extends State<StartDriveMap>
    with WidgetsBindingObserver {
  late GoogleMapController mapController;

  Marker? startMarker;
  Marker? userMarker;
  Marker? endMarker;
  late Polyline routePolyline;
  List<LatLng> routePoints = [];

  bool isDriveEnded = false;
  bool isLoading = true;
  String error = '';
  double totalDistance = 0.0;
  bool _backgroundServiceStarted = false;
  Timer? _serviceHealthCheck;

  // Enhanced duration tracking
  DateTime? driveStartTime;
  DateTime? driveEndTime;
  DateTime? pauseStartTime;
  int totalPausedDuration = 0;
  bool isDrivePaused = false;

  StreamSubscription<Position>? positionStreamSubscription;
  bool isSubmitting = false;
  bool _isBackgroundServiceActive = false;
  LatLng? _lastValidLocation;
  DateTime? _lastLocationTime;
  double _totalDistanceAccumulator = 0.0;
  Timer? _locationUpdateTimer;
  bool _isBackgroundServiceStarting = false;
  static const platform = MethodChannel('testdrive_native_service');
  static const iosChannel = MethodChannel('testdrive_ios_service');

  // Enhanced constants for better accuracy
  static const double MIN_DISTANCE_THRESHOLD = 0.001; // 1 meter in km
  static const double MAX_SPEED_THRESHOLD =
      200.0; // 200 km/h max realistic speed
  static const double MIN_ACCURACY_THRESHOLD = 50.0; // 50 meters max accuracy
  static const int MAX_LOCATION_AGE = 10; // seconds
  static const int LOCATION_UPDATE_INTERVAL = 3; // seconds

  // exit popup
  DateTime? _lastBackPressTime;
  final int _exitTimeInMillis = 2000;

  String? isFromTestdrive;

  @override
  void initState() {
    super.initState();
    driveStartTime = DateTime.now();
    totalDistance = 0.0;
    WidgetsBinding.instance.addObserver(this);
    // _requestBatteryOptimization();
    _setupiOSLocationListener();
    _initializeBackgroundService();
    _determinePosition(); // This starts the permission flow
    _startServiceHealthCheck();

    routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: routePoints,
      color: AppColors.colorsBlue,
      width: 5,
    );
  }

  void _startServiceHealthCheck() {
    _serviceHealthCheck = Timer.periodic(Duration(seconds: 60), (timer) {
      if (_backgroundServiceStarted) {
        _checkBackgroundServiceHealth();
      }
    });
  }

  void _checkBackgroundServiceHealth() {
    final service = FlutterBackgroundService();
    service.invoke('get_data');
    service.on('data_response').listen((event) {
      bool isRunning = event?['isRunning'] ?? false;
      if (!isRunning && !isDriveEnded) {
        print('⚠️ Background service not running, attempting restart');
        _restartBackgroundService();
      }
    });
  }

  void _restartBackgroundService() {
    if (!isDriveEnded) {
      _startBackgroundService();
    }
  }

  Future<void> _getAndroidLocation() async {
    try {
      print('✅ Getting Android location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
      print(
        '📍 Android location obtained: ${position.latitude}, ${position.longitude}',
      );
      _handleLocationObtained(position);
    } catch (e) {
      print('❌ Error getting Android location: $e');
      setState(() {
        error = 'Error getting Android location: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _getiOSLocation() async {
    try {
      print('✅ Getting iOS location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
      print(
        '📍 iOS location obtained: ${position.latitude}, ${position.longitude}',
      );
      _handleLocationObtained(position);
    } catch (e) {
      print('❌ Error getting iOS location: $e');
      setState(() {
        error = 'Error getting iOS location: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
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
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    print('🚀 Background service started');

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Test Drive Service',
        content: 'Initializing...',
      );
      service.setAsForegroundService();
      print('✅ Set as foreground service immediately');
    }

    String? eventId;
    double totalDistance = 0.0;

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

        Timer.periodic(Duration(seconds: 10), (timer) async {
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            print(
              '📍 Background location: ${position.latitude}, ${position.longitude}',
            );

            service.invoke('location_update', {
              'position': {
                'latitude': position.latitude,
                'longitude': position.longitude,
              },
              'totalDistance': totalDistance,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          } catch (e) {
            print('❌ Background location error: $e');
          }
        });
      }
    });

    service.on('stop_tracking').listen((event) {
      print('🛑 Stopping background service');
      service.stopSelf();
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 App lifecycle state: $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (!isDriveEnded) {
          _startNativeBackgroundService();
        }
        break;
      case AppLifecycleState.resumed:
        _stopNativeBackgroundService();
        if (!isDriveEnded) {
          _startLocationTracking();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _startNativeBackgroundService() async {
    try {
      print('🚀 Starting native background service');

      if (Platform.isAndroid) {
        await platform.invokeMethod('startBackgroundService', {
          'eventId': widget.eventId,
          'totalDistance': totalDistance,
        });
      } else if (Platform.isIOS) {
        await iosChannel.invokeMethod('startTracking', {
          'eventId': widget.eventId,
          'distance': totalDistance,
        });
      }

      if (positionStreamSubscription != null) {
        positionStreamSubscription!.cancel();
        positionStreamSubscription = null;
      }

      print('✅ Native background service started');
    } catch (e) {
      print('❌ Failed to start native background service: $e');
    }
  }

  void _setupiOSLocationListener() {
    if (Platform.isIOS) {
      iosChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'location_update':
            if (mounted && !isDriveEnded) {
              try {
                final arguments = call.arguments as Map<dynamic, dynamic>;
                final latitude = arguments['latitude'] as double;
                final longitude = arguments['longitude'] as double;
                final distance = arguments['distance'] as double;
                final duration = arguments['duration'] as int;
                final accuracy = arguments['accuracy'] as double;

                print(
                  '📍 iOS location update: $latitude, $longitude, distance: $distance km',
                );

                setState(() {
                  final newLocation = LatLng(latitude, longitude);

                  userMarker = Marker(
                    markerId: const MarkerId('user'),
                    position: newLocation,
                    infoWindow: InfoWindow(
                      title: 'Current Location',
                      snippet: 'Accuracy: ${accuracy.toStringAsFixed(1)}m',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  );

                  if (distance > totalDistance &&
                      distance < totalDistance + 0.5) {
                    totalDistance = distance;
                    _totalDistanceAccumulator = distance;
                  }

                  if (routePoints.isEmpty ||
                      _calculateAccurateDistance(
                            routePoints.last,
                            newLocation,
                          ) >
                          0.005) {
                    routePoints.add(newLocation);
                  }

                  _lastValidLocation = newLocation;
                  _lastLocationTime = DateTime.now();
                });

                if (mapController != null) {
                  mapController.animateCamera(
                    CameraUpdate.newLatLng(LatLng(latitude, longitude)),
                  );
                }
              } catch (e) {
                print('❌ Error processing iOS location update: $e');
              }
            }
            break;
        }
      });
    }
  }

  // ✅ FIXED: Better permission handling that doesn't exit screen immediately
  Future<void> _determinePosition() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      // Check current permission first
      LocationPermission currentPermission = await Geolocator.checkPermission();
      if (currentPermission == LocationPermission.whileInUse ||
          currentPermission == LocationPermission.always) {
        print('✅ Already have permission: $currentPermission');
        await _getCurrentLocation();
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          error =
              'Location services are disabled. Please enable location services.';
          isLoading = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Platform-specific permission handling
      if (Platform.isIOS) {
        await _handleiOSPermissions();
      } else if (Platform.isAndroid) {
        await _handleAndroidPermissions();
      }
    } catch (e) {
      print('❌ Error in _determinePosition: $e');
      setState(() {
        error = 'Error setting up location tracking: $e';
        isLoading = false;
      });
    }
  }

  // ✅ FIXED: Permission denied dialog that doesn't exit screen
  void _showPermissionDeniedDialog() {
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
                'This app needs location access to track your test drive accurately.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Please grant location permission to continue with the test drive.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show option to exit or retry
                _showExitOrRetryDialog();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Retry permission request
                await Future.delayed(Duration(milliseconds: 500));
                _determinePosition();
              },
              child: Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Exit or retry dialog when user cancels permission
  void _showExitOrRetryDialog() {
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
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Exit the test drive screen
              },
              child: Text('Exit Test Drive'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _determinePosition(); // Retry
              },
              child: Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Location Services Disabled',
                style: AppFont.dropDowmLabel(context),
              ),
            ],
          ),
          content: Text(
            'Location services are turned off. Please enable location services to track your test drive.',
            style: AppFont.smallText12(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Exit the screen
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                // Show retry option
                Future.delayed(Duration(seconds: 2), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tap "Try Again" after enabling location services',
                        ),
                        action: SnackBarAction(
                          label: 'Try Again',
                          onPressed: () => _determinePosition(),
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

  void _showPermanentlyDeniedDialog() {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Exit the screen
              },
              child: Text('Exit'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // Show retry option
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'After enabling permissions, tap "Try Again"',
                    ),
                    duration: Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Try Again',
                      onPressed: () => _determinePosition(),
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

  Future<void> _requestiOSAlwaysPermission() async {
    if (Platform.isIOS) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse) {
          _showAlwaysPermissionDialog();
        }
        await iosChannel.invokeMethod('requestAlwaysPermission');
        print('✅ iOS always permission requested');
      } catch (e) {
        print('❌ Failed to request iOS always permission: $e');
      }
    }
  }

  void _showAlwaysPermissionDialog() {
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

  Future<void> _tryRequestAndroidBackgroundPermission() async {
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
          _showBackgroundPermissionInfo();
        } else if (backgroundPermission.isGranted) {
          print('✅ Android background location granted');
        }
      }
    } catch (e) {
      print('❌ Error requesting Android background permission: $e');
    }
  }

  void _showBackgroundPermissionInfo() {
    if (mounted) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
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
  }

  int _calculateDuration() {
    if (driveStartTime == null) return 0;

    DateTime endTime = driveEndTime ?? DateTime.now();
    int totalElapsed = endTime.difference(driveStartTime!).inSeconds;

    // Subtract paused duration
    int activeDrivingTime = totalElapsed - totalPausedDuration;

    // If currently paused, subtract current pause duration
    if (isDrivePaused && pauseStartTime != null) {
      int currentPauseDuration = DateTime.now()
          .difference(pauseStartTime!)
          .inSeconds;
      activeDrivingTime -= currentPauseDuration;
    }

    return (activeDrivingTime / 60).round(); // Convert to minutes
  }

  Future<void> _stopNativeBackgroundService() async {
    try {
      print('🛑 Stopping native background service');

      if (Platform.isAndroid) {
        await platform.invokeMethod('stopBackgroundService');
      } else if (Platform.isIOS) {
        await iosChannel.invokeMethod('stopTracking');
      }

      print('✅ Native background service stopped');
    } catch (e) {
      print('❌ Failed to stop native background service: $e');
    }
  }

  void _startBackgroundService() {
    if (_backgroundServiceStarted || isDriveEnded) return;

    try {
      print('🚀 Starting background service');
      final service = FlutterBackgroundService();

      service.isRunning().then((isRunning) {
        if (!isRunning) {
          service.startService();
          Future.delayed(Duration(seconds: 2), () {
            service.invoke('start_tracking', {
              'eventId': widget.eventId,
              'totalDistance': totalDistance,
              'driveStartTime': driveStartTime?.millisecondsSinceEpoch,
              'totalPausedDuration': totalPausedDuration,
            });
          });
        } else {
          service.invoke('start_tracking', {
            'eventId': widget.eventId,
            'totalDistance': totalDistance,
            'driveStartTime': driveStartTime?.millisecondsSinceEpoch,
            'totalPausedDuration': totalPausedDuration,
          });
        }
      });

      _backgroundServiceStarted = true;

      // Stop foreground location tracking
      if (positionStreamSubscription != null) {
        positionStreamSubscription!.cancel();
        positionStreamSubscription = null;
      }

      print('✅ Background service started successfully');
    } catch (e) {
      print('❌ Failed to start background service: $e');
      _backgroundServiceStarted = false;
    }
  }

  Future<void> _startTestDrive(LatLng currentLocation) async {
    try {
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/events/${widget.eventId}/start-drive',
      );
      final token = await Storage.getToken();

      final requestBody = {
        'start_location': {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📤 Sending JSON: ${json.encode(requestBody)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 5));

      print('Starting test drive for event: ${widget.eventId}');
      print('📩 Response body: ${response.body}');

      print('Starting test drive for event: ${widget.eventId}');
      if (response.statusCode == 200) {
        print('Test drive started successfully');
        _startLocationTracking();
      } else {
        throw Exception('Failed to start test drive: ${response.statusCode}');
      }
    } catch (e) {
      print('Error starting test drive: $e');
      if (mounted) {
        setState(() {
          error = 'Error starting test drive: $e';
        });
      }
    }
  }

  void _processLocationUpdate(Position position) {
    if (!mounted || isDriveEnded || isDrivePaused) return;

    final LatLng newLocation = LatLng(position.latitude, position.longitude);
    final DateTime now = DateTime.now();

    // Use improved validation
    LocationValidationResult validationResult =
        ImprovedDistanceCalculator.validateLocationUpdate(
          position,
          _lastValidLocation,
          _lastLocationTime,
        );

    print('📍 Location validation: ${validationResult.reason}');

    // Always update visual marker for user feedback (even for invalid locations)
    setState(() {
      userMarker = Marker(
        markerId: const MarkerId('user'),
        position: newLocation,
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: 'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          validationResult.isValid
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueOrange,
        ),
      );
    });

    // Only process distance for valid locations
    if (validationResult.isValid) {
      setState(() {
        // Add valid distance to total
        double distanceKm = validationResult.distanceKm;
        _totalDistanceAccumulator += distanceKm;
        totalDistance = _totalDistanceAccumulator;

        // Add to route points
        routePoints.add(newLocation);

        print(
          '✅ Distance added: ${(distanceKm * 1000).toStringAsFixed(1)}m, Total: ${totalDistance.toStringAsFixed(3)} km',
        );
      });

      // Update last valid position
      _lastValidLocation = newLocation;
      _lastLocationTime = now;

      // Update camera to follow valid locations
      if (mapController != null) {
        mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
      }
    } else {
      // Check if we should release accumulated small movements
      if (validationResult.accumulatedDistance != null &&
          validationResult.accumulatedDistance! >= 2.0) {
        LocationValidationResult accumulatedResult =
            ImprovedDistanceCalculator.checkAccumulatedMovements(
              _lastValidLocation,
            );
        if (accumulatedResult.isValid) {
          setState(() {
            double distanceKm = accumulatedResult.distanceKm;
            _totalDistanceAccumulator += distanceKm;
            totalDistance = _totalDistanceAccumulator;

            // Add accumulated position to route
            if (ImprovedDistanceCalculator._lastAccumulatedPosition != null) {
              routePoints.add(
                ImprovedDistanceCalculator._lastAccumulatedPosition!,
              );
            }

            print(
              '✅ Accumulated distance added: ${(distanceKm * 1000).toStringAsFixed(1)}m, Total: ${totalDistance.toStringAsFixed(3)} km',
            );
          });

          _lastValidLocation = newLocation;
          _lastLocationTime = now;
        }
      }
    }
  }

  bool _isValidLocationUpdate(
    LatLng newLocation,
    Position position,
    DateTime now,
  ) {
    // More lenient accuracy check for Android
    double maxAccuracy = Platform.isAndroid
        ? 30.0
        : 15.0; // 30m for Android, 15m for iOS

    if (position.accuracy > maxAccuracy) {
      print(
        '❌ Location accuracy too low: ${position.accuracy}m (max: ${maxAccuracy}m)',
      );
      return false;
    }

    // Check location age
    if (position.timestamp != null) {
      int locationAge = now.difference(position.timestamp!).inSeconds;
      if (locationAge > 10) {
        print('❌ Location too old: ${locationAge}s');
        return false;
      }
    }

    if (_lastValidLocation == null || _lastLocationTime == null) {
      print('✅ First location - accepted');
      return true;
    }

    // Check for unrealistic speed
    double distance = _calculateAccurateDistance(
      _lastValidLocation!,
      newLocation,
    );
    double timeElapsed = now
        .difference(_lastLocationTime!)
        .inSeconds
        .toDouble();

    if (timeElapsed > 0) {
      double speed = (distance / timeElapsed) * 3600; // km/h
      if (speed > 150.0) {
        print('❌ Unrealistic speed: ${speed.toStringAsFixed(1)} km/h');
        return false;
      }
    }

    // Smaller minimum movement for better tracking
    double minMovement = Platform.isAndroid
        ? 0.003
        : 0.005; // 3m for Android, 5m for iOS

    if (distance >= minMovement) {
      print('✅ Valid movement: ${(distance * 1000).toStringAsFixed(1)}m');
      return true;
    } else {
      print(
        '⏸️ Movement too small: ${(distance * 1000).toStringAsFixed(1)}m (min: ${(minMovement * 1000).toStringAsFixed(0)}m)',
      );
      return false;
    }
  }

  void _startLocationTracking() {
    try {
      LocationSettings locationSettings;

      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high, // Use high accuracy
          distanceFilter: 0, // No distance filter - let our algorithm handle it
          timeLimit: Duration(seconds: 10),
          forceLocationManager: false,
        );
      } else {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation, // Best for driving
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 0, // No distance filter
          pauseLocationUpdatesAutomatically: false,
          timeLimit: Duration(seconds: 8),
        );
      }

      // Request location updates every 2-3 seconds for better accuracy
      positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              if (!isDrivePaused) {
                _processLocationUpdate(position);
              }
            },
            onError: (error) {
              print('Location stream error: $error');
              // Retry after error
              Future.delayed(Duration(seconds: 3), () {
                if (!isDriveEnded && mounted) {
                  print('Retrying location tracking...');
                  _startLocationTracking();
                }
              });
            },
          );
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  double _calculateAccurateDistance(LatLng point1, LatLng point2) {
    double distanceInMeters = Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );

    return distanceInMeters / 1000.0; // Convert to kilometers
  }

  void _handleDriveEnded(double distance, int duration) {
    if (mounted) {
      setState(() {
        driveEndTime = DateTime.now();

        if (userMarker != null) {
          endMarker = Marker(
            markerId: const MarkerId('end'),
            position: userMarker!.position,
            infoWindow: const InfoWindow(title: 'End'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          );
        }

        isDriveEnded = true;
        totalDistance = distance > 0 ? distance : totalDistance;

        if (positionStreamSubscription != null) {
          positionStreamSubscription!.cancel();
        }
      });
    }
  }

  // Format distance for display with appropriate precision
  String _formatDistance(double distance) {
    if (distance < 0.001) {
      // Less than 1 meter
      return '0 m';
    } else if (distance < 0.01) {
      // Less than 10 meters
      return '${(distance * 1000).round()} m';
    } else if (distance < 0.1) {
      // Less than 100 meters
      return '${(distance * 1000).round()} m';
    } else if (distance < 1.0) {
      // Less than 1 km
      return '${distance.toStringAsFixed(2)} km';
    } else if (distance < 10.0) {
      // Less than 10 km
      return '${distance.toStringAsFixed(2)} km';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  void _handleLocationObtained(Position position) {
    final LatLng currentLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {
        startMarker = Marker(
          markerId: const MarkerId('start'),
          position: currentLocation,
          infoWindow: const InfoWindow(title: 'Start'),
        );

        userMarker = Marker(
          markerId: const MarkerId('user'),
          position: currentLocation,
          infoWindow: const InfoWindow(title: 'User'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        );

        routePoints.add(currentLocation);
        _lastValidLocation = currentLocation;
        _lastLocationTime = DateTime.now();
        isLoading = false;
      });

      // Start the test drive
      _startTestDrive(currentLocation);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Getting current location...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      print(
        '📍 Location obtained: ${position.latitude}, ${position.longitude}',
      );
      _handleLocationObtained(position);
    } catch (e) {
      print('❌ Error getting current location: $e');
      setState(() {
        error = 'Failed to get current location: $e';
        isLoading = false;
      });
    }
  }

  // Missing complete iOS handling:
  Future<void> _handleiOSPermissions() async {
    print('📍 Handling iOS permissions...');
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current iOS permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 iOS permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          error =
              'Location permissions are denied. Please allow access to your location.';
          isLoading = false;
        });
        _showPermissionDialog();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error =
              'Location permissions are permanently denied. Please enable them in app settings.';
          isLoading = false;
        });
        _showPermanentlyDeniedDialog();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print(
          '✅ iOS basic permission granted, requesting always permission...',
        );
        await _requestiOSAlwaysPermission();
        await _getiOSLocation();
      }
    } catch (e) {
      print('❌ Error handling iOS permissions: $e');
      setState(() {
        error = 'Error handling iOS permissions: $e';
        isLoading = false;
      });
    }
  }

  // Missing platform-specific instructions in _showPermissionDialog():
  void _showPermissionDialog() {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showExitOrRetryDialog(); // Add this
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (Platform.isIOS) {
                  await _handleiOSPermissions();
                } else if (Platform.isAndroid) {
                  await _handleAndroidPermissions();
                }
              },
              child: Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAndroidPermissions() async {
    print('📍 Handling Android permissions...');
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current Android permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 Android permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          error =
              'Location permissions are denied. Please allow access to your location.';
          isLoading = false;
        });
        _showPermissionDialog();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error =
              'Location permissions are permanently denied. Please enable them in app settings.';
          isLoading = false;
        });
        _showPermanentlyDeniedDialog();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('✅ Android basic permission granted');
        await _tryRequestAndroidBackgroundPermission();
        await _getAndroidLocation();
      }
    } catch (e) {
      print('❌ Error handling Android permissions: $e');
      setState(() {
        error = 'Error handling Android permissions: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final bool isDisabled = await platform.invokeMethod(
        'isBatteryOptimizationDisabled',
      );
      if (!isDisabled) {
        _showBatteryOptimizationDialog();
      }
    } catch (e) {
      print('❌ Failed to check battery optimization: $e');
    }
  }

  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Battery Optimization',
            style: AppFont.dropDowmLabel(context),
          ),
          content: Text(
            'To ensure accurate test drive tracking in the background, please disable battery optimization for this app.',
            style: AppFont.smallText12(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await platform.invokeMethod('requestBatteryOptimization');
                } catch (e) {
                  print('❌ Failed to request battery optimization: $e');
                }
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _cleanupResources() {
    try {
      _locationUpdateTimer?.cancel();

      if (_isBackgroundServiceActive) {
        final service = FlutterBackgroundService();
        service.invoke('stop_tracking');
        _isBackgroundServiceActive = false;
      }

      if (positionStreamSubscription != null) {
        positionStreamSubscription!.cancel();
        positionStreamSubscription = null;
      }
    } catch (e) {
      print("Error during resource cleanup: $e");
    }
  }

  @override
  void dispose() {
    _serviceHealthCheck?.cancel();
    _locationUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Stop background service when disposing
    if (_backgroundServiceStarted) {
      final service = FlutterBackgroundService();
      service.invoke('stop_tracking');
    }

    if (Platform.isIOS) {
      _stopNativeBackgroundService();
      // ✅ ADDED: Cancel iOS notifications
      iosChannel.invokeMethod('cancelNotification').catchError((e) {
        print('Error canceling iOS notifications: $e');
      });
    }

    if (Platform.isAndroid) {
      platform.invokeMethod('cancelNotification');
    }

    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: isLoading
            ? const Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : error.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _determinePosition,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: startMarker?.position ?? const LatLng(0, 0),
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    markers: {
                      if (startMarker != null) startMarker!,
                      if (userMarker != null) userMarker!,
                      if (isDriveEnded && endMarker != null) endMarker!,
                    },
                    polylines: {routePolyline},
                  ),

                  // Drive Stats Container (positioned at top)
                  if (!isDriveEnded)
                    Positioned(
                      top: 50,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Distance: ${_formatDistance(totalDistance)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Duration: ${_calculateDuration()} mins',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isDrivePaused)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Drive Paused',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Floating Buttons at Bottom
                  if (!isDriveEnded)
                    Positioned(
                      bottom: 40,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // First Button - Submit Feedback Now
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      try {
                                        await _captureAndUploadImage().catchError((
                                          e,
                                        ) {
                                          print(
                                            "Screenshot capture/upload failed: $e",
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not capture map image: $e',
                                              ),
                                            ),
                                          );
                                        });
                                        await _submitEndDrive();
                                      } catch (e) {
                                        print("Error ending drive: $e");
                                        Get.snackbar(
                                          'Error',
                                          'Error ending drive: $e',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.colorsBlueButton,
                                elevation: 0,
                              ),
                              child: isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : Text(
                                      'End Test Drive & Submit Feedback Now',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Second Button - Submit Feedback Later
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      try {
                                        await _captureAndUploadImage().catchError((
                                          e,
                                        ) {
                                          print(
                                            "Screenshot capture/upload failed: $e",
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not capture map image: $e',
                                              ),
                                            ),
                                          );
                                        });
                                        await _submitEndDriveNavigate();
                                      } catch (e) {
                                        print("Error ending drive: $e");
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error ending drive: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.black,
                                elevation: 0,
                              ),
                              child: isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : Text(
                                      'End Test Drive & Submit Feedback Later',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitEndDrive() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      await _handleEndDrive(sendFeedback: false);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Submission failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _submitEndDriveNavigate() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      await _handleEndDriveNavigatesummary();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Submission failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _handleEndDrive({bool sendFeedback = false}) async {
    setState(() {
      isLoading = true;
    });

    try {
      // End any active pause
      if (isDrivePaused) {
        // _resumeDrive();
      }

      bool screenshotSuccess = false;
      try {
        await _captureAndUploadImage().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("Screenshot operation timed out");
            return;
          },
        );
        screenshotSuccess = true;
      } catch (e) {
        print("Screenshot process failed: $e");
      }

      await _endTestDrive(sendFeedback: sendFeedback);
      _cleanupResources();

      if (!screenshotSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Map image could not be captured, but drive data was saved successfully',
            ),
          ),
        );
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                Feedbackscreen(leadId: widget.leadId, eventId: widget.eventId),
          ),
        );
      }
    } catch (e) {
      print("Error in end drive process: $e");
      if (mounted) {
        Get.snackbar('Error', 'Error ending drive end: $e');
      }
      _cleanupResources();
    }
  }

  Future<void> _handleEndDriveNavigatesummary() async {
    setState(() {
      isLoading = true;
    });

    try {
      // End any active pause
      if (isDrivePaused) {
        // _resumeDrive();
      }

      bool screenshotSuccess = false;
      try {
        await _captureAndUploadImage().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print("Screenshot operation timed out");
            return;
          },
        );
        screenshotSuccess = true;
      } catch (e) {
        print("Screenshot process failed: $e");
      }

      await _endTestDrive(sendFeedback: true);
      _cleanupResources();

      if (!screenshotSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Map image could not be captured, but drive data was saved successfully',
            ),
          ),
        );
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TestdriveOverview(
              isFromCompletdTimeline: false,
              eventId: widget.eventId,
              leadId: widget.leadId,
              isFromTestdrive: true,
              isFromCompletedEventId: '',
              isFromCompletedLeadId: '',
            ),
          ),
        );
      }
    } catch (e) {
      print("Error in end drive process: $e");
      if (mounted) {
        Get.snackbar('Error', 'Error ending drive: $e');
      }
      _cleanupResources();
    }
  }

  // ✅ SIMPLIFIED: Only send data to API, no socket communication
  Future<void> _endTestDrive({bool sendFeedback = false}) async {
    try {
      // Reset distance accumulation when ending drive
      ImprovedDistanceCalculator.resetAccumulation();

      final uri = Uri.parse(
        'https://api.smartassistapp.in/api/events/${widget.eventId}/end-drive',
      );
      final url = uri.replace(
        queryParameters: {'send_feedback': sendFeedback.toString()},
      );

      final token = await Storage.getToken();

      // Calculate final duration ensuring pauses are accounted for
      int finalDuration = _calculateDuration();

      // Get current location for end coordinates
      LatLng? endLocation;
      if (_lastValidLocation != null) {
        endLocation = _lastValidLocation;
      } else if (userMarker != null) {
        endLocation = userMarker!.position;
      } else if (routePoints.isNotEmpty) {
        endLocation = routePoints.last;
      }

      final requestBody = {
        'distance': double.parse(
          totalDistance.toStringAsFixed(3),
        ), // 3 decimal precision
        'duration': finalDuration,
        'end_location': endLocation != null
            ? {
                'latitude': endLocation.latitude,
                'longitude': endLocation.longitude,
              }
            : {},
        'routePoints': routePoints
            .map(
              (point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              },
            )
            .toList(),
      };

      print(
        '📤 Final distance being sent: ${totalDistance.toStringAsFixed(3)} km',
      );
      // print('this is fullbody ${encoder.convert(requestBody)}');
      print('📤 Route points count: ${routePoints.length}');

      const encoder = JsonEncoder.withIndent('  ');
      print('📤 Sending JSON:\n${encoder.convert(requestBody)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 5));

      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Test drive ended successfully');
        print('Final distance: ${totalDistance.toStringAsFixed(3)} km');
        print('Duration: $finalDuration minutes');
        print('Total paused time: ${totalPausedDuration}s');
        print('Send feedback: $sendFeedback');
        _handleDriveEnded(totalDistance, finalDuration);
      } else {
        throw Exception('Failed to end drive: ${response.statusCode}');
      }
    } catch (e) {
      print('Error ending drive: $e');
      throw e;
    }
  }
  // Future<void> _endTestDrive({bool sendFeedback = false}) async {
  //   try {
  //     final uri = Uri.parse(
  //       'https://api.smartassistapp.in/api/events/${widget.eventId}/end-drive',
  //     );
  //     final url = uri.replace(
  //       queryParameters: {'send_feedback': sendFeedback.toString()},
  //     );

  //     final token = await Storage.getToken();

  //     // Calculate final duration ensuring pauses are accounted for
  //     int finalDuration = _calculateDuration();

  //     // ✅ FIXED: Get current location for end coordinates
  //     LatLng? endLocation;
  //     if (_lastValidLocation != null) {
  //       endLocation = _lastValidLocation;
  //     } else if (userMarker != null) {
  //       endLocation = userMarker!.position;
  //     } else if (routePoints.isNotEmpty) {
  //       endLocation = routePoints.last;
  //     }

  //     final requestBody = {
  //       'distance': totalDistance,
  //       'duration': finalDuration,
  //       'end_location': endLocation != null
  //           ? {
  //               'latitude': endLocation.latitude,
  //               'longitude': endLocation.longitude,
  //             }
  //           : {},
  //       'routePoints': routePoints
  //           .map(
  //             (point) => {
  //               'latitude': point.latitude,
  //               'longitude': point.longitude,
  //             },
  //           )
  //           .toList(),
  //     };

  //     print('📤 Sending JSON: ${json.encode(requestBody)}'); // compact one-line

  //     // If you want pretty-printed JSON (multiline & indented):
  //     const encoder = JsonEncoder.withIndent('  ');
  //     print('📤 Sending JSON (pretty):\n${encoder.convert(requestBody)}');

  //     final response = await http
  //         .post(
  //           url,
  //           headers: {
  //             'Content-Type': 'application/json',
  //             'Authorization': 'Bearer $token',
  //           },
  //           body: json.encode(requestBody),
  //         )
  //         .timeout(const Duration(seconds: 5));

  //     print('📩 Response status: ${response.statusCode}');
  //     print('📩 Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       print('Test drive ended successfully');
  //       print('Duration: $finalDuration minutes');
  //       print('Total paused time: ${totalPausedDuration}s');
  //       print('Send feedback: $sendFeedback');
  //       _handleDriveEnded(totalDistance, finalDuration);
  //     } else {
  //       throw Exception('Failed to end drive: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error ending drive: $e');
  //     throw e;
  //   }
  // }

  Future<void> _captureAndUploadImage() async {
    try {
      if (mapController == null) {
        print("Map controller is not initialized");
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      Uint8List? image;
      for (int i = 0; i < 3; i++) {
        try {
          image = await mapController.takeSnapshot();
          if (image != null) break;
          print('Snapshot attempt ${i + 1} failed, retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Snapshot attempt ${i + 1} error: $e');
        }
      }

      if (image == null) {
        print("Failed to capture map screenshot after retries");
        return;
      }

      print('Snapshot size: ${image.lengthInBytes} bytes');

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/map_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath)..writeAsBytesSync(image);

      final uploadSuccess = await _uploadImage(file);
      if (!uploadSuccess) {
        print("Image upload failed");
      } else {
        print("Image uploaded successfully");
      }
    } catch (e) {
      print("Error capturing/uploading map image: $e");
      rethrow;
    }
  }

  Future<bool> _uploadImage(File file) async {
    final url = Uri.parse(
      'https://api.smartassistapp.in/api/events/${widget.eventId}/upload-map',
    );
    final token = await Storage.getToken();

    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', 'png'),
          ),
        );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Image upload timed out");
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('Upload Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String? uploadedUrl;
        if (responseData['data'] is String) {
          uploadedUrl = responseData['data'];
        } else {
          uploadedUrl =
              responseData['data']?['map_img'] ?? responseData['map_img'];
        }
        print('Uploaded Map Image URL: $uploadedUrl');
        return true;
      } else {
        print('Failed to upload image: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting temporary file: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) >
            Duration(milliseconds: _exitTimeInMillis)) {
      _lastBackPressTime = now;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Exit Testdrive',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorsBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit from Testdrive?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.colorsBlue,
                            side: const BorderSide(color: AppColors.colorsBlue),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            try {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => BottomNavigation(),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              print("Navigation error: $e");
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BottomNavigation(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorsBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      );
      return false;
    }
    return true;
  }
}
