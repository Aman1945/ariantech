import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/pages/login_steps/biometric_screen.dart';
import 'package:smartassist/pages/login_steps/first_screen.dart';
import 'package:smartassist/pages/login_steps/forget_password.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/utils/admin_bottomnavigation.dart';
import 'package:smartassist/utils/biometric_prefrence.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/connection_service.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/style_text.dart';
import 'package:smartassist/utils/token_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smartassist/widgets/interneterror_screed.dart';

class LoginPage extends StatefulWidget {
  final String email;
  final Function()? onLoginSuccess;
  const LoginPage({
    super.key,
    required this.email,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController newPwdController = TextEditingController();
  bool _isPasswordObscured = true;
  bool isLoading = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  // bool isAdmin = false;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Slide animation from left (-1.5) to center (0)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0), // Start from left
      end: Offset.zero, // Move to center
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    newEmailController.dispose();
    newPwdController.dispose();
    super.dispose();
  }

  // Helper method to check if input is email or excellence ID
  bool _isEmail(String input) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input);
  }

  // Helper method to validate excellence ID format (customize as needed)
  bool _isValidExcellenceId(String input) {
    return RegExp(r'^[0-9]{6}$').hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content - always visible
              Center(
                child: SingleChildScrollView(
                  // keyboardDismissBehavior:
                  //     ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image with animation applied
Hero(
  tag: 'logo',
  child: SlideTransition(
    position: _slideAnimation,
    child: Image.asset(
      'assets/logo-black.png', // ✅ your PNG file path
      width: MediaQuery.of(context).size.width * .7,        
      fit: BoxFit.contain,
    ),
  ),
),

                        const SizedBox(height: 20),
                        const StyleText('Login to Smart Assist'),

                        // Only show the form after animation starts
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _controller.value,
                              child: child,
                            );
                          },
                          child: Column(
                            children: [
                              const SizedBox(height: 32),
                              buildInputLabel('Email or Excellence ID'),
                              buildTextField(
                                newEmailController,
                                'Enter Email or Excellence ID',
                                false,
                                keyboardType: TextInputType
                                    .text, // Changed from emailAddress to text
                              ),
                              const SizedBox(height: 25),
                              buildInputLabel('Password'),
                              buildTextField(
                                inputLength: 20,
                                newPwdController,
                                'Enter Password',
                                true,
                              ),
                              const SizedBox(height: 32),
                              buildLoginButton(),
                              const SizedBox(height: 20),
                              buildRichText(
                                "Forgot Password ? ",
                                "Reset Password",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (cotext) =>
                                          const ForgetPassword(text: ''),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              buildRichText(
                                "First time logging in ? ",
                                "Verify OTP",
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EmailSetupScreen(text: ''),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for Login Button
  Widget buildLoginButton() {
    return ElevatedButton(
      // onPressed: isLoading ? null : submitBtn,
      onPressed: isLoading
          ? null
          : () {
              FocusScope.of(context).unfocus(); // Dismiss the keyboard
              submitBtn(); // Call the login function
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.colorsBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // elevation: 4,
        // shadowColor: AppColors.colorsBlue.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Login',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  // Widget for Input Labels
  Widget buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.fontColor,
          ),
        ),
      ),
    );
  }

  // Widget for TextFields
  Widget buildTextField(
    TextEditingController controller,
    String hint,
    bool isPassword, {
    TextInputType keyboardType = TextInputType.text,
    int? inputLength,
  }) {
    return TextField(
      inputFormatters: [LengthLimitingTextInputFormatter(inputLength)],
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      controller: controller,
      obscureText: isPassword ? _isPasswordObscured : false,
      keyboardType: keyboardType,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        fillColor: const Color(0xffF3F9FF),
        filled: true,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.hintTextColor, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.fontColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.colorsBlue, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Widget for RichText Links
  Widget buildRichText(String text, String linkText, VoidCallback onTap) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.fontColor,
        ),
        children: [
          TextSpan(
            text: linkText,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.colorsBlue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }

  Future<void> submitBtn() async {
    if (!mounted) return;
    final emailOrExcellence = newEmailController.text.trim();
    final pwd = newPwdController.text.trim();

    if (emailOrExcellence.isEmpty || pwd.isEmpty) {
      showErrorMessage(
        context,
        message: 'Email/Excellence ID and Password cannot be empty.',
      );
      return;
    }

    // Validate input format
    if (!_isEmail(emailOrExcellence) &&
        !_isValidExcellenceId(emailOrExcellence)) {
      showErrorMessage(
        context,
        message: 'Please enter a valid email address or Excellence ID.',
      );
      return;
    }

    await ConnectionService().checkConnection();
    final isConnected = ConnectionService().isConnected;
    print("Internet connection status: $isConnected");
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: InternetErrorWidget(
            onRetry: () {
              Navigator.pop(context);
              submitBtn(); // retry login
            },
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? deviceToken = '';
      try {
        // deviceToken = await FirebaseMessaging.instance.getToken();

        deviceToken = await FirebaseMessaging.instance.getToken();
        if (deviceToken == null) {
          throw Exception('Failed to retrieve device token.');
        }
      } catch (e) {
        print("Error retrieving device token: $e");
      }

      // Determine if input is email or excellence ID
      Map<String, dynamic> loginData = {
        "password": pwd,
        "device_token": deviceToken,
      };

      if (_isEmail(emailOrExcellence)) {
        loginData["email"] = emailOrExcellence;
      } else {
        loginData["excellence"] = emailOrExcellence;
      }

      final response = await LeadsSrv.onLogin(loginData);

      if (!mounted) return;

      if (response['isSuccess'] == true && response['user'] != null) {
        final user = response['user'];
        final userId = user['user_id'];
        final authToken = response['token'];
        final userRole = user['user_role'];
        final userEmail = user['email'] ?? emailOrExcellence;
        final rawAdmin = user['isAdmin'];
        final bool isAdmin = rawAdmin is bool
            ? rawAdmin
            : (rawAdmin.toString().toLowerCase() == "true");

        if (userId != null && authToken != null) {
          // Save authentication data
          // await TokenManager.saveAuthData(
          //   authToken,
          //   userId,
          //   userRole,
          //   userEmail,
          //   isAdmin,
          // );
          await TokenManager.saveAuthData(
            token: authToken,
            userId: userId,
            userRole: userRole,
            email: userEmail,
            isAdmin: isAdmin,
          );
          String successMessage =
              response['message']?.toString() ?? 'Login Successful';
          Get.snackbar(
            'Success',
            successMessage,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Reset all biometric preferences since this is a fresh login
          await BiometricPreference.resetBiometricPreferences();

          // Check if device supports biometrics
          final LocalAuthentication auth = LocalAuthentication();
          bool canCheckBiometrics = false;

          try {
            canCheckBiometrics = await auth.canCheckBiometrics;
            List<BiometricType> availableBiometrics = await auth
                .getAvailableBiometrics();
            print("Available biometrics: $availableBiometrics");
          } catch (e) {
            print("Error checking biometric capability: $e");
          }

          if (canCheckBiometrics) {
            // Navigate to BiometricScreen with isFirstTime flag
            Get.offAll(() => BiometricScreen(isFirstTime: true));
          } else {
            await BiometricPreference.setUseBiometric(false);
            if (isAdmin == true) {
              Get.offAll(() => AdminDealerall());
            } else {
              Get.offAll(() => BottomNavigation());
            }
          }

          widget.onLoginSuccess?.call();
        } else {
          String errorMessage =
              response['error'] ??
              response['message'] ??
              'Something went wrong';
          Get.snackbar(
            'Error',
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        String errorMessage =
            response['error'] ?? response['message'] ?? 'Something went wrong';
        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (error) {
      if (!mounted) return;
      print('error');
      Get.snackbar(
        'Error',
        '${error.toString()}',
        backgroundColor: Colors.red[500],
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
