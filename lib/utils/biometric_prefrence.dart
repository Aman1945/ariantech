// // biometric_preference.dart

// old one
// // This class handles saving and retrieving biometric preferences
// import 'package:shared_preferences/shared_preferences.dart';

// class BiometricPreference {
//   static const String _useBiometricKey = 'use_biometric';
//   static const String _hasPromptedBiometricKey = 'has_prompted_biometric';
//   static const String _hasMadeBiometricChoiceKey = 'has_made_biometric_choice';

//   // Get whether biometric is enabled
//   static Future<bool> getUseBiometric() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_useBiometricKey) ?? false;
//   }

//   // Set whether biometric is enabled
//   static Future<void> setUseBiometric(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_useBiometricKey, value);
//     // When setting biometric preference, also mark that user has made a choice
//     await prefs.setBool(_hasMadeBiometricChoiceKey, true);

//     // Log for debugging
//     print("Setting _useBiometricKey = $value");
//     print("Setting _hasMadeBiometricChoiceKey = true");
//   }

//   // Check if the user has been prompted about biometrics before
//   static Future<bool> getHasPromptedBiometric() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_hasPromptedBiometricKey) ?? false;
//   }

//   // Set that the user has been prompted about biometrics
//   static Future<void> setHasPromptedBiometric(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_hasPromptedBiometricKey, value);
//   }

//   // Check if the user has made a choice about biometrics (yes or no)
//   static Future<bool> getHasMadeBiometricChoice() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_hasMadeBiometricChoiceKey) ?? false;
//   }

//   // Directly set whether the user has made a choice
//   static Future<void> setHasMadeBiometricChoice(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_hasMadeBiometricChoiceKey, value);
//   }

//   // Reset all biometric preferences (typically on logout)
//   static Future<void> resetBiometricPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_useBiometricKey);
//     await prefs.remove(_hasPromptedBiometricKey);
//     await prefs.remove(_hasMadeBiometricChoiceKey);

//     print("All biometric preferences have been reset");
//   }

//   // For debugging purposes
//   static Future<void> printAllPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     print("All SharedPreferences keys: $keys");

//     bool? useBiometric = prefs.getBool(_useBiometricKey);
//     bool? hasPrompted = prefs.getBool(_hasPromptedBiometricKey);
//     bool? hasMadeChoice = prefs.getBool(_hasMadeBiometricChoiceKey);
//     print("Current use_biometric value: $useBiometric");
//     print("Current has_prompted_biometric value: $hasPrompted");
//     print("Current has_made_biometric_choice value: $hasMadeChoice");
//   }
// }

// biometric_preference.dart
// Enhanced class to handle both fingerprint and Face ID preferences
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class BiometricPreference {
  static const String _useBiometricKey = 'use_biometric';
  static const String _hasPromptedBiometricKey = 'has_prompted_biometric';
  static const String _hasMadeBiometricChoiceKey = 'has_made_biometric_choice';
  static const String _preferredBiometricTypeKey = 'preferred_biometric_type';
  static const String _useFaceIdKey = 'use_face_id';
  static const String _useFingerprintKey = 'use_fingerprint';

  // Get whether any biometric is enabled
  static Future<bool> getUseBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useBiometricKey) ?? false;
  }

  // Set whether biometric is enabled
  static Future<void> setUseBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBiometricKey, value);
    await prefs.setBool(_hasMadeBiometricChoiceKey, true);

    print("Setting _useBiometricKey = $value");
    print("Setting _hasMadeBiometricChoiceKey = true");
  }

  // Face ID specific methods
  static Future<bool> getUseFaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useFaceIdKey) ?? false;
  }

  static Future<void> setUseFaceId(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFaceIdKey, value);
    await prefs.setBool(_hasMadeBiometricChoiceKey, true);

    if (value) {
      await prefs.setString(_preferredBiometricTypeKey, 'face');
      // Ensure general biometric is also enabled
      await prefs.setBool(_useBiometricKey, true);
    } else {
      // Check if fingerprint is still enabled
      bool fingerprintEnabled = prefs.getBool(_useFingerprintKey) ?? false;
      if (!fingerprintEnabled) {
        // No biometric types enabled, disable general biometric
        await prefs.setBool(_useBiometricKey, false);
      }
    }
    print("Setting Face ID preference: $value");
  }

  // Fingerprint specific methods
  static Future<bool> getUseFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useFingerprintKey) ?? false;
  }

  static Future<void> setUseFingerprint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFingerprintKey, value);
    await prefs.setBool(_hasMadeBiometricChoiceKey, true);

    if (value) {
      await prefs.setString(_preferredBiometricTypeKey, 'fingerprint');
      // Ensure general biometric is also enabled
      await prefs.setBool(_useBiometricKey, true);
    } else {
      // Check if Face ID is still enabled
      bool faceIdEnabled = prefs.getBool(_useFaceIdKey) ?? false;
      if (!faceIdEnabled) {
        // No biometric types enabled, disable general biometric
        await prefs.setBool(_useBiometricKey, false);
      }
    }
    print("Setting F  ingerprint preference: $value");
  }

  // Get preferred biometric type
  static Future<String> getPreferredBiometricType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredBiometricTypeKey) ?? 'fingerprint';
  }

  // Set preferred biometric type
  static Future<void> setPreferredBiometricType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredBiometricTypeKey, type);
  }

  // Check if any biometric authentication is enabled (general OR specific types)
  static Future<bool> isAnyBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    bool generalBiometric = prefs.getBool(_useBiometricKey) ?? false;
    bool faceIdEnabled = prefs.getBool(_useFaceIdKey) ?? false;
    bool fingerprintEnabled = prefs.getBool(_useFingerprintKey) ?? false;

    return generalBiometric || faceIdEnabled || fingerprintEnabled;
  }

  // FIXED: Check available biometric types on device
  static Future<Map<String, bool>> getAvailableBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();

    try {
      // First check if biometrics are available at all
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      print("canCheckBiometrics: $canCheckBiometrics");
      print("isDeviceSupported: $isDeviceSupported");

      if (!canCheckBiometrics || !isDeviceSupported) {
        print("Device doesn't support biometrics");
        return {
          'fingerprint': false,
          'face': false,
          'iris': false,
          'weak': false,
          'strong': false,
        };
      }

      final List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();
      print("Raw available biometrics: $availableBiometrics");

      Map<String, bool> result = {
        'fingerprint': availableBiometrics.contains(BiometricType.fingerprint),
        'face': availableBiometrics.contains(BiometricType.face),
        'iris': availableBiometrics.contains(BiometricType.iris),
        'weak': availableBiometrics.contains(BiometricType.weak),
        'strong': availableBiometrics.contains(BiometricType.strong),
      };

      // Fallback: If no specific types detected but biometrics are available,
      // assume fingerprint is available (most common case)
      if (!result.values.any((v) => v) && canCheckBiometrics) {
        print(
          "No specific biometric types detected, defaulting to fingerprint",
        );
        result['fingerprint'] = true;
      }

      print("Final available biometrics result: $result");
      return result;
    } catch (e) {
      print("Error getting available biometrics: $e");

      // Fallback: Try to detect if biometrics work by attempting basic check
      try {
        final bool canCheck = await auth.canCheckBiometrics;
        if (canCheck) {
          print(
            "Fallback: Device supports biometrics, defaulting to fingerprint",
          );
          return {
            'fingerprint': true,
            'face': false,
            'iris': false,
            'weak': false,
            'strong': false,
          };
        }
      } catch (fallbackError) {
        print("Fallback check also failed: $fallbackError");
      }

      return {
        'fingerprint': false,
        'face': false,
        'iris': false,
        'weak': false,
        'strong': false,
      };
    }
  }

  // Check if the user has been prompted about biometrics before
  static Future<bool> getHasPromptedBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPromptedBiometricKey) ?? false;
  }

  // Set that the user has been prompted about biometrics
  static Future<void> setHasPromptedBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPromptedBiometricKey, value);
  }

  // Check if the user has made a choice about biometrics (yes or no)
  static Future<bool> getHasMadeBiometricChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasMadeBiometricChoiceKey) ?? false;
  }

  // Directly set whether the user has made a choice
  static Future<void> setHasMadeBiometricChoice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasMadeBiometricChoiceKey, value);
  }

  // Reset all biometric preferences (typically on logout)
  static Future<void> resetBiometricPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_useBiometricKey);
    await prefs.remove(_hasPromptedBiometricKey);
    await prefs.remove(_hasMadeBiometricChoiceKey);
    await prefs.remove(_preferredBiometricTypeKey);
    await prefs.remove(_useFaceIdKey);
    await prefs.remove(_useFingerprintKey);

    print("All biometric preferences have been reset");
  }

  // For debugging purposes
  static Future<void> printAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    print("All SharedPreferences keys: $keys");

    bool? useBiometric = prefs.getBool(_useBiometricKey);
    bool? hasPrompted = prefs.getBool(_hasPromptedBiometricKey);
    bool? hasMadeChoice = prefs.getBool(_hasMadeBiometricChoiceKey);
    String? preferredType = prefs.getString(_preferredBiometricTypeKey);
    bool? useFaceId = prefs.getBool(_useFaceIdKey);
    bool? useFingerprint = prefs.getBool(_useFingerprintKey);
    bool anyEnabled = await isAnyBiometricEnabled();

    print("Current use_biometric value: $useBiometric");
    print("Current has_prompted_biometric value: $hasPrompted");
    print("Current has_made_biometric_choice value: $hasMadeChoice");
    print("Current preferred_biometric_type: $preferredType");
    print("Current use_face_id: $useFaceId");
    print("Current use_fingerprint: $useFingerprint");
    print("Any biometric enabled: $anyEnabled");
  }
}




// biometric_preference.dart
// Enhanced class to handle both fingerprint and Face ID preferences
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:local_auth/local_auth.dart';

// class BiometricPreference {
//   static const String _useBiometricKey = 'use_biometric';
//   static const String _hasPromptedBiometricKey = 'has_prompted_biometric';
//   static const String _hasMadeBiometricChoiceKey = 'has_made_biometric_choice';
//   static const String _preferredBiometricTypeKey = 'preferred_biometric_type';
//   static const String _useFaceIdKey = 'use_face_id';
//   static const String _useFingerprintKey = 'use_fingerprint';

//   // Get whether any biometric is enabled
//   static Future<bool> getUseBiometric() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_useBiometricKey) ?? false;
//   }

//   // Set whether biometric is enabled
//   static Future<void> setUseBiometric(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_useBiometricKey, value);
//     await prefs.setBool(_hasMadeBiometricChoiceKey, true);
    
//     print("Setting _useBiometricKey = $value");
//     print("Setting _hasMadeBiometricChoiceKey = true");
//   }

//   // Face ID specific methods
//   static Future<bool> getUseFaceId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_useFaceIdKey) ?? false;
//   }

//   static Future<void> setUseFaceId(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_useFaceIdKey, value);
//     if (value) {
//       await prefs.setString(_preferredBiometricTypeKey, 'face');
//     }
//     print("Setting Face ID preference: $value");
//   }

//   // Fingerprint specific methods
//   static Future<bool> getUseFingerprint() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_useFingerprintKey) ?? false;
//   }

//   static Future<void> setUseFingerprint(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_useFingerprintKey, value);
//     if (value) {
//       await prefs.setString(_preferredBiometricTypeKey, 'fingerprint');
//     }
//     print("Setting Fingerprint preference: $value");
//   }

//   // Get preferred biometric type
//   static Future<String> getPreferredBiometricType() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_preferredBiometricTypeKey) ?? 'fingerprint';
//   }

//   // Set preferred biometric type
//   static Future<void> setPreferredBiometricType(String type) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_preferredBiometricTypeKey, type);
//   }

//   // Check available biometric types on device
//   static Future<Map<String, bool>> getAvailableBiometrics() async {
//     final LocalAuthentication auth = LocalAuthentication();
    
//     try {
//       final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      
//       return {
//         'fingerprint': availableBiometrics.contains(BiometricType.fingerprint),
//         'face': availableBiometrics.contains(BiometricType.face),
//         'iris': availableBiometrics.contains(BiometricType.iris),
//         'weak': availableBiometrics.contains(BiometricType.weak),
//         'strong': availableBiometrics.contains(BiometricType.strong),
//       };
//     } catch (e) {
//       print("Error getting available biometrics: $e");
//       return {
//         'fingerprint': false,
//         'face': false,
//         'iris': false,
//         'weak': false,
//         'strong': false,
//       };
//     }
//   }

//   // Check if the user has been prompted about biometrics before
//   static Future<bool> getHasPromptedBiometric() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_hasPromptedBiometricKey) ?? false;
//   }

//   // Set that the user has been prompted about biometrics
//   static Future<void> setHasPromptedBiometric(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_hasPromptedBiometricKey, value);
//   }

//   // Check if the user has made a choice about biometrics (yes or no)
//   static Future<bool> getHasMadeBiometricChoice() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_hasMadeBiometricChoiceKey) ?? false;
//   }

//   // Directly set whether the user has made a choice
//   static Future<void> setHasMadeBiometricChoice(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_hasMadeBiometricChoiceKey, value);
//   }

//   // Reset all biometric preferences (typically on logout)
//   static Future<void> resetBiometricPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_useBiometricKey);
//     await prefs.remove(_hasPromptedBiometricKey);
//     await prefs.remove(_hasMadeBiometricChoiceKey);
//     await prefs.remove(_preferredBiometricTypeKey);
//     await prefs.remove(_useFaceIdKey);
//     await prefs.remove(_useFingerprintKey);
    
//     print("All biometric preferences have been reset");
//   }

//   // For debugging purposes
//   static Future<void> printAllPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     print("All SharedPreferences keys: $keys");
    
//     bool? useBiometric = prefs.getBool(_useBiometricKey);
//     bool? hasPrompted = prefs.getBool(_hasPromptedBiometricKey);
//     bool? hasMadeChoice = prefs.getBool(_hasMadeBiometricChoiceKey);
//     String? preferredType = prefs.getString(_preferredBiometricTypeKey);
//     bool? useFaceId = prefs.getBool(_useFaceIdKey);
//     bool? useFingerprint = prefs.getBool(_useFingerprintKey);
    
//     print("Current use_biometric value: $useBiometric");
//     print("Current has_prompted_biometric value: $hasPrompted");
//     print("Current has_made_biometric_choice value: $hasMadeChoice");
//     print("Current preferred_biometric_type: $preferredType");
//     print("Current use_face_id: $useFaceId");
//     print("Current use_fingerprint: $useFingerprint");
//   }
// }