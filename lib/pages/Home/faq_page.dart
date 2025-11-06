import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  int? expandedIndex;
  static const String emailSupport =
      'support.smartassist@ariantechsolutions.com';

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

  final List<Map<String, String>> faqData = [
    {
      'question': 'How to start test drive?',
      'answer':
          ' 1. Schedule a drive for respective customer from the "Global add button" or from the Enquiry details page\n 2. Initiate the test drive from sliding the card of the test drive on dashboard or more test drives or lead history page.\n 3. Verify the OTP, initiate drive, end drive & submit feedback to complete your test drive.',
    },
    {
      'question': 'Customer not receiving OTP?',
      'answer':
          'Ask the customer to check their Email, if still not received proceed with the drive and edit the record later. Never let the customer wait 😊',
    },
    {
      'question': 'Enquiry not visible in Smart Assist?',
      'answer':
          'Check for the enquiry in CXP & share the details with support team. Make sure it was not reassigned to you directly from CXP.',
    },
    {
      'question': 'Unable to access WhatsApp?',
      'answer':
          'Check internet connection. Be patient it takes a while for the chats to load. ',
    },
    {
      'question': 'Unable to punch enquiry, shows already exist?',
      'answer':
          'Enquiry already lost by another PS? Ask your manager to reassign it to you if you are confident enough to pull the customer off.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(FontAwesomeIcons.angleLeft, color: Colors.white),
        ),
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.colorsBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.colorsBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  const Icon(
                    FontAwesomeIcons.circleQuestion,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How can we help you?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to common questions below',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // FAQ List
            ListView.builder(
              shrinkWrap: true, // important
              physics:
                  const NeverScrollableScrollPhysics(), // disable inner scroll
              padding: const EdgeInsets.all(20),
              itemCount: faqData.length,
              itemBuilder: (context, index) {
                final isExpanded = expandedIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isExpanded
                          ? AppColors.colorsBlue
                          : Colors.grey.withOpacity(0.2),
                      width: isExpanded ? 1.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          20,
                        ),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        iconColor: AppColors.colorsBlue,
                        collapsedIconColor: Colors.grey.shade600,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            expandedIndex = expanded ? index : null;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? AppColors.colorsBlue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            FontAwesomeIcons.circleQuestion,
                            color: isExpanded
                                ? AppColors.colorsBlue
                                : Colors.grey.shade600,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          faqData[index]['question']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isExpanded
                                ? AppColors.colorsBlue
                                : Colors.grey.shade800,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              faqData[index]['answer']!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Contact Us Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.colorsBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.colorsBlue, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      "Still facing issues?",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colorsBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Contact us and we’ll be happy to help you.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _launchEmail(emailSupport);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.colorsBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Contact Us",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // body: Column(
      //   children: [
      //     // Header Section
      //     Container(
      //       width: double.infinity,
      //       decoration: BoxDecoration(
      //         color: AppColors.colorsBlue,
      //         borderRadius: const BorderRadius.only(
      //           bottomLeft: Radius.circular(24),
      //           bottomRight: Radius.circular(24),
      //         ),
      //       ),
      //       padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      //       child: Column(
      //         children: [
      //           const Icon(
      //             FontAwesomeIcons.circleQuestion,
      //             color: Colors.white,
      //             size: 48,
      //           ),
      //           const SizedBox(height: 12),
      //           Text(
      //             'How can we help you?',
      //             style: GoogleFonts.poppins(
      //               color: Colors.white,
      //               fontSize: 20,
      //               fontWeight: FontWeight.w600,
      //             ),
      //           ),
      //           const SizedBox(height: 8),
      //           Text(
      //             'Find answers to common questions below',
      //             style: GoogleFonts.poppins(
      //               color: Colors.white.withOpacity(0.9),
      //               fontSize: 14,
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),

      //     // FAQ List
      //     Expanded(
      //       child: ListView.builder(
      //         padding: const EdgeInsets.all(20),
      //         itemCount: faqData.length,
      //         itemBuilder: (context, index) {
      //           final isExpanded = expandedIndex == index;

      //           return Container(
      //             margin: const EdgeInsets.only(bottom: 12),
      //             decoration: BoxDecoration(
      //               color: Colors.white,
      //               borderRadius: BorderRadius.circular(12),
      //               boxShadow: [
      //                 BoxShadow(
      //                   color: Colors.grey.withOpacity(0.1),
      //                   spreadRadius: 1,
      //                   blurRadius: 6,
      //                   offset: const Offset(0, 2),
      //                 ),
      //               ],
      //               border: Border.all(
      //                 color: isExpanded
      //                     ? AppColors.colorsBlue
      //                     : Colors.grey.withOpacity(0.2),
      //                 width: isExpanded ? 1.5 : 1,
      //               ),
      //             ),
      //             child: ClipRRect(
      //               borderRadius: BorderRadius.circular(12),
      //               child: Theme(
      //                 data: Theme.of(context).copyWith(
      //                   splashColor: Colors.transparent,
      //                   highlightColor: Colors.transparent,
      //                 ),
      //                 child: ExpansionTile(
      //                   tilePadding: const EdgeInsets.symmetric(
      //                     horizontal: 20,
      //                     vertical: 4,
      //                   ),
      //                   childrenPadding: const EdgeInsets.fromLTRB(
      //                     20,
      //                     0,
      //                     20,
      //                     20,
      //                   ),
      //                   backgroundColor: Colors.white,
      //                   collapsedBackgroundColor: Colors.white,
      //                   iconColor: AppColors.colorsBlue,
      //                   collapsedIconColor: Colors.grey.shade600,
      //                   // Remove grey ripple effect
      //                   shape: const RoundedRectangleBorder(
      //                     borderRadius: BorderRadius.zero,
      //                   ),
      //                   collapsedShape: const RoundedRectangleBorder(
      //                     borderRadius: BorderRadius.zero,
      //                   ),
      //                   onExpansionChanged: (expanded) {
      //                     setState(() {
      //                       expandedIndex = expanded ? index : null;
      //                     });
      //                   },
      //                   leading: Container(
      //                     padding: const EdgeInsets.all(8),
      //                     decoration: BoxDecoration(
      //                       color: isExpanded
      //                           ? AppColors.colorsBlue.withOpacity(0.1)
      //                           : Colors.grey.withOpacity(0.1),
      //                       borderRadius: BorderRadius.circular(8),
      //                     ),
      //                     child: Icon(
      //                       FontAwesomeIcons.circleQuestion,
      //                       color: isExpanded
      //                           ? AppColors.colorsBlue
      //                           : Colors.grey.shade600,
      //                       size: 16,
      //                     ),
      //                   ),
      //                   title: Text(
      //                     faqData[index]['question']!,
      //                     style: TextStyle(
      //                       fontWeight: FontWeight.w600,
      //                       fontSize: 16,
      //                       color: isExpanded
      //                           ? AppColors.colorsBlue
      //                           : Colors.grey.shade800,
      //                     ),
      //                   ),
      //                   children: [
      //                     Container(
      //                       width: double.infinity,
      //                       padding: const EdgeInsets.all(16),
      //                       decoration: BoxDecoration(
      //                         color: Colors.grey.shade50,
      //                         borderRadius: BorderRadius.circular(8),
      //                       ),
      //                       child: Text(
      //                         faqData[index]['answer']!,
      //                         style: TextStyle(
      //                           fontSize: 14,
      //                           height: 1.5,
      //                           color: Colors.grey.shade700,
      //                         ),
      //                       ),
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //             ),
      //           );
      //         },
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
