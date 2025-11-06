// utils/location_tracker.dart
import 'dart:async';
import 'dart:io'; 
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartassist/utils/testdrive/distance_calculation.dart';

class TestDriveLocationTracker {
  // Location tracking state
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  bool _isPaused = false;

  // Location data
  LatLng? _lastValidLocation;
  DateTime? _lastLocationTime;
  double _totalDistance = 0.0;
  List<LatLng> _routePoints = [];

  // Callbacks
  Function(LatLng, double)? _onLocationUpdate;
  Function(String)? _onError;
  Function(Map<String, dynamic>)? _onStateChange;

  // Initialize tracker with callbacks
  TestDriveLocationTracker({
    Function(LatLng, double)? onLocationUpdate,
    Function(String)? onError,
    Function(Map<String, dynamic>)? onStateChange,
  }) {
    _onLocationUpdate = onLocationUpdate;
    _onError = onError;
    _onStateChange = onStateChange;
  }

  // Start location tracking
  Future<bool> startTracking({LatLng? initialLocation}) async {
    if (_isTracking) {
      print('⚠️ Location tracking already active');
      return true;
    }

    try {
      // Get current location if not provided
      if (initialLocation == null) {
        Position position = await getCurrentLocation();
        initialLocation = LatLng(position.latitude, position.longitude);
      }

      // Initialize tracking state
      _lastValidLocation = initialLocation;
      _lastLocationTime = DateTime.now();
      _routePoints.add(initialLocation);

      // Start location stream
      _startLocationStream();
      _isTracking = true;

      print('✅ Location tracking started');
      _notifyStateChange();
      return true;
    } catch (e) {
      print('❌ Failed to start location tracking: $e');
      _onError?.call('Failed to start location tracking: $e');
      return false;
    }
  }

  // Stop location tracking
  void stopTracking() {
    if (!_isTracking) return;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;

    // Reset distance calculator
    TestDriveDistanceCalculator.resetAccumulation();

    print('🛑 Location tracking stopped');
    _notifyStateChange();
  }

  // Pause location tracking
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;

    _isPaused = true;
    print('⏸️ Location tracking paused');
    _notifyStateChange();
  }

  // Resume location tracking
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;

    _isPaused = false;
    print('▶️ Location tracking resumed');
    _notifyStateChange();
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
      return position;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Start the location stream
  void _startLocationStream() {
    LocationSettings locationSettings = _getLocationSettings();

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _processLocationUpdate,
          onError: (error) {
            print('❌ Location stream error: $error');
            _onError?.call('Location tracking error: $error');

            // Retry after error
            Future.delayed(Duration(seconds: 3), () {
              if (_isTracking) {
                print('🔄 Retrying location tracking...');
                _startLocationStream();
              }
            });
          },
        );
  }

  // Get platform-specific location settings
  LocationSettings _getLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // No distance filter - let algorithm handle it
        timeLimit: Duration(seconds: 10),
        forceLocationManager: false,
      );
    } else {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        timeLimit: Duration(seconds: 8),
      );
    }
  }

  // Process location updates
  void _processLocationUpdate(Position position) {
    if (!_isTracking || _isPaused) return;

    final LatLng newLocation = LatLng(position.latitude, position.longitude);

    // Validate location using distance calculator
    DistanceValidationResult validationResult =
        TestDriveDistanceCalculator.validateLocationUpdate(
          position,
          _lastValidLocation,
          _lastLocationTime,
        );

    // Log validation result
    if (validationResult.isStationary) {
      Map<String, dynamic> state =
          TestDriveDistanceCalculator.getCurrentState();
      print('🛑 ${validationResult.reason} (${state['stationaryDuration']}s)');
    } else {
      print('📍 Location validation: ${validationResult.reason}');
    }

    // Process valid movements
    if (validationResult.isValid && !validationResult.isStationary) {
      _handleValidMovement(newLocation, validationResult);
    } else if (!validationResult.isStationary) {
      _handleAccumulatedMovement(newLocation, validationResult);
    }

    // Always notify location update for UI purposes
    _onLocationUpdate?.call(newLocation, _totalDistance);
    _notifyStateChange();
  }

  // Handle valid movement
  void _handleValidMovement(
    LatLng newLocation,
    DistanceValidationResult result,
  ) {
    double distanceKm = result.distanceKm;
    _totalDistance += distanceKm;
    _routePoints.add(newLocation);

    _lastValidLocation = newLocation;
    _lastLocationTime = DateTime.now();

    print(
      '✅ Distance added: ${(distanceKm * 1000).toStringAsFixed(1)}m, Total: ${_totalDistance.toStringAsFixed(3)} km',
    );
  }

  // Handle accumulated small movements
  void _handleAccumulatedMovement(
    LatLng newLocation,
    DistanceValidationResult result,
  ) {
    if (result.accumulatedDistance != null &&
        result.accumulatedDistance! >= 5.0) {
      DistanceValidationResult accumulatedResult =
          TestDriveDistanceCalculator.checkAccumulatedMovements(
            _lastValidLocation,
          );

      if (accumulatedResult.isValid) {
        double distanceKm = accumulatedResult.distanceKm;
        _totalDistance += distanceKm;
        _routePoints.add(newLocation);

        _lastValidLocation = newLocation;
        _lastLocationTime = DateTime.now();

        print(
          '✅ Accumulated distance added: ${(distanceKm * 1000).toStringAsFixed(1)}m, Total: ${_totalDistance.toStringAsFixed(3)} km',
        );
      }
    }
  }

  // Notify state change
  void _notifyStateChange() {
    Map<String, dynamic> calculatorState =
        TestDriveDistanceCalculator.getCurrentState();

    _onStateChange?.call({
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'totalDistance': _totalDistance,
      'routePointsCount': _routePoints.length,
      'lastLocation': _lastValidLocation != null
          ? {
              'latitude': _lastValidLocation!.latitude,
              'longitude': _lastValidLocation!.longitude,
            }
          : null,
      ...calculatorState,
    });
  }

  // Get marker color based on validation state
  BitmapDescriptor getMarkerColor(Position position) {
    if (!_isTracking) return BitmapDescriptor.defaultMarker;

    Map<String, dynamic> state = TestDriveDistanceCalculator.getCurrentState();
    bool isStationary = state['isStationary'] ?? false;

    if (isStationary) {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      ); // Red for stationary
    } else if (position.accuracy <= 25.0) {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ); // Blue for valid
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      ); // Orange for filtered
    }
  }

  // Get marker info window text
  InfoWindow getMarkerInfoWindow(Position position) {
    Map<String, dynamic> state = TestDriveDistanceCalculator.getCurrentState();
    bool isStationary = state['isStationary'] ?? false;

    return InfoWindow(
      title: isStationary ? 'Stationary (GPS Protected)' : 'Current Location',
      snippet:
          'Accuracy: ${position.accuracy.toStringAsFixed(1)}m | ${isStationary ? 'Stopped' : 'Moving'}',
    );
  }

  // Format distance for display
  String get formattedDistance =>
      TestDriveDistanceCalculator.formatDistance(_totalDistance);

  // Getters
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  double get totalDistance => _totalDistance;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  LatLng? get lastValidLocation => _lastValidLocation;
  DateTime? get lastLocationTime => _lastLocationTime;

  // Get current state for debugging
  Map<String, dynamic> get debugState {
    return {
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'totalDistance': _totalDistance,
      'routePointsCount': _routePoints.length,
      'hasLastLocation': _lastValidLocation != null,
      ...TestDriveDistanceCalculator.getCurrentState(),
    };
  }

  // Cleanup
  void dispose() {
    stopTracking();
    _onLocationUpdate = null;
    _onError = null;
    _onStateChange = null;
  }
}
