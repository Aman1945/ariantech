import 'package:flutter/material.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? trailing;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
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
              onPressed: onToggle,
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 35,
                color: AppColors.iconGrey,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: Text(
                title,
                style: AppFont.dropDowmLabel(context).copyWith(
                  color: AppColors.iconGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
