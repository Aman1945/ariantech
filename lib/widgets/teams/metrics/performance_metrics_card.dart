import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/widgets/teams/metrics/metric_card.dart';
import 'package:smartassist/widgets/teams/metrics/period_filter.dart';
import '../../../config/component/color/colors.dart';  

class PerformanceMetricsCard extends StatelessWidget {
  const PerformanceMetricsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      if (controller.isOnlyLetterSelected) {
        return Container(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(
              "Select a user to view details.",
              style: AppFont.dropDowmLabelLightcolors(context),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLightGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [PeriodFilter(), _buildMetricsGrid(context, controller)],
          ),
        ),
      );
    });
  }

  Widget _buildMetricsGrid(BuildContext context, TeamsController controller) {
    final performanceData = controller.currentPerformanceData;

    if (performanceData == null) {
      return const Center(child: Text('No data available'));
    }

    final metrics = performanceData.toMetricItems();
    List<Widget> rows = [];

    for (int i = 0; i < metrics.length; i += 2) {
      rows.add(
        Row(
          children: [
            for (int j = i; j < i + 2 && j < metrics.length; j++) ...[
              Expanded(
                child: MetricCard(
                  value: metrics[j].value.toString(),
                  label: metrics[j].label,
                  valueColor: AppColors.colorsBlue,
                  isSelected: controller.metricIndex.value == j,
                  isUserSelected: controller.selectedType.value != 'All',
                ),
              ),
              if (j % 2 == 0 && j + 1 < metrics.length)
                const SizedBox(width: 12),
            ],
          ],
        ),
      );
      if (i + 2 < metrics.length) rows.add(const SizedBox(height: 12));
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
