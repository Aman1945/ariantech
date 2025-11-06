// 📁 android/app/src/main/kotlin/com/smartassist/app/MainActivity.kt
// 📁 android/app/src/main/kotlin/com/smartassist/app/MainActivity.kt
package com.smartassist.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.content.Context
import android.app.NotificationManager


class MainActivity: FlutterFragmentActivity() { 
    private val CHANNEL = "testdrive_native_service"
    private val CALLLOG_CHANNEL = "smartassist/calllog"
    private val NOTIFICATION_CHANNEL = "com.smartassist/notifications" 
    private val TAG = "MainActivity"
    
    private lateinit var callLogManager: CallLogManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize CallLogManager
        callLogManager = CallLogManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "clearAllNotifications" -> {
                    try {
                        Log.d(TAG, "🔔 Clearing all notifications via native Android")
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager.cancelAll()
                        Log.d(TAG, "✅ All notifications cleared successfully")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Failed to clear notifications", e)
                        result.error("ERROR", "Failed to clear notifications", e.message)
                    }
                }
                "cancelNotification" -> {
                    try {
                        val notificationId = call.argument<Int>("id")
                        if (notificationId != null) {
                            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            notificationManager.cancel(notificationId)
                            Log.d(TAG, "✅ Notification $notificationId cancelled")
                            result.success(true)
                        } else {
                            result.error("BAD_ARGS", "Notification ID is required", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Failed to cancel notification", e)
                        result.error("ERROR", "Failed to cancel notification", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Existing testdrive channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    val eventId = call.argument<String>("eventId")
                    val totalDistance = call.argument<Double>("totalDistance") ?: 0.0
                    startBackgroundService(eventId, totalDistance)
                    result.success(true)
                }
                "stopBackgroundService" -> {
                    stopBackgroundService()
                    result.success(true)
                } 
                "openLocationSettings" -> {
                    openLocationSettings()
                    result.success(true)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                "isBatteryOptimizationDisabled" -> {
                    val isDisabled = isBatteryOptimizationDisabled()
                    result.success(isDisabled)
                }
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // New call log channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALLLOG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "listSimAccounts" -> {
                    try {
                        val sims = callLogManager.listSimAccounts()
                        result.success(sims)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error listing SIM accounts", e)
                        result.error("LIST_SIMS_ERROR", e.message, null)
                    }
                }
                "getCallLogsForAccount" -> {
                    val accountId = call.argument<String>("phoneAccountId")
                    val max = call.argument<Int>("limit") ?: 100
                    val afterMillis = call.argument<Long>("after")
                    
                    if (accountId.isNullOrEmpty()) {
                        result.error("BAD_ARGS", "phoneAccountId is required", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val logs = callLogManager.getCallLogsForAccount(accountId, max, afterMillis)
                        result.success(logs)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting call logs for account: $accountId", e)
                        result.error("QUERY_LOGS_ERROR", e.message, null)
                    }
                }
                "getAllCallLogs" -> {
                    val max = call.argument<Int>("limit") ?: 100
                    val afterMillis = call.argument<Long>("after")
                    
                    try {
                        val logs = callLogManager.getAllCallLogs(max, afterMillis)
                        result.success(logs)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting all call logs", e)
                        result.error("QUERY_ALL_LOGS_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent().apply {
                    action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
                Log.d(TAG, "Opened battery optimization settings")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open battery optimization settings", e)
                try {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    startActivity(intent)
                } catch (e2: Exception) {
                    Log.e(TAG, "Failed to open general battery optimization settings", e2)
                }
            }
        }
    }
    private fun startBackgroundService(eventId: String?, totalDistance: Double) {
        try {
            Log.d(TAG, "Starting Android background service for event: $eventId")
            
            val serviceIntent = Intent(this, TestDriveBackgroundService::class.java).apply {
                action = TestDriveBackgroundService.ACTION_START_TRACKING
                putExtra(TestDriveBackgroundService.EXTRA_EVENT_ID, eventId)
                putExtra(TestDriveBackgroundService.EXTRA_TOTAL_DISTANCE, totalDistance)
            }
            
            // Since we're not using foreground service anymore, just start regular service
            startService(serviceIntent)
            
            Log.d(TAG, "✅ Android background service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start Android background service", e)
        }
    }
    // private fun startBackgroundService(eventId: String?, totalDistance: Double) {
    //     try {
    //         Log.d(TAG, "Starting Android background service for event: $eventId")
            
    //         NotificationHelper.createNotificationChannel(this)
            
    //         val serviceIntent = Intent(this, TestDriveBackgroundService::class.java).apply {
    //             action = TestDriveBackgroundService.ACTION_START_TRACKING
    //             putExtra(TestDriveBackgroundService.EXTRA_EVENT_ID, eventId)
    //             putExtra(TestDriveBackgroundService.EXTRA_TOTAL_DISTANCE, totalDistance)
    //         }
            
    //         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    //             startForegroundService(serviceIntent)
    //         } else {
    //             startService(serviceIntent)
    //         }
            
    //         Log.d(TAG, "✅ Android background service started successfully")
    //     } catch (e: Exception) {
    //         Log.e(TAG, "❌ Failed to start Android background service", e)
    //     }
    // }

    private fun stopBackgroundService() {
        try {
            Log.d(TAG, "Stopping Android background service")
            
            val serviceIntent = Intent(this, TestDriveBackgroundService::class.java).apply {
                action = TestDriveBackgroundService.ACTION_STOP_TRACKING
            }
            startService(serviceIntent)
            
            Log.d(TAG, "✅ Android background service stop command sent")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to stop Android background service", e)
        }
    } 

    private fun openLocationSettings() {
        try {
            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            startActivity(intent)
            Log.d(TAG, "Opened location settings")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open location settings", e)
        }
    }

    private fun openAppSettings() {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.fromParts("package", packageName, null)
            }
            startActivity(intent)
            Log.d(TAG, "Opened app settings")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app settings", e)
        }
    } 
}



// package com.smartassist.app

// import io.flutter.embedding.android.FlutterFragmentActivity

// class MainActivity : FlutterFragmentActivity() // ✅ this is correct

// 📁 android/app/src/main/kotlin/com/smartassist/app/MainActivity.kt
// package com.smartassist.app

// import io.flutter.embedding.android.FlutterFragmentActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import android.content.Intent
// import android.net.Uri
// import android.os.Build
// import android.os.PowerManager
// import android.provider.Settings
// import android.util.Log
// import android.content.Context

// class MainActivity: FlutterFragmentActivity() { 
//     private val CHANNEL = "testdrive_native_service"
//     private val TAG = "MainActivity"

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)
        
//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             when (call.method) {
//                 "startBackgroundService" -> {
//                     val eventId = call.argument<String>("eventId")
//                     val totalDistance = call.argument<Double>("totalDistance") ?: 0.0
//                     startBackgroundService(eventId, totalDistance)
//                     result.success(true)
//                 }
//                 "stopBackgroundService" -> {
//                     stopBackgroundService()
//                     result.success(true)
//                 } 
//                 "openLocationSettings" -> {
//                     openLocationSettings()
//                     result.success(true)
//                 }
//                 "openAppSettings" -> {
//                     openAppSettings()
//                     result.success(true)
//                 }

//                 "cancelNotification" -> {
//                     NotificationHelper.cancelNotification(this)
//                     result.success(true)
//                 }
//                 else -> {
//                     result.notImplemented()
//                 }
//             }
//         }
//     }

//     // ✅ NEW: Background service methods
//     private fun startBackgroundService(eventId: String?, totalDistance: Double) {
//         try {
//             Log.d(TAG, "Starting Android background service for event: $eventId")
            
//             val serviceIntent = Intent(this, TestDriveBackgroundService::class.java).apply {
//                 action = TestDriveBackgroundService.ACTION_START_TRACKING
//                 putExtra(TestDriveBackgroundService.EXTRA_EVENT_ID, eventId)
//                 putExtra(TestDriveBackgroundService.EXTRA_TOTAL_DISTANCE, totalDistance)
//             }
            
//             if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                 startForegroundService(serviceIntent)
//             } else {
//                 startService(serviceIntent)
//             }
            
//             Log.d(TAG, "✅ Android background service started successfully")
//         } catch (e: Exception) {
//             Log.e(TAG, "❌ Failed to start Android background service", e)
//         }
//     }

//     private fun stopBackgroundService() {
//         try {
//             Log.d(TAG, "Stopping Android background service")
            
//             val serviceIntent = Intent(this, TestDriveBackgroundService::class.java).apply {
//                 action = TestDriveBackgroundService.ACTION_STOP_TRACKING
//             }
//             startService(serviceIntent)
            
//             Log.d(TAG, "✅ Android background service stop command sent")
//         } catch (e: Exception) {
//             Log.e(TAG, "❌ Failed to stop Android background service", e)
//         }
//     } 

//     // ✅ Location settings helper
//     private fun openLocationSettings() {
//         try {
//             val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
//             startActivity(intent)
//             Log.d(TAG, "Opened location settings")
//         } catch (e: Exception) {
//             Log.e(TAG, "Failed to open location settings", e)
//         }
//     }
    

//     // ✅ App settings helper
//     private fun openAppSettings() {
//         try {
//             val intent = Intent().apply {
//                 action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
//                 data = Uri.fromParts("package", packageName, null)
//             }
//             startActivity(intent)
//             Log.d(TAG, "Opened app settings")
//         } catch (e: Exception) {
//             Log.e(TAG, "Failed to open app settings", e)
//         }
//     }
// }

 