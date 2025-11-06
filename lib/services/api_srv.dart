import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/route/route_name.dart';
import 'package:smartassist/pages/login_steps/login_page.dart';
import 'package:smartassist/utils/admin_is_manager.dart'
    show AdminUserIdManager;
import 'package:smartassist/utils/connection_service.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/utils/token_manager.dart';

class LeadsSrv {
  final token = Storage.getToken();
  static const String baseUrl = 'https://api.smartassistapp.in/api/';
  static final ConnectionService _connectionService = ConnectionService();

  static Future<void> handleUnauthorizedIfNeeded(
    int statusCode,
    String errorMessage,
  ) async {
    if (statusCode == 401 ||
        errorMessage.toLowerCase().contains("unauthorized")) {
      await TokenManager.clearAll();
      await Future.delayed(Duration(seconds: 2));
      Get.offAll(() => LoginPage(email: '', onLoginSuccess: () {}));
      showErrorMessageGetx(
        message:
            "You have been logged out because your account was used on another device.",
      );
      throw Exception('Unauthorized. Redirecting to login.');
    }
  }

  // Add this to your API helper file
  static Future<http.Response> makeAuthenticatedRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await Storage.getToken();

    final defaultHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    http.Response response;

    if (method.toUpperCase() == 'GET') {
      response = await http.get(Uri.parse(url), headers: defaultHeaders);
    } else if (method.toUpperCase() == 'POST') {
      response = await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: body,
      );
    } else if (method.toUpperCase() == 'PUT') {
      response = await http.put(
        Uri.parse(url),
        headers: defaultHeaders,
        body: body,
      );
    } else if (method.toUpperCase() == 'DELETE') {
      response = await http.delete(Uri.parse(url), headers: defaultHeaders);
    } else {
      throw Exception('Unsupported HTTP method: $method');
    }

    // Handle 401 here for ALL API calls
    if (response.statusCode == 401) {
      await TokenManager.clearAll();
      Get.offAllNamed(RoutesName.login);

      Future.delayed(Duration(milliseconds: 300), () {
        Get.snackbar(
          'Session Expired',
          "Please login again",
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
      });

      throw Exception('Unauthorized. Redirecting to login.');
    }

    return response;
  }

  static Future<Map<String, dynamic>> verifyEmail(Map body) async {
    const url = '${baseUrl}login/verify-email';
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      // Log the response for debugging
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      print(uri);

      if (response.statusCode == 200) {
        return {'isSuccess': true, 'data': jsonDecode(response.body)};
      } else {
        return {'isSuccess': false, 'data': jsonDecode(response.body)};
      }
    } catch (error) {
      // Log any error that occurs during the API call
      print('Error: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  static Future<Map<String, dynamic>> forgetPwd(Map body) async {
    const url = '${baseUrl}login/forgot-pwd/verify-email';
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      // Log the response for debugging
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'isSuccess': true, 'data': jsonDecode(response.body)};
      } else {
        return {'isSuccess': false, 'data': jsonDecode(response.body)};
      }
    } catch (error) {
      // Log any error that occurs during the API call
      print('Error: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(Map body) async {
    const url = '${baseUrl}login/verify-otp';
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      // Log the response for debugging
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed verification response: $responseData');
        return {'isSuccess': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        print('Error verification response: $errorData');
        return {'isSuccess': false, 'data': errorData};
      }
    } catch (error) {
      print('Error during OTP verification: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  static Future<Map<String, dynamic>> forgetOtp(Map body) async {
    const url = '${baseUrl}events/forgot-pwd/verify-otp';
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      // Log the response for debugging
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed verification response: $responseData');
        return {'isSuccess': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        print('Error verification response: $errorData');
        return {'isSuccess': false, 'data': errorData};
      }
    } catch (error) {
      print('Error during OTP verification: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  // login api

  static Future<Map<String, dynamic>> onLogin(Map body) async {
    const url = '${baseUrl}login';
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Check for success in both HTTP status and response body
      if (response.statusCode == 200 &&
          responseData['status'] == 200 &&
          responseData.containsKey('data')) {
        final data = responseData['data'];
        final String token = data['token'];
        final Map<String, dynamic>? user = data['user'];

        // Save token for subsequent calls.
        await Storage.saveToken(token);

        if (user != null) {
          return {'isSuccess': true, 'token': token, 'user': user};
        } else {
          return {
            'isSuccess': false,
            'message': 'User data missing in response',
          };
        }
      } else {
        // Return the backend error message if available.
        return {
          'isSuccess': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (error) {
      print('Error: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  static Future<Map<String, dynamic>> setPwd(Map body) async {
    const url = '${baseUrl}login/create-pwd';
    final uri = Uri.parse(url);

    try {
      final response = await http.put(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      // Log the response for debugging
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
        return {'isSuccess': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        print('Error response: $errorData');
        return {'isSuccess': false, 'data': errorData};
      }
    } catch (error) {
      // Log any error that occurs during the API call
      print('Error in setPwd: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  static Future<Map<String, dynamic>> setNewPwd(Map body) async {
    const url = '${baseUrl}login/forgot-pwd/new-pwd';
    final uri = Uri.parse(url);

    try {
      final response = await http.put(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      // Log the response for debugging
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
        return {'isSuccess': true, 'data': responseData};
      } else {
        final errorData = jsonDecode(response.body);
        print('Error response: $errorData');
        return {'isSuccess': false, 'data': errorData};
      }
    } catch (error) {
      // Log any error that occurs during the API call
      print('Error in setPwd: $error');
      return {'isSuccess': false, 'error': error.toString()};
    }
  }

  static Future<List?> loadFollowups(Map body) async {
    const url = '${baseUrl}admin/leads/all';

    final uri = Uri.parse(url);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['items'] as List;
      return result;
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      final String errorMessage =
          errorData['message'] ?? 'Failed to load dashboard data';

      await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
      ();
      return null;
    }
  }

  //fetch users
  // Add this method to your LeadsSrv class
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    final token = await Storage.getToken();
    try {
      print('🔍 Fetching users from: ${baseUrl}admin/users/all');
      print('🔑 Using token: ${token?.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('${baseUrl}admin/users/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Response status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (data['data'] != null && data['data']['rows'] != null) {
          final rows = data['data']['rows'] as List;
          print('✅ Found ${rows.length} users');

          // Convert to List<Map<String, dynamic>>
          return List<Map<String, dynamic>>.from(rows);
        } else {
          print('❌ Unexpected response structure: $data');
          throw Exception('Invalid response structure - missing data.rows');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        throw Exception(
          'Failed to fetch users. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (error) {
      print('💥 Error in fetchUsers: $error');
      rethrow; // Re-throw so the UI can handle it
    }
  }
  //end

  static Future<List<String>> fetchDropdownOptions() async {
    const url = '${baseUrl}admin/users/all';
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Assuming the API response is a list of strings:
        // Example: { "options": ["Option 1", "Option 2", "Option 3"] }

        return List<String>.from(data['options']);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to fetch options');
      }
    } catch (error) {
      print('Error fetching options: $error');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> submitLead(
    Map<String, dynamic> leadData,
  ) async {
    const String apiUrl = "${baseUrl}admin/leads/create";

    final token = await Storage.getToken();
    if (token == null) {
      return {"error": "No token found. Please login."};
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(leadData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        print('Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        showErrorMessageGetx(
          message: 'Submission failed: ${response.statusCode}',
        );
        // return false;
      }
    } on SocketException {
      showErrorMessageGetx(
        message: 'No internet connection. Please check your network.',
      );
      // return false;
    } on TimeoutException {
      showErrorMessageGetx(
        message: 'Request timed out. Please try again later.',
      );
      // return false;
    } catch (e) {
      print('Unexpected error: $e');
      showErrorMessageGetx(
        message: 'An unexpected error occurred. Please try again.',
      );
      // return false;
    }
  }

  static Future<Map<String, dynamic>?> tdLoginToken(
    Map<String, dynamic> username,
  ) async {
    const String apiUrl = "https://services.smartassistapp.in/service/td/login";

    final token = await Storage.getToken();
    if (token == null) {
      return {"error": "No token found. Please login."};
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(username),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('hitt login api');
        return responseData;
      } else {
        print('Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        showErrorMessageGetx(
          message: 'Submission failed: ${response.statusCode}',
        );
        // return false;
      }
    } on SocketException {
      showErrorMessageGetx(
        message: 'No internet connection. Please check your network.',
      );
      // return false;
    } on TimeoutException {
      showErrorMessageGetx(
        message: 'Request timed out. Please try again later.',
      );
      // return false;
    } catch (e) {
      print('Unexpected error: $e');
      showErrorMessageGetx(
        message: 'An unexpected error occurred. Please try again.',
      );
      // return false;
    }
    return null;
  }

  // create followups

  static Future<bool> submitFollowups(
    Map<String, dynamic> followupsData,
    String leadId,
    BuildContext context,
  ) async {
    final token = await Storage.getToken();

    // Debugging: print the headers and body
    print(
      'Headers: ${{'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'recordId': leadId}}',
    );

    print('Request body: ${jsonEncode(followupsData)}');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}admin/leads/$leadId/create-task'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'recordId': leadId,
        },
        body: jsonEncode(followupsData),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        showErrorMessage(
          context,
          // message: 'Submission failed: ${response.statusCode}',
          message: 'Submission failed : ${responseData['message']}',
        );
        return false;
      }
    } on SocketException {
      showErrorMessageGetx(
        message: 'No internet connection. Please check your network.',
      );
      return false;
    } on TimeoutException {
      showErrorMessage(
        context,
        message: 'Request timed out. Please try again later.',
      );
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      showErrorMessage(
        context,
        message: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  // create appoinment
  static Future<bool> submitAppoinment(
    Map<String, dynamic> followupsData,
    String leadId,
  ) async {
    final token = await Storage.getToken();

    // Debugging: print the headers and body
    print(
      'Headers: ${{'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'recordId': leadId}}',
    );
    print('Request body: ${jsonEncode(followupsData)}');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}admin/records/$leadId/tasks/create-appointment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'recordId': leadId,
        },
        body: jsonEncode(followupsData),
      );

      final responseData = jsonDecode(response.body);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        showErrorMessageGetx(
          message: 'Submission failed: ${responseData['message']}',
        );
        return false;
      }
    } on SocketException {
      showErrorMessageGetx(
        message: 'No internet connection. Please check your network.',
      );
      return false; // Added return statement
    } on TimeoutException {
      showErrorMessageGetx(
        message: 'Request timed out. Please try again later.',
      );
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      showErrorMessageGetx(
        message: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  static Future<String?> webXoxo(context) async {
    final token = await Storage.getToken();

    // Debugging: print the headers
    print(
      'Headers: ${{'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}}',
    );

    try {
      final response = await http.post(
        Uri.parse('https://api.smartassistapp.in/compass/user-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract and return the token from response
        final xoxoToken =
            responseData['access_token'] ??
            responseData['token'] ??
            responseData['data']?['token'] ??
            responseData['data']?['access_token'];
        if (xoxoToken != null) {
          return xoxoToken.toString();
        } else {
          print('Token not found in response');
          print('Available keys: ${responseData.keys.toList()}');
          showErrorMessage(
            context,
            message: 'Authentication token not received',
          );
          return null;
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        showErrorMessage(
          context,
          message:
              'Authentication failed: ${responseData['message'] ?? 'Unknown error'}',
        );
        return null;
      }
    } on SocketException {
      showErrorMessage(
        context,
        message: 'No internet connection. Please check your network.',
      );
      return null;
    } on TimeoutException {
      showErrorMessage(
        context,
        message: 'Request timed out. Please try again later.',
      );
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      showErrorMessage(context, message: e.toString());
      return null;
    }
  }

  static String buildXoxoUrl(String xoxoToken) {
    // Simply return the URL with the token - no need for HTTP call
    return 'https://m.getcompass.ai/?url=oauth&token=$xoxoToken';
  }

  static Future<bool> submitTestDrive(
    Map<String, dynamic> testdriveData,
    String leadId,
  ) async {
    final token = await Storage.getToken();

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}admin/records/$leadId/events/create-test-drive'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'recordId': leadId,
        },
        body: jsonEncode(testdriveData),
      );

      // print();
      final responseData = jsonDecode(response.body);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        showErrorMessageGetx(
          message: 'Submission failed: ${responseData['message']}',
        );
        print('Error details: ${response.body}');
        return false;
      }
    } on SocketException {
      showErrorMessageGetx(
        message: 'No internet connection. Please check your network.',
      );
      return false;
    } on TimeoutException {
      showErrorMessageGetx(
        message: 'Request timed out. Please try again later.',
      );
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      showErrorMessageGetx(
        message: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchLeadsById(String leadId) async {
    const String apiUrl = "${baseUrl}leads/";

    final token = await Storage.getToken();
    if (token == null) {
      print("No token found. Please login.");
      throw Exception("No token found. Please login.");
    }

    try {
      // Debug: Print the full URL with leadId
      final fullUrl = Uri.parse('$apiUrl$leadId');
      print('Fetching data from URL: $fullUrl');

      final response = await http.get(
        fullUrl, // Use the full URL
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'leadId': leadId,
        },
      );

      // Debug: Print response details
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data')) {
          return responseData['data'];
        } else {
          throw Exception('Unexpected response structure: ${response.body}');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception(
          'Failed to load data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<Map<String, dynamic>> singleFollowupsById(String leadId) async {
    const String apiUrl = "${baseUrl}leads/by-id/";

    final token = await Storage.getToken();
    if (token == null) {
      // print("No token found. Please login.");
      throw Exception("No token found. Please login.");
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl$leadId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'leadId': leadId,
        },
      );

      // Debug: Print the response status code and body
      print('this is upper api');
      print('Response status code:: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  // history data api

  static Future<Map<String, dynamic>> adminSingleFollowupsIds(
    String leadId,
  ) async {
    final adminId = await AdminUserIdManager.getAdminUserId();
    const String apiUrl = "${baseUrl}app-admin/lead-byId/";

    final token = await Storage.getToken();
    if (token == null) {
      // print("No token found. Please login.");
      throw Exception("No token found. Please login.");
    }
    final url = '$apiUrl$leadId?userId=$adminId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'leadId': leadId,
        },
      );
      print('thisis the url of the lead-by-id admin $url');
      // Debug: Print the response status code and body
      print('this is upper api');
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> singleTaskById(
    String leadId,
  ) async {
    const String apiUrl = "${baseUrl}admin/leads/tasks/all/";

    final token = await Storage.getToken();
    if (token == null) {
      print("No token found. Please login.");
      throw Exception("No token found. Please login.");
    }

    try {
      print('Fetching data for Lead ID: $leadId');
      print('API URL: ${apiUrl + leadId}');

      final response = await http.get(
        Uri.parse('$apiUrl$leadId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Handle the nested structure with allEvents.rows
        if (data.containsKey('data') &&
            data['data'].containsKey('allTasks') &&
            data['data']['allTasks'].containsKey('rows')) {
          // Extract the rows containing the task data
          return List<Map<String, dynamic>>.from(
            data['data']['allTasks']['rows'],
          );
        } else {
          return []; // Return empty list if no tasks found
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  // static Future<List<Map<String, dynamic>>> singleTasksById(
  //     String leadId) async {
  //   const String apiUrl =
  //       "https://api.smartassistapp.in/api/admin/leads/tasks/all/";

  //   final token = await Storage.getToken();
  //   if (token == null) {
  //     print("No token found. Please login.");
  //     throw Exception("No token found. Please login.");
  //   }

  //   try {
  //     print('Fetching data for Lead ID: $leadId');
  //     print('API URL: ${apiUrl + leadId}');

  //     final response = await http.get(
  //       Uri.parse('$apiUrl$leadId'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     print('Response status code: ${response.statusCode}');
  //     print('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);

  //       // Handle the nested structure with allEvents.rows
  //       if (data.containsKey('allTasks') &&
  //           data['allTasks'] is Map<String, dynamic> &&
  //           data['allTasks'].containsKey('rows')) {
  //         return List<Map<String, dynamic>>.from(data['allTasks']['rows']);
  //       } else {
  //         return []; // Return empty list if no events found
  //       }
  //     } else {
  //       throw Exception('Failed to load data: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching data: $e');
  //     throw Exception('Error fetching data: $e');
  //   }
  // }

  static Future<Map<String, dynamic>> eventTaskByLead(
    String leadId, {
    bool isFromSM = false,
    String? userId,
  }) async {
    // const String apiUrl = "${baseUrl}leads/events-&-tasks/";
    const String baseApiUrl = "${baseUrl}leads/events-&-tasks/";
    final token = await Storage.getToken();

    try {
      late Uri uri;

      if (isFromSM && userId != null && userId.isNotEmpty) {
        uri = Uri.parse('$baseApiUrl$leadId?user_id=$userId');
      } else {
        uri = Uri.parse('$baseApiUrl$leadId');
      }
      // Append the leadId and subject to the API URL
      print('Fetching data for Lead ID: $leadId');
      print('API URL: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body for both data task and event: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  //

  static Future<Map<String, dynamic>> adminEventTaskByLead(
    String leadId,
  ) async {
    const String apiUrl = "${baseUrl}app-admin/lead/history/";
    final token = await Storage.getToken();
    final adminId = await AdminUserIdManager.getAdminUserId();

    try {
      // Append the leadId and subject to the API URL
      print('Fetching data for Lead ID: $leadId');
      print('API URL: ${apiUrl + leadId + '?userId=$adminId'}');
      final response = await http.get(
        Uri.parse('$apiUrl$leadId?userId=$adminId'),

        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body for both data task and event: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  // for teams only
  static Future<Map<String, dynamic>> eventTaskByLeadTeams(
    String leadId,
    String userId,
  ) async {
    const String apiUrl = "${baseUrl}leads/events-&-tasks/";
    final token = await Storage.getToken();

    try {
      final fullUrl = '$apiUrl$leadId?user_id=$userId';
      print('Fetching data for Lead ID: $leadId');
      print('API URL: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body for both data task and event: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<Map<String, dynamic>> AdmineventTaskByLeadTeams(
    String leadId,
    String userId,
  ) async {
    const String apiUrl = "${baseUrl}app-admin/lead/history/";
    final token = await Storage.getToken();
    final adminId = await AdminUserIdManager.getAdminUserId();

    try {
      final fullUrl = '$apiUrl$leadId?user_id=$userId?userId=$adminId';
      print('Fetching data for Lead ID: $leadId');
      print('API URL: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body for both data task and event: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  // static Future<Map<String, dynamic>> AdmineventTaskByLeadTeams(
  //   String leadId,
  //   String userId,
  // ) async {
  //   const String apiUrl = "${baseUrl}leads/events-&-tasks/";
  //   final token = await Storage.getToken();

  //   try {
  //     final fullUrl = '$apiUrl$leadId?user_id=$userId';
  //     print('Fetching data for Lead ID: $leadId');
  //     print('API URL: $fullUrl');

  //     final response = await http.get(
  //       Uri.parse(fullUrl),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     print('Response status code: ${response.statusCode}');
  //     print('Response body for both data task and event: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonResponse = json.decode(response.body);
  //       final Map<String, dynamic> data = jsonResponse['data'];
  //       return data;
  //     } else {
  //       final Map<String, dynamic> errorData = json.decode(response.body);
  //       final String errorMessage =
  //           errorData['message'] ?? 'Failed to load dashboard data';
  //       print("Failed to load data: $errorMessage");

  //       // Check if unauthorized: status 401 or error message includes "unauthorized"
  //       await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
  //       ();
  //       throw Exception('Failed to load data: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching data: $e');
  //   }
  // }

  static Future<List<Map<String, dynamic>>> singleTestDriveById(
    String leadId,
    String subject,
  ) async {
    const String apiUrl = "${baseUrl}admin/leads/events/all/";

    final token = await Storage.getToken();

    try {
      // Append the leadId and subject to the API URL
      final response = await http.get(
        Uri.parse('${apiUrl + leadId + '?' + subject}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Handle the nested structure with allEvents.rows
        if (data.containsKey('data') &&
            data['data'].containsKey('allEvents') &&
            data['data']['allEvents'].containsKey('rows')) {
          // Extract the rows containing the task data
          return List<Map<String, dynamic>>.from(
            data['data']['allEvents']['rows'],
          );
        } else {
          return []; // Return empty list if no events found
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> singleTasksById(
    String leadId,
  ) async {
    const String apiUrl = "${baseUrl}admin/leads/events/all/";

    final token = await Storage.getToken();
    if (token == null) {
      print("No token found. Please login.");
      throw Exception("No token found. Please login.");
    }

    try {
      print('Fetching data for Lead ID: $leadId');
      print('API URL: ${apiUrl + leadId}');

      final response = await http.get(
        Uri.parse('$apiUrl$leadId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Ensure the data structure contains 'allTasks' and 'rows'
        if (data.containsKey('data') &&
            data['data'].containsKey('allEvents') &&
            data['data']['allEvents'].containsKey('rows')) {
          // Extract the rows containing the task data
          return List<Map<String, dynamic>>.from(
            data['data']['allEvents']['rows'],
          );
        } else {
          return []; // Return empty list if no tasks found
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  //
  static Future<Map<String, dynamic>> singleAppointmentById(
    String eventId,
  ) async {
    const String apiUrl = "${baseUrl}admin/events/";

    final token = await Storage.getToken();
    if (token == null) {
      print("No token found. Please login.");
      throw Exception("No token found. Please login.");
    }

    try {
      // Ensure the actual leadId is being passed correctly
      print('Fetching data for Lead ID: $eventId');
      print(
        'API URL: ${apiUrl + eventId}',
      ); // Concatenate the leadId with the API URL

      final response = await http.get(
        Uri.parse('$apiUrl$eventId'), // Correct URL with leadId appended
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'eventId': eventId,
        },
      );

      // Debug: Print the response status code and body
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // Return the response data
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  // Fetch appointments (tasks) for a selected date
  static Future<List<dynamic>> fetchAppointments(DateTime selectedDate) async {
    final DateTime finalDate = selectedDate ?? DateTime.now();
    final String formattedDate = DateFormat('dd-MM-yyyy').format(finalDate);
    final String apiUrl =
        '${baseUrl}calendar/events/all/asondate?date=$formattedDate';

    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("Error: ${response.statusCode}");
        final Map<String, dynamic> data = json.decode(response.body);
        print("Total Appointments Fetched: ${data['data']['rows']?.length}");
        return data['data']['rows'] ?? [];
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        print("Error: ${response.statusCode}");
        return [];
      }
    } catch (error) {
      print("Error fetching appointments: $error");

      return [];
    }
  }

  // fetch tasks change the url calendar

  static Future<List<dynamic>> fetchtasks(DateTime selectedDate) async {
    final DateTime finalDate = selectedDate ?? DateTime.now();
    final String formattedDate = DateFormat('dd-MM-yyyy').format(finalDate);
    final String apiUrl =
        '${baseUrl}calendar/tasks/all/asondate?date=$formattedDate';

    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("Error: ${response.statusCode}");
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data']['rows'] ?? [];
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        print("Error: ${response.statusCode}");
        return [];
      }
    } catch (error) {
      print("Error fetching appointments: $error");

      return [];
    }
  }

  // Fetch event counts for a selected date
  static Future<Map<String, int>> fetchCount(DateTime selectedDate) async {
    final String formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
    final String apiUrl =
        '${baseUrl}calendar/data-count/asondate?date=$formattedDate';
    print("Calling API for count on: $formattedDate");
    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'upcomingFollowupsCount': data['data']['upcomingFollowupsCount'] ?? 0,
          'overdueFollowupsCount': data['data']['overdueFollowupsCount'] ?? 0,
          'upcomingAppointmentsCount':
              data['data']['upcomingAppointmentsCount'] ?? 0,
          'overdueAppointmentsCount':
              data['data']['overdueAppointmentsCount'] ?? 0,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        print('API Error: ${response.statusCode}');
        return {};
      }
    } catch (error) {
      print("Error fetching event counts: $error");
      return {};
    }
  }

  static Future<Map<String, dynamic>> fetchDashboardData() async {
    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}users/dashboard?filterType=MTD&category=Leads'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchTasksUpcoming() async {
    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}tasks/all-tasks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchAppointment() async {
    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}tasks/all-appointments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        showErrorMessageGetx(message: errorMessage);
        print('this is the msg $errorMessage');
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchTeamData() async {
    try {
      final token = await Storage.getToken();
      final url = Uri.parse('${baseUrl}users/sm/analytics/team-dashboard');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");
        showErrorMessageGetx(message: errorMessage);
        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<Map<String, dynamic>> smCalendarAsondate(
    Map<String, String> queryParams,
  ) async {
    try {
      final token = await Storage.getToken();

      final url = Uri.parse(
        '${baseUrl}calendar/activities/all/asondate',
      ).replace(queryParameters: queryParams); // ✅ Proper way to append

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(url);
        final data = json.decode(response.body);
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load calendar data';
        showErrorMessageGetx(message: errorMessage);
        print("Failed to load data: $errorMessage");
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching calendar data: $e');
      throw Exception('Error fetching calendar data: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchAllEnq() async {
    try {
      final token = await Storage.getToken();

      final url = Uri.parse('${baseUrl}leads/all');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(url);
        final data = json.decode(response.body);
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load calendar data';
        showErrorMessageGetx(message: errorMessage);
        print("Failed to load data: $errorMessage");
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching calendar data: $e');
      throw Exception('Error fetching calendar data: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchDashboardDataAn({
    String? timeRange,
    String? userId,
    bool isFromSM = false,
  }) async {
    try {
      final token = await Storage.getToken();
      String endpoint = 'users/ps/dashboard/call-analytics';

      // Add time range parameter
      String periodParam = '';
      switch (timeRange) {
        case '1D':
          periodParam = '?type=DAY';
          break;
        case '1W':
          periodParam = '?type=WEEK';
          break;
        case '1M':
          periodParam = '?type=MTD';
          break;
        case '1Q':
          periodParam = '?type=QTD';
          break;
        case '1Y':
          periodParam = '?type=YTD';
          break;
        default:
          periodParam = '?type=DAY';
      }

      // Add user_id parameter if needed
      if (isFromSM && userId != null) {
        periodParam += '&user_id=$userId';
      }

      // ✅ Combine everything into a full URL
      final String url = '$baseUrl$endpoint$periodParam';

      print('📡 API Endpoint: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print(url);
        return {
          'success': true,
          'data': jsonResponse,
          'message': 'Dashboard data fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        showErrorMessageGetx(message: errorMessage);

        print('❌ Failed to load dashboard data: $errorMessage');
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching dashboard data: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // static Future<Map<String, dynamic>> fetchDashboardDataAn({
  //   String? timeRange,
  //   String? userId,
  //   bool isFromSM = false,
  // }) async {
  //   try {
  //     final token = await Storage.getToken();
  //     // Build the endpoint with parameters
  //     String endpoint = 'users/ps/dashboard/call-analytics';

  //     // Add time range parameter
  //     String periodParam = '';
  //     switch (timeRange) {
  //       case '1D':
  //         periodParam = '?type=DAY';
  //         break;
  //       case '1W':
  //         periodParam = '?type=WEEK';
  //         break;
  //       case '1M':
  //         periodParam = '?type=MTD';
  //         break;
  //       case '1Q':
  //         periodParam = '?type=QTD';
  //         break;
  //       case '1Y':
  //         periodParam = '?type=YTD';
  //         break;
  //       default:
  //         periodParam = '?type=DAY';
  //     }

  //     // Add user_id parameter if needed
  //     if (isFromSM && userId != null) {
  //       periodParam += '&user_id=$userId';
  //     }

  //     endpoint += periodParam;

  //     print('API Endpoint: $endpoint'); // Debug print

  //     // final response = await authenticatedRequest(
  //     //   method: 'GET',
  //     //   endpoint: endpoint,
  //     // );

  //     final response = await http.get(
  //       endpoint,
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonResponse = json.decode(response.body);

  //       return {
  //         'success': true,
  //         'data': jsonResponse,
  //         'message': 'Dashboard data fetched successfully',
  //         'timestamp': DateTime.now().toIso8601String(),
  //       };
  //     } else {
  //       final Map<String, dynamic> errorData = json.decode(response.body);
  //       final String errorMessage =
  //           errorData['message'] ?? 'Failed to load dashboard data';

  //       print("Failed to load dashboard data: $errorMessage");
  //       await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

  //       return {
  //         'success': false,
  //         'data': {},
  //         'message': errorMessage,
  //         'status_code': response.statusCode,
  //       };
  //     }
  //   } catch (e) {
  //     print('Error fetching dashboard data: $e');
  //     return {
  //       'success': false,
  //       'data': {},
  //       'message': 'Network error: ${e.toString()}',
  //     };
  //   }
  // }

  static Future<Map<String, dynamic>> profileData() async {
    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}users/show-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        showErrorMessageGetx(message: errorMessage);
        print('this is the msg $errorMessage');
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchTestdrive() async {
    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}events/all-events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        showErrorMessageGetx(message: errorMessage);
        print('this is the msg $errorMessage');
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> adminFetchDashboardData() async {
    final token = await Storage.getToken();
    final adminId = await AdminUserIdManager.getAdminUserId();
    try {
      final url = Uri.parse('${baseUrl}app-admin/dashboard?userId=$adminId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        print('this is the url $url');
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchDealer() async {
    final token = await Storage.getToken();
    try {
      final url = '${baseUrl}app-admin/all-dealerships';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('dealer login email get $url');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Dashboard data is nested under "data"
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchXoxoUrl(String xoxoToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://m.getcompass.ai/?url=oauth&token=$xoxoToken'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetch URL Response Status: ${response.statusCode}');
      print('Fetch URL Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Return the response data which should contain the URL
        return jsonResponse;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard URL';

        throw Exception(
          'Failed to load dashboard URL: ${response.statusCode} - $errorMessage',
        );
      }
    } catch (e) {
      print('Fetch URL error: $e');
      throw Exception('Failed to fetch dashboard URL: ${e.toString()}');
    }
  }

  // static Future<Map<String, dynamic>> fetchXoxoUrl(String? xoxoToken) async {
  //   final token = await Storage.getToken();
  //   try {
  //     final response = await http.get(
  //       Uri.parse('https://m.getcompass.ai/?url=oauth&&token=$xoxoToken'),
  //       headers: {'Content-Type': 'application/json'},
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonResponse = json.decode(response.body);
  //       // Dashboard data is nested under "data"
  //       final Map<String, dynamic> data = jsonResponse['data'];
  //       return data;
  //     } else {
  //       final Map<String, dynamic> errorData = json.decode(response.body);
  //       final String errorMessage =
  //           errorData['message'] ?? 'Failed to load dashboard data';
  //       await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
  //       throw Exception(
  //         'Failed to load dashboard data: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }

  // static Future<Map<String, dynamic>> fetchDashboardDataapi() async {
  //   const url = '${baseUrl}users/dashboard?filterType=MTD&category=Leads';
  //   final uri = Uri.parse(url);
  //   try {
  //     // final response = await http.get(uri);

  //     final response = await makeAuthenticatedRequest(
  //       'GET',
  //       '${baseUrl}users/dashboard?filterType=MTD&category=Leads',
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonResponse = json.decode(response.body);
  //       final Map<String, dynamic> data = jsonResponse['data'];
  //       return data;
  //     } else {
  //       final Map<String, dynamic> errorData = json.decode(response.body);
  //       final String errorMessage =
  //           errorData['message'] ?? 'Failed to load dashboard data';
  //       throw Exception(errorMessage);
  //     }
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }

  static Future<Map<String, dynamic>> fetchDashboardAnalytics() async {
    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}users/dashboard/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];
        return data;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchSingleCallLogData({
    required int periodIndex,
    required String selectedUserId,
  }) async {
    try {
      final token = await Storage.getToken();

      String periodParam;
      switch (periodIndex) {
        case 0:
          periodParam = 'DAY';
          break;
        case 1:
          periodParam = 'WEEK';
          break;
        case 2:
          periodParam = 'MTD';
          break;
        case 3:
          periodParam = 'QTD';
          break;
        case 4:
          periodParam = 'YTD';
          break;
        default:
          periodParam = 'DAY';
      }

      final Map<String, String> queryParams = {
        'type': periodParam,
        if (selectedUserId.isNotEmpty) 'userId': selectedUserId,
      };

      final uri = Uri.parse(
        '${baseUrl}users/sm/dashboard/individual/call-analytics',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final Map<String, dynamic> errorData = json.decode(response.body);
      final String errorMessage =
          errorData['message'] ?? 'Failed to load dashboard data';

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        throw Exception(
          'Failed to fetch single call log data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(e.toString());
      throw Exception('Error fetching single call log data: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchAllCalllog({
    required int periodIndex,
  }) async {
    try {
      final token = await Storage.getToken();

      // Determine the period parameter
      String periodParam;
      switch (periodIndex) {
        case 1:
          periodParam = 'DAY';
          break;
        case 2:
          periodParam = 'WEEK';
          break;
        case 3:
          periodParam = 'MTD';
          break;
        case 4:
          periodParam = 'QTD';
          break;
        case 5:
          periodParam = 'YTD';
          break;
        default:
          periodParam = 'QTD';
      }

      final queryParams = {'type': periodParam};

      final uri = Uri.parse(
        '${baseUrl}users/sm/dashboard/call-analytics',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'analyticsData': responseData['data'],
          'membersData': List<Map<String, dynamic>>.from(
            responseData['data']['members'],
          ),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception(
          'Failed to fetch call analytics: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchAllCalllog: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchTeamDetails({
    required int periodIndex,
    required int metricIndex,
    required int selectedProfileIndex,
    required String selectedUserId,
    required List<String> selectedCheckboxIds,
    required int upcomingButtonIndex,
  }) async {
    try {
      final token = await Storage.getToken();

      // Build query parameters
      final periodParam =
          ['DAY', 'WEEK', 'MTD', 'QTD', 'YTD'].elementAtOrNull(periodIndex) ??
          'QTD';

      final summaryParam =
          [
            'enquiries',
            'testDrives',
            'orders',
            'cancellation',
            'netOrders',
            'retail',
          ].elementAtOrNull(metricIndex) ??
          'enquiries';

      final queryParams = {'type': periodParam, 'summary': summaryParam};

      if (selectedProfileIndex != 0 && selectedUserId.isNotEmpty) {
        queryParams['user_id'] = selectedUserId;
      }

      if (selectedCheckboxIds.isNotEmpty) {
        queryParams['userIds'] = selectedCheckboxIds.join(',');
      }

      final uri = Uri.parse(
        '${baseUrl}users/sm/dashboard/team-dashboard',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final performance = data['data']?['selectedUserPerformance'] ?? {};
        final upcoming = performance['Upcoming'] ?? {};
        final overdue = performance['Overdue'] ?? {};

        return {
          'teamData': data['data'] ?? {},
          'allMember': data['data']?['allMember'] ?? [],
          'summary': data['data']?['summary'] ?? {},
          'totalPerformance': data['data']?['totalPerformance'] ?? {},
          'upcomingFollowups': List<Map<String, dynamic>>.from(
            upcomingButtonIndex == 0
                ? upcoming['upComingFollowups'] ?? []
                : overdue['overdueFollowups'] ?? [],
          ),
          'upcomingAppointments': List<Map<String, dynamic>>.from(
            upcomingButtonIndex == 0
                ? upcoming['upComingAppointment'] ?? []
                : overdue['overdueAppointments'] ?? [],
          ),
          'upcomingTestDrives': List<Map<String, dynamic>>.from(
            upcomingButtonIndex == 0
                ? upcoming['upComingTestDrive'] ?? []
                : overdue['overdueTestDrives'] ?? [],
          ),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in LeadsSrv.fetchTeamDetails: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchNotifications({
    String? category,
  }) async {
    try {
      final token = await Storage.getToken();

      // String url = '${baseUrl}users/notifications/all';

      // if (category != null && category != 'All') {
      //   String formattedCategory = category.replaceAll(' ', '');
      //   url += '?category=$formattedCategory';
      // }

      String url = '${baseUrl}users/notifications/all';

      // ✅ FIX: Properly handle category values
      if (category != null && category != 'All') {
        // Map user-friendly category names to API keys
        final Map<String, String> categoryMap = {
          'All': 'All',
          'Leads': 'leads',
          'Followups': 'followups',
          'Appointments': 'appointment',
          'Test drives': 'test%20drive',
        };

        // Pick mapped value or fallback to cleaned version
        final mappedCategory =
            categoryMap[category] ?? category.replaceAll(' ', '').toLowerCase();

        url += '?category=$mappedCategory';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        print(url);
        final Map<String, dynamic> data = json.decode(response.body);

        // Combine unread and read notifications
        List<dynamic> allNotifications = [];
        if (data['data']['unread']?['rows'] != null) {
          allNotifications.addAll(data['data']['unread']['rows']);
        }
        if (data['data']['read']?['rows'] != null) {
          allNotifications.addAll(data['data']['read']['rows']);
        }

        return {
          'success': true,
          'data': allNotifications,
          'message': 'Notifications fetched successfully',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");
        showErrorMessageGetx(message: errorMessage);
        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        return {
          'success': false,
          'data': [],
          'message': 'Failed to load notifications: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': 'Error fetching notifications: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchFavLeadsAll() async {
    try {
      final token = await Storage.getToken();

      final url = Uri.parse('${baseUrl}favourites/leads/all');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': 'Tasks fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load tasks';

        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchFavFollowups() async {
    try {
      final token = await Storage.getToken();

      final url = Uri.parse('${baseUrl}favourites/follow-ups/all');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': 'Tasks fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load tasks';

        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchFavAppointment() async {
    try {
      final token = await Storage.getToken();

      final url = Uri.parse('${baseUrl}favourites/events/appointments/all');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': 'Tasks fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load tasks';

        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchFavTestdrive() async {
    try {
      final token = await Storage.getToken();

      final url = Uri.parse('${baseUrl}favourites/events/test-drives/all');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': 'Tasks fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load tasks';

        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchSingleCalllogTeams({
    String? timeRange,
    String? userId,
    bool isFromSM = false,
  }) async {
    try {
      final token = await Storage.getToken();
      String endpoint = 'users/ps/dashboard/call-analytics';

      // Add time range parameter
      String periodParam = '';
      switch (timeRange) {
        case '1D':
          periodParam = '?type=DAY';
          break;
        case '1W':
          periodParam = '?type=WEEK';
          break;
        case '1M':
          periodParam = '?type=MTD';
          break;
        case '1Q':
          periodParam = '?type=QTD';
          break;
        case '1Y':
          periodParam = '?type=YTD';
          break;
        default:
          periodParam = '?type=DAY';
      }

      // Add user_id parameter if needed
      if (isFromSM && userId != null && userId.isNotEmpty) {
        periodParam += '&user_id=$userId';
      }

      // endpoint += periodParam;

      print('API Endpoint: $endpoint'); // Debug print

      // final response = await authenticatedRequest(
      //   method: 'GET',
      //   endpoint: endpoint,
      // );

      final String url = '$baseUrl$endpoint$periodParam';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('calllog $url');
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return {
          'success': true,
          'data': jsonResponse,
          'message': 'Dashboard data fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';

        print("Failed to load dashboard data: $errorMessage");
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final token = await Storage.getToken();
      final url = '${baseUrl}users/notifications/$notificationId';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'read': true}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification marked as read successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to mark as read: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error marking notification as read: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> fetchDetailsTeams({
    int? periodIndex,
    String? timeRange,
    bool isComparing = false,
    List<String>? selectedUserIds,
    String? selectedUserId,
    int selectedProfileIndex = 0,
    bool avatarAll = false,
    List<String>? totalPerformanceIds,
    bool isAlphabetLogsMode = false,
    List<String>? logStatusAlphabet,
  }) async {
    try {
      final token = await Storage.getToken();
      const String baseUrl = 'https://api.smartassistapp.in/api/';
      const String endpoint = 'users/sm/analytics/team-dashboard';

      // 🧭 Determine period type
      String periodParam = 'QTD';
      if (periodIndex != null) {
        switch (periodIndex) {
          case 1:
            periodParam = 'MTD';
            break;
          case 0:
            periodParam = 'QTD';
            break;
          case 2:
            periodParam = 'YTD';
            break;
        }
      } else if (timeRange != null) {
        switch (timeRange) {
          case '1D':
            periodParam = 'DAY';
            break;
          case '1W':
            periodParam = 'WEEK';
            break;
          case '1M':
            periodParam = 'MTD';
            break;
          case '1Q':
            periodParam = 'QTD';
            break;
          case '1Y':
            periodParam = 'YTD';
            break;
        }
      }

      // 🧱 Build query parameters safely
      final Map<String, String> queryParams = {'type': periodParam};

      if (isComparing &&
          selectedUserIds != null &&
          selectedUserIds.isNotEmpty) {
        queryParams['userIds'] = selectedUserIds.join(',');
      } else if (!isComparing &&
          selectedProfileIndex != 0 &&
          selectedUserId != null &&
          selectedUserId.isNotEmpty) {
        queryParams['user_id'] = selectedUserId;
      }

      if (avatarAll &&
          totalPerformanceIds != null &&
          totalPerformanceIds.isNotEmpty) {
        queryParams['total_performance'] = totalPerformanceIds.join(',');
      }

      if (isAlphabetLogsMode &&
          logStatusAlphabet != null &&
          logStatusAlphabet.isNotEmpty) {
        queryParams['logs_userIds'] = logStatusAlphabet.join(',');
        queryParams['total_performance'] = logStatusAlphabet.join(',');
        print('📤 Sending logs_userIds: ${logStatusAlphabet.join(',')}');
      }

      // 🧩 Construct final URI safely
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      print('📡 Final API URL: $uri');

      // 🧠 Send request
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': 'Team details fetched successfully',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load team details';

        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        return {
          'success': false,
          'data': {},
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching team details: $e');
      return {
        'success': false,
        'data': {},
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // static Future<Map<String, dynamic>> fetchDetailsTeams({
  //   int? periodIndex,
  //   String? timeRange,
  //   bool isComparing = false,
  //   List<String>? selectedUserIds,
  //   String? selectedUserId,
  //   int selectedProfileIndex = 0,
  //   bool avatarAll = false,
  //   List<String>? totalPerformanceIds,
  //   bool isAlphabetLogsMode = false,
  //   List<String>? logStatusAlphabet,
  // }) async {
  //   try {
  //     final token = await Storage.getToken();
  //     // Build the endpoint with parameters
  //     String endpoint = 'users/sm/analytics/team-dashboard';

  //     // Build query parameters map
  //     final Map<String, String> queryParams = {};

  //     // Add time range parameter based on periodIndex or timeRange
  //     String? periodParam;
  //     if (periodIndex != null) {
  //       switch (periodIndex) {
  //         case 1:
  //           periodParam = 'MTD';
  //           break;
  //         case 0:
  //           periodParam = 'QTD';
  //           break;
  //         case 2:
  //           periodParam = 'YTD';
  //           break;
  //         default:
  //           periodParam = 'QTD';
  //       }
  //     } else if (timeRange != null) {
  //       switch (timeRange) {
  //         case '1D':
  //           periodParam = 'DAY';
  //           break;
  //         case '1W':
  //           periodParam = 'WEEK';
  //           break;
  //         case '1M':
  //           periodParam = 'MTD';
  //           break;
  //         case '1Q':
  //           periodParam = 'QTD';
  //           break;
  //         case '1Y':
  //           periodParam = 'YTD';
  //           break;
  //         default:
  //           periodParam = 'QTD';
  //       }
  //     } else {
  //       periodParam = 'QTD'; // Default
  //     }

  //     if (periodParam != null) {
  //       queryParams['type'] = periodParam;
  //     }

  //     // Handle user selection based on comparison mode
  //     if (isComparing &&
  //         selectedUserIds != null &&
  //         selectedUserIds.isNotEmpty) {
  //       // If comparison mode is ON, ONLY pass userIds (NO user_id)
  //       queryParams['userIds'] = selectedUserIds.join(',');
  //     } else if (!isComparing &&
  //         selectedProfileIndex != 0 &&
  //         selectedUserId != null &&
  //         selectedUserId.isNotEmpty) {
  //       // If comparison mode is OFF and specific user is selected, pass user_id
  //       queryParams['user_id'] = selectedUserId;
  //     }

  //     if (avatarAll &&
  //         totalPerformanceIds != null &&
  //         totalPerformanceIds.isNotEmpty) {
  //       queryParams['total_performance'] = totalPerformanceIds.join(',');
  //     }

  //     if (isAlphabetLogsMode &&
  //         logStatusAlphabet != null &&
  //         logStatusAlphabet.isNotEmpty) {
  //       queryParams['logs_userIds'] = logStatusAlphabet.join(',');
  //       queryParams['total_performance'] = logStatusAlphabet.join(',');
  //       print('📤 Sending logs_userIds: ${logStatusAlphabet.join(',')}');
  //     }

  //     // Build the final endpoint with query parameters
  //     if (queryParams.isNotEmpty) {
  //       final uri = Uri.parse('dummy').replace(queryParameters: queryParams);
  //       endpoint += uri.query.isNotEmpty ? '?${uri.query}' : '';
  //     }

  //     print('📤 API Endpoint: $endpoint'); // Debug print

  //     final String url = '$baseUrl$endpoint$periodParam';

  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     print('📥 Status Code: ${response.statusCode}');
  //     print('📥 Response: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonResponse = json.decode(response.body);

  //       return {
  //         'success': true,
  //         'data': jsonResponse['data'],
  //         'message': 'Team details fetched successfully',
  //         'timestamp': DateTime.now().toIso8601String(),
  //       };
  //     } else {
  //       final Map<String, dynamic> errorData = json.decode(response.body);
  //       final String errorMessage =
  //           errorData['message'] ?? 'Failed to load team details';

  //       print("Failed to load team details: $errorMessage");
  //       await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);

  //       return {
  //         'success': false,
  //         'data': {},
  //         'message': errorMessage,
  //         'status_code': response.statusCode,
  //       };
  //     }
  //   } catch (e) {
  //     print('Error fetching team details: $e');
  //     return {
  //       'success': false,
  //       'data': {},
  //       'message': 'Network error: ${e.toString()}',
  //     };
  //   }
  // }

  static Future<bool> favorite({required String taskId}) async {
    try {
      final token = await Storage.getToken();
      final response = await http.put(
        Uri.parse('${baseUrl}favourites/mark-fav/task/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Failed to mark favorite: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error in favorite(): $e');
      return false;
    }
  }

  static Future<bool> favoriteEvent({required String taskId}) async {
    try {
      final token = await Storage.getToken();
      final response = await http.put(
        Uri.parse('${baseUrl}favourites/mark-fav/task/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(response.body.toString());
        return true;
      } else {
        print(Uri.parse.toString());
        print('❌ Failed to mark favorite: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error in favorite(): $e');
      return false;
    }
  }

  static Future<bool> favoriteTestDrive({required String eventId}) async {
    try {
      final token = await Storage.getToken();
      final response = await http.put(
        Uri.parse('${baseUrl}favourites/mark-fav/event/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Failed to mark favorite: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error in favorite(): $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getAllVehicles() async {
    try {
      final token = await Storage.getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}users/vehicles/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {'success': true, 'data': data['data']['rows'] ?? []};
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // static Future<Map<String, dynamic>> vehicleSearch(String query) async {
  //   try {
  //     final token = await Storage.getToken();
  //     final response = await http.get(
  //       Uri.parse(
  //         '${baseUrl}search/vehicles?vehicle=${Uri.encodeComponent(query)}',
  //       ),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       return {'success': true, 'data': data['data']['suggestions'] ?? []};
  //     } else {
  //       return {
  //         'success': false,
  //         'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
  //       };
  //     }
  //   } catch (e) {
  //     return {'success': false, 'error': e.toString()};
  //   }
  // }

  static Future<Map<String, dynamic>> globalSearch(String query) async {
    try {
      final token = await Storage.getToken();

      final response = await http.get(
        Uri.parse('${baseUrl}search/global?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {'success': true, 'data': data['data']['results'] ?? []};
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getVehicle(String query) async {
    try {
      final token = await Storage.getToken();

      final response = await http.get(
        Uri.parse('${baseUrl}search/global?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {'success': true, 'data': data['data']['suggestions'] ?? []};
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to load dashboard data';
        print("Failed to load data: $errorMessage");

        // Check if unauthorized: status 401 or error message includes "unauthorized"
        await handleUnauthorizedIfNeeded(response.statusCode, errorMessage);
        ();
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> getOtp({required String eventId}) async {
    try {
      final token = await Storage.getToken();
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/events/$eventId/send-consent',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Sent OTP request for eventId: $eventId');
      print('📥 Status Code: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error in getOtp(): $e');
      return false;
    }
  }
}
