import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/popups_widget/vehicleSearch_textfield.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LeadUpdate extends StatefulWidget {
  final Function onEdit;
  final Function onFormSubmit;
  final String leadId;
  const LeadUpdate({
    super.key,
    required this.onFormSubmit,
    required this.leadId,
    required this.onEdit,
  });

  @override
  State<LeadUpdate> createState() => _LeadUpdateState();
}

class _LeadUpdateState extends State<LeadUpdate> {
  final PageController _pageController = PageController();
  List<dynamic> _searchResultsCampaign = [];
  bool isLoading = true;
  int _currentStep = 0;
  String? selectedVehicleName;
  String? selectedBrand;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool isSubmitting = false;
  String? vehicleId;
  List<dynamic> vehicleList = [];
  List<dynamic> _searchResults = [];
  List<String> uniqueVehicleNames = [];
  Map<String, dynamic>? selectedVehicleData;
  // Form error tracking
  Map<String, String> _errors = {};
  bool _isLoadingSearch = false;
  String _selectedBrand = '';
  String _selectedEnquiryType = '';
  Map<String, dynamic>? _existingLeadData;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController campaignController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController modelInterestController = TextEditingController();
  bool consentValue = false;

  bool _isLoadingCampaignSearch = false;
  String _campaignQuery = '';
  String? selectedCampaignName;
  String? selectedCampaignId;
  Map<String, dynamic>? selectedCampaignData;
  final TextEditingController _searchControllerCampaign =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize speech recognition
    _speech = stt.SpeechToText();
    _initSpeech();
    // _searchController.addListener(_onSearchChanged);
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _debounceSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });

    // ✅ Campaign search listener - use the passed controller
    campaignController.addListener(_onCampaignSearchChanged);

    _fetchLeadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    campaignController.removeListener(
      _onCampaignSearchChanged,
    ); // ✅ Remove listener
    // ✅ Don't dispose campaignController as it's passed from parent
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    modelInterestController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Timer? _debounce;

  void _debounceSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetchVehicleData(query); // ← call your controller/API fetch function here
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

  // void _onCampaignSearchChanged() {
  //   final newQuery = _searchControllerCampaign.text.trim();
  //   if (newQuery == _campaignQuery) return;

  //   _campaignQuery = newQuery;
  //   Future.delayed(const Duration(milliseconds: 500), () {
  //     if (_campaignQuery == _searchControllerCampaign.text.trim()) {
  //       fetchCampaignData(_campaignQuery);
  //     }
  //   });
  // }

  void _onCampaignSearchChanged() {
    final newQuery = campaignController.text.trim(); // ✅ Correct controller
    if (newQuery == _campaignQuery) return;

    _campaignQuery = newQuery;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_campaignQuery == campaignController.text.trim()) {
        // ✅ Correct controller
        fetchCampaignData(_campaignQuery);
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        fetchVehicleData(query);
      } else {
        setState(() => _searchResults.clear());
      }
    });
  }

  // Fetch lead data by ID to populate the form
  Future<void> _fetchLeadData() async {
    setState(() {
      isLoading = true;
    });

    final token = await Storage.getToken();

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.smartassistapp.in/api/leads/by-id/${widget.leadId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print(data.toString());
        // Populate the form with existing data
        if (data['data'] != null) {
          setState(() {
            _existingLeadData = data['data'];

            // Split the existing lead_name into first and last name
            String fullName = data['data']['lead_name'] ?? '';
            List<String> nameParts = fullName.split(' ');
            if (nameParts.isNotEmpty) {
              firstNameController.text = nameParts[0];
              if (nameParts.length > 1) {
                lastNameController.text = nameParts.sublist(1).join(' ');
              }
            }

            emailController.text = data['data']['email'] ?? '';
            campaignController.text = data['data']['campaign'] ?? '';
            // Handle mobile number formatting (remove +91 if present)
            String mobile = data['data']['mobile'] ?? '';
            if (mobile.startsWith('+91')) {
              mobile = mobile.substring(3); // Remove +91 prefix
            }
            mobileController.text = mobile;

            // Set dropdown values
            // _selectedBrand = data['data']['brand'] ?? '';
            _selectedEnquiryType = data['data']['enquiry_type'] ?? '';

            // Set model interest
            modelInterestController.text = data['data']['PMI'] ?? '';
          });
        }
      } else {
        showErrorMessage(context, message: 'Failed to fetch lead data');
      }
    } catch (e) {
      showErrorMessage(
        context,
        message: 'Something went wrong: ${e.toString()}',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add this helper method for showing error messages
  void showErrorMessage(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Validate page 1 fields (removed required validations)
  bool _validatePage1() {
    bool isValid = true;
    setState(() {
      _errors = {}; // Clear previous errors

      // Optional email validation (only validate format if provided)
      if (emailController.text.trim().isNotEmpty &&
          !_isValidEmail(emailController.text.trim())) {
        _errors['email'] = 'Please enter a valid email';
        isValid = false;
      }

      // Optional mobile validation (only validate format if provided)
      if (mobileController.text.trim().isNotEmpty &&
          !_isValidMobile(mobileController.text.trim())) {
        _errors['mobile'] = 'Please enter a valid 10-digit mobile number';
        isValid = false;
      }

      // Optional first name validation (only validate format if provided)
      if (firstNameController.text.trim().isNotEmpty &&
          !_isValidFirst(firstNameController.text.trim())) {
        _errors['firstName'] = 'Invalid first name format';
        isValid = false;
      }

      // Optional last name validation (only validate format if provided)
      if (lastNameController.text.trim().isNotEmpty &&
          !_isValidSecond(lastNameController.text.trim())) {
        _errors['lastName'] = 'Invalid last name format';
        isValid = false;
      }
    });

    return isValid;
  }

  // Add these validation methods if they don't exist:
  bool _isValidFirst(String name) {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9]+( [a-zA-Z0-9]+)*$');
    return nameRegExp.hasMatch(name);
  }

  bool _isValidSecond(String name) {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9]+( [a-zA-Z0-9]+)*$');
    return nameRegExp.hasMatch(name);
  }

  // Validate page 2 fields (removed required validations)
  bool _validatePage2() {
    // Since all validations are removed, always return true
    setState(() {
      _errors = {}; // Clear previous errors
    });
    return true;
  }

  // Email validation
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(
      // r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ); // ✅ More flexible
    return emailRegExp.hasMatch(email);
  }

  // Mobile validation
  bool _isValidMobile(String mobile) {
    // Remove any non-digit characters
    String digitsOnly = mobile.replaceAll(RegExp(r'\D'), '');

    // Check if it's 10 digits (standard Indian mobile number)
    return digitsOnly.length == 10;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validatePage1()) {
        setState(() => _currentStep++);
        // No need for PageController navigation with IndexedStack
      } else {
        Get.snackbar(
          'Error',
          'Please check the contact details',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      if (_validatePage2()) {
        _submitForm(); // Submit form after second page
      } else {
        Get.snackbar(
          'Error',
          'Please check the vehicle details',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Add this state variable at the top of your class
  bool get _canProceed {
    if (_currentStep == 0) {
      return _validatePage1();
    } else {
      return _validatePage2();
    }
  }

  Future<void> _submitForm() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      await submitLeadUpdate();
    } catch (e) {
      showErrorMessageGetx(message: 'Submission failed: ${e.toString()}');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        'Update Enquiry',
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
                                color: Colors.grey.shade300,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Page content
                  IndexedStack(
                    index: _currentStep,
                    children: [
                      // First page - Contact Details
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'First Name',
                              controller: firstNameController,
                              hintText: 'Enter first name',
                              errorText: _errors['firstName'],
                              onChanged: (value) {
                                if (_errors.containsKey('firstName')) {
                                  setState(() {
                                    _errors.remove('firstName');
                                  });
                                }
                              },
                            ),
                            _buildTextField(
                              label: 'Last Name',
                              controller: lastNameController,
                              hintText: 'Enter last name',
                              errorText: _errors['lastName'],
                              onChanged: (value) {
                                if (_errors.containsKey('lastName')) {
                                  setState(() {
                                    _errors.remove('lastName');
                                  });
                                }
                              },
                            ),
                            _buildTextField(
                              label: 'Email',
                              controller: emailController,
                              hintText: 'Email address',
                              errorText: _errors['email'],
                              onChanged: (value) {
                                if (_errors.containsKey('email')) {
                                  setState(() {
                                    _errors.remove('email');
                                  });
                                }
                              },
                            ),
                            _buildNumberWidget(
                              label: 'Mobile No',
                              controller: mobileController,
                              errorText: _errors['mobile'],
                              hintText: 'Mobile number',
                              onChanged: (value) {
                                if (_errors.containsKey('mobile')) {
                                  setState(() {
                                    _errors.remove('mobile');
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Second page - Vehicle Details
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const SizedBox(height: 15),
                            _buildEnquiryTypeSelector(
                              options: {
                                "KMI": "KMI",
                                "Generic":
                                    "(Generic) Purchase intent within 90 days",
                              },
                              groupValue: _selectedEnquiryType,
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
                            const SizedBox(height: 15),

                            // _buildSearchField(),
                            // _buildTextField(
                            //   label: 'Primary Model Interest',
                            //   controller: modelInterestController,
                            //   hintText: 'Enter model name',
                            //   errorText: _errors['model'],
                            //   onChanged: (value) {
                            //     if (_errors.containsKey('model')) {
                            //       setState(() {
                            //         _errors.remove('model');
                            //       });
                            //     }
                            //   },
                            // ),
                            VehiclesearchTextfield(
                              initialVehicleName:
                                  modelInterestController.text.isNotEmpty
                                  ? modelInterestController.text
                                  : null, // Pass PMI here
                              initialVehicleId: '',
                              onVehicleSelected: (selectedVehicle) {
                                setState(() {
                                  // Handle clearing
                                  if (selectedVehicle.isEmpty) {
                                    selectedVehicleData = null;
                                    selectedVehicleName =
                                        modelInterestController.text.isNotEmpty
                                        ? modelInterestController.text
                                        : null; // Revert to original PMI
                                    vehicleId = '';
                                    selectedBrand = null;
                                    return;
                                  }

                                  // Handle new selection
                                  selectedVehicleData = selectedVehicle;
                                  selectedVehicleName =
                                      selectedVehicle['vehicle_name'];
                                  vehicleId = selectedVehicle['vehicle_id'];
                                  // houseOfBrand = selectedVehicle['houseOfBrand'];
                                  selectedBrand =
                                      selectedVehicle['brand'] ?? '';
                                });

                                print("Selected Vehicle: $selectedVehicleName");
                                print(
                                  "Selected Brand: ${selectedBrand ?? 'No Brand'}",
                                );
                              },
                            ),

                            SizedBox(height: 10),

                            CampaignSearchTextfield(
                              controller: campaignController,
                              errorText: _errors['campaign'],
                              onCampaignSelected: (selectedCampaign) {
                                setState(() {
                                  selectedCampaignData = selectedCampaign;
                                  selectedCampaignName =
                                      selectedCampaign['campaign_name'];
                                  selectedCampaignId =
                                      selectedCampaign['campaign_id']
                                          .toString();

                                  if (_errors.containsKey('campaign')) {
                                    _errors.remove('campaign');
                                  }
                                });

                                print(
                                  "Selected Campaign: $selectedCampaignName",
                                );
                                print(
                                  "Selected Campaign ID: $selectedCampaignId",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              217,
                              217,
                              217,
                              1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () {
                            if (_currentStep == 0) {
                              Navigator.pop(context); // Close if on first page
                            } else {
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
                          // onPressed: isSubmitting ? null : _nextStep,
                          onPressed: (isSubmitting || !_canProceed)
                              ? null
                              : _nextStep,
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStep == 1 ? "Update" : "Continue",
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

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text('Primary Model Interest', style: AppFont.dropDowmLabel(context)),
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
                  onChanged: (value) {
                    // 🔁 Call your search API when the user types
                    _onSearchChanged(value);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.containerBg,
                    hintText: selectedVehicleName ?? 'Vehicle Name',
                    hintStyle: TextStyle(
                      color: selectedVehicleName != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 15,
                      color: AppColors.iconGrey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
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
        if (_isLoadingSearch)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
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
                      selectedVehicleName = result['vehicle_name'];

                      selectedVehicleName = selectedVehicleName;
                      modelInterestController.text =
                          selectedVehicleName!; // ✅ This sets the controller

                      _searchController.clear();
                      _searchResults.clear();
                    });
                    // ✅ Fetch additional info if needed
                    // fetchVehicleColors(result['vehicle_name']);
                  },
                  title: Text(
                    result['vehicle_name'] ?? 'No Name',
                    style: TextStyle(
                      color: selectedVehicleName == result['vehicle_name']
                          ? Colors.black
                          : AppColors.fontBlack,
                    ),
                  ),
                  leading: const Icon(Icons.directions_car),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNumberWidget({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
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
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.fontBlack,
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildButtonsFloat({
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
                    SizedBox(
                      child: Text(
                        label,
                        style: AppFont.dropDowmLabel(context),
                        textAlign: TextAlign.left,
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildEnquiryTypeSelector({
    required Map<String, String> options,
    required String groupValue,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: Text(
            'Enquiry Type',
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
            color: const Color.fromARGB(255, 248, 247, 247),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.entries.map((entry) {
                bool isSelected = groupValue == entry.value;
                return GestureDetector(
                  onTap: () {
                    onChanged(entry.value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.colorsBlue
                            : AppColors.fontColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget CampaignSearchTextfield({
    required TextEditingController controller,
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
                controller:
                    controller, // ✅ Use the passed controller consistently
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
                      : controller
                            .text
                            .isNotEmpty // ✅ Use controller consistently
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              controller
                                  .clear(); // ✅ Clear the passed controller
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
                  controller.text.isNotEmpty && // ✅ Use controller consistently
                  selectedCampaignName !=
                      controller.text) // ✅ Use controller consistently
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

                          print("Selected Campaign ID: $campaignId");
                          print("Full campaign data: $campaign");

                          setState(() {
                            controller.text =
                                campaignName; // ✅ Use controller consistently
                            _searchResultsCampaign.clear();
                            selectedCampaignName = campaignName;
                            selectedCampaignId = campaignId;
                          });

                          // Create the campaign data
                          final campaignData = {
                            'campaign_name': campaignName,
                            'campaign_id':
                                campaignId, // ✅ Include campaign_id if needed
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
                  controller.text.isNotEmpty && // ✅ Use controller consistently
                  !_isLoadingCampaignSearch &&
                  selectedCampaignName !=
                      controller.text) // ✅ Use controller consistently
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No campaigns found',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
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

  // Widget CampaignSearchTextfield({
  //   required TextEditingController controller,
  //   String? errorText,
  //   required Function(Map<String, dynamic>) onCampaignSelected,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
  //         child: Text(
  //           'Campaign',
  //           style: GoogleFonts.poppins(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w500,
  //             color: AppColors.fontBlack,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 5),
  //       Container(
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(5),
  //           color: const Color.fromARGB(255, 248, 247, 247),
  //           border: errorText != null
  //               ? Border.all(color: Colors.red, width: 1.0)
  //               : null,
  //         ),
  //         child: Column(
  //           children: [
  //             TextField(
  //               // controller: _searchControllerCampaign,
  //               controller: controller,
  //               style: AppFont.dropDowmLabel(context),
  //               decoration: InputDecoration(
  //                 hintText: 'Search campaign',
  //                 hintStyle: GoogleFonts.poppins(
  //                   color: Colors.grey,
  //                   fontSize: 14,
  //                 ),
  //                 contentPadding: const EdgeInsets.symmetric(
  //                   horizontal: 10,
  //                   vertical: 14,
  //                 ),
  //                 border: InputBorder.none,
  //                 suffixIcon: _isLoadingCampaignSearch
  //                     ? const Padding(
  //                         padding: EdgeInsets.all(12.0),
  //                         child: SizedBox(
  //                           width: 16,
  //                           height: 16,
  //                           child: CircularProgressIndicator(strokeWidth: 2),
  //                         ),
  //                       )
  //                     : campaignController.text.isNotEmpty
  //                     ? IconButton(
  //                         icon: const Icon(Icons.clear, color: Colors.grey),
  //                         onPressed: () {
  //                           setState(() {
  //                             campaignController
  //                                 .clear(); // Clear the passed controller
  //                             _searchControllerCampaign
  //                                 .clear(); // Clear internal controller

  //                             // _searchControllerCampaign.clear();
  //                             _searchResultsCampaign.clear();
  //                             selectedCampaignName = null;
  //                             selectedCampaignId = null;
  //                             selectedCampaignData = null;
  //                             _campaignQuery = '';

  //                             campaignController.clear();
  //                           });
  //                         },
  //                       )
  //                     : const Icon(Icons.search, color: Colors.grey),
  //               ),
  //             ),
  //             // Campaign Results
  //             if (_searchResultsCampaign.isNotEmpty &&
  //                 _searchControllerCampaign.text.isNotEmpty &&
  //                 selectedCampaignName != _searchControllerCampaign.text)
  //               Container(
  //                 constraints: const BoxConstraints(maxHeight: 200),
  //                 child: ListView.builder(
  //                   shrinkWrap: true,
  //                   itemCount: _searchResultsCampaign.length,
  //                   itemBuilder: (context, index) {
  //                     final campaign = _searchResultsCampaign[index];
  //                     return ListTile(
  //                       dense: true,
  //                       title: Text(
  //                         campaign['campaign_name'] ?? 'Unknown Campaign',
  //                         style: AppFont.dropDowmLabel(context),
  //                       ),
  //                       subtitle: campaign['campaign_code'] != null
  //                           ? Text(
  //                               campaign['campaign_code'],
  //                               style: GoogleFonts.poppins(
  //                                 fontSize: 12,
  //                                 color: Colors.grey,
  //                               ),
  //                               maxLines: 1,
  //                               overflow: TextOverflow.ellipsis,
  //                             )
  //                           : null,
  //                       onTap: () {
  //                         final campaignName = campaign['campaign_name'] ?? '';

  //                         // Try different possible field names for campaign ID
  //                         final campaignId =
  //                             campaign['id']?.toString() ??
  //                             campaign['campaign_id']?.toString() ??
  //                             campaign['Campaign_id']?.toString() ??
  //                             '';

  //                         print(
  //                           "Selected Campaign ID: $campaignId",
  //                         ); // Debug print
  //                         print("Full campaign data: $campaign"); // Debug print

  //                         setState(() {
  //                           _searchControllerCampaign.text = campaignName;
  //                           _searchResultsCampaign.clear();
  //                           selectedCampaignName = campaignName;
  //                           selectedCampaignId = campaignId;
  //                         });

  //                         // Create the campaign data
  //                         final campaignData = {
  //                           'campaign_name': campaignName,
  //                           // 'campaign_id': campaignId,
  //                         };

  //                         // Call the callback
  //                         onCampaignSelected(campaignData);

  //                         // Hide keyboard
  //                         FocusScope.of(context).unfocus();
  //                       },
  //                     );
  //                   },
  //                 ),
  //               )
  //             else if (_searchResultsCampaign.isEmpty &&
  //                 _searchControllerCampaign.text.isNotEmpty &&
  //                 !_isLoadingCampaignSearch &&
  //                 selectedCampaignName != _searchControllerCampaign.text)
  //               Container(
  //                 padding: const EdgeInsets.all(16.0),
  //                 child: Text(
  //                   'No campaigns found',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 14,
  //                     color: Colors.grey,
  //                     // fontStyle: FontStyle.italic,
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),

  //       if (errorText != null)
  //         Padding(
  //           padding: const EdgeInsets.only(top: 5, left: 5),
  //           child: Text(
  //             errorText,
  //             style: const TextStyle(color: Colors.red, fontSize: 12),
  //           ),
  //         ),
  //     ],
  //   );
  // }

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

  Future<void> submitLeadUpdate() async {
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
        return;
      }

      String mobileNumber = mobileController.text;

      // Ensure the mobile number always includes the country code
      if (mobileNumber.isNotEmpty && !mobileNumber.startsWith('+91')) {
        mobileNumber = '+91$mobileNumber';
      }

      // Combine first name and last name to create full name
      String fullName = '';
      if (firstNameController.text.trim().isNotEmpty) {
        fullName = firstNameController.text.trim();
        if (lastNameController.text.trim().isNotEmpty) {
          fullName += ' ${lastNameController.text.trim()}';
        }
      } else if (lastNameController.text.trim().isNotEmpty) {
        fullName = lastNameController.text.trim();
      }

      final leadData = {
        'fname': firstNameController.text,
        'lname': lastNameController.text,
        'lead_name': fullName,
        'email': emailController.text,
        'mobile': mobileNumber,
        'sp_id': spId,
        'PMI': selectedVehicleName?.isNotEmpty == true
            ? selectedVehicleName
            : modelInterestController.text,
        'enquiry_type': _selectedEnquiryType,
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

      // 👇 Log response status and body
      print('Response body: ${response.body}');
      print(leadData);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message =
            responseData['message'] ?? 'Enquiry updated successfully!';

        Navigator.pop(context, true);
        widget.onEdit();
        showSuccessMessage(context, message: message);

        await widget.onFormSubmit(widget.leadId);
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message =
            responseData['message'] ?? 'Submission failed. Try again.';
        showErrorMessageGetx(message: message);
        print(response.body);
      }
    } catch (e) {
      // showErrorMessageGetx(message: 'Something went wrong. Please try again.');
      print('Error during PUT request: $e');
    }
  }
}
