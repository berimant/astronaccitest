plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.astronacci_test_flutter"
    compileSdk = 36 
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // FIX KRITIS (Hardcode): Langsung masukkan kredensial.
    // Peringatan: Hardcode SANGAT TIDAK AMAN jika kode ini di-commit ke Git.
    signingConfigs {
        create("release") {
            // FIX PATH: Menggunakan path relatif ("../") dari 'android/app/' ke 'android/'.
            storeFile = file("../astronacci_key.jks") 
            storePassword = "chindy" 
            keyAlias = "astronacci_alias"
            keyPassword = "chindy"
        }
    }

    defaultConfig {
        applicationId = "com.example.astronacci_test_flutter"
        minSdk = 21
        targetSdk = 36 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false // FIX: Menonaktifkan R8
            isShrinkResources = false // FIX: Menonaktifkan resource shrinking
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
