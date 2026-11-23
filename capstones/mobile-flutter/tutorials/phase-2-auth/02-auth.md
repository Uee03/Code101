---
track: capstone
level: 201
phase: 2
phase_name: auth
lesson: 02
title: "Auth (PKCE) and secure storage"
time: 90 min
prerequisites: [capstone-mobile-flutter-01]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", android_build_tools: "36.0.0", gradle: "9.5.0", agp: "9.3.1" }
verified: not yet run
source: capstones/mobile-flutter/source/phase-2-auth/02-auth/
assets: [arrows/log-in, arrows/log-out, arrows/refresh-cw, users/team, files/folder, ui/list, ui/plus, ui/settings, devices/wifi-off, communication/message-square]
---

# 02. Auth (PKCE) and secure storage

## Why it matters
A hotel key card is not the guest?s password. The system browser proves identity, then gives the app limited-lived credentials. Rotation makes refresh a serialized operation, not a convenience call every screen may race.

## What you will build
System-browser authorization code with PKCE, one encrypted token blob, serialized refresh, rotation persistence, browser sign-out and a go_router guard. After sign-in a Teams placeholder explicitly defers real data to chapter 03.

Requirements taught: **M-05?M-09, M-26**. This chapter is **written (not run)**. Executable verification was stopped at the user's request; a static source/text comparison is not runtime verification. Historical error excerpts below were captured before that stop and are not evidence that these final files were run.

## Before you start
- Flutter 3.50.1 / Dart 3.14.0; Android Studio JBR; SDK platform 36, build-tools 36.0.0 and NDK 28.2.13676358. SDK 37.2 alone does not supply these template requirements. Plugins may also request platform 35/CMake. The earlier Flutter Doctor accepted Android licenses; a desktop Chrome warning does not prevent an Android APK build.
- A terminal: the prompt tells you its current folder. All app commands run beside `pubspec.yaml`, not in the capstone documentation folder. PowerShell commands are 5.1-compatible; Flutter/Dart commands are identical on macOS/Linux. Use `python3` if `python` is unavailable there.
- Unzip `mobile-flutter-phase-2-auth.zip` (Windows: right-click ? **Extract All**; macOS: double-click; Linux: `unzip`). Open `02-auth/code` in Android Studio or VS Code. This is a whole phase snapshot, not a patch; do not combine phase folders.
- A dot on an editor tab means unsaved changes. Save each file before comparing or running later.
- Exact package pins and sources are in [VERSION-NOTES.md](../../VERSION-NOTES.md). The platform TDD section 12.1 **Decision** column resolves older contract omissions. Do not edit that contract or another capstone as a client workaround.

## Steps
### Step 1. Prepare one app workspace
Continue in the same workspace from chapter 01, or open `02-auth/code` from this phase?s pack. Whole files below deliberately repeat unchanged snapshot files so the phase is standalone. A later edit to a long file is shown as a **whole replacement**, not a context-free edit; no region is omitted. Preserve your private local.properties and build caches locally, but never distribute them. Phase 4 switches the store provider, not the view/repository interfaces.

The commands in each step create its concrete parent folders. Directory creation and saving are the only genuinely repeated operations: every distinct path and full file is listed. Create new folders first, then create/replace and save each captioned file. No build is run halfway through an incomplete app.

### Step 2. Pin packages and public build configuration

Work in the app root. Create or replace these files and save their full contents.

#### Read every configuration setting
- `name`, `description`, `publish_to`, `version`, `environment.sdk` identify the private learning app and SDK range. Runtime `dependencies` differ from `dev_dependencies` (generation/analysis tools). SDK dependencies use this Flutter installation. `assets` paths are app-root relative and case-sensitive on other platforms. `uses-material-design: false` avoids an external icon font.
- Riverpod supplies state and DI; go_router routes; Dio transports; AppAuth/secure storage wrap native behavior; drift persists; connectivity hints at reachability; WorkManager schedules; flutter_svg draws supplied art; uuid creates retry keys; intl formats values. JSON/build_runner/drift_dev generate parts; swagger_parser generates the contract client. material_ui is Flutter?s extracted official Material package, and path_provider locates the token-free lock file.
- API_BASE_URL is an origin: generated paths already include `/v1`, so do not append it. OIDC_ISSUER contains the exact realm path; OIDC_CLIENT_ID and redirect/logout URIs match the realm. All five define values are public, not secrets.
- `applicationId` controls installation; `namespace` locates MainActivity. Different twin ids avoid replacing each other, but the shared OAuth scheme still means only one twin should be installed for this exercise. `manifestPlaceholders +=` preserves Flutter?s other placeholders.
- `compileSdk`/`targetSdk` come from Flutter, `minSdk=26` is our floor, version code/name come from pubspec. Java/Kotlin bytecode targets are 17 even on a newer JBR runtime; desugaring supplies newer library APIs on supported older devices.
- Main manifest INTERNET enables API/identity traffic. `allowBackup=false` prevents ciphertext/key restore separation. General cleartext is denied; only debug names the network policy. XML denies by default, then permits the three exact development hosts without subdomains. Dart enforces the same rule for its transport.
- Flutter recreates local.properties for your machine during a later authorized build. The Gradle wrapper version is pinned; Google/Maven/plugin repositories resolve tooling. Wrapper scripts and JAR are standard scaffold artifacts, not feature code.
- `org.gradle.jvmargs`, worker limits and daemon settings constrain resources; AndroidX is enabled. Compatibility flags retain the template?s current AGP/Kotlin integration. Do not change flags just to silence a future plugin warning.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'config' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'config'
```

#### `.gitignore`
Exclude local caches and private Android signing material, while retaining pubspec.lock. Ignore rules do not erase previously committed secrets.

Create or replace this file, then save it:

**File: `.gitignore`**
```text
.dart_tool/
.flutter-plugins-dependencies
build/
.idea/
*.iml
android/.gradle/
android/local.properties
android/key.properties
*.jks
*.keystore
*.hprof
```

#### `analysis_options.yaml`
Use Flutter?s maintained lints. Exclude generated/build/platform files, not authored Dart. Do not silence a real authored-code warning.

Create or replace this file, then save it:

**File: `analysis_options.yaml`**
```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  exclude:
    - lib/data/generated/**
    - '**/*.g.dart'
    - lib/l10n/generated/**
    - build/**
    - android/**
```

#### `config/dev.json`
Only the emulator API uses 10.0.2.2. The issuer stays localhost so discovery and bearer validation agree. Client id and redirect/logout paths must match the realm exactly.

Create or replace this file, then save it:

**File: `config/dev.json`**
```json
{
  "API_BASE_URL": "http://10.0.2.2:8000",
  "OIDC_ISSUER": "http://localhost:8180/realms/tasksteams",
  "OIDC_CLIENT_ID": "tasks-mobile",
  "OIDC_REDIRECT_URI": "com.code101.tasks:/oauth2redirect",
  "OIDC_LOGOUT_URI": "com.code101.tasks:/logout"
}
```

#### `config/release.example.json`
HTTPS .invalid hosts are deliberate examples, not a production service. Public define files must never hold a client secret or password.

Create or replace this file, then save it:

**File: `config/release.example.json`**
```json
{
  "API_BASE_URL": "https://tasks.example.invalid",
  "OIDC_ISSUER": "https://identity.example.invalid/realms/tasksteams",
  "OIDC_CLIENT_ID": "tasks-mobile",
  "OIDC_REDIRECT_URI": "com.code101.tasks:/oauth2redirect",
  "OIDC_LOGOUT_URI": "com.code101.tasks:/logout"
}
```

#### `config/usb.json`
The phone uses localhost for both services through adb reverse. The emulator alias does not exist on a physical phone.

Create or replace this file, then save it:

**File: `config/usb.json`**
```json
{
  "API_BASE_URL": "http://localhost:8000",
  "OIDC_ISSUER": "http://localhost:8180/realms/tasksteams",
  "OIDC_CLIENT_ID": "tasks-mobile",
  "OIDC_REDIRECT_URI": "com.code101.tasks:/oauth2redirect",
  "OIDC_LOGOUT_URI": "com.code101.tasks:/logout"
}
```

#### `pubspec.yaml`
Pin runtime packages separately from generator/analysis tools; retain pubspec.lock for transitive versions. uses-material-design is false: the app uses the listed SVGs, not an external icon font.

Create or replace this file, then save it:

**File: `pubspec.yaml`**
```yaml
name: tasks_flutter
description: Code101 Tasks and Teams Android client.
publish_to: none
version: 1.0.0+1
environment:
  sdk: '>=3.14.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  material_ui: 1.11.1
  flutter_riverpod: 3.5.0
  go_router: 18.1.4
  dio: 5.11.1
  json_annotation: 4.12.0
  flutter_appauth: 13.0.0
  flutter_secure_storage: 11.2.0
  drift: 2.35.4
  drift_flutter: 0.3.1
  connectivity_plus: 7.3.2
  workmanager: 0.10.10
  flutter_svg: 2.5.0
  uuid: 4.6.0
  intl: 0.20.3
  path_provider: 2.1.6
dev_dependencies:
  flutter_lints: 6.0.0
  swagger_parser: 2.3.0
  json_serializable: 6.15.2
  build_runner: 2.17.1
  drift_dev: 2.35.3
flutter:
  uses-material-design: false
  assets:
    - lib/l10n/app_en.arb
    - assets/icons/log-in.svg
    - assets/icons/log-out.svg
    - assets/icons/refresh-cw.svg
    - assets/icons/team.svg
    - assets/icons/folder.svg
    - assets/icons/list.svg
    - assets/icons/plus.svg
    - assets/icons/settings.svg
    - assets/icons/wifi-off.svg
    - assets/icons/message-square.svg
```

#### `swagger_parser.yaml`
schema_path is the copied contract; output_directory is the generated-code boundary. Nested generation selects standalone Dio plus json_serializable parts, without Retrofit or a Java generator.

Create or replace this file, then save it:

**File: `swagger_parser.yaml`**
```yaml
swagger_parser:
  schema_path: contract/openapi.yaml
  output_directory: lib/data/generated
  generation:
    root_api_class_name: TasksApi
    http_client: dio
    serializer: json_serializable
    response_mode: first_success
    generate_docs: true
```

### Step 3. Configure the Android host in full

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'android' | Out-Null
New-Item -ItemType Directory -Force 'android/app' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/debug' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/debug/res/xml' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/main' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/main/kotlin/com/code101/tasks' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/main/res/drawable' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/main/res/drawable-v21' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/main/res/values' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/main/res/values-night' | Out-Null
New-Item -ItemType Directory -Force 'android/app/src/profile' | Out-Null
New-Item -ItemType Directory -Force 'android/gradle/wrapper' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'android'
mkdir -p 'android/app'
mkdir -p 'android/app/src/debug'
mkdir -p 'android/app/src/debug/res/xml'
mkdir -p 'android/app/src/main'
mkdir -p 'android/app/src/main/kotlin/com/code101/tasks'
mkdir -p 'android/app/src/main/res/drawable'
mkdir -p 'android/app/src/main/res/drawable-v21'
mkdir -p 'android/app/src/main/res/values'
mkdir -p 'android/app/src/main/res/values-night'
mkdir -p 'android/app/src/profile'
mkdir -p 'android/gradle/wrapper'
```

#### `android/.gitignore`
This complete Flutter Android scaffold configuration is retained so the phase is independently usable. Keep machine-local SDK paths and signing material out of these files.

Create or replace this file, then save it:

**File: `android/.gitignore`**
```text
gradle-wrapper.jar
/.gradle
/captures/
/gradlew
/gradlew.bat
/local.properties
GeneratedPluginRegistrant.java
.cxx/

# Remember to never publicly share your keystore.
# See https://flutter.dev/to/reference-keystore
key.properties
**/*.keystore
**/*.jks
```

#### `android/app/build.gradle.kts`
Set distinct install id and namespace, minSdk 26, Flutter compile/target defaults, Java/Kotlin 17 bytecode and desugaring. Merge lowercase AppAuth placeholders. Phase 5 conditionally reads private upload signing and labels fallback NOT FOR STORE.

Create or replace this file, then save it:

**File: `android/app/build.gradle.kts`**
```kotlin
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.code101.tasks"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    defaultConfig {
        applicationId = "com.code101.tasks.flutter"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders += mapOf("appAuthRedirectScheme" to "com.code101.tasks")
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
```

#### `android/app/src/debug/AndroidManifest.xml`
Only this debug overlay refers to networkSecurityConfig. Do not move that attribute to main or release.

Create or replace this file, then save it:

**File: `android/app/src/debug/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:networkSecurityConfig="@xml/network_security_config" />
</manifest>
```

#### `android/app/src/debug/res/xml/network_security_config.xml`
Deny cleartext by default; permit only the three exact debug hosts with no subdomains. A broad usesCleartextTraffic=true exception would be unsafe.

Create or replace this file, then save it:

**File: `android/app/src/debug/res/xml/network_security_config.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">localhost</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

#### `android/app/src/main/AndroidManifest.xml`
Require INTERNET, disable backups/general cleartext, configure the exported launcher and preserve Flutter embedding metadata. AppAuth supplies its redirect activity via plugin manifest and the Gradle placeholder.

Create or replace this file, then save it:

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:label="Tasks and Teams" android:name="${applicationName}" android:allowBackup="false" android:usesCleartextTraffic="false">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:theme="@style/LaunchTheme" android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode" android:hardwareAccelerated="true" android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="code101-tasks-flutter" android:host="app" />
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
        <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
    </application>
</manifest>
```

#### `android/app/src/main/kotlin/com/code101/tasks/MainActivity.kt`
The minimal FlutterActivity supplies Android embedding. No data logic, token handling or direct HTTP belongs in the launcher.

Create or replace this file, then save it:

**File: `android/app/src/main/kotlin/com/code101/tasks/MainActivity.kt`**
```kotlin
package com.code101.tasks

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

#### `android/app/src/main/res/drawable/launch_background.xml`
Keep the plain Android resource background. It contains no network behavior, credentials or third-party image.

Create or replace this file, then save it:

**File: `android/app/src/main/res/drawable/launch_background.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
```

#### `android/app/src/main/res/drawable-v21/launch_background.xml`
Keep the plain Android resource background. It contains no network behavior, credentials or third-party image.

Create or replace this file, then save it:

**File: `android/app/src/main/res/drawable-v21/launch_background.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="?android:colorBackground" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
```

#### `android/app/src/main/res/values/styles.xml`
The complete Android launch/normal themes provide a plain native background while Flutter starts. No external splash or launcher artwork is added.

Create or replace this file, then save it:

**File: `android/app/src/main/res/values/styles.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

#### `android/app/src/main/res/values-night/styles.xml`
The complete Android launch/normal themes provide a plain native background while Flutter starts. No external splash or launcher artwork is added.

Create or replace this file, then save it:

**File: `android/app/src/main/res/values-night/styles.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is on -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

#### `android/app/src/profile/AndroidManifest.xml`
This complete Flutter Android scaffold configuration is retained so the phase is independently usable. Keep machine-local SDK paths and signing material out of these files.

Create or replace this file, then save it:

**File: `android/app/src/profile/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- The INTERNET permission is required for development. Specifically,
         the Flutter tool needs it to communicate with the running application
         to allow setting breakpoints, to provide hot reload, etc.
    -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

#### `android/build.gradle.kts`
This complete Flutter Android scaffold configuration is retained so the phase is independently usable. Keep machine-local SDK paths and signing material out of these files.

Create or replace this file, then save it:

**File: `android/build.gradle.kts`**
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```

#### `android/gradle/wrapper/gradle-wrapper.properties`
Pin Gradle 9.5.0. The download URL is tooling, not app configuration. Generated wrapper scripts and the binary JAR belong together.

Create or replace this file, then save it:

**File: `android/gradle/wrapper/gradle-wrapper.properties`**
```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.5.0-all.zip
```

#### `android/gradle.properties`
Bound heap/workers, enable AndroidX, keep template compatibility flags, disable cross-drive Windows incremental caching, and avoid a persistent Gradle daemon.

Create or replace this file, then save it:

**File: `android/gradle.properties`**
```properties
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
# This newDsl flag was added by the Flutter template
android.newDsl=false
# This builtInKotlin flag was added by the Flutter template
android.builtInKotlin=false

# Avoid cross-drive Kotlin incremental cache failures on Windows.
kotlin.incremental=false
org.gradle.workers.max=2
org.gradle.daemon=false
```

#### `android/gradlew`
This standard generated Gradle wrapper script finds Java and launches its paired JAR. The exact generated text is supplied; app-specific credentials never belong here.

Create or replace this file, then save it:

**File: `android/gradlew`**
```text
#!/usr/bin/env bash

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS=""

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn ( ) {
    echo "$*"
}

die ( ) {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
case "`uname`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
esac

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "$cygwin" = "false" -a "$darwin" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if $darwin; then
    GRADLE_OPTS="$GRADLE_OPTS \"-Xdock:name=$APP_NAME\" \"-Xdock:icon=$APP_HOME/media/gradle.icns\""
fi

# For Cygwin, switch paths to Windows format before running java
if $cygwin ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
    JAVACMD=`cygpath --unix "$JAVACMD"`

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=`find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null`
    SEP=""
    for dir in $ROOTDIRSRAW ; do
        ROOTDIRS="$ROOTDIRS$SEP$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "$@" ; do
        CHECK=`echo "$arg"|egrep -c "$OURCYGPATTERN" -`
        CHECK2=`echo "$arg"|egrep -c "^-"`                                 ### Determine if an option

        if [ $CHECK -ne 0 ] && [ $CHECK2 -eq 0 ] ; then                    ### Added a condition
            eval `echo args$i`=`cygpath --path --ignore --mixed "$arg"`
        else
            eval `echo args$i`="\"$arg\""
        fi
        i=$((i+1))
    done
    case $i in
        (0) set -- ;;
        (1) set -- "$args0" ;;
        (2) set -- "$args0" "$args1" ;;
        (3) set -- "$args0" "$args1" "$args2" ;;
        (4) set -- "$args0" "$args1" "$args2" "$args3" ;;
        (5) set -- "$args0" "$args1" "$args2" "$args3" "$args4" ;;
        (6) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" ;;
        (7) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" ;;
        (8) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" ;;
        (9) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" "$args8" ;;
    esac
fi

# Split up the JVM_OPTS And GRADLE_OPTS values into an array, following the shell quoting and substitution rules
function splitJvmOpts() {
    JVM_OPTS=("$@")
}
eval splitJvmOpts $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS
JVM_OPTS[${#JVM_OPTS[*]}]="-Dorg.gradle.appname=$APP_BASE_NAME"

exec "$JAVACMD" "${JVM_OPTS[@]}" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
```

#### `android/gradlew.bat`
This standard generated Gradle wrapper script finds Java and launches its paired JAR. The exact generated text is supplied; app-specific credentials never belong here.

Create or replace this file, then save it:

**File: `android/gradlew.bat`**
```bat
@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

@rem Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windowz variants

if not "%OS%" == "Windows_NT" goto win9xME_args
if "%@eval[2+2]" == "4" goto 4NT_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto execute

set CMD_LINE_ARGS=%*
goto execute

:4NT_args
@rem Get arguments from the 4NT Shell from JP Software
set CMD_LINE_ARGS=%$

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%GRADLE_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
```

#### `android/settings.gradle.kts`
Read the locally supplied Flutter SDK path, include its build and repositories, and pin template plugin versions. local.properties is machine-local and absent from the pack.

Create or replace this file, then save it:

**File: `android/settings.gradle.kts`**
```kotlin
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.3.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

include(":app")
```

### Step 4. Copy the platform contract unchanged

Work in the app root. Create or replace these files and save their full contents.

When authoring from scratch, copy the existing platform file unchanged. `$repo`/`repo` must be your Code101 root (set it in Step 1 or use your checkout?s absolute path). In the pack this exact copy already exists.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force contract | Out-Null
Copy-Item "$repo/capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml" contract/openapi.yaml
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p contract
cp "$repo/capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml" contract/openapi.yaml
```

Its full text below is for comparison, not permission to change a mobile fork. The platform chapter already explains each endpoint/schema; these copy steps are genuinely identical and introduce no mobile-specific contract differences.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'contract' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'contract'
```

#### `contract/openapi.yaml`
This is the byte-for-byte platform contract. Its full text is shown for an offline reader; never repair a generator problem by editing a mobile fork. Platform section 12.1 Decision column resolves documented gaps.

Create or replace this file, then save it:

**File: `contract/openapi.yaml`**
```yaml
openapi: 3.1.1
info:
  title: Tasks and Teams API
  version: 1.0.0
  summary: The shared contract every Code101 backend implements and every client consumes.
  description: |
    Domain: teams, members, projects, tasks, comments and an audit trail.
    Conventions (apply to every operation unless stated otherwise):

    - Version prefix `/v1`. `/health` is unversioned infrastructure.
    - Errors are RFC 9457 problem details (`application/problem+json`).
    - Lists use cursor pagination: `limit` and `cursor` in, `items` and `page.nextCursor` out.
    - Single resources carry a strong `ETag` (the quoted `version`). Updates and deletes of
      versioned resources need `If-Match`: missing gives 428, stale gives 412.
    - Creates accept an optional `Idempotency-Key` header; a replay returns the first response
      with `Idempotent-Replayed: true`.
    - Every response carries `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset`;
      a throttled request gets 429 with `Retry-After`.
  license:
    name: MIT
    identifier: MIT
servers:
  - url: http://localhost:8000
    description: Local backend (any of the four implementations, port 8000)
tags:
  - name: Platform
    description: Health and the calling user
  - name: Teams
  - name: Members
  - name: Projects
  - name: Tasks
  - name: Comments
  - name: Audit
security:
  - oidc: [tasks:read]
paths:
  /health:
    get:
      operationId: getHealth
      tags: [Platform]
      summary: Liveness and database check
      security: []
      x-access: public
      responses:
        '200':
          description: The service and its database are reachable.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Health' }
        '503':
          description: The database is not reachable.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Health' }
  /v1/me:
    get:
      operationId: getMe
      tags: [Platform]
      summary: The calling user, roles, scopes and team memberships
      x-access: authenticated
      responses:
        '200':
          description: The caller. The user row is created on the first authenticated request.
          headers:
            RateLimit-Limit: { $ref: '#/components/headers/RateLimitLimit' }
            RateLimit-Remaining: { $ref: '#/components/headers/RateLimitRemaining' }
            RateLimit-Reset: { $ref: '#/components/headers/RateLimitReset' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Me' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '429': { $ref: '#/components/responses/TooManyRequests' }
  /v1/users:
    get:
      operationId: listUsers
      tags: [Platform]
      summary: Find users, for example to add a team member
      x-access: authenticated
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
        - name: q
          in: query
          description: Case-insensitive prefix of username or display name.
          schema: { type: string, minLength: 1, maxLength: 100 }
      responses:
        '200':
          description: One page of users.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/UserPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
  /v1/teams:
    get:
      operationId: listTeams
      tags: [Teams]
      summary: Teams the caller belongs to (admins see every team)
      x-access: authenticated
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
        - { $ref: '#/components/parameters/SortCreated' }
        - name: q
          in: query
          description: Case-insensitive prefix of the team name.
          schema: { type: string, minLength: 1, maxLength: 100 }
      responses:
        '200':
          description: One page of teams.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/TeamPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
    post:
      operationId: createTeam
      tags: [Teams]
      summary: Create a team (admin); the lead becomes its first member
      x-access: admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IdempotencyKey' }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/TeamCreate' }
      responses:
        '201':
          description: Created.
          headers:
            Location: { $ref: '#/components/headers/Location' }
            ETag: { $ref: '#/components/headers/ETag' }
            Idempotent-Replayed: { $ref: '#/components/headers/IdempotentReplayed' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Team' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '409': { $ref: '#/components/responses/Conflict' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
  /v1/teams/{teamId}:
    parameters:
      - { $ref: '#/components/parameters/TeamId' }
    get:
      operationId: getTeam
      tags: [Teams]
      summary: One team
      x-access: team-member-or-admin
      responses:
        '200':
          description: The team.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Team' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
    patch:
      operationId: updateTeam
      tags: [Teams]
      summary: Change name or description (JSON Merge Patch)
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IfMatch' }
      requestBody:
        required: true
        content:
          application/merge-patch+json:
            schema: { $ref: '#/components/schemas/TeamUpdate' }
          application/json:
            schema: { $ref: '#/components/schemas/TeamUpdate' }
      responses:
        '200':
          description: The updated team with its new ETag.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Team' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
        '428': { $ref: '#/components/responses/PreconditionRequired' }
    delete:
      operationId: deleteTeam
      tags: [Teams]
      summary: Delete a team with its projects, tasks and comments (admin)
      x-access: admin
      security:
        - oidc: [tasks:admin]
      responses:
        '204':
          description: Deleted.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
  /v1/teams/{teamId}/members:
    parameters:
      - { $ref: '#/components/parameters/TeamId' }
    get:
      operationId: listMembers
      tags: [Members]
      summary: Members of a team
      x-access: team-member-or-admin
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
      responses:
        '200':
          description: One page of members.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/MemberPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
  /v1/teams/{teamId}/members/{userId}:
    parameters:
      - { $ref: '#/components/parameters/TeamId' }
      - { $ref: '#/components/parameters/UserId' }
    put:
      operationId: putMember
      tags: [Members]
      summary: Add a member or change their team role (idempotent)
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/MemberPut' }
      responses:
        '200':
          description: The member already existed; the role was updated.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Member' }
        '201':
          description: The member was added.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Member' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
    delete:
      operationId: removeMember
      tags: [Members]
      summary: Remove a member; the last lead cannot be removed
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      responses:
        '204':
          description: Removed.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
  /v1/teams/{teamId}/projects:
    parameters:
      - { $ref: '#/components/parameters/TeamId' }
    get:
      operationId: listProjects
      tags: [Projects]
      summary: Projects of a team
      x-access: team-member-or-admin
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
        - { $ref: '#/components/parameters/SortCreated' }
        - name: archived
          in: query
          description: Default false (hide archived projects).
          schema: { type: boolean, default: false }
      responses:
        '200':
          description: One page of projects.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/ProjectPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
    post:
      operationId: createProject
      tags: [Projects]
      summary: Create a project in the team
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IdempotencyKey' }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ProjectCreate' }
      responses:
        '201':
          description: Created.
          headers:
            Location: { $ref: '#/components/headers/Location' }
            ETag: { $ref: '#/components/headers/ETag' }
            Idempotent-Replayed: { $ref: '#/components/headers/IdempotentReplayed' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Project' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
  /v1/projects/{projectId}:
    parameters:
      - { $ref: '#/components/parameters/ProjectId' }
    get:
      operationId: getProject
      tags: [Projects]
      summary: One project
      x-access: team-member-or-admin
      responses:
        '200':
          description: The project.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Project' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
    patch:
      operationId: updateProject
      tags: [Projects]
      summary: Change name, description or archive a project (JSON Merge Patch)
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IfMatch' }
      requestBody:
        required: true
        content:
          application/merge-patch+json:
            schema: { $ref: '#/components/schemas/ProjectUpdate' }
          application/json:
            schema: { $ref: '#/components/schemas/ProjectUpdate' }
      responses:
        '200':
          description: The updated project with its new ETag.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Project' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
        '428': { $ref: '#/components/responses/PreconditionRequired' }
    delete:
      operationId: deleteProject
      tags: [Projects]
      summary: Delete a project with its tasks and comments
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      responses:
        '204':
          description: Deleted.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
  /v1/projects/{projectId}/tasks:
    parameters:
      - { $ref: '#/components/parameters/ProjectId' }
    get:
      operationId: listTasks
      tags: [Tasks]
      summary: Tasks of a project, filtered and paged
      x-access: team-member-or-admin
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
        - name: sort
          in: query
          description: Order. `dueDate` lists tasks without a due date last. Ties break on `id`.
          schema:
            type: string
            enum: [-createdAt, createdAt, dueDate]
            default: -createdAt
        - name: status
          in: query
          description: Repeat the parameter to match several statuses.
          style: form
          explode: true
          schema:
            type: array
            items: { $ref: '#/components/schemas/TaskStatus' }
        - name: priority
          in: query
          style: form
          explode: true
          schema:
            type: array
            items: { $ref: '#/components/schemas/TaskPriority' }
        - name: assigneeId
          in: query
          schema: { type: string, format: uuid }
        - name: dueBefore
          in: query
          description: Tasks due on or before this date.
          schema: { type: string, format: date }
        - name: dueAfter
          in: query
          description: Tasks due on or after this date.
          schema: { type: string, format: date }
        - name: q
          in: query
          description: Case-insensitive substring of the title.
          schema: { type: string, minLength: 1, maxLength: 100 }
      responses:
        '200':
          description: One page of tasks.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/TaskPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
    post:
      operationId: createTask
      tags: [Tasks]
      summary: Create a task
      x-access: team-member-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IdempotencyKey' }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/TaskCreate' }
      responses:
        '201':
          description: Created.
          headers:
            Location: { $ref: '#/components/headers/Location' }
            ETag: { $ref: '#/components/headers/ETag' }
            Idempotent-Replayed: { $ref: '#/components/headers/IdempotentReplayed' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
  /v1/tasks/{taskId}:
    parameters:
      - { $ref: '#/components/parameters/TaskId' }
    get:
      operationId: getTask
      tags: [Tasks]
      summary: One task; send If-None-Match to get 304 when unchanged
      x-access: team-member-or-admin
      parameters:
        - name: If-None-Match
          in: header
          schema: { type: string }
      responses:
        '200':
          description: The task.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '304':
          description: The ETag still matches; no body.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
    patch:
      operationId: updateTask
      tags: [Tasks]
      summary: Change fields, status, assignee or due date (JSON Merge Patch)
      description: |
        Send only the fields to change. `null` clears `assigneeId` and `dueDate`.
        Setting `status` to `done` stamps `completedAt`; any other status clears it.
      x-access: team-member-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IfMatch' }
      requestBody:
        required: true
        content:
          application/merge-patch+json:
            schema: { $ref: '#/components/schemas/TaskUpdate' }
          application/json:
            schema: { $ref: '#/components/schemas/TaskUpdate' }
      responses:
        '200':
          description: The updated task with its new ETag.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
        '428': { $ref: '#/components/responses/PreconditionRequired' }
    delete:
      operationId: deleteTask
      tags: [Tasks]
      summary: Delete a task and its comments
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - name: If-Match
          in: header
          description: Optional here; when present it must match the current ETag.
          schema: { type: string }
      responses:
        '204':
          description: Deleted.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
  /v1/tasks/{taskId}/complete:
    parameters:
      - { $ref: '#/components/parameters/TaskId' }
    post:
      operationId: completeTask
      tags: [Tasks]
      summary: Mark a task done (calls the complete_task stored procedure)
      description: Completing a done task returns it unchanged; a cancelled task gives 409.
      x-access: team-member-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IfMatch' }
      responses:
        '200':
          description: The completed task.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
        '428': { $ref: '#/components/responses/PreconditionRequired' }
  /v1/tasks/{taskId}/reassign:
    parameters:
      - { $ref: '#/components/parameters/TaskId' }
    post:
      operationId: reassignTask
      tags: [Tasks]
      summary: Change the assignee (calls the reassign_task stored procedure)
      description: The new assignee must belong to the project's team; `null` unassigns.
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IfMatch' }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ReassignRequest' }
      responses:
        '200':
          description: The reassigned task.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
        '428': { $ref: '#/components/responses/PreconditionRequired' }
  /v1/tasks/{taskId}/comments:
    parameters:
      - { $ref: '#/components/parameters/TaskId' }
    get:
      operationId: listComments
      tags: [Comments]
      summary: Comments of a task, oldest first
      x-access: team-member-or-admin
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
      responses:
        '200':
          description: One page of comments.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/CommentPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
    post:
      operationId: createComment
      tags: [Comments]
      summary: Add a comment
      x-access: team-member-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IdempotencyKey' }
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CommentCreate' }
      responses:
        '201':
          description: Created.
          headers:
            Location: { $ref: '#/components/headers/Location' }
            Idempotent-Replayed: { $ref: '#/components/headers/IdempotentReplayed' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Comment' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '409': { $ref: '#/components/responses/Conflict' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
  /v1/comments/{commentId}:
    parameters:
      - { $ref: '#/components/parameters/CommentId' }
    delete:
      operationId: deleteComment
      tags: [Comments]
      summary: Delete a comment (its author, a team lead or an admin)
      x-access: author-lead-or-admin
      security:
        - oidc: [tasks:write]
      responses:
        '204':
          description: Deleted.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
  /v1/audit-log:
    get:
      operationId: listAuditLog
      tags: [Audit]
      summary: The audit trail, newest first (admin)
      x-access: admin
      security:
        - oidc: [tasks:admin]
      parameters:
        - { $ref: '#/components/parameters/Limit' }
        - { $ref: '#/components/parameters/Cursor' }
        - name: entityType
          in: query
          schema: { $ref: '#/components/schemas/AuditEntityType' }
        - name: entityId
          in: query
          schema: { type: string, format: uuid }
        - name: actorId
          in: query
          schema: { type: string, format: uuid }
        - name: from
          in: query
          description: Entries at or after this instant.
          schema: { type: string, format: date-time }
        - name: to
          in: query
          description: Entries before this instant.
          schema: { type: string, format: date-time }
      responses:
        '200':
          description: One page of audit entries.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/AuditPage' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
components:
  securitySchemes:
    oidc:
      type: openIdConnect
      description: |
        Keycloak realm `tasksteams`. Web and mobile clients use the authorization code flow with PKCE (S256).
        The API only validates the bearer access token: issuer, audience `tasks-api`, expiry and signature.
        Scopes limit what the client may do; the realm role (`admin`, `member`) limits what the user may do.
      openIdConnectUrl: http://localhost:8180/realms/tasksteams/.well-known/openid-configuration
  parameters:
    TeamId:
      name: teamId
      in: path
      required: true
      schema: { type: string, format: uuid }
    ProjectId:
      name: projectId
      in: path
      required: true
      schema: { type: string, format: uuid }
    TaskId:
      name: taskId
      in: path
      required: true
      schema: { type: string, format: uuid }
    CommentId:
      name: commentId
      in: path
      required: true
      schema: { type: string, format: uuid }
    UserId:
      name: userId
      in: path
      required: true
      schema: { type: string, format: uuid }
    Limit:
      name: limit
      in: query
      description: Page size.
      schema: { type: integer, minimum: 1, maximum: 100, default: 25 }
    Cursor:
      name: cursor
      in: query
      description: Opaque value copied from `page.nextCursor`. Do not build or parse it.
      schema: { type: string, minLength: 1, maxLength: 512 }
    SortCreated:
      name: sort
      in: query
      schema:
        type: string
        enum: [-createdAt, createdAt]
        default: -createdAt
    IfMatch:
      name: If-Match
      in: header
      required: true
      description: The `ETag` of the version being changed, quotes included, for example `"3"`.
      schema: { type: string, minLength: 3, maxLength: 20 }
    IdempotencyKey:
      name: Idempotency-Key
      in: header
      required: false
      description: |
        A unique value (a UUID is fine) per create. Same key and same body replays the first response;
        same key and a different body gives 422; the same key still running gives 409.
        Keys are scoped to the caller and kept for 24 hours.
      schema: { type: string, minLength: 8, maxLength: 128 }
  headers:
    ETag:
      description: Strong validator, the quoted resource `version`, for example `"3"`.
      schema: { type: string }
    Location:
      description: Absolute URL of the created resource.
      schema: { type: string, format: uri }
    IdempotentReplayed:
      description: "`true` when the response is a replay of an earlier request with the same Idempotency-Key."
      schema: { type: string, enum: ['true'] }
    RateLimitLimit:
      description: Requests allowed per window.
      schema: { type: integer }
    RateLimitRemaining:
      description: Requests left in the current window.
      schema: { type: integer }
    RateLimitReset:
      description: Seconds until the window resets.
      schema: { type: integer }
    RetryAfter:
      description: Seconds to wait before retrying.
      schema: { type: integer }
    WWWAuthenticate:
      description: The Bearer challenge, for example `Bearer realm="tasksteams"`.
      schema: { type: string }
  responses:
    BadRequest:
      description: Malformed JSON, a bad query parameter or a bad cursor.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            badCursor:
              value:
                type: https://code101.example/problems/bad-request
                title: Bad request
                status: 400
                detail: The cursor is not valid.
                instance: /v1/projects/5d1b8d9e-0000-4000-8000-000000000001/tasks
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
    Unauthorized:
      description: Missing, expired or invalid bearer token.
      headers:
        WWW-Authenticate: { $ref: '#/components/headers/WWWAuthenticate' }
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            noToken:
              value:
                type: https://code101.example/problems/unauthorized
                title: Unauthorized
                status: 401
                detail: A bearer access token is required.
                instance: /v1/me
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
    Forbidden:
      description: The token is valid but the role, scope or team membership does not allow this.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            notAdmin:
              value:
                type: https://code101.example/problems/forbidden
                title: Forbidden
                status: 403
                detail: The admin role is required.
                instance: /v1/audit-log
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
    NotFound:
      description: The resource does not exist, or the caller may not know that it exists.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
    Conflict:
      description: Duplicate name or key, a business rule, or an Idempotency-Key still in progress.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
    PreconditionFailed:
      description: The If-Match value is stale. Fetch the resource again and retry.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            stale:
              value:
                type: https://code101.example/problems/precondition-failed
                title: Precondition failed
                status: 412
                detail: The task changed since you read it (current version 4).
                instance: /v1/tasks/7c9e6679-7425-40de-944b-e07fc1f90ae7
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
    PreconditionRequired:
      description: The request must include If-Match.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
    UnprocessableContent:
      description: The JSON is well formed but a field is invalid, or an Idempotency-Key was reused with another body.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/ValidationProblem' }
          examples:
            emptyName:
              value:
                type: https://code101.example/problems/validation-error
                title: Validation failed
                status: 422
                detail: One or more fields are invalid.
                instance: /v1/teams
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
                errors:
                  - pointer: /name
                    detail: must be between 1 and 80 characters
    TooManyRequests:
      description: Rate limit exceeded.
      headers:
        Retry-After: { $ref: '#/components/headers/RetryAfter' }
        RateLimit-Limit: { $ref: '#/components/headers/RateLimitLimit' }
        RateLimit-Remaining: { $ref: '#/components/headers/RateLimitRemaining' }
        RateLimit-Reset: { $ref: '#/components/headers/RateLimitReset' }
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
  schemas:
    Problem:
      type: object
      description: RFC 9457 problem details with two extension members, `traceId` and `code`.
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri-reference
          description: Stable identifier of the problem type.
        title: { type: string }
        status: { type: integer, minimum: 400, maximum: 599 }
        detail: { type: string }
        instance: { type: string, description: The request path. }
        traceId: { type: string, description: Correlates with the server log. }
        code:
          type: string
          description: Optional machine-readable code, for example `last_lead`.
    ValidationProblem:
      allOf:
        - $ref: '#/components/schemas/Problem'
        - type: object
          properties:
            errors:
              type: array
              items:
                type: object
                required: [pointer, detail]
                properties:
                  pointer:
                    type: string
                    description: JSON Pointer (RFC 6901) to the invalid field in the request body.
                  detail: { type: string }
    Health:
      type: object
      required: [status]
      properties:
        status: { type: string, enum: [ok, degraded] }
        version: { type: string, examples: ['1.0.0'] }
        database: { type: string, enum: [up, down] }
    PageInfo:
      type: object
      required: [limit, nextCursor]
      properties:
        limit: { type: integer }
        nextCursor:
          type: [string, 'null']
          description: "`null` on the last page."
    Role:
      type: string
      enum: [admin, member]
    TeamRole:
      type: string
      enum: [lead, member]
    TaskStatus:
      type: string
      enum: [todo, in_progress, blocked, done, cancelled]
    TaskPriority:
      type: string
      enum: [low, medium, high, urgent]
    AuditEntityType:
      type: string
      enum: [team, member, project, task, comment]
    UserSummary:
      type: object
      required: [id, username, displayName]
      properties:
        id: { type: string, format: uuid, description: The Keycloak `sub`. }
        username: { type: string }
        displayName: { type: string }
    UserPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/UserSummary' } }
        page: { $ref: '#/components/schemas/PageInfo' }
    Me:
      type: object
      required: [id, username, email, displayName, roles, scopes, teams]
      properties:
        id: { type: string, format: uuid }
        username: { type: string }
        email: { type: string, format: email }
        displayName: { type: string }
        roles:
          type: array
          items: { $ref: '#/components/schemas/Role' }
        scopes:
          type: array
          items: { type: string }
        teams:
          type: array
          items:
            type: object
            required: [teamId, name, role]
            properties:
              teamId: { type: string, format: uuid }
              name: { type: string }
              role: { $ref: '#/components/schemas/TeamRole' }
    Team:
      type: object
      required: [id, name, description, memberCount, createdBy, version, createdAt, updatedAt]
      properties:
        id: { type: string, format: uuid, readOnly: true }
        name: { type: string, minLength: 1, maxLength: 80 }
        description: { type: string, maxLength: 500 }
        memberCount: { type: integer, readOnly: true }
        createdBy: { type: string, format: uuid, readOnly: true }
        version: { type: integer, minimum: 1, readOnly: true }
        createdAt: { type: string, format: date-time, readOnly: true }
        updatedAt: { type: string, format: date-time, readOnly: true }
    TeamCreate:
      type: object
      required: [name]
      additionalProperties: false
      properties:
        name: { type: string, minLength: 1, maxLength: 80 }
        description: { type: string, maxLength: 500, default: '' }
        leadUserId:
          type: string
          format: uuid
          description: Defaults to the caller.
    TeamUpdate:
      type: object
      additionalProperties: false
      minProperties: 1
      properties:
        name: { type: string, minLength: 1, maxLength: 80 }
        description: { type: string, maxLength: 500 }
    TeamPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/Team' } }
        page: { $ref: '#/components/schemas/PageInfo' }
    Member:
      type: object
      required: [userId, username, displayName, role, joinedAt]
      properties:
        userId: { type: string, format: uuid }
        username: { type: string }
        displayName: { type: string }
        role: { $ref: '#/components/schemas/TeamRole' }
        joinedAt: { type: string, format: date-time }
    MemberPut:
      type: object
      required: [role]
      additionalProperties: false
      properties:
        role: { $ref: '#/components/schemas/TeamRole' }
    MemberPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/Member' } }
        page: { $ref: '#/components/schemas/PageInfo' }
    Project:
      type: object
      required: [id, teamId, key, name, description, archived, version, createdAt, updatedAt]
      properties:
        id: { type: string, format: uuid, readOnly: true }
        teamId: { type: string, format: uuid, readOnly: true }
        key:
          type: string
          pattern: '^[A-Z][A-Z0-9]{1,9}$'
          description: Short uppercase code, unique inside the team.
        name: { type: string, minLength: 1, maxLength: 120 }
        description: { type: string, maxLength: 2000 }
        archived: { type: boolean }
        version: { type: integer, minimum: 1, readOnly: true }
        createdAt: { type: string, format: date-time, readOnly: true }
        updatedAt: { type: string, format: date-time, readOnly: true }
    ProjectCreate:
      type: object
      required: [key, name]
      additionalProperties: false
      properties:
        key: { type: string, pattern: '^[A-Z][A-Z0-9]{1,9}$' }
        name: { type: string, minLength: 1, maxLength: 120 }
        description: { type: string, maxLength: 2000, default: '' }
    ProjectUpdate:
      type: object
      additionalProperties: false
      minProperties: 1
      properties:
        name: { type: string, minLength: 1, maxLength: 120 }
        description: { type: string, maxLength: 2000 }
        archived: { type: boolean }
    ProjectPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/Project' } }
        page: { $ref: '#/components/schemas/PageInfo' }
    Task:
      type: object
      required: [id, projectId, title, description, status, priority, assigneeId, dueDate, completedAt, createdBy, version, createdAt, updatedAt]
      properties:
        id: { type: string, format: uuid, readOnly: true }
        projectId: { type: string, format: uuid, readOnly: true }
        title: { type: string, minLength: 1, maxLength: 200 }
        description: { type: string, maxLength: 10000 }
        status: { $ref: '#/components/schemas/TaskStatus' }
        priority: { $ref: '#/components/schemas/TaskPriority' }
        assigneeId: { type: [string, 'null'], format: uuid }
        dueDate: { type: [string, 'null'], format: date }
        completedAt: { type: [string, 'null'], format: date-time, readOnly: true }
        createdBy: { type: string, format: uuid, readOnly: true }
        version: { type: integer, minimum: 1, readOnly: true }
        createdAt: { type: string, format: date-time, readOnly: true }
        updatedAt: { type: string, format: date-time, readOnly: true }
    TaskCreate:
      type: object
      required: [title]
      additionalProperties: false
      properties:
        title: { type: string, minLength: 1, maxLength: 200 }
        description: { type: string, maxLength: 10000, default: '' }
        priority: { $ref: '#/components/schemas/TaskPriority' }
        assigneeId: { type: [string, 'null'], format: uuid }
        dueDate: { type: [string, 'null'], format: date }
    TaskUpdate:
      type: object
      additionalProperties: false
      minProperties: 1
      properties:
        title: { type: string, minLength: 1, maxLength: 200 }
        description: { type: string, maxLength: 10000 }
        status: { $ref: '#/components/schemas/TaskStatus' }
        priority: { $ref: '#/components/schemas/TaskPriority' }
        assigneeId: { type: [string, 'null'], format: uuid }
        dueDate: { type: [string, 'null'], format: date }
    TaskPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/Task' } }
        page: { $ref: '#/components/schemas/PageInfo' }
    ReassignRequest:
      type: object
      required: [assigneeId]
      additionalProperties: false
      properties:
        assigneeId: { type: [string, 'null'], format: uuid }
    Comment:
      type: object
      required: [id, taskId, author, body, createdAt]
      properties:
        id: { type: string, format: uuid, readOnly: true }
        taskId: { type: string, format: uuid, readOnly: true }
        author: { $ref: '#/components/schemas/UserSummary' }
        body: { type: string, minLength: 1, maxLength: 2000 }
        createdAt: { type: string, format: date-time, readOnly: true }
    CommentCreate:
      type: object
      required: [body]
      additionalProperties: false
      properties:
        body: { type: string, minLength: 1, maxLength: 2000 }
    CommentPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/Comment' } }
        page: { $ref: '#/components/schemas/PageInfo' }
    AuditEntry:
      type: object
      required: [id, occurredAt, actorId, action, entityType, entityId, details]
      properties:
        id: { type: integer, format: int64 }
        occurredAt: { type: string, format: date-time }
        actorId: { type: [string, 'null'], format: uuid }
        action: { type: string, enum: [create, update, delete] }
        entityType: { $ref: '#/components/schemas/AuditEntityType' }
        entityId: { type: string, format: uuid }
        details:
          type: object
          description: The new row (create), the changed columns (update) or the old row (delete).
          additionalProperties: true
    AuditPage:
      type: object
      required: [items, page]
      properties:
        items: { type: array, items: { $ref: '#/components/schemas/AuditEntry' } }
        page: { $ref: '#/components/schemas/PageInfo' }
```

### Step 5. Copy only the CC0 SVG assets

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'assets' | Out-Null
New-Item -ItemType Directory -Force 'assets/icons' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'assets'
mkdir -p 'assets/icons'
```

Copy only the repository CC0 originals and retain their license. No external art is needed. The currentColor strokes are recolored by flutter_svg?s ColorFilter, so conversion to another drawing format is unnecessary.

**Terminal: app root, PowerShell; `$repo` is Code101 root**
```powershell
Copy-Item "$repo/assets/art/icons/arrows/log-in.svg" "assets/icons/log-in.svg"
Copy-Item "$repo/assets/art/icons/arrows/log-out.svg" "assets/icons/log-out.svg"
Copy-Item "$repo/assets/art/icons/arrows/refresh-cw.svg" "assets/icons/refresh-cw.svg"
Copy-Item "$repo/assets/art/icons/users/team.svg" "assets/icons/team.svg"
Copy-Item "$repo/assets/art/icons/files/folder.svg" "assets/icons/folder.svg"
Copy-Item "$repo/assets/art/icons/ui/list.svg" "assets/icons/list.svg"
Copy-Item "$repo/assets/art/icons/ui/plus.svg" "assets/icons/plus.svg"
Copy-Item "$repo/assets/art/icons/ui/settings.svg" "assets/icons/settings.svg"
Copy-Item "$repo/assets/art/icons/devices/wifi-off.svg" "assets/icons/wifi-off.svg"
Copy-Item "$repo/assets/art/icons/communication/message-square.svg" "assets/icons/message-square.svg"
Copy-Item "$repo/assets/art/LICENSE-ICONS-CC0.txt" assets/LICENSE-ICONS-CC0.txt
```

**Terminal: app root, macOS/Linux; `$repo` is Code101 root**
```bash
cp "$repo/assets/art/icons/arrows/log-in.svg" "assets/icons/log-in.svg"
cp "$repo/assets/art/icons/arrows/log-out.svg" "assets/icons/log-out.svg"
cp "$repo/assets/art/icons/arrows/refresh-cw.svg" "assets/icons/refresh-cw.svg"
cp "$repo/assets/art/icons/users/team.svg" "assets/icons/team.svg"
cp "$repo/assets/art/icons/files/folder.svg" "assets/icons/folder.svg"
cp "$repo/assets/art/icons/ui/list.svg" "assets/icons/list.svg"
cp "$repo/assets/art/icons/ui/plus.svg" "assets/icons/plus.svg"
cp "$repo/assets/art/icons/ui/settings.svg" "assets/icons/settings.svg"
cp "$repo/assets/art/icons/devices/wifi-off.svg" "assets/icons/wifi-off.svg"
cp "$repo/assets/art/icons/communication/message-square.svg" "assets/icons/message-square.svg"
cp "$repo/assets/art/LICENSE-ICONS-CC0.txt" assets/LICENSE-ICONS-CC0.txt
```

#### `assets/icons/folder.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/folder.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Folder">
  <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
</svg>
```

#### `assets/icons/list.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/list.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="List">
  <line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>
</svg>
```

#### `assets/icons/log-in.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/log-in.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Log In">
  <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/>
</svg>
```

#### `assets/icons/log-out.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/log-out.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Log Out">
  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
</svg>
```

#### `assets/icons/message-square.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/message-square.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Message Square">
  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
</svg>
```

#### `assets/icons/plus.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/plus.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Plus">
  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
</svg>
```

#### `assets/icons/refresh-cw.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/refresh-cw.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Refresh Cw">
  <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
</svg>
```

#### `assets/icons/settings.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/settings.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Settings">
  <circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
</svg>
```

#### `assets/icons/team.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/team.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Team">
  <circle cx="12" cy="7" r="3"/><circle cx="5" cy="11" r="2.5"/><circle cx="19" cy="11" r="2.5"/><path d="M8 21v-2a4 4 0 0 1 8 0v2"/><path d="M1 21v-1a3 3 0 0 1 4-2.8"/><path d="M23 21v-1a3 3 0 0 0-4-2.8"/>
</svg>
```

#### `assets/icons/wifi-off.svg`
This is the unchanged CC0 SVG from the repository art path listed in front matter. Keep viewBox/stroke geometry intact and supply presentation color and a semantic label at the widget boundary.

Create or replace this file, then save it:

**File: `assets/icons/wifi-off.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Wifi Off">
  <line x1="1" y1="1" x2="23" y2="23"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/>
</svg>
```

#### `assets/LICENSE-ICONS-CC0.txt`
Retain the public-domain icon license in the pack. No third-party icon font, Flutter PNG, proprietary Art animation or loader is shipped.

Create or replace this file, then save it:

**File: `assets/LICENSE-ICONS-CC0.txt`**
```text
Creative Commons Legal Code

CC0 1.0 Universal

The person who associated a work with this deed has dedicated the work to the
public domain by waiving all of his or her rights to the work worldwide under
copyright law, including all related and neighboring rights, to the extent
allowed by law.

You can copy, modify, distribute and perform the work, even for commercial
purposes, all without asking permission.

For the full legal text, see: https://creativecommons.org/publicdomain/zero/1.0/legalcode
```

### Step 6. Introduce the resource bundle

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/l10n' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/l10n'
```

#### `lib/l10n/app_en.arb`
This resource bundle owns authored presentation labels and problem messages. Server content, ids and stable backend product names remain data.

Create or replace this file, then save it:

**File: `lib/l10n/app_en.arb`**
```json
{
  "@@locale": "en",
  "appTitle": "Tasks and Teams",
  "sessionCheck": "Session check",
  "login": "Login",
  "signIn": "Sign in",
  "signOut": "Sign out",
  "teams": "Teams",
  "settings": "Settings",
  "authError": "Sign-in or sign-out could not finish. Check your connection and try again.",
  "configurationError": "Configuration error: use HTTPS, or a debug-only loopback host.",
  "continueChapter": "Continue with chapter 03 to load server data.",
  "busy": "Please wait",
  "back": "Back"
}
```

#### `lib/l10n/strings.dart`
Load the bundled English ARB before building widgets. Views use stable keys; adding translations requires extending the supported locale/loading strategy.

Create or replace this file, then save it:

**File: `lib/l10n/strings.dart`**
```dart
import 'dart:convert';
import 'package:flutter/services.dart';

abstract final class Strings {
  static Map<String, dynamic> _values = {};
  static Future<void> load() async {
    _values = jsonDecode(await rootBundle.loadString('lib/l10n/app_en.arb')) as Map<String, dynamic>;
  }
  static String text(String key) => _values[key] as String? ?? key;
}
```

### Step 7. Define policy and immutable domain state

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/core' | Out-Null
New-Item -ItemType Directory -Force 'lib/data/models' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/core'
mkdir -p 'lib/data/models'
```

#### `lib/core/config.dart`
String.fromEnvironment reads compile-time defines, not device environment variables. The six approved scopes are declared once. Defines are public compiled configuration.

Create or replace this file, then save it:

**File: `lib/core/config.dart`**
```dart
abstract final class Config {
  static const apiBase = String.fromEnvironment('API_BASE_URL');
  static const issuer = String.fromEnvironment('OIDC_ISSUER');
  static const clientId = String.fromEnvironment('OIDC_CLIENT_ID');
  static const redirect = String.fromEnvironment('OIDC_REDIRECT_URI');
  static const logout = String.fromEnvironment('OIDC_LOGOUT_URI');
  static const scopes = [
    'openid', 'profile', 'email', 'offline_access', 'tasks:read', 'tasks:write',
  ];
}
```

#### `lib/core/url_policy.dart`
Reject credentials, query/fragment-bearing bases, missing hosts and non-HTTPS URLs except exact debug-loopback hosts. The explicit debug argument also permits a plain Dart CLI demonstration.

Create or replace this file, then save it:

**File: `lib/core/url_policy.dart`**
```dart
abstract final class UrlPolicy {
  static Uri validate(String value, {required bool debug}) {
    final uri = Uri.parse(value);
    const hosts = {'10.0.2.2', 'localhost', '127.0.0.1'};
    if (uri.userInfo.isNotEmpty || uri.hasFragment || uri.hasQuery ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(debug && uri.scheme == 'http' && hosts.contains(uri.host)))) {
      throw const FormatException('Use HTTPS, or a debug-only loopback host.');
    }
    return uri;
  }
}
```

#### `lib/data/models/session.dart`
Only the secure store serializes this object. The id-token subject partitions local data; it is not local proof of backend authorization. Never interpolate credentials into logs.

Create or replace this file, then save it:

**File: `lib/data/models/session.dart`**
```dart
import 'dart:convert';

final class Session {
  const Session(this.access, this.refresh, this.idToken, this.expires);
  final String access;
  final String refresh;
  final String idToken;
  final DateTime expires;
  String get subject {
    final payload = idToken.split('.')[1];
    final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))) as Map;
    return claims['sub'] as String;
  }
  Map<String, Object?> toJson() => {
    'access': access, 'refresh': refresh, 'id': idToken,
    'expires': expires.toUtc().toIso8601String(),
  };
  factory Session.fromJson(Map<String, dynamic> json) => Session(
    json['access'] as String, json['refresh'] as String,
    json['id'] as String, DateTime.parse(json['expires'] as String),
  );
}
```

### Step 8. Implement services, cache and repositories

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/data/repositories' | Out-Null
New-Item -ItemType Directory -Force 'lib/data/services' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/data/repositories'
mkdir -p 'lib/data/services'
```

#### `lib/data/repositories/auth_repository.dart`
Own restoration and one in-flight refresh Future. Re-read secure storage within the cross-isolate lock and persist rotation before use. Preserve cache/queue on rejection and cached access on temporary issuer failure.

Create or replace this file, then save it:

**File: `lib/data/repositories/auth_repository.dart`**
```dart
import 'dart:async';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

final class AuthExpired implements Exception {
  const AuthExpired();
}

final class AuthRepository {
  AuthRepository(this._service, this._store);
  final AuthService _service;
  final TokenStore _store;
  final _changes = StreamController<bool?>.broadcast();
  Stream<bool?> get changes => _changes.stream;
  bool? signedIn;
  String intendedRoute = '/teams';
  Future<Session>? _refreshing;
  void _notify(bool value) {
    signedIn = value;
    _changes.add(value);
  }
  Future<void> restore() async => _notify(await _store.read() != null);
  Future<void> signIn() async {
    final value = await _service.signIn();
    if (value == null) return;
    await _store.exclusive(() => _store.write(value));
    _notify(true);
  }
  Future<Session> _refresh({String? rejected}) async {
    try {
      return await _store.exclusive(() async {
        final old = await _store.read();
        if (old == null) throw const AuthExpired();
        if (rejected != null && old.access != rejected) return old;
        if (rejected == null && old.expires.isAfter(DateTime.now().add(const Duration(seconds: 60)))) return old;
        final next = await _service.refresh(old);
        await _store.write(next); // Persist rotation before exposing the new token.
        return next;
      });
    } on AuthUnavailable {
      rethrow; // An unreachable issuer is not a revoked session. Keep cached screens open.
    } catch (_) {
      _notify(false); // A rejected refresh keeps the cache and queue.
      throw const AuthExpired();
    }
  }
  Future<String> accessToken({String? rejected}) async {
    final pending = _refreshing;
    if (pending != null) return (await pending).access;
    final job = _refresh(rejected: rejected);
    _refreshing = job;
    try {
      return (await job).access;
    } finally {
      _refreshing = null;
    }
  }
  Future<void> signOut() async {
    await _store.exclusive(() async {
      final session = await _store.read();
      if (session != null) await _service.signOut(session);
      await _store.clear(); // Browser logout must succeed before claiming logout.
    });
    intendedRoute = '/teams';
    _notify(false);
  }
  Future<void> dispose() => _changes.close();
}
```

#### `lib/data/services/auth_service.dart`
AppAuth handles browser authorization and native PKCE. The app supplies public configuration and approved scopes. Cancellation is normal; raw SDK protocol errors are not presentation messages.

Create or replace this file, then save it:

**File: `lib/data/services/auth_service.dart`**
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../../core/config.dart';
import '../../core/url_policy.dart';
import '../models/session.dart';

final class AuthService {
  final _appAuth = const FlutterAppAuth();
  AuthService() {
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
  }
  Session _session(TokenResponse result, [Session? old]) {
    final access = result.accessToken;
    final refresh = result.refreshToken ?? old?.refresh;
    final id = result.idToken ?? old?.idToken;
    final expires = result.accessTokenExpirationDateTime;
    if (access == null || refresh == null || id == null || expires == null) {
      throw StateError('incomplete_session');
    }
    return Session(access, refresh, id, expires);
  }
  Future<Session?> signIn() async {
    try {
      return _session(await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(Config.clientId, Config.redirect,
          issuer: Config.issuer, scopes: Config.scopes,
          allowInsecureConnections: kDebugMode),
      ));
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }
  Future<Session> refresh(Session old) async {
    try {
      return _session(await _appAuth.token(TokenRequest(Config.clientId, Config.redirect,
        issuer: Config.issuer, refreshToken: old.refresh,
        scopes: Config.scopes, allowInsecureConnections: kDebugMode)), old);
    } on FlutterAppAuthPlatformException catch (error) {
      if (const ['invalid_grant','invalid_client','unauthorized_client','invalid_scope']
          .contains(error.platformErrorDetails.error)) { rethrow; }
      throw const AuthUnavailable();
    }
  }
  Future<void> signOut(Session old) async {
    await _appAuth.endSession(EndSessionRequest(
      issuer: Config.issuer, idTokenHint: old.idToken,
      postLogoutRedirectUrl: Config.logout,
      allowInsecureConnections: kDebugMode,
    ));
  }
}

final class AuthUnavailable implements Exception { const AuthUnavailable(); }
```

#### `lib/data/services/token_store.dart`
Only this class imports secure storage. Store one encrypted JSON blob so rotated credentials are not updated separately. The support-directory file lock contains no credentials and also coordinates background refresh.

Create or replace this file, then save it:

**File: `lib/data/services/token_store.dart`**
```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session.dart';

final class TokenStore {
  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions());
  static const _key = 'session.v1';
  Future<Session?> read() async {
    final value = await _storage.read(key: _key);
    return value == null ? null : Session.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
  Future<void> write(Session session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));
  Future<void> clear() => _storage.delete(key: _key);

  // A file lock also serializes refresh across the WorkManager isolate.
  // The file contains no tokens. Read secure storage again inside the lock.
  Future<T> exclusive<T>(Future<T> Function() action) async {
    final folder = await getApplicationSupportDirectory();
    await folder.create(recursive: true);
    final file = await File('${folder.path}/auth.lock').open(mode: FileMode.append);
    try {
      await file.lock(FileLock.blockingExclusive);
      return await action();
    } finally {
      await file.unlock();
      await file.close();
    }
  }
}
```

### Step 9. Expose commands through per-feature ViewModels

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/features/login/view_model' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/features/login/view_model'
```

#### `lib/features/login/view_model/login_view_model.dart`
Expose asynchronous auth commands and block duplicate taps while loading. Widgets receive a safe error state, not SDK/token text.

Create or replace this file, then save it:

**File: `lib/features/login/view_model/login_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

final loginViewModelProvider = AsyncNotifierProvider<LoginViewModel, void>(LoginViewModel.new);
class LoginViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}
  Future<void> signIn() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authProvider).signIn());
  }
  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authProvider).signOut());
  }
}
```

### Step 10. Build the named feature views

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/features/login/view' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/features/login/view'
```

#### `lib/features/login/view/login_screen.dart`
S2 presents progress, a safe error and one sign-in action. It has no password field and no direct HTTP or secure-storage access.

Create or replace this file, then save it:

**File: `lib/features/login/view/login_screen.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/strings.dart';
import '../view_model/login_view_model.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    return Scaffold(appBar: AppBar(title: Text(Strings.text('login'))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        if (state.isLoading) const LinearProgressIndicator(),
        if (state.hasError) Text(Strings.text('authError')),
        FilledButton(onPressed: state.isLoading ? null :
          ref.read(loginViewModelProvider.notifier).signIn,
          child: Text(Strings.text('signIn'))),
      ])),
    );
  }
}
```

### Step 11. Wire dependencies, routes and the Material app

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/app' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/app'
```

#### `lib/app/app.dart`
Watch one router, install Material localization delegates and use padded tap targets with a seeded color scheme. Defaults do not replace TalkBack, contrast and large-font acceptance.

Create or replace this file, then save it:

**File: `lib/app/app.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/strings.dart';
import 'router.dart';

class TasksApp extends ConsumerWidget {
  const TasksApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: Strings.text('appTitle'), routerConfig: ref.watch(routerProvider),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en')],
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff17467c)),
      materialTapTargetSize: MaterialTapTargetSize.padded),
  );
}
```

#### `lib/app/providers.dart`
Riverpod wires services, one store, repositories and write gateway in dependency order. Do not add a competing service locator. The durable phase also guards cache ownership across signed-in subjects.

Create or replace this file, then save it:

**File: `lib/app/providers.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/token_store.dart';

final authProvider = Provider<AuthRepository>((ref) {
  final auth = AuthRepository(AuthService(), TokenStore());
  ref.onDispose(auth.dispose);
  return auth;
});
```

#### `lib/app/router.dart`
Guard signed-out access, preserve an intended in-app route and declare S1?S10 navigation; S8 stays modal. The ChangeNotifier is only a GoRouter notification adapter. Android task links use the distinct code101-tasks-flutter scheme; AppAuth alone retains the registered OAuth scheme. Device delivery is not yet run.

Create or replace this file, then save it:

**File: `lib/app/router.dart`**
```dart
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/login/view/login_screen.dart';
import '../features/login/view_model/login_view_model.dart';
import '../l10n/strings.dart';
import 'providers.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Stream<bool?> stream) { _subscription = stream.listen((_) => notifyListeners()); }
  late final StreamSubscription<bool?> _subscription;
  @override
  void dispose() { _subscription.cancel(); super.dispose(); }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authProvider);
  final refresh = _RouterRefresh(auth.changes);
  final router = GoRouter(initialLocation: '/', refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (auth.signedIn == null) {
        if (path != '/' && path != '/login') auth.intendedRoute = '${state.uri.path}${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
        return path == '/' ? null : '/';
      }
      if (!auth.signedIn! && path != '/login') {
        if (path != '/') auth.intendedRoute = '${state.uri.path}${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
        return '/login';
      }
      if (auth.signedIn! && (path == '/' || path == '/login')) return auth.intendedRoute;
      return null;
    }, routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: Center(child: Text(Strings.text('sessionCheck'))))),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/teams', builder: (_, _) => const _SignedInScreen()),
    ]);
  ref.onDispose(() { router.dispose(); refresh.dispose(); });
  unawaited(auth.restore());
  return router;
});

class _SignedInScreen extends ConsumerWidget {
  const _SignedInScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    return Scaffold(appBar: AppBar(title: Text(Strings.text('teams'))), body: ListView(children: [
      Text(Strings.text('continueChapter')),
      if (state.hasError) Text(Strings.text('authError')),
      FilledButton(onPressed: state.isLoading ? null : ref.read(loginViewModelProvider.notifier).signOut,
        child: Text(Strings.text('signOut'))),
    ]));
  }
}
```

### Step 12. Initialize and launch the app

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib'
```

#### `lib/main.dart`
Initialize Flutter and the English ARB before using plugins/widgets. Reject unsafe config before launching; phases 4/5 also register deferred sync. Do not log tokens or response bodies.

Create or replace this file, then save it:

**File: `lib/main.dart`**
```dart
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config.dart';
import 'core/url_policy.dart';
import 'l10n/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Strings.load();
  try {
    UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
    runApp(const ProviderScope(child: TasksApp()));
  } on FormatException {
    runApp(MaterialApp(home: Scaffold(body: SafeArea(
      child: Center(child: Text(Strings.text('configurationError'))),
    ))));
  }
}
```

### Step 13. Add emulator-free diagnostic tools

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'tool' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'tool'
```

#### `tool/check_artifacts.py`
Call SDK aapt2 on an actual built APK, then inspect an AAB only when requested. This helper starts no adb, emulator, Docker or server; manifest checks are not device security approval.

Create or replace this file, then save it:

**File: `tool/check_artifacts.py`**
```python
"""Inspect the actual APK (and release bundle in chapter 05), without adb."""
from pathlib import Path
import os
import subprocess
import sys
import zipfile

sdk = Path(os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT") or Path.home() / "AppData/Local/Android/sdk")
aapt = sdk / "build-tools/36.0.0" / ("aapt2.exe" if os.name == "nt" else "aapt2")
apk = Path("build/app/outputs/flutter-apk/app-debug.apk")
if not apk.is_file() or apk.stat().st_size == 0:
    raise SystemExit("Debug APK missing")
result = subprocess.run([str(aapt), "dump", "xmltree", "--file", "AndroidManifest.xml", str(apk)],capture_output=True,text=True,check=True)
for required in ("com.code101.tasks.flutter", "com.code101.tasks", "networkSecurityConfig"):
    if required not in result.stdout:
        raise SystemExit("Manifest missing " + required)
print("Debug APK: application id, redirect scheme and networkSecurityConfig present")
if "--release" in sys.argv:
    bundle = Path("build/app/outputs/bundle/release/app-release.aab")
    with zipfile.ZipFile(bundle) as archive:
        manifest = archive.read("base/manifest/AndroidManifest.xml")
    if b"networkSecurityConfig" in manifest:
        raise SystemExit("Release bundle contains debug network policy")
    print("Release AAB: present; debug networkSecurityConfig absent")
```

#### `tool/url_probe.dart`
Exercise the real URL policy from a plain Dart CLI and a public define file; output only a host name, never credentials.

Create or replace this file, then save it:

**File: `tool/url_probe.dart`**
```dart
import 'dart:convert';
import 'dart:io';
import 'package:tasks_flutter/core/url_policy.dart';

void main(List<String> args) {
  final release = args.contains('--release');
  final paths = args.where((value) => value != '--release').toList();
  final file = paths.isEmpty ? 'config/dev.json' : paths.single;
  final config = jsonDecode(File(file).readAsStringSync()) as Map;
  final uri = UrlPolicy.validate(config['API_BASE_URL'] as String,debug:!release);
  stdout.writeln('URL allowed: ${uri.host}');
}
```

### Step 14. Regenerate instead of editing generated output
Supplied generated text is deliberately listed in `skip_lesson_check`: pubspec.lock, every file under lib/data/generated and, from phase 4, lib/data/local/database.g.dart. Every authored text file was displayed above. The Gradle wrapper JAR is supplied binary scaffold tooling, not authored source.

**Terminal: app root, every OS; for a later authorized run**
```text
flutter pub get
dart run swagger_parser
dart run build_runner build
```

Expected output (final chapter not yet run; stable excerpts from earlier author runs):
```text
Got dependencies!
Generated 58 files
Built with build_runner
```

The generation line continues with your absolute output folder. build_runner timing/input/output counts vary with caching. Keep the supplied lockfile and direct pins; do not substitute pub upgrade. Recreating a lockfile from nothing at a later date can resolve different transitive versions. build_runner 2.17.1 reports the old --delete-conflicting-outputs option as removed; use the command shown.

## Run it
This is a **future** smoke procedure, not a claim that the final files were run. After generation above, use the app root:

**Terminal: app root, every OS**
```text
flutter analyze --no-pub
flutter build apk --debug --no-pub --dart-define-from-file=config/dev.json
python tool/check_artifacts.py
dart run tool/url_probe.dart
```

Expected output (not yet run for the final chapter; omit variable progress/timing):
```text
No issues found!
Built build\app\outputs\flutter-apk\app-debug.apk
Debug APK: application id, redirect scheme and networkSecurityConfig present
URL allowed: 10.0.2.2
```

macOS/Linux use `/` in the built path. Flutter may prepend a success glyph. The scripts above are the source of the manifest/probe messages. Set ANDROID_HOME (or ANDROID_SDK_ROOT) for a nondefault SDK location, especially macOS/Linux.
The future clean-room verifier has a 1200-second first-build timeout for Gradle/SDK downloads. No unit test, server, Docker, adb or emulator is part of this spec.

**File: `../verify.json` (beside code and exercise)**
```json
{
  "requires": [
    "flutter",
    "dart",
    "python"
  ],
  "steps": [
    {
      "name": "restore locked dependencies",
      "cwd": "code",
      "cmd": "flutter pub get",
      "timeout": 600,
      "expect_contains": [
        "Got dependencies!"
      ]
    },
    {
      "name": "generate typed client",
      "cwd": "code",
      "cmd": "dart run swagger_parser",
      "timeout": 300,
      "expect_contains": [
        "Generated 58 files"
      ]
    },
    {
      "name": "generate serializers and database",
      "cwd": "code",
      "cmd": "dart run build_runner build",
      "timeout": 600,
      "expect_contains": [
        "Built with build_runner"
      ]
    },
    {
      "name": "analyze once",
      "cwd": "code",
      "cmd": "flutter analyze --no-pub",
      "timeout": 300,
      "expect_contains": [
        "No issues found!"
      ]
    },
    {
      "name": "build debug APK once",
      "cwd": "code",
      "cmd": "flutter build apk --debug --no-pub --dart-define-from-file=config/dev.json",
      "timeout": 1200,
      "expect_contains": [
        "app-debug.apk"
      ]
    },
    {
      "name": "inspect actual manifests",
      "cwd": "code",
      "cmd": "{python} tool/check_artifacts.py",
      "expect_contains": [
        "Debug APK: application id, redirect scheme and networkSecurityConfig present"
      ]
    },
    {
      "name": "run URL policy once",
      "cwd": "code",
      "cmd": "dart run tool/url_probe.dart",
      "timeout": 120,
      "expect_contains": [
        "URL allowed: 10.0.2.2"
      ]
    },
    {
      "name": "run exercise solution once",
      "cwd": "exercise/solution",
      "cmd": "dart run main.dart",
      "timeout": 120,
      "expect_stdout": "Refresh before request"
    }
  ],
  "cleanup": [],
  "skip_lesson_check": [
    "code/lib/data/generated/.swagger_parser.lock",
    "code/lib/data/generated/audit/audit_client.dart",
    "code/lib/data/generated/audit/models/audit_entity_type.dart",
    "code/lib/data/generated/audit/models/audit_entity_type.g.dart",
    "code/lib/data/generated/audit/models/audit_entry.dart",
    "code/lib/data/generated/audit/models/audit_entry.g.dart",
    "code/lib/data/generated/audit/models/audit_entry_action.dart",
    "code/lib/data/generated/audit/models/audit_entry_action.g.dart",
    "code/lib/data/generated/audit/models/audit_page.dart",
    "code/lib/data/generated/audit/models/audit_page.g.dart",
    "code/lib/data/generated/comments/comments_client.dart",
    "code/lib/data/generated/comments/models/comment_create.dart",
    "code/lib/data/generated/comments/models/comment_create.g.dart",
    "code/lib/data/generated/comments/models/comment_page_request.dart",
    "code/lib/data/generated/comments/models/comment_page_request.g.dart",
    "code/lib/data/generated/comments/models/comment_page_response.dart",
    "code/lib/data/generated/comments/models/comment_page_response.g.dart",
    "code/lib/data/generated/comments/models/comment_request.dart",
    "code/lib/data/generated/comments/models/comment_request.g.dart",
    "code/lib/data/generated/comments/models/comment_response.dart",
    "code/lib/data/generated/comments/models/comment_response.g.dart",
    "code/lib/data/generated/exports.dart",
    "code/lib/data/generated/members/members_client.dart",
    "code/lib/data/generated/members/models/member.dart",
    "code/lib/data/generated/members/models/member.g.dart",
    "code/lib/data/generated/members/models/member_page.dart",
    "code/lib/data/generated/members/models/member_page.g.dart",
    "code/lib/data/generated/members/models/member_put.dart",
    "code/lib/data/generated/members/models/member_put.g.dart",
    "code/lib/data/generated/models/create_team_response201_idempotent_replayed.dart",
    "code/lib/data/generated/models/create_team_response201_idempotent_replayed.g.dart",
    "code/lib/data/generated/platform/models/health.dart",
    "code/lib/data/generated/platform/models/health.g.dart",
    "code/lib/data/generated/platform/models/health_database.dart",
    "code/lib/data/generated/platform/models/health_database.g.dart",
    "code/lib/data/generated/platform/models/health_status.dart",
    "code/lib/data/generated/platform/models/health_status.g.dart",
    "code/lib/data/generated/platform/models/me.dart",
    "code/lib/data/generated/platform/models/me.g.dart",
    "code/lib/data/generated/platform/models/me_teams_item.dart",
    "code/lib/data/generated/platform/models/me_teams_item.g.dart",
    "code/lib/data/generated/platform/models/page_info.dart",
    "code/lib/data/generated/platform/models/page_info.g.dart",
    "code/lib/data/generated/platform/models/problem.dart",
    "code/lib/data/generated/platform/models/problem.g.dart",
    "code/lib/data/generated/platform/models/role.dart",
    "code/lib/data/generated/platform/models/role.g.dart",
    "code/lib/data/generated/platform/models/team_role.dart",
    "code/lib/data/generated/platform/models/team_role.g.dart",
    "code/lib/data/generated/platform/models/user_page.dart",
    "code/lib/data/generated/platform/models/user_page.g.dart",
    "code/lib/data/generated/platform/models/user_summary.dart",
    "code/lib/data/generated/platform/models/user_summary.g.dart",
    "code/lib/data/generated/platform/platform_client.dart",
    "code/lib/data/generated/projects/models/project_create.dart",
    "code/lib/data/generated/projects/models/project_create.g.dart",
    "code/lib/data/generated/projects/models/project_page_request.dart",
    "code/lib/data/generated/projects/models/project_page_request.g.dart",
    "code/lib/data/generated/projects/models/project_page_response.dart",
    "code/lib/data/generated/projects/models/project_page_response.g.dart",
    "code/lib/data/generated/projects/models/project_request.dart",
    "code/lib/data/generated/projects/models/project_request.g.dart",
    "code/lib/data/generated/projects/models/project_response.dart",
    "code/lib/data/generated/projects/models/project_response.g.dart",
    "code/lib/data/generated/projects/models/project_update.dart",
    "code/lib/data/generated/projects/models/project_update.g.dart",
    "code/lib/data/generated/projects/projects_client.dart",
    "code/lib/data/generated/tasks/models/list_tasks_sort.dart",
    "code/lib/data/generated/tasks/models/list_tasks_sort.g.dart",
    "code/lib/data/generated/tasks/models/reassign_request.dart",
    "code/lib/data/generated/tasks/models/reassign_request.g.dart",
    "code/lib/data/generated/tasks/models/task_create.dart",
    "code/lib/data/generated/tasks/models/task_create.g.dart",
    "code/lib/data/generated/tasks/models/task_page_request.dart",
    "code/lib/data/generated/tasks/models/task_page_request.g.dart",
    "code/lib/data/generated/tasks/models/task_page_response.dart",
    "code/lib/data/generated/tasks/models/task_page_response.g.dart",
    "code/lib/data/generated/tasks/models/task_priority.dart",
    "code/lib/data/generated/tasks/models/task_priority.g.dart",
    "code/lib/data/generated/tasks/models/task_request.dart",
    "code/lib/data/generated/tasks/models/task_request.g.dart",
    "code/lib/data/generated/tasks/models/task_response.dart",
    "code/lib/data/generated/tasks/models/task_response.g.dart",
    "code/lib/data/generated/tasks/models/task_status.dart",
    "code/lib/data/generated/tasks/models/task_status.g.dart",
    "code/lib/data/generated/tasks/models/task_update.dart",
    "code/lib/data/generated/tasks/models/task_update.g.dart",
    "code/lib/data/generated/tasks/tasks_client.dart",
    "code/lib/data/generated/tasks_api.dart",
    "code/lib/data/generated/teams/models/list_teams_sort.dart",
    "code/lib/data/generated/teams/models/list_teams_sort.g.dart",
    "code/lib/data/generated/teams/models/team_create.dart",
    "code/lib/data/generated/teams/models/team_create.g.dart",
    "code/lib/data/generated/teams/models/team_page_request.dart",
    "code/lib/data/generated/teams/models/team_page_request.g.dart",
    "code/lib/data/generated/teams/models/team_page_response.dart",
    "code/lib/data/generated/teams/models/team_page_response.g.dart",
    "code/lib/data/generated/teams/models/team_request.dart",
    "code/lib/data/generated/teams/models/team_request.g.dart",
    "code/lib/data/generated/teams/models/team_response.dart",
    "code/lib/data/generated/teams/models/team_response.g.dart",
    "code/lib/data/generated/teams/models/team_update.dart",
    "code/lib/data/generated/teams/models/team_update.g.dart",
    "code/lib/data/generated/teams/models/validation_problem.dart",
    "code/lib/data/generated/teams/models/validation_problem.g.dart",
    "code/lib/data/generated/teams/models/validation_problem_errors_item.dart",
    "code/lib/data/generated/teams/models/validation_problem_errors_item.g.dart",
    "code/lib/data/generated/teams/teams_client.dart",
    "code/pubspec.lock"
  ]
}
```

### Device acceptance is separate
Browser sign-in, secure storage, UI behavior and accessibility have not been run. Chapter 05 includes the complete [manual checklist](../../MANUAL-CHECKLIST.md), with the locked disposable backend session, emulator/USB URLs and cleanup. Do not start a stack merely to make a build look more verified.

### Captured text-only comparison (not executable verification)
After these lessons existed, the author ran only `python scripts/verify_labs.py --static capstones/mobile-flutter`. This permitted mode compares files with lesson text and does not execute any verify.json command. Its actual output was:

```text
[STATIC    ] capstones/mobile-flutter/source/phase-1-setup/01-setup
[STATIC    ] capstones/mobile-flutter/source/phase-2-auth/02-auth
[STATIC    ] capstones/mobile-flutter/source/phase-3-screens/03-screens
[STATIC    ] capstones/mobile-flutter/source/phase-4-offline/04-offline
[STATIC    ] capstones/mobile-flutter/source/phase-5-ship/05-build-run-ship

0 passed, 5 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

This is **0 runtime passes**, not five verified apps. Front matter remains `verified: not yet run` and state remains `written (not run)`.

## How it works
The final manifest adds a separate task-link filter for `code101-tasks-flutter://app/teams` and `code101-tasks-flutter://app/tasks/<id>` (task routes from chapter 03). OAuth still uses only `com.code101.tasks:/oauth2redirect` in AppAuth?s receiver. The router retains only path/query for the intended in-app route. This integration is written, not device-verified.

App startup loads ARB strings and creates the provider scope. The router waits while secure storage is restored. Login delegates through its ViewModel to AuthRepository/AuthService; AppAuth owns the browser handoff, state, nonce and PKCE verifier. One shared refresh Future protects an isolate, and a token-free file lock protects rotation across isolates. Re-read storage inside that lock and persist the replacement refresh token before exposing access. A transient issuer outage does not prove revocation; an OAuth rejection goes to Login without deleting local work.

New terms are defined in [GLOSSARY.md](../../GLOSSARY.md). Why Riverpod rather than another DI library too? One approach already supplies both state and injection. Why repositories rather than HTTP in widgets? Replacing the source of truth should not require rewriting every screen.

## Try it
Decide whether to refresh when an access token expires within 60 seconds. Use the fixed 45-second value; do not print or invent tokens.

Copy exercise/starter to a separate work folder before editing; do not overwrite lib/main.dart. For example, from the extracted `02-auth` folder:

**Terminal: extracted lesson folder, PowerShell**
```powershell
Copy-Item exercise/starter exercise/my-attempt -Recurse
Set-Location exercise/my-attempt
```

**Terminal: extracted lesson folder, macOS/Linux**
```bash
cp -r exercise/starter exercise/my-attempt
cd exercise/my-attempt
```

The complete starter is:

**File: `exercise/starter/main.dart`**
```dart
void main() {
  const secondsUntilExpiry = 45;
  // TODO: refresh when expiry is at most 60 seconds away.
  print(secondsUntilExpiry);
}
```

Edit, save, then later run `dart run main.dart` from your copied exercise folder. It uses only Dart?s standard library, not a Flutter engine or a test runner.

<details><summary>Solution</summary>

**File: `exercise/solution/main.dart`**
```dart
void main() {
  const secondsUntilExpiry = 45;
  print(secondsUntilExpiry <= 60 ? 'Refresh before request' : 'Use current access token');
}
```

This implements the one requested rule, not platform integration. Expected output (final exercise delivery not yet run):

```text
Refresh before request
```

</details>

## Check yourself
1. Where does the password go?
   <details><summary>Answer</summary>Only into the identity provider page in the system browser.</details>

2. Why persist rotation before returning access?
   <details><summary>Answer</summary>Another caller must not reuse the now-invalid refresh token.</details>

3. Does losing a session erase the queue?
   <details><summary>Answer</summary>No. Deletion is a separate explicit choice.</details>

4. Does a build prove browser sign-in?
   <details><summary>Answer</summary>No; browser redirect, secure storage and logout require a device.</details>

## Common mistakes
These excerpts were **actually captured before executable work was stopped**. Reproduction actions are for a later authorized session, not a new verification claim.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Expected to find project root in current working directory.` | The author deliberately ran flutter pub get in the capstone documentation folder. | Change to this phase?s code folder or your app workspace; inspect the prompt. |
| `PathNotFoundException: Cannot open file, path = 'config/missing.json'` | Captured by running `dart run tool/url_probe.dart config/missing.json`. This is a path error, not failed login. | Use the exact shipped configuration path and save it before running. |
| `FormatException: Use HTTPS, or a debug-only loopback host.` | Captured with `dart run tool/url_probe.dart --release` against dev.json. | Release rejects HTTP deliberately; use a real HTTPS release configuration, not a broader exception. |
| `Use package:material_ui/material_ui.dart instead.` | Flutter 3.50 analysis captured a deprecation for the old SDK Material import. | Use the pinned official material_ui package/import, not a lint suppression. |

## Best practice
Keep credentials out of widgets and delegate native behavior behind services/repositories. Source: [Architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations) (Tier 1).

Also keep [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) checks manual: defaults and a passing analyzer do not prove a usable screen. Package behavior is pinned/sourced in VERSION-NOTES.md. No outside art is used.

## Next lesson
03. Screens and state: replace the Teams placeholder with the shared screen workflow.
