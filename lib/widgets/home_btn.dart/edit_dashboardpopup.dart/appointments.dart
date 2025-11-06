import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/reusable/date_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AppointmentsEdit extends StatefulWidget {
  final String taskId;
  final Function onFormSubmit;

  const AppointmentsEdit({
    super.key,
    required this.onFormSubmit,
    required this.taskId,
  });

  @override
  State<AppointmentsEdit> createState() => _AppointmentsEditState();
}

class _AppointmentsEditState extends State<AppointmentsEdit> {
  Map<String, String> _errors = {};
  TextEditingController startTimeController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  TextEditingController modelInterestController = TextEditingController();
  final TextEditingController statusController = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _isLoadingSearch = false;
  String? selectedLeads;
  String? selectedLeadsName;
  String? selectedStatus;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  bool isButtonEnabled = false;

  // Store initial values for comparison
  String? _initialStatus;
  String? _initialRemarks;
  String? _initialStartDate;
  String? _initialStartTime;
  String? _initialDeferredReason;
  String? _initialDate;
  String? _initialTime;

  // New variables for nested dropdown
  String? selectedDeferredReason;

  @override
  void initState() {
    super.initState();
    _fetchDataId();
    _speech = stt.SpeechToText();
    _initSpeech();
    // Add listeners for real-time change detection
    descriptionController.addListener(_checkIfFormIsComplete);
    startDateController.addListener(_checkIfFormIsComplete);
    startTimeController.addListener(_checkIfFormIsComplete);
  }

  @override
  void dispose() {
    _searchController.dispose();
    descriptionController.removeListener(_checkIfFormIsComplete);
    startDateController.removeListener(_checkIfFormIsComplete);
    startTimeController.removeListener(_checkIfFormIsComplete);
    descriptionController.dispose();
    startDateController.dispose();
    startTimeController.dispose();
    endDateController.dispose();
    endTimeController.dispose();
    modelInterestController.dispose();
    statusController.dispose();
    super.dispose();
  }

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
            _checkIfFormIsComplete();
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> _fetchDataId() async {
    setState(() {
      _isLoadingSearch = true;
    });

    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse('https://api.smartassistapp.in/api/tasks/${widget.taskId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String comment = data['data']['remarks'] ?? '';
        final String status = data['data']['status'] ?? '';
        // final String dueDate = data['data']['due_date'] ?? '';
        // final String time = data['data']['time'] ?? '';
        // final String endTime = data['data']['end_time'] ?? '';
        final String deferredReason = data['data']['deferred_reason'] ?? '';
        final String date = data['data']['due_date'] ?? '';
        final String time = data['data']['time'] ?? '';
        String formattedDate = '';
        String formattedTime = '';

        try {
          if (date.isNotEmpty) {
            final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
            formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
          }

          if (time.isNotEmpty) {
            final parsedTime = DateFormat('HH:mm:ss').parse(time);
            formattedTime = DateFormat('hh:mm a').format(parsedTime);
          }
        } catch (e) {
          debugPrint('Date/Time format error: $e');
        }
        setState(() {
          descriptionController.text = comment;
          _initialRemarks = comment;
          startDateController.text = formattedDate;
          startTimeController.text = formattedTime;
          _initialDate = formattedDate;
          _initialTime = formattedTime;

          if (items.contains(status)) {
            selectedValue = status;
            _initialStatus = status;
          }

          // Set deferred reason if status is deferred
          if (status == 'Deferred' &&
              deferredReasons.contains(deferredReason)) {
            selectedDeferredReason = deferredReason;
            _initialDeferredReason = deferredReason;
          }

          _checkIfFormIsComplete();
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

  bool get _hasRemarksError => descriptionController.text.trim().isEmpty;
  bool get _hasDeferredError =>
      selectedValue == 'Deferred' && selectedDeferredReason == null;

  void _checkIfFormIsComplete() {
    setState(() {
      bool statusChanged = selectedValue != _initialStatus;
      bool remarksChanged =
          descriptionController.text.trim() != (_initialRemarks ?? '').trim();
      bool startDateChanged =
          startDateController.text.trim() != (_initialStartDate ?? '').trim();
      bool startTimeChanged =
          startTimeController.text.trim() != (_initialStartTime ?? '').trim();
      bool deferredReasonChanged =
          selectedDeferredReason != _initialDeferredReason;

      // Check if deferred is selected but no reason is chosen
      bool isDeferredValid =
          selectedValue != 'Deferred' || selectedDeferredReason != null;

      // Check if remarks field is valid (not empty when required)
      bool remarksValid = descriptionController.text.trim().isNotEmpty;

      // Enable button if any field changed and all validations pass
      isButtonEnabled =
          (statusChanged ||
              remarksChanged ||
              startDateChanged ||
              startTimeChanged ||
              deferredReasonChanged) &&
          isDeferredValid;
    });
  }

  Future<void> _pickStartDate() async {
    FocusScope.of(context).unfocus();

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
      // String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);
      String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);

      setState(() {
        // startDateController.text = formattedDate;
        startDateController.text = formattedDate;
        // endDateController.text = formattedDate;
        // Clear date error when date is selected
        if (_errors.containsKey('date')) {
          _errors.remove('date');
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    FocusScope.of(context).unfocus();

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
      final now = DateTime.now();
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      String formattedTime = DateFormat('hh:mm a').format(time);

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
        startTimeController.text = formattedTime;
        // endTimeController.text = formattedEndTime;
        // Clear time error when time is selected
        if (_errors.containsKey('time')) {
          _errors.remove('time');
        }
      });
    }
  }

  void _submit() {
    // Validate deferred reason if deferred is selected
    if (selectedValue == 'Deferred' && selectedDeferredReason == null) {
      showErrorMessage(
        context,
        message: 'Please select a reason for deferring',
      );
      return;
    }

    // Validate remarks field
    // if (descriptionController.text.trim().isEmpty) {
    //   showErrorMessage(context, message: 'Please enter remarks');
    //   return;
    // }

    FocusScope.of(context).unfocus();
    submitForm();
  }

  Future<void> submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? spId = prefs.getString('user_id');
    final token = await Storage.getToken();

    if (spId == null) {
      showErrorMessage(
        context,
        message: 'User ID not found. Please log in again.',
      );
      return;
    }

    print('Date text: ${startDateController.text}');
    print('Time text: ${startTimeController.text}');

    // Parse date - handle both formats
    DateTime rawStartDate;
    try {
      // Try API format first (yyyy-MM-dd)
      rawStartDate = DateFormat('yyyy-MM-dd').parse(startDateController.text);
    } catch (e) {
      // Fall back to user-selected format (dd MMM yyyy)
      rawStartDate = DateFormat('dd MMM yyyy').parse(startDateController.text);
    }

    // Parse time - handle both formats
    DateTime rawStartTime;
    try {
      // Try API format first (24-hour with seconds)
      rawStartTime = DateFormat('HH:mm:ss').parse(startTimeController.text);
    } catch (e) {
      // Fall back to user-selected format (12-hour with AM/PM)
      rawStartTime = DateFormat('hh:mm a').parse(startTimeController.text);
    }

    // Combine them into one DateTime
    final combinedDateTime = DateTime(
      rawStartDate.year,
      rawStartDate.month,
      rawStartDate.day,
      rawStartTime.hour,
      rawStartTime.minute,
    );
    final formattedStartDate = DateFormat(
      'dd-MM-yyyy',
    ).format(combinedDateTime);
    final formattedStartTime = DateFormat('hh:mm a').format(combinedDateTime);

    final newTaskForLead = {
      'comments': descriptionController.text,
      // 'status': selectedValue,
      'status': selectedValue ?? 'Not Started',
      'sp_id': spId,
      // 'time': formattedStartTime,
      // 'due_date': formattedStartDate,
      // 'due_date': dueDate != null
      //     ? DateFormat('dd/MM/yyyy').format(dueDate)
      //     : '',
      // 'time': startTimeController.text,
      // 'end_time': endTimeController.text,
      if (selectedValue == 'Deferred' && selectedDeferredReason != null)
        'deferred_reason': selectedDeferredReason,
    };

    print('Sending PUT request body: ${jsonEncode(newTaskForLead)}');

    try {
      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/tasks/${widget.taskId}/update',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(newTaskForLead),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        showSuccessMessage(
          context,
          message: 'Appointment updated successfully',
        );
        widget.onFormSubmit();
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message =
            responseData['message'] ?? 'Submission failed. Try again.';
        showErrorMessage(context, message: message);
      }
    } catch (e) {
      showErrorMessage(
        context,
        message: 'Something went wrong. Please try again.',
      );
      print('Error during PUT request: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.containerBg,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: (value) => _checkIfFormIsComplete(),
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
              if (!readOnly)
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

  final List<String> items = ['In Progress', 'Completed', 'Deferred'];
  final List<String> deferredReasons = ['Not picking up', 'Lost interest'];
  String? selectedValue;

  List<DropdownMenuItem<String>> _addDividersAfterItems(List<String> items) {
    final List<DropdownMenuItem<String>> menuItems = [];
    for (final String item in items) {
      menuItems.addAll([
        DropdownMenuItem<String>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(item, style: AppFont.dropDowmLabel(context)),
          ),
        ),
        if (item != items.last)
          const DropdownMenuItem<String>(enabled: false, child: Divider()),
      ]);
    }
    return menuItems;
  }

  List<DropdownMenuItem<String>> _addDividersAfterDeferredReasons(
    List<String> reasons,
  ) {
    final List<DropdownMenuItem<String>> menuItems = [];
    for (final String reason in reasons) {
      menuItems.addAll([
        DropdownMenuItem<String>(
          value: reason,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(reason, style: AppFont.dropDowmLabel(context)),
          ),
        ),
        if (reason != reasons.last)
          const DropdownMenuItem<String>(enabled: false, child: Divider()),
      ]);
    }
    return menuItems;
  }

  List<double> _getCustomItemsHeights() {
    final List<double> itemsHeights = [];
    for (int i = 0; i < (items.length * 2) - 1; i++) {
      if (i.isEven) {
        itemsHeights.add(40);
      }
      if (i.isOdd) {
        itemsHeights.add(4);
      }
    }
    return itemsHeights;
  }

  List<double> _getCustomDeferredItemsHeights() {
    final List<double> itemsHeights = [];
    for (int i = 0; i < (deferredReasons.length * 2) - 1; i++) {
      if (i.isEven) {
        itemsHeights.add(40);
      }
      if (i.isOdd) {
        itemsHeights.add(4);
      }
    }
    return itemsHeights;
  }

  Widget _buildDeferredReasonDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: selectedValue == 'Deferred' ? null : 0,
      child: selectedValue == 'Deferred'
          ? Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'Reason :',
                            style: AppFont.dropDowmLabel(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLightGrey,
                          borderRadius: BorderRadius.circular(10),
                          border: _hasDeferredError
                              ? Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            style: const TextStyle(color: AppColors.fontColor),
                            isExpanded: true,
                            hint: Text(
                              'Select Reason',
                              style: AppFont.dropDowmLabelLightcolors(context),
                            ),
                            items: _addDividersAfterDeferredReasons(
                              deferredReasons,
                            ),
                            value: selectedDeferredReason,
                            onChanged: (String? value) {
                              setState(() {
                                selectedDeferredReason = value;
                                _checkIfFormIsComplete();
                              });
                            },
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              height: 40,
                              width: double.infinity,
                            ),
                            dropdownStyleData: const DropdownStyleData(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(2),
                                ),
                              ),
                              maxHeight: 200,
                            ),
                            menuItemStyleData: MenuItemStyleData(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              customHeights: _getCustomDeferredItemsHeights(),
                            ),
                            iconStyleData: const IconStyleData(
                              openMenuIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_hasDeferredError)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Please select a reason for deferring',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      // key: scaffoldMessengerKey,
      child: GestureDetector(
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
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Update Appointment',
                      style: AppFont.popupTitleBlack(context),
                    ),
                  ),
                ],
              ),
              // DateButton(
              //   isRequired: true,
              //   label: 'When?',
              //   dateController: startDateController,
              //   timeController: startTimeController,
              //   onDateTap: _pickStartDate,
              //   onTimeTap: _pickStartTime,
              //   onChanged: (String value) {},
              //   dateErrorText: _errors['date'],
              //   timeErrorText: _errors['time'],
              // ),
              // const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        // child: Text(
                        //   'Status :',
                        //   style: AppFont.dropDowmLabel(context),
                        // ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: 'Status :'),
                              // if (widget.isRequired)
                              // const TextSpan(
                              //   text: " *",
                              //   style: TextStyle(color: Colors.red),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          style: const TextStyle(color: AppColors.fontColor),
                          isExpanded: true,
                          hint: Text(
                            'Select status',
                            style: AppFont.dropDowmLabelLightcolors(context),
                          ),
                          items: _addDividersAfterItems(items),
                          value: selectedValue,
                          onChanged: (String? value) {
                            setState(() {
                              selectedValue = value;
                              // Reset deferred reason when status changes
                              if (value != 'Deferred') {
                                selectedDeferredReason = null;
                              }
                              _checkIfFormIsComplete();
                            });
                          },
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            height: 40,
                            width: double.infinity,
                          ),
                          dropdownStyleData: const DropdownStyleData(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(2),
                              ),
                            ),
                            maxHeight: 200,
                          ),
                          menuItemStyleData: MenuItemStyleData(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            customHeights: _getCustomItemsHeights(),
                          ),
                          iconStyleData: const IconStyleData(
                            openMenuIcon: Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Nested dropdown for deferred reasons
              _buildDeferredReasonDropdown(),
              const SizedBox(height: 10),
              EnhancedSpeechTextField(
                isRequired: false,
                error: _hasRemarksError,
                label: 'Remarks:',
                controller: descriptionController,
                hint: 'Type or speak... ',
                onChanged: (text) {
                  _checkIfFormIsComplete();
                  print('Text changed: $text');
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.cancelButton,
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
                        backgroundColor: isButtonEnabled
                            ? AppColors.colorsBlue
                            : AppColors.cancelButton,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: isButtonEnabled ? _submit : null,
                      child: Text("Update", style: AppFont.buttons(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/utils/storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smartassist/utils/snackbar_helper.dart';
// import 'package:smartassist/widgets/remarks_field.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class AppointmentsEdit extends StatefulWidget {
//   final String taskId;
//   final Function onFormSubmit;

//   const AppointmentsEdit({
//     super.key,
//     required this.onFormSubmit,
//     required this.taskId,
//   });

//   @override
//   State<AppointmentsEdit> createState() => _AppointmentsEditState();
// }

// class _AppointmentsEditState extends State<AppointmentsEdit> {
//   Map<String, String> _errors = {};
//   TextEditingController startTimeController = TextEditingController();
//   TextEditingController startDateController = TextEditingController();
//   TextEditingController endTimeController = TextEditingController();
//   TextEditingController endDateController = TextEditingController();
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController dateController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   TextEditingController modelInterestController = TextEditingController();
//   final TextEditingController statusController = TextEditingController();

//   List<dynamic> _searchResults = [];
//   bool _isLoadingSearch = false;
//   String? selectedLeads;
//   String? selectedLeadsName;
//   String? selectedStatus;
//   late stt.SpeechToText _speech;
//   bool _isListening = false;

//   bool isButtonEnabled = false;

//   // Store initial values for comparison
//   String? _initialStatus;
//   String? _initialRemarks;
//   String? _initialStartDate;
//   String? _initialStartTime;

//   @override
//   void initState() {
//     super.initState();
//     _fetchDataId();
//     _speech = stt.SpeechToText();
//     _initSpeech();
//     // Add listeners for real-time change detection
//     descriptionController.addListener(_checkIfFormIsComplete);
//     startDateController.addListener(_checkIfFormIsComplete);
//     startTimeController.addListener(_checkIfFormIsComplete);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     descriptionController.removeListener(_checkIfFormIsComplete);
//     startDateController.removeListener(_checkIfFormIsComplete);
//     startTimeController.removeListener(_checkIfFormIsComplete);
//     descriptionController.dispose();
//     startDateController.dispose();
//     startTimeController.dispose();
//     endDateController.dispose();
//     endTimeController.dispose();
//     modelInterestController.dispose();
//     statusController.dispose();
//     super.dispose();
//   }

//   void _initSpeech() async {
//     bool available = await _speech.initialize(
//       onStatus: (status) {
//         if (status == 'done') {
//           setState(() {
//             _isListening = false;
//           });
//         }
//       },
//       onError: (errorNotification) {
//         setState(() {
//           _isListening = false;
//         });
//         showErrorMessage(
//           context,
//           message: 'Speech recognition error: ${errorNotification.errorMsg}',
//         );
//       },
//     );
//     if (!available) {
//       showErrorMessage(
//         context,
//         message: 'Speech recognition not available on this device',
//       );
//     }
//   }

//   void _toggleListening(TextEditingController controller) async {
//     if (_isListening) {
//       _speech.stop();
//       setState(() {
//         _isListening = false;
//       });
//     } else {
//       setState(() {
//         _isListening = true;
//       });

//       await _speech.listen(
//         onResult: (result) {
//           setState(() {
//             controller.text = result.recognizedWords;
//             _checkIfFormIsComplete();
//           });
//         },
//         listenFor: const Duration(seconds: 30),
//         pauseFor: const Duration(seconds: 5),
//         partialResults: true,
//         cancelOnError: true,
//         listenMode: stt.ListenMode.confirmation,
//       );
//     }
//   }

//   Future<void> _fetchDataId() async {
//     setState(() {
//       _isLoadingSearch = true;
//     });

//     final token = await Storage.getToken();

//     try {
//       final response = await http.get(
//         Uri.parse('https://api.smartassistapp.in/api/tasks/${widget.taskId}'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Fetch Response: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         final String comment = data['data']['remarks'] ?? '';
//         final String status = data['data']['status'] ?? '';
//         final String dueDate = data['data']['due_date'] ?? '';
//         final String time = data['data']['time'] ?? '';
//         final String endTime = data['data']['end_time'] ?? '';
//         setState(() {
//           descriptionController.text = comment;
//           _initialRemarks = comment;
//           startDateController.text = dueDate.isNotEmpty
//               ? DateFormat(
//                   'dd MMM yyyy',
//                 ).format(DateFormat('dd-MM-yyyy').parse(dueDate))
//               : '';
//           _initialStartDate = startDateController.text;
//           startTimeController.text = time;
//           _initialStartTime = time;
//           endDateController.text = dueDate.isNotEmpty
//               ? DateFormat(
//                   'dd MMM yyyy',
//                 ).format(DateFormat('dd-MM-yyyy').parse(dueDate))
//               : '';
//           endTimeController.text = endTime;
//           if (items.contains(status)) {
//             selectedValue = status;
//             _initialStatus = status;
//           }
//           _checkIfFormIsComplete();
//         });
//       }
//     } catch (e) {
//       showErrorMessage(context, message: 'Something went wrong..!');
//     } finally {
//       setState(() {
//         _isLoadingSearch = false;
//       });
//     }
//   }

//   void _checkIfFormIsComplete() {
//     setState(() {
//       isButtonEnabled =
//           (selectedValue != _initialStatus) ||
//           (descriptionController.text.trim() !=
//               (_initialRemarks ?? '').trim()) ||
//           (startDateController.text.trim() !=
//               (_initialStartDate ?? '').trim()) ||
//           (startTimeController.text.trim() != (_initialStartTime ?? '').trim());
//     });
//   }

//   Future<void> _pickStartDate() async {
//     FocusScope.of(context).unfocus();

//     DateTime initialDate;
//     try {
//       if (startDateController.text.isNotEmpty) {
//         initialDate = DateFormat('dd MMM yyyy').parse(startDateController.text);
//       } else {
//         initialDate = DateTime.now();
//       }
//     } catch (e) {
//       initialDate = DateTime.now();
//     }

//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );

//     if (pickedDate != null) {
//       String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);
//       setState(() {
//         startDateController.text = formattedDate;
//         endDateController.text = formattedDate;
//         _checkIfFormIsComplete();
//       });
//     }
//   }

//   Future<void> _pickStartTime() async {
//     FocusScope.of(context).unfocus();

//     TimeOfDay initialTime;
//     try {
//       if (startTimeController.text.isNotEmpty) {
//         final parsedTime = DateFormat(
//           'hh:mm a',
//         ).parse(startTimeController.text);
//         initialTime = TimeOfDay(
//           hour: parsedTime.hour,
//           minute: parsedTime.minute,
//         );
//       } else {
//         initialTime = TimeOfDay.now();
//       }
//     } catch (e) {
//       initialTime = TimeOfDay.now();
//     }

//     TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: initialTime,
//     );

//     if (pickedTime != null) {
//       final now = DateTime.now();
//       final time = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         pickedTime.hour,
//         pickedTime.minute,
//       );
//       String formattedTime = DateFormat('hh:mm a').format(time);
//       final endHour = (pickedTime.hour + 1) % 24;
//       final endTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         endHour,
//         pickedTime.minute,
//       );
//       String formattedEndTime = DateFormat('hh:mm a').format(endTime);

//       setState(() {
//         startTimeController.text = formattedTime;
//         endTimeController.text = formattedEndTime;
//         _checkIfFormIsComplete();
//       });
//     }
//   }

//   void _submit() {
//     FocusScope.of(context).unfocus();
//     submitForm();
//   }

//   Future<void> submitForm() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? spId = prefs.getString('user_id');
//     final token = await Storage.getToken();

//     if (spId == null) {
//       showErrorMessage(
//         context,
//         message: 'User ID not found. Please log in again.',
//       );
//       return;
//     }

//     DateTime? dueDate;
//     try {
//       if (startDateController.text.isNotEmpty) {
//         dueDate = DateFormat('dd MMM yyyy').parse(startDateController.text);
//       }
//     } catch (e) {
//       showErrorMessage(context, message: 'Invalid date format.');
//       return;
//     }

//     final newTaskForLead = {
//       'remarks': descriptionController.text,
//       'status': selectedValue,
//       'sp_id': spId,
//       'due_date': dueDate != null
//           ? DateFormat('dd-MM-yyyy').format(dueDate)
//           : '',
//       'time': startTimeController.text,
//       'end_time': endTimeController.text,
//     };

//     print('Sending PUT request body: ${jsonEncode(newTaskForLead)}');

//     try {
//       final response = await http.put(
//         Uri.parse(
//           'https://api.smartassistapp.in/api/tasks/${widget.taskId}/update',
//         ),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(newTaskForLead),
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         Navigator.pop(context, true);
//         showSuccessMessage(
//           context,
//           message: 'Appointment updated successfully',
//         );
//         widget.onFormSubmit();
//       } else {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         String message =
//             responseData['message'] ?? 'Submission failed. Try again.';
//         showErrorMessage(context, message: message);
//       }
//     } catch (e) {
//       showErrorMessage(
//         context,
//         message: 'Something went wrong. Please try again.',
//       );
//       print('Error during PUT request: $e');
//     }
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     bool readOnly = false,
//     VoidCallback? onTap,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             color: AppColors.containerBg,
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: controller,
//                   maxLines: null,
//                   minLines: 1,
//                   keyboardType: TextInputType.multiline,
//                   readOnly: readOnly,
//                   onTap: onTap,
//                   onChanged: (value) => _checkIfFormIsComplete(),
//                   decoration: InputDecoration(
//                     hintText: hint,
//                     hintStyle: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 10,
//                     ),
//                     border: InputBorder.none,
//                   ),
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               if (!readOnly)
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: IconButton(
//                     onPressed: () => _toggleListening(controller),
//                     icon: Icon(
//                       _isListening
//                           ? FontAwesomeIcons.stop
//                           : FontAwesomeIcons.microphone,
//                       color: _isListening ? Colors.red : AppColors.fontColor,
//                       size: 15,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   final List<String> items = ['Not Started', 'Completed', 'Deferred'];
//   String? selectedValue;

//   List<DropdownMenuItem<String>> _addDividersAfterItems(List<String> items) {
//     final List<DropdownMenuItem<String>> menuItems = [];
//     for (final String item in items) {
//       menuItems.addAll([
//         DropdownMenuItem<String>(
//           value: item,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Text(item, style: AppFont.dropDowmLabel(context)),
//           ),
//         ),
//         if (item != items.last)
//           const DropdownMenuItem<String>(enabled: false, child: Divider()),
//       ]);
//     }
//     return menuItems;
//   }

//   List<double> _getCustomItemsHeights() {
//     final List<double> itemsHeights = [];
//     for (int i = 0; i < (items.length * 2) - 1; i++) {
//       if (i.isEven) {
//         itemsHeights.add(40);
//       }
//       if (i.isOdd) {
//         itemsHeights.add(4);
//       }
//     }
//     return itemsHeights;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaffoldMessenger(
//       // key: scaffoldMessengerKey,
//       child: GestureDetector(
//         onTap: () => FocusScope.of(context).unfocus(),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 10),
//                     child: Text(
//                       'Update Appointment',
//                       style: AppFont.popupTitleBlack(context),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 1,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Container(
//                         margin: const EdgeInsets.only(bottom: 5),
//                         child: Text(
//                           'Status :',
//                           style: AppFont.dropDowmLabel(context),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     flex: 3,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 5),
//                       decoration: BoxDecoration(
//                         color: AppColors.backgroundLightGrey,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton2<String>(
//                           style: const TextStyle(color: AppColors.fontColor),
//                           isExpanded: true,
//                           hint: Text(
//                             'Select Item',
//                             style: AppFont.dropDowmLabelLightcolors(context),
//                           ),
//                           items: _addDividersAfterItems(items),
//                           value: selectedValue,
//                           onChanged: (String? value) {
//                             setState(() {
//                               selectedValue = value;
//                               _checkIfFormIsComplete();
//                             });
//                           },
//                           buttonStyleData: const ButtonStyleData(
//                             padding: EdgeInsets.symmetric(horizontal: 10),
//                             height: 40,
//                             width: double.infinity,
//                           ),
//                           dropdownStyleData: const DropdownStyleData(
//                             decoration: BoxDecoration(
//                               color: AppColors.white,
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(2),
//                               ),
//                             ),
//                             maxHeight: 200,
//                           ),
//                           menuItemStyleData: MenuItemStyleData(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8.0,
//                             ),
//                             customHeights: _getCustomItemsHeights(),
//                           ),
//                           iconStyleData: const IconStyleData(
//                             openMenuIcon: Icon(Icons.arrow_drop_down),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               EnhancedSpeechTextField(
//                 isRequired: false,
//                 error: true,
//                 // contentPadding: EdgeInsets.zero,
//                 label: 'Remarks:',
//                 controller: descriptionController,
//                 hint: 'Type or speak... ',
//                 onChanged: (text) {
//                   print('Text changed: $text');
//                 },
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.zero,
//                         backgroundColor: AppColors.cancelButton,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       onPressed: () => Navigator.pop(context),
//                       child: Text(
//                         "Cancel",
//                         textAlign: TextAlign.center,
//                         style: AppFont.buttons(context),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.zero,
//                         backgroundColor: isButtonEnabled
//                             ? AppColors.colorsBlue
//                             : AppColors.cancelButton,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       onPressed: isButtonEnabled ? _submit : null,
//                       child: Text("Update", style: AppFont.buttons(context)),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// // import 'package:dropdown_button2/dropdown_button2.dart';
// // import 'package:flutter/material.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';
// // import 'package:smartassist/config/component/color/colors.dart';
// // import 'package:smartassist/config/component/font/font.dart';
// // import 'package:smartassist/utils/storage.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:smartassist/utils/snackbar_helper.dart';
// // import 'package:smartassist/widgets/remarks_field.dart';
// // import 'package:speech_to_text/speech_to_text.dart' as stt;

// // class AppointmentsEdit extends StatefulWidget {
// //   final String taskId;
// //   final Function onFormSubmit;
// //   const AppointmentsEdit({
// //     super.key,
// //     required this.onFormSubmit,
// //     required this.taskId,
// //   });

// //   @override
// //   State<AppointmentsEdit> createState() => _AppointmentsEditState();
// // }

// // class _AppointmentsEditState extends State<AppointmentsEdit> {
// //   Map<String, String> _errors = {};
// //   TextEditingController startTimeController = TextEditingController();
// //   TextEditingController startDateController = TextEditingController();
// //   TextEditingController endTimeController = TextEditingController();
// //   TextEditingController endDateController = TextEditingController();

// //   final TextEditingController _searchController = TextEditingController();
// //   final TextEditingController dateController = TextEditingController();
// //   final TextEditingController descriptionController = TextEditingController();
// //   TextEditingController modelInterestController = TextEditingController();
// //   final TextEditingController statusController = TextEditingController();

// //   List<dynamic> _searchResults = [];
// //   bool _isLoadingSearch = false;
// //   String _query = '';
// //   String? selectedLeads;
// //   String? selectedLeadsName;
// //   String _selectedSubject = '';
// //   String? selectedStatus;
// //   late stt.SpeechToText _speech;
// //   bool _isListening = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchDataId();
// //     _speech = stt.SpeechToText();
// //     _initSpeech();
// //   }

// //   @override
// //   void dispose() {
// //     _searchController.dispose();
// //     super.dispose();
// //   }

// //   // Initialize speech recognition
// //   void _initSpeech() async {
// //     bool available = await _speech.initialize(
// //       onStatus: (status) {
// //         if (status == 'done') {
// //           setState(() {
// //             _isListening = false;
// //           });
// //         }
// //       },
// //       onError: (errorNotification) {
// //         setState(() {
// //           _isListening = false;
// //         });
// //         showErrorMessage(
// //           context,
// //           message: 'Speech recognition error: ${errorNotification.errorMsg}',
// //         );
// //       },
// //     );
// //     if (!available) {
// //       showErrorMessage(
// //         context,
// //         message: 'Speech recognition not available on this device',
// //       );
// //     }
// //   }

// //   // Toggle listening
// //   void _toggleListening(TextEditingController controller) async {
// //     if (_isListening) {
// //       _speech.stop();
// //       setState(() {
// //         _isListening = false;
// //       });
// //     } else {
// //       setState(() {
// //         _isListening = true;
// //       });

// //       await _speech.listen(
// //         onResult: (result) {
// //           setState(() {
// //             controller.text = result.recognizedWords;
// //           });
// //         },
// //         listenFor: Duration(seconds: 30),
// //         pauseFor: Duration(seconds: 5),
// //         partialResults: true,
// //         cancelOnError: true,
// //         listenMode: stt.ListenMode.confirmation,
// //       );
// //     }
// //   }

// //   Future<void> _fetchDataId() async {
// //     setState(() {
// //       _isLoadingSearch = true;
// //     });

// //     final token = await Storage.getToken();

// //     try {
// //       final response = await http.get(
// //         Uri.parse('https://api.smartassistapp.in/api/tasks/${widget.taskId}'),
// //         headers: {
// //           'Authorization': 'Bearer $token',
// //           'Content-Type': 'application/json',
// //         },
// //       );

// //       print(response.body);

// //       if (response.statusCode == 200) {
// //         final Map<String, dynamic> data = json.decode(response.body);
// //         final String comment = data['data']['remarks'] ?? '';
// //         final String status = data['data']['status'] ?? '';
// //         descriptionController.text = comment;
// //         // statusController.text = status;
// //         // Set dropdown selected value if it matches one of the items
// //         if (items.contains(status)) {
// //           selectedValue = status;
// //         }
// //       }
// //     } catch (e) {
// //       showErrorMessage(context, message: 'Something went wrong..!');
// //     } finally {
// //       setState(() {
// //         _isLoadingSearch = false;
// //       });
// //     }
// //   }

// //   /// Open date picker
// //   Future<void> _pickDate() async {
// //     DateTime? pickedDate = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime(2000),
// //       lastDate: DateTime(2100),
// //     );

// //     if (pickedDate != null) {
// //       setState(() {
// //         dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
// //         _errors.remove('');
// //       });
// //     }
// //   }

// //   void _submit() {
// //     // if (_validation()) {
// //     submitForm();
// //     // }
// //   }

// //   /// Submit form
// //   Future<void> submitForm() async {
// //     SharedPreferences prefs = await SharedPreferences.getInstance();
// //     String? spId = prefs.getString('user_id');
// //     final token = await Storage.getToken();

// //     if (spId == null) {
// //       showErrorMessage(
// //         context,
// //         message: 'User ID not found. Please log in again.',
// //       );
// //       return;
// //     }

// //     final newTaskForLead = {
// //       'remarks': descriptionController.text,
// //       'status': selectedValue,
// //       'sp_id': spId,
// //     };

// //     // 👇 Print the body you're about to send
// //     print('Sending PUT request body: ${jsonEncode(newTaskForLead)}');

// //     try {
// //       final response = await http.put(
// //         Uri.parse(
// //           'https://api.smartassistapp.in/api/tasks/${widget.taskId}/update',
// //         ),
// //         headers: {
// //           'Authorization': 'Bearer $token',
// //           'Content-Type': 'application/json',
// //         },
// //         body: jsonEncode(newTaskForLead),
// //       );

// //       // 👇 Log response status and body
// //       print('Response status: ${response.statusCode}');
// //       print('Response body: ${response.body}');

// //       if (response.statusCode == 200) {
// //         print(response.body);
// //         Navigator.pop(context, true);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               'Appointment updated successfully',
// //               style: GoogleFonts.poppins(),
// //             ),
// //             backgroundColor: Colors.green,
// //             duration: const Duration(seconds: 2),
// //             behavior:
// //                 SnackBarBehavior.floating, // Optional: Makes it float above UI
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(
// //                 10,
// //               ), // Optional: rounded corners
// //             ),
// //           ),
// //         );
// //       } else {
// //         final Map<String, dynamic> responseData = json.decode(response.body);
// //         String message =
// //             responseData['message'] ?? 'Submission failed. Try again.';
// //         showErrorMessage(context, message: message);
// //         print(response.body);
// //       }
// //     } catch (e) {
// //       showErrorMessage(
// //         context,
// //         message: 'Something went wrong. Please try again.',
// //       );
// //       print('Error during PUT request: $e');
// //     }
// //   }

// //   Widget _buildTextField({
// //     // required String label,
// //     required TextEditingController controller,
// //     required String hint,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Container(
// //           width: double.infinity,
// //           decoration: BoxDecoration(
// //             borderRadius: BorderRadius.circular(10),
// //             color: AppColors.containerBg,
// //           ),
// //           child: Row(
// //             children: [
// //               // Expanded TextField that adjusts height
// //               Expanded(
// //                 child: TextField(
// //                   controller: controller,
// //                   maxLines:
// //                       null, // This allows the TextField to expand vertically based on content
// //                   minLines: 1, // Minimum 1 line of height
// //                   keyboardType: TextInputType.multiline,
// //                   decoration: InputDecoration(
// //                     hintText: hint,
// //                     hintStyle: GoogleFonts.poppins(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.w500,
// //                       color: Colors.grey,
// //                     ),
// //                     contentPadding: const EdgeInsets.symmetric(
// //                       horizontal: 10,
// //                       vertical: 10,
// //                     ),
// //                     border: InputBorder.none,
// //                   ),
// //                   style: GoogleFonts.poppins(
// //                     fontSize: 14,
// //                     fontWeight: FontWeight.w500,
// //                     color: Colors.black,
// //                   ),
// //                 ),
// //               ),
// //               // Microphone icon with speech recognition
// //               Align(
// //                 alignment: Alignment.centerRight,
// //                 child: IconButton(
// //                   onPressed: () => _toggleListening(controller),
// //                   icon: Icon(
// //                     _isListening
// //                         ? FontAwesomeIcons.stop
// //                         : FontAwesomeIcons.microphone,
// //                     color: _isListening ? Colors.red : AppColors.fontColor,
// //                     size: 15,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Future<void> _pickStartDate() async {
// //     FocusScope.of(context).unfocus();

// //     // Get current start date or use today
// //     DateTime initialDate;
// //     try {
// //       if (startDateController.text.isNotEmpty) {
// //         initialDate = DateFormat('dd MMM yyyy').parse(startDateController.text);
// //       } else {
// //         initialDate = DateTime.now();
// //       }
// //     } catch (e) {
// //       initialDate = DateTime.now();
// //     }

// //     DateTime? pickedDate = await showDatePicker(
// //       context: context,
// //       initialDate: initialDate,
// //       firstDate: DateTime(2000),
// //       lastDate: DateTime(2100),
// //     );

// //     if (pickedDate != null) {
// //       String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);

// //       setState(() {
// //         // Set start date
// //         startDateController.text = formattedDate;

// //         // Set end date to the same as start date but not visible in the UI
// //         // (Only passed to API)
// //         endDateController.text = formattedDate;
// //       });
// //     }
// //   }

// //   Future<void> _pickStartTime() async {
// //     FocusScope.of(context).unfocus();

// //     // Get current time from startTimeController or use current time
// //     TimeOfDay initialTime;
// //     try {
// //       if (startTimeController.text.isNotEmpty) {
// //         final parsedTime = DateFormat(
// //           'hh:mm a',
// //         ).parse(startTimeController.text);
// //         initialTime = TimeOfDay(
// //           hour: parsedTime.hour,
// //           minute: parsedTime.minute,
// //         );
// //       } else {
// //         initialTime = TimeOfDay.now();
// //       }
// //     } catch (e) {
// //       initialTime = TimeOfDay.now();
// //     }

// //     TimeOfDay? pickedTime = await showTimePicker(
// //       context: context,
// //       initialTime: initialTime,
// //     );

// //     if (pickedTime != null) {
// //       // Create a temporary DateTime to format the time
// //       final now = DateTime.now();
// //       final time = DateTime(
// //         now.year,
// //         now.month,
// //         now.day,
// //         pickedTime.hour,
// //         pickedTime.minute,
// //       );
// //       String formattedTime = DateFormat('hh:mm a').format(time);

// //       // Calculate end time (1 hour later)
// //       final endHour = (pickedTime.hour + 1) % 24;
// //       final endTime = DateTime(
// //         now.year,
// //         now.month,
// //         now.day,
// //         endHour,
// //         pickedTime.minute,
// //       );
// //       String formattedEndTime = DateFormat('hh:mm a').format(endTime);

// //       setState(() {
// //         // Set start time
// //         startTimeController.text = formattedTime;

// //         // Set end time to 1 hour later but not visible in the UI
// //         // (Only passed to API)
// //         endTimeController.text = formattedEndTime;
// //       });
// //     }
// //   }

// //   final List<String> items = ['Not Started', 'Completed', 'Deferred'];
// //   String? selectedValue;

// //   List<DropdownMenuItem<String>> _addDividersAfterItems(List<String> items) {
// //     final List<DropdownMenuItem<String>> menuItems = [];
// //     for (final String item in items) {
// //       menuItems.addAll([
// //         DropdownMenuItem<String>(
// //           value: item,
// //           child: Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 8.0),
// //             child: Text(item, style: AppFont.dropDowmLabel(context)),
// //           ),
// //         ),
// //         //If it's last item, we will not add Divider after it.
// //         if (item != items.last)
// //           const DropdownMenuItem<String>(enabled: false, child: Divider()),
// //       ]);
// //     }
// //     return menuItems;
// //   }

// //   List<double> _getCustomItemsHeights() {
// //     final List<double> itemsHeights = [];
// //     for (int i = 0; i < (items.length * 2) - 1; i++) {
// //       if (i.isEven) {
// //         itemsHeights.add(40);
// //       }
// //       //Dividers indexes will be the odd indexes
// //       if (i.isOdd) {
// //         itemsHeights.add(4);
// //       }
// //     }
// //     return itemsHeights;
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: () => FocusScope.of(context).unfocus(),
// //       child: SingleChildScrollView(
// //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Row(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Container(
// //                   margin: const EdgeInsets.symmetric(vertical: 10),
// //                   child: Text(
// //                     'Update Appointment',
// //                     style: AppFont.popupTitleBlack(context),
// //                   ),
// //                 ),
// //                 // TextButton(
// //                 //   onPressed: () => Navigator.pop(context),
// //                 //   child: Text(
// //                 //     textAlign: TextAlign.start,
// //                 //     'Cancel',
// //                 //     style: GoogleFonts.poppins(
// //                 //       fontSize: 18,
// //                 //       color: AppColors.colorsBlue,
// //                 //       fontWeight: FontWeight.w500,
// //                 //     ),
// //                 //   ),
// //                 // )
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   flex: 1,
// //                   child: Align(
// //                     alignment: Alignment.centerLeft,
// //                     child: Container(
// //                       margin: const EdgeInsets.only(bottom: 5),
// //                       child: Text(
// //                         'Status :',
// //                         style: AppFont.dropDowmLabel(context),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Expanded(
// //                   flex: 3,
// //                   child: Container(
// //                     padding: const EdgeInsets.symmetric(vertical: 5),
// //                     decoration: BoxDecoration(
// //                       color: AppColors.backgroundLightGrey,
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: DropdownButtonHideUnderline(
// //                       child: DropdownButton2<String>(
// //                         style: const TextStyle(color: AppColors.fontColor),
// //                         isExpanded: true,
// //                         hint: Text(
// //                           'Select Item',
// //                           style: AppFont.dropDowmLabelLightcolors(context),
// //                         ),
// //                         items: _addDividersAfterItems(items),
// //                         value: selectedValue,
// //                         onChanged: (String? value) {
// //                           setState(() {
// //                             selectedValue = value;
// //                           });
// //                         },
// //                         buttonStyleData: const ButtonStyleData(
// //                           padding: EdgeInsets.symmetric(horizontal: 10),
// //                           height: 40,
// //                           width: double.infinity,
// //                         ),
// //                         dropdownStyleData: const DropdownStyleData(
// //                           decoration: BoxDecoration(
// //                             color: AppColors.white,
// //                             borderRadius: BorderRadius.all(Radius.circular(2)),
// //                           ),
// //                           maxHeight: 200,
// //                         ),
// //                         menuItemStyleData: MenuItemStyleData(
// //                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
// //                           customHeights: _getCustomItemsHeights(),
// //                         ),
// //                         iconStyleData: const IconStyleData(
// //                           openMenuIcon: Icon(Icons.arrow_drop_down),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   flex: 1,
// //                   child: Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 5.0),
// //                     child: Text(
// //                       'Remarks :',
// //                       style: GoogleFonts.poppins(
// //                         fontSize: 14,
// //                         fontWeight: FontWeight.w500,
// //                         color: AppColors.fontBlack,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),

// //                 // Expanded(
// //                 //   flex: 3,
// //                 //   child: _buildTextField(
// //                 //     // label: 'Remark :',
// //                 //     controller: descriptionController,
// //                 //     hint: 'Type or speak...',
// //                 //   ),
// //                 // ),
// //                 Expanded(
// //                   flex: 3,
// //                   child: EnhancedSpeechTextField(
// //                     // contentPadding: EdgeInsets.zero,
// //                     label: 'Remarks:',
// //                     controller: descriptionController,
// //                     hint: 'Type or speak... ',
// //                     onChanged: (text) {
// //                       print('Text changed: $text');
// //                     },
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: ElevatedButton(
// //                     style: ElevatedButton.styleFrom(
// //                       padding: EdgeInsets.zero,
// //                       backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
// //                       elevation: 0,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(5),
// //                       ),
// //                     ),
// //                     onPressed: () => Navigator.pop(context),
// //                     child: Text(
// //                       "Cancel",
// //                       textAlign: TextAlign.center,
// //                       style: AppFont.buttons(context),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Expanded(
// //                   child: ElevatedButton(
// //                     style: ElevatedButton.styleFrom(
// //                       padding: EdgeInsets.zero,
// //                       backgroundColor: AppColors.colorsBlue,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(5),
// //                       ),
// //                     ),
// //                     onPressed: _submit,
// //                     child: Text("Update", style: AppFont.buttons(context)),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   }
