import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:appcheck/appcheck.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/utils/token_manager.dart';
import 'package:smartassist/widgets/reusable/whatsapp_fullscreen.dart'
    as fullscreen;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class FileProcessingData {
  final String base64Data;
  final String filePath;

  FileProcessingData({required this.base64Data, required this.filePath});
}

class Message {
  final String body;
  final bool fromMe;
  final int timestamp;
  final String type;
  final String? mediaUrl;
  final String? id;
  final Map<String, dynamic>? media;

  Message({
    required this.body,
    required this.fromMe,
    required this.timestamp,
    required this.type,
    this.mediaUrl,
    this.id,
    this.media,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    String? mediaUrl;

    // Handle media data from server with size optimization
    if (json['media'] != null && json['media']['base64'] != null) {
      final mediaData = json['media'];
      final base64Data = mediaData['base64'] as String;
      final mimeType = mediaData['mimetype'] ?? '';
      final messageType = json['type'] ?? 'chat';

      // Only create data URLs for images and only if they're reasonably sized
      if (messageType == 'image') {
        // Check if base64Data already contains data URL prefix
        if (base64Data.startsWith('data:')) {
          // It's already a complete data URL, use it directly
          mediaUrl = base64Data;
        } else {
          // It's just base64, add the data URL prefix
          // Estimate file size from base64
          final estimatedSize = (base64Data.length * 0.75).round();
          const maxDataUrlSize = 5 * 1024 * 1024; // 5MB limit for data URLs

          if (estimatedSize <= maxDataUrlSize && _isValidBase64(base64Data)) {
            try {
              // Clean the base64 string before creating data URL
              final cleanBase64 = _cleanBase64String(base64Data);
              mediaUrl = 'data:$mimeType;base64,$cleanBase64';
            } catch (e) {
              print('Error creating data URL: $e');
              mediaUrl = null;
            }
          } else {
            print('Image too large for data URL: ${estimatedSize} bytes');
            mediaUrl = null;
          }
        }
      } else {
        // For documents and other media types, don't create data URLs
        mediaUrl = null;
      }
    }

    return Message(
      body: json['body'] ?? '',
      fromMe: json['fromMe'] ?? false,
      timestamp:
          json['timestamp'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      type: json['type'] ?? 'chat',
      mediaUrl: mediaUrl ?? json['mediaUrl'],
      id: json['id'],
      media: json['media'],
    );
  }

  // Helper method to validate base64 string
  static bool _isValidBase64(String base64String) {
    try {
      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      // Check if it's valid base64
      final RegExp base64RegExp = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      return base64RegExp.hasMatch(cleanBase64.replaceAll(RegExp(r'\s'), ''));
    } catch (e) {
      return false;
    }
  }

  // Helper method to clean base64 string
  static String _cleanBase64String(String base64String) {
    String cleaned = base64String;

    // Remove data URL prefix if present
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').last;
    }

    // Remove any whitespace characters
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');

    // Ensure proper padding
    while (cleaned.length % 4 != 0) {
      cleaned += '=';
    }

    return cleaned;
  }
}

class MessageBubble extends StatefulWidget {
  final Message message;
  final String timeString;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.timeString,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.message.fromMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: widget.message.fromMe
              ? const Color.fromARGB(255, 198, 210, 248)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.message.type == 'image' &&
                widget.message.mediaUrl != null)
              fullscreen.ClickableMessageImage(
                imageUrl: widget.message.mediaUrl!,
                heroTag: widget.message.id ?? widget.message.mediaUrl,
              ),
            // Document handling
            if (widget.message.type == 'document' &&
                widget.message.media != null)
              _buildDocumentWidget(),

            if (widget.message.body.isNotEmpty)
              Text(widget.message.body, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.timeString,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                if (widget.message.fromMe) const SizedBox(width: 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentWidget() {
    final media = widget.message.media;
    final filename = media?['filename'] ?? 'Document';
    final mimetype = media?['mimetype'] ?? '';
    final base64Data = media?['base64'];

    // Get appropriate icon based on file type
    IconData getDocumentIcon(String mimetype, String filename) {
      final extension = filename.split('.').last.toLowerCase();

      switch (extension) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'xls':
        case 'xlsx':
          return Icons.table_chart;
        case 'ppt':
        case 'pptx':
          return Icons.slideshow;
        case 'txt':
          return Icons.text_snippet;
        case 'zip':
        case 'rar':
        case '7z':
          return Icons.archive;
        case 'mp3':
        case 'wav':
          return Icons.audio_file;
        case 'mp4':
        case 'avi':
        case 'mov':
          return Icons.video_file;
        default:
          return Icons.insert_drive_file;
      }
    }

    // Enhanced file size calculation with better formatting
    String getFileSize(String? base64Data) {
      if (base64Data == null) return 'Unknown size';

      final bytes = (base64Data.length * 0.75).round();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
      }
    }

    // Check if file is large
    bool isLargeFile(String? base64Data) {
      if (base64Data == null) return false;
      final bytes = (base64Data.length * 0.75).round();
      return bytes > 10 * 1024 * 1024; // 10MB threshold for warning
    }

    return GestureDetector(
      onTap: () async {
        if (isLargeFile(base64Data)) {
          // Show confirmation dialog for large files
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Large File'),
              content: Text(
                'This file is ${getFileSize(base64Data)}. '
                'Opening large files may take some time and use memory. '
                'Do you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Open'),
                ),
              ],
            ),
          );

          if (shouldProceed == true) {
            _openDocument(media);
          }
        } else {
          _openDocument(media);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getDocumentIcon(mimetype, filename),
              size: 32,
              color: AppColors.colorsBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        getFileSize(base64Data),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (isLargeFile(base64Data)) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 20, color: AppColors.colorsBlue),
          ],
        ),
      ),
    );
  }

  static Future<bool> _processLargeFileInIsolate(
    FileProcessingData data,
  ) async {
    try {
      // Decode base64 in chunks to avoid memory issues
      final bytes = await _decodeBase64InChunks(data.base64Data);

      // Write file
      final file = File(data.filePath);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('Error in isolate: $e');
      return false;
    }
  }

  // Decode base64 in chunks to handle large files
  static Future<Uint8List> _decodeBase64InChunks(String base64Data) async {
    const int chunkSize = 1024 * 1024; // 1MB chunks
    final List<int> bytes = [];

    for (int i = 0; i < base64Data.length; i += chunkSize) {
      final end = (i + chunkSize < base64Data.length)
          ? i + chunkSize
          : base64Data.length;
      final chunk = base64Data.substring(i, end);

      // Yield control back to the event loop periodically
      if (i % (chunkSize * 4) == 0) {
        await Future.delayed(Duration.zero);
      }

      try {
        final chunkBytes = base64Decode(chunk);
        bytes.addAll(chunkBytes);
      } catch (e) {
        // Handle partial chunk at the end
        if (i + chunkSize >= base64Data.length) {
          // This might be the last chunk, try to decode what we have
          try {
            final paddedChunk = _addBase64Padding(chunk);
            final chunkBytes = base64Decode(paddedChunk);
            bytes.addAll(chunkBytes);
          } catch (paddingError) {
            print('Error decoding final chunk: $paddingError');
          }
        } else {
          throw e;
        }
      }
    }

    return Uint8List.fromList(bytes);
  }

  static String _addBase64Padding(String base64) {
    final padding = 4 - (base64.length % 4);
    if (padding != 4) {
      return base64 + ('=' * padding);
    }
    return base64;
  }

  Future<void> _openDocument(Map<String, dynamic>? media) async {
    if (media == null || media['base64'] == null) {
      _showSnackBar('Document data not available', Colors.red);
      return;
    }

    try {
      // Show loading indicator
      _showLoadingDialog('Processing document...');

      // Request storage permission
      if (await _requestStoragePermission()) {
        String base64Data = media['base64'] as String;
        if (base64Data.startsWith('data:')) {
          base64Data = base64Data.split(',').last;
        }

        // Get filename and ensure it has an extension
        String filename = media['filename'] ?? 'document';
        if (!filename.contains('.')) {
          final mimetype = media['mimetype'] ?? '';
          final extension = _getExtensionFromMimeType(mimetype);
          filename = '$filename.$extension';
        }

        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$filename';

        // Check file size and process accordingly
        final estimatedSize = (base64Data.length * 0.75).round();
        const largeSizeThreshold = 5 * 1024 * 1024; // 5MB threshold

        bool success = false;

        if (estimatedSize > largeSizeThreshold) {
          // Process large files in isolate
          _updateLoadingDialog('Processing large file...');

          try {
            success = await compute(
              _processLargeFileInIsolate,
              FileProcessingData(base64Data: base64Data, filePath: filePath),
            );
          } catch (e) {
            print('Isolate processing failed, trying direct method: $e');
            success = await _processFileDirectly(base64Data, filePath);
          }
        } else {
          // Process smaller files directly
          success = await _processFileDirectly(base64Data, filePath);
        }

        // Close loading dialog
        Navigator.of(context).pop();

        if (success) {
          // Verify file exists and has content
          final file = File(filePath);
          if (await file.exists() && await file.length() > 0) {
            // Open the file
            final result = await OpenFile.open(filePath);

            if (result.type != ResultType.done) {
              _showSnackBar(
                'Could not open file: ${result.message}',
                Colors.orange,
              );
            }
          } else {
            _showSnackBar('Failed to create file', Colors.red);
          }
        } else {
          _showSnackBar('Failed to process document', Colors.red);
        }
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnackBar(
          'Storage permission required to open documents',
          Colors.red,
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error opening document: $e');
      _showSnackBar('Failed to open document: ${e.toString()}', Colors.red);
    }
  }

  // Process file directly (for smaller files or fallback)
  Future<bool> _processFileDirectly(String base64Data, String filePath) async {
    try {
      final bytes = await _decodeBase64InChunks(base64Data);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('Direct processing error: $e');
      return false;
    }
  }

  // Updated loading dialog that can be updated
  void _updateLoadingDialog(String message) {
    // You might need to implement a stateful dialog or use a different approach
    // For now, we'll just print the update
    print('Loading update: $message');
  }

  // Enhanced loading dialog with progress indication
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.colorsBlue),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 8),
            Text(
              'This may take a moment for large files',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to requ  est storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ doesn't need storage permission for temporary files
        return true;
      } else {
        // Android 12 and below
        var status = await Permission.storage.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.storage.request();
        }
        return status == PermissionStatus.granted;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't require explicit permission for temporary files
      return true;
    }
    return true;
  }

  // Helper method to get file extension from MIME type
  String _getExtensionFromMimeType(String mimetype) {
    switch (mimetype.toLowerCase()) {
      case 'application/pdf':
        return 'pdf';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      case 'application/vnd.ms-excel':
        return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'xlsx';
      case 'application/vnd.ms-powerpoint':
        return 'ppt';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return 'pptx';
      case 'text/plain':
        return 'txt';
      case 'application/zip':
        return 'zip';
      case 'application/x-rar-compressed':
        return 'rar';
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      default:
        return 'file';
    }
  }

  // Helper method to show snack bar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class WhatsappChat extends StatefulWidget {
  final String chatId;
  final String userName;

  const WhatsappChat({super.key, required this.chatId, required this.userName});

  @override
  State<WhatsappChat> createState() => _WhatsappChatState();
}

class _WhatsappChatState extends State<WhatsappChat>
    with WidgetsBindingObserver {
  List<Message> messages = [];
  bool isLoading = false;
  bool isWhatsAppLoading = false;
  String loadingMessage = '';
  String spId = '';
  String email = '';
  bool isWhatsAppReady = false;
  bool isCheckingStatus = false;
  bool isLoggedOut = false;
  bool hasInitialized = false;
  Timer? _reconnectTimer;
  Timer? _statusCheckTimer;
  Timer? _initializationTimeout;

  final ImagePicker _picker = ImagePicker();
  bool isSendingImage = false;
  bool isSendingDocument = false;

  final TextEditingController _messageController = TextEditingController();
  late IO.Socket socket;
  bool isConnected = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWithTimeout();
  }

  // Add initialization timeout to prevent infinite loading
  void _initializeWithTimeout() {
    loadInitialData();

    // Failsafe: If initialization takes too long, show connect button
    _initializationTimeout = Timer(Duration(seconds: 10), () {
      if (mounted && !hasInitialized) {
        print('Initialization timeout - showing connect button');
        setState(() {
          isCheckingStatus = false;
          isLoading = false;
          isWhatsAppLoading = false;
          isLoggedOut = true;
          hasInitialized = true;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('AppLifecycleState: $state');

    if (state == AppLifecycleState.resumed) {
      _stopReconnectTimer();

      // Quick reconnection without delay
      if (!isConnected) {
        print('App resumed, reconnecting socket');
        socket.connect();
      }

      // Check status only if we don't know the current state and have initialized
      if (hasInitialized &&
          !isWhatsAppReady &&
          !isLoggedOut &&
          !isCheckingStatus) {
        _delayedStatusCheck();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      print('App backgrounded, starting reconnect timer');
      _startReconnectTimer();
    }
  }

  void _delayedStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted && !isCheckingStatus) {
        checkWhatsAppStatus();
      }
    });
  }

  Future<void> connectWhatsApp() async {
    if (isLoading || isWhatsAppLoading) return;

    setState(() {
      isLoading = true;
      isLoggedOut = false;
      loadingMessage = 'Initializing WhatsApp connection...';
      hasInitialized = true;
    });

    try {
      final url = Uri.parse('https://api.smartassistapp.in/api/init-wa');
      final token = await Storage.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'sessionId': spId, 'email': email}),
          )
          .timeout(Duration(seconds: 20)); // Increased timeout for better UX

      print('Connect WA: ${response.statusCode} - ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['isReady'] == true) {
            // Already connected
            setState(() {
              isWhatsAppReady = true;
              isWhatsAppLoading = false;
              isLoggedOut = false;
            });
            _fetchMessages();
          } else {
            // Session starting - backend will send wa_loading_started event
            setState(() {
              isWhatsAppLoading = true;
              loadingMessage = 'Starting WhatsApp session...';
            });

            // Don't launch WhatsApp here - wait for QR event
            print('WhatsApp session initiated. Waiting for QR...');
          }
        } else {
          final errorMsg = response.statusCode == 200
              ? json.decode(response.body)['message'] ?? 'Connection failed'
              : 'Server error: ${response.statusCode}';
          _handleConnectionError(errorMsg);
        }
      }
    } catch (e) {
      print('Connect error: $e');
      if (mounted) {
        String errorMsg = 'Connection failed. Please try again.';
        if (e.toString().contains('timeout')) {
          errorMsg =
              'Connection timeout. Please check your internet connection.';
        } else if (e.toString().contains('Authentication')) {
          errorMsg = 'Please login again to continue.';
        }
        _handleConnectionError(errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _handleConnectionError(String message) {
    showErrorMessage(context, message: message);
    setState(() {
      isLoggedOut = true;
      isWhatsAppLoading = false;
      loadingMessage = '';
    });
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    int attempt = 0;

    _reconnectTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!isConnected && mounted && attempt < 5) {
        print('Reconnect attempt ${attempt + 1}');
        socket.connect();
        attempt++;
      } else {
        timer.cancel();
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _statusCheckTimer?.cancel();
    _initializationTimeout?.cancel();
  }

  Future<void> loadInitialData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      spId = prefs.getString('user_id') ?? '';
      email = await TokenManager.getUserEmail() ?? '';
      print('User ID: $spId, Email: $email');

      if (spId.isEmpty || email.isEmpty) {
        setState(() {
          isLoggedOut = true;
          isCheckingStatus = false;
          hasInitialized = true;
        });
        return;
      }

      initSocket();

      // Wait for socket connection before checking status
      await _waitForSocketConnection();
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        setState(() {
          isLoggedOut = true;
          isCheckingStatus = false;
          hasInitialized = true;
        });
      }
    }
  }

  Future<void> _waitForSocketConnection() async {
    int attempts = 0;
    const maxAttempts = 20; // 2 seconds max wait

    while (!isConnected && attempts < maxAttempts && mounted) {
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }

    if (mounted) {
      if (isConnected) {
        await checkWhatsAppStatus();
      } else {
        print('Socket connection timeout during initialization');
        setState(() {
          isLoggedOut = true;
          isCheckingStatus = false;
          hasInitialized = true;
        });
      }
    }
  }

  Future<void> checkWhatsAppStatus() async {
    if (!mounted || isCheckingStatus || !isConnected) {
      print(
        'Skipping status check - mounted: $mounted, isCheckingStatus: $isCheckingStatus, isConnected: $isConnected',
      );
      return;
    }

    setState(() {
      isCheckingStatus = true;
    });

    try {
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/check-wa-status',
      );
      final token = await Storage.getToken();

      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'sessionId': spId}),
          )
          .timeout(Duration(seconds: 8)); // Reduced timeout

      print('Status Check: ${response.statusCode} - ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final isReady = data['isReady'] ?? false;

          print('Setting states - isReady: $isReady, isLoggedOut: ${!isReady}');

          setState(() {
            isWhatsAppReady = isReady;
            isLoggedOut = !isReady;
            isCheckingStatus = false;
            hasInitialized = true;
          });

          if (isReady && isConnected) {
            _fetchMessages();
          }
        } else {
          print('Status check failed: ${response.statusCode}');
          _handleStatusCheckFailure();
        }
      }
    } catch (e) {
      print('Status check error: $e');
      if (mounted) {
        _handleStatusCheckFailure();
      }
    }
  }

  void _handleStatusCheckFailure() {
    setState(() {
      isWhatsAppReady = false;
      isLoggedOut = true;
      isCheckingStatus = false;
      hasInitialized = true;
    });
  }

  void _fetchMessages() {
    if (!isConnected || !isWhatsAppReady || isLoggedOut) return;

    socket.emit('get_messages', {'sessionId': spId, 'chatId': widget.chatId});
    print('Fetching messages for chat: ${widget.chatId}');
  }

  Future<String?> getInstalledWhatsApp() async {
    try {
      final appCheck = AppCheck();

      // Check both WhatsApp versions with individual error handling
      bool normalInstalled = false;
      bool businessInstalled = false;

      try {
        final normal = await appCheck.checkAvailability('com.whatsapp');
        normalInstalled = normal != null;
      } catch (e) {
        print("Error checking normal WhatsApp: $e");
      }

      try {
        final business = await appCheck.checkAvailability('com.whatsapp.w4b');
        businessInstalled = business != null;
      } catch (e) {
        print("Error checking business WhatsApp: $e");
      }

      if (normalInstalled && businessInstalled) {
        return 'both'; // both installed
      } else if (normalInstalled) {
        return 'personal'; // only personal
      } else if (businessInstalled) {
        return 'business'; // only business
      } else {
        return null; // none installed
      }
    } catch (e) {
      print("General error checking WhatsApp: $e");
      // As a fallback, try to launch WhatsApp directly to test if it exists
      try {
        // This is a more robust way to check if we can open WhatsApp
        return 'personal'; // Assume personal WhatsApp as default
      } catch (e2) {
        return null;
      }
    }
  }

  Future<void> _openWhatsApp(String packageName) async {
    await LaunchApp.openApp(
      androidPackageName: packageName,
      iosUrlScheme: "whatsapp://",
      appStoreLink:
          "https://play.google.com/store/apps/details?id=com.whatsapp",
    );
  }

  Future<void> initWhatsAppChat(BuildContext context) async {
    if (isWhatsAppReady || isLoading) return;

    setState(() {
      isLoading = true;
      isLoggedOut = false;
      hasInitialized = true;
    });

    try {
      final url = Uri.parse('https://api.smartassistapp.in/api/init-wa');
      final token = await Storage.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'sessionId': spId, 'email': email}),
          )
          .timeout(Duration(seconds: 15));

      print('Init WA Response: ${response.statusCode} - ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['isReady'] == true) {
            setState(() {
              isWhatsAppReady = true;
              isLoggedOut = false;
            });
            socket.emit('get_messages', {
              'sessionId': spId,
              'chatId': widget.chatId,
            });
          } else {
            await launchWhatsAppScanner();
          }
        } else {
          final errorMessage =
              json.decode(response.body)['message'] ?? 'Unknown error';
          _handleConnectionError(errorMessage);
        }
      }
    } catch (e) {
      print('Error initializing WhatsApp chat: $e');
      if (mounted) {
        // _handleConnectionError('Failed to initialize WhatsApp chat.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resendQR() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      loadingMessage = 'Generating new QR code...';
    });

    try {
      // Force new QR by reconnecting
      socket.emit('resend_qr', {'sessionId': spId, 'email': email});

      // Also call connect to restart the process
      await Future.delayed(Duration(milliseconds: 500));
      await connectWhatsApp();
    } catch (e) {
      print('Error resending QR: $e');
      if (mounted) {
        showErrorMessage(context, message: 'Failed to generate new QR code');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _scrollToBottomDelayed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> showWhatsAppPicker(BuildContext context) async {
    final type = await getInstalledWhatsApp();

    if (type == null) {
      // No WhatsApp installed - show more helpful message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "WhatsApp is not installed. Please install WhatsApp to continue.",
          ),
          action: SnackBarAction(
            label: "Install",
            onPressed: () {
              // Open Play Store to WhatsApp
              LaunchApp.openApp(
                androidPackageName: "com.whatsapp",
                appStoreLink:
                    "https://play.google.com/store/apps/details?id=com.whatsapp",
              );
            },
          ),
        ),
      );
      return;
    }

    if (type == 'both') {
      // Show bottom sheet with both options
      showModalBottomSheet(
        backgroundColor: AppColors.white,
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                // Text(
                //   "Choose WhatsApp Version",
                //   style: AppFont.appbarfontblack(context),
                // ),
                // SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildAppIcon(
                      ctx,
                      "WhatsApp",
                      "assets/whatsapp_normal.png",
                      45,
                      () => _openWhatsApp("com.whatsapp"),
                    ),
                    const SizedBox(width: 12),
                    _buildAppIcon(
                      ctx,
                      "Business",
                      "assets/whatsapp_bussiness.png",
                      45,
                      () => _openWhatsApp("com.whatsapp.w4b"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Directly open whichever is installed
      final pkg = type == 'business' ? 'com.whatsapp.w4b' : 'com.whatsapp';
      await _openWhatsApp(pkg);
    }
  }

  // Future<void> showWhatsAppPicker(BuildContext context) async {
  //   final type = await getInstalledWhatsApp();

  //   if (type == null) {
  //     // No WhatsApp installed
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("WhatsApp is not installed")));
  //     return;
  //   }

  //   if (type == 'both') {
  //     // Show bottom sheet with both options
  //     showModalBottomSheet(
  //       backgroundColor: AppColors.white,
  //       context: context,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //       ),
  //       builder: (ctx) {
  //         return Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Wrap(
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: [
  //                   _buildAppIcon(
  //                     ctx,
  //                     "WhatsApp",
  //                     "assets/whatsapp_normal.png",
  //                     45,
  //                     () => _openWhatsApp("com.whatsapp"),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   _buildAppIcon(
  //                     ctx,
  //                     "Business",
  //                     "assets/whatsapp_bussiness.png",
  //                     45,
  //                     () => _openWhatsApp("com.whatsapp.w4b"),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );
  //   } else {
  //     // Directly open whichever is installed
  //     final pkg = type == 'business' ? 'com.whatsapp.w4b' : 'com.whatsapp';
  //     await _openWhatsApp(pkg);
  //   }
  // }

  Future<void> launchWhatsAppScanner() async {
    await showWhatsAppPicker(context);
  }

  String formatTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('HH:mm');
    if (messageDate == today) {
      return timeFormat.format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${timeFormat.format(dateTime)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  void disconnectSocket() {
    _stopReconnectTimer();
    socket.disconnect();
    setState(() {
      isConnected = false;
    });
    print('Socket manually disconnected');
  }

  void initSocket() {
    socket = IO.io('wss://api.smartassistapp.in', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 3000,
      'timeout': 10000,
    });

    socket.onConnect((_) {
      print('Socket connected');
      _stopReconnectTimer();

      setState(() {
        isConnected = true;
      });

      // Register session immediately
      socket.emit('register_session', {'sessionId': spId, 'email': email});

      // Only check status after socket is connected and if not already initialized
      if (!hasInitialized) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted && isConnected) {
            checkWhatsAppStatus();
          }
        });
      } else if (isWhatsAppReady && !isLoggedOut) {
        _fetchMessages();
      }
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
      setState(() {
        isConnected = false;
      });
      if (hasInitialized) {
        _startReconnectTimer();
      }
    });

    socket.onConnectError((error) {
      print('Connection error: $error');
      setState(() {
        isConnected = false;
      });

      if (!hasInitialized && mounted) {
        setState(() {
          isLoggedOut = true;
          isCheckingStatus = false;
          hasInitialized = true;
        });
      } else {
        _startReconnectTimer();
      }
    });

    // CRITICAL: Handle wa_loading_started - this comes first
    socket.on('wa_loading_started', (data) {
      print('WA Loading Started: $data');
      if (mounted) {
        setState(() {
          isWhatsAppLoading = true;
          loadingMessage = data['message'] ?? 'Starting WhatsApp session...';
          isLoggedOut = false;
          hasInitialized = true;
        });
      }
    });

    // CRITICAL: Handle QrSend event - this triggers after loading_started
    socket.on('wa_qr_sent', (data) {
      print('QR Code Sent: $data');
      if (mounted) {
        setState(() {
          isWhatsAppLoading = true;
          loadingMessage = 'QR code sent to your email. Scan it in WhatsApp.';
          isLoggedOut = false;
          hasInitialized = true;
        });

        // Show QR instructions and launch WhatsApp
        _showQRInstructions();
      }
    });

    // Handle wa_loading (during authentication process)
    socket.on('wa_loading', (data) {
      print('WA Loading: $data');
      if (mounted) {
        setState(() {
          isWhatsAppLoading = true;
          loadingMessage = data['message'] ?? 'Preparing WhatsApp session...';
          isLoggedOut = false;
          hasInitialized = true;
        });
      }
    });

    // WhatsApp ready - authentication successful
    socket.on('wa_login_success', (data) {
      print('Login Success: $data');
      if (mounted) {
        setState(() {
          isWhatsAppReady = true;
          isWhatsAppLoading = false;
          loadingMessage = '';
          isLoggedOut = false;
          hasInitialized = true;
        });
        _fetchMessages();

        // Show success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('WhatsApp connected successfully!'),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    });

    // Handle logout properly
    socket.on('wa_logout', (data) {
      print('WA Logout: $data');
      if (mounted) {
        setState(() {
          isWhatsAppReady = false;
          isWhatsAppLoading = false;
          loadingMessage = '';
          isLoggedOut = true;
          hasInitialized = true;
          messages.clear();
        });
        showErrorMessage(
          context,
          message: data['message'] ?? 'WhatsApp logged out',
        );
      }
    });

    // Handle authentication failure
    socket.on('wa_auth_failure', (data) {
      print('Auth Failure: $data');
      if (mounted) {
        setState(() {
          isWhatsAppReady = false;
          isWhatsAppLoading = false;
          loadingMessage = '';
          isLoggedOut = true;
          hasInitialized = true;
          messages.clear();
        });

        showErrorMessage(
          context,
          message: data['error'] ?? 'Authentication failed. Please try again.',
        );
      }
    });

    // CRITICAL: Handle QR expiration properly
    socket.on('wa_qr_expired', (data) {
      print('QR Expired: $data');
      if (mounted) {
        setState(() {
          isWhatsAppReady = false;
          isWhatsAppLoading = false;
          loadingMessage = '';
          isLoggedOut = true;
          hasInitialized = true;
        });

        // Show QR expired dialog with retry option
        _showQRExpiredDialog();
      }
    });

    // Handle disconnection
    socket.on('wa_disconnected', (data) {
      print('WA Disconnected: $data');
      if (mounted) {
        setState(() {
          isWhatsAppReady = false;
          isWhatsAppLoading = false;
          loadingMessage = '';
          isLoggedOut = true;
          hasInitialized = true;
        });

        showErrorMessage(
          context,
          message: 'WhatsApp disconnected. Please reconnect.',
        );
      }
    });

    // Handle chat messages
    socket.on('chat_messages', (data) {
      print(
        'Received messages: ${data?.toString().substring(0, math.min(100, data?.toString().length ?? 0))}...',
      );
      if (data != null && mounted) {
        try {
          final messagesList = data['messages'] as List?;
          if (messagesList != null) {
            final List<Message> initialMessages = messagesList
                .map((msg) => Message.fromJson(msg))
                .toList();
            setState(() {
              messages = initialMessages;
            });
            _scrollToBottomDelayed();
          }
        } catch (e) {
          print('Error parsing messages: $e');
        }
      }
    });

    // Handle new messages
    socket.on('new_message', (data) {
      print('New message: $data');
      if (data != null && mounted) {
        try {
          final messageData = data['message'];
          if (messageData != null && data['chatId'] == widget.chatId) {
            final newMessage = Message.fromJson(messageData);
            if (!messages.any((m) => m.id == newMessage.id)) {
              setState(() {
                messages.add(newMessage);
              });
              _scrollToBottomDelayed();
            }
          }
        } catch (e) {
          print('Error parsing new message: $e');
        }
      }
    });

    // Handle general WhatsApp errors
    socket.on('wa_error', (data) {
      print('WA Error: $data');
      if (mounted) {
        setState(() {
          isWhatsAppLoading = false;
          loadingMessage = '';
          hasInitialized = true;
        });

        final errorMsg = data['error'] ?? 'WhatsApp error occurred';

        // Don't show error for "Chat not found" - it's normal for new chats
        if (!errorMsg.toLowerCase().contains('chat not found')) {
          showErrorMessage(context, message: errorMsg);

          // If it's a critical error, show connect button
          if (errorMsg.contains('session') || errorMsg.contains('auth')) {
            setState(() {
              isLoggedOut = true;
            });
          }
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showQRInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.qr_code, color: AppColors.colorsBlue),
              SizedBox(width: 8),
              Text('QR Code Ready', style: AppFont.appbarfontblack(context)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A QR code has been sent to your email.',
                style: AppFont.dropDowmLabel(context),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 40,
                      color: AppColors.colorsBlue,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Steps to connect:',

                      // style: TextStyle(fontWeight: FontWeight.bold),
                      style: AppFont.dropDowmLabel(context),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Open WhatsApp\n2. Go to Settings > Linked Devices\n3. Tap "Link a Device"\n4. Scan the QR code from your email',

                      style: AppFont.dropDowmLabel(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: AppFont.buttons(context)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                launchWhatsAppScanner();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorsBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Open WhatsApp', style: AppFont.buttons(context)),
            ),
          ],
        );
      },
    );
  }

  void _showQRExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.timer_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('QR Code Expired', style: AppFont.appbarfontblack(context)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The QR code has expired after 60 seconds.',
                style: AppFont.dropDowmLabel(context),
              ),
              SizedBox(height: 12),
              Text(
                'Would you like to generate a new QR code?',
                style: AppFont.dropDowmLabel(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // User cancelled, go back to connect screen
                setState(() {
                  isLoggedOut = true;
                  isWhatsAppLoading = false;
                });
              },
              child: Text('Cancel', style: AppFont.buttons(context)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Generate new QR
                connectWhatsApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorsBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Try Again', style: AppFont.buttons(context)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopReconnectTimer();

    // Clean up socket listeners
    socket.off('connect');
    socket.off('disconnect');
    socket.off('new_message');
    socket.off('chat_messages');
    socket.off('message_sent');
    socket.off('wa_error');
    socket.off('connect_error');
    socket.off('wa_login_success');
    socket.off('wa_auth_failure');
    socket.off('wa_disconnected');
    socket.off('wa_loading_started');
    socket.off('wa_logout');
    socket.off('wa_qr_expired');
    socket.off('QrSend');
    socket.off('whatsapp_ready');
    socket.disconnect();
    socket.dispose();

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Your existing attachment, sendVideoMessage, sendDocumentMessage, sendImageMessage methods remain the same...
  void attachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.colorsBlue,
                ),
                title: Text('Document', style: AppFont.dropDowmLabel(context)),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(type: FileType.any, allowMultiple: false);

                  if (result != null && result.files.single.path != null) {
                    final file = XFile(result.files.single.path!);
                    await sendDocumentMessage(file);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo, color: AppColors.colorsBlue),
                title: Text('Photo', style: AppFont.dropDowmLabel(context)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (image != null) {
                    await sendImageMessage(image);
                  }
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.videocam, color: AppColors.colorsBlue),
              //   title: Text('Video', style: AppFont.dropDowmLabel(context)),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     final XFile? video = await _picker.pickVideo(
              //       source: ImageSource.gallery,
              //     );
              //     if (video != null) {
              //       await sendVideoMessage(video);
              //     }
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  // Your existing media sending methods remain the same...
  Future<void> sendVideoMessage(XFile video) async {
    if (!isWhatsAppReady) return;

    setState(() {
      isSendingImage = true;
    });

    try {
      final bytes = await video.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = video.path.split('.').last.toLowerCase();
      String mimeType = 'video/mp4';

      switch (extension) {
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        case 'avi':
          mimeType = 'video/x-msvideo';
          break;
        case 'mkv':
          mimeType = 'video/x-matroska';
          break;
        case '3gp':
          mimeType = 'video/3gpp';
          break;
      }

      final message = {
        'chatId': widget.chatId,
        'message': _messageController.text.trim(),
        'sessionId': spId,
        'media': {
          'mimetype': mimeType,
          'base64': base64String,
          'filename': video.name,
        },
      };

      socket.emit('send_message', message);

      final localMessage = Message(
        body: _messageController.text.trim(),
        fromMe: true,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        type: 'video',
        mediaUrl: video.path,
        media: null,
      );

      setState(() {
        messages.add(localMessage);
      });

      _messageController.clear();
      _scrollToBottomDelayed();
    } catch (e) {
      print('Error sending video: $e');
      if (mounted) {
        showErrorMessage(context, message: 'Failed to send video');
      }
    } finally {
      setState(() {
        isSendingImage = false;
      });
    }
  }

  Future<void> sendDocumentMessage(XFile document) async {
    if (!isWhatsAppReady) return;

    setState(() {
      isSendingDocument = true;
    });

    try {
      final bytes = await document.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = document.path.split('.').last.toLowerCase();

      // Enhanced MIME type detection
      String mimeType = _getMimeType(extension);

      final mediaInfo = {
        'mimetype': mimeType,
        'base64': base64String,
        'filename': document.name,
      };

      final message = {
        'sessionId': spId,
        'chatId': widget.chatId,
        'message': _messageController.text.trim(),
        'media': mediaInfo,
      };

      socket.emit('send_message', message);

      final localMessage = Message(
        body: _messageController.text.trim(),
        fromMe: true,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        type: 'document',
        mediaUrl: document.path,
        media: mediaInfo,
      );

      setState(() {
        messages.add(localMessage);
      });

      _messageController.clear();
      _scrollToBottomDelayed();
    } catch (e) {
      print('Error sending document: $e');
      if (mounted) {
        showErrorMessage(context, message: 'Failed to send document');
      }
    } finally {
      setState(() {
        isSendingDocument = false;
      });
    }
  }

  String _getMimeType(String extension) {
    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'zip': 'application/zip',
      'rar': 'application/vnd.rar',
      '7z': 'application/x-7z-compressed',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  Future<void> sendImageMessage(XFile image) async {
    if (!isWhatsAppReady) return;

    setState(() {
      isSendingImage = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = image.path.split('.').last.toLowerCase();
      String mimeType = _getMimeType(extension);

      final message = {
        'chatId': widget.chatId,
        'message': _messageController.text.trim(),
        'sessionId': spId,
        'media': {
          'mimetype': mimeType,
          'base64': base64String,
          'filename': image.name,
        },
      };

      socket.emit('send_message', message);

      final localMessage = Message(
        body: _messageController.text.trim(),
        fromMe: true,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        type: 'image',
        mediaUrl: image.path,
        media: null,
      );

      setState(() {
        messages.add(localMessage);
      });

      _messageController.clear();
      _scrollToBottomDelayed();
    } catch (e) {
      print('Error sending image: $e');
      if (mounted) {
        showErrorMessage(context, message: 'Failed to send image.');
      }
    } finally {
      setState(() {
        isSendingImage = false;
      });
    }
  }

  void sendMessage() {
    if (_messageController.text.trim().isEmpty || !isWhatsAppReady) return;

    final message = {
      'chatId': widget.chatId,
      'message': _messageController.text,
      'sessionId': spId,
    };

    final localMessage = Message(
      body: _messageController.text,
      fromMe: true,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      type: 'chat',
      mediaUrl: null,
      media: null,
    );

    socket.emit('send_message', message);

    setState(() {
      messages.add(localMessage);
    });

    _messageController.clear();
    _scrollToBottomDelayed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.colorsBlue,
          leadingWidth: 40,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              disconnectSocket();
            },
          ),
          title: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            IconButton(
              icon: Icon(_getConnectionIcon(), color: Colors.white),
              onPressed: () {
                if (!isConnected) {
                  socket.connect();
                } else if (!isWhatsAppReady) {
                  connectWhatsApp();
                }
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Show initial loading only when first checking status
    if (isCheckingStatus && !hasInitialized) {
      return _buildLoadingScreen(
        'Checking WhatsApp status...',
        'Please wait while we verify your connection',
      );
    }

    return Column(
      children: [
        Expanded(child: _buildMessageArea()),
        if (isWhatsAppReady && !isLoggedOut && isConnected)
          _buildMessageInput(),
      ],
    );
  }

  Widget _buildLoadingScreen(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.colorsBlue),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppFont.dropDowmLabel(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppFont.dropDowmLabelLightcolors(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (!hasInitialized) return 'Initializing...';
    if (isWhatsAppLoading) return 'Connecting...';
    if (isLoggedOut) return 'Logged Out';
    if (!isConnected) return 'Connecting...';
    if (!isWhatsAppReady) return 'Not Connected';
    return 'Online';
  }

  IconData _getConnectionIcon() {
    if (!hasInitialized || isCheckingStatus) return Icons.sync;
    if (isWhatsAppLoading) return Icons.hourglass_empty;
    if (isConnected && isWhatsAppReady) return Icons.wifi;
    return Icons.wifi_off;
  }

  Widget _buildMessageArea() {
    // Show WhatsApp connection loading
    if (isWhatsAppLoading) {
      return _buildLoadingScreen(
        loadingMessage.isNotEmpty
            ? loadingMessage
            : 'Connecting to WhatsApp...',
        'Please wait while we set up your WhatsApp connection',
      );
    }

    // Show connect button when logged out or not ready
    if (isLoggedOut || (!isWhatsAppReady && hasInitialized)) {
      return _buildConnectionPrompt();
    }

    // Show socket connection status
    if (!isConnected && hasInitialized) {
      return _buildConnectionIssue();
    }

    // Show messages when ready
    if (messages.isEmpty && isWhatsAppReady) {
      return _buildEmptyChat();
    }

    return _buildMessagesList();
  }

  Widget _buildAppIcon(
    BuildContext context,
    String name,
    String asset,
    double size, // 👈 size for asset
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close bottom sheet
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size / 4), // optional rounded
              child: Image.asset(
                asset,
                fit: BoxFit.contain, // keep aspect ratio
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: AppFont.dropDowmLabel(context)),
        ],
      ),
    );
  }

  Widget _buildConnectionPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.colorsBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLoggedOut ? Icons.logout : Icons.chat_bubble_outline,
                size: 60,
                color: AppColors.colorsBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isLoggedOut ? 'WhatsApp Session Ended' : 'Connect WhatsApp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isLoggedOut
                  ? 'Your WhatsApp session has expired.\nPlease reconnect to continue chatting.'
                  : 'Connect your WhatsApp account to start\nsending and receiving messages.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : connectWhatsApp,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey[400] : AppColors.colorsBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.colorsBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      Icon(
                        isLoading ? null : Icons.link,
                        color: Colors.white,
                        size: 18,
                      ),
                      if (!isLoading) SizedBox(width: 8),
                      Text(
                        isLoading
                            ? 'Connecting...'
                            : isLoggedOut
                            ? 'Reconnect WhatsApp'
                            : 'Connect WhatsApp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoggedOut) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => checkWhatsAppStatus(),
                child: Text(
                  'Check Connection Status',
                  style: TextStyle(color: AppColors.colorsBlue, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIssue() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Connection Issue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Having trouble connecting to server.\nPlease check your internet connection.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => socket.connect(),
              icon: Icon(Icons.refresh),
              label: Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorsBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refreshConnection() async {
    if (isCheckingStatus) return;

    setState(() {
      isCheckingStatus = true;
    });

    try {
      // First check if socket is connected
      if (!isConnected) {
        socket.connect();
        await Future.delayed(Duration(seconds: 2));
      }

      // Then check WhatsApp status
      await checkWhatsAppStatus();
    } catch (e) {
      print('Error refreshing connection: $e');
      if (mounted) {
        setState(() {
          isLoggedOut = true;
          isCheckingStatus = false;
        });
      }
    }
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.userName}',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDate = _shouldShowDate(index);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.timestamp),
            MessageBubble(
              message: message,
              timeString: formatTimestamp(message.timestamp),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;

    final currentDate = DateTime.fromMillisecondsSinceEpoch(
      messages[index].timestamp * 1000,
    );
    final previousDate = DateTime.fromMillisecondsSinceEpoch(
      messages[index - 1].timestamp * 1000,
    );

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  Widget _buildDateDivider(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('EEEE, MMM d').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: (isSendingImage || isSendingDocument)
                ? null
                : attachment,
            icon: (isSendingImage || isSendingDocument)
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.colorsBlue,
                      ),
                    ),
                  )
                : Icon(Icons.attach_file, color: AppColors.colorsBlue),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.iconGrey,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt_rounded),
              color: Colors.white,
              onPressed: isSendingImage
                  ? null
                  : () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (image != null) {
                        await sendImageMessage(image);
                      }
                    },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              // color: _messageController.text.trim().isEmpty
              //     ? Colors.grey[400]
              //     : AppColors.colorsBlue,
              color: AppColors.colorsBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              // onPressed: _messageController.text.trim().isEmpty
              //     ? null
              //     : sendMessage,
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}



// class _WhatsappChatState extends State<WhatsappChat>
//     with WidgetsBindingObserver {
//   List<Message> messages = [];
//   bool isLoading = false;
//   bool isWhatsAppLoading = false;
//   String loadingMessage = '';
//   String spId = '';
//   String email = '';
//   bool isWhatsAppReady = false;
//   bool isCheckingStatus = true;
//   bool isLoggedOut = false;
//   Timer? _reconnectTimer;

//   final ImagePicker _picker = ImagePicker();
//   bool isSendingImage = false;
//   bool isSendingDocument = false;

//   final TextEditingController _messageController = TextEditingController();
//   late IO.Socket socket;
//   bool isConnected = false;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadInitialData();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     print('AppLifecycleState: $state');

//     if (state == AppLifecycleState.resumed) {
//       _stopReconnectTimer();

//       if (!isConnected) {
//         print('App resumed, forcing socket reconnect');
//         socket.connect();
//       }

//       // Check WhatsApp status when app resumes, but only if not currently checking
//       Future.delayed(Duration(seconds: 1), () {
//         if (mounted && !isCheckingStatus) {
//           checkWhatsAppStatus();
//         }
//       });
//     } else if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.hidden) {
//       print('App paused or hidden, starting reconnect timer');
//       _startReconnectTimer();
//     }
//   }

//   // @override
//   // void didChangeAppLifecycleState(AppLifecycleState state) {
//   //   super.didChangeAppLifecycleState(state);
//   //   print('AppLifecycleState: $state');
//   //   if (state == AppLifecycleState.resumed) {
//   //     // App is back in foreground, attempt to reconnect socket immediately
//   //     _stopReconnectTimer();
//   //     if (!isConnected) {
//   //       print('App resumed, forcing socket reconnect');
//   //       socket.connect();
//   //       // Delay status check to allow socket connection
//   //       Future.delayed(Duration(seconds: 1), () {
//   //         if (mounted && !isWhatsAppReady && !isLoggedOut) {
//   //           checkWhatsAppStatus();
//   //         }
//   //       });
//   //     }
//   //   } else if (state == AppLifecycleState.paused ||
//   //       state == AppLifecycleState.hidden) {
//   //     // App is in background or hidden, start reconnection attempts
//   //     print('App paused or hidden, starting reconnect timer');
//   //     _startReconnectTimer();
//   //   }
//   // }

//   void _startReconnectTimer() {
//     _reconnectTimer?.cancel();
//     int attempt = 0;
//     const maxAttempts = 10;
//     const baseDelay = 2000; // Start with 2 seconds
//     const maxDelay = 20000; // Cap at 20 seconds

//     _reconnectTimer = Timer.periodic(Duration(milliseconds: baseDelay), (
//       timer,
//     ) async {
//       if (!isConnected && mounted && attempt < maxAttempts) {
//         print(
//           'Attempting to reconnect socket... (Attempt ${attempt + 1}/$maxAttempts)',
//         );
//         socket.connect();
//         attempt++;
//         // Increase delay with exponential backoff
//         final delay = (baseDelay * pow(1.5, attempt)).toInt().clamp(
//           baseDelay,
//           maxDelay,
//         );
//         if (delay > baseDelay) {
//           timer.cancel();
//           _reconnectTimer = Timer.periodic(Duration(milliseconds: delay), (t) {
//             if (!isConnected && mounted && attempt < maxAttempts) {
//               print(
//                 'Attempting to reconnect socket... (Attempt ${attempt + 1}/$maxAttempts)',
//               );
//               socket.connect();
//               attempt++;
//             } else {
//               t.cancel();
//             }
//           });
//         }
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   void _stopReconnectTimer() {
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//   }

//   Future<void> loadInitialData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     spId = prefs.getString('user_id') ?? '';
//     email = await TokenManager.getUserEmail() ?? '';
//     print('this is spid $spId');
//     initSocket(); // Initialize socket first
//     await checkWhatsAppStatus(); // Check status after socket is initialized
//   }

//   Future<void> checkWhatsAppStatus() async {
//     if (!mounted) return;

//     setState(() {
//       isCheckingStatus = true;
//     });

//     try {
//       final url = Uri.parse(
//         'https://api.smartassistapp.in/api/check-wa-status',
//       );
//       final token = await Storage.getToken();
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({'sessionId': spId}),
//       );

//       print(
//         'Check WA Status Response: ${response.statusCode} - ${response.body}',
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final isReady = data['isReady'] ?? false;

//         setState(() {
//           isWhatsAppReady = isReady;
//           isCheckingStatus = false;
//           isLoggedOut = !isReady; // If not ready, show connect button
//         });

//         // If WhatsApp is ready and we have a connection, fetch messages
//         if (isReady && isConnected) {
//           socket.emit('get_messages', {
//             'sessionId': spId,
//             'chatId': widget.chatId,
//           });
//         }
//       } else {
//         print('Failed to check WhatsApp status: ${response.body}');
//         setState(() {
//           isWhatsAppReady = false;
//           isCheckingStatus = false;
//           isLoggedOut = true;
//         });
//       }
//     } catch (e) {
//       print('Error checking WhatsApp status: $e');
//       setState(() {
//         isWhatsAppReady = false;
//         isCheckingStatus = false;
//         isLoggedOut = true;
//       });
//       showErrorMessage(context, message: 'Failed to check WhatsApp status');
//     }
//   }

//   // Future<void> checkWhatsAppStatus() async {
//   //   setState(() {
//   //     isCheckingStatus = true;
//   //   });
//   //   try {
//   //     final url = Uri.parse(
//   //       'https://api.smartassistapp.in/api/check-wa-status',
//   //     );
//   //     final token = await Storage.getToken();
//   //     final response = await http.post(
//   //       url,
//   //       headers: {
//   //         'Content-Type': 'application/json',
//   //         'Authorization': 'Bearer $token',
//   //       },
//   //       body: json.encode({'sessionId': spId}),
//   //     );

//   //     print(
//   //       'Check WA Status Response: ${response.statusCode} - ${response.body}',
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final data = json.decode(response.body);
//   //       setState(() {
//   //         isWhatsAppReady = data['isReady'] ?? false;
//   //         isCheckingStatus = false;
//   //         if (isWhatsAppReady) {
//   //           isLoggedOut = false;
//   //         }
//   //       });
//   //       // Remove direct socket.emit; rely on socket's onConnect
//   //     } else {
//   //       print('Failed to check WhatsApp status: ${response.body}');
//   //       setState(() {
//   //         isWhatsAppReady = false;
//   //         isCheckingStatus = false;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     print('Error checking WhatsApp status: $e');
//   //     setState(() {
//   //       isWhatsAppReady = false;
//   //       isCheckingStatus = false;
//   //     });
//   //     showErrorMessage(context, message: 'Failed to check WhatsApp status');
//   //   }
//   // }

//   Future<void> initWhatsAppChat(BuildContext context) async {
//     if (isWhatsAppReady || isLoading) return;

//     setState(() {
//       isLoading = true;
//       isLoggedOut = false; // Reset logout flag when trying to reconnect
//     });

//     try {
//       final url = Uri.parse('https://api.smartassistapp.in/api/init-wa');
//       final token = await Storage.getToken();
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({'sessionId': spId, 'email': email}),
//       );

//       print(url.toString());
//       print('Init WA Response: ${response.statusCode} - ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['isReady'] == true) {
//           setState(() {
//             isWhatsAppReady = true;
//             isLoggedOut = false;
//           });
//           socket.emit('get_messages', {
//             'sessionId': spId,
//             'chatId': widget.chatId,
//           });
//         } else {
//           await launchWhatsAppScanner();
//         }
//       } else {
//         final errorMessage =
//             json.decode(response.body)['message'] ?? 'Unknown error';
//         print(errorMessage.toString());
//       }
//     } catch (e) {
//       print('Error initializing WhatsApp chat: $e');

//       showErrorMessage(context, message: 'Failed to initialize WhatsApp chat.');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> resendQR() async {
//     // if (!isConnected) {
//     //   showErrorMessage(context, message: 'Not connected to server.');

//     //   return;
//     // }

//     // setState(() {
//     //   isWhatsAppLoading = true;
//     //   loadingMessage = 'Regenerating QR code...';
//     // });

//     // await initWhatsAppChat(context);

//     await initWhatsAppChat(context);
//     socket.emit('resend_qr', {'sessionId': spId, 'email': email});
//   }

//   Future<void> launchWhatsAppScanner() async {
//     try {
//       await LaunchApp.openApp(
//         androidPackageName: 'com.whatsapp',
//         iosUrlScheme: 'whatsapp://',
//         appStoreLink:
//             'https://play.google.com/store/apps/details?id=com.whatsapp',
//       );
//       print('WhatsApp launched successfully');
//     } catch (e) {
//       print('Error launching WhatsApp: $e');

//       showErrorMessage(
//         context,
//         message: e.toString().contains('not installed')
//             ? 'Please install whatsapp to continue'
//             : 'Failed to open WhatsApp',
//       );
//     }
//   }

//   String formatTimestamp(int timestamp) {
//     final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
//       timestamp * 1000,
//     );
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

//     final timeFormat = DateFormat('HH:mm');
//     if (messageDate == today) {
//       return timeFormat.format(dateTime);
//     } else if (messageDate == yesterday) {
//       return 'Yesterday, ${timeFormat.format(dateTime)}';
//     } else {
//       return DateFormat('MMM d, HH:mm').format(dateTime);
//     }
//   }

//   void initSocket() {
//     socket = IO.io('wss://api.smartassistapp.in', <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': true,
//       'reconnection': true,
//       'reconnectionAttempts': 10,
//       'reconnectionDelay': 1000,
//       'reconnectionDelayMax': 5000,
//       'timeout': 20000,
//     });

//     socket.onConnect((_) {
//       print('Socket connected');
//       _stopReconnectTimer();
//       socket.emit('register_session', {'sessionId': spId, 'email': email});
//       print('Emitted register_session: sessionId=$spId');
//       setState(() {
//         isConnected = true;
//       });

//       // Always check status when socket connects
//       if (!isCheckingStatus) {
//         checkWhatsAppStatus();
//       }
//     });

//     socket.onDisconnect((_) {
//       print('Socket disconnected');
//       setState(() {
//         isConnected = false;
//       });
//       _startReconnectTimer();
//     });

//     socket.onConnectError((error) {
//       print('Connection error: $error');
//       setState(() {
//         isConnected = false;
//       });
//       _startReconnectTimer();
//     });

//     // WhatsApp initialization started
//     socket.on('wa_loading_started', (data) {
//       print('WA Loading Started: $data');
//       setState(() {
//         isWhatsAppLoading = true;
//         loadingMessage = data['message'] ?? 'Starting WhatsApp client...';
//         isLoggedOut = false;
//       });
//     });

//     // QR code generated and ready for scanning
//     socket.on('QrSend', (data) {
//       print('QrSend received: $data');
//       setState(() {
//         isWhatsAppLoading = true;
//         loadingMessage = 'QR code generated, please scan in WhatsApp';
//         isLoggedOut = false;
//       });
//       launchWhatsAppScanner();
//     });

//     // WhatsApp client is ready and authenticated
//     socket.on('whatsapp_ready', (data) {
//       print('WhatsApp Ready: $data');
//       setState(() {
//         isWhatsAppReady = true;
//         isWhatsAppLoading = false; // Stop loading when truly ready
//         loadingMessage = '';
//         isLoggedOut = false;
//       });

//       // Automatically fetch messages when WhatsApp becomes ready
//       socket.emit('get_messages', {'sessionId': spId, 'chatId': widget.chatId});
//       print('Requesting messages for chat ID: ${widget.chatId}');
//     });

//     // Successful login/authentication
//     socket.on('wa_login_success', (data) {
//       print('WA Login Success: $data');
//       setState(() {
//         isWhatsAppReady = true;
//         isWhatsAppLoading = false;
//         loadingMessage = '';
//         isLoggedOut = false;
//       });

//       // Fetch messages after successful login
//       socket.emit('get_messages', {'sessionId': spId, 'chatId': widget.chatId});
//     });

//     // Authentication failure
//     socket.on('wa_auth_failure', (data) {
//       print('WA Auth Failure: $data');
//       setState(() {
//         isWhatsAppReady = false;
//         isWhatsAppLoading = false;
//         loadingMessage = '';
//         isLoggedOut = true;
//         messages.clear();
//       });

//       showErrorMessage(
//         context,
//         message: data['error'] ?? 'WhatsApp authentication failed.',
//       );
//     });

//     // QR code expired
//     socket.on('wa_qr_expired', (data) {
//       print('QR Expired: $data');
//       setState(() {
//         isWhatsAppReady = false;
//         isWhatsAppLoading = false;
//         loadingMessage = '';
//         isLoggedOut = true;
//       });

//       showErrorMessage(
//         context,
//         message: data['message'] ?? 'QR code expired, please scan again.',
//       );
//     });

//     // WhatsApp disconnected
//     socket.on('wa_disconnected', (data) {
//       print('WA Disconnected: $data');
//       setState(() {
//         isWhatsAppReady = false;
//         isWhatsAppLoading = false;
//         loadingMessage = '';
//         isLoggedOut = true; // Show reconnect option
//       });

//       showErrorMessage(
//         context,
//         message: data['message'] ?? 'WhatsApp disconnected',
//       );
//     });

//     // WhatsApp logged out
//     socket.on('wa_logout', (data) {
//       print('WA Logout: $data');
//       setState(() {
//         isWhatsAppReady = false;
//         isWhatsAppLoading = false;
//         loadingMessage = '';
//         isLoggedOut = true;
//         messages.clear();
//       });

//       showErrorMessage(
//         context,
//         message: data['message'] ?? 'WhatsApp session ended. Please reconnect.',
//       );
//     });

//     // Receive initial chat messages
//     socket.on('chat_messages', (data) {
//       print('Received initial messages: $data');
//       if (data != null && mounted) {
//         try {
//           final List<Message> initialMessages = (data['messages'] as List)
//               .map((msg) => Message.fromJson(msg))
//               .toList();
//           setState(() {
//             messages = initialMessages;
//           });
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _scrollToBottom();
//           });
//         } catch (e) {
//           print('Error parsing chat messages: $e');
//         }
//       }
//     });

//     // Receive new messages
//     socket.on('new_message', (data) {
//       print('New message received: $data');
//       if (data != null && mounted) {
//         try {
//           final messageData = data['message'];
//           if (messageData != null) {
//             if (messageData['media'] != null) {
//               print(
//                 'Received media message: ${messageData['type']} - ${messageData['media']['mimetype']}',
//               );
//             }

//             final newMessage = Message.fromJson(messageData);
//             if (data['chatId'] == widget.chatId &&
//                 !messages.any((m) => m.id == newMessage.id)) {
//               setState(() {
//                 messages.add(newMessage);
//               });
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _scrollToBottom();
//               });
//             }
//           }
//         } catch (e) {
//           print('Error parsing new message: $e');
//           print('Message data: $data');
//         }
//       }
//     });

//     // Message sent confirmation
//     socket.on('message_sent', (data) {
//       print('Message sent confirmation: $data');
//     });

//     // General WhatsApp errors
//     socket.on('wa_error', (data) {
//       print('WebSocket error: $data');
//       setState(() {
//         isWhatsAppLoading = false;
//         loadingMessage = '';
//       });
//       showErrorMessage(context, message: data['error'] ?? 'Unknown error');
//     });
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _stopReconnectTimer();
//     socket.off('connect');
//     socket.off('disconnect');
//     socket.off('new_message');
//     socket.off('chat_messages');
//     socket.off('message_sent');
//     socket.off('wa_error');
//     socket.off('connect_error');
//     socket.off('wa_login_success');
//     socket.off('wa_auth_failure');
//     socket.off('wa_disconnected');
//     socket.off('wa_loading_started');
//     socket.off('wa_logout');
//     socket.off('wa_qr_expired');
//     socket.disconnect();
//     _messageController.dispose();
//     _scrollController.dispose();
//     socket.disconnect();
//     socket.dispose();
//     super.dispose();
//   }

//   void disconnectSocket() {
//     _stopReconnectTimer();
//     socket.disconnect();
//     setState(() {
//       isConnected = false;
//     });
//     print('Socket manually disconnected');
//   }

//   void attachment() async {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           height: 220,
//           child: Column(
//             children: [
//               ListTile(
//                 leading: Icon(Icons.picture_as_pdf),
//                 title: Text('Document', style: AppFont.dropDowmLabel(context)),
//                 onTap: () async {
//                   Navigator.pop(
//                     context,
//                   ); // ✅ This is correct - we're in a modal
//                   FilePickerResult? result = await FilePicker.platform
//                       .pickFiles(type: FileType.any, allowMultiple: false);

//                   if (result != null && result.files.single.path != null) {
//                     final file = XFile(result.files.single.path!);
//                     await sendDocumentMessage(file);
//                   }
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.photo),
//                 title: Text('Photo', style: AppFont.dropDowmLabel(context)),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   final XFile? image = await _picker.pickImage(
//                     source: ImageSource.gallery,
//                     imageQuality: 70,
//                   );
//                   if (image != null) {
//                     await sendImageMessage(image);
//                   }
//                 },
//               ),
//               // ListTile(
//               //   leading: Icon(Icons.videocam),
//               //   title: Text('Video', style: AppFont.dropDowmLabel(context)),
//               //   onTap: () async {
//               //     Navigator.pop(
//               //       context,
//               //     ); // ✅ This is correct - we're in a modal
//               //     final XFile? video = await _picker.pickVideo(
//               //       source: ImageSource.gallery,
//               //     );
//               //     if (video != null) {
//               //       await sendVideoMessage(video);
//               //     }
//               //   },
//               // ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> sendVideoMessage(XFile video) async {
//     if (!isWhatsAppReady) return;

//     setState(() {
//       isSendingImage = true; // You can rename this to isSendingMedia
//     });

//     try {
//       // Read video as bytes
//       final bytes = await video.readAsBytes();
//       final base64String = base64Encode(bytes);

//       // Get file extension and mime type
//       final extension = video.path.split('.').last.toLowerCase();
//       String mimeType = 'video/mp4'; // default

//       switch (extension) {
//         case 'mp4':
//           mimeType = 'video/mp4';
//           break;
//         case 'mov':
//           mimeType = 'video/quicktime';
//           break;
//         case 'avi':
//           mimeType = 'video/x-msvideo';
//           break;
//         case 'mkv':
//           mimeType = 'video/x-matroska';
//           break;
//         case '3gp':
//           mimeType = 'video/3gpp';
//           break;
//       }

//       final message = {
//         'chatId': widget.chatId,
//         'message': _messageController.text.trim(), // Caption
//         'sessionId': spId,
//         'media': {
//           'mimetype': mimeType,
//           'base64': base64String,
//           'filename': video.name,
//         },
//       };

//       print(
//         'Sending video message: ${(message['media'] as Map<String, dynamic>)['filename']}',
//       );
//       socket.emit('send_message', message);

//       // Add local message to UI
//       final localMessage = Message(
//         body: _messageController.text.trim(),
//         fromMe: true,
//         timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         type: 'video',
//         mediaUrl: video.path, // Use local path for immediate display
//         media: null,
//       );

//       setState(() {
//         messages.add(localMessage);
//       });

//       _messageController.clear();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollToBottom();
//       });
//     } catch (e) {
//       print('Error sending video: $e');

//       showErrorMessage(context, message: 'Failed to send video');
//     } finally {
//       setState(() {
//         isSendingImage = false;
//       });
//     }
//   }

//   Future<void> sendDocumentMessage(XFile document) async {
//     if (!isWhatsAppReady) return;

//     setState(() {
//       isSendingDocument = true;
//     });

//     try {
//       // Read document as bytes
//       final bytes = await document.readAsBytes();
//       final base64String = base64Encode(bytes);

//       // Get file extension and mime type
//       final extension = document.path.split('.').last.toLowerCase();
//       String mimeType = 'application/octet-stream'; // default

//       switch (extension) {
//         case 'pdf':
//           mimeType = 'application/pdf';
//           break;
//         case 'doc':
//           mimeType = 'application/msword';
//           break;
//         case 'docx':
//           mimeType =
//               'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
//           break;
//         case 'xls':
//           mimeType = 'application/vnd.ms-excel';
//           break;
//         case 'xlsx':
//           mimeType =
//               'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
//           break;
//         case 'ppt':
//           mimeType = 'application/vnd.ms-powerpoint';
//           break;
//         case 'pptx':
//           mimeType =
//               'application/vnd.openxmlformats-officedocument.presentationml.presentation';
//           break;
//         case 'txt':
//           mimeType = 'text/plain';
//           break;
//         case 'csv':
//           mimeType = 'text/csv';
//           break;
//         case 'zip':
//           mimeType = 'application/zip';
//           break;
//         case 'rar':
//           mimeType = 'application/vnd.rar';
//           break;
//         case '7z':
//           mimeType = 'application/x-7z-compressed';
//           break;
//         case 'mp3':
//           mimeType = 'audio/mpeg';
//           break;
//         case 'mp4':
//           mimeType = 'video/mp4';
//           break;
//         case 'avi':
//           mimeType = 'video/x-msvideo';
//           break;
//         case 'mov':
//           mimeType = 'video/quicktime';
//           break;
//       }

//       final mediaInfo = {
//         'mimetype': mimeType,
//         'base64': base64String,
//         'filename': document.name,
//       };

//       // Fixed: Match the expected socket structure
//       final message = {
//         'sessionId': spId,
//         'chatId': widget.chatId,
//         'message': _messageController.text.trim(),
//         'media': mediaInfo,
//       };

//       print('Sending document message: ${document.name}');
//       print('Message structure: $message');

//       socket.emit('send_message', message);

//       // Fixed: Include media info in local message
//       final localMessage = Message(
//         body: _messageController.text.trim(),
//         fromMe: true,
//         timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         type: 'document',
//         mediaUrl: document.path,
//         media: mediaInfo, // Include media info for local display
//       );

//       setState(() {
//         messages.add(localMessage);
//       });

//       _messageController.clear();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollToBottom();
//       });
//     } catch (e) {
//       print('Error sending document: $e');

//       showErrorMessage(context, message: 'Failed to send document');
//     } finally {
//       setState(() {
//         isSendingDocument = false;
//       });
//     }
//   }

//   Future<void> sendImageMessage(XFile image) async {
//     if (!isWhatsAppReady) return;

//     setState(() {
//       isSendingImage = true;
//     });

//     try {
//       // Read image as bytes
//       final bytes = await image.readAsBytes();
//       final base64String = base64Encode(bytes);

//       // Get file extension and mime type
//       final extension = image.path.split('.').last.toLowerCase();
//       String mimeType = 'image/jpeg'; // default

//       switch (extension) {
//         case 'png':
//           mimeType = 'image/png';
//           break;
//         case 'jpg':
//         case 'jpeg':
//           mimeType = 'image/jpeg';
//           break;
//         case 'gif':
//           mimeType = 'image/gif';
//           break;
//         case 'webp':
//           mimeType = 'image/webp';
//           break;
//       }

//       final message = {
//         'chatId': widget.chatId,
//         'message': _messageController.text.trim(), // Caption
//         'sessionId': spId,
//         'media': {
//           'mimetype': mimeType,
//           'base64': base64String,
//           'filename': image.name,
//         },
//       };

//       print(
//         'Sending image message: ${(message['media'] as Map<String, dynamic>)['filename']}',
//       );
//       socket.emit('send_message', message);

//       final localMessage = Message(
//         body: _messageController.text.trim(),
//         fromMe: true,
//         timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         type: 'image',
//         mediaUrl: image.path, // Use local path for immediate display
//         media: null,
//       );

//       // );

//       setState(() {
//         messages.add(localMessage);
//       });

//       _messageController.clear();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollToBottom();
//       });
//     } catch (e) {
//       print('Error sending image: $e');

//       showErrorMessage(context, message: 'Failed to send image.');
//     } finally {
//       setState(() {
//         isSendingImage = false;
//       });
//     }
//   }

//   void sendMessage() {
//     if (_messageController.text.trim().isEmpty || !isWhatsAppReady) return;

//     final message = {
//       'chatId': widget.chatId,
//       'message': _messageController.text,
//       'sessionId': spId,
//     };

//     print('Sending message: ${jsonEncode(message)}');
//     final localMessage = Message(
//       body: _messageController.text,
//       fromMe: true,
//       timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       type: 'chat',
//       mediaUrl: null,
//       media: null,
//     );

//     socket.emit('send_message', message);

//     setState(() {
//       messages.add(localMessage);
//     });

//     _messageController.clear();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       excludeFromSemantics: true,
//       onTap: () => FocusScope.of(context).unfocus(),
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: AppColors.colorsBlue,
//           leadingWidth: 40,
//           leading: IconButton(
//             icon: const Icon(
//               Icons.arrow_back_ios_new_rounded,
//               color: Colors.white,
//             ),
//             onPressed: () {
//               Navigator.pop(context);
//               disconnectSocket();
//             },
//           ),
//           title: Row(
//             children: [
//               const SizedBox(width: 10),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.userName,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   Text(
//                     isWhatsAppLoading
//                         // ? 'Initializing...'
//                         ? 'Connected'
//                         : isLoggedOut
//                         ? 'Logged Out'
//                         : isWhatsAppReady
//                         ? (isConnected ? 'Online' : 'Connecting...')
//                         : 'Not Connected',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white.withOpacity(0.8),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(
//                 isConnected && isWhatsAppReady ? Icons.wifi : Icons.wifi_off,
//                 color: Colors.white,
//               ),
//               onPressed: () {
//                 if (!isConnected || !isWhatsAppReady) {
//                   socket.connect();
//                   checkWhatsAppStatus();
//                 }
//               },
//             ),
//           ],
//         ),
//         body: isCheckingStatus
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//                 children: [
//                   Expanded(
//                     child: isWhatsAppReady && !isLoggedOut
//                         ? messages.isEmpty
//                               ? const Center(child: Text('No messages yet'))
//                               : ListView.builder(
//                                   controller: _scrollController,
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 10,
//                                     horizontal: 10,
//                                   ),
//                                   itemCount: messages.length,
//                                   itemBuilder: (context, index) {
//                                     final message = messages[index];
//                                     final showDate =
//                                         index == 0 ||
//                                         DateTime.fromMillisecondsSinceEpoch(
//                                               messages[index].timestamp * 1000,
//                                             ).day !=
//                                             DateTime.fromMillisecondsSinceEpoch(
//                                               messages[index - 1].timestamp *
//                                                   1000,
//                                             ).day;

//                                     return Column(
//                                       children: [
//                                         if (showDate)
//                                           Container(
//                                             margin: const EdgeInsets.symmetric(
//                                               vertical: 10,
//                                             ),
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 15,
//                                               vertical: 5,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: Colors.grey[300],
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                             child: Text(
//                                               DateFormat('EEEE, MMM d').format(
//                                                 DateTime.fromMillisecondsSinceEpoch(
//                                                   message.timestamp * 1000,
//                                                 ),
//                                               ),
//                                               style: const TextStyle(
//                                                 fontSize: 12,
//                                                 color: Colors.black54,
//                                               ),
//                                             ),
//                                           ),
//                                         MessageBubble(
//                                           message: message,
//                                           timeString: formatTimestamp(
//                                             message.timestamp,
//                                           ),
//                                         ),
//                                       ],
//                                     );
//                                   },
//                                 )
//                         : Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 // Show different UI based on loading states
//                                 if (isWhatsAppLoading)
//                                   Column(
//                                     children: [
//                                       const CircularProgressIndicator(
//                                         color: AppColors.colorsBlue,
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Text(
//                                         loadingMessage.isNotEmpty
//                                             ? loadingMessage
//                                             : 'Starting WhatsApp client...',
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         'Please wait while we initialize your WhatsApp connection',
//                                         style: TextStyle(
//                                           color: Colors.grey[600],
//                                           fontSize: 14,
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                     ],
//                                   )
//                                 else
//                                   Column(
//                                     children: [
//                                       // Show different icon and text based on logout state
//                                       if (isLoggedOut)
//                                         Column(
//                                           children: [
//                                             Icon(
//                                               Icons.account_circle_outlined,
//                                               size: 80,
//                                               color: Colors.grey[400],
//                                             ),
//                                             const SizedBox(height: 16),
//                                             Text(
//                                               'WhatsApp Logged Out',
//                                               style: TextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: FontWeight.w600,
//                                                 color: Colors.grey[700],
//                                               ),
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Text(
//                                               'Your WhatsApp session has ended.\nPlease reconnect to continue chatting.',
//                                               style: TextStyle(
//                                                 color: Colors.grey[600],
//                                                 fontSize: 14,
//                                               ),
//                                               textAlign: TextAlign.center,
//                                             ),
//                                             const SizedBox(height: 24),
//                                           ],
//                                         )
//                                       else
//                                         Column(
//                                           children: [
//                                             SvgPicture.asset(
//                                               'assets/whatsapp.svg', // Replace with your SVG path
//                                               width: 80,
//                                               height: 80,
//                                               color: Colors
//                                                   .green[400], // Optional: applies color to the SVG
//                                               fit: BoxFit.fill,
//                                             ),
//                                             const SizedBox(height: 16),
//                                           ],
//                                         ),
//                                       InkWell(
//                                         onTap: () {
//                                           if (isLoggedOut) {
//                                             resendQR(); // Call resendQR if user was logged out
//                                             print('Resend QR clicked');
//                                           } else {
//                                             initWhatsAppChat(
//                                               context,
//                                             ); // Call normal init for first connection
//                                             print('Connect WhatsApp clicked');
//                                           }
//                                         },
//                                         child: Container(
//                                           width: double
//                                               .infinity, // Makes it full width
//                                           constraints: BoxConstraints(
//                                             minHeight:
//                                                 44, // Minimum touch target size
//                                             maxWidth:
//                                                 MediaQuery.of(
//                                                   context,
//                                                 ).size.width *
//                                                 0.9, // Max 90% of screen width
//                                           ),
//                                           padding: EdgeInsets.symmetric(
//                                             horizontal:
//                                                 MediaQuery.of(
//                                                   context,
//                                                 ).size.width *
//                                                 0.04, // 4% of screen width
//                                             vertical:
//                                                 MediaQuery.of(
//                                                   context,
//                                                 ).size.height *
//                                                 0.01, // 1% of screen height
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: AppColors.colorsBlue,
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                           ),
//                                           child: Center(
//                                             child: Text(
//                                               isLoading
//                                                   ? 'Connecting...'
//                                                   : isLoggedOut
//                                                   ? 'Reconnect WhatsApp'
//                                                   : 'WhatsApp not connected, connect now?',
//                                               style: AppFont.appbarfontWhite(
//                                                 context,
//                                               ),
//                                               textAlign: TextAlign.center,
//                                               maxLines:
//                                                   2, // Allows text to wrap to 2 lines if needed
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       if (!isConnected && !isLoading)
//                                         Padding(
//                                           padding: const EdgeInsets.only(
//                                             top: 8.0,
//                                           ),
//                                           child: Text(
//                                             'Click to connect',
//                                             style: TextStyle(
//                                               color: Colors.grey[600],
//                                               fontSize: 12,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                               ],
//                             ),
//                           ),
//                   ),
//                   if (isWhatsAppReady && !isLoggedOut)
//                     Container(
//                       margin: EdgeInsets.only(bottom: 10),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8.0,
//                         vertical: 5.0,
//                       ),
//                       color: Colors.white,
//                       child: Row(
//                         children: [
//                           IconButton(
//                             onPressed: isSendingImage ? null : attachment,
//                             icon: isSendingImage
//                                 ? SizedBox(
//                                     width: 20,
//                                     height: 20,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                         AppColors.colorsBlue,
//                                       ),
//                                     ),
//                                   )
//                                 : Icon(Icons.attachment_sharp),
//                           ),
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 15,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[200],
//                                 borderRadius: BorderRadius.circular(25),
//                               ),
//                               child: TextField(
//                                 controller: _messageController,
//                                 decoration: const InputDecoration(
//                                   hintText: 'Type a message',
//                                   border: InputBorder.none,
//                                 ),
//                                 maxLines: null,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             decoration: const BoxDecoration(
//                               color: AppColors.iconGrey,
//                               shape: BoxShape.circle,
//                             ),
//                             child: IconButton(
//                               icon: const Icon(Icons.camera_alt_rounded),
//                               color: Colors.white,
//                               onPressed: () async {
//                                 // Navigator.pop(context);
//                                 final XFile? image = await _picker.pickImage(
//                                   source: ImageSource.camera,
//                                   imageQuality: 70,
//                                 );
//                                 if (image != null) {
//                                   await sendImageMessage(image);
//                                 }
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             decoration: const BoxDecoration(
//                               color: AppColors.colorsBlue,
//                               shape: BoxShape.circle,
//                             ),
//                             child: IconButton(
//                               icon: const Icon(Icons.send),
//                               color: Colors.white,
//                               onPressed: sendMessage,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//       ),
//     );
//   }
// }