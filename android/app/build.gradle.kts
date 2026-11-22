import java.util.Properties
import java.io.FileInputStream

// Llave de release propia (fuera del repo). Si no hay key.properties (por
// ejemplo en el CI), el release se firma con la llave de depuración.
val propiedadesLlave = Properties().apply {
    val archivo = rootProject.file("key.properties")
    if (archivo.exists()) load(FileInputStream(archivo))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Compose para las prácticas nativas 9 y 10.
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ceosmos.ceosmos_movil_integral"
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
        applicationId = "com.ceosmos.ceosmos_movil_integral"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        compose = true
    }

    signingConfigs {
        if (propiedadesLlave.isNotEmpty()) {
            create("release") {
                keyAlias = propiedadesLlave["keyAlias"] as String
                keyPassword = propiedadesLlave["keyPassword"] as String
                storeFile = file(propiedadesLlave["storeFile"] as String)
                storePassword = propiedadesLlave["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Blindaje: build aislada para monkey (otro paquete, convive con la app real
            // y las claves de Firebase restringidas por paquete la rechazan).
            // 22/11: la variable ORG_GRADLE_PROJECT_ceosmosMonkey NO llegó a la build y
            // `flutter test` desinstaló la app real del S24. Ahora también se activa con
            // el archivo marcador `android/app/.ceosmos_monkey` (lo crea y borra
            // scripts/mono_bloques.ps1, que además comprueba el paquete antes de correr).
            if (project.hasProperty("ceosmosMonkey") || file(".ceosmos_monkey").exists()) {
                applicationIdSuffix = ".monkey"
            }
        }
        release {
            signingConfig = if (propiedadesLlave.isNotEmpty()) signingConfigs.getByName("release")
            else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Prácticas nativas con Firebase (Reportes Firestore, P9, P10). Misma BoM que usa FlutterFire.
    // No se aplica el plugin google-services: cada práctica crea su FirebaseApp con nombre.
    implementation(platform("com.google.firebase:firebase-bom:34.19.0"))
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-auth")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")
    // Prácticas 9 y 10 (Jetpack Compose), versiones de sus build.gradle originales.
    implementation("androidx.core:core-ktx:1.13.1")
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-core")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
