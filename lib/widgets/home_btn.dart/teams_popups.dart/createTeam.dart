import 'dart:convert';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';

class Createteam extends StatefulWidget {
  const Createteam({super.key});

  @override
  State<Createteam> createState() => _CreateteamState();
}

class _CreateteamState extends State<Createteam> {
  bool _isLoadingAssignee = false;
  String? spId;
  String _assigneeQuery = '';
  List<dynamic> _searchResultsAssignee = [];
  String? selectedAssigneName;
  String? selectedAssigne;
  String? selectedAssigneEmail;

  @override
  void initState() {
    super.initState();
    // _searchController
    //     .addListener(_onSearchChanged); // Initialize speech recognition
    // _speech = stt.SpeechToText();
    _searchControllerAssignee.addListener(_onAssigneeSearchChanged);

    // _initSpeech();
  }

  void _onAssigneeSearchChanged() {
    final newQuery = _searchControllerAssignee.text.trim();
    if (newQuery == _assigneeQuery) return;

    _assigneeQuery = newQuery;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_assigneeQuery == _searchControllerAssignee.text.trim()) {
        _fetchAssigneeSearchResults(_assigneeQuery);
      }
    });
  }

  final TextEditingController _searchControllerAssignee =
      TextEditingController();

  Future<void> _fetchAssigneeSearchResults(String query) async {
    print(
      "Inside _fetchAssigneeSearchResults with query: '$query'",
    ); // Debug print

    if (query.isEmpty) {
      setState(() {
        _searchResultsAssignee.clear();
      });
      return;
    }

    setState(() {
      _isLoadingAssignee = true;
    });

    try {
      final token = await Storage.getToken();
      print(
        "Token retrieved: ${token != null ? 'Yes' : 'No'}",
      ); // Debug token presence

      final apiUrl =
          'https://api.smartassistapp.in/api/search/users?user=$query';
      print("API URL: $apiUrl"); // Debug URL

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        "API Response status: ${response.statusCode}",
      ); // Debug response code
      print("API Response body: ${response.body}"); // Debug response data

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          // _searchResultsAssignee = data['data']['suggestions'] ?? [];
          _searchResultsAssignee = data['data']['results'] ?? [];

          print(
            "Search results loaded: ${_searchResultsAssignee.length}",
          ); // Debug results
        });
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        showErrorMessage(context, message: 'API Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception during API call: $e"); // Debug exception
      showErrorMessage(context, message: 'Something went wrong..! $e');
    } finally {
      setState(() {
        _isLoadingAssignee = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Team', style: AppFont.popupTitleBlack(context)),
              ],
            ),
            const SizedBox(height: 10),
            _buildAssigneSearch(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      textAlign: TextAlign.center,
                      style: AppFont.buttons(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.colorsBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: // _submit,,
                        () {},
                    child: Text("Create", style: AppFont.buttons(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Assignee', style: AppFont.dropDowmLabel(context)),
        const SizedBox(height: 10),
        Container(
          height: MediaQuery.of(context).size.height * 0.055,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.containerBg,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchControllerAssignee,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.containerBg,
                    hintText: selectedAssigneName ?? 'Select Assignee',
                    hintStyle: TextStyle(
                      color: selectedAssigneName != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 15,
                      color: AppColors.fontColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  onTap: () {
                    // If there is a selected lead, populate the text field with its name
                    if (selectedAssigneName != null &&
                        _searchControllerAssignee.text.isEmpty) {
                      _searchControllerAssignee.text = selectedAssigneName!;
                      _searchControllerAssignee.selection =
                          TextSelection.fromPosition(
                            TextPosition(
                              offset: _searchControllerAssignee.text.length,
                            ),
                          );
                    }
                  },
                  onChanged: (value) {
                    print("TextField onChanged: '$value'"); // Additional debug
                  },
                ),
              ),
            ],
          ),
        ),

        // Show loading indicator
        if (_isLoadingAssignee)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Show search results
        if (_searchResultsAssignee.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResultsAssignee.length,
              itemBuilder: (context, index) {
                final result = _searchResultsAssignee[index];
                return ListTile(
                  onTap: () {
                    setState(() {
                      FocusScope.of(context).unfocus();
                      spId = result['user_id'];
                      selectedAssigne = result['user_id'];
                      selectedAssigneName = result['name'];
                      selectedAssigneEmail = result['email'];

                      _searchControllerAssignee.clear();
                      _searchResultsAssignee.clear();
                    });
                  },
                  title: Text(
                    result['name'] ?? 'No Name',
                    style: GoogleFonts.poppins(
                      color: selectedAssigne == result['user_id']
                          ? Colors.black
                          : AppColors.fontBlack,
                    ),
                  ),
                  subtitle: Text(
                    result['email'] ?? 'No Email',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: selectedAssigne == result['user_id']
                          ? Colors.black
                          : AppColors.fontBlack,
                    ),
                  ),
                  leading: const Icon(Icons.person),
                );
              },
            ),
          ),
      ],
    );
  }
}
