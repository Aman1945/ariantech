import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart'; 
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart';
import 'activity_filter.dart';
import 'activity_list.dart';

class ActivitiesSection extends StatelessWidget {
  const ActivitiesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Obx(() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Filter (Upcoming/Overdue)
            const ActivityFilter(),

            // Activity Lists
            if (controller.upcomingFollowups.isNotEmpty)
              ActivityList(
                activities: controller.upcomingFollowups,
                title: 'Follow-ups',
                dateKey: 'due_date',
              ),

            if (controller.upcomingAppointments.isNotEmpty)
              ActivityList(
                activities: controller.upcomingAppointments,
                title: 'Appointments',
                dateKey: 'start_date',
              ),

            if (controller.upcomingTestDrives.isNotEmpty)
              ActivityList(
                activities: controller.upcomingTestDrives,
                title: 'Test Drives',
                dateKey: 'start_date',
              ),

            // Empty state when no activities
            if (controller.upcomingFollowups.isEmpty &&
                controller.upcomingAppointments.isEmpty &&
                controller.upcomingTestDrives.isEmpty)
              _buildEmptyState(context),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No activities found',
              style: AppFont.dropDowmLabelLightcolors(context),
            ),
          ],
        ),
      ),
    );
  }
}
