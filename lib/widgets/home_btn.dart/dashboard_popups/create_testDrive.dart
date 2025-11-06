import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/environment/environment.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/widgets/google_location.dart';
import 'package:smartassist/widgets/remarks_field.dart';
import 'package:smartassist/widgets/reusable/leadsearch_testdrive.dart';
import 'package:smartassist/widgets/reusable/slot_calendar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CreateTestdrive extends StatefulWidget {
  final Function onFormSubmit;
  final Function(int)? onTabChange;
  final Function? dashboardRefresh;
  const CreateTestdrive({
    super.key,
    required this.onFormSubmit,
    this.onTabChange,
    this.dashboardRefresh,
  });

  @override
  State<CreateTestdrive> createState() => _CreateTestdriveState();
}

class _CreateTestdriveState extends State<CreateTestdrive> {
  PlaceDetails? selectedPlaceDetails;
  String? _leadId;
  String? _leadName;
  bool isSubmitting = false;
  String? selectedVehicleName;
  String? selectedBrand;
  String? vehicleId;
  Map<String, dynamic>? selectedVehicleData;
  // final PageController _pageController = PageController();
  List<Map<String, String>> dropdownItems = [];
  bool isLoading = false;
  Map<String, String> _errors = {};
  Map<String, dynamic>? slotData;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLocationValid = true;

  String? selectedLeads;
  String? selectedLeadsName;
  String? selectedPriority;
  List<dynamic> vehicleList = [];
  List<String> uniqueVehicleNames = [];
  List<String> colorOptions = [];
  String? selectedColor;
  String? selectedExteriorColor;
  String? selectedInteriorColor;
  List<String> exteriorOptions = [];
  List<String> interiorOptions = [];

  // List<dynamic> _searchResults = [];
  List<dynamic> vehicleName = [];

  // Google Maps API key
  String get _googleApiKey => Environment.googleMapsApiKey;

  final TextEditingController _locationController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
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

      if (_leadId == null || _leadId!.isEmpty) {
        _errors['select lead name'] = 'Please select a lead name';
        isValid = false;
      }

      if (_locationController.text.isNotEmpty && !_isLocationValid) {
        _errors['location'] = 'Please select a valid location from suggestions';
        isValid = false;
      }

      if (slotData == null) {
        _errors['select_slot'] = 'Please select a date and time slot';
        isValid = false;
      } else {
        // Only check for start/end time if a date is selected
        if (slotData?['start_time_slot'] == null ||
            slotData?['start_time_slot'].isEmpty) {
          _errors['select_start_time'] = '';
          isValid = false;
        }

        if (slotData?['end_time_slot'] == null ||
            slotData?['end_time_slot'].isEmpty) {
          _errors['select_end_time'] = '';
          isValid = false;
        }
      }
    });
    if (!isValid) {
      setState(() => isSubmitting = false);

      return;
    }

    // Continue with your submission...
    try {
      print('Submitting form with slotData: $slotData'); // Debug log
      await submitForm(); // ✅ Only call if valid
    } catch (e) {
      print('Submission error: $e'); // Debug log
      Get.snackbar(
        'Error',

        // 'Submission failed: ${e.toString()}',
        'Submission failed: Not a valid location',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isSubmitting = false);
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
              'Create Test Drive',
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
              LeadsearchTestdrive(
                onChanged: (String value) {
                  if (_errors.containsKey('select lead name')) {
                    setState(() {
                      _errors.remove('select lead name');
                    });
                  }
                  // Handle lead search input changes
                  print('Lead search input changed: $value');
                },
                isRequired: true, // Set to true if lead selection is mandatory
                errorText: _errors['select lead name'],
                onLeadSelected: (leadId, leadName) {
                  setState(() {
                    _leadId = leadId;
                    _leadName = leadName;

                    // Clear slot data when lead changes since vehicle might change
                    slotData = {};
                    startDateController.clear();
                  });

                  // Handle lead selection
                  print('Lead selected: ID = $leadId, Name = $leadName');
                },
                onClearSelection: () {
                  setState(() {
                    // Clear all related data when lead selection is cleared
                    _leadId = null;
                    _leadName = null;
                    selectedVehicleData = {};
                    selectedVehicleName = null;
                    vehicleId = null;
                    selectedBrand = null;
                    slotData = {};
                    startDateController.clear();
                  });
                  // Handle clearing of lead selection
                  print('Lead selection cleared');
                },
                onVehicleSelected: (Map<String, dynamic> selectedVehicle) {
                  setState(() {
                    selectedVehicleData = selectedVehicle;
                    selectedVehicleName = selectedVehicle['vehicle_name'];
                    vehicleId = selectedVehicle['vehicle_id'];
                    selectedBrand = selectedVehicle['brand'] ?? '';
                    slotData = {};
                    startDateController.clear();
                  });

                  // Log the vehicle selection
                  if (selectedVehicle['from_lead'] == true) {
                    print(
                      'Vehicle auto-selected from lead PMI: ${selectedVehicle['vehicle_name']} (ID: ${selectedVehicle['vehicle_id']})',
                    );
                  } else {
                    print(
                      'Vehicle manually selected: ${selectedVehicle['vehicle_name']} (ID: ${selectedVehicle['vehicle_id']})',
                    );
                  }
                },
              ),

              const SizedBox(height: 5),
              CustomGooglePlacesField(
                controller: _locationController,
                hintText: 'Enter location',
                label: 'Location',
                onChanged: (value) {},
                onPlaceSelected: (placeDetails) {
                  // This callback is triggered when user selects a place
                  selectedPlaceDetails = placeDetails;
                  if (placeDetails != null) {
                    // print('Selected place details:');
                    // print('Lat: ${placeDetails.lat}');
                    // print('Lng: ${placeDetails.lng}');
                    // print('City: ${placeDetails.city}');
                    // print('Pincode: ${placeDetails.pincode}');
                    // print('State: ${placeDetails.state}');
                    // print('Country: ${placeDetails.country}');
                    // print('Address: ${placeDetails.address}');
                  }
                },
                onValidationChanged: (isValid) {
                  setState(() {
                    _isLocationValid = isValid;
                    // Clear location error if input becomes valid
                    if (isValid && _errors.containsKey('location')) {
                      _errors.remove('location');
                    }
                  });
                },
                googleApiKey: _googleApiKey,
                isRequired: true,
                errorText: _errors['location'],
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
                // onChanged: (value) {
                //   try {
                //     if (value == 'clear_start_time_error') {
                //       setState(() {
                //         _errors.remove('select_start_time');
                //       });
                //       return;
                //     }

                //     if (value == 'clear_end_time_error') {
                //       setState(() {
                //         _errors.remove('select_end_time');
                //       });
                //       return;
                //     }
                //     final parsedSlotData = jsonDecode(value);
                //     print('Slot data received: $parsedSlotData');

                //     setState(() {
                //       slotData = parsedSlotData;
                //       // Clear the error if it exists
                //       if (_errors.containsKey('select_slot')) {
                //         _errors.remove('select_slot');
                //       }
                //       _errors.remove('select_slot');
                //       _errors.remove('select_start_time');
                //       _errors.remove('select_end_time');
                //     });

                //     print('slotData variable set to: $slotData'); // Debug log
                //   } catch (e) {
                //     // If it's not JSON (like initial date selection), just print
                //     print('Slot changed: $value');
                //   }
                // },
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

              // const SizedBox(height: 10),
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
                  textCapitalization: TextCapitalization.sentences,
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

  Future<void> submitForm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spId = prefs.getString('user_id');

      final rawStartDate = DateTime.parse(slotData!['date']);
      final rawEndDate = DateTime.parse(slotData!['date']); // Automatically set
      final formattedStartDate = DateFormat('dd/MM/yyyy').format(rawStartDate);
      final formattedEndDate = DateFormat('dd/MM/yyyy').format(rawEndDate);

      final rawStartTime = DateFormat(
        'HH:mm:ss',
      ).parse(slotData!['start_time_slot']);
      final rawEndTime = DateFormat(
        'HH:mm:ss',
      ).parse(slotData!['end_time_slot']);
      final formattedStartTime = DateFormat('hh:mm a').format(rawStartTime);
      final formattedEndTime = DateFormat(
        'HH:mm:ss',
      ).format(rawEndTime); // Automatically set

      final testdriveData = {
        'vehicleId': vehicleId,
        'start_date': formattedStartDate,
        'end_date': formattedEndDate,
        'start_time': formattedStartTime,
        'end_time': formattedEndTime,
        'date_of_booking': slotData!['date'],
        'start_time_slot': slotData!['start_time_slot'],
        'end_time_slot': slotData!['end_time_slot'],
        'PMI': selectedVehicleName,
        'sp_id': spId,
        'remarks': descriptionController.text.trim(),
        'location':
            (_locationController.text.trim().isNotEmpty && _isLocationValid)
            ? _locationController.text.trim()
            : '',
        if (_locationController.text.trim().isNotEmpty && _isLocationValid)
          "places": selectedPlaceDetails!.toJson(),
      };
      final success = await LeadsSrv.submitTestDrive(testdriveData, _leadId!);
      print('Submitting testdrive data: $testdriveData');

      if (success) {
        if (context.mounted) {
          Navigator.pop(context, true);
        }
        showSuccessMessage(
          context,
          message: 'Testdrive created successfully for $formattedStartDate',
        );
        widget.onFormSubmit();
        widget.dashboardRefresh!();
        widget.onTabChange?.call(2);
      } else {
        showErrorMessage(context, message: 'Failed to submit Testdrive.');
      }
    } catch (e) {
      if (context.mounted) {
        print(e.toString());
      }
      rethrow;
    }
  }
}
