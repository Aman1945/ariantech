import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import '../../../config/component/color/colors.dart'; 

class PeriodFilter extends StatelessWidget {
  const PeriodFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildPeriodButton('MTD', 1, controller),
                  _buildPeriodButton('QTD', 0, controller),
                  _buildPeriodButton('YTD', 2, controller),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPeriodButton(
    String label,
    int index,
    TeamsController controller,
  ) {
    final isSelected = controller.periodIndex.value == index;

    return InkWell(
      onTap: () => controller.changePeriod(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.colorsBlue.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.colorsBlue : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.colorsBlue : AppColors.iconGrey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
