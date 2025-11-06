import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/widgets/mobile_check_dialog.dart';

typedef VehicleSelectedCallback =
    void Function(Map<String, dynamic> selectedVehicle);

class LeadsearchTestdrive extends StatefulWidget {
  final String? errorText;
  final bool isRequired;
  final ValueChanged<String> onChanged;
  final Function(String leadId, String leadName)? onLeadSelected;
  final VoidCallback? onClearSelection;
  final VehicleSelectedCallback? onVehicleSelected;

  const LeadsearchTestdrive({
    super.key,
    this.onLeadSelected,
    this.onClearSelection,
    required this.errorText,
    required this.onChanged,
    this.isRequired = false,
    this.onVehicleSelected,
  });

  @override
  State<LeadsearchTestdrive> createState() => _LeadsearchTestdriveState();
}

class _LeadsearchTestdriveState extends State<LeadsearchTestdrive> {
  // Controllers and Focus
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController1 = TextEditingController();
  final FocusNode _vehicleFocusNode = FocusNode();
  bool _isSelecting = false;
  bool _isLoadingVehicles = false;
  bool _hasLoadedVehicles = false;
  List<Map<String, dynamic>> _filteredVehicles = [];
  List<Map<String, dynamic>> _allVehicles = []; // Store all vehicles

  Map<String, dynamic>? selectedVehicle; // Store entire vehicle object
  String? selectedVehicleName;
  String? vehicleBrand;

  // Search state
  bool _isLoadingSearch = false;
  List<dynamic> _searchResults = [];
  bool _showResults = false;
  bool _hasSearched = false;

  // Selected lead state
  String? selectedLeads;
  String? selectedLeadsName;
  String? selectedLeadPMI; // Store PMI from selected lead

  // Vehicle search state
  bool _showVehicleDropdown = false;
  bool _isVehicleSearchActive = false;
  String _lastVehicleQuery = '';

  // Debouncing
  Timer? _debounceTimer;
  Timer? _vehicleDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  // Error handling
  bool _isErrorShowing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchController1.addListener(_onVehicleSearchChanged);
    _focusNode.addListener(_onFocusChanged);
    _vehicleFocusNode.addListener(_onVehicleFocusChanged);
    // Load vehicles initially - but don't show them until user interacts
    loadAllVehicles();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _vehicleDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController1.removeListener(_onVehicleSearchChanged);
    _searchController.dispose();
    _searchController1.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _vehicleFocusNode.removeListener(_onVehicleFocusChanged);
    _vehicleFocusNode.dispose();
    _isSelecting = false;
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showResults) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _showResults = false;
          });
        }
      });
    }
  }

  void _onVehicleFocusChanged() {
    if (!_vehicleFocusNode.hasFocus && _showVehicleDropdown) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_vehicleFocusNode.hasFocus) {
          setState(() {
            _showVehicleDropdown = false;
          });
        }
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (_isErrorShowing) {
      setState(() {
        _isErrorShowing = false;
      });
    }

    if (query.isEmpty && selectedLeadsName != null) {
      _clearSelection();
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  void _onVehicleSearchChanged() {
    final query = _searchController1.text.trim();

    // If user clears the field, clear selection
    if (query.isEmpty && selectedVehicleName != null) {
      setState(() {
        selectedVehicle = null;
        selectedVehicleName = null;
        vehicleBrand = null;
        _showVehicleDropdown = false;
        _isVehicleSearchActive = false;
      });
      widget.onVehicleSelected?.call({});
      return;
    }

    // Only trigger search if user is actively typing (not from PMI auto-fill)
    if (_isVehicleSearchActive) {
      _vehicleDebounceTimer?.cancel();
      _vehicleDebounceTimer = Timer(_debounceDuration, () {
        if (mounted && query != _lastVehicleQuery) {
          _lastVehicleQuery = query;
          _performVehicleSearch(query);
        }
      });
    }
  }

  void _clearSelection() {
    setState(() {
      selectedLeads = null;
      selectedLeadsName = null;
      selectedLeadPMI = null;
      _searchController.text = '';
      _searchResults.clear();
      _showResults = false;
      _hasSearched = false;
      // Clear vehicle selection as well
      selectedVehicle = null;
      selectedVehicleName = null;
      vehicleBrand = null;
      _searchController1.text = '';
      _showVehicleDropdown = false;
      _isVehicleSearchActive = false;
      _filteredVehicles.clear();
    });
    widget.onClearSelection?.call();
    widget.onVehicleSelected?.call({});
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _hasSearched = false;
      });
      return;
    }

    if (query == selectedLeadsName) {
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _showResults = true;
    });

    try {
      final result = await LeadsSrv.globalSearch(query);

      if (!mounted) return;

      setState(() {
        _hasSearched = true;
        _isLoadingSearch = false;

        if (result['success'] == true) {
          _searchResults = result['data'] ?? [];
          print('Search results: $_searchResults');
          _isErrorShowing = false;
        } else {
          _searchResults.clear();
          _showSearchError('Lead not found' ?? 'Search failed');
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSearch = false;
        _searchResults.clear();
        _hasSearched = true;
      });

      _showSearchError('Network error occurred');
      debugPrint('Search error: $e');
    }
  }

  Future<void> _performVehicleSearch(String query) async {
    if (query.isEmpty || !_hasLoadedVehicles) {
      setState(() {
        _filteredVehicles = [];
        _showVehicleDropdown = false;
      });
      return;
    }

    setState(() {
      _showVehicleDropdown = true;
      _filteredVehicles = _allVehicles.where((vehicle) {
        final vehicleName =
            vehicle['vehicle_name']?.toString().toLowerCase() ?? '';
        final assetName = vehicle['asset_name']?.toString().toLowerCase() ?? '';
        final vin = vehicle['VIN']?.toString().toLowerCase() ?? '';
        final brand = vehicle['brand']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return vehicleName.contains(searchQuery) ||
            assetName.contains(searchQuery) ||
            vin.contains(searchQuery) ||
            brand.contains(searchQuery);
      }).toList();
    });
  }

  void _showSearchError(String message) {
    if (!_isErrorShowing) {
      setState(() {
        _isErrorShowing = true;
      });

      Get.snackbar(
        'Search Error',
        message,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        onTap: (_) {
          setState(() {
            _isErrorShowing = false;
          });
        },
        isDismissible: true,
      );
    }
  }

  Future<void> loadAllVehicles() async {
    if (_hasLoadedVehicles) return;

    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      final result = await LeadsSrv.getAllVehicles();

      if (result['success']) {
        setState(() {
          _allVehicles = List<Map<String, dynamic>>.from(result['data']);
          _hasLoadedVehicles = true;
        });
        print('Vehicles loaded successfully: ${_allVehicles.length} vehicles');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to load vehicles'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching vehicles: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
        });
      }
    }
  }

  // In your LeadsearchTestdrive widget, update the _onLeadSelected method:

  void _onLeadSelected(Map<String, dynamic> lead) async {
    // Prevent multiple rapid selections
    if (_isSelecting) return;
    _isSelecting = true;

    final leadId = lead['lead_id']?.toString() ?? '';
    final leadName = lead['lead_name']?.toString() ?? '';
    final number = lead['mobile']?.toString();
    final pmi =
        lead['PMI']?.toString() ??
        lead['pmi']?.toString(); // Check both PMI and pmi
    final vehicleId = lead['vehicle_id']?.toString() ?? '';

    print(
      'Lead selected: ID=$leadId, Name=$leadName, PMI=$pmi, VehicleID=$vehicleId',
    );

    print('Full lead object: $lead'); // Debug full lead object

    // Check if mobile number is null or empty
    if (number == null || number.isEmpty || number == 'null') {
      print('Mobile number is null/empty for lead: $leadName');

      // Reset the selecting flag
      _isSelecting = false;

      // Show mobile number dialog
      await MobileDialogHelper.showMobileDialog(
        heading:
            "This enquiry has no number associated to it, please add one before creating a Test drive",
        context,
        leadId: leadId,
        leadName: leadName,
      );

      return;
    }
    setState(() {
      FocusScope.of(context).unfocus();
      selectedLeads = leadId;
      selectedLeadsName = leadName;
      selectedLeadPMI = pmi;
      _searchController.text = leadName;
      _searchResults.clear();
      _showResults = false;
      _hasSearched = false;

      // Clear any previous vehicle selection
      selectedVehicle = null;
      selectedVehicleName = null;
      vehicleBrand = null;
      _showVehicleDropdown = false;
      _isVehicleSearchActive = false;

      // Auto-fill vehicle search with PMI and set vehicleId
      if (pmi != null &&
          pmi.isNotEmpty &&
          vehicleId.isNotEmpty &&
          vehicleId != "null") {
        _searchController1.text = pmi;
        _isVehicleSearchActive = false;

        // Create a vehicle object with PMI and vehicleId from lead
        selectedVehicle = {
          'vehicle_name': pmi,
          'vehicle_id': vehicleId,
          'pmi': pmi,
          'from_lead': true,
        };
        selectedVehicleName = pmi;
        print('Auto-filled vehicle: PMI=$pmi, VehicleID=$vehicleId');
      } else {
        _searchController1.text = '';
        print('No valid PMI or vehicleId for lead');
      }
    });

    widget.onChanged(leadName);
    widget.onLeadSelected?.call(leadId, leadName);

    // Reset the flag after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _isSelecting = false;
    });
    // Pass the vehicle data (including vehicleId) when lead is selected
    if (pmi != null &&
        pmi.isNotEmpty &&
        vehicleId.isNotEmpty &&
        vehicleId != "null") {
      widget.onVehicleSelected?.call({
        'vehicle_name': pmi,
        'vehicle_id': vehicleId,
        'pmi': pmi,
        'from_lead': true,
      });
    } else {
      print(
        'Calling onVehicleSelected with empty vehicle data due to invalid vehicleId or PMI',
      );
      widget.onVehicleSelected?.call({});
      Get.snackbar(
        'Warning',
        'Selected lead has no valid vehicle associated. Please select a vehicle manually.',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void _onVehicleSelected(Map<String, dynamic> vehicle) {
    // Prevent selecting the same vehicle twice
    if (selectedVehicle != null &&
        selectedVehicle!['vehicle_id'] == vehicle['vehicle_id']) {
      setState(() {
        _showVehicleDropdown = false;
      });
      return;
    }

    // IMPORTANT: Set this flag to false BEFORE updating the text field
    // This prevents the onChanged listener from triggering a search
    _isVehicleSearchActive = false;

    setState(() {
      FocusScope.of(context).unfocus();
      selectedVehicle = vehicle;
      selectedVehicleName = vehicle['vehicle_name'];
      vehicleBrand = vehicle['brand'];
      _showVehicleDropdown = false;
      _filteredVehicles.clear();
    });

    _searchController1.text = vehicle['vehicle_name'] ?? '';

    widget.onVehicleSelected?.call(vehicle);
  }

  Widget _buildSearchResults() {
    if (!_showResults) return const SizedBox.shrink();

    if (_isLoadingSearch) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              dense: true,
              onTap: () => _onLeadSelected(result),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      result['lead_name']?.toString() ?? 'No Name',
                      style: AppFont.dropDowmLabel(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (result['mobile'] != null) ...[
                    Container(
                      width: 1,
                      height: 15,
                      color: Colors.grey.shade400,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Text(
                      result['mobile'].toString(),
                      style: AppFont.tinytext(context),
                    ),
                  ],
                ],
              ),
              subtitle: result['email'] != null
                  ? Text(
                      result['email'].toString(),
                      style: AppFont.smallText(context),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,

              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVehicleDropdown() {
    if (!_showVehicleDropdown || _filteredVehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: AppColors.iconGrey, blurRadius: 4)],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Column(
          children: [
            // Header showing search results count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredVehicles.length} vehicles found',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Vehicle list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _filteredVehicles[index];
                  return ListTile(
                    // onTap: () => _onVehicleSelected(vehicle),
                    onTap: () {
                      // Only allow selection if it's not already selected
                      if (selectedVehicleName != vehicle['vehicle_name']) {
                        _onVehicleSelected(vehicle);
                      } else {
                        // Just close dropdown if same vehicle is tapped
                        setState(() {
                          _showVehicleDropdown = false;
                        });
                      }
                    },
                    title: Text(
                      vehicle['vehicle_name'] ?? 'No Name',
                      style: TextStyle(
                        color: selectedVehicleName == vehicle['vehicle_name']
                            ? AppColors.colorsBlue
                            : AppColors.fontBlack,
                        fontWeight:
                            selectedVehicleName == vehicle['vehicle_name']
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vehicle['asset_name'] != null)
                          Text(
                            vehicle['asset_name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (vehicle['brand'] != null &&
                            vehicle['brand'].toString().isNotEmpty)
                          Text(
                            'Brand: ${vehicle['brand']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.colorsBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                    trailing: selectedVehicleName == vehicle['vehicle_name']
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                TextSpan(text: 'Select Lead'),
                if (widget.isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.055,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(5),
            color: AppColors.containerBg,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? Colors.red
                            : AppColors.fontColor,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBg,
                    // hintText: selectedVehicleName ?? 'Search for a lead',
                    // hintStyle: TextStyle(
                    //   color: selectedVehicleName != null
                    //       ? Colors.black
                    //       : Colors.grey,
                    //   fontSize: selectedVehicleName != null ? 14 : 13,
                    // ),
                    hintText: selectedLeadsName ?? 'Search for a lead',
                    hintStyle: TextStyle(
                      color: selectedLeadsName != null
                          ? Colors.black
                          : Colors.grey,
                      fontSize: selectedLeadsName != null ? 14 : 13,
                    ),
                    suffixIcon: selectedLeadsName != null
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              // _searchController1.clear();
                              setState(() {
                                _searchController.clear();
                                _clearSelection();
                              });
                              widget.onVehicleSelected?.call({});
                            },
                            tooltip: 'Clear vehicle selection',
                          )
                        : null,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 15,
                      color: AppColors.iconGrey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                  ),

                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  onTap: () {
                    if (_searchResults.isNotEmpty) {
                      setState(() {
                        _showResults = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        _buildSearchResults(),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 0.0, left: 5),
          child: Row(
            children: [
              // Text('Select Vehicle', style: AppFont.dropDowmLabel(context)),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.fontBlack,
                  ),
                  children: [
                    TextSpan(text: 'Select Vehicle'),
                    if (widget.isRequired)
                      const TextSpan(
                        text: " *",
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
                  controller: _searchController1,
                  focusNode: _vehicleFocusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color:
                            widget.errorText != null &&
                                widget.errorText!.isNotEmpty
                            ? Colors.red
                            : AppColors.fontColor,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBg,
                    hintText: selectedVehicleName ?? 'Search vehicles...',
                    // hintText:
                    //     selectedVehicleName ??
                    //     (selectedLeadPMI != null
                    //         ? 'Search vehicles or use PMI: ${selectedLeadPMI}'
                    //         : 'Search vehicles...'),
                    hintStyle: TextStyle(
                      color: selectedVehicleName != null
                          ? Colors.black
                          : Colors.grey,
                      fontSize: selectedVehicleName != null ? 14 : 13,
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 15,
                      color: AppColors.iconGrey,
                    ),
                    suffixIcon: selectedVehicleName != null
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController1.clear();
                              setState(() {
                                selectedVehicle = null;
                                selectedVehicleName = null;
                                vehicleBrand = null;
                                _showVehicleDropdown = false;
                                _isVehicleSearchActive = false;
                                _filteredVehicles.clear();
                              });
                              widget.onVehicleSelected?.call({});
                            },
                            tooltip: 'Clear vehicle selection',
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  onTap: () {
                    // Only show dropdown if user hasn't selected a vehicle
                    if (selectedVehicleName == null) {
                      setState(() {
                        _isVehicleSearchActive = true;
                      });
                    }
                  },
                  // onTap: () {
                  //   // Only show dropdown if user hasn't selected a vehicle
                  //   if (selectedVehicleName == null) {
                  //     setState(() {
                  //       _isVehicleSearchActive = true;
                  //     });
                  //     // If there's PMI available, auto-fill it for user convenience
                  //     if (selectedLeadPMI != null &&
                  //         selectedLeadPMI!.isNotEmpty &&
                  //         _searchController1.text.isEmpty) {
                  //       _searchController1.text = selectedLeadPMI!;
                  //       _performVehicleSearch(selectedLeadPMI!);
                  //     }
                  //   }
                  // },
                  onChanged: (value) {
                    if (!_isVehicleSearchActive) {
                      setState(() {
                        _isVehicleSearchActive = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        if (_isLoadingVehicles && !_hasLoadedVehicles)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        _buildVehicleDropdown(),
      ],
    );
  }
}
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/services/api_srv.dart';
// import 'package:smartassist/widgets/mobile_check_dialog.dart';

// typedef VehicleSelectedCallback =
//     void Function(Map<String, dynamic> selectedVehicle);

// class LeadsearchTestdrive extends StatefulWidget {
//   final String? errorText;
//   final bool isRequired;
//   final ValueChanged<String> onChanged;
//   final Function(String leadId, String leadName)? onLeadSelected;
//   final VoidCallback? onClearSelection;
//   final VehicleSelectedCallback? onVehicleSelected;

//   const LeadsearchTestdrive({
//     super.key,
//     this.onLeadSelected,
//     this.onClearSelection,
//     required this.errorText,
//     required this.onChanged,
//     this.isRequired = false,
//     this.onVehicleSelected,
//   });

//   @override
//   State<LeadsearchTestdrive> createState() => _LeadsearchTestdriveState();
// }

// class _LeadsearchTestdriveState extends State<LeadsearchTestdrive> {
//   // Controllers and Focus
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   final TextEditingController _searchController1 = TextEditingController();
//   final FocusNode _vehicleFocusNode = FocusNode();
//   bool _isSelecting = false;
//   bool _isLoadingVehicles = false;
//   bool _hasLoadedVehicles = false;
//   List<Map<String, dynamic>> _filteredVehicles = [];
//   List<Map<String, dynamic>> _allVehicles = []; // Store all vehicles

//   Map<String, dynamic>? selectedVehicle; // Store entire vehicle object
//   String? selectedVehicleName;
//   String? vehicleBrand;

//   // Search state
//   bool _isLoadingSearch = false;
//   List<dynamic> _searchResults = [];
//   bool _showResults = false;
//   bool _hasSearched = false;

//   // Selected lead state
//   String? selectedLeads;
//   String? selectedLeadsName;
//   String? selectedLeadPMI; // Store PMI from selected lead

//   // Vehicle search state
//   bool _showVehicleDropdown = false;
//   bool _isVehicleSearchActive = false;
//   String _lastVehicleQuery = '';

//   // Debouncing
//   Timer? _debounceTimer;
//   Timer? _vehicleDebounceTimer;
//   static const Duration _debounceDuration = Duration(milliseconds: 800);

//   // Error handling
//   bool _isErrorShowing = false;

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//     _searchController1.addListener(_onVehicleSearchChanged);
//     _focusNode.addListener(_onFocusChanged);
//     _vehicleFocusNode.addListener(_onVehicleFocusChanged);
//     // Load vehicles initially - but don't show them until user interacts
//     loadAllVehicles();
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _vehicleDebounceTimer?.cancel();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController1.removeListener(_onVehicleSearchChanged);
//     _searchController.dispose();
//     _searchController1.dispose();
//     _focusNode.removeListener(_onFocusChanged);
//     _focusNode.dispose();
//     _vehicleFocusNode.removeListener(_onVehicleFocusChanged);
//     _vehicleFocusNode.dispose();
//     _isSelecting = false;
//     super.dispose();
//   }

//   void _onFocusChanged() {
//     if (!_focusNode.hasFocus && _showResults) {
//       Future.delayed(const Duration(milliseconds: 150), () {
//         if (mounted && !_focusNode.hasFocus) {
//           setState(() {
//             _showResults = false;
//           });
//         }
//       });
//     }
//   }

//   void _onVehicleFocusChanged() {
//     if (!_vehicleFocusNode.hasFocus && _showVehicleDropdown) {
//       Future.delayed(const Duration(milliseconds: 150), () {
//         if (mounted && !_vehicleFocusNode.hasFocus) {
//           setState(() {
//             _showVehicleDropdown = false;
//           });
//         }
//       });
//     }
//   }

//   void _onSearchChanged() {
//     final query = _searchController.text.trim();

//     if (_isErrorShowing) {
//       setState(() {
//         _isErrorShowing = false;
//       });
//     }

//     if (query.isEmpty && selectedLeadsName != null) {
//       _clearSelection();
//     }

//     _debounceTimer?.cancel();
//     _debounceTimer = Timer(_debounceDuration, () {
//       if (mounted) {
//         _performSearch(query);
//       }
//     });
//   }

//   void _onVehicleSearchChanged() {
//     final query = _searchController1.text.trim();

//     // If user clears the field, clear selection
//     if (query.isEmpty && selectedVehicleName != null) {
//       setState(() {
//         selectedVehicle = null;
//         selectedVehicleName = null;
//         vehicleBrand = null;
//         _showVehicleDropdown = false;
//         _isVehicleSearchActive = false;
//       });
//       widget.onVehicleSelected?.call({});
//       return;
//     }

//     // Only trigger search if user is actively typing (not from PMI auto-fill)
//     if (_isVehicleSearchActive) {
//       _vehicleDebounceTimer?.cancel();
//       _vehicleDebounceTimer = Timer(_debounceDuration, () {
//         if (mounted && query != _lastVehicleQuery) {
//           _lastVehicleQuery = query;
//           _performVehicleSearch(query);
//         }
//       });
//     }
//   }

//   void _clearSelection() {
//     setState(() {
//       selectedLeads = null;
//       selectedLeadsName = null;
//       selectedLeadPMI = null;
//       _searchController.text = '';
//       _searchResults.clear();
//       _showResults = false;
//       _hasSearched = false;
//       // Clear vehicle selection as well
//       selectedVehicle = null;
//       selectedVehicleName = null;
//       vehicleBrand = null;
//       _searchController1.text = '';
//       _showVehicleDropdown = false;
//       _isVehicleSearchActive = false;
//       _filteredVehicles.clear();
//     });
//     widget.onClearSelection?.call();
//     widget.onVehicleSelected?.call({});
//   }

//   Future<void> _performSearch(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         _searchResults.clear();
//         _showResults = false;
//         _hasSearched = false;
//       });
//       return;
//     }

//     if (query == selectedLeadsName) {
//       return;
//     }

//     setState(() {
//       _isLoadingSearch = true;
//       _showResults = true;
//     });

//     try {
//       final result = await LeadsSrv.globalSearch(query);

//       if (!mounted) return;

//       setState(() {
//         _hasSearched = true;
//         _isLoadingSearch = false;

//         if (result['success'] == true) {
//           _searchResults = result['data'] ?? [];
//           print('Search results: $_searchResults');
//           _isErrorShowing = false;
//         } else {
//           _searchResults.clear();
//           _showSearchError('Lead not found' ?? 'Search failed');
//         }
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         _isLoadingSearch = false;
//         _searchResults.clear();
//         _hasSearched = true;
//       });

//       _showSearchError('Network error occurred');
//       debugPrint('Search error: $e');
//     }
//   }

//   Future<void> _performVehicleSearch(String query) async {
//     if (query.isEmpty || !_hasLoadedVehicles) {
//       setState(() {
//         _filteredVehicles = [];
//         _showVehicleDropdown = false;
//       });
//       return;
//     }

//     setState(() {
//       _showVehicleDropdown = true;
//       _filteredVehicles = _allVehicles.where((vehicle) {
//         final vehicleName =
//             vehicle['vehicle_name']?.toString().toLowerCase() ?? '';
//         final assetName = vehicle['asset_name']?.toString().toLowerCase() ?? '';
//         final vin = vehicle['VIN']?.toString().toLowerCase() ?? '';
//         final brand = vehicle['brand']?.toString().toLowerCase() ?? '';
//         final searchQuery = query.toLowerCase();

//         return vehicleName.contains(searchQuery) ||
//             assetName.contains(searchQuery) ||
//             vin.contains(searchQuery) ||
//             brand.contains(searchQuery);
//       }).toList();
//     });
//   }

//   void _showSearchError(String message) {
//     if (!_isErrorShowing) {
//       setState(() {
//         _isErrorShowing = true;
//       });

//       Get.snackbar(
//         'Search Error',
//         message,
//         duration: const Duration(seconds: 3),
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         onTap: (_) {
//           setState(() {
//             _isErrorShowing = false;
//           });
//         },
//         isDismissible: true,
//       );
//     }
//   }

//   Future<void> loadAllVehicles() async {
//     if (_hasLoadedVehicles) return;

//     setState(() {
//       _isLoadingVehicles = true;
//     });

//     try {
//       final result = await LeadsSrv.getAllVehicles();

//       if (result['success']) {
//         setState(() {
//           _allVehicles = List<Map<String, dynamic>>.from(result['data']);
//           _hasLoadedVehicles = true;
//         });
//         print('Vehicles loaded successfully: ${_allVehicles.length} vehicles');
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result['error'] ?? 'Failed to load vehicles'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print("Error fetching vehicles: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading vehicles: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingVehicles = false;
//         });
//       }
//     }
//   }

//   // In your LeadsearchTestdrive widget, update the _onLeadSelected method:

//   void _onLeadSelected(Map<String, dynamic> lead) async {
//     // Prevent multiple rapid selections
//     if (_isSelecting) return;
//     _isSelecting = true;

//     final leadId = lead['lead_id']?.toString() ?? '';
//     final leadName = lead['lead_name']?.toString() ?? '';
//     final number = lead['mobile']?.toString();
//     final pmi =
//         lead['PMI']?.toString() ??
//         lead['pmi']?.toString(); // Check both PMI and pmi
//     final vehicleId = lead['vehicle_id']?.toString() ?? '';

//     print(
//       'Lead selected: ID=$leadId, Name=$leadName, PMI=$pmi, VehicleID=$vehicleId',
//     );

//     print('Full lead object: $lead'); // Debug full lead object

//     // Check if mobile number is null or empty
//     if (number == null || number.isEmpty || number == 'null') {
//       print('Mobile number is null/empty for lead: $leadName');

//       // Reset the selecting flag
//       _isSelecting = false;

//       // Show mobile number dialog
//       await MobileDialogHelper.showMobileDialog(
//         heading:
//             "This enquiry has no number associated to it, please add one before creating a Test drive",
//         context,
//         leadId: leadId,
//         leadName: leadName,
//       );

//       return;
//     }
//     setState(() {
//       FocusScope.of(context).unfocus();
//       selectedLeads = leadId;
//       selectedLeadsName = leadName;
//       selectedLeadPMI = pmi;
//       _searchController.text = leadName;
//       _searchResults.clear();
//       _showResults = false;
//       _hasSearched = false;

//       // Clear any previous vehicle selection
//       selectedVehicle = null;
//       selectedVehicleName = null;
//       vehicleBrand = null;
//       _showVehicleDropdown = false;
//       _isVehicleSearchActive = false;

//       // Auto-fill vehicle search with PMI and set vehicleId
//       if (pmi != null &&
//           pmi.isNotEmpty &&
//           vehicleId.isNotEmpty &&
//           vehicleId != "null") {
//         _searchController1.text = pmi;
//         _isVehicleSearchActive = false;

//         // Create a vehicle object with PMI and vehicleId from lead
//         selectedVehicle = {
//           'vehicle_name': pmi,
//           'vehicle_id': vehicleId,
//           'pmi': pmi,
//           'from_lead': true,
//         };
//         selectedVehicleName = pmi;
//         print('Auto-filled vehicle: PMI=$pmi, VehicleID=$vehicleId');
//       } else {
//         _searchController1.text = '';
//         print('No valid PMI or vehicleId for lead');
//       }
//     });

//     widget.onChanged(leadName);
//     widget.onLeadSelected?.call(leadId, leadName);

//     // Reset the flag after a short delay
//     Future.delayed(const Duration(milliseconds: 300), () {
//       _isSelecting = false;
//     });
//     // Pass the vehicle data (including vehicleId) when lead is selected
//     if (pmi != null &&
//         pmi.isNotEmpty &&
//         vehicleId.isNotEmpty &&
//         vehicleId != "null") {
//       widget.onVehicleSelected?.call({
//         'vehicle_name': pmi,
//         'vehicle_id': vehicleId,
//         'pmi': pmi,
//         'from_lead': true,
//       });
//     } else {
//       print(
//         'Calling onVehicleSelected with empty vehicle data due to invalid vehicleId or PMI',
//       );
//       widget.onVehicleSelected?.call({});
//       Get.snackbar(
//         'Warning',
//         'Selected lead has no valid vehicle associated. Please select a vehicle manually.',
//         duration: const Duration(seconds: 3),
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//     }
//   }

//   void _onVehicleSelected(Map<String, dynamic> vehicle) {
//     // Prevent selecting the same vehicle twice
//     if (selectedVehicle != null &&
//         selectedVehicle!['vehicle_id'] == vehicle['vehicle_id']) {
//       return;
//     }
//     setState(() {
//       FocusScope.of(context).unfocus();
//       selectedVehicle = vehicle;
//       selectedVehicleName = vehicle['vehicle_name'];
//       vehicleBrand = vehicle['brand'];
//       _searchController1.text = vehicle['vehicle_name'] ?? '';
//       _showVehicleDropdown = false;
//       _isVehicleSearchActive = false;
//       _filteredVehicles.clear();
//     });

//     widget.onVehicleSelected?.call(vehicle);
//   }

//   Widget _buildSearchResults() {
//     if (!_showResults) return const SizedBox.shrink();

//     if (_isLoadingSearch) {
//       return Container(
//         margin: const EdgeInsets.only(top: 8),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(5),
//           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
//         ),
//         child: const Center(
//           child: SizedBox(
//             height: 20,
//             width: 20,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//         ),
//       );
//     }

//     if (_searchResults.isNotEmpty) {
//       return Container(
//         margin: const EdgeInsets.only(top: 8),
//         constraints: const BoxConstraints(maxHeight: 200),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(5),
//           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
//         ),
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: _searchResults.length,
//           itemBuilder: (context, index) {
//             final result = _searchResults[index];
//             return ListTile(
//               dense: true,
//               onTap: () => _onLeadSelected(result),
//               title: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       result['lead_name']?.toString() ?? 'No Name',
//                       style: AppFont.dropDowmLabel(context),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (result['mobile'] != null) ...[
//                     Container(
//                       width: 1,
//                       height: 15,
//                       color: Colors.grey.shade400,
//                       margin: const EdgeInsets.symmetric(horizontal: 8),
//                     ),
//                     Text(
//                       result['mobile'].toString(),
//                       style: AppFont.tinytext(context),
//                     ),
//                   ],
//                 ],
//               ),
//               subtitle: result['email'] != null
//                   ? Text(
//                       result['email'].toString(),
//                       style: AppFont.smallText(context),
//                       overflow: TextOverflow.ellipsis,
//                     )
//                   : null,

//               trailing: Icon(
//                 Icons.arrow_forward_ios,
//                 size: 12,
//                 color: Colors.grey.shade400,
//               ),
//             );
//           },
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }

//   Widget _buildVehicleDropdown() {
//     if (!_showVehicleDropdown || _filteredVehicles.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(5),
//         boxShadow: const [BoxShadow(color: AppColors.iconGrey, blurRadius: 4)],
//       ),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.3,
//         ),
//         child: Column(
//           children: [
//             // Header showing search results count
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(5),
//                   topRight: Radius.circular(5),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.search, size: 16, color: Colors.grey.shade600),
//                   const SizedBox(width: 8),
//                   Text(
//                     '${_filteredVehicles.length} vehicles found',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey.shade600,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Vehicle list
//             Flexible(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: _filteredVehicles.length,
//                 itemBuilder: (context, index) {
//                   final vehicle = _filteredVehicles[index];
//                   return ListTile(
//                     // onTap: () => _onVehicleSelected(vehicle),
//                     onTap: () {
//                       // Only allow selection if it's not already selected
//                       if (selectedVehicleName != vehicle['vehicle_name']) {
//                         _onVehicleSelected(vehicle);
//                       } else {
//                         // Just close dropdown if same vehicle is tapped
//                         setState(() {
//                           _showVehicleDropdown = false;
//                         });
//                       }
//                     },
//                     title: Text(
//                       vehicle['vehicle_name'] ?? 'No Name',
//                       style: TextStyle(
//                         color: selectedVehicleName == vehicle['vehicle_name']
//                             ? AppColors.colorsBlue
//                             : AppColors.fontBlack,
//                         fontWeight:
//                             selectedVehicleName == vehicle['vehicle_name']
//                             ? FontWeight.w600
//                             : FontWeight.normal,
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (vehicle['asset_name'] != null)
//                           Text(
//                             vehicle['asset_name'],
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         if (vehicle['brand'] != null &&
//                             vehicle['brand'].toString().isNotEmpty)
//                           Text(
//                             'Brand: ${vehicle['brand']}',
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey[500],
//                             ),
//                           ),
//                       ],
//                     ),
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: AppColors.colorsBlue,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.directions_car,
//                         color: AppColors.colorsBlue,
//                         size: 20,
//                       ),
//                     ),
//                     trailing: selectedVehicleName == vehicle['vehicle_name']
//                         ? Icon(
//                             Icons.check_circle,
//                             color: Colors.green,
//                             size: 20,
//                           )
//                         : Icon(
//                             Icons.arrow_forward_ios,
//                             size: 12,
//                             color: Colors.grey.shade400,
//                           ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
//           child: RichText(
//             text: TextSpan(
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.fontBlack,
//               ),
//               children: [
//                 TextSpan(text: 'Select Lead'),
//                 if (widget.isRequired)
//                   const TextSpan(
//                     text: " *",
//                     style: TextStyle(color: Colors.red),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           height: MediaQuery.of(context).size.height * 0.055,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.transparent),
//             borderRadius: BorderRadius.circular(5),
//             color: AppColors.containerBg,
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _searchController,
//                   focusNode: _focusNode,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide(
//                         color:
//                             widget.errorText != null &&
//                                 widget.errorText!.isNotEmpty
//                             ? Colors.red
//                             : Colors.transparent,
//                       ),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide(
//                         color:
//                             widget.errorText != null &&
//                                 widget.errorText!.isNotEmpty
//                             ? Colors.red
//                             : Colors.transparent,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide(
//                         color:
//                             widget.errorText != null &&
//                                 widget.errorText!.isNotEmpty
//                             ? Colors.red
//                             : AppColors.fontColor,
//                       ),
//                     ),
//                     filled: true,
//                     fillColor: AppColors.containerBg,
//                     hintText: selectedVehicleName ?? 'Search for a lead',
//                     // hintText:
//                     //     selectedVehicleName ??
//                     //     (selectedLeadPMI != null
//                     //         ? 'Search vehicles or use PMI: ${selectedLeadPMI}'
//                     //         : 'Search vehicles...'),
//                     hintStyle: TextStyle(
//                       color: selectedVehicleName != null
//                           ? Colors.black
//                           : Colors.grey,
//                       fontSize: selectedVehicleName != null ? 14 : 13,
//                     ),
//                     prefixIcon: const Icon(
//                       FontAwesomeIcons.magnifyingGlass,
//                       size: 15,
//                       color: AppColors.iconGrey,
//                     ),
//                     suffixIcon: selectedVehicleName != null
//                         ? IconButton(
//                             icon: Icon(
//                               Icons.clear,
//                               color: Colors.grey.shade600,
//                               size: 18,
//                             ),
//                             onPressed: () {
//                               // _searchController1.clear();
//                               setState(() {
//                                 _searchController.clear();
//                                 _clearSelection();
//                               });
//                               widget.onVehicleSelected?.call({});
//                             },
//                             tooltip: 'Clear vehicle selection',
//                           )
//                         : null,
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 0,
//                       horizontal: 10,
//                     ),
//                   ),

//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black87,
//                   ),
//                   onTap: () {
//                     if (_searchResults.isNotEmpty) {
//                       setState(() {
//                         _showResults = true;
//                       });
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),

//         _buildSearchResults(),

//         const SizedBox(height: 10),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 0.0, left: 5),
//           child: Row(
//             children: [
//               // Text('Select Vehicle', style: AppFont.dropDowmLabel(context)),
//               RichText(
//                 text: TextSpan(
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.fontBlack,
//                   ),
//                   children: [
//                     TextSpan(text: 'Select Vehicle'),
//                     if (widget.isRequired)
//                       const TextSpan(
//                         text: " *",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           height: MediaQuery.of(context).size.height * 0.055,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(5),
//             color: AppColors.containerBg,
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _searchController1,
//                   focusNode: _vehicleFocusNode,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide(
//                         color:
//                             widget.errorText != null &&
//                                 widget.errorText!.isNotEmpty
//                             ? Colors.red
//                             : Colors.transparent,
//                       ),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide(
//                         color:
//                             widget.errorText != null &&
//                                 widget.errorText!.isNotEmpty
//                             ? Colors.red
//                             : Colors.transparent,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(5),
//                       borderSide: BorderSide(
//                         color:
//                             widget.errorText != null &&
//                                 widget.errorText!.isNotEmpty
//                             ? Colors.red
//                             : AppColors.fontColor,
//                       ),
//                     ),
//                     filled: true,
//                     fillColor: AppColors.containerBg,
//                     hintText: selectedVehicleName ?? 'Search vehicles...',
//                     // hintText:
//                     //     selectedVehicleName ??
//                     //     (selectedLeadPMI != null
//                     //         ? 'Search vehicles or use PMI: ${selectedLeadPMI}'
//                     //         : 'Search vehicles...'),
//                     hintStyle: TextStyle(
//                       color: selectedVehicleName != null
//                           ? Colors.black
//                           : Colors.grey,
//                       fontSize: selectedVehicleName != null ? 14 : 13,
//                     ),
//                     prefixIcon: const Icon(
//                       FontAwesomeIcons.magnifyingGlass,
//                       size: 15,
//                       color: AppColors.iconGrey,
//                     ),
//                     suffixIcon: selectedVehicleName != null
//                         ? IconButton(
//                             icon: Icon(
//                               Icons.clear,
//                               color: Colors.grey.shade600,
//                               size: 18,
//                             ),
//                             onPressed: () {
//                               _searchController1.clear();
//                               setState(() {
//                                 selectedVehicle = null;
//                                 selectedVehicleName = null;
//                                 vehicleBrand = null;
//                                 _showVehicleDropdown = false;
//                                 _isVehicleSearchActive = false;
//                                 _filteredVehicles.clear();
//                               });
//                               widget.onVehicleSelected?.call({});
//                             },
//                             tooltip: 'Clear vehicle selection',
//                           )
//                         : null,
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 0,
//                       horizontal: 10,
//                     ),
//                   ),
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black,
//                   ),
//                   onTap: () {
//                     // Only show dropdown if user hasn't selected a vehicle
//                     if (selectedVehicleName == null) {
//                       setState(() {
//                         _isVehicleSearchActive = true;
//                       });
//                     }
//                   },
//                   // onTap: () {
//                   //   // Only show dropdown if user hasn't selected a vehicle
//                   //   if (selectedVehicleName == null) {
//                   //     setState(() {
//                   //       _isVehicleSearchActive = true;
//                   //     });
//                   //     // If there's PMI available, auto-fill it for user convenience
//                   //     if (selectedLeadPMI != null &&
//                   //         selectedLeadPMI!.isNotEmpty &&
//                   //         _searchController1.text.isEmpty) {
//                   //       _searchController1.text = selectedLeadPMI!;
//                   //       _performVehicleSearch(selectedLeadPMI!);
//                   //     }
//                   //   }
//                   // },
//                   onChanged: (value) {
//                     if (!_isVehicleSearchActive) {
//                       setState(() {
//                         _isVehicleSearchActive = true;
//                       });
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),

//         if (_isLoadingVehicles && !_hasLoadedVehicles)
//           const Padding(
//             padding: EdgeInsets.only(top: 8.0),
//             child: Center(child: CircularProgressIndicator()),
//           ),

//         _buildVehicleDropdown(),
//       ],
//     );
//   }
// }
