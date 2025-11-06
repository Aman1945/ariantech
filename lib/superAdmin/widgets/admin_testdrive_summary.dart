import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'dart:convert';
import 'package:smartassist/utils/storage.dart';

class AdminTestdriveSummary extends StatefulWidget {
  final bool isFromCompletdTimeline;
  final bool isFromTestdrive;
  final String eventId;
  final String isFromCompletedEventId;
  final String leadId;
  final String isFromCompletedLeadId;
  const AdminTestdriveSummary({
    super.key,
    required this.eventId,
    required this.leadId,
    required this.isFromTestdrive,
    required this.isFromCompletdTimeline,
    required this.isFromCompletedEventId,
    required this.isFromCompletedLeadId,
  });

  @override
  State<AdminTestdriveSummary> createState() => _AdminTestdriveSummaryState();
}

class _AdminTestdriveSummaryState extends State<AdminTestdriveSummary> {
  // Define variables to hold the data
  bool isFromTestdriveOverview = false;
  bool _isHidden = false;
  String startTime = '';
  String remarks = 'No Remarks';
  String distanceCovered = '';
  String mapImgUrl = '';
  bool isLoading = true;
  String potentialPurchase = '';
  String purchase_potential = '';
  String avg_rating = '';
  // Map<String, dynamic> ratings = {};
  Map<String, dynamic>? ratings;
  String rawDistance = '';
  // String formattedDistance = rawDistance.toStringAsFixed(2);

  DateTime? _lastBackPressTime;
  final int _exitTimeInMillis = 2000;

  @override
  void initState() {
    super.initState();
    _fetchTestDriveData();
  }

  double parseDistance(String concatenatedDistance) {
    if (concatenatedDistance.isEmpty) return 0.0;

    // Remove leading/trailing whitespace
    concatenatedDistance = concatenatedDistance.trim();

    // Split by decimal points and sum up the segments
    List<String> segments = concatenatedDistance.split('.');
    double totalDistance = 0.0;

    for (int i = 0; i < segments.length; i++) {
      String segment = segments[i];
      if (segment.isNotEmpty) {
        // Try to parse each segment as a decimal number
        double? value = double.tryParse('0.$segment');
        if (value != null) {
          totalDistance += value;
        }
      }
    }

    return totalDistance;
  }

  String formatDistance(double distance) {
    if (distance < 1.0) {
      // Show in meters if less than 1 km
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      // Show in kilometers with 2 decimal places
      return '${distance.toStringAsFixed(2)} km';
    }
  }

  Future<void> _fetchTestDriveData() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      final token = await Storage.getToken();
      final url = widget.isFromTestdrive
          ? 'https://api.smartassistapp.in/api/events/${widget.eventId}'
          : 'https://api.smartassistapp.in/api/events/${widget.isFromCompletedEventId}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded JSON:');
        print(const JsonEncoder.withIndent('  ').convert(data));
        setState(() {
          startTime = data['data']['duration'] ?? '0';
          remarks = data['data']['feedback_comments'] ?? 'No Remarks';
          if (data['data']['distance'] != null) {
            String rawDistance = data['data']['distance'].toString();

            double parsedDistance = double.tryParse(rawDistance) ?? 0.0;
            String formattedDistance = parsedDistance.toStringAsFixed(2);

            distanceCovered = '$formattedDistance km';

            print('Raw distance: $rawDistance');
            print('Formatted distance: $distanceCovered');
          } else {
            distanceCovered = '0.0 km';
          }
          mapImgUrl = data['data']['map_img'] ?? '';
          potentialPurchase =
              data['data']['purchase_potential'] ?? 'Not provided';
          purchase_potential =
              data['data']['purchase_potential'] ?? 'Not provided';
          avg_rating = data['data']['avg_rating'] != null
              ? double.tryParse(
                      data['data']['avg_rating'].toString(),
                    )?.toStringAsFixed(1) ??
                    '0.0'
              : '0.0';
          ratings = data['data']['drive_feedback'];
          isLoading = false;
        });

        print('this is sthe data');
        print(data);
      } else {
        setState(() {
          isLoading =
              false; // If there is an error, stop loading and show content
        });
        print(
          'Failed to fetch test drive data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if there is an error
      });
      // Handle different types of errors (network, JSON, etc.)
      print('Error fetching test drive data: $e');
      // Optionally, you can also show an error message to the user
    }
  }

  String formatTime(String startTime) {
    try {
      DateFormat inputFormat = DateFormat(
        "HH:mm",
      ); // Assuming startTime is in "24-hour" format (e.g., "12:12")
      DateTime time = inputFormat.parse(startTime);
      DateFormat outputFormat = DateFormat(
        "hh:mm a",
      ); // Converts to 12-hour format with AM/PM
      return outputFormat.format(time);
    } catch (e) {
      return "Invalid time"; // Handle if input is not in the expected format
    }
  }

  bool _isLoading = false;

  String getRatingLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Below Average';
    return 'Poor';
  }

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  double _titleFontSize(BuildContext context) =>
      _isTablet(context) ? 20 : (_isSmallScreen(context) ? 16 : 18);
  double _bodyFontSize(BuildContext context) =>
      _isTablet(context) ? 16 : (_isSmallScreen(context) ? 12 : 14);
  double _smallFontSize(BuildContext context) =>
      _isTablet(context) ? 14 : (_isSmallScreen(context) ? 10 : 12);

  @override
  Widget build(BuildContext context) {
    String formattedTime = formatTime(startTime);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.colorsBlue,
        title: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () async {
              setState(() {
                _isLoading = true; // Step 1: show loader
              });

              await AdminUserIdManager.clearAll(); // Step 2: clear ID

              if (!mounted) return;

              Get.offAll(() => AdminDealerall());
            },
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),

                SizedBox(width: 10),
                Text(
                  AdminUserIdManager.adminNameSync ?? "No Name",
                  style: AppFont.dropDowmLabelWhite(context),
                ),
              ],
            ),
          ),
        ),
      ),

      // appBar: AppBar(
      //   backgroundColor: AppColors.colorsBlue,
      //   title: Align(
      //     alignment: Alignment.centerLeft,
      //     child: Text(
      //       'Test Drive summary',
      //       style: GoogleFonts.poppins(
      //         fontSize: _titleFontSize(context),
      //         fontWeight: FontWeight.w400,
      //         color: Colors.white,
      //       ),
      //     ),
      //   ),
      //   leading: IconButton(
      //     icon: Icon(
      //       Icons.arrow_back_ios_new_outlined,
      //       color: Colors.white,
      //       size: _isSmallScreen(context) ? 18 : 20,
      //     ),
      //     onPressed: () {
      //       print(
      //         'this is the lead id from testdrive ${widget.isFromCompletedLeadId}',
      //       );
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => FollowupsDetails(
      //             leadId: widget.isFromCompletdTimeline
      //                 ? widget.isFromCompletedLeadId
      //                 : widget.leadId,
      //             isFromFreshlead: false,
      //             isFromManager: false,
      //             refreshDashboard: () async {},
      //             isFromTestdriveOverview: true,
      //           ),
      //         ),
      //       );
      //     },
      //   ),
      //   elevation: 0,
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              backgroundColor: AppColors.backgroundLightGrey,
              body: Container(
                width: double.infinity, // ✅ Ensures full width
                height: double.infinity,
                decoration: BoxDecoration(color: AppColors.backgroundLightGrey),
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map
                        const SizedBox(height: 20),
                        ratings == null
                            ? Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  width: MediaQuery.sizeOf(context).width,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    'Feedback not submitted yet.',
                                    style: AppFont.dropDowmLabel(context),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        avg_rating,
                                                        style:
                                                            AppFont.popupTitleBlack(
                                                              context,
                                                            ),
                                                      ),
                                                      const Icon(
                                                        Icons.star_rounded,
                                                        color: AppColors
                                                            .starBorderColor,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    getRatingLabel(
                                                      double.tryParse(
                                                            avg_rating,
                                                          ) ??
                                                          0,
                                                    ),
                                                    style: AppFont.mediumText14(
                                                      context,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Potential of Purchase',
                                                    style:
                                                        AppFont.dropDowmLabel(
                                                          context,
                                                        ),
                                                  ),
                                                  Text(
                                                    potentialPurchase,
                                                    style:
                                                        AppFont.mediumText14blue(
                                                          context,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Column(
                                            children: [
                                              _buildRatingRow(
                                                'Overall Ambience',
                                                ratings?['ambience'],
                                              ),
                                              _buildRatingRow(
                                                'Features',
                                                ratings?['features'],
                                              ),
                                              _buildRatingRow(
                                                'Ride and Comfort',
                                                ratings?['ride_comfort'],
                                              ),
                                              _buildRatingRow(
                                                'Quality',
                                                ratings?['quality'],
                                              ),
                                              _buildRatingRow(
                                                'Dynamics',
                                                ratings?['dynamics'],
                                              ),
                                              _buildRatingRow(
                                                'Driving Experience',
                                                ratings?['driving_experience'],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                        // Start time
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          color: AppColors.backgroundLightGrey,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            FontAwesomeIcons.clock,
                                            size: 20,
                                            color: AppColors.colorsBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Duration',
                                        style: AppFont.dropDowmLabel(context),
                                      ),
                                      Text(
                                        '${startTime} m',
                                        style: AppFont.mediumText14(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          color: AppColors.backgroundLightGrey,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            FontAwesomeIcons.locationDot,
                                            size: 20,
                                            color: AppColors.colorsBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: Text(
                                          'Distance covered',
                                          style: AppFont.mediumText14Black(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$distanceCovered',
                                        style: AppFont.mediumText14(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15.0),
                                    child: Text(
                                      'Remarks',
                                      style: AppFont.dropDowmLabel(context),
                                    ),
                                  ),
                                  Container(
                                    width: 250,
                                    margin: EdgeInsets.only(right: 10),
                                    child: Text(
                                      (remarks == null ||
                                              remarks.trim().isEmpty)
                                          ? 'No Remarks'
                                          : remarks,

                                      style: AppFont.mediumText14(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15.0),
                                    child: Text(
                                      'Map',
                                      style: AppFont.popupTitleBlack16(context),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isHidden = !_isHidden;
                                      });
                                    },
                                    icon: Icon(
                                      _isHidden
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_up_rounded,
                                      size: 30,
                                      color: AppColors.fontColor,
                                      // style: AppFont.smallText(context),
                                    ),
                                  ),
                                ],
                              ),

                              // if (!_isHidden) ...[
                              //   if (mapImgUrl.isNotEmpty)
                              //     Column(
                              //       children: [
                              //         Container(
                              //           margin: const EdgeInsets.symmetric(
                              //             horizontal: 10,
                              //           ),
                              //           decoration: BoxDecoration(
                              //             borderRadius: BorderRadius.circular(
                              //               30,
                              //             ),
                              //           ),
                              //           child: Image.network(mapImgUrl),
                              //         ),
                              //       ],
                              //     ),
                              // ],
                              if (!_isHidden) ...[
                                if (mapImgUrl.isNotEmpty)
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Image.network(
                                          mapImgUrl,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  height:
                                                      200, // Set a fixed height for the placeholder
                                                  width: double.infinity,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Text(
                                                      'Failed to load map image',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text(
                                        'No map image available',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method to build the rating row with stars and emojis

  Widget _buildRatingRow(String label, int? rating) {
    // List of emojis corresponding to each rating level
    final List<String> emojiRatings = ['😔', '🙁', '🙂', '😃', '😍'];

    // Fix rating properly
    int validRating = (rating != null && rating >= 1 && rating <= 5)
        ? rating
        : 0;

    // Calculate the percentage for the progress bar
    double percentage = (validRating / 5.0); // rating out of 5 stars

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rating label
          Text('$label', style: AppFont.smallText(context)),

          // The progress line using LinearPercentIndicator
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                child: LinearPercentIndicator(
                  lineHeight: 8.0, // Height of the progress line
                  percent: percentage, // Fill percentage
                  backgroundColor:
                      Colors.grey[300]!, // Background color for the line
                  progressColor:
                      Colors.amber, // Color for the filled portion of the line
                  barRadius: Radius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  ' $validRating',
                  style: AppFont.mediumText14(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) >
            Duration(milliseconds: _exitTimeInMillis)) {
      _lastBackPressTime = now;

      // Show a bottom slide dialog
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Exit Testdrive',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorsBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit from Testdrive?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Cancel button (White)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Dismiss dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.colorsBlue,
                            side: const BorderSide(color: AppColors.colorsBlue),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Exit button (Blue)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // First close the bottom sheet
                            Navigator.pop(context);

                            try {
                              // Navigate to home screen and clear the stack
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => BottomNavigation(),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              print("Navigation error: $e");
                              // Fallback navigation
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BottomNavigation(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorsBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      );
      return false;
    }
    return true;
  }
}
