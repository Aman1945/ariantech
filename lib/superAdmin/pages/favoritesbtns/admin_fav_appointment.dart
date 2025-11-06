import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/appointments.dart';
import 'package:smartassist/widgets/reusable/skeleton_card.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminFavAppointment extends StatefulWidget {
  const AdminFavAppointment({super.key});

  @override
  State<AdminFavAppointment> createState() => _AdminFavAppointmentState();
}

class _AdminFavAppointmentState extends State<AdminFavAppointment> {
  bool isLoading = true;
  final Map<String, double> _swipeOffsets = {};
  List<dynamic> upcomingTasks = [];
  List<dynamic> overdueTasks = [];
  // String get taskId => null;

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

  Future<void> _toggleFavorite(String taskId, int index) async {
    final token = await Storage.getToken();
    try {
      // Find the current favorite status by searching for the event
      bool currentStatus = false;

      // Search in both lists to find the current status
      for (var task in [...upcomingTasks, ...overdueTasks]) {
        if (task['task_id'] == taskId) {
          currentStatus = task['favourite'] ?? false;
          break;
        }
      }

      bool newFavoriteStatus = !currentStatus;

      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/favourites/mark-fav/task/$taskId',
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
            if (upcomingTasks[i]['task_id'] == taskId) {
              upcomingTasks[i]['favourite'] = newFavoriteStatus;
              break;
            }
          }

          // Update in overdue tasks
          for (int i = 0; i < overdueTasks.length; i++) {
            if (overdueTasks[i]['task_id'] == taskId) {
              overdueTasks[i]['favourite'] = newFavoriteStatus;
              break;
            }
          }
        });

        print('✅ Favorite toggled successfully');
        print('upcomingTasks length: ${upcomingTasks.length}');
        print('overdueTasks length: ${overdueTasks.length}');
      } else {
        print('❌ Failed to toggle favorite: ${response.statusCode}');
      }
      await fetchTasksData();
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
          'https://api.smartassistapp.in/api/app-admin/fav-appointments/all?userId=$adminId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('status code 22 ${response.statusCode}');
        final data = json.decode(response.body);
        setState(() {
          // upcomingTasks = data['data']['upcomingAppointments']['rows'] ?? [];
          // overdueTasks = data['data']['overdueAppointments']['rows'] ?? [];
          overdueTasks = data['data']['allAppointments']['rows'] ?? [];

          isLoading = false;
          print(
            'Fetched tasks: upcoming=${upcomingTasks.length}, overdue=${overdueTasks.length}',
          );
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    if (isLoading) {
      return SkeletonCard();
    }

    if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet
              ? screenSize.width * 0.15
              : screenSize.width * 0.1,
          vertical: isTablet ? 30 : 20,
        ),
        child: Center(
          child: Text(
            'No data found',
            style: AppFont.dropDowmLabel(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTasksList(upcomingTasks, isUpcoming: true),
          _buildTasksList(overdueTasks, isUpcoming: true),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<dynamic> tasks, {required bool isUpcoming}) {
    if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
      return const Center(child: Text('No data found'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var item = tasks[index];

        // Validate required fields based on API response
        if (!item.containsKey('task_id') ||
            item['task_id'] == null ||
            !item.containsKey('name') ||
            !item.containsKey('due_date') ||
            !item.containsKey('time') ||
            !item.containsKey('lead_id')) {
          return ListTile(title: Text('Invalid task data at index $index'));
        }

        String taskId = item['task_id'];
        double swipeOffset = _swipeOffsets[taskId] ?? 0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(details, taskId),
          onHorizontalDragEnd: (details) =>
              _onHorizontalDragEnd(details, item, index),
          child: TaskItem(
            key: ValueKey(taskId),
            name: item['name']?.toString() ?? 'Unknown',
            subject: item['subject']?.toString() ?? 'Meeting',
            date: item['due_date']?.toString() ?? '',
            vehicle: item['PMI']?.toString() ?? 'Unknown Vehicle',
            leadId: item['lead_id']?.toString() ?? '',
            time: item['time']?.toString() ?? '',
            taskId: taskId,
            mobile: item['mobile']?.toString() ?? '',
            isFavorite: item['favourite'] == true,
            isUpcoming: isUpcoming,
            // swipeOffset: swipeOffset,
            fetchDashboardData: () {},
            onFavoriteToggled: () {},
            onToggleFavorite: () {
              _toggleFavorite(taskId, index);
            },
          ),
        );
      },
    );
  }
}

class TaskItem extends StatefulWidget {
  final String name, subject, mobile;
  final String date;
  final String vehicle;
  final String leadId;
  final String taskId;
  final bool isFavorite;
  final bool isUpcoming;
  final String time;
  final VoidCallback onFavoriteToggled;
  // final double swipeOffset;
  final VoidCallback fetchDashboardData;

  final VoidCallback onToggleFavorite;

  const TaskItem({
    super.key,
    required this.name,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.taskId,
    required this.isFavorite,
    required this.isUpcoming,
    required this.onFavoriteToggled,
    required this.time,
    // required this.swipeOffset,
    required this.fetchDashboardData,
    required this.subject,
    required this.onToggleFavorite,
    required this.mobile,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late bool isFav;

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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
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
                color: widget.isFavorite ? Colors.yellow : AppColors.sideGreen,
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

  // Widget _buildFollowupCard(BuildContext context) {
  //   // bool isFavoriteSwipe = widget.swipeOffset > 50;
  //   // bool isCallSwipe = widget.swipeOffset < -50;

  //   return Slidable(
  //     key: ValueKey(widget.taskId), // Always good to set keys
  //     controller: _slidableController,
  //     startActionPane: ActionPane(
  //       extentRatio: 0.2,
  //       motion: const ScrollMotion(),
  //       children: [
  //         ReusableSlidableAction(
  //           onPressed: widget.onToggleFavorite, // handle fav toggle
  //           backgroundColor: Colors.amber,
  //           icon: widget.isFavorite
  //               ? Icons.star_rounded
  //               : Icons.star_border_rounded,
  //           foregroundColor: Colors.white,
  //         ),
  //       ],
  //     ),

  //     endActionPane: ActionPane(
  //       extentRatio: 0.4,
  //       motion: const StretchMotion(),
  //       children: [
  //         // if (widget.subject == 'Meeting')
  //         ReusableSlidableAction(
  //           onPressed: _phoneAction,
  //           backgroundColor: AppColors.colorsBlue,
  //           icon: Icons.phone,
  //           foregroundColor: Colors.white,
  //         ),
  //         if (widget.subject == 'Quetations')
  //           ReusableSlidableAction(
  //             onPressed: _messageAction,
  //             backgroundColor: AppColors.colorsBlueGrey,
  //             icon: Icons.message_rounded,
  //             foregroundColor: Colors.white,
  //           ),
  //         // Edit is always shown
  //         ReusableSlidableAction(
  //           onPressed: _mailAction,
  //           backgroundColor: const Color.fromARGB(255, 231, 225, 225),
  //           icon: Icons.edit,
  //           foregroundColor: Colors.white,
  //         ),
  //       ],
  //     ),

  //     child: Stack(
  //       children: [
  //         // Main Container
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             Row(
  //               children: [
  //                 const SizedBox(width: 8),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       children: [
  //                         _buildUserDetails(context),
  //                         _buildVerticalDivider(15),
  //                         _buildCarModel(context),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Row(
  //                       children: [
  //                         _buildSubjectDetails(context),
  //                         _date(context),
  //                         _time(),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             _buildNavigationButton(context),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
    // return SlidableAction(
    //   onPressed: (context) => onPressed(),
    //   backgroundColor: backgroundColor,
    //   foregroundColor: foregroundColor ?? Colors.white,
    //   icon: icon,
    //   borderRadius: BorderRadius.circular(0),
    // );

    return CustomSlidableAction(
      padding: EdgeInsets.zero,
      onPressed: (context) => onPressed(),
      backgroundColor: backgroundColor,
      child: Icon(icon, size: iconSize, color: foregroundColor ?? Colors.white),
    );
  }
}
