import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/controller/calllogs_channel.dart';
import 'package:smartassist/pages/navbar_page/call_logs.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';

class CallAnalytics extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isFromSM;
  const CallAnalytics({
    super.key,
    required this.userId,
    this.isFromSM = false,
    required this.userName,
  });

  @override
  State<CallAnalytics> createState() => _CallAnalyticsState();
}

class _CallAnalyticsState extends State<CallAnalytics>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabTitles = ['Enquiry', 'Cold Calls'];

  String selectedTimeRange = '1D';
  int selectedTabIndex = 0;
  int touchedIndex = -1;
  int _childButtonIndex = 0;
  bool _permissionsGranted = false;
  bool _permissionsChecked = false;

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _enquiryData;
  Map<String, dynamic>? _coldCallData;

  String get analysisTitle {
    switch (selectedTimeRange) {
      case '1D':
        return 'Hourly Analysis';
      case '1W':
        return 'Daily Analysis';
      case '1M':
        return 'Weekly Analysis';
      case '1Q':
        return 'Monthly Analysis';
      case '1Y':
        return 'Quarterly Analysis';
      default:
        return 'Analysis';
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: tabTitles.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() {
          selectedTabIndex = _tabController.index;
        });
      }
    });

    print('this is userid ${widget.userId}');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _isLoading = true;
      });

      try {
        // 👇 Conditional API call
        if (widget.isFromSM != true) {
          // Only call if not from SM or if null
          await uploadCallLogsAfterLogin();
        }

        await _fetchDashboardData();
      } catch (e) {
        debugPrint("Error during initialization: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: tabTitles.length, vsync: this);
  //   _tabController.addListener(() {
  //     if (_tabController.indexIsChanging == false) {
  //       setState(() {
  //         selectedTabIndex = _tabController.index;
  //       });
  //     }
  //   });
  //   print('this is userid ${widget.userId}');
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     await uploadCallLogsAfterLogin();
  //     await Future.delayed(Duration(seconds: 2));
  //     await _fetchDashboardData();
  //   });
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     try {
  //       await Future.wait([uploadCallLogsAfterLogin(), _fetchDashboardData()]);
  //     } catch (e) {
  //       debugPrint("Error during initialization: $e");
  //     } finally {
  //       if (mounted) {
  //         setState(() {
  //           _isLoading = false;
  //         });
  //       }
  //     }
  //   });
  // }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([uploadCallLogsAfterLogin(), _fetchDashboardData()]);
    } catch (e) {
      debugPrint("Error during refresh: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> uploadCallLogsAfterLogin() async {
    final hasPermissions = await _checkAndRequestPermissions();

    if (!hasPermissions) {
      _showDialorPermission();
    }

    try {
      // Get available SIMs
      final sims = await CalllogChannel.listSimAccounts();

      if (sims.isEmpty) {
        showErrorMessage(context, message: 'No SIM cards found');
        return;
      }

      Map<String, dynamic>? selectedSim;
      final prefs = await SharedPreferences.getInstance();
      final storedSimId = prefs.getString('selected_sim_id');

      // Debug: Print SIM data structure to understand available fields
      print('Available SIMs: $sims');

      // Check if we have a stored SIM selection
      if (storedSimId != null) {
        // Find the previously selected SIM using phoneAccountId or other identifier
        try {
          selectedSim = sims.firstWhere(
            (sim) =>
                (sim['phoneAccountId']?.toString() ??
                    sim['id']?.toString() ??
                    sim.toString()) ==
                storedSimId,
          );
          print(
            'Using stored SIM selection: ${selectedSim['label'] ?? selectedSim['displayName'] ?? 'Unknown SIM'}',
          );
        } catch (e) {
          // Previously selected SIM not found, clear storage and show dialog
          await prefs.remove('selected_sim_id');
          selectedSim = null;
          print('Previously selected SIM not found, will show dialog');
        }
      }

      // If no stored selection or stored SIM not found
      if (selectedSim == null) {
        if (sims.length == 1) {
          selectedSim = sims.first;
          print(
            'Auto-selected single SIM: ${selectedSim['label'] ?? selectedSim['displayName'] ?? 'Unknown SIM'}',
          );
          // Store the selection using the best available identifier
          final simId =
              selectedSim['phoneAccountId']?.toString() ??
              selectedSim['id']?.toString() ??
              selectedSim.toString();
          await prefs.setString('selected_sim_id', simId);
        } else {
          // Multiple SIMs, show selection dialog
          selectedSim = await _showSimSelectionDialog(sims);
          if (selectedSim != null) {
            // Store the user's choice using the best available identifier
            final simId =
                selectedSim['phoneAccountId']?.toString() ??
                selectedSim['id']?.toString() ??
                selectedSim.toString();
            await prefs.setString('selected_sim_id', simId);
            print(
              'User selected and stored SIM: ${selectedSim['label'] ?? selectedSim['displayName'] ?? 'Unknown SIM'}',
            );
          }
        }
      }

      if (selectedSim != null) {
        await _uploadCallLogsForSim(selectedSim);
      }
    } catch (e) {
      print('Error in upload process: $e');
    }
  }

  void _showDialorPermission() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.phone_locked, color: AppColors.colorsBlue),
              SizedBox(width: 8),
              Text(
                'Permission Needed',
                style: AppFont.appbarfontblack(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To access your call logs, this app requires phone permission. Please follow the steps below:',
                style: AppFont.dropDowmLabel(context),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps to Enable Call Logs Permission:',
                      style: AppFont.dropDowmLabel(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Tap "Open Settings" below\n'
                      '2. In Settings, go to **Permissions**\n'
                      '3. Find and enable **Phone / Call Logs**\n'
                      '4. Return to this app and continue',
                      style: AppFont.dropDowmLabel(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: AppFont.buttons(context)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings(); // opens app settings
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorsBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Open Settings', style: AppFont.buttons(context)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkAndRequestPermissions() async {
    // If already checked and granted, return true
    if (_permissionsChecked && _permissionsGranted) {
      return true;
    }

    // Check current permission status
    final hasPermissions = await CalllogChannel.arePermissionsGranted();

    if (hasPermissions) {
      _permissionsGranted = true;
      _permissionsChecked = true;
      return true;
    }

    // Only request if not checked before
    if (!_permissionsChecked) {
      _permissionsGranted = await CalllogChannel.requestPermissions();
      _permissionsChecked = true;
    }

    return _permissionsGranted;
  }

  Future<Map<String, dynamic>?> _showSimSelectionDialog(
    List<Map<String, dynamic>> sims,
  ) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Select SIM Card',
            style: AppFont.appbarfontblack(context),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose which SIM to upload call logs from: ',
                  style: AppFont.dropDowmLabel(context),
                ),
                SizedBox(height: 16.h),
                ...sims
                    .map((sim) => _buildEnhancedSimDialogOption(sim))
                    .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel', style: AppFont.dropDowmLabel(context)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedSimDialogOption(Map<String, dynamic> sim) {
    final label = sim['label'] ?? 'SIM';
    final slot = sim['simSlotIndex'];
    final number = sim['number'];
    final carrier = sim['carrierName'];
    final isAllSims = sim['phoneAccountId'] == 'all';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(sim),
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.colorsBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    isAllSims ? Icons.all_inclusive : Icons.sim_card_rounded,
                    color: AppColors.colorsBlue,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          if (slot != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.colorsBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Slot ${slot + 1}',
                                style: AppFont.smallText(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (number != null && number.toString().isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          number.toString(),
                          style: AppFont.dropDowmLabel(context),
                        ),
                      ],
                      if (carrier != null &&
                          carrier != label &&
                          carrier.toString().isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          carrier.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                      if (isAllSims) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'Upload logs from all SIM cards',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: const Color(0xFF718096),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadCallLogsForSim(Map<String, dynamic> selectedSim) async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Map<String, dynamic>> callLogs = [];

      final phoneAccountId = selectedSim['phoneAccountId']?.toString() ?? '';
      if (phoneAccountId == 'all' || phoneAccountId.isEmpty) {
        callLogs = await CalllogChannel.getAllCallLogs(limit: 500);
      } else {
        callLogs = await CalllogChannel.getCallLogsForAccount(
          phoneAccountId: phoneAccountId,
          limit: 500,
        );
      }

      if (callLogs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No call logs found for selected SIM')),
        );
        return;
      }

      List<Map<String, dynamic>> formattedLogs = callLogs.map((log) {
        // Get call type - prioritize the string version from native code
        String callType = 'unknown';

        // First check if we have the string version from native code
        if (log['call_type'] != null &&
            log['call_type'].toString().isNotEmpty) {
          callType = log['call_type'].toString().toLowerCase();
        }
        // If not, convert from numeric type
        else if (log['type'] != null) {
          int typeInt = int.tryParse(log['type'].toString()) ?? 0;
          callType = _getCallTypeString(typeInt);
        }

        return {
          'name': log['name'] ?? 'Unknown',
          'start_time':
              log['timestamp']?.toString() ?? log['date']?.toString() ?? '',
          'mobile': log['mobile'] ?? log['number'] ?? '',
          'call_type': callType,
          'call_duration': log['duration']?.toString() ?? '',
          'unique_key':
              log['unique_key'] ??
              '${log['number'] ?? log['mobile']}_${log['date'] ?? log['timestamp']}',
        };
      }).toList();

      final token = await Storage.getToken();
      const apiUrl = 'https://api.smartassistapp.in/api/leads/create-call-logs';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formattedLogs),
      );

      print('Call logs data: $formattedLogs');

      if (response.statusCode == 201) {
        print('Call logs uploaded successfully');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Call logs uploaded successfully')),
        // );
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to convert numeric call type to string
  String _getCallTypeString(int type) {
    switch (type) {
      case 1: // CallLog.Calls.INCOMING_TYPE
        return 'incoming';
      case 2: // CallLog.Calls.OUTGOING_TYPE
        return 'outgoing';
      case 3: // CallLog.Calls.MISSED_TYPE
        return 'missed';
      case 5: // CallLog.Calls.REJECTED_TYPE
        return 'rejected';
      default:
        return 'other';
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await LeadsSrv.fetchDashboardDataAn(
        timeRange: selectedTimeRange,
        userId: widget.isFromSM ? widget.userId : null,
        isFromSM: widget.isFromSM,
      );

      print('Dashboard API Result: $result'); // Debug print

      if (result['success'] == true) {
        final data = result['data'];
        if (mounted) {
          setState(() {
            _dashboardData = data['data'];
            _enquiryData = data['data']['summaryEnquiry'];
            _coldCallData = data['data']['summaryColdCalls'];
            _isLoading = false;
          });
        }
      } else {
        final errorMessage =
            result['message'] ?? 'Failed to fetch dashboard data';
        print('❌ Failed to fetch dashboard data: $errorMessage');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          showErrorMessage(context, message: errorMessage);
        }
      }
    } catch (e) {
      print('Exception in _fetchDashboardData: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show appropriate error message based on error type
        String errorMessage = 'An unexpected error occurred';
        if (e is SocketException) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again later.';
        } else if (e is FormatException) {
          errorMessage = 'Error parsing server response';
        }

        showErrorMessageGetx(message: errorMessage);
      }
    }
  }

  // Future<void> _fetchDashboardData() async {
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     final token = await Storage.getToken();

  //     String periodParam = '';
  //     switch (selectedTimeRange) {
  //       case '1D':
  //         periodParam = '?type=DAY';
  //         break;
  //       case '1W':
  //         periodParam = '?type=WEEK';
  //         break;
  //       case '1M':
  //         periodParam = '?type=MTD';
  //         break;
  //       case '1Q':
  //         periodParam = '?type=QTD';
  //         break;
  //       case '1Y':
  //         periodParam = '?type=YTD';
  //         break;
  //       default:
  //         periodParam = '?type=DAY';
  //     }

  //     late Uri uri;

  //     if (widget.isFromSM) {
  //       uri = Uri.parse(
  //         '/api/users/ps/dashboard/call-analytics$periodParam&user_id=${widget.userId}',
  //       );
  //     } else {
  //       uri = Uri.parse(
  //         '/api/users/ps/dashboard/call-analytics$periodParam',
  //       );
  //     }

  //     final response = await http.get(
  //       uri,
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     print(uri);
  //     print(response.body);

  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body);
  //       if (mounted) {
  //         setState(() {
  //           _dashboardData = jsonData['data'];
  //           _enquiryData = jsonData['data']['summaryEnquiry'];
  //           _coldCallData = jsonData['data']['summaryColdCalls'];
  //           _isLoading = false;
  //         });
  //       }
  //     } else {
  //       throw Exception(
  //         'Failed to load dashboard data. Status code: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }

  //     if (e is http.ClientException) {
  //       debugPrint('Network error: $e');
  //     } else if (e is FormatException) {
  //       debugPrint('Error parsing data: $e');
  //     } else {
  //       debugPrint('Unexpected error: $e');
  //     }
  //   }
  // }

  void _updateSelectedTimeRange(String range) {
    setState(() {
      selectedTimeRange = range;
      _fetchDashboardData();
    });
  }

  void _updateSelectedTab(int index) {
    setState(() {
      selectedTabIndex = index;
      _tabController.animateTo(index);
    });
  }

  Map<String, dynamic> get currentTabData {
    if (_dashboardData == null) {
      return {};
    }
    return selectedTabIndex == 0 ? _enquiryData ?? {} : _coldCallData ?? {};
  }

  Map<String, dynamic> get summarySectionData {
    if (currentTabData.isEmpty) {
      return {};
    }
    return currentTabData['summary'] ?? {};
  }

  Map<String, dynamic> get hourlyAnalysisData {
    if (currentTabData.isEmpty) {
      return {};
    }
    return currentTabData['hourlyAnalysis'] ?? {};
  }

  bool get _isTablet => MediaQuery.of(context).size.width > 768;
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 400;
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  EdgeInsets get _responsivePadding => EdgeInsets.symmetric(
    horizontal: _isTablet ? 20 : (_isSmallScreen ? 8 : 10),
    vertical: _isTablet ? 12 : 8,
  );

  double get _titleFontSize => _isTablet ? 20 : (_isSmallScreen ? 16 : 18);
  double get _bodyFontSize => _isTablet ? 16 : (_isSmallScreen ? 12 : 14);
  double get _smallFontSize => _isTablet ? 14 : (_isSmallScreen ? 10 : 12);

  List<List<Widget>> get tableData {
    List<List<Widget>> data = [];
    final summary = summarySectionData;

    data.add([
      Row(
        children: [
          Icon(
            Icons.call,
            size: _isSmallScreen ? 14 : 16,
            color: AppColors.colorsBlue,
          ),
          SizedBox(width: _isSmallScreen ? 4 : 6),
          Flexible(
            child: Text(
              'All Calls',
              style: TextStyle(fontSize: _smallFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Text(
        summary.containsKey('All Calls')
            ? summary['All Calls']['calls']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('All Calls')
            ? summary['All Calls']['duration']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('All Calls')
            ? summary['All Calls']['uniqueClients']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
    ]);

    data.add([
      Row(
        children: [
          Icon(Icons.call, size: _isSmallScreen ? 14 : 16, color: Colors.green),
          SizedBox(width: _isSmallScreen ? 4 : 6),
          Flexible(
            child: Text(
              'Connected',
              style: TextStyle(fontSize: _smallFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Text(
        summary.containsKey('Connected')
            ? summary['Connected']['calls']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('Connected')
            ? summary['Connected']['duration']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('Connected')
            ? summary['Connected']['uniqueClients']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
    ]);

    data.add([
      Row(
        children: [
          Icon(
            Icons.call_missed,
            size: _isSmallScreen ? 14 : 16,
            color: Colors.redAccent,
          ),
          SizedBox(width: _isSmallScreen ? 4 : 6),
          Flexible(
            child: Text(
              'Missed',
              style: TextStyle(fontSize: _smallFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Text(
        summary.containsKey('Missed')
            ? summary['Missed']['calls']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('Missed')
            ? summary['Missed']['duration']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('Missed')
            ? summary['Missed']['uniqueClients']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
    ]);

    data.add([
      Row(
        children: [
          Icon(
            Icons.call_missed_outgoing_rounded,
            size: _isSmallScreen ? 14 : 16,
            color: Colors.redAccent,
          ),
          SizedBox(width: _isSmallScreen ? 4 : 6),
          Flexible(
            child: Text(
              'Rejected',
              style: TextStyle(fontSize: _smallFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Text(
        summary.containsKey('Rejected')
            ? summary['Rejected']['calls']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('Rejected')
            ? summary['Rejected']['duration']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
      Text(
        summary.containsKey('Rejected')
            ? summary['Rejected']['uniqueClients']?.toString() ?? '0'
            : '0',
        style: TextStyle(fontSize: _smallFontSize),
      ),
    ]);

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            FontAwesomeIcons.angleLeft,
            color: Colors.white,
            size: _isSmallScreen ? 18 : 20,
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.isFromSM ? widget.userName : 'Call Analysis',
            style: GoogleFonts.poppins(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppColors.colorsBlue,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _onRefresh,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            _buildTabBar(),
                            _buildUserStatsCard(),
                            SizedBox(height: _isTablet ? 20 : 16),
                            _buildCallsSummary(),
                            SizedBox(height: _isTablet ? 20 : 16),
                            _buildHourlyAnalysis(),
                            if (!widget.isFromSM && !_isTablet)
                              const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: !widget.isFromSM
          ? Container(
              width: _isTablet ? 150 : (_isSmallScreen ? 100 : 120),
              height: _isTablet ? 60 : (_isSmallScreen ? 45 : 56),
              child: FloatingActionButton(
                backgroundColor: AppColors.colorsBlue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CallLogs()),
                  );
                },
                tooltip: 'Exclude unwanted numbers',
                child: Text(
                  'Exclude',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isTablet ? 14 : (_isSmallScreen ? 14 : 16),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: _isTablet
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTimeFilterRow() {
    final timeRanges = ['1D', '1W', '1M', '1Q', '1Y'];
    double filterWidth = _isTablet ? 250 : (_isSmallScreen ? 180 : 200);

    return Padding(
      padding: EdgeInsets.only(
        top: 5,
        bottom: 10,
        left: _responsivePadding.left,
        right: _responsivePadding.right,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: filterWidth,
          height: _isTablet ? 35 : (_isSmallScreen ? 28 : 30),
          decoration: BoxDecoration(
            color: AppColors.backgroundLightGrey,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              for (final range in timeRanges)
                Expanded(
                  child: _buildTimeFilterChip(
                    range,
                    range == selectedTimeRange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => _updateSelectedTimeRange(label),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 3 : 5,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? AppColors.colorsBlue : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isActive ? AppColors.colorsBlue : AppColors.fontColor,
            fontSize: _isTablet ? 16 : (_isSmallScreen ? 11 : 14),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatsCard() {
    return Container(
      margin: _responsivePadding,
      padding: EdgeInsets.all(_isTablet ? 16 : (_isSmallScreen ? 8 : 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeFilterRow(),
          SizedBox(height: _isTablet ? 20 : 16),
          _isTablet
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        currentTabData['totalConnected']?.toString() ?? '0',
                        'Total\nConnected',
                        Colors.green,
                        Icons.call,
                      ),
                    ),
                    _buildVerticalDivider(60),
                    Expanded(
                      child: _buildStatBox(
                        currentTabData['conversationTime']?.toString() ?? '0',
                        'Conversation\ntime',
                        AppColors.colorsBlue,
                        Icons.access_time,
                      ),
                    ),
                    _buildVerticalDivider(60),
                    Expanded(
                      child: _buildStatBox(
                        currentTabData['notConnected']?.toString() ?? '0',
                        'Not\nConnected',
                        Colors.red,
                        Icons.call_missed,
                      ),
                    ),
                  ],
                )
              : _isSmallScreen
              ? Column(
                  children: [
                    _buildStatBox(
                      currentTabData['totalConnected']?.toString() ?? '0',
                      'Total Connected',
                      Colors.green,
                      Icons.call,
                    ),
                    const SizedBox(height: 12),
                    _buildStatBox(
                      currentTabData['conversationTime']?.toString() ?? '0',
                      'Conversation time',
                      AppColors.colorsBlue,
                      Icons.access_time,
                    ),
                    const SizedBox(height: 12),
                    _buildStatBox(
                      currentTabData['notConnected']?.toString() ?? '0',
                      'Not Connected',
                      Colors.redAccent,
                      Icons.call_missed,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox(
                      currentTabData['totalConnected']?.toString() ?? '0',
                      'Total\nConnected',
                      Colors.green,
                      Icons.call,
                    ),
                    _buildVerticalDivider(50),
                    _buildStatBox(
                      currentTabData['conversationTime']?.toString() ?? '0',
                      'Conversation\ntime',
                      AppColors.colorsBlue,
                      Icons.access_time,
                    ),
                    _buildVerticalDivider(50),
                    _buildStatBox(
                      currentTabData['notConnected']?.toString() ?? '0',
                      'Not\nConnected',
                      Colors.redAccent,
                      Icons.call_missed,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: _isSmallScreen
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: _isTablet ? 28 : (_isSmallScreen ? 20 : 24),
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(width: _isSmallScreen ? 2 : 3),
            Icon(
              icon,
              color: color,
              size: _isTablet ? 24 : (_isSmallScreen ? 16 : 20),
            ),
          ],
        ),
        SizedBox(height: _isTablet ? 12 : 10),
        Text(
          label,
          style: TextStyle(fontSize: _smallFontSize, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(double height) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isSmallScreen ? 3 : 5),
      height: height,
      width: 0.1,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.backgroundLightGrey)),
      ),
    );
  }

  Widget _buildCallsSummary() {
    return Container(
      margin: _responsivePadding,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [_buildAnalyticsTable()]),
    );
  }

  Widget _buildTabBar() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact(); // Dismiss keyboard on tap
      },
      child: Container(
        height: _isTablet ? 40 : (_isSmallScreen ? 35 : 50),
        padding: EdgeInsets.zero,
        margin: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 60 : 70,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundLightGrey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (int i = 0; i < tabTitles.length; i++)
              Expanded(
                child: _buildTab(tabTitles[i], i == selectedTabIndex, i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTable() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildTableContent();
  }

  Widget _buildTableContent() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 0.6,
        ),
        verticalInside: BorderSide.none,
      ),
      columnWidths: _isTablet
          ? {
              0: const FlexColumnWidth(2.5), // Metric
              1: const FlexColumnWidth(1.5), // Calls
              2: const FlexColumnWidth(1.5), // Duration
              3: const FlexColumnWidth(2), // Unique client
            }
          : _isSmallScreen
          ? {
              0: const FlexColumnWidth(2), // Metric
              1: const FlexColumnWidth(1), // Calls
              2: const FlexColumnWidth(1), // Duration
              3: const FlexColumnWidth(1.3), // Unique client
            }
          : {
              0: const FlexColumnWidth(2.2), // Metric
              1: const FlexColumnWidth(1.3), // Calls
              2: const FlexColumnWidth(1.3), // Duration
              3: const FlexColumnWidth(1.5), // Unique client
            },
      children: [
        TableRow(
          children: [
            const SizedBox(), // Empty cell
            Container(
              margin: EdgeInsets.only(
                bottom: 10,
                top: 10,
                left: _isSmallScreen ? 2 : 5,
              ),
              child: Text(
                'Calls',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: _smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                bottom: 10,
                top: 10,
                left: _isSmallScreen ? 2 : 5,
              ),
              child: Text(
                'Duration',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: _smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                bottom: 10,
                top: 10,
                right: _isSmallScreen ? 2 : 5,
                left: _isSmallScreen ? 2 : 5,
              ),
              child: Text(
                _isSmallScreen ? 'Clients' : 'Unique client',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: _smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        ...tableData.map((row) => _buildTableRow(row)).toList(),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () => _updateSelectedTab(index),
      child: Container(
        height: 48.0, // <-- Explicitly set a fixed height for the container
        alignment: Alignment
            .center, // <-- Center the text vertically within the container
        padding: EdgeInsets.symmetric(
          horizontal: 14,
        ), // Adjust horizontal padding as needed
        decoration: BoxDecoration(
          color: isActive ? AppColors.colorsBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : AppColors.colorsBlue,
            fontSize: _isTablet ? 14 : (_isSmallScreen ? 14 : 16),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ------ HOURLY ANALYSIS CHART & LEGEND --------

  Widget _buildHourlyAnalysis() {
    return Container(
      margin: _responsivePadding,
      padding: EdgeInsets.all(_isTablet ? 16 : (_isSmallScreen ? 8 : 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            analysisTitle,
            style: GoogleFonts.poppins(
              fontSize: _bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: _isTablet ? 15 : 10),
          // ------- REMOVED _buildCallStatsRows() ---------
          SizedBox(height: _isTablet ? 15 : 10),
          SizedBox(
            height: _isTablet ? 300 : (_isSmallScreen ? 180 : 200),
            child: _buildCombinedBarChart(),
          ),
        ],
      ),
    );
  }
  // Place these helpers in your _CallAnalyticsState class (above build method):

  double getIncoming(Map data) {
    if (data['incoming'] != null && data['incoming']['calls'] != null) {
      return (data['incoming']['calls'] as num).toDouble();
    }
    if (data['Connected'] != null && data['Connected']['calls'] != null) {
      return (data['Connected']['calls'] as num).toDouble();
    }
    if (data['answered'] != null && data['answered']['calls'] != null) {
      return (data['answered']['calls'] as num).toDouble();
    }
    return 0.0;
  }

  String _formatYAxisLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }

  Widget _buildCombinedBarChart() {
    List<FlSpot> allCallSpots = [];
    List<FlSpot> incomingSpots = [];
    List<FlSpot> missedCallSpots = [];
    List<String> xLabels = [];
    Map ha = hourlyAnalysisData;

    List<List<String>> quarterMonths = [
      ["Jan", "Feb", "Mar"],
      ["Apr", "May", "Jun"],
      ["Jul", "Aug", "Sep"],
      ["Oct", "Nov", "Dec"],
    ];

    int currentQuarterIdx = () {
      DateTime now = DateTime.now();
      int q = ((now.month - 1) / 3).floor();
      return q;
    }();

    // ==== X Axis Data/Labels for each time range =====
    if (selectedTimeRange == "1D") {
      List<int> hours = List.generate(13, (i) => i + 9); // 9AM to 9PM
      for (int i = 0; i < hours.length; i++) {
        String hourStr = hours[i].toString();
        var data = ha[hourStr] ?? {};
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
        int hr = hours[i];
        String ampm = hr < 12 ? "AM" : "PM";
        int hourOnClock = hr > 12 ? hr - 12 : hr;
        hourOnClock = hourOnClock == 0 ? 12 : hourOnClock;
        xLabels.add("$hourOnClock$ampm");
      }
    } else if (selectedTimeRange == "1W") {
      final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      for (int i = 0; i < weekDays.length; i++) {
        String day = weekDays[i];
        var data = ha[day] ?? {};
        xLabels.add(day);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
      }
    } else if ((selectedTabIndex == 0 && selectedTimeRange == "1M") ||
        (selectedTabIndex == 1 && selectedTimeRange == "1M")) {
      final weeks = ["Week 1", "Week 2", "Week 3", "Week 4"];
      for (int i = 0; i < weeks.length; i++) {
        var week = weeks[i];
        var data = ha[week] ?? {};
        xLabels.add(week);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
      }
    } else if ((selectedTabIndex == 0 && selectedTimeRange == "1Q") ||
        (selectedTabIndex == 1 && selectedTimeRange == "1Q")) {
      int qIdx = 0;
      if (ha.keys.isNotEmpty) {
        String? firstMonth = ha.keys.first;
        int idx = quarterMonths.indexWhere(
          (mList) => mList.contains(firstMonth),
        );
        if (idx != -1) qIdx = idx;
      } else {
        qIdx = currentQuarterIdx;
      }
      List<String> months = quarterMonths[qIdx];
      for (int i = 0; i < months.length; i++) {
        String m = months[i];
        var data = ha[m] ?? {};
        xLabels.add(m);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
      }
    } else if (selectedTimeRange == "1Y") {
      final quarters = ["Q1", "Q2", "Q3", "Q4"];
      for (int i = 0; i < quarters.length; i++) {
        var q = quarters[i];
        var data = ha[q] ?? {};
        xLabels.add(q);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
      }
    } else if ([
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ].any((m) => ha.keys.contains(m))) {
      const allMonths = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      for (int i = 0; i < allMonths.length; i++) {
        var m = allMonths[i];
        var data = ha[m] ?? {};
        xLabels.add(m);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
      }
    } else if (ha.isNotEmpty) {
      final keys = ha.keys.map((e) => e.toString()).toList();
      for (int i = 0; i < keys.length; i++) {
        var data = ha[keys[i]] ?? {};
        xLabels.add(keys[i]);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        missedCallSpots.add(
          FlSpot(i.toDouble(), (data['missedCalls'] ?? 0).toDouble()),
        );
      }
    } else {
      allCallSpots = [const FlSpot(0, 0)];
      incomingSpots = [const FlSpot(0, 0)];
      missedCallSpots = [const FlSpot(0, 0)];
      xLabels = ["-"];
    }

    // ===== Y AXIS INTERVAL LOGIC (always show intervals even if empty) =====

    double calcNiceInterval(double rawMax, double baseInterval) {
      double multiplier = ((rawMax / baseInterval) / 4).ceilToDouble();
      if (multiplier < 1) multiplier = 1;
      return baseInterval * multiplier;
    }

    double getBaseInterval(String timeRange) {
      switch (timeRange) {
        case "1D":
          return 5.0;
        case "1W":
          return 50.0;
        case "1M":
          return 100.0;
        case "1Q":
          return 100.0;
        case "1Y":
          return 200.0;
        default:
          return 10.0;
      }
    }

    double maxY =
        ([
              ...allCallSpots,
              ...incomingSpots,
              ...missedCallSpots,
            ].map((e) => e.y).fold<double>(0, (prev, e) => e > prev ? e : prev))
            .ceilToDouble();

    double yInterval;

    if (selectedTabIndex == 0 && selectedTimeRange == "1Q") {
      maxY = 400;
      yInterval = 100;
    } else {
      double base = getBaseInterval(selectedTimeRange);
      yInterval = calcNiceInterval(maxY, base);
      // If data is empty or all zeros, enforce min axis (at least 4 intervals shown)
      if (maxY == 0) {
        maxY = base * 4;
        yInterval = base;
      } else {
        maxY = ((maxY / yInterval).ceil() + 1) * yInterval;
      }
    }

    int labelMaxLen = selectedTimeRange == "1D" ? 4 : 7;
    double fontSize = 11;
    bool rotateLabel = false;
    if (xLabels.length >= 8) {
      fontSize = 10;
      rotateLabel = true;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 10, bottom: 10),
      child: LineChart(
        LineChartData(
          // clipData: FlClipData.none(),
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  String callType = '';
                  if (spot.barIndex == 0)
                    callType = 'All Calls';
                  else if (spot.barIndex == 1)
                    callType = 'Incoming';
                  else
                    callType = 'Missed calls';
                  String xLabel = spot.x < xLabels.length
                      ? xLabels[spot.x.toInt()]
                      : '';
                  return LineTooltipItem(
                    '$callType\n$xLabel: ${spot.y.toInt()} calls',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 50,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.round();
                  if (idx >= 0 && idx < xLabels.length) {
                    String label = xLabels[idx];
                    if (label.length > labelMaxLen) {
                      label = label.substring(0, labelMaxLen - 1) + '…';
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 12,
                      child: rotateLabel || selectedTimeRange == "1D"
                          ? Transform.rotate(
                              angle: -0.7,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              label,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == 0) return const SizedBox();

                  if (selectedTabIndex == 0 && selectedTimeRange == "1Q") {
                    if (value % yInterval != 0) return const SizedBox();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                      ),
                    );
                  }

                  if (maxY > 5000 && value % (yInterval * 2) != 0)
                    return const SizedBox();
                  if (value % yInterval != 0) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _formatYAxisLabel(value),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          minX: 0,
          maxX: xLabels.length > 0 ? (xLabels.length - 1).toDouble() : 0,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: allCallSpots,
              isCurved: true,
              color: AppColors.colorsBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => true,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.colorsBlue.withOpacity(0.2),
              ),
            ),
            LineChartBarData(
              spots: incomingSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => true,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
            LineChartBarData(
              spots: missedCallSpots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => true,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  TableRow _buildTableRow(List<Widget> widgets) {
    return TableRow(
      children: widgets.map((widget) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
          child: widget,
        );
      }).toList(),
    );
  }
}
