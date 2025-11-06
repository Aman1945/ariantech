import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import CoreLocation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var locationManager: LocationManager?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()  // ✅ Initializes Firebase
        
        // Read API key from Info.plist (configured via .xcconfig)
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["GoogleMapsAPIKey"] as? String,
              !apiKey.isEmpty else {
            print("❌ Google Maps API key not found")
            return false
        }
        
        GMSServices.provideAPIKey(apiKey)
        GeneratedPluginRegistrant.register(with: self)
        
        // ✅ Setup location manager
        setupLocationManager()
        
        // ✅ Request notification permissions
        requestNotificationPermissions()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // ✅ Setup location manager
    private func setupLocationManager() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("❌ Failed to get FlutterViewController")
            return
        }
        
        // ✅ Create LocationManager instance
        if #available(iOS 9.0, *) {
            locationManager = LocationManager()
        } else {
            print("❌ iOS version not supported")
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "testdrive_ios_service",
            binaryMessenger: controller.binaryMessenger
        )
        
        locationManager?.setMethodChannel(channel)
        
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterError(code: "NO_SELF", message: "Self is nil", details: nil))
                return
            }
            
            switch call.method {
            case "startTracking":
                if let args = call.arguments as? [String: Any],
                   let eventId = args["eventId"] as? String,
                   let distance = args["distance"] as? Double {
                    self.locationManager?.startTracking(eventId, distance: distance)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }
            case "stopTracking":
                self.locationManager?.stopTracking()
                result(true)
            case "pauseTracking":
                self.locationManager?.pauseTracking()
                result(true)
            case "resumeTracking":
                self.locationManager?.resumeTracking()
                result(true)
            case "requestAlwaysPermission":
                self.locationManager?.requestAlwaysPermission()
                result(true)
                // ✅ ADDED: New case for notification cleanup
            case "cancelNotification":
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        print("✅ iOS location manager setup complete")
    }
    
    // ✅ Request notification permission
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ iOS notification permission granted")
                } else {
                    print("❌ iOS notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // ✅ Background app refresh handling
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        print("📱 iOS app entered background")
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        print("📱 iOS app entering foreground")
    }
}

// import UIKit
// import Flutter
// import GoogleMaps
// import FirebaseCore


// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     FirebaseApp.configure()  // ✅ Initializes Firebase
//     // Read API key from Info.plist (configured via .xcconfig)
//     guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
//           let plist = NSDictionary(contentsOfFile: path),
//           let apiKey = plist["GoogleMapsAPIKey"] as? String,
//           !apiKey.isEmpty else {
//         print("❌ Google Maps API key not found")
//         return false
//     } 
//     GMSServices.provideAPIKey(apiKey)
//     GeneratedPluginRegistrant.register(with: self)   

//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

// import UIKit
// import Flutter
// import GoogleMaps
// import FirebaseCore

// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     FirebaseApp.configure()  // ✅ Initializes Firebase
//     GMSServices.provideAPIKey("AIzaSyCaFZ4RXQIy86v9B24wz5l0vgDKbQSP5LE")  // ✅ Google Maps API key
//     GeneratedPluginRegistrant.register(with: self)  // ✅ Registers plugins

//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

