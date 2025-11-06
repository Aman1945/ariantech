// import 'dart:async';
// import 'dart:isolate';
// import 'dart:ui';
// import 'package:background_locator_2/location_dto.dart';
// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:latlong2/latlong.dart' as latlong;

// class LocationCallbackHandler {
//   static const String isolateName = 'LocatorIsolate';
//   static const String _boxName = 'drive_state';
//   static const String _pointsBoxName = 'location_points';

//   static Box? _stateBox;
//   static Box? _pointsBox;

//   @pragma('vm:entry-point')
//   static Future<void> initCallback(Map<dynamic, dynamic> params) async {
//     print('🟢 Background locator initialized');

//     // Initialize Hive in background isolate
//     await Hive.initFlutter();
//     _stateBox = await Hive.openBox(_boxName);
//     _pointsBox = await Hive.openBox(_pointsBoxName);
//   }

//   @pragma('vm:entry-point')
//   static Future<void> disposeCallback() async {
//     print('🔴 Background locator disposed');
//     await _stateBox?.close();
//     await _pointsBox?.close();
//   }

//   @pragma('vm:entry-point')
//   static Future<void> callback(LocationDto locationDto) async {
//     print(
//       '📍 Background location: ${locationDto.latitude}, ${locationDto.longitude}',
//     );

//     if (_stateBox == null || _pointsBox == null) {
//       await initCallback({});
//     }

//     try {
//       // Check if drive is active
//       final isActive =
//           _stateBox?.get('active_drive', defaultValue: false) ?? false;
//       if (!isActive) {
//         print('⚠️ No active drive, skipping location');
//         return;
//       }

//       // Validate accuracy
//       if (locationDto.accuracy > 20.0) {
//         print('⚠️ Poor accuracy: ${locationDto.accuracy}m');
//         return;
//       }

//       // Get last location
//       final lastLat = _stateBox?.get('last_lat');
//       final lastLng = _stateBox?.get('last_lng');

//       double distance = 0.0;
//       if (lastLat != null && lastLng != null) {
//         // Calculate distance using latlong2
//         final lastPoint = latlong.LatLng(lastLat, lastLng);
//         final currentPoint = latlong.LatLng(
//           locationDto.latitude,
//           locationDto.longitude,
//         );

//         const latlong.Distance distanceCalc = latlong.Distance();
//         distance = distanceCalc.as(
//           latlong.LengthUnit.Meter,
//           lastPoint,
//           currentPoint,
//         );

//         // Ignore if movement is too small
//         if (distance < 2.0) {
//           print('⚠️ Movement too small: ${distance.toStringAsFixed(1)}m');
//           return;
//         }
//       }

//       // Update total distance
//       final currentTotal =
//           _stateBox?.get('total_distance', defaultValue: 0.0) ?? 0.0;
//       final newTotal = currentTotal + (distance / 1000.0); // Convert to km

//       // Save location point
//       final point = {
//         'lat': locationDto.latitude,
//         'lng': locationDto.longitude,
//         'timestamp': DateTime.now().toIso8601String(),
//         'accuracy': locationDto.accuracy,
//       };

//       // Get current route points
//       final routePoints =
//           _stateBox?.get('route_points', defaultValue: []) as List;
//       routePoints.add(point);

//       // Update state
//       await _stateBox?.put('last_lat', locationDto.latitude);
//       await _stateBox?.put('last_lng', locationDto.longitude);
//       await _stateBox?.put('total_distance', newTotal);
//       await _stateBox?.put('route_points', routePoints);
//       await _stateBox?.put('last_update', DateTime.now().toIso8601String());

//       // Store in separate points box for reliability
//       await _pointsBox?.add(point);

//       print(
//         '✅ Saved: ${distance.toStringAsFixed(1)}m, Total: ${newTotal.toStringAsFixed(3)}km',
//       );

//       // Send to UI if available
//       _sendToUI(locationDto, newTotal, routePoints.length);
//     } catch (e) {
//       print('❌ Background callback error: $e');
//     }
//   }

//   @pragma('vm:entry-point')
//   static Future<void> notificationCallback() async {
//     print('🔔 Notification callback triggered');
//   }

//   static void _sendToUI(
//     LocationDto location,
//     double totalDistance,
//     int pointsCount,
//   ) { 
//     final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
//     if (send != null) {
//       send.send({
//         'latitude': location.latitude,
//         'longitude': location.longitude,
//         'accuracy': location.accuracy,
//         'totalDistance': totalDistance,
//         'pointsCount': pointsCount,
//         'timestamp': DateTime.now().toIso8601String(),
//       });
//     }
//   }
// }
