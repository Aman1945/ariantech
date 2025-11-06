import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedButtonIndex = 0;
  List<dynamic> notifications = [];
  Map<String, DateTime> arrivalTimes = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  final Map<String, String> categoryMap = {
    'All': 'All',
    'Leads': 'leads',
    'Followups': 'followups',
    'Appointments': 'appointment',
    'Test drives': 'test%20drive',
  };

  final List<String> categories = [
    'All',
    'Leads',
    'Followups',
    'Appointments',
    'Test drives',
  ];

  Future<void> _fetchNotifications({String? category}) async {
    try {
      setState(() {
        _isLoading = true; // Add loading state if you have it
      });

      final result = await LeadsSrv.fetchNotifications(category: category);

      if (result['success'] == true) {
        List<dynamic> list = result['data'];

        // Initialize arrival times
        await _initArrivalTimes(list);

        // Sort by arrival time descending (latest first)
        list.sort((a, b) {
          final idA = a['notification_id'];
          final idB = b['notification_id'];
          final dtA = arrivalTimes[idA] ?? DateTime.now();
          final dtB = arrivalTimes[idB] ?? DateTime.now();
          return dtB.compareTo(dtA); // Descending order
        });

        setState(() {
          notifications = list;
          _isLoading = false;
        });

        print('✅ Loaded ${list.length} notifications');
        print(
          '📊 Unread: ${result['unread_count']}, Read: ${result['read_count']}',
        );
      } else {
        setState(() {
          notifications = [];
          _isLoading = false;
        });
        print('❌ Failed to fetch notifications: ${result['message']}');

        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        notifications = [];
        _isLoading = false;
      });
      print('❌ Error in _fetchNotifications: $e');
      showErrorMessageGetx(message: 'Something went wrong. Please try again.');
    }
  }

  // Future<void> _fetchNotifications({String? category}) async {
  //   final token = await Storage.getToken();
  //   String url = ' ';
  //   if (category != null && category != 'All') {
  //     final mapped = categoryMap[category];
  //     if (mapped != null && mapped != 'All') {
  //       url += '?category=$mapped';
  //     }
  //   }

  //   try {
  //     final resp = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //     if (resp.statusCode == 200) {
  //       print(url);
  //       final data = json.decode(resp.body) as Map<String, dynamic>;
  //       List<dynamic> list = [];
  //       if (data['data']['unread']?['rows'] != null) {
  //         list.addAll(data['data']['unread']['rows']);
  //       }
  //       if (data['data']['read']?['rows'] != null) {
  //         list.addAll(data['data']['read']['rows']);
  //       }
  //       await _initArrivalTimes(list);

  //       // Sort by arrival time descending (latest first)
  //       list.sort((a, b) {
  //         final idA = a['notification_id'];
  //         final idB = b['notification_id'];
  //         final dtA = arrivalTimes[idA] ?? DateTime.now();
  //         final dtB = arrivalTimes[idB] ?? DateTime.now();
  //         return dtB.compareTo(dtA); // Descending order
  //       });

  //       setState(() => notifications = list);
  //     } else {
  //       print('Fetch failed ${resp.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetch: $e');
  //   }
  // }

  Future<void> _initArrivalTimes(List<dynamic> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    for (var n in notifs) {
      final id = n['notification_id'];
      final key = 'notif_arrival_$id';
      if (!prefs.containsKey(key)) {
        await prefs.setString(key, DateTime.now().toIso8601String());
      }
      arrivalTimes[id] = DateTime.parse(prefs.getString(key)!);
    }
  }

  Future<void> markAsRead(String id) async {
    final token = await Storage.getToken();
    final url = 'https://api.smartassistapp.in/api/users/notifications/$id';
    try {
      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'read': true}),
      );
      if (resp.statusCode == 200) {
        setState(() {
          notifications.removeWhere((n) => n['notification_id'] == id);
        });
      } else {
        print('Mark read failed ${resp.statusCode}');
      }
    } catch (e) {
      print('Error mark read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await Storage.getToken();
    final url =
        'https://api.smartassistapp.in/api/users/notifications/read/all';
    try {
      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'read': true}),
      );
      if (resp.statusCode == 200) {
        await _fetchNotifications(category: categories[_selectedButtonIndex]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'All notifications marked as read',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to mark all as read',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error occurred while marking notifications as read',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildButton(String name, int idx) {
    return Container(
      height: MediaQuery.of(context).size.height * .034,
      decoration: BoxDecoration(
        border: _selectedButtonIndex == idx
            ? Border.all(color: AppColors.colorsBlue)
            : Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xffF3F9FF),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          setState(() => _selectedButtonIndex = idx);
          _fetchNotifications(category: categories[idx]);
        },
        child: Text(
          name,
          style: GoogleFonts.poppins(
            color: _selectedButtonIndex == idx
                ? AppColors.colorsBlue
                : AppColors.fontColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BottomNavigation()),
            );
          },
          icon: const Icon(FontAwesomeIcons.angleLeft, color: Colors.white),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColors.colorsBlue,
        actions: [
          IconButton(
            onPressed: () async {
              final has = notifications.any((n) => n['read'] == false);
              if (!has) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Nothing to read',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: const Color.fromARGB(255, 132, 132, 132),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  title: Text(
                    'Mark all as read?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    'Are you sure you want to mark all notifications as read?',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('No', style: GoogleFonts.poppins()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Yes', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              );
              if (confirm == true) await markAllAsRead();
            },
            icon: const Icon(Icons.done_all, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: categories
                .asMap()
                .entries
                .map((e) => _buildButton(e.value, e.key))
                .toList(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 5, 0, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notification',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.fontColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notifications
                  .where((n) => n['read'] == false)
                  .toList()
                  .length,
              itemBuilder: (ctx, i) {
                final notif = notifications
                    .where((n) => n['read'] == false)
                    .toList()[i];
                final id = notif['notification_id'];
                final isRead = notif['read'] ?? false;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GestureDetector(
                        onTap: () async {
                          if (!isRead) await markAsRead(id);
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowupsDetails(
                                leadId: notif['recordId'] ?? '',
                                isFromFreshlead: false,
                                isFromManager: false,
                                spId: '',
                                isFromTestdriveOverview: false,
                                refreshDashboard: () async {},
                              ),
                            ),
                          );
                          if (res == true) {
                            _fetchNotifications(
                              category: categories[_selectedButtonIndex],
                            );
                          }
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          leading: Icon(
                            Icons.circle,
                            color: isRead ? Colors.grey : AppColors.colorsBlue,
                            size: 10,
                          ),
                          title: Text(
                            notif['title'] ?? 'No Title',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            notif['body'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      thickness: 0.1,
                      color: Colors.black,
                      indent: 10,
                      endIndent: 10,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
