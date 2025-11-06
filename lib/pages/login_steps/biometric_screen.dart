// biometric_screen.dart - Modified to redirect to login when user declines biometrics
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/services/notifacation_srv.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/utils/admin_bottomnavigation.dart';
import 'package:smartassist/utils/biometric_prefrence.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/pages/login_steps/login_page.dart';
import 'package:smartassist/utils/token_manager.dart';

class BiometricScreen extends StatefulWidget {
  final bool isFirstTime;
  // final bool isAdmin;

  const BiometricScreen({
    super.key,
    this.isFirstTime = false,
    // required this.isAdmin, // Flag to indicate if this is the first time after login
  });

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isAuthenticating = false;
  String _authStatus = 'Verifying your identity';
  bool _mounted = true;
  bool _canCheckBiometrics = false;
  bool _showBiometricChoice = false;
  bool _useBiometric = false;

  // Track available biometric types
  Map<String, bool> _availableBiometrics = {};
  List<String> _failedBiometricTypes = []; // Track which ones failed

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    BiometricPreference.printAllPreferences(); // For debugging
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    if (!_mounted) return;

    try {
      // Check if device supports biometrics
      _canCheckBiometrics = await auth.canCheckBiometrics;
      _availableBiometrics = await BiometricPreference.getAvailableBiometrics();

      print("Device supports biometrics: $_canCheckBiometrics");
      print("Available biometrics: $_availableBiometrics");

      if (!_mounted) return;

      // If this is the first time after login (biometric setup screen)
      if (widget.isFirstTime && _canCheckBiometrics) {
        bool hasMadeBiometricChoice =
            await BiometricPreference.getHasMadeBiometricChoice();

        if (!hasMadeBiometricChoice) {
          // User hasn't made a choice yet - show the setup UI
          setState(() {
            _showBiometricChoice = true;
          });
        } else {
          // User already made a choice previously
          bool shouldUseBiometric = await _shouldUseBiometric();

          if (shouldUseBiometric) {
            // User previously enabled biometrics
            setState(() {
              _useBiometric = true;
            });
            // Small delay before authentication prompt
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_mounted) {
                _authenticateWithFallback();
              }
            });
          } else {
            // User previously declined biometrics, redirect to login
            _redirectToLogin();
          }
        }
      } else {
        // Regular app open - check saved preference
        bool shouldUseBiometric = await _shouldUseBiometric();
        bool hasMadeBiometricChoice =
            await BiometricPreference.getHasMadeBiometricChoice();

        if (!_mounted) return;

        print("shouldUseBiometric: $shouldUseBiometric");
        print(
          "hasMadeBiometricChoice from preferences: $hasMadeBiometricChoice",
        );

        if (shouldUseBiometric && _canCheckBiometrics) {
          // User enabled biometrics, show authentication
          setState(() {
            _useBiometric = true;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_mounted) {
              _authenticateWithFallback();
            }
          });
        } else {
          // User declined biometrics (or no choice made), redirect to login
          _redirectToLogin();
        }
      }
    } catch (e) {
      if (!_mounted) return;

      print("Error checking biometrics: $e");
      // On error, redirect to login
      _redirectToLogin();
    }
  }

  // New method to check if any biometric method is enabled
  Future<bool> _shouldUseBiometric() async {
    // Check if general biometric is enabled
    bool generalBiometric = await BiometricPreference.getUseBiometric();

    // Check if any specific biometric type is enabled
    bool faceIdEnabled = await BiometricPreference.getUseFaceId();
    bool fingerprintEnabled = await BiometricPreference.getUseFingerprint();

    // Return true if general biometric is enabled OR any specific type is enabled
    return generalBiometric || faceIdEnabled || fingerprintEnabled;
  }

  // Main authentication method with intelligent fallback
  Future<void> _authenticateWithFallback() async {
    if (!_mounted) return;

    setState(() {
      isAuthenticating = true;
      _authStatus = 'Verifying your identity';
    });

    // Get list of available and enabled biometric types
    List<String> biometricTypesToTry = await _getBiometricTypesToTry();

    print("Biometric types to try: $biometricTypesToTry");

    if (biometricTypesToTry.isEmpty) {
      // No biometric types available, go to login
      _redirectToLogin();
      return;
    }

    // Try each biometric type until one succeeds or all fail
    bool authenticationSuccessful = false;

    for (String biometricType in biometricTypesToTry) {
      if (!_mounted) return;

      // Skip if this type already failed
      if (_failedBiometricTypes.contains(biometricType)) {
        continue;
      }

      try {
        print("Trying authentication with: $biometricType");

        setState(() {
          _authStatus = _getAuthStatusMessage(biometricType);
        });

        String authReason = _getAuthReason(biometricType);

        bool authenticated = await auth.authenticate(
          localizedReason: authReason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!_mounted) return;

        if (authenticated) {
          print("Authentication successful with: $biometricType");
          authenticationSuccessful = true;

          // Update preferred type for future use
          await BiometricPreference.setPreferredBiometricType(biometricType);

          _proceedToHome();
          return;
        } else {
          print("Authentication failed with: $biometricType");
          _failedBiometricTypes.add(biometricType);
        }
      } catch (e) {
        print("Biometric error with $biometricType: $e");
        _failedBiometricTypes.add(biometricType);

        // If this was a hardware/sensor error, continue to next type
        if (_isHardwareError(e.toString())) {
          continue;
        }
      }
    }

    // If we get here, all biometric methods failed
    if (!authenticationSuccessful) {
      if (!_mounted) return;

      setState(() {
        isAuthenticating = false;
        _authStatus = 'Authentication failed. Try again or use password.';
      });

      // Show options: retry or go to password login
      _showFallbackOptions();
    }
  }

  // Get list of biometric types to try based on availability and user preferences
  // Replace the _getBiometricTypesToTry method in BiometricScreen with this:
  Future<List<String>> _getBiometricTypesToTry() async {
    List<String> typesToTry = [];

    bool faceIdEnabled = await BiometricPreference.getUseFaceId();
    bool fingerprintEnabled = await BiometricPreference.getUseFingerprint();
    bool generalEnabled = await BiometricPreference.getUseBiometric();

    print(
      "Face ID enabled: $faceIdEnabled, available: ${_availableBiometrics['face']}",
    );
    print(
      "Fingerprint enabled: $fingerprintEnabled, available: ${_availableBiometrics['fingerprint']}",
    );
    print("General biometric enabled: $generalEnabled");

    // If specific types are enabled, prioritize them
    if (faceIdEnabled && (_availableBiometrics['face'] ?? false)) {
      typesToTry.add('face');
    }

    if (fingerprintEnabled && (_availableBiometrics['fingerprint'] ?? false)) {
      typesToTry.add('fingerprint');
    }

    // If only general biometric is enabled, try all available types
    if (typesToTry.isEmpty && generalEnabled) {
      if (_availableBiometrics['face'] ?? false) {
        typesToTry.add('face');
      }
      if (_availableBiometrics['fingerprint'] ?? false) {
        typesToTry.add('fingerprint');
      }
    }

    // FALLBACK: If no types found but general biometric is enabled,
    // try fingerprint as default (most common biometric type)
    if (typesToTry.isEmpty && generalEnabled && _canCheckBiometrics) {
      print(
        "No specific biometric types available, trying default fingerprint",
      );
      typesToTry.add('fingerprint');
    }

    // Remove failed types from the list
    typesToTry.removeWhere((type) => _failedBiometricTypes.contains(type));

    print("Final biometric types to try: $typesToTry");
    return typesToTry;
  }

  String _getAuthStatusMessage(String biometricType) {
    switch (biometricType) {
      case 'face':
        return 'Place your face in front of the camera';
      case 'fingerprint':
        return 'Place your finger on the sensor';
      default:
        return 'Verifying your identity';
    }
  }

  String _getAuthReason(String biometricType) {
    switch (biometricType) {
      case 'face':
        return 'Please use Face ID to access the app';
      case 'fingerprint':
        return 'Please use your fingerprint to access the app';
      default:
        return 'Please authenticate to access the app';
    }
  }

  bool _isHardwareError(String error) {
    // Check if the error indicates a hardware problem
    String lowerError = error.toLowerCase();
    return lowerError.contains('sensor') ||
        lowerError.contains('hardware') ||
        lowerError.contains('not available') ||
        lowerError.contains('not enrolled') ||
        lowerError.contains('no hardware');
  }

  void _showFallbackOptions() {
    showDialog(
      // barrierColor: AppColors.backgroundLightGrey,
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.containerPopBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Text(
            textAlign: TextAlign.center,
            'Authentication Failed',
            style: AppFont.popupTitleBlack(context),
          ),
        ),
        content: const Text(
          'Biometric authentication is not working. Would you like to try again or use password login?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _skipAndLogin();
            },
            child: Text('Use Password', style: AppFont.mediumText14(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset failed types and try again
              _failedBiometricTypes.clear();
              _authenticateWithFallback();
            },
            child: Text('Try Again', style: AppFont.mediumText14(context)),
          ),
        ],
      ),
    );
  }

  // Replace the _enableBiometric method in BiometricScreen with this:
  Future<void> _enableBiometric(bool enable) async {
    print("Setting biometric preference to: $enable");

    if (enable) {
      // Enable general biometric first
      await BiometricPreference.setUseBiometric(true);

      // Get fresh biometric availability data
      Map<String, bool> freshBiometrics =
          await BiometricPreference.getAvailableBiometrics();
      print("Fresh biometric data for setup: $freshBiometrics");

      // Update local state
      _availableBiometrics = freshBiometrics;

      // Enable available biometric types
      if (_availableBiometrics['face'] == true) {
        await BiometricPreference.setUseFaceId(true);
        await BiometricPreference.setPreferredBiometricType('face');
        print("Enabled Face ID");
      } else if (_availableBiometrics['fingerprint'] == true) {
        await BiometricPreference.setUseFingerprint(true);
        await BiometricPreference.setPreferredBiometricType('fingerprint');
        print("Enabled Fingerprint");
      } else {
        // Fallback: If no specific type detected but general biometric is available,
        // enable fingerprint as default and let the system handle it
        await BiometricPreference.setUseFingerprint(true);
        await BiometricPreference.setPreferredBiometricType('fingerprint');
        print("Enabled default fingerprint fallback");
      }

      // Mark that user has made a choice
      await BiometricPreference.setHasMadeBiometricChoice(true);
    } else {
      // Disable all biometric preferences
      await BiometricPreference.setUseBiometric(false);
      await BiometricPreference.setUseFaceId(false);
      await BiometricPreference.setUseFingerprint(false);
      await BiometricPreference.setHasMadeBiometricChoice(true);
    }

    if (!_mounted) return;

    if (enable) {
      setState(() {
        _showBiometricChoice = false;
        _useBiometric = true;
      });

      // Small delay to ensure preferences are saved
      await Future.delayed(const Duration(milliseconds: 300));

      // Debug: Print preferences after setup
      await BiometricPreference.printAllPreferences();

      _authenticateWithFallback();
    } else {
      _redirectToLogin();
    }
  }

  // Replace these methods in your BiometricScreen:

  void _proceedToHome() async {
    try {
      await NotificationService.instance.initialize();
      print("Proceeding to home screen");
    } catch (e) {
      print("Error initializing notifications: $e");
    }

    if (_mounted) {
      // ✅ Check admin status before navigation
      bool isAdmin = await TokenManager.getIsAdmin();

      if (isAdmin) {
        Get.offAll(() => AdminDealerall());
      } else {
        Get.offAll(() => BottomNavigation());
      }
    }
  }

  void _redirectToLogin() {
    // Navigate to login screen
    if (_mounted) {
      Get.offAll(
        () => LoginPage(
          onLoginSuccess: () async {
            // ✅ Check admin status in login success callback too
            bool isAdmin = await TokenManager.getIsAdmin();

            if (isAdmin) {
              // Get.off(() => AdminBottomnavigation());
              Get.off(() => AdminDealerall());
            } else {
              Get.off(() => BottomNavigation());
            }
          },
          email: '',
        ),
      );
    }
  }

  void _skipAndLogin() async {
    // Navigate to login screen
    if (_mounted) {
      Get.offAll(
        () => LoginPage(
          onLoginSuccess: () async {
            // ✅ Check admin status in login success callback too
            bool isAdmin = await TokenManager.getIsAdmin();

            if (isAdmin) {
              Get.off(() => AdminDealerall());
            } else {
              Get.off(() => BottomNavigation());
            }
          },
          email: '',
        ),
      );
    }
  }

  Widget _buildBiometricChoiceUI() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show appropriate icon based on available biometrics
          Icon(_getSetupIcon(), size: 80.w, color: AppColors.colorsBlue),
          SizedBox(height: 24.h),
          Text(
            'Enable Biometric Authentication?',
            textAlign: TextAlign.center,
            style: AppFont.popupTitleWhite(context),
          ),
          SizedBox(height: 16.h),
          Text(
            _getSetupDescription(),
            style: AppFont.dropDowmLabelLightcolors(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48.h),
          ElevatedButton(
            onPressed: () => _enableBiometric(true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('Enable', style: AppFont.dropDowmLabel(context)),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: () => _enableBiometric(false),
            child: Text(
              'Not Now',
              style: AppFont.dropDowmLabelLightcolors(context),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSetupIcon() {
    bool hasFace = _availableBiometrics['face'] ?? false;
    bool hasFingerprint = _availableBiometrics['fingerprint'] ?? false;

    if (hasFace && hasFingerprint) {
      return Icons.security; // General security icon for multiple options
    } else if (hasFace) {
      return Icons.face;
    } else if (hasFingerprint) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }

  String _getSetupDescription() {
    bool hasFace = _availableBiometrics['face'] ?? false;
    bool hasFingerprint = _availableBiometrics['fingerprint'] ?? false;

    if (hasFace && hasFingerprint) {
      return 'Use your fingerprint or face ID to quickly and securely access the app. We\'ll try the best option for your device.';
    } else if (hasFace) {
      return 'Use Face ID to quickly and securely access the app next time.';
    } else if (hasFingerprint) {
      return 'Use your fingerprint to quickly and securely access the app next time.';
    } else {
      return 'Use biometric authentication to quickly and securely access the app next time.';
    }
  }

  Widget _buildAuthenticationUI() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCurrentAuthIcon(),
            size: 80.w,
            color: isAuthenticating ? AppColors.colorsBlue : Colors.white,
          ),
          SizedBox(height: 24.h),
          Text(
            _authStatus,
            style: TextStyle(fontSize: 18.sp, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          if (isAuthenticating)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.colorsBlue),
            )
          else
            ElevatedButton(
              onPressed: () {
                _failedBiometricTypes.clear(); // Reset failed attempts
                _authenticateWithFallback();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text('Try Again', style: TextStyle(fontSize: 16.sp)),
            ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: _skipAndLogin,
            child: Text(
              'Use Password Instead',
              style: AppFont.dropDowmLabel(context),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCurrentAuthIcon() {
    // Show icon based on current authentication status
    if (_authStatus.toLowerCase().contains('face')) {
      return Icons.face;
    } else if (_authStatus.toLowerCase().contains('finger')) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              textAlign: TextAlign.center,
              _showBiometricChoice ? 'Setup Biometrics' : 'Authentication',
              style: AppFont.popupTitleWhite(context),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _showBiometricChoice
            ? _buildBiometricChoiceUI()
            : _buildAuthenticationUI(),
      ),
    );
  }
}
