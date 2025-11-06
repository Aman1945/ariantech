// // biometric_settings.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:local_auth/local_auth.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/utils/biometric_prefrence.dart';

// class BiometricSettingsScreen extends StatefulWidget {
//   const BiometricSettingsScreen({super.key});

//   @override
//   State<BiometricSettingsScreen> createState() =>
//       _BiometricSettingsScreenState();
// }

// class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
//   bool _isBiometricAvailable = false;
//   bool _isBiometricEnabled = false;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }

//   Future<void> _loadSettings() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Check if device supports biometrics
//       final LocalAuthentication auth = LocalAuthentication();
//       _isBiometricAvailable = await auth.canCheckBiometrics;

//       // Get current preference
//       _isBiometricEnabled = await BiometricPreference.getUseBiometric();
//     } catch (e) {
//       print("Error loading biometric settings: $e");
//       _isBiometricAvailable = false;
//       _isBiometricEnabled = false;
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _toggleBiometric(bool value) async {
//     try {
//       await BiometricPreference.setUseBiometric(value);
//       if (mounted) {
//         setState(() {
//           _isBiometricEnabled = value;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               value
//                   ? 'Biometric authentication enabled'
//                   : 'Biometric authentication disabled',
//               style: AppFont.dropDowmLabel(context),
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       print("Error toggling biometric: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to update settings: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Biometric Settings',
//           style: AppFont.popupTitleWhite(context),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: EdgeInsets.all(16.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Security Settings',
//                     style: AppFont.dropDowmLabel(context),
//                   ),
//                   SizedBox(height: 20.h),
//                   if (!_isBiometricAvailable)
//                     Card(
//                       child: Padding(
//                         padding: EdgeInsets.all(16.w),
//                         child: Row(
//                           children: [
//                           const  Icon(Icons.info_outline, color: Colors.orange),
//                             SizedBox(width: 10.w),
//                             Expanded(
//                               child: Text(
//                                 'Biometric authentication is not available on this device.',
//                                 style: AppFont.dropDowmLabel(context),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                   else
//                     Card(
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 16.w,
//                           vertical: 8.h,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Use Biometric Authentication',
//                                   style: TextStyle(
//                                     fontSize: 16.sp,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Unlock app using fingerprint or face ID',
//                                   style: TextStyle(
//                                     fontSize: 14.sp,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Switch(
//                               value: _isBiometricEnabled,
//                               onChanged: _toggleBiometric,
//                               activeColor: AppColors.colorsBlueAccent,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// biometric_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/biometric_prefrence.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  State<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isFaceIdEnabled = false;
  bool _isFingerprintEnabled = false;
  bool _isLoading = true;

  Map<String, bool> _availableBiometrics = {};
  String _preferredBiometricType = 'fingerprint';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if device supports biometrics
      final LocalAuthentication auth = LocalAuthentication();
      _isBiometricAvailable = await auth.canCheckBiometrics;

      // Get available biometric types
      _availableBiometrics = await BiometricPreference.getAvailableBiometrics();

      // Get current preferences
      _isBiometricEnabled = await BiometricPreference.getUseBiometric();
      _isFaceIdEnabled = await BiometricPreference.getUseFaceId();
      _isFingerprintEnabled = await BiometricPreference.getUseFingerprint();
      _preferredBiometricType =
          await BiometricPreference.getPreferredBiometricType();

      print("Available biometrics: $_availableBiometrics");
      print("Face ID enabled: $_isFaceIdEnabled");
      print("Fingerprint enabled: $_isFingerprintEnabled");
    } catch (e) {
      print("Error loading biometric settings: $e");
      _isBiometricAvailable = false;
      _isBiometricEnabled = false;
      _isFaceIdEnabled = false;
      _isFingerprintEnabled = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      await BiometricPreference.setUseBiometric(value);

      if (!value) {
        // If disabling biometric, also disable individual types
        await BiometricPreference.setUseFaceId(false);
        await BiometricPreference.setUseFingerprint(false);
      }

      if (mounted) {
        setState(() {
          _isBiometricEnabled = value;
          if (!value) {
            _isFaceIdEnabled = false;
            _isFingerprintEnabled = false;
          }
        });

        _showSnackBar(
          value
              ? 'Biometric authentication enabled'
              : 'Biometric authentication disabled',
          Colors.green,
        );
      }
    } catch (e) {
      print("Error toggling biometric: $e");
      _showSnackBar('Failed to update settings: $e', Colors.red);
    }
  }

  Future<void> _toggleFaceId(bool value) async {
    try {
      await BiometricPreference.setUseFaceId(value);

      if (value) {
        // Enable overall biometric if enabling Face ID
        await BiometricPreference.setUseBiometric(true);
        await BiometricPreference.setPreferredBiometricType('face');
      }

      if (mounted) {
        setState(() {
          _isFaceIdEnabled = value;
          if (value) {
            _isBiometricEnabled = true;
            _preferredBiometricType = 'face';
          }
        });

        _showSnackBar(
          value ? 'Face ID enabled' : 'Face ID disabled',
          Colors.green,
        );
      }
    } catch (e) {
      print("Error toggling Face ID: $e");
      _showSnackBar('Failed to update Face ID settings: $e', Colors.red);
    }
  }

  Future<void> _toggleFingerprint(bool value) async {
    try {
      await BiometricPreference.setUseFingerprint(value);

      if (value) {
        // Enable overall biometric if enabling fingerprint
        await BiometricPreference.setUseBiometric(true);
        await BiometricPreference.setPreferredBiometricType('fingerprint');
      }

      if (mounted) {
        setState(() {
          _isFingerprintEnabled = value;
          if (value) {
            _isBiometricEnabled = true;
            _preferredBiometricType = 'fingerprint';
          }
        });

        _showSnackBar(
          value ? 'Fingerprint enabled' : 'Fingerprint disabled',
          Colors.green,
        );
      }
    } catch (e) {
      print("Error toggling fingerprint: $e");
      _showSnackBar('Failed to update fingerprint settings: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: AppFont.dropDowmLabel(context)),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  Widget _buildBiometricOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isAvailable,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24.w,
                  color: isAvailable ? AppColors.colorsBlue : Colors.grey,
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      isAvailable ? subtitle : 'Not available on this device',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: value && isAvailable,
              onChanged: isAvailable ? onChanged : null,
              activeColor: AppColors.colorsBlue,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Biometric Settings',
            style: AppFont.popupTitleWhite(context),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Settings',
                    style: AppFont.dropDowmLabel(context),
                  ),
                  SizedBox(height: 20.h),

                  if (!_isBiometricAvailable)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'Biometric authentication is not available on this device.',
                                style: AppFont.dropDowmLabel(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Overall biometric toggle
                    _buildBiometricOption(
                      title: 'Use Biometric Authentication',
                      subtitle: 'Enable biometric authentication for the app',
                      icon: Icons.security,
                      value: _isBiometricEnabled,
                      onChanged: _toggleBiometric,
                      isAvailable: _isBiometricAvailable,
                    ),

                    SizedBox(height: 16.h),

                    Text(
                      'Biometric Options',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Face ID option
                    _buildBiometricOption(
                      title: 'Face ID',
                      subtitle: 'Unlock using facial recognition',
                      icon: Icons.face,
                      value: _isFaceIdEnabled,
                      onChanged: _toggleFaceId,
                      isAvailable: _availableBiometrics['face'] ?? false,
                    ),

                    SizedBox(height: 8.h),

                    // Fingerprint option
                    _buildBiometricOption(
                      title: 'Fingerprint',
                      subtitle: 'Unlock using fingerprint',
                      icon: Icons.fingerprint,
                      value: _isFingerprintEnabled,
                      onChanged: _toggleFingerprint,
                      isAvailable: _availableBiometrics['fingerprint'] ?? false,
                    ),

                    if (_isBiometricEnabled) ...[
                      SizedBox(height: 20.h),
                      Card(
                        color: AppColors.colorsBlue,
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.colorsBlue,
                                size: 20.w,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'Preferred method: ${_preferredBiometricType == 'face' ? 'Face ID' : 'Fingerprint'}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.colorsBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
