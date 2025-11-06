import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuListWidget extends StatefulWidget {
  const MenuListWidget({super.key});

  @override
  _MenuListWidgetState createState() => _MenuListWidgetState();
}

class _MenuListWidgetState extends State<MenuListWidget> {
  // Track expanded state for each expandable item
  Map<int, bool> expandedStates = {};

  // List of menu items with nested sub-items
  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.video_collection_outlined,
      'title': 'Introduction & Signup',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Introduction',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Introduction+%26+Signup/Introduction+(1)+(1).mp4',
        },
        {
          'title': 'Set you password for first login',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Introduction+%26+Signup/Sign-up+and+login+(2).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Dashboard',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Enquiries Analytical Reports',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Dashboard/Analytical+Reports+(9).mp4',
        },
        {
          'title': 'Test drives & Orders Analytical Reports',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Dashboard/Analytical+Reports+2+(11).mp4',
        },
        {
          'title': 'Dashboard Intro',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Dashboard/Dashboard+(5).mp4',
        },
        {
          'title': 'Global Search & Activities',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Dashboard/Global+Search+%26+Activities(6).mp4',
        },
        {
          'title': 'Take action on activities',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Dashboard/Global+Search+Activities+%26+Analytics+(7).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Enquiry',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Add New Enquiry (Customer & Vehicle details)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Add+New+Enquiry/Add+new+Enquiry+Steps+(12).mp4',
        },
        {
          'title': 'Enquiry details (how to view / take actions)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Add+New+Enquiry/Enquiry++(13).mp4',
        },
        {
          'title': 'Change enquiry stage (Qualify / Lost)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Add+New+Enquiry/Enquiry+(14).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Followups',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Add Follow ups(call,email,sms,etc.) via global button',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Add+Follow-ups/Add++followup+steps+(22).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Followups',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Follow ups (All / New)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Followups/Follow-up+workflow+Steps+(16).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_library_outlined,
      'title': 'Test Drive',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Test Drive (Create new)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Test+drive/Test+drive+steps(18).mp4',
        },
        {
          'title':
              'Test Drive cycle (capture additional details & track location)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Test+drive/Test+drive+Steps+(19).mp4',
        },
        {
          'title': 'Test Drive (Summary / Feedbacks)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Test+drive/Test+drive+steps+(20).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Appointment',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Add Appointment (New)',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Add+Appointment/Add+Appointment(24).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Calender & notifications',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Search for upcoming notifications, check for schedule',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Calender+%26+notifications/Calender+%26+Notifications(26).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_library_outlined,
      'title': 'More section',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'My Enquiries (view & edit) & My Call Analysis',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/More+section/My+Enquiries+%26+My+Call+Analysis+(28).mp4',
        },
        {
          'title': 'Favourites & Raise a tickets',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/More+section/Favourites++%26+Raise+a+tickets(29).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_collection_outlined,
      'title': 'Call logs and Watsapp Analysis',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Enquiry & Call analysis of the Enquiry',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Call+logs+and+Watsapp+Analysis/Call+logs+(32).mp4',
        },
        {
          'title': 'WatsApp Chat',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Call+logs+and+Watsapp+Analysis/Whatsapp+Chat+(31).mp4',
        },
        {
          'title': 'Watsapp Chat & Call Logs',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/Call+logs+and+Watsapp+Analysis/Whatsapp+Chat+%26+Call+Logs+(30).mp4',
        },
      ],
    },

    {
      'icon': Icons.video_library_outlined,
      'title': 'My teams',
      'hasSubItems': true,
      'subItems': [
        {
          'title': 'Select a PS to view their activities & call analysis',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/My+teams/My+teams+(34).mp4',
        },
        {
          'title': 'Team comparison',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/My+teams/My+teams+Comparison+%26+Tooltips+(37).mp4',
        },
        {
          'title': 'Call Analysis comparison',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/My+teams/My+teams+Comparison+%26+Tooltips+(38).mp4',
        },
        {
          'title': "Team's calendar & Individual Call Analysis",
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/My+teams/My+teams(35).mp4',
        },
        {
          'title': 'Reassign Enquiries',
          'url':
              'https://smartassist-media.s3.ap-south-1.amazonaws.com/tutorial/My+teams/My+teams(36).mp4',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(FontAwesomeIcons.angleLeft, color: Colors.white, size: 20),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Tutorial', style: AppFont.appbarfontWhite(context)),
        ),
        backgroundColor: AppColors.colorsBlue,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Menu Container
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: AppColors.colorsBlue.withOpacity(0.1),
                margin: EdgeInsets.only(left: 60),
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isExpanded = expandedStates[index] ?? false;

                return Column(
                  children: [
                    // Main item
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'],
                          size: 28,
                          color: AppColors.colorsBlue,
                        ),
                      ),
                      title: Text(
                        item['title'],
                        style: AppFont.dropDowmLabel(context),
                      ),
                      trailing: item['hasSubItems']
                          ? Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 24,
                              color: AppColors.colorsBlue,
                            )
                          : Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.colorsBlue.withOpacity(0.6),
                            ),
                      onTap: () {
                        if (item['hasSubItems']) {
                          setState(() {
                            expandedStates[index] = !isExpanded;
                          });
                        } else {
                          _handleNavigation(item['title'], item['url']);
                        }
                      },
                    ),

                    // Sub-items (nested list)
                    if (item['hasSubItems'] && isExpanded)
                      Container(
                        color: Colors.grey[50],
                        child: Column(
                          children: (item['subItems'] as List).map<Widget>((
                            subItem,
                          ) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 80,
                                right: 20,
                                top: 4,
                                bottom: 4,
                              ),
                              title: Text(
                                subItem['title'],
                                style: AppFont.dropDowmLabelLightcolors(
                                  context,
                                ),
                              ),
                              trailing: Icon(
                                Icons.keyboard_arrow_right_rounded,
                                size: 24,
                                color: AppColors.colorsBlue.withOpacity(0.4),
                              ),
                              onTap: () {
                                _handleNavigation(
                                  subItem['title'],
                                  subItem['url'],
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(String title, String url) async {
    print('Navigating to: $title');
    print('URL: $url');

    // Launch URL using url_launcher
    // final Uri uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }

    try {
      final Uri uri = Uri.parse(url);

      // Check if it's a video file
      if (url.endsWith('.mp4') ||
          url.endsWith('.mov') ||
          url.endsWith('.avi')) {
        // For video files, try to open in external app
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // If can't launch externally, try in app
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
      } else {
        // For other URLs (YouTube, web pages, etc.)
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open this link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // You can implement different navigation logic based on the item
    switch (title) {
      case 'Tutorial':
        // Get.to(() => BottomTutorial());
        print('Navigate to Tutorial: $url');
        break;
      case 'Call Analysis':
        print('Navigate to Call Analysis: $url');
        break;
      case 'Call Reports':
        print('Navigate to Call Reports: $url');
        break;
      case 'Performance Metrics':
        print('Navigate to Performance Metrics: $url');
        break;
      case 'Dashboard':
        print('Navigate to Dashboard: $url');
        break;
      case 'Settings':
        print('Navigate to Settings: $url');
        break;
      case 'Account Settings':
        print('Navigate to Account Settings: $url');
        break;
      case 'Privacy Settings':
        print('Navigate to Privacy Settings: $url');
        break;
      case 'Push Notifications':
        print('Navigate to Push Notifications: $url');
        break;
      case 'FAQ':
        print('Navigate to FAQ: $url');
        break;
      case 'Contact Support':
        print('Navigate to Contact Support: $url');
        break;
      case 'Version Info':
        print('Navigate to Version Info: $url');
        break;
      default:
        print('Navigate to $title: $url');
        break;
    }
  }
}
