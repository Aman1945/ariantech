import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/calender/calender.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AdminSingleCallhistory extends StatefulWidget {
  final String category;
  final String mobile;
  const AdminSingleCallhistory({
    super.key,
    required this.category,
    required this.mobile,
  });

  @override
  State<AdminSingleCallhistory> createState() => _AdminSingleCallhistoryState();
}

class _AdminSingleCallhistoryState extends State<AdminSingleCallhistory> {
  String _categoryTitle = '';
  bool _isLoading = true;
  List<dynamic> _callLogs = [];
  String _totalDuration = '0';
  int _totalCalls = 0;
  String _periodFilter = '';
  int _childButtonIndex = 0;
  DateTime _selectedDate = DateTime.now(); // Initially set to the current date
  String _formattedDate = ''; // Store the formatted date for the API query

  @override
  void initState() {
    super.initState();
    _categoryTitle = widget.category; // Set the category title dynamically
    _formattedDate = formatDate(_selectedDate); // Format the current date
    _fetchCallLogs(); // Fetch the call logs based on category, mobile, and date
  }

  String formatDate(DateTime date) {
    return DateFormat(
      'yyyy/MM/dd',
    ).format(date); // Formats the date to "YYYY/MM/dd"
  }

  String _getFormattedDateString(Map<String, dynamic> call) {
    String formattedDate = '';
    try {
      DateTime parseDate = DateTime.parse(call['call_date']);
      if (parseDate.year == DateTime.now().year &&
          parseDate.month == DateTime.now().month &&
          parseDate.day == DateTime.now().day) {
        formattedDate = 'Today';
      } else {
        int day = parseDate.day;
        String suffix = _getDaySuffix(day);
        String month = DateFormat('MMM').format(parseDate);
        formattedDate = '${day}$suffix $month';
      }
    } catch (e) {
      formattedDate = call['call_date'];
    }
    return formattedDate;
  }

  // Fetch call logs based on the category, mobile number, and date
  Future<void> _fetchCallLogs() async {
    try {
      final data = await fetchCallLogs(
        widget.mobile,
        widget.category,
        _periodFilter,
      );
      setState(() {
        _callLogs = data['logs']['rows']; // Store the call logs
        _totalDuration = data['totalDurationInMins']
            .toString(); // Store total duration
        _totalCalls = data['logs']['count']; // Store total call count
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching call logs: $e');
    }
  }

  Future<Map<String, dynamic>> fetchCallLogs(
    String mobile,
    String category,
    String periodFilter,
  ) async {
    // If callDate is empty, omit the call_date query parameter from the URL
    String apiUrl =
        "https://api.smartassistapp.in/api/leads/call-logs/all?category=$category&mobile=${Uri.encodeComponent(mobile)}";

    // If callDate is not empty, include it in the URL
    // if (callDate.isNotEmpty) {
    //   apiUrl += "&call_date=$callDate";
    // }
    if (periodFilter.isNotEmpty) {
      apiUrl += "&range=$periodFilter";
    }

    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(apiUrl); // Print the final API URL

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return jsonResponse['data']; // Returning data from the API
      } else {
        setState(() => _isLoading = false);
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Widget _time(Map<String, dynamic> call) {
    DateTime parsedTime = DateFormat("HH:mm:ss").parse(call['start_time']);
    String formattedTime = DateFormat("HH:mm").format(parsedTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        Text(
          formattedTime,
          style: GoogleFonts.poppins(
            color: AppColors.fontColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

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

  // Update the date filter when a button is clicked
  void _updateDateFilter(String filter) {
    setState(() {
      switch (filter) {
        case 'All':
          _periodFilter = ''; // Empty for "All"
          break;
        case '1D':
          _periodFilter = 'day';
          break;
        case '1W':
          _periodFilter = 'week';
          break;
        case '1M':
          _periodFilter = 'quarter';
          break;
        case '1Y':
          _periodFilter = 'year';
          break;
        default:
          _periodFilter = '';
      }
      _fetchCallLogs(); // Fetch new data based on the selected period
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            // '$_categoryTitle Calls',
            '${_categoryTitle.isNotEmpty ? _categoryTitle[0].toUpperCase() + _categoryTitle.substring(1) : ""} Calls',

            style: AppFont.appbarfontgrey(context),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppColors.iconGrey,
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              // Date filter buttons
              Container(
                width: screenWidth * 0.95,
                height: 27,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 129, 129, 129),
                    width: .2,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildButton('All', 0),
                    // _buildButton('Today', 1),
                    _buildButton('1D', 2),
                    _buildButton('1W', 3),
                    _buildButton('1M', 4),
                    _buildButton('1Y', 5),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCallSummary(context, screenWidth),
              const SizedBox(height: 10),

              const SizedBox(height: 10),
              _buildCallHistory(context),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallSummary(BuildContext context, double screenWidth) {
    // final selectedData = getSelectedData();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildInfoCard1(
                      context,
                      'Total Duration',
                      '$_totalDuration Mins',
                      screenWidth,
                      Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard1(
    BuildContext context,
    String title,
    String value,
    double screenWidth,
    Color valueColor,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          // boxShadow: List.filled(3, fil),
          border: Border.all(color: Colors.grey, width: .5),
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 4,
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                // textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fontColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display call logs
  Widget _buildCallHistory(BuildContext context) {
    if (_callLogs.isEmpty) {
      return const Center(child: Text('No data found'));
    }

    // Group calls by date
    Map<String, List<dynamic>> callsByDate = {};

    for (var call in _callLogs) {
      String dateKey = _getFormattedDateString(call);
      if (!callsByDate.containsKey(dateKey)) {
        callsByDate[dateKey] = [];
      }
      callsByDate[dateKey]!.add(call);
    }

    // Create a list of widgets for each date group
    List<Widget> dateGroups = [];

    callsByDate.forEach((date, calls) {
      // Create a container for each date with all its calls
      dateGroups.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 15, bottom: 5),
              child: Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Single container for all calls of this date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: .2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: calls.map((call) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        _getCallTypeIcon(call['call_type']),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _time(call),
                            const SizedBox(height: 5),
                            Text(
                              '${call['call_type']} call, ${call['call_duration']} secs',
                              style: AppFont.smallText(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dateGroups,
    );
  }

  // Widget _buildCallHistory(BuildContext context) {
  //   if (_callLogs.isEmpty) {
  //     return const Center(child: Text('No data found'));
  //   }

  //   // Group calls by date
  //   Map<String, List<dynamic>> callsByDate = {};

  //   for (var call in _callLogs) {
  //     // Use _getFormattedDateString instead of _date
  //     String dateKey = _getFormattedDateString(call);
  //     if (!callsByDate.containsKey(dateKey)) {
  //       callsByDate[dateKey] = [];
  //     }
  //     callsByDate[dateKey]!.add(call);
  //   }

  //   // Create a list of widgets for each date group
  //   List<Widget> dateGroups = [];

  //   callsByDate.forEach((date, calls) {
  //     // Add the date header
  //     dateGroups.add(
  //       Padding(
  //         padding: const EdgeInsets.only(left: 5, top: 15, bottom: 5),
  //         child: Text(
  //           date,
  //           style: GoogleFonts.poppins(
  //             fontSize: 14,
  //             color: Colors.grey[600],
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ),
  //     );

  //     // Add the calls for this date
  //     for (var call in calls) {
  //       dateGroups.add(
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //           margin: const EdgeInsets.symmetric(vertical: 5),
  //           decoration: BoxDecoration(
  //               border: Border.all(color: Colors.grey, width: .2),
  //               borderRadius: BorderRadius.circular(5)),
  //           child: Row(
  //             children: [
  //               _getCallTypeIcon(call['call_type']),
  //               const SizedBox(width: 10),
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   _time(call),
  //                   const SizedBox(height: 5),
  //                   Text(
  //                     '${call['call_type']} call, ${call['call_duration']} secs',
  //                     style: AppFont.smallText(context),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     }
  //   });

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: dateGroups,
  //   );
  // }
  // Helper method to get the correct icon based on call type
  Widget _getCallTypeIcon(String callType) {
    IconData iconData;
    Color iconColor;

    switch (callType) {
      case 'incoming':
        iconData = Icons.call_received;
        iconColor = AppColors.colorsBlue;
        break;
      case 'outgoing':
        iconData = Icons.call_made;
        iconColor = AppColors.sideGreen;
        break;
      case 'missed':
        iconData = Icons.call_missed;
        iconColor = AppColors.sideRed;
        break;
      case 'rejected':
        iconData = Icons.call_missed_outgoing;
        iconColor = AppColors.sideRed;
        break;
      default:
        iconData = Icons.call;
        iconColor = AppColors.iconGrey;
        break;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  // Build each date filter button
  Widget _buildButton(String text, int index) {
    bool isSelected = _childButtonIndex == index;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.colorsBlue : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextButton(
          onPressed: () {
            setState(() {
              _childButtonIndex = index;
            });
            _updateDateFilter(
              text,
            ); // Update the date filter based on the selected button
          },
          style: TextButton.styleFrom(
            foregroundColor: isSelected ? AppColors.colorsBlue : Colors.black,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.colorsBlue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
