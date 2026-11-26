plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.ceosmos.companion"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.ceosmos.companion"
        minSdk = 26
        targetSdk = 36
        versionCode = 2
        versionName = "1.4.0"
    }

    // Un mismo código, tres apps:
    //  - reloj:     solo el periférico Reloj (UI circular).
    //  - tv:        solo el periférico TV (UI horizontal con D-pad).
    //  - companion: ambos servicios GATT en un mismo servidor (alternativa si dos
    //               apps no pudieran anunciar a la vez en la tablet).
    flavorDimensions += "modo"
    productFlavors {
        create("reloj") {
            dimension = "modo"
            applicationIdSuffix = ".reloj"
            resValue("string", "app_name", "CEOSMOS Reloj")
            buildConfigField("String", "ROLES", "\"reloj\"")
        }
        create("tv") {
            dimension = "modo"
            applicationIdSuffix = ".tv"
            resValue("string", "app_name", "CEOSMOS TV")
            buildConfigField("String", "ROLES", "\"tv\"")
        }
        create("companion") {
            dimension = "modo"
            resValue("string", "app_name", "CEOSMOS Companion")
            buildConfigField("String", "ROLES", "\"reloj,tv\"")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // Sin llave de firma propia en el proyecto: se firma con la de depuración
            // para poder instalarla en la tablet (riesgo documentado).
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
        resValues = true
    }
    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-core")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20260719") // Blindaje 22/11: 20180813 tenía 3 avisos DoS (OSV)
}
