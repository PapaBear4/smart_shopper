import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read signing properties (ensure the properties file exists and is gitignored!)
val keystorePropertiesFile = rootProject.file("gradle.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.smart_shopper"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" //flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.brambleberrytech.smart_shopper"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("MYAPP_RELEASE_KEY_ALIAS")
            keyPassword = keystoreProperties.getProperty("MYAPP_RELEASE_KEY_PASSWORD")
            storeFile = file(keystoreProperties.getProperty("MYAPP_RELEASE_STORE_FILE"))
            storePassword = keystoreProperties.getProperty("MYAPP_RELEASE_STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Signing with the release keys
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
            // Default debug configuration
        }
    }
}

flutter {
    source = "../.."
}
