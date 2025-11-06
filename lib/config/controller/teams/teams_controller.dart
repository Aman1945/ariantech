// controllers/teams/teams_controller.dart
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:smartassist/config/model/teams/activity_data.dart';
import 'package:smartassist/config/model/teams/analytics_data.dart';
import 'package:smartassist/config/model/teams/performance_data.dart';
import 'package:smartassist/config/model/teams/team_member.dart';
import 'package:smartassist/services/teams/teams_api_service.dart';

class TeamsController extends GetxController {
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingComparison = false.obs;

  // Team data
  final RxList<TeamMember> teamMembers = <TeamMember>[].obs;
  final RxMap<String, dynamic> teamData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> selectedUserData = <String, dynamic>{}.obs;

  // Analytics data
  final Rx<AnalyticsData?> analyticsData = Rx<AnalyticsData?>(null);
  final RxList<MemberAnalytics> membersAnalytics = <MemberAnalytics>[].obs;

  // Performance data
  final Rx<PerformanceData?> performanceData = Rx<PerformanceData?>(null);
  final RxList<dynamic> teamComparisonData = <dynamic>[].obs;

  // Activities data
  final RxList<ActivityData> upcomingFollowups = <ActivityData>[].obs;
  final RxList<ActivityData> upcomingAppointments = <ActivityData>[].obs;
  final RxList<ActivityData> upcomingTestDrives = <ActivityData>[].obs;
  final RxInt overdueCount = 0.obs;

  // Selection states
  final RxSet<String> selectedUserIds = <String>{}.obs;
  final RxSet<String> selectedLetters = <String>{}.obs;
  final RxString selectedUserId = ''.obs;
  final RxInt selectedProfileIndex = 0.obs;
  final RxString selectedType = 'All'.obs;
  final RxBool isComparing = false.obs;
  final RxBool isMultiSelectMode = false.obs;

  // Filter states
  final RxInt periodIndex = 0.obs; // QTD, MTD, YTD
  final RxInt metricIndex = 0.obs;
  final RxInt upcomingButtonIndex = 0.obs; // Upcoming/Overdue
  final RxString selectedTimeRange = '1D'.obs;
  final RxInt selectedTabIndex = 0.obs;

  // Display states
  final RxInt currentDisplayCount = 10.obs;
  final RxString sortColumn = ''.obs;
  final RxInt sortState = 0.obs;
  final RxList<dynamic> originalMembersData = <dynamic>[].obs;

  // UI states
  final RxBool isFabVisible = true.obs;
  final RxBool isHideAllcall = false.obs;
  final RxBool isHideActivities = false.obs;
  final RxBool isHide = false.obs;
  final RxBool isHideCalls = false.obs;

  // Constants
  static const int incrementCount = 10;
  static const int decrementCount = 10;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  // Initialize data
  Future<void> initialize() async {
    try {
      isLoading.value = true;
      await Future.wait([fetchTeamDetails(), fetchCallAnalytics()]);
    } catch (error) {
      print("Error during initialization: $error");
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch team details
  Future<void> fetchTeamDetails() async {
    try {
      if (isComparing.value && selectedUserIds.isEmpty) {
        isComparing.value = false;
        teamComparisonData.clear();
        return;
      }

      final response = await TeamsApiService.fetchTeamDetails(
        periodIndex: periodIndex.value,
        metricIndex: metricIndex.value,
        isComparing: isComparing.value,
        selectedUserIds: selectedUserIds,
        selectedUserId: selectedUserId.value.isEmpty
            ? null
            : selectedUserId.value,
        selectedProfileIndex: selectedProfileIndex.value,
      );

      // Update team data
      teamData.value = {
        'summary': response.summary,
        'totalPerformance': response.totalPerformance,
        'teamComparsion': response.teamComparison,
        'selectedUserPerformance': response.selectedUserPerformance,
      };

      // Update team members
      teamMembers.value = response.allMembers;

      // Update comparison data
      if (isComparing.value) {
        teamComparisonData.value = response.teamComparison;
      }

      // Update selected user data
      _updateSelectedUserData(response);

      // Update activities
      _updateActivitiesData(response.selectedUserPerformance);
    } catch (e) {
      print('Error fetching team details: $e');
    }
  }

  // Fetch call analytics
  Future<void> fetchCallAnalytics() async {
    try {
      final data = await TeamsApiService.fetchCallAnalytics(
        periodIndex: periodIndex.value,
      );
      analyticsData.value = data;
      membersAnalytics.value = data.members;
    } catch (e) {
      print('Error fetching call analytics: $e');
    }
  }

  // Fetch single user call log
  Future<void> fetchSingleUserCallLog() async {
    try {
      isLoading.value = true;
      final data = await TeamsApiService.fetchSingleUserCallLog(
        timeRange: selectedTimeRange.value,
        userId: selectedUserId.value.isEmpty ? null : selectedUserId.value,
      );
      // Handle single user call log data
      selectedUserData['dashboardData'] = data;
      selectedUserData['enquiryData'] = data['summaryEnquiry'];
      selectedUserData['coldCallData'] = data['summaryColdCalls'];
    } catch (e) {
      print('Error fetching single user call log: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Profile selection methods
  void selectProfile(int index, String userId) {
    if (isMultiSelectMode.value) {
      toggleUserSelection(userId);
    } else {
      if (selectedUserId.value == userId) {
        clearAllSelections();
      } else {
        selectedProfileIndex.value = index;
        selectedUserId.value = userId;
        selectedType.value = 'dynamic';
        fetchTeamDetails();
        fetchSingleUserCallLog();
      }
    }
    resetDisplayCount();
  }

  void selectAll() {
    selectedProfileIndex.value = 0;
    selectedType.value = 'All';
    selectedLetters.clear();
    isMultiSelectMode.value = false;
    isComparing.value = false;
    selectedUserIds.clear();
    teamComparisonData.clear();
    metricIndex.value = 0;
    fetchTeamDetails();
  }

  void toggleLetterSelection(String letter) {
    if (selectedLetters.contains(letter)) {
      selectedLetters.remove(letter);
      clearUsersFromLetter(letter);
      if (selectedLetters.isEmpty) {
        isMultiSelectMode.value = false;
        selectedType.value = 'All';
        selectedProfileIndex.value = 0;
      }
    } else {
      selectedLetters.add(letter);
      selectedType.value = 'Letter';
    }
    selectedProfileIndex.value = -1;
  }

  void toggleUserSelection(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
      if (selectedUserIds.isEmpty) {
        isMultiSelectMode.value = false;
      }
    } else {
      selectedUserIds.add(userId);
    }
  }

  void selectAllUsers() {
    bool allSelected = selectedUserIds.length == teamMembers.length;
    if (allSelected) {
      selectedUserIds.clear();
      selectedLetters.clear();
      selectedType.value = '';
    } else {
      isMultiSelectMode.value = true;
      selectedUserIds.clear();
      selectedUserIds.addAll(teamMembers.map((member) => member.userId));
      selectedLetters.clear();
      for (var member in teamMembers) {
        if (member.firstLetter.isNotEmpty) {
          selectedLetters.add(member.firstLetter);
        }
      }
      selectedType.value = 'Letter';
    }
  }

  void clearAllSelections() {
    selectedUserIds.clear();
    selectedLetters.clear();
    selectedProfileIndex.value = -1;
    selectedUserId.value = '';
    for (var member in membersAnalytics) {
      // Clear selection flags if needed
    }
  }

  void clearUsersFromLetter(String letter) {
    List<String> usersToRemove = [];
    for (String userId in selectedUserIds) {
      var member = teamMembers.firstWhere(
        (m) => m.userId == userId,
        orElse: () => TeamMember(
          userId: '',
          firstName: '',
          lastName: '',
          initials: '',
          profile: '',
        ),
      );
      if (member.firstLetter == letter) {
        usersToRemove.add(userId);
      }
    }
    for (String userId in usersToRemove) {
      selectedUserIds.remove(userId);
    }
  }

  // Comparison methods
  Future<void> startComparison() async {
    isComparing.value = true;
    teamComparisonData.clear();
    await Future.delayed(Duration(milliseconds: 50));
    await fetchTeamDetails();
  }

  // Filter methods
  void changePeriod(int index) {
    periodIndex.value = index;
    fetchTeamDetails();
  }

  void changeMetric(int index) {
    metricIndex.value = index;
    fetchTeamDetails();
  }

  void changeUpcomingFilter(int index) {
    upcomingButtonIndex.value = index;
    if (selectedProfileIndex.value == 0) return;

    final selectedUserPerformance = teamData['selectedUserPerformance'] ?? {};
    final upcoming = selectedUserPerformance['Upcoming'] ?? {};
    final overdue = selectedUserPerformance['Overdue'] ?? {};

    if (upcomingButtonIndex.value == 0) {
      upcomingFollowups.value = (upcoming['upComingFollowups'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.followup))
          .toList();
      upcomingAppointments
          .value = (upcoming['upComingAppointment'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.appointment))
          .toList();
      upcomingTestDrives.value = (upcoming['upComingTestDrive'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.testDrive))
          .toList();
    } else {
      upcomingFollowups.value = (overdue['overdueFollowups'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.followup))
          .toList();
      upcomingAppointments
          .value = (overdue['overdueAppointments'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.appointment))
          .toList();
      upcomingTestDrives.value = (overdue['overdueTestDrives'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.testDrive))
          .toList();

      overdueCount.value =
          upcomingFollowups.length +
          upcomingAppointments.length +
          upcomingTestDrives.length;
    }
  }

  void changeTimeRange(String newTimeRange) {
    selectedTimeRange.value = newTimeRange;
    fetchSingleUserCallLog();
  }

  void changeTab(int newTabIndex) {
    selectedTabIndex.value = newTabIndex;
    fetchSingleUserCallLog();
  }

  // Display methods
  void loadMoreRecords() {
    List<dynamic> dataToDisplay = getCurrentDataToDisplay();
    int newDisplayCount = math.min(
      currentDisplayCount.value + incrementCount,
      dataToDisplay.length,
    );
    currentDisplayCount.value = newDisplayCount;
  }

  void loadLessRecords() {
    currentDisplayCount.value = math.max(
      incrementCount,
      currentDisplayCount.value - incrementCount,
    );
  }

  void resetDisplayCount() {
    List<dynamic> currentData = getCurrentDataToDisplay();
    currentDisplayCount.value = math.min(incrementCount, currentData.length);
  }

  bool hasMoreRecords() {
    return currentDisplayCount.value < getCurrentDataToDisplay().length;
  }

  bool canShowLess() {
    return currentDisplayCount.value > incrementCount;
  }

  List<dynamic> getCurrentDataToDisplay() {
    if (isComparing.value &&
        selectedUserIds.isNotEmpty &&
        teamComparisonData.isNotEmpty) {
      return teamComparisonData;
    } else if (isComparing.value && selectedUserIds.isNotEmpty) {
      return membersAnalytics.where((member) {
        return selectedUserIds.contains(member.userId);
      }).toList();
    } else {
      return membersAnalytics;
    }
  }

  List<dynamic> getDisplayedData() {
    List<dynamic> dataToDisplay = getCurrentDataToDisplay();
    return dataToDisplay.take(currentDisplayCount.value).toList();
  }

  // Sorting methods
  void sortData(String column) {
    if (originalMembersData.isEmpty) {
      originalMembersData.value = List.from(membersAnalytics);
    }

    if (sortColumn.value == column) {
      sortState.value = (sortState.value + 1) % 3;
    } else {
      sortColumn.value = column;
      sortState.value = 1;
    }

    List<dynamic> dataToSort = getCurrentDataToDisplay();

    if (sortState.value == 0) {
      // Original order - sort by name descending
      dataToSort.sort((a, b) {
        String aName = (a['name'] ?? '').toString().toLowerCase();
        String bName = (b['name'] ?? '').toString().toLowerCase();
        return bName.compareTo(aName);
      });
    } else {
      // Sort by selected column
      dataToSort.sort((a, b) {
        var aValue = a[sortColumn.value];
        var bValue = b[sortColumn.value];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return sortState.value == 1 ? 1 : -1;
        if (bValue == null) return sortState.value == 1 ? -1 : 1;

        double aNum = double.tryParse(aValue.toString()) ?? 0;
        double bNum = double.tryParse(bValue.toString()) ?? 0;

        return sortState.value == 1
            ? bNum.compareTo(aNum)
            : aNum.compareTo(bNum);
      });
    }

    // Update the appropriate data source
    if (isComparing.value && teamComparisonData.isNotEmpty) {
      teamComparisonData.value = dataToSort;
    } else {
      membersAnalytics.value = List<MemberAnalytics>.from(dataToSort);
    }
  }

  // UI toggle methods
  void toggleFabVisibility(bool visible) {
    isFabVisible.value = visible;
  }

  void toggleHideAllCall() {
    isHideAllcall.value = !isHideAllcall.value;
  }

  void toggleHideActivities() {
    isHideActivities.value = !isHideActivities.value;
  }

  void toggleHide() {
    isHide.value = !isHide.value;
  }

  void toggleHideCalls() {
    isHideCalls.value = !isHideCalls.value;
  }

  // Computed properties
  bool get isOnlyLetterSelected =>
      selectedLetters.isNotEmpty &&
      selectedProfileIndex.value == -1 &&
      selectedUserId.value.isEmpty;

  bool get shouldShowCompareButton => selectedUserIds.length >= 2;

  PerformanceData? get currentPerformanceData {
    if (selectedProfileIndex.value > 0) {
      // Individual user
      final userStats = teamData['selectedUserPerformance'] ?? selectedUserData;
      return PerformanceData.fromJson(userStats);
    } else {
      // All users or team comparison
      final stats = (isMultiSelectMode.value || isComparing.value)
          ? (teamData["teamComparsion"] as List? ?? [])
                .where((member) => member["isSelected"] == true)
                .toList()
          : (teamData["teamComparsion"] as List? ?? []);

      if (stats.isNotEmpty) {
        // Aggregate from team members
        Map<String, int> aggregated = {
          'enquiries': 0,
          'testDrives': 0,
          'orders': 0,
          'cancellation': 0,
          'net_orders': 0,
          'retail': 0,
        };

        for (var member in stats) {
          aggregated.forEach((key, value) {
            aggregated[key] =
                value + (int.tryParse(member[key]?.toString() ?? '0') ?? 0);
          });
        }

        return PerformanceData.fromJson(aggregated);
      } else {
        // Fallback to totalPerformance for "All" selection
        final totalStats = selectedUserData['totalPerformance'] ?? {};
        return PerformanceData.fromJson(totalStats);
      }
    }
  }

  // Private helper methods
  void _updateSelectedUserData(response) {
    if (selectedProfileIndex.value == 0) {
      selectedUserData.value = response.summary;
      selectedUserData['totalPerformance'] = response.totalPerformance;
    } else if (selectedProfileIndex.value - 1 < teamMembers.length) {
      final selectedMember = teamMembers[selectedProfileIndex.value - 1];
      selectedUserData.value = selectedMember
          .toJson();  
      selectedUserData['totalPerformance'] = response.totalPerformance;
    }
  }

  void _updateActivitiesData(Map<String, dynamic> selectedUserPerformance) {
    if (selectedProfileIndex.value <= 0) return;

    final upcoming = selectedUserPerformance['Upcoming'] ?? {};
    final overdue = selectedUserPerformance['Overdue'] ?? {};

    if (upcomingButtonIndex.value == 0) {
      upcomingFollowups.value = (upcoming['upComingFollowups'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.followup))
          .toList();

          
      upcomingAppointments
          .value = (upcoming['upComingAppointment'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.appointment))
          .toList();
      upcomingTestDrives.value = (upcoming['upComingTestDrive'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.testDrive))
          .toList();
    } else {
      upcomingFollowups.value = (overdue['overdueFollowups'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.followup))
          .toList();
      upcomingAppointments
          .value = (overdue['overdueAppointments'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.appointment))
          .toList();
      upcomingTestDrives.value = (overdue['overdueTestDrives'] as List? ?? [])
          .map((item) => ActivityData.fromJson(item, ActivityType.testDrive))
          .toList();

      overdueCount.value =
          upcomingFollowups.length +
          upcomingAppointments.length +
          upcomingTestDrives.length;
    }
  }
}
