import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.4" apply false
}

android {
    namespace = "club.ntut.tattoo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "club.ntut.tattoo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = System.getenv("MATCH_KEYSTORE_PATH")?.let { file(it) }
            storePassword = System.getenv("MATCH_KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("MATCH_KEYSTORE_ALIAS_NAME") ?: ""
            keyPassword = System.getenv("MATCH_KEYSTORE_ALIAS_PASSWORD") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = if (System.getenv("MATCH_KEYSTORE_PATH").isNullOrEmpty()) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.fromTarget("17")
    }
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.2.0")
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    implementation("com.google.firebase:firebase-analytics")

}

flutter {
    source = "../.."
}
