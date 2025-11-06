import 'dart:math' as math;
import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart'; 
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/superAdmin/pages/single_id_view.dart/admin_singlelead_followups.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
import 'package:smartassist/widgets/testdrive_verifyotp.dart';

class TestdriveAdminUpcoming extends StatefulWidget {
  final Future<void> Function() refreshDashboard;
  final List<dynamic> upcomingTestDrive;
  final bool isNested;
  final Function(String, bool)? onFavoriteToggle;
  const TestdriveAdminUpcoming({
    super.key,
    required this.upcomingTestDrive,
    required this.isNested,
    this.onFavoriteToggle,
    required this.refreshDashboard,
  });

  @override
  State<TestdriveAdminUpcoming> createState() => _TestdriveAdminUpcomingState();
}

class _TestdriveAdminUpcomingState extends State<TestdriveAdminUpcoming> {
  List<dynamic> upcomingTestDrives = [];
  final Map<String, double> _swipeOffsets = {};
  int _currentDisplayCount = 10;
  final int _incrementCount = 10;
  @override
  void initState() {
    super.initState();
    upcomingTestDrives = widget.upcomingTestDrive;
    print('this is testdrive');
    print(widget.upcomingTestDrive);
    _currentDisplayCount = math.min(
      _incrementCount,
      widget.upcomingTestDrive.length,
    );
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.upcomingTestDrive != oldWidget.upcomingTestDrive) {
      // _initializeFavorites();
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.upcomingTestDrive.length,
      );
    }
  }

  void _loadLessRecords() {
    setState(() {
      _currentDisplayCount = _incrementCount;
      print(
        '📊 Loading less records. New display count: $_currentDisplayCount',
      );
    });
  }

  void _loadAllRecords() {
    setState(() {
      // Show all records at once
      _currentDisplayCount = widget.upcomingTestDrive.length;
      print('📊 Loading all records. New display count: $_currentDisplayCount');
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, String eventId) {
    setState(() {
      _swipeOffsets[eventId] =
          (_swipeOffsets[eventId] ?? 0) + (details.primaryDelta ?? 0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, dynamic item, int index) {
    String eventId = item['event_id'];

    double swipeOffset = _swipeOffsets[eventId] ?? 0;

    if (swipeOffset > 100) {
      // Right Swipe (Favorite)
      _toggleFavorite(eventId, index);
    } else if (swipeOffset < -100) {
      // Left Swipe (Call)
      _handleTestDrive(item);
    }

    // Reset animation
    setState(() {
      _swipeOffsets[eventId] = 0.0;
    });
  }

  void _handleTestDrive(dynamic item) {
    String email = item['updated_by'] ?? '';
    String mobile = item['mobile'] ?? '';
    String eventId = item['event_id'] ?? '';
    String leadId = item['lead_id'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestdriveVerifyotp(
          email: email,
          mobile: mobile,
          leadId: leadId,
          eventId: eventId,
        ),
      ),
    );
    print("Call action triggered for ${item['name']}");
  }

  Future<void> _toggleFavorite(String eventId, int index) async {
    bool currentStatus = widget.upcomingTestDrive[index]['favourite'] ?? false;
    bool newFavoriteStatus = !currentStatus;

    final success = await LeadsSrv.favoriteTestDrive(eventId: eventId);

    if (success) {
      setState(() {
        widget.upcomingTestDrive[index]['favourite'] = newFavoriteStatus;
      });

      if (widget.onFavoriteToggle != null) {
        widget.onFavoriteToggle!(eventId, newFavoriteStatus);
      }
    }
  }

  Future<void> _getOtp(String eventId) async {
    final success = await LeadsSrv.getOtp(eventId: eventId);

    if (success) {
      print('✅ Test drive started successfully');
    } else {
      print('❌ Failed to start test drive');
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.upcomingTestDrive.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No upcoming TestDrive available',
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    // Get the items to display based on current count
    List<dynamic> itemsToDisplay = widget.upcomingTestDrive
        .take(_currentDisplayCount)
        .toList();

    return Column(
      children: [
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: widget.isNested
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          // itemCount: widget.upcomingTestDrive.length,
          itemCount: _currentDisplayCount,
          itemBuilder: (context, index) {
            var item = widget.upcomingTestDrive[index];

            if (!(item.containsKey('assigned_to') &&
                item.containsKey('start_date') &&
                item.containsKey('lead_id') &&
                item.containsKey('event_id'))) {
              return ListTile(title: Text('Invalid data at index $index'));
            }

            String eventId = item['event_id'];
            double swipeOffset = _swipeOffsets[eventId] ?? 0;

            return GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _onHorizontalDragUpdate(details, eventId),
              onHorizontalDragEnd: (details) =>
                  _onHorizontalDragEnd(details, item, index),
              child: upcomingTestDrivesItem(
                key: ValueKey(item['event_id']),
                name: item['name'] ?? '',
                vehicle: item['PMI'] ?? 'Range Rover Velar',
                subject: item['subject'] ?? 'Meeting',
                date: item['start_date'] ?? '',
                email: item['updated_by'] ?? '',
                leadId: item['lead_id'],
                // isCompleted : item['completed'] ?? false ;
                startTime:
                    (item['start_time'] != null &&
                        item['start_time'].toString().isNotEmpty)
                    ? item['start_time'].toString()
                    : "00:00:00",
                eventId: item['event_id'] ?? '',
                isFavorite: item['favourite'] ?? false,
                swipeOffset: swipeOffset,
                onToggleFavorite: () {
                  _toggleFavorite(eventId, index);
                },
                otpTrigger: () {
                  _getOtp(eventId);
                },
                fetchDashboardData: () {},
                handleTestDrive: () {
                  _handleTestDrive(item);
                },
                refreshDashboard: widget.refreshDashboard,
                isCompleted: item['completed'] ?? false,

                // Placeholder, replace with actual method
              ),
            );
          },
        ), // Add the show more/less button
        _buildShowMoreButton(),
      ],
    );
  }

  Widget _buildShowMoreButton() {
    // If no data, don't show anything
    if (widget.upcomingTestDrive.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fix invalid display count
    if (_currentDisplayCount <= 0 ||
        _currentDisplayCount > widget.upcomingTestDrive.length) {
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.upcomingTestDrive.length,
      );
    }

    // Check if we can show more records
    bool hasMoreRecords =
        _currentDisplayCount < widget.upcomingTestDrive.length;

    // Check if we can show less records - only if we're showing more than initial count
    bool canShowLess = _currentDisplayCount > _incrementCount;

    // If no action is possible, don't show button
    if (!hasMoreRecords && !canShowLess) {
      return const SizedBox.shrink();
    }

    return Container(
      // padding: EdgeInsets.only(bottom: 20),
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (canShowLess)
            TextButton(
              onPressed: _loadLessRecords,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Show Less'),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_up, size: 16),
                ],
              ),
            ),

          // Show More button - only when there are more records to show
          if (hasMoreRecords)
            TextButton(
              onPressed: _loadAllRecords, // Changed method name
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorsBlue,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Show All (${widget.upcomingTestDrive.length - _currentDisplayCount} more)', // Updated text
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class upcomingTestDrivesItem extends StatefulWidget {
  final String name, date, vehicle, subject, leadId, eventId, startTime, email;
  final bool isFavorite, isCompleted;
  final Future<void> Function() refreshDashboard;
  final VoidCallback fetchDashboardData;
  final double swipeOffset;
  final VoidCallback onToggleFavorite;
  final VoidCallback handleTestDrive;
  final dynamic item;
  final VoidCallback otpTrigger;
  const upcomingTestDrivesItem({
    super.key,
    required this.name,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.isFavorite,
    required this.fetchDashboardData,
    required this.eventId,
    required this.startTime,
    required this.subject,
    required this.swipeOffset,
    required this.email,
    required this.onToggleFavorite,
    required this.handleTestDrive,
    this.item,
    required this.otpTrigger,
    required this.refreshDashboard,
    required this.isCompleted,
  });

  @override
  State<upcomingTestDrivesItem> createState() => _upcomingTestDrivesItemState();
}

class _upcomingTestDrivesItemState extends State<upcomingTestDrivesItem>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // _slidableController.animation.addListener(() {
    //   final isOpen = _slidableController.ratio != 0;
    //   if (_isActionPaneOpen != isOpen) {
    //     setState(() {
    //       _isActionPaneOpen = isOpen;
    //     });
    //   }
    // });
  }

  @override
  void dispose() {
    // _slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: InkWell(
        onTap: () {
          if (widget.leadId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminSingleleadFollowups(
                  leadId: widget.leadId,
                  isFromFreshlead: false,
                  isFromManager: false,
                  isFromTestdriveOverview: false,
                  refreshDashboard: widget.refreshDashboard,
                ),
              ),
            );
          } else {
            print("Invalid leadId");
          }
        },
        child: _buildFollowupCard(context),
      ),
    );
  }

  Widget _buildFollowupCard(BuildContext context) {
    bool isFavoriteSwipe = widget.swipeOffset > 50;
    bool isCallSwipe = widget.swipeOffset < -50;

    return Stack(
      children: [
        // Main Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.containerBg,
            // gradient: _buildSwipeGradient(),
            borderRadius: BorderRadius.circular(5),
            border: Border(
              left: BorderSide(
                width: 8.0,
                color: widget.isFavorite
                    ? (isCallSwipe
                          ? AppColors.colorsBlue.withOpacity(
                              0.2,
                            ) // Green when swiping for a call
                          : Colors.yellow.withOpacity(
                              isFavoriteSwipe ? 0.1 : 0.9,
                            )) // Keep yellow when favorite
                    : (isFavoriteSwipe
                          ? Colors.yellow.withOpacity(0.1)
                          : (isCallSwipe
                                ? AppColors.colorsBlue.withOpacity(0.2)
                                : AppColors.sideGreen)),
              ),
            ),
          ),
          child: Opacity(
            opacity: (isFavoriteSwipe || isCallSwipe) ? 0 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildUserDetails(context),
                            _buildVerticalDivider(15),
                            _buildCarModel(context),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildSubjectDetails(context),
                            _date(context),
                            _time(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                _buildNavigationButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _messageAction() {
    print("Message action triggered");
  }

  void _mailAction() {
    print("Mail action triggered");

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Testdrive(onFormSubmit: () {}, eventId: widget.eventId),
        );
      },
    );
  }

  Widget _buildUserDetails(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .35,
      ),
      child: Text(
        maxLines: 1, // Allow up to 2 lines
        overflow: TextOverflow
            .ellipsis, // Show ellipsis if it overflows beyond 2 lines
        softWrap: true,
        widget.name,
        style: AppFont.dashboardName(context),
      ),
    );
  }

  Widget _buildSubjectDetails(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.directions_car, color: AppColors.colorsBlue, size: 18),
        const SizedBox(width: 5),
        Text('${widget.subject},', style: AppFont.smallText(context)),
      ],
    );
  }

  Widget _time() {
    DateTime parsedTime = DateFormat("HH:mm:ss").parse(widget.startTime);
    String formattedTime = DateFormat("ha").format(parsedTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        Text(
          formattedTime,
          style: GoogleFonts.poppins(
            color: AppColors.fontColor,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _date(BuildContext context) {
    String formattedDate = '';
    try {
      DateTime parseDate = DateTime.parse(widget.date);
      // formattedDate = DateFormat('dd MMM').format(parseDate);
      // Check if the date is today
      if (parseDate.year == DateTime.now().year &&
          parseDate.month == DateTime.now().month &&
          parseDate.day == DateTime.now().day) {
        formattedDate = 'Today';
      } else {
        // If not today, format it as "26th March"
        int day = parseDate.day;
        String suffix = _getDaySuffix(day);
        String month = DateFormat('MMM').format(parseDate); // Full month name
        formattedDate = '${day}$suffix $month';
      }
    } catch (e) {
      formattedDate = widget.date;
    }
    return Row(
      children: [
        const SizedBox(width: 5),
        Text(formattedDate, style: AppFont.smallText(context)),
      ],
    );
  }

  // Helper method to get the suffix for the day (e.g., "st", "nd", "rd", "th")
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildVerticalDivider(double height) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: height,
      width: 0.1,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.fontColor)),
      ),
    );
  }

  Widget _buildCarModel(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .30,
      ),
      child: Text(
        widget.vehicle,
        style: AppFont.dashboardCarName(context),
        maxLines: 1, // Allow up to 2 lines
        overflow: TextOverflow
            .ellipsis, // Show ellipsis if it overflows beyond 2 lines
        softWrap: true, // Allow wrapping
      ),
    );
  }

  bool _isActionPaneOpen = false;
  Widget _buildNavigationButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isActionPaneOpen) {
          // _slidableController.close();
          setState(() {
            _isActionPaneOpen = false;
          });
        } else {
          // _slidableController.close();
          // Future.delayed(Duration(milliseconds: 100), () {
          //   _slidableController.openEndActionPane();
          //   setState(() {
          //     _isActionPaneOpen = true;
          //   });
          // });
        }
      },

      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.arrowContainerColor,
          borderRadius: BorderRadius.circular(30),
        ),

        child: Icon(
          _isActionPaneOpen
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_rounded,

          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }
}
