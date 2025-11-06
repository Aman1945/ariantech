import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/storage.dart';

class ApiService {
  static const String baseUrl = "https://api.smartassistapp.in/api/";

  // Reassign leads API call
  static Future<Map<String, dynamic>> reassignLeads({
    required Set<String> leadIds,
    required String assignee,
  }) async {
    final token = await Storage.getToken();
    if (token == null) {
      return {"error": "No token found. Please login."};
    }

    try {
      // Convert Set to List for proper JSON serialization
      final payload = {
        'user_id': assignee,
        'leadIds': leadIds.toList(), // Convert Set to List
      };

      print("API Payload: ${jsonEncode(payload)}"); // Debug log

      final response = await http.put(
        Uri.parse('${baseUrl}leads/change-assignee'),
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
              'Failed to reassign leads: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print("API Error: $e"); // Debug log
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
