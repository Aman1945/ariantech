import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/config/model/teams/activity_data.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 
import '../../../pages/Home/single_details_pages/teams_enquiryIds.dart';

class ActivityCard extends StatelessWidget {
  final ActivityData activity;
  final String dateKey;

  const ActivityCard({Key? key, required this.activity, required this.dateKey})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: const Border(
          left: BorderSide(width: 8.0, color: AppColors.colorsBlue),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameAndVehicleRow(context),
                      const SizedBox(height: 2),
                      _buildSubjectAndDateRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(context, controller),
        ],
      ),
    );
  }

  Widget _buildNameAndVehicleRow(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .30,
          ),
          child: Text(
            activity.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: AppFont.dashboardName(context),
          ),
        ),
        if (activity.vehicle.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 15,
            width: 0.1,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.fontColor)),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .30,
            ),
            child: Text(
              activity.vehicle,
              style: AppFont.dashboardCarName(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubjectAndDateRow(BuildContext context) {
    return Row(
      children: [
        Text(activity.subject, style: AppFont.smallText10(context)),
        _buildFormattedDate(context, activity.date),
      ],
    );
  }

  Widget _buildFormattedDate(BuildContext context, String dateStr) {
    String formattedDate = '';

    try {
      DateTime parseDate = DateTime.parse(dateStr);

      // Check if the date is today
      if (parseDate.year == DateTime.now().year &&
          parseDate.month == DateTime.now().month &&
          parseDate.day == DateTime.now().day) {
        formattedDate = 'Today';
      } else {
        // If not today, format it as "26th March"
        int day = parseDate.day;
        String suffix = _getDaySuffix(day);
        String month = DateFormat('MMM').format(parseDate);
        formattedDate = '${day}$suffix $month';
      }
    } catch (e) {
      formattedDate = dateStr; // Fallback if date parsing fails
    }

    return Row(
      children: [
        const SizedBox(width: 5),
        Text(formattedDate, style: AppFont.smallText10(context)),
      ],
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildActionButton(BuildContext context, TeamsController controller) {
    return GestureDetector(
      onTap: () {
        if (activity.leadId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamsEnquiryids(
                leadId: activity.leadId,
                userId: controller.selectedUserId.value,
              ),
            ),
          );
        } else {
          print("Invalid leadId");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.arrowContainerColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }
}
