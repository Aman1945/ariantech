import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get fileName {
    // You can change this based on your build configuration
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    switch (flavor) {
      case 'prod':
        return '.env';
      case 'dev':
        return '.env';
      default:
        return '.env';
    }
  }

  static Future<void> init() async {
    await dotenv.load(fileName: fileName);
    print('this is the key :${googleMapsApiKey}');
  }

  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? '';
  static String get googleMapsApiKey => dotenv.   env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get appName => dotenv.env['APP_NAME'] ?? 'SmartAssist';

  // Validation methods
  static bool get isConfigValid {
    return apiBaseUrl.isNotEmpty &&
        googleMapsApiKey.isNotEmpty &&
        socketUrl.isNotEmpty;
  }

  static void validateConfig() {
    if (!isConfigValid) {
      throw Exception(
        'Environment configuration is invalid. Please check your .env file.',
      );
    }
  }
}
