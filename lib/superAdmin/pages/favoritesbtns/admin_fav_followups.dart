import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/leads_srv.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/followups.dart';
import 'package:smartassist/widgets/reusable/skeleton_card.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminFavFollowups extends StatefulWidget {
  final String leadId;
  const AdminFavFollowups({super.key, required this.leadId});

  @override
  State<AdminFavFollowups> createState() => _AdminFavFollowupsState();
}

class _AdminFavFollowupsState extends State<AdminFavFollowups> {
  final Map<String, double> _swipeOffsets = {};
  bool isLoading = true;
  List<dynamic> upcomingTasks = [];
  List<dynamic> overdueTasks = [];

  void _onHorizontalDragUpdate(DragUpdateDetails details, String taskId) {
    setState(() {
      _swipeOffsets[taskId] =
          (_swipeOffsets[taskId] ?? 0) + (details.primaryDelta ?? 0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, dynamic item, int index) {
    String taskId = item['task_id'];
    double swipeOffset = _swipeOffsets[taskId] ?? 0;

    if (swipeOffset > 100) {
      // Right Swipe (Favorite)
      _toggleFavorite(taskId, index);
    } else if (swipeOffset < -100) {
      // Left Swipe (Call)
      _handleCall(item);
    }

    // Reset animation
    setState(() {
      _swipeOffsets[taskId] = 0.0;
    });
  }

  // Alternative simpler approach - replace your _toggleFavorite method:

  Future<void> _toggleFavorite(String taskId, int index) async {
    // Find the current favorite status by searching for the task
    bool currentStatus = false;

    // Search in upcoming tasks
    for (var task in upcomingTasks) {
      if (task['task_id'] == taskId) {
        currentStatus = task['favourite'] ?? false;
        break;
      }
    }

    // If not found in upcoming, search in overdue tasks
    if (!currentStatus) {
      for (var task in overdueTasks) {
        if (task['task_id'] == taskId) {
          currentStatus = task['favourite'] ?? false;
          break;
        }
      }
    }

    bool newFavoriteStatus = !currentStatus;

    final success = await LeadsSrv.favorite(taskId: taskId);

    if (success) {
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

      print('upcomingTasks length: ${upcomingTasks.length}');
      print('overdueTasks length: ${overdueTasks.length}');

      // Optionally refresh data from server
      await fetchTasksData();
    } else {
      print('Failed to toggle favorite for task: $taskId');
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
          'https://api.smartassistapp.in/api/app-admin/fav-followups/all?userId=$adminId',
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
          upcomingTasks = data['data']['allTasks']['rows'] ?? [];
          // overdueTasks = data['data']['overdueTasks']['rows'] ?? [];
          isLoading = false;
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
    if (isLoading) {
      return SkeletonCard();
    }

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
    // Check if both lists are empty and show "No data found"
    if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
      return const Center(child: Text('No data found'));
    }

    return ListView.builder(
      shrinkWrap: true,
      // physics: widget.isNested
      //     ? const NeverScrollableScrollPhysics()
      //     : const AlwaysScrollableScrollPhysics(),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var item = tasks[index];

        if (!(item.containsKey('name') &&
            item.containsKey('due_date') &&
            item.containsKey('lead_id') &&
            item.containsKey('task_id'))) {
          return ListTile(title: Text('Invalid data at index $index'));
        }

        String taskId = item['task_id'];
        double swipeOffset = _swipeOffsets[taskId] ?? 0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(details, taskId),
          onHorizontalDragEnd: (details) =>
              _onHorizontalDragEnd(details, item, index),
          child: TaskItem(
            key: ValueKey(item['task_id']),
            name: item['name'],
            date: item['due_date'],
            subject: item['subject'] ?? '',
            vehicle: 'Discovery Sport',
            leadId: item['lead_id'],
            taskId: taskId,
            isFavorite: item['favourite'] ?? false,
            swipeOffset: swipeOffset,
            isUpcoming: isUpcoming,
            mobile: item['mobile'],
            fetchDashboardData: () {},
            onFavoriteToggled: () {}, // Placeholder, replace with actual method
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
  final double swipeOffset;
  final VoidCallback fetchDashboardData;
  final VoidCallback onFavoriteToggled;

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
    required this.subject,
    required this.swipeOffset,
    required this.fetchDashboardData,
    required this.onToggleFavorite,
    required this.mobile,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _wasCallingPhone = false;
  late bool isFav;

  late SlidableController _slidableController;
  //  final GlobalKey<SlidableState> _slidableKey = GlobalKey<SlidableState>();

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
    bool isFavoriteSwipe = widget.swipeOffset > 50;
    bool isCallSwipe = widget.swipeOffset < -50;

    return Stack(
      children: [
        // Favorite Swipe Overlay
        // if (isFavoriteSwipe) Positioned.fill(child: _buildFavoriteOverlay()),

        // // Call Swipe Overlay
        // if (isCallSwipe) Positioned.fill(child: _buildCallOverlay()),

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
                  color: widget.isFavorite
                      ? Colors.yellow
                      : AppColors.sideGreen,
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

                        const SizedBox(height: 2),
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
        const Icon(Icons.phone_in_talk, color: AppColors.colorsBlue, size: 18),
        const SizedBox(width: 5),
        Text(widget.subject, style: AppFont.smallText(context)),
      ],
    );
  }

  Widget _date(BuildContext context) {
    String formattedDate = '';

    try {
      DateTime parseDate = DateTime.parse(widget.date);

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
      formattedDate = widget.date; // Fallback if date parsing fails
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
      margin: const EdgeInsets.only(bottom: 3, left: 10, right: 10),
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
          child: FollowupsEdit(onFormSubmit: () {}, taskId: widget.taskId),
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
    return CustomSlidableAction(
      padding: EdgeInsets.zero,
      onPressed: (context) => onPressed(),
      backgroundColor: backgroundColor,
      child: Icon(icon, size: iconSize, color: foregroundColor ?? Colors.white),
    );
  }
}
// class FUpcoming extends StatefulWidget {
//   final String leadId;
//   const FUpcoming({super.key, required this.leadId});

//   @override
//   State<FUpcoming> createState() => _FUpcomingState();
// }

// class _FUpcomingState extends State<FUpcoming> {
//   bool isLoading = true;
//   List<dynamic> upcomingTasks = [];
//   List<dynamic> overdueTasks = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchTasksData();
//   }

//   Future<void> fetchTasksData() async {
//     final token = await Storage.getToken();
//     try {
//       final response = await http.get(
//         Uri.parse(
//             'https://api.smartassistapp.in/api/favourites/follow-ups/all'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json'
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           upcomingTasks = data['data']['upcomingTasks']['rows'] ?? [];
//           overdueTasks = data['data']['overdueTasks']['rows'] ?? [];
//           isLoading = false;
//         });
//       } else {
//         print("Failed to load data: ${response.statusCode}");
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       print("Error fetching data: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildTasksList(upcomingTasks, isUpcoming: true),
//           _buildTasksList(overdueTasks, isUpcoming: false),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(
//     String title,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTasksList(List<dynamic> tasks, {required bool isUpcoming}) {
//     // Check if both lists are empty and show "No data found"
//     if (upcomingTasks.isEmpty && overdueTasks.isEmpty) {
//       return const Center(
//         child: Text('No data found'),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: tasks.length,
//       itemBuilder: (context, index) {
//         var task = tasks[index];
//         return TaskItem(
//           key: ValueKey(task['task_id']),
//           name: task['name'] ?? 'No Name',
//           date: task['due_date'] ?? 'No Date',
//           vehicle: task['vehicle'] ?? 'Discovery Sport',
//           leadId: task['lead_id'] ?? '',
//           taskId: task['task_id'] ?? '',
//           isFavorite: task['favourite'] ?? false,
//           isUpcoming: isUpcoming,
//           onFavoriteToggled: fetchTasksData,
//         );
//       },
//     );
//   }
// }

// class TaskItem extends StatefulWidget {
//   final String name;
//   final String date;
//   final String vehicle;
//   final String leadId;
//   final String taskId;
//   final bool isFavorite;
//   final bool isUpcoming;
//   final VoidCallback onFavoriteToggled;

//   const TaskItem({
//     super.key,
//     required this.name,
//     required this.date,
//     required this.vehicle,
//     required this.leadId,
//     required this.taskId,
//     required this.isFavorite,
//     required this.isUpcoming,
//     required this.onFavoriteToggled,
//   });

//   @override
//   State<TaskItem> createState() => _TaskItemState();
// }

// class _TaskItemState extends State<TaskItem> {
//   late bool isFav;

//   @override
//   void initState() {
//     super.initState();
//     isFav = widget.isFavorite;
//   }

//   Future<void> _toggleFavorite() async {
//     final token = await Storage.getToken();
//     try {
//       final response = await http.put(
//         Uri.parse(
//           'https://api.smartassistapp.in/api/favourites/mark-fav/task/${widget.taskId}',
//         ),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({'taskId': widget.taskId, 'favourite': !isFav}),
//       );

//       if (response.statusCode == 200) {
//         setState(() => isFav = !isFav);
//         widget.onFavoriteToggled();
//       }
//     } catch (e) {
//       print('Error updating favorite status: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: AppColors.containerBg,
//           borderRadius: BorderRadius.circular(10),
//           border: Border(
//             left: BorderSide(
//               width: 8.0,
//               color:
//                   widget.isUpcoming ? AppColors.sideGreen : AppColors.sideRed,
//             ),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             IconButton(
//               icon: Icon(
//                 isFav ? Icons.star_rounded : Icons.star_border_rounded,
//                 color: isFav
//                     ? AppColors.starColorsYellow
//                     : AppColors.starBorderColor,
//                 size: 40,
//               ),
//               onPressed: _toggleFavorite,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildUserDetails(),
//                 const SizedBox(
//                     height: 4), // Spacing between user details and date-car
//                 Row(
//                   children: [
//                     _date(),
//                     _buildVerticalDivider(20),
//                     _buildCarModel(),
//                   ],
//                 ),
//               ],
//             ),
//             _buildNavigationButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUserDetails() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(widget.name,
//             style: GoogleFonts.poppins(
//                 color: AppColors.fontColor,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14)),
//         const SizedBox(height: 5),
//       ],
//     );
//   }

//   Widget _date() {
//     String formattedDate = '';
//     try {
//       DateTime parseDate = DateTime.parse(widget.date);
//       formattedDate = DateFormat('dd/MM/yyyy').format(parseDate);
//     } catch (e) {
//       formattedDate = widget.date;
//     }
//     return Row(
//       children: [
//         const Icon(Icons.phone_in_talk, color: AppColors.colorsBlue, size: 14),
//         const SizedBox(width: 5),
//         Text(formattedDate,
//             style: const TextStyle(fontSize: 12, color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildVerticalDivider(double height) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 10),
//       height: height,
//       width: 1,
//       decoration: const BoxDecoration(
//           border: Border(right: BorderSide(color: AppColors.fontColor))),
//     );
//   }

//   Widget _buildCarModel() {
//     return Text(
//       widget.vehicle,
//       textAlign: TextAlign.start,
//       style: GoogleFonts.poppins(fontSize: 10, color: AppColors.fontColor),
//       softWrap: true,
//       overflow: TextOverflow.visible,
//     );
//   }

//   Widget _buildNavigationButton() {
//     return GestureDetector(
//       onTap: () {
//         if (widget.leadId.isNotEmpty) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => FollowupsDetails(leadId: widget.leadId)),
//           );
//         } else {
//           print("Invalid leadId");
//         }
//       },
//       child: Container(
//         padding: const EdgeInsets.all(3),
//         decoration: BoxDecoration(
//             color: AppColors.arrowContainerColor,
//             borderRadius: BorderRadius.circular(30)),
//         child: const Icon(Icons.arrow_forward_ios_rounded,
//             size: 25, color: Colors.white),
//       ),
//     );
//   }
// }
