import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/environment/environment.dart';
import 'package:smartassist/config/getX/fab.controller.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/google_location.dart';
import 'package:smartassist/widgets/popups_widget/vehicleSearch_textfield.dart';
import 'package:smartassist/widgets/reusable/vehicle_colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CreateLeads extends StatefulWidget {
  final Function onFormSubmit;
  final Function? dashboardRefresh;
  const CreateLeads({
    super.key,
    required this.onFormSubmit,
    this.dashboardRefresh,
  });

  @override
  State<CreateLeads> createState() => _CreateLeadsState();
}

class _CreateLeadsState extends State<CreateLeads> {
  String? selectedVehicleName;
  String? selectedBrand;
  String? vehicleId;
  String? houseOfBrand;
  Map<String, dynamic>? selectedVehicleData;
  final PageController _pageController = PageController();
  List<Map<String, String>> dropdownItems = [];
  bool isLoading = true;
  bool _isLoading = true;
  int _currentStep = 0;
  List<dynamic> vehicleList = [];
  List<String> uniqueVehicleNames = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool isSubmitting = false;

  bool _isLoadingColor = false;
  String _ColorQuery = '';
  List<dynamic> _searchResultsColor = [];
  String? selectedColorName;
  String? selectedVehicleColorId;
  String? selectedUrl;

  List<dynamic> _searchResults = [];

  // Campaign related variables - exactly like vehicle search
  List<dynamic> _searchResultsCampaign = [];
  bool _isLoadingCampaignSearch = false;
  String _campaignQuery = '';
  String? selectedCampaignName;
  String? selectedCampaignId;
  Map<String, dynamic>? selectedCampaignData;
  final TextEditingController _searchControllerCampaign =
      TextEditingController();

  // Form error tracking
  Map<String, String> _errors = {};
  bool _isLoadingSearch = false;
  String _selectedType = '';
  String _selectedPurchaseType = '';
  String _selectedEnquiryType = '';
  String _selectedHaloOption = ''; // State for the new "Halo?" radio group
  Map<String, dynamic>? _existingLeadData;

  // Define constants
  final double _minValue = 4000000; // 40 lakhs
  final double _maxValue = 40000000; // 400 lakhs (2 crore)

  // Initialize range values within min-max bounds
  late RangeValues _rangeAmount;
  List<dynamic> vehicleName = [];
  String selectedSubType = 'Retail';
  String? _locationErrorText;
  // Google Maps API key
  String get _googleApiKey => Environment.googleMapsApiKey;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchControllerVehicleColor =
      TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();

  TextEditingController mobileController = TextEditingController();
  TextEditingController mobileSecondController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController modelInterestController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool consentValue = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    print('this is the key :${Environment.googleMapsApiKey}');
    _rangeAmount = RangeValues(_minValue, _maxValue);
    _searchController.addListener(_onSearchChanged);
    _searchControllerVehicleColor.addListener(_onVehicleColorSearchChanged);
    _searchControllerCampaign.addListener(_onCampaignSearchChanged);
    // Initialize speech recognition
    // _speech = stt.SpeechToText();
    // _initSpeech();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchControllerVehicleColor.removeListener(_onVehicleColorSearchChanged);
    _searchControllerCampaign.removeListener(_onCampaignSearchChanged);
    _searchController.dispose();
    _locationController.dispose();
    _searchControllerCampaign.dispose();
    super.dispose();
  }

  Future<void> fetchCampaignData(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResultsCampaign = [];
        _isLoadingCampaignSearch = false;
      });
      return;
    }

    final token = await Storage.getToken();

    setState(() {
      _isLoadingCampaignSearch = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.smartassistapp.in/api/leads/campaigns/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['data'] ?? [];

        // Debug: Print the structure of campaign data
        if (results.isNotEmpty) {
          print("Campaign data structure: ${results.first}");
        }

        // Filter campaigns based on query
        final List<dynamic> filteredResults = results.where((campaign) {
          final campaignName =
              campaign['campaign_name']?.toString().toLowerCase() ?? '';
          return campaignName.contains(query.toLowerCase());
        }).toList();

        setState(() {
          _searchResultsCampaign = filteredResults;
        });
      } else {
        print("Failed to load campaigns: ${response.statusCode}");
        setState(() {
          _searchResultsCampaign = [];
        });
      }
    } catch (e) {
      print("Error fetching campaigns: $e");
      setState(() {
        _searchResultsCampaign = [];
      });
    } finally {
      setState(() {
        _isLoadingCampaignSearch = false;
      });
    }
  }

  void _onCampaignSearchChanged() {
    final newQuery = _searchControllerCampaign.text.trim();
    if (newQuery == _campaignQuery) return;

    _campaignQuery = newQuery;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_campaignQuery == _searchControllerCampaign.text.trim()) {
        fetchCampaignData(_campaignQuery);
      }
    });
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

  // Add this helper method for showing error messages
  void showErrorMessage(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> fetchVehicleData(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
      return;
    }

    final token = await Storage.getToken();

    setState(() {
      _isLoadingSearch = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.smartassistapp.in/api/search/vehicles?vehicle=${Uri.encodeComponent(query)}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['data']['suggestions'] ?? [];

        final Set<String> seenNames = {};
        final List<dynamic> uniqueResults = [];

        for (var vehicle in results) {
          final name = vehicle['vehicle_name'];
          if (name != null && seenNames.add(name)) {
            uniqueResults.add(vehicle);
          }
        }

        setState(() {
          _searchResults = uniqueResults;
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
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
        fetchVehicleData(_query);
      }
    });
  }

  Future<void> _fetchVehicleColorSearchResults(String query) async {
    print("Inside _fetchVehicleColorSearchResults with query: '$query'");

    if (query.isEmpty) {
      setState(() {
        _searchResultsColor.clear();
      });
      return;
    }

    setState(() {
      _isLoadingColor = true;
    });

    try {
      final token = await Storage.getToken();

      final apiUrl =
          'https://api.smartassistapp.in/api/search/vehicle-color?color=$query';
      print("API URL: $apiUrl");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("API Response status: ${response.statusCode}");
      print("API Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _searchResultsColor = data['data']['results'] ?? [];
          print("Search results loaded: ${_searchResultsColor.length}");
        });
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        showErrorMessage(context, message: 'API Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during API call: $e");
      showErrorMessage(context, message: 'Something went wrong..! $e');
    } finally {
      setState(() {
        _isLoadingColor = false;
      });
    }
  }

  void _onVehicleColorSearchChanged() {
    final newQuery = _searchControllerVehicleColor.text.trim();
    if (newQuery == _ColorQuery) return;

    _ColorQuery = newQuery;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_ColorQuery == _searchControllerVehicleColor.text.trim()) {
        _fetchVehicleColorSearchResults(_ColorQuery);
      }
    });
  } //9

  // Method to check if lead exists
  Future<void> _checkExistingLead(String mobileNumber) async {
    final token = await Storage.getToken();

    // Add the country code before making the API call
    // if (!mobileNumber.startsWith('+91')) {
    //   mobileNumber = '+91' + mobileNumber;
    //   print('Adding country code: $mobileNumber');
    // }

    // URL encode the phone number to handle the + symbol
    final encodedMobile = Uri.encodeComponent(mobileNumber);

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.smartassistapp.in/api/leads/existing-check?mobile=$encodedMobile',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('this is body');
        print(response.body);

        // Check if lead exists based on the API response structure
        if (data['status'] == 200 && data['data'] != null) {
          setState(() {
            _existingLeadData = {
              'name': data['data']['lead_name'] ?? 'Unknown',
              'mobile': data['data']['mobile'] ?? mobileNumber,
              'status': data['data']['status'] ?? 'no-status',
              'PMI': data['data']['PMI'] ?? 'Unknown',
              'lead_owner': data['data']['lead_owner'] ?? 'Unknown',
            };
          });
          print("Existing lead found: ${_existingLeadData}");
        } else {
          setState(() {
            _existingLeadData = null;
          });
          print("No existing lead found");
        }
      }
    } catch (e) {
      print('Error checking existing lead: $e');
      setState(() {
        _existingLeadData = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    FocusScope.of(context).unfocus();
    final DateTime today = DateTime.now();
    final DateTime initialDate = today;
    final DateTime lastDate = DateTime(2100);
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {
        if (isStartDate) {
          startDateController.text = formattedDate;
          _errors.remove('startDate');
        } else {
          endDateController.text = formattedDate;
        }
      });
    }
  }

  // Validate page 1 fields
  bool _validatePage1() {
    bool isValid = true;
    setState(() {
      _errors = {}; // Clear previous errors

      String fname = firstNameController.text.trim();
      String lname = lastNameController.text.trim();
      // Validate first name
      if (fname.isEmpty) {
        _errors['firstName'] = 'First name is required';
        isValid = false;
      } else if (!_isValidFirst(fname)) {
        _errors['firstName'] = 'Invalid first name format';
        isValid = false;
      }

      // Validate last name
      if (lname.isEmpty) {
        _errors['lastName'] = 'Last name is required';
        isValid = false;
      } else if (!_isValidSecond(lname)) {
        _errors['lastName'] = 'Invalid last name format';
        isValid = false;
      }

      // Email validation - removed required validation
      if (emailController.text.trim().isEmpty) {
        _errors['email'] = 'Email is required';
        isValid = false;
      } else if (!_isValidEmail(emailController.text.trim())) {
        _errors['email'] = 'Please enter a valid email';
        isValid = false;
      }

      // Validate mobile
      if (mobileController.text.trim().isEmpty) {
        _errors['mobile'] = 'Mobile number is required';
        isValid = false;
      } else if (!_isValidMobile(mobileController.text.trim())) {
        _errors['mobile'] =
            'Please enter a valid 10-digit Indian mobile number';
        isValid = false;
      }

      if (_existingLeadData != null) {
        _errors['mobile'] = 'This mobile number already exists';
        showErrorMessageGetx(message: 'This mobile number already exists');
        isValid = false;
      }

      if (_selectedType.isEmpty) {
        _errors['leadSource'] = 'Please select a lead source';
        isValid = false;
      }
    });

    return isValid;
  }

  // Validate page 2 fields
  bool _validatePage2() {
    bool isValid = true;
    setState(() {
      _errors = {}; // Clear previous errors

      if (selectedVehicleData == null || selectedVehicleName!.isEmpty) {
        _errors['vehicleName'] = 'Please select a vehicle';
        isValid = false;
      }

      // Validate purchase type
      if (_selectedPurchaseType.isEmpty) {
        _errors['purchaseType'] = 'Please select a purchase type';
        isValid = false;
      }

      // Validate enquiry type
      if (_selectedEnquiryType.isEmpty) {
        _errors['enquiryType'] = 'Please select an enquiry type';
        isValid = false;
      }
    });

    return isValid;
  }

  bool _validatePage3() {
    bool isValid = true;
    setState(() {}); // Update UI to show error messages if needed
    return isValid;
  }

  // Email validation
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  bool _isValidFirst(String name) {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9]+( [a-zA-Z0-9]+)*$');
    return nameRegExp.hasMatch(name);
  }

  bool _isValidSecond(String name) {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9]+( [a-zA-Z0-9]+)*$');
    return nameRegExp.hasMatch(name);
  }

  bool _isValidMobile(String mobile) {
    // Remove any non-digit characters
    String digitsOnly = mobile.replaceAll(RegExp(r'\D'), '');

    // Check if it's a valid Indian number: 10 digits and starts with 6-9
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validatePage1()) {
        setState(() => _currentStep++);
      } else {
        String errorMessage = _errors.values.join('\n');
        print(errorMessage.toString());
      }
    } else if (_currentStep == 1) {
      if (_validatePage2()) {
        setState(() => _currentStep++);
      } else {
        String errorMessage = _errors.values.join('\n');
        print(errorMessage.toString());
      }
    } else {
      if (_validatePage3()) {
        _submitForm();
      } else {
        String errorMessage = _errors.values.join('\n');
        print(errorMessage.toString());
      }
    }
  }

  Future<void> _submitForm() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

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

  void _validateLocation() {
    if (_locationController.text.trim().isEmpty) {
      setState(() {
        _locationErrorText = 'Location is required';
      });
    } else {
      setState(() {
        _locationErrorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 1;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                child: Text(
                  'Add New Enquiry',
                  style: AppFont.popupTitleBlack(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                // Step indicators with line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Step 1 indicator column
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _currentStep == 0
                                  ? AppColors.colorsBlue
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: _currentStep == 0
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Contact \nDetails',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _currentStep == 0
                                  ? AppColors.colorsBlue
                                  : Colors.grey,
                              fontWeight: _currentStep == 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      // Connector line
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 17),
                          height: 2,
                          color: _currentStep == 1
                              ? Colors.grey.shade300
                              : Colors.grey.shade300,
                        ),
                      ),

                      // Step 2 indicator column
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _currentStep == 1
                                  ? AppColors.colorsBlue
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: _currentStep == 1
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Vehicle \nDetails',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _currentStep == 1
                                  ? AppColors.colorsBlue
                                  : Colors.grey,
                              fontWeight: _currentStep == 1
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 17),
                          height: 2,
                          color: _currentStep == 2
                              ? Colors.grey.shade300
                              : Colors.grey.shade300,
                        ),
                      ),

                      // Step 3 indicator column
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _currentStep == 2
                                  ? AppColors.colorsBlue
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: _currentStep == 2
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'More \n Details',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _currentStep == 2
                                  ? AppColors.colorsBlue
                                  : Colors.grey,
                              fontWeight: _currentStep == 2
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            IndexedStack(
              index: _currentStep,
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              isRequired: true,
                              label: 'First Name',
                              controller: firstNameController,
                              hintText: 'First name',
                              errorText: _errors['firstName'],
                              onChanged: (value) {
                                if (_errors.containsKey('firstName')) {
                                  setState(() {
                                    _errors.remove('firstName');
                                  });
                                }
                                print("firstName : $value");
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              isRequired: true,
                              label: 'Last Name',
                              errorText: _errors['lastName'],
                              controller: lastNameController,
                              hintText: 'Last name',
                              onChanged: (value) {
                                if (_errors.containsKey('lastName')) {
                                  setState(() {
                                    _errors.remove('lastName');
                                  });
                                }
                                print("lastName : $value");
                              },
                            ),
                          ),
                        ],
                      ),

                      _buildNumberWidget(
                        isRequired: true,
                        label: 'Mobile No',
                        controller: mobileController,
                        errorText: _errors['mobile'],
                        hintText: '+91',
                        onChanged: (value) {
                          if (_errors.containsKey('mobile')) {
                            setState(() {
                              _errors.remove('mobile');
                            });
                          }
                          print("mobile: $value");
                        },
                      ),

                      _buildTextField(
                        isRequired: true,
                        label: 'Email',
                        controller: emailController,
                        hintText: 'Email',
                        errorText: _errors['email'],
                        onChanged: (value) {
                          if (_errors.containsKey('email')) {
                            setState(() {
                              _errors.remove('email');
                            });
                          }
                          print("email : $value");
                        },
                      ),

                      // _buildSecondNumberWidget(
                      //   isRequired: false,
                      //   label: 'Mobile No',
                      //   controller: mobileSecondController,
                      //   // errorText: _errors['mobile'],
                      //   hintText: '+91',
                      //   onChanged: (value) {
                      //     if (_errors.containsKey('mobile')) {
                      //       setState(() {
                      //         _errors.remove('mobile');
                      //       });
                      //     }
                      //     print("mobile: $value");
                      //   },
                      // ),
                      const SizedBox(height: 10),
                      _buildButtonsFloat1(
                        isRequired: true,
                        label: 'Lead Source',
                        options: {
                          "Email": "Email",
                          "Existing Customer": "Existing Customer",
                          "Field Visit": "Field Visit",
                          "Phone-in": "Phone-in",
                          "Phone-out": "Phone-out",
                          "Purchased List": "Purchased List",
                          "Referral": "Referral",
                          "Retailer Experience": "Retailer Experience",
                          "SMS": "SMS",
                          "Social (Retailer)": "Social (Retailer)",
                          "Walk-in": "Walk-in",
                          "Events": "Events",
                          // "Other": "Other",
                        },
                        groupValue: _selectedType,
                        errorText: _errors['leadSource'],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                            if (_errors.containsKey('leadSource')) {
                              _errors.remove('leadSource');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountRange(isRequired: true),
                      VehiclesearchTextfield(
                        errorText: _errors['vehicleName'],
                        onVehicleSelected: (selectedVehicle) {
                          setState(() {
                            selectedVehicleData = selectedVehicle;
                            selectedVehicleName =
                                selectedVehicle['vehicle_name'];
                            selectedBrand = selectedVehicle['brand'];
                            vehicleId = selectedVehicle['vehicle_id'];
                            houseOfBrand = selectedVehicle['houseOfBrand'];

                            if (_errors.containsKey('vehicleName')) {
                              _errors.remove('vehicleName');
                            }
                          });
                          print("Selected Vehicle: $selectedVehicleName");
                          print(
                            "Selected Brand: ${selectedBrand ?? 'No Brand'}",
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      VehicleColors(
                        errorText: _errors['vehicleColors'],
                        onVehicleColorSelected: (selectedColorData) {
                          setState(() {
                            selectedColorName = selectedColorData['color_name'];
                            if (_errors.containsKey('vehicleColors')) {
                              _errors.remove('vehicleColors');
                            }
                          });

                          print("Selected Color Name: $selectedColorName");
                        },
                      ),

                      const SizedBox(height: 10),

                      _buildButtonsFloat(
                        isRequired: true,
                        options: {
                          "New": "New Vehicle",
                          "Pre-Owned": "Used Vehicle",
                        },
                        groupValue: _selectedPurchaseType,
                        label: 'Purchase Type',
                        errorText: _errors['purchaseType'],
                        onChanged: (value) {
                          setState(() {
                            _selectedPurchaseType = value;
                            if (_errors.containsKey('purchaseType')) {
                              _errors.remove('purchaseType');
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildButtonsFloat(
                        isRequired: true,
                        options: {
                          "KMI": "KMI",
                          "Generic": "(Generic) Purchase intent within 90 days",
                        },
                        groupValue: _selectedEnquiryType,
                        label: 'Enquiry Type',
                        errorText: _errors['enquiryType'],
                        onChanged: (value) {
                          setState(() {
                            _selectedEnquiryType = value;
                            if (_errors.containsKey('enquiryType')) {
                              _errors.remove('enquiryType');
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomGooglePlacesField(
                        controller: _locationController,
                        hintText: 'Enter location',
                        label: 'Location',
                        onChanged: (value) {},
                        googleApiKey: _googleApiKey,
                        isRequired: true,
                      ),

                      _buildDatePicker(
                        label: 'Expected purchase date',
                        controller: endDateController,
                        errorText: _errors['purchaseDate'],
                        onTap: () => _pickDate(isStartDate: false),
                      ),

                      const SizedBox(height: 10),
                      CampaignSearchTextfield(
                        errorText: _errors['campaign'],
                        onCampaignSelected: (selectedCampaign) {
                          setState(() {
                            selectedCampaignData = selectedCampaign;
                            selectedCampaignName =
                                selectedCampaign['campaign_name'];
                            selectedCampaignId = selectedCampaign['campaign_id']
                                .toString();

                            if (_errors.containsKey('campaign')) {
                              _errors.remove('campaign');
                            }
                          });

                          print("Selected Campaign: $selectedCampaignName");
                          print("Selected Campaign ID: $selectedCampaignId");
                        },
                      ),

                      // _buildTextField(
                      //   isRequired: false,
                      //   label: 'Company',
                      //   errorText: _errors['company'],
                      //   controller: companyController,
                      //   hintText: 'Company',
                      //   onChanged: (value) {
                      //     if (_errors.containsKey('company')) {
                      //       setState(() {
                      //         _errors.remove('company');
                      //       });
                      //     }
                      //     print("company : $value");
                      //   },
                      // ),
                      const SizedBox(height: 10),

                      // New "Halo?" radio button group
                      _buildButtonsFloat(
                        isRequired: false, // Assuming it's not required
                        label: 'HALO?',
                        options: const {"Yes": "Yes", "No": "No"},
                        groupValue: _selectedHaloOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedHaloOption = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Updated Button Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      if (_currentStep == 0) {
                        Navigator.pop(context);
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_pageController.hasClients) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                        setState(() => _currentStep--);
                      }
                    },
                    child: Text(
                      _currentStep == 0 ? "Cancel" : "Previous",
                      style: AppFont.buttons(context),
                    ),
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
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == 2 ? "Create" : "Continue",
                      style: AppFont.buttons(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget CampaignSearchTextfield({
    String? errorText,
    required Function(Map<String, dynamic>) onCampaignSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: Text(
            'Campaign',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.fontBlack,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: const Color.fromARGB(255, 248, 247, 247),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchControllerCampaign,
                style: AppFont.dropDowmLabel(context),
                decoration: InputDecoration(
                  hintText: 'Search campaign',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                  suffixIcon: _isLoadingCampaignSearch
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchControllerCampaign.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchControllerCampaign.clear();
                              _searchResultsCampaign.clear();
                              selectedCampaignName = null;
                              selectedCampaignId = null;
                              selectedCampaignData = null;
                              _campaignQuery = '';
                            });
                          },
                        )
                      : const Icon(Icons.search, color: Colors.grey),
                ),
              ),
              // Campaign Results
              if (_searchResultsCampaign.isNotEmpty &&
                  _searchControllerCampaign.text.isNotEmpty &&
                  selectedCampaignName != _searchControllerCampaign.text)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResultsCampaign.length,
                    itemBuilder: (context, index) {
                      final campaign = _searchResultsCampaign[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          campaign['campaign_name'] ?? 'Unknown Campaign',
                          style: AppFont.dropDowmLabel(context),
                        ),
                        subtitle: campaign['campaign_code'] != null
                            ? Text(
                                campaign['campaign_code'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          final campaignName = campaign['campaign_name'] ?? '';

                          // Try different possible field names for campaign ID
                          final campaignId =
                              campaign['id']?.toString() ??
                              campaign['campaign_id']?.toString() ??
                              campaign['Campaign_id']?.toString() ??
                              '';

                          print(
                            "Selected Campaign ID: $campaignId",
                          ); // Debug print
                          print("Full campaign data: $campaign"); // Debug print

                          setState(() {
                            _searchControllerCampaign.text = campaignName;
                            _searchResultsCampaign.clear();
                            selectedCampaignName = campaignName;
                            selectedCampaignId = campaignId;
                          });

                          // Create the campaign data
                          final campaignData = {
                            'campaign_name': campaignName,
                            // 'campaign_id': campaignId,
                          };

                          // Call the callback
                          onCampaignSelected(campaignData);

                          // Hide keyboard
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                )
              else if (_searchResultsCampaign.isEmpty &&
                  _searchControllerCampaign.text.isNotEmpty &&
                  !_isLoadingCampaignSearch &&
                  selectedCampaignName != _searchControllerCampaign.text)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No campaigns found',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                      // fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // All other existing widget methods remain the same...
  Widget _buildNumberWidget({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    String? errorText,
  }) {
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
                color: Colors.black87,
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
        //
        // enquiry check 8788761660
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: const Color.fromARGB(255, 248, 247, 247),
            border:
                //  errorText != null
                (errorText != null || _existingLeadData != null)
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              controller: controller,
              style: AppFont.dropDowmLabel(context),
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
              ),

              onChanged: (value) {
                onChanged(value);

                print("Current mobile input: $value, length: ${value.length}");

                if (value.length != 10) {
                  setState(() {
                    _existingLeadData = null;
                    _isLoading = false;
                  });
                }

                if (value.length == 10) {
                  print("Checking for existing lead with number: $value");
                  _checkExistingLead(value);
                }
              },
            ),
          ),
        ),

        // Show this only if an existing lead is found
        if (_existingLeadData != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Enquiry already exists',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              '${_existingLeadData!['name']}',
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              height: 15,
                              width: 0.1,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.fontColor),
                                ),
                              ),
                            ),
                            Text(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              '${_existingLeadData!['PMI']}',
                              style: AppFont.smallText(context),
                            ),

                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              height: 15,
                              width: 0.1,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.fontColor),
                                ),
                              ),
                            ),
                            Text(
                              '${_existingLeadData!['status']}',
                              style: AppFont.smallText(context),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '${_existingLeadData!['mobile']}',
                              style: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              height: 15,
                              width: 0.1,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.fontColor),
                                ),
                              ),
                            ),
                            Text(
                              'by ${_existingLeadData!['lead_owner']}',
                              style: AppFont.smallText(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSecondNumberWidget({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    String? errorText,
  }) {
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
                color: Colors.black87,
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              controller: controller,
              style: AppFont.dropDowmLabel(context),
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
              ),

              onChanged: (value) {
                onChanged(value);

                print("Current mobile input: $value, length: ${value.length}");

                if (value.length != 10) {
                  setState(() {
                    _existingLeadData = null;
                    _isLoading = false;
                  });
                }

                if (value.length == 10) {
                  print("Checking for existing lead with number: $value");
                  _checkExistingLead(value);
                }
              },
            ),
          ),
        ),

        // Show this only if an existing lead is found
        if (_existingLeadData != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Enquiry already exists',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_existingLeadData!['name']}',
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 15,
                              width: 0.1,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.fontColor),
                                ),
                              ),
                            ),
                            Text(
                              '${_existingLeadData!['PMI']}',
                              style: AppFont.smallText(context),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '${_existingLeadData!['mobile']}',
                              style: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 15,
                              width: 0.1,
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.fontColor),
                                ),
                              ),
                            ),
                            Text(
                              'by ${_existingLeadData!['lead_owner']}',
                              style: AppFont.smallText(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    String? errorText,
  }) {
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
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    bool isRequired = false,
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    String? errorText,
  }) {
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 45,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: errorText != null
                  ? Border.all(color: Colors.red)
                  : Border.all(color: Colors.black, width: 0.5),
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
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.fontBlack,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // REVERTED to the original widget to maintain styling
  Widget _buildButtonsFloat({
    bool isRequired = false,
    required Map<String, String> options,
    required String groupValue,
    required String label,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    List<String> optionKeys = options.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 248, 247, 247),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 5,
                      ),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildOptionButton(
                                optionKeys[0],
                                options,
                                groupValue,
                                onChanged,
                              ),
                              const SizedBox(width: 5),
                              _buildOptionButton(
                                optionKeys[1],
                                options,
                                groupValue,
                                onChanged,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsFloat1({
    bool isRequired = false,
    required Map<String, String> options,
    required String groupValue,
    required String label,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    List<String> optionKeys = options.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 248, 247, 247),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0, left: 5),
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
                Wrap(
                  spacing: 2,
                  runSpacing: 10,
                  children: options.keys.map((shortText) {
                    bool isSelected = groupValue == options[shortText];

                    return GestureDetector(
                      onTap: () {
                        onChanged(options[shortText]!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.colorsBlue
                                : AppColors.fontColor,
                            width: .5,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          color: isSelected
                              ? AppColors.colorsBlue.withOpacity(0.2)
                              : AppColors.innerContainerBg,
                        ),
                        child: Text(
                          shortText,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.colorsBlue
                                : AppColors.fontColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRange({bool isRequired = false}) {
    final int startLakh = (_rangeAmount.start / 100000).round();
    final int endLakh = (_rangeAmount.end / 100000).round();

    final startText = startLakh.toString();
    final endText = endLakh.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text("Budget", style: AppFont.dropDowmLabel(context)),
        const SizedBox(height: 5),

        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "INR:$startText lakh - INR:$endText lakh",
            style: AppFont.smallText(context),
          ),
        ),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.colorsBlue,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            thumbColor: AppColors.colorsBlue,
            overlayColor: AppColors.colorsBlue.withOpacity(0.2),
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: RangeSlider(
            values: _rangeAmount,
            min: _minValue,
            max: _maxValue,
            divisions: 160,
            labels: RangeLabels("INR:${startText}L", "INR:${endText}L"),
            onChanged: (RangeValues values) {
              final double newStart = (values.start / 100000).round() * 100000;
              final double newEnd = (values.end / 100000).round() * 100000;

              final clampedStart = newStart.clamp(_minValue, _maxValue);
              final clampedEnd = newEnd.clamp(_minValue, _maxValue);

              setState(() {
                _rangeAmount = RangeValues(clampedStart, clampedEnd);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(
    String shortText,
    Map<String, String> options,
    String groupValue,
    ValueChanged<String> onChanged,
  ) {
    bool isSelected = groupValue == options[shortText];

    return GestureDetector(
      onTap: () {
        onChanged(options[shortText]!);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.colorsBlue : Colors.grey,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(15),
          color: isSelected
              ? AppColors.colorsBlue.withOpacity(0.1)
              : AppColors.innerContainerBg,
        ),
        child: Center(
          child: Text(
            shortText,
            style: TextStyle(
              color: isSelected ? AppColors.colorsBlue : AppColors.fontColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submitForm() async {
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
        print("Error: User ID not found.");
        return;
      }

      String mobileNumber = mobileController.text;

      if (!mobileNumber.startsWith('+91')) {
        mobileNumber = '+91' + mobileNumber;
      }

      final double highestBudgetValue = _rangeAmount.end;

      final leadData = {
        'fname': firstNameController.text,
        'lname': lastNameController.text,
        'email': emailController.text,
        'mobile': mobileNumber,
        // 'company_name': companyController.text,
        // 'mobile_second': mobileSecondController,
        'purchase_type': _selectedPurchaseType,
        'brand': selectedBrand ?? '',
        'vehicle_id': vehicleId ?? '',
        'houseOfBrand': houseOfBrand ?? '',
        'type': 'Product',
        'sub_type': selectedSubType,
        'chat_id': "91${mobileController.text}@c.us",
        'PMI': selectedVehicleName,
        'expected_date_purchase': endDateController.text,
        'enquiry_type': _selectedEnquiryType,
        'lead_source': _selectedType,
        'consent': consentValue,
        'budget': highestBudgetValue,

        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),

        'exterior_color': selectedColorName,
        'campaign': selectedCampaignName,
        'halo': _selectedHaloOption.isNotEmpty ? _selectedHaloOption : null,
      };

      print("Submitting lead data: $leadData");

      Map<String, dynamic>? response = await LeadsSrv.submitLead(leadData);

      if (response != null) {
        print("Response received: $response");
        if (response.containsKey('data')) {
          String leadId = response['data']['lead_id'];

          if (context.mounted) {
            Get.find<FabController>().temporarilyDisableFab();

            Navigator.pop(context);
            widget.onFormSubmit();
            widget.dashboardRefresh!();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowupsDetails(
                  leadId: leadId,
                  isFromFreshlead: true,
                  isFromManager: false,
                  spId: '',
                  refreshDashboard: () async {},
                  isFromTestdriveOverview: false,
                ),
              ),
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Enquiry created successfully',
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
          widget.onFormSubmit();
        } else if (response.containsKey('error') ||
            response.containsKey('message')) {
          String errorMessage =
              response['error'] ??
              response['message'] ??
              'Something went wrong';

          if (response['errors'] != null && response['errors'] is Map) {
            Map<String, dynamic> errorDetails = response['errors'];

            if (errorDetails.isNotEmpty) {
              setState(() {
                _errors = errorDetails.map(
                  (key, value) => MapEntry(key, value.toString()),
                );
              });

              String firstFieldError = errorDetails.entries.first.value
                  .toString();
              Get.snackbar(
                'Validation Error',
                firstFieldError,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } else {
            Get.snackbar(
              'Error',
              errorMessage,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      } else {
        print("Error: API response is null");

        Get.snackbar(
          'Error',
          'Something went wrong. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      print("Exception Occurred: $e");
      print("Stack Trace: $stackTrace");

      Get.snackbar(
        'Error',
        'An error occurred: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
