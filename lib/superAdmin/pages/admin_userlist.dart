import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/admin_is_manager.dart';
import 'package:smartassist/utils/admin_bottomnavigation.dart';

class AdminUserlist extends StatefulWidget {
  final Map<String, dynamic> dealer;
  final List<Map<String, dynamic>> users;
  // final List<Map<String, dynamic>> activeUser;
  final int activeUser;
  final int inactiveUser;
  const AdminUserlist({
    super.key,
    required this.dealer,
    required this.users,
    required this.activeUser,
    required this.inactiveUser,
  });

  @override
  State<AdminUserlist> createState() => _AdminUserlistState();
}

class _AdminUserlistState extends State<AdminUserlist> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredUsers = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    filteredUsers = List.from(widget.users);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(widget.users);
      } else {
        filteredUsers = widget.users.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final role = (user['user_role'] ?? '').toString().toLowerCase();
          final userId = (user['user_id'] ?? '').toString().toLowerCase();

          return name.contains(query) ||
              email.contains(query) ||
              role.contains(query) ||
              userId.contains(query);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      filteredUsers = List.from(widget.users);
      isSearching = false;
    });
  }

  void _onUserSelected(Map<String, dynamic> user) async {
    // Save the admin ID and role
    await AdminUserIdManager.saveAdminUserId(user['user_id']);
    await AdminUserIdManager.saveAdminRole(user['user_role']);
    await AdminUserIdManager.saveAdminName(user['name']);
    // Navigate to AdminBottomnavigation
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBottomnavigation(role: user['user_role']),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            isSearching = value.isNotEmpty;
          });
        },
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          filled: true,
          fillColor: AppColors.searchBar,
          hintText: 'Search users by name, email, or role...',
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

  Widget _buildUserStats() {
    final totalUsers = widget.users.length;
    final activeUser = widget.activeUser;
    final filteredCount = filteredUsers.length;
    final showingText = isSearching
        ? 'Showing $filteredCount of $activeUser users'
        : '$totalUsers users found';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dealer['dealer_name'] ?? 'Unknown Dealer',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  showingText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sideGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activeUser.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.sideGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user, bool isLast) {
    // final inactiveUser = widget.inactiveUser;
    return InkWell(
      onTap: () => _onUserSelected(user),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // color: AppColors.colorsBlue.withOpacity(0.1),
                color: (user['status']?.toString().toLowerCase() == 'inactive')
                    ? AppColors.iconGrey.withOpacity(0.1)
                    : AppColors.sideGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  (user['user_role'] ?? 'U').toString().toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // color: AppColors.colorsBlue,
                    color:
                        (user['status']?.toString().toLowerCase() == 'inactive')
                        ? AppColors.iconGrey
                        : AppColors.sideGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Unknown User',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? 'No email',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getRoleColor(dynamic role) {
    final roleStr = (role ?? '').toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      case 'user':
        return AppColors.colorsBlue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.person_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No users found' : 'No users available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorsBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Clear Search',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.colorsBlue,
        title: Text('Users', style: AppFont.appbarfontWhite(context)),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // User stats
          _buildUserStats(),

          // Users list
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserListItem(
                        user,
                        index == filteredUsers.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
