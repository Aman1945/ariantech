import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/widgets/testdrive_verifyotp.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/followups.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/appointments.dart';

// Global variables to persist across widget rebuilds
bool _globalWasCallingPhone = false;
String? _globalCurrentTaskId;

class AdminUpcomingtimeline extends StatefulWidget {
  // final bool isfrom
  final bool isFromTeams;
  final carIcon = '/assets/caricon.png';
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> upcomingEvents;

  const AdminUpcomingtimeline({
    super.key,
    required this.tasks,
    required this.upcomingEvents,
    required this.isFromTeams,
  });

  @override
  State<AdminUpcomingtimeline> createState() => _AdminUpcomingtimelineState();
}

class _AdminUpcomingtimelineState extends State<AdminUpcomingtimeline>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final Set<int> expandedTaskIndexes = {};
  final Set<int> expandedEventIndexes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("🔧 initState called - adding observer");

    // Check if we need to show dialog immediately (for when widget is recreated)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("📱 Post frame callback - checking for pending dialog");
      print("📞 _globalWasCallingPhone: $_globalWasCallingPhone");
      print("📋 _globalCurrentTaskId: $_globalCurrentTaskId");

      if (_globalWasCallingPhone && _globalCurrentTaskId != null) {
        print("🔄 Widget recreated after call - showing dialog immediately");
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showFollowupsDialog();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print("🗑️ dispose called - removing observer");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔄 App lifecycle state changed to: $state");
    print("📞 _globalWasCallingPhone: $_globalWasCallingPhone");
    print("📋 _globalCurrentTaskId: $_globalCurrentTaskId");

    if (state == AppLifecycleState.resumed && _globalWasCallingPhone) {
      print("✅ Conditions met - showing dialog after phone call");
      _globalWasCallingPhone = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        print("⏰ Delay completed, checking if mounted: $mounted");
        if (mounted && _globalCurrentTaskId != null) {
          print("🎯 About to show dialog");
          _showFollowupsDialog();
        } else {
          print(
            "❌ Not showing dialog - mounted: $mounted, taskId: $_globalCurrentTaskId",
          );
        }
      });
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
      return DateFormat("d MMM").format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  // Updated handleCall function
  void _handleCall(String mobile, {String? taskId}) {
    print("📞 Call action triggered for $mobile");
    print("📋 TaskId provided: $taskId");

    if (mobile.isNotEmpty) {
      try {
        // Store the task ID globally for persistence across widget rebuilds
        _globalCurrentTaskId = taskId;
        print("💾 Stored taskId globally: $_globalCurrentTaskId");

        // Set flag globally that we're making a phone call
        _globalWasCallingPhone = true;
        print("🚩 Set _globalWasCallingPhone to: $_globalWasCallingPhone");

        // Launch phone dialer - using the same approach as FollowupsUpcoming
        launchUrl(Uri.parse('tel:$mobile'));

        print('📱 Phone dialer launched');
      } catch (e) {
        print('❌ Error launching phone app: $e');

        // Reset flag if there was an error
        _globalWasCallingPhone = false;
        _globalCurrentTaskId = null;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } else {
      print("❌ No mobile number provided");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
    }
  }

  IconData _getIconFromSubject(String subject) {
    switch (subject.trim().toLowerCase()) {
      case 'provide quotation':
        return Icons.receipt_long;
      case 'send sms':
        return Icons.message_rounded;
      case 'call':
        return Icons.phone;
      case 'send email':
        return Icons.mail;
      case 'showroom appointment':
        return Icons.person_2_outlined;
      case 'trade in evaluation':
        return Icons.handshake;
      case 'test drive':
        return Icons.directions_car;
      case 'quotation':
        return FontAwesomeIcons.solidCalendar;
      case 'meeting':
        return Icons.groups;
      case 'vehicle selection':
        return Icons.directions_car_filled;
      default:
        return Icons.info_outline;
    }
  }

  void _handleIconPress(
    String subject,
    String mobile,
    String eventId,
    String gmail,
    String leadId,
    BuildContext context, {
    String? taskId,
  }) {
    if (widget.isFromTeams) return;
    final lower = subject.trim().toLowerCase();
    if (lower == 'call') {
      // _handleCall(mobile, taskId: taskId);
    } else if (lower == 'send sms') {
      // launchUrl(Uri.parse('sms:$mobile'));
    } else if (lower == 'test drive') {
      // _showAleart(eventId, gmail, leadId, mobile, context);
    }
  }

  void _handleFollowupsEdit(String taskId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: FollowupsEdit(
          taskId: taskId,
          onFormSubmit: () {
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  void handleAppointmentsEdit(String taskId) {
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
          child: AppointmentsEdit(
            onFormSubmit: () {
              Navigator.pop(context);
              setState(() {
                print('this is the taskid $taskId');
              });
            },
            taskId: taskId,
          ),
        );
      },
    );
  }

  void _handleTestDriveEdit(String eventId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Testdrive(
          eventId: eventId,
          onFormSubmit: () {
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _showAleart(
    String eventId,
    String gmail,
    String leadId,
    String mobile,
    BuildContext context,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Ready to start test drive?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Please make sure you have all the necessary documents(license) and permissions(OTP) ready before starting test drive.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _getOtp(eventId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestdriveVerifyotp(
                      email: gmail,
                      eventId: eventId,
                      leadId: leadId,
                      mobile: mobile,
                    ),
                  ),
                );
              },
              child: Text(
                'Yes',
                style: GoogleFonts.poppins(color: AppColors.colorsBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getOtp(String eventId) async {
    final success = await LeadsSrv.getOtp(eventId: eventId);
    print(
      success
          ? '✅ Test drive started successfully'
          : '❌ Failed to start test drive',
    );
  }

  bool _shouldShowSeeMore(String text) => text.length > 100;

  // Method to show FollowupsEdit dialog
  void _showFollowupsDialog() {
    print("🎪 _showFollowupsDialog called");
    print("📋 _globalCurrentTaskId: $_globalCurrentTaskId");
    print("🏠 context.mounted: ${context.mounted}");

    if (_globalCurrentTaskId != null && context.mounted) {
      print("✅ Showing FollowupsEdit dialog");
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
            child: FollowupsEdit(
              onFormSubmit: () {
                print("📝 Dialog form submitted");
                Navigator.pop(context);
                setState(() {
                  _globalCurrentTaskId = null; // Reset after dialog closes
                });
              },
              taskId: _globalCurrentTaskId!,
            ),
          );
        },
      );
    } else {
      print(
        "❌ Cannot show dialog - taskId: $_globalCurrentTaskId, mounted: ${context.mounted}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reversedTasks = widget.tasks.reversed.toList();
    final reversedUpcomingEvents = widget.upcomingEvents.reversed.toList();

    if (reversedTasks.isEmpty && reversedUpcomingEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No upcoming task available",
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    return Column(
      children: [
        // TASKS
        ...List.generate(reversedTasks.length, (index) {
          final task = reversedTasks[index];
          final remarks = task['remarks'] ?? '';
          final mobile = task['mobile'] ?? '';
          final dueDate = _formatDate(task['due_date'] ?? 'N/A');
          final subject = (task['subject'] ?? 'No Subject').toString();
          final taskId = task['task_id'];

          final isExpanded = expandedTaskIndexes.contains(index);
          final showSeeMore = _shouldShowSeeMore(remarks);
          final iconData = _getIconFromSubject(subject);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _handleIconPress(
                      subject,
                      mobile,
                      '',
                      '',
                      '',
                      context,
                      taskId: taskId,
                    ),
                    child: Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.colorsBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconData, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dueDate,
                    style: AppFont.dropDowmLabel(context)?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colorsBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: AppFont.dropDowmLabel(context)?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppColors.colorsBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // if (!widget.isFromTeams)
                        //   IconButton(
                        //     icon: Icon(
                        //       Icons.edit,
                        //       size: 18,
                        //       color: Colors.black,
                        //     ),
                        //     onPressed: () {
                        //       final lower = subject.trim().toLowerCase();

                        //       // These subjects open FollowupsEdit

                        //       // if (lower == 'provide quotation' ||
                        //       //     lower == 'send sms' ||
                        //       //     lower == 'call' ||
                        //       //     lower == 'send email' ||
                        //       //     lower == 'showroom appointment' ||
                        //       //     lower == 'trade in evaluation') {
                        //       //   _handleFollowupsEdit(taskId);
                        //       // }
                        //       // // These subjects open AppointmentsEdit
                        //       // else if (lower == 'quotation' ||
                        //       //     lower == 'meeting' ||
                        //       //     lower == 'vehicle selection') {
                        //       //   handleAppointmentsEdit(taskId);
                        //       // }
                        //       // // Otherwise, fallback to followup (optional)
                        //       // else {
                        //       //   _handleFollowupsEdit(taskId);
                        //       // }
                        //     },
                        //     tooltip: 'Edit Remarks',
                        //     splashRadius: 18,
                        //     padding: EdgeInsets.zero,
                        //     constraints: BoxConstraints(),
                        //   ),
                        
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.colorsBlueBar.withOpacity(.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(top: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remarks:',
                      style: AppFont.dropDowmLabel(
                        context,
                      )?.copyWith(color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remarks.isNotEmpty ? remarks : 'No remarks',
                      style: AppFont.smallText12(context)?.copyWith(
                        color: remarks.isNotEmpty
                            ? Colors.black
                            : Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: (!showSeeMore || isExpanded) ? null : 2,
                      overflow: (!showSeeMore || isExpanded)
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (showSeeMore)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded
                                ? expandedTaskIndexes.remove(index)
                                : expandedTaskIndexes.add(index);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            isExpanded ? 'See less' : 'See more',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),

        // EVENTS
        ...List.generate(reversedUpcomingEvents.length, (index) {
          final event = reversedUpcomingEvents[index];
          final eventId = event['event_id'] ?? '';
          final leadId = event['lead_id'] ?? '';
          final gmail = event['lead_email'] ?? '';
          final remarks = event['remarks'] ?? '';
          final mobile = event['mobile'] ?? '';
          final eventDate = _formatDate(event['start_date'] ?? 'N/A');
          final eventSubject = (event['subject'] ?? 'No Subject').toString();

          final isExpanded = expandedEventIndexes.contains(index);
          final showSeeMore = _shouldShowSeeMore(remarks);
          final iconData = _getIconFromSubject(eventSubject);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _handleIconPress(
                          eventSubject,
                          mobile,
                          eventId,
                          gmail,
                          leadId,
                          context,
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      eventDate,
                      style: AppFont.dropDowmLabel(context)?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colorsBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              eventSubject,
                              style: AppFont.dropDowmLabel(context)?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.colorsBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // if (!widget.isFromTeams)
                          //   if (eventSubject.trim().toLowerCase() ==
                          //       'test drive')
                          //     IconButton(
                          //       icon: Icon(
                          //         Icons.edit,
                          //         size: 18,
                          //         color: Colors.black,
                          //       ),
                          //       onPressed: () => {},
                          //       //  _handleTestDriveEdit(eventId),
                          //       tooltip: 'Edit Test Drive',
                          //       splashRadius: 18,
                          //       padding: EdgeInsets.zero,
                          //       constraints: BoxConstraints(),
                          //     ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.colorsBlueBar.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remarks:',
                        style: AppFont.dropDowmLabel(
                          context,
                        )?.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remarks.isNotEmpty ? remarks : 'No remarks',
                        style: AppFont.smallText12(context)?.copyWith(
                          color: remarks.isNotEmpty
                              ? Colors.black
                              : Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: (!showSeeMore || isExpanded) ? null : 2,
                        overflow: (!showSeeMore || isExpanded)
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (showSeeMore)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isExpanded
                                  ? expandedEventIndexes.remove(index)
                                  : expandedEventIndexes.add(index);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              isExpanded ? 'See less' : 'See more',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),
      ],
    );
  }
}
