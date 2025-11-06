import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/controller/tab_controller.dart';
import 'package:smartassist/pages/Home/All_field_bottomArrow/all_appointment.dart';
import 'package:smartassist/pages/Home/All_field_bottomArrow/all_followups.dart';
import 'package:smartassist/pages/Home/All_field_bottomArrow/all_testdrive.dart';
import 'package:smartassist/widgets/followups/overdue_followup.dart';
import 'package:smartassist/widgets/followups/upcoming_row.dart';
import 'package:smartassist/widgets/oppointment/overdue.dart';
import 'package:smartassist/widgets/oppointment/upcoming.dart';
import 'package:smartassist/widgets/testdrive/overdue.dart';
import 'package:smartassist/widgets/testdrive/upcoming.dart';

class Threebtn extends StatefulWidget {
  final String leadId;
  final int overdueFollowupsCount;
  final int overdueAppointmentsCount;
  final int overdueTestDrivesCount;
  final List<dynamic> upcomingFollowups;
  final List<dynamic> overdueFollowups;
  final List<dynamic> upcomingAppointments;
  final List<dynamic> overdueAppointments;
  final List<dynamic> upcomingTestDrives;
  final List<dynamic> overdueTestDrives;
  final Future<void> Function() refreshDashboard;
  final TabControllerNew tabController;
  final void Function(int)? onTabChanged;

  const Threebtn({
    super.key,
    required this.leadId,
    required this.upcomingFollowups,
    required this.overdueFollowups,
    required this.upcomingAppointments,
    required this.overdueAppointments,
    required this.refreshDashboard,
    required this.overdueFollowupsCount,
    required this.overdueAppointmentsCount,
    required this.overdueTestDrivesCount,
    required this.upcomingTestDrives,
    required this.overdueTestDrives,
    required this.tabController,
    this.onTabChanged,
  });

  @override
  State<Threebtn> createState() => _ThreebtnState();
}

class _ThreebtnState extends State<Threebtn> {
  int _childButtonIndex = 0;
  Widget? _currentWidget;
  int _currentMainTab = 0;

  @override
  void initState() {
    super.initState();
    _startToggleTimer();
    _currentMainTab = widget.tabController.currentTab ?? 0;
    widget.tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateCurrentWidget();
      }
    });
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    widget.tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(Threebtn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasDataChanged(oldWidget) ||
        oldWidget.tabController != widget.tabController) {
      if (oldWidget.tabController != widget.tabController) {
        oldWidget.tabController.removeListener(_onTabChanged);
        widget.tabController.addListener(_onTabChanged);
        _currentMainTab = widget.tabController.currentTab ?? 0;
      }
      _updateCurrentWidget();
    }
  }

  bool _hasDataChanged(Threebtn oldWidget) {
    return oldWidget.upcomingFollowups != widget.upcomingFollowups ||
        oldWidget.overdueFollowups != widget.overdueFollowups ||
        oldWidget.upcomingAppointments != widget.upcomingAppointments ||
        oldWidget.overdueAppointments != widget.overdueAppointments ||
        oldWidget.upcomingTestDrives != widget.upcomingTestDrives ||
        oldWidget.overdueTestDrives != widget.overdueTestDrives;
  }

  void _onTabChanged() {
    if (mounted && widget.tabController != null) {
      setState(() {
        _currentMainTab = widget.tabController.currentTab;
        _childButtonIndex = 0;
      });
      _updateCurrentWidget();
    }
  }

  void _changeMainTab(int index) {
    setState(() {
      _currentMainTab = index;
      _childButtonIndex = 0;
    });
    widget.tabController?.changeTab(index);
    widget.onTabChanged?.call(index); // Add this line
    _updateCurrentWidget();
  }

  void _changeSubTab(int index) {
    if (_childButtonIndex != index) {
      setState(() {
        _childButtonIndex = index;
      });
      _updateCurrentWidget();
    }
  }

  void _updateCurrentWidget() {
    Widget newWidget;

    switch (_currentMainTab) {
      case 0:
        newWidget = _childButtonIndex == 0
            ? FollowupsUpcoming(
                refreshDashboard: widget.refreshDashboard,
                upcomingFollowups: widget.upcomingFollowups,
                isNested: false,
              )
            : OverdueFollowup(
                refreshDashboard: widget.refreshDashboard,
                overdueeFollowups: widget.overdueFollowups,
                isNested: false,
              );
        break;
      case 1:
        newWidget = _childButtonIndex == 0
            ? OppUpcoming(
                refreshDashboard: widget.refreshDashboard,
                upcomingOpp: widget.upcomingAppointments,
                isNested: false,
              )
            : OppOverdue(
                refreshDashboard: widget.refreshDashboard,
                overdueeOpp: widget.overdueAppointments,
                isNested: false,
              );
        break;
      case 2:
        newWidget = _childButtonIndex == 0
            ? TestUpcoming(
                refreshDashboard: widget.refreshDashboard,
                upcomingTestDrive: widget.upcomingTestDrives,
                isNested: false,
              )
            : TestOverdue(
                refreshDashboard: widget.refreshDashboard,
                overdueTestDrive: widget.overdueTestDrives,
                isNested: false,
              );
        break;
      default:
        newWidget = const SizedBox(height: 10);
    }

    if (mounted) {
      setState(() {
        _currentWidget = newWidget;
      });
    }
  }

  // Helper methods for responsive design - maintaining current sizes as base
  double _getScreenWidth() => MediaQuery.sizeOf(context).width;
  double _getScreenHeight() => MediaQuery.sizeOf(context).height;

  // Responsive scaling while maintaining current design proportions
  double _getResponsiveScale() {
    final width = _getScreenWidth();
    if (width <= 320) return 0.85; // Very small phones
    if (width <= 375) return 0.95; // Small phones
    if (width <= 414) return 1.0; // Standard phones (base size)
    if (width <= 600) return 1.05; // Large phones
    if (width <= 768) return 1.1; // Small tablets
    return 1.15; // Large tablets and up
  }

  double _getResponsivePadding() {
    return 10.0 * _getResponsiveScale(); // Base padding: 10
  }

  double _getMainTabHeight() {
    return (MediaQuery.sizeOf(context).height * 0.04).clamp(40.0, 50.0);
  }

  double _getSubTabHeight() {
    return 27.0 * _getResponsiveScale(); // Base height: 27
  }

  double _getSubTabWidth() {
    return 150.0 * _getResponsiveScale(); // Base width: 150
  }

  double _getMainTabFontSize() {
    // Use your existing AppFont.threeBtn or scale accordingly
    final baseSize = 12.0; // Approximate base font size
    return baseSize * _getResponsiveScale();
  }

  double _getSubTabFontSize() {
    return 10.0 * _getResponsiveScale(); // Base font size: 10
  }

  double _getBorderRadius() {
    return 10.0 * _getResponsiveScale();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainTabButtons(),
        _buildSubTabButtons(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _currentWidget ?? const SizedBox(height: 10),
        ),
        _buildNavigationArrow(context),
      ],
    );
  }

  Widget _buildMainTabButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: _getResponsivePadding(),
      ),
      child: Container(
        height: _getMainTabHeight(),
        width: double.infinity,
        child: Row(
          children: [
            Expanded(child: _buildTabButton('Follow ups', Icons.call, 0)),
            SizedBox(width: 8.0 * _getResponsiveScale()),
            Expanded(child: _buildTabButton('Appointments', Icons.event, 1)),
            SizedBox(width: 8.0 * _getResponsiveScale()),
            Expanded(
              child: _buildTabButton('Test Drives', Icons.directions_car, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    final isActive = _currentMainTab == index;

    return TextButton(
      onPressed: () => _changeMainTab(index),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: 8.0 * _getResponsiveScale(),
          horizontal:
              8.0 * _getResponsiveScale(), // Increased from 4.0 to 12.0
        ),
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          side: BorderSide(
            color: isActive
                ? AppColors.containerblue
                : AppColors.fontColor.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        backgroundColor: isActive
            ? AppColors.containerblue
            : Colors.transparent,
        foregroundColor: isActive ? Colors.white : AppColors.fontColor,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 4.0 * _getResponsiveScale(),
        ), // Added extra padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size:
                  _getMainTabFontSize() *
                  1.1, // Slightly increased icon relative to smaller text
              color: isActive ? Colors.white : AppColors.fontColor,
            ),
            SizedBox(
              width: 6.0 * _getResponsiveScale(),
            ), // Increased spacing between icon and text
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: _getMainTabFontSize(),
                  fontWeight: FontWeight.w400,
                  color: isActive ? Colors.white : AppColors.fontColor,
                  letterSpacing:
                      0.2, // Added letter spacing for better readability
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            _getResponsivePadding(),
            _getResponsivePadding(),
            0,
            _getResponsivePadding(),
          ),
          child: Container(
            width: _getSubTabWidth(),
            height: _getSubTabHeight(),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF767676).withOpacity(0.3),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildSubTabButton('Upcoming', 0),
                _buildSubTabButton('Overdue', 1, showCount: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String title, int index, {bool showCount = false}) {
    final isActive = _childButtonIndex == index;
    final overdueCount = _getOverdueCount();

    return Expanded(
      child: TextButton(
        onPressed: () => _changeSubTab(index),
        style: TextButton.styleFrom(
          backgroundColor: isActive
              ? (index == 0 ? AppColors.borderGreen : const Color(0xFFFFF5F4))
              : Colors.transparent,
          foregroundColor: isActive ? Colors.white : Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: 5.0 * _getResponsiveScale(),
            horizontal: 8.0 * _getResponsiveScale(),
          ),
          side: BorderSide(
            color: isActive
                ? (index == 0 ? AppColors.borderGreen : AppColors.borderRed)
                : Colors.transparent,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: _getSubTabFontSize(),
                  fontWeight: FontWeight.w400,
                  color: isActive
                      ? (index == 0
                            ? AppColors.containerGreen
                            : AppColors.containerRed)
                      : const Color(0xff000000).withOpacity(0.56),
                ),
              ),

              if (showCount) ...[
                SizedBox(width: 4.0 * _getResponsiveScale()),
                Text(
                  '($overdueCount)',
                  style: GoogleFonts.poppins(
                    fontSize: _getSubTabFontSize(),
                    fontWeight: FontWeight.w400,
                    color: isActive
                        ? AppColors.containerRed
                        : const Color(0xff000000).withOpacity(0.56),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _showText = false;
  Timer? _toggleTimer;

  void _startToggleTimer() {
    _toggleTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _showText = !_showText;
        });
      }
    });
  }

  Widget _buildNavigationArrow(BuildContext context) {
    final scale = _getResponsiveScale();
    final fontSize = 12.0 * scale; // Base: 12px
    final iconSize = 36.0 * scale; // Base: 36px
    final containerHeight = 40.0 * scale;
    final containerWidth = 100.0 * scale;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsivePadding()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _navigateToDetailPage,
            child: Container(
              height: containerHeight,
              width: containerWidth,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: _showText
                    ? Text(
                        "See more",
                        key: const ValueKey('text'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          color: AppColors.fontColor,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    : Icon(
                        Icons.keyboard_arrow_down_rounded,
                        key: const ValueKey('icon'),
                        size: iconSize,
                        color: AppColors.fontColor,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetailPage() {
    Widget targetPage;

    switch (_currentMainTab) {
      case 0:
        targetPage = AddFollowups(refreshDashboard: widget.refreshDashboard);
        break;
      case 1:
        targetPage = AllAppointment(refreshDashboard: widget.refreshDashboard);

        break;
      case 2:
        targetPage = AllTestdrive(refreshDashboard: widget.refreshDashboard);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  int _getOverdueCount() {
    switch (_currentMainTab) {
      case 0:
        return widget.overdueFollowupsCount;
      case 1:
        return widget.overdueAppointmentsCount;
      case 2:
        return widget.overdueTestDrivesCount;
      default:
        return 0;
    }
  }
}
