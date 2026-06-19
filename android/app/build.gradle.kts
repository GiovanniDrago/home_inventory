plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.home_inventory"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.home_inventory"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val props = keystorePropertiesFile.readLines()
                    .filter { it.contains("=") && !it.trim().startsWith("#") }
                    .associate {
                        val (key, value) = it.split("=", limit = 2)
                        key.trim() to value.trim()
                    }
                storeFile = file(props["storeFile"]!!)
                storePassword = props["storePassword"]!!
                keyAlias = props["keyAlias"]!!
                keyPassword = props["keyPassword"]!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
}

import com.android.build.gradle.internal.api.ApkVariantOutputImpl

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)

android.applicationVariants.configureEach { variant ->
    variant.outputs.forEach { output ->
        val abiFilter = output.filters.find { it.filterType == "ABI" }
        val abiVersionCode = abiCodes[abiFilter?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}

flutter {
    source = "../.."
}
