import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 

class AnalyticsStatsCard extends StatelessWidget {
  const AnalyticsStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      final analyticsData = controller.analyticsData.value;

      if (analyticsData == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamSizeSection(context, analyticsData.teamSize),
            const SizedBox(height: 16),
            _buildStatsRow(context, analyticsData),
          ],
        ),
      );
    });
  }

  Widget _buildTeamSizeSection(BuildContext context, int teamSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Text(
            'Team size : $teamSize',
            style: AppFont.mediumText14(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, analyticsData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBox(
          context,
          analyticsData.totalConnected.toString(),
          'Connected',
        ),
        _buildVerticalDivider(),
        _buildStatBox(
          context,
          analyticsData.totalDuration.toString(),
          'Duration',
        ),
        _buildVerticalDivider(),
        _buildStatBox(context, analyticsData.declined.toString(), 'Declined'),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppFont.appbarfontblack(context)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFont.mediumText14(context).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 3, left: 10, right: 10),
      height: 50,
      width: 0.1,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.fontColor)),
      ),
    );
  }
}
