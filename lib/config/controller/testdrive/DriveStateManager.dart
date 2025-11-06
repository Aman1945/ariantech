import 'package:hive/hive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriveStateManager {
  static const String _boxName = 'drive_state';
  static const String _keyActiveDrive = 'active_drive';
  static const String _keyEventId = 'event_id';
  static const String _keyLeadId = 'lead_id';
  static const String _keyStartTime = 'start_time';
  static const String _keyTotalDistance = 'total_distance';
  static const String _keyRoutePoints = 'route_points';
  static const String _keyLastLat = 'last_lat';
  static const String _keyLastLng = 'last_lng';

  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> startDrive({
    required String eventId,
    required String leadId,
    required LatLng startLocation,
  }) async {
    await _box?.put(_keyActiveDrive, true);
    await _box?.put(_keyEventId, eventId);
    await _box?.put(_keyLeadId, leadId);
    await _box?.put(_keyStartTime, DateTime.now().toIso8601String());
    await _box?.put(_keyTotalDistance, 0.0);
    await _box?.put(_keyRoutePoints, []);
    await _box?.put(_keyLastLat, startLocation.latitude);
    await _box?.put(_keyLastLng, startLocation.longitude);
  }

  static Future<void> updateDriveState({
    required double totalDistance,
    required LatLng lastLocation,
    List<Map<String, double>>? routePoints,
  }) async {
    await _box?.put(_keyTotalDistance, totalDistance);
    await _box?.put(_keyLastLat, lastLocation.latitude);
    await _box?.put(_keyLastLng, lastLocation.longitude);

    if (routePoints != null) {
      await _box?.put(_keyRoutePoints, routePoints);
    }
  }

  static Future<void> endDrive() async {
    await _box?.put(_keyActiveDrive, false);
  }

  static Future<void> clearDriveState() async {
    await _box?.delete(_keyActiveDrive);
    await _box?.delete(_keyEventId);
    await _box?.delete(_keyLeadId);
    await _box?.delete(_keyStartTime);
    await _box?.delete(_keyTotalDistance);
    await _box?.delete(_keyRoutePoints);
    await _box?.delete(_keyLastLat);
    await _box?.delete(_keyLastLng);
  }

  static bool get hasActiveDrive =>
      _box?.get(_keyActiveDrive, defaultValue: false) ?? false;

  static String? get eventId => _box?.get(_keyEventId);

  static String? get leadId => _box?.get(_keyLeadId);

  static DateTime? get startTime {
    final timeStr = _box?.get(_keyStartTime);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static double get totalDistance =>
      _box?.get(_keyTotalDistance, defaultValue: 0.0) ?? 0.0;

  static LatLng? get lastLocation {
    final lat = _box?.get(_keyLastLat);
    final lng = _box?.get(_keyLastLng);
    return (lat != null && lng != null) ? LatLng(lat, lng) : null;
  }

  static List<LatLng> get routePoints {
    final points = _box?.get(_keyRoutePoints, defaultValue: []) as List?;
    if (points == null) return [];

    return points.map((p) {
      final map = p as Map;
      return LatLng(map['lat'] as double, map['lng'] as double);
    }).toList();
  }

  // static Future<void> addRoutePoint(LatLng point) async {
  //   final points = _box?.get(_keyRoutePoints, defaultValue: []) as List;
  //   points.add({'lat': point.latitude, 'lng': point.longitude});
  //   await _box?.put(_keyRoutePoints, points);
  // }
  static Future<void> addRoutePoint(LatLng point) async {
    // Safely get the list of route points or start a new list
    final existing = _box?.get(_keyRoutePoints);

    List points;
    if (existing is List) {
      points = List.from(existing); // make a mutable copy
    } else {
      points = []; // fallback if null or corrupted
    }

    points.add({'lat': point.latitude, 'lng': point.longitude});

    await _box?.put(_keyRoutePoints, points);
  }
}
