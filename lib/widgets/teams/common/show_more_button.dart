import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../config/component/color/colors.dart';

class ShowMoreButton extends StatelessWidget {
  final VoidCallback onLoadMore;
  final VoidCallback onLoadLess;
  final bool hasMoreRecords;
  final bool canShowLess;
  final int currentCount;
  final int totalCount;
  final int incrementCount;

  const ShowMoreButton({
    Key? key,
    required this.onLoadMore,
    required this.onLoadLess,
    required this.hasMoreRecords,
    required this.canShowLess,
    required this.currentCount,
    required this.totalCount,
    this.incrementCount = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If no data or no actions possible, don't show button
    if (totalCount == 0 || (!hasMoreRecords && !canShowLess)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Show Less button
          if (canShowLess)
            TextButton(
              onPressed: onLoadLess,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Show Less'),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_up, size: 16),
                ],
              ),
            ),

          // Show More button
          if (hasMoreRecords)
            TextButton(
              onPressed: onLoadMore,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorsBlue,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Show More (${math.min(incrementCount, totalCount - currentCount)} more)',
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
