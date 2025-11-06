import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/widgets/mobile_check_dialog.dart';

class LeadTextfield extends StatefulWidget {
  final String resions;
  final String? errorText;
  final bool isRequired;
  final ValueChanged<String> onChanged;
  final Function(String leadId, String leadName)? onLeadSelected;
  final VoidCallback? onClearSelection;

  const LeadTextfield({
    super.key,
    this.onLeadSelected,
    this.onClearSelection,
    required this.errorText,
    required this.onChanged,
    this.isRequired = false,
    required this.resions,
  });

  @override
  State<LeadTextfield> createState() => _LeadTextfieldState();
}

class _LeadTextfieldState extends State<LeadTextfield> {
  // Controllers and Focus
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSelecting = false;
  // Search state
  bool _isLoadingSearch = false;
  List<dynamic> _searchResults = [];
  bool _showResults = false;
  bool _hasSearched = false;

  // Selected lead state
  String? selectedLeads;
  String? selectedLeadsName;

  // Debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  // Error handling
  bool _isErrorShowing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showResults) {
      // Hide results when focus is lost (with small delay to allow tap on results)
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _showResults = false;
          });
        }
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Clear error state when user starts typing
    if (_isErrorShowing) {
      setState(() {
        _isErrorShowing = false;
      });
    }

    // If field is cleared and there was a selection, notify parent
    if (query.isEmpty && selectedLeadsName != null) {
      _clearSelection();
    }

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new timer for debouncing
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedLeads = null;
      selectedLeadsName = null;
      _searchResults.clear();
      _showResults = false;
      _hasSearched = false;
    });
    widget.onClearSelection?.call();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _hasSearched = false;
      });
      return;
    }

    // Don't search if it's the same as selected lead name
    if (query == selectedLeadsName) {
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _showResults = true;
    });

    try {
      final result = await LeadsSrv.globalSearch(query);

      if (!mounted) return;

      setState(() {
        _hasSearched = true;
        _isLoadingSearch = false;

        if (result['success'] == true) {
          _searchResults = result['data'] ?? [];
          _isErrorShowing = false;
        } else {
          _searchResults.clear();
          // _showSearchError(result['error'] ?? 'Search failed');
          _showSearchError('Lead not found ' ?? 'Search failed');
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSearch = false;
        _searchResults.clear();
        _hasSearched = true;
      });

      _showSearchError('Network error occurred');
      debugPrint('Search error: $e');
    }
  }

  void _showSearchError(String message) {
    if (!_isErrorShowing) {
      setState(() {
        _isErrorShowing = true;
      });

      Get.snackbar(
        'Search Error',
        message,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        onTap: (_) {
          setState(() {
            _isErrorShowing = false;
          });
        },
        isDismissible: true,
      );
    }
  }

  void _onLeadSelected(Map<String, dynamic> lead) async {
    final leadId = lead['lead_id']?.toString() ?? '';
    final leadName = lead['lead_name']?.toString() ?? '';
    final number = lead['mobile']?.toString();
    // Check if mobile number is null or empty
    if (number == null || number.isEmpty || number == 'null') {
      print('Mobile number is null/empty for lead: $leadName');

      // Reset the selecting flag
      _isSelecting = false;

      // Show mobile number dialog
      await MobileDialogHelper.showMobileDialog(
        heading: widget.resions,
        context,
        leadId: leadId,
        leadName: leadName,
      );

      return;
    }

    setState(() {
      FocusScope.of(context).unfocus();
      selectedLeads = leadId;
      selectedLeadsName = leadName;
      _searchController.text = leadName;
      _searchResults.clear();
      _showResults = false;
      _hasSearched = false;
    });

    widget.onChanged(leadName);
    widget.onLeadSelected?.call(leadId, leadName);
  }

  Widget _buildSearchResults() {
    if (!_showResults) return const SizedBox.shrink();

    if (_isLoadingSearch) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // if (_hasSearched && _searchResults.isEmpty) {
    //   return Container(
    //     margin: const EdgeInsets.only(top: 8),
    //     padding: const EdgeInsets.all(16),
    //     decoration: BoxDecoration(
    //       color: Colors.white,
    //       borderRadius: BorderRadius.circular(5),
    //       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
    //     ),
    //     child: Row(
    //       children: [
    //         Icon(
    //           FontAwesomeIcons.magnifyingGlass,
    //           size: 16,
    //           color: Colors.grey.shade600,
    //         ),
    //         const SizedBox(width: 12),
    //         Expanded(
    //           child: Text(
    //             'No leads found matching "${_searchController.text.trim()}"',
    //             style: GoogleFonts.poppins(
    //               fontSize: 14,
    //               color: Colors.grey.shade600,
    //               fontWeight: FontWeight.w400,
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   );
    // }

    if (_searchResults.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              dense: true,
              onTap: () => _onLeadSelected(result),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      result['lead_name']?.toString() ?? 'No Name',
                      style: AppFont.dropDowmLabel(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (result['PMI'] != null) ...[
                    Container(
                      width: 1,
                      height: 15,
                      color: Colors.grey.shade400,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Text(
                      result['PMI'].toString(),
                      style: AppFont.tinytext(context),
                    ),
                  ],
                ],
              ),
              subtitle: result['email'] != null
                  ? Text(
                      result['email'].toString(),
                      style: AppFont.smallText(context),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: 'Select Lead'),
                if (widget.isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.055,
          width: double.infinity,
          decoration: BoxDecoration(
            border: widget.errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : Border.all(color: Colors.grey.shade300, width: 1.0),
            borderRadius: BorderRadius.circular(5),
            color: AppColors.containerBg,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.containerBg,
                    hintText: selectedLeadsName ?? 'Type name, email or phone',
                    hintStyle: TextStyle(
                      color: selectedLeadsName != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 15,
                      color: AppColors.fontColor,
                    ),
                    suffixIcon: selectedLeadsName != null
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _clearSelection();
                            },
                            tooltip: 'Clear selection',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  onTap: () {
                    if (_searchResults.isNotEmpty) {
                      setState(() {
                        _showResults = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Error text
        // if (widget.errorText != null)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 4, left: 4),
        //     child: Text(
        //       widget.errorText!,
        //       style: TextStyle(
        //         color: Colors.red,
        //         fontSize: 12,
        //         fontWeight: FontWeight.w400,
        //       ),
        //     ),
        //   ),

        // Search results
        _buildSearchResults(),
      ],
    );
  }
}
