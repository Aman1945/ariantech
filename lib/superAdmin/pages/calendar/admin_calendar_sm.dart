import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/getX/fab.controller.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/calender/calender.dart';
import 'package:smartassist/widgets/reusable/skeleton_calendar_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AdminCalendarSm extends StatefulWidget {
  final String leadName;
  const AdminCalendarSm({super.key, required this.leadName});
  @override
  State<AdminCalendarSm> createState() => _AdminCalendarSmState();
}

class _AdminCalendarSmState extends State<AdminCalendarSm> {
  Map<String, dynamic> _teamData = {};
  List<Map<String, dynamic>> _teamMembers = [];
  int _selectedProfileIndex = 0;
  String _selectedUserId = '';
  String _selectedType = 'your';

  // Selection state without ticking
  Set<String> _selectedLetters = {};
  bool _isMultiSelectMode = false;
  Set<String> selectedUserIds = {};

  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isMonthView = false;
  List<dynamic> tasks = [];
  List<dynamic> events = [];
  DateTime? _selectedDay;
  bool _isLoading = false;
  ScrollController _timelineScrollController = ScrollController();

  Set<int> _activeHours = {};
  Map<String, List<dynamic>> _timeSlotItems = {};
  Map<String, bool> _expandedSlots = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
      _fetchTeamDetails();
      _fetchActivitiesData();
    });
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    if (!_timelineScrollController.hasClients) return;
    final currentHour = DateTime.now().hour;
    double scrollPosition = currentHour * 80.0;
    scrollPosition = scrollPosition > 60 ? scrollPosition - 60 : 0;
    _timelineScrollController.animateTo(
      scrollPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Color _getConsistentColor(String seed) {
    int hash = seed.hashCode;
    final math.Random random = math.Random(hash);
    int red = 80 + random.nextInt(150);
    int green = 80 + random.nextInt(150);
    int blue = 80 + random.nextInt(150);
    return Color.fromARGB(255, red, green, blue);
  }

  void _clearAllSelections() {
    setState(() {
      selectedUserIds.clear();
      _selectedLetters.clear();
      _selectedProfileIndex = 0;
      _selectedUserId = '';
      _selectedType = 'your';
      _isMultiSelectMode = false;
    });
  }

  void _clearUsersFromLetter(String letter) {
    List<String> usersToRemove = [];
    for (String userId in selectedUserIds) {
      var member = _teamMembers.firstWhere(
        (m) => m['user_id'] == userId,
        orElse: () => {},
      );
      if (member.isNotEmpty) {
        String firstName = (member['fname'] ?? '').toString().toUpperCase();
        if (firstName.startsWith(letter)) {
          usersToRemove.add(userId);
        }
      }
    }
    for (String userId in usersToRemove) {
      selectedUserIds.remove(userId);
    }
  }

  Future<void> _fetchTeamDetails() async {
    try {
      final token = await Storage.getToken();

      final userId = await AdminUserIdManager.getAdminUserId();
      final baseUri = Uri.parse(
        'https://api.smartassistapp.in/api/app-admin/SM/dashboard?userId=$userId',
      );
      final response = await http.get(
        baseUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('this is the url smsssss $baseUri');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _teamData = data['data'] ?? {};
          if (_teamData.containsKey('allMember') &&
              _teamData['allMember'].isNotEmpty) {
            _teamMembers = [];
            for (var member in _teamData['allMember']) {
              _teamMembers.add({
                'fname': member['fname'] ?? '',
                'lname': member['lname'] ?? '',
                'user_id': member['user_id'] ?? '',
                'profile': member['profile'],
                'initials': member['initials'] ?? '',
              });
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching team details: $e');
    }
  }

  Future<void> _fetchActivitiesData() async {
    if (_selectedType == 'team' && _selectedUserId.isEmpty) {
      setState(() {
        tasks = [];
        events = [];
        _isLoading = false;
      });
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final token = await Storage.getToken();
      final adminId = await AdminUserIdManager.getAdminUserId();

      String formattedDate = DateFormat(
        'dd-MM-yyyy',
      ).format(_selectedDay ?? _focusedDay);

      final Map<String, String> queryParams = {
        'userId': adminId ?? '',
        'date': formattedDate,
      };

      if (_selectedType == 'team' && _selectedUserId.isNotEmpty) {
        queryParams['user_id'] = _selectedUserId;
      }

      final uri = Uri.https(
        "api.smartassistapp.in",
        "/api/app-admin/calendar/activities",
        queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // final adminId = await AdminUserIdManager.getAdminUserId();
      // String formattedDate = DateFormat(
      //   'dd-MM-yyyy',
      // ).format(_selectedDay ?? _focusedDay);

      // final Map<String, String> queryParams = {'date': formattedDate};
      // if (_selectedType == 'team' && _selectedUserId.isNotEmpty) {
      //   queryParams['user_id'] = _selectedUserId;
      // }
      // final baseUrl = Uri.parse(
      //   "https://api.smartassistapp.in/api/app-admin/calendar/activities?userId=$adminId",
      // );
      // final uri = baseUrl.replace(queryParameters: queryParams);
      // final response = await http.get(
      //   uri,
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );

      print('this is calenderrrrrr url $uri');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          tasks = data['data']['tasks'] ?? [];
          events = data['data']['events'] ?? [];
          _isLoading = false;
        });
        _processTimeSlots();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching activities data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processTimeSlots() {
    _activeHours.clear();
    _timeSlotItems.clear();
    for (var item in [...events, ...tasks]) {
      String? timeRaw = item['start_time'] ?? item['time'] ?? item['due_date'];
      if (timeRaw == null || timeRaw.toString().isEmpty) timeRaw = "09:00";
      final itemTime = _parseTimeString(timeRaw);
      final hour = itemTime.hour;
      _activeHours.add(hour);
      final timeKey = '${hour.toString().padLeft(2, '0')}:00';
      if (!_timeSlotItems.containsKey(timeKey)) _timeSlotItems[timeKey] = [];
      _timeSlotItems[timeKey]!.add(item);
    }
    if (_activeHours.isEmpty) {
      if (_isSameDay(_selectedDay ?? _focusedDay, DateTime.now())) {
        _activeHours.add(DateTime.now().hour);
      } else {
        _activeHours.add(9);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _handleDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDay = selectedDate;
      _focusedDay = selectedDate;
      tasks = [];
      events = [];
      _activeHours.clear();
      _timeSlotItems.clear();
      _isLoading = true;
      _expandedSlots.clear();
    });
    _fetchActivitiesData();
  }

  void _handleTeamYourSelection(String type) async {
    setState(() {
      _selectedType = type;
      if (type == 'your') {
        _clearAllSelections();
      } else if (type == 'team') {
        _selectedUserId = '';
        _selectedProfileIndex = 0;
        _selectedLetters.clear();
      }
      _isLoading = true;
      _expandedSlots.clear();
    });
    await _fetchActivitiesData();
  }

  Future<void> _handleTeamMemberSelection(int index, String userId) async {
    // Check if the same user is being selected again - if so, refresh
    if (_selectedUserId == userId) {
      setState(() {
        _isLoading = true;
        _expandedSlots.clear();
      });
      await _fetchActivitiesData();
      return;
    }

    setState(() {
      _selectedProfileIndex = index;
      _selectedUserId = userId;
      _selectedType = 'team';
      _isLoading = true;
      _expandedSlots.clear();
    });
    await _fetchActivitiesData();
  }

  final FabController fabController = Get.put(FabController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // appBar: AppBar(
      //   backgroundColor: AppColors.colorsBlue,
      //   automaticallyImplyLeading: false,
      //   title: Align(
      //     alignment: Alignment.centerLeft,
      //     child: Text(
      //       'Calendar',
      //       style: GoogleFonts.poppins(
      //         fontSize: 18,
      //         fontWeight: FontWeight.w500,
      //         color: Colors.white,
      //       ),
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       onPressed: () {
      //         setState(() {
      //           _calendarFormat = _isMonthView
      //               ? CalendarFormat.week
      //               : CalendarFormat.month;
      //           _isMonthView = !_isMonthView;
      //         });
      //       },
      //       icon: _isMonthView
      //           ? Image.asset(
      //               'assets/week.png',
      //               width: 24,
      //               height: 24,
      //               color: Colors.white,
      //             )
      //           : Image.asset(
      //               'assets/calendar.png',
      //               width: 24,
      //               height: 24,
      //               color: Colors.white,
      //             ),
      //     ),
      //   ],
      // ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.colorsBlue,
        title: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () async {
              setState(() {
                _isLoading = true;
              });
              await AdminUserIdManager.clearAll();
              if (!mounted) return;
              Get.offAll(() => AdminDealerall());
            },
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),

                SizedBox(width: 10),
                Text(
                  AdminUserIdManager.adminNameSync ?? "No Name",
                  style: AppFont.dropDowmLabelWhite(context),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTeamYourButtons(),
            if (_selectedType == 'team') _buildProfileAvatars(),
            CalenderWidget(
              key: ValueKey(_calendarFormat),
              calendarFormat: _calendarFormat,
              onDateSelected: _handleDateSelected,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: Text(
                DateFormat('EEEE, MMMM d').format(_selectedDay ?? _focusedDay),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildTimelineView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamYourButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 35,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(239, 239, 239, 1),
            border: Border.all(
              color: const Color.fromRGBO(239, 239, 239, 1),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: _selectedType == 'team'
                      ? Colors.white
                      : const Color.fromRGBO(239, 239, 239, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: Colors.transparent,
                  ),
                  onPressed: () => _handleTeamYourSelection('team'),
                  child: Text(
                    "Team's",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.fontColor,
                    ),
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: _selectedType == 'your'
                      ? Colors.white
                      : const Color.fromRGBO(239, 239, 239, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: Colors.transparent,
                  ),
                  onPressed: () => _handleTeamYourSelection('your'),
                  child: Text(
                    'Your',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.fontColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Profile avatars with selection logic but without ticking
  Widget _buildProfileAvatars() {
    List<Map<String, dynamic>> sortedTeamMembers = List.from(_teamMembers);
    sortedTeamMembers.sort(
      (a, b) => (a['fname'] ?? '').toString().toLowerCase().compareTo(
        (b['fname'] ?? '').toString().toLowerCase(),
      ),
    );

    // Get unique letters
    Set<String> uniqueLetters = {};
    for (var member in sortedTeamMembers) {
      String firstLetter = (member['fname'] ?? '').toString().toUpperCase();
      if (firstLetter.isNotEmpty) {
        uniqueLetters.add(firstLetter[0]);
      }
    }

    List<String> sortedLetters = uniqueLetters.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 90,
        padding: const EdgeInsets.only(top: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Build letters with their members inline
            ...sortedLetters.expand(
              (letter) => _buildLetterWithMembers(letter),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLetterWithMembers(String letter) {
    List<Widget> widgets = [];
    bool isSelected = _selectedLetters.contains(letter);

    // Add the letter avatar
    widgets.add(_buildAlphabetAvatar(letter));

    // If letter is selected, add its members right after
    if (isSelected) {
      List<Map<String, dynamic>> letterMembers = _teamMembers.where((member) {
        String firstName = (member['fname'] ?? '').toString().toUpperCase();
        return firstName.startsWith(letter);
      }).toList();

      // Sort members alphabetically
      letterMembers.sort(
        (a, b) => (a['fname'] ?? '').toString().toLowerCase().compareTo(
          (b['fname'] ?? '').toString().toLowerCase(),
        ),
      );

      // Add member avatars
      for (int i = 0; i < letterMembers.length; i++) {
        widgets.add(
          _buildProfileAvatar(
            letterMembers[i]['fname'] ?? '',
            i + 1,
            letterMembers[i]['user_id'] ?? '',
            letterMembers[i]['profile'],
            letterMembers[i]['initials'] ?? '',
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildAlphabetAvatar(String letter) {
    bool isSelected = _selectedLetters.contains(letter);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();

            setState(() {
              if (_isMultiSelectMode) {
                if (isSelected) {
                  _selectedLetters.remove(letter);
                  _clearUsersFromLetter(letter);
                  if (_selectedLetters.isEmpty) {
                    _isMultiSelectMode = false;
                    // Keep on team view, don't switch to 'your'
                    _selectedProfileIndex = 0;
                  }
                } else {
                  _selectedLetters.add(letter);
                  _selectedType = 'team';
                }
              } else {
                if (isSelected) {
                  _selectedLetters.remove(letter);
                  // Don't switch to 'your' when deselecting, stay on team
                  if (_selectedLetters.isEmpty) {
                    _selectedProfileIndex = 0;
                  }
                } else {
                  _selectedLetters.add(letter);
                  _selectedType = 'team';
                }
              }
              _selectedProfileIndex = -1;
              _selectedUserId = '';
            });
            _fetchActivitiesData();
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.colorsBlue
                      : AppColors.backgroundLightGrey,
                  border: isSelected
                      ? Border.all(color: AppColors.colorsBlue, width: 2.5)
                      : Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 22 : 20,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    child: Text(letter),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Match the spacing with profile avatars
        const SizedBox(
          height: 28,
        ), // Increased to match profile avatar total height
      ],
    );
  }

  // Profile avatar with selection but no ticking overlay
  Widget _buildProfileAvatar(
    String firstName,
    int index,
    String userId,
    String? profileUrl,
    String initials,
  ) {
    bool isSelectedForComparison = selectedUserIds.contains(userId);
    bool isCurrentlySelected =
        _selectedProfileIndex == index && _selectedUserId == userId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();

            // Call the updated handler that includes refresh logic
            await _handleTeamMemberSelection(index, userId);
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 5, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: _getBorderStyle(
                  isSelectedForComparison,
                  isCurrentlySelected,
                ),
              ),
              child: ClipOval(
                child: _buildProfileContent(profileUrl, initials, firstName),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 70),
          child: Text(
            _getDisplayText(
              firstName,
              isSelectedForComparison,
              isCurrentlySelected,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: (isSelectedForComparison || isCurrentlySelected)
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: _getNameTextColor(
                isSelectedForComparison,
                isCurrentlySelected,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // Helper method to determine what text to display under avatar
  String _getDisplayText(
    String firstName,
    bool isSelectedForComparison,
    bool isCurrentlySelected,
  ) {
    // Always show the person's name, regardless of selection state
    return firstName;
  }

  // Helper methods for visual selection indicators - UPDATED: removed blue highlight
  Color _getNameTextColor(
    bool isSelectedForComparison,
    bool isCurrentlySelected,
  ) {
    if (isCurrentlySelected) {
      return AppColors.fontColor; // Selected avatar name in normal color
    } else if (_selectedUserId.isNotEmpty) {
      return Colors.grey.shade500; // Unselected avatars (showing "PS") in grey
    } else {
      return AppColors.fontColor; // Default color when no selection
    }
  }

  Border? _getBorderStyle(
    bool isSelectedForComparison,
    bool isCurrentlySelected,
  ) {
    if (isCurrentlySelected) {
      // CHANGED: Use grey border instead of blue for selected avatar
      return Border.all(color: Colors.grey.shade300, width: 1.5);
    }
    return Border.all(
      color: Colors.grey.withOpacity(0.1),
      width: 1,
    ); // Light border for unselected
  }

  double _getAvatarOpacity(
    bool isSelectedForComparison,
    bool isCurrentlySelected,
  ) {
    if (_selectedUserId.isEmpty)
      return 1.0; // All full opacity when no selection
    return isCurrentlySelected
        ? 1.0
        : 0.6; // Selected full opacity, others dimmed
  }

  // Profile content builder without ticking overlay
  Widget _buildProfileContent(
    String? profileUrl,
    String initials,
    String firstName,
  ) {
    if (profileUrl != null && profileUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          profileUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialAvatar(initials, firstName, showLoader: true);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialAvatar(initials, firstName);
          },
        ),
      );
    } else {
      return _buildInitialAvatar(initials, firstName);
    }
  }

  Widget _buildInitialAvatar(
    String initials,
    String firstName, {
    bool showLoader = false,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getConsistentColor(firstName + initials),
        shape: BoxShape.circle,
      ),
      child: showLoader
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Center(
              child: Text(
                initials.isNotEmpty
                    ? initials.toUpperCase()
                    : (firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildTimelineView() {
    if (_isLoading) {
      return SkeletonCalendarCard();
    }

    if (_selectedType == 'team' && _selectedUserId.isEmpty) {
      return _emptyState('Select a PS to view their schedule');
    }

    final activeTimeSlots = _timeSlotItems.keys.toList()..sort();
    if (activeTimeSlots.isEmpty) {
      return _emptyState('No scheduled activities for this date');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: activeTimeSlots.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey.shade300,
        thickness: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemBuilder: (context, index) {
        final timeKey = activeTimeSlots[index];
        final items = _timeSlotItems[timeKey] ?? [];
        final events = items
            .where((item) => item['start_time'] != null)
            .toList();
        final tasks = items
            .where((item) => item['start_time'] == null)
            .toList();
        List<dynamic> allItems = [];
        allItems.addAll(events);
        allItems.addAll(tasks);
        bool isExpanded = _expandedSlots[timeKey] ?? false;
        int showCount = isExpanded ? allItems.length : 2;
        bool showMore = allItems.length > 2;
        List<dynamic> displayItems = allItems.take(showCount).toList();

        // TIME ABOVE, CARDS BELOW:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  timeKey,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              ...displayItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildTaskCard(item),
                ),
              ),
              if (showMore && !isExpanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedSlots[timeKey] = true;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 8,
                      ),
                      child: Text(
                        "Show More (${allItems.length - 2} more) ▼",
                        style: TextStyle(
                          color: const Color.fromRGBO(117, 117, 117, 1),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showMore && isExpanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedSlots[timeKey] = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 8,
                      ),
                      child: Text(
                        "Show Less ▲",
                        style: TextStyle(
                          color: const Color.fromRGBO(117, 117, 117, 1.0),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color getTaskCardColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('test drive')) {
      return Color(0xFFF5EFFA);
    }
    if (c.contains('call') ||
        c.contains('quotation') ||
        c.contains('provide quotation') ||
        c.contains('send email') ||
        c.contains('send sms') ||
        c.contains('meeting') ||
        c.contains('vehicle selection') ||
        c.contains('showroom appointment') ||
        c.contains('trade in evaluation')) {
      return Color(0xFFEAF2FE);
    }
    return Color(0xFFF0F3FA);
  }

  Widget _buildTaskCard(dynamic item) {
    String leadId = item['lead_id']?.toString() ?? '';
    String clientName = item['name'] ?? 'No Name';
    String carName = item['PMI'] ?? '';
    String category = item['subject'] ?? 'Appointment';
    String location = item['location'] ?? '';

    String timeStr =
        item['slot'] ??
        item['time_range'] ??
        item['start_time'] ??
        item['time'] ??
        item['due_date'] ??
        '';

    final isTestDrive = category.toLowerCase().contains('test drive');
    final verticalBarColor = isTestDrive
        ? Color(0xFFA674D4)
        : AppColors.colorsBlue;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowupsDetails(
              leadId: leadId,
              isFromFreshlead: false,
              isFromManager: true,
              spId: '',
              isFromTestdriveOverview: false,
              refreshDashboard: () async {},
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: getTaskCardColor(category),
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 6.1),
            Container(
              width: 4,
              height: 70,
              margin: EdgeInsets.only(left: 6, right: 14),
              decoration: BoxDecoration(
                color: verticalBarColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.5,
                  horizontal: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTestDrive
                        ? Transform.translate(
                            offset: Offset(-2, 3),
                            child: Text(
                              clientName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        : Text(
                            clientName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                    SizedBox(height: 4),

                    Row(
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: verticalBarColor,
                          ),
                        ),
                        if (isTestDrive && carName.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.grey.shade400,
                          ),
                          Transform.translate(
                            offset: Offset(-5, 0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                              ),
                              child: Text(
                                carName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ] else if (!isTestDrive && timeStr.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.grey.shade400,
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (isTestDrive)
                      Transform.translate(
                        offset: Offset(-5, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text(
                            location.isNotEmpty
                                ? location
                                : 'Location not specified',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      )
                    else if (!isTestDrive && carName.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          carName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Image.asset(
            'assets/calendar.png',
            width: 50,
            height: 50,
            color: const Color.fromRGBO(117, 117, 117, 1.0),
          ),
          SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseTimeString(String timeStr) {
    if (timeStr.isEmpty) {
      return DateTime(2022, 1, 1, 0, 0);
    }
    bool isPM = timeStr.toLowerCase().contains('pm');
    bool isAM = timeStr.toLowerCase().contains('am');
    String cleanTime = timeStr
        .toLowerCase()
        .replaceAll('am', '')
        .replaceAll('pm', '')
        .replaceAll(' ', '')
        .trim();
    final parts = cleanTime.split(':');
    if (parts.length < 2) return DateTime(2022, 1, 1, 0, 0);
    try {
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (isPM && hour < 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }
      return DateTime(2022, 1, 1, hour, minute);
    } catch (e) {
      return DateTime(2022, 1, 1, 0, 0);
    }
  }
}
