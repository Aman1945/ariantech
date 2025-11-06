import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/followups.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/appointments.dart';

class AdminOverduetimeline extends StatefulWidget {
  final bool isFromTeams;
  final carIcon = '/assets/caricon.png';
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> overdueEvents;
  const AdminOverduetimeline({
    super.key,
    required this.tasks,
    required this.overdueEvents,
    required this.isFromTeams,
  });

  @override
  State<AdminOverduetimeline> createState() => _AdminOverduetimelineState();
}

class _AdminOverduetimelineState extends State<AdminOverduetimeline> {
  final Set<int> expandedTaskIndexes = {};
  final Set<int> expandedEventIndexes = {};

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
      return DateFormat("d MMM").format(parsedDate);
    } catch (e) {
      return 'N/A';
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

  void _handleEdit(String subject, String id) {
    final lower = subject.trim().toLowerCase();
    if (lower == 'provide quotation' ||
        lower == 'send sms' ||
        lower == 'call' ||
        lower == 'send email' ||
        lower == 'showroom appointment' ||
        lower == 'trade in evaluation') {
      _showFollowupsEdit(id);
    } else if (lower == 'quotation' ||
        lower == 'meeting' ||
        lower == 'vehicle selection') {
      _showAppointmentsEdit(id);
    } else if (lower == 'test drive') {
      _showTestDriveEdit(id);
    } else {
      _showFollowupsEdit(id);
    }
  }

  void _showFollowupsEdit(String taskId) {
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

  void _showAppointmentsEdit(String taskId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: AppointmentsEdit(
          onFormSubmit: () {
            Navigator.pop(context);
            setState(() {});
          },
          taskId: taskId,
        ),
      ),
    );
  }

  void _showTestDriveEdit(String eventId) {
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

  bool _shouldShowSeeMore(String remarks) => remarks.length > 60;

  @override
  Widget build(BuildContext context) {
    final reversedTasks = widget.tasks.reversed.toList();
    final reversedUpcomingEvents = widget.overdueEvents.reversed.toList();

    if (reversedTasks.isEmpty && reversedUpcomingEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No overdue task available",
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    const double minBoxHeight = 68.0;

    return Column(
      children: [
        // TASKS
        ...List.generate(reversedTasks.length, (index) {
          final task = reversedTasks[index];
          String remarks = task['remarks'] ?? '';
          String dueDate = _formatDate(task['due_date'] ?? 'N/A');
          String subject = task['subject'] ?? 'No Subject';
          String taskId = task['task_id'] ?? '';

          bool isExpanded = expandedTaskIndexes.contains(index);
          bool showSeeMore = _shouldShowSeeMore(remarks);
          IconData icon = _getIconFromSubject(subject);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.sideRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dueDate,
                    style: AppFont.dropDowmLabel(context)?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sideRed,
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
                              color: AppColors.sideRed,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // IconButton(
                        //   icon: Icon(
                        //     Icons.edit,
                        //     size: 18,
                        //     color: Colors.black,
                        //   ), // Red pencil
                        //   onPressed: () => _handleEdit(subject, taskId),
                        //   tooltip: 'Edit',
                        //   splashRadius: 18,
                        //   padding: EdgeInsets.zero,
                        //   constraints: BoxConstraints(),
                        // ),
                        // if (!widget.isFromTeams)
                        //   IconButton(
                        //     icon: const Icon(
                        //       Icons.edit,
                        //       size: 18,
                        //       color: Colors.black,
                        //     ),
                        //     onPressed: () => {},
                        //     // _handleEdit(subject, taskId),
                        //     tooltip: 'Edit',
                        //     splashRadius: 18,
                        //     padding: EdgeInsets.zero,
                        //     constraints: const BoxConstraints(),
                        //   ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // REMARKS CARD
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: minBoxHeight),
                decoration: BoxDecoration(
                  color: const Color(0xffE7F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(top: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remarks:', style: AppFont.dropDowmLabel(context)),
                    const SizedBox(height: 4),
                    if (remarks.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remarks,
                            maxLines: (!showSeeMore || isExpanded) ? null : 2,
                            overflow: (!showSeeMore || isExpanded)
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                          if (showSeeMore) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    expandedTaskIndexes.remove(index);
                                  } else {
                                    expandedTaskIndexes.add(index);
                                  }
                                });
                              },
                              child: Text(
                                isExpanded ? 'See less' : 'See more',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'No remarks',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
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
          String eventId = event['event_id'] ?? '';
          String leadId = event['lead_id'] ?? '';
          String gmail = event['lead_email'] ?? '';
          String remarks = event['remarks'] ?? '';
          String mobile = event['mobile'] ?? '';
          String eventDate = _formatDate(event['start_date'] ?? 'N/A');
          String eventSubject = event['subject'] ?? 'No Subject';

          bool isExpanded = expandedEventIndexes.contains(index);
          bool showSeeMore = _shouldShowSeeMore(remarks);
          IconData icon = _getIconFromSubject(eventSubject);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.sideRed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      eventDate,
                      style: AppFont.dropDowmLabel(context)?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sideRed,
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
                                color: AppColors.sideRed,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // IconButton(
                          //   icon: Icon(
                          //     Icons.edit,
                          //     size: 18,
                          //     color: const Color.fromARGB(255, 0, 0, 0),
                          //   ), // Red pencil
                          //   onPressed: () => _handleEdit(eventSubject, eventId),
                          //   tooltip: 'Edit',
                          //   splashRadius: 18,
                          //   padding: EdgeInsets.zero,
                          //   constraints: BoxConstraints(),
                          // ),
                          // if (!widget.isFromTeams)
                          //   IconButton(
                          //     icon: const Icon(
                          //       Icons.edit,
                          //       size: 18,
                          //       color: Colors.black,
                          //     ),
                          //     onPressed: () => {},
                          //     // _handleEdit(eventSubject, eventId),
                          //     tooltip: 'Edit',
                          //     splashRadius: 18,
                          //     padding: EdgeInsets.zero,
                          //     constraints: const BoxConstraints(),
                          //   ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // REMARKS CARD
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: minBoxHeight),
                  decoration: BoxDecoration(
                    color: const Color(0xffE7F2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remarks:', style: AppFont.dropDowmLabel(context)),
                      const SizedBox(height: 4),
                      if (remarks.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              remarks,
                              maxLines: (!showSeeMore || isExpanded) ? null : 2,
                              overflow: (!showSeeMore || isExpanded)
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: AppFont.smallText12(
                                context,
                              )?.copyWith(color: Colors.black),
                            ),
                            if (showSeeMore) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      expandedEventIndexes.remove(index);
                                    } else {
                                      expandedEventIndexes.add(index);
                                    }
                                  });
                                },
                                child: Text(
                                  isExpanded ? 'See less' : 'See more',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'No remarks',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
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
