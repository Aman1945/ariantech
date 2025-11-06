import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/config/model/teams/team_member.dart';
import 'dart:math' as math;
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 

class ProfileAvatar extends StatelessWidget {
  final TeamMember member;
  final int index;

  const ProfileAvatar({Key? key, required this.member, required this.index})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      final isSelectedForComparison = controller.selectedUserIds.contains(
        member.userId,
      );
      final isCurrentlySelected =
          controller.selectedProfileIndex.value == index &&
          controller.selectedUserId.value == member.userId;
      final isMultiSelectMode = controller.isMultiSelectMode.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              controller.isMultiSelectMode.value = true;
              controller.toggleUserSelection(member.userId);
            },
            onTap: () {
              HapticFeedback.lightImpact();
              controller.selectProfile(index, member.userId);
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 5, 0),
              child: Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: _getBorderStyle(
                        isSelectedForComparison,
                        isCurrentlySelected,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildProfileContent(
                        isSelectedForComparison,
                        member.profileUrl,
                        member.initials,
                        member.firstName,
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 70),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppFont.mediumText14(context).copyWith(
                color: _getNameTextColor(
                  isSelectedForComparison,
                  isCurrentlySelected,
                  isMultiSelectMode,
                ),
                fontWeight: (isSelectedForComparison || isCurrentlySelected)
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              child: Text(
                member.firstName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    });
  }

  Border? _getBorderStyle(
    bool isSelectedForComparison,
    bool isCurrentlySelected,
  ) {
    if (isCurrentlySelected) {
      return Border.all(color: AppColors.backgroundLightGrey, width: 3);
    }
    return Border.all(color: AppColors.colorsBlue.withOpacity(0.1), width: 1);
  }

  Color _getNameTextColor(
    bool isSelectedForComparison,
    bool isCurrentlySelected,
    bool isMultiSelectMode,
  ) {
    if (isMultiSelectMode) {
      if (isSelectedForComparison) {
        return AppColors.fontColor;
      } else {
        return Colors.grey.shade500;
      }
    } else {
      if (isCurrentlySelected) {
        return AppColors.fontColor;
      } else {
        return Colors.grey.shade500;
      }
    }
  }

  Widget _buildProfileContent(
    bool isSelectedForComparison,
    String? profileUrl,
    String initials,
    String firstName,
    BuildContext context,
  ) {
    if (isSelectedForComparison) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.sideGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      );
    } else {
      if (profileUrl != null && profileUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Image.network(
            profileUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildInitialAvatar(initials, firstName, showLoader: true);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialAvatar(initials, firstName);
            },
          ),
        );
      } else {
        return _buildInitialAvatar(initials, firstName);
      }
    }
  }

  Widget _buildInitialAvatar(
    String initials,
    String firstName, {
    bool showLoader = false,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getConsistentColor(firstName + initials),
        shape: BoxShape.circle,
      ),
      child: showLoader
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Center(
              child: Text(
                initials.isNotEmpty
                    ? initials.toUpperCase()
                    : (firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Color _getConsistentColor(String seed) {
    int hash = seed.hashCode;
    final math.Random random = math.Random(hash);
    int red = 80 + random.nextInt(150);
    int green = 80 + random.nextInt(150);
    int blue = 80 + random.nextInt(150);
    return Color.fromARGB(255, red, green, blue);
  }
}
