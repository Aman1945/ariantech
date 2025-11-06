import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/config/route/route_name.dart';
import 'package:smartassist/utils/token_manager.dart';

// Future<T> processResponse<T>(
//   http.Response response,
//   T Function(Map<String, dynamic> data) onSuccess,
// ) async {
//   if (response.statusCode == 401) {
//     await TokenManager.clearAuthData();
//     Get.offAllNamed(RoutesName.splashScreen);
//     Get.snackbar('Error', "Someone Login on the same I'ds'");
//     throw Exception('Unauthorized. Redirecting to login.');
//   } else if (response.statusCode >= 200 && response.statusCode < 300) {
//     final Map<String, dynamic> data = json.decode(response.body);
//     return onSuccess(data);
//   } else {
//     final Map<String, dynamic> errorData = json.decode(response.body);
//     throw Exception(errorData['message'] ?? 'Error: ${response.statusCode}');
//   }
// }

Future<T> processResponse<T>(
  http.Response response,
  T Function(Map<String, dynamic> data) onSuccess,
) async {
  if (response.statusCode == 401) {
    // Clear auth data first
    await TokenManager.clearAll();

    // Navigate to login
    Get.offAllNamed(RoutesName.login);

    // Show snackbar after navigation
    Future.delayed(Duration(milliseconds: 300), () {
      Get.snackbar(
        'Session Expired',
        "Someone logged in with the same credentials",
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
      );
    });

    throw Exception('Unauthorized. Redirecting to login.');
  } else if (response.statusCode >= 200 && response.statusCode < 300) {
    final Map<String, dynamic> data = json.decode(response.body);
    return onSuccess(data);
  } else {
    final Map<String, dynamic> errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Error: ${response.statusCode}');
  }
}
