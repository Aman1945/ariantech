import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/storage.dart';

class ApiService {
  static const String baseUrl = "https://api.smartassistapp.in/api/";

  // Reassign leads API call
  static Future<Map<String, dynamic>> bugReport({
    // required Set<String> leadIds,
    required String subject,
    required String category,
    required String description,
    String? media,
  }) async {
    final token = await Storage.getToken();
    if (token == null) {
      return {"error": "No token found. Please login."};
    }

    try {
      final payload = {
        'category': category,
        'description': description,
        'subject': subject,
        'media': media,
      };

      print("API Payload: ${jsonEncode(payload)}"); // Debug log

      final response = await http.post(
        Uri.parse('${baseUrl}issues/raise-new'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print("Response status: ${response.statusCode}"); // Debug log
      print("Response body: ${response.body}"); // Debug log

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error':
              'Failed to submit bug: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print("API Error: $e"); // Debug log
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
