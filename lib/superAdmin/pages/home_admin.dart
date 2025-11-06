import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/controller/tab_controller.dart';
import 'package:smartassist/config/getX/fab.controller.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/superAdmin/widgets/admin_notification.dart';
import 'package:smartassist/superAdmin/widgets/home_analysis_admin_performance.dart';
import 'package:smartassist/superAdmin/widgets/home_analysisc_admin.dart';
import 'package:smartassist/superAdmin/widgets/threebtn_admin.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/widgets/home_btn.dart/dashboard_analytics_one.dart';
import 'package:smartassist/widgets/internet_exception.dart';

class HomeAdmin extends StatefulWidget {
  final String greeting;
  final String leadId;

  const HomeAdmin({super.key, required this.greeting, required this.leadId});

  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  final GlobalKey<BottomBtnSecondState> _bottomBtnSecondKey =
      GlobalKey<BottomBtnSecondState>();

  Future<void> _refreshDashboard() async {
    _bottomBtnSecondKey.currentState?.refreshData();
  }

  bool _isLoading = false;
  bool hasInternet = true;
  bool isRefreshing = false;
  int _currentTabIndex = 0; // Track which tab is active
  late TabControllerNew _tabController;
  String? leadId;
  bool _isHidden = false;
  String greeting = '';
  String name = '';
  int notificationCount = 0;
  int overdueFollowupsCount = 0;
  int overdueAppointmentsCount = 0;
  int overdueTestDrivesCount = 0;
  List<dynamic> upcomingFollowups = [];
  List<dynamic> overdueFollowups = [];
  List<dynamic> upcomingAppointments = [];
  List<dynamic> overdueAppointments = [];
  List<dynamic> upcomingTestDrives = [];
  List<dynamic> overdueTestDrives = [];
  bool isDashboardLoading = true;
  String? teamRole;

  String? profilePicUrl; // Make nullable
  Map<String, dynamic> dashboardData = {};
  Map<String, dynamic> MtdData = {};
  Map<String, dynamic> QtdData = {};
  Map<String, dynamic> YtdData = {};
  // Search Functionality
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoadingSearch = false;

  // exit popup
  DateTime? _lastBackPressTime;
  final int _exitTimeInMillis = 2000;

  // Initialize the controller
  final FabController fabController = Get.put(FabController());

  @override
  void initState() {
    super.initState();
    _tabController = TabControllerNew();
    _tabController.addListener(_onTabChanged);

    // Move async operations to after controller initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("🔄 setState called in ${this.runtimeType}");
      fetchDashboardData();
      _loadDashboardAnalytics();
      _loadTeamRole();
      // uploadCallLogsAfterLogin();
    });
  }

  Future<void> _loadDashboardAnalytics() async {
    setState(() {
      isDashboardLoading = true;
    });
    try {
      final data = await LeadsSrv.fetchDashboardAnalytics();
      setState(() {
        MtdData = data['MTD'] ?? {};
        QtdData = data['QTD'] ?? {};
        YtdData = data['YTD'] ?? {};
      });
    } catch (e) {
      print("Error loading analytics: $e");
    }
  }

  Future<void> _loadTeamRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teamRole = prefs.getString('USER_ROLE');
    });
    // Print all relevant keys
    print('USER_ROLE value: ${prefs.getString('USER_ROLE')}');
    print('All keys: ${prefs.getKeys()}');
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleFormSubmit() async {
    print("🔄 Dashboard refresh called from ProfileScreen");

    setState(() {
      isRefreshing = true;
    });

    await fetchDashboardData(isRefresh: true);

    // Force UI update
    if (mounted) {
      setState(() {
        print("✅ Dashboard UI refreshed");
      });
    }

    print("✅ Dashboard refresh completed");
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> reloadanalysis() async {
    // Refresh the BottomBtnSecond widget data
    if (_bottomBtnSecondKey.currentState != null) {
      await _bottomBtnSecondKey.currentState!.refreshDashboardData();
    }
  }

  Future<void> fetchDashboardData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        isDashboardLoading = true;
      });
    } else {
      setState(() {
        isRefreshing = true;
      });
    }
    try {
      final data = await LeadsSrv.adminFetchDashboardData();
      if (mounted) {
        setState(() {
          hasInternet = true;
          upcomingFollowups = data['upcomingFollowups'];
          overdueFollowups = data['overdueFollowups'];
          upcomingAppointments = data['upcomingAppointments'];
          overdueAppointments = data['overdueAppointments'];
          upcomingTestDrives = data['upcomingTestDrives'];
          overdueTestDrives = data['overdueTestDrives'];
          overdueFollowupsCount =
              data.containsKey('overdueFollowupsCount') &&
                  data['overdueFollowupsCount'] is int
              ? data['overdueFollowupsCount']
              : 0;

          overdueAppointmentsCount =
              data.containsKey('overdueAppointmentsCount') &&
                  data['overdueAppointmentsCount'] is int
              ? data['overdueAppointmentsCount']
              : 0;

          overdueTestDrivesCount =
              data.containsKey('overdueTestDrivesCount') &&
                  data['overdueTestDrivesCount'] is int
              ? data['overdueTestDrivesCount']
              : 0;

          notificationCount =
              data.containsKey('notifications') && data['notifications'] is int
              ? data['notifications']
              : 0;
          greeting =
              (data.containsKey('greetings') && data['greetings'] is String)
              ? data['greetings']
              : 'Welcome!';

          name =
              (data.containsKey('userData') &&
                  data['userData'] is Map &&
                  data['userData'].containsKey('initials') &&
                  data['userData']['initials'] is String &&
                  data['userData']['initials'].trim().isNotEmpty)
              ? data['userData']['initials'].trim()
              : '';

          profilePicUrl = null;
          if (data['userData'] != null && data['userData'] is Map) {
            final userData = data['userData'] as Map<String, dynamic>;
            if (userData['initials'] != null &&
                userData['initials'] is String) {
              name = userData['initials'].toString().trim();
            }
            if (userData['profile_pic'] != null &&
                userData['profile_pic'] is String) {
              profilePicUrl = userData['profile_pic'];
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      bool isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable');

      setState(() {
        hasInternet = !isNetworkError;
      });

      print('Dashboard fetch error: $e');
      // showErrorMessage(context, message: e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        isDashboardLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> onrefreshToggle() async {
    await fetchDashboardData(isRefresh: true);
  }

  // Handle tab change from popup
  void _handleTabChangeFromPopup(int tabIndex) {
    // Use controller to change tab
    _tabController.changeTab(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet && dashboardData.isEmpty) {
      return InternetException(
        onRetry: () {
          fetchDashboardData();
        },
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveFontSize = screenWidth * 0.035;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.colorsBlue,
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        _isLoading = true; // Step 1: show loader
                      });

                      await AdminUserIdManager.clearAll(); // Step 2: clear ID

                      if (!mounted) return;

                      Get.offAll(() => AdminDealerall());
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                        ),

                        SizedBox(width: 10),
                        Text(
                          AdminUserIdManager.adminNameSync ?? "No Name",
                          style: AppFont.dropDowmLabelWhite(context),
                        ),

                        // Text(
                        //   "${AdminUserIdManager.getAdminName().toString()}",
                        //   textAlign: TextAlign.start,
                        //   style: AppFont.dropDowmLabelWhite(context),
                        // ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminNotification(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications),
                        color: Colors.white,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: AppColors.sideRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                              maxWidth: 20,
                              maxHeight: 20,
                            ),
                            child: Text(
                              notificationCount.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              body: Stack(
                children: [
                  SafeArea(
                    child: RefreshIndicator(
                      onRefresh: onrefreshToggle,
                      child:
                          // isDashboardLoading
                          //     ? SkeletonHomepage()
                          //     :
                          SingleChildScrollView(
                            controller: fabController.scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              children: [
                                SizedBox(height: 10),

                                /// ✅ Row with Menu, Search Bar, and Microphone
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: Container(
                                //         margin: const EdgeInsets.symmetric(
                                //           horizontal: 15,
                                //           vertical: 10,
                                //         ),
                                //         child: SizedBox(
                                //           height: 40,
                                //           child: TextField(
                                //             readOnly: true,
                                //             onTap: () {
                                //               Get.to(
                                //                 () => const GlobalSearch(),
                                //               );
                                //             },
                                //             textAlignVertical:
                                //                 TextAlignVertical.center,
                                //             decoration: InputDecoration(
                                //               enabledBorder: OutlineInputBorder(
                                //                 borderRadius:
                                //                     BorderRadius.circular(30),
                                //                 borderSide: BorderSide.none,
                                //               ),
                                //               contentPadding: EdgeInsets.zero,
                                //               filled: true,
                                //               fillColor: AppColors.containerBg,
                                //               hintText:
                                //                   'Search by name, email or phone',
                                //               hintStyle: GoogleFonts.poppins(
                                //                 fontSize: responsiveFontSize,
                                //                 color: AppColors.fontColor,
                                //                 fontWeight: FontWeight.w400,
                                //               ),
                                //               prefixIcon: const Icon(
                                //                 FontAwesomeIcons
                                //                     .magnifyingGlass,
                                //                 color: AppColors.iconGrey,
                                //                 size: 15,
                                //               ),
                                //               border: OutlineInputBorder(
                                //                 borderRadius:
                                //                     BorderRadius.circular(30),
                                //                 borderSide: BorderSide.none,
                                //               ),
                                //               suffixIcon: Padding(
                                //                 padding:
                                //                     const EdgeInsets.symmetric(
                                //                       vertical: 2,
                                //                     ),
                                //                 child: GestureDetector(
                                //                   onTap: () {
                                //                     Navigator.push(
                                //                       context,
                                //                       MaterialPageRoute(
                                //                         builder: (context) =>
                                //                             ProfileScreen(
                                //                               refreshDashboard:
                                //                                   _handleFormSubmit,
                                //                             ),
                                //                       ),
                                //                     );
                                //                   },
                                //                   child: Container(
                                //                     width: 28,
                                //                     height: 28,
                                //                     // decoration: BoxDecoration(
                                //                     //   color: AppColors
                                //                     //       .backgroundLightGrey,
                                //                     //   shape: BoxShape.circle,
                                //                     // ),
                                //                     alignment: Alignment.center,
                                //                     child:
                                //                         profilePicUrl != null &&
                                //                             profilePicUrl!
                                //                                 .isNotEmpty
                                //                         ? ClipOval(
                                //                             child: Image.network(
                                //                               profilePicUrl!,
                                //                               width: 28,
                                //                               height: 28,
                                //                               fit: BoxFit.cover,
                                //                               errorBuilder:
                                //                                   (
                                //                                     context,
                                //                                     error,
                                //                                     stackTrace,
                                //                                   ) {
                                //                                     return Container(
                                //                                       width: 28,
                                //                                       height:
                                //                                           28,
                                //                                       decoration: BoxDecoration(
                                //                                         shape: BoxShape
                                //                                             .circle,
                                //                                         color: Theme.of(
                                //                                           context,
                                //                                         ).colorScheme.primary.withOpacity(0.1),
                                //                                       ),
                                //                                       child: Center(
                                //                                         child: Text(
                                //                                           (name?.isNotEmpty ??
                                //                                                   false)
                                //                                               ? name!
                                //                                                     .substring(
                                //                                                       0,
                                //                                                       1,
                                //                                                     )
                                //                                                     .toUpperCase()
                                //                                               : 'N/A',
                                //                                           style:
                                //                                               AppFont.mediumText14bluebold(
                                //                                                 context,
                                //                                               ).copyWith(
                                //                                                 fontSize: 10,
                                //                                               ),
                                //                                         ),
                                //                                       ),
                                //                                     );
                                //                                   },
                                //                             ),
                                //                           )
                                //                         : Container(
                                //                             width:
                                //                                 MediaQuery.of(
                                //                                   context,
                                //                                 ).size.width *
                                //                                 0.08,
                                //                             height:
                                //                                 MediaQuery.of(
                                //                                   context,
                                //                                 ).size.width *
                                //                                 0.08,
                                //                             alignment: Alignment
                                //                                 .center,
                                //                             decoration: BoxDecoration(
                                //                               color: AppColors
                                //                                   .backgroundLightGrey,
                                //                               shape: BoxShape
                                //                                   .circle,
                                //                             ),
                                //                             child: Text(
                                //                               (name?.isNotEmpty ??
                                //                                       false)
                                //                                   ? name!
                                //                                         .substring(
                                //                                           0,
                                //                                           1,
                                //                                         )
                                //                                         .toUpperCase()
                                //                                   : 'N/A',
                                //                               style:
                                //                                   AppFont.mediumText14bluebold(
                                //                                     context,
                                //                                   ).copyWith(
                                //                                     fontSize:
                                //                                         14,
                                //                                   ),
                                //                             ),
                                //                           ),
                                //                   ),
                                //                 ),
                                //               ),
                                //             ),
                                //           ),
                                //         ),
                                //       ),
                                //     ),

                                //   ],
                                // ),

                                // const SizedBox(height: 3),
                                ThreebtnAdmin(
                                  leadId: leadId ?? 'empty',
                                  upcomingFollowups: upcomingFollowups,
                                  overdueFollowups: overdueFollowups,
                                  upcomingAppointments: upcomingAppointments,
                                  overdueAppointments: overdueAppointments,
                                  upcomingTestDrives: upcomingTestDrives,
                                  overdueTestDrives: overdueTestDrives,
                                  refreshDashboard: fetchDashboardData,
                                  overdueFollowupsCount: overdueFollowupsCount,
                                  overdueAppointmentsCount:
                                      overdueAppointmentsCount,
                                  overdueTestDrivesCount:
                                      overdueTestDrivesCount,
                                  tabController: _tabController,
                                  onTabChanged: (index) {
                                    _bottomBtnSecondKey.currentState
                                        ?.handleExternalTabChange(index);
                                  },
                                ),
                                // IconButton(
                                //   onPressed: () async {
                                //     await AdminUserIdManager.clearAdminUserId();
                                //   },
                                //   icon: Icon(Icons.delete),
                                // ),
                                HomeAnalysiscAdmin(key: _bottomBtnSecondKey),

                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10.0,
                                    right: 10.0,
                                  ),
                                  child: Row(
                                    // mainAxisAlignment:
                                    //     MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Performance Analysis',
                                        style: AppFont.appbarfontgrey(context),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isHidden = !_isHidden;
                                          });
                                        },
                                        icon: Icon(
                                          _isHidden
                                              ? Icons
                                                    .keyboard_arrow_down_rounded
                                              : Icons.keyboard_arrow_up_rounded,
                                          size: 35,
                                          color: AppColors.iconGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isHidden) ...[
                                  const HomeAnalysisAdminPerformance(),
                                ],

                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to handle back button press
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) >
            Duration(milliseconds: _exitTimeInMillis)) {
      _lastBackPressTime = now;

      // Show a bottom slide dialog
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Exit App',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorsBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Cancel button (White)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Dismiss dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.colorsBlue,
                            side: const BorderSide(color: AppColors.colorsBlue),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Exit button (Blue)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            SystemNavigator.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorsBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      );
      return false;
    }
    return true;
  }
}
