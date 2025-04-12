plugins {
    id("com.android.application")
<<<<<<< HEAD
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
=======
>>>>>>> 1ade028f5ff23de3dde1390dc19f70ec431e725e
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
<<<<<<< HEAD
dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:33.11.0"))


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}
android {
    namespace = "com.example.terafarm1"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
=======

android {
    namespace = "com.example.terafarm01"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
>>>>>>> 1ade028f5ff23de3dde1390dc19f70ec431e725e

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
<<<<<<< HEAD
        applicationId = "com.example.terafarm1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 35
=======
        applicationId = "com.example.terafarm01"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
>>>>>>> 1ade028f5ff23de3dde1390dc19f70ec431e725e
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
