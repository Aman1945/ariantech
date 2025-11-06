import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 

class AllAvatar extends StatelessWidget {
  const AllAvatar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      final isSelected =
          controller.selectedType.value == 'All' &&
          controller.selectedLetters.isEmpty;
      final isMultiSelectMode = controller.isMultiSelectMode.value;
      final teamMembersCount = controller.teamMembers.length;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              controller.selectAll();
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
              Get.snackbar(
                'Total',
                'Total $teamMembersCount team members',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
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
                    color: isMultiSelectMode
                        ? AppColors.sideRed
                        : (isSelected
                              ? AppColors.colorsBlue
                              : AppColors.backgroundLightGrey),
                    border: isSelected
                        ? Border.all(color: AppColors.colorsBlue, width: 2.5)
                        : Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isMultiSelectMode
                            ? Icons.close_rounded
                            : (isSelected
                                  ? Icons.people_rounded
                                  : Icons.people_rounded),
                        key: ValueKey(
                          isMultiSelectMode
                              ? 'clear'
                              : (isSelected ? 'groups' : 'people'),
                        ),
                        color: isMultiSelectMode
                            ? Colors.white
                            : (isSelected ? Colors.white : Colors.grey),
                        size: isSelected ? 34 : 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => controller.selectAll(),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppFont.mediumText14(context).copyWith(
                color: isSelected
                    ? AppColors.colorsBlue
                    : (isMultiSelectMode ? AppColors.fontColor : null),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(
                isMultiSelectMode ? 'Clear' : 'All',
                style: AppFont.mediumText14(context),
              ),
            ),
          ),
        ],
      );
    });
  }
}
