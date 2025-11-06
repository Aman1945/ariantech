import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/environment/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/widgets/google_location.dart';
import 'package:smartassist/widgets/popups_widget/vehicleSearch_textfield.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/reusable/slot_calendar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TestdriveIds extends StatefulWidget {
  final Function onFormSubmit;
  final String leadId;
  final String vehicle_id;
  final String PMI;
  TestdriveIds({
    super.key,
    required this.leadId,
    required this.onFormSubmit,
    required this.vehicle_id,
    required this.PMI,
  });

  @override
  State<TestdriveIds> createState() => _TestdriveIdsState();
}

class _TestdriveIdsState extends State<TestdriveIds> {
  String? selectedVehicleName;
  String? selectedBrand;
  Map<String, dynamic>? selectedVehicleData;
  List<Map<String, String>> dropdownItems = [];
  bool isLoading = false;
  List<dynamic> vehicleList = [];
  List<String> uniqueVehicleNames = [];
  String? selectedLeads;
  String? selectedLeadsName;
  String? selectedPriority;
  String? vehicleId;
  // String? houseOfBrand;
  bool isSelected = false;
  late stt.SpeechToText _speech;
  bool isSubmitting = false;
  Map<String, dynamic>? slotData;
  bool isPMIPreSelected = false;

  Map<String, String> _errors = {};
  String get _googleApiKey => Environment.googleMapsApiKey;

  // final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    if (widget.PMI.isNotEmpty && widget.vehicle_id.isNotEmpty) {
      setState(() {
        isPMIPreSelected = true;
        selectedVehicleName = widget.PMI;
        vehicleId = widget.vehicle_id;
      });
    }
  }

  @override
  void dispose() {
    // _searchController1.removeListener(_onSearchChanged1);
    _searchController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (isSubmitting) return;

    bool isValid = true;

    setState(() {
      isSubmitting = true;
      _errors = {};

      // Validate date selection first
      if (startDateController.text.isEmpty) {
        _errors['select_slot'] = 'Please select a date and time slot';
        isValid = false;
      }

      // Validate time slots (both start and end time must be selected)
      if (slotData == null ||
          slotData?['start_time_slot'] == null ||
          slotData?['start_time_slot'].isEmpty) {
        _errors['select_start_time'] = '';
        isValid = false;
      }

      if (slotData == null ||
          slotData?['end_time_slot'] == null ||
          slotData?['end_time_slot'].isEmpty) {
        _errors['select_end_time'] = '';
        isValid = false;
      }
    });

    if (!isValid) {
      setState(() => isSubmitting = false);
      return;
    }

    try {
      print('Submitting form with slotData: $slotData');
      await submitForm();
    } catch (e) {
      print('Submission error: $e');
      showErrorMessage(
        context,
        message: 'Submission failed: Not a valid location',
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

  //     if (startDateController == null || startDateController.text!.isEmpty) {
  //       _errors['date'] = 'Please select an action';
  //       isValid = false;
  //     }

  //     if (slotData == null) {
  //       _errors['select_slot'] = 'Please select a date and time slot';
  //       isValid = false;
  //     } else {
  //       // Only check for start/end time if a date is selected
  //       if (slotData?['start_time_slot'] == null ||
  //           slotData?['start_time_slot'].isEmpty) {
  //         _errors['select_start_time'] = '';
  //         isValid = false;
  //       }

  //       if (slotData?['end_time_slot'] == null ||
  //           slotData?['end_time_slot'].isEmpty) {
  //         _errors['select_end_time'] = '';
  //         isValid = false;
  //       }
  //     }
  //   });

  //   // 💡 Check validity before calling the API
  //   if (!isValid) {
  //     setState(() => isSubmitting = false);
  //     return;
  //   }

  //   try {
  //     await submitForm(); // ✅ Only call if valid
  //     // Show snackbar or do post-submit work here
  //   } catch (e) {
  //     print(e.toString());
  //   } finally {
  //     setState(() => isSubmitting = false);
  //   }
  // }

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
              'Create TestDrive',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehiclesearchTextfield(
                initialVehicleName: widget.PMI.isNotEmpty
                    ? widget.PMI
                    : null, // Pass PMI here
                initialVehicleId: widget.vehicle_id.isNotEmpty
                    ? widget.vehicle_id
                    : null, // Pass vehicle_id here
                onVehicleSelected: (selectedVehicle) {
                  setState(() {
                    // Handle clearing
                    if (selectedVehicle.isEmpty) {
                      selectedVehicleData = null;
                      selectedVehicleName = widget.PMI.isNotEmpty
                          ? widget.PMI
                          : null; // Revert to original PMI
                      vehicleId = widget.vehicle_id.isNotEmpty
                          ? widget.vehicle_id
                          : null;
                      selectedBrand = null;
                      return;
                    }

                    // Handle new selection
                    selectedVehicleData = selectedVehicle;
                    selectedVehicleName = selectedVehicle['vehicle_name'];
                    vehicleId = selectedVehicle['vehicle_id'];
                    // houseOfBrand = selectedVehicle['houseOfBrand'];
                    selectedBrand = selectedVehicle['brand'] ?? '';
                  });

                  print("Selected Vehicle: $selectedVehicleName");
                  print("Selected Brand: ${selectedBrand ?? 'No Brand'}");
                },
              ),

              const SizedBox(height: 5),
              CustomGooglePlacesField(
                controller: _locationController,
                hintText: 'Enter location',
                label: 'Location',
                onChanged: (value) {},
                googleApiKey: _googleApiKey,
                isRequired: true,
              ),
              const SizedBox(height: 15),
              SlotCalendar(
                label: 'Select Date & Time Slot',
                isRequired: true,
                controller: startDateController,

                errorText: _errors['select_slot'], // Date error
                startTimeError:
                    _errors['select_start_time'], // Start time error
                endTimeError: _errors['select_end_time'], // End time error
                vehicleId:
                    vehicleId?.toString() ??
                    '', // This gets the vehicle ID from either source

                onChanged: (value) {
                  try {
                    if (value == 'date_selected') {
                      setState(() {
                        _errors.remove('select_slot'); // Clear date error
                      });
                      return;
                    }

                    if (value == 'clear_start_time_error') {
                      setState(() {
                        _errors.remove('select_start_time');
                      });
                      return;
                    }

                    if (value == 'clear_end_time_error') {
                      setState(() {
                        _errors.remove('select_end_time');
                      });
                      return;
                    }

                    final parsedSlotData = jsonDecode(value);
                    print('Slot data received: $parsedSlotData');

                    setState(() {
                      slotData = parsedSlotData;
                      _errors.remove('select_slot');
                      _errors.remove('select_start_time');
                      _errors.remove('select_end_time');
                    });

                    print('slotData variable set to: $slotData');
                  } catch (e) {
                    print('Slot changed (not JSON): $value');
                  }
                },

                onTextFieldTap: () {
                  print('Calendar container tapped');
                },
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
    );
  }

  Future<void> submitForm() async {
    // Retrieve sp_id from SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final spId = prefs.getString('user_id');

    final leadId = widget.leadId;
    // final vehicleId = widget

    final rawStartDate = DateTime.parse(slotData!['date']);
    final rawEndDate = DateTime.parse(slotData!['date']); // Automatically set
    final formattedStartDate = DateFormat('dd/MM/yyyy').format(rawStartDate);
    final formattedEndDate = DateFormat('dd/MM/yyyy').format(rawEndDate);

    final rawStartTime = DateFormat(
      'HH:mm:ss',
    ).parse(slotData!['start_time_slot']);
    final rawEndTime = DateFormat('HH:mm:ss').parse(slotData!['end_time_slot']);
    final formattedStartTime = DateFormat('hh:mm a').format(rawStartTime);
    final formattedEndTime = DateFormat(
      'HH:mm:ss',
    ).format(rawEndTime); // Automatically set
    if (spId == null || leadId.isEmpty) {
      showErrorMessage(
        context,
        message: 'User ID or Lead ID not found. Please log in again.',
      );
      return;
    }
    if (spId == null || leadId.isEmpty) {
      showErrorMessage(
        context,
        message: 'User ID or Lead ID not found. Please log in again.',
      );
      return;
    }

    // Prepare the appointment data.
    final testdriveData = {
      'vehicleId': vehicleId,
      // 'houseOfBrand': slotData!['houseOfBrand'],
      'start_date': formattedStartDate,
      'end_date': formattedEndDate,
      'start_time': formattedStartTime,
      'end_time': formattedEndTime,
      'date_of_booking': slotData!['date'],
      'start_time_slot': slotData!['start_time_slot'],
      'end_time_slot': slotData!['end_time_slot'],
      'remarks': descriptionController.text,
      'PMI': selectedVehicleName,
      'location': _locationController.text.trim(),
      'sp_id': spId,
    };

    // Call the service to submit the appointment.
    final success = await LeadsSrv.submitTestDrive(
      testdriveData,
      widget.leadId,
    );

    print('this is the latest obj: $testdriveData');

    if (success) {
      if (context.mounted) {
        Navigator.pop(context, true); // Close the modal on success.
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test drive created successfully',
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
      widget.onFormSubmit(widget.leadId);
    } else {
      showErrorMessage(context, message: 'Failed to submit appointment.');
    }
  }
}
