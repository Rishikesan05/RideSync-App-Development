import java.util.Properties
import java.io.FileInputStream

val envFile = rootProject.projectDir.parentFile.resolve(".env")
val env = Properties()
if (envFile.exists()) {
    env.load(FileInputStream(envFile))
    println("Loaded .env from: ${envFile.absolutePath}")
} else {
    println(".env file not found at: ${envFile.absolutePath}")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.ridesync.ridesync_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ridesync.ridesync_mobile"
        minSdk = flutter.minSdkVersion // Increased for Firebase support
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["mapsApiKey"] = env.getProperty("GOOGLE_MAPS_API_KEY") ?: "YOUR_GOOGLE_MAPS_API_KEY_HERE"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
