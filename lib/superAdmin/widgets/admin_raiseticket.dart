// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:http/http.dart' as http;
// import 'package:smartassist/utils/storage.dart';
// import 'package:smartassist/services/bugReport_srv.dart';
// import 'package:http_parser/http_parser.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

// class FeedbackForm extends StatefulWidget {
//   final String userId;
//   final String userName;
//   final bool isFromSM;

//   const FeedbackForm({
//     super.key,
//     required this.userId,
//     this.isFromSM = false,
//     required this.userName,
//   });

//   @override
//   State<FeedbackForm> createState() => _FeedbackFormState();
// }

// class _FeedbackFormState extends State<FeedbackForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _feedbackController = TextEditingController();
//   final _titleController = TextEditingController();

//   String _selectedCategory = 'Login';
//   bool _isSubmitting = false;
//   List<File> _selectedFiles = [];
//   bool _isPickingFiles = false;

//   final List<String> _categories = [
//     'Login',
//     'Dashboard',
//     'Profile',
//     'Enquiries',
//     'Test drives',
//     'Follow-ups',
//     'Appointments',
//     'Call Analysis',
//     'WhatsApp',
//     'Analytics',
//     'Other',
//   ];

//   @override
//   void dispose() {
//     _feedbackController.dispose();
//     _titleController.dispose();
//     _selectedFiles.clear();
//     super.dispose();
//   }

//   // Helper methods to get responsive dimensions - moved to methods to avoid context issues
//   bool _isTablet(BuildContext context) =>
//       MediaQuery.of(context).size.width > 768;
//   bool _isSmallScreen(BuildContext context) =>
//       MediaQuery.of(context).size.width < 400;
//   double _screenWidth(BuildContext context) =>
//       MediaQuery.of(context).size.width;

//   // Responsive padding
//   EdgeInsets _responsivePadding(BuildContext context) => EdgeInsets.symmetric(
//     horizontal: _isTablet(context) ? 20 : (_isSmallScreen(context) ? 8 : 10),
//     vertical: _isTablet(context) ? 12 : 8,
//   );

//   // Responsive font sizes
//   double _titleFontSize(BuildContext context) =>
//       _isTablet(context) ? 20 : (_isSmallScreen(context) ? 16 : 18);
//   double _bodyFontSize(BuildContext context) =>
//       _isTablet(context) ? 16 : (_isSmallScreen(context) ? 12 : 14);
//   double _smallFontSize(BuildContext context) =>
//       _isTablet(context) ? 14 : (_isSmallScreen(context) ? 10 : 12);

//   Future<void> _pickFiles() async {
//     setState(() {
//       _isPickingFiles = true;
//     });

//     try {
//       final ImagePicker picker = ImagePicker();

//       // Show options dialog
//       final result = await showDialog<String>(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text(
//               'Select Media Type',
//               style: GoogleFonts.poppins(
//                 fontSize: _titleFontSize(context),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ListTile(
//                   leading: Icon(Icons.photo, color: AppColors.colorsBlue),
//                   title: Text('Photo', style: GoogleFonts.poppins()),
//                   onTap: () => Navigator.of(context).pop('image'),
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.videocam, color: AppColors.colorsBlue),
//                   title: Text('Video', style: GoogleFonts.poppins()),
//                   onTap: () => Navigator.of(context).pop('video'),
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.photo_library, color: AppColors.colorsBlue),
//                   title: Text('Multiple Photos', style: GoogleFonts.poppins()),
//                   onTap: () => Navigator.of(context).pop('multiple'),
//                 ),
//               ],
//             ),
//           );
//         },
//       );

//       if (result != null) {
//         List<XFile> pickedFiles = [];

//         switch (result) {
//           case 'image':
//             final XFile? image = await picker.pickImage(
//               source: ImageSource.gallery,
//               maxWidth: 1920,
//               maxHeight: 1080,
//               imageQuality: 85,
//             );
//             if (image != null) pickedFiles.add(image);
//             break;

//           case 'video':
//             final XFile? video = await picker.pickVideo(
//               source: ImageSource.gallery,
//               maxDuration: Duration(minutes: 5),
//             );
//             if (video != null) pickedFiles.add(video);
//             break;

//           case 'multiple':
//             pickedFiles = await picker.pickMultipleMedia(
//               maxWidth: 1920,
//               maxHeight: 1080,
//               imageQuality: 85,
//             );
//             break;
//         }

//         if (pickedFiles.isNotEmpty) {
//           // Check file size limit (10MB per file)
//           const int maxFileSize = 10 * 1024 * 1024; // 10MB
//           List<File> validFiles = [];

//           for (XFile file in pickedFiles) {
//             final fileSize = await file.length();
//             if (fileSize <= maxFileSize) {
//               validFiles.add(File(file.path));
//             } else {
//               _showErrorDialog(
//                 'File ${file.name} is too large. Maximum size is 10MB.',
//               );
//             }
//           }

//           setState(() {
//             _selectedFiles.addAll(validFiles);
//             // Limit to 5 files total
//             if (_selectedFiles.length > 5) {
//               _selectedFiles = _selectedFiles.take(5).toList();
//               _showErrorDialog(
//                 'Maximum 5 files allowed. Only first 5 files were selected.',
//               );
//             }
//           });
//         }
//       }
//     } catch (e) {
//       _showErrorDialog('Error picking files: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isPickingFiles = false;
//       });
//     }
//   }

//   void _removeFile(int index) {
//     setState(() {
//       _selectedFiles.removeAt(index);
//     });
//   }

//   String _getFileTypeIcon(String path) {
//     final extension = path.split('.').last.toLowerCase();
//     if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
//       return '📷';
//     } else if ([
//       'mp4',
//       'avi',
//       'mov',
//       'wmv',
//       'flv',
//       'webm',
//     ].contains(extension)) {
//       return '🎥';
//     }
//     return '📄';
//   }

//   String _formatFileSize(int bytes) {
//     if (bytes < 1024) return '${bytes}B';
//     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
//     return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
//   }

//   Future<void> _submitFeedback() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       final token = await Storage.getToken();

//       // Create multipart request for file upload
//       var uri = Uri.parse('https://api.smartassistapp.in/api/issues/media/upload');
//       var request = http.MultipartRequest('POST', uri);

//       // Add headers
//       request.headers['Authorization'] = 'Bearer $token';
//       request.headers['Content-Type'] = 'application/json';

//       // Add text fields
//       request.fields['userId'] = widget.userId;
//       request.fields['subject'] = _titleController.text.trim();
//       request.fields['category'] = _selectedCategory;
//       request.fields['description'] = _feedbackController.text.trim();
//       request.fields['timestamp'] = DateTime.now().toIso8601String();

//       // Add files
//       for (int i = 0; i < _selectedFiles.length; i++) {
//         final file = _selectedFiles[i];
//         final fileName = file.path.split('/').last;
//         final mimeType = fileName.contains('.mp4') || fileName.contains('.mov')
//             ? 'video/mp4'
//             : 'image/jpeg';

//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'attachments', // field name for files
//             file.path,
//             filename: fileName,
//             contentType: MediaType.parse(mimeType),
//           ),
//         );
//       }

//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         _showSuccessDialog();
//       } else {
//         _showErrorDialog('Failed to submit feedback. Please try again.');
//       }
//     } catch (e) {
//       _showErrorDialog(
//         'Network error. Please check your connection and try again.',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmitting = false;
//         });
//       }
//     }
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: Row(
//             children: [
//               Icon(
//                 Icons.check_circle,
//                 color: Colors.green,
//                 size: _isTablet(context) ? 28 : 24,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Thank You!',
//                 style: GoogleFonts.poppins(
//                   fontSize: _titleFontSize(context),
//                   fontWeight: FontWeight.w600,
//                   color: Colors.green,
//                 ),
//               ),
//             ],
//           ),
//           content: Text(
//             'Your feedback has been submitted successfully. We appreciate your input and will review it shortly.',
//             style: GoogleFonts.poppins(
//               fontSize: _bodyFontSize(context),
//               color: Colors.grey[700],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close dialog
//                 Navigator.of(context).pop(); // Go back to previous screen
//               },
//               style: TextButton.styleFrom(
//                 backgroundColor: AppColors.colorsBlue,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 padding: EdgeInsets.symmetric(
//                   horizontal: _isTablet(context) ? 24 : 16,
//                   vertical: _isTablet(context) ? 12 : 8,
//                 ),
//               ),
//               child: Text(
//                 'OK',
//                 style: TextStyle(
//                   fontSize: _bodyFontSize(context),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: Row(
//             children: [
//               Icon(
//                 Icons.error,
//                 color: Colors.red,
//                 size: _isTablet(context) ? 28 : 24,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Error',
//                 style: GoogleFonts.poppins(
//                   fontSize: _titleFontSize(context),
//                   fontWeight: FontWeight.w600,
//                   color: Colors.red,
//                 ),
//               ),
//             ],
//           ),
//           content: Text(
//             message,
//             style: GoogleFonts.poppins(
//               fontSize: _bodyFontSize(context),
//               color: Colors.grey[700],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 padding: EdgeInsets.symmetric(
//                   horizontal: _isTablet(context) ? 24 : 16,
//                   vertical: _isTablet(context) ? 12 : 8,
//                 ),
//               ),
//               child: Text(
//                 'OK',
//                 style: TextStyle(
//                   fontSize: _bodyFontSize(context),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/services/bugReport_srv.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class AdminRaiseticket extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isFromSM;

  const AdminRaiseticket({
    super.key,
    required this.userId,
    this.isFromSM = false,
    required this.userName,
  });

  @override
  State<AdminRaiseticket> createState() => _AdminRaiseticketState();
}

class _AdminRaiseticketState extends State<AdminRaiseticket> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _titleController = TextEditingController();

  String _selectedCategory = 'Login';
  bool _isSubmitting = false;
  List<File> _selectedFiles = [];
  bool _isPickingFiles = false;

  final List<String> _categories = [
    'Login',
    'Dashboard',
    'Profile',
    'Enquiries',
    'Test drives',
    'Follow-ups',
    'Appointments',
    'Call Analysis',
    'WhatsApp',
    'Analytics',
    'Other',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _titleController.dispose();
    _selectedFiles.clear();
    super.dispose();
  }

  // Helper methods to get responsive dimensions - moved to methods to avoid context issues
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Responsive padding
  EdgeInsets _responsivePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: _isTablet(context) ? 20 : (_isSmallScreen(context) ? 8 : 10),
    vertical: _isTablet(context) ? 12 : 8,
  );

  // Responsive font sizes
  double _titleFontSize(BuildContext context) =>
      _isTablet(context) ? 20 : (_isSmallScreen(context) ? 16 : 18);
  double _bodyFontSize(BuildContext context) =>
      _isTablet(context) ? 16 : (_isSmallScreen(context) ? 12 : 14);
  double _smallFontSize(BuildContext context) =>
      _isTablet(context) ? 14 : (_isSmallScreen(context) ? 10 : 12);

  Future<void> _pickFiles() async {
    print('DEBUG: Starting file picker');
    setState(() {
      _isPickingFiles = true;
    });

    try {
      final ImagePicker picker = ImagePicker();

      // Show options dialog
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select Media Type',
              style: GoogleFonts.poppins(
                fontSize: _titleFontSize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo, color: AppColors.colorsBlue),
                  title: Text('Photo', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.of(context).pop('image'),
                ),
                ListTile(
                  leading: Icon(Icons.videocam, color: AppColors.colorsBlue),
                  title: Text('Video', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.of(context).pop('video'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppColors.colorsBlue,
                  ),
                  title: Text('Multiple Photos', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.of(context).pop('multiple'),
                ),
              ],
            ),
          );
        },
      );

      print('DEBUG: User selected option: $result');

      if (result != null) {
        List<XFile> pickedFiles = [];

        switch (result) {
          case 'image':
            print('DEBUG: Picking single image');
            final XFile? image = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              maxHeight: 1080,
              imageQuality: 85,
            );
            if (image != null) {
              pickedFiles.add(image);
              print('DEBUG: Single image picked: ${image.path}');
            } else {
              print('DEBUG: No image selected');
            }
            break;

          case 'video':
            print('DEBUG: Picking single video');
            final XFile? video = await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: Duration(minutes: 5),
            );
            if (video != null) {
              pickedFiles.add(video);
              print('DEBUG: Single video picked: ${video.path}');
            } else {
              print('DEBUG: No video selected');
            }
            break;

          case 'multiple':
            print('DEBUG: Picking multiple media');
            pickedFiles = await picker.pickMultipleMedia(
              maxWidth: 1920,
              maxHeight: 1080,
              imageQuality: 85,
            );
            print('DEBUG: Multiple media picked: ${pickedFiles.length} files');
            for (var file in pickedFiles) {
              print('DEBUG: - ${file.path}');
            }
            break;
        }

        if (pickedFiles.isNotEmpty) {
          print('DEBUG: Processing ${pickedFiles.length} picked files');
          // Check file size limit (10MB per file)
          const int maxFileSize = 10 * 1024 * 1024; // 10MB
          List<File> validFiles = [];

          for (int i = 0; i < pickedFiles.length; i++) {
            XFile file = pickedFiles[i];
            print('DEBUG: Checking file $i: ${file.path}');

            try {
              final fileSize = await file.length();
              print('DEBUG: File size: ${_formatFileSize(fileSize)}');

              if (fileSize <= maxFileSize) {
                final dartFile = File(file.path);
                validFiles.add(dartFile);
                print('DEBUG: File $i added to valid files');
              } else {
                print('DEBUG: File $i too large: ${_formatFileSize(fileSize)}');
                _showErrorDialog(
                  'File ${file.name} is too large. Maximum size is 10MB.',
                );
              }
            } catch (e) {
              print('DEBUG: Error checking file $i: $e');
              _showErrorDialog('Error processing file: ${file.path}');
            }
          }

          print('DEBUG: Valid files: ${validFiles.length}');

          setState(() {
            _selectedFiles.addAll(validFiles);
            // Limit to 5 files total
            if (_selectedFiles.length > 5) {
              _selectedFiles = _selectedFiles.take(5).toList();
              print('DEBUG: Limited to 5 files');
              _showErrorDialog(
                'Maximum 5 files allowed. Only first 5 files were selected.',
              );
            }
          });

          print('DEBUG: Final selected files count: ${_selectedFiles.length}');
        } else {
          print('DEBUG: No files were picked');
        }
      } else {
        print('DEBUG: User cancelled file picker');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in file picker: $e');
      print('DEBUG: Stack trace: $stackTrace');
      _showErrorDialog('Error picking files: ${e.toString()}');
    } finally {
      setState(() {
        _isPickingFiles = false;
      });
      print('DEBUG: File picker completed');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _getFileTypeIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return '📷';
    } else if ([
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
    ].contains(extension)) {
      return '🎥';
    }
    return '📄';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Separate method to upload media files
  Future<String?> _uploadMediaFiles() async {
    if (_selectedFiles.isEmpty) {
      print('DEBUG: No files selected for upload');
      return null;
    }

    print('DEBUG: Starting media upload for ${_selectedFiles.length} files');

    try {
      final token = await Storage.getToken();
      if (token == null) {
        print('DEBUG: No token available');
        return null;
      }

      print('DEBUG: Token retrieved successfully');

      // Create multipart request for file upload
      var uri = Uri.parse(
        'https://api.smartassistapp.in/api/issues/media/upload',
      );
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      print('DEBUG: Request headers set: ${request.headers}');

      // Add files
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final fileName = file.path.split('/').last;

        print('DEBUG: Processing file $i: $fileName');
        print('DEBUG: File path: ${file.path}');
        print('DEBUG: File exists: ${await file.exists()}');

        if (await file.exists()) {
          final fileSize = await file.length();
          print('DEBUG: File size: ${_formatFileSize(fileSize)}');

          // Better MIME type detection
          final extension = fileName.split('.').last.toLowerCase();
          String mimeType;

          if (['mp4', 'mov', 'avi', 'wmv', 'flv', 'webm'].contains(extension)) {
            mimeType = 'video/$extension';
          } else if (['jpg', 'jpeg'].contains(extension)) {
            mimeType = 'image/jpeg';
          } else if (extension == 'png') {
            mimeType = 'image/png';
          } else if (extension == 'gif') {
            mimeType = 'image/gif';
          } else if (extension == 'webp') {
            mimeType = 'image/webp';
          } else {
            mimeType = 'application/octet-stream';
          }

          print('DEBUG: Detected MIME type: $mimeType');

          try {
            final multipartFile = await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            );

            request.files.add(multipartFile);
            print('DEBUG: File $i added to request successfully');
          } catch (fileError) {
            print('DEBUG: Error adding file $i to request: $fileError');
            _showErrorDialog('Error processing file: $fileName');
            return null;
          }
        } else {
          print('DEBUG: File does not exist: ${file.path}');
          _showErrorDialog('File not found: $fileName');
          return null;
        }
      }

      print(
        'DEBUG: All files processed. Total files in request: ${request.files.length}',
      );
      print('DEBUG: Request fields: ${request.fields}');
      print('DEBUG: Sending request to: $uri');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response headers: ${response.headers}');
      print('DEBUG: Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // Parse response to get media URL from the data field
          final jsonResponse = jsonDecode(responseBody);
          print('DEBUG: Parsed JSON response: $jsonResponse');

          if (jsonResponse['status'] == 200 && jsonResponse['data'] != null) {
            print(
              'DEBUG: Media upload successful. URL: ${jsonResponse['data']}',
            );
            return jsonResponse['data']; // Returns the S3 URL
          } else {
            print(
              'DEBUG: Media upload failed - API returned error: ${jsonResponse['message'] ?? 'Unknown error'}',
            );
            return null;
          }
        } catch (jsonError) {
          print('DEBUG: Error parsing JSON response: $jsonError');
          print('DEBUG: Raw response body: $responseBody');
          return null;
        }
      } else {
        print('DEBUG: Media upload failed with status ${response.statusCode}');
        print('DEBUG: Error response body: $responseBody');
        return null;
      }
    } catch (e, stackTrace) {
      print('DEBUG: Media upload error: $e');
      print('DEBUG: Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    print('DEBUG: Starting feedback submission');
    print('DEBUG: Selected files count: ${_selectedFiles.length}');
    print('DEBUG: Form data - Subject: ${_titleController.text.trim()}');
    print('DEBUG: Form data - Category: $_selectedCategory');
    print('DEBUG: Form data - Description: ${_feedbackController.text.trim()}');

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? mediaUrl;

      // First upload media files if any
      if (_selectedFiles.isNotEmpty) {
        print('DEBUG: Uploading media files...');
        mediaUrl = await _uploadMediaFiles();

        if (mediaUrl == null) {
          print('DEBUG: Media upload failed, stopping submission');
          _showErrorDialog('Failed to upload media files. Please try again.');
          return;
        }

        print('DEBUG: Media upload successful. URL: $mediaUrl');
      } else {
        print('DEBUG: No media files to upload');
      }

      // Then submit the bug report using the service
      print('DEBUG: Submitting bug report...');
      final result = await ApiService.bugReport(
        subject: _titleController.text.trim(),
        category: _selectedCategory,
        description: _feedbackController.text.trim(),
        media: mediaUrl,
      );

      print('DEBUG: Bug report API result: $result');

      if (result['success'] == true) {
        print('DEBUG: Bug report submitted successfully');
        _showSuccessDialog();
      } else {
        print('DEBUG: Bug report submission failed: ${result['error']}');
        _showErrorDialog(
          result['error'] ?? 'Failed to submit feedback. Please try again.',
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: Exception during feedback submission: $e');
      print('DEBUG: Stack trace: $stackTrace');
      _showErrorDialog(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: _isTablet(context) ? 28 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Thank You!',
                style: GoogleFonts.poppins(
                  fontSize: _titleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Text(
            'Your feedback has been submitted successfully. We appreciate your input and will review it shortly.',
            style: GoogleFonts.poppins(
              fontSize: _bodyFontSize(context),
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.colorsBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: _isTablet(context) ? 24 : 16,
                  vertical: _isTablet(context) ? 12 : 8,
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: _bodyFontSize(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: _isTablet(context) ? 28 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: _titleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: _bodyFontSize(context),
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: _isTablet(context) ? 24 : 16,
                  vertical: _isTablet(context) ? 12 : 8,
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: _bodyFontSize(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            FontAwesomeIcons.angleLeft,
            color: Colors.white,
            size: _isSmallScreen(context) ? 18 : 20,
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Raise a ticket',
            style: GoogleFonts.poppins(
              fontSize: _titleFontSize(context),
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppColors.colorsBlue,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _responsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: _isTablet(context) ? 20 : 16),

                // Header Section
                _buildHeaderSection(context),

                SizedBox(height: _isTablet(context) ? 24 : 20),

                // Title Field
                _buildTitleField(context),

                SizedBox(height: _isTablet(context) ? 20 : 16),

                // Category Selection
                _buildCategorySection(context),

                SizedBox(height: _isTablet(context) ? 20 : 16),

                // Rating Section
                // _buildRatingSection(context),
                SizedBox(height: _isTablet(context) ? 20 : 16),

                // Feedback Text Area
                _buildFeedbackField(context),

                SizedBox(height: _isTablet(context) ? 20 : 16),

                // File Upload Section
                _buildFileUploadSection(context),

                SizedBox(height: _isTablet(context) ? 20 : 16),

                // Anonymous Option
                // _buildAnonymousOption(context),
                SizedBox(height: _isTablet(context) ? 32 : 24),

                // Submit Button
                _buildSubmitButton(context),

                SizedBox(height: _isTablet(context) ? 20 : 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_isTablet(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.feedback,
                color: AppColors.colorsBlue,
                size: _isTablet(context) ? 28 : 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We Value Your Feedback',
                  style: GoogleFonts.poppins(
                    fontSize: _isTablet(context) ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Help us improve by sharing your thoughts, suggestions, or reporting any issues you\'ve encountered.',
            style: GoogleFonts.poppins(
              fontSize: _bodyFontSize(context),
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_isTablet(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        //
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: 'Subject'),

                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Brief description of your feedback...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: _bodyFontSize(context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.colorsBlue),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: _isTablet(context) ? 16 : 12,
              ),
            ),
            style: TextStyle(fontSize: _bodyFontSize(context)),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a subject';
              }
              if (value.trim().length < 5) {
                return 'Subject must be at least 5 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_isTablet(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        //
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: GoogleFonts.poppins(
              fontSize: _bodyFontSize(context),
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isTablet(context) ? 16 : 12,
                    vertical: _isTablet(context) ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.colorsBlue
                        : AppColors.backgroundLightGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.colorsBlue
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: _smallFontSize(context),
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackField(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_isTablet(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        //
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: 'Your Feedback'),

                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),
          TextFormField(
            controller: _feedbackController,
            maxLines: _isTablet(context) ? 8 : 6,
            decoration: InputDecoration(
              hintText:
                  'Please share your detailed feedback on issues faced...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: _bodyFontSize(context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.colorsBlue),
              ),
              contentPadding: EdgeInsets.all(_isTablet(context) ? 16 : 12),
            ),
            style: TextStyle(fontSize: _bodyFontSize(context)),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your feedback';
              }
              if (value.trim().length < 10) {
                return 'Feedback must be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_isTablet(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        //
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                color: AppColors.colorsBlue,
                size: _isTablet(context) ? 24 : 20,
              ),
              SizedBox(width: 8),
              Text(
                'Attachments (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: _bodyFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Add photos or videos to help explain your issue (Max 5 files, 10MB each)',
            style: GoogleFonts.poppins(
              fontSize: _smallFontSize(context),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),

          // Upload Button
          InkWell(
            onTap: _isPickingFiles ? null : _pickFiles,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: _isTablet(context) ? 16 : 12,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.colorsBlue,
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.colorsBlue.withOpacity(0.05),
              ),
              child: _isPickingFiles
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.colorsBlue,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Selecting files...',
                          style: GoogleFonts.poppins(
                            fontSize: _bodyFontSize(context),
                            color: AppColors.colorsBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.colorsBlue,
                          size: _isTablet(context) ? 24 : 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Choose Photos or Videos',
                          style: GoogleFonts.poppins(
                            fontSize: _bodyFontSize(context),
                            color: AppColors.colorsBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Selected Files List
          if (_selectedFiles.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Selected Files (${_selectedFiles.length}/5)',
              style: GoogleFonts.poppins(
                fontSize: _smallFontSize(context),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            ...List.generate(_selectedFiles.length, (index) {
              final file = _selectedFiles[index];
              final fileName = file.path.split('/').last;
              final fileSize = file.lengthSync();

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Text(
                      _getFileTypeIcon(fileName),
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: GoogleFonts.poppins(
                              fontSize: _smallFontSize(context),
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(fileSize),
                            style: GoogleFonts.poppins(
                              fontSize: _smallFontSize(context) - 1,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeFile(index),
                      icon: Icon(
                        Icons.close,
                        color: Colors.red,
                        size: _isTablet(context) ? 20 : 18,
                      ),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _isTablet(context) ? 56 : 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorsBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Submitting...',
                    style: GoogleFonts.poppins(
                      fontSize: _bodyFontSize(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Submit Feedback',
                style: GoogleFonts.poppins(
                  fontSize: _bodyFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
