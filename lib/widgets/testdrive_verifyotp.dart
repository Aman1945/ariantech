import 'dart:convert';
import 'package:flutter_svg/svg.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/button.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:smartassist/utils/token_manager.dart';
import 'package:smartassist/widgets/testdrive_camera_screen.dart';
import 'package:sms_autofill/sms_autofill.dart';

class TestdriveVerifyotp extends StatefulWidget {
  static const int _otpLength = 6;
  final String eventId;
  final String leadId;
  final String email;
  final String mobile;
  final TextStyle? style;

  const TestdriveVerifyotp({
    super.key,
    required this.email,
    this.style,
    required this.eventId,
    required this.leadId,
    required this.mobile,
  });

  @override
  State<TestdriveVerifyotp> createState() => _TestdriveVerifyotpState();
}

class _TestdriveVerifyotpState extends State<TestdriveVerifyotp>
    with CodeAutoFill {
  final List<TextEditingController> _controllers = List.generate(
    TestdriveVerifyotp._otpLength,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    TestdriveVerifyotp._otpLength,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResendingOTP = false;
  int _resendTimer = 30;
  String? appSignature; // Add this for SMS autofill

  // exit popup
  DateTime? _lastBackPressTime;
  final int _exitTimeInMillis = 2000;

  @override
  void initState() {
    super.initState();
    tdLogin();
    _startResendTimer();
    _initSmsListener();
  }

  Future<void> tdLogin() async {
    try {
      final username = {'username': 'jlrsa-admin070825'};
      Map<String, dynamic>? response = await LeadsSrv.tdLoginToken(username);

      if (response != null) {
        print("Response received token: $response");

        if (response.containsKey('token')) {
          String token = response['token'];
          await TokenManager.saveTdAuthToken(tdToken: token);
          print('saved token $token');
        } else {
          String errorMessage =
              response['error'] ??
              response['message'] ??
              'Something went wrong';
          showErrorMessageGetx(message: errorMessage);
        }
      } else {
        print("Error: API response is null");
        showErrorMessageGetx(
          message: 'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener(); // Unregister SMS listener
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Initialize SMS autofill listener
  void _initSmsListener() async {
    // Get app signature for SMS autofill
    appSignature = await SmsAutoFill().getAppSignature;

    // Listen for SMS
    await SmsAutoFill().listenForCode();
  }

  // Handle automatic OTP filling
  @override
  void codeUpdated() {
    if (code != null && code!.length == TestdriveVerifyotp._otpLength) {
      // Fill OTP fields automatically
      for (int i = 0; i < TestdriveVerifyotp._otpLength; i++) {
        _controllers[i].text = code![i];
      }
      setState(() {});

      // Optionally auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _handleVerification();
        }
      });
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderImage(),
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 10),
                    _buildEmailInfo(),
                    const SizedBox(height: 20),
                    _buildOTPFields(),
                    const SizedBox(height: 20),
                    _buildResendOption(),
                    Row(
                      children: [
                        Expanded(child: _cancelButton()),
                        Expanded(child: _buildVerifyButton()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildHeaderImage() {
  return Hero(
    tag: 'logo',
    child: Image.asset(
      'assets/logo-black.png', // ✅ Replace with your PNG file path
      width: MediaQuery.of(context).size.width * .3,
      fit: BoxFit.contain,
    ),
  );
}

  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text('Start Test drive', style: AppFont.popupTitle(context)),
    );
  }

  Widget _buildEmailInfo() {
    bool isEmailHidden = true;
    String mobile = widget.mobile;
    String emailPart = widget.email;

    String hiddenMobile = _hideMobileNumber(mobile);
    String hiddenEmail = _hideEmail(emailPart);

    String message =
        'Enter OTP sent to $hiddenMobile & ${isEmailHidden ? hiddenEmail : emailPart} to continue';

    return Text(
      message,
      textAlign: TextAlign.center,
      style: AppFont.mediumText14(context),
    );
  }

  // Helper to hide mobile number
  String _hideMobileNumber(String mobile) {
    if (mobile.length >= 10) {
      return mobile.substring(0, 3) + '*****' + mobile.substring(8);
    } else {
      return mobile;
    }
  }

  // Helper to hide email
  String _hideEmail(String email) {
    if (!email.contains('@')) return email;

    List<String> parts = email.split('@');
    String namePart = parts[0];
    String domainPart = parts[1];

    if (namePart.length <= 2) {
      return '***@$domainPart';
    } else {
      String visible = namePart.substring(0, 2);
      return '$visible***@$domainPart';
    }
  }

  Widget _buildOTPFields() {
    return AutofillGroup(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            TestdriveVerifyotp._otpLength,
            (index) => Container(
              margin: EdgeInsets.only(
                right: index < TestdriveVerifyotp._otpLength - 1 ? 8.0 : 0,
              ),
              width: 45,
              height: 50,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                autofillHints: index == 0 ? [AutofillHints.oneTimeCode] : null,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.colorsBlue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: (value) => _handleOTPInput(value, index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildOTPFields() {
  //   final screenWidth = MediaQuery.of(context).size.width;
  //   final availableWidth = screenWidth - 32;
  //   final spacing = 8.0;
  //   final fieldWidth =
  //       (availableWidth - (spacing * (TestdriveVerifyotp._otpLength - 1))) /
  //       TestdriveVerifyotp._otpLength;

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8),
  //     child: FittedBox(
  //       fit: BoxFit.scaleDown,
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: List.generate(
  //           TestdriveVerifyotp._otpLength,
  //           (index) => Container(
  //             margin: EdgeInsets.only(
  //               right: index < TestdriveVerifyotp._otpLength - 1 ? spacing : 0,
  //             ),
  //             width: fieldWidth.clamp(35, 45),
  //             height: 50,
  //             child: TextFormField(
  //               controller: _controllers[index],
  //               focusNode: _focusNodes[index],
  //               keyboardType: TextInputType.number,
  //               textAlign: TextAlign.center,
  //               maxLength: 1,
  //               // Add autofill hints for better SMS recognition
  //               autofillHints: index == 0 ? [AutofillHints.oneTimeCode] : null,
  //               style: GoogleFonts.poppins(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //               decoration: InputDecoration(
  //                 counterText: '',
  //                 contentPadding: EdgeInsets.zero,
  //                 enabledBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: Colors.grey.shade300),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderSide: const BorderSide(color: AppColors.colorsBlue, width: 2),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 errorBorder: OutlineInputBorder(
  //                   borderSide: const BorderSide(color: Colors.red),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //               ),
  //               inputFormatters: [
  //                 FilteringTextInputFormatter.digitsOnly,
  //                 LengthLimitingTextInputFormatter(1),
  //               ],
  //               onChanged: (value) => _handleOTPInput(value, index),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildResendOption() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: "Didn't receive the code? ",
        style: AppFont.mediumText14(context),
        children: [
          TextSpan(
            text: _resendTimer > 0 ? 'Resend in ${_resendTimer}s' : 'Resend',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _resendTimer > 0 ? Colors.grey : AppColors.colorsBlue,
              decoration: _resendTimer > 0 ? null : TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = _resendTimer > 0 ? null : _handleResendOTP,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 8),
      child: ElevatedButton(
        onPressed: () async {
          await _handleVerification();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorsBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Button(
                'Verify',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _cancelButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.containerPopBg,
          foregroundColor: AppColors.fontColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Button(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _handleOTPInput(String value, int index) {
    if (value.isNotEmpty && index < TestdriveVerifyotp._otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleResendOTP() async {
    if (_isResendingOTP) return;

    setState(() => _isResendingOTP = true);

    try {
      await SmsAutoFill().listenForCode();

      if (!mounted) return;

      setState(() => _resendTimer = 30);
      _startResendTimer();
      _getOtp(widget.eventId);
      showSuccessMessage(context, message: 'OTP resent successfully');
    } catch (error) {
      if (!mounted) return;
      showErrorMessage(context, message: 'Failed to resend OTP');
      debugPrint('Resend OTP error: $error');
    } finally {
      if (mounted) {
        setState(() => _isResendingOTP = false);
      }
    }
  }

  Future<void> _getOtp(String eventId) async {
    final success = await LeadsSrv.getOtp(eventId: eventId);

    if (success) {
      print('OTP Send');
    } else {
      print('Error');
    }

    if (mounted) setState(() {});
  }

  Future<void> _handleVerification() async {
    final otpString = _controllers.map((controller) => controller.text).join();

    if (otpString.length != TestdriveVerifyotp._otpLength) {
      showErrorMessage(context, message: 'Please enter all digits');
      return;
    }

    if (int.tryParse(otpString) == null) {
      showErrorMessage(context, message: 'Please enter valid digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://api.smartassistapp.in/api/events/${widget.eventId}/verify-otp',
      );
      final token = await Storage.getToken();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"otp": int.parse(otpString)}),
      );

      if (!mounted) return;

      print('this is the final otp send ${jsonDecode.toString()}');
      print('this is the final otp send ${response.body}');
      final decoded = jsonDecode(response.body);

      print(response.body);

      if (response.statusCode == 200) {
        final successMessage =
            decoded['message'] ?? 'OTP verified successfully';
        showSuccessMessage(context, message: successMessage);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LicenseVarification(
              eventId: widget.eventId,
              leadId: widget.leadId,
            ),
          ),
        );
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(
        //     builder: (context) => LicenseVarification(
        //       eventId: widget.eventId,
        //       leadId: widget.leadId,
        //     ),
        //   ),
        //   (route) => false,
        // );
      } else {
        final errorMessage =
            decoded['message'] ?? 'Invalid OTP. Please try again.';
        showErrorMessage(context, message: errorMessage);
      }
    } catch (error) {
      if (!mounted) return;
      showErrorMessage(
        context,
        message: 'Verification failed. Please try again.',
      );
      debugPrint('OTP verification error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) >
            Duration(milliseconds: _exitTimeInMillis)) {
      _lastBackPressTime = now;

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
                  'Exit Test',
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => BottomNavigation(),
                              ),
                              (route) => false,
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
