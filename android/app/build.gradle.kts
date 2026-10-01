val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun signingValue(environmentName: String, propertyName: String): String? =
    System.getenv(environmentName)
        ?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }

val uploadStoreFile = signingValue("ANDROID_UPLOAD_KEYSTORE_PATH", "storeFile")
val uploadStorePassword =
    signingValue("ANDROID_UPLOAD_STORE_PASSWORD", "storePassword")
val uploadKeyAlias = signingValue("ANDROID_UPLOAD_KEY_ALIAS", "keyAlias")
val uploadKeyPassword = signingValue("ANDROID_UPLOAD_KEY_PASSWORD", "keyPassword")
val hasUploadSigning = listOf(
    uploadStoreFile,
    uploadStorePassword,
    uploadKeyAlias,
    uploadKeyPassword,
).all { !it.isNullOrBlank() }

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.frainzzel.photocut"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.frainzzel.photocut"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadSigning) {
            create("release") {
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
                storeFile = rootProject.file(uploadStoreFile!!)
                storePassword = uploadStorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadSigning) {
                signingConfigs.getByName("release")
            } else {
                // Ordinary CI and local test builds keep the existing fallback.
                // Play-release CI always supplies protected upload credentials.
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
