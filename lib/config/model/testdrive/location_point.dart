import 'package:hive/hive.dart';

part 'location_point.g.dart';

@HiveType(typeId: 0)
class LocationPoint extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double? accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
  };
}

@HiveType(typeId: 1)
class DriveSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  final List<LocationPoint> points;

  @HiveField(4)
  double? totalDistance;

  @HiveField(5)
  double? duration;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  bool isUploaded;

  @HiveField(8)
  String? eventId;

  DriveSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.points,
    this.totalDistance,
    this.duration,
    this.isActive = true,
    this.isUploaded = false,
    this.eventId,
  });
}
