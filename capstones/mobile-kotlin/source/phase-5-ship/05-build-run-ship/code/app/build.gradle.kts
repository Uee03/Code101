import java.util.Properties
import java.net.URI

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}
val signingFile = rootProject.file("keystore.properties")
val signing = Properties().apply { if (signingFile.exists()) signingFile.inputStream().use { load(it) } }
android {
    signingConfigs {
        if (signingFile.exists()) create("upload") {
            storeFile = file(signing.getProperty("storeFile"))
            storePassword = providers.environmentVariable("TASKS_STORE_PASSWORD").get()
            keyAlias = signing.getProperty("keyAlias")
            keyPassword = providers.environmentVariable("TASKS_KEY_PASSWORD").get()
        }
    }
    namespace = "com.code101.tasks"
    compileSdk { version = release(37) { minorApiLevel = 2 } }
    buildToolsVersion = "36.0.0"
    defaultConfig {
        applicationId = "com.code101.tasks.kotlin"
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
            buildConfigField("String", "API_BASE_URL", "\"${providers.gradleProperty("apiBaseUrl").getOrElse("http://10.0.2.2:8000")}\"")
            buildConfigField("String", "OIDC_ISSUER", "\"http://localhost:8180/realms/tasksteams\"")
        }
        release {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName(if (signingFile.exists()) "upload" else "debug")
            buildConfigField("String", "API_BASE_URL", "\"${providers.gradleProperty("apiBaseUrl").getOrElse("https://tasks.example.invalid")}\"")
            buildConfigField("String", "OIDC_ISSUER", "\"${providers.gradleProperty("oidcIssuer").getOrElse("https://identity.example.invalid/realms/tasksteams")}\"")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    sourceSets.named("main") { kotlin.directories += "src/main/kotlin-generated/src/main/kotlin" }
    buildFeatures { compose = true; buildConfig = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
kotlin {
    compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}
ksp { arg("room.schemaLocation", "$projectDir/schemas") }
dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.activity.compose)
    implementation(libs.lifecycle.runtime)
    implementation(libs.lifecycle.viewmodel)
    implementation(libs.navigation)
    implementation(libs.hilt.android)
    implementation(libs.hilt.viewmodel)
    implementation(libs.hilt.work)
    ksp(libs.hilt.compiler)
    ksp(libs.hilt.worker.compiler)
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.work)
    implementation(libs.datastore)
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.serialization)
    implementation(libs.coroutines)
    implementation(libs.appauth)
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        val api = URI(providers.gradleProperty("apiBaseUrl").getOrElse("https://tasks.example.invalid"))
        val issuer = URI(providers.gradleProperty("oidcIssuer").getOrElse("https://identity.example.invalid/realms/tasksteams"))
        require(listOf(api, issuer).all { it.scheme == "https" && it.host != null && it.userInfo == null }) {
            "Release API and issuer must use HTTPS without credentials"
        }
        if (!signingFile.exists()) logger.warn("NOT FOR STORE: release bundle uses the local debug key")
    }
}
