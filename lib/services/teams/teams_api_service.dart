// services/teams/teams_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/config/model/teams/analytics_data.dart';
import 'package:smartassist/config/model/teams/team_member.dart';
import '../../utils/storage.dart';

class TeamsApiService {
  static const String _baseUrl = 'https://api.smartassistapp.in/api/users';

  // Get team details with performance data
  static Future<TeamsApiResponse> fetchTeamDetails({
    required int periodIndex,
    required int metricIndex,
    bool isComparing = false,
    Set<String> selectedUserIds = const {},
    String? selectedUserId,
    int selectedProfileIndex = 0,
  }) async {
    try {
      final token = await Storage.getToken();
      final queryParams = _buildTeamDetailsParams(
        periodIndex: periodIndex,
        metricIndex: metricIndex,
        isComparing: isComparing,
        selectedUserIds: selectedUserIds,
        selectedUserId: selectedUserId,
        selectedProfileIndex: selectedProfileIndex,
      );

      final uri = Uri.parse(
        '$_baseUrl/sm/analytics/team-dashboard',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] ?? {};
        return TeamsApiResponse.fromJson(data);
      } else {
        throw Exception('Failed to fetch team details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching team details: $e');
    }
  }

  // Get call analytics data
  static Future<AnalyticsData> fetchCallAnalytics({
    required int periodIndex,
  }) async {
    try {
      final token = await Storage.getToken();
      final queryParams = _buildAnalyticsParams(periodIndex);

      final uri = Uri.parse(
        '$_baseUrl/sm/dashboard/call-analytics',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] ?? {};
        return AnalyticsData.fromJson(data);
      } else {
        throw Exception('Failed to fetch analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get single user call log
  static Future<Map<String, dynamic>> fetchSingleUserCallLog({
    required String timeRange,
    String? userId,
  }) async {
    try {
      final token = await Storage.getToken();
      final queryParams = _buildSingleUserParams(timeRange, userId);

      final uri = Uri.parse(
        '$_baseUrl/ps/dashboard/call-analytics',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'] ?? {};
      } else {
        throw Exception('Failed to fetch call log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching call log: $e');
    }
  }

  // Helper method to build team details query parameters
  static Map<String, String> _buildTeamDetailsParams({
    required int periodIndex,
    required int metricIndex,
    bool isComparing = false,
    Set<String> selectedUserIds = const {},
    String? selectedUserId,
    int selectedProfileIndex = 0,
  }) {
    final queryParams = <String, String>{};

    // Add period parameter
    final periodParam = _getPeriodParam(periodIndex);
    if (periodParam != null) {
      queryParams['type'] = periodParam;
    }

    // Add metric parameters
    final metrics = _getMetricParams(metricIndex);
    queryParams['summary'] = metrics['summary']!;
    queryParams['target'] = metrics['target']!;

    // Add user selection parameters
    if (isComparing && selectedUserIds.isNotEmpty) {
      queryParams['userIds'] = selectedUserIds.join(',');
    } else if (!isComparing &&
        selectedProfileIndex != 0 &&
        selectedUserId != null &&
        selectedUserId.isNotEmpty) {
      queryParams['user_id'] = selectedUserId;
    }

    return queryParams;
  }

  // Helper method to build analytics query parameters
  static Map<String, String> _buildAnalyticsParams(int periodIndex) {
    final queryParams = <String, String>{};
    final periodParam = _getPeriodParam(periodIndex);
    if (periodParam != null) {
      queryParams['type'] = periodParam;
    }
    return queryParams;
  }

  // Helper method to build single user query parameters
  static Map<String, String> _buildSingleUserParams(
    String timeRange,
    String? userId,
  ) {
    final queryParams = <String, String>{};
    queryParams['type'] = _getTimeRangeParam(timeRange);
    if (userId != null && userId.isNotEmpty) {
      queryParams['user_id'] = userId;
    }
    return queryParams;
  }

  // Get period parameter
  static String? _getPeriodParam(int periodIndex) {
    switch (periodIndex) {
      case 1:
        return 'MTD';
      case 0:
        return 'QTD';
      case 2:
        return 'YTD';
      default:
        return 'QTD';
    }
  }

  // Get metric parameters
  static Map<String, String> _getMetricParams(int metricIndex) {
    const summaryMetrics = [
      'enquiries',
      'testDrives',
      'orders',
      'cancellation',
      'netOrders',
      'retail',
    ];
    const targetMetrics = [
      'target_enquiries',
      'target_testDrives',
      'target_orders',
      'target_cancellation',
      'target_netOrders',
      'target_retail',
    ];

    return {
      'summary': summaryMetrics[metricIndex],
      'target': targetMetrics[metricIndex],
    };
  }

  // Get time range parameter
  static String _getTimeRangeParam(String timeRange) {
    switch (timeRange) {
      case '1D':
        return 'DAY';
      case '1W':
        return 'WEEK';
      case '1M':
        return 'MTD';
      case '1Q':
        return 'QTD';
      case '1Y':
        return 'YTD';
      default:
        return 'DAY';
    }
  }
}

// Response model for team details API
class TeamsApiResponse {
  final Map<String, dynamic> summary;
  final Map<String, dynamic> totalPerformance;
  final List<TeamMember> allMembers;
  final List<dynamic> teamComparison;
  final Map<String, dynamic> selectedUserPerformance;

  TeamsApiResponse({
    required this.summary,
    required this.totalPerformance,
    required this.allMembers,
    required this.teamComparison,
    required this.selectedUserPerformance,
  });

  factory TeamsApiResponse.fromJson(Map<String, dynamic> json) {
    return TeamsApiResponse(
      summary: json['summary'] ?? {},
      totalPerformance: json['totalPerformance'] ?? {},
      allMembers: (json['allMember'] as List? ?? [])
          .map((member) => TeamMember.fromJson(member))
          .toList(),
      teamComparison: json['teamComparsion'] ?? [],
      selectedUserPerformance: json['selectedUserPerformance'] ?? {},
    );
  }
}
