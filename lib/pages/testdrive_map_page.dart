// testdrive_map_page.dart - CLEANED VERSION
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/controller/testdrive/DriveStateManager.dart';
import 'package:smartassist/config/controller/testdrive/background_services.dart';
import 'package:smartassist/config/controller/testdrive/local_notification.dart';
import 'package:smartassist/config/controller/testdrive/route_calculation.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/utils/testdrive_notification_helper.dart';
import 'package:smartassist/widgets/feedback.dart';
import 'package:smartassist/widgets/internet_exception.dart';
import 'package:smartassist/widgets/testdrive_summary.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class TestdriveMapPage extends StatefulWidget {
  final String eventId;
  final String leadId;
  final bool isResuming;

  const TestdriveMapPage({
    super.key,
    required this.eventId,
    required this.leadId,
    this.isResuming = false,
  });

  @override
  State<TestdriveMapPage> createState() => _TestdriveMapPageState();
}

class _TestdriveMapPageState extends State<TestdriveMapPage>
    with WidgetsBindingObserver {
  late GoogleMapController mapController;
  bool _notificationShown = false;
  Marker? startMarker;
  Marker? userMarker;
  Marker? endMarker;
  late Polyline routePolyline;
  List<LatLng> routePoints = [];
  bool hasInternet = true;

  bool isDriveEnded = false;
  bool isLoading = true;
  String error = '';
  double totalDistance = 0.0;

  DateTime? driveStartTime;
  DateTime? driveEndTime;

  bool isSubmittingNow = false;
  bool isSubmittingLater = false;

  StreamSubscription<Position>? positionStreamSubscription;
  bool isSubmitting = false;
  LatLng? _lastValidLocation;
  DateTime? _lastLocationTime;
  double _totalDistanceAccumulator = 0.0;

  static const double MIN_ACCURACY_THRESHOLD = 25.0;
  static const double MAX_SPEED_THRESHOLD = 150.0;
  static const double MIN_MOVEMENT_THRESHOLD = 3.0;

  // Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize background service
    BackgroundLocationService().initialize();

    // Initialize connectivity checking
    _checkInternetConnectivity();
    _initConnectivityListener();

    if (widget.isResuming) {
      _resumeDrive();
    } else {
      driveStartTime = DateTime.now();
      totalDistance = 0.0;
      _determinePosition();
    }

    routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: routePoints,
      color: AppColors.colorsBlue,
      width: 5,
    );

    // _startNotificationUpdates();
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        hasInternet = !connectivityResult.contains(ConnectivityResult.none);
      });
    } catch (e) {
      print('Error checking connectivity: $e');
      setState(() {
        hasInternet = true; // Assume internet if check fails
      });
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        setState(() {
          hasInternet = !results.contains(ConnectivityResult.none);
        });

        if (!hasInternet) {
          print('⚠️ Internet connection lost');
          showErrorMessageGetx(
            message: 'Please check your internet connection',
          );
        } else {
          print('✅ Internet connection restored');
          // Optionally show a success message
          showSuccessMessage(context, message: 'Internet connection restored');
        }
      },
      onError: (error) {
        print('Connectivity listener error: $error');
      },
    );
  }

  void _resumeDrive() {
    driveStartTime = DriveStateManager.startTime ?? DateTime.now();
    totalDistance = DriveStateManager.totalDistance;
    _totalDistanceAccumulator = totalDistance;
    routePoints = DriveStateManager.routePoints;
    _lastValidLocation = DriveStateManager.lastLocation;
    _lastLocationTime = DateTime.now();

    setState(() {
      isLoading = false;
      if (_lastValidLocation != null) {
        userMarker = Marker(
          markerId: const MarkerId('user'),
          position: _lastValidLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        );
        startMarker = Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          infoWindow: const InfoWindow(title: 'Start'),
        );
      }
    });

    _startLocationTracking();
  }

  // void _startNotificationUpdates() {
  //   _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
  //     if (!isDriveEnded) {
  //       final duration = _calculateDuration();
  //       LocalNotificationService().showDriveTrackingNotification(
  //         distance: totalDistance,
  //         duration: duration,
  //         isSilentUpdate: _notificationShown,
  //       );
  //     }
  //   });
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 App lifecycle state: $state');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // Save state when going to background
      if (_lastValidLocation != null) {
        DriveStateManager.updateDriveState(
          totalDistance: totalDistance,
          lastLocation: _lastValidLocation!,
          routePoints: routePoints
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        );
      }
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          error = 'Location permissions are denied';
          isLoading = false;
        });
        _showPermissionDeniedDialog();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error = 'Location permissions are permanently denied';
          isLoading = false;
        });
        _showPermanentlyDeniedDialog();
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          error = 'Location services are disabled';
          isLoading = false;
        });
        _showLocationServiceDialog();
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      print('❌ Error in _determinePosition: $e');
      setState(() {
        error = 'Error setting up location: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Getting current location...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final LatLng currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        startMarker = Marker(
          markerId: const MarkerId('start'),
          position: currentLocation,
          infoWindow: const InfoWindow(title: 'Start'),
        );

        userMarker = Marker(
          markerId: const MarkerId('user'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        );

        routePoints.add(currentLocation);
        _lastValidLocation = currentLocation;
        _lastLocationTime = DateTime.now();
        isLoading = false;
      });

      // Save initial state
      await DriveStateManager.startDrive(
        eventId: widget.eventId,
        leadId: widget.leadId,
        startLocation: currentLocation,
      );

      // Start API tracking
      await _startTestDrive(currentLocation);
    } catch (e) {
      print('❌ Error getting location: $e');
      setState(() {
        error = 'Failed to get location: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _startTestDrive(LatLng currentLocation) async {
    try {
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/events/${widget.eventId}/start-drive',
      );
      final token = await Storage.getToken();

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'start_location': {
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
              },
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Test drive started');
        _startLocationTracking();
      } else {
        throw Exception('Failed to start: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error starting drive: $e');
      if (mounted) {
        setState(() => error = 'Error starting: $e');
      }
    }
  }

  void _startLocationTracking() {
    // Start background service for persistent tracking
    BackgroundLocationService().startTracking();

    LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: const Duration(seconds: 10),
        forceLocationManager: false,
      );
    } else {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        timeLimit: const Duration(seconds: 8),
      );
    }

    positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _processLocationUpdate,
          onError: (error) {
            print('❌ Location stream error: $error');
            Future.delayed(const Duration(seconds: 3), () {
              if (!isDriveEnded && mounted) {
                _startLocationTracking();
              }
            });
          },
        );

    LocalNotificationService().showDriveTrackingNotification(
      isSilentUpdate: true,
    );
  }

  void _processLocationUpdate(Position position) {
    if (!mounted || isDriveEnded) return;

    final LatLng newLocation = LatLng(position.latitude, position.longitude);

    // Basic validation
    if (position.accuracy > MIN_ACCURACY_THRESHOLD) {
      print('⚠️ Poor accuracy: ${position.accuracy}m');
      return;
    }

    // Update visual marker
    setState(() {
      userMarker = Marker(
        markerId: const MarkerId('user'),
        position: newLocation,
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: 'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });

    // Calculate distance
    if (_lastValidLocation != null) {
      double distance = Geolocator.distanceBetween(
        _lastValidLocation!.latitude,
        _lastValidLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      if (distance >= MIN_MOVEMENT_THRESHOLD) {
        setState(() {
          _totalDistanceAccumulator += distance / 1000.0; // to km
          totalDistance = _totalDistanceAccumulator;
          routePoints.add(newLocation);
        });

        _lastValidLocation = newLocation;
        _lastLocationTime = DateTime.now();

        // Update Hive state
        DriveStateManager.updateDriveState(
          totalDistance: totalDistance,
          lastLocation: newLocation,
        );
        DriveStateManager.addRoutePoint(newLocation);

        // Update camera
        if (mapController != null) {
          mapController.animateCamera(CameraUpdate.newLatLng(newLocation));
        }

        print(
          '✅ Distance: ${distance.toStringAsFixed(1)}m, Total: ${totalDistance.toStringAsFixed(3)}km',
        );
      }
    } else {
      _lastValidLocation = newLocation;
      _lastLocationTime = DateTime.now();
    }
  }

  int _calculateDuration() {
    if (driveStartTime == null) return 0;
    final endTime = driveEndTime ?? DateTime.now();
    return endTime.difference(driveStartTime!).inMinutes;
  }

  String _formatDistance(double distance) {
    if (distance < 0.001) return '0 m';
    if (distance < 0.1) return '${(distance * 1000).round()} m';
    if (distance < 1.0) return '${distance.toStringAsFixed(2)} km';
    return '${distance.toStringAsFixed(2)} km';
  }

  Future<void> _submitEndDrive({required bool showFeedback}) async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      await _captureAndUploadImage().catchError((e) {
        print("Screenshot failed: $e");
      });

      await _endTestDrive();
      await _cleanupResources();

      if (mounted) {
        await DriveStateManager.endDrive();
        await Future.delayed(const Duration(milliseconds: 300));

        if (showFeedback) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Feedbackscreen(
                leadId: widget.leadId,
                eventId: widget.eventId,
              ),
            ),
          );
        } else {
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
      }
    } catch (e) {
      print("Error ending drive: $e");
      if (mounted) {
        Get.snackbar('Error', 'Error ending drive: $e');
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _endTestDrive() async {
    try {
      Map<String, dynamic>? routeData;

      if (routePoints.length > 1) {
        final routeCalc = RouteCalculator();
        routeData = await routeCalc.calculateRouteFromPoints(routePoints);
      }

      final uri = Uri.parse(
        'https://api.smartassistapp.in/api/events/${widget.eventId}/end-drive',
      );
      final token = await Storage.getToken();

      final duration = _calculateDuration();
      LatLng? endLocation = _lastValidLocation ?? routePoints.lastOrNull;
      final body = {
        'distance': routeData?['distance'] ?? 0.0,
        // 'duration': routeData?['duration'] ?? 0.0,
        'duration': duration,
        'end_location': endLocation != null
            ? {
                'latitude': endLocation.latitude,
                'longitude': endLocation.longitude,
              }
            : {},
        // 'routePoints': routePoints
        //     .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
        //     .toList(),
        'directions': {
          'coordinates': routePoints
              .map((p) => [p.longitude, p.latitude])
              .toList(),
        },
      };

      print('Request body: ${json.encode(body)}');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('body end : ${response.body}');

      if (response.statusCode == 200) {
        print(
          '✅ Drive ended: ${routeData?['distance'] ?? 0.0} km, ${routeData?['duration'] ?? 0.0} mins',
        );
        setState(() {
          isDriveEnded = true;
          driveEndTime = DateTime.now();

          if (endLocation != null) {
            endMarker = Marker(
              markerId: const MarkerId('end'),
              position: endLocation,
              infoWindow: const InfoWindow(title: 'End'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            );
          }
        });
      } else {
        throw Exception('Failed to end drive: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error ending drive: $e');
      rethrow;
    }
  }

  Future<void> _captureAndUploadImage() async {
    try {
      if (mapController == null) return;

      await Future.delayed(const Duration(milliseconds: 1000));

      Uint8List? image;
      for (int i = 0; i < 3; i++) {
        try {
          image = await mapController.takeSnapshot();
          if (image != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Snapshot attempt ${i + 1} error: $e');
        }
      }

      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/map_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath)..writeAsBytesSync(image);

      await _uploadImage(file);
      await file.delete();
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<bool> _uploadImage(File file) async {
    try {
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/events/${widget.eventId}/upload-map',
      );
      final token = await Storage.getToken();

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', 'png'),
          ),
        );

      var response = await request.send().timeout(const Duration(seconds: 15));
      final responseBody = await http.Response.fromStream(response);

      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }

  Future<void> _cleanupResources() async {
    print('🧹 Starting cleanup...');

    try {
      // 1. Cancel position stream first
      await positionStreamSubscription?.cancel();
      positionStreamSubscription = null;
      print('✅ Position stream cancelled');

      // 2. Stop background service (this will trigger notification removal)
      await BackgroundLocationService().stopTracking();
      print('✅ Background service stopped');

      // 3. Cancel local notification service (Flutter level)
      await LocalNotificationService().clearAllTestDriveNotifications();
      print('✅ Flutter notifications cancelled');

      // 4. Force clear using native Android (most reliable - THE KEY FIX!)
      if (Platform.isAndroid) {
        await NotificationHelper.clearAllNotifications();
        print('✅ Native Android notifications cleared');
      }

      // 5. Wait to ensure cleanup completes
      await Future.delayed(const Duration(milliseconds: 800));

      // 6. Clear drive state
      await DriveStateManager.clearDriveState();
      print('✅ Drive state cleared');

      print('✅✅✅ All resources cleaned up successfully');
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  // void _cleanupResources() {
  //   // _notificationTimer?.cancel();
  //   LocalNotificationService().cancelDriveNotification();
  //   BackgroundLocationService().stopTracking();
  //   positionStreamSubscription?.cancel();
  //   DriveStateManager.clearDriveState();
  // }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location access to track your test drive.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _determinePosition();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Please enable location permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'Location Services Disabled',
          style: AppFont.appbarfontblack(context),
        ),
        content: Text(
          'Please enable location services.',
          style: AppFont.dropDowmLabel(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigator.of(context).pushAndRemoveUntil(
              //   MaterialPageRoute(builder: (context) => BottomNavigation()),
              //   (route) => false,
              // );
            },
            child: Text('Cancel', style: AppFont.dropDowmLabel(context)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.colorsBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('Open Settings'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if (!hasInternet) {
    //   return InternetException(
    //     onRetry: () async {
    //       await _checkInternetConnectivity();
    //       if (hasInternet) {
    //         // Retry initialization if internet is back
    //         if (widget.isResuming) {
    //           _resumeDrive();
    //         } else {
    //           _determinePosition();
    //         }
    //       }
    //     },
    //   );
    // }
    return WillPopScope(
      onWillPop: () async {
        if (isDriveEnded) return true;

        _showExitDialog();
        return false;
      },
      child: Scaffold(
        body: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your location...'),
                  ],
                ),
              )
            : error.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                        textAlign: TextAlign.center,
                        style: AppFont.dropDowmLabel(context),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorsBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _determinePosition,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('Try Again'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: startMarker?.position ?? const LatLng(0, 0),
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    markers: {
                      if (startMarker != null) startMarker!,
                      if (userMarker != null) userMarker!,
                      if (endMarker != null) endMarker!,
                    },
                    polylines: {routePolyline},
                  ),
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
                        child: Row(
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
                      ),
                    ),
                  if (!isDriveEnded)
                    Positioned(
                      bottom: 40,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // _buildButton(
                          //   'End Test Drive & Submit Feedback Now',
                          //   AppColors.colorsBlueButton,
                          //   () => _submitEndDrive(showFeedback: true),
                          // ),
                          // const SizedBox(height: 12),
                          // _buildButton(
                          //   'End Test Drive & Submit Feedback Later',
                          //   Colors.black,
                          //   () => _submitEndDrive(showFeedback: false),
                          // ),
                          _buildButton(
                            'End Test Drive & Submit Feedback Now',
                            AppColors.colorsBlueButton,
                            isSubmittingNow,
                            () async {
                              setState(() => isSubmittingNow = true);
                              await _submitEndDrive(showFeedback: true);
                              setState(() => isSubmittingNow = false);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildButton(
                            'End Test Drive & Submit Feedback Later',
                            Colors.black,
                            isSubmittingLater,
                            () async {
                              setState(() => isSubmittingLater = true);
                              await _submitEndDrive(showFeedback: false);
                              setState(() => isSubmittingLater = false);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color color,
    bool isLoading,
    VoidCallback onPressed,
  ) {
    return Container(
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
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
  // Widget _buildButton(String text, Color color, VoidCallback onPressed) {
  //   return Container(
  //     width: double.infinity,
  //     height: 56,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.2),
  //           blurRadius: 12,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: ElevatedButton(
  //       onPressed: isSubmitting ? null : onPressed,
  //       style: ElevatedButton.styleFrom(
  //         padding: EdgeInsets.zero,
  //         backgroundColor: color,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         elevation: 0,
  //       ),
  //       child: isSubmitting
  //           ? const CircularProgressIndicator(
  //               color: Colors.white,
  //               strokeWidth: 2,
  //             )
  //           : Text(
  //               text,
  //               style: GoogleFonts.poppins(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w500,
  //                 color: Colors.white,
  //               ),
  //             ),
  //     ),
  //   );
  // }

  void _showExitDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(
                'Exit Test Drive',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to exit?',
                style: AppFont.dropDowmLabel(context),
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

                    // Expanded(
                    //   child: OutlinedButton(
                    //     onPressed: () => Navigator.pop(context),
                    //     child: const Text('Cancel'),
                    //   ),
                    // ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorsBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _cleanupResources();
                          // DriveStateManager.clearDriveState();
                          // if (mounted) {
                          //   Navigator.pushAndRemoveUntil(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (_) => BottomNavigation(),
                          //     ),
                          //     (route) => false,
                          //   );
                          // }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BottomNavigation(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text('Exit'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
