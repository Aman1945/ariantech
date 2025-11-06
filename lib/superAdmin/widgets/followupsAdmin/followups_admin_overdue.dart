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
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/followups.dart';
import 'package:url_launcher/url_launcher.dart';

class FollowupsAdminOverdue extends StatefulWidget {
  final Future<void> Function() refreshDashboard;
  final bool isNested;
  final List<dynamic> overdueeFollowups;
  final Function(String, bool)? onFavoriteToggle;
  const FollowupsAdminOverdue({
    super.key,
    required this.overdueeFollowups,
    required this.isNested,
    this.onFavoriteToggle,
    required this.refreshDashboard,
  });

  @override
  State<FollowupsAdminOverdue> createState() => _FollowupsAdminOverdueState();
}

class _FollowupsAdminOverdueState extends State<FollowupsAdminOverdue> {
  bool isLoading = false;
  final Map<String, double> _swipeOffsets = {};
  List<dynamic> overdueFollowups = [];
  int _currentDisplayCount = 10;
  final int _incrementCount = 10;

  @override
  void initState() {
    super.initState();
    print("widget.upcomingFollowups");
    print(widget.overdueeFollowups);
    _currentDisplayCount = math.min(
      _incrementCount,
      widget.overdueeFollowups.length,
    );
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overdueeFollowups != oldWidget.overdueeFollowups) {
      // _initializeFavorites();
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.overdueeFollowups.length,
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
      _currentDisplayCount = widget.overdueeFollowups.length;
      print('📊 Loading all records. New display count: $_currentDisplayCount');
    });
  }

  // void _onHorizontalDragUpdate(DragUpdateDetails details, String taskId) {
  //   setState(() {
  //     _swipeOffsets[taskId] =
  //         (_swipeOffsets[taskId] ?? 0) + (details.primaryDelta ?? 0);
  //   });
  // }

  // void _onHorizontalDragEnd(DragEndDetails details, dynamic item, int index) {
  //   String taskId = item['task_id'];
  //   double swipeOffset = _swipeOffsets[taskId] ?? 0;

  //   if (swipeOffset > 100) {
  //     // Right Swipe (Favorite)
  //     _toggleFavorite(taskId, index);
  //   } else if (swipeOffset < -100) {
  //     // Left Swipe (Call)
  //     _handleCall(item);
  //   }

  //   // Reset animation
  //   setState(() {
  //     _swipeOffsets[taskId] = 0.0;
  //   });
  // }

  void _handleCall(dynamic item) {
    print("Call action triggered for ${item['name']}");

    String mobile = item['mobile'] ?? '';

    if (mobile.isNotEmpty) {
      try {
        // Simple approach without canLaunchUrl check
        final phoneNumber = 'tel:$mobile';
        launchUrl(
          Uri.parse(phoneNumber),
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (e) {
        print('Error launching phone app: $e');
        // Show error message to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No phone number available')));
      }
    }
  }

  Future<void> _toggleFavorite(String taskId, int index) async {
    bool currentStatus = widget.overdueeFollowups[index]['favourite'] ?? false;
    bool newFavoriteStatus = !currentStatus;

    final success = await LeadsSrv.favorite(taskId: taskId);

    if (success) {
      setState(() {
        widget.overdueeFollowups[index]['favourite'] = newFavoriteStatus;
      });

      if (widget.onFavoriteToggle != null) {
        widget.onFavoriteToggle!(taskId, newFavoriteStatus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overdueeFollowups.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No overdue followups available',
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    // Get the items to display based on current count
    List<dynamic> itemsToDisplay = widget.overdueeFollowups
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
          // itemCount: widget.overdueeFollowups.length,
          itemCount: _currentDisplayCount,
          itemBuilder: (context, index) {
            var item = widget.overdueeFollowups[index];

            if (!(item.containsKey('name') &&
                item.containsKey('due_date') &&
                item.containsKey('lead_id') &&
                item.containsKey('task_id'))) {
              return ListTile(title: Text('Invalid data at index $index'));
            }

            String taskId = item['task_id'];
            double swipeOffset = _swipeOffsets[taskId] ?? 0;

            return GestureDetector(
              // onHorizontalDragUpdate: (details) =>
              //     _onHorizontalDragUpdate(details, taskId),
              // onHorizontalDragEnd: (details) =>
              //     _onHorizontalDragEnd(details, item, index),
              child: overdueeFollowupsItem(
                name: item['name'] ?? '',
                mobile: item['mobile'] ?? '',
                subject: item['subject'] ?? 'call',
                date: item['due_date'] ?? '',
                taskId: item['task_id'] ?? '',
                vehicle: item['PMI'] ?? 'Range Rover Velar',
                leadId: item['lead_id'],
                refreshDashboard: widget.refreshDashboard,
                // taskId: taskId,
                onToggleFavorite: () {
                  _toggleFavorite(taskId, index);
                },
                isFavorite: item['favourite'] ?? false,
                swipeOffset: swipeOffset,
                // fetchDashboardData:
                //     () {}, // Placeholder, replace with actual method
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
    if (widget.overdueeFollowups.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fix invalid display count
    if (_currentDisplayCount <= 0 ||
        _currentDisplayCount > widget.overdueeFollowups.length) {
      _currentDisplayCount = math.min(
        _incrementCount,
        widget.overdueeFollowups.length,
      );
    }

    // Check if we can show more records
    bool hasMoreRecords =
        _currentDisplayCount < widget.overdueeFollowups.length;

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
                    'Show All (${widget.overdueeFollowups.length - _currentDisplayCount} more)', // Updated text
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

class overdueeFollowupsItem extends StatefulWidget {
  final String name, mobile, taskId;
  final String subject;
  final String date;
  final String vehicle;
  final String leadId;
  final Future<void> Function() refreshDashboard;
  final double swipeOffset;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const overdueeFollowupsItem({
    super.key,
    required this.name,
    required this.subject,
    required this.date,
    required this.vehicle,
    required this.leadId,
    this.swipeOffset = 0.0,
    this.isFavorite = false,
    required this.onToggleFavorite,
    required this.mobile,
    required this.taskId,
    required this.refreshDashboard,
  });

  @override
  State<overdueeFollowupsItem> createState() => _overdueeFollowupsItemState();
}

class _overdueeFollowupsItemState extends State<overdueeFollowupsItem>
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
    bool isFavoriteSwipe = widget.swipeOffset > 50;
    bool isCallSwipe = widget.swipeOffset < -50;

    return Stack(
      children: [
        // Favorite Swipe Overlay
        if (isFavoriteSwipe) Positioned.fill(child: _buildFavoriteOverlay()),

        // Call Swipe Overlay
        if (isCallSwipe) Positioned.fill(child: _buildCallOverlay()),

        // Main Card
        Opacity(
          opacity: (isFavoriteSwipe || isCallSwipe) ? 0 : 1.0,
          child: Container(
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

  Widget _buildFavoriteOverlay() {
    return Container(
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
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(
            widget.isFavorite ? Icons.star_outline_rounded : Icons.star_rounded,
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
    );
  }

  Widget _buildCallOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.phone_in_talk, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Text(
            'Call',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
    if (widget.subject == 'Call') {
      icon = Icons.phone_in_talk;
    } else if (widget.subject == 'Send SMS') {
      icon = Icons.mail_rounded;
    } else if (widget.subject == 'Provide quotation') {
      icon = Icons.mail_rounded;
    } else if (widget.subject == 'Send Email') {
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
          child: FollowupsEdit(onFormSubmit: () {}, taskId: widget.taskId),
        );
      },
    );
  }
}
