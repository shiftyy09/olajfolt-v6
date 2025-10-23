plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.car_maintenance_app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {

        // Desugaring bekapcsolása
        isCoreLibraryDesugaringEnabled = true


        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.car_maintenance_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName


        // MultiDex bekapcsolása (fontos a desugaring-hoz)
        multiDexEnabled = true

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


// A hiányzó `dependencies` blokk hozzáadása a desugaring könyvtárral
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}


