import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import 'package:smartassist/widgets/teams/common/analytic_helper.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 
import '../../../pages/navbar_page/call_analytics.dart'; 
import '../common/avatar_helper.dart';

class AnalyticsTable extends StatelessWidget {
  const AnalyticsTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();
    double screenWidth = MediaQuery.of(context).size.width;

    return Obx(() {
      final hasData = controller.membersAnalytics.isNotEmpty;

      return Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: hasData
            ? Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: 0.6,
                  ),
                  verticalInside: BorderSide.none,
                ),
                columnWidths: {
                  0: FixedColumnWidth(screenWidth * 0.35), // Name column
                  1: FixedColumnWidth(screenWidth * 0.12), // Incoming
                  2: FixedColumnWidth(screenWidth * 0.12), // Outgoing
                  3: FixedColumnWidth(screenWidth * 0.12), // Connected
                  4: FixedColumnWidth(screenWidth * 0.12), // Duration
                  5: FixedColumnWidth(screenWidth * 0.12), // Declined
                },
                children: [
                    AnalyticsHeaderHelper.buildHeaderRow(context),
                  ..._buildMemberRows(controller),
                ],
              )
            : _buildEmptyState(context),
      );
    });
  }

  List<TableRow> _buildMemberRows(TeamsController controller) {
    final displayMembers = controller.getDisplayedData();

    return displayMembers.map((member) {
      return _buildTableRow([
        _buildMemberCell(member),
        _buildDataCell(member.incoming.toString()),
        _buildDataCell(member.outgoing.toString()),
        _buildDataCell(member.connected.toString()),
        _buildDataCell(member.duration.toString()),
        _buildDataCell(member.declined.toString()),
      ]);
    }).toList();
  }

  Widget _buildMemberCell(dynamic member) {
    return InkWell(
      onTap: () {
        Get.to(
          () => CallAnalytics(
            userName: member.name,
            userId: member.userId,
            isFromSM: true,
          ),
        );
      },
      child: Row(
        children: [
          AvatarHelper.buildAvatar(
            name: member.name,
            imageUrl: member.profileImage,
            radius: 12,
            fontSize: 12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              member.name,
              overflow: TextOverflow.ellipsis,
              style: AppFont.smallText10(Get.context!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String value) {
    return Text(value, style: AppFont.smallText10(Get.context!));
  }

  TableRow _buildTableRow(List<Widget> widgets) {
    return TableRow(
      children: widgets.map((widget) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
          child: widget,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'No analytics data available',
          style: AppFont.smallText10(context).copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}
