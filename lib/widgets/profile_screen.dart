import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/utils/toast_msg.dart';

class ProfileScreen extends StatefulWidget {
  final Future<void> Function() refreshDashboard;
  const ProfileScreen({super.key, required this.refreshDashboard});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  bool isLoading = true;
  String? userId, name, email, location, mobile, userRole, profilePic;
  double rating = 0.0;
  double professionalism = 0.0;
  double efficiency = 0.0;
  double responseTime = 0.0;
  double productKnowledge = 0.0;
  double responsiveness = 0.0;

  bool isEditingMobile = false;
  TextEditingController _mobileController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Screenshot controllers
  ScreenshotController _evaluationScreenshotController = ScreenshotController();
  ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _evaluationKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    fetchProfileData();
    _screenshotController = ScreenshotController();
    _evaluationScreenshotController = ScreenshotController();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchProfileData() async {
    final data = await LeadsSrv.profileData();
    if (mounted) {
      setState(() {
        _mobileController.text = mobile ?? '';
        userId = data['user_id'];
        name = data['name'];
        email = data['email'];
        location = data['dealer_location'];
        mobile = data['phone'];
        profilePic = data['profile_pic'];
        userRole = data['user_role'];

        rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;

        final evaluation = data['evaluation'];
        if (evaluation != null) {
          professionalism = evaluation['knowledge'] != null
              ? evaluation['knowledge'] / 10
              : 0.0;
          efficiency = evaluation['dependability'] != null
              ? evaluation['dependability'] / 10
              : 0.0;
          responseTime = evaluation['easy_business'] != null
              ? evaluation['easy_business'] / 10
              : 0.0;
          productKnowledge = evaluation['extra_efforts'] != null
              ? evaluation['extra_efforts'] / 10
              : 0.0;

          responsiveness = evaluation['responsiveness'] != null
              ? evaluation['responsiveness'] / 10
              : 0.0;
        }
        widget.refreshDashboard();
        isLoading = false;

        // Start animations once data is loaded
        _fadeController.forward();
        _slideController.forward();

        // print('this is the obj ${json.decode(response.body)}');
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to fetch profile data');
    }
  }

  Future<void> _showPermissionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs access to your photos to select a profile picture. Do you want to grant permission?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _requestPermissionsAndPick(); // Then request permissions
              },
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
  }

  // Request permissions and proceed with image picking
  Future<void> _requestPermissionsAndPick() async {
    final hasPermission = await _requestPermissions();

    if (hasPermission) {
      _proceedWithImagePicking();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Photo access is required to select profile pictures. You can enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Open device settings
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Check if permission is already granted
      if (await Permission.photos.isGranted) {
        return true;
      }

      // For Android 13+ (API 33+), request photos permission
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status == PermissionStatus.granted;
      }

      // For older Android versions, request storage permission
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    }
    return true; // iOS permissions are handled automatically
  }

  Future<void> _updateMobileOnly() async {
    final token = await Storage.getToken();
    final uri = Uri.parse(
      'https://api.smartassistapp.in/api/users/profile/set',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['phone'] = _mobileController.text; // only mobile, no file

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        print("✅ Mobile updated: ${res['message']}");
        print("✅ Mobile updated: ${res['body']}");
        setState(() {
          mobile = _mobileController.text;
        });
        showSuccessToast(message: res['message'] ?? "Mobile updated");
        // showSuccessMessage(
        //   context,
        //   message: res['message'] ?? "Mobile updated",
        // );
        await fetchProfileData();
      } else {
        final res = json.decode(response.body);
        showErrorMessage(context, message: res['message'] ?? "Mobile updated");
        print("❌ Failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Error updating mobile: $e");
    }
  }

  Future<void> _proceedWithImagePicking() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    setState(() {
      _profileImage = imageFile;
      _isUploading = true;
    });

    final token = await Storage.getToken();
    final uri = Uri.parse(
      'https://api.smartassistapp.in/api/users/profile/set',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile(
          'file',
          imageFile.readAsBytes().asStream(),
          imageFile.lengthSync(),
          filename: path.basename(imageFile.path),
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        print(response.body);
        print('this is the update img');
        setState(() {
          profilePic = res;
          _profileImage = null;
        });
        // fetchProfileData();
      }
    } catch (e) {
      print("❌ Upload error: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      deleteImg(context);
      _profileImage = null;
      profilePic = null;
    });
  }

  Future<void> deleteImg(BuildContext context) async {
    try {
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/users/profile/remove-pic',
      );
      final token = await Storage.getToken();

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error';
        showSuccessMessage(context, message: errorMessage);
        fetchProfileData();
      }
    } catch (e) {
      print('Exception occurred: ${e.toString()}');
    }
  }

  Future<void> _shareFullBodyScreenshot() async {
    try {
      await Share.share(
        'Hi this is'
        ' ${name ?? "User"},\n'
        'from Ariantech solutions, India.\n\n'
        'Rating: ${rating.toStringAsFixed(1)}/5\n'
        'My Performance Evaluation:\n'
        'Professionalism: ${(professionalism * 100).toStringAsFixed(0)}%\n'
        'Efficiency: ${(efficiency * 100).toStringAsFixed(0)}%\n'
        'Response Time: ${(responseTime * 100).toStringAsFixed(0)}%\n'
        'Product Knowledge: ${(productKnowledge * 100).toStringAsFixed(0)}%\n\n'
        'Feel free to share your feedback here 👇.\n\n'
        'https://feedbacks.smartassistapp.in/user-feedback/feedback/${userId}\n\n',
      );
    } catch (e) {
      showErrorMessage(
        context,
        message: 'Failed to share profile: ${e.toString()}',
      );
      showErrorMessage(
        context,
        message: 'Failed to share profile: ${e.toString()}',
      );
      // Get.snackbar(
      //   'Error',
      //   'Failed to share profile: ${e.toString()}',
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    }
  }

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Responsive padding and sizing
    final horizontalPadding = isDesktop
        ? 40.0
        : isTablet
        ? 24.0
        : 16.0;
    final cardPadding = isDesktop
        ? 32.0
        : isTablet
        ? 24.0
        : 20.0;
    final profileImageRadius = isDesktop
        ? 80.0
        : isTablet
        ? 70.0
        : 60.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.colorsBlue,
            // borderRadius: BorderRadius.circular(8),
          ),

          child: InkWell(
            onTap: () async {
              await widget.refreshDashboard();
              Get.back();
            },
            child: Icon(
              FontAwesomeIcons.angleLeft,
              color: Colors.white,
              size: _isSmallScreen(context) ? 18 : 20,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _shareFullBodyScreenshot,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(color: AppColors.colorsBlue),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.colorsBlue),
                strokeWidth: 2,
              ),
            )
          : Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.grey[50],
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Profile Header
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.only(
                          top:
                              kToolbarHeight +
                              MediaQuery.of(context).padding.top +
                              20,
                          bottom: 24,
                          left: horizontalPadding,
                          right: horizontalPadding,
                        ),
                        child: _buildCleanProfileHeader(
                          profileImageRadius,
                          isDesktop,
                          isTablet,
                        ),
                      ),
                    ),

                    // Content Cards
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Profile Details Card
                          _buildCleanCard(
                            child: _buildProfileDetails(cardPadding, isDesktop),
                          ),

                          SizedBox(height: 16),

                          // Evaluation Card
                          _buildCleanCard(
                            child: _buildEvaluationSection(
                              cardPadding,
                              isDesktop,
                              isTablet,
                            ),
                          ),

                          SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCleanProfileHeader(
    double radius,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Profile Image with Clean Styling
        Stack(
          alignment: Alignment.center,
          children: [
            // Simple profile image container
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 2),
              ),
              child: _profileImage != null
                  ? CircleAvatar(
                      radius: radius,
                      backgroundImage: FileImage(_profileImage!),
                    )
                  : (profilePic != null && profilePic!.isNotEmpty
                        ? CircleAvatar(
                            radius: radius,
                            // backgroundImage: NetworkImage(profilePic!),
                            backgroundImage: NetworkImage(
                              '$profilePic?v=${DateTime.now().millisecondsSinceEpoch}',
                            ),
                          )
                        : CircleAvatar(
                            radius: radius,
                            backgroundColor: Colors.grey[100],
                            child: Text(
                              (name?.isNotEmpty ?? false)
                                  ? name![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: radius * 0.6,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
            ),

            if (_isUploading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.colorsBlue),
                strokeWidth: 2,
              ),

            // Clean action buttons
            if (_profileImage != null ||
                (profilePic != null && profilePic!.isNotEmpty))
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (!_isUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.fontColor,
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _showPermissionDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: isDesktop ? 20 : 16),

        // Name with clean typography
        Text(
          name ?? '',
          style: TextStyle(
            fontSize: isDesktop
                ? 24
                : isTablet
                ? 22
                : 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        Text(
          userRole ?? 'User',
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: isDesktop ? 16 : 12),

        // Simple star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: index < rating ? Colors.amber[600] : Colors.grey[300],
                size: isDesktop
                    ? 28
                    : isTablet
                    ? 26
                    : 24,
              ),
            );
          }),
        ),

        // const SizedBox(height: 6),

        // Text(
        //   '(0 reviews)',
        //   style: TextStyle(
        //     fontSize: 13,
        //     color: Colors.grey[500],
        //     fontWeight: FontWeight.w400,
        //   ),
        //   textAlign: TextAlign.center,
        // ),
      ],
    );
  }

  Widget _buildCleanCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildProfileDetails(double padding, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),

          SizedBox(height: 20),

          _buildCleanProfileItem(
            'Email',
            email ?? '',
            Icons.email_outlined,
            isDesktop,
          ),
          const SizedBox(height: 12),
          _buildCleanProfileItem(
            'Location',
            location ?? '',
            Icons.location_on_outlined,
            isDesktop,
          ),
          const SizedBox(height: 12),
          _buildCleanProfileItem(
            'Mobile',
            mobile ?? '',
            Icons.phone_outlined,
            isDesktop,
            isEditable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanProfileItem(
    String label,
    String value,
    IconData icon,
    bool isDesktop, {
    bool isEditable = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                isEditable && isEditingMobile
                    ? TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // only digits
                          LengthLimitingTextInputFormatter(10), // max 10 digits
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          hintText: "Enter Mobile",
                          border: UnderlineInputBorder(),
                        ),
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[900],
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[900],
                        ),
                      ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: Icon(
                isEditingMobile ? Icons.check : Icons.edit,
                color: AppColors.colorsBlue,
                size: 20,
              ),
              onPressed: () {
                if (isEditingMobile) {
                  _updateMobileOnly();
                }
                setState(() {
                  isEditingMobile = !isEditingMobile;
                });
              },
            ),
        ],
      ),
    );
  }

  // Widget _buildCleanProfileItem(
  //   String label,
  //   String value,
  //   IconData icon,
  //   bool isDesktop,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: Colors.grey[100],
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(icon, size: 20, color: Colors.grey[600]),
  //         ),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 label,
  //                 style: TextStyle(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.grey[600],
  //                 ),
  //               ),
  //               const SizedBox(height: 2),
  //               Text(
  //                 value,
  //                 style: TextStyle(
  //                   fontSize: isDesktop ? 16 : 15,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.grey[900],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEvaluationSection(
    double padding,
    bool isDesktop,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Evaluation',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),

          SizedBox(height: 20),

          _buildCleanEvaluationProgress(
            'Professionalism',
            professionalism,
            isDesktop,
          ),
          const SizedBox(height: 16),
          _buildCleanEvaluationProgress(
            'Service Efficiency',
            efficiency,
            isDesktop,
          ),
          const SizedBox(height: 16),
          _buildCleanEvaluationProgress(
            'Response Time',
            responseTime,
            isDesktop,
          ),
          const SizedBox(height: 16),
          _buildCleanEvaluationProgress(
            'Product Knowledge',
            productKnowledge,
            isDesktop,
          ),
          const SizedBox(height: 16),
          _buildCleanEvaluationProgress(
            'Product Responsiveness',
            responsiveness,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanEvaluationProgress(
    String label,
    double percentage,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.colorsBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: AppColors.colorsBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
