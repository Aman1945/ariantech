import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:smartassist/utils/token_manager.dart';

class RouteCalculator {
  static const String api =
      'https://services.smartassistapp.in/service/td/generate-route';

  Future<Map<String, dynamic>> calculateRouteFromPoints(
    List<LatLng> points,
  ) async {
    final tdTokenKey = await TokenManager.getTdToken();

    if (points.isEmpty) throw Exception('No points provided');
    if (points.length == 1) {
      return {'points': points, 'distance': 0.0, 'duration': 0.0};
    }

    try {
      final coordinates = points
          .map((point) => [point.longitude, point.latitude])
          .toList();
      final body = jsonEncode({'coordinates': coordinates});

      // ✅ Print everything before sending
      print('--------------------------------------');
      print('🛰️  TD Route API Call');
      print('📍 Endpoint: $api');
      print('🔑 Token: $tdTokenKey');
      print('🧾 Headers:');
      print({
        'Authorization': 'Bearer $tdTokenKey',
        'Content-Type': 'application/json',
      });
      print('📦 Body: $body');
      print('--------------------------------------');

      final response = await http.post(
        Uri.parse(api),
        headers: {
          'Authorization': 'Bearer $tdTokenKey',
          'Content-Type': 'application/json',
        },
        body: body, // ✅ no need for jsonEncode again
      );

      // ✅ Print after response
      print('--------------------------------------');
      print('📬 Response Code: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');
      print('--------------------------------------');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('distance') && data.containsKey('duration')) {
          final distance = (data['distance'] as num).toDouble();
          final duration = (data['duration'] as num).toDouble();

          print('✅ Route Calculated: ${distance} km, ${duration} min');

          return {'distance': distance, 'duration': duration};
        } else {
          throw Exception('Invalid response format: $data');
        }

        // if (data.containsKey('distance_km') &&
        //     data.containsKey('duration_min')) {
        //   final distance = (data['distance_km'] as num).toDouble();
        //   final duration = (data['duration_min'] as num).toDouble();

        //   print('✅ Route Calculated: ${distance} km, ${duration} min');

        //   return {'distance': distance, 'duration': duration};
        // } else {
        //   throw Exception('Invalid response format: $data');
        // }
      }

      throw Exception(
        'Failed to calculate route: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('❌ ORS calculation error: $e');
      return _calculateFallbackRoute(points);
    }
  }

  // Future<Map<String, dynamic>> calculateRouteFromPoints(
  //   List<LatLng> points,
  // ) async {
  //   final tdTokenKey = await TokenManager.getTdToken();

  //   if (points.isEmpty) throw Exception('No points provided');
  //   if (points.length == 1) {
  //     return {'points': points, 'distance': 0.0, 'duration': 0.0};
  //   }
  //   try {
  //     final coordinates = points
  //         .map((point) => [point.longitude, point.latitude])
  //         .toList();

  //     final body = jsonEncode({'coordinates': coordinates});

  //     print('Calling ORS with ${points.length} points...');

  //     final response = await http.post(
  //       Uri.parse(api),
  //       headers: {
  //         'Authorization': 'Bearer $tdTokenKey',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode(body),
  //     );
  //     print(body);
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       if (data.containsKey('distance_km') &&
  //           data.containsKey('duration_min')) {
  //         final distance = (data['distance_km'] as num).toDouble();
  //         final duration = (data['duration_min'] as num).toDouble();

  //         print('Routes: ${distance} km, ${duration} min');

  //         return {
  //           // 'points': points,
  //           'distance': distance,
  //           'duration': duration,
  //         };
  //       } else {
  //         throw Exception('Invalid response format: $data');
  //       }
  //     }

  //     throw Exception('Failed to calculate route: ${response.statusCode}');
  //   } catch (e) {
  //     print('ORS calculation error: $e');
  //     return _calculateFallbackRoute(points);
  //   }
  // }

  Map<String, dynamic> _calculateFallbackRoute(List<LatLng> points) {
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }
    return {'points': points, 'distance': totalDistance, 'duration': 0.0};
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000.0;
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final deltaLat = (end.latitude - start.latitude) * math.pi / 180;
    final deltaLng = (end.longitude - start.longitude) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
}

// // old with ors
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'dart:math' as math;

// class RouteCalculator {
//   static const String _apiKey =
//       'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjcyYTdmN2EwODgxMDY1NTAxODgwMjExYWI5MzJmMjMyYjQ3ZDVlZDRkZmJiMzhlMDc3NzllZDg2IiwiaCI6Im11cm11cjY0In0='; // Replace with your key
//   static const String _baseUrl =
//       'https://api.openrouteservice.org/v2/directions/driving-car';
//   Future<Map<String, dynamic>> calculateRouteFromPoints(
//     List<LatLng> points,
//   ) async {
//     if (points.isEmpty) throw Exception('No points provided');
//     if (points.length == 1) {
//       return {'points': points, 'distance': 0.0, 'duration': 0.0};
//     }

//     try {
//       final coordinates = points
//           .map((point) => [point.longitude, point.latitude])
//           .toList();

//       final url = Uri.parse(_baseUrl);
//       final headers = {
//         'Authorization': _apiKey,
//         'Content-Type': 'application/json',
//       };

//       final body = jsonEncode({
//         'coordinates': coordinates,
//         'format': 'geojson',
//         'instructions': false,
//         'preference': 'recommended',
//       });

//       // 🛰️ Debug before request
//       print('--------------------------------------');
//       print('🛰️  ORS API Request');
//       print('📍 Endpoint: $url');
//       print('🔑 Headers: $headers');
//       print('📦 Body: $body');
//       print('--------------------------------------');

//       final response = await http
//           .post(url, headers: headers, body: body)
//           .timeout(const Duration(seconds: 30));

//       // 📨 Debug response
//       print('--------------------------------------');
//       print('📬 Response Code: ${response.statusCode}');
//       print('📨 Response Body: ${response.body}');
//       print('--------------------------------------');

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         // ✅ Use "routes" instead of "features"
//         if (data['routes'] != null && data['routes'].isNotEmpty) {
//           final route = data['routes'][0];
//           final summary = route['summary'];

//           final distance = (summary['distance'] as num).toDouble(); // meters
//           final duration = (summary['duration'] as num).toDouble(); // seconds

//           print('✅ Parsed ORS Route');
//           print('📏 Distance: ${distance / 1000} km');
//           print('⏱️ Duration: ${duration / 60} mins');

//           return {'distance': distance, 'duration': duration};
//         } else {
//           throw Exception('Invalid route response: ${response.body}');
//         }
//       }

//       throw Exception('Failed to calculate route: ${response.statusCode}');
//     } catch (e) {
//       print('❌ ORS calculation error: $e');
//       return _calculateFallbackRoute(points);
//     }
//   }

//   // Future<Map<String, dynamic>> calculateRouteFromPoints(
//   //   List<LatLng> points,
//   // ) async {
//   //   if (points.isEmpty) throw Exception('No points provided');
//   //   if (points.length == 1) {
//   //     return {'points': points, 'distance': 0.0, 'duration': 0.0};
//   //   }

//   //   try {
//   //     final coordinates = points
//   //         .map((point) => [point.longitude, point.latitude])
//   //         .toList();

//   //     final url = Uri.parse(_baseUrl);
//   //     final headers = {
//   //       'Authorization': _apiKey,
//   //       'Content-Type': 'application/json',
//   //     };

//   //     final body = jsonEncode({
//   //       'coordinates': coordinates,
//   //       'format': 'geojson',
//   //       'instructions': false,
//   //       'preference': 'recommended',
//   //     });

//   //     print('Calling ORS with ${points.length} points...');

//   //     final response = await http
//   //         .post(url, headers: headers, body: body)
//   //         .timeout(Duration(seconds: 30));

//   //     if (response.statusCode == 200) {
//   //       final data = jsonDecode(response.body);

//   //       if (data['features'] != null && data['features'].isNotEmpty) {
//   //         final feature = data['features'][0];
//   //         final coordinates = feature['geometry']['coordinates'];
//   //         final properties = feature['properties'];
//   //         final segments = properties['segments'][0];

//   //         final distance = segments['distance'].toDouble();
//   //         final duration = segments['duration'].toDouble();

//   //         List<LatLng> routePoints = coordinates
//   //             .map<LatLng>(
//   //               (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
//   //             )
//   //             .toList();

//   //         print(
//   //           'ORS Route: ${routePoints.length} points, ${distance}m, ${duration}s',
//   //         );

//   //         return {
//   //           'points': routePoints,
//   //           'distance': distance,
//   //           'duration': duration,
//   //         };
//   //       }
//   //     }

//   //     throw Exception('Failed to calculate route: ${response.statusCode}');
//   //   } catch (e) {
//   //     print('ORS calculation error: $e');
//   //     return _calculateFallbackRoute(points);
//   //   }
//   // }

//   Map<String, dynamic> _calculateFallbackRoute(List<LatLng> points) {
//     double totalDistance = 0.0;
//     for (int i = 0; i < points.length - 1; i++) {
//       totalDistance += _calculateDistance(points[i], points[i + 1]);
//     }
//     return {'points': points, 'distance': totalDistance, 'duration': 0.0};
//   }

//   double _calculateDistance(LatLng start, LatLng end) {
//     const earthRadius = 6371000.0;
//     final lat1 = start.latitude * math.pi / 180;
//     final lat2 = end.latitude * math.pi / 180;
//     final deltaLat = (end.latitude - start.latitude) * math.pi / 180;
//     final deltaLng = (end.longitude - start.longitude) * math.pi / 180;

//     final a =
//         math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
//         math.cos(lat1) *
//             math.cos(lat2) *
//             math.sin(deltaLng / 2) *
//             math.sin(deltaLng / 2);

//     final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return earthRadius * c;
//   }
// }
