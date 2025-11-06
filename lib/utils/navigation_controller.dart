import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:smartassist/pages/Home/home_screen.dart';
import 'package:smartassist/pages/navbar_page/my_teams.dart';
import 'package:smartassist/pages/navbar_page/webview_screen.dart';
import 'package:smartassist/utils/token_manager.dart';
import 'package:smartassist/widgets/timeline_view_calender.dart';
import 'package:smartassist/pages/Calendar/calendar_sm.dart';

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;
  var userRole = ''.obs; // Observable to track user role

  // Define screens corresponding to the navigation items
  List<Widget> get screens {
    // Base screens that everyone sees
    List<Widget> baseScreens = [
      HomeScreen(greeting: '', leadId: ''),
      // MyTeams screen is conditionally included below
      CalendarWithTimeline(leadName: ''),
    ];

    // Insert MyTeams screen only for SM role
    if (userRole.value == "SM") {
      baseScreens.insert(0, const MyTeams());
      baseScreens.insert(2, CalendarSm(leadName: ''));
    } else {
      // Regular calendar screen for other roles
      baseScreens.add(CalendarWithTimeline(leadName: ''));
    }

    return baseScreens;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    String? role = await TokenManager.getUserRole();
    userRole.value = role ?? '';
    _setInitialScreen();
  }

  void _setInitialScreen() {
    // For SM users, we can set default to teams screen if desired
    if (userRole.value == "SM") {
      selectedIndex.value = 0; // Teams screen
    } else {
      selectedIndex.value = 0; // Home screen
    }
  }
}
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:smartassist/pages/Home/home_screen.dart'; 
// import 'package:smartassist/pages/navbar_page/my_teams.dart';  
// import 'package:smartassist/utils/token_manager.dart';
// import 'package:smartassist/widgets/timeline_view_calender.dart';
// import 'package:smartassist/pages/Calendar/calendar_sm.dart';

// class NavigationController extends GetxController {
//   var selectedIndex = 0.obs;
//   var userRole = ''.obs; // Observable to track user role

//   // Define screens corresponding to the navigation items
//   List<Widget> get screens {
//     // Base screens that everyone sees
//     List<Widget> baseScreens = [
// // mustafa.sayyed@ariantechsolutions.com
//       HomeScreen(greeting: '', leadId: ''),

//       // HomeAdmin(greeting: '', leadId: ''),
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
