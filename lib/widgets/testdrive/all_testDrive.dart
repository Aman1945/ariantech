import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/widgets/testdrive/upcoming.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/testdrive.dart';
// import 'package:smartassist/widgets/testdrive/overdue.dart';
import 'package:smartassist/widgets/testdrive_verifyotp.dart';

class AllTestrive extends StatefulWidget {
  final String name, date, vehicle, subject, leadId, eventId, startTime, email;
  final bool isFavorite, isCompleted;
  final VoidCallback onToggleFavorite;
  final VoidCallback handleTestDrive;
  final VoidCallback otpTrigger;

  const AllTestrive({
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
  State<AllTestrive> createState() => _AllFollowupsItemState();
}

class _AllFollowupsItemState extends State<AllTestrive>
    with SingleTickerProviderStateMixin {
  bool _wasCallingPhone = false;

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
        child: _buildOverdueCard(context),
      ),
    );
  }

  Widget _buildOverdueCard(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.leadId), // Always good to set keys
      controller: _slidableController,
      startActionPane: ActionPane(
        extentRatio: 0.2,
        motion: const ScrollMotion(),
        children: [
          // ReusableSlidableAction(
          //   onPressed: widget.onToggleFavorite, // handle fav toggle
          //   backgroundColor: Colors.amber,
          //   icon: widget.isFavorite
          //       ? Icons.star_rounded
          //       : Icons.star_border_rounded,
          //   foregroundColor: Colors.white,
          //   handleTestDrive: '',
          //   otpTrigger: '',
          // ),
          ReusableSlidableAction(
            onPressed: widget.onToggleFavorite, // handle fav toggle
            backgroundColor: Colors.amber,
            icon: widget.isFavorite
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            foregroundColor: Colors.white,
            handleTestDrive: '',
            otpTrigger: '',
          ),
        ],
      ),

      endActionPane: ActionPane(
        extentRatio: 0.4,
        motion: const StretchMotion(),
        children: [
          if (widget.subject == 'Test Drive')
            ReusableSlidableAction(
              // onPressed: _showAleart,
              onPressed: () {
                widget.isCompleted == true ? _showAleart1() : _showAleart();
              },
              backgroundColor: AppColors.colorsBlue,
              icon: Icons.directions_car,
              foregroundColor: Colors.white,
              handleTestDrive: '',
              otpTrigger: '',
            ),
          if (widget.subject == 'Send SMS')
            ReusableSlidableAction(
              onPressed: _messageAction,
              backgroundColor: AppColors.colorsBlue,
              icon: Icons.message_rounded,
              foregroundColor: Colors.white,
              handleTestDrive: '',
              otpTrigger: '',
            ),
          // Edit is always shown
          ReusableSlidableAction(
            onPressed: _mailAction,
            backgroundColor: const Color.fromARGB(255, 231, 225, 225),
            icon: Icons.edit,
            foregroundColor: Colors.white,
            handleTestDrive: '',
            otpTrigger: '',
          ),
        ],
      ),
      child: Stack(
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
      ),
    );
  }

  Future<void> _showAleart() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(

          backgroundColor: AppColors.containerBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
              style: TextButton.styleFrom(
                overlayColor: Colors.grey.withOpacity(0.1),
                foregroundColor: Colors.grey,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                overlayColor: AppColors.colorsBlue.withOpacity(0.1),
                foregroundColor: AppColors.colorsBlue,
              ),
              // onPressed: () => Navigator.of(context).pop(
              // true),
              onPressed: () {
                // initwhatsappChat(context); // Pass context to submit
                widget.handleTestDrive();
                widget.otpTrigger();
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

    Future<void> _showAleart1() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.containerBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            'Test Drive has already been completed',

            // style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            style: AppFont.appbarfontblack(context),
          ),
          content: Text(
            'If you wish to initiate test drive again for this client, kindly create a new one',

            // style: GoogleFonts.poppins(),
            style: AppFont.dropDown(context),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                overlayColor: Colors.grey.withOpacity(0.1),
                foregroundColor: Colors.grey,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.colorsBlue),
              ),
            ),
          ],
        );
      },
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
}

class ReusableSlidableAction extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData icon;
  final Color? foregroundColor;
  final double iconSize;
  final String handleTestDrive;
  final String otpTrigger;

  const ReusableSlidableAction({
    Key? key,
    required this.onPressed,
    required this.backgroundColor,
    required this.icon,
    required this.handleTestDrive,
    required this.otpTrigger,
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

class AllTestDrive extends StatefulWidget {
  final List<dynamic> allTestDrive;
  final bool isNested;

  const AllTestDrive({
    super.key,
    required this.allTestDrive,
    this.isNested = false,
  });

  @override
  State<AllTestDrive> createState() => _AllTestDriveState();
}

class _AllTestDriveState extends State<AllTestDrive> {
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
  void didUpdateWidget(AllTestDrive oldWidget) {
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
    // String email = item['updated_by'] ?? '';
    String email = item['lead_email'] ?? 'No Email';
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

      // if (widget.onFavoriteToggle != null) {
      //   widget.onFavoriteToggle!(eventId, newFavoriteStatus);
      // }
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
              child: upcomingTestDrivesItem(
                key: ValueKey(item['event_id']),
                name: item['name'] ?? '',
                vehicle: item['PMI'] ?? 'Range Rover Velar',
                subject: item['subject'] ?? 'Meeting',
                leadEmail: item['lead_email'] ?? 'no email',
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
                fetchDashboardData: () {},
                handleTestDrive: () {
                  _handleTestDrive(item);
                },
                swipeOffset: 0,
                // taskId: '',
                refreshDashboard: () async {},
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
