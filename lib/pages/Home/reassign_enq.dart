import 'dart:async';
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
import 'package:smartassist/services/reassign_enq_srv.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/widgets/reusable/globle_speechtotext.dart';

class AllEnq extends StatefulWidget {
  const AllEnq({super.key});

  @override
  State<AllEnq> createState() => _AllEnqState();
}

class _AllEnqState extends State<AllEnq> {
  int _selectedButtonIndex = 0;
  bool isLoading = true;
  bool _isLoadingSearch = false;
  bool isSelectionMode = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _swipeOffsets = {};
  final TextEditingController _searchController = TextEditingController();
  Set<String> selectedLeads = {};
  List<dynamic> upcomingTasks = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _filteredTasks = [];
  String _query = '';
  Timer? _debounceTimer; // Added for proper debouncing

  // Filter variables
  String _selectedBrand = 'All';
  String _selectedAssignee = 'All';
  String _selectedTimeFrame = 'All';
  List<String> _availableBrands = ['All'];
  List<String> _availableAssignees = ['All'];
  final List<String> _timeFrameOptions = [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  void _onHorizontalDragUpdate(DragUpdateDetails details, String leadId) {
    if (!mounted) return;
    setState(() {
      _swipeOffsets[leadId] =
          (_swipeOffsets[leadId] ?? 0) + (details.primaryDelta ?? 0);
    });
  }

  // void _handleCall(dynamic item) {
  //   print("Call action triggered for ${item['name']}");
  //   // Implement actual call functionality here
  // }

  @override
  void initState() {
    super.initState();
    fetchTasksData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Cancel any pending timer
    _searchController.removeListener(_onSearchChanged); // Remove listener first
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper methods to get responsive dimensions
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Responsive padding
  EdgeInsets _responsivePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: _isTablet(context) ? 20 : (_isSmallScreen(context) ? 8 : 10),
    vertical: _isTablet(context) ? 12 : 8,
  );

  // Responsive font sizes
  double _titleFontSize(BuildContext context) =>
      _isTablet(context) ? 20 : (_isSmallScreen(context) ? 16 : 18);
  double _bodyFontSize(BuildContext context) =>
      _isTablet(context) ? 16 : (_isSmallScreen(context) ? 12 : 14);
  double _smallFontSize(BuildContext context) =>
      _isTablet(context) ? 14 : (_isSmallScreen(context) ? 10 : 12);

  Future<void> fetchTasksData() async {
    if (!mounted) return; // Check if widget is still mounted

    final token = await Storage.getToken();
    try {
      final response = await http.get(
        Uri.parse('https://api.smartassistapp.in/api/leads/my-teams/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return; // Check again before setState

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('this is the leadall $data');

        if (mounted) {
          // Always check before setState
          setState(() {
            upcomingTasks = data['data']['rows'] ?? [];
            _filteredTasks = List.from(upcomingTasks);
            isLoading = false;
          });
          _extractFilterOptions();
        }
      } else {
        print("Failed to load data: ${response.statusCode}");
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _extractFilterOptions() {
    if (!mounted) return;

    Set<String> brands = {};
    Set<String> assignees = {};

    print('Extracting filter options from ${upcomingTasks.length} tasks');

    for (var task in upcomingTasks) {
      if (task == null) continue; // Null safety check

      print('Task data: ${task.toString()}');

      // Extract brand information
      var brandValue = task['brand'];
      if (brandValue != null) {
        String brandString = brandValue.toString().trim();
        if (brandString.isNotEmpty && brandString.toLowerCase() != 'null') {
          brands.add(brandString);
          print('Added brand: $brandString');
        }
      }

      // Extract assignee information (lead_owner)
      var assigneeValue = task['lead_owner'];
      if (assigneeValue != null) {
        String assigneeString = assigneeValue.toString().trim();
        if (assigneeString.isNotEmpty &&
            assigneeString.toLowerCase() != 'null') {
          assignees.add(assigneeString);
          print('Added assignee: $assigneeString');
        }
      }
    }

    if (mounted) {
      setState(() {
        _availableBrands = ['All', ...brands.toList()..sort()];
        _availableAssignees = ['All', ...assignees.toList()..sort()];
      });
    }

    print('Final Available Brands: $_availableBrands');
    print('Final Available Assignees: $_availableAssignees');
  }

  bool _isDateInTimeFrame(String dateString, String timeFrame) {
    if (timeFrame == 'All') return true;

    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      switch (timeFrame) {
        case 'Today':
          DateTime itemDate = DateTime(date.year, date.month, date.day);
          return itemDate.isAtSameMomentAs(today);
        case 'This Week':
          DateTime startOfWeek = today.subtract(
            Duration(days: today.weekday - 1),
          );
          DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
          return date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              date.isBefore(endOfWeek.add(Duration(days: 1)));
        case 'This Month':
          return date.year == now.year && date.month == now.month;
        default:
          return true;
      }
    } catch (e) {
      print('Error parsing date: $dateString');
      return true;
    }
  }

  void _applyAllFilters() {
    if (!mounted) return;

    List<dynamic> filtered = List.from(upcomingTasks);

    // Apply search filter
    if (_query.isNotEmpty) {
      filtered = filtered.where((item) {
        if (item == null) return false; // Null safety
        String name = (item['lead_name'] ?? '').toString().toLowerCase();
        String email = (item['email'] ?? '').toString().toLowerCase();
        String phone = (item['mobile'] ?? '').toString().toLowerCase();
        String searchQuery = _query.toLowerCase();

        return name.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery);
      }).toList();
    }

    // Apply brand filter
    if (_selectedBrand != 'All') {
      filtered = filtered.where((item) {
        if (item == null) return false; // Null safety
        String itemBrand = (item['brand'] ?? '').toString().trim();
        bool match = itemBrand == _selectedBrand;
        print('Checking brand: $itemBrand == $_selectedBrand ? $match');
        return match;
      }).toList();
    }

    // Apply assignee filter
    if (_selectedAssignee != 'All') {
      filtered = filtered.where((item) {
        if (item == null) return false; // Null safety
        String itemAssignee = (item['lead_owner'] ?? '').toString().trim();
        bool match = itemAssignee == _selectedAssignee;
        print(
          'Checking assignee: $itemAssignee == $_selectedAssignee ? $match',
        );
        return match;
      }).toList();
    }

    // Apply time frame filter
    if (_selectedTimeFrame != 'All') {
      filtered = filtered.where((item) {
        if (item == null) return false; // Null safety
        String dateString = item['created_at'] ?? '';
        return _isDateInTimeFrame(dateString, _selectedTimeFrame);
      }).toList();
    }

    print('Filtered results count: ${filtered.length}');

    if (mounted) {
      setState(() {
        _filteredTasks = filtered;
      });
    }
  }

  void _performLocalSearch(String query) {
    _query = query;
    _applyAllFilters();
  }

  void _updateFilteredResults() {
    _applyAllFilters();
  }

  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingSearch = true;
      });
    }
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.trim();
    if (newQuery == _query) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Perform local search immediately for better UX
    _performLocalSearch(newQuery);

    // Set new timer for API search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (newQuery == _searchController.text.trim() && mounted) {
        _fetchSearchResults(newQuery);
      }
    });
  }

  void _toggleSelection(String leadId) {
    if (!mounted) return;

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

  void _clearSelection() {
    if (!mounted) return;

    HapticFeedback.lightImpact();

    setState(() {
      selectedLeads.clear();
      isSelectionMode = false;
    });
  }

  void _resetFilters() {
    if (!mounted) return;

    setState(() {
      _selectedBrand = 'All';
      _selectedAssignee = 'All';
      _selectedTimeFrame = 'All';
      _searchController.clear();
      _query = '';
    });
    _applyAllFilters();
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedBrand != 'All') count++;
    if (_selectedAssignee != 'All') count++;
    if (_selectedTimeFrame != 'All') count++;
    if (_query.isNotEmpty) count++;
    return count;
  }

  // Responsive helper methods
  double _getResponsiveFontSize(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 12;
    if (screenWidth < 400) return 13;
    if (isTablet) return 16;
    return 14;
  }

  double _getResponsiveHintFontSize(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 10;
    if (screenWidth < 400) return 11;
    if (isTablet) return 14;
    return 12;
  }

  double _getResponsiveIconSize(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 14;
    if (screenWidth < 400) return 15;
    if (isTablet) return 18;
    return 16;
  }

  double _getResponsiveHorizontalPadding(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 12;
    if (screenWidth < 400) return 14;
    if (isTablet) return 20;
    return 16;
  }

  double _getResponsiveVerticalPadding(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 10;
    if (screenWidth < 400) return 12;
    if (isTablet) return 16;
    return 14;
  }

  double _getResponsiveIconContainerWidth(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 40;
    if (screenWidth < 400) return 45;
    if (isTablet) return 55;
    return 50;
  }

  Widget _buildUserAvatar(Map<String, dynamic> user, String userName) {
    final profilePic = user['profile_pic']?.toString();

    if (profilePic != null && profilePic.isNotEmpty && profilePic != 'null') {
      return Image.network(
        profilePic,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.colorsBlue,
                  AppColors.colorsBlue.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialAvatar(userName);
        },
      );
    } else {
      return _buildInitialAvatar(userName);
    }
  }

  Widget _buildInitialAvatar(String userName) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.colorsBlue, AppColors.colorsBlue.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: selectedLeads.isNotEmpty
              ? IconButton(
                  key: const ValueKey('clear'),
                  onPressed: _clearSelection,
                  icon: const Icon(FontAwesomeIcons.xmark, color: Colors.white),
                )
              : IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    FontAwesomeIcons.angleLeft,
                    color: Colors.white,
                    size: _isSmallScreen(context) ? 18 : 20,
                  ),
                ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            selectedLeads.isNotEmpty
                ? "${selectedLeads.length} selected"
                : "Team's Enquiries",
            key: ValueKey(selectedLeads.isNotEmpty),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppColors.colorsBlue,
        automaticallyImplyLeading: false,
        actions: selectedLeads.isNotEmpty
            ? [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: selectedLeads.isNotEmpty ? 1.0 : 0.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double screenWidth = MediaQuery.of(context).size.width;
                      double fontSize = screenWidth < 360
                          ? 12
                          : (screenWidth < 600 ? 14 : 16);
                      EdgeInsets padding = screenWidth < 360
                          ? const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            )
                          : screenWidth < 600
                          ? const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            )
                          : const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            );

                      return TextButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          print("Selected leads: $selectedLeads");

                          if (selectedLeads.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select leads to reassign',
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          // Show user selection dialog
                          final selectedUser = await showDialog<Map<String, dynamic>>(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                constraints: const BoxConstraints(
                                  maxHeight: 700,
                                  maxWidth: 400,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header with gradient background
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.colorsBlue,
                                            const Color(
                                              0xFF1380FE,
                                            ).withOpacity(0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.person_search_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Select a PS to reassign',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Content area
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        child: FutureBuilder<List<Map<String, dynamic>>>(
                                          future: LeadsSrv.fetchUsers(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                height: 200,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 3,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              const Color(
                                                                0xFF1380FE,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Loading users...',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            if (snapshot.hasError) {
                                              return Container(
                                                height: 200,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .error_outline_rounded,
                                                        color: Colors.red[400],
                                                        size: 48,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Error loading users',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${snapshot.error}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            final users = snapshot.data ?? [];

                                            if (users.isEmpty) {
                                              return Container(
                                                height: 200,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[100],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .people_outline_rounded,
                                                        color: Colors.grey[400],
                                                        size: 48,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'No users available',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: users.length,
                                              separatorBuilder:
                                                  (context, index) => Divider(
                                                    height: 1,
                                                    color: Colors.grey[200],
                                                  ),
                                              itemBuilder: (context, index) {
                                                final user = users[index];
                                                final userName =
                                                    user['name'] ??
                                                    'Unknown User';

                                                return Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () async {
                                                      final userId =
                                                          user['user_id']
                                                              ?.toString();

                                                      if (userId != null &&
                                                          userId.isNotEmpty &&
                                                          userId != 'null') {
                                                        if (context.mounted) {
                                                          Navigator.of(
                                                            context,
                                                          ).pop({
                                                            'id': userId,
                                                            'name': userName,
                                                          });
                                                        }
                                                      } else {
                                                        if (context.mounted) {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        }

                                                        await Future.delayed(
                                                          const Duration(
                                                            milliseconds: 100,
                                                          ),
                                                        );

                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: const Text(
                                                                'Unable to get user ID',
                                                              ),
                                                              backgroundColor:
                                                                  Colors
                                                                      .red[400],
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 16,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 48,
                                                            height: 48,
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    24,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    const Color(
                                                                      0xFF1380FE,
                                                                    ).withOpacity(
                                                                      0.2,
                                                                    ),
                                                                width: 2,
                                                              ),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    22,
                                                                  ),
                                                              child:
                                                                  _buildUserAvatar(
                                                                    user,
                                                                    userName,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 16,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  userName,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .grey[800],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .arrow_forward_ios_rounded,
                                                            size: 16,
                                                            color: Colors
                                                                .grey[400],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                    // Footer with action buttons
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          // If no user was selected, return early
                          if (selectedUser == null) {
                            return;
                          }

                          final selectedUserId = selectedUser['id']!;
                          final selectedUserName = selectedUser['name']!;

                          // Show loading indicator
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          try {
                            final result = await ApiService.reassignLeads(
                              leadIds: selectedLeads,
                              assignee: selectedUserId,
                            );

                            // Hide loading indicator
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            if (result['success']) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reassigned to $selectedUserName',
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
                              }

                              // Clear selection
                              if (mounted) {
                                setState(() {
                                  selectedLeads.clear();
                                });
                              }

                              // Refresh the leads data
                              await fetchTasksData();
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['error'] ??
                                          'Unknown error occurred',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Hide loading indicator
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }

                            print("Error reassigning leads: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Unexpected error: $e')),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: padding,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Reassign to",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Responsive Search field container
                // Container(
                //   margin: EdgeInsets.all(isTablet ? 15 : 10),
                //   child: ConstrainedBox(
                //     constraints: const BoxConstraints(
                //       minHeight: 38,
                //       maxHeight: 38,
                //     ),
                //     child: TextField(
                //       autofocus: false,
                //       controller: _searchController,
                //       onChanged: (value) => _onSearchChanged(),
                //       textAlignVertical: TextAlignVertical.center,
                //       style: GoogleFonts.poppins(
                //         fontSize: _getResponsiveFontSize(context, isTablet),
                //       ),
                //       decoration: InputDecoration(
                //         enabledBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(30),
                //           borderSide: BorderSide.none,
                //         ),
                //         focusedBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(30),
                //           borderSide: BorderSide.none,
                //         ),
                //         contentPadding: EdgeInsets.symmetric(
                //           horizontal: _getResponsiveHorizontalPadding(
                //             context,
                //             isTablet,
                //           ),
                //           vertical: _getResponsiveVerticalPadding(
                //             context,
                //             isTablet,
                //           ),
                //         ),
                //         filled: true,
                //         fillColor: AppColors.backgroundLightGrey,
                //         hintText: 'Search by name, email or phone',
                //         hintStyle: GoogleFonts.poppins(
                //           fontSize: _getResponsiveHintFontSize(
                //             context,
                //             isTablet,
                //           ),
                //           fontWeight: FontWeight.w300,
                //         ),
                //         prefixIcon: Container(
                //           width: _getResponsiveIconContainerWidth(
                //             context,
                //             isTablet,
                //           ),
                //           child: Center(
                //             child: Icon(
                //               FontAwesomeIcons.magnifyingGlass,
                //               color: AppColors.fontColor,
                //               size: _getResponsiveIconSize(context, isTablet),
                //             ),
                //           ),
                //         ),
                //         prefixIconConstraints: BoxConstraints(
                //           minWidth: _getResponsiveIconContainerWidth(
                //             context,
                //             isTablet,
                //           ),
                //           maxWidth: _getResponsiveIconContainerWidth(
                //             context,
                //             isTablet,
                //           ),
                //         ),
                //         border: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(30),
                //           borderSide: BorderSide.none,
                //         ),
                //         isDense: true,
                //       ),
                //     ),
                //   ),
                // ),
                SpeechSearchWidget(
                  controller: _searchController,
                  hintText: "Search by name, email or phone",
                  onChanged: (value) => _onSearchChanged(),
                  primaryColor: AppColors.fontColor,
                  backgroundColor: Colors.grey.shade100,
                  borderRadius: 30.0,
                  prefixIcon: Icon(Icons.search, color: AppColors.fontColor),
                ),
                // Filter Section
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isTablet ? 15 : 10,
                    vertical: isTablet ? 8 : 5,
                  ),
                  child: Column(
                    children: [
                      // Filter Buttons Row
                      Row(
                        children: [
                          // Brand Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              'Brand',
                              _selectedBrand,
                              _availableBrands,
                              (value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedBrand = value!;
                                  });
                                  _applyAllFilters();
                                }
                              },
                              isTablet,
                            ),
                          ),
                          SizedBox(width: isTablet ? 10 : 8),

                          // Assignee Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              'Owner',
                              _selectedAssignee,
                              _availableAssignees,
                              (value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedAssignee = value!;
                                  });
                                  _applyAllFilters();
                                }
                              },
                              isTablet,
                            ),
                          ),
                          SizedBox(width: isTablet ? 10 : 8),

                          // Time Frame Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              'Time',
                              _selectedTimeFrame,
                              _timeFrameOptions,
                              (value) {
                                if (mounted) {
                                  setState(() {
                                    _selectedTimeFrame = value!;
                                  });
                                  _applyAllFilters();
                                }
                              },
                              isTablet,
                            ),
                          ),
                        ],
                      ),

                      // Clear Filters Button (only show if filters are active)
                      if (_getActiveFilterCount() > 0)
                        Padding(
                          padding: EdgeInsets.only(top: isTablet ? 8 : 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_getActiveFilterCount()} filter(s) active',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 12 : 10,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextButton(
                                onPressed: _resetFilters,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 12 : 8,
                                    vertical: isTablet ? 4 : 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear All',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 14 : 12,
                                    color: AppColors.sideRed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Search query indicator
                if (_query.isNotEmpty || _getActiveFilterCount() > 0)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isTablet ? 15 : 10,
                      bottom: isTablet ? 8 : 5,
                      right: isTablet ? 15 : 10,
                    ),
                    child: const Align(alignment: Alignment.centerLeft),
                  ),

                // Results list - FIXED: Removed duplicate _buildTasksList call
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    trackVisibility: false,
                    thickness: 8.0,
                    radius: const Radius.circular(4.0),
                    interactive: true,
                    child: _buildTasksList(_filteredTasks),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
    bool isTablet,
  ) {
    print('Building dropdown for $label with options: $options');

    return Container(
      height: isTablet ? 40 : 36,
      decoration: BoxDecoration(
        color: selectedValue != 'All'
            ? AppColors.colorsBlue.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: selectedValue != 'All'
              ? AppColors.colorsBlue.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedValue != 'All'
                ? AppColors.colorsBlue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: Container(
            margin: EdgeInsets.only(right: isTablet ? 8 : 6),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: isTablet ? 22 : 20,
              color: selectedValue != 'All'
                  ? AppColors.colorsBlue
                  : Colors.grey[500],
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 13 : 11,
            color: selectedValue != 'All'
                ? AppColors.colorsBlue
                : Colors.grey[700],
            fontWeight: selectedValue != 'All'
                ? FontWeight.w600
                : FontWeight.w400,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
          elevation: 8,
          menuMaxHeight: 250,
          items: options.map<DropdownMenuItem<String>>((String value) {
            bool isSelected = value == selectedValue;
            bool isAllOption = value == 'All';

            return DropdownMenuItem<String>(
              value: value,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 10,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.colorsBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isSelected && !isAllOption)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.check_circle,
                          size: isTablet ? 16 : 14,
                          color: AppColors.colorsBlue,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        isAllOption ? label : value,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 13 : 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.colorsBlue
                              : (isAllOption
                                    ? Colors.grey[600]
                                    : Colors.grey[800]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return options.map<Widget>((String value) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 10,
                  vertical: 0,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    if (selectedValue != 'All')
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: isTablet ? 6 : 5,
                        height: isTablet ? 6 : 5,
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        value == 'All' ? label : value,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 13 : 11,
                          fontWeight: selectedValue != 'All'
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selectedValue != 'All'
                              ? AppColors.colorsBlue
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTasksList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      final screenSize = MediaQuery.of(context).size;
      final isTablet = screenSize.width > 600;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getActiveFilterCount() > 0
                  ? FontAwesomeIcons.filter
                  : FontAwesomeIcons.magnifyingGlass,
              size: isTablet ? 60 : 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: isTablet ? 20 : 15),
            Text(
              _getActiveFilterCount() > 0
                  ? 'No results found with current filters'
                  : (_query.isEmpty
                        ? 'No Enquiries available'
                        : 'No results found for "$_query"'),
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_getActiveFilterCount() > 0) ...[
              SizedBox(height: isTablet ? 10 : 8),
              Text(
                'Try adjusting your filters or search terms',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 15 : 10),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Clear All Filters',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 14 : 12,
                    color: AppColors.sideRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else if (_query.isNotEmpty) ...[
              SizedBox(height: isTablet ? 10 : 8),
              Text(
                'Try searching with different keywords',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey[500],
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
        // Safety check for index bounds
        if (index >= tasks.length) return const SizedBox.shrink();

        var item = tasks[index];

        // Enhanced null safety checks
        if (item == null ||
            !item.containsKey('lead_id') ||
            !item.containsKey('lead_name') ||
            item['lead_id'] == null ||
            item['lead_name'] == null) {
          return const SizedBox.shrink(); // Return empty widget instead of error
        }

        String leadId = item['lead_id']?.toString() ?? '';
        if (leadId.isEmpty) {
          return const SizedBox.shrink();
        }

        double swipeOffset = _swipeOffsets[leadId] ?? 0;
        bool isSelected = selectedLeads.contains(leadId);

        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(details, leadId),
          child: TaskItem(
            name: item['lead_name']?.toString() ?? '',
            date: item['created_at']?.toString() ?? '',
            subject: item['email']?.toString() ?? 'No subject',
            vehicle: item['PMI']?.toString() ?? 'Discovery Sport',
            spId: item['sp_id']?.toString() ?? 'no id',
            leadId: leadId,
            taskId: leadId,
            brand: item['brand']?.toString() ?? '',
            assignee: item['lead_owner']?.toString() ?? '',
            number: item['mobile']?.toString() ?? '',
            isFavorite: item['favourite'] ?? false,
            swipeOffset: swipeOffset,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            fetchDashboardData: () {},
            onLongPress: () => _toggleSelection(leadId),
            onTap: selectedLeads.isNotEmpty
                ? () => _toggleSelection(leadId)
                : null,
          ),
        );
      },
    );
  }
}

// TaskItem class with proper disposal
class TaskItem extends StatefulWidget {
  final String name, subject, number, spId;
  final String date;
  final String vehicle;
  final String leadId;
  final String taskId;
  final String brand;
  final String assignee;
  final double swipeOffset;
  final bool isFavorite;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback fetchDashboardData;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;

  const TaskItem({
    super.key,
    required this.name,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.taskId,
    required this.isFavorite,
    required this.isSelected,
    required this.isSelectionMode,
    required this.brand,
    required this.assignee,
    required this.subject,
    required this.swipeOffset,
    required this.fetchDashboardData,
    required this.number,
    required this.onLongPress,
    this.onTap,
    required this.spId,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with SingleTickerProviderStateMixin {
  late bool isFav;
  late SlidableController _slidableController;
  bool _isActionPaneOpen = false;
  void updateFavoriteStatus(bool newStatus) {
    if (mounted) {
      setState(() {
        isFav = newStatus;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    isFav = widget.isFavorite;
    _slidableController = SlidableController(this);
    _slidableController.animation.addListener(() {
      final isOpen = _slidableController.ratio != 0;
      if (_isActionPaneOpen != isOpen) {
        setState(() {
          _isActionPaneOpen = isOpen;
        });
      }
    });
    print('this is all enq spid ${widget.spId}');
  }

  @override
  void dispose() {
    _slidableController.dispose(); // Proper controller disposal
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

  Widget _buildFollowupCard(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    bool isCallSwipe = widget.swipeOffset < -50;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onLongPress();
      },
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
                    spId: widget.spId,
                    isFromFreshlead: false,
                    isFromManager: true,
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
        controller: _slidableController,
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: isTablet ? 0.15 : 0.2,
          children: [
            ReusableSlidableAction(
              onPressed: () {
                HapticFeedback.heavyImpact();
                widget.onLongPress();
              },
              onDismissed: () {},
              backgroundColor: const Color.fromARGB(255, 231, 225, 225),
              icon: Icons.check_circle_outline_rounded,
              foregroundColor: Colors.white,
              iconSize: isTablet ? 45 : 40,
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 30),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 15 : 10,
                vertical: isTablet ? 20 : 15,
              ),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.backgroundLightGrey.withOpacity(0.8)
                    : AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(7),
                border: Border(
                  left: BorderSide(
                    width: isTablet ? 10.0 : 8.0,
                    color: widget.isSelected
                        ? AppColors.sideGreen.withOpacity(0.8)
                        : AppColors.colorsBlue.withOpacity(0.6),
                  ),
                  bottom: widget.isSelected
                      ? BorderSide(
                          width: 1,
                          color: AppColors.sideGreen.withOpacity(0.8),
                        )
                      : BorderSide.none,
                ),
              ),
              child: Opacity(
                opacity: (isCallSwipe) ? 0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated check icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: widget.isSelected ? 36 : 0,
                      margin: EdgeInsets.only(
                        right: widget.isSelected ? 12 : 0,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: widget.isSelected ? 1.0 : 0.0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: widget.isSelected ? 1.0 : 0.8,
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

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
                                    _buildVerticalDivider(15),
                                    Text(
                                      "By- ",
                                      style: AppFont.dashboardCarName(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Flexible(child: _buildAssignee(context)),
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
      hiddenMobile,
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

  Widget _buildNavigationButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isActionPaneOpen) {
          _slidableController.close();
          if (mounted) {
            setState(() {
              _isActionPaneOpen = false;
            });
          }
        } else {
          _slidableController.close();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _slidableController.openEndActionPane();
              setState(() {
                _isActionPaneOpen = true;
              });
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.arrowContainerColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          _isActionPaneOpen
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_rounded,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
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

  Widget _buildAssignee(BuildContext context) {
    return Text(
      widget.assignee,
      textAlign: TextAlign.start,
      style: AppFont.assigneeName(context),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// FlexibleButton class
class FlexibleButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final BoxDecoration decoration;
  final TextStyle textStyle;

  const FlexibleButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.decoration,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      height: 30,
      decoration: decoration,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xffF3F9FF),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: textStyle, textAlign: TextAlign.center),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

// ReusableSlidableAction class
class ReusableSlidableAction extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData icon;
  final Color? foregroundColor;
  final double iconSize;

  const ReusableSlidableAction({
    Key? key,
    required this.onPressed,
    required this.backgroundColor,
    required this.icon,
    this.foregroundColor,
    this.iconSize = 40.0,
    required Null Function() onDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) => onPressed(),
      backgroundColor: backgroundColor,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: iconSize, color: foregroundColor ?? Colors.white),
    );
  }
}
