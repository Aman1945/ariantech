import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartassist/config/route/route_name.dart';
import 'package:smartassist/pages/login_steps/biometric_screen.dart'
    as loginStep;
import 'package:smartassist/pages/login_steps/login_page.dart';
import 'package:smartassist/pages/login_steps/splash_screen.dart';
import 'package:smartassist/superAdmin/pages/admin_dealerall.dart';
import 'package:smartassist/utils/admin_bottomnavigation.dart';
import 'package:smartassist/utils/bottom_navigation.dart';
import 'package:smartassist/utils/token_manager.dart';

// class Routes {
//   static Route<dynamic> generateRoute(RouteSettings settings) {
//     // Extract arguments if they exist
//     final args = settings.arguments;
//     switch (settings.name) {
//       case RoutesName.splashScreen:
//         return MaterialPageRoute(
//           builder: (context) => const SplashScreen(),
//         );
//       case RoutesName.biometricScreen:
//         // Check if args contains isFirstTime parameter
//         bool isFirstTime = false;
//         if (args is Map<String, dynamic> && args.containsKey('isFirstTime')) {
//           isFirstTime = args['isFirstTime'];
//         }

//         return MaterialPageRoute(
//           builder: (context) => BiometricScreen(isFirstTime: isFirstTime),
//         );
// //comment this
//       case RoutesName.home:
//         return MaterialPageRoute(
//           builder: (context) => BottomNavigation(),
//         );

//       //this
//       case RoutesName.login:
//         return MaterialPageRoute(
//           builder: (context) => LoginPage(
//             onLoginSuccess: () {
//               Get.off(() => BottomNavigation());
//             },
//             email: '',
//           ),
//         );

//       // Add settings screen route
//       case RoutesName.biometricSettings:
//         return MaterialPageRoute(
//           builder: (context) => const BiometricSettingsScreen(),
//         );

//       default:
//         return MaterialPageRoute(
//           builder: (context) => Scaffold(
//             body: Center(
//               child: Text('No route defined for ${settings.name}'),
//             ),
//           ),
//         );
//     }
//   }
// }

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if they exist
    final args = settings.arguments;
    switch (settings.name) {
      case RoutesName.splashScreen:
        return MaterialPageRoute(builder: (context) => const SplashScreen());

      // case RoutesName.biometricScreen:
      //   // Check if args contains isFirstTime parameter
      //   bool isFirstTime = false;
      //   if (args is Map<String, dynamic> && args.containsKey('isFirstTime')) {
      //     isFirstTime = args['isFirstTime'];
      //   }

      //   return MaterialPageRoute(
      //     builder: (context) =>
      //         loginStep.BiometricScreen(isFirstTime: isFirstTime ,
      //         //  isAdmin: false,
      //          ),
      //   );

      // case RoutesName.home:
      //   return MaterialPageRoute(builder: (context) => BottomNavigation());
      case RoutesName.biometricScreen:
        // Check if args contains isFirstTime parameter
        bool isFirstTime = false;
        if (args is Map<String, dynamic> && args.containsKey('isFirstTime')) {
          isFirstTime = args['isFirstTime'];
        }

        return MaterialPageRoute(
          builder: (context) =>
              loginStep.BiometricScreen(isFirstTime: isFirstTime),
        );

      case RoutesName.home:
        // ✅ Make home route async to check admin status
        return MaterialPageRoute(
          builder: (context) => FutureBuilder<bool>(
            future: TokenManager.getIsAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              bool isAdmin = snapshot.data ?? false;
              return isAdmin ? AdminBottomnavigation() : BottomNavigation();
            },
          ),
        );

      case RoutesName.login:
        return MaterialPageRoute(
          builder: (context) => LoginPage(
            onLoginSuccess: () async {
              // Check admin status and navigate accordingly
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

      // case RoutesName.login:
      //   return MaterialPageRoute(
      //     builder: (context) => LoginPage(
      //       onLoginSuccess: () {
      //         Get.off(() => BottomNavigation());
      //       },
      //       email: '',
      //     ),
      //   );

      // Add settings screen route
      case RoutesName.biometricSettings:
        return MaterialPageRoute(
          builder: (context) => loginStep.BiometricScreen(
            // isAdmin: false,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
