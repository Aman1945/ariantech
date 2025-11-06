import 'package:get/get.dart';
import 'package:flutter/material.dart'; 
import 'package:smartassist/superAdmin/pages/admin_teams.dart';
import 'package:smartassist/superAdmin/pages/calendar/admin_calendar_sm.dart';
import 'package:smartassist/superAdmin/pages/calendar/admin_calendar_timeline.dart';
import 'package:smartassist/superAdmin/pages/home_admin.dart';
import 'package:smartassist/utils/admin_is_manager.dart'; 

class AdminNavigationController extends GetxController {
  var selectedIndex = 0.obs;
  var userRole = ''.obs; // Observable to track user role
  var isLoading = true.obs; // Add loading state

  // Define screens corresponding to the navigation items
  List<Widget> get screens {
    // Base screens that everyone sees
    List<Widget> baseScreens = [
      // Always show HomeAdmin for AdminNavigationController
      HomeAdmin(greeting: '', leadId: ''),
      AdminCalendarTimeline(leadName: ''),
    ];

    // Insert MyTeams screen only for SM role
    if (userRole.value == "SM") {
      baseScreens.insert(0, const AdminTeams());
      baseScreens.insert(2, AdminCalendarSm(leadName: ''));
    } else {
      // Regular calendar screen for other roles
      baseScreens.add(AdminCalendarTimeline(leadName: ''));
    }

    return baseScreens;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    String? role = await AdminUserIdManager.getAdminRole();
    userRole.value = role ?? '';
    isLoading.value = false; // Mark as loaded
    _setInitialScreen();
  }

  void _setInitialScreen() {
    // For SM users, we can set default to teams screen if desired
    if (userRole.value == "SM") {
      selectedIndex.value = 0; // Teams screen
    } else {
      selectedIndex.value = 0; // Home screen (HomeAdmin)
    }
  }
}

// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:smartassist/pages/navbar_page/my_teams.dart';
// import 'package:smartassist/superAdmin/pages/home_admin.dart';
// import 'package:smartassist/utils/token_manager.dart';
// import 'package:smartassist/widgets/timeline_view_calender.dart';
// import 'package:smartassist/pages/Calendar/calendar_sm.dart';

// class AdminNavigationController extends GetxController {
//   var selectedIndex = 0.obs;
//   var userRole = ''.obs; // Observable to track user role

//   // Define screens corresponding to the navigation items
//   List<Widget> get screens {
//     // Base screens that everyone sees
//     List<Widget> baseScreens = [
//       // HomeScreen(greeting: '', leadId: ''),
//       HomeAdmin(greeting: '', leadId: ''),
//       // MyTeams screen is conditionally included below
//       CalendarWithTimeline(leadName: ''),
//     ];

//     // Insert MyTeams screen only for SM role
//     if (userRole.value == "SM") {
//       baseScreens.insert(0, const MyTeams());
//       baseScreens.insert(2, CalendarSm(leadName: ''));
//     } else {
//       // Regular calendar screen for other roles
//       baseScreens.add(CalendarWithTimeline(leadName: ''));
//     }

//     return baseScreens;
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     _loadUserRole();
//   }

//   Future<void> _loadUserRole() async {
//     String? role = await TokenManager.getUserRole();
//     userRole.value = role ?? '';
//     _setInitialScreen();
//   }

//   void _setInitialScreen() {
//     // For SM users, we can set default to teams screen if desired
//     if (userRole.value == "SM") {
//       selectedIndex.value = 0; // Teams screen
//     } else {
//       selectedIndex.value = 0; // Home screen
//     }
//   }
// }
