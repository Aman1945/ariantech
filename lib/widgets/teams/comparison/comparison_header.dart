import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/widgets/teams/common/tooltip_helper.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart';

class ComparisonHeader extends StatelessWidget {
  const ComparisonHeader({Key? key}) : super(key: key);

  // Global keys for tooltips
  static final GlobalKey enquiriesKey = GlobalKey();
  static final GlobalKey tDrivesKey = GlobalKey();
  static final GlobalKey ordersKey = GlobalKey();
  static final GlobalKey cancelKey = GlobalKey();
  static final GlobalKey netOrdersKey = GlobalKey();
  static final GlobalKey retailsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Table(
      children: [
        TableRow(
          children: [
            const SizedBox(), // Empty cell for name column
            _buildSortableHeader(
              'EQ',
              'enquiries',
              enquiriesKey,
              'Enquiries',
              controller,
            ),
            _buildSortableHeader(
              'TD',
              'testDrives',
              tDrivesKey,
              'Test Drives',
              controller,
            ),
            _buildSortableHeader(
              'OD',
              'orders',
              ordersKey,
              'Orders',
              controller,
            ),
            _buildSortableHeader(
              'CL',
              'cancellation',
              cancelKey,
              'Cancellations',
              controller,
            ),
            _buildSortableHeader(
              'ND',
              'net_orders',
              netOrdersKey,
              'Net Orders',
              controller,
            ),
            _buildSortableHeader(
              'RS',
              'retail',
              retailsKey,
              'Retails',
              controller,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortableHeader(
    String displayText,
    String sortKey,
    GlobalKey key,
    String tooltipText,
    TeamsController controller,
  ) {
    return Obx(() {
      final isCurrentSortColumn = controller.sortColumn.value == sortKey;

      return GestureDetector(
        key: key,
        onTap: () {
          TooltipHelper.showBubbleTooltip(Get.context!, key, tooltipText);
          controller.sortData(sortKey);
        },
        child: Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayText,
                style: AppFont.smallTextBold(Get.context!).copyWith(
                  color: isCurrentSortColumn && controller.sortState.value != 0
                      ? AppColors.colorsBlue
                      : null,
                ),
              ),
              if (isCurrentSortColumn && controller.sortState.value != 0)
                Icon(
                  controller.sortState.value == 1
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 12,
                  color: AppColors.colorsBlue,
                ),
            ],
          ),
        ),
      );
    });
  }
}
