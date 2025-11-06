import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/reusable/action_button.dart';
import 'package:smartassist/widgets/reusable/date_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FollowupsIds extends StatefulWidget {
  final Function onFormSubmit;
  final String leadId;
  // final String onSubmitStatus;
  final Future<void> Function(String) onSubmitStatus;

  const FollowupsIds({
    super.key,
    required this.leadId,
    required this.onFormSubmit,
    required this.onSubmitStatus,
  });

  @override
  State<FollowupsIds> createState() => _FollowupsIdsState();
}

class _FollowupsIdsState extends State<FollowupsIds> {
  Map<String, String> _errors = {};
  bool isSubmitting = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  TextEditingController modelInterestController = TextEditingController();

  TextEditingController startTimeController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  // final TextEditingController descriptionController = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _isLoadingSearch = false;
  String _query = '';
  String? selectedLeads;
  String? selectedLeadsName;
  String _selectedSubject = '';
  String? selectedStatus;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    print(widget.leadId);
    _speech = stt.SpeechToText();
    _initSpeech();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        showErrorMessage(
          context,
          message: 'Speech recognition error: ${errorNotification.errorMsg}',
        );
      },
    );
    if (!available) {
      showErrorMessage(
        context,
        message: 'Speech recognition not available on this device',
      );
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

  /// Fetch search results from API
  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
    });

    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.smartassistapp.in/api/search/global?query=$query',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data['data']['suggestions'] ?? [];
        });
      }
    } catch (e) {
      showErrorMessage(context, message: 'Something went wrong..!');
    } finally {
      setState(() {
        _isLoadingSearch = false;
      });
    }
  }

  /// Handle search input change
  void _onSearchChanged() {
    final newQuery = _searchController.text.trim();
    if (newQuery == _query) return;

    _query = newQuery;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_query == _searchController.text.trim()) {
        _fetchSearchResults(_query);
      }
    });
  }

  /// Open date picker
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        _errors.remove('');
      });
    }
  }

  Future<void> _pickStartDate() async {
    FocusScope.of(context).unfocus();

    // Get current start date or use today
    DateTime initialDate;
    try {
      if (startDateController.text.isNotEmpty) {
        initialDate = DateFormat('dd MMM yyyy').parse(startDateController.text);
      } else {
        initialDate = DateTime.now();
      }
    } catch (e) {
      initialDate = DateTime.now();
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);

      setState(() {
        // Set start date
        startDateController.text = formattedDate;

        // Set end date to the same as start date but not visible in the UI
        // (Only passed to API)
        endDateController.text = formattedDate;
      });
    }
  }

  Future<void> _pickStartTime() async {
    FocusScope.of(context).unfocus();

    // Get current time from startTimeController or use current time
    TimeOfDay initialTime;
    try {
      if (startTimeController.text.isNotEmpty) {
        final parsedTime = DateFormat(
          'hh:mm a',
        ).parse(startTimeController.text);
        initialTime = TimeOfDay(
          hour: parsedTime.hour,
          minute: parsedTime.minute,
        );
      } else {
        initialTime = TimeOfDay.now();
      }
    } catch (e) {
      initialTime = TimeOfDay.now();
    }

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      // Create a temporary DateTime to format the time
      final now = DateTime.now();
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      String formattedTime = DateFormat('hh:mm a').format(time);

      // Calculate end time (1 hour later)
      final endHour = (pickedTime.hour + 1) % 24;
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        endHour,
        pickedTime.minute,
      );
      String formattedEndTime = DateFormat('hh:mm a').format(endTime);

      setState(() {
        // Set start time
        startTimeController.text = formattedTime;

        // Set end time to 1 hour later but not visible in the UI
        // (Only passed to API)
        endTimeController.text = formattedEndTime;
      });
    }
  }

  void _submit() async {
    if (isSubmitting) return;

    bool isValid = true;

    setState(() {
      isSubmitting = true;
      _errors = {};

      // if (_leadId == null || _leadId!.isEmpty) {
      //   _errors['select lead name'] = 'Please select a lead name';
      //   isValid = false;
      // }

      if (_selectedSubject == null || _selectedSubject!.isEmpty) {
        _errors['subject'] = 'Please select an action';
        isValid = false;
      }

      if (startDateController == null || startDateController.text!.isEmpty) {
        _errors['date'] = 'Please select an action';
        isValid = false;
      }

      if (startDateController.text.isEmpty) {
        _errors['date'] = 'Please select a date';
        isValid = false;
      }

      if (startTimeController.text.isEmpty) {
        _errors['time'] = 'Please select a time';
        isValid = false;
      }
    });

    // 💡 Check validity before calling the API
    if (!isValid) {
      setState(() => isSubmitting = false);
      return;
    }

    try {
      await submitForm(); // ✅ Only call if valid
      // Show snackbar or do post-submit work here
    } catch (e) {
      Get.snackbar(
        'Error',
        'Submission failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.fontBlack,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.containerBg,
          ),
          child: Row(
            children: [
              // Expanded TextField that adjusts height
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines:
                      null, // This allows the TextField to expand vertically based on content
                  minLines: 1, // Minimum 1 line of height
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              // Microphone icon with speech recognition
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _toggleListening(controller),
                  icon: Icon(
                    _isListening
                        ? FontAwesomeIcons.stop
                        : FontAwesomeIcons.microphone,
                    color: _isListening ? Colors.red : AppColors.fontColor,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Submit form
  Future<void> submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? spId = prefs.getString('user_id');

    if (spId == null) {
      showErrorMessage(
        context,
        message: 'User ID not found. Please log in again.',
      );
      return;
    }
    final rawStartDate = DateFormat(
      'dd MMM yyyy',
    ).parse(startDateController.text);
    final rawStartTime = DateFormat('hh:mm a').parse(startTimeController.text);

    final formattedStartDate = DateFormat('dd-MM-yyyy').format(rawStartDate);

    // final formattedStartTime = DateFormat('HH:mm:ss').format(rawStartTime);

    final formattedStartTime = DateFormat('hh:mm a').format(rawStartTime);

    final newTaskForLead = {
      'subject': _selectedSubject,
      'status': 'Not Started',
      'priority': 'High',
      'time': formattedStartTime,
      'due_date': formattedStartDate,
      'remarks': descriptionController.text,
      'sp_id': spId,
      'lead_id': widget.leadId,
    };

    bool success = await LeadsSrv.submitFollowups(
      newTaskForLead,
      widget.leadId,
      context,
    );

    // print(s)

    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow up created !', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior:
              SnackBarBehavior.floating, // Optional: Makes it float above UI
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10,
            ), // Optional: rounded corners
          ),
        ),
      );
      widget.onFormSubmit(widget.leadId);
      widget.onSubmitStatus(widget.leadId);

      Navigator.pop(context, true);
    } else {
      showErrorMessage(context, message: 'Submission failed. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan a Follow up',
                  style: AppFont.popupTitleBlack(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ActionButton(
              label: "Action:",
              isRequired: true,
              options: {
                "Call": "Call",
                'Provide quotation': "Provide Quotation",
                "Send Email": "Send Email",
                "Send SMS": "Send SMS",
              },
              groupValue: _selectedSubject,
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                  if (_errors.containsKey('subject')) {
                    _errors.remove('subject');
                  }
                });
              },
              errorText: _errors['subject'],
            ),

            const SizedBox(height: 10),

            DateButton(
              // errorText: _errors['date'],
              isRequired: true,
              label: 'When?',
              dateController: startDateController,
              timeController: startTimeController,
              onDateTap: _pickStartDate,
              onTimeTap: _pickStartTime,
              onChanged: (String value) {},
              dateErrorText: _errors['date'],
              timeErrorText: _errors['time'],
            ),
            // _buildSearchField(),
            // const SizedBox(height: 10),
            // _buildDatePicker(
            //   label: 'Select date:',
            //   controller: dateController,
            //   errorText: _errors['date'],
            //   onTap: _pickDate,
            // ),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.start,
            //   children: [
            //     _selectedInput(
            //       label: "Priority:",
            //       options: ["High"],
            //     ),
            //   ],
            // ),
            // _buildButtons(
            //   label: 'Action:',
            //   // options: ['Call', 'Provide Quotation', 'Send Email'],
            //   options: {
            //     "Call": "Call",
            //     'Provide quotation': "Provide Quotation",
            //     "Send Email": "Send Email",
            //     "Send SMS": "Send SMS",
            //   },
            //   groupValue: _selectedSubject,
            //   onChanged: (value) {
            //     setState(() {
            //       _selectedSubject = value;
            //     });
            //   },
            // ),

            // _buildTextField(
            //   label: 'Comments:',
            //   controller: descriptionController,
            //   hint: 'Type or speak...',
            // ),
            EnhancedSpeechTextField(
              isRequired: false,
              error: false,
              // contentPadding: EdgeInsets.zero,
              label: 'Remarks:',
              controller: descriptionController,
              hint: 'Type or speak... ',
              onChanged: (text) {
                print('Text changed: $text');
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.innerContainerBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      textAlign: TextAlign.center,
                      style: AppFont.buttons(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.colorsBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text("Create", style: AppFont.buttons(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedInput({
    required String label,
    required List<String> options,
  }) {
    return Flexible(
      // Use Flexible instead of Expanded
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
            child: Text(label, style: AppFont.dropDowmLabel(context)),
          ),
          const SizedBox(height: 3),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                constraints: const BoxConstraints(minWidth: 50),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: AppColors.containerBg,
                ),
                child: Text(option, style: AppFont.dropDown(context)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(5.0, 0, 0, 5),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.fontBlack,
            ),
          ),
        ),
        // const SizedBox(height: 2),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 45,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              // color: AppColors.containerPopBg,
              border: errorText != null
                  ? Border.all(color: Colors.redAccent)
                  : Border.all(color: Colors.black, width: .5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? "DD / MM / YY" : controller.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: controller.text.isEmpty
                          ? AppColors.fontColor
                          : AppColors.fontColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month,
                  color: AppColors.fontColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildTextField({
  //   required String label,
  //   required TextEditingController controller,
  //   required String hint,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 5.0),
  //         child: Text(
  //           label,
  //           style: GoogleFonts.poppins(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w500,
  //             color: AppColors.fontBlack,
  //           ),
  //         ),
  //       ),
  //       Container(
  //         width: double.infinity,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(5),
  //           color: AppColors.containerBg,
  //         ),
  //         child: Row(
  //           children: [
  //             // TextField itself
  //             Expanded(
  //               child: TextField(
  //                 controller: controller,
  //                 decoration: InputDecoration(
  //                   hintText: hint,
  //                   hintStyle: GoogleFonts.poppins(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w500,
  //                     color: Colors.grey,
  //                   ),
  //                   contentPadding: const EdgeInsets.symmetric(horizontal: 10),
  //                   border: InputBorder.none,
  //                 ),
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.black,
  //                 ),
  //               ),
  //             ),
  //             // Suffix icon (microphone)
  //             TextButton(
  //               onPressed: () {},
  //               child: const Align(
  //                 alignment: Alignment.centerRight,
  //                 child: Icon(
  //                   FontAwesomeIcons.microphone,
  //                   color: AppColors.fontColor,
  //                   size: 16, // Adjust the size for better alignment
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Lead', style: AppFont.dropDowmLabel(context)),
        const SizedBox(height: 5),
        Container(
          height: MediaQuery.of(context).size.height * 0.055,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.containerBg,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.containerBg,
                    hintText: selectedLeadsName ?? 'Type name, email or phone',
                    hintStyle: TextStyle(
                      color: selectedLeadsName != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 15,
                      color: AppColors.fontColor,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.microphone,
                        color: AppColors.fontColor,
                        size: 15,
                      ),
                      onPressed: () {
                        print('Microphone button pressed');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show loading indicator
        if (_isLoadingSearch)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Show search results
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  onTap: () {
                    setState(() {
                      FocusScope.of(context).unfocus();
                      selectedLeads = result['lead_id'];
                      selectedLeadsName = result['lead_name'];
                      _searchController.clear();
                      _searchResults.clear();
                    });
                  },
                  title: Text(
                    result['lead_name'] ?? 'No Name',
                    style: TextStyle(
                      color: selectedLeads == result['lead_id']
                          ? Colors.black
                          : AppColors.fontBlack,
                    ),
                  ),
                  leading: const Icon(Icons.person),
                );
              },
            ),
          ),
      ],
    );
  }

  // Widget _buildSearchField() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text('Select Lead', style: AppFont.dropDowmLabel(context)),
  //       const SizedBox(height: 5),
  //       Container(
  //         height: MediaQuery.of(context).size.height *
  //             .055, // Match height from previous widget
  //         width: double.infinity,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(5),
  //           color: AppColors.containerBg,
  //         ),
  //         child: Row(
  //           children: [
  //             // TextField itself
  //             Expanded(
  //               child: Align(
  //                 alignment: Alignment.bottomCenter,
  //                 child: TextField(
  //                   controller: _searchController,
  //                   onTap: () => FocusScope.of(context).unfocus(),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     alignLabelWithHint: true,
  //                     fillColor: AppColors.containerBg,
  //                     hintText: selectedLeadsName ?? 'Select Leads',
  //                     hintStyle: TextStyle(
  //                         color: selectedLeadsName != null
  //                             ? Colors.black
  //                             : Colors.grey),
  //                     prefixIcon: const Icon(
  //                       FontAwesomeIcons.magnifyingGlass,
  //                       size: 15,
  //                       color: AppColors.fontColor,
  //                     ),
  //                     suffixIcon: IconButton(
  //                       icon: const Icon(
  //                         FontAwesomeIcons.microphone,
  //                         color: AppColors.fontColor,
  //                         size: 15, // Adjusted to match sizing
  //                       ),
  //                       onPressed: () {
  //                         // Implement the action for the microphone button here
  //                         print('Microphone button pressed');
  //                       },
  //                     ),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(5),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                   ),
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w500,
  //                     color: Colors.black,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       if (_isLoadingSearch) const Center(child: CircularProgressIndicator()),
  //       if (_searchResults.isNotEmpty)
  //         Positioned(
  //           top: 60, // Adjusted top positioning for proper dropdown placement
  //           left: 20,
  //           right: 20,
  //           child: Material(
  //             elevation: 5,
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(5),
  //               ),
  //               child: ListView.builder(
  //                 shrinkWrap: true, // Shrink to fit the content height
  //                 physics:
  //                     NeverScrollableScrollPhysics(), // Prevent scrolling inside the dropdown
  //                 itemCount: _searchResults.length,
  //                 itemBuilder: (context, index) {
  //                   final result = _searchResults[index];
  //                   return ListTile(
  //                     onTap: () {
  //                       setState(() {
  //                         FocusScope.of(context).unfocus();
  //                         selectedLeads = result['lead_id'];
  //                         selectedLeadsName = result['lead_name'];
  //                         _searchController.clear();
  //                         _searchResults.clear();
  //                       });
  //                     },
  //                     title: Text(
  //                       result['lead_name'] ?? 'No Name',
  //                       style: TextStyle(
  //                         color: selectedLeads == result['lead_id']
  //                             ? Colors.black // Selected item color
  //                             : AppColors.fontBlack, // Default color
  //                       ),
  //                     ),
  //                     leading: const Icon(Icons.person),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _buildButtons({
    required Map<String, String> options, // ✅ Short display & actual value
    required String groupValue,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 5, 0, 5),
            child: Text(label, style: AppFont.dropDowmLabel(context)),
          ),
        ),
        const SizedBox(height: 5),

        // ✅ Wrap ensures buttons move to next line when needed
        Wrap(
          spacing: 10, // Space between buttons
          runSpacing: 10, // Space between lines
          children: options.keys.map((shortText) {
            bool isSelected =
                groupValue == options[shortText]; // ✅ Compare actual value

            return GestureDetector(
              onTap: () {
                onChanged(
                  options[shortText]!,
                ); // ✅ Pass actual value on selection
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppColors.colorsBlue : Colors.black,
                    width: .5,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  color: isSelected
                      ? AppColors.colorsBlue.withOpacity(0.2)
                      : AppColors.innerContainerBg,
                ),
                child: Text(
                  shortText, // ✅ Only show short text
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.colorsBlue
                        : AppColors.fontColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 5),
      ],
    );
  }
}
