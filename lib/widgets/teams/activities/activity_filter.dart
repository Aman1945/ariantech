import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import '../../../config/component/color/colors.dart'; 

class ActivityFilter extends StatelessWidget {
  const ActivityFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          children: [
            IntrinsicWidth(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10, top: 5),
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 300),
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.arrowContainerColor,
                    width: .5,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton(
                      controller: controller,
                      index: 0,
                      text: 'Upcoming',
                      activeColor: AppColors.borderGreen,
                    ),
                    _buildFilterButton(
                      controller: controller,
                      index: 1,
                      text: 'Overdue (${controller.overdueCount.value})',
                      activeColor: AppColors.borderRed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterButton({
    required TeamsController controller,
    required int index,
    required String text,
    required Color activeColor,
  }) {
    final isSelected = controller.upcomingButtonIndex.value == index;

    return Expanded(
      child: TextButton(
        onPressed: () => controller.changeUpcomingFilter(index),
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? activeColor.withOpacity(0.29)
              : Colors.transparent,
          foregroundColor: isSelected ? activeColor : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          side: BorderSide(
            color: isSelected ? activeColor : Colors.transparent,
            width: .5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            color: isSelected
                ? activeColor.withOpacity(0.89)
                : AppColors.iconGrey,
          ),
        ),
      ),
    );
  }
}
