import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:smartassist/pages/navbar_page/call_analytics.dart';
import 'package:smartassist/pages/navbar_page/customer_support.dart';
import 'package:smartassist/pages/navbar_page/favorite.dart';
import 'package:smartassist/pages/navbar_page/leads_all.dart';
import 'package:smartassist/pages/navbar_page/logout_page.dart';
import 'package:smartassist/pages/Home/reassign_enq.dart';
import 'package:smartassist/pages/Navigation/feedback_nav.dart'; 
import 'package:smartassist/utils/navigation_controller.dart' as nav_utils;
import 'package:smartassist/pages/navbar_page/bottom_tutorial.dart';

class BottomNavigation extends StatelessWidget {
  BottomNavigation({super.key});

  final nav_utils.NavigationController controller = Get.put(
    nav_utils.NavigationController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => controller.screens[controller.selectedIndex.value]),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // Calculate responsive icon size
  double _calculateIconSize(
    bool isExtraSmallScreen,
    bool isSmallScreen,
    bool isTablet,
  ) {
    if (isExtraSmallScreen) return 18;
    if (isSmallScreen) return 20;
    if (isTablet) return 28;
    return 22;
  }

  // Calculate responsive font size
  double _calculateFontSize(
    bool isExtraSmallScreen,
    bool isSmallScreen,
    bool isTablet,
  ) {
    if (isExtraSmallScreen) return 9;
    if (isSmallScreen) return 10;
    if (isTablet) return 14;
    return 12;
  }

  // Calculate responsive item padding
  EdgeInsets _calculateItemPadding(
    bool isExtraSmallScreen,
    bool isSmallScreen,
  ) {
    if (isExtraSmallScreen)
      return const EdgeInsets.symmetric(horizontal: 2, vertical: 2);
    if (isSmallScreen)
      return const EdgeInsets.symmetric(horizontal: 3, vertical: 3);
    return const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
  }

  // Calculate responsive spacing
  double _calculateSpacing(bool isExtraSmallScreen) {
    return isExtraSmallScreen ? 2 : 4;
  }

  // Calculate responsive scale multiplier
  double _calculateScaleMultiplier(
    bool isExtraSmallScreen,
    bool isSmallScreen,
  ) {
    if (isExtraSmallScreen) return 1.1;
    if (isSmallScreen) return 1.15;
    return 1.2;
  }

  double _calculateBottomNavHeight(
    double screenHeight,
    bool isExtraSmallScreen,
    bool isSmallScreen,
    bool isTablet,
  ) {
    if (isExtraSmallScreen) return 60;
    if (isSmallScreen) return 70;
    if (isTablet) return 90;
    return 80;
  }

  // Calculate responsive horizontal padding
  double _calculateHorizontalPadding(double screenWidth, bool isTablet) {
    if (isTablet) return screenWidth * 0.05; // 5% of screen width for tablets
    if (screenWidth < 320) return 4;
    if (screenWidth < 375) return 8;
    return 12;
  }

  // Calculate responsive vertical padding
  double _calculateVerticalPadding(
    bool isExtraSmallScreen,
    bool isSmallScreen,
  ) {
    if (isExtraSmallScreen) return 2;
    if (isSmallScreen) return 4;
    return 6;
  }

  // Update the method to not require a parameter
  Widget _buildBottomNavigationBar(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Define responsive breakpoints
    final isExtraSmallScreen = screenHeight < 550 || screenWidth < 320;
    final isSmallScreen = screenHeight < 650 || screenWidth < 375;
    final isTablet = screenWidth > 600;
    final aspectRatio = screenWidth / screenHeight;
    final isWideScreen = aspectRatio > 2.0; // For very wide screens

    // Calculate responsive dimensions
    final bottomNavHeight = _calculateBottomNavHeight(
      screenHeight,
      isExtraSmallScreen,
      isSmallScreen,
      isTablet,
    );
    final horizontalPadding = _calculateHorizontalPadding(
      screenWidth,
      isTablet,
    );
    final verticalPadding = _calculateVerticalPadding(
      isExtraSmallScreen,
      isSmallScreen,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: bottomNavHeight * 0.8,
            maxHeight: bottomNavHeight,
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Obx(() {
              List<Widget> navItems = [];

              //  List<Widget> navItems = [
              //   _buildNavItem(
              //     icon: Icons.home,
              //     label: 'Home',
              //     index: 0,
              //     isIcon: true,
              //     isImg: false,
              //   ),
              // ];

              // Insert Teams navigation only for SM role
              if (controller.userRole.value == "SM") {
                navItems.add(
                  _buildNavItem(
                    context: context,
                    icon: Icons.people,
                    label: 'My Team',
                    index: 0,
                    isIcon: true,
                    isImg: false,
                  ),
                );
                // Home comes second at index 1
                navItems.add(
                  _buildNavItem(
                    context: context,
                    icon: Icons.auto_graph_rounded,
                    label: 'Dashboard',
                    index: 1,
                    isIcon: true,
                    isImg: false,
                  ),
                );
              }

              if (controller.userRole.value == "SM") {
                // SM users: show icon-based Calendar nav item
                navItems.add(
                  _buildNavItem(
                    context: context,
                    isImg: true,
                    isIcon: false,
                    icon: Icons.calendar_month_outlined,
                    label: 'Calendar',
                    index: 2,
                    // isIcon: true,
                    img: Image.asset(
                      'assets/calendar.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              } else {
                navItems.add(
                  _buildNavItem(
                    context: context,
                    icon: Icons.auto_graph_rounded,
                    label: 'Dashboard',
                    index: 0,
                    isIcon: true,
                    isImg: false,
                  ),
                );

                navItems.add(
                  _buildNavItem(
                    context: context,
                    isImg: true,
                    isIcon: false,
                    img: Image.asset(
                      'assets/calendar.png',
                      fit: BoxFit.contain,
                    ),
                    label: 'Calendar',
                    index: 1,
                  ),
                );
              }

              // int xoxoIndex = controller.userRole.value == "SM" ? 3 : 2;
              // navItems.add(
              //   _buildNavItem(
              //     context: context,
              //     isImg: false,
              //     icon: Icons.new_releases,
              //     isIcon: true,
              //     label: 'xoxo',
              //     index: xoxoIndex,
              //   ),
              // );

              // Add More/Settings - index needs to be adjusted based on whether Teams is present
              int moreIndex = controller.userRole.value == "SM" ? 3 : 2;
              navItems.add(
                _buildNavItem(
                  context: context,
                  icon: Icons.more_horiz_sharp,
                  label: 'More',
                  index: moreIndex,
                  isIcon: true,
                  isImg: false,
                  onTap: () => _showMoreBottomSheet(context),
                ),
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navItems,
              );
            }),
          ),
        ),
      ),
    );
  }

  // Update this method to not require a controller parameter
  Widget _buildNavItem({
    required BuildContext context,
    Image? img,
    IconData? icon,
    required String label,
    required int index,
    bool isImg = false,
    bool isIcon = false,
    VoidCallback? onTap,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSelected = controller.selectedIndex.value == index;

    // Define responsive breakpoints
    final isExtraSmallScreen = screenHeight < 550 || screenWidth < 320;
    final isSmallScreen = screenHeight < 650 || screenWidth < 375;
    final isTablet = screenWidth > 600;

    // Calculate responsive dimensions
    final iconSize = _calculateIconSize(
      isExtraSmallScreen,
      isSmallScreen,
      isTablet,
    );
    final fontSize = _calculateFontSize(
      isExtraSmallScreen,
      isSmallScreen,
      isTablet,
    );
    final itemPadding = _calculateItemPadding(
      isExtraSmallScreen,
      isSmallScreen,
    );
    final spacing = _calculateSpacing(isExtraSmallScreen);
    final scaleMultiplier = _calculateScaleMultiplier(
      isExtraSmallScreen,
      isSmallScreen,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            HapticFeedback.lightImpact();
            controller.selectedIndex.value = index;
          }
        },
        child: Container(
          constraints: BoxConstraints(
            minWidth: isTablet ? 80 : 60,
            maxWidth: isTablet ? 120 : 90,
          ),

          child: Padding(
            // padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            padding: EdgeInsets.symmetric(
              horizontal: itemPadding.horizontal,
              vertical: itemPadding.vertical,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.2 : 1.0,
                  child: isImg && img != null
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              isSelected
                                  ? AppColors.colorsBlue
                                  : AppColors.iconGrey,
                              BlendMode.srcIn,
                            ),
                            child: img,
                          ),
                        )
                      : isIcon && icon != null
                      ? Icon(
                          icon,
                          color: isSelected
                              ? AppColors.colorsBlue
                              : AppColors.iconGrey,
                          size: 22,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected ? AppColors.colorsBlue : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateBottomSheetHeight(double screenHeight, bool isTablet) {
    final calculatedHeight = screenHeight * 0.4;
    final minHeight = isTablet ? 600.0 : 500.0;
    final maxHeight = isTablet ? 650.0 : 600.0;

    return calculatedHeight.clamp(minHeight, maxHeight);
  }

  // ✅ Show Bottom Sheet for More options
  void _showMoreBottomSheet(BuildContext context) async {
    String? teamRole = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString('user_role'),
    );

    try {
      final screenSize = MediaQuery.of(context).size;
      final screenHeight = screenSize.height;
      final isTablet = screenSize.width > 600;
      // Calculate responsive height
      final bottomSheetHeight = _calculateBottomSheetHeight(
        screenHeight,
        isTablet,
      );
      Get.bottomSheet(
        SafeArea(
          child: SingleChildScrollView(
            // scrollDirection: Axis.vertical,
            child: Container(
              // padding: const EdgeInsets.all(16),
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              height: teamRole == "Owner" ? 600 : 480,
              // height: 310,
              // height: bottomSheetHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                // scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_search, size: 28),
                      title: Text(
                        'My Enquiries',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () => Get.to(() => const AllLeads()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.call_outlined, size: 28),
                      title: Text(
                        'My Call Analysis',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () => Get.to(
                        () =>
                            const //CallLogs()
                            CallAnalytics(userId: '', userName: ''),
                      ),
                    ),

                    if (teamRole == "SM")
                      ListTile(
                        leading: const Icon(Icons.group, size: 28),
                        title: Text(
                          'Reassign Enquiries ',
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                        onTap: () => Get.to(() => const AllEnq()),
                      ),
                    ListTile(
                      leading: const Icon(Icons.star_border_rounded, size: 28),
                      title: Text(
                        'Favourites',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () => Get.to(() => const FavoritePage(leadId: '')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_outlined, size: 28),
                      title: Text(
                        'Raise a ticket',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () =>
                          Get.to(() => FeedbackForm(userId: '', userName: '')),
                    ),

                    ListTile(
                      leading: const Icon(Icons.video_collection, size: 28),
                      title: Text(
                        'Tutorial',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () => Get.to(() => MenuListWidget()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.message, size: 28),
                      title: Text(
                        'Help & Support',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () => Get.to(() => CustomerSupportPage()),
                    ),

                    // ListTile(
                    //   leading: const Icon(Icons.android_rounded , size: 28),
                    //   title: Text(
                    //     'XOXO',
                    //     style: GoogleFonts.poppins(fontSize: 18),
                    //   ),
                    //   onTap: () => Get.to(() => SmartAssistWebView()),
                    // ),
                    ListTile(
                      leading: const Icon(Icons.logout_outlined, size: 28),
                      title: Text(
                        'Logout',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      onTap: () => Get.to(() => const LogoutPage()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing bottom sheet: $e');
      // Show a simple snackbar as fallback
      Get.snackbar(
        'Navigation',
        'More options temporarily unavailable',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/services.dart';
// import 'package:smartassist/pages/navbar_page/call_analytics.dart';
// import 'package:smartassist/pages/navbar_page/customer_support.dart';
// import 'package:smartassist/pages/navbar_page/favorite.dart';
// import 'package:smartassist/pages/navbar_page/leads_all.dart';
// import 'package:smartassist/pages/navbar_page/logout_page.dart';
// import 'package:smartassist/pages/Home/reassign_enq.dart';
// import 'package:smartassist/pages/Navigation/feedback_nav.dart';
// import 'package:smartassist/utils/navigation_controller.dart' as nav_utils;
// import 'package:smartassist/pages/navbar_page/bottom_tutorial.dart';

// class BottomNavigation extends StatelessWidget {
//   BottomNavigation({super.key});

//   final nav_utils.NavigationController controller = Get.put(
//     nav_utils.NavigationController(),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Obx(() => controller.screens[controller.selectedIndex.value]),
//         ],
//       ),
//       bottomNavigationBar: _buildBottomNavigationBar(context),
//     );
//   }

//   // Calculate responsive icon size
//   double _calculateIconSize(
//     bool isExtraSmallScreen,
//     bool isSmallScreen,
//     bool isTablet,
//   ) {
//     if (isExtraSmallScreen) return 18;
//     if (isSmallScreen) return 20;
//     if (isTablet) return 28;
//     return 22;
//   }

//   // Calculate responsive font size
//   double _calculateFontSize(
//     bool isExtraSmallScreen,
//     bool isSmallScreen,
//     bool isTablet,
//   ) {
//     if (isExtraSmallScreen) return 9;
//     if (isSmallScreen) return 10;
//     if (isTablet) return 14;
//     return 12;
//   }

//   // Calculate responsive item padding
//   EdgeInsets _calculateItemPadding(
//     bool isExtraSmallScreen,
//     bool isSmallScreen,
//   ) {
//     if (isExtraSmallScreen)
//       return const EdgeInsets.symmetric(horizontal: 2, vertical: 2);
//     if (isSmallScreen)
//       return const EdgeInsets.symmetric(horizontal: 3, vertical: 3);
//     return const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
//   }

//   // Calculate responsive spacing
//   double _calculateSpacing(bool isExtraSmallScreen) {
//     return isExtraSmallScreen ? 2 : 4;
//   }

//   // Calculate responsive scale multiplier
//   double _calculateScaleMultiplier(
//     bool isExtraSmallScreen,
//     bool isSmallScreen,
//   ) {
//     if (isExtraSmallScreen) return 1.1;
//     if (isSmallScreen) return 1.15;
//     return 1.2;
//   }

//   double _calculateBottomNavHeight(
//     double screenHeight,
//     bool isExtraSmallScreen,
//     bool isSmallScreen,
//     bool isTablet,
//   ) {
//     if (isExtraSmallScreen) return 60;
//     if (isSmallScreen) return 70;
//     if (isTablet) return 90;
//     return 80;
//   }

//   // Calculate responsive horizontal padding
//   double _calculateHorizontalPadding(double screenWidth, bool isTablet) {
//     if (isTablet) return screenWidth * 0.05; // 5% of screen width for tablets
//     if (screenWidth < 320) return 4;
//     if (screenWidth < 375) return 8;
//     return 12;
//   }

//   // Calculate responsive vertical padding
//   double _calculateVerticalPadding(
//     bool isExtraSmallScreen,
//     bool isSmallScreen,
//   ) {
//     if (isExtraSmallScreen) return 2;
//     if (isSmallScreen) return 4;
//     return 6;
//   }

//   // Update the method to not require a parameter
//   Widget _buildBottomNavigationBar(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenHeight = screenSize.height;
//     final screenWidth = screenSize.width;

//     // Define responsive breakpoints
//     final isExtraSmallScreen = screenHeight < 550 || screenWidth < 320;
//     final isSmallScreen = screenHeight < 650 || screenWidth < 375;
//     final isTablet = screenWidth > 600;
//     final aspectRatio = screenWidth / screenHeight;
//     final isWideScreen = aspectRatio > 2.0; // For very wide screens

//     // Calculate responsive dimensions
//     final bottomNavHeight = _calculateBottomNavHeight(
//       screenHeight,
//       isExtraSmallScreen,
//       isSmallScreen,
//       isTablet,
//     );
//     final horizontalPadding = _calculateHorizontalPadding(
//       screenWidth,
//       isTablet,
//     );
//     final verticalPadding = _calculateVerticalPadding(
//       isExtraSmallScreen,
//       isSmallScreen,
//     );

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 10,
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minHeight: bottomNavHeight * 0.8,
//             maxHeight: bottomNavHeight,
//           ),

//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 0),
//             child: Obx(() {
//               List<Widget> navItems = [];

//               //  List<Widget> navItems = [
//               //   _buildNavItem(
//               //     icon: Icons.home,
//               //     label: 'Home',
//               //     index: 0,
//               //     isIcon: true,
//               //     isImg: false,
//               //   ),
//               // ];

//               // Insert Teams navigation only for SM role
//               if (controller.userRole.value == "SM") {
//                 navItems.add(
//                   _buildNavItem(
//                     context: context,
//                     icon: Icons.people,
//                     label: 'My Team',
//                     index: 0,
//                     isIcon: true,
//                     isImg: false,
//                   ),
//                 );
//                 // Home comes second at index 1
//                 navItems.add(
//                   _buildNavItem(
//                     context: context,
//                     icon: Icons.auto_graph_rounded,
//                     label: 'Dashboard',
//                     index: 1,
//                     isIcon: true,
//                     isImg: false,
//                   ),
//                 );
//               }

//               if (controller.userRole.value == "SM") {
//                 // SM users: show icon-based Calendar nav item
//                 navItems.add(
//                   _buildNavItem(
//                     context: context,
//                     isImg: true,
//                     isIcon: false,
//                     icon: Icons.calendar_month_outlined,
//                     label: 'Calendar',
//                     index: 2,
//                     // isIcon: true,
//                     img: Image.asset(
//                       'assets/calendar.png',
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 );
//               } else {
//                 navItems.add(
//                   _buildNavItem(
//                     context: context,
//                     icon: Icons.auto_graph_rounded,
//                     label: 'Dashboard',
//                     index: 0,
//                     isIcon: true,
//                     isImg: false,
//                   ),
//                 );

//                 navItems.add(
//                   _buildNavItem(
//                     context: context,
//                     isImg: true,
//                     isIcon: false,
//                     img: Image.asset(
//                       'assets/calendar.png',
//                       fit: BoxFit.contain,
//                     ),
//                     label: 'Calendar',
//                     index: 1,
//                   ),
//                 );
//               }

//               // int xoxoIndex = controller.userRole.value == "SM" ? 3 : 2;
//               // navItems.add(
//               //   _buildNavItem(
//               //     context: context,
//               //     isImg: false,
//               //     icon: Icons.new_releases,
//               //     isIcon: true,
//               //     label: 'xoxo',
//               //     index: xoxoIndex,
//               //   ),
//               // );

//               // Add More/Settings - index needs to be adjusted based on whether Teams is present
//               int moreIndex = controller.userRole.value == "SM" ? 3 : 2;
//               navItems.add(
//                 _buildNavItem(
//                   context: context,
//                   icon: Icons.more_horiz_sharp,
//                   label: 'More',
//                   index: moreIndex,
//                   isIcon: true,
//                   isImg: false,
//                   onTap: () => _showMoreBottomSheet(context),
//                 ),
//               );

//               return Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: navItems,
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }

//   // Update this method to not require a controller parameter
//   Widget _buildNavItem({
//     required BuildContext context,
//     Image? img,
//     IconData? icon,
//     required String label,
//     required int index,
//     bool isImg = false,
//     bool isIcon = false,
//     VoidCallback? onTap,
//   }) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenHeight = screenSize.height;
//     final screenWidth = screenSize.width;
//     final isSelected = controller.selectedIndex.value == index;

//     // Define responsive breakpoints
//     final isExtraSmallScreen = screenHeight < 550 || screenWidth < 320;
//     final isSmallScreen = screenHeight < 650 || screenWidth < 375;
//     final isTablet = screenWidth > 600;

//     // Calculate responsive dimensions
//     final iconSize = _calculateIconSize(
//       isExtraSmallScreen,
//       isSmallScreen,
//       isTablet,
//     );
//     final fontSize = _calculateFontSize(
//       isExtraSmallScreen,
//       isSmallScreen,
//       isTablet,
//     );
//     final itemPadding = _calculateItemPadding(
//       isExtraSmallScreen,
//       isSmallScreen,
//     );
//     final spacing = _calculateSpacing(isExtraSmallScreen);
//     final scaleMultiplier = _calculateScaleMultiplier(
//       isExtraSmallScreen,
//       isSmallScreen,
//     );
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () {
//           if (onTap != null) {
//             onTap();
//           } else {
//             HapticFeedback.lightImpact();
//             controller.selectedIndex.value = index;
//           }
//         },
//         child: Container(
//           constraints: BoxConstraints(
//             minWidth: isTablet ? 80 : 60,
//             maxWidth: isTablet ? 120 : 90,
//           ),

//           child: Padding(
//             // padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
//             padding: EdgeInsets.symmetric(
//               horizontal: itemPadding.horizontal,
//               vertical: itemPadding.vertical,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 AnimatedScale(
//                   duration: const Duration(milliseconds: 200),
//                   scale: isSelected ? 1.2 : 1.0,
//                   child: isImg && img != null
//                       ? SizedBox(
//                           height: 24,
//                           width: 24,
//                           child: ColorFiltered(
//                             colorFilter: ColorFilter.mode(
//                               isSelected
//                                   ? AppColors.colorsBlue
//                                   : AppColors.iconGrey,
//                               BlendMode.srcIn,
//                             ),
//                             child: img,
//                           ),
//                         )
//                       : isIcon && icon != null
//                       ? Icon(
//                           icon,
//                           color: isSelected
//                               ? AppColors.colorsBlue
//                               : AppColors.iconGrey,
//                           size: 22,
//                         )
//                       : const SizedBox.shrink(),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   label,
//                   style: GoogleFonts.poppins(
//                     fontSize: 12,
//                     fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
//                     color: isSelected ? AppColors.colorsBlue : Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   double _calculateBottomSheetHeight(double screenHeight, bool isTablet) {
//     final calculatedHeight = screenHeight * 0.4;
//     final minHeight = isTablet ? 600.0 : 500.0;
//     final maxHeight = isTablet ? 650.0 : 600.0;

//     return calculatedHeight.clamp(minHeight, maxHeight);
//   }

//   // ✅ Show Bottom Sheet for More options
//   void _showMoreBottomSheet(BuildContext context) async {
//     String? teamRole = await SharedPreferences.getInstance().then(
//       (prefs) => prefs.getString('user_role'),
//     );

//     try {
//       final screenSize = MediaQuery.of(context).size;
//       final screenHeight = screenSize.height;
//       final isTablet = screenSize.width > 600;
//       // Calculate responsive height
//       final bottomSheetHeight = _calculateBottomSheetHeight(
//         screenHeight,
//         isTablet,
//       );
//       Get.bottomSheet(
//         SingleChildScrollView(
//           // scrollDirection: Axis.vertical,
//           child: Container(
//             // padding: const EdgeInsets.all(16),
//             padding: EdgeInsets.all(isTablet ? 24 : 16),
//             height: teamRole == "Owner" ? 600 : 480,
//             // height: 310,
//             // height: bottomSheetHeight,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//             ),
//             child: SingleChildScrollView(
//               // scrollDirection: Axis.vertical,
//               child: Column(
//                 children: [
//                   ListTile(
//                     leading: const Icon(Icons.person_search, size: 28),
//                     title: Text(
//                       'My Enquiries',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () => Get.to(() => const AllLeads()),
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.call_outlined, size: 28),
//                     title: Text(
//                       'My Call Analysis',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () => Get.to(
//                       () =>
//                           const //CallLogs()
//                           CallAnalytics(userId: '', userName: ''),
//                     ),
//                   ),

//                   if (teamRole == "SM")
//                     ListTile(
//                       leading: const Icon(Icons.group, size: 28),
//                       title: Text(
//                         'Reassign Enquiries ',
//                         style: GoogleFonts.poppins(fontSize: 18),
//                       ),
//                       onTap: () => Get.to(() => const AllEnq()),
//                     ),
//                   ListTile(
//                     leading: const Icon(Icons.star_border_rounded, size: 28),
//                     title: Text(
//                       'Favourites',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () => Get.to(() => const FavoritePage(leadId: '')),
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.receipt_outlined, size: 28),
//                     title: Text(
//                       'Raise a ticket',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () =>
//                         Get.to(() => FeedbackForm(userId: '', userName: '')),
//                   ),

//                   ListTile(
//                     leading: const Icon(Icons.video_collection, size: 28),
//                     title: Text(
//                       'Tutorial',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () => Get.to(() => MenuListWidget()),
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.message, size: 28),
//                     title: Text(
//                       'Help & Support',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () => Get.to(() => CustomerSupportPage()),
//                   ),

//                   // ListTile(
//                   //   leading: const Icon(Icons.android_rounded, size: 28),
//                   //   title: Text(
//                   //     'XOXO',
//                   //     style: GoogleFonts.poppins(fontSize: 18),
//                   //   ),
//                   //   onTap: () => Get.to(() => SmartAssistWebView()),
//                   // ),
//                   ListTile(
//                     leading: const Icon(Icons.logout_outlined, size: 28),
//                     title: Text(
//                       'Logout',
//                       style: GoogleFonts.poppins(fontSize: 18),
//                     ),
//                     onTap: () => Get.to(() => const LogoutPage()),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error showing bottom sheet: $e');
//       // Show a simple snackbar as fallback
//       Get.snackbar(
//         'Navigation',
//         'More options temporarily unavailable',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
// }
