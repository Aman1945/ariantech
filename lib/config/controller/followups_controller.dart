import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/storage.dart';

class FollowupsController extends GetxController {
  // Observable lists
  final allTasks = <dynamic>[].obs;
  final upcomingTasks = <dynamic>[].obs;
  final overdueTasks = <dynamic>[].obs;

  // Observable counts
  final allCount = 0.obs;
  final upcomingCount = 0.obs;
  final overdueCount = 0.obs;

  // Loading state
  final isLoading = false.obs;

  Future<void> fetchTasks() async {
    isLoading.value = true;

    try {
      final token = await Storage.getToken();
      const String apiUrl = "https://api.smartassistapp.in/api/tasks/all-tasks";

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Update observables
        overdueCount.value =
            data['data']['overdueFollowupsCount']?['count'] ?? 0;
        // upcomingCount.value = data['data']['upcomingWeekTasks']?['count'] ?? 0;
        allCount.value = data['data']['allTasks']?['count'] ?? 0;

        allTasks.value = List<dynamic>.from(
          data['data']['allTasks']?['rows'] ?? [],
        );
        upcomingTasks.value = List<dynamic>.from(
          data['data']['upcomingWeekTasks']?['rows'] ?? [],
        );
        overdueTasks.value = List<dynamic>.from(
          data['data']['overdueWeekTasks']?['rows'] ?? [],
        );

        print('✅ Tasks fetched successfully');
      } else {
        print('❌ Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTasks() async {
    print('🔄 Refreshing tasks...');
    await fetchTasks();
    print('✅ Tasks refreshed');
  }
}
