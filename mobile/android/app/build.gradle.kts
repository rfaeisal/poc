plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fakhriez.poc_pecek"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fakhriez.poc_pecek"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    flavorDimensions += "app"
    productFlavors {
        create("pocPecek") {
            dimension = "app"
            applicationId = "com.fakhriez.poc_pecek"
            resValue("string", "app_name", "POC-SMART")
        }
        create("hytera") {
            dimension = "app"
            applicationId = "com.fakhriez.poc_ptx"
            resValue("string", "app_name", "POC-SMART")
            minSdk = 31
        }
        create("ksun") {
            dimension = "app"
            applicationId = "com.fakhriez.poc_ksun"
            resValue("string", "app_name", "POC-SMART")
            minSdk = (project.property("ksun.minSdk") as String).toInt()
            proguardFile("proguard-ksun.pro")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Force older AndroidX core for KSUN API 22 compat
configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.12.0")
        force("androidx.core:core-ktx:1.12.0")
    }
}

// For KSUN: force webrtc-sdk 137 which supports API 21
// (144 uses __register_atfork and other API 23+ symbols)
afterEvaluate {
    configurations.matching { it.name.lowercase().contains("ksun") }.all {
        resolutionStrategy {
            force("io.github.webrtc-sdk:android:137.7151.04")
        }
    }
}

gradle.taskGraph.whenReady {
    allTasks.filter { it.name.contains("Ksun") && it.name.endsWith("MinSdkCheck") }.forEach {
        it.enabled = false
    }
}



