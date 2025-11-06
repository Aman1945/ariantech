import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/login_steps/login_page.dart';
import 'package:smartassist/services/api_srv.dart' show LeadsSrv;
import 'package:smartassist/superAdmin/pages/admin_userlist.dart';
import 'package:smartassist/utils/admin_is_manager.dart';

class AdminDealerall extends StatefulWidget {
  const AdminDealerall({super.key});

  @override
  State<AdminDealerall> createState() => _AdminDealerallState();
}

class _AdminDealerallState extends State<AdminDealerall> {
  // Data variables
  List<Map<String, dynamic>> dealersWithUsers = [];
  // List<Map<String, dynamic>> activeUser = [];
  int activeUser = 0;
  List<Map<String, dynamic>> inactiveUser = [];
  List<Map<String, dynamic>> filteredDealers =
      []; // Add this for filtered results
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  // Loading states
  bool isDashboardLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    fetchDealer();
  }

  void onDealerTapped(Map<String, dynamic> dealer) {
    final users = List<Map<String, dynamic>>.from(dealer['Users'] ?? []);
    // final activeUser = List<Map<String, dynamic>>.from(
    //   dealer['total_active_users'] ?? [],
    // );
    final activeUser =
        int.tryParse(dealer['total_active_users']?.toString() ?? "0") ?? 0;
    final inactiveUser =
        int.tryParse(dealer['total_active_users']?.toString() ?? "0") ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserlist(
          dealer: dealer,
          users: users,
          inactiveUser: inactiveUser,
          activeUser: activeUser,
        ),
      ),
    );
  }

  Future<void> fetchDealer({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        isDashboardLoading = true;
      });
    } else {
      setState(() {
        isRefreshing = true;
      });
    }

    try {
      final data = await LeadsSrv.fetchDealer();
      if (mounted) {
        setState(() {
          dealersWithUsers = List<Map<String, dynamic>>.from(
            data['dealersWithUsers'] ?? [],
          );

          activeUser = data['total_active_users'] ?? 0;

          inactiveUser = List<Map<String, dynamic>>.from(
            data['total_inactive_users'] ?? [],
          );

          filteredDealers = List.from(dealersWithUsers);
          isDashboardLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Dashboard fetch error: $e');
      setState(() {
        isDashboardLoading = false;
        isRefreshing = false;
      });
    }
  }

  void _filterDealers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDealers = List.from(dealersWithUsers);
        isSearching = false;
      } else {
        isSearching = true;
        filteredDealers = dealersWithUsers.where((dealer) {
          final dealerName = (dealer['dealer_name'] ?? '')
              .toString()
              .toLowerCase();
          final dealerCode = (dealer['dealer_code'] ?? '')
              .toString()
              .toLowerCase();
          final dealerLocation = (dealer['dealer_location'] ?? '')
              .toString()
              .toLowerCase();
          final searchQuery = query.toLowerCase();

          // Also search in users within each dealer
          // final users = dealer['Users'] as List<dynamic>? ?? [];
          // final hasMatchingUser = users.any((user) {
          // final userName = (user['name'] ?? '').toString().toLowerCase();
          // final userEmail = (user['email'] ?? '').toString().toLowerCase();
          // final userRole = (user['user_role'] ?? '').toString().toLowerCase();
          // return userName.contains(searchQuery) ||
          //     userEmail.contains(searchQuery) ||
          //     userRole.contains(searchQuery);
          // });

          return dealerName.contains(searchQuery) ||
              dealerCode.contains(searchQuery) ||
              dealerLocation.contains(searchQuery);
          // hasMatchingUser;
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      filteredDealers = List.from(dealersWithUsers);
      isSearching = false;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterDealers, // Connect to filter function
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          filled: true,
          fillColor: AppColors.searchBar,
          hintText: 'Search dealers by name, code, location, or users...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use filteredDealers instead of dealersWithUsers for display
    final dealersToShow = filteredDealers;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.colorsBlue,
        title: Text('Dealers & Users', style: AppFont.appbarfontWhite(context)),
        actions: [
          IconButton(
            onPressed: () async {
              await AdminUserIdManager.clearAll();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LoginPage(email: '', onLoginSuccess: () {}),
                ),
              );
            },
            tooltip: "Logout",
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: isDashboardLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading dealers...'),
                ],
              ),
            )
          : Column(
              children: [
                // Search bar - moved to top
                _buildSearchBar(),

                // Stats header
                if (dealersWithUsers.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${dealersToShow.length}', // Show filtered count
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorsBlue,
                              ),
                            ),
                            Text(
                              isSearching ? 'Found' : 'Dealers',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              '${dealersToShow.fold<int>(0, (sum, dealer) => sum + ((dealer['Users'] as List?)?.length ?? 0))}',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorsBlue,
                              ),
                            ),
                            Text(
                              'Total Users',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Section header with search results info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    isSearching
                        ? 'Search results (${dealersToShow.length} dealers found)'
                        : 'Select a dealer to view users',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Dealers list - now using filtered results
                Expanded(
                  child: dealersToShow.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSearching
                                    ? Icons.search_off
                                    : Icons.store_mall_directory,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isSearching
                                    ? 'No dealers found matching "${_searchController.text}"'
                                    : 'No dealers found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (isSearching) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _clearSearch,
                                  child: Text(
                                    'Clear search',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.colorsBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => fetchDealer(isRefresh: true),
                          child: ListView.builder(
                            itemCount: dealersToShow.length,
                            itemBuilder: (context, index) {
                              final dealer = dealersToShow[index];
                              return _buildDealerListItem(
                                dealer,
                                index == dealersToShow.length - 1,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDealerListItem(Map<String, dynamic> dealer, bool isLast) {
    final userCount = (dealer['Users'] as List?)?.length ?? 0;
    // final activeUer = activeUser;
    final activeUer =
        int.tryParse(dealer['total_active_users']?.toString() ?? "0") ?? 0;

    return InkWell(
      onTap: () => onDealerTapped(dealer),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: isLast ? 16 : 8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Dealer icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.colorsBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.store, size: 28, color: AppColors.colorsBlue),
            ),
            const SizedBox(width: 16),

            // Dealer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dealer['dealer_name'] ?? 'Unknown Dealer',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Code: ${dealer['dealer_code'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$userCount users',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User count badge and arrow
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sideGreen.withOpacity(0.1),
                    // color: userCount > 0
                    //     ? AppColors.colorsBlue.withOpacity(0.1)
                    //     : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeUer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sideGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
