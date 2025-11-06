import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/testdrive_map_page.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/license_preview.dart';
import 'package:image/image.dart' as img;

class LicenseVarification extends StatefulWidget {
  final String eventId;
  final String leadId;
  const LicenseVarification({
    super.key,
    required this.eventId,
    required this.leadId,
  });

  @override
  State<LicenseVarification> createState() => _LicenseVarificationState();
}

class _LicenseVarificationState extends State<LicenseVarification>
    with WidgetsBindingObserver, RouteAware {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  File? _capturedImage;
  bool _isCameraInitialized = false;
  bool _isUploading = false;
  bool _isCapturing = false;
  bool _isDisposed = false;

  DateTime? _lastBackPressTime;
  final int _exitTimeInMillis = 2000;

  Map<String, String> skip = {'Overall Ambience': ''};

  // Rectangle dimensions for the license frame
  late double frameWidth;
  late double frameHeight;
  late Rect frameRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameraController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context) != null) {}
    });
  }

  @override
  void dispose() {
    print('LicenseVarification: dispose() called');
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (_isDisposed) return;

  //   final CameraController? cameraController = this.cameraController;

  //   if (cameraController == null || !cameraController.value.isInitialized) {
  //     return;
  //   }

  //   if (state == AppLifecycleState.inactive) {
  //     _disposeCamera();
  //   } else if (state == AppLifecycleState.resumed) {
  //     _setupCameraController();
  //   }
  // }
  void _onReturnFromPreview() {
    // This will be called when returning from LicencePreview
    if (!_isDisposed && mounted) {
      setState(() {
        _capturedImage = null;
        _isCameraInitialized = false;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && mounted) {
          _setupCameraController();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    final CameraController? cameraController = this.cameraController;

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Add a small delay and then reinitialize
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && mounted) {
          _setupCameraController();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _disposeCamera();
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // This is called when returning from another screen
    if (!_isDisposed && mounted && !_isCameraInitialized) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed && mounted) {
          _setupCameraController();
        }
      });
    }
  }

  Future<void> _disposeCamera() async {
    print('_disposeCamera called');
    final CameraController? cameraController = this.cameraController;
    if (cameraController != null) {
      this.cameraController = null;
      try {
        await cameraController.dispose();
        print('Camera controller disposed successfully');
      } catch (e) {
        print('Error disposing camera controller: $e');
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _setupCameraController() async {
    if (_isDisposed) return;

    try {
      await _disposeCamera();
      await Future.delayed(const Duration(milliseconds: 100));

      List<CameraDescription> _cameras = await availableCameras();
      if (_cameras.isNotEmpty && !_isDisposed) {
        cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.high, // Use high resolution for better quality
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await cameraController!.initialize();
        await cameraController!.setFlashMode(FlashMode.off);

        try {
          await cameraController!.setExposureMode(ExposureMode.auto);
          await cameraController!.setFocusMode(FocusMode.auto);
        } catch (e) {
          print('Error setting camera modes: $e');
        }

        if (!_isDisposed && mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (!(cameraController?.value.isInitialized ?? false) ||
        _isCapturing ||
        _isDisposed) {
      print(
        'Cannot capture: camera not initialized or already capturing or disposed',
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      print('Starting image capture...');
      final XFile file = await cameraController!.takePicture();
      print('Image captured successfully: ${file.path}');
      await _processAndCropImage(file);
    } catch (e) {
      print('Error capturing image: $e');
      if (!_isDisposed && mounted) {
        Get.snackbar('Error', 'Failed to capture image: ${e.toString()}');
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _processAndCropImage(XFile file) async {
    try {
      // Get the actual image dimensions
      final imageBytes = await File(file.path).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print("Failed to decode image");
        throw Exception("Failed to decode image");
      }

      // TEMPORARY: Save the full uncropped image first to see what we're working with
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fullImagePath = path.join(
        appDir.path,
        'full_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final File fullImageFile = File(fullImagePath);
      await fullImageFile.writeAsBytes(img.encodeJpg(image, quality: 85));
      print('Full image saved for debugging: $fullImagePath');

      // Get screen dimensions and camera preview info
      final screenSize = MediaQuery.of(context).size;
      final previewSize = cameraController!.value.previewSize!;

      print('=== DEBUG INFO ===');
      print('Screen size: ${screenSize.width} x ${screenSize.height}');
      print('Preview size: ${previewSize.width} x ${previewSize.height}');
      print('Image size: ${image.width} x ${image.height}');

      // Calculate frame dimensions and position (same as UI)
      final frameWidth = screenSize.width * 0.85;
      final frameHeight = screenSize.width * 0.55;
      final frameLeft = (screenSize.width - frameWidth) / 2;
      final frameTop = (screenSize.height - frameHeight) / 2;

      print('Frame size: ${frameWidth} x ${frameHeight}');
      print('Frame position: left=$frameLeft, top=$frameTop');

      // Simple approach: calculate crop based on center percentage
      final centerX = image.width / 2;
      final centerY = image.height / 2;

      // Use the same proportions as the frame
      final cropWidth = (image.width * 0.85).round();
      final cropHeight = (image.width * 0.55)
          .round(); // Note: using width for aspect ratio

      final cropX = (centerX - cropWidth / 2).round();
      final cropY = (centerY - cropHeight / 2).round();

      // Ensure within bounds
      final safeCropX = cropX.clamp(0, image.width - cropWidth);
      final safeCropY = cropY.clamp(0, image.height - cropHeight);
      final safeCropWidth = cropWidth.clamp(1, image.width - safeCropX);
      final safeCropHeight = cropHeight.clamp(1, image.height - safeCropY);

      print(
        'Crop area: x=$safeCropX, y=$safeCropY, w=$safeCropWidth, h=$safeCropHeight',
      );

      // Crop the image
      final img.Image croppedImage = img.copyCrop(
        image,
        x: safeCropX,
        y: safeCropY,
        width: safeCropWidth,
        height: safeCropHeight,
      );

      // Resize if needed
      final img.Image finalImage = safeCropWidth > 800
          ? img.copyResize(croppedImage, width: 800)
          : croppedImage;

      // Save the cropped image
      final String croppedImagePath = path.join(
        appDir.path,
        'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final File croppedFile = File(croppedImagePath);
      await croppedFile.writeAsBytes(img.encodeJpg(finalImage, quality: 85));

      // Clean up
      try {
        await File(file.path).delete();
        print('Temporary file deleted: ${file.path}');
      } catch (e) {
        print('Error deleting temporary file: $e');
      }

      // Clear images from memory
      image.clear();
      croppedImage.clear();
      if (finalImage != croppedImage) finalImage.clear();

      if (!_isDisposed) {
        setState(() {
          _capturedImage = croppedFile;
        });
        if (mounted) {
          await _disposeCamera();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicencePreview(
                imageFile: croppedFile,
                eventId: widget.eventId,
                leadId: widget.leadId,
              ),
            ),
          );
          // Navigator.of(context).pushAndRemoveUntil(
          //   MaterialPageRoute(
          //     builder: (context) => LicencePreview(
          //       imageFile: croppedFile,
          //       eventId: widget.eventId,
          //       leadId: widget.leadId,
          //     ),
          //   ),
          //   (route) => false,
          // );
          _onReturnFromPreview();
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      try {
        await File(file.path).delete();
      } catch (deleteError) {
        print('Error deleting file after processing failure: $deleteError');
      }
      rethrow;
    }
  }
  // Future<void> _processAndCropImage(XFile file) async {
  //   try {
  //     // Get the actual image dimensions
  //     final imageBytes = await File(file.path).readAsBytes();
  //     final image = img.decodeImage(imageBytes);

  //     if (image == null) {
  //       print("Failed to decode image");
  //       throw Exception("Failed to decode image");
  //     }

  //     // Get screen dimensions
  //     final screenSize = MediaQuery.of(context).size;
  //     final screenWidth = screenSize.width;
  //     final screenHeight = screenSize.height;

  //     // Calculate frame dimensions (same as in build method)
  //     final frameWidth = screenWidth * 0.85;
  //     final frameHeight = screenWidth * 0.55;

  //     // Calculate frame position (centered on screen)
  //     final frameLeft = (screenWidth - frameWidth) / 2;
  //     final frameTop = (screenHeight - frameHeight) / 2;

  //     // Calculate the scale between the actual image and the preview
  //     final previewSize = cameraController!.value.previewSize!;
  //     final imageWidth = image.width;
  //     final imageHeight = image.height;

  //     // Calculate scale factors
  //     final scaleX =
  //         imageWidth /
  //         previewSize.height; // Note: swapped for camera orientation
  //     final scaleY =
  //         imageHeight /
  //         previewSize.width; // Note: swapped for camera orientation

  //     // Calculate crop coordinates in the actual image
  //     final cropX = (frameLeft * scaleX).round();
  //     final cropY = (frameTop * scaleY).round();
  //     final cropWidth = (frameWidth * scaleX).round();
  //     final cropHeight = (frameHeight * scaleY).round();

  //     // Ensure coordinates are within bounds
  //     final safeCropX = cropX.clamp(0, imageWidth - 1);
  //     final safeCropY = cropY.clamp(0, imageHeight - 1);
  //     final safeCropWidth = (cropWidth).clamp(1, imageWidth - safeCropX);
  //     final safeCropHeight = (cropHeight).clamp(1, imageHeight - safeCropY);

  //     print('Image dimensions: ${imageWidth}x${imageHeight}');
  //     print(
  //       'Crop parameters: x=$safeCropX, y=$safeCropY, w=$safeCropWidth, h=$safeCropHeight',
  //     );

  //     // Crop the image
  //     final img.Image croppedImage = img.copyCrop(
  //       image,
  //       x: safeCropX,
  //       y: safeCropY,
  //       width: safeCropWidth,
  //       height: safeCropHeight,
  //     );

  //     // Resize if needed to optimize file size
  //     final img.Image finalImage = safeCropWidth > 800
  //         ? img.copyResize(croppedImage, width: 800)
  //         : croppedImage;

  //     // Save the processed image
  //     final Directory appDir = await getApplicationDocumentsDirectory();
  //     final String imagePath = path.join(
  //       appDir.path,
  //       '${DateTime.now().millisecondsSinceEpoch}.jpg',
  //     );
  //     final File croppedFile = File(imagePath);

  //     await croppedFile.writeAsBytes(img.encodeJpg(finalImage, quality: 85));

  //     // Clean up
  //     try {
  //       await File(file.path).delete();
  //       print('Temporary file deleted: ${file.path}');
  //     } catch (e) {
  //       print('Error deleting temporary file: $e');
  //     }

  //     // Clear images from memory
  //     image.clear();
  //     croppedImage.clear();
  //     if (finalImage != croppedImage) finalImage.clear();

  //     if (!_isDisposed) {
  //       setState(() {
  //         _capturedImage = croppedFile;
  //       });

  //       if (mounted) {
  //         await _disposeCamera();
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => LicencePreview(
  //               imageFile: croppedFile,
  //               eventId: widget.eventId,
  //               leadId: widget.leadId,
  //             ),
  //           ),
  //         );

  //         // Call the return handler
  //         _onReturnFromPreview();
  //       }
  //     }
  //   } catch (e) {
  //     print('Error processing image: $e');
  //     try {
  //       await File(file.path).delete();
  //     } catch (deleteError) {
  //       print('Error deleting file after processing failure: $deleteError');
  //     }
  //     rethrow;
  //   }
  // }

  Future<void> submitFeedback(String skipReason) async {
    if (_isDisposed) return;

    setState(() {
      _isUploading = true;
    });
    try {
      print('Event ID: ${widget.eventId}');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? spId = prefs.getString('user_id');
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/events/update/${widget.eventId}',
      );
      final token = await Storage.getToken();
      skip['Overall Ambience'] = skipReason;
      final requestBody = {
        'sp_id': spId,
        'skip_license': skip['Overall Ambience'],
      };
      print(requestBody);
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );
      final responseData = jsonDecode(response.body);
      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');
      print(url.toString());
      if (response.statusCode == 200) {
        print('Feedback submitted successfully');
        if (!_isDisposed && mounted) {
          Get.snackbar('Success', 'License verification skipped successfully');

          // Dispose camera before navigation
          await _disposeCamera();
          print('navigate to new map ');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestdriveMapPage(
                leadId: widget.leadId,
                eventId: widget.eventId,
              ),
            ),
          );
        }
      } else {
        print(
          'Failed to submit feedback : ${responseData['message'].toString()}',
        );
        if (!_isDisposed && mounted) {
          Get.snackbar('Error', 'error due to ${responseData['message']}');
        }
      }
    } catch (e) {
      print('Exception occurred: ${e.toString()}');
      if (!_isDisposed && mounted) {
        Get.snackbar('Error', 'An error occurred: ${e.toString()}');
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculate rectangle dimensions consistently
    final screenSize = MediaQuery.of(context).size;
    frameWidth = screenSize.width * 0.85;
    frameHeight = screenSize.width * 0.55;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? Stack(
                children: [
                  // Camera Preview - properly fitted
                  Positioned.fill(child: _buildCameraPreview()),

                  // Overlay with guidance
                  Positioned.fill(child: _buildOverlay()),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.colorsBlue),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return AspectRatio(
      aspectRatio: cameraController!.value.aspectRatio,
      child: CameraPreview(cameraController!),
    );
  }

  Widget _buildOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    return Stack(
      children: [
        // Darkened overlay with cutout
        ClipPath(
          clipper: InvertedRectangleClipper(
            center: Offset(centerX, centerY),
            width: frameWidth,
            height: frameHeight,
            borderRadius: 12,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        // Frame border - properly centered
        Center(
          child: Container(
            width: frameWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.colorsBlue, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Guidance text
        Positioned(
          top: centerY - frameHeight / 2 - 60,
          left: 0,
          right: 0,
          child: const Text(
            'Align license within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Corner lines - properly centered
        Center(
          child: Container(
            width: frameWidth,
            height: frameHeight,
            child: _buildCornerLines(),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _isUploading ? null : _showSkipDialog,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.skip_next, color: Colors.black87),
                  ],
                ),
              ),

              // Capture button
              InkWell(
                onTap: () {
                  if (!_isUploading && !_isCapturing) {
                    _captureImage();
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _isCapturing ? Colors.grey : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.colorsBlue, width: 3),
                  ),
                  child: Center(
                    child: _isCapturing
                        ? const CircularProgressIndicator(
                            color: AppColors.colorsBlue,
                            strokeWidth: 2,
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: AppColors.colorsBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              ),

              // Placeholder for symmetry
              const SizedBox(width: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCornerLines() {
    const cornerSize = 20.0;

    return Stack(
      children: [
        // Top Left Corner
        Positioned(
          top: 0,
          left: 0,
          child: _buildCorner(cornerSize, isTopLeft: true),
        ),
        // Top Right Corner
        Positioned(
          top: 0,
          right: 0,
          child: _buildCorner(cornerSize, isTopRight: true),
        ),
        // Bottom Left Corner
        Positioned(
          bottom: 0,
          left: 0,
          child: _buildCorner(cornerSize, isBottomLeft: true),
        ),
        // Bottom Right Corner
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildCorner(cornerSize, isBottomRight: true),
        ),
      ],
    );
  }

  Widget _buildCorner(
    double size, {
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CornerPainter(
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
          color: Colors.white,
          lineWidth: 3,
        ),
      ),
    );
  }

  // Show skip confirmation dialog
  Future<void> _showSkipDialog() async {
    if (_isDisposed) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(10),
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  textAlign: TextAlign.center,
                  'Select reason to skip',
                  style: AppFont.popupTitleBlack(context),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Divider(height: 1, color: Colors.grey.shade200),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submitFeedback("License not available");
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'License not available',
                      style: AppFont.mediumText14(context),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submitFeedback("Client denied");
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Client denied',
                      style: AppFont.mediumText14(context),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submitFeedback("Already taken");
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Already taken',
                      style: AppFont.mediumText14(context),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submitFeedback("Just exploring");
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Just exploring',
                      style: AppFont.mediumText14(context),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submitFeedback("Time constraints");
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Time constraints',
                      style: AppFont.mediumText14(context),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    submitFeedback("Others");
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Others',
                      style: AppFont.mediumText14(context),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },

              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.colorsBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) >
            Duration(milliseconds: _exitTimeInMillis)) {
      _lastBackPressTime = now;

      // Show a bottom slide dialog
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Exit Test Drive',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorsBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Cancel button (White)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Dismiss dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.colorsBlue,
                            side: const BorderSide(color: AppColors.colorsBlue),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Exit button (Blue) - Modified to navigate to HomeScreen
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => BottomNavigation(),
                              ),
                              (route) => false, // This clears the stack
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorsBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      );
      return false;
    }
    return true;
  }
}

// Custom painter for license corner lines
class CornerPainter extends CustomPainter {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;
  final Color color;
  final double lineWidth;

  CornerPainter({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
    this.color = Colors.white,
    this.lineWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    if (isTopLeft) {
      // Draw top line
      canvas.drawLine(Offset(0, 0), Offset(size.width * 0.7, 0), paint);
      // Draw left line
      canvas.drawLine(Offset(0, 0), Offset(0, size.height * 0.7), paint);
    } else if (isTopRight) {
      // Draw top line
      canvas.drawLine(
        Offset(size.width * 0.3, 0),
        Offset(size.width, 0),
        paint,
      );
      // Draw right line
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height * 0.7),
        paint,
      );
    } else if (isBottomLeft) {
      // Draw bottom line
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width * 0.7, size.height),
        paint,
      );
      // Draw left line
      canvas.drawLine(
        Offset(0, size.height * 0.3),
        Offset(0, size.height),
        paint,
      );
    } else if (isBottomRight) {
      // Draw bottom line
      canvas.drawLine(
        Offset(size.width * 0.3, size.height),
        Offset(size.width, size.height),
        paint,
      );
      // Draw right line
      canvas.drawLine(
        Offset(size.width, size.height * 0.3),
        Offset(size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Changed to false for better performance
  }
}

// Custom clipper to create the transparent rectangle in the middle
class InvertedRectangleClipper extends CustomClipper<Path> {
  final Offset center;
  final double width;
  final double height;
  final double borderRadius;

  InvertedRectangleClipper({
    required this.center,
    required this.width,
    required this.height,
    this.borderRadius = 0,
  });

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutLeft = center.dx - width / 2;
    final cutoutTop = center.dy - height / 2;
    final cutoutRight = center.dx + width / 2;
    final cutoutBottom = center.dy + height / 2;

    final cutoutPath = Path();

    if (borderRadius > 0) {
      cutoutPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cutoutLeft, cutoutTop, cutoutRight, cutoutBottom),
          Radius.circular(borderRadius),
        ),
      );
    } else {
      cutoutPath.addRect(
        Rect.fromLTRB(cutoutLeft, cutoutTop, cutoutRight, cutoutBottom),
      );
    }

    // Subtracts the cutout from the full size to create the inverted effect
    return Path.combine(PathOperation.difference, path, cutoutPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false; // Changed for better performance
}
