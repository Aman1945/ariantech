// widgets/teams/analytics/analytics_header.dart
import 'package:flutter/material.dart';
import '../../../config/component/color/colors.dart';
import '../common/tooltip_helper.dart';

class AnalyticsHeaderHelper {
  // Global keys for tooltips
  static final GlobalKey incomingKey = GlobalKey();
  static final GlobalKey outgoingKey = GlobalKey();
  static final GlobalKey connectedKey = GlobalKey();
  static final GlobalKey durationKey = GlobalKey();
  static final GlobalKey rejectedKey = GlobalKey();

  static TableRow buildHeaderRow(BuildContext context) {
    return TableRow(
      children: [
        const SizedBox(), // Empty cell for name column
        _buildHeaderIcon(
          key: incomingKey,
          assetPath: 'assets/incoming.png',
          tooltip: 'Incoming',
          context: context,
        ),
        _buildHeaderIcon(
          key: outgoingKey,
          assetPath: 'assets/outgoing.png',
          tooltip: 'Outgoing',
          context: context,
        ),
        _buildHeaderIconWidget(
          key: connectedKey,
          icon: Icons.call,
          color: AppColors.sideGreen,
          tooltip: 'Connected Calls',
          context: context,
        ),
        _buildHeaderIconWidget(
          key: durationKey,
          icon: Icons.access_time,
          color: AppColors.colorsBlue,
          tooltip: 'Total Duration',
          context: context,
        ),
        _buildHeaderIcon(
          key: rejectedKey,
          assetPath: 'assets/missed.png',
          tooltip: 'Rejected',
          context: context,
        ),
      ],
    );
  }

  static Widget _buildHeaderIcon({
    required GlobalKey key,
    required String assetPath,
    required String tooltip,
    required BuildContext context,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => TooltipHelper.showBubbleTooltip(context, key, tooltip),
      child: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.04,
          height: MediaQuery.of(context).size.width * 0.04,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  static Widget _buildHeaderIconWidget({
    required GlobalKey key,
    required IconData icon,
    required Color color,
    required String tooltip,
    required BuildContext context,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => TooltipHelper.showBubbleTooltip(context, key, tooltip),
      child: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Icon(
          icon,
          color: color,
          size: MediaQuery.of(context).size.width * 0.05,
        ),
      ),
    );
  }
}
