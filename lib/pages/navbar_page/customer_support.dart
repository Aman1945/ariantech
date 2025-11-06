import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerSupportPage extends StatelessWidget {
  const CustomerSupportPage({super.key});

  // Contact information
  static const String phoneNumberSupport = '+918788761660';
  static const String phoneNumberTechnical = '+918652203837';
  static const String emailSupport =
      'support.smartassist@ariantechsolutions.com';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with gradient
          SliverAppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(
                  Icons.keyboard_arrow_left_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            expandedHeight: screenHeight * 0.25,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.colorsBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.colorsBlue,
                      AppColors.colorsBlue.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Customer Support',
                        style: AppFont.popupTitleWhite(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'re here to help you..',
                        style: AppFont.appbarfontWhite(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Quick Actions Header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Get in Touch',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Contact Cards Grid
                  _buildModernContactCard(
                    context,
                    icon: Icons.phone_in_talk,
                    title: 'Call Support',
                    subtitle: 'Speak with our experts',
                    details: phoneNumberSupport,
                    onTap: () => _launchPhone(phoneNumberSupport),
                    gradientColors: [
                      AppColors.colorsBlue,
                      AppColors.colorsBlue.withOpacity(0.2),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildModernContactCard(
                    context,
                    icon: Icons.engineering,
                    title: 'Technical Help',
                    subtitle: 'Get technical assistance',
                    details: phoneNumberTechnical,
                    onTap: () => _launchPhone(phoneNumberTechnical),
                    gradientColors: [
                      AppColors.colorsBlue,
                      AppColors.colorsBlue.withOpacity(0.2),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildModernContactCard(
                    context,
                    icon: Icons.mail_outline,
                    title: 'Email Us',
                    subtitle: 'Send detailed questions',
                    details: emailSupport,
                    onTap: () => _launchEmail(emailSupport),
                    gradientColors: [
                      AppColors.colorsBlue,
                      AppColors.colorsBlue.withOpacity(0.2),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: gradientColors[0],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradientColors[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: gradientColors[0],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHoursCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Support Hours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildHourRow('Monday - Friday', '9:00 AM - 6:00 PM', true),
          _buildHourRow('Saturday', '10:00 AM - 4:00 PM', true),
          _buildHourRow('Sunday', 'Closed', false),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.colorsBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All times are in your local timezone',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.colorsBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String day, String hours, bool isOpen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hours,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.colorsBlue.withOpacity(0.1),
            AppColors.colorsBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.colorsBlue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.colorsBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.quiz, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Find quick answers to common questions',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'View FAQ',
                  Icons.help_outline,
                  () {},
                  AppColors.colorsBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Live Chat',
                  Icons.chat_bubble_outline,
                  () {},
                  const Color(0xFF00B894),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String text,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Emergency Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For urgent issues outside business hours\nCall our 24/7 emergency line',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _launchPhone('+1234567892'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: Color(0xFFFF6B6B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Call Emergency',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Launch phone dialer
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  // Launch email client with fallback options
  Future<void> _launchEmail(String email) async {
    final List<Uri> emailUris = [
      Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'Support Request',
          'body': 'Hi, I need help with...',
        },
      ),
      Uri(scheme: 'mailto', path: email),
      Uri.parse('mailto:$email'),
    ];

    bool launched = false;

    for (final emailUri in emailUris) {
      try {
        debugPrint('Trying to launch: $emailUri');
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        debugPrint('Failed with URI $emailUri: $e');
        continue;
      }
    }

    if (!launched) {
      debugPrint('All email launch methods failed');
      _showEmailFallback(email);
    }
  }

  void _showEmailFallback(String email) {
    debugPrint('Email fallback: $email');
  }
}

// import 'package:flutter/material.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:url_launcher/url_launcher.dart';

// class CustomerSupportPage extends StatelessWidget {
//   const CustomerSupportPage({Key? key}) : super(key: key);

//   // Phone numbers
//   static const String phoneNumberSupport = '+1234567890';
//   static const String phoneNumberTechnical = '+1234567891';
//   static const String emailSupport = 'support@yourcompany.com';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: AppColors.colorsBlue,
//         foregroundColor: Colors.white,
//         title: const Text(
//           'Customer Support',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//         ),
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Header Section
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: AppColors.colorsBlue.withOpacity(.1),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: AppColors.colorsBlue),
//               ),
//               child: Column(
//                 children: [
//                   Icon(
//                     Icons.headset_mic,
//                     size: 64,
//                     color: AppColors.colorsBlue,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'We\'re Here to Help!',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.colorsBlue,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Get in touch with our support team for any questions or assistance',
//                     style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 32),

//             // Contact Options
//             Text(
//               'Contact Options',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.colorsBlue,
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Phone Support Card
//             _buildContactCard(
//               icon: Icons.phone,
//               title: 'Phone Support',
//               subtitle: 'Speak directly with our support team',
//               details: phoneNumberSupport,
//               onTap: () => _launchPhone(phoneNumberSupport),
//               color: AppColors.colorsBlue,
//             ),

//             const SizedBox(height: 16),

//             // Technical Support Card
//             _buildContactCard(
//               icon: Icons.build,
//               title: 'Technical Support',
//               subtitle: 'Get help with technical issues',
//               details: phoneNumberTechnical,
//               onTap: () => _launchPhone(phoneNumberTechnical),
//               color: AppColors.colorsBlue,
//             ),

//             const SizedBox(height: 16),

//             // Email Support Card
//             _buildContactCard(
//               icon: Icons.email,
//               title: 'Email Support',
//               subtitle: 'Send us your questions via email',
//               details: emailSupport,
//               onTap: () => _launchEmail(emailSupport),
//               color: AppColors.colorsBlue,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String details,
//     required VoidCallback onTap,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 2,
//       shadowColor: AppColors.colorsBlue.withOpacity(0.1),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: color, size: 28),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade800,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       details,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios,
//                 color: Colors.grey.shade400,
//                 size: 16,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Launch phone dialer
//   Future<void> _launchPhone(String phoneNumber) async {
//     final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
//     try {
//       if (await canLaunchUrl(phoneUri)) {
//         await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
//       } else {
//         throw 'Could not launch phone dialer';
//       }
//     } catch (e) {
//       debugPrint('Error launching phone: $e');
//     }
//   }

//   // Launch email client with fallback options
//   Future<void> _launchEmail(String email) async {
//     // Try different email URI formats for better compatibility
//     final List<Uri> emailUris = [
//       // Method 1: Standard mailto with query parameters
//       Uri(
//         scheme: 'mailto',
//         path: email,
//         queryParameters: {
//           'subject': 'Support Request',
//           'body': 'Hi, I need help with...',
//         },
//       ),
//       // Method 2: Simple mailto without parameters
//       Uri(scheme: 'mailto', path: email),
//       // Method 3: mailto as string
//       Uri.parse('mailto:$email'),
//     ];

//     bool launched = false;

//     for (final emailUri in emailUris) {
//       try {
//         debugPrint('Trying to launch: $emailUri');
//         if (await canLaunchUrl(emailUri)) {
//           await launchUrl(
//             emailUri,
//             mode: LaunchMode.externalApplication, // Force external app
//           );
//           launched = true;
//           break;
//         }
//       } catch (e) {
//         debugPrint('Failed with URI $emailUri: $e');
//         continue;
//       }
//     }

//     if (!launched) {
//       debugPrint('All email launch methods failed');
//       // Show a snackbar or dialog to inform user
//       _showEmailFallback(email);
//     }
//   }

//   // Fallback method to show email address for manual copy
//   void _showEmailFallback(String email) {
//     // You can implement this to show a dialog or snackbar
//     debugPrint('Email fallback: $email');
//   }
// }
