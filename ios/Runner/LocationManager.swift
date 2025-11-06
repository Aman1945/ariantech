// 📁 ios/Runner/LocationManager.swift
import Foundation
import CoreLocation
import Flutter
import UIKit
import UserNotifications

@available(iOS 9.0, *)
@objc(LocationManager)
class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager!
    private var channel: FlutterMethodChannel?
    private var isTracking = false
    private var lastLocation: CLLocation?
    private var totalDistance: Double = 0.0
    private var driveStartTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var isPaused = false
    private var pauseStartTime: Date?
    private var eventId: String?
    private var notificationTimer: Timer?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    @objc func setMethodChannel(_ channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 5 meters minimum movement
        
        print("✅ iOS LocationManager initialized")
    }
    
    @objc func startTracking(_ eventId: String, distance: Double) {
        guard !isTracking else { 
            print("⚠️ iOS tracking already active")
            return 
        }
        
        self.eventId = eventId
        driveStartTime = Date()
        totalDistance = distance
        isTracking = true
        
        print("🚀 Starting iOS background tracking for event: \(eventId)")
        
        // Request permissions if needed
        if #available(iOS 14.0, *) {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestAlwaysAuthorization()
            }
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            
            // ✅ Enable background location updates
            if #available(iOS 9.0, *) {
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
            }
            
            // Start notification updates
            startNotificationUpdates()
            
            print("✅ iOS background location tracking started")
        } else {
            print("❌ iOS location services not enabled")
        }
    }
    
    @objc func stopTracking() {
        guard isTracking else { 
            print("⚠️ iOS tracking not active")
            return 
        }
        
        isTracking = false
        locationManager.stopUpdatingLocation()
        
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
        notificationTimer?.invalidate()
        notificationTimer = nil
        
        // ✅ ADDED: Cancel persistent notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("🛑 iOS background location tracking stopped")
    }
    
    @objc func pauseTracking() {
        if !isPaused {
            isPaused = true
            pauseStartTime = Date()
            print("⏸️ iOS tracking paused")
        }
    }
    
    @objc func resumeTracking() {
        if isPaused, let pauseStart = pauseStartTime {
            totalPausedDuration += Date().timeIntervalSince(pauseStart)
            isPaused = false
            pauseStartTime = nil
            print("▶️ iOS tracking resumed")
        }
    }
    
    @objc func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    private func startNotificationUpdates() {
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.updateLocalNotification()
        }
    }
    
    private func updateLocalNotification() {
        let duration = calculateDuration()
        let distanceText = formatDistance(totalDistance)
        let content = "\(distanceText) • \(duration)m • \(isPaused ? "Paused" : "Tracking")"
        
        // ✅ IMPROVED: Remove previous notifications before adding new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["testdrive_tracking"])
        
        // Create local notification
        let content_notification = UNMutableNotificationContent()
        content_notification.title = "Test Drive Active"
        content_notification.body = content
        content_notification.sound = nil // Silent
        
        let request = UNNotificationRequest(
            identifier: "testdrive_tracking",
            content: content_notification,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ iOS notification error: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 0.01 {
            return "0.0 km"
        } else if distance < 1.0 {
            return String(format: "%.2f km", distance)
        } else if distance < 10.0 {
            return String(format: "%.1f km", distance)
        } else {
            return "\(Int(distance.rounded())) km"
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, !isPaused else { return }
        
        for location in locations {
            // Filter out inaccurate locations
            if location.horizontalAccuracy > 25 { 
                print("❌ iOS location accuracy too low: \(location.horizontalAccuracy)m")
                continue 
            }
            
            // Calculate distance if we have a previous location
            if let lastLoc = lastLocation {
                let distance = location.distance(from: lastLoc)
                if distance >= 5 { // 5 meters minimum movement
                    let distanceKm = distance / 1000.0
                    totalDistance += distanceKm
                    print("📍 iOS location updated: \(formatDistance(totalDistance)), accuracy: \(location.horizontalAccuracy)m")
                } else {
                    print("⏸️ iOS movement too small: \(distance)m")
                    continue
                }
            } else {
                print("📍 iOS first location acquired")
            }
            
            lastLocation = location
            
            // Send to Flutter
            channel?.invokeMethod("location_update", arguments: [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "distance": totalDistance,
                "duration": calculateDuration(),
                "accuracy": location.horizontalAccuracy,
                "timestamp": Date().timeIntervalSince1970 * 1000 // milliseconds
            ])
        }
    }
    
    // ✅ FIXED: Only ONE didFailWithError method with proper error handling
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ iOS location error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("❌ iOS location access denied")
                stopTracking()
            case .locationUnknown:
                print("⚠️ iOS location unknown - continuing")
                // Don't stop, just continue
            case .network:
                print("⚠️ iOS network error - retrying")
                // Retry after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if self.isTracking {
                        self.locationManager.startUpdatingLocation()
                    }
                }
            default:
                print("⚠️ iOS other location error - retrying")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if self.isTracking {
                        self.locationManager.startUpdatingLocation()
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 iOS location authorization changed: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways:
            print("✅ iOS always location permission granted")
            if isTracking {
                locationManager.startUpdatingLocation()
            }
        case .authorizedWhenInUse:
            print("⚠️ iOS when-in-use location permission granted - requesting always")
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("❌ iOS location permission denied or restricted")
        case .notDetermined:
            print("🔄 iOS location permission not determined - requesting")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            print("🔄 iOS unknown location permission status")
            break
        }
    }
    
    private func calculateDuration() -> Int {
        guard let startTime = driveStartTime else { return 0 }
        
        let totalElapsed = Date().timeIntervalSince(startTime)
        let activeDuration: TimeInterval
        
        if isPaused, let pauseStart = pauseStartTime {
            activeDuration = totalElapsed - totalPausedDuration - Date().timeIntervalSince(pauseStart)
        } else {
            activeDuration = totalElapsed - totalPausedDuration
        }
        
        return Int(activeDuration / 60) // Convert to minutes
    }
}