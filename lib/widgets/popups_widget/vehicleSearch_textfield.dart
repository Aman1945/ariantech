import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';

typedef VehicleSelectedCallback =
    void Function(Map<String, dynamic> selectedVehicle);

// Updated VehiclesearchTextfield widget
class VehiclesearchTextfield extends StatefulWidget {
  final String? errorText;
  final VehicleSelectedCallback? onVehicleSelected;
  final String? initialVehicleName;
  final String? initialVehicleId;
  const VehiclesearchTextfield({
    super.key,
    this.onVehicleSelected,
    this.errorText,
    this.initialVehicleName,
    this.initialVehicleId,
  });

  @override
  _VehiclesearchTextfieldState createState() => _VehiclesearchTextfieldState();
}

class _VehiclesearchTextfieldState extends State<VehiclesearchTextfield> {
  bool _isLoadingVehicles = false;
  bool _hasLoadedVehicles = false;
  bool showClearIcon = false;
  List<Map<String, dynamic>> _filteredVehicles = [];
  List<Map<String, dynamic>> _allVehicles = []; // Store all vehicles
  final TextEditingController _searchController1 = TextEditingController();

  Map<String, dynamic>? selectedVehicle; // Store entire vehicle object
  String? selectedVehicleName;
  String? vehicleBrand;
  String? vehicleId;

  @override
  void initState() {
    super.initState();

    // Add listener to search controller for real-time filtering
    // _searchController1.addListener(() {
    //   filterVehicles(_searchController1.text);
    // });

    if (widget.initialVehicleName != null &&
        widget.initialVehicleName!.isNotEmpty) {
      selectedVehicleName = widget.initialVehicleName;
      vehicleId = widget.initialVehicleId;
      showClearIcon = true; // Show clear icon for pre-selected vehicle
    }

    loadAllVehicles();

    _searchController1.addListener(() {
      setState(() {
        showClearIcon = _searchController1.text.isNotEmpty;
      });
      filterVehicles(_searchController1.text);
    });
  }

  // Load all vehicles once
  Future<void> loadAllVehicles() async {
    if (_hasLoadedVehicles) return; // Prevent multiple API calls

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
      } else {
        // Handle error - you can show a snackbar or error message
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

  // Filter vehicles based on search query
  void filterVehicles(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredVehicles = [];
      });
      return;
    }

    setState(() {
      _filteredVehicles = _allVehicles.where((vehicle) {
        final vehicleName =
            vehicle['vehicle_name']?.toString().toLowerCase() ?? '';
        final assetName = vehicle['asset_name']?.toString().toLowerCase() ?? '';
        final vin = vehicle['VIN']?.toString().toLowerCase() ?? '';
        final brand = vehicle['brand']?.toString().toLowerCase() ?? '';
        final vehicleId = vehicle['vehicle_id']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return vehicleName.contains(searchQuery) ||
            assetName.contains(searchQuery) ||
            vin.contains(searchQuery) ||
            brand.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Text('Select Vehicle', style: AppFont.dropDowmLabel(context)),
        Padding(
          padding: const EdgeInsets.only(bottom: 0.0, left: 5),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(
                  text: 'Select Vehicle',
                  style: AppFont.dropDowmLabel(context),
                ),

                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
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
                        color: widget.errorText != null
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: widget.errorText != null
                            ? Colors.red
                            : Colors.transparent,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBg,
                    hintText: selectedVehicleName ?? 'Select a vehicle',
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
                    // Add the clear icon (X) here
                    suffixIcon: showClearIcon || selectedVehicleName != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.iconGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController1.clear();
                                selectedVehicle = null;
                                selectedVehicleName = null;
                                vehicleBrand = null;
                                vehicleId = null;
                                _filteredVehicles.clear();
                                showClearIcon = false;
                              });

                              // Notify parent that vehicle was cleared
                              if (widget.onVehicleSelected != null) {
                                widget.onVehicleSelected!({});
                              }
                            },
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
                ),
              ),
            ],
          ),
        ),

        // Show loading indicator when initially loading vehicles
        if (_isLoadingVehicles && !_hasLoadedVehicles)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(
              // child: CircularProgressIndicator()
            ),
          ),

        // Show filtered search results
        if (_filteredVehicles.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(color: AppColors.iconGrey, blurRadius: 4),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _filteredVehicles[index];
                  return ListTile(
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).unfocus();
                        selectedVehicle =
                            vehicle; // Store entire vehicle object
                        selectedVehicleName = vehicle['vehicle_name'];
                        vehicleBrand = vehicle['brand'];
                        vehicleId = vehicle['vehicle_id'];
                        _searchController1.clear();
                        _filteredVehicles.clear();
                      });

                      // Pass the entire vehicle object to callback
                      if (widget.onVehicleSelected != null) {
                        widget.onVehicleSelected!(vehicle);
                      }
                    },
                    title: Text(
                      vehicle['vehicle_name'] ?? 'No Name',
                      style: TextStyle(
                        color: selectedVehicleName == vehicle['vehicle_name']
                            ? Colors.black
                            : AppColors.fontBlack,
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
                    leading: const Icon(Icons.directions_car),
                  );
                },
              ),
            ),
          ),

        // Show "No results found" when search has no matches
        if (_searchController1.text.isNotEmpty &&
            _filteredVehicles.isEmpty &&
            _hasLoadedVehicles)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(color: AppColors.iconGrey, blurRadius: 4),
              ],
            ),
            child: const Center(
              child: Text(
                'No vehicles found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController1.dispose();
    super.dispose();
  }
}
