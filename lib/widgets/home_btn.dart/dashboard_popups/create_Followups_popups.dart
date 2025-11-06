import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/widgets/popups_widget/leadSearch_textfield.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/reusable/action_button.dart';
import 'package:smartassist/widgets/reusable/date_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CreateFollowupsPopups extends StatefulWidget {
  final Function onFormSubmit;
  final Function(int)? onTabChange;

  const CreateFollowupsPopups({
    super.key,
    required this.onFormSubmit,
    this.onTabChange,
  });

  @override
  State<CreateFollowupsPopups> createState() => _CreateFollowupsPopupsState();
}

class _CreateFollowupsPopupsState extends State<CreateFollowupsPopups> {
  String? _leadId;
  String? _leadName;
  Map<String, String> _errors = {};
  TextEditingController startTimeController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  TextEditingController modelInterestController = TextEditingController();

  List<dynamic> _searchResults = [];
  String _selectedSubject = '';
  String? selectedStatus;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
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

  void _submit() async {
    if (isSubmitting) return;

    bool isValid = true;

    setState(() {
      isSubmitting = true;
      _errors = {};

      // Validate lead selection
      if (_leadId == null || _leadId!.isEmpty) {
        _errors['select lead name'] = 'Please select a lead name';
        isValid = false;
      }

      // Validate action selection
      if (_selectedSubject == null || _selectedSubject!.isEmpty) {
        _errors['subject'] = 'Please select an action';
        isValid = false;
      }

      // Validate date selection
      // if (startDateController.text.isEmpty) {
      //   _errors['date'] = 'Please select a date';
      //   isValid = false;
      // }

      // // Validate time selection - Only highlight time tab, not date
      // if (startTimeController.text.isEmpty) {
      //   _errors['time'] = 'Please select a time for the follow-up';
      //   isValid = false;
      // }

      if (startDateController.text.isEmpty) {
        _errors['date'] = 'Please select a date';
        isValid = false;
      }

      if (startTimeController.text.isEmpty) {
        _errors['time'] = 'Please select a time';
        isValid = false;
      }
    });

    // Check validity before calling the API
    if (!isValid) {
      setState(() => isSubmitting = false);

      // This means user has filled the form but just missing the time
      if (_errors.containsKey('time') &&
          _leadId != null &&
          _leadId!.isNotEmpty &&
          _selectedSubject.isNotEmpty &&
          startDateController.text.isNotEmpty) {
        _showTimeValidationSnackbar();
      }
      return;
    }

    try {
      await submitForm();
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
  // void _submit() async {
  //   if (isSubmitting) return;

  //   bool isValid = true;

  //   setState(() {
  //     isSubmitting = true;
  //     _errors = {};

  //     // Validate lead selection
  //     if (_leadId == null || _leadId!.isEmpty) {
  //       _errors['select lead name'] = 'Please select a lead name';
  //       isValid = false;
  //     }

  //     // Validate action selection
  //     if (_selectedSubject == null || _selectedSubject!.isEmpty) {
  //       _errors['subject'] = 'Please select an action';
  //       isValid = false;
  //     }

  //     // Validate date selection
  //     if (startDateController.text.isEmpty) {
  //       _errors['date'] = 'Please select a date';
  //       isValid = false;
  //     }

  //     // Validate time selection - Only highlight time tab, not date
  //     if (startTimeController.text.isEmpty) {
  //       _errors['time'] = 'Please select a time for the follow-up';
  //       isValid = false;
  //     }
  //   });

  //   // Check validity before calling the API
  //   if (!isValid) {
  //     setState(() => isSubmitting = false);

  //     // Show specific error snackbar for time validation
  //     if (_errors.containsKey('time')) {
  //       _showTimeValidationSnackbar();
  //     }
  //     return;
  //   }

  //   try {
  //     await submitForm();
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'Submission failed: ${e.toString()}',
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   } finally {
  //     setState(() => isSubmitting = false);
  //   }
  // }

  // Show specific time validation snackbar at the top
  void _showTimeValidationSnackbar() {
    Get.snackbar(
      'Time Required',
      'Please select a time for the follow-up',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red[500],
      colorText: Colors.white,
      icon: Icon(Icons.access_time, color: Colors.white),
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  /// Submit form
  Future<void> submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? spId = prefs.getString('user_id');

    try {
      final rawStartDate = DateFormat(
        'dd MMM yyyy',
      ).parse(startDateController.text);
      final rawEndDate = DateFormat(
        'dd MMM yyyy',
      ).parse(endDateController.text);

      final rawStartTime = DateFormat(
        'hh:mm a',
      ).parse(startTimeController.text);
      final rawEndTime = DateFormat('hh:mm a').parse(endTimeController.text);

      // Format for API
      final formattedStartDate = DateFormat('dd-MM-yyyy').format(rawStartDate);
      final formattedEndDate = DateFormat('dd/MM/yyyy').format(rawEndDate);

      final formattedStartTime = DateFormat('hh:mm a').format(rawStartTime);
      final formattedEndTime = DateFormat('HH:mm:ss').format(rawEndTime);

      final newTaskForLead = {
        'subject': _selectedSubject,
        'status': 'Not Started',
        'priority': 'High',
        'time': formattedStartTime,
        'due_date': formattedStartDate,
        'remarks': descriptionController.text,
        'sp_id': spId,
        'lead_id': _leadId,
      };

      bool success = await LeadsSrv.submitFollowups(
        newTaskForLead,
        _leadId!,
        context,
      );

      if (success) {
        
        Navigator.pop(context, true);
        showSuccessMessage(
          context,
          message: 'Follow-up created successfully for $formattedStartDate',
        );
        widget.onFormSubmit?.call();
        widget.onTabChange?.call(0);
      } else {
        showErrorMessageGetx(message: 'Failed to submit appointment.');
      }
    } catch (e) {
      showErrorMessage(
        context,
        message: 'Invalid input. Please check your entries.',
      );
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
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  minLines: 1,
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
      String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);

      setState(() {
        startDateController.text = formattedDate;
        endDateController.text = formattedDate;
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
        endTimeController.text = formattedEndTime;
        // Clear time error when time is selected
        if (_errors.containsKey('time')) {
          _errors.remove('time');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

            LeadTextfield(
              resions:
                  'This enquiry has no number associated to it, please add one before creating a Followups',
              isRequired: true,
              onChanged: (value) {
                if (_errors.containsKey('select lead name')) {
                  setState(() {
                    _errors.remove('select lead name');
                  });
                }
                print("select lead name : $value");
              },
              onClearSelection: () {
                setState(() {
                  _leadId = null;
                  _leadName = null;
                  _errors['select lead name'] = 'Please select a lead name';
                });
              },
              errorText: _errors['select lead name'],
              onLeadSelected: (leadId, leadName) {
                setState(() {
                  _leadId = leadId;
                  _leadName = leadName;
                });
              },
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

            const SizedBox(height: 15),

            // FIXED: Only pass error text when there's a date error (not time error)
            DateButton(
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

            const SizedBox(height: 10),

            EnhancedSpeechTextField(
              isRequired: false,
              label: 'Remarks:',
              error: false,
              controller: descriptionController,
              hint: 'Type or speak... ',
              onChanged: (text) {
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
                      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
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
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 45,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromARGB(255, 248, 247, 247),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? "Select" : controller.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: controller.text.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.fontColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker1({
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 45,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromARGB(255, 248, 247, 247),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? "Select" : controller.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: controller.text.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.watch_later_outlined,
                  color: AppColors.fontColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
