import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/widgets/teams/common/show_more_button.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 
import '../metrics/period_filter.dart';
import 'comparison_table.dart'; 

class TeamComparisonSection extends StatelessWidget {
  const TeamComparisonSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      if (controller.selectedType.value == 'dynamic') {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleHeader(context, controller),
            if (!controller.isHide.value) ...[
              if (controller.teamComparisonData.isEmpty &&
                  controller.isComparing.value)
                _buildEmptyState(context)
              else ...[
                ComparisonTable(),
                ShowMoreButton(
                  onLoadMore: controller.loadMoreRecords,
                  onLoadLess: controller.loadLessRecords,
                  hasMoreRecords: controller.hasMoreRecords(),
                  canShowLess: controller.canShowLess(),
                  currentCount: controller.currentDisplayCount.value,
                  totalCount: controller.getCurrentDataToDisplay().length,
                ),
              ],
            ],
          ],
        ),
      );
    });
  }

  Widget _buildToggleHeader(BuildContext context, TeamsController controller) {
    return InkWell(
      onTap: () => controller.toggleHide(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.backgroundLightGrey, width: 1),
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 0,
              spreadRadius: 0.2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => controller.toggleHide(),
              icon: Icon(
                controller.isHide.value
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 35,
                color: AppColors.iconGrey,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: Text(
                'Team Comparison',
                style: AppFont.dropDowmLabel(context).copyWith(
                  color: AppColors.iconGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            _buildFilterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(minWidth: 60, maxWidth: 150),
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const PeriodFilter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        child: Text(
          'No team data available',
          style: AppFont.dropDowmLabelLightcolors(context),
        ),
      ),
    );
  }
}
