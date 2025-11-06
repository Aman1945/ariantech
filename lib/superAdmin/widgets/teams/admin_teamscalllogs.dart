import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';

class AdminTeamscalllogs extends StatefulWidget {
  final int? initialTabIndex;
  final Function(int)? onTabChanged;
  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic>? enquiryData;
  final Map<String, dynamic>? coldCallData;
  final String? initialTimeRange;

  final Function(String)? onTimeRangeChanged;
  const AdminTeamscalllogs({
    super.key,
    required this.dashboardData,
    this.enquiryData,
    this.coldCallData,
    this.onTimeRangeChanged,
    this.initialTimeRange,
    this.onTabChanged,
    this.initialTabIndex,
  });

  @override
  State<AdminTeamscalllogs> createState() => _AdminTeamscalllogsState();
}

class _AdminTeamscalllogsState extends State<AdminTeamscalllogs>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabTitles = ['Enquiry', 'Cold Calls'];

  String selectedTimeRange = '1D';
  int selectedTabIndex = 0;
  int touchedIndex = -1;
  int _childButtonIndex = 0;

  bool _isLoading = false;

  // Helper method to get responsive dimensions
  bool get _isTablet => MediaQuery.of(context).size.width > 768;
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 400;
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // Responsive padding
  EdgeInsets get _responsivePadding => EdgeInsets.symmetric(
    horizontal: _isTablet ? 20 : (_isSmallScreen ? 8 : 10),
    vertical: _isTablet ? 12 : 8,
  );

  // Responsive font sizes
  double get _titleFontSize => _isTablet ? 20 : (_isSmallScreen ? 16 : 18);
  double get _bodyFontSize => _isTablet ? 16 : (_isSmallScreen ? 12 : 14);
  double get _smallFontSize => _isTablet ? 14 : (_isSmallScreen ? 10 : 12);

  @override
  void initState() {
    super.initState();
    selectedTimeRange = widget.initialTimeRange ?? '1D';
    selectedTabIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(length: tabTitles.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() {
          selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // @override
  // void didUpdateWidget(TeamCalllogUserid oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.initialTimeRange != oldWidget.initialTimeRange) {
  //     setState(() {
  //       selectedTimeRange = widget.initialTimeRange ?? '1D';
  //       _isLoading = true; // Trigger loading state to refresh data
  //     });
  //     // Optionally, fetch data or notify parent to refresh
  //     if (widget.onTimeRangeChanged != null) {
  //       widget.onTimeRangeChanged!(selectedTimeRange);
  //     }
  //   }
  // }

  @override
  void didUpdateWidget(covariant AdminTeamscalllogs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTimeRange != oldWidget.initialTimeRange) {
      setState(() {
        selectedTimeRange = widget.initialTimeRange ?? '1D';
      });
    }

    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      // Add this block
      setState(() {
        selectedTabIndex = widget.initialTabIndex ?? 0;
        _tabController.animateTo(selectedTabIndex);
      });
    }
  }

  void _updateSelectedTimeRange(String range) {
    setState(() {
      selectedTimeRange = range;
    });

    // Call the parent callback function
    if (widget.onTimeRangeChanged != null) {
      widget.onTimeRangeChanged!(range);
    }
  }

  // void _updateSelectedTab(int index) {
  //   setState(() {
  //     selectedTabIndex = index;
  //     _tabController.animateTo(index);
  //   });
  // }

  void _updateSelectedTab(int index) {
    setState(() {
      selectedTabIndex = index;
      _tabController.animateTo(index);
    });

    // Call the parent callback function
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index);
    }
  }

  // Get current data based on selected tab
  Map<String, dynamic> get currentTabData {
    if (widget.dashboardData == null) {
      return {};
    }
    return selectedTabIndex == 0
        ? widget.enquiryData ?? {}
        : widget.coldCallData ?? {};
  }

  // Get summary data based on selected tab
  Map<String, dynamic> get summarySectionData {
    if (currentTabData.isEmpty) {
      return {};
    }
    return currentTabData['summary'] ?? {};
  }

  // Get hourly analysis data based on selected tab
  Map<String, dynamic> get hourlyAnalysisData {
    if (currentTabData.isEmpty) {
      return {};
    }
    return currentTabData['hourlyAnalysis'] ?? {};
  }

  // Generate table rows based on API data for the selected tab
  List<List<Widget>> get tableData {
    List<List<Widget>> data = [];
    final summary = summarySectionData;

    // Always show these rows even if data is empty
    // Add All Calls row
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

    // Add Connected row
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

    // Add Missed row
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

    // Add Rejected row
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
    if (widget.dashboardData == null || widget.dashboardData!.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    return SafeArea(
      child: Column(
        children: [
          _buildTabBar(),
          _buildUserStatsCard(),
          SizedBox(height: _isTablet ? 20 : 16),
          _buildCallsSummary(),
          SizedBox(height: _isTablet ? 20 : 16),
          _buildHourlyAnalysis(),
        ],
      ),
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
            width: 1.5, // Ensure border is visible
          ),
          color: isActive
              ? AppColors.colorsBlue.withOpacity(0.1)
              : Colors.transparent,
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

          // Responsive stats layout
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
                      Colors.red,
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
                      Colors.red,
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
    return Container(
      height: _isTablet ? 40 : (_isSmallScreen ? 25 : 30),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.symmetric(
        horizontal: _responsivePadding.horizontal,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabTitles.length; i++)
            Expanded(child: _buildTab(tabTitles[i], i == selectedTabIndex, i)),
        ],
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
        padding: EdgeInsets.symmetric(
          horizontal: 0,
          vertical: _isSmallScreen ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.colorsBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
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
            'Hourly Analysis',
            style: TextStyle(
              fontSize: _bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: _isTablet ? 15 : 10),
          SizedBox(height: _isTablet ? 15 : 10),
          SizedBox(
            height: _isTablet ? 300 : (_isSmallScreen ? 180 : 200),
            child: _buildCombinedBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallStatsRows() {
    // Calculate totals from hourly analysis data
    int allCalls = 0;
    String allCallsDuration = "0m";
    int incomingCalls = 0;
    String incomingDuration = "0m";
    int missedCalls = 0;
    String missedDuration = "";

    // Sum up the calls and durations from hourly data
    hourlyAnalysisData.forEach((hour, data) {
      if (data['AllCalls'] != null) {
        allCalls += (data['AllCalls']['calls'] as num?)?.toInt() ?? 0;
        allCallsDuration = data['AllCalls']['duration'] ?? "0m";
      }

      // Connected calls (treating as incoming for now)
      if (data['Connected'] != null) {
        incomingCalls += (data['Connected']['calls'] as num?)?.toInt() ?? 0;
        incomingDuration = data['Connected']['duration']?.toString() ?? "0m";
      }

      // Missed calls
      if (data['missedCalls'] != null) {
        missedCalls = data['missedCalls'] as int;
      }
    });

    return Container(
      padding: EdgeInsets.all(_isTablet ? 16 : (_isSmallScreen ? 8 : 10)),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildCallStatRow('All calls', allCalls.toString(), allCallsDuration),
          _buildCallStatRow(
            'Connected',
            incomingCalls.toString(),
            incomingDuration,
          ),
          _buildCallStatRow(
            'Missed calls',
            missedCalls.toString(),
            missedDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildCallStatRow(String label, String count, String duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppFont.smallText10(context))),
          Text(count, style: AppFont.smallText12(context)),
          const SizedBox(width: 12),
          Text(
            duration,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
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

  Widget _buildCombinedLineChart() {
    List<FlSpot> allCallSpots = [];
    List<FlSpot> incomingSpots = [];
    List<FlSpot> outgoingSpots = [];
    List<String> xLabels = [];
    Map ha = hourlyAnalysisData;

    // Handle 1D special case: Always show 9AM - 9PM
    if (selectedTimeRange == "1D") {
      List<int> hours = List.generate(13, (i) => i + 9); // 9 to 21
      for (int i = 0; i < hours.length; i++) {
        String hourStr = hours[i].toString();
        var data = ha[hourStr] ?? {};
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
        // Format label as e.g. "9AM", "10AM", ... "12PM", "1PM", ... "8PM", "9PM"
        int hr = hours[i];
        String ampm = hr < 12 ? "AM" : "PM";
        int hourOnClock = hr > 12 ? hr - 12 : hr;
        hourOnClock = hourOnClock == 0 ? 12 : hourOnClock;
        xLabels.add("$hourOnClock$ampm");
      }
    }
    // Enquiry 1W: Mon-Sun
    else if (selectedTabIndex == 0 && selectedTimeRange == "1W") {
      final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      for (int i = 0; i < weekDays.length; i++) {
        String day = weekDays[i];
        var data = ha[day] ?? {};
        xLabels.add(day);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    }
    // Enquiry 1M: Week 1-4
    else if (selectedTabIndex == 0 && selectedTimeRange == "1M") {
      final weeks = ["Week 1", "Week 2", "Week 3", "Week 4"];
      for (int i = 0; i < weeks.length; i++) {
        var week = weeks[i];
        var data = ha[week] ?? {};
        xLabels.add(week);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    }
    // WEEK (Mon-Sun) - For other tabs
    else if (ha.keys.any(
      (k) => ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].contains(k),
    )) {
      final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      for (int i = 0; i < weekDays.length; i++) {
        String day = weekDays[i];
        var data = ha[day] ?? {};
        xLabels.add(day);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    }
    // MONTH (Weeks: Week 1, 2, ...)
    else if (ha.keys.isNotEmpty && ha.keys.first.toString().contains('Week')) {
      final weeks = ha.keys.toList()
        ..sort((a, b) {
          int ai = int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '0') ?? 0;
          int bi = int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '0') ?? 0;
          return ai.compareTo(bi);
        });
      for (int i = 0; i < weeks.length; i++) {
        var week = weeks[i];
        var data = ha[week] ?? {};
        xLabels.add(week);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    }
    // QUARTER (Months: Apr, May, Jun...)
    else if ([
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
      final List<String> foundMonths = ha.keys
          .map((e) => e.toString())
          .toList();
      List<String> monthsToShow = allMonths
          .where((m) => foundMonths.contains(m))
          .toList();
      for (int i = 0; i < monthsToShow.length; i++) {
        var m = monthsToShow[i];
        var data = ha[m] ?? {};
        xLabels.add(m);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    }
    // YEAR (Quarters: Q1, Q2, ...)
    else if (ha.keys.isNotEmpty && ha.keys.first.toString().contains('Q')) {
      final List<String> quarters = ["Q1", "Q2", "Q3", "Q4"];
      for (int i = 0; i < quarters.length; i++) {
        var q = quarters[i];
        var data = ha[q] ?? {};
        xLabels.add(q);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    }
    // fallback: show by keys order
    else if (ha.isNotEmpty) {
      final keys = ha.keys.map((e) => e.toString()).toList();
      for (int i = 0; i < keys.length; i++) {
        var data = ha[keys[i]] ?? {};
        xLabels.add(keys[i]);
        allCallSpots.add(
          FlSpot(i.toDouble(), (data['AllCalls']?['calls'] ?? 0).toDouble()),
        );
        incomingSpots.add(FlSpot(i.toDouble(), getIncoming(data)));
        outgoingSpots.add(
          FlSpot(i.toDouble(), (data['outgoing']?['calls'] ?? 0).toDouble()),
        );
      }
    } else {
      allCallSpots = [const FlSpot(0, 0)];
      incomingSpots = [const FlSpot(0, 0)];
      outgoingSpots = [const FlSpot(0, 0)];
      xLabels = ["-"];
    }

    // Determine maxY for Y axis scaling
    double maxY =
        ([
              ...allCallSpots,
              ...incomingSpots,
              ...outgoingSpots,
            ].map((e) => e.y).fold<double>(0, (prev, e) => e > prev ? e : prev))
            .ceilToDouble();
    if (maxY < 5) maxY = 5;
    // Adaptive interval for big/zero data
    double yInterval;
    if (maxY > 2000)
      yInterval = 1000;
    else if (maxY > 1000)
      yInterval = 500;
    else if (maxY > 500)
      yInterval = 200;
    else if (maxY > 200)
      yInterval = 100;
    else if (maxY > 100)
      yInterval = 50;
    else if (maxY > 50)
      yInterval = 10;
    else if (maxY > 20)
      yInterval = 5;
    else
      yInterval = 2;
    maxY = ((maxY ~/ yInterval) + 2) * yInterval;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LineChart(
        LineChartData(
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
                    callType = 'Outgoing';
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
                reservedSize: 44,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.round();
                  if (idx >= 0 && idx < xLabels.length) {
                    // For 1D, rotate/resize labels to prevent overlap
                    return SideTitleWidget(
                      meta: meta,
                      child: selectedTimeRange == "1D"
                          ? Transform.rotate(
                              angle: -0.7, // rotate -40deg
                              child: Text(
                                xLabels[idx],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              xLabels[idx],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                reservedSize: 48,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == 0) return const SizedBox();
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
          maxX: xLabels.length > 0 ? (xLabels.length - 1).toDouble() : 1,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: allCallSpots,
              isCurved: true,
              color: AppColors.colorsBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
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
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
            LineChartBarData(
              spots: outgoingSpots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.2),
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
          child: widget, // Use the widget directly here
        );
      }).toList(),
    );
  }
}
