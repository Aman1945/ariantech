import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartassist/config/controller/dashboard_getxapi.dart';
import 'package:smartassist/config/controller/testdrive/DriveStateManager.dart';
import 'package:smartassist/config/controller/testdrive/local_notification.dart';
import 'package:smartassist/config/environment/environment.dart';
import 'package:smartassist/config/model/testdrive/location_point.dart';
import 'package:smartassist/config/route/route.dart';
import 'package:smartassist/config/route/route_name.dart';
import 'package:smartassist/services/notifacation_srv.dart';
import 'package:smartassist/utils/connection_service.dart';
import 'package:smartassist/utils/token_manager.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await Environment.init();
    Environment.validateConfig();
    // Request location permissions

    await _requestLocationPermissions();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Forward all uncaught Flutter errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Forward all Dart async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    print("Firebase initialized successfully!");
  } catch (e) {
    print("Initialization failed: $e");
  }

  await Hive.initFlutter();
  Hive.registerAdapter(LocationPointAdapter());
  Hive.registerAdapter(DriveSessionAdapter());

  await Hive.openBox<LocationPoint>('locations');
  await Hive.openBox<DriveSession>('drives');
  await Hive.openBox('settings');

  // Initialize Drive State Manager
  await DriveStateManager.init();
  try {
    await NotificationService.instance.initialize();
    await LocalNotificationService().initialize();
    // ADD DELAY FOR iOS APNs TOKEN
    if (Platform.isIOS) {
      // Wait a bit for APNs token to be available
      await Future.delayed(Duration(seconds: 2));
    }

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      print('🔔 APNs Token retrieved: $apnsToken');
    } else {
      print(
        '❌ APNs Token is null - make sure you are testing on a real iOS device',
      );

      // Try to get APNs token again after a delay
      if (Platform.isIOS) {
        await Future.delayed(Duration(seconds: 3));
        final retryApnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (retryApnsToken != null) {
          print('🔔 APNs Token retrieved on retry: $retryApnsToken');
        }
      }
    }

    // Get FCM token

    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $fcmToken');
  } catch (e) {
    print("Notification initialization failed: $e");
  }
  Get.put(DashboardController(), permanent: true);
  await ConnectionService().initialize();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestLocationPermissions() async {
  try {
    // First check current permission status
    PermissionStatus currentStatus = await Permission.location.status;
    print('📍 Current location permission status: $currentStatus');

    // Only request if not already granted
    if (!currentStatus.isGranted) {
      // Don't open settings immediately - give user a chance to grant
      if (currentStatus.isPermanentlyDenied) {
        print('❌ Location permission permanently denied');
        return;
      }

      // Request location permission
      PermissionStatus locationStatus = await Permission.location.request();
      print('📍 Location permission request result: $locationStatus');

      if (locationStatus.isPermanentlyDenied) {
        print('❌ Location permission permanently denied after request');
        return;
      }

      if (!locationStatus.isGranted) {
        print('❌ Location permission denied');
        return;
      }
    }

    print('✅ Location permission granted');

    if (Platform.isAndroid) {
      PermissionStatus backgroundStatus =
          await Permission.locationAlways.status;
      print('📍 Background location permission status: $backgroundStatus');

      // Only request background location if foreground is granted and background isn't permanently denied
      if (!backgroundStatus.isGranted &&
          !backgroundStatus.isPermanentlyDenied) {}
    }

    // Cross-check with Geolocator (this might be causing the settings navigation)
    LocationPermission geolocatorPermission =
        await Geolocator.checkPermission();
    print('📍 Geolocator permission status: $geolocatorPermission');

    if (geolocatorPermission == LocationPermission.denied) {
      geolocatorPermission = await Geolocator.requestPermission();
      print('📍 Geolocator permission after request: $geolocatorPermission');

      // Handle geolocator permission results without forcing settings
      if (geolocatorPermission == LocationPermission.deniedForever) {
        print('❌ Geolocator permission permanently denied');
        // Don't automatically open settings
      }
    }
  } catch (e) {
    print('❌ Error requesting location permissions: $e');
  }
}

// Alternative approach with better user experience
Future<bool> _requestLocationPermissionsWithDialog() async {
  try {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      print('✅ Location permission already granted');
      return true;
    }

    if (status.isDenied) {
      // Show explanation dialog before requesting
      bool shouldRequest = await _showPermissionDialog();
      if (!shouldRequest) return false;

      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      // Show dialog explaining how to enable in settings
      bool openSettings = await _showSettingsDialog();
      if (openSettings) {
        await openAppSettings();
      }
      return false;
    }

    return status.isGranted;
  } catch (e) {
    print('❌ Error in permission request: $e');
    return false;
  }
}

// Helper method to show permission explanation dialog
Future<bool> _showPermissionDialog() async {
  return true;
}

// Helper method to show settings dialog
Future<bool> _showSettingsDialog() async {
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ToastificationWrapper(
          child: GetMaterialApp(
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: widget!,
              );
            },
            initialRoute: RoutesName.splashScreen,
            // home: ProfileScreen(), //remove this
            onGenerateRoute: Routes.generateRoute,
            theme: ThemeData(
              scaffoldBackgroundColor: const Color(0xFFFFFFFF),
              appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFFFFF)),
            ),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
