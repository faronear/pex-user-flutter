plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cc.tic.pex_user_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // 允许 flavor 定义自定义资源值（resValue application name）。
        resValues = true
    }

    defaultConfig {
        // 默认包名（实际以各 flavor 的 applicationId 为准）。
        applicationId = "cc.tic.pex_user_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 三品牌 flavors：`flutter build apk --flavor agidin`。
    // 品牌差异（包名/应用名）在此定义；Dart 侧入口见 lib/main_<brand>.dart。
    flavorDimensions += "brand"
    productFlavors {
        create("agidin") {
            dimension = "brand"
            applicationId = "cc.tic.agidin"
            resValue("string", "app_name", "Agidin")
        }
        create("babelyx") {
            dimension = "brand"
            applicationId = "cc.tic.babelyx"
            resValue("string", "app_name", "Babelyx")
        }
        create("tryapp") {
            dimension = "brand"
            applicationId = "cc.tic.tryapp"
            resValue("string", "app_name", "TRYAPP")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
