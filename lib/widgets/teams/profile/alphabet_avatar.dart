import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import '../../../config/component/color/colors.dart'; 

class AlphabetAvatar extends StatelessWidget {
  final String letter;

  const AlphabetAvatar({Key? key, required this.letter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      final isSelected = controller.selectedLetters.contains(letter);
      final isMultiSelectMode = controller.isMultiSelectMode.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.toggleLetterSelection(letter);
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
          const SizedBox(height: 24),
        ],
      );
    });
  }
}
