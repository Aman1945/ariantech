import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/superAdmin/pages/analysis/admin_leads.dart';
import 'package:smartassist/superAdmin/pages/analysis/admin_orders.dart';
import 'package:smartassist/superAdmin/pages/analysis/admin_testdrive.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:http/http.dart' as http;

class HomeAnalysiscAdmin extends StatefulWidget {
  const HomeAnalysiscAdmin({super.key});

  @override
  State<HomeAnalysiscAdmin> createState() => HomeAnalysiscAdminState();
}

class HomeAnalysiscAdminState extends State<HomeAnalysiscAdmin> {
  // Expose refresh method
  Future<void> refreshData() async {
    await _fetchAllPeriodData();
    _setInitialWidget();
  }

  Future<void> refreshDashboardData() async {
    await _fetchAllPeriodData();
    _setInitialWidget();
  }

  int _childButtonIndex = 0; // 0:MTD, 1:QTD, 2:YTD
  int _leadButton = 0;

  bool _isLoading = true;
  Map<String, dynamic>? _mtdData;
  Map<String, dynamic>? _qtdData;
  Map<String, dynamic>? _ytdData;
  Widget? currentWidget;

  @override
  void initState() {
    super.initState();
    _fetchAllPeriodData().then((_) {
      _setInitialWidget();
    });
  }

  // Fetch data for all periods (MTD, QTD, YTD)
  Future<void> _fetchAllPeriodData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch MTD data
      await _fetchDashboardData('MTD').then((data) {
        if (mounted) {
          setState(() {
            _mtdData = data;
          });
        }
      });

      // Fetch QTD data
      await _fetchDashboardData('QTD').then((data) {
        if (mounted) {
          setState(() {
            _qtdData = data;
          });
        }
      });

      // Fetch YTD data
      await _fetchDashboardData('YTD').then((data) {
        if (mounted) {
          setState(() {
            _ytdData = data;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error fetching all period data: $e');
    }
  }

  // Fetch dashboard data for a specific period
  Future<Map<String, dynamic>?> _fetchDashboardData(String period) async {
    try {
      // this is new one
      final token = await Storage.getToken();

      final adminId = await AdminUserIdManager.getAdminUserId();

      // final uri = Uri.parse(
      //   'https://api.smartassistapp.in/api/app-admin/dashboard/analytics?adminIduserId?type=$period',
      // );

      final uri = Uri.parse(
        'https://api.smartassistapp.in/api/app-admin/dashboard/analytics?userId=$adminId&type=$period',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('this the url fo the dashboard_one ghhhhh ${uri}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else {
        throw Exception(
          'Failed to load $period dashboard data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching $period data: $e');
      return null;
    }
  }

  void _setInitialWidget() {
    if (_isLoading ||
        _mtdData == null ||
        _qtdData == null ||
        _ytdData == null) {
      return;
    }

    if (_leadButton == 0) {
      _updateLeadsWidget();
    } else if (_leadButton == 1) {
      _updateTestDriveWidget();
    } else if (_leadButton == 2) {
      _updateOrdersWidget();
    }
  }

  void _updateLeadsWidget() {
    setState(() {
      currentWidget = AdminLeads(
        MtdData: _mtdData!,
        QtdData: _qtdData!,
        YtdData: _ytdData!,
        onFormSubmit: (String period) => _fetchDashboardData(period),
      );
    });
  }

  void _updateTestDriveWidget() {
    setState(() {
      currentWidget = AdminTestdrive(
        MtdData: _mtdData!,
        QtdData: _qtdData!,
        YtdData: _ytdData!,
        onFormSubmit: (String period) => _fetchDashboardData(period),
      );
    });
  }

  void _updateOrdersWidget() {
    setState(() {
      currentWidget = AdminOrders(
        MtdData: _mtdData!,
        QtdData: _qtdData!,
        YtdData: _ytdData!,
        onFormSubmit: (String period) => _fetchDashboardData(period),
      );
    });
  }

  void handleExternalTabChange(int tabIndex) {
    // No underscore = public method
    int leadButtonIndex;
    switch (tabIndex) {
      case 0:
        leadButtonIndex = 0; // Enquiries
        break;
      case 1:
        leadButtonIndex = 0; // Default to Enquiries for Appointments
        break;
      case 2:
        leadButtonIndex = 1; // Test Drives
        break;
      default:
        leadButtonIndex = 0;
    }

    if (_leadButton != leadButtonIndex) {
      setState(() {
        _leadButton = leadButtonIndex;
        if (leadButtonIndex == 0) {
          _updateLeadsWidget();
        } else if (leadButtonIndex == 1) {
          _updateTestDriveWidget();
        } else if (leadButtonIndex == 2) {
          _updateOrdersWidget();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.containerBg,
        border: Border.all(color: Colors.black.withOpacity(.1)),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: _isLoading
          ? _buildSkeletonLoader()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  child: Container(
                    height: MediaQuery.sizeOf(context).height * .05,
                    width: double.infinity,
                    child: Row(
                      children: [
                        // Enquiries Button
                        Expanded(
                          child: _buildTabButton(
                            'Enquiries',
                            Icons.person_search,
                            0,
                            () {
                              setState(() {
                                _leadButton = 0;
                                _updateLeadsWidget();
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8.0),

                        // Test Drive Button
                        Expanded(
                          child: _buildTabButton(
                            'Test Drives',
                            Icons.directions_car,
                            1,
                            () {
                              setState(() {
                                _leadButton = 1;
                                _updateTestDriveWidget();
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8.0),

                        // Orders Button
                        Expanded(
                          child: _buildTabButton(
                            'Orders',
                            Icons.receipt_long,
                            2,
                            () {
                              setState(() {
                                _leadButton = 2;
                                _updateOrdersWidget();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                currentWidget ?? const SizedBox(height: 10),
                const SizedBox(height: 5),
              ],
            ),
    );
  }

  // New tab button widget with icons and consistent styling
  // New tab button widget with icons on the left and consistent styling
  Widget _buildTabButton(
    String title,
    IconData icon,
    int index,
    VoidCallback onPressed,
  ) {
    final isActive = _leadButton == index;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isActive
                ? AppColors.colorsBlue
                : AppColors.fontColor.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        backgroundColor: isActive ? AppColors.colorsBlue : Colors.transparent,
        foregroundColor: isActive ? Colors.white : AppColors.fontColor,
      ),
      child: Container(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.fontColor,
            ),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFont.buttonwhite(context).copyWith(
                  color: isActive ? Colors.white : AppColors.fontColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Remove the old _buttonStyle method as it's no longer needed

  Widget _buildSkeletonLoader() {
    // [Skeleton loader remains the same]
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            // Top tab section
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  // Other tabs
                  Container(
                    width: MediaQuery.of(context).size.width * 0.33,
                    color: Colors.white,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.33,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MTD/QTD/YTD tabs row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics section with colored numbers
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column with color indicators and metrics
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Fourth metric row
                      Row(
                        children: [
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.5,
                            height: MediaQuery.sizeOf(context).height * 0.2,
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 16,
                              height: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.3,
                            height: MediaQuery.sizeOf(context).height * 0.2,
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 16,
                              height: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
