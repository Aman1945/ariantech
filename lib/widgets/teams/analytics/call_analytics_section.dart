// widgets/teams/analytics/call_analytics_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart'; 
import '../../../config/component/color/colors.dart';
import 'analytics_stats_card.dart';
import 'analytics_table.dart';
import '../common/show_more_button.dart';

class CallAnalyticsSection extends StatelessWidget {
  const CallAnalyticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      return Column(
        children: [
          const AnalyticsStatsCard(),
          const AnalyticsTable(),
          ShowMoreButton(
            onLoadMore: controller.loadMoreRecords,
            onLoadLess: controller.loadLessRecords,
            hasMoreRecords: controller.hasMoreRecords(),
            canShowLess: controller.canShowLess(),
            currentCount: controller.currentDisplayCount.value,
            totalCount: controller.membersAnalytics.length,
          ),
        ],
      );
    });
  }
}
