plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// 发布签名从 gitignore 的 key.properties 读取（与 einz/app 共用同一 keystore，不在仓库内）。
// 用法：在 android/key.properties 填入 storePassword / keyPassword / keyAlias / storeFile。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties: Properties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
val hasReleaseKey = keystoreProperties.getProperty("keyAlias") != null

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
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // 有 key.properties 时用真实 keystore 签名，否则退回 debug key（与 einz/app 现状一致）。
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
