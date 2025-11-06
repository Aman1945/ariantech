// utils/distance_calculator.dart
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TestDriveDistanceCalculator {
  // Stationary detection constants
  static const double STATIONARY_RADIUS =
      15.0; // 15 meters radius for stationary detection
  static const int STATIONARY_TIME_THRESHOLD =
      30; // 30 seconds to confirm stationary
  static const int MIN_MOVEMENT_COUNT =
      3; // Need 3 consistent movements to exit stationary
  static const double SIGNIFICANT_MOVEMENT =
      10.0; // 10 meters to break stationary state

  // Enhanced constants
  static const double MIN_ACCURACY_THRESHOLD = 25.0; // 25m max GPS accuracy
  static const double MAX_SPEED_THRESHOLD =
      120.0; // 120 km/h max realistic speed
  static const double MIN_MOVEMENT_THRESHOLD = 5.0; // 5m minimum movement
  static const int MAX_LOCATION_AGE_SECONDS = 15; // 15 seconds max age

  // Stationary tracking variables
  static LatLng? _stationaryCenter;
  static DateTime? _stationaryStartTime;
  static bool _isStationary = false;
  static int _movementAttempts = 0;
  static List<LatLng> _recentPositions = [];
  static const int MAX_RECENT_POSITIONS = 10;

  // Accumulated small movements (only when not stationary)
  static double _accumulatedSmallMovements = 0.0;

  // Calculate distance using Haversine formula
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

  // Check if position is within stationary radius
  static bool _isWithinStationaryRadius(
    LatLng position,
    LatLng center,
    double radius,
  ) {
    double distance = calculateDistanceHaversine(position, center);
    return distance <= radius;
  }

  // Update stationary detection
  static void _updateStationaryDetection(LatLng currentPosition) {
    DateTime now = DateTime.now();

    // Add to recent positions
    _recentPositions.add(currentPosition);
    if (_recentPositions.length > MAX_RECENT_POSITIONS) {
      _recentPositions.removeAt(0);
    }

    if (_isStationary) {
      // Check if we're still within stationary radius
      if (_stationaryCenter != null &&
          _isWithinStationaryRadius(
            currentPosition,
            _stationaryCenter!,
            STATIONARY_RADIUS,
          )) {
        // Still stationary - reset movement attempts
        _movementAttempts = 0;
      } else {
        // Potential movement out of stationary zone
        _movementAttempts++;

        // Need consistent movements to exit stationary state
        if (_movementAttempts >= MIN_MOVEMENT_COUNT) {
          print('🚶 Exiting stationary state - consistent movement detected');
          _isStationary = false;
          _stationaryCenter = null;
          _stationaryStartTime = null;
          _movementAttempts = 0;
          _accumulatedSmallMovements = 0.0; // Reset accumulation
        }
      }
    } else {
      // Not currently stationary - check if we should enter stationary state
      if (_recentPositions.length >= 5) {
        // Calculate center of recent positions
        double avgLat =
            _recentPositions.map((p) => p.latitude).reduce((a, b) => a + b) /
            _recentPositions.length;
        double avgLng =
            _recentPositions.map((p) => p.longitude).reduce((a, b) => a + b) /
            _recentPositions.length;
        LatLng center = LatLng(avgLat, avgLng);

        // Check if all recent positions are within stationary radius
        bool allWithinRadius = _recentPositions.every(
          (pos) => _isWithinStationaryRadius(pos, center, STATIONARY_RADIUS),
        );

        if (allWithinRadius) {
          if (_stationaryStartTime == null) {
            _stationaryStartTime = now;
            _stationaryCenter = center;
          } else {
            // Check if we've been stationary long enough
            int stationaryDuration = now
                .difference(_stationaryStartTime!)
                .inSeconds;
            if (stationaryDuration >= STATIONARY_TIME_THRESHOLD) {
              print(
                '🛑 Entering stationary state - GPS drift protection active',
              );
              _isStationary = true;
              _accumulatedSmallMovements =
                  0.0; // Clear any accumulated distance
            }
          }
        } else {
          // Reset stationary detection if positions spread out
          _stationaryStartTime = null;
          _stationaryCenter = null;
        }
      }
    }
  }

  // Enhanced validation with stationary detection
  static DistanceValidationResult validateLocationUpdate(
    Position position,
    LatLng? lastLocation,
    DateTime? lastTime,
  ) {
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    // Update stationary detection first
    _updateStationaryDetection(currentLocation);

    // If we're in stationary mode, reject all movements
    if (_isStationary) {
      return DistanceValidationResult(
        isValid: false,
        isStationary: true,
        reason: 'Stationary mode - GPS drift filtered',
        distanceMeters: 0,
      );
    }

    // Check GPS accuracy
    if (position.accuracy > MIN_ACCURACY_THRESHOLD) {
      return DistanceValidationResult(
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
        return DistanceValidationResult(
          isValid: false,
          reason: 'Location too old: ${locationAge}s',
          distanceMeters: 0,
        );
      }
    }

    // First location is always valid
    if (lastLocation == null || lastTime == null) {
      return DistanceValidationResult(
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
        return DistanceValidationResult(
          isValid: false,
          reason: 'Unrealistic speed: ${speedKmh.toStringAsFixed(1)} km/h',
          distanceMeters: distanceMeters,
        );
      }
    }

    // Check minimum movement threshold
    if (distanceMeters < MIN_MOVEMENT_THRESHOLD) {
      // Only accumulate if we're not in a potentially stationary state
      if (_stationaryStartTime == null) {
        _accumulatedSmallMovements += distanceMeters;

        return DistanceValidationResult(
          isValid: false,
          reason:
              'Small movement accumulated: ${distanceMeters.toStringAsFixed(1)}m (total: ${_accumulatedSmallMovements.toStringAsFixed(1)}m)',
          distanceMeters: distanceMeters,
          accumulatedDistance: _accumulatedSmallMovements,
        );
      } else {
        return DistanceValidationResult(
          isValid: false,
          reason: 'Small movement ignored - potential stationary state',
          distanceMeters: 0,
        );
      }
    }

    // Valid significant movement - add any accumulated distance
    double totalDistance = distanceMeters + _accumulatedSmallMovements;
    _accumulatedSmallMovements = 0.0; // Reset accumulation

    return DistanceValidationResult(
      isValid: true,
      reason: 'Valid movement: ${distanceMeters.toStringAsFixed(1)}m',
      distanceMeters: totalDistance,
    );
  }

  // Check if we should release accumulated movements (stricter conditions)
  static DistanceValidationResult checkAccumulatedMovements(
    LatLng? lastValidLocation,
  ) {
    // Only release if we have significant accumulated distance and we're not stationary
    if (_accumulatedSmallMovements >= MIN_MOVEMENT_THRESHOLD &&
        lastValidLocation != null &&
        !_isStationary &&
        _stationaryStartTime == null) {
      double totalAccumulated = _accumulatedSmallMovements;
      _accumulatedSmallMovements = 0.0;

      return DistanceValidationResult(
        isValid: true,
        reason:
            'Accumulated movements released: ${totalAccumulated.toStringAsFixed(1)}m',
        distanceMeters: totalAccumulated,
      );
    }

    return DistanceValidationResult(
      isValid: false,
      reason: 'No significant accumulated movements to release',
      distanceMeters: 0,
    );
  }

  // Reset all tracking
  static void resetAccumulation() {
    _accumulatedSmallMovements = 0.0;
    _stationaryCenter = null;
    _stationaryStartTime = null;
    _isStationary = false;
    _movementAttempts = 0;
    _recentPositions.clear();
  }

  // Get current state info
  static Map<String, dynamic> getCurrentState() {
    return {
      'isStationary': _isStationary,
      'accumulatedDistance': _accumulatedSmallMovements,
      'stationaryCenter': _stationaryCenter != null
          ? {
              'lat': _stationaryCenter!.latitude,
              'lng': _stationaryCenter!.longitude,
            }
          : null,
      'stationaryDuration': _stationaryStartTime != null
          ? DateTime.now().difference(_stationaryStartTime!).inSeconds
          : 0,
      'recentPositionsCount': _recentPositions.length,
    };
  }

  // Format distance for display
  static String formatDistance(double distance) {
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
}

// Result class for distance validation
class DistanceValidationResult {
  final bool isValid;
  final bool isStationary;
  final String reason;
  final double distanceMeters;
  final double? accumulatedDistance;

  const DistanceValidationResult({
    required this.isValid,
    this.isStationary = false,
    required this.reason,
    required this.distanceMeters,
    this.accumulatedDistance,
  });

  double get distanceKm => distanceMeters / 1000.0;
}
