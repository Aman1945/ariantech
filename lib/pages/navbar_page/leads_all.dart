import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/buttons/add_btn.dart';
import 'package:smartassist/widgets/home_btn.dart/dashboard_popups/create_leads.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/lead_update.dart';
import 'package:smartassist/pages/Home/reassign_enq.dart';
import 'package:smartassist/widgets/reusable/globle_speechtotext.dart';
import 'package:smartassist/widgets/reusable/skeleton_globle_search_card.dart';

class AllLeads extends StatefulWidget {
  const AllLeads({super.key});

  @override
  State<AllLeads> createState() => _AllLeadsState();
}

class _AllLeadsState extends State<AllLeads> {
  bool isLoading = true;
  final Widget _createLeads = CreateLeads(onFormSubmit: () {});
  final Map<String, double> _swipeOffsets = {};
  final ScrollController _scrollController = ScrollController();
  Set<String> selectedLeads = {};
  bool isSelectionMode = false;
  List<dynamic> upcomingTasks = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _filteredTasks = []; // Local filtered results
  bool _isLoadingSearch = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  String _selectedSortBy = 'Date Created';
  String _selectedStatus = 'All';
  String _selectedTimeFilter = 'All Time';

  // PATCH 1: Add these filter count variables
  Map<String, int> _filterCounts = {};
  bool _hasActiveFilters = false;
  String _selectedLeadSource = 'All';
  String _selectedLeadSourceCategory = 'All'; // Main category selection

  // Update your filter options lists:
  // final List<String> _leadSourceCategoryOptions = [
  //   'All Sources',
  //   'Online Sources',
  //   'Others',
  // ];

  final List<String> _leadSourceCategoryOptions = ['All', 'Digitals', 'Others'];

  final List<String> _onlineSourceOptions = ['All Online'];

  // final List<String> _otherSourceOptions = [
  //   "Email",
  //   "Existing Customer",
  //   "Field Visit",
  //   "Phone-in",
  //   "Phone-out",
  //   "Purchased List",
  //   "Referral",
  //   "Retailer Experience",
  //   "SMS",
  //   "Social (Retailer)",
  //   "Walk-in",
  // ];

  final List<String> _offlineSourcesList = [
    "Email",
    "Existing Customer",
    "Field Visit",
    "Phone-in",
    "Phone-out",
    "Purchased List",
    "Referral",
    "Retailer Experience",
    "SMS",
    "Social (Retailer)",
    "Walk-in",
  ];
  // Filter options
  final List<String> _sortOptions = [
    'Date Created',
    'Name (A-Z)',
    'Name (Z-A)',
    'Recently Updated',
    'Oldest First',
  ];

  final List<String> _statusOptions = [
    'All',
    'New',
    'Follow Up',
    'Qualified',
    'Lost',
  ];

  final List<String> _timeFilterOptions = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  void _onHorizontalDragUpdate(DragUpdateDetails details, String leadId) {
    setState(() {
      _swipeOffsets[leadId] =
          (_swipeOffsets[leadId] ?? 0) + (details.primaryDelta ?? 0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, dynamic item, int index) {
    String leadId = item['lead_id'];
    double swipeOffset = _swipeOffsets[leadId] ?? 0;

    if (swipeOffset > 100) {
      _toggleFavorite(leadId, index);
      bool currentStatus = item['favourite'] ?? false;
      bool newStatus = !currentStatus;

      setState(() {
        upcomingTasks[index]['favourite'] = newStatus;
        _updateFilteredResults();
      });
    } else if (swipeOffset < -100) {
      _handleCall(item);
    }

    setState(() {
      _swipeOffsets[leadId] = 0.0;
    });
  }

  void _toggleSelection(String leadId) {
    HapticFeedback.selectionClick();

    setState(() {
      if (selectedLeads.contains(leadId)) {
        selectedLeads.remove(leadId);
        if (selectedLeads.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedLeads.add(leadId);
        if (!isSelectionMode) {
          isSelectionMode = true;
          HapticFeedback.mediumImpact();
        }
      }
    });
  }

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  EdgeInsets _responsivePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: _isTablet(context) ? 20 : (_isSmallScreen(context) ? 8 : 10),
    vertical: _isTablet(context) ? 12 : 8,
  );

  double _titleFontSize(BuildContext context) =>
      _isTablet(context) ? 20 : (_isSmallScreen(context) ? 16 : 18);
  double _bodyFontSize(BuildContext context) =>
      _isTablet(context) ? 16 : (_isSmallScreen(context) ? 12 : 14);
  double _smallFontSize(BuildContext context) =>
      _isTablet(context) ? 14 : (_isSmallScreen(context) ? 10 : 12);

  Future<void> _toggleFavorite(String leadId, int index) async {
    final token = await Storage.getToken();
    try {
      bool currentStatus = upcomingTasks[index]['favourite'] ?? false;
      bool newFavoriteStatus = !currentStatus;

      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/favourites/mark-fav/lead/$leadId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          upcomingTasks[index]['favourite'] = newFavoriteStatus;
          int filteredIndex = _filteredTasks.indexWhere(
            (task) => task['lead_id'] == leadId,
          );
          if (filteredIndex != -1) {
            _filteredTasks[filteredIndex]['favourite'] = newFavoriteStatus;
          }
        });
      } else {
        print('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _handleCall(dynamic item) {
    print("Call action triggered for ${item['name']}");
    // Implement actual call functionality here
  }

  @override
  void initState() {
    super.initState();
    fetchTasksData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // <-- add this!
    super.dispose();
  }

  Future<void> fetchTasksData() async {
    final token = await Storage.getToken();
    try {
      final url = 'https://api.smartassistapp.in/api/leads/fetch/all';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('leads all url $url');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          upcomingTasks = data['data']['rows'] ?? [];
          _filteredTasks = List.from(upcomingTasks);
          _applyFilters();
          isLoading = false;
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  void _performLocalSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTasks = List.from(upcomingTasks);
        _applyFilters();
      });
      return;
    }

    setState(() {
      _filteredTasks = upcomingTasks.where((item) {
        String name = (item['lead_name'] ?? '').toString().toLowerCase();
        String email = (item['email'] ?? '').toString().toLowerCase();
        String phone = (item['mobile'] ?? '').toString().toLowerCase();
        String searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery);
      }).toList();
      _applyFilters();
    });
  }

  void _updateFilteredResults() {
    if (_query.isEmpty) {
      setState(() {
        _filteredTasks = List.from(upcomingTasks);
        _applyFilters();
      });
    } else {
      _performLocalSearch(_query);
    }
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.trim();
    if (newQuery == _query) return;

    _query = newQuery;
    _performLocalSearch(_query);
  }

  void _applyFilters() {
    List<dynamic> filteredList = List.from(_filteredTasks);

    // Calculate counts for each filter option
    _filterCounts.clear();

    // Count status options (keep existing logic)
    for (String status in _statusOptions) {
      if (status == 'All') {
        _filterCounts[status] = filteredList.length;
      } else {
        _filterCounts[status] = filteredList.where((item) {
          String itemStatus = (item['status'] ?? 'New').toString();
          return itemStatus.toLowerCase() == status.toLowerCase();
        }).length;
      }
    }

    // Count lead source categories
    for (String category in _leadSourceCategoryOptions) {
      if (category == 'All') {
        _filterCounts[category] = filteredList.length;
      } else if (category == 'Online Sources') {
        _filterCounts[category] = filteredList.where((item) {
          String leadSource = (item['lead_source'] ?? '').toString();
          return !_offlineSourcesList.contains(leadSource);
        }).length;
      } else if (category == 'Others') {
        // Count items where lead_source IS in the offline list
        _filterCounts[category] = filteredList.where((item) {
          String leadSource = (item['lead_source'] ?? '').toString();
          return _offlineSourcesList.contains(leadSource);
        }).length;
      }
    }

    // Apply actual filters
    if (_selectedStatus != 'All') {
      filteredList = filteredList.where((item) {
        String status = (item['status'] ?? 'New').toString();
        return status.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    // Apply lead source filter - SIMPLIFIED
    if (_selectedLeadSourceCategory != 'All') {
      if (_selectedLeadSourceCategory == 'Digitals') {
        // Show only items where lead_source is NOT in offline list
        filteredList = filteredList.where((item) {
          String leadSource = (item['lead_source'] ?? '').toString();
          return !_offlineSourcesList.contains(leadSource);
        }).toList();
      } else if (_selectedLeadSourceCategory == 'Others') {
        // Show only items where lead_source IS in offline list
        filteredList = filteredList.where((item) {
          String leadSource = (item['lead_source'] ?? '').toString();
          return _offlineSourcesList.contains(leadSource);
        }).toList();
      }
    }

    // Apply sorting (keep existing logic)
    switch (_selectedSortBy) {
      case 'Name (A-Z)':
        filteredList.sort((a, b) {
          String nameA = (a['lead_name'] ?? '').toString().toLowerCase();
          String nameB = (b['lead_name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
      case 'Name (Z-A)':
        filteredList.sort((a, b) {
          String nameA = (a['lead_name'] ?? '').toString().toLowerCase();
          String nameB = (b['lead_name'] ?? '').toString().toLowerCase();
          return nameB.compareTo(nameA);
        });
        break;
      case 'Recently Updated':
        filteredList.sort((a, b) {
          String dateA = a['updated_at'] ?? a['created_at'] ?? '';
          String dateB = b['updated_at'] ?? b['created_at'] ?? '';
          return dateB.compareTo(dateA);
        });
        break;
      case 'Oldest First':
        filteredList.sort((a, b) {
          String dateA = a['created_at'] ?? '';
          String dateB = b['created_at'] ?? '';
          return dateA.compareTo(dateB);
        });
        break;
      case 'Date Created':
      default:
        filteredList.sort((a, b) {
          String dateA = a['created_at'] ?? '';
          String dateB = b['created_at'] ?? '';
          return dateB.compareTo(dateA);
        });
        break;
    }

    // Update _hasActiveFilters
    _hasActiveFilters =
        _selectedSortBy != 'Date Created' ||
        _selectedStatus != 'All' ||
        _selectedLeadSourceCategory != 'All';

    setState(() {
      _filteredTasks = filteredList;
    });
  }

  void _onFilterChanged() {
    _updateFilteredResults();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSortBy = 'Date Created';
      _selectedStatus = 'All';
      _selectedLeadSourceCategory = 'All';
      _selectedLeadSource = 'All';
    });
    _onFilterChanged();
  }

  // PATCH 4/5: Build Filter Chips row
  Widget _buildFilterChips(bool isTablet) {
    if (!_hasActiveFilters) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(
        left: isTablet ? 15 : 10,
        right: isTablet ? 15 : 10,
        top: 5,
        bottom: 5,
      ),
      child: Row(
        children: [
          Text(
            '${(_selectedStatus != 'All' ? 1 : 0) + (_selectedTimeFilter != 'All Time' ? 1 : 0) + (_selectedSortBy != 'Date Created' ? 1 : 0)} filter(s) active',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 13 : 11,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Text(
              'Clear filter(s)',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 13 : 11,
                color: AppColors.sideRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
    required bool isTablet,
  }) {
    // Decide which value is considered "not selected"
    String defaultValue = label == 'Sort By'
        ? 'Date Created'
        : label == 'Status'
        ? 'All'
        : label == 'Lead Source'
        ? 'All'
        : options.first;

    bool isSelected = value != defaultValue;

    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.colorsBlue.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? AppColors.colorsBlue
                : Colors.grey.withOpacity(0.2),
            width: 2.0,
          ),
        ),
        height: isTablet ? 35 : 31,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 8,
          vertical: isTablet ? 3 : 2,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: isTablet ? 22 : 20,
              color: isSelected ? AppColors.colorsBlue : Colors.grey[500],
            ),
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 13 : 11,
              color: isSelected ? AppColors.colorsBlue : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(15),
            elevation: 8,
            menuMaxHeight: 250,
            selectedItemBuilder: (BuildContext context) {
              return options.map<Widget>((String item) {
                bool itemIsSelected = item == value && isSelected;
                return Row(
                  children: [
                    if (itemIsSelected)
                      Container(
                        width: isTablet ? 8 : 7,
                        height: isTablet ? 8 : 7,
                        margin: EdgeInsets.only(
                          right: isTablet ? 6 : 5,
                          left: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 15 : 13,
                          color: isSelected
                              ? AppColors.colorsBlue
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15 : 13,
                    color: option == value && isSelected
                        ? AppColors.colorsBlue
                        : Colors.grey.shade700,
                    fontWeight: option == value && isSelected
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            FontAwesomeIcons.angleLeft,
            color: Colors.white,
            size: _isSmallScreen(context) ? 18 : 20,
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'My Enquiries',
            style: GoogleFonts.poppins(
              fontSize: _titleFontSize(context),
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppColors.colorsBlue,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: CustomFloatingButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _createLeads,
              );
            },
          );
        },
      ),
      body: isLoading
          ? SkeletonGlobleSearchCard()
          : Column(
              children: [
                SpeechSearchWidget(
                  controller: _searchController,
                  hintText: "Search by name, email or phone",
                  onChanged: (value) => _onSearchChanged(),
                  primaryColor: AppColors.fontColor,
                  backgroundColor: Colors.grey.shade100,
                  borderRadius: 30.0,
                  prefixIcon: Icon(Icons.search, color: AppColors.fontColor),
                ),
                // Filters Row
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isTablet ? 15 : 10,
                    vertical: isTablet ? 10 : 5,
                  ),
                  child: Row(
                    children: [
                      _buildDropdownFilter(
                        label: 'Sort By',
                        value: _selectedSortBy,
                        options: _sortOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedSortBy = value!;
                          });
                          _onFilterChanged();
                        },
                        isTablet: isTablet,
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      _buildDropdownFilter(
                        label: 'Status',
                        value: _selectedStatus,
                        options: _statusOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                          _onFilterChanged();
                        },
                        isTablet: isTablet,
                      ),
                      SizedBox(width: isTablet ? 12 : 8),

                      // here i want to show them two option online sources and others onclick on the online will show onlineoption and others click show them leadsoruces and now timefile remove no need to use comment the logic
                      // _buildDropdownFilter(
                      //   label: 'Time',
                      //   value: _selectedTimeFilter,
                      //   options: _timeFilterOptions,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       _selectedTimeFilter = value!;
                      //     });
                      //     _onFilterChanged();
                      //   },
                      //   isTablet: isTablet,
                      // ),
                      _buildDropdownFilter(
                        label: 'Lead Source',
                        value:
                            _selectedLeadSourceCategory, // Simplified - just use the main category
                        options:
                            _leadSourceCategoryOptions, // Only show main categories
                        onChanged: (value) {
                          setState(() {
                            _selectedLeadSourceCategory = value!;
                          });
                          _onFilterChanged();
                        },
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),

                // PATCH 7: Filter Chips Row
                _buildFilterChips(isTablet),
                // PATCH 6: Filtered By indicator text
                // _buildFilterIndicatorText(isTablet),
                // Results count or query indicator (unchanged)
                _buildResultsCount(isTablet),
                // Results list - using filtered local results
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    trackVisibility: false,
                    thickness: 7.0,
                    radius: const Radius.circular(4.0),
                    interactive: true,
                    child: _buildTasksList(_filteredTasks),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResultsCount(bool isTablet) {
    String text;
    if (_query.isEmpty) {
      text = 'Showing ${_filteredTasks.length} lead(s)';
    } else {
      text = 'Found ${_filteredTasks.length} result(s) for "$_query"';
    }
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(left: isTablet ? 15 : 10, top: 4, bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: isTablet ? 13 : 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // --- Results List Widget ---
  Widget _buildTasksList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      final screenSize = MediaQuery.of(context).size;
      final isTablet = screenSize.width > 600;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.magnifyingGlass,
              size: isTablet ? 60 : 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: isTablet ? 20 : 15),
            Text(
              _query.isEmpty
                  ? 'No Leads available'
                  : 'No results found for "$_query"',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey[600],
              ),
            ),
            if (_query.isNotEmpty) ...[
              SizedBox(height: isTablet ? 10 : 8),
              Text(
                'Try searching with different keywords',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var item = tasks[index];

        if (!(item.containsKey('lead_id') && item.containsKey('lead_name'))) {
          return ListTile(title: Text('Invalid data at index $index'));
        }

        String leadId = item['lead_id'] ?? '';
        double swipeOffset = _swipeOffsets[leadId] ?? 0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(details, leadId),
          onHorizontalDragEnd: (details) =>
              _onHorizontalDragEnd(details, item, index),
          child: TaskItem(
            name: item['lead_name'] ?? '',
            date: item['created_at'] ?? '',
            subject: item['email'] ?? 'No subject',
            vehicle: item['PMI'] ?? 'Discovery Sport',
            leadId: leadId,
            taskId: leadId,
            brand: item['brand'] ?? '',
            number: item['mobile'] ?? '',
            isFavorite: item['favourite'] ?? false,
            leadSource: item['lead_source'],
            status: item['status'] ?? 'New',
            swipeOffset: swipeOffset,
            fetchDashboardData: () {},
            onFavoriteToggled: () async {
              _updateFilteredResults();
            },
            fetchTasksData: fetchTasksData,
            onTap: selectedLeads.isNotEmpty
                ? () => _toggleSelection(leadId)
                : null,
            onFavoriteChanged: (newStatus) {
              setState(() {
                int originalIndex = upcomingTasks.indexWhere(
                  (task) => task['lead_id'] == leadId,
                );
                if (originalIndex != -1) {
                  upcomingTasks[originalIndex]['favourite'] = newStatus;
                }
                _updateFilteredResults();
              });
            },
            onToggleFavorite: () {
              int originalIndex = upcomingTasks.indexWhere(
                (task) => task['lead_id'] == leadId,
              );
              if (originalIndex != -1) {
                _toggleFavorite(leadId, originalIndex);
              }
            },
          ),
        );
      },
    );
  }
}

class TaskItem extends StatefulWidget {
  final String name, subject, number, status, leadSource;
  final String date;
  final String vehicle;
  final String leadId;
  final String taskId;
  final String brand;
  final double swipeOffset;
  final bool isFavorite;
  final VoidCallback fetchDashboardData;
  final VoidCallback onFavoriteToggled;
  final Function(bool) onFavoriteChanged;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;
  final VoidCallback? fetchTasksData;

  const TaskItem({
    super.key,
    required this.name,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.taskId,
    required this.isFavorite,
    required this.onFavoriteToggled,
    required this.brand,
    required this.subject,
    required this.swipeOffset,
    required this.fetchDashboardData,
    required this.onFavoriteChanged,
    required this.onToggleFavorite,
    required this.number,
    required this.onTap,
    this.fetchTasksData,
    required this.status,
    required this.leadSource,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with SingleTickerProviderStateMixin {
  late SlidableController _slidableController;
  late bool isFav;

  void updateFavoriteStatus(bool newStatus) {
    setState(() {
      isFav = newStatus;
    });
  }

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
    _slidableController.animation.addListener(() {
      final isOpen = _slidableController.ratio != 0;
      if (_isActionPaneOpen != isOpen) {
        setState(() {
          _isActionPaneOpen = isOpen;
        });
      }
    });
    isFav = widget.isFavorite;
  }

  @override
  void dispose() {
    _slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 15 : 10,
        isTablet ? 8 : 5,
        isTablet ? 15 : 10,
        0,
      ),
      child: _buildFollowupCard(context),
    );
  }

  Color _getStatusBorderColor() {
    // Get the status from the widget (you might need to pass this as a parameter)
    // For now, I'll assume you add a status parameter to TaskItem widget
    String status = widget.status ?? 'New'; // Add this parameter to TaskItem

    switch (status.toLowerCase()) {
      case 'lost':
        return AppColors.sideRed;
      case 'qualified':
        return AppColors.sideGreen;
      case 'new':
        return AppColors.colorsBlue;
      case 'follow up':
        return AppColors.colorsBlue; // or any color you prefer
      default:
        return AppColors.colorsBlue;
    }
  }

  Widget _buildFollowupCard(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    bool isFavoriteSwipe = widget.swipeOffset > 50;
    bool isCallSwipe = widget.swipeOffset < -50;

    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            if (widget.leadId.isNotEmpty) {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowupsDetails(
                    leadId: widget.leadId,
                    spId: '',
                    isFromFreshlead: false,
                    isFromManager: false,
                    isFromTestdriveOverview: false,
                    refreshDashboard: () async {},
                  ),
                ),
              );
            } else {
              print("Invalid leadId");
            }
          },
      child: Slidable(
        key: ValueKey(widget.leadId),
        controller: _slidableController, // Add this line
        closeOnScroll: true,
        startActionPane: ActionPane(
          extentRatio: isTablet ? 0.15 : 0.2,
          motion: const ScrollMotion(),
          children: [
            ReusableSlidableAction(
              onPressed: () {
                widget.onToggleFavorite();
                _slidableController.close();
                setState(() {
                  _isActionPaneOpen = false;
                });
              },
              onDismissed: () {},
              backgroundColor: Colors.amber,
              icon: widget.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              foregroundColor: Colors.white,
              iconSize: isTablet ? 45 : 40,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: isTablet ? 0.15 : 0.2,
          children: [
            ReusableSlidableAction(
              onPressed: () {
                _mailAction();
                _slidableController.close();
                setState(() {
                  _isActionPaneOpen = false;
                });
              },
              backgroundColor: const Color.fromARGB(255, 231, 225, 225),
              icon: Icons.edit,
              foregroundColor: Colors.white,
              iconSize: isTablet ? 45 : 40,
              onDismissed: () {
                setState(() {
                  _isActionPaneOpen = false;
                });
              },
            ),
          ],
        ),
        child: Stack(
          children: [
            // Favorite Swipe Overlay
            if (isFavoriteSwipe)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow.withOpacity(0.2),
                        Colors.yellow.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: isTablet ? 20 : 15),
                        Icon(
                          isFav
                              ? Icons.star_outline_rounded
                              : Icons.star_rounded,
                          color: const Color.fromRGBO(226, 195, 34, 1),
                          size: isTablet ? 50 : 40,
                        ),
                        SizedBox(width: isTablet ? 15 : 10),
                        Text(
                          isFav ? 'Unfavorite' : 'Favorite',
                          style: GoogleFonts.poppins(
                            color: const Color.fromRGBO(187, 158, 0, 1),
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Call Swipe Overlay
            if (isCallSwipe)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.2),
                        Colors.green.withOpacity(0.8),
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: isTablet ? 15 : 10),
                        Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: isTablet ? 35 : 30,
                        ),
                        SizedBox(width: isTablet ? 15 : 10),
                        Text(
                          'Call',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main Container
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 15 : 10,
                vertical: isTablet ? 20 : 15,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(7),
                border: Border(
                  left: BorderSide(
                    width: isTablet ? 10.0 : 8.0,
                    color: isFav
                        // ? (isCallSwipe
                        //       ? AppColors.colorsBlue.withOpacity(0.9)
                        //       : Colors.yellow.withOpacity(
                        //           isFavoriteSwipe ? 0.1 : 0.9,
                        //         ))
                        // : (isFavoriteSwipe
                        //       ? Colors.yellow.withOpacity(0.1)
                        //       : (isCallSwipe
                        //             ? Colors.green.withOpacity(0.1)
                        //             : AppColors.colorsBlue)),
                        ? (isCallSwipe
                              ? AppColors.colorsBlue.withOpacity(0.9)
                              : Colors.yellow.withOpacity(
                                  isFavoriteSwipe ? 0.1 : 0.9,
                                ))
                        : (isFavoriteSwipe
                              ? Colors.yellow.withOpacity(0.1)
                              : (isCallSwipe
                                    ? Colors.green.withOpacity(0.1)
                                    : _getStatusBorderColor())), // Modified this line
                  ),
                ),
              ),
              child: Opacity(
                opacity: (isFavoriteSwipe || isCallSwipe) ? 0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(child: _buildUserDetails(context)),
                                    _buildVerticalDivider(isTablet ? 18 : 15),
                                    Flexible(
                                      child: _buildSubjectDetails(context),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isTablet ? 6 : 4),
                                Row(
                                  children: [
                                    Flexible(child: _buildCarModel(context)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildNavigationButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(TaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() {
        isFav = widget.isFavorite;
      });
    }
  }

  void _mailAction() {
    print("Mail action triggered");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: LeadUpdate(
            onFormSubmit: (leadId) {
              // Add parameter
              print('this is called with leadId: $leadId');
              if (widget.fetchTasksData != null) {
                widget.fetchTasksData!(); // Add () to actually call it
              }
            },
            leadId: widget.leadId,
            onEdit: widget.onFavoriteToggled,
          ),
        );
      },
    );
  }

  bool _isActionPaneOpen = false;
  Widget _buildNavigationButton(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return GestureDetector(
      onTap: () {
        if (_isActionPaneOpen) {
          // Close the action pane if it's open
          _slidableController.close();
          setState(() {
            _isActionPaneOpen = false;
          });
        } else {
          // Open the end action pane if it's closed
          _slidableController.openEndActionPane();
          setState(() {
            _isActionPaneOpen = true;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 4 : 3),
        decoration: BoxDecoration(
          color: AppColors.arrowContainerColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          _isActionPaneOpen
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_rounded,
          size: isTablet ? 28 : 25,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Text(
      widget.name,
      textAlign: TextAlign.start,
      style:
          AppFont.dashboardName(
            context,
          )?.copyWith(fontSize: isTablet ? 18 : null) ??
          GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubjectDetails(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    String mobile = widget.number;
    String hiddenMobile = _hideMobileNumber(mobile);

    return Text(
      mobile, // add hiddenmobile for hidden
      style:
          AppFont.smallText(
            context,
          )?.copyWith(fontSize: isTablet ? 14 : null) ??
          GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey[600],
          ),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _hideMobileNumber(String mobile) {
    if (mobile.length >= 10) {
      return mobile.substring(0, 3) + '*****' + mobile.substring(8);
    } else {
      return mobile;
    }
  }

  Widget _buildVerticalDivider(double height) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      margin: EdgeInsets.only(
        bottom: 3,
        left: isTablet ? 15 : 10,
        right: isTablet ? 15 : 10,
      ),
      height: height,
      width: 0.1,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.fontColor)),
      ),
    );
  }

  Widget _buildCarModel(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Text(
      widget.vehicle,
      textAlign: TextAlign.start,
      style:
          AppFont.dashboardCarName(
            context,
          )?.copyWith(fontSize: isTablet ? 16 : null) ??
          GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w400,
          ),
      softWrap: true,
      overflow: TextOverflow.ellipsis,
    );
  }
}
