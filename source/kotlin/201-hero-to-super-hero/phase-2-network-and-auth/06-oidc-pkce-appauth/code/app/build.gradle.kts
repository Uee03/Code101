plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.code101.tasks"
    compileSdk { version = release(37) }

    defaultConfig {
        applicationId = "com.code101.tasks.lab"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        manifestPlaceholders["appAuthRedirectScheme"] = "com.code101.tasks"
        buildConfigField("String", "OIDC_CLIENT_ID", "\"tasks-mobile\"")
        buildConfigField("String", "OIDC_REDIRECT_URI", "\"com.code101.tasks:/oauth2redirect\"")
        buildConfigField("String", "OIDC_LOGOUT_URI", "\"com.code101.tasks:/logout\"")
    }

    buildTypes {
        debug {
            buildConfigField(
                "String",
                "API_BASE_URL",
                "\"${providers.gradleProperty("apiBaseUrl").getOrElse("http://10.0.2.2:8000")}\"",
            )
            buildConfigField("String", "OIDC_ISSUER", "\"http://localhost:8180/realms/tasksteams\"")
        }
        release {
            buildConfigField(
                "String",
                "API_BASE_URL",
                "\"${providers.gradleProperty("apiBaseUrl").getOrElse("https://tasks.example.invalid")}\"",
            )
            buildConfigField(
                "String",
                "OIDC_ISSUER",
                "\"${providers.gradleProperty("oidcIssuer").getOrElse("https://identity.example.invalid/realms/tasksteams")}\"",
            )
        }
    }

    sourceSets.named("main") {
        kotlin.directories += "src/main/kotlin-generated/src/main/kotlin"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.activity.compose)
    implementation(libs.lifecycle.runtime)
    implementation(libs.lifecycle.viewmodel)
    implementation(libs.navigation)
    implementation(libs.serialization)
    implementation(libs.coroutines)
    implementation(libs.hilt.android)
    implementation(libs.hilt.viewmodel)
    ksp(libs.hilt.compiler)
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.appauth)
    implementation(libs.datastore)
    debugImplementation(libs.compose.ui.tooling)
}
