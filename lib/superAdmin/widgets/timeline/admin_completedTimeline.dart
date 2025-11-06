import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/superAdmin/widgets/admin_testdrive_summary.dart';
import 'package:smartassist/widgets/testdrive_summary.dart';
import 'package:intl/intl.dart';

class AdminCompletedtimeline extends StatefulWidget {
  final carIcon = '/assets/caricon.png';
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> completedEvents;

  const AdminCompletedtimeline({
    super.key,
    required this.events,
    required this.completedEvents,
  });

  @override
  State<AdminCompletedtimeline> createState() => _AdminCompletedtimelineState();
}

class _AdminCompletedtimelineState extends State<AdminCompletedtimeline> {
  final Set<int> expandedTaskIndexes = {};
  final Set<int> expandedEventIndexes = {};

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
      return DateFormat("d MMM").format(parsedDate); // Outputs "22 May"
    } catch (e) {
      print('Error formatting date: $e');
      return 'N/A';
    }
  }

  Future<void> _getOtp(String eventId) async {
    final success = await LeadsSrv.getOtp(eventId: eventId);

    if (success) {
      print('✅ Test drive started successfully');
    } else {
      print('❌ Failed to start test drive');
    }
  }

  String _formatTo12HourFormat(String time24) {
    try {
      // Parse the 24-hour time string to DateTime
      DateFormat inputFormat = DateFormat("HH:mm"); // 24-hour format
      DateTime dateTime = inputFormat.parse(time24);

      // Convert it to 12-hour format with AM/PM
      DateFormat outputFormat = DateFormat(
        "hh:mm a",
      ); // 12-hour format with AM/PM
      return outputFormat.format(dateTime);
    } catch (e) {
      return "Invalid time"; // Handle error if time format is incorrect
    }
  }

  bool _shouldShowSeeMore(String remarks) {
    return remarks.length > 60;
  }

  // Function to get icon based on subject
  IconData _getIconForSubject(String subject) {
    if (subject == 'Provide Quotation') {
      return Icons.receipt_long;
    } else if (subject == 'Send SMS') {
      return Icons.message_rounded;
    } else if (subject == 'Call') {
      return Icons.phone;
    } else if (subject == 'Send Email') {
      return Icons.mail;
    } else if (subject == 'Showroom appointment') {
      return Icons.person_2_outlined;
    } else if (subject == 'Trade in evaluation') {
      return Icons.handshake;
    } else if (subject == 'Test Drive') {
      return Icons.directions_car;
    } else if (subject == 'Quotation') {
      return FontAwesomeIcons.solidCalendar;
    } else {
      return Icons.phone; // default fallback icon
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reverse the events and completedEvents list to show from bottom to top
    final reversedEvents = widget.events.reversed.toList();
    final reversedCompletedEvents = widget.completedEvents.reversed.toList();

    if (reversedEvents.isEmpty && reversedCompletedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'No completed task available',
            style: AppFont.smallText12(context),
          ),
        ),
      );
    }

    const double minBoxHeight = 90.0;

    return Column(
      children: [
        ...List.generate(reversedEvents.length, (index) {
          final task = reversedEvents[index];
          String dueDate = _formatDate(task['due_date'] ?? 'N/A');
          String mobile = task['mobile'] ?? 'N/A';
          String subject = task['subject'] ?? 'N/A';
          String time = _formatDate(task['completed_at'] ?? 'No Time');
          String eventId = task['event_id'] ?? 'No Time';
          String taskId = task['task_id'] ?? 'empty';
          String comment = task['remarks'] ?? 'No Remarks';
          String leadId = task['lead_id'] ?? 'No Time';
          bool isExpanded = expandedTaskIndexes.contains(index);
          bool showSeeMore = _shouldShowSeeMore(comment);
          IconData icon = _getIconForSubject(subject);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () {
                if (subject == 'Test Drive') {
                  // Navigate only if subject is "Test Drive"
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminTestdriveSummary(
                        eventId: eventId,
                        leadId: '',
                        isFromCompletedEventId: eventId,
                        isFromTestdrive: true,
                        isFromCompletdTimeline: true,
                        isFromCompletedLeadId: leadId,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Action Row with Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon in circular container
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.sideGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      // Date Badge - Changed to Green
                      Text(
                        dueDate,
                        style: AppFont.dropDowmLabel(context)?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green, // Changed to green
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Text - Changed to Green
                      Expanded(
                        child: Text(
                          subject,
                          style: AppFont.dropDowmLabel(context)?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.green, // Changed to green
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Card with Remarks and Completed At
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
                        // Remarks
                        Text(
                          'Remarks:',
                          style: AppFont.dropDowmLabel(
                            context,
                          )?.copyWith(color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        if (comment.isNotEmpty && comment != 'No Remarks') ...[
                          Text(
                            comment,
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
                                  color: const Color(0xFF3497F9),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'No remarks available',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Completed At
                        Text(
                          'Completed at:',
                          style: AppFont.dropDowmLabel(
                            context,
                          )?.copyWith(color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: AppFont.smallText12(
                            context,
                          )?.copyWith(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // EVENTS (completedEvents list)
        ...List.generate(reversedCompletedEvents.length, (index) {
          final task = reversedCompletedEvents[index];
          String remarks = task['remarks'] ?? '';
          String startDate = _formatDate(task['start_date'] ?? 'No date');
          String completeAt = task['completed_at'] != null
              ? _formatDate(task['completed_at'])
              : 'No complete date';
          String leadId = task['lead_id'] ?? 'No Time';
          String startTime = task['start_time'] ?? 'No Start time';
          String endTime = task['end_time'] ?? 'No end time';
          String duration = task['duration'] ?? 'No duration';
          String startActualTime = task['actual_start_time'] ?? 'No Start time';
          String endActualTime = task['actual_end_time'] ?? 'No end time';
          // String distance = task['distance'] ?? 'No distance';
          String rawDistance = task['distance']?.toString() ?? 'No distance';
          String rating = task['avg_rating'] ?? 'No rating';
          String mobile = task['mobile'] ?? 'N/A';
          String date = _formatDate(task['start_date'] ?? 'No Date');
          String taskSubject = task['subject'] ?? 'No Subject';
          String eventId = task['event_id'] ?? 'No Time';

          bool isExpanded = expandedEventIndexes.contains(index);
          bool showSeeMore = _shouldShowSeeMore(remarks);
          IconData icon = _getIconForSubject(taskSubject);

          // Calculate the formatted string
          double parseDistance(String raw) {
            return double.tryParse(raw) ?? 0.0;
          }

          String formatDistance(double distance) {
            if (distance < 1.0) {
              return '${(distance * 1000).toStringAsFixed(0)} m';
            } else {
              return '${distance.toStringAsFixed(2)} km';
            }
          }

          // Now use them
          // String rawDistance = task['distance']?.toString() ?? 'No distance';
          String distanceFormatted = 'No distance';
          if (rawDistance != 'No distance') {
            double calculatedDistance = parseDistance(rawDistance);
            distanceFormatted = formatDistance(calculatedDistance);
          }

          // double parseDistance(String raw) {
          //   return double.tryParse(raw) ?? 0.0;
          // }

          // String formatDistance(double distance) {
          //   if (distance < 1.0) {
          //     return '${(distance * 1000).toStringAsFixed(0)} m';
          //   } else {
          //     return '${distance.toStringAsFixed(2)} km';
          //   }
          // }

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () {
                if (taskSubject == 'Test Drive') {
                  // Navigate only if subject is "Test Drive"
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminTestdriveSummary(
                        isFromCompletedEventId: eventId,
                        eventId: eventId,
                        leadId: '',
                        isFromTestdrive: true,
                        isFromCompletdTimeline: true,
                        isFromCompletedLeadId: leadId,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Action Row with Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon in circular container
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.sideGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      // Date Badge - Changed to Green
                      Text(
                        date,
                        style: AppFont.dropDowmLabel(context)?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green, // Changed to green
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Text - Changed to Green
                      Expanded(
                        child: Text(
                          taskSubject,
                          style: AppFont.dropDowmLabel(context)?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.green, // Changed to green
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Card with all event details
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
                        // Remarks
                        Text(
                          'Remarks:',
                          style: AppFont.dropDowmLabel(
                            context,
                          )?.copyWith(color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        if (remarks.isNotEmpty) ...[
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
                                  color: const Color(0xFF3497F9),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            'No remarks available',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Completed At
                        Text(
                          'Completed at:',
                          style: AppFont.dropDowmLabel(
                            context,
                          )?.copyWith(color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          completeAt,
                          style: AppFont.smallText12(
                            context,
                          )?.copyWith(color: Colors.black),
                        ),

                        // Additional event details (for events only)
                        if (startTime != 'No Start time') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Start Time: $startTime',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],
                        if (endTime != 'No end time') ...[
                          const SizedBox(height: 4),
                          Text(
                            'End Time: $endTime',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],
                        if (duration != 'No duration') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Duration: $duration',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],
                        if (distanceFormatted != 'No distance') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Distance: $distanceFormatted',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],
                        if (rating != 'No rating') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Average rating: $rating',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],

                        if (startActualTime != 'No Time') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Actual Start Time: $startActualTime',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],
                        if (endActualTime != 'No Time') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Actual End Time: $endActualTime',
                            style: AppFont.smallText12(
                              context,
                            )?.copyWith(color: Colors.black),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }
}
