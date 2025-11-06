// pages/Home/my_teams.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/widgets/teams/activities/activities_section.dart';
import 'package:smartassist/widgets/teams/analytics/call_analytics_section.dart';
import 'package:smartassist/widgets/teams/common/loading_widget.dart';
import 'package:smartassist/widgets/teams/common/section_header.dart';
import 'package:smartassist/widgets/teams/comparison/team_comparison_section.dart';
import 'package:smartassist/widgets/teams/metrics/performance_metrics_card.dart';
import 'package:smartassist/widgets/teams/profile/profile_avatar_row.dart';
import '../../config/component/color/colors.dart';
import '../../config/component/font/font.dart';
import '../../config/getX/fab.controller.dart';
import '../../widgets/team_calllog_userid.dart';

class Teams extends StatefulWidget {
  const Teams({super.key});

  @override
  State<Teams> createState() => _TeamsState();
}

class _TeamsState extends State<Teams> {
  final ScrollController _scrollController = ScrollController();
  final FabController fabController = Get.put(FabController());
  late TeamsController _teamsController;

  @override
  void initState() {
    super.initState();
    _teamsController = Get.put(TeamsController());
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_teamsController.isFabVisible.value) {
          _teamsController.toggleFabVisibility(false);
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_teamsController.isFabVisible.value) {
          _teamsController.toggleFabVisibility(true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.colorsBlue,
      title: Obx(() => _buildAppBarContent(context)),
    );
  }

  Widget _buildAppBarContent(BuildContext context) {
    final shouldShowCompareButton = _teamsController.shouldShowCompareButton;
    final teamMembersLength = _teamsController.teamMembers.length;
    final selectedUserIdsLength = _teamsController.selectedUserIds.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Select All or Title
        shouldShowCompareButton
            ? _buildSelectAllButton(
                context,
                teamMembersLength,
                selectedUserIdsLength,
              )
            : Text('My Team', style: AppFont.appbarfontWhite(context)),

        // Right side - Compare button
        if (shouldShowCompareButton) _buildCompareButton(context),
      ],
    );
  }

  Widget _buildSelectAllButton(
    BuildContext context,
    int teamMembersLength,
    int selectedUserIdsLength,
  ) {
    final isAllSelected = selectedUserIdsLength == teamMembersLength;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _teamsController.selectAllUsers();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isAllSelected
              ? Colors.green.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Checkbox(
              side: const BorderSide(color: Colors.white),
              activeColor: Colors.white,
              checkColor: AppColors.colorsBlue,
              value: isAllSelected,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                _teamsController.selectAllUsers();
              },
            ),
            Text('Select All', style: AppFont.appbarfontWhite(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _teamsController.startComparison(),
        child: Text('Compare', style: AppFont.mediumText14white(context)),
      ),
    );
  }

  Widget _buildBody() {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _teamsController.fetchTeamDetails,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10.0),
              child: Obx(() => _buildContent()),
            ),
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      final direction = notification.direction;
      if (direction == ScrollDirection.reverse &&
          _teamsController.isFabVisible.value) {
        _teamsController.toggleFabVisibility(false);
      } else if (direction == ScrollDirection.forward &&
          !_teamsController.isFabVisible.value) {
        _teamsController.toggleFabVisibility(true);
      }
    }
    return false;
  }

  Widget _buildContent() {
    if (_teamsController.isLoading.value) {
      return const LoadingWidget(message: 'Loading team data...');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Avatars Row
        _buildProfileSection(),
        const SizedBox(height: 10),

        // Individual Performance Section
        if (!_teamsController.isComparing.value) ...[
          const PerformanceMetricsCard(),
          const SizedBox(height: 10),
        ],

        // Team Comparison Section
        const TeamComparisonSection(),
        const SizedBox(height: 10),

        // Activities Section
        if (_teamsController.selectedType.value != 'All') ...[
          _buildActivitiesSection(),
          const SizedBox(height: 10),
        ],

        // Call Analytics Section
        _buildCallAnalyticsSection(),
        const SizedBox(height: 10),

        // Call Logs Section for individual users
        if (_teamsController.selectedType.value != 'All') ...[
          _buildCallLogsSection(),
        ],
      ],
    );
  }

  Widget _buildProfileSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [ProfileAvatarRow(scrollController: _scrollController)],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Obx(() {
      return Column(
        children: [
          SectionHeader(
            title: 'Activities',
            isExpanded: !_teamsController.isHideActivities.value,
            onToggle: _teamsController.toggleHideActivities,
          ),
          if (!_teamsController.isHideActivities.value) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(top: 10),
              child: const ActivitiesSection(),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildCallAnalyticsSection() {
    if (_teamsController.isOnlyLetterSelected) {
      return Container(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text(
            "Select a user to view call analysis.",
            style: AppFont.dropDowmLabelLightcolors(context),
          ),
        ),
      );
    }

    return Obx(() {
      if (_teamsController.selectedType.value == 'dynamic') {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          SectionHeader(
            title: 'Call Analysis',
            isExpanded: _teamsController.isHideAllcall.value,
            onToggle: _teamsController.toggleHideAllCall,
          ),
          if (_teamsController.isHideAllcall.value) ...[
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: CallAnalyticsSection(),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildCallLogsSection() {
    return Obx(() {
      return Column(
        children: [
          SectionHeader(
            title: 'Call Logs',
            isExpanded: !_teamsController.isHideCalls.value,
            onToggle: _teamsController.toggleHideCalls,
          ),
          if (!_teamsController.isHideCalls.value) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSingleUserCallLog(),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSingleUserCallLog() {
    return Obx(() {
      final dashboardData = _teamsController.selectedUserData['dashboardData'];
      final enquiryData = _teamsController.selectedUserData['enquiryData'];
      final coldCallData = _teamsController.selectedUserData['coldCallData'];

      return TeamCalllogUserid(
        key: ValueKey(_teamsController.selectedTimeRange.value),
        dashboardData: dashboardData,
        enquiryData: enquiryData,
        coldCallData: coldCallData,
        onTabChanged: _teamsController.changeTab,
        onTimeRangeChanged: _teamsController.changeTimeRange,
        initialTimeRange: _teamsController.selectedTimeRange.value,
        initialTabIndex: _teamsController.selectedTabIndex.value,
      );
    });
  }
}
