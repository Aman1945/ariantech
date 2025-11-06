import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/storage.dart';

class BottomBtnThird extends StatefulWidget {
  const BottomBtnThird({super.key});

  @override
  State<BottomBtnThird> createState() => _BottomBtnThirdState();
}

class _BottomBtnThirdState extends State<BottomBtnThird> {
  int _periodIndex = 0;
  int _childButtonIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  // Define table metrics - these match what's shown in the image
  final List<String> tableMetrics = [
    'Enquiries',
    'Lost Enquiries',
    'U Test Drives',
    'New Orders',
    'Cancellations',
    'Net Orders',
    'Retail',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> refreshAnalytics() async {
    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await Storage.getToken();

      // Determine period parameter based on selection
      String periodParam = '';
      switch (_childButtonIndex) {
        case 1:
          periodParam = '?type=MTD';
          break;
        case 0:
          periodParam = '?type=QTD';
          break;
        case 2:
          periodParam = '?type=YTD';
          break;
        default:
          periodParam = '?type=MTD';
      }

      final uri = Uri.parse(
        'https://api.smartassistapp.in/api/users/analytics$periodParam',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('this is the ${uri}');
      print(response.body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Check if the widget is still in the widget tree before calling setState
        if (mounted) {
          setState(() {
            _dashboardData = jsonData['data'];
            _isLoading = false;
          });
        }
      } else {
        // Handle unsuccessful status codes
        throw Exception(
          'Failed to load dashboard data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Check if the widget is still in the widget tree before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Handle different types of errors
      if (e is http.ClientException) {
        debugPrint('Network error: $e');
      } else if (e is FormatException) {
        debugPrint('Error parsing data: $e');
      } else {
        debugPrint('Unexpected error: $e');
      }
    }
  }

  // Get current data based on selected period
  Map<String, dynamic> get performanceCount {
    if (_dashboardData == null) {
      // Return empty data if API data isn't available yet
      return {};
    }
    return _dashboardData!['performance'] ?? {};
    // return _dashboardData!['dealerShipRank'] ??
    //     {}; // Fixed key from 'dealershipRank' to 'dealerShipRank'
  }

  Map<String, dynamic> get currentAllIndiaRank {
    if (_dashboardData == null) {
      // Return empty data if API data isn't available yet
      return {};
    }

    // Using allIndiaRank from API response - fixed key from 'allINDRank' to 'allIndiaRank'
    return _dashboardData!['allIndiaRank'] ?? {};
  }

  Map<String, dynamic> get allIndiaBestPerformace {
    if (_dashboardData == null) {
      // Return empty data if API data isn't available yet
      return {};
    }

    // Using allIndiaRank from API response - fixed key from 'allINDRank' to 'allIndiaRank'
    return _dashboardData!['allIndiaBestPerformace'] ?? {};
  }

  //new code remove us unused

  Map<String, dynamic> get dealershipRank {
    if (_dashboardData == null) {
      return {};
    }
    return _dashboardData!['dealerShipRank'] ?? {};
  }

  // Generate dynamic table rows based on API data
  List<List<String>> get tableData {
    final List<List<String>> data = [];

    if (_dashboardData == null) {
      return [];
    }

    // Add Enquiries row
    data.add([
      'Enquiries',
      performanceCount['enquiry']?.toString() ?? '0', //performance
      allIndiaBestPerformace['enquiriesCount']?.toString() ??
          '0', //allIndiaRank
      dealershipRank['enquiriesRank']?.toString() ?? '0', //
      currentAllIndiaRank['enquiriesRank']?.toString() ?? '0', //dealershiprank
    ]);

    // Add Lost Enquiries row
    data.add([
      'Lost Enquiries',
      performanceCount['lostEnq']?.toString() ?? '0', //performance
      allIndiaBestPerformace['lostEnquiriesCount']?.toString() ??
          '0', //allIndiaRank
      dealershipRank['lostEnquiriesRank']?.toString() ?? '0', //
      currentAllIndiaRank['lostEnquiriesRank']?.toString() ??
          '0', //dealershiprank
    ]);

    // Add Test drives row
    data.add([
      'U-Test Drives',
      performanceCount['testDriveData']?.toString() ?? '0', //performance
      allIndiaBestPerformace['testDrivesCount']?.toString() ??
          '0', //allIndiaRank
      dealershipRank['testDrivesRank']?.toString() ?? '0', //
      currentAllIndiaRank['testDrivesRank']?.toString() ?? '0', //dealershiprank
    ]);

    // Add New Orders row
    data.add([
      'New Orders',
      performanceCount['orders']?.toString() ?? '0', //performance
      allIndiaBestPerformace['newOrdersCount']?.toString() ??
          '0', //allIndiaRank
      dealershipRank['newOrdersRank']?.toString() ?? '0', //
      currentAllIndiaRank['newOrdersRank']?.toString() ?? '0', //dealershiprank
    ]);

    // Add Cancellations row
    data.add([
      'Cancellations',
      performanceCount['dealerCancellation']?.toString() ?? '0', //performance
      allIndiaBestPerformace['cancellationsCount']?.toString() ??
          '0', //allIndiaRank
      dealershipRank['cancellationsRank']?.toString() ?? '0', //
      currentAllIndiaRank['cancellationsRank']?.toString() ??
          '0', //dealershiprank
    ]);

    data.add([
      'Net Orders',
      performanceCount['net_orders']?.toString() ?? '0', //performance
      allIndiaBestPerformace['netOrdersCount']?.toString() ??
          '0', //allIndiaRank
      dealershipRank['netOrdersRank']?.toString() ?? '0', //
      currentAllIndiaRank['netOrdersRank']?.toString() ?? '0', //dealershiprank
    ]);
    // Add Retail row
    data.add([
      'Retail',
      performanceCount['retail']?.toString() ?? '0', //performance
      allIndiaBestPerformace['retailCount']?.toString() ?? '0', //allIndiaRank
      dealershipRank['retailRank']?.toString() ?? '0', //
      currentAllIndiaRank['retailRank']?.toString() ?? '0', //dealershiprank
    ]);

    return data;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 0),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black.withOpacity(.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeaderRow(screenWidth),

            _isLoading ? _buildSkeletonLoader() : const SizedBox(height: 5),
            // _isLoading ? _buildAnalyticsTable() : _buildSkeletonLoader(),
            _buildAnalyticsTable(),
            // _buildPeriodToggle(),
          ],
        ),
      ),

      // child: _buildSkeletonLoader()),
    );
  }

  Widget _buildAnalyticsTable() {
    double screenWidth = MediaQuery.of(context).size.width;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 0.5,
        ),
        verticalInside: BorderSide.none,
      ),
      columnWidths: {
        0: FixedColumnWidth(screenWidth * 0.3), // Metric
        1: FixedColumnWidth(screenWidth * 0.15), // My
        2: FixedColumnWidth(screenWidth * 0.15), // All India Best
        3: FixedColumnWidth(screenWidth * 0.15), // Dealership
        4: FixedColumnWidth(screenWidth * 0.15), // All India
      },
      children: [...tableData.map((row) => _buildTableRow(row)).toList()],
    );
  }

  // Widget _buildHeaderRow(double screenWidth) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       // MTD, QTD, YTD toggle buttons
  //       Container(
  //         width: screenWidth * 0.30,
  //         height: screenWidth * 0.06,
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey, width: .5),
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(30),
  //         ),
  //         child: Row(
  //           children: [
  //             _buildButton('MTD', 1),
  //             _buildButton('QTD', 0),
  //             _buildButton('YTD', 2),
  //           ],
  //         ),
  //       ),
  //       // Performance and Rank headers
  //       Expanded(
  //         child: Column(
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 // Performance Column
  //                 Column(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       'Performance',
  //                       style: AppFont.mediumText14(
  //                         context,
  //                       ).copyWith(fontWeight: FontWeight.w400),
  //                     ),
  //                     // const SizedBox(height: 8),
  //                   ],
  //                 ),

  //                 // Rank Column
  //                 Column(
  //                   children: [
  //                     Text('Rank', style: AppFont.mediumText14(context)),
  //                     // const SizedBox(height: 8),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildHeaderRow(double screenWidth) {
    return Row(
      children: [
        Container(
          width: screenWidth * 0.30,
          height: screenWidth * 0.06,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: .5),
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              _buildButton('MTD', 1),
              _buildButton('QTD', 0),
              _buildButton('YTD', 2),
            ],
          ),
        ),
        // const SizedBox(width: 10),

        // Headers section: Performance / Rank + Sub-columns
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance / Rank section titles
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Performance',
                        style: AppFont.mediumText14(
                          context,
                        ).copyWith(fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height:
                        30, // Match height of both header rows for consistent divider
                    color: Colors.grey.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(left: 9.0),
                      child: Text(
                        'Rank',
                        style: AppFont.mediumText14(
                          context,
                        ).copyWith(fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Sub headers: My, All India Best, Dealership, All India
              Row(
                children: [
                  Expanded(flex: 1, child: _buildHeaderCell('My')),
                  Expanded(flex: 1, child: _buildHeaderCell('All India Best')),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Expanded(flex: 1, child: _buildHeaderCell('Dealership')),
                  Expanded(flex: 1, child: _buildHeaderCell('All India')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build individual column header cells
  Widget _buildHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      // padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 7),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(List<String> values) {
    return TableRow(
      children: values.asMap().entries.map((entry) {
        int index = entry.key;
        String value = entry.value;

        return Container(
          decoration:
              index ==
                  2 // Divider after 2nd column (My, All India Best)
              ? BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                )
              : null,
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
          child: Text(
            value,
            style: AppFont.smallText(context),
            textAlign: index == 0 ? TextAlign.left : TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton(String text, int index) {
    bool isSelected = _childButtonIndex == index;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
        child: TextButton(
          onPressed: () {
            setState(() {
              _childButtonIndex = index;
              _fetchDashboardData(); // Reload data when period changes
            });
          },
          style: TextButton.styleFrom(
            alignment: Alignment.center,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            backgroundColor: isSelected
                ? AppColors.colorsBlue
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: List.generate(7, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.3,
                  height: 16.0,
                  color: AppColors.backgroundLightGrey,
                ),
                const SizedBox(width: 10),
                Container(
                  width: screenWidth * 0.55,
                  height: 16.0,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
