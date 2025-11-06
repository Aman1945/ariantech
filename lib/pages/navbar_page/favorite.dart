import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/controller/dashboard_getxapi.dart';
import 'package:smartassist/pages/navbar_page/favorites/favoritesbtns/f_appointment.dart';
import 'package:smartassist/pages/navbar_page/favorites/favoritesbtns/f_leads.dart';
import 'package:smartassist/pages/navbar_page/favorites/favoritesbtns/f_testdrive.dart';
import 'package:smartassist/pages/navbar_page/favorites/favoritesbtns/f_upcoming.dart';

class FavoritePage extends StatefulWidget {
  final String leadId;
  const FavoritePage({super.key, required this.leadId});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  int _selectedButtonIndex = 0;
  List<Map<String, dynamic>> followupData = [];
  List<Map<String, dynamic>> appointmentData = [];
  List<Map<String, dynamic>> testDriveData = [];
  List<Map<String, dynamic>> opportunityData = [];
  bool isLoading = false;
  final controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    // Load initial data for followups
    // fetchFollowupData();
    FLeads();
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedButtonIndex) {
      case 0:
        // return _buildDataList(opportunityData);
        return FLeads();
      case 1:
        return FUpcoming(leadId: widget.leadId); // Load follow-ups
      case 2:
        // return _buildDataList(appointmentData);
        return const FAppointment();
      case 3:
        // return _buildDataList(testDriveData);
        return const FTestdrive();

      default:
        return const SizedBox();
    }
  }

  // Helper methods to get responsive dimensions - moved to methods to avoid context issues
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Responsive padding
  EdgeInsets _responsivePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: _isTablet(context) ? 20 : (_isSmallScreen(context) ? 8 : 10),
    vertical: _isTablet(context) ? 12 : 8,
  );

  // Responsive font sizes
  double _titleFontSize(BuildContext context) =>
      _isTablet(context) ? 20 : (_isSmallScreen(context) ? 16 : 18);
  double _bodyFontSize(BuildContext context) =>
      _isTablet(context) ? 16 : (_isSmallScreen(context) ? 12 : 14);
  double _smallFontSize(BuildContext context) =>
      _isTablet(context) ? 14 : (_isSmallScreen(context) ? 10 : 12);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final controller = Get.find<DashboardController>();
        await controller.refreshData();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              final controller = Get.find<DashboardController>();
              await controller.refreshData(); // Calls API
              Navigator.pop(context);
            },
            icon: Icon(
              FontAwesomeIcons.angleLeft,
              color: Colors.white,
              size: _isSmallScreen(context) ? 18 : 20,
            ),
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Favourites',
              style: GoogleFonts.poppins(
                fontSize: _titleFontSize(context),
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: AppColors.colorsBlue,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 10,
                ),
                child: Wrap(
                  spacing: 1, // Space between buttons
                  children: [
                    FlexibleButton(
                      title: 'Enquiries',
                      onPressed: () {
                        setState(() {
                          _selectedButtonIndex = 0;
                        });
                      },
                      decoration: BoxDecoration(
                        border: _selectedButtonIndex == 0
                            ? Border.all(color: AppColors.colorsBlue)
                            : Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: GoogleFonts.poppins(
                        color: _selectedButtonIndex == 0
                            ? AppColors.colorsBlue
                            : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    FlexibleButton(
                      title: 'Follow ups',
                      onPressed: () {
                        setState(() {
                          _selectedButtonIndex = 1;
                        });
                      },
                      decoration: BoxDecoration(
                        border: _selectedButtonIndex == 1
                            ? Border.all(color: AppColors.colorsBlue)
                            : Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: GoogleFonts.poppins(
                        color: _selectedButtonIndex == 1
                            ? AppColors.colorsBlue
                            : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    FlexibleButton(
                      title: 'Appointments',
                      onPressed: () {
                        setState(() {
                          _selectedButtonIndex = 2;
                        });
                      },
                      decoration: BoxDecoration(
                        border: _selectedButtonIndex == 2
                            ? Border.all(color: AppColors.colorsBlue)
                            : Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: GoogleFonts.poppins(
                        color: _selectedButtonIndex == 2
                            ? AppColors.colorsBlue
                            : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    FlexibleButton(
                      title: 'Test Drives',
                      onPressed: () {
                        setState(() {
                          _selectedButtonIndex = 3;
                        });
                      },
                      decoration: BoxDecoration(
                        border: _selectedButtonIndex == 3
                            ? Border.all(color: AppColors.colorsBlue)
                            : Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: GoogleFonts.poppins(
                        color: _selectedButtonIndex == 3
                            ? AppColors.colorsBlue
                            : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 5),
              _buildContent(), // Load follow-ups or other data based on selection
            ],
          ),
        ),
      ),
    );
  }
}

class FlexibleButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final BoxDecoration decoration;
  final TextStyle textStyle;

  const FlexibleButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.decoration,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: decoration,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Color(0xffF3F9FF),
          padding: EdgeInsets.symmetric(horizontal: 5),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Text(title, style: textStyle, textAlign: TextAlign.center),
      ),
    );
  }
}
