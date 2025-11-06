import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/superAdmin/pages/single_id_view.dart/admin_singlelead_followups.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
import 'package:smartassist/widgets/testdrive_verifyotp.dart';

class TestdriveAdminOverdue extends StatefulWidget {
  final Future<void> Function() refreshDashboard;
  final List<dynamic> overdueTestDrive;
  final bool isNested;
  final Function(String, bool)? onFavoriteToggle;
  const TestdriveAdminOverdue({
    super.key,
    required this.overdueTestDrive,
    required this.isNested,
    this.onFavoriteToggle,
    required this.refreshDashboard,
  });

  @override
  State<TestdriveAdminOverdue> createState() => _TestdriveAdminOverdueState();
}

class _TestdriveAdminOverdueState extends State<TestdriveAdminOverdue> {
  List<dynamic> upcomingTestDrives = [];
  final Map<String, double> _swipeOffsets = {};
  int _currentDisplayCount = 10;
  final int _incrementCount = 10;

  @override
  void initState() {
    super.initState();
    upcomingTestDrives = widget.overdueTestDrive;
    print('this is testdrive');
    print(widget.overdueTestDrive);
    _currentDisplayCount = math.min(
      _incrementCount,
      widget.overdueTestDrive.length,
    );
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overdueTestDrive != oldWidget.overdueTestDrive) {
      // _initializeFavorites();
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.overdueTestDrive.length,
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
      _currentDisplayCount = widget.overdueTestDrive.length;
      print('📊 Loading all records. New display count: $_currentDisplayCount');
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, String eventId) {
    setState(() {
      _swipeOffsets[eventId] =
          (_swipeOffsets[eventId] ?? 0) + (details.primaryDelta ?? 0);
    });
  }

  // void _onHorizontalDragEnd(DragEndDetails details, dynamic item, int index) {
  //   String eventId = item['event_id'];

  //   double swipeOffset = _swipeOffsets[eventId] ?? 0;

  //   if (swipeOffset > 100) {
  //     // Right Swipe (Favorite)
  //     _toggleFavorite(eventId, index);
  //   } else if (swipeOffset < -100) {
  //     // Left Swipe (Call)
  //     _handleTestDrive(item);
  //   }

  //   // Reset animation
  //   setState(() {
  //     _swipeOffsets[eventId] = 0.0;
  //   });
  // }

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
          leadId: leadId,
          eventId: eventId,
          mobile: mobile,
        ),
      ),
    );
    print("Call action triggered for ${item['name']}");
  }

  Future<void> _toggleFavorite(String eventId, int index) async {
    bool currentStatus = widget.overdueTestDrive[index]['favourite'] ?? false;
    bool newFavoriteStatus = !currentStatus;

    final success = await LeadsSrv.favoriteTestDrive(eventId: eventId);

    if (success) {
      setState(() {
        widget.overdueTestDrive[index]['favourite'] = newFavoriteStatus;
      });

      if (widget.onFavoriteToggle != null) {
        widget.onFavoriteToggle!(eventId, newFavoriteStatus);
      }
    }
  }

  // Future<void> _toggleFavorite(String eventId, int index) async {
  //   final token = await Storage.getToken();
  //   try {
  //     // Get the current favorite status before toggling
  //     bool currentStatus = widget.overdueTestDrive[index]['favourite'] ?? false;
  //     bool newFavoriteStatus = !currentStatus;

  //     final response = await http.put(
  //       Uri.parse(
  //         'https://api.smartassistapp.in/api/favourites/mark-fav/event/$eventId',
  //       ),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //       // No need to send in body since taskId is already in the URL
  //     );

  //     if (response.statusCode == 200) {
  //       setState(() {
  //         widget.overdueTestDrive[index]['favourite'] = newFavoriteStatus;
  //       });

  //       // Notify the parent if the callback is provided
  //       if (widget.onFavoriteToggle != null) {
  //         widget.onFavoriteToggle!(eventId, newFavoriteStatus);
  //       }
  //     } else {
  //       print('Failed to toggle favorite: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error toggling favorite: $e');
  //   }
  // }

  Future<void> _getOtp(String eventId) async {
    final success = await LeadsSrv.getOtp(eventId: eventId);

    if (success) {
      print('✅ OTP send successfully');
    } else {
      print('❌ Failed to start test drive');
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overdueTestDrive.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No Overdue TestDrive available',
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    // Get the items to display based on current count
    List<dynamic> itemsToDisplay = widget.overdueTestDrive
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
          // itemCount: widget.overdueTestDrive.length,
          itemCount: _currentDisplayCount,
          itemBuilder: (context, index) {
            var item = widget.overdueTestDrive[index];

            String eventId = item['event_id'];
            double swipeOffset = _swipeOffsets[eventId] ?? 0;

            return GestureDetector(
              child: upcomingTestDrivesItem(
                key: ValueKey(item['event_id']),
                name: item['name'] ?? '',
                isCompleted: item['completed'] ?? false,
                vehicle: item['PMI'] ?? 'Range Rover Velar',
                subject: item['subject'] ?? 'Meeting',
                date: item['start_date'] ?? '',
                leadId: item['lead_id'],
                taskId: item['task_id'] ?? '',
                // startTime: item['start_time'],
                startTime:
                    (item['start_time'] != null &&
                        item['start_time'].toString().isNotEmpty)
                    ? item['start_time'].toString()
                    : "00:00:00",
                eventId: item['event_id'],
                isFavorite: item['favourite'] ?? false,
                swipeOffset: swipeOffset,
                refreshDashboard: widget.refreshDashboard,
                onToggleFavorite: () {
                  _toggleFavorite(eventId, index);
                },
                otpTrigger: () {
                  _getOtp(eventId);
                },
                fetchDashboardData: () {},
                handleTestDrive: () {
                  _handleTestDrive(item);
                }, // Placeholder, replace with actual method
              ),
            );
          },
        ),
        // Add the show more/less button
        _buildShowMoreButton(),
      ],
    );
  }

  Widget _buildShowMoreButton() {
    // If no data, don't show anything
    if (widget.overdueTestDrive.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fix invalid display count
    if (_currentDisplayCount <= 0 ||
        _currentDisplayCount > widget.overdueTestDrive.length) {
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.overdueTestDrive.length,
      );
    }

    // Check if we can show more records
    bool hasMoreRecords = _currentDisplayCount < widget.overdueTestDrive.length;

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
                    'Show All (${widget.overdueTestDrive.length - _currentDisplayCount} more)', // Updated text
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
  final String name, date, vehicle, taskId, leadId, eventId, subject, startTime;
  final bool isFavorite, isCompleted;
  final double swipeOffset;
  final Future<void> Function() refreshDashboard;
  final VoidCallback fetchDashboardData;
  final VoidCallback onToggleFavorite;
  final VoidCallback handleTestDrive;
  final dynamic item;
  final VoidCallback otpTrigger;
  const upcomingTestDrivesItem({
    super.key,
    required this.name,
    required this.date,
    required this.leadId,
    required this.fetchDashboardData,
    required this.eventId,
    required this.startTime,
    required this.subject,
    required this.swipeOffset,
    required this.isFavorite,
    required this.vehicle,
    required this.onToggleFavorite,
    required this.taskId,
    this.item,
    required this.handleTestDrive,
    required this.otpTrigger,
    required this.refreshDashboard,
    required this.isCompleted,
  });

  @override
  State<upcomingTestDrivesItem> createState() => _upcomingTestDrivesItemState();
}

class _upcomingTestDrivesItemState extends State<upcomingTestDrivesItem>
    with SingleTickerProviderStateMixin {
  late SlidableController _slidableController;
  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);

    _slidableController.animation.addListener(() {
      final isOpen = _slidableController.ratio != 0;
      if (_isActionPaneOpen != isOpen) {
        setState(() {
          _isActionPaneOpen = isOpen;
        });
      }
    });
  }

  @override
  void dispose() {
    _slidableController.dispose();
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
        // Favorite Swipe Overlay
        if (isFavoriteSwipe)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.withOpacity(0.2),
                    Colors.yellow.withOpacity(0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 15),
                    Icon(
                      widget.isFavorite
                          ? Icons.star_outline_rounded
                          : Icons.star_rounded,
                      color: const Color.fromRGBO(226, 195, 34, 1),
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isFavorite ? 'Unfavorite' : 'Favorite',
                      style: GoogleFonts.poppins(
                        color: const Color.fromRGBO(187, 158, 0, 1),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Call Swipe Overlay
        if (isCallSwipe)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.colorsBlue, AppColors.colorsBlue],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Start Test Drive',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ),
          ),

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
                                : AppColors.sideRed)),
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
          _slidableController.close();
          setState(() {
            _isActionPaneOpen = false;
          });
        } else {
          _slidableController.close();
          Future.delayed(Duration(milliseconds: 100), () {
            _slidableController.openEndActionPane();
            setState(() {
              _isActionPaneOpen = true;
            });
          });
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
