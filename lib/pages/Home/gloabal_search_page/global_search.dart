import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';

class GlobalSearch extends StatefulWidget {
  const GlobalSearch({super.key});

  @override
  State<GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<GlobalSearch> {
  final TextEditingController _searchController = TextEditingController();
  final PublishSubject<String> _searchSubject = PublishSubject<String>();

  List<dynamic> _searchResults = [];
  bool _isLoadingSearch = false;
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _setupSearchStream();
  }

  void _setupSearchStream() {
    // Setup debounced search stream
    _searchSubject
        .debounceTime(
          const Duration(milliseconds: 800),
        ) // Reduced debounce time
        .distinct() // Only emit if the value is different from the previous one
        .where((query) => query.isNotEmpty) // Only search for non-empty queries
        .listen(
          (query) => _fetchSearchResults(query),
          onError: (error) => _handleStreamError(error),
        );

    // Listen to search controller changes
    _searchController.addListener(() {
      final query = _searchController.text.trim();

      // Clear results immediately if query is empty
      if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
          _lastErrorMessage = null;
        });
        return;
      }

      // Clear previous error when user starts typing
      if (_lastErrorMessage != null) {
        setState(() {
          _lastErrorMessage = null;
        });
      }

      // Add query to stream
      _searchSubject.add(query);
    });
  }

  Future<void> _fetchSearchResults(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoadingSearch = true;
      _lastErrorMessage = null;
    });

    try {
      final token = await Storage.getToken();
      final response = await http.get(
        Uri.parse(
          'https://api.smartassistapp.in/api/search/global?query=$query',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = data['data']['suggestions'] ?? [];
        });
      } else {
        _handleApiError(data['message']?.toString() ?? 'Search failed');
      }
    } catch (e) {
      _handleApiError('Network error. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSearch = false;
        });
      }
    }
  }

  void _handleApiError(String message) {
    setState(() {
      _lastErrorMessage = message;
      _searchResults.clear();
    });

    // Show snackbar only once per error
    showErrorMessage(context, message: message);
  }

  void _handleStreamError(dynamic error) {
    debugPrint('Search stream error: $error');
    _handleApiError('Search encountered an unexpected error');
  }

  Widget _buildEmptyState() {
    if (_lastErrorMessage != null) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Search Error',
                style: AppFont.dropDowmLabel(context).copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _lastErrorMessage!,
                  textAlign: TextAlign.center,
                  style: AppFont.smallText(
                    context,
                  ).copyWith(color: Colors.red.shade600),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _lastErrorMessage = null;
                  });
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    _fetchSearchResults(query);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: AppFont.dropDowmLabel(context).copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Start typing to search...",
              style: AppFont.dropDowmLabel(
                context,
              ).copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: IconButton(
            icon: const Icon(Icons.close, size: 30, weight: 100),
            onPressed: () => Get.back(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * .8,
              height: MediaQuery.of(context).size.height * .05,
              child: TextField(
                autofocus: true,
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  filled: true,
                  fillColor: AppColors.searchBar,
                  hintText: 'Search leads...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _isLoadingSearch
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            FontAwesomeIcons.magnifyingGlass,
                            color: AppColors.fontColor,
                            size: 15,
                          ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _searchResults.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    onTap: () {
                      Get.to(
                        () => FollowupsDetails(
                          leadId: result['lead_id'],
                          isFromFreshlead: false,
                          isFromManager: false,
                          spId: '',
                          isFromTestdriveOverview: false,
                          refreshDashboard: () async {},
                        ),
                      );
                    },
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            result['lead_name'] ?? 'No Name',
                            style: AppFont.dropDowmLabel(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 15,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            result['PMI'] ?? 'Discovery Sport',
                            style: AppFont.tinytext(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      result['email'] ?? 'No Email',
                      style: AppFont.smallText(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.containerBg,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.trending_up,
                          color: AppColors.iconGrey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }
}

// import 'dart:convert';
// // import 'dart:ffi';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
// import 'package:smartassist/utils/snackbar_helper.dart';
// import 'package:smartassist/utils/storage.dart';

// class GlobalSearch extends StatefulWidget {
//   const GlobalSearch({super.key});

//   @override
//   State<GlobalSearch> createState() => _GlobalSearchState();
// }

// class _GlobalSearchState extends State<GlobalSearch> {
//   final TextEditingController _searchController = TextEditingController();
//   List<dynamic> _searchResults = [];
//   bool _isLoadingSearch = false;
//   String _query = '';
//   bool _isErrorShowing = false;

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchSearchResults(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         _searchResults.clear();
//       });
//       return;
//     }

//     setState(() {
//       _isLoadingSearch = true;
//     });

//     try {
//       final token = await Storage.getToken();
//       final response = await http.get(
//         Uri.parse(
//           'https://api.smartassistapp.in/api/search/global?query=$query',
//         ),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       final Map<String, dynamic> data = json.decode(response.body);

//       if (response.statusCode == 200) {
//         setState(() {
//           _searchResults = data['data']['suggestions'] ?? [];
//           _isErrorShowing = false;
//         });
//       } else {
//         // showErrorMessage(context, message: data['message']);
//         // Get.snackbar('Error', data['message'].toString());
//         if (!_isErrorShowing) {
//           setState(() {
//             _isErrorShowing = true;
//           });
//           Get.snackbar(
//             'Error',
//             data['message'].toString(),
//             duration: Duration(seconds: 3),
//             onTap: (_) {
//               setState(() {
//                 _isErrorShowing = false;
//               });
//             },
//             isDismissible: true,
//           );
//         }
//       }
//     } catch (e) {
//       showErrorMessage(context, message: 'Something went wrong..!');
//     } finally {
//       setState(() {
//         _isLoadingSearch = false;
//       });
//     }
//   }

//   void _onSearchChanged() {
//     final newQuery = _searchController.text.trim();
//     if (newQuery == _query) return;

//     _query = newQuery;

//     // Also clear error status when user changes search text
//     if (_isErrorShowing) {
//       setState(() {
//         _isErrorShowing = false;
//       });
//     }

//     Future.delayed(const Duration(milliseconds: 1500), () {
//       if (_query == _searchController.text.trim()) {
//         _fetchSearchResults(_query);
//       }
//     });
//   }

//   // void _onSearchChanged() {
//   //   final newQuery = _searchController.text.trim();
//   //   if (newQuery == _query) return;

//   //   _query = newQuery;
//   //   Future.delayed(const Duration(milliseconds: 1500), () {
//   //     if (_query == _searchController.text.trim()) {
//   //       _fetchSearchResults(_query);
//   //     }
//   //   });
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         titleSpacing: 10, // Removes default space between leading and title
//         leadingWidth: 40, // Reduce width of leading to keep it compact
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 5),
//           child: IconButton(
//             icon: const Icon(
//               Icons.close,
//               size: 30,
//               // weight: Double(),
//               weight: 100,
//             ),
//             onPressed: () => Get.back(),
//           ),
//         ),

//         title: Row(
//           mainAxisSize: MainAxisSize.min, // Prevents unnecessary extra space
//           children: [
//             SizedBox(
//               width:
//                   MediaQuery.of(context).size.width *
//                   .8, // Adjust width as needed
//               height: MediaQuery.of(context).size.height * .05,
//               child: TextField(
//                 autofocus: true,
//                 controller: _searchController,
//                 textAlignVertical: TextAlignVertical.center,
//                 decoration: InputDecoration(
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 15,
//                   ), // Reduce padding
//                   filled: true,
//                   fillColor: AppColors.searchBar,
//                   hintText: 'Search',
//                   hintStyle: GoogleFonts.poppins(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w300,
//                   ),
//                   prefix: const Padding(
//                     padding: EdgeInsets.only(right: 8), // Reduce icon padding
//                     child: Icon(
//                       FontAwesomeIcons.magnifyingGlass,
//                       color: AppColors.fontColor,
//                       size: 15,
//                     ),
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: _isLoadingSearch
//           ? const Center(child: CircularProgressIndicator())
//           : _searchResults.isEmpty
//           ? GestureDetector(
//               onTap: () => FocusScope.of(context).unfocus(),
//               child: Center(
//                 child: Text(
//                   "Type something...",
//                   style: AppFont.dropDowmLabel(context),
//                 ),
//               ),
//             )
//           : ListView.builder(
//               keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//               itemCount: _searchResults.length,
//               itemBuilder: (context, index) {
//                 final result = _searchResults[index];
//                 return ListTile(
//                   onTap: () {
//                     Get.to(
//                       () => FollowupsDetails(
//                         leadId: result['lead_id'],
//                         isFromFreshlead: false,
//                         isFromManager: false,

//                         isFromTestdriveOverview: false,
//                         refreshDashboard: () async {},
//                       ),
//                     );
//                   },
//                   title: Row(
//                     children: [
//                       Text(
//                         result['lead_name'] ?? 'No Name',
//                         style: AppFont.dropDowmLabel(context),
//                       ),
//                       const SizedBox(width: 5),
//                       // Divider Replacement: A Thin Line
//                       Container(
//                         width: .5, // Set width for the divider
//                         height: 15, // Make it a thin horizontal line
//                         color: Colors.black,
//                       ),
//                       const SizedBox(width: 5),
//                       Text(
//                         result['PMI'] ?? 'Discovery Sport',
//                         style: AppFont.tinytext(context),
//                       ),
//                     ],
//                   ),
//                   subtitle: Text(
//                     result['email'] ?? 'No Email',
//                     style: AppFont.smallText(context),
//                   ),
//                   leading: Container(
//                     decoration: const BoxDecoration(
//                       color: AppColors.containerBg,
//                       borderRadius: BorderRadius.all(Radius.circular(30)),
//                     ),
//                     child: const Padding(
//                       padding: EdgeInsets.all(5),
//                       child: Icon(Icons.trending_up, color: AppColors.iconGrey),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
