import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/storage.dart';

class AdminCallanalysis extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isFromSM;
  const AdminCallanalysis({
    super.key,
    required this.userId,
    this.isFromSM = false,
    required this.userName,
  });

  @override
  State<AdminCallanalysis> createState() => _CallAnalyticsState();
}

class _CallAnalyticsState extends State<AdminCallanalysis>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabTitles = ['Enquiry', 'Cold Calls'];
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

  String selectedTimeRange = '1D';
  int selectedTabIndex = 0;
  int touchedIndex = -1;
  int _childButtonIndex = 0;

  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _enquiryData;
  Map<String, dynamic>? _coldCallData;

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
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await Storage.getToken();
      final adminId = await AdminUserIdManager.getAdminUserId();

      String periodParam = '';
      switch (selectedTimeRange) {
        case '1D':
          periodParam = 'type=DAY';
          break;
        case '1W':
          periodParam = 'type=WEEK';
          break;
        case '1M':
          periodParam = 'type=MTD';
          break;
        case '1Q':
          periodParam = 'type=QTD';
          break;
        case '1Y':
          periodParam = 'type=YTD';
          break;
        default:
          periodParam = 'type=DAY';
      }

      late Uri uri;

      if (widget.isFromSM) {
        uri = Uri.parse(
          'https://api.smartassistapp.in/api/app-admin/call/analytics?userId=$adminId&$periodParam&user_id=${widget.userId}',
        );
      } else {
        uri = Uri.parse(
          'https://api.smartassistapp.in/api/app-admin/call/analytics?userId=$adminId&$periodParam',
        );
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(uri);
      print(response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _dashboardData = jsonData['data'];
            _enquiryData = jsonData['data']['summaryEnquiry'];
            _coldCallData = jsonData['data']['summaryColdCalls'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception(
          'Failed to load dashboard data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (e is http.ClientException) {
        debugPrint('Network error: $e');
      } else if (e is FormatException) {
        debugPrint('Error parsing data: $e');
      } else {
        debugPrint('Unexpected error: $e');
      }
    }
  }

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
                Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),

                SizedBox(width: 10),
                Text(
                  AdminUserIdManager.adminNameSync ?? "No Name",
                  style: AppFont.dropDowmLabelWhite(context),
                ),
              ],
            ),
          ),
        ),
      ),

      // appBar: AppBar(
      //   leading: IconButton(
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //     icon: Icon(
      //       FontAwesomeIcons.angleLeft,
      //       color: Colors.white,
      //       size: _isSmallScreen ? 18 : 20,
      //     ),
      //   ),
      //   title: Align(
      //     alignment: Alignment.centerLeft,
      //     child: Text(
      //       widget.isFromSM ? widget.userName : 'Call Analysis',
      //       style: GoogleFonts.poppins(
      //         fontSize: _titleFontSize,
      //         fontWeight: FontWeight.w400,
      //         color: Colors.white,
      //       ),
      //     ),
      //   ),
      //   backgroundColor: AppColors.colorsBlue,
      //   automaticallyImplyLeading: false,
      // ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
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
      //   floatingActionButton: !widget.isFromSM
      //       ? Container(
      //           width: _isTablet ? 150 : (_isSmallScreen ? 100 : 120),
      //           height: _isTablet ? 60 : (_isSmallScreen ? 45 : 56),
      //           child: FloatingActionButton(
      //             backgroundColor: AppColors.colorsBlue,
      //             onPressed: () {
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(builder: (context) => const CallLogs()),
      //               );
      //             },
      //             tooltip: 'Exclude unwanted numbers',
      //             child: Text(
      //               'Exclude',
      //               style: TextStyle(
      //                 color: Colors.white,
      //                 fontSize: _isTablet ? 14 : (_isSmallScreen ? 14 : 16),
      //                 fontWeight: FontWeight.w500,
      //               ),
      //               textAlign: TextAlign.center,
      //             ),
      //           ),
      //         )
      //       : null,
      //   floatingActionButtonLocation: _isTablet
      //       ? FloatingActionButtonLocation.endFloat
      //       : FloatingActionButtonLocation.endFloat,
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
          horizontal: 24,
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
          clipData: FlClipData.none(),
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
