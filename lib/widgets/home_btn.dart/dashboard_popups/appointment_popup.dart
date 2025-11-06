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
import 'package:smartassist/widgets/popups_widget/leadSearch_textfield.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/reusable/action_button.dart';
import 'package:smartassist/widgets/reusable/date_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AppointmentPopup extends StatefulWidget {
  final Function onFormSubmit;
  final Function(int)? onTabChange;
  const AppointmentPopup({
    super.key,
    required this.onFormSubmit,
    this.onTabChange,
  });

  @override
  State<AppointmentPopup> createState() => _AppointmentPopupState();
}

class _AppointmentPopupState extends State<AppointmentPopup> {
  String? _leadId;
  String? _leadName;
  // final PageController _pageController = PageController();
  List<Map<String, String>> dropdownItems = [];
  bool isLoading = false;
  int _currentStep = 0;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  Map<String, String> _errors = {};
  bool isSubmitting = false;

  bool _isLoadingSearch = false;
  String _query = '';
  String? selectedLeads;
  String _selectedSubject = '';
  String? selectedLeadsName;
  String? selectedPriority;

  List<dynamic> _searchResults = [];

  final TextEditingController _searchController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // fetchDropdownData();

    _speech = stt.SpeechToText();
    _initSpeech();
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

  Future<void> _pickDate({required bool isStartDate}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        String formattedDateTime = DateFormat(
          'dd/MM/yyyy hh:mm a',
        ).format(combinedDateTime);
        setState(() {
          if (isStartDate) {
            startDateController.text = formattedDateTime;
          } else {
            endDateController.text = formattedDateTime;
          }
        });
      }
    }
  }

  void _submit() async {
    if (isSubmitting) return;

    bool isValid = true;

    setState(() {
      isSubmitting = true;
      _errors = {};

      if (_leadId == null || _leadId!.isEmpty) {
        _errors['select lead name'] = 'Please select a lead name';
        isValid = false;
      }

      if (_selectedSubject == null || _selectedSubject!.isEmpty) {
        _errors['subject'] = 'Please select an action';
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
      print(e.toString());
      // Get.snackbar(
      //   'Error',
      //   'Submission failed: ${e.toString()}',
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    } finally {
      setState(() => isSubmitting = false);
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
      firstDate: DateTime.now(),
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
      // Check if the selected date is today
      DateTime selectedDate;
      try {
        if (startDateController.text.isNotEmpty) {
          selectedDate = DateFormat(
            'dd MMM yyyy',
          ).parse(startDateController.text);
        } else {
          selectedDate = DateTime.now();
        }
      } catch (e) {
        selectedDate = DateTime.now();
      }

      // If the selected date is today, check if the time is in the past
      bool isToday =
          selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day;

      if (isToday) {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // If selected time is in the past, show error and return
        if (selectedDateTime.isBefore(now)) {
          Get.snackbar(
            'Error',
            'Please select a future time',
            colorText: Colors.white,
            backgroundColor: Colors.red[400],
          );
          return;
        }
      }

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Create Appointment',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildSearchField(),
              LeadTextfield(
                resions:
                    'This enquiry has no number associated to it, please add one before creating a Appointment',

                isRequired: true,
                onChanged: (value) {
                  if (_errors.containsKey('select lead name')) {
                    setState(() {
                      _errors.remove('select lead name');
                    });
                  }
                  print("select lead name : $value");
                },
                errorText: _errors['select lead name'],
                onLeadSelected: (leadId, leadName) {
                  setState(() {
                    _leadId = leadId;
                    _leadName = leadName;
                  });
                },
                onClearSelection: () {
                  setState(() {
                    _leadId = null;
                    _leadName = null;
                    _errors['select lead name'] = 'Please select a lead name';
                  });
                },
              ),
              const SizedBox(height: 15),
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

              ActionButton(
                label: "Action:",
                isRequired: true,
                options: {
                  "Meeting": "Meeting",
                  "Vehicle selection": "Vehicle Selection",
                  "Showroom appointment": "Showroom appointment",
                  "Trade in evaluation": "Trade in evaluation",
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
              const SizedBox(height: 10),
            ],
          ),
          // const SizedBox(height: ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: AppFont.buttons(context)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorsBlueButton,
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
    );
  }

  Future<void> submitForm() async {
    final prefs = await SharedPreferences.getInstance();
    final spId = prefs.getString('user_id');

    try {
      // Parse raw date and time
      final rawStartDate = DateFormat(
        'dd MMM yyyy',
      ).parse(startDateController.text);
      final rawEndDate = DateFormat(
        'dd MMM yyyy',
      ).parse(endDateController.text); // Automatically set

      final rawStartTime = DateFormat(
        'hh:mm a',
      ).parse(startTimeController.text);
      final rawEndTime = DateFormat(
        'hh:mm a',
      ).parse(endTimeController.text); // Automatically set

      // Format for API
      final formattedStartDate = DateFormat('dd/MM/yyyy').format(rawStartDate);
      final formattedEndDate = DateFormat(
        'dd/MM/yyyy',
      ).format(rawEndDate); // Automatically set

      // final formattedStartTime = DateFormat('HH:mm:ss').format(rawStartTime);

      // final formattedStartTime = DateFormat('hh:mm a').format(rawStartTime);
      final formattedStartTime = DateFormat('hh:mm a').format(rawStartTime);
      final formattedEndTime = DateFormat(
        'HH:mm:ss',
      ).format(rawEndTime); // Automatically set

      final appointmentData = {
        'due_date': formattedStartDate,
        // 'end_date': formattedEndDate, // Automatically passed to API
        'time': formattedStartTime,
        // 'end_time': formattedEndTime, // Automatically passed to API
        'priority': selectedPriority,
        'subject': _selectedSubject,
        'sp_id': spId,
        'remarks': descriptionController.text,
      };

      final success = await LeadsSrv.submitAppoinment(
        appointmentData,
        _leadId!,
      );

      if (success) {
        if (context.mounted) {
          Navigator.pop(context, true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment created successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // widget.onFormSubmit();
        widget.onFormSubmit?.call(); // Refresh dashboard data
        widget.onTabChange?.call(1);
      } else {
        showErrorMessageGetx(message: 'Failed to submit appointment.');
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
