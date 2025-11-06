import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartassist/utils/storage.dart';

class TestDriveApiService {
  static const String baseUrl = 'https://api.smartassistapp.in';

  // Start test drive
  static Future<TestDriveApiResult> startTestDrive({
    required String eventId,
    required LatLng startLocation,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/start-drive');
      final token = await Storage.getToken();

      final requestBody = {
        'start_location': {
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📤 Starting test drive - Event: $eventId');
      print('📤 Request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      print('📩 Start drive response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return TestDriveApiResult.success(
          message: 'Test drive started successfully',
          data: json.decode(response.body),
        );
      } else {
        return TestDriveApiResult.error(
          'Failed to start test drive: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error starting test drive: $e');
      return TestDriveApiResult.error('Error starting test drive: $e');
    }
  }

  // End test drive
  static Future<TestDriveApiResult> endTestDrive({
    required String eventId,
    required double distance,
    required int duration,
    required LatLng? endLocation,
    required List<LatLng> routePoints,
    bool sendFeedback = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/events/$eventId/end-drive');
      final url = uri.replace(
        queryParameters: {'send_feedback': sendFeedback.toString()},
      );
      final token = await Storage.getToken();

      final requestBody = {
        'distance': double.parse(
          distance.toStringAsFixed(3),
        ), // 3 decimal precision
        'duration': duration,
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

      print('📤 Ending test drive - Event: $eventId');
      print('📤 Distance: ${distance.toStringAsFixed(3)} km');
      print('📤 Duration: $duration minutes');
      print('📤 Route points: ${routePoints.length}');
      print('📤 Send feedback: $sendFeedback');

      const encoder = JsonEncoder.withIndent('  ');
      print('📤 Request body:\n${encoder.convert(requestBody)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 15));

      print('📩 End drive response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return TestDriveApiResult.success(
          message: 'Test drive ended successfully',
          data: json.decode(response.body),
        );
      } else {
        return TestDriveApiResult.error(
          'Failed to end test drive: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error ending test drive: $e');
      return TestDriveApiResult.error('Error ending test drive: $e');
    }
  }

  // Upload map screenshot
  static Future<TestDriveApiResult> uploadMapImage({
    required String eventId,
    required Uint8List imageData,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/upload-map');
      final token = await Storage.getToken();

      print('📤 Uploading map image - Size: ${imageData.lengthInBytes} bytes');

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageData,
            filename: 'map_image_${DateTime.now().millisecondsSinceEpoch}.png',
            contentType: MediaType('image', 'png'),
          ),
        );

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('📩 Upload response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String? uploadedUrl;

        if (responseData['data'] is String) {
          uploadedUrl = responseData['data'];
        } else {
          uploadedUrl =
              responseData['data']?['map_img'] ?? responseData['map_img'];
        }

        return TestDriveApiResult.success(
          message: 'Map image uploaded successfully',
          data: {'imageUrl': uploadedUrl},
        );
      } else {
        return TestDriveApiResult.error(
          'Failed to upload map image: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error uploading map image: $e');
      return TestDriveApiResult.error('Error uploading map image: $e');
    }
  }

  // Update drive progress (for real-time tracking)
  static Future<TestDriveApiResult> updateDriveProgress({
    required String eventId,
    required double distance,
    required LatLng currentLocation,
    required DateTime timestamp,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/update-progress');
      final token = await Storage.getToken();

      final requestBody = {
        'distance': distance,
        'current_location': {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
        'timestamp': timestamp.toIso8601String(),
      };

      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        return TestDriveApiResult.success(
          message: 'Progress updated successfully',
          data: json.decode(response.body),
        );
      } else {
        return TestDriveApiResult.error(
          'Failed to update progress: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error updating progress: $e');
      return TestDriveApiResult.error('Error updating progress: $e');
    }
  }

  // Get drive status
  static Future<TestDriveApiResult> getDriveStatus(String eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/drive-status');
      final token = await Storage.getToken();

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return TestDriveApiResult.success(
          message: 'Drive status retrieved successfully',
          data: json.decode(response.body),
        );
      } else {
        return TestDriveApiResult.error(
          'Failed to get drive status: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error getting drive status: $e');
      return TestDriveApiResult.error('Error getting drive status: $e');
    }
  }
}

// Result class for API operations
class TestDriveApiResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const TestDriveApiResult._({
    required this.isSuccess,
    required this.message,
    this.data,
    this.errorMessage,
  });

  factory TestDriveApiResult.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return TestDriveApiResult._(isSuccess: true, message: message, data: data);
  }

  factory TestDriveApiResult.error(String errorMessage) {
    return TestDriveApiResult._(
      isSuccess: false,
      message: 'API Error',
      errorMessage: errorMessage,
    );
  }

  bool get isError => !isSuccess;
}
