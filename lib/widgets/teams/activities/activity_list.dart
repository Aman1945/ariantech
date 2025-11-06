import 'package:flutter/material.dart';
import 'package:smartassist/config/model/teams/activity_data.dart'; 
import 'activity_card.dart';

class ActivityList extends StatelessWidget {
  final List<ActivityData> activities;
  final String title;
  final String dateKey;

  const ActivityList({
    Key? key,
    required this.activities,
    required this.title,
    required this.dateKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional section title
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 8),
        //   child: Text(
        //     title,
        //     style: AppFont.mediumText14(context).copyWith(
        //       fontWeight: FontWeight.w600,
        //     ),
        //   ),
        // ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ActivityCard(activity: activity, dateKey: dateKey),
              ),
            );
          },
        ),
      ],
    );
  }
}
