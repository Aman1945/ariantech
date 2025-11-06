import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/getX/fab.controller.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/call_history.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/lead_update.dart';
import 'package:smartassist/widgets/home_btn.dart/single_ids_popup/appointment_ids.dart';
import 'package:smartassist/widgets/home_btn.dart/single_ids_popup/followups_ids.dart';
import 'package:smartassist/widgets/home_btn.dart/single_ids_popup/testdrive_ids.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/timeline/timeline_overdue.dart';
import 'package:smartassist/widgets/timeline/timeline_tasks.dart';
import 'package:smartassist/widgets/timeline/timeline_completed.dart';
import 'package:smartassist/widgets/whatsapp_chat.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FollowupsDetails extends StatefulWidget {
  final Future<void> Function() refreshDashboard;
  final bool isFromFreshlead;
  final bool isFromManager;
  final bool isFromTestdriveOverview;
  String? selectedLostReason;
  final String? spId;

  final String leadId;
  FollowupsDetails({
    super.key,
    this.selectedLostReason,
    required this.leadId,
    required this.isFromFreshlead,
    required this.isFromManager,
    required this.refreshDashboard,
    required this.isFromTestdriveOverview,
    required this.spId,
  });

  @override
  State<FollowupsDetails> createState() => _FollowupsDetailsState();
}

class _FollowupsDetailsState extends State<FollowupsDetails> {
  // Placeholder data
  Map<String, String> _errors = {};
  String mobile = 'Loading...';
  String chatId = 'Loading...';
  String email = 'Loading...';
  String status = 'Loading...';
  String company = 'Loading...';
  String address = 'Loading...';
  String lead_owner = 'Loading....';
  String leadSource = 'Loading....';
  String enquiry_type = 'Loading...';
  String purchase_type = 'Loading...';
  String PMI = 'Loading....';
  String fuel_type = 'Loading....';
  String lead_name = 'Loading....';
  String expected_date_purchase = 'Loading...';
  String pincode = 'Loading..';
  String lead_status = 'Not Converted';
  String vehicle_id = '';
  String company_name = '';
  bool for_company = false;
  bool isLoading = false;
  int _childButtonIndex = 0;
  Widget _selectedTaskWidget = Container();
  // int overdueCount = 0;
  static Map<String, int> _callLogs = {
    'all': 0,
    'outgoing': 0,
    'incoming': 0,
    'missed': 0,
  };

  //  Widget _callLogsWidget = Container();
  // fetchevent data

  List<Map<String, dynamic>> upcomingTasks = [];
  List<Map<String, dynamic>> overdueTasks = [];
  List<Map<String, dynamic>> overdueEvents = [];
  List<Map<String, dynamic>> upcomingEvents = [];
  List<Map<String, dynamic>> completedEvents = [];
  List<Map<String, dynamic>> completedTasks = [];
  int overdueCount = 0;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController companynameController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  List<String> subjectList = [];
  List<String> priorityList = [];
  List<String> startTimeList = [];
  List<String> endTimeList = [];
  List<String> startDateList = [];

  bool _isHidden = false;
  bool _isHiddenTop = true;
  bool _isHiddenMiddle = true;
  // Initialize the controller
  // Create unique controller for this page using tag
  late FabController fabController;
  late ScrollController scrollController;
  // final FabController fabController = Get.put(FabController());
  String leadId = '';

  @override
  void initState() {
    super.initState();
    eventandtask(widget.leadId);
    fetchSingleIdData(widget.leadId).then((_) {
      fetchCallLogs(mobile);
      // _fetchCallLogs();
      // _speech = stt.SpeechToText();
      // _initSpeech();
    });

    // Initially, set the selected widget
    _selectedTaskWidget = TimelineUpcoming(
      isFromTeams: false,
      tasks: upcomingTasks,
      upcomingEvents: upcomingEvents,
    );

    _selectedTaskWidget = timelineOverdue(
      tasks: overdueTasks,
      overdueEvents: overdueEvents,
      isFromTeams: false,
    );
    fabController = Get.put(
      FabController(),
      tag: 'followups_details_${widget.leadId}', // Unique tag
    );

    // Create page-specific scroll controller
    scrollController = ScrollController();
    scrollController.addListener(_handleScroll);
    // _callLogsWidget = TimelineEightWid(tasks: upcomingTasks, upcomingEvents: upcomingEvents);
  }

  @override
  void dispose() {
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();

    // Clean up the controller with the same tag
    Get.delete<FabController>(tag: 'followups_details_${widget.leadId}');

    super.dispose();
  }

  void _handleScroll() {
    if (!scrollController.hasClients) return;

    final currentScrollPosition = scrollController.offset;
    double lastScrollPosition = 0.0;
    final scrollDifference = (currentScrollPosition - lastScrollPosition).abs();

    if (scrollDifference < 10) return;

    // Hide FAB when scrolling down, show when scrolling up
    if (currentScrollPosition > lastScrollPosition &&
        currentScrollPosition > 50) {
      if (fabController.isFabVisible.value) {
        fabController.isFabVisible.value = false;
        if (fabController.isFabExpanded.value) {
          fabController.isFabExpanded.value = false;
        }
      }
    } else if (currentScrollPosition < lastScrollPosition) {
      if (!fabController.isFabVisible.value) {
        fabController.isFabVisible.value = true;
      }
    }

    lastScrollPosition = currentScrollPosition;
  }

  // Initialize speech recognition
  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (errorNotification) {
        setState(() {
          _isListening = false;
        });
        showErrorMessageGetx(
          message: 'Speech recognition error: ${errorNotification.errorMsg}',
        );
      },
    );
    if (!available) {
      showErrorMessageGetx(
        message: 'Speech recognition not available on this device',
      );
    }
  }

  // Check if there's any data to determine if buttons should be enabled
  bool areButtonsEnabled() {
    // Return true if any of the lists have data, false if all are empty
    return overdueTasks.isNotEmpty ||
        overdueEvents.isNotEmpty ||
        upcomingTasks.isNotEmpty ||
        upcomingEvents.isNotEmpty ||
        completedTasks.isNotEmpty ||
        completedEvents.isNotEmpty;
  }

  String _getFirstTwoLettersCapitalized(String input) {
    input = input.trim(); // Remove any extra spaces
    if (input.length >= 2) {
      return input.substring(0, 2).toUpperCase();
    } else if (input.isNotEmpty) {
      return input.toUpperCase();
    } else {
      return '';
    }
  }

  // Toggle listening
  void _toggleListening(TextEditingController controller) async {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            controller.text = result.recognizedWords;
          });
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(date);
      return DateFormat("d MMM").format(parsedDate); // Outputs "22 May"
    } catch (e) {
      print('Error formatting date: $e');
      return 'N/A';
    }
  }

  Future<void> fetchSingleIdData(String leadId) async {
    try {
      final leadData = await LeadsSrv.singleFollowupsById(leadId);
      setState(() {
        mobile = leadData['data']['mobile'] ?? 'N/A';
        chatId = leadData['data']['chat_id'] ?? 'N/A';
        email = leadData['data']['email'] ?? 'N/A';
        status = leadData['data']['status'] ?? 'N/A';
        company = leadData['data']['brand'] ?? 'N/A';
        address = leadData['data']['location'] ?? 'Not provided';
        leadSource = leadData['data']['lead_source'] ?? 'N/A';
        fuel_type = leadData['data']['fuel_type'] ?? 'N/A';
        lead_owner = leadData['data']['lead_owner'] ?? 'N/A';
        PMI = leadData['data']['PMI'] ?? 'N/A';
        purchase_type = leadData['data']['purchase_type'] ?? 'N/A';
        enquiry_type = leadData['data']['enquiry_type'] ?? 'N/A';
        expected_date_purchase =
            leadData['data']['expected_date_purchase'] ?? 'N/A';
        lead_name = leadData['data']['lead_name'] ?? 'N/A';
        pincode = leadData['data']['pincode']?.toString() ?? 'N/A';
        lead_status = leadData['data']['opp_status'] ?? 'Not Converted';
        vehicle_id = leadData['data']['vehicle_id'] ?? '';
        company_name = leadData['data']['company_name'] ?? 'No Company';
        for_company = leadData['data']['for_company'] ?? false;
      });
      print('api will call');
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  static Future<Map<String, int>> fetchCallLogs(String mobile) async {
    const String apiUrl =
        "https://api.smartassistapp.in/api/leads/call-logs/all";
    final token = await Storage.getToken();

    try {
      final encodedMobile = Uri.encodeComponent(mobile);

      final response = await http.get(
        Uri.parse(
          '$apiUrl?mobile=$encodedMobile',
        ), // Correct query parameter format
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse['data'];
        print('$apiUrl?mobile=$encodedMobile');
        final Map<String, dynamic> categoryCounts = data['category_counts'];

        // Update the class variable with the category counts
        _callLogs = {
          'all': categoryCounts['all'] ?? 0,
          'outgoing': categoryCounts['outgoing'] ?? 0,
          'incoming': categoryCounts['incoming'] ?? 0,
          'missed': categoryCounts['missed'] ?? 0,
          'rejected':
              categoryCounts['rejected'] ??
              0, // Added this as it's in your API response
        };
        return _callLogs;
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  List<Map<String, dynamic>> allEvents = [];
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> allTestdrive = [];

  Future<void> eventandtask(String leadId) async {
    setState(() => isLoading = true);
    try {
      print('this is fetch leadid ${widget.leadId}');
      // final data = await LeadsSrv.eventTaskByLead(leadId ,);
      final data = await LeadsSrv.eventTaskByLead(
        leadId,
        isFromSM: widget.isFromManager,
        userId: widget.spId,
      );

      setState(() {
        // Ensure that upcomingTasks and completedTasks are correctly cast to List<Map<String, dynamic>>.
        overdueTasks = List<Map<String, dynamic>>.from(data['overdueTasks']);
        overdueEvents = List<Map<String, dynamic>>.from(data['overdueEvents']);
        upcomingTasks = List<Map<String, dynamic>>.from(data['upcomingTasks']);

        overdueCount = overdueTasks.length + overdueEvents.length;

        upcomingEvents = List<Map<String, dynamic>>.from(
          data['upcomingEvents'],
        );
        completedTasks = List<Map<String, dynamic>>.from(
          data['completedTasks'],
        );
        completedEvents = List<Map<String, dynamic>>.from(
          data['completedEvents'],
        );

        // Now you can safely pass the upcomingTasks and completedTasks to the widgets.
        _selectedTaskWidget = TimelineUpcoming(
          isFromTeams: false,
          tasks: upcomingTasks,
          upcomingEvents: upcomingEvents,
        );
      });
    } catch (e) {
      print('Error Fetching events: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleTasks(int index) {
    setState(() {
      _childButtonIndex = index;
      if (index == 0) {
        // Show upcoming tasks
        _selectedTaskWidget = TimelineUpcoming(
          isFromTeams: false,
          tasks: upcomingTasks,
          upcomingEvents: upcomingEvents,
        );
      } else if (index == 1) {
        _selectedTaskWidget = TimelineCompleted(
          events: completedTasks,
          completedEvents: completedEvents,
        );
      } else {
        _selectedTaskWidget = timelineOverdue(
          tasks: overdueTasks,
          overdueEvents: overdueEvents,
          isFromTeams: false,
        );
      }
    });
  }

  // The method to show the toggle options (Upcoming / Completed)
  Widget _buildToggleOption(int index, String text, Color color) {
    final bool isActive = _childButtonIndex == index;
    return GestureDetector(
      onTap: () => _toggleTasks(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.2) // Light background when active
              : Colors.transparent, // Very light grey when inactive
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: .5,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: isActive ? 12 : 12,
            fontWeight: isActive ? FontWeight.w400 : FontWeight.w400,
            color: isActive ? color : Colors.grey,
          ),
        ),
      ),
    );
  }

  // Toggle switch to toggle between 'Upcoming' and 'Completed'
  Widget _buildToggleSwitch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleOption(0, 'Upcoming', AppColors.containerGreen),
        const SizedBox(width: 10),
        _buildToggleOption(1, 'Completed', AppColors.colorsBlue),
        const SizedBox(width: 10),
        _buildToggleOption(
          2,
          'Overdue ($overdueCount)',
          AppColors.containerRed,
        ),
      ],
    );
  }

  void _showFollowupPopup(BuildContext context, String leadId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add some margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FollowupsIds(
              leadId: leadId,
              onFormSubmit: eventandtask,
              onSubmitStatus: fetchSingleIdData,
            ),
          ),
        );
      },
    );
  }

  void _showAppointmentPopup(BuildContext context, String leadId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Remove default padding
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppointmentIds(
              leadId: leadId,
              onFormSubmit: eventandtask,
            ), // Appointment modal
          ),
        );
      },
    );
  }

  void _showTestdrivePopup(BuildContext context, String leadId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Remove default padding
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TestdriveIds(
              leadId: leadId,
              vehicle_id: vehicle_id,
              PMI: PMI,
              onFormSubmit: eventandtask,
            ), // Appointment modal
          ),
        );
      },
    );
  }

  // ✅ Function to Convert 24-hour Time to 12-hour Format
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'N/A';

    try {
      DateTime parsedTime = DateFormat("HH:mm").parse(time);
      return DateFormat("hh:mm").format(parsedTime);
    } catch (e) {
      print("Error formatting time: $e");
      return 'Invalid Time';
    }
  }

  // Helper method to build ContactRow widget
  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ContactRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      taskId: widget.leadId,
    );
  }

  Widget _callLogsWidget(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // All Calls
          _buildRow('All calls', _callLogs['all'] ?? 0, '', Icons.call),

          // Outgoing Calls
          _buildRow(
            'Outgoing calls',
            _callLogs['outgoing'] ?? 0,
            'outgoing',
            Icons.phone_forwarded_outlined,
          ),

          // Incoming Calls
          _buildRow(
            'Incoming calls',
            _callLogs['incoming'] ?? 0,
            'incoming',
            Icons.call,
          ),

          // Missed Calls
          _buildRow(
            'Missed calls',
            _callLogs['missed'] ?? 0,
            'missed',
            Icons.call_missed,
          ),
        ],
      ),
    );
  }

  // Helper method to build each row with dynamic values
  Widget _buildRow(String title, int count, String category, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, size: 25, color: _getIconColor(category)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.1),
        Text(title, style: AppFont.dropDowmLabel(context)),
        Expanded(child: Container()),
        Text(
          '$count', // Use dynamic value
          style: AppFont.dropDowmLabel(context),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CallHistory(category: category, mobile: mobile),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 25,
            color: AppColors.iconGrey,
          ),
        ),
      ],
    );
  }

  // Helper method to get icon color based on category
  Color _getIconColor(String category) {
    switch (category) {
      case 'outgoing':
        return AppColors.colorsBlue;
      case 'incoming':
        return AppColors.sideGreen;
      case 'missed':
        return AppColors.sideRed;
      case 'rejected':
        return AppColors.iconGrey;
      default:
        return AppColors.iconGrey;
    }
  }

  bool isFabExpanded = false;

  // API call methods
  void handleFabAction() {
    // Your FAB API call logic here
    print('FAB action triggered - API call would happen here');
  }

  void handleLostAction() {
    _showLostDiolog();
    print('Lost API call triggered');
  }

  Future<void> _showLostDiolog() async {
    // Reset the selected reason when dialog opens
    widget.selectedLostReason = null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Add StatefulBuilder to update dialog state
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(10),
              contentPadding: EdgeInsets.zero,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      textAlign: TextAlign.left,
                      'If you wish to mark this enquiry as lost, please provide a reason',
                      style: AppFont.mediumText14(context),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: EnhancedSpeechTextField(
                      isRequired: true,
                      error: false,
                      label: 'Remarks:',
                      controller: descriptionController,
                      hint: 'Type or speak... ',
                      onChanged: (text) {
                        print('Text changed: $text');
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DropdownButtonFormField<String>(
                      value: widget.selectedLostReason, // Bind to the variable
                      decoration: InputDecoration(
                        labelText: 'Select Reason',
                        labelStyle: TextStyle(
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          color: Colors.grey[600],
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: MediaQuery.of(context).size.height * 0.017,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.w400,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[600],
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'bought_competitor',
                          child: Text(
                            'Bought competitor',
                            style: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color: Colors.grey.shade800,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'duplicate_lead',
                          child: Text(
                            'Duplicate lead',
                            style: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color: Colors.grey.shade800,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'no_intention',
                          child: Text(
                            'No intention to buy',
                            style: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color: Colors.grey.shade800,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'unable_to_contact',
                          child: Text(
                            'Unable to contact',
                            style: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color: Colors.grey.shade800,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          widget.selectedLostReason = value;
                        });
                        print('Dropdown changed: $value');
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: AppFont.mediumText14blue(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Validate both fields
                    if (descriptionController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please provide remarks before marking as lost',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    } else if (widget.selectedLostReason == null) {
                      Get.snackbar(
                        'Error',
                        'Please select a reason before marking as lost',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    } else {
                      submitLost(context);
                    }
                  },
                  child: Text(
                    'Submit',
                    style: AppFont.mediumText14blue(context),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateLeads() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? spId = prefs.getString('user_id');

      if (spId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found. Please log in again.'),
            ),
          );
        }
        throw Exception('User ID not found');
      }

      final leadData = {
        'company_name': companynameController.text,
        'for_company': true,
      };
      final token = await Storage.getToken();

      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/leads/update/${widget.leadId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(leadData),
      );

      print('Response body: ${response.body}');
      print('Response status: ${response.statusCode}');
      print(leadData);

      // Check for both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message =
            responseData['message'] ?? 'Company updated successfully!';

        // Update the local company_name variable
        setState(() {
          company_name = companynameController.text;
        });

        // showSuccessMessage(context, message: message);
        Get.snackbar(
          'Success',
          message,
          colorText: Colors.white,
          backgroundColor: Colors.green.shade500,
        );
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message = responseData['message'] ?? 'Update failed. Try again.';
        showErrorMessageGetx(message: message);
        throw Exception(message);
      }
    } catch (e) {
      // showErrorMessageGetx(message: 'Something went wrong. Please try again.');
      print('Error during PUT request: $e');
      // throw e; // Re-throw to handle in the calling function
    }
  }

  void _mailAction() {
    print("Mail action triggered");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          child: LeadUpdate(
            onFormSubmit: fetchSingleIdData,
            leadId: widget.leadId,
            onEdit: () {},
          ),
        );
      },
    );
  }

  Future<void> submitLost(BuildContext context) async {
    setState(() {
      // _isUploading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? spId = prefs.getString('user_id');
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/leads/mark-lost/${widget.leadId}',
      );
      final token = await Storage.getToken();

      // Create the request body with the selected reason
      final requestBody = {
        'sp_id': spId,
        'lost_remarks': descriptionController.text,
        'lost_reason':
            widget.selectedLostReason, // Use the selected dropdown value
      };

      // Print the data to console for debugging
      print('Submitting lost lead data:');
      print(requestBody);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      // Print the response
      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final successMessage =
            json.decode(response.body)['message'] ??
            'Lead marked as lost successfully';

        print('Lead marked as lost successfully');
        Get.snackbar(
          'Success',
          successMessage,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.pop(context);

        // Refresh the data after successful submission
        await fetchSingleIdData(widget.leadId);
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error';
        print('Failed to mark lead as lost');
        Get.snackbar(
          'Error',

          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Exception occurred: ${e.toString()}');
    } finally {
      setState(() {
        // _isUploading = false;
      });
    }
  }

  void toggleFab() {
    setState(() {
      isFabExpanded = !isFabExpanded;
    });
  }

  // vishal.iswalkar@navnitmotors.com
  Future<void> _showSkipDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(10),
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  textAlign: TextAlign.center,
                  'Are you sure you want to qualify this lead to an opportunity?',
                  style: AppFont.mediumText14(context),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                // style: TextStyle(color: AppColors.colorsBlue),
                style: AppFont.mediumText14blue(context),
              ),
            ),
            TextButton(
              onPressed: () {
                submitQualify(context); // Pass context to submit
              },
              child: Text('Submit', style: AppFont.mediumText14blue(context)),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _showSkipDialog() async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext dialogContext) {
  //       bool showCompanyField = false;
  //       bool isLoading = false;
  //       bool isApiSuccess = false; // Track if API call was successful
  //       bool hasEdited = false; // Track if user has edited the field
  //       String initialCompanyValue = ''; // Store initial value

  //       return StatefulBuilder(
  //         builder: (BuildContext context, void Function(void Function()) setState) {
  //           return AlertDialog(
  //             titlePadding: EdgeInsets.zero,
  //             insetPadding: EdgeInsets.symmetric(horizontal: 10),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             backgroundColor: Colors.white,
  //             contentPadding: EdgeInsets.zero,
  //             title: Container(
  //               padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       Align(
  //                         alignment: Alignment.bottomLeft,
  //                         child: Text(
  //                           'Qualify as individual account ?',
  //                           style: AppFont.mediumText14(context),
  //                         ),
  //                       ),
  //                       Align(
  //                         alignment: Alignment.centerRight,
  //                         child: IconButton(
  //                           onPressed: () => Get.back(),
  //                           icon: const Icon(Icons.close),
  //                         ),
  //                       ),
  //                     ],
  //                   ),

  //                   if (showCompanyField) ...[
  //                     const SizedBox(height: 10),
  //                     _buildTextField(
  //                       isRequired: true,
  //                       label: 'Company',
  //                       controller: companynameController,
  //                       hintText: 'Company',
  //                       errorText: _errors['company'],
  //                       isLoading: isLoading,
  //                       isSuccess: isApiSuccess,
  //                       hasEdited: hasEdited,
  //                       initialValue: initialCompanyValue,
  //                       onChanged: (value) {
  //                         if (value.isNotEmpty &&
  //                             _errors.containsKey('company')) {
  //                           setState(() {
  //                             _errors.remove('company');
  //                           });
  //                         }
  //                         // Check if user has edited the field
  //                         setState(() {
  //                           hasEdited = value != initialCompanyValue;
  //                           if (hasEdited) {
  //                             isApiSuccess =
  //                                 false; // Reset API success if user edits again
  //                           }
  //                         });
  //                       },
  //                       onIconPressed: () async {
  //                         if (isLoading || isApiSuccess) return;

  //                         if (companynameController.text.trim().isEmpty) {
  //                           setState(() {
  //                             _errors['company'] = 'Company field is required';
  //                           });
  //                           return;
  //                         }

  //                         setState(() {
  //                           isLoading = true;
  //                           _errors.remove('company');
  //                         });

  //                         try {
  //                           await updateLeads();
  //                           setState(() {
  //                             isLoading = false;
  //                             isApiSuccess = true;
  //                             hasEdited =
  //                                 false; // Reset edit state after successful API call
  //                             initialCompanyValue = companynameController
  //                                 .text; // Update initial value
  //                           });
  //                         } catch (e) {
  //                           setState(() {
  //                             isLoading = false;
  //                             isApiSuccess = false;
  //                           });
  //                         }
  //                       },
  //                       onClearPressed: () {
  //                         setState(() {
  //                           companynameController.clear();
  //                           _errors.remove('company');
  //                           isApiSuccess = false;
  //                           hasEdited =
  //                               true; // Field is now different from initial value
  //                         });
  //                       },
  //                     ),
  //                   ],
  //                   const SizedBox(height: 10),
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   setState(() {
  //                     showCompanyField = true;
  //                     // Pre-fill the company field with existing data if available
  //                     if (company_name != null &&
  //                         company_name!.isNotEmpty &&
  //                         company_name != 'No Company') {
  //                       companynameController.text = company_name!;
  //                       initialCompanyValue = company_name!;
  //                     } else {
  //                       companynameController.clear();
  //                       initialCompanyValue = '';
  //                     }
  //                     hasEdited = false;
  //                     isApiSuccess = false;
  //                   });
  //                 },
  //                 child: Text('No', style: AppFont.mediumText14blue(context)),
  //               ),
  //               // Show "Yes" button when showCompanyField is true
  //               if (showCompanyField) ...[
  //                 TextButton(
  //                   onPressed: (isApiSuccess && !hasEdited)
  //                       ? () {
  //                           submitQualify(context);
  //                         }
  //                       : (!hasEdited && !isApiSuccess)
  //                       ? () {
  //                           // Show snackbar when text field is not edited
  //                           Get.snackbar(
  //                             'Edit Required',
  //                             'Please edit the textfield first',
  //                             // snackPosition: SnackPosition.BOTTOM,
  //                             backgroundColor: Colors.orange,
  //                             colorText: Colors.white,
  //                             duration: Duration(seconds: 2),
  //                           );
  //                         }
  //                       : null, // Disable if hasEdited is true but API not successful
  //                   child: Text(
  //                     'Yes',
  //                     style: (isApiSuccess && !hasEdited)
  //                         ? AppFont.mediumText14blue(context) // Active state
  //                         : GoogleFonts.poppins(
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.grey, // Disabled state
  //                           ),
  //                   ),
  //                 ),
  //               ],
  //               // Show "Ok" button if showCompanyField is false (normal flow)
  //               if (!showCompanyField) ...[
  //                 TextButton(
  //                   onPressed: () {
  //                     submitQualify(context);
  //                   },
  //                   child: Text('Ok', style: AppFont.mediumText14blue(context)),
  //                 ),
  //               ],
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    String? errorText,
    VoidCallback? onIconPressed,
    VoidCallback? onClearPressed,
    bool isLoading = false,
    bool isSuccess = false,
    bool hasEdited = false,
    String initialValue = '',
  }) {
    // Determine if the done icon should be clickable
    bool isDoneClickable =
        controller.text.trim().isNotEmpty &&
        (hasEdited || (!hasEdited && !isSuccess));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: label),
                if (isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: const Color.fromARGB(255, 248, 247, 247),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              minLines: 1,
              maxLines: 10,
              controller: controller,
              style: AppFont.dropDowmLabel(context),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: InputBorder.none,
                suffixIcon: onIconPressed != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show close icon when field has content and not in loading/success state
                          if (controller.text.isNotEmpty &&
                              !isLoading &&
                              !isSuccess &&
                              onClearPressed != null)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.grey),
                              onPressed: onClearPressed,
                            ),
                          // Show different icons based on state
                          if (isLoading)
                            Container(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.colorsBlue,
                                ),
                              ),
                            )
                          else if (isSuccess)
                            Container(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.done,
                                color: isDoneClickable
                                    ? AppColors.colorsBlue
                                    : Colors.grey,
                              ),
                              onPressed: isDoneClickable ? onIconPressed : null,
                            ),
                        ],
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        // Show error text if exists
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> submitQualify(BuildContext context) async {
    setState(() {
      // _isUploading = true; // If you are showing any loading indicator
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? spId = prefs.getString('user_id');
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/leads/convert-to-opp/${widget.leadId}',
      );
      final token = await Storage.getToken();

      // Create the request body
      final requestBody = {'sp_id': spId};

      // Print the data to console for debugging
      print('Submitting feedback data:');
      print(requestBody);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      // Print the response
      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 201) {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error';
        // Success handling
        print('Feedback submitted successfully');
        Get.snackbar(
          'Success',
          errorMessage,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.pop(context); // Dismiss the dialog after success
        await fetchSingleIdData(widget.leadId);
      } else {
        // Error handling
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error';
        print('Failed to submit feedback');
        Get.snackbar(
          'Error',
          errorMessage, // Show the backend error message
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Navigator.pop(context); // Dismiss the dialog on error
      }
    } catch (e) {
      // Exception handling
      print('Exception occurred: ${e.toString()}');
      Get.snackbar(
        'Error',
        'An error occurred: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Navigator.pop(context); // Dismiss the dialog on exception
    } finally {
      setState(() {
        // _isUploading = false; // Reset loading state
      });
    }
  }

  void handleQualifyAction() {
    _showSkipDialog();
    // API call for Qualify tab
    print('Qualify API call triggered');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.backgroundLightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.colorsBlue,
        // title: Text('Enquiry', style: AppFont.appbarfontWhite(context)),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enquiry', style: AppFont.appbarfontWhite(context)),
              Text(
                'Opportunity Status : $lead_status',
                style: AppFont.smallTextWhite1(context),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppColors.white,
          ),
          onPressed: () {
            // Navigator.pop(context, true);
            if (widget.isFromTestdriveOverview == true) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BottomNavigation()),
              );
            } else {
              Navigator.pop(context);
              widget.refreshDashboard();
            }
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => BottomNavigation()),
            // );
          },
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Scaffold(
            body: Container(
              width: double.infinity, // ✅ Ensures full width
              height: double.infinity,
              decoration: BoxDecoration(color: AppColors.backgroundLightGrey),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        // Main Container with Flexbox Layout
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Profile Section (Icon, Name, Divider, Gmail, Car Name)
                              Row(
                                children: [
                                  // Profile Icon and Name
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        0,
                                        255,
                                        255,
                                        255,
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      Icons.person_search,
                                      size: 40,
                                      color: AppColors.colorsBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      // mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                textAlign: TextAlign.left,
                                                lead_name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                          ],
                                        ),
                                        Text(
                                          PMI,
                                          maxLines: 4,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (!widget.isFromManager)
                                        IconButton(
                                          onPressed: () {
                                            _mailAction();
                                            // setState(() {
                                            //   _isHiddenTop = !_isHiddenTop;
                                            // });
                                          },
                                          icon: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: AppColors.iconGrey,
                                          ),
                                        ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isHiddenTop = !_isHiddenTop;
                                          });
                                        },
                                        icon: Icon(
                                          _isHiddenTop
                                              ? Icons
                                                    .keyboard_arrow_down_rounded
                                              : Icons.keyboard_arrow_up_rounded,
                                          size: 35,
                                          color: AppColors.iconGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // Contact Details Section (Phone, Company, Address)
                              if (!_isHiddenTop) ...[
                                const Divider(thickness: 0.5),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    // Left Section: Phone Number and Company
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.phone,
                                        title: 'Mobile',
                                        subtitle: mobile,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.location_on,
                                        title: 'Location',
                                        subtitle: address,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.question_mark_rounded,
                                        title: 'Status',
                                        subtitle:
                                            status, // Replace with the actual address variable
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.wechat_rounded,
                                        title: 'Source',
                                        subtitle:
                                            leadSource, // Replace with the actual address variable
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Left Section: Phone Number and Company
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.email_outlined,
                                        title: 'Email',
                                        subtitle: email,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.directions_car,
                                        title: 'Brand',
                                        subtitle: company,
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    // Left Section: Phone Number and Company
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.calendar_month,
                                        title: 'Expected purchase date',
                                        subtitle: formatDate(
                                          expected_date_purchase,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildContactRow(
                                        icon: Icons.person_search,
                                        title: 'Enquiry type',
                                        subtitle: enquiry_type,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Assignee',
                                          style: AppFont.mediumText14(context),
                                        ),
                                        const SizedBox(width: 10),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            color: AppColors.homeContainerLeads,
                                          ),
                                          child: Text(
                                            lead_owner,
                                            style: AppFont.mediumText14blue(
                                              context,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10), // Spacer
                        // History Section
                        // Text('hiii'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLightGrey,
                                      border: Border.all(
                                        color: AppColors.iconGrey,
                                        width: .5,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: _buildToggleSwitch(),
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
                                      size: 35,
                                      color: AppColors.iconGrey,
                                    ),
                                  ),
                                ],
                              ),

                              // Show only if _isHidden is false
                              if (!_isHidden) ...[
                                //  i want to show here the timeline eight and nine
                                // and nine data
                                _selectedTaskWidget,
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // _buildToggleSwitch(),
                                  Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLightGrey,
                                      border: Border.all(
                                        color: AppColors.iconGrey,
                                        width: .5,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF1380FE,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            border: Border.all(
                                              color: Color(
                                                0xFF1380FE,
                                              ), // Border color
                                              width: .5,
                                            ),
                                          ),
                                          child: Text(
                                            'Call logs',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.colorsBlue,
                                            ),
                                          ),
                                        ),
                                        if (!widget.isFromManager)
                                          Tooltip(
                                            // decoration: BoxDecoration(),
                                            message: 'Send message WhatsApp',
                                            child: TextButton(
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                ),
                                              ),
                                              onPressed: () async {
                                                Get.to(
                                                  WhatsappChat(
                                                    chatId: chatId,
                                                    userName: lead_name,
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'Whatsapp',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isHiddenMiddle = !_isHiddenMiddle;
                                      });
                                    },
                                    icon: Icon(
                                      _isHiddenMiddle
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_up_rounded,
                                      size: 35,
                                      color: AppColors.iconGrey,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isHiddenMiddle) ...[
                                _callLogsWidget(context),
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
          ),

          // Floating Action Button
          Obx(
            () => fabController.isFabExpanded.value
                ? _buildPopupMenu(context)
                : SizedBox.shrink(),
          ),
        ],
      ),
      // floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: widget.isFromManager
          ? null
          : SafeArea(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Lost Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _showFollowupPopup(context, widget.leadId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.colorsBlue,
                                // Green color from image
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Follow up?',
                                style: AppFont.mediumText14White(context),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Qualify Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (areButtonsEnabled()) {
                                handleQualifyAction();
                              } else {
                                showTaskRequiredDialog(context);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF35CB64),
                                // Green color from image
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Qualify',
                                style: AppFont.mediumText14white(context),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          height: 45,
                          child: _buildFloatingActionButton(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // FAB Builder
  Widget _buildFloatingActionButton(BuildContext context) {
    return Obx(
      () => GestureDetector(
        // onTap: fabController.toggleFab,
        onTap: fabController.isFabDisabled.value
            ? null // Disable onTap if FAB is disabled
            : fabController.toggleFab,
        child: AnimatedContainer(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          duration: const Duration(milliseconds: 300),
          width: MediaQuery.of(context).size.width * .15,
          height: MediaQuery.of(context).size.height * .08,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              width: 1,
              color: fabController.isFabDisabled.value
                  ? Colors
                        .grey // Grey when disabled
                  : (fabController.isFabExpanded.value
                        ? Colors.red
                        : AppColors.colorsBlue),
            ),
            // color: fabController.isFabExpanded.value
            //     ? Colors.red
            //     : AppColors.colorsBlue,
            shape: BoxShape.rectangle,
          ),
          child: Center(
            child: AnimatedRotation(
              turns: fabController.isFabExpanded.value ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                fabController.isFabExpanded.value ? Icons.close : Icons.add,
                color: fabController.isFabDisabled.value
                    ? Colors
                          .grey // Grey when disabled
                    : (fabController.isFabExpanded.value
                          ? Colors.red
                          : AppColors.colorsBlue),
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to show dialog when disabled buttons are clicked
  void showTaskRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(10),
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  textAlign: TextAlign.center,
                  'Perform atleast one follow up qualifying this enquiry.',
                  style: AppFont.mediumText14(context),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Ok',
                // style: TextStyle(color: AppColors.colorsBlue),
                style: AppFont.mediumText14blue(context),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show dialog when disabled buttons are clicked
  void showLostRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(10),
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  textAlign: TextAlign.center,
                  'Cannot mark this Enquiry as lost without performing any actions ',
                  style: AppFont.mediumText14(context),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Ok',
                // style: TextStyle(color: AppColors.colorsBlue),
                style: AppFont.mediumText14blue(context),
              ),
            ),
          ],
        );
      },
    );
  }

  // Popup Menu Builder
  Widget _buildPopupMenu(BuildContext context) {
    return GestureDetector(
      onTap: fabController.closeFab,
      child: Stack(
        children: [
          // Background overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),

          // Popup Items Container aligned bottom right
          Positioned(
            bottom: 20,
            right: 20,
            child: SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPopupItem(
                    Icons.calendar_month_outlined,
                    "Appointment",
                    -80,
                    onTap: () {
                      fabController.closeFab();
                      _showAppointmentPopup(context, widget.leadId);
                    },
                  ),
                  _buildPopupItem(
                    Icons.directions_car,
                    "Test Drive",
                    -20,
                    onTap: () {
                      fabController.closeFab();
                      _showTestdrivePopup(context, widget.leadId);
                    },
                  ),
                  _buildPopupItem(
                    Icons.trending_down_sharp,
                    "Lost",
                    -40,
                    onTap: () {
                      fabController.closeFab();
                      handleLostAction();
                      // _showFollowupPopup(context, widget.leadId);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Popup Item Builder
  Widget _buildPopupItem(
    IconData icon,
    String label,
    double offsetY, {
    required Function() onTap,
  }) {
    return Obx(
      () => TweenAnimationBuilder(
        tween: Tween<double>(
          begin: 0,
          end: fabController.isFabExpanded.value ? 1 : 0,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ContactRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String taskId;

  const ContactRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.taskId,
  });

  @override
  State<ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<ContactRow> {
  String phoneNumber = 'Loading...';
  String email = 'Loading...';
  String status = 'Loading...';
  String company = 'Loading...';
  String address = 'Loading...';
  String lead_owner = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchSingleIdData(widget.taskId); // Fetch data when widget is initialized
  }

  Future<void> fetchSingleIdData(String taskId) async {
    try {
      final leadData = await LeadsSrv.singleFollowupsById(taskId);
      setState(() {
        phoneNumber = leadData['data']['mobile'] ?? 'N/A';
        email = leadData['data']['lead_email'] ?? 'N/A';
        status = leadData['data']['status'] ?? 'N/A';
        company = leadData['data']['PMI'] ?? 'N/A';
        address = leadData['data']['address'] ?? 'N/A';
        lead_owner = leadData['data']['lead_owner'] ?? 'N/A';
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text at the top
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 241, 248, 255),
            ),
            child: Icon(widget.icon, size: 25, color: AppColors.colorsBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.fontColor,
                  ),
                ),
                // const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.fontBlack,
                  ),
                  softWrap: true, // Allows text wrapping
                  overflow: TextOverflow.visible, // Ensures no cutoff
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationController extends GetxController {
  final RxBool isFabExpanded = false.obs;

  void toggleFab() {
    // Add a slight delay to ensure smooth animation
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.lightImpact();
      isFabExpanded.toggle();
    });
  }
}
