// // import 'package:flutter/material.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // import 'package:intl/intl.dart';
// // import 'package:smartassist/config/component/color/colors.dart';
// // import 'package:smartassist/config/component/font/font.dart';
// // import 'package:smartassist/services/api_srv.dart';
// // import 'package:smartassist/widgets/testdrive_verifyotp.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:timeline_tile/timeline_tile.dart';
// // import 'package:google_fonts/google_fonts.dart';

// // class timelineOverdue extends StatelessWidget {
// //   final carIcon = '/assets/caricon.png';
// //   final List<Map<String, dynamic>> tasks;
// //   final List<Map<String, dynamic>> overdueEvents;
// //   const timelineOverdue({
// //     super.key,
// //     required this.tasks,
// //     required this.overdueEvents,
// //   });

// //   String _formatDate(String date) {
// //     try {
// //       final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
// //       return DateFormat("d MMM").format(parsedDate); // Outputs "22 May"
// //     } catch (e) {
// //       print('Error formatting date: $e');
// //       return 'N/A';
// //     }
// //   }

// //   Future<void> _showAleart(
// //     String eventId,
// //     String gmail,
// //     String leadId,
// //     String mobile,
// //     BuildContext context,
// //   ) async {
// //     return showDialog<void>(
// //       context: context,
// //       barrierDismissible: false, // User must tap button to close dialog
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(10),
// //           ),
// //           title: Text(
// //             'Ready to start test drive?',
// //             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
// //           ),
// //           content: Text(
// //             'Please make sure you have all the necessary documents(license) and permissions(OTP) ready before starting test drive.',
// //             style: GoogleFonts.poppins(),
// //           ),
// //           actions: [
// //             TextButton(
// //               style: TextButton.styleFrom(
// //                 overlayColor: Colors.grey.withOpacity(0.1),
// //                 foregroundColor: Colors.grey,
// //               ),
// //               onPressed: () => Navigator.of(context).pop(false),
// //               child: Text('No', style: GoogleFonts.poppins(color: Colors.grey)),
// //             ),
// //             TextButton(
// //               style: TextButton.styleFrom(
// //                 overlayColor: AppColors.colorsBlue.withOpacity(0.1),
// //                 foregroundColor: AppColors.colorsBlue,
// //               ),
// //               onPressed: () {
// //                 _getOtp(eventId);
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (context) => TestdriveVerifyotp(
// //                       email: gmail,
// //                       eventId: eventId,
// //                       leadId: leadId,
// //                       mobile: mobile,
// //                     ),
// //                   ),
// //                 );
// //               },
// //               child: Text(
// //                 'Yes',
// //                 style: GoogleFonts.poppins(color: AppColors.colorsBlue),
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   Future<void> _getOtp(String eventId) async {
// //     final success = await LeadsSrv.getOtp(eventId: eventId);

// //     if (success) {
// //       print('✅ Test drive started successfully');
// //     } else {
// //       print('❌ Failed to start test drive');
// //     }

// //     // if (mounted) setState(() {});
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Reverse the tasks list to show from bottom to top
// //     final reversedTasks = tasks.reversed.toList();

// //     // Reverse the upcomingEvents list to show from bottom to top
// //     final reversedUpcomingEvents = overdueEvents.reversed.toList();

// //     if (reversedTasks.isEmpty && reversedUpcomingEvents.isEmpty) {
// //       return Center(
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(vertical: 20),
// //           child: Text(
// //             "No overdue task available",
// //             style: AppFont.smallText12(context),
// //           ),
// //         ),
// //       );
// //     }

// //     return Column(
// //       children: [
// //         // Loop through tasks and display them
// //         ...List.generate(reversedTasks.length, (index) {
// //           final task = reversedTasks[index];
// //           String remarks = task['remarks'] ?? 'No Remarks';
// //           String dueDate = _formatDate(task['due_date'] ?? 'N/A');
// //           String subject = task['subject'] ?? 'No Subject';

// //           IconData icon;

// //           if (subject == 'Provide Quotation') {
// //             icon = Icons.receipt_long;
// //           } else if (subject == 'Send SMS') {
// //             icon = Icons.message_rounded;
// //           } else if (subject == 'Call') {
// //             icon = Icons.phone;
// //           } else if (subject == 'Send Email') {
// //             icon = Icons.mail;
// //           } else if (subject == 'Showroom appointment') {
// //             icon = Icons.person_2_outlined;
// //           } else if (subject == 'Trade in evaluation') {
// //             icon = Icons.handshake;
// //           } else if (subject == 'Test Drive') {
// //             icon = carIcon as IconData;
// //           } else {
// //             icon = Icons.phone; // default fallback icon
// //           }

// //           return TimelineTile(
// //             alignment: TimelineAlign.manual,
// //             lineXY: 0.25,
// //             isFirst: index == (reversedTasks.length - 1),
// //             isLast: index == 0,
// //             beforeLineStyle: const LineStyle(color: Colors.transparent),
// //             afterLineStyle: const LineStyle(color: Colors.transparent),
// //             indicatorStyle: IndicatorStyle(
// //               padding: const EdgeInsets.only(left: 5),
// //               width: 30,
// //               height: 30,
// //               color: AppColors.sideRed,
// //               iconStyle: IconStyle(iconData: icon, color: Colors.white),
// //             ),
// //             startChild: Text(
// //               dueDate, // Show the due date
// //               style: AppFont.dropDowmLabel(context),
// //             ),
// //             endChild: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 10.0),
// //               child: Column(
// //                 children: [
// //                   const SizedBox(height: 10),
// //                   Container(
// //                     width: double.infinity,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xffE7F2FF),
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     padding: const EdgeInsets.fromLTRB(10.0, 10, 0, 10),
// //                     child: RichText(
// //                       text: TextSpan(
// //                         children: [
// //                           TextSpan(
// //                             text: 'Action : ',
// //                             style: AppFont.dropDowmLabel(context),
// //                           ),
// //                           TextSpan(
// //                             text: '$subject\n',
// //                             style: AppFont.smallText12(context),
// //                           ),
// //                           TextSpan(
// //                             text: 'Remarks : ',
// //                             style: AppFont.dropDowmLabel(context),
// //                           ),
// //                           TextSpan(
// //                             text: remarks,
// //                             style: AppFont.smallText12(context),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         }),

// //         // Loop through upcomingEvents and display them
// //         ...List.generate(reversedUpcomingEvents.length, (index) {
// //           final event = reversedUpcomingEvents[index];
// //           String eventId = event['event_id'] ?? 'No ID';
// //           String leadId = event['lead_id'] ?? 'No ID';
// //           String gmail = event['lead_email'] ?? 'No email ID';
// //           String remarks = event['remarks'] ?? 'No Remarks';
// //           String mobile = event['mobile'] ?? 'No Number';
// //           String eventDate = _formatDate(event['start_date'] ?? 'N/A');
// //           String eventSubject = event['subject'] ?? 'No Subject';

// //           IconData icon;

// //           if (eventSubject == 'Test Drive') {
// //             icon = Icons.directions_car;
// //           } else if (eventSubject == 'Showroom appointment') {
// //             icon = FontAwesomeIcons.solidCalendar;
// //           } else if (eventSubject == 'Quotation') {
// //             icon = FontAwesomeIcons.solidCalendar;
// //           } else if (eventSubject == 'Showroom appointment') {
// //             icon = FontAwesomeIcons.solidCalendar;
// //           } else {
// //             icon = Icons.phone;
// //           }

// //           return TimelineTile(
// //             alignment: TimelineAlign.manual,
// //             lineXY: 0.25,
// //             isFirst: index == (reversedUpcomingEvents.length - 1),
// //             isLast: index == 0,
// //             beforeLineStyle: const LineStyle(color: Colors.transparent),
// //             afterLineStyle: const LineStyle(color: Colors.transparent),
// //             // indicatorStyle: IndicatorStyle(
// //             //   padding: const EdgeInsets.only(left: 5),
// //             //   width: 30,
// //             //   height: 30,
// //             //   color: AppColors.sideRed, // Green for upcoming events
// //             //   iconStyle: IconStyle(iconData: icon, color: Colors.white),
// //             // ),
// //             indicatorStyle: IndicatorStyle(
// //               width: 30,
// //               height: 30,
// //               padding: const EdgeInsets.only(left: 5),
// //               drawGap: true,
// //               indicator: Container(
// //                 decoration: const BoxDecoration(
// //                   color: AppColors.sideRed,
// //                   shape: BoxShape.circle,
// //                 ),
// //                 child: IconButton(
// //                   style: const ButtonStyle(
// //                     // padding:
// //                     minimumSize: WidgetStatePropertyAll(Size.zero),
// //                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //                     padding: WidgetStatePropertyAll(EdgeInsets.zero),
// //                   ),
// //                   icon: Icon(size: 20, icon, color: Colors.white),
// //                   onPressed: () {
// //                     if (eventSubject == 'Call') {
// //                       // Example: Launch phone dialer (you'll need url_launcher package)
// //                       launchUrl(Uri.parse('tel:$mobile'));
// //                     } else if (eventSubject == 'Send SMS') {
// //                       // Example: Open SMS
// //                       launchUrl(Uri.parse('sms:$mobile'));
// //                     } else if (eventSubject == 'Test Drive') {
// //                       // Example: Open Test Drive UR
// //                       // _getOtp(eventId);
// //                       // Navigator.push(
// //                       //   context,
// //                       //   MaterialPageRoute(
// //                       //     builder: (context) => TestdriveVerifyotp(
// //                       //       email: gmail,
// //                       //       eventId: eventId,
// //                       //       leadId: leadId,
// //                       //       mobile: mobile,
// //                       //     ),
// //                       //   ),
// //                       // );
// //                       _showAleart(eventId, gmail, leadId, mobile, context);
// //                     } else {
// //                       // fallback action
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(
// //                           content: Text('No action defined for this subject'),
// //                         ),
// //                       );
// //                     }
// //                   },
// //                 ),
// //               ),
// //             ),

// //             startChild: Text(
// //               eventDate, // Show the event date
// //               style: AppFont.dropDowmLabel(context),
// //             ),
// //             endChild: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 10.0),
// //               child: Column(
// //                 children: [
// //                   const SizedBox(height: 10),
// //                   Container(
// //                     width: double.infinity,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xffE7F2FF),
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     padding: const EdgeInsets.fromLTRB(10.0, 10, 0, 10),
// //                     child: RichText(
// //                       text: TextSpan(
// //                         children: [
// //                           TextSpan(
// //                             text: 'Action : ',
// //                             style: AppFont.dropDowmLabel(context),
// //                           ),
// //                           TextSpan(
// //                             text: '$eventSubject\n',
// //                             style: AppFont.smallText12(context),
// //                           ),
// //                           TextSpan(
// //                             text: 'Remarks : ',
// //                             style: AppFont.dropDowmLabel(context),
// //                           ),
// //                           TextSpan(
// //                             text: remarks,
// //                             style: AppFont.smallText12(context),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         }),
// //         const SizedBox(height: 10),
// //       ],
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/services/api_srv.dart';
// import 'package:smartassist/widgets/testdrive_verifyotp.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:timeline_tile/timeline_tile.dart';
// import 'package:google_fonts/google_fonts.dart';

// class timelineOverdue extends StatefulWidget {
//   final carIcon = '/assets/caricon.png';
//   final List<Map<String, dynamic>> tasks;
//   final List<Map<String, dynamic>> overdueEvents;
//   const timelineOverdue({
//     super.key,
//     required this.tasks,
//     required this.overdueEvents,
//   });

//   @override
//   State<timelineOverdue> createState() => _timelineOverdueState();
// }

// class _timelineOverdueState extends State<timelineOverdue> {
//   final Set<int> expandedTaskIndexes = {};
//   final Set<int> expandedEventIndexes = {};

//   String _formatDate(String date) {
//     try {
//       final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
//       return DateFormat("d MMM").format(parsedDate); // Outputs "22 May"
//     } catch (e) {
//       print('Error formatting date: $e');
//       return 'N/A';
//     }
//   }

//   Future<void> _showAleart(
//     String eventId,
//     String gmail,
//     String leadId,
//     String mobile,
//     BuildContext context,
//   ) async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false, // User must tap button to close dialog
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           title: Text(
//             'Ready to start test drive?',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//           ),
//           content: Text(
//             'Please make sure you have all the necessary documents(license) and permissions(OTP) ready before starting test drive.',
//             style: GoogleFonts.poppins(),
//           ),
//           actions: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 overlayColor: Colors.grey.withOpacity(0.1),
//                 foregroundColor: Colors.grey,
//               ),
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text('No', style: GoogleFonts.poppins(color: Colors.grey)),
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                 overlayColor: AppColors.colorsBlue.withOpacity(0.1),
//                 foregroundColor: AppColors.colorsBlue,
//               ),
//               onPressed: () {
//                 _getOtp(eventId);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TestdriveVerifyotp(
//                       email: gmail,
//                       eventId: eventId,
//                       leadId: leadId,
//                       mobile: mobile,
//                     ),
//                   ),
//                 );
//               },
//               child: Text(
//                 'Yes',
//                 style: GoogleFonts.poppins(color: AppColors.colorsBlue),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _getOtp(String eventId) async {
//     final success = await LeadsSrv.getOtp(eventId: eventId);

//     if (success) {
//       print('✅ Test drive started successfully');
//     } else {
//       print('❌ Failed to start test drive');
//     }

//     // if (mounted) setState(() {});
//   }

//   bool _shouldShowSeeMore(String remarks) {
//     return remarks.length > 60;
//   }

//   bool _isTestDrive(String subject) {
//     return subject.toLowerCase().contains('test drive');
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Reverse the tasks list to show from bottom to top
//     final reversedTasks = widget.tasks.reversed.toList();

//     // Reverse the upcomingEvents list to show from bottom to top
//     final reversedUpcomingEvents = widget.overdueEvents.reversed.toList();

//     if (reversedTasks.isEmpty && reversedUpcomingEvents.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           child: Text(
//             "No overdue task available",
//             style: AppFont.smallText12(context),
//           ),
//         ),
//       );
//     }

//     const double minBoxHeight = 90.0;

//     return Column(
//       children: [
//         // TASKS - Updated styling
//         ...List.generate(reversedTasks.length, (index) {
//           final task = reversedTasks[index];
//           String remarks = task['remarks'] ?? '';
//           String dueDate = _formatDate(task['due_date'] ?? 'N/A');
//           String subject = task['subject'] ?? 'No Subject';

//           bool isExpanded = expandedTaskIndexes.contains(index);
//           bool showSeeMore = _shouldShowSeeMore(remarks);

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Date & Action Row (NO icon)
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // Date Badge
//                   Text(
//                     dueDate,
//                     style: AppFont.dropDowmLabel(context)?.copyWith(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.sideRed,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   // Action Text
//                   Text(
//                     subject,
//                     style: AppFont.dropDowmLabel(context)?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12.5,
//                       color: AppColors.sideRed,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),

//               // Card with only Remarks
//               Container(
//                 width: double.infinity,
//                 constraints: BoxConstraints(
//                   minHeight: minBoxHeight,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xffE7F2FF),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.all(14),
//                 margin: const EdgeInsets.only(top: 4, bottom: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Remarks:',
//                       style: AppFont.dropDowmLabel(context),
//                     ),
//                     const SizedBox(height: 2),
//                     if (remarks.isNotEmpty) ...[
//                       Text(
//                         remarks,
//                         maxLines: (!showSeeMore || isExpanded) ? null : 2,
//                         overflow: (!showSeeMore || isExpanded)
//                             ? TextOverflow.visible
//                             : TextOverflow.ellipsis,
//                         style: AppFont.smallText12(context),
//                       ),
//                       if (showSeeMore) ...[
//                         const SizedBox(height: 8),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               if (isExpanded) {
//                                 expandedTaskIndexes.remove(index);
//                               } else {
//                                 expandedTaskIndexes.add(index);
//                               }
//                             });
//                           },
//                           child: Text(
//                             isExpanded ? 'See less' : 'See more',
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.w500,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                     if (remarks.isEmpty)
//                       const SizedBox(height: 24), // For empty remarks, to match box size
//                   ],
//                 ),
//               ),
//             ],
//           );
//         }),

//         // EVENTS - Updated styling
//         ...List.generate(reversedUpcomingEvents.length, (index) {
//           final event = reversedUpcomingEvents[index];
//           String eventId = event['event_id'] ?? 'No ID';
//           String leadId = event['lead_id'] ?? 'No ID';
//           String gmail = event['lead_email'] ?? '';
//           String remarks = event['remarks'] ?? '';
//           String mobile = event['mobile'] ?? '';
//           String eventDate = _formatDate(event['start_date'] ?? 'N/A');
//           String eventSubject = event['subject'] ?? 'No Subject';

//           bool isExpanded = expandedEventIndexes.contains(index);
//           bool showSeeMore = _shouldShowSeeMore(remarks);
//           bool isTestDriveEvent = _isTestDrive(eventSubject);

//           // Choose colors based on whether it's a test drive
//           Color badgeColor = AppColors.sideRed;
//           Color badgeBackgroundColor = AppColors.sideRed.withOpacity(0.1);
//           Color badgeBorderColor = AppColors.sideRed.withOpacity(0.3);

//           return Container(
//             margin: const EdgeInsets.only(bottom: 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Date & Action Row (NO icon)
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Date Badge
//                     Text(
//                       eventDate,
//                       style: AppFont.dropDowmLabel(context)?.copyWith(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: badgeColor,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     // Action Text
//                     Text(
//                       eventSubject,
//                       style: AppFont.dropDowmLabel(context)?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                         color: AppColors.sideRed,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),

//                 // Card with only Remarks
//                 Container(
//                   width: double.infinity,
//                   constraints: BoxConstraints(minHeight: minBoxHeight),
//                   decoration: BoxDecoration(
//                     color: const Color(0xffE7F2FF),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.all(14),
//                   margin: const EdgeInsets.only(top: 4),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Remarks:',
//                         style: AppFont.dropDowmLabel(context),
//                       ),
//                       const SizedBox(height: 2),
//                       if (remarks.isNotEmpty) ...[
//                         Text(
//                           remarks,
//                           maxLines: (!showSeeMore || isExpanded) ? null : 2,
//                           overflow: (!showSeeMore || isExpanded)
//                               ? TextOverflow.visible
//                               : TextOverflow.ellipsis,
//                           style: AppFont.smallText12(context),
//                         ),
//                         if (showSeeMore) ...[
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 if (isExpanded) {
//                                   expandedEventIndexes.remove(index);
//                                 } else {
//                                   expandedEventIndexes.add(index);
//                                 }
//                               });
//                             },
//                             child: Text(
//                               isExpanded ? 'See less' : 'See more',
//                               style: GoogleFonts.poppins(
//                                 color: badgeColor,
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                       if (remarks.isEmpty)
//                         const SizedBox(height: 24),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),

//         const SizedBox(height: 10),
//       ],
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/services/api_srv.dart';
// import 'package:smartassist/widgets/testdrive_verifyotp.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:timeline_tile/timeline_tile.dart';
// import 'package:google_fonts/google_fonts.dart';

// class timelineOverdue extends StatefulWidget {
//   final carIcon = '/assets/caricon.png';
//   final List<Map<String, dynamic>> tasks;
//   final List<Map<String, dynamic>> overdueEvents;
//   const timelineOverdue({
//     super.key,
//     required this.tasks,
//     required this.overdueEvents,
//   });

//   @override
//   State<timelineOverdue> createState() => _timelineOverdueState();
// }

// class _timelineOverdueState extends State<timelineOverdue> {
//   final Set<int> expandedTaskIndexes = {};
//   final Set<int> expandedEventIndexes = {};

//   String _formatDate(String date) {
//     try {
//       final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
//       return DateFormat("d MMM").format(parsedDate); // Outputs "22 May"
//     } catch (e) {
//       print('Error formatting date: $e');
//       return 'N/A';
//     }
//   }

//   Future<void> _showAleart(
//     String eventId,
//     String gmail,
//     String leadId,
//     String mobile,
//     BuildContext context,
//   ) async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false, // User must tap button to close dialog
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           title: Text(
//             'Ready to start test drive?',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//           ),
//           content: Text(
//             'Please make sure you have all the necessary documents(license) and permissions(OTP) ready before starting test drive.',
//             style: GoogleFonts.poppins(),
//           ),
//           actions: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 overlayColor: Colors.grey.withOpacity(0.1),
//                 foregroundColor: Colors.grey,
//               ),
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text('No', style: GoogleFonts.poppins(color: Colors.grey)),
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                 overlayColor: AppColors.colorsBlue.withOpacity(0.1),
//                 foregroundColor: AppColors.colorsBlue,
//               ),
//               onPressed: () {
//                 _getOtp(eventId);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TestdriveVerifyotp(
//                       email: gmail,
//                       eventId: eventId,
//                       leadId: leadId,
//                       mobile: mobile,
//                     ),
//                   ),
//                 );
//               },
//               child: Text(
//                 'Yes',
//                 style: GoogleFonts.poppins(color: AppColors.colorsBlue),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _getOtp(String eventId) async {
//     final success = await LeadsSrv.getOtp(eventId: eventId);

//     if (success) {
//       print('✅ Test drive started successfully');
//     } else {
//       print('❌ Failed to start test drive');
//     }

//     // if (mounted) setState(() {});
//   }

//   bool _shouldShowSeeMore(String remarks) {
//     return remarks.length > 60;
//   }

//   bool _isTestDrive(String subject) {
//     return subject.toLowerCase().contains('test drive');
//   }

//   // Icon logic from first code
//   IconData _getIconForSubject(String subject) {
//     if (subject == 'Provide Quotation') {
//       return Icons.receipt_long;
//     } else if (subject == 'Send SMS') {
//       return Icons.message_rounded;
//     } else if (subject == 'Call') {
//       return Icons.phone;
//     } else if (subject == 'Send Email') {
//       return Icons.mail;
//     } else if (subject == 'Showroom appointment') {
//       return Icons.person_2_outlined;
//     } else if (subject == 'Trade in evaluation') {
//       return Icons.handshake;
//     } else if (subject == 'Test Drive') {
//       return Icons.directions_car;
//     } else {
//       return Icons.phone; // default fallback icon
//     }
//   }

//   // Icon logic for events from first code
//   IconData _getIconForEventSubject(String eventSubject) {
//     if (eventSubject == 'Test Drive') {
//       return Icons.directions_car;
//     } else if (eventSubject == 'Showroom appointment') {
//       return FontAwesomeIcons.solidCalendar;
//     } else if (eventSubject == 'Quotation') {
//       return FontAwesomeIcons.solidCalendar;
//     } else {
//       return Icons.phone;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Reverse the tasks list to show from bottom to top
//     final reversedTasks = widget.tasks.reversed.toList();

//     // Reverse the upcomingEvents list to show from bottom to top
//     final reversedUpcomingEvents = widget.overdueEvents.reversed.toList();

//     if (reversedTasks.isEmpty && reversedUpcomingEvents.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           child: Text(
//             "No overdue task available",
//             style: AppFont.smallText12(context),
//           ),
//         ),
//       );
//     }

//     const double minBoxHeight = 90.0;

//     return Column(
//       children: [
//         // TASKS - Updated styling with icon
//         ...List.generate(reversedTasks.length, (index) {
//           final task = reversedTasks[index];
//           String remarks = task['remarks'] ?? '';
//           String dueDate = _formatDate(task['due_date'] ?? 'N/A');
//           String subject = task['subject'] ?? 'No Subject';

//           bool isExpanded = expandedTaskIndexes.contains(index);
//           bool showSeeMore = _shouldShowSeeMore(remarks);

//           // Get icon for this subject
//           IconData icon = _getIconForSubject(subject);

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Date & Action Row with icon
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // Icon
//                   Container(
//                     width: 30,
//                     height: 30,
//                     decoration: BoxDecoration(
//                       color: AppColors.sideRed,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(icon, color: Colors.white, size: 16),
//                   ),
//                   const SizedBox(width: 12),
//                   // Date Badge
//                   Text(
//                     dueDate,
//                     style: AppFont.dropDowmLabel(context)?.copyWith(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.sideRed,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   // Action Text
//                   Text(
//                     subject,
//                     style: AppFont.dropDowmLabel(context)?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12.5,
//                       color: AppColors.sideRed,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),

//               // Card with only Remarks
//               Container(
//                 width: double.infinity,
//                 constraints: BoxConstraints(minHeight: minBoxHeight),
//                 decoration: BoxDecoration(
//                   color: const Color(0xffE7F2FF),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.all(14),
//                 margin: const EdgeInsets.only(top: 4, bottom: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Remarks:', style: AppFont.dropDowmLabel(context)),
//                     const SizedBox(height: 2),
//                     if (remarks.isNotEmpty) ...[
//                       Text(
//                         remarks,
//                         maxLines: (!showSeeMore || isExpanded) ? null : 2,
//                         overflow: (!showSeeMore || isExpanded)
//                             ? TextOverflow.visible
//                             : TextOverflow.ellipsis,
//                         style: AppFont.smallText12(context),
//                       ),
//                       if (showSeeMore) ...[
//                         const SizedBox(height: 8),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               if (isExpanded) {
//                                 expandedTaskIndexes.remove(index);
//                               } else {
//                                 expandedTaskIndexes.add(index);
//                               }
//                             });
//                           },
//                           child: Text(
//                             isExpanded ? 'See less' : 'See more',
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.w500,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                     if (remarks.isEmpty)
//                       const SizedBox(
//                         height: 24,
//                       ), // For empty remarks, to match box size
//                   ],
//                 ),
//               ),
//             ],
//           );
//         }),

//         // EVENTS - Updated styling with icon
//         ...List.generate(reversedUpcomingEvents.length, (index) {
//           final event = reversedUpcomingEvents[index];
//           String eventId = event['event_id'] ?? 'No ID';
//           String leadId = event['lead_id'] ?? 'No ID';
//           String gmail = event['lead_email'] ?? '';
//           String remarks = event['remarks'] ?? '';
//           String mobile = event['mobile'] ?? '';
//           String eventDate = _formatDate(event['start_date'] ?? 'N/A');
//           String eventSubject = event['subject'] ?? 'No Subject';

//           bool isExpanded = expandedEventIndexes.contains(index);
//           bool showSeeMore = _shouldShowSeeMore(remarks);
//           bool isTestDriveEvent = _isTestDrive(eventSubject);

//           // Get icon for this event subject
//           IconData icon = _getIconForEventSubject(eventSubject);

//           // Choose colors based on whether it's a test drive
//           Color badgeColor = AppColors.sideRed;
//           Color badgeBackgroundColor = AppColors.sideRed.withOpacity(0.1);
//           Color badgeBorderColor = AppColors.sideRed.withOpacity(0.3);

//           return Container(
//             margin: const EdgeInsets.only(bottom: 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Date & Action Row with icon
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Icon
//                     Container(
//                       width: 30,
//                       height: 30,
//                       decoration: BoxDecoration(
//                         color: AppColors.sideRed,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(icon, color: Colors.white, size: 16),
//                     ),
//                     const SizedBox(width: 12),
//                     // Date Badge
//                     Text(
//                       eventDate,
//                       style: AppFont.dropDowmLabel(context)?.copyWith(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: badgeColor,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     // Action Text
//                     Text(
//                       eventSubject,
//                       style: AppFont.dropDowmLabel(context)?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                         color: AppColors.sideRed,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),

//                 // Card with only Remarks
//                 Container(
//                   width: double.infinity,
//                   constraints: BoxConstraints(minHeight: minBoxHeight),
//                   decoration: BoxDecoration(
//                     color: const Color(0xffE7F2FF),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.all(14),
//                   margin: const EdgeInsets.only(top: 4),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Remarks:', style: AppFont.dropDowmLabel(context)),
//                       const SizedBox(height: 2),
//                       if (remarks.isNotEmpty) ...[
//                         Text(
//                           remarks,
//                           maxLines: (!showSeeMore || isExpanded) ? null : 2,
//                           overflow: (!showSeeMore || isExpanded)
//                               ? TextOverflow.visible
//                               : TextOverflow.ellipsis,
//                           style: AppFont.smallText12(context),
//                         ),
//                         if (showSeeMore) ...[
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 if (isExpanded) {
//                                   expandedEventIndexes.remove(index);
//                                 } else {
//                                   expandedEventIndexes.add(index);
//                                 }
//                               });
//                             },
//                             child: Text(
//                               isExpanded ? 'See less' : 'See more',
//                               style: GoogleFonts.poppins(
//                                 color: badgeColor,
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                       if (remarks.isEmpty) const SizedBox(height: 24),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),

//         const SizedBox(height: 10),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/followups.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/appointments.dart';

class timelineOverdue extends StatefulWidget {
  final bool isFromTeams;
  final carIcon = '/assets/caricon.png';
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> overdueEvents;
  const timelineOverdue({
    super.key,
    required this.tasks,
    required this.overdueEvents,
    required this.isFromTeams,
  });

  @override
  State<timelineOverdue> createState() => _timelineOverdueState();
}

class _timelineOverdueState extends State<timelineOverdue> {
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
                        if (!widget.isFromTeams)
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.black,
                            ),
                            onPressed: () => _handleEdit(subject, taskId),
                            tooltip: 'Edit',
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
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
                          if (!widget.isFromTeams)
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.black,
                              ),
                              onPressed: () =>
                                  _handleEdit(eventSubject, eventId),
                              tooltip: 'Edit',
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
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
