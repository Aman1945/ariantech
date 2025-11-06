// import java.util.Properties
// import java.io.FileInputStream

// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     id("dev.flutter.flutter-gradle-plugin")
//     id("com.google.gms.google-services")
//     id("com.google.firebase.crashlytics")
// }


// val keystoreProperties = Properties()
// val keystorePropertiesFile = rootProject.file("key.properties")
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(FileInputStream(keystorePropertiesFile))
// }

 

// android {
//     namespace = "com.smartassist.app"
//     compileSdk = 35
//     ndkVersion = "27.0.12077973" 

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_11
//         targetCompatibility = JavaVersion.VERSION_11
//         isCoreLibraryDesugaringEnabled = true 
//     }

//     kotlinOptions {
//         jvmTarget = "11"
//     }

//     defaultConfig {
//         applicationId = "com.smartassist.app"
//         minSdk = 24
//         targetSdk = 35
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//         multiDexEnabled = true

//          // Load from local.properties
//         val properties = Properties()
//         val localPropertiesFile = project.rootProject.file("local.properties")
//         if (localPropertiesFile.exists()) {
//             properties.load(FileInputStream(localPropertiesFile))
//         }
        
//         val googleMapsApiKey = properties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
        
//         // ✅ Use manifestPlaceholders (more secure than buildConfigField)
//         manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey 
//     } 

//       signingConfigs {
//         create("release") {
//             keyAlias = keystoreProperties["keyAlias"] as String
//             keyPassword = keystoreProperties["keyPassword"] as String
//             storeFile = keystoreProperties["storeFile"]?.let { file(it) }
//             storePassword = keystoreProperties["storePassword"] as String
//         }
//     }

//     buildTypes {
//         release {
//             signingConfig = signingConfigs.getByName("release")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // ✅ Required for Java 8+ features
//     implementation("androidx.multidex:multidex:2.0.1")
//     implementation ("com.google.android.gms:play-services-location:21.0.1")
//     implementation("org.jetbrains.kotlin:kotlin-reflect")
//     implementation(kotlin("stdlib-jdk8"))
//     implementation("com.google.firebase:firebase-crashlytics-ndk")
//     implementation("com.google.firebase:firebase-analytics")
// }
    



// // import java.util.Properties
// // import java.io.FileInputStream

// // plugins {
// //     id("com.android.application")
// //     id("kotlin-android")
// //     id("dev.flutter.flutter-gradle-plugin")
// //     id("com.google.gms.google-services")
// // }


// // android {
// //     namespace = "com.smartassist.app"
// //     compileSdk = 35
// //     ndkVersion = "27.0.12077973" 

// //     compileOptions {
// //         sourceCompatibility = JavaVersion.VERSION_11
// //         targetCompatibility = JavaVersion.VERSION_11
// //         isCoreLibraryDesugaringEnabled = true 
// //     }

// //     kotlinOptions {
// //         jvmTarget = "11"
// //     }

// //     defaultConfig {
// //         applicationId = "com.smartassist.app"
// //         minSdk = 23
// //         targetSdk = 35
// //         versionCode = flutter.versionCode
// //         versionName = flutter.versionName

// //         multiDexEnabled = true
// //     }
   

// //     buildTypes {
// //         release {
// //             signingConfig = signingConfigs.getByName("debug")
// //         }
// //     }
// // }

// // flutter {
// //     source = "../.."
// // }

// // dependencies {
// //     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // ✅ Required for Java 8+ features
// //     implementation("androidx.multidex:multidex:2.0.1")
// // }



import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// ✅ Load keystore properties safely
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.smartassist.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.smartassist.app"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // ✅ Load Google Maps key from local.properties
        val properties = Properties()
        val localPropertiesFile = project.rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            properties.load(FileInputStream(localPropertiesFile))
        }
        val googleMapsApiKey = properties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString() ?: ""
            keyPassword = keystoreProperties["keyPassword"]?.toString() ?: ""
            storeFile = keystoreProperties["storeFile"]?.toString()?.let { file(it) }
            storePassword = keystoreProperties["storePassword"]?.toString() ?: ""
        }
    }

    buildTypes {
        release {
            // ✅ Only use release keystore if available
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-location:21.0.1")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation(kotlin("stdlib-jdk8"))
    implementation("com.google.firebase:firebase-crashlytics-ndk")
    implementation("com.google.firebase:firebase-analytics")
}
