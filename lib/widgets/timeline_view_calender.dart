import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/getX/fab.controller.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/calender/calender.dart';
import 'package:smartassist/widgets/reusable/skeleton_calendar_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarWithTimeline extends StatefulWidget {
  final String leadName;

  const CalendarWithTimeline({Key? key, required this.leadName})
    : super(key: key);

  @override
  State<CalendarWithTimeline> createState() => _CalendarWithTimelineState();
}

class _CalendarWithTimelineState extends State<CalendarWithTimeline> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isMonthView = false;
  List<dynamic> tasks = [];
  List<dynamic> events = [];
  DateTime? _selectedDay;
  bool _isLoading = false;
  ScrollController _timelineScrollController = ScrollController();
  Map<String, bool> _expandedSlots = {};
  Set<int> _activeHours = {};
  Map<String, List<dynamic>> _timeSlotItems = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchActivitiesData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    if (!_timelineScrollController.hasClients) return;
    final currentHour = DateTime.now().hour;
    double scrollPosition = currentHour * 60.0;
    scrollPosition = scrollPosition > 60 ? scrollPosition - 60 : 0;
    _timelineScrollController.animateTo(
      scrollPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Future<void> _fetchActivitiesData() async {
  //   if (mounted) setState(() => _isLoading = true);
  //   try {
  //     final token = await Storage.getToken();
  //     String formattedDate = DateFormat(
  //       'dd-MM-yyyy',
  //     ).format(_selectedDay ?? _focusedDay);

  //     final Map<String, String> queryParams = {'date': formattedDate};
  //     final baseUrl = Uri.parse( 
  //     );
  //     final uri = baseUrl.replace(queryParameters: queryParams);

  //     final response = await http.get(
  //       uri,
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       setState(() {
  //         tasks = data['data']['tasks'] ?? [];
  //         events = data['data']['events'] ?? [];
  //         _isLoading = false;
  //       });
  //       _processTimeSlots();
  //     } else {
  //       setState(() => _isLoading = false);
  //     }
  //   } catch (e) {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _fetchActivitiesData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final String formattedDate = DateFormat(
        'dd-MM-yyyy',
      ).format(_selectedDay ?? _focusedDay);

      final Map<String, String> queryParams = {'date': formattedDate};

      final data = await LeadsSrv.smCalendarAsondate(queryParams);

      if (mounted) {
        setState(() {
          tasks = data['data']['tasks'] ?? [];
          events = data['data']['events'] ?? [];
          _isLoading = false;
        });
      }

      _processTimeSlots();
    } catch (e) {
      print("🚨 Error fetching activities data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processTimeSlots() {
    _activeHours.clear();
    _timeSlotItems.clear();

    for (var event in events) {
      final startTime = _parseTimeString(event['start_time'] ?? '00:00');
      _activeHours.add(startTime.hour);
      final timeKey =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      if (!_timeSlotItems.containsKey(timeKey)) _timeSlotItems[timeKey] = [];
      _timeSlotItems[timeKey]!.add(event);
    }

    for (var task in tasks) {
      DateTime taskTime;
      if (task['time'] != null && task['time'].toString().isNotEmpty) {
        taskTime = _parseTimeString(task['time']);
      } else {
        taskTime = DateTime(2022, 1, 1, 9, 0);
      }
      _activeHours.add(taskTime.hour);
      final timeKey =
          '${taskTime.hour.toString().padLeft(2, '0')}:${taskTime.minute.toString().padLeft(2, '0')}';
      if (!_timeSlotItems.containsKey(timeKey)) _timeSlotItems[timeKey] = [];
      _timeSlotItems[timeKey]!.add(task);
    }

    if (_activeHours.isEmpty) {
      if (_isSameDay(_selectedDay ?? _focusedDay, DateTime.now())) {
        _activeHours.add(DateTime.now().hour);
      } else {
        _activeHours.add(9);
      }
    }
    setState(() {});
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDay = selectedDate;
      _focusedDay = selectedDate;
      tasks = [];
      events = [];
      _activeHours.clear();
      _timeSlotItems.clear();
      _isLoading = true;
    });
    _fetchActivitiesData();
  }

  final FabController fabController = Get.put(FabController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.colorsBlue,
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Calendar',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _calendarFormat = _isMonthView
                    ? CalendarFormat.week
                    : CalendarFormat.month;
                _isMonthView = !_isMonthView;
              });
            },
            icon: _isMonthView
                ? Image.asset(
                    'assets/week.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  )
                : Image.asset(
                    'assets/calendar.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          CalenderWidget(
            key: ValueKey(_calendarFormat),
            calendarFormat: _calendarFormat,
            onDateSelected: _handleDateSelected,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            child: Text(
              DateFormat('EEEE, MMMM d').format(_selectedDay ?? _focusedDay),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildTabbedTimelineView()),
        ],
      ),
    );
  }

  Widget _buildTabbedTimelineView() {
    if (_isLoading) {
      return SkeletonCalendarCard();
    }

    final activeTimeSlots = _timeSlotItems.keys.toList()..sort();

    if (activeTimeSlots.isEmpty) {
      return _emptyState('No scheduled activities for this date');
    }

    return ListView.separated(
      controller: _timelineScrollController,
      itemCount: activeTimeSlots.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey.shade300,
        thickness: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemBuilder: (context, index) {
        final timeKey = activeTimeSlots[index];
        final items = _timeSlotItems[timeKey] ?? [];

        bool isExpanded = _expandedSlots[timeKey] ?? false;
        int showCount = isExpanded ? items.length : 2;
        bool showMore = items.length > 2;
        List<dynamic> displayItems = items.take(showCount).toList();

        // Time above cards
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 5),
                child: Text(timeKey, style: AppFont.dropDowmLabel(context)),
              ),
              ...displayItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildTaskCard(item),
                ),
              ),
              if (showMore && !isExpanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedSlots[timeKey] = true;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 8,
                      ),
                      child: Text(
                        "Show More (${items.length - 2} more) ▼",
                        style: TextStyle(
                          color: const Color.fromRGBO(117, 117, 117, 1),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showMore && isExpanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedSlots[timeKey] = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 8,
                      ),
                      child: Text(
                        "Show Less ▲",
                        style: TextStyle(
                          color: const Color.fromRGBO(117, 117, 117, 1),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(dynamic item) {
    bool completed = item['completed'] ?? false;
    String leadId = item['lead_id']?.toString() ?? '';
    String clientName = item['name'] ?? 'No Name';
    String carName = item['PMI'] ?? '';
    String category = item['subject'] ?? 'Appointment';
    String location = item['location'] ?? '';

    String timeStr =
        item['slot'] ??
        item['time_range'] ??
        item['start_time'] ??
        item['time'] ??
        item['due_date'] ??
        '';

    final c = category.toLowerCase();
    final isTestDrive = c.contains('test drive');
    final isSpecialBlue =
        c.contains('call') ||
        c.contains('quotation') ||
        c.contains('provide quotation') ||
        c.contains('send email') ||
        c.contains('send sms') ||
        c.contains('meeting') ||
        c.contains('vehicle selection') ||
        c.contains('showroom appointment') ||
        c.contains('trade in evaluation');

    Color getTaskCardColor() {
      if (isTestDrive) {
        return Color(0xFFF5EFFA); // Light purple for Test Drive
      }
      if (isSpecialBlue) {
        return Color(0xFFEAF2FE); // Light blue for all these
      }
      return Color(0xFFF0F3FA); // Default
    }

    final verticalBarColor = isTestDrive
        ? Color(0xFFA674D4)
        : AppColors.colorsBlue; // Always blue for all others

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowupsDetails(
              leadId: leadId,
              isFromFreshlead: false,
              isFromManager: false,
              spId: '',
              isFromTestdriveOverview: false,
              refreshDashboard: () async {},
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: getTaskCardColor(),
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 6.1),
            Container(
              width: 4,
              height: 70,
              margin: EdgeInsets.only(left: 6, right: 14),
              decoration: BoxDecoration(
                color: verticalBarColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.5,
                  horizontal: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTestDrive
                        ? Transform.translate(
                            offset: Offset(-2, 3),
                            child: Text(
                              clientName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        : Text(
                            clientName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: verticalBarColor,
                          ),
                        ),
                        if (isTestDrive && carName.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.grey.shade400,
                          ),
                          Transform.translate(
                            offset: Offset(-5, 0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                              ),
                              child: Text(
                                carName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ] else if (!isTestDrive && timeStr.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.grey.shade400,
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isTestDrive)
                      Transform.translate(
                        offset: Offset(-5, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text(
                            location.isNotEmpty
                                ? location
                                : 'Location not specified',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      )
                    else if (!isTestDrive && carName.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          carName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            completed
                ? Icon(Icons.task_alt, size: 30, color: AppColors.sideGreen)
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/calendar.png',
              width: 50,
              height: 50,
              color: const Color.fromRGBO(117, 117, 117, 1),
            ),
            SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _parseTimeString(String timeStr) {
    if (timeStr.isEmpty) {
      return DateTime(2022, 1, 1, 0, 0);
    }
    // Support HH:mm:ss and HH:mm
    List<String> parts = timeStr.split(":");
    int hour = 0, minute = 0;
    if (parts.length >= 2) {
      hour = int.tryParse(parts[0]) ?? 0;
      minute = int.tryParse(parts[1]) ?? 0;
    }
    return DateTime(2022, 1, 1, hour, minute);
  }
}
