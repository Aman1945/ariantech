import 'dart:math' as math;

import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/superAdmin/pages/single_id_view.dart/admin_singlelead_followups.dart';
import 'package:smartassist/widgets/testdrive/upcoming.dart';
// import 'package:smartassist/widgets/testdrive/overdue.dart';
import 'package:smartassist/widgets/testdrive_verifyotp.dart';

class TestdriveAdminAlls extends StatefulWidget {
  final String name, date, vehicle, subject, leadId, eventId, startTime, email;
  final bool isFavorite, isCompleted;
  final VoidCallback onToggleFavorite;
  final VoidCallback handleTestDrive;
  final VoidCallback otpTrigger;

  const TestdriveAdminAlls({
    super.key,
    required this.name,
    required this.subject,
    required this.date,
    required this.vehicle,
    required this.leadId,
    this.isFavorite = false,
    required this.onToggleFavorite,
    required this.startTime,
    required this.eventId,
    required this.handleTestDrive,
    required this.otpTrigger,
    required this.email,
    required this.isCompleted,
  });

  @override
  State<TestdriveAdminAlls> createState() => _AllFollowupsItemState();
}

class _AllFollowupsItemState extends State<TestdriveAdminAlls>
    with SingleTickerProviderStateMixin {
  bool _wasCallingPhone = false;

  // late SlidableController _slidableController;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // void _handleTestDrive(dynamic item) {
  //   String email = item['updated_by'] ?? '';
  //   String mobile = item['mobile'] ?? '';
  //   String eventId = item['event_id'] ?? '';
  //   String leadId = item['lead_id'] ?? '';
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TestdriveVerifyotp(
  //         email: email,
  //         mobile: mobile,
  //         leadId: leadId,
  //         eventId: eventId,
  //       ),
  //     ),
  //   );
  //   print("Call action triggered for ${item['name']}");
  // }

  //   Future<void> _getOtp(String eventId) async {
  //   final success = await LeadsSrv.getOtp(eventId: eventId);

  //   if (success) {
  //     print('✅ Test drive started successfully');
  //   } else {
  //     print('❌ Failed to start test drive');
  //   }

  //   if (mounted) setState(() {});
  // }

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
                  refreshDashboard: () async {},
                ),
              ),
            );
          } else {
            print("Invalid leadId");
          }
        },
        child: _buildOverdueCard(context),
      ),
    );
  }

  Widget _buildOverdueCard(BuildContext context) {
    return Stack(
      children: [
        // Main Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.containerBg,
            borderRadius: BorderRadius.circular(5),
            border: Border(
              left: BorderSide(
                width: 8.0,
                color: widget.isFavorite
                    ? Colors.yellow
                    : AppColors.colorsBlueBar,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    IconData icon;
    if (widget.subject == 'Test Drive') {
      icon = Icons.directions_car_filled_rounded;
    } else if (widget.subject == 'Send SMS') {
      icon = Icons.mail_rounded;
    } else {
      icon = Icons.phone; // fallback icon
    }

    return Row(
      children: [
        Icon(icon, color: AppColors.colorsBlue, size: 18),
        const SizedBox(width: 5),
        Text('${widget.subject},', style: AppFont.smallText(context)),
      ],
    );
  }

  // Widget _buildSubjectDetails(BuildContext context) {
  //   return Row(
  //     children: [
  //       const Icon(Icons.phone_in_talk, color: AppColors.colorsBlue, size: 18),
  //       const SizedBox(width: 5),
  //       Text('${widget.subject},', style: AppFont.smallText(context)),
  //     ],
  //   );
  // }

  Widget _date(BuildContext context) {
    String formattedDate = '';
    try {
      DateTime parseDate = DateTime.parse(widget.date);
      if (parseDate.year == DateTime.now().year &&
          parseDate.month == DateTime.now().month &&
          parseDate.day == DateTime.now().day) {
        formattedDate = 'Today';
      } else {
        int day = parseDate.day;
        String suffix = _getDaySuffix(day);
        String month = DateFormat('MMM').format(parseDate);
        formattedDate = '$day$suffix $month';
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

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
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
          setState(() {
            _isActionPaneOpen = false;
          });
        } else {}
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

  // void _phoneAction() {
  //   print("Call action triggered for ${widget.mobile}");

  //   // String mobile = item['mobile'] ?? '';

  //   if (widget.mobile.isNotEmpty) {
  //     try {
  //       // Set flag that we're making a phone call
  //       _wasCallingPhone = true;

  //       // Simple approach without canLaunchUrl check
  //       final phoneNumber = 'tel:${widget.mobile}';
  //       launchUrl(
  //         Uri.parse(phoneNumber),
  //         mode: LaunchMode.externalNonBrowserApplication,
  //       );
  //     } catch (e) {
  //       print('Error launching phone app: $e');

  //       // Reset flag if there was an error
  //       _wasCallingPhone = false;
  //       // Show error message to user
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Could not launch phone dialer')),
  //         );
  //       }
  //     }
  //   } else {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('No phone number available')));
  //     }
  //   }
  // }
}

class TestdriveAdminAll extends StatefulWidget {
  final List<dynamic> allTestDrive;
  final bool isNested;

  const TestdriveAdminAll({
    super.key,
    required this.allTestDrive,
    this.isNested = false,
  });

  @override
  State<TestdriveAdminAll> createState() => _TestdriveAdminAllState();
}

class _TestdriveAdminAllState extends State<TestdriveAdminAll> {
  List<bool> _favorites = [];
  int _currentDisplayCount = 10;
  final int _incrementCount = 10;

  @override
  void initState() {
    super.initState();
    _initializeFavorites();
    _currentDisplayCount = math.min(
      _incrementCount,
      widget.allTestDrive.length,
    );
  }

  @override
  void didUpdateWidget(TestdriveAdminAll oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.allTestDrive != oldWidget.allTestDrive) {
      _initializeFavorites();
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.allTestDrive.length,
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
      _currentDisplayCount = widget.allTestDrive.length;
      print('📊 Loading all records. New display count: $_currentDisplayCount');
    });
  }

  Widget _buildShowMoreButton() {
    // If no data, don't show anything
    if (widget.allTestDrive.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fix invalid display count
    if (_currentDisplayCount <= 0 ||
        _currentDisplayCount > widget.allTestDrive.length) {
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.allTestDrive.length,
      );
    }

    // Check if we can show more records
    bool hasMoreRecords = _currentDisplayCount < widget.allTestDrive.length;

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
                    'Show All (${widget.allTestDrive.length - _currentDisplayCount} more)', // Updated text
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

  Future<void> _getOtp(String eventId) async {
    final success = await LeadsSrv.getOtp(eventId: eventId);

    if (success) {
      print('✅ Test drive started successfully');
    } else {
      print('❌ Failed to start test drive');
    }

    if (mounted) setState(() {});
  }

  void _initializeFavorites() {
    _favorites = List.generate(
      widget.allTestDrive.length,
      (index) => widget.allTestDrive[index]['favourite'] == true,
    );
  }

  // void _toggleFavorite(int index) {
  //   setState(() {
  //     _favorites[index] = !_favorites[index];
  //   });
  // }

  Future<void> _toggleFavorite(String eventId, int index) async {
    bool currentStatus = widget.allTestDrive[index]['favourite'] ?? false;
    bool newFavoriteStatus = !currentStatus;

    final success = await LeadsSrv.favoriteTestDrive(eventId: eventId);

    if (success) {
      setState(() {
        widget.allTestDrive[index]['favourite'] = newFavoriteStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allTestDrive.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No Testdrive available",
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    //    return ListView.builder(
    //     shrinkWrap: true,
    //     physics: widget.isNested
    //         ? const NeverScrollableScrollPhysics()
    //         : const AlwaysScrollableScrollPhysics(),
    //     itemCount: widget.allTestDrive.length,
    //     itemBuilder: (context, index) {
    //       var item = widget.allTestDrive[index];

    //       if (!(item.containsKey('assigned_to') &&
    //           item.containsKey('start_date') &&
    //           item.containsKey('lead_id') &&
    //           item.containsKey('event_id'))) {
    //         return ListTile(title: Text('Invalid data at index $index'));
    //       }

    //       String eventId = item['event_id'];
    //       // double swipeOffset = _swipeOffsets[eventId] ?? 0;

    //       return GestureDetector(
    //         child: upcomingTestDrivesItem(
    //           key: ValueKey(item['event_id']),
    //           name: item['name'],
    //           vehicle: item['PMI'] ?? 'Range Rover Velar',
    //           subject: item['subject'] ?? 'Meeting',

    //           date: item['start_date'],
    //           email: item['updated_by'],
    //           leadId: item['lead_id'],
    //           startTime:
    //               (item['start_time'] != null &&
    //                   item['start_time'].toString().isNotEmpty)
    //               ? item['start_time'].toString()
    //               : "00:00:00",

    //           eventId: item['event_id'] ?? '',

    //           isFavorite: item['favourite'] ?? false,
    //           swipeOffset: swipeOffset,
    //           onToggleFavorite: () {
    //             _toggleFavorite(eventId, index);
    //           },
    //           otpTrigger: () {
    //             _getOtp(eventId);
    //           },
    //           fetchDashboardData: () {},
    //           handleTestDrive: () {
    //             _handleTestDrive(item);
    //           },
    //           refreshDashboard: widget.refreshDashboard,

    //           // Placeholder, replace with actual method
    //         ),
    //       );
    //     },
    //   );
    // }

    // Get the items to display based on current count
    List<dynamic> itemsToDisplay = widget.allTestDrive
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
          // itemCount: widget.allTestDrive.length,
          itemCount:
              _currentDisplayCount, // Changed from widget.allFollowups.length

          itemBuilder: (context, index) {
            var item = widget.allTestDrive[index];

            if (!(item.containsKey('assigned_to') &&
                item.containsKey('start_date') &&
                item.containsKey('lead_id') &&
                item.containsKey('event_id'))) {
              return ListTile(title: Text('Invalid data at index $index'));
            }

            String eventId = item['event_id'];
            // double swipeOffset = _swipeOffsets[eventId] ?? 0;

            return GestureDetector(
              child: TestdriveAdminAlls(
                key: ValueKey(item['event_id']),
                name: item['name'] ?? '',
                vehicle: item['PMI'] ?? 'Range Rover Velar',
                subject: item['subject'] ?? 'Meeting',

                date: item['start_date'] ?? '',
                // email: item['updated_by'], // Removed because 'email' is not a defined parameter
                leadId: item['lead_id'],
                startTime:
                    (item['start_time'] != null &&
                        item['start_time'].toString().isNotEmpty)
                    ? item['start_time'].toString()
                    : "00:00:00",

                eventId: item['event_id'] ?? '',

                isFavorite: item['favourite'] ?? false,
                // swipeOffset: swipeOffset,
                onToggleFavorite: () {
                  _toggleFavorite(eventId, index);
                },
                otpTrigger: () {
                  _getOtp(eventId);
                },
                // fetchDashboardData: () {},
                handleTestDrive: () {
                  _handleTestDrive(item);
                },
                email: '',
                isCompleted: item['completed'] ?? false,
              ),
            );
          },
        ), // Add the show more/less button
        _buildShowMoreButton(),
      ],
    );
  }
}
