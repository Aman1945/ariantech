// import 'package:get/get.dart';
// import 'package:smartassist/services/api_srv.dart' show LeadsSrv;

// class DashboardController extends GetxController {
//   // Observable variables
//   var isDashboardLoading = false.obs;
//   var isRefreshing = false.obs;
//   var hasInternet = true.obs;

//   var upcomingFollowups = <dynamic>[].obs;
//   var overdueFollowups = <dynamic>[].obs;
//   var upcomingAppointments = <dynamic>[].obs;
//   var overdueAppointments = <dynamic>[].obs;
//   var upcomingTestDrives = <dynamic>[].obs;
//   var overdueTestDrives = <dynamic>[].obs;

//   var overdueFollowupsCount = 0.obs;
//   var overdueAppointmentsCount = 0.obs;
//   var overdueTestDrivesCount = 0.obs;
//   var notificationCount = 0.obs;

//   var greeting = 'Welcome!'.obs;
//   var name = ''.obs;
//   var profilePicUrl = Rxn<String>();

//   @override
//   void onInit() {
//     super.onInit();
//     fetchDashboardData();
//   }

//   @override
//   void onResumed() {
//     // This will be called when returning to the screen
//     refreshData();
//   }

//   Future<void> fetchDashboardData({bool isRefresh = false}) async {
//     if (!isRefresh) {
//       isDashboardLoading.value = true;
//     } else {
//       isRefreshing.value = true;
//     }

//     try {
//       final data = await LeadsSrv.fetchDashboardData();

//       hasInternet.value = true;
//       upcomingFollowups.value = data['upcomingFollowups'] ?? [];
//       overdueFollowups.value = data['overdueFollowups'] ?? [];
//       upcomingAppointments.value = data['upcomingAppointments'] ?? [];
//       overdueAppointments.value = data['overdueAppointments'] ?? [];
//       upcomingTestDrives.value = data['upcomingTestDrives'] ?? [];
//       overdueTestDrives.value = data['overdueTestDrives'] ?? [];

//       overdueFollowupsCount.value =
//           data.containsKey('overdueFollowupsCount') &&
//               data['overdueFollowupsCount'] is int
//           ? data['overdueFollowupsCount']
//           : 0;

//       overdueAppointmentsCount.value =
//           data.containsKey('overdueAppointmentsCount') &&
//               data['overdueAppointmentsCount'] is int
//           ? data['overdueAppointmentsCount']
//           : 0;

//       overdueTestDrivesCount.value =
//           data.containsKey('overdueTestDrivesCount') &&
//               data['overdueTestDrivesCount'] is int
//           ? data['overdueTestDrivesCount']
//           : 0;

//       notificationCount.value =
//           data.containsKey('notifications') && data['notifications'] is int
//           ? data['notifications']
//           : 0;

//       greeting.value =
//           (data.containsKey('greetings') && data['greetings'] is String)
//           ? data['greetings']
//           : 'Welcome!';

//       name.value =
//           (data.containsKey('userData') &&
//               data['userData'] is Map &&
//               data['userData'].containsKey('initials') &&
//               data['userData']['initials'] is String &&
//               data['userData']['initials'].trim().isNotEmpty)
//           ? data['userData']['initials'].trim()
//           : '';

//       profilePicUrl.value = null;
//       if (data['userData'] != null && data['userData'] is Map) {
//         final userData = data['userData'] as Map<String, dynamic>;
//         if (userData['initials'] != null && userData['initials'] is String) {
//           name.value = userData['initials'].toString().trim();
//         }
//         if (userData['profile_pic'] != null &&
//             userData['profile_pic'] is String) {
//           profilePicUrl.value = userData['profile_pic'];
//         }
//       }
//     } catch (e) {
//       bool isNetworkError =
//           e.toString().contains('SocketException') ||
//           e.toString().contains('Failed host lookup') ||
//           e.toString().contains('Network is unreachable');

//       hasInternet.value = !isNetworkError;

//       print('Dashboard fetch error: $e');
//     } finally {
//       isDashboardLoading.value = false;
//       isRefreshing.value = false;
//     }
//   }

//   Future<void> refreshData() async {
//     await fetchDashboardData(isRefresh: true);
//   }
// }

import 'package:get/get.dart';
import 'package:smartassist/services/api_srv.dart' show LeadsSrv;

class DashboardController extends GetxController {
  // Observable variables
  var isDashboardLoading = false.obs;
  var isRefreshing = false.obs;
  var hasInternet = true.obs;

  var upcomingFollowups = <dynamic>[].obs;
  var overdueFollowups = <dynamic>[].obs;
  var upcomingAppointments = <dynamic>[].obs;
  var overdueAppointments = <dynamic>[].obs;
  var upcomingTestDrives = <dynamic>[].obs;
  var overdueTestDrives = <dynamic>[].obs;

  var overdueFollowupsCount = 0.obs;
  var overdueAppointmentsCount = 0.obs;
  var overdueTestDrivesCount = 0.obs;
  var notificationCount = 0.obs;

  var greeting = 'Welcome!'.obs;
  var name = ''.obs;
  var profilePicUrl = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  @override
  void onResumed() {
    // This will be called when returning to the screen
    refreshData();
  }

  Future<void> fetchDashboardData({bool isRefresh = false}) async {
    if (!isRefresh) {
      isDashboardLoading.value = true;
    } else {
      isRefreshing.value = true;
    }

    try {
      final data = await LeadsSrv.fetchDashboardData();

      hasInternet.value = true;
      upcomingFollowups.value = data['upcomingFollowups'] ?? [];
      overdueFollowups.value = data['overdueFollowups'] ?? [];
      upcomingAppointments.value = data['upcomingAppointments'] ?? [];
      overdueAppointments.value = data['overdueAppointments'] ?? [];
      upcomingTestDrives.value = data['upcomingTestDrives'] ?? [];
      overdueTestDrives.value = data['overdueTestDrives'] ?? [];

      overdueFollowupsCount.value =
          data.containsKey('overdueFollowupsCount') &&
              data['overdueFollowupsCount'] is int
          ? data['overdueFollowupsCount']
          : 0;

      overdueAppointmentsCount.value =
          data.containsKey('overdueAppointmentsCount') &&
              data['overdueAppointmentsCount'] is int
          ? data['overdueAppointmentsCount']
          : 0;

      overdueTestDrivesCount.value =
          data.containsKey('overdueTestDrivesCount') &&
              data['overdueTestDrivesCount'] is int
          ? data['overdueTestDrivesCount']
          : 0;

      notificationCount.value =
          data.containsKey('notifications') && data['notifications'] is int
          ? data['notifications']
          : 0;

      greeting.value =
          (data.containsKey('greetings') && data['greetings'] is String)
          ? data['greetings']
          : 'Welcome!';

      name.value =
          (data.containsKey('userData') &&
              data['userData'] is Map &&
              data['userData'].containsKey('initials') &&
              data['userData']['initials'] is String &&
              data['userData']['initials'].trim().isNotEmpty)
          ? data['userData']['initials'].trim()
          : '';

      profilePicUrl.value = null;
      if (data['userData'] != null && data['userData'] is Map) {
        final userData = data['userData'] as Map<String, dynamic>;
        if (userData['initials'] != null && userData['initials'] is String) {
          name.value = userData['initials'].toString().trim();
        }
        if (userData['profile_pic'] != null &&
            userData['profile_pic'] is String) {
          profilePicUrl.value = userData['profile_pic'];
        }
      }
    } catch (e) {
      bool isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable');

      hasInternet.value = !isNetworkError;

      print('Dashboard fetch error: $e');
    } finally {
      isDashboardLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    await fetchDashboardData(isRefresh: true);
  }
}
