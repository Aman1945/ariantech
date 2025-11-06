import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/controller/teams/teams_controller.dart';
import '../../../config/component/color/colors.dart';
import '../../../config/component/font/font.dart'; 
import 'comparison_header.dart';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamsController>();
    double screenWidth = MediaQuery.of(context).size.width;

    return Obx(() {
      final hasData = controller.getCurrentDataToDisplay().isNotEmpty;

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
                  0: FixedColumnWidth(screenWidth * 0.30),
                  1: FixedColumnWidth(screenWidth * 0.11),
                  2: FixedColumnWidth(screenWidth * 0.11),
                  3: FixedColumnWidth(screenWidth * 0.11),
                  4: FixedColumnWidth(screenWidth * 0.11),
                  5: FixedColumnWidth(screenWidth * 0.11),
                  6: FixedColumnWidth(screenWidth * 0.11),
                },
                children: [
                    _buildHeaderRow(),
                  ..._buildMemberRows(controller),
                ],
              )
            : _buildEmptyState(),
      );
    });
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Name', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Enquiries', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Test Drives', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Orders', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Cancellation', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Net Orders', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Text('Retail', style: AppFont.smallText10(Get.context!).copyWith(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  List<TableRow> _buildMemberRows(TeamsController controller) {
    final displayData = controller.getDisplayedData();
    final selectedUserIds = controller.selectedUserIds;

    return displayData.map((member) {
      if (member == null)
        return TableRow(children: List.filled(7, const Text('')));

      bool isSelected = selectedUserIds.contains(
        member['user_id']?.toString() ?? '',
      );

      return _buildTableRow([
        _buildMemberCell(member),
        _buildDataCell(member['enquiries'], isSelected),
        _buildDataCell(member['testDrives'], isSelected),
        _buildDataCell(member['orders'], isSelected),
        _buildDataCell(member['cancellation'], isSelected),
        _buildDataCell(member['net_orders'], isSelected),
        _buildDataCell(member['retail'], isSelected),
      ]);
    }).toList();
  }

  Widget _buildMemberCell(dynamic member) {
    return InkWell(
      onTap: () {
        // Handle member tap if needed
      },
      child: Row(
        children: [
          _buildMemberAvatar(member),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              member['name'].toString(),
              overflow: TextOverflow.ellipsis,
              style: AppFont.smallText10(Get.context!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(dynamic member) {
    final String name = member['name'] ?? '';
    final String? imageUrl = member['profileImage'];
    final String initials = name.isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 12,
      backgroundColor: (imageUrl == null || imageUrl.isEmpty)
          ? _getConsistentColor(name)
          : Colors.transparent,
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildDataCell(dynamic value, bool isSelected) {
    return Text(
      value.toString(),
      style: AppFont.smallText10(
        Get.context!,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'No data available',
          style: AppFont.smallText10(Get.context!).copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  Color _getConsistentColor(String seed) {
    final List<Color> bgColors = [
      Colors.red,
      Colors.green,
      AppColors.colorsBlue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.purpleAccent,
    ];

    final int hash = seed.codeUnits.fold(0, (prev, el) => prev + el);
    return bgColors[hash % bgColors.length].withOpacity(0.8);
  }
}
