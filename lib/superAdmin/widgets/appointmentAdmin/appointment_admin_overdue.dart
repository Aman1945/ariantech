import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
// import 'package:smartassist/pages/home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/superAdmin/pages/single_id_view.dart/admin_singlelead_followups.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/appointments.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------- appointment UPCOMING LIST ----------------
class AppointmentAdminOverdue extends StatefulWidget {
  final Future<void> Function() refreshDashboard;
  final List<dynamic> overdueeOpp;
  final bool isNested;

  final Function(String, bool)? onFavoriteToggle;
  const AppointmentAdminOverdue({
    super.key,
    required this.overdueeOpp,
    required this.isNested,
    this.onFavoriteToggle,
    required this.refreshDashboard,
  });

  @override
  State<AppointmentAdminOverdue> createState() => _AppointmentAdminOverdueState();
}

class _AppointmentAdminOverdueState extends State<AppointmentAdminOverdue> {
  bool isLoading = false;
  bool _showLoader = true;
  final Map<String, double> _swipeOffsets = {};
  List<dynamic> overdueAppointments = [];
  int _currentDisplayCount = 10;
  final int _incrementCount = 10;

  @override
  void initState() {
    super.initState();
    // fetchDashboardData();
    overdueAppointments = widget.overdueeOpp;
    _currentDisplayCount = math.min(_incrementCount, widget.overdueeOpp.length);
    print('this is widget.overdue appointmnet');
    print(widget.overdueeOpp);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overdueeOpp != oldWidget.overdueeOpp) {
      // _initializeFavorites();
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.overdueeOpp.length,
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
      _currentDisplayCount = widget.overdueeOpp.length;
      print('📊 Loading all records. New display count: $_currentDisplayCount');
    });
  }

  // void _handleCall(dynamic item) {
  //   print("Call action triggered for ${item['name']}");

  //   String mobile = item['mobile'] ?? '';

  //   if (mobile.isNotEmpty) {
  //     try {
  //       // Simple approach without canLaunchUrl check
  //       final phoneNumber = 'tel:$mobile';
  //       launchUrl(
  //         Uri.parse(phoneNumber),
  //         mode: LaunchMode.externalNonBrowserApplication,
  //       );
  //     } catch (e) {
  //       print('Error launching phone app: $e');
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

  Future<void> _toggleFavorite(String taskId, int index) async {
    bool currentStatus = widget.overdueeOpp[index]['favourite'] ?? false;
    bool newFavoriteStatus = !currentStatus;

    final success = await LeadsSrv.favoriteEvent(taskId: taskId);

    if (success) {
      setState(() {
        widget.overdueeOpp[index]['favourite'] = newFavoriteStatus;
      });

      if (widget.onFavoriteToggle != null) {
        widget.onFavoriteToggle!(taskId, newFavoriteStatus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overdueeOpp.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No Overdue Appointment available',
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }
    // Get the items to display based on current count
    List<dynamic> itemsToDisplay = widget.overdueeOpp
        .take(_currentDisplayCount)
        .toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: widget.isNested
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          // itemCount: widget.overdueeOpp.length,
          itemCount: _currentDisplayCount,
          itemBuilder: (context, index) {
            var item = widget.overdueeOpp[index];

            String taskId = item['task_id'];
            double swipeOffset = _swipeOffsets[taskId] ?? 0;

            return GestureDetector(
              child: overdueeOppItem(
                key: ValueKey(taskId),
                name: item['name'] ?? '',
                subject: item['subject'] ?? 'Meeting',
                date: item['due_date'] ?? '',
                vehicle: item['PMI'] ?? 'Range Rover Velar',
                leadId: item['lead_id'],
                mobile: item['mobile'] ?? '',
                time: item['time'] ?? '',
                taskId: item['task_id'] ?? '',
                refreshDashboard: widget.refreshDashboard,
                isFavorite: item['favourite'] ?? false,
                // swipeOffset: swipeOffset,
                fetchDashboardData: () {},
                onToggleFavorite: () {
                  _toggleFavorite(taskId, index);
                },
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
    if (widget.overdueeOpp.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fix invalid display count
    if (_currentDisplayCount <= 0 ||
        _currentDisplayCount > widget.overdueeOpp.length) {
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.overdueeOpp.length,
      );
    }

    // Check if we can show more records
    bool hasMoreRecords = _currentDisplayCount < widget.overdueeOpp.length;

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
                    'Show All (${widget.overdueeOpp.length - _currentDisplayCount} more)', // Updated text
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

class overdueeOppItem extends StatefulWidget {
  final String name, date, vehicle, mobile, leadId, taskId, time, subject;
  // final double swipeOffset;
  final bool isFavorite;
  final VoidCallback fetchDashboardData;
  final VoidCallback onToggleFavorite;
  final Future<void> Function() refreshDashboard;

  const overdueeOppItem({
    super.key,
    required this.name,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.isFavorite,
    required this.fetchDashboardData,
    required this.taskId,
    required this.time,
    // required this.swipeOffset,
    required this.subject,
    required this.onToggleFavorite,
    required this.mobile,
    required this.refreshDashboard,
  });

  @override
  State<overdueeOppItem> createState() => _overdueeOppItemState();
}

class _overdueeOppItemState extends State<overdueeOppItem>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _wasCallingPhone = false;

  late SlidableController _slidableController;

  @override
  void initState() {
    super.initState();
    // Register this class as an observer to track app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
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
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    _slidableController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This gets called when app lifecycle state changes
    if (state == AppLifecycleState.resumed && _wasCallingPhone) {
      // App is resumed and we marked that user was making a call
      _wasCallingPhone = false;
      // Show the mail action dialog after a short delay to ensure app is fully resumed
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mailAction();
        }
      });
    }
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
        child: _buildOverdueCard(context),
      ),
    );
  }

  Widget _buildOverdueCard(BuildContext context) {
    // bool isFavoriteSwipe = widget.swipeOffset > 50;
    // bool isCallSwipe = widget.swipeOffset < -50;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.containerBg,
            borderRadius: BorderRadius.circular(5),
            border: Border(
              left: BorderSide(
                width: 8.0,
                color: widget.isFavorite ? Colors.yellow : AppColors.sideRed,
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

  void _phoneAction() {
    print("Call action triggered for ${widget.mobile}");

    if (widget.mobile.isNotEmpty) {
      try {
        // Set flag that we're making a phone call
        _wasCallingPhone = true;

        // Use the same approach as _handleCall - no launch mode specified
        launchUrl(Uri.parse('tel:${widget.mobile}'));

        print('Phone dialer launched');
      } catch (e) {
        print('Error launching phone app: $e');

        // Reset flag if there was an error
        _wasCallingPhone = false;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
    }
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
          child: AppointmentsEdit(onFormSubmit: () {}, taskId: widget.taskId),
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
    IconData icon;
    if (widget.subject == 'Meeting') {
      icon = Icons.phone_in_talk;
    } else if (widget.subject == 'Provide Quotation') {
      icon = Icons.mail_rounded;
    } else if (widget.subject == 'Showroom appointment') {
      icon = Icons.mail_rounded;
    } else {
      icon = Icons.phone; // fallback icon
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.colorsBlue, size: 18),
        const SizedBox(width: 5),
        Text('${widget.subject},', style: AppFont.smallText(context)),
      ],
    );
  }

  Widget _time() {
    DateTime parsedTime = DateFormat("HH:mm:ss").parse(widget.time);
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

  // Widget _buildCarModel(BuildContext context) {
  //   return Text(
  //     widget.vehicle,
  //     style: AppFont.dashboardCarName(context),
  //     overflow: TextOverflow.visible, // Allow text wrapping
  //     softWrap: true, // Enable wrapping
  //   );
  // }
  bool _isActionPaneOpen = false; // Declare this in your StatefulWidget

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

class ReusableSlidableAction extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData icon;
  final Color? foregroundColor;
  final double iconSize;

  const ReusableSlidableAction({
    Key? key,
    required this.onPressed,
    required this.backgroundColor,
    required this.icon,
    this.foregroundColor,
    this.iconSize = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      padding: EdgeInsets.zero,
      onPressed: (context) => onPressed(),
      backgroundColor: backgroundColor,
      child: Icon(icon, size: iconSize, color: foregroundColor ?? Colors.white),
    );
  }
}
