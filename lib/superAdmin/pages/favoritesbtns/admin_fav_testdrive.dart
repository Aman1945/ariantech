import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
import 'package:smartassist/widgets/reusable/skeleton_card.dart';

class AdminFavTestdrive extends StatefulWidget {
  const AdminFavTestdrive({super.key});

  @override
  State<AdminFavTestdrive> createState() => _AdminFavTestdriveState();
}

class _AdminFavTestdriveState extends State<AdminFavTestdrive> {
  bool isLoading = true;
  final Map<String, double> _swipeOffsets = {};
  List<dynamic> upcomingTasks = [];
  List<dynamic> overdueTasks = [];

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
      _handleCall(item);
    }

    // Reset animation
    setState(() {
      _swipeOffsets[eventId] = 0.0;
    });
  }

  // Alternative simpler approach - replace your _toggleFavorite method:

  Future<void> _toggleFavorite(String eventId, int index) async {
    final token = await Storage.getToken();
    try {
      // Find the current favorite status by searching for the event
      bool currentStatus = false;

      // Search in both lists to find the current status
      for (var task in [...upcomingTasks, ...overdueTasks]) {
        if (task['event_id'] == eventId) {
          currentStatus = task['favourite'] ?? false;
          break;
        }
      }

      bool newFavoriteStatus = !currentStatus;

      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/favourites/mark-fav/event/$eventId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response to get the updated favorite status
        final responseData = json.decode(response.body);

        // Update the task in both lists if it exists
        setState(() {
          // Update in upcoming tasks
          for (int i = 0; i < upcomingTasks.length; i++) {
            if (upcomingTasks[i]['event_id'] == eventId) {
              upcomingTasks[i]['favourite'] = newFavoriteStatus;
              break;
            }
          }

          // Update in overdue tasks
          for (int i = 0; i < overdueTasks.length; i++) {
            if (overdueTasks[i]['event_id'] == eventId) {
              overdueTasks[i]['favourite'] = newFavoriteStatus;
              break;
            }
          }
        });

        print('✅ Favorite toggled successfully');
        print('upcomingTasks length: ${upcomingTasks.length}');
        print('overdueTasks length: ${overdueTasks.length}');
        await fetchTasksData();
      } else {
        print('❌ Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
    }
  }

  void _handleCall(dynamic item) {
    print("Call action triggered for ${item['name']}");
    // Implement actual call functionality here
  }

  @override
  void initState() {
    super.initState();
    fetchTasksData();
  }

  Future<void> fetchTasksData() async {
    final token = await Storage.getToken();
    final adminId = await AdminUserIdManager.getAdminUserId();
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.smartassistapp.in/api/app-admin/fav-events/all?userId=$adminId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('status code11 ${response.statusCode}');
        final data = json.decode(response.body);
        setState(() {
          upcomingTasks = data['data']['upcomingDrives']['rows'] ?? [];
          overdueTasks = data['data']['overdueDrives']['rows'] ?? [];
          isLoading = false;
          print('this is from FOppointment ${Uri.parse}');
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
        print('this is the api appoinment${Uri}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
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
    if (isLoading) {
      return SkeletonCard();
    }

    if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Center(
          child: Text('No data found', style: AppFont.dropDowmLabel(context)),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTasksList(upcomingTasks, isUpcoming: true),
          _buildTasksList(overdueTasks, isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<dynamic> tasks, {required bool isUpcoming}) {
    // if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
    //   return const Center(child: Text('No data found'));
    // }

    if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 0.15, vertical: 20),
        child: Center(
          child: Text(
            'No data found',
            style: AppFont.dropDowmLabel(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var item = tasks[index];

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
          child: TaskItem(
            key: ValueKey(item['event_id']),
            name: item['name'],
            vehicle: item['PMI'] ?? 'Discovery Sport',
            subject: item['subject'] ?? 'Meeting',
            date: item['start_date'],
            leadId: item['lead_id'],
            startTime: item['start_time'],
            eventId: item['event_id'],
            isFavorite: item['favourite'] ?? false,
            swipeOffset: swipeOffset,
            fetchDashboardData: () {},
            onFavoriteToggled: () {},
            onToggleFavorite: () {
              _toggleFavorite(eventId, index);
            },
            isUpcoming: isUpcoming,
            // handleTestDrive: () {
            //   _handleTestDrive(item);
            // },
            otpTrigger: () {
              _getOtp(eventId);
            },
          ),
        );
      },
    );
  }
}

class TaskItem extends StatefulWidget {
  final String name, date, vehicle, leadId, eventId, startTime, subject;
  final bool isFavorite;
  final VoidCallback fetchDashboardData;
  final bool isUpcoming;
  final VoidCallback onFavoriteToggled;
  final double swipeOffset;
  final VoidCallback onToggleFavorite;

  // final VoidCallback handleTestDrive;
  final dynamic item;
  final VoidCallback otpTrigger;
  const TaskItem({
    super.key,
    required this.name,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.isFavorite,
    required this.eventId,
    required this.startTime,
    required this.fetchDashboardData,
    required this.isUpcoming,
    required this.subject,
    required this.onFavoriteToggled,
    required this.swipeOffset,
    required this.onToggleFavorite,
    this.item,
    required this.otpTrigger,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
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
                builder: (context) => FollowupsDetails(
                  leadId: widget.leadId,
                  isFromFreshlead: false,
                  isFromManager: false,
                  spId: '',
                  isFromTestdriveOverview: false,
                  refreshDashboard: () async {},
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
      onPressed: (context) => onPressed(),
      backgroundColor: backgroundColor,
      child: Icon(icon, size: iconSize, color: foregroundColor ?? Colors.white),
    );
  }
}
