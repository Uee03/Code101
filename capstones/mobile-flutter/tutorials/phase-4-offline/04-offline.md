---
track: capstone
level: 201
phase: 4
phase_name: offline
lesson: 04
title: "Offline cache, sync and errors"
time: 120 min
prerequisites: [capstone-mobile-flutter-03]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", android_build_tools: "36.0.0", gradle: "9.5.0", agp: "9.3.1" }
verified: not yet run
source: capstones/mobile-flutter/source/phase-4-offline/04-offline/
assets: [arrows/log-in, arrows/log-out, arrows/refresh-cw, users/team, files/folder, ui/list, ui/plus, ui/settings, devices/wifi-off, communication/message-square]
---

# 04. Offline cache, sync and errors

## Why it matters
A notebook can accept your order while the kitchen is disconnected, but must not lose it when the waiter leaves. SQLite records the visible change and pending write together. Sync must also account for conflicts, duplicate delivery, process death and another isolate refreshing the same credentials.

## What you will build
The full app with drift/SQLite cache, ordered durable outbox, temporary-to-server-id mapping, capped backoff and jitter, problem messages and pointer errors, conflicts, a live offline banner and deferred WorkManager scheduling.

Requirements taught: **M-07, M-16?M-22**. This chapter is **written (not run)**. Executable verification was stopped at the user's request; a static source/text comparison is not runtime verification. Historical error excerpts below were captured before that stop and are not evidence that these final files were run.

## Before you start
- Flutter 3.50.1 / Dart 3.14.0; Android Studio JBR; SDK platform 36, build-tools 36.0.0 and NDK 28.2.13676358. SDK 37.2 alone does not supply these template requirements. Plugins may also request platform 35/CMake. The earlier Flutter Doctor accepted Android licenses; a desktop Chrome warning does not prevent an Android APK build.
- A terminal: the prompt tells you its current folder. All app commands run beside `pubspec.yaml`, not in the capstone documentation folder. PowerShell commands are 5.1-compatible; Flutter/Dart commands are identical on macOS/Linux. Use `python3` if `python` is unavailable there.
- Unzip `mobile-flutter-phase-4-offline.zip` (Windows: right-click ? **Extract All**; macOS: double-click; Linux: `unzip`). Open `04-offline/code` in Android Studio or VS Code. This is a whole phase snapshot, not a patch; do not combine phase folders.
- A dot on an editor tab means unsaved changes. Save each file before comparing or running later.
- Exact package pins and sources are in [VERSION-NOTES.md](../../VERSION-NOTES.md). The platform TDD section 12.1 **Decision** column resolves older contract omissions. Do not edit that contract or another capstone as a client workaround.

## Steps
### Step 1. Prepare one app workspace
Continue in the same workspace from chapter 03, or open `04-offline/code` from this phase?s pack. Whole files below deliberately repeat unchanged snapshot files so the phase is standalone. A later edit to a long file is shown as a **whole replacement**, not a context-free edit; no region is omitted. Preserve your private local.properties and build caches locally, but never distribute them. Phase 4 switches the store provider, not the view/repository interfaces.

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
  "projects": "Projects",
  "tasks": "Task list",
  "taskDetail": "Task detail",
  "taskForm": "Create or edit task",
  "conflict": "Conflict sheet",
  "syncQueue": "Sync queue",
  "search": "Search teams",
  "archived": "Show archived projects",
  "empty": "Nothing here yet.",
  "loadMore": "Load more",
  "newTask": "New task",
  "edit": "Edit",
  "save": "Save",
  "cancel": "Cancel",
  "title": "Title",
  "description": "Description",
  "status": "Status",
  "priority": "Priority",
  "assigneeId": "Assignee id (blank clears it)",
  "dueDate": "Due date YYYY-MM-DD (blank clears it)",
  "complete": "Complete task",
  "comments": "Comments",
  "body": "Comment",
  "addComment": "Add comment",
  "delete": "Delete",
  "waiting": "Waiting to sync",
  "networkError": "Could not reach the server. Your saved data is kept.",
  "validationError": "Check the field limits, date and identifiers.",
  "backend": "Backend",
  "customUrl": "Custom URL",
  "apply": "Apply backend",
  "testConnection": "Test connection",
  "deleteOffline": "Also delete offline data",
  "queueNotEmpty": "Sync or discard pending changes before changing the backend.",
  "account": "Account",
  "retry": "Retry",
  "discard": "Discard",
  "mine": "Mine",
  "theirs": "Theirs",
  "keepMine": "Keep mine",
  "takeTheirs": "Take theirs",
  "queueNextChapter": "Durable sync queue arrives in chapter 04.",
  "id": "Id",
  "projectId": "Project id",
  "createdBy": "Created by",
  "createdAt": "Created at",
  "updatedAt": "Updated at",
  "version": "Version",
  "completedAt": "Completed at",
  "todo": "To do",
  "in_progress": "In progress",
  "blocked": "Blocked",
  "done": "Done",
  "cancelled": "Cancelled",
  "low": "Low",
  "medium": "Medium",
  "high": "High",
  "urgent": "Urgent",
  "sort": "Sort",
  "-createdAt": "Newest first",
  "createdAtSort": "Oldest first",
  "dueDateSort": "Due date",
  "nullValue": "Not set",
  "health": "Database state",
  "roles": "Roles",
  "scopes": "Scopes",
  "name": "Name",
  "syncNow": "Sync now",
  "offline": "Offline",
  "pending": "Pending writes",
  "failed": "Failed",
  "conflictHelp": "Compare each changed field. Choosing theirs drops that field; keep mine retries the remaining fields against the newest version.",
  "problem_bad-request": "Request invalid. Refresh the list and try again.",
  "problem_unauthorized": "Sign in again. Your pending changes are kept.",
  "problem_forbidden": "You do not have permission for this action.",
  "problem_not-found": "This item is missing or not visible to your account.",
  "problem_conflict": "This change conflicts with a server rule.",
  "problem_precondition-failed": "This task changed. Compare your edit with the server.",
  "problem_validation-error": "Correct the highlighted fields.",
  "problem_precondition-required": "Version missing. Reload the task.",
  "problem_rate-limited": "Too many requests. Wait before retrying.",
  "problem_internal-error": "The server could not finish. Try later.",
  "problem_payload-too-large": "The request is too large. Shorten it.",
  "problem_method-not-allowed": "This operation is not supported.",
  "problem_unsupported-media-type": "The server did not accept the request format.",
  "problem_service-unavailable": "The backend is not ready. Retry later.",
  "discardChain": "Discard this entity and dependent local changes",
  "differentAccountQueue": "Sign in with the previous account to sync or discard its pending changes first.",
  "create_task": "Create task",
  "update_task": "Edit task",
  "complete_task": "Complete task",
  "create_comment": "Create comment",
  "in_flight": "Syncing",
  "synced": "Synced",
  "network": "Network unavailable",
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

#### `lib/core/api_problem.dart`
Normalize RFC 9457 bodies once, including pointer-keyed errors and case-insensitive Retry-After lookup. Support seconds/HTTP dates; retry transient failures and park permanent failures. Unknown types show their title.

Create or replace this file, then save it:

**File: `lib/core/api_problem.dart`**
```dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../l10n/strings.dart';

final class ApiProblem implements Exception {
  const ApiProblem(this.type, this.title, this.status, this.fields, this.retryAt, this.traceId);
  final String type;
  final String title;
  final int status;
  final Map<String, String> fields;
  final DateTime? retryAt;
  final String? traceId;
  String get suffix => type.split('/').last;
  String get message => Strings.text('problem_$suffix') == 'problem_$suffix' ? title : Strings.text('problem_$suffix');
  bool get retryable => status == 0 || status >= 500 || const [408,425,429].contains(status);
  factory ApiProblem.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    final body = data is Map ? data : const {};
    final delay = int.tryParse(response?.headers.value('retry-after') ?? '');
    DateTime? retryDate;
    try { retryDate = HttpDate.parse(response?.headers.value('retry-after') ?? ''); } on FormatException { /* A missing or malformed header has no delay. */ }
    return ApiProblem(body['type'] as String? ?? 'network',
      body['title'] as String? ?? Strings.text('networkError'), response?.statusCode ?? 0,
      {for (final field in body['errors'] as List? ?? const [])
        if (field is Map && field['pointer'] is String && field['detail'] is String)
          field['pointer'] as String: field['detail'] as String},
      delay == null ? retryDate : DateTime.now().add(Duration(seconds: delay)),
      body['traceId'] as String?);
  }
  @override
  String toString() => message;
}
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

#### `lib/data/models/item.dart`
Immutable domain snapshots keep generated DTOs out of features. PageData retains opaque cursors; Query is a value-equal record. The compact Item model is a disclosed alternative to separate per-entity classes.

Create or replace this file, then save it:

**File: `lib/data/models/item.dart`**
```dart
import 'dart:convert';

// A frozen domain snapshot. Generated DTOs never escape ApiService.
final class Item {
  Item(Map<String, Object?> value) : json = Map.unmodifiable(value);
  final Map<String, Object?> json;
  String get id => json['id'] as String;
  int get version => json['version'] as int? ?? 0;
  String text(String key) => json[key]?.toString() ?? '';
  String get label => text(json.containsKey('title') ? 'title' : json.containsKey('name') ? 'name' : 'body');
  bool get pending => json['syncState'] != null && json['syncState'] != 'synced';
  String encode() => jsonEncode(json);
}

final class PageData {
  const PageData(this.items, this.cursor);
  final List<Item> items;
  final String? cursor;
  factory PageData.fromJson(Map<String, Object?> json) => PageData(
    List.unmodifiable((json['items'] as List).map((v) => Item(Map<String, Object?>.from(v as Map)))),
    (json['page'] as Map)['nextCursor'] as String?,
  );
}

typedef Query = ({String kind, String parent, String search, bool archived, String statuses, String sort});
Query query(String kind, {String parent = '', String search = '', bool archived = false, String statuses = '', String sort = '-createdAt'}) =>
  (kind: kind, parent: parent, search: search, archived: archived, statuses: statuses, sort: sort);
String queryKey(Query q) => jsonEncode([q.kind,q.parent,q.search,q.archived,q.statuses,q.sort]);
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
New-Item -ItemType Directory -Force 'lib/data/local' | Out-Null
New-Item -ItemType Directory -Force 'lib/data/repositories' | Out-Null
New-Item -ItemType Directory -Force 'lib/data/services' | Out-Null
New-Item -ItemType Directory -Force 'lib/data/sync' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/data/local'
mkdir -p 'lib/data/repositories'
mkdir -p 'lib/data/services'
mkdir -p 'lib/data/sync'
```

#### `lib/data/local/cache_store.dart`
This interface separates repositories from the current cache implementation. Screens do not know whether pages and records live in memory or SQLite.

Create or replace this file, then save it:

**File: `lib/data/local/cache_store.dart`**
```dart
import '../models/item.dart';

abstract interface class CacheStore {
  Stream<void> get changes;
  Future<String> canonicalId(String id);
  Future<PageData?> page(Query q);
  Future<void> savePage(Query q, PageData page, {required bool append});
  Future<Item?> item(String kind, String id);
  Future<void> put(String kind, Item item);
  Future<void> remove(String kind, String id);
  Future<String?> setting(String key);
  Future<void> setSetting(String key, String value);
  Future<int> pendingCount();
  Future<void> clear();
  Future<void> close();
}
```

#### `lib/data/local/database.dart`
Generate table classes from the SQL baseline. Whitelist table names, bind values, use transactions and schemaVersion 1, and enable WAL/busy timeout for coordination. Future shipped-schema changes require numbered migrations.

Create or replace this file, then save it:

**File: `lib/data/local/database.dart`**
```dart
import 'dart:convert';
import 'package:drift/drift.dart' hide Query;
import 'package:drift_flutter/drift_flutter.dart';
import '../models/item.dart';
import 'cache_store.dart';

part 'database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase implements CacheStore {
  AppDatabase() : super(driftDatabase(name: 'tasksteams',native: const DriftNativeOptions(shareAcrossIsolates:true)));
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll(),
    beforeOpen: (_) async { await customStatement('PRAGMA journal_mode=WAL'); await customStatement('PRAGMA busy_timeout=5000'); });
  TableInfo _table(String kind) => switch(kind) {
    'teams' => teams, 'projects' => projects, 'tasks' => tasks, 'comments' => comments,
    _ => throw ArgumentError('unknown_table'),
  };
  @override
  Stream<void> get changes => tableUpdates(TableUpdateQuery.onAllTables([teams,projects,tasks,comments,outbox,cachedPages,appSettings])).map((_) {});
  @override
  Future<String> canonicalId(String id) async => await setting('alias.$id') ?? id;
  @override
  Future<String?> setting(String key) async => (await customSelect('SELECT value FROM app_settings WHERE key = ?',variables:[Variable(key)]).getSingleOrNull())?.read<String>('value');
  @override
  Future<void> setSetting(String key,String value) async {
    await customInsert('INSERT INTO app_settings(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
      variables:[Variable(key),Variable(value)],updates:{appSettings});
  }
  @override
  Future<Item?> item(String kind,String id) async {
    _table(kind);
    final row = await customSelect('SELECT payload_json FROM $kind WHERE id = ?',variables:[Variable(await canonicalId(id))]).getSingleOrNull();
    return row == null ? null : Item(Map<String,Object?>.from(jsonDecode(row.read<String>('payload_json')) as Map));
  }
  @override
  Future<void> put(String kind,Item value) async {
    final table = _table(kind);
    final j = value.json;
    final columns = <String,Object?>{'id':value.id,'payload_json':value.encode()};
    final names = switch(kind) {
      'teams' => {'name':'name','description':'description','member_count':'memberCount','version':'version','updated_at':'updatedAt'},
      'projects' => {'team_id':'teamId','key':'key','name':'name','description':'description','archived':'archived','version':'version'},
      'tasks' => {'project_id':'projectId','title':'title','description':'description','status':'status','priority':'priority','assignee_id':'assigneeId','due_date':'dueDate','completed_at':'completedAt','version':'version','created_at':'createdAt','sync_state':'syncState','server_json':'serverJson'},
      'comments' => {'task_id':'taskId','body':'body','created_at':'createdAt','sync_state':'syncState'},
      _ => <String,String>{},
    };
    for (final e in names.entries) {
      Object? v = j[e.value];
      if (e.key == 'sync_state') v ??= 'synced';
      if (e.key == 'member_count' || e.key == 'version') v ??= 0;
      if (e.key == 'archived') v = v == true ? 1 : 0;
      if (e.key == 'server_json' && v != null) v = jsonEncode(v);
      if (v == null && !const ['assignee_id','due_date','completed_at','server_json'].contains(e.key)) v = '';
      columns[e.key] = v;
    }
    if (kind == 'comments') {
      final author = j['author'] as Map? ?? {};
      columns.addAll({'author_id':author['id'] ?? '', 'author_name':author['displayName'] ?? ''});
    }
    final keys = columns.keys.toList();
    await customInsert('INSERT INTO $kind (${keys.join(',')}) VALUES (${keys.map((_) => '?').join(',')}) ON CONFLICT(id) DO UPDATE SET ${keys.where((k) => k != 'id').map((k) => '$k=excluded.$k').join(',')}',
      variables:columns.values.map((v) => Variable(v)).toList(),updates:{table});
  }
  @override
  Future<void> remove(String kind,String id) async {
    await customUpdate('DELETE FROM $kind WHERE id=?',variables:[Variable(id)],updates:{_table(kind)});
  }
  @override
  Future<PageData?> page(Query q) async {
    final page = await customSelect('SELECT * FROM cached_pages WHERE page_key=?',variables:[Variable(queryKey(q))]).getSingleOrNull();
    final ids = <String>{if (page != null) ...(jsonDecode(page.read<String>('ids')) as List).cast<String>()};
    final items = <Item>[];
    final parent = await canonicalId(q.parent);
    if (const ['tasks','comments'].contains(q.kind)) {
      final column = q.kind == 'tasks' ? 'project_id' : 'task_id';
      final pending = await customSelect('SELECT id FROM ${q.kind} WHERE $column=? AND sync_state != ?',variables:[Variable(parent),const Variable('synced')]).get();
      ids.addAll(pending.map((row) => row.read<String>('id')));
    }
    for (final id in ids) {
      final entity = await item(q.kind,id);
      if (entity == null) continue;
      if (q.kind == 'tasks' && q.statuses.isNotEmpty && !q.statuses.split(',').contains(entity.text('status'))) continue;
      items.add(entity);
    }
    if (page == null && items.isEmpty) return null;
    if (q.kind == 'tasks') { items.sort((a,b) {
      final field = q.sort == 'dueDate' ? 'dueDate' : 'createdAt';
      final av = a.text(field), bv = b.text(field);
      if (field == 'dueDate' && (av.isEmpty || bv.isEmpty)) return av.isEmpty == bv.isEmpty ? a.id.compareTo(b.id) : av.isEmpty ? 1 : -1;
      final compared = av.compareTo(bv);
      final tie = compared == 0 ? a.id.compareTo(b.id) : compared;
      return q.sort.startsWith('-') ? -tie : tie;
    });
    }
    return PageData(List.unmodifiable(items),page?.readNullable<String>('next_cursor'));
  }
  @override
  Future<void> savePage(Query q,PageData value,{required bool append}) => transaction(() async {
    final old = append ? await page(q) : null;
    if (!append && q.kind == 'tasks') {
      await customUpdate("DELETE FROM tasks WHERE project_id=? AND sync_state='synced'",
        variables:[Variable(await canonicalId(q.parent))],updates:{tasks});
    }
    final ids = <String>{if (old != null) ...old.items.map((item) => item.id)};
    for (final entity in value.items) {
      final local = await item(q.kind,entity.id);
      if (local == null || !local.pending) await put(q.kind,entity);
      ids.add(entity.id);
    }
    await customInsert('INSERT INTO cached_pages(page_key,ids,next_cursor) VALUES (?,?,?) ON CONFLICT(page_key) DO UPDATE SET ids=excluded.ids,next_cursor=excluded.next_cursor',
      variables:[Variable(queryKey(q)),Variable(jsonEncode(ids.toList())),Variable(value.cursor)],updates:{cachedPages});
  });
  @override
  Future<int> pendingCount() async => (await customSelect('SELECT count(*) AS n FROM outbox').getSingle()).read<int>('n');
  @override
  Future<void> clear() => transaction(() async {
    for (final table in <TableInfo>[cachedPages,outbox,comments,tasks,projects,teams,appSettings]) {
      await customUpdate('DELETE FROM ${table.actualTableName}',updates:{table});
    }
  });
}
```

#### `lib/data/local/memory_store.dart`
The phase-3 cache emits immutable snapshots and notifications but cannot survive process death. Phase 4 retains this file for comparison while wiring AppDatabase instead.

Create or replace this file, then save it:

**File: `lib/data/local/memory_store.dart`**
```dart
import 'dart:async';
import '../models/item.dart';
import 'cache_store.dart';

final class MemoryStore implements CacheStore {
  @override
  Future<String> canonicalId(String id) async => id;
  final _pages = <String, (List<String>, String?)>{};
  final _items = <String, Item>{};
  final _settings = <String, String>{};
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<PageData?> page(Query q) async {
    final stored = _pages[queryKey(q)];
    if (stored == null) return null;
    return PageData(List.unmodifiable(stored.$1.map((id) => _items['${q.kind}/$id']).whereType<Item>()),stored.$2);
  }
  @override
  Future<void> savePage(Query q, PageData value, {required bool append}) async {
    final ids = <String>{if (append) ...?_pages[queryKey(q)]?.$1};
    for (final item in value.items) { _items['${q.kind}/${item.id}'] = item; ids.add(item.id); }
    _pages[queryKey(q)] = (ids.toList(),value.cursor);
    _changes.add(null);
  }
  @override
  Future<Item?> item(String kind, String id) async => _items['$kind/$id'];
  @override
  Future<void> put(String kind, Item value) async { _items['$kind/${value.id}'] = value; _changes.add(null); }
  @override
  Future<void> remove(String kind, String id) async { _items.remove('$kind/$id'); _changes.add(null); }
  @override
  Future<String?> setting(String key) async => _settings[key];
  @override
  Future<void> setSetting(String key, String value) async { _settings[key] = value; }
  @override
  Future<int> pendingCount() async => 0;
  @override
  Future<void> clear() async { _pages.clear(); _items.clear(); _settings.clear(); _changes.add(null); }
  @override
  Future<void> close() => _changes.close();
}
```

#### `lib/data/local/schema.drift`
Keep the named TDD tables and indexes; payload_json preserves complete snapshots, cached_pages retains query membership and a lease coordinates drainers. Quote the key column: it is a parser keyword.

Create or replace this file, then save it:

**File: `lib/data/local/schema.drift`**
```sql
CREATE TABLE teams (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  member_count INTEGER NOT NULL DEFAULT 0,
  version INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  payload_json TEXT NOT NULL
);
CREATE TABLE projects (
  id TEXT NOT NULL PRIMARY KEY,
  team_id TEXT NOT NULL,
  "key" TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0,
  version INTEGER NOT NULL,
  payload_json TEXT NOT NULL
);
CREATE INDEX projects_team ON projects(team_id);
CREATE TABLE tasks (
  id TEXT NOT NULL PRIMARY KEY,
  project_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  assignee_id TEXT,
  due_date TEXT,
  completed_at TEXT,
  version INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  sync_state TEXT NOT NULL CHECK(sync_state IN ('synced','pending','conflict','failed')),
  server_json TEXT,
  payload_json TEXT NOT NULL
);
CREATE INDEX tasks_project ON tasks(project_id,created_at DESC,id DESC);
CREATE TABLE comments (
  id TEXT NOT NULL PRIMARY KEY,
  task_id TEXT NOT NULL,
  author_id TEXT NOT NULL,
  author_name TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  sync_state TEXT NOT NULL,
  payload_json TEXT NOT NULL
);
CREATE INDEX comments_task ON comments(task_id,created_at);
CREATE TABLE outbox (
  seq INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  id TEXT NOT NULL UNIQUE,
  kind TEXT NOT NULL CHECK(kind IN ('create_task','update_task','complete_task','create_comment')),
  entity_id TEXT NOT NULL,
  parent_id TEXT NOT NULL,
  payload TEXT NOT NULL,
  base_version INTEGER,
  state TEXT NOT NULL CHECK(state IN ('pending','in_flight','failed','conflict')),
  attempts INTEGER NOT NULL DEFAULT 0,
  next_attempt_at INTEGER NOT NULL DEFAULT 0,
  last_problem_type TEXT,
  problem_json TEXT,
  server_json TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX outbox_ready ON outbox(state,next_attempt_at);
CREATE INDEX outbox_entity ON outbox(entity_id,seq);
CREATE TABLE app_settings (
  "key" TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE TABLE cached_pages (
  page_key TEXT NOT NULL PRIMARY KEY,
  ids TEXT NOT NULL,
  next_cursor TEXT
);
CREATE TABLE sync_leases (
  name TEXT NOT NULL PRIMARY KEY,
  owner TEXT NOT NULL,
  expires INTEGER NOT NULL
);
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
  Future<void> Function(String)? acceptSubject;
  Future<void> restore() async {
    final session = await _store.read();
    if (session != null) {
      try { await acceptSubject?.call(session.subject); } catch (_) { _notify(false); return; }
    }
    _notify(session != null);
  }
  Future<void> signIn() async {
    final value = await _service.signIn();
    if (value == null) return;
    await acceptSubject?.call(value.subject);
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
    intendedRoute = '/teams';
    _notify(false);
  }
  Future<void> dispose() => _changes.close();
}
```

#### `lib/data/repositories/collection_repository.dart`
Watch cached pages first, then update them from the API. Separate Team/Project/Comment repositories share list mechanics without exposing transport to widgets.

Create or replace this file, then save it:

**File: `lib/data/repositories/collection_repository.dart`**
```dart
import '../local/cache_store.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class CollectionRepository {
  CollectionRepository(this.store, this.api);
  final CacheStore store;
  final ApiService api;
  Stream<PageData?> watch(Query q) async* {
    yield await store.page(q);
    await for (final _ in store.changes) { yield await store.page(q); }
  }
  Future<void> refresh(Query q, {String? cursor}) async {
    final canonical = (kind:q.kind,parent:await store.canonicalId(q.parent),search:q.search,archived:q.archived,statuses:q.statuses,sort:q.sort);
    final page = await api.page(canonical, cursor: cursor);
    await store.savePage(q, page, append: cursor != null);
  }
}
class TeamRepository extends CollectionRepository { TeamRepository(super.store, super.api); }
class ProjectRepository extends CollectionRepository { ProjectRepository(super.store, super.api); }
class CommentRepository extends CollectionRepository {
  CommentRepository(super.store, super.api);
  Future<void> delete(String id) async { await api.deleteComment(id); await store.remove('comments',id); }
}
```

#### `lib/data/repositories/settings_repository.dart`
Restore a public API URL, refuse backend changes with pending work, and clear stale cache when changing sources. Test health before reading account data; roles/scopes are server data, not invented privileges.

Create or replace this file, then save it:

**File: `lib/data/repositories/settings_repository.dart`**
```dart
import 'package:flutter/foundation.dart';
import '../../core/config.dart';
import '../../core/url_policy.dart';
import '../local/cache_store.dart';
import '../services/api_service.dart';

final class SettingsRepository {
  SettingsRepository(this.store, this.api);
  final CacheStore store;
  final ApiService api;
  Future<void> restore() async => api.setBase(await store.setting('base_url') ?? Config.apiBase);
  Future<void> select(String label, String url) async {
    UrlPolicy.validate(url, debug: kDebugMode);
    if (await store.pendingCount() != 0) throw StateError('queueNotEmpty');
    final owner = await store.setting('owner');
    await store.clear();
    if (owner != null) await store.setSetting('owner',owner);
    await store.setSetting('base_url',url);
    await store.setSetting('backend_label',label);
    api.setBase(url);
  }
  Future<Map<String,Object?>> account() async {
    final me = await api.me();
    await store.setSetting('owner_name',me['displayName'] as String);
    return me;
  }
  Future<Map<String, Object?>> test() async {
    final health = await api.health();
    final me = await account();
    return {'health': health, 'account': me};
  }
}
```

#### `lib/data/repositories/task_repository.dart`
TaskRepository adds task snapshots and writes. DirectWriter is the online phase implementation; the durable phase substitutes OutboxWriter behind the same gateway interface.

Create or replace this file, then save it:

**File: `lib/data/repositories/task_repository.dart`**
```dart
import '../local/cache_store.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import 'collection_repository.dart';

abstract interface class WriteGateway {
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key);
}
final class DirectWriter implements WriteGateway {
  DirectWriter(this.api, this.store);
  final ApiService api;
  final CacheStore store;
  @override
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key) async {
    final result = await api.write(kind,entity,parent,body,version,key);
    await store.put(kind == 'create_comment' ? 'comments' : 'tasks',result);
    return result;
  }
}
final class TaskRepository extends CollectionRepository {
  TaskRepository(super.store, super.api, this.writer);
  final WriteGateway writer;
  Future<void> refreshTask(String id) async {
    final local = await store.item('tasks',id);
    if (local?.pending ?? false) return;
    await store.put('tasks',await api.task(await store.canonicalId(id)));
  }
  Stream<Item?> watchTask(String id) async* {
    yield await store.item('tasks',id);
    await for (final _ in store.changes) { yield await store.item('tasks',id); }
  }
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key) =>
    writer.write(kind,entity,parent,body,version,key);
}
```

#### `lib/data/services/api_service.dart`
Only this application boundary imports generated clients. Validate destinations, disable redirects, attach bearer credentials and retry a 401 at most once. One raw PATCH preserves absent-versus-null semantics; generated code stays untouched.

Create or replace this file, then save it:

**File: `lib/data/services/api_service.dart`**
```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_problem.dart';
import '../../core/url_policy.dart';
import '../generated/tasks_api.dart' as generated;
import '../models/item.dart';
import '../repositories/auth_repository.dart';
import 'auth_service.dart';

final class ApiService {
  ApiService(String baseUrl, AuthRepository auth) {
    setBase(baseUrl);
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      try {
        UrlPolicy.validate(Uri(scheme: options.uri.scheme, host: options.uri.host, port: options.uri.port, path: options.uri.path).toString(), debug: kDebugMode);
        if (options.path != '/health') {
          options.headers['Authorization'] = 'Bearer ${await auth.accessToken()}';
        }
        handler.next(options);
      } on AuthUnavailable {
        handler.reject(DioException(requestOptions: options,
          error: const ApiProblem('network','',0,{},null,null)));
      } catch (_) {
        handler.reject(DioException(requestOptions: options, error: const AuthExpired()));
      }
    }, onError: (error, handler) async {
      final request = error.requestOptions;
      if (error.response?.statusCode == 401 && request.extra['retried'] != true) {
        try {
          final previous = (request.headers['Authorization'] as String).substring(7);
          final next = await auth.accessToken(rejected: previous);
          request.headers['Authorization'] = 'Bearer $next';
          request.extra['retried'] = true;
          handler.resolve(await _dio.fetch<dynamic>(request));
          return;
        } on AuthUnavailable {
          handler.next(error.copyWith(error: const ApiProblem('network','',0,{},null,null)));
          return;
        } catch (_) {
          handler.next(error.copyWith(error: const AuthExpired()));
          return;
        }
      }
      handler.next(error.copyWith(error: ApiProblem.fromDio(error)));
    }));
    _api = generated.TasksApi(_dio);
  }
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20), followRedirects: false));
  late final generated.TasksApi _api;
  void setBase(String value) => _dio.options.baseUrl = UrlPolicy.validate(value, debug: kDebugMode).toString().replaceFirst(RegExp(r'/$'), '');
  Map<String, Object?> _json(Object value) => Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
  Future<T> _call<T>(Future<T> Function() action) async {
    try { return await action(); } on DioException catch (error) {
      throw error.error is ApiProblem ? error.error! : const AuthExpired();
    }
  }
  Future<PageData> page(Query q, {String? cursor}) => _call(() async {
    final Object result = switch (q.kind) {
      'teams' => await _api.teams.listTeams(q: q.search.isEmpty ? null : q.search, limit: 25, cursor: cursor),
      'projects' => await _api.projects.listProjects(teamId: q.parent, archived: q.archived, limit: 25, cursor: cursor),
      'tasks' => await _api.tasks.listTasks(projectId: q.parent, limit: 25, cursor: cursor,
        sort: generated.ListTasksSort.fromJson(q.sort),
        status: q.statuses.isEmpty ? null : q.statuses.split(',').map(generated.TaskStatus.fromJson).toList()),
      'comments' => await _api.comments.listComments(taskId: q.parent, limit: 25, cursor: cursor),
      _ => throw ArgumentError('unknown_resource'),
    };
    return PageData.fromJson(_json(result));
  });
  Future<Item> task(String id) => _call(() async => Item(_json(await _api.tasks.getTask(taskId: id))));
  Future<Map<String, Object?>> me() => _call(() async => _json(await _api.platform.getMe()));
  Future<Map<String, Object?>> health() => _call(() async => _json(await _api.platform.getHealth()));
  Future<void> deleteComment(String id) => _call(() => _api.comments.deleteComment(commentId: id));
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key) => _call(() async {
    final Object result;
    switch (kind) {
      case 'create_task':
        result = await _api.tasks.createTask(projectId: parent, idempotencyKey: key,
          body: generated.TaskCreate.fromJson(body));
      case 'update_task':
        // Generated TaskUpdate cannot distinguish absent from explicit null.
        // Keep this one merge-patch request hand-written, inside the API boundary.
        final response = await _dio.patch<Map<String, dynamic>>('/v1/tasks/${Uri.encodeComponent(entity)}',
          data: body, options: Options(contentType: 'application/merge-patch+json', headers: {'If-Match': '"$version"'}));
        result = response.data!;
      case 'complete_task':
        result = await _api.tasks.completeTask(taskId: entity, ifMatch: '"$version"');
      case 'create_comment':
        result = await _api.comments.createComment(taskId: parent, idempotencyKey: key,
          body: generated.CommentCreate.fromJson(body));
      default: throw ArgumentError('unknown_write');
    }
    return Item(_json(result));
  });
  void dispose() => _dio.close();
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

#### `lib/data/services/connectivity_service.dart`
Connectivity is only a scheduling hint: a connected Wi-Fi interface may still have no route to the API or issuer.

Create or replace this file, then save it:

**File: `lib/data/services/connectivity_service.dart`**
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

final class ConnectivityService {
  Stream<bool> get changes => Connectivity().onConnectivityChanged.map((values) => !values.contains(ConnectivityResult.none));
  Future<bool> available() async => !(await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);
}
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

#### `lib/data/sync/outbox_dao.dart`
Drain in sequence per entity, use a renewable lease, and recover abandoned in-flight rows after acquisition. Discard explicitly removes the whole dependent local chain; it does not undo remote data.

Create or replace this file, then save it:

**File: `lib/data/sync/outbox_dao.dart`**
```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../models/item.dart';

final class PendingWrite {
  PendingWrite(QueryRow row) : id=row.read<String>('id'),kind=row.read<String>('kind'),entity=row.read<String>('entity_id'),
    parent=row.read<String>('parent_id'),version=row.readNullable<int>('base_version'),state=row.read<String>('state'),
    attempts=row.read<int>('attempts'),next=row.read<int>('next_attempt_at'),
    payload=Map<String,Object?>.from(jsonDecode(row.read<String>('payload')) as Map),
    problem=row.readNullable<String>('problem_json'),server=row.readNullable<String>('server_json');
  final String id,kind,entity,parent,state;
  final int? version;
  final int attempts,next;
  final Map<String,Object?> payload;
  final String? problem,server;
  Map<String,Object?> get body => Map<String,Object?>.from(payload['body'] as Map);
}
final class OutboxDao {
  OutboxDao(this.db);
  final AppDatabase db;
  Future<List<PendingWrite>> all() async => (await db.customSelect('SELECT * FROM outbox ORDER BY seq').get()).map(PendingWrite.new).toList();
  Future<PendingWrite?> ready() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await db.customSelect("SELECT o.* FROM outbox o WHERE o.state='pending' AND o.next_attempt_at<=? AND NOT EXISTS (SELECT 1 FROM outbox earlier WHERE earlier.entity_id=o.entity_id AND earlier.seq<o.seq) ORDER BY o.seq LIMIT 1",variables:[Variable(now)]).getSingleOrNull();
    return row == null ? null : PendingWrite(row);
  }
  Future<void> update(String id,String state,{int? attempts,int? next,String? problem,String? server}) async {
    await db.customUpdate('UPDATE outbox SET state=?,attempts=coalesce(?,attempts),next_attempt_at=coalesce(?,next_attempt_at),problem_json=?,last_problem_type=?,server_json=? WHERE id=?',
      variables:[Variable(state),Variable(attempts),Variable(next),Variable(problem),Variable(problem == null ? null : (jsonDecode(problem) as Map)['type'] as String?),Variable(server),Variable(id)],updates:{db.outbox});
  }
  Future<bool> lease(String owner) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final n = await db.customUpdate("INSERT INTO sync_leases(name,owner,expires) VALUES ('drain',?,?) ON CONFLICT(name) DO UPDATE SET owner=excluded.owner,expires=excluded.expires WHERE sync_leases.expires<? OR sync_leases.owner=?",
      variables:[Variable(owner),Variable(now+90000),Variable(now),Variable(owner)]);
    return n == 1;
  }
  Future<void> release(String owner) async {
    await db.customUpdate('DELETE FROM sync_leases WHERE owner=?',variables:[Variable(owner)]);
  }
  Future<void> recover() async {
    await db.customUpdate("UPDATE outbox SET state='pending' WHERE state='in_flight'",updates:{db.outbox});
  }
  Future<void> remove(String id) async { await db.customUpdate('DELETE FROM outbox WHERE id=?',variables:[Variable(id)],updates:{db.outbox}); }
  Future<void> retry(String id) => update(id,'pending',next:0);
  Future<void> resolve(PendingWrite row,Set<String> keep) => db.transaction(() async {
    final latest = Item(Map<String,Object?>.from(jsonDecode(row.server!) as Map));
    final body = {for (final e in row.body.entries) if (keep.contains(e.key)) e.key:e.value};
    if (body.isEmpty) { await remove(row.id); }
    else {
      await db.customUpdate("UPDATE outbox SET payload=?,base_version=?,state='pending',next_attempt_at=0,attempts=0,problem_json=NULL,server_json=NULL WHERE id=?",
        variables:[Variable(jsonEncode({'body':body,'before':latest.json})),Variable(latest.version),Variable(row.id)],updates:{db.outbox});
    }
    await db.put('tasks',Item({...latest.json,...body,'syncState':body.isEmpty ? 'synced':'pending'}));
  });
  // Discard the entity's whole local chain; never leave dependent writes dangling.
  Future<void> discard(PendingWrite row) => db.transaction(() async {
    final chain = (await all()).where((r) => r.entity == row.entity).toList();
    final before = chain.first.payload['before'];
    for (final pending in await all()) {
      if (pending.entity == row.entity || (before == null && pending.parent == row.entity)) {
        await remove(pending.id);
        if (pending.kind == 'create_comment') await db.remove('comments',pending.entity);
      }
    }
    final table = row.kind == 'create_comment' ? 'comments':'tasks';
    if (before == null) { await db.remove(table,row.entity); }
    else { await db.put(table,Item(Map<String,Object?>.from(before as Map))); }
  });
}
```

#### `lib/data/sync/outbox_writer.dart`
Commit the optimistic record and queued operation together. Merge only never-dispatched creates. A definitive 422 rejection can be corrected under a fresh key; no HTTP occurs inside the local transaction.

Create or replace this file, then save it:

**File: `lib/data/sync/outbox_writer.dart`**
```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../models/item.dart';
import '../repositories/task_repository.dart';
import 'outbox_dao.dart';

final class OutboxWriter implements WriteGateway {
  OutboxWriter(this.db);
  final AppDatabase db;
  @override
  Future<Item> write(String kind,String entity,String parent,Map<String,Object?> body,int? version,String key) => db.transaction(() async {
    entity = await db.canonicalId(entity);
    parent = await db.canonicalId(parent);
    final table = kind == 'create_comment' ? 'comments':'tasks';
    final before = await db.item(table,entity);
    final now = DateTime.now().toUtc().toIso8601String();
    final optimistic = Item({
      'id':entity,'createdAt':now,'updatedAt':now,'version':version ?? 0,
      if (kind == 'create_task') ...{'projectId':parent,'createdBy':await db.setting('owner'),'completedAt':null},
      if (kind == 'create_comment') ...{'taskId':parent,'author':{'id':await db.setting('owner'),'displayName':await db.setting('owner_name') ?? ''}},
      ...?before?.json,...body,
      if (kind == 'complete_task') ...{'status':'done','completedAt':now},
      'syncState':'pending',
    });
    await db.put(table,optimistic);
    final all = await OutboxDao(db).all();
    final invalid = all.where((r) => r.entity == entity && r.state == 'failed' &&
      r.problem != null && (jsonDecode(r.problem!) as Map)['status'] == 422);
    if (invalid.isNotEmpty && kind == 'update_task') {
      final failed = invalid.first;
      final corrected = {...failed.body,...body};
      await db.customUpdate("UPDATE outbox SET id=?,payload=?,state='pending',attempts=0,next_attempt_at=0,problem_json=NULL WHERE id=?",
        variables:[Variable(key),Variable(jsonEncode({...failed.payload,'body':corrected})),Variable(failed.id)],updates:{db.outbox});
      return optimistic;
    }
    final creates = all.where((r) => r.entity == entity && r.kind == 'create_task' && r.attempts == 0 && r.state == 'pending');
    if (creates.isNotEmpty && kind != 'create_task') {
      final create = creates.first;
      final merged = {...create.body,...body,if (kind == 'complete_task') 'status':'done'};
      await db.customUpdate('UPDATE outbox SET payload=? WHERE id=?',variables:[Variable(jsonEncode({...create.payload,'body':merged})),Variable(create.id)],updates:{db.outbox});
    } else {
      await db.customInsert("INSERT INTO outbox(id,kind,entity_id,parent_id,payload,base_version,state,created_at) VALUES (?,?,?,?,?,?,'pending',?) ON CONFLICT(id) DO NOTHING",
        variables:[Variable(key),Variable(kind),Variable(entity),Variable(parent),Variable(jsonEncode({'body':body,'before':before?.json})),Variable(version),Variable(now)],updates:{db.outbox});
    }
    return optimistic;
  });
}
```

#### `lib/data/sync/sync_engine.dart`
Use the stable row id as the create key, honor versions, park conflicts/permanent errors and back off with jitter for transient failures. Re-key accepted creates and dependent membership atomically. Never hold a SQLite transaction across HTTP.

Create or replace this file, then save it:

**File: `lib/data/sync/sync_engine.dart`**
```dart
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/api_problem.dart';
import '../local/database.dart';
import '../models/item.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import 'outbox_dao.dart';

final class SyncEngine {
  SyncEngine(this.db,this.api,this.auth) : dao=OutboxDao(db);
  final AppDatabase db;
  final ApiService api;
  final AuthRepository auth;
  final OutboxDao dao;
  Future<void>? _running;
  Future<void> drain() => _running ??= _drain().whenComplete(() => _running=null);
  Future<void> _drain() async {
    if (auth.signedIn != true) return;
    final owner = const Uuid().v4();
    if (!await dao.lease(owner)) return;
    try {
      await dao.recover();
      for (var n=0;n<100;n++) {
        if (!await dao.lease(owner)) return;
        final row = await dao.ready();
        if (row == null) return;
        await dao.update(row.id,'in_flight',attempts:row.attempts+1);
        try {
          final result = await api.write(row.kind,await db.canonicalId(row.entity),
            await db.canonicalId(row.parent),row.body,row.version,row.id);
          await _accept(row,result);
        } on AuthExpired {
          await dao.update(row.id,'pending');
          return;
        } on ApiProblem catch (problem) {
          if (problem.status == 412) {
            final server = await api.task(await db.canonicalId(row.entity));
            await db.transaction(() async {
              await dao.update(row.id,'conflict',server:server.encode(),problem:jsonEncode({'type':problem.type,'title':problem.title}));
              final mine = await db.item('tasks',row.entity);
              if (mine != null) await db.put('tasks',Item({...mine.json,'syncState':'conflict','serverJson':server.json}));
            });
          } else {
            final exponent = min(row.attempts,10);
            final backoff = min(3600000,1000 * (1 << exponent)) + Random.secure().nextInt(1000);
            final retryAt = problem.retryAt?.millisecondsSinceEpoch ?? 0;
            final next = max(DateTime.now().millisecondsSinceEpoch+backoff,retryAt);
            await dao.update(row.id,problem.retryable ? 'pending':'failed',next:next,
              problem:jsonEncode({'type':problem.type,'title':problem.title,'status':problem.status,'errors':problem.fields,'traceId':problem.traceId}));
            if (!problem.retryable) {
              final table = row.kind == 'create_comment' ? 'comments':'tasks';
              final local = await db.item(table,row.entity);
              if (local != null) await db.put(table,Item({...local.json,'syncState':'failed','fieldErrors':problem.fields}));
            }
            if (problem.status == 0 || problem.status == 429 || problem.status >= 500) return;
          }
        } catch (_) {
          await dao.update(row.id,'pending',next:DateTime.now().millisecondsSinceEpoch+30000);
          return;
        }
      }
    } finally { await dao.release(owner); }
  }
  Future<void> _accept(PendingWrite row,Item server) => db.transaction(() async {
    final table = row.kind == 'create_comment' ? 'comments':'tasks';
    if (row.entity != server.id) {
      await db.setSetting('alias.${row.entity}',server.id);
      await db.remove(table,row.entity);
      await db.customUpdate('UPDATE outbox SET entity_id=? WHERE entity_id=?',variables:[Variable(server.id),Variable(row.entity)],updates:{db.outbox});
      await db.customUpdate('UPDATE outbox SET parent_id=? WHERE parent_id=?',variables:[Variable(server.id),Variable(row.entity)],updates:{db.outbox});
      for (final comment in await db.customSelect('SELECT payload_json FROM comments WHERE task_id=?',variables:[Variable(row.entity)]).get()) {
        final json = Map<String,Object?>.from(jsonDecode(comment.read<String>('payload_json')) as Map);
        await db.put('comments',Item({...json,'taskId':server.id}));
      }
    }
    await dao.remove(row.id);
    final later = (await dao.all()).where((r) => r.entity == server.id).toList();
    var merged = {...server.json,'syncState':'synced'};
    if (later.isNotEmpty) {
      final first = later.first;
      await db.customUpdate('UPDATE outbox SET base_version=? WHERE id=?',variables:[Variable(server.version),Variable(first.id)],updates:{db.outbox});
      for (final pending in later) {
        merged = {...merged,...pending.body,if (pending.kind == 'complete_task') 'status':'done','syncState':'pending'};
      }
    }
    await db.put(table,Item(merged));
    if (row.kind.startsWith('create_')) {
      for (final page in await db.customSelect('SELECT * FROM cached_pages').get()) {
        final pageKey = page.read<String>('page_key');
        final query = jsonDecode(pageKey) as List;
        if (query[0] != table || await db.canonicalId(query[1] as String) != await db.canonicalId(row.parent)) continue;
        final ids = (jsonDecode(page.read<String>('ids')) as List).cast<String>().toSet();
        ids.remove(row.entity); ids.add(server.id);
        await db.customUpdate('UPDATE cached_pages SET ids=? WHERE page_key=?',
          variables:[Variable(jsonEncode(ids.toList())),Variable(pageKey)],updates:{db.cachedPages});
      }
    }
  });
}
```

#### `lib/data/sync/sync_worker.dart`
WorkManager runs a separate isolate. Register plugins, reopen the same database, check secure subject against cache owner, construct services and close resources in finally. Fifteen minutes is a minimum interval, not a deadline.

Create or replace this file, then save it:

**File: `lib/data/sync/sync_worker.dart`**
```dart
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/config.dart';
import '../local/database.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';
import '../../l10n/strings.dart';
import 'sync_engine.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task,input) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await Strings.load();
    final db = AppDatabase();
    final store = TokenStore();
    final auth = AuthRepository(AuthService(),store);
    ApiService? api;
    try {
      await auth.restore();
      final session = await store.read();
      if (session == null || await db.setting('owner') != session.subject) return true;
      api = ApiService(await db.setting('base_url') ?? Config.apiBase,auth);
      await SyncEngine(db,api,auth).drain();
      return true;
    } catch (_) { return false; }
    finally { api?.dispose(); await auth.dispose(); await db.close(); }
  });
}
Future<void> registerSyncWorker() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask('tasks-sync','tasks-sync',
    frequency:const Duration(minutes:15),
    constraints:Constraints(networkType:NetworkType.connected));
}
```

### Step 9. Expose commands through per-feature ViewModels

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/core' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/login/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/projects/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/settings/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/sync/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/task_detail/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/task_form/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/tasks/view_model' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/teams/view_model' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/core'
mkdir -p 'lib/features/login/view_model'
mkdir -p 'lib/features/projects/view_model'
mkdir -p 'lib/features/settings/view_model'
mkdir -p 'lib/features/sync/view_model'
mkdir -p 'lib/features/task_detail/view_model'
mkdir -p 'lib/features/task_form/view_model'
mkdir -p 'lib/features/tasks/view_model'
mkdir -p 'lib/features/teams/view_model'
```

#### `lib/core/collection_view_model.dart`
Replace immutable loading/data/error state, retain stale data after failed refresh and dispose subscriptions. The 429 deadline prevents immediate resend.

Create or replace this file, then save it:

**File: `lib/core/collection_view_model.dart`**
```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/item.dart';
import 'api_problem.dart';
import '../data/repositories/collection_repository.dart';

final class CollectionState {
  const CollectionState({this.page, this.loading = true, this.error});
  final PageData? page;
  final bool loading;
  final Object? error;
}
abstract class CollectionViewModel extends Notifier<CollectionState> {
  CollectionViewModel(this.query);
  Query query;
  DateTime? _notBefore;
  CollectionRepository get repository;
  StreamSubscription<PageData?>? _subscription;
  @override
  CollectionState build() {
    ref.onDispose(() => _subscription?.cancel());
    Future.microtask(() => load(query));
    return const CollectionState();
  }
  Future<void> load(Query next) async {
    query = next;
    await _subscription?.cancel();
    state = const CollectionState();
    _subscription = repository.watch(next).listen((page) {
      state = CollectionState(page: page, loading: state.loading, error: state.error);
    });
    await refresh();
  }
  Future<void> refresh({bool next = false}) async {
    if (_notBefore?.isAfter(DateTime.now()) ?? false) return;
    if (next && (state.loading || state.page?.cursor == null)) return;
    final current = query;
    state = CollectionState(page: state.page, loading: true);
    try {
      await repository.refresh(current, cursor: next ? state.page?.cursor : null);
      if (query == current) state = CollectionState(page: state.page, loading: false);
    } catch (error) {
      if (error is ApiProblem && error.status == 429) _notBefore = error.retryAt;
      if (query == current) state = CollectionState(page: state.page, loading: false,error: error);
    }
  }
}
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

#### `lib/features/projects/view_model/projects_view_model.dart`
This feature-specific Riverpod ViewModel chooses its repository and initial query, then inherits immutable collection state and commands. It imports no generated DTO, SQL or another feature?s view.

Create or replace this file, then save it:

**File: `lib/features/projects/view_model/projects_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final projectsViewModelProvider = NotifierProvider.family<ProjectsViewModel, CollectionState, String>(ProjectsViewModel.new);
class ProjectsViewModel extends CollectionViewModel {
  ProjectsViewModel(String parent) : super(query('projects',parent: parent));
  @override
  CollectionRepository get repository => ref.read(projectsRepositoryProvider);
}
```

#### `lib/features/settings/view_model/settings_view_model.dart`
This feature-specific Riverpod ViewModel chooses its repository and initial query, then inherits immutable collection state and commands. It imports no generated DTO, SQL or another feature?s view.

Create or replace this file, then save it:

**File: `lib/features/settings/view_model/settings_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

final settingsViewModelProvider = AsyncNotifierProvider<SettingsViewModel,Map<String,Object?>>(SettingsViewModel.new);
class SettingsViewModel extends AsyncNotifier<Map<String,Object?>> {
  @override
  Future<Map<String,Object?>> build() async {
    await ref.read(settingsRepositoryProvider).restore();
    return {};
  }
  Future<void> test() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(settingsRepositoryProvider).test);
  }
  Future<void> select(String label,String url) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).select(label,url); return <String,Object?>{};
    });
  }
  Future<void> signOut(bool deleteOffline) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authProvider).signOut();
      if (deleteOffline) await ref.read(storeProvider).clear();
      return <String,Object?>{};
    });
  }
}
```

#### `lib/features/sync/view_model/sync_view_model.dart`
This feature-specific Riverpod ViewModel chooses its repository and initial query, then inherits immutable collection state and commands. It imports no generated DTO, SQL or another feature?s view.

Create or replace this file, then save it:

**File: `lib/features/sync/view_model/sync_view_model.dart`**
```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/local/database.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/sync/outbox_dao.dart';

final syncViewModelProvider = NotifierProvider<SyncViewModel,SyncState>(SyncViewModel.new);
final class SyncState {
  const SyncState({this.online = true,this.busy = false,this.rows = const []});
  final bool online,busy;
  final List<PendingWrite> rows;
}
class SyncViewModel extends Notifier<SyncState> {
  @override
  SyncState build() {
    final db = ref.read(storeProvider) as AppDatabase;
    final data = db.changes.listen((_) => _reload());
    final connectivity = ConnectivityService();
    final network = connectivity.changes.listen((online) {
      state = SyncState(online:online,busy:state.busy,rows:state.rows);
      if (online) sync();
    });
    final timer = Timer.periodic(const Duration(seconds:5),(_) => sync());
    ref.onDispose(() { data.cancel(); network.cancel(); timer.cancel(); });
    Future.microtask(() async {
      final online = await connectivity.available();
      if (!ref.mounted) return;
      state = SyncState(online:online);
      await _reload();
      if (online) await sync();
    });
    return const SyncState();
  }
  OutboxDao get _dao => OutboxDao(ref.read(storeProvider) as AppDatabase);
  Future<void> _reload() async {
    final rows = await _dao.all();
    if (ref.mounted) state = SyncState(online:state.online,busy:state.busy,rows:List.unmodifiable(rows));
  }
  Future<void> sync() async {
    if (state.busy || !state.online) return;
    state = SyncState(online:state.online,busy:true,rows:state.rows);
    try { await ref.read(syncEngineProvider).drain(); }
    finally { if (ref.mounted) { state = SyncState(online:state.online,rows:state.rows); await _reload(); } }
  }
  Future<void> retry(PendingWrite row) async { await _dao.retry(row.id); await sync(); }
  Future<void> discard(PendingWrite row) => _dao.discard(row);
  Future<void> resolve(PendingWrite row,Set<String> keep) async { await _dao.resolve(row,keep); await sync(); }
}
```

#### `lib/features/task_detail/view_model/comments_view_model.dart`
This feature-specific Riverpod ViewModel chooses its repository and initial query, then inherits immutable collection state and commands. It imports no generated DTO, SQL or another feature?s view.

Create or replace this file, then save it:

**File: `lib/features/task_detail/view_model/comments_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final commentsViewModelProvider = NotifierProvider.family<CommentsViewModel, CollectionState, String>(CommentsViewModel.new);
class CommentsViewModel extends CollectionViewModel {
  CommentsViewModel(String parent) : super(query('comments',parent: parent));
  @override
  CollectionRepository get repository => ref.read(commentsRepositoryProvider);
}
```

#### `lib/features/task_detail/view_model/task_detail_view_model.dart`
Watch the cache, expose complete/comment/delete commands, and retain a comment key across retries. The current id limits the author-only affordance, but the backend still enforces authorization.

Create or replace this file, then save it:

**File: `lib/features/task_detail/view_model/task_detail_view_model.dart`**
```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../data/models/item.dart';

final detailViewModelProvider = NotifierProvider.autoDispose.family<TaskDetailViewModel,AsyncValue<Item?>,String>(TaskDetailViewModel.new);
class TaskDetailViewModel extends Notifier<AsyncValue<Item?>> {
  TaskDetailViewModel(this.id);
  final String id;
  String _commentKey = const Uuid().v4();
  bool _writing = false;
  String? callerId;
  @override
  AsyncValue<Item?> build() {
    final repository = ref.read(tasksRepositoryProvider);
    final subscription = repository.watchTask(id).listen((item) { state = AsyncData(item); });
    ref.onDispose(subscription.cancel);
    Future.microtask(refresh);
    return const AsyncLoading();
  }
  Future<void> refresh() async {
    try {
      callerId = (await ref.read(settingsRepositoryProvider).account())['id'] as String;
      await ref.read(tasksRepositoryProvider).refreshTask(id);
    } catch (error,stack) {
      if (state.value == null) state = AsyncError(error,stack);
    }
  }
  Future<void> complete() async {
    if (_writing || state.value == null) return;
    _writing = true;
    try {
      final item = state.value!;
      await ref.read(tasksRepositoryProvider).write('complete_task',id,item.text('projectId'),{},item.version,const Uuid().v4());
    } catch (error,stack) { state = AsyncError(error,stack); }
    finally { _writing = false; }
  }
  Future<bool> comment(String body) async {
    if (_writing || body.trim().isEmpty || body.length > 2000) return false;
    _writing = true;
    try {
      await ref.read(tasksRepositoryProvider).write('create_comment',_commentKey,id,{'body':body.trim()},null,_commentKey);
      _commentKey = const Uuid().v4();
      return true;
    } finally { _writing = false; }
  }
  Future<void> delete(String id) => ref.read(commentsRepositoryProvider).delete(id);
}
```

#### `lib/features/task_form/view_model/task_form_view_model.dart`
Snapshot the original task, validate limits, build changed-fields patches and retain a form create key. Original version becomes quoted If-Match. Pointer errors stay field-keyed; a 412 exposes per-field conflict choices.

Create or replace this file, then save it:

**File: `lib/features/task_form/view_model/task_form_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/api_problem.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';

typedef FormKey = ({String projectId,String taskId});
final formViewModelProvider = NotifierProvider.autoDispose.family<TaskFormViewModel,TaskFormState,FormKey>(TaskFormViewModel.new);
final class TaskFormState {
  const TaskFormState({this.values = const {},this.fields = const {},this.busy = true,this.error,this.conflict,this.revision = 0});
  final Map<String,Object?> values;
  final Map<String,String> fields;
  final bool busy;
  final Object? error;
  final Item? conflict;
  final int revision;
}
class TaskFormViewModel extends Notifier<TaskFormState> {
  TaskFormViewModel(this.key);
  final FormKey key;
  final String idempotencyKey = const Uuid().v4();
  Item? original;
  Map<String,Object?> _patch = {};
  @override
  TaskFormState build() {
    Future.microtask(_load);
    return const TaskFormState();
  }
  Future<void> _load() async {
    try {
      if (key.taskId.isNotEmpty) {
        original = await ref.read(storeProvider).item('tasks',key.taskId);
        if (original == null) { await ref.read(tasksRepositoryProvider).refreshTask(key.taskId); original = await ref.read(storeProvider).item('tasks',key.taskId); }
      }
      if (key.taskId.isNotEmpty && original == null) throw StateError('not-found');
      state = TaskFormState(busy:false,revision:1,fields:Map<String,String>.from(original?.json['fieldErrors'] as Map? ?? {}),values: Map.unmodifiable({
        'title':'','description':'','status':'todo','priority':'medium','assigneeId':null,'dueDate':null,
        if (original != null) for (final field in const ['title','description','status','priority','assigneeId','dueDate']) field: original!.json[field],
      }));
    } catch (error) { state = TaskFormState(busy:false,error:error); }
  }
  void change(String field,Object? value) {
    state = TaskFormState(values: Map.unmodifiable({...state.values,field:value}),fields:state.fields,busy:false,revision:state.revision);
  }
  String? _validate() {
    final v = state.values;
    final title = (v['title'] as String? ?? '').trim();
    if (title.isEmpty || title.length > 200 || (v['description'] as String? ?? '').length > 10000) return 'validationError';
    final due = v['dueDate'] as String?;
    if (due != null && (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(due) || DateTime.tryParse(due)?.toIso8601String().substring(0,10) != due)) return 'validationError';
    final assignee = v['assigneeId'] as String?;
    if (assignee != null && !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$').hasMatch(assignee)) return 'validationError';
    return null;
  }
  Future<bool> save() async {
    if (state.busy) return false;
    final invalid = _validate();
    if (invalid != null) { state = TaskFormState(values:state.values,busy:false,fields:{'/title':Strings.text(invalid)}); return false; }
    final values = {...state.values,'title':(state.values['title'] as String).trim()};
    _patch = original == null ? values : {for (final e in values.entries) if (e.value != original!.json[e.key]) e.key:e.value};
    if (_patch.isEmpty) return true;
    return _send(_patch,original?.version);
  }
  Future<bool> _send(Map<String,Object?> patch,int? version) async {
    state = TaskFormState(values:state.values,busy:true);
    try {
      await ref.read(tasksRepositoryProvider).write(original == null ? 'create_task':'update_task',
        original?.id ?? idempotencyKey,original?.text('projectId') ?? key.projectId,patch,version,idempotencyKey);
      state = TaskFormState(values:state.values,busy:false);
      return true;
    } on ApiProblem catch (problem) {
      Item? latest;
      if (problem.status == 412) { await ref.read(tasksRepositoryProvider).refreshTask(key.taskId); latest = await ref.read(storeProvider).item('tasks',key.taskId); }
      state = TaskFormState(values:state.values,busy:false,error:problem,fields:problem.fields,conflict:latest);
      return false;
    } catch (error) { state = TaskFormState(values:state.values,busy:false,error:error); return false; }
  }
  Map<String,Object?> get changed => Map.unmodifiable(_patch);
  Future<bool> resolve(Set<String> keep) async {
    final latest = state.conflict!;
    original = latest;
    final patch = {for (final e in _patch.entries) if (keep.contains(e.key)) e.key:e.value};
    if (patch.isEmpty) return true;
    return _send(patch,latest.version);
  }
}
```

#### `lib/features/tasks/view_model/tasks_view_model.dart`
This feature-specific Riverpod ViewModel chooses its repository and initial query, then inherits immutable collection state and commands. It imports no generated DTO, SQL or another feature?s view.

Create or replace this file, then save it:

**File: `lib/features/tasks/view_model/tasks_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final tasksViewModelProvider = NotifierProvider.family<TasksViewModel, CollectionState, String>(TasksViewModel.new);
class TasksViewModel extends CollectionViewModel {
  TasksViewModel(String parent) : super(query('tasks',parent: parent));
  @override
  CollectionRepository get repository => ref.read(tasksRepositoryProvider);
}
```

#### `lib/features/teams/view_model/teams_view_model.dart`
This feature-specific Riverpod ViewModel chooses its repository and initial query, then inherits immutable collection state and commands. It imports no generated DTO, SQL or another feature?s view.

Create or replace this file, then save it:

**File: `lib/features/teams/view_model/teams_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final teamsViewModelProvider = NotifierProvider.family<TeamsViewModel, CollectionState, String>(TeamsViewModel.new);
class TeamsViewModel extends CollectionViewModel {
  TeamsViewModel(String parent) : super(query('teams',parent: parent));
  @override
  CollectionRepository get repository => ref.read(teamsRepositoryProvider);
}
```

### Step 10. Compose reusable presentation widgets

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/core' | Out-Null
New-Item -ItemType Directory -Force 'lib/core/widgets' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/core'
mkdir -p 'lib/core/widgets'
```

#### `lib/core/format_value.dart`
Use device-locale number/date formatting and an explicit resource label for null values instead of displaying raw UTC strings as UI.

Create or replace this file, then save it:

**File: `lib/core/format_value.dart`**
```dart
import 'dart:ui';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';

String formatValue(String key,Object? value) {
  if (value == null || value == '') return Strings.text('nullValue');
  final locale = PlatformDispatcher.instance.locale.toLanguageTag();
  if (value is num) return NumberFormat.decimalPattern(locale).format(value);
  if (key.endsWith('At') || key == 'dueDate') {
    final date = DateTime.tryParse(value.toString());
    if (date != null) return DateFormat.yMMMd(locale).format(date.toLocal());
  }
  return value.toString();
}
```

#### `lib/core/widgets/app_frame.dart`
Own safe area, app bar and Teams/Settings navigation. The durable phase adds a shared offline banner, not an eleventh screen.

Create or replace this file, then save it:

**File: `lib/core/widgets/app_frame.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/strings.dart';
import 'art_icon.dart';
import 'offline_banner.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({super.key,required this.title,required this.child,this.actions,this.floatingActionButton});
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions,automaticallyImplyLeading:false,
      leading:context.canPop() ? IconButton(tooltip:Strings.text('back'),
        onPressed:() => context.pop(),icon:ArtIcon('log-out',Strings.text('back'))) : null),
    body: SafeArea(child: Column(children: [const OfflineBanner(),Expanded(child:child)])), floatingActionButton: floatingActionButton,
    bottomNavigationBar: NavigationBar(selectedIndex: GoRouterState.of(context).uri.path.startsWith('/settings') ? 1 : 0,
      onDestinationSelected: (index) => context.go(index == 0 ? '/teams' : '/settings'),
      destinations: [
        NavigationDestination(icon: ArtIcon('team',Strings.text('teams')),label: Strings.text('teams')),
        NavigationDestination(icon: ArtIcon('settings',Strings.text('settings')),label: Strings.text('settings')),
      ]),
  );
}
```

#### `lib/core/widgets/art_icon.dart`
Draw only the copied CC0 SVG; ColorFilter recolors currentColor strokes. Supply a semantic label; interactive controls still require readable labels and large targets.

Create or replace this file, then save it:

**File: `lib/core/widgets/art_icon.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ArtIcon extends StatelessWidget {
  const ArtIcon(this.name, this.label, {super.key});
  final String name;
  final String label;
  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/icons/$name.svg',
    width: 24, height: 24, semanticsLabel: label,
    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface,BlendMode.srcIn));
}
```

#### `lib/core/widgets/collection_panel.dart`
Show loading/empty/data/error, pull-to-refresh and explicit Load more. The ViewModel checks loading/cursor state; the widget never decodes a cursor.

Create or replace this file, then save it:

**File: `lib/core/widgets/collection_panel.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import '../../l10n/strings.dart';
import '../../data/models/item.dart';
import '../api_problem.dart';
import '../collection_view_model.dart';

class CollectionPanel extends StatelessWidget {
  const CollectionPanel({super.key,required this.state,required this.refresh,required this.more,required this.tile});
  final CollectionState state;
  final Future<void> Function() refresh;
  final Future<void> Function() more;
  final Widget Function(Item) tile;
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: refresh,
    child: NotificationListener<ScrollEndNotification>(onNotification: (event) {
      if (event.metrics.extentAfter < 160) more();
      return false;
    }, child: ListView(physics: const AlwaysScrollableScrollPhysics(),padding: const EdgeInsets.all(16),children: [
      if (state.loading) const LinearProgressIndicator(),
      if (state.error != null) Text(state.error is ApiProblem ? (state.error as ApiProblem).message : Strings.text('networkError')),
      if (!state.loading && (state.page?.items.isEmpty ?? true)) Text(Strings.text('empty')),
      for (final item in state.page?.items ?? <Item>[]) tile(item),
      if (state.page?.cursor != null) TextButton(onPressed: state.loading ? null : more,child: Text(Strings.text('loadMore'))),
    ])),
  );
}
```

#### `lib/core/widgets/offline_banner.dart`
Use a live-region Semantics container, an explicit offline/pending label and formatted count, with text Sync now/queue actions. Color alone communicates nothing.

Create or replace this file, then save it:

**File: `lib/core/widgets/offline_banner.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/sync/view_model/sync_view_model.dart';
import '../../l10n/strings.dart';
import '../format_value.dart';
import 'art_icon.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final state = ref.watch(syncViewModelProvider);
    if (state.online && state.rows.isEmpty) return const SizedBox.shrink();
    final message = '${Strings.text(state.online ? 'pending' : 'offline')}: ${formatValue('count',state.rows.length)}';
    return Semantics(liveRegion:true,container:true,child: Material(
      color:Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(padding:const EdgeInsets.all(8),child:Wrap(crossAxisAlignment:WrapCrossAlignment.center,spacing:8,children: [
        ArtIcon('wifi-off',Strings.text('offline')),Text(message),
        TextButton(onPressed:state.busy ? null : ref.read(syncViewModelProvider.notifier).sync,child:Text(Strings.text('syncNow'))),
        TextButton(onPressed:() => context.push('/settings/sync'),child:Text(Strings.text('syncQueue'))),
      ])),
    ));
  }
}
```

### Step 11. Build the named feature views

Work in the app root. Create or replace these files and save their full contents.

**Terminal: app root, Windows PowerShell**
```powershell
New-Item -ItemType Directory -Force 'lib/features/login/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/projects/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/settings/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/sync/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/task_detail/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/task_form/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/tasks/view' | Out-Null
New-Item -ItemType Directory -Force 'lib/features/teams/view' | Out-Null
```

**Terminal: app root, macOS/Linux**
```bash
mkdir -p 'lib/features/login/view'
mkdir -p 'lib/features/projects/view'
mkdir -p 'lib/features/settings/view'
mkdir -p 'lib/features/sync/view'
mkdir -p 'lib/features/task_detail/view'
mkdir -p 'lib/features/task_form/view'
mkdir -p 'lib/features/tasks/view'
mkdir -p 'lib/features/teams/view'
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

#### `lib/features/projects/view/projects_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/projects/view/projects_screen.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../view_model/projects_view_model.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen(this.teamId,{super.key});
  final String teamId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = projectsViewModelProvider(teamId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title: Strings.text('projects'),child: Column(children: [
      SwitchListTile(title: Text(Strings.text('archived')),value: vm.query.archived,
        onChanged: (value) => vm.load(query('projects',parent: teamId,archived: value))),
      Expanded(child: CollectionPanel(state: state,refresh: vm.refresh,more: () => vm.refresh(next:true),
        tile: (item) => ListTile(title: Text('${item.text('key')} ${item.label}'),subtitle: Text(item.text('description')),
          onTap: () => context.push('/projects/${item.id}/tasks')))),
    ]));
  }
}
```

#### `lib/features/settings/view/settings_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/settings/view/settings_screen.dart`**
```dart
import '../../../core/widgets/art_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_problem.dart';
import '../../../core/config.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../l10n/strings.dart';
import '../view_model/settings_view_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _url = TextEditingController(text:Config.apiBase);
  String _backend = 'Python';
  bool _delete = false;
  @override
  void dispose() { _url.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);
    final account = state.value?['account'] as Map?;
    final health = state.value?['health'] as Map?;
    return AppFrame(title:Strings.text('settings'),child:ListView(padding: const EdgeInsets.all(16),children: [
      if (state.isLoading) const LinearProgressIndicator(),
      if (state.hasError) Text(state.error is ApiProblem ? (state.error as ApiProblem).message : Strings.text('queueNotEmpty')),
      DropdownButtonFormField<String>(icon:ArtIcon('list',Strings.text('backend')),initialValue:_backend,decoration:InputDecoration(labelText:Strings.text('backend')),
        items: [for (final name in const ['ASP.NET','Python','Go','customUrl']) DropdownMenuItem(value:name,child:Text(name == 'customUrl' ? Strings.text(name) : name))],
        onChanged: (value) => setState(() { _backend = value!; if (value != 'customUrl') _url.text = Config.apiBase; })),
      TextField(controller:_url,decoration:InputDecoration(labelText:Strings.text('customUrl'))),
      FilledButton(onPressed:state.isLoading ? null : () => vm.select(_backend,_url.text),child:Text(Strings.text('apply'))),
      OutlinedButton(onPressed:state.isLoading ? null : vm.test,child:Text(Strings.text('testConnection'))),
      if (health != null) ListTile(title:Text(Strings.text('health')),subtitle:Text(health.toString())),
      if (account != null) ...[
        ListTile(title:Text(Strings.text('name')),subtitle:Text(account['displayName']?.toString() ?? '')),
        for (final key in const ['roles','scopes']) ListTile(title:Text(Strings.text(key)),subtitle:Text((account[key] as List).join(', '))),
      ],
      TextButton(onPressed: () => context.push('/settings/sync'),child:Text(Strings.text('syncQueue'))),
      CheckboxListTile(value:_delete,onChanged:(value) => setState(() => _delete = value!),title:Text(Strings.text('deleteOffline'))),
      FilledButton(onPressed:state.isLoading ? null : () => vm.signOut(_delete),child:Text(Strings.text('signOut'))),
    ]));
  }
}
```

#### `lib/features/sync/view/sync_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/sync/view/sync_screen.dart`**
```dart
import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../../task_form/view/conflict_sheet.dart';
import '../view_model/sync_view_model.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final state = ref.watch(syncViewModelProvider);
    final vm = ref.read(syncViewModelProvider.notifier);
    return AppFrame(title:Strings.text('syncQueue'),child:ListView(padding:const EdgeInsets.all(16),children: [
      if (state.busy) const LinearProgressIndicator(),
      if (state.rows.isEmpty) Text(Strings.text('empty')),
      for (final row in state.rows) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children: [
        Text('${Strings.text(row.kind)} ? ${Strings.text(row.state)}'),
        Text(row.entity),
        if (row.problem != null) Text((jsonDecode(row.problem!) as Map)['title'] as String? ?? Strings.text('networkError')),
        Wrap(spacing:8,children: [
          if (row.state == 'failed' && row.kind != 'create_comment') TextButton(onPressed:() => context.push('/tasks/${row.entity}/edit'),child:Text(Strings.text('edit'))),
          if (row.state != 'conflict') TextButton(onPressed:state.busy ? null : () => vm.retry(row),child:Text(Strings.text('retry'))),
          if (row.state == 'conflict' && row.server != null) TextButton(onPressed:state.busy ? null : () async {
            final theirs = Item(Map<String,Object?>.from(jsonDecode(row.server!) as Map));
            final keep = await showConflict(context,row.body,theirs);
            if (keep != null) await vm.resolve(row,keep);
          },child:Text(Strings.text('conflict'))),
          TextButton(onPressed:state.busy ? null : () => vm.discard(row),child:Text(Strings.text('discardChain'))),
        ]),
      ]))),
    ]));
  }
}
```

#### `lib/features/task_detail/view/task_detail_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/task_detail/view/task_detail_screen.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_problem.dart';
import '../../../core/format_value.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../l10n/strings.dart';
import '../view_model/task_detail_view_model.dart';
import '../view_model/comments_view_model.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen(this.id,{super.key});
  final String id;
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}
class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _comment = TextEditingController();
  String? _error;
  @override
  void dispose() { _comment.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(detailViewModelProvider(widget.id));
    final vm = ref.read(detailViewModelProvider(widget.id).notifier);
    final comments = ref.watch(commentsViewModelProvider(widget.id));
    final commentsVm = ref.read(commentsViewModelProvider(widget.id).notifier);
    return AppFrame(title: Strings.text('taskDetail'),child: detail.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error,_) => Center(child: Text(error is ApiProblem ? error.message : Strings.text('networkError'))),
      data: (item) => item == null ? Center(child: Text(Strings.text('empty'))) : ListView(padding: const EdgeInsets.all(16),children: [
        if (item.pending) Text(Strings.text('waiting')),
        for (final key in const ['id','projectId','title','description','status','priority','assigneeId','dueDate','completedAt','createdBy','version','createdAt','updatedAt'])
          ListTile(title: Text(Strings.text(key)),subtitle: Text(formatValue(key,item.json[key]))),
        Wrap(spacing: 8,children: [
          FilledButton(onPressed: vm.complete,child: Text(Strings.text('complete'))),
          OutlinedButton(onPressed: () => context.push('/tasks/${item.id}/edit'),child: Text(Strings.text('edit'))),
        ]),
        Text(Strings.text('comments'),style: Theme.of(context).textTheme.titleLarge),
        // Comments use a shrink-wrapped panel to avoid nested infinite height.
        SizedBox(height: MediaQuery.sizeOf(context).height * .45,child: CollectionPanel(
          state: comments,refresh: commentsVm.refresh,more: () => commentsVm.refresh(next:true),
          tile: (comment) => ListTile(title: Text(comment.label),subtitle: Text(formatValue('createdAt',comment.json['createdAt'])),
            trailing: (comment.json['author'] as Map?)?['id'] == vm.callerId ? TextButton(
              onPressed: () async {
                try { await vm.delete(comment.id); } catch (_) { if (mounted) setState(() => _error = Strings.text('networkError')); }
              },child: Text(Strings.text('delete'))) : null))),
        TextField(controller: _comment,maxLength: 2000,maxLines: null,decoration: InputDecoration(labelText: Strings.text('body'))),
        if (_error != null) Text(_error!),
        FilledButton(onPressed: () async {
          try {
            if (await vm.comment(_comment.text)) { _comment.clear(); await commentsVm.refresh(); }
          } catch (error) { if (mounted) setState(() => _error = error is ApiProblem ? error.message : Strings.text('networkError')); }
        },child: Text(Strings.text('addComment'))),
      ]),
    ));
  }
}
```

#### `lib/features/task_form/view/conflict_sheet.dart`
S8 is a modal over S7. Each checkbox compares mine/theirs for one changed field. The returned keep-set selects retry fields; taking all theirs drops the patch.

Create or replace this file, then save it:

**File: `lib/features/task_form/view/conflict_sheet.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import '../../../core/format_value.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';

Future<Set<String>?> showConflict(BuildContext context,Map<String,Object?> mine,Item theirs) =>
  showModalBottomSheet<Set<String>>(context: context,isScrollControlled:true,useSafeArea:true,
    builder: (_) => ConflictSheet(mine,theirs));
class ConflictSheet extends StatefulWidget {
  const ConflictSheet(this.mine,this.theirs,{super.key});
  final Map<String,Object?> mine;
  final Item theirs;
  @override
  State<ConflictSheet> createState() => _ConflictSheetState();
}
class _ConflictSheetState extends State<ConflictSheet> {
  late final _keep = widget.mine.keys.toSet();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24),child: Column(mainAxisSize: MainAxisSize.min,children: [
    Text(Strings.text('conflict'),style: Theme.of(context).textTheme.headlineSmall),
    Text(Strings.text('conflictHelp')),
    for (final e in widget.mine.entries) CheckboxListTile(
      title: Text(Strings.text(e.key)),
      subtitle: Text('${Strings.text('mine')}: ${formatValue(e.key,e.value)}\n${Strings.text('theirs')}: ${formatValue(e.key,widget.theirs.json[e.key])}'),
      value: _keep.contains(e.key),onChanged: (value) => setState(() { if (value!) { _keep.add(e.key); } else { _keep.remove(e.key); } })),
    Wrap(spacing: 8,children: [
      FilledButton(onPressed: () => Navigator.pop(context,_keep),child: Text(Strings.text('keepMine'))),
      TextButton(onPressed: () => Navigator.pop(context,<String>{}),child: Text(Strings.text('takeTheirs'))),
    ]),
  ]));
}
```

#### `lib/features/task_form/view/task_form_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/task_form/view/task_form_screen.dart`**
```dart
import '../../../core/widgets/art_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_problem.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../l10n/strings.dart';
import '../view_model/task_form_view_model.dart';
import 'conflict_sheet.dart';

class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key,this.projectId = '',this.taskId = ''});
  final String projectId;
  final String taskId;
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final provider = formViewModelProvider((projectId:projectId,taskId:taskId));
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title:Strings.text('taskForm'),child: ListView(padding: const EdgeInsets.all(16),children: [
      if (state.busy) const LinearProgressIndicator(),
      if (state.error != null) Text(state.error is ApiProblem ? (state.error as ApiProblem).message : Strings.text('networkError')),
      for (final field in const ['title','description','assigneeId','dueDate'])
        TextFormField(key: ValueKey('$taskId$field${state.revision}'),initialValue: state.values[field] as String? ?? '',
          enabled: !state.busy,maxLines: field == 'description' ? null : 1,
          maxLength: field == 'title' ? 200 : field == 'description' ? 10000 : null,
          decoration: InputDecoration(labelText: Strings.text(field),errorText:state.fields['/$field']),
          onChanged: (value) => vm.change(field,(field == 'dueDate' || field == 'assigneeId') && value.isEmpty ? null : value)),
      for (final field in const ['status','priority'])
        DropdownButtonFormField<String>(icon:ArtIcon('list',Strings.text('status')),key:ValueKey('$field${state.revision}'),initialValue: state.values[field] as String? ?? (field == 'status' ? 'todo':'medium'),
          decoration: InputDecoration(labelText:Strings.text(field),errorText:state.fields['/$field']),
          items: [for (final value in field == 'status' ? const ['todo','in_progress','blocked','done','cancelled'] : const ['low','medium','high','urgent'])
            DropdownMenuItem(value:value,child:Text(Strings.text(value)))],
          onChanged: state.busy ? null : (value) => vm.change(field,value)),
      FilledButton(onPressed: state.busy ? null : () async {
        var saved = await vm.save();
        if (!context.mounted) return;
        final conflict = ref.read(provider).conflict;
        if (!saved && conflict != null) {
          final keep = await showConflict(context,vm.changed,conflict);
          if (keep != null) saved = await vm.resolve(keep);
        }
        if (saved && context.mounted) { if (context.canPop()) { context.pop(); } else { context.go('/teams'); } }
      },child:Text(Strings.text('save'))),
    ]));
  }
}
```

#### `lib/features/tasks/view/tasks_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/tasks/view/tasks_screen.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/art_icon.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../view_model/tasks_view_model.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen(this.projectId,{super.key});
  final String projectId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tasksViewModelProvider(projectId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title: Strings.text('tasks'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { await context.push('/projects/$projectId/tasks/new'); await vm.refresh(); },
        icon: ArtIcon('plus',Strings.text('newTask')),label: Text(Strings.text('newTask'))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(8),child: Wrap(spacing: 8,children: [
          for (final status in const ['todo','in_progress','blocked','done','cancelled'])
            FilterChip(label: Text(Strings.text(status)),selected: vm.query.statuses.split(',').contains(status),
              onSelected: (selected) {
                final statuses = vm.query.statuses.split(',').where((s) => s.isNotEmpty).toSet();
                if (selected) { statuses.add(status); } else { statuses.remove(status); }
                vm.load(query('tasks',parent: projectId,statuses: (statuses.toList()..sort()).join(','),sort: vm.query.sort));
              }),
        ])),
        DropdownButtonFormField<String>(icon:ArtIcon('list',Strings.text('sort')),initialValue: vm.query.sort,
          decoration: InputDecoration(labelText: Strings.text('sort')),
          items: [for (final entry in const {'-createdAt':'-createdAt','createdAt':'createdAtSort','dueDate':'dueDateSort'}.entries)
            DropdownMenuItem(value: entry.key,child: Text(Strings.text(entry.value)))],
          onChanged: (value) { if (value != null) vm.load(query('tasks',parent: projectId,statuses: vm.query.statuses,sort:value)); }),
        Expanded(child: CollectionPanel(state: state,refresh: vm.refresh,more: () => vm.refresh(next:true),
          tile: (item) => ListTile(title: Text(item.label),
            subtitle: Text('${Strings.text(item.text('status'))} ? ${Strings.text(item.text('priority'))}${item.pending ? ' ? ${Strings.text('waiting')}' : ''}'),
            onTap: () => context.push('/tasks/${item.id}')))),
      ]));
  }
}
```

#### `lib/features/teams/view/teams_screen.dart`
This named screen composes immutable state and delegates gestures to its ViewModel. Keep async errors explicit, use resource keys for presentation and dispose any controller/subscription it owns. No HTTP, generated DTO or SQL belongs in a view.

Create or replace this file, then save it:

**File: `lib/features/teams/view/teams_screen.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../view_model/teams_view_model.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = teamsViewModelProvider('');
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title: Strings.text('teams'),child: Column(children: [
      Padding(padding: const EdgeInsets.all(16),child: TextField(
        decoration: InputDecoration(labelText: Strings.text('search')),
        onSubmitted: (value) => vm.load(query('teams',search: value)))),
      Expanded(child: CollectionPanel(state: state,refresh: vm.refresh,more: () => vm.refresh(next:true),
        tile: (item) => ListTile(title: Text(item.label),subtitle: Text(item.text('description')),
          onTap: () => context.push('/teams/${item.id}/projects')))),
    ]));
  }
}
```

### Step 12. Wire dependencies, routes and the Material app

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
import '../core/config.dart';
import '../data/local/cache_store.dart';
import '../data/local/database.dart';
import '../data/sync/outbox_writer.dart';
import '../data/sync/sync_engine.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/collection_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/token_store.dart';
import '../data/services/api_service.dart';

final authProvider = Provider<AuthRepository>((ref) {
  final auth = AuthRepository(AuthService(), TokenStore());
  auth.acceptSubject = (subject) async {
    final store = ref.read(storeProvider);
    final previous = await store.setting('owner');
    if (previous != null && previous != subject) {
      if (await store.pendingCount() != 0) throw StateError('differentAccountQueue');
      final base = await store.setting('base_url');
      await store.clear();
      if (base != null) await store.setSetting('base_url',base);
    }
    await store.setSetting('owner',subject);
  };
  ref.onDispose(auth.dispose);
  return auth;
});
final storeProvider = Provider<CacheStore>((ref) {
  final store = AppDatabase(); ref.onDispose(store.close); return store;
});
final apiProvider = Provider<ApiService>((ref) {
  final api = ApiService(Config.apiBase,ref.watch(authProvider)); ref.onDispose(api.dispose); return api;
});
final teamsRepositoryProvider = Provider((ref) => TeamRepository(ref.watch(storeProvider),ref.watch(apiProvider)));
final projectsRepositoryProvider = Provider((ref) => ProjectRepository(ref.watch(storeProvider),ref.watch(apiProvider)));
final commentsRepositoryProvider = Provider((ref) => CommentRepository(ref.watch(storeProvider),ref.watch(apiProvider)));
final writerProvider = Provider<WriteGateway>((ref) => OutboxWriter(ref.watch(storeProvider) as AppDatabase));
final tasksRepositoryProvider = Provider((ref) => TaskRepository(ref.watch(storeProvider),ref.watch(apiProvider),ref.watch(writerProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(storeProvider),ref.watch(apiProvider)));

final syncEngineProvider = Provider((ref) => SyncEngine(ref.watch(storeProvider) as AppDatabase,ref.watch(apiProvider),ref.watch(authProvider)));
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
import '../l10n/strings.dart';
import '../features/teams/view/teams_screen.dart';
import '../features/projects/view/projects_screen.dart';
import '../features/tasks/view/tasks_screen.dart';
import '../features/task_detail/view/task_detail_screen.dart';
import '../features/task_form/view/task_form_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/sync/view/sync_screen.dart';
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
      // S1 Session check, S2 Login are above; S8 Conflict sheet is a modal over S7.
      GoRoute(path: '/teams', builder: (_, _) => const TeamsScreen()), // S3
      GoRoute(path: '/teams/:teamId/projects', builder: (_, s) => ProjectsScreen(s.pathParameters['teamId']!)), // S4
      GoRoute(path: '/projects/:projectId/tasks', builder: (_, s) => TasksScreen(s.pathParameters['projectId']!)), // S5
      GoRoute(path: '/tasks/:taskId', builder: (_, s) => TaskDetailScreen(s.pathParameters['taskId']!)), // S6
      GoRoute(path: '/projects/:projectId/tasks/new', builder: (_, s) => TaskFormScreen(projectId:s.pathParameters['projectId']!)), // S7
      GoRoute(path: '/tasks/:taskId/edit', builder: (_, s) => TaskFormScreen(taskId:s.pathParameters['taskId']!)),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()), // S9
      GoRoute(path: '/settings/sync', builder: (_, _) => const SyncScreen()), // S10
    ]);
  ref.onDispose(() { router.dispose(); refresh.dispose(); });
  unawaited(ref.read(settingsRepositoryProvider).restore().then((_) => auth.restore()));
  return router;
});
```

### Step 13. Initialize and launch the app

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
import 'data/sync/sync_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Strings.load();
  try {
    UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
    await registerSyncWorker();
    runApp(const ProviderScope(child: TasksApp()));
  } on FormatException {
    runApp(MaterialApp(home: Scaffold(body: SafeArea(
      child: Center(child: Text(Strings.text('configurationError'))),
    ))));
  }
}
```

### Step 14. Add emulator-free diagnostic tools

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

### Step 15. Regenerate instead of editing generated output
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
      "expect_stdout": "Retry in 8000 ms (before jitter)"
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
    "code/lib/data/local/database.g.dart",
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

AppDatabase implements the same cache interface as chapter 03. Indexed columns plus response snapshots retain every detail field; cached_pages retains membership/cursors. OutboxWriter commits visible data and queued operation together. An undispatched create can absorb edits, but its body freezes once delivery may have happened. SyncEngine takes a renewable lease, recovers abandoned in-flight work, drains in entity order and parks permanent/conflict rows without blocking unrelated entities. A successful create re-keys dependent data atomically. Connectivity, a foreground timer, Sync now and WorkManager request the same drain; reachability still depends on the actual request succeeding.

New terms are defined in [GLOSSARY.md](../../GLOSSARY.md). Why Riverpod rather than another DI library too? One approach already supplies both state and injection. Why repositories rather than HTTP in widgets? Replacing the source of truth should not require rewriting every screen.

Names match the Kotlin twin: S1 Session check; S2 Login; S3 Teams; S4 Projects; S5 Task list; S6 Task detail; S7 Create or edit task; S8 Conflict sheet; S9 Settings; S10 Sync queue. S8 is modal, and the offline banner is shared presentation, not an extra screen. External task links use code101-tasks-flutter://app plus an existing route; both OS delivery and intended-route restoration remain unrun manual acceptance.

Retry network/5xx and 408/425/429 failures; park most other 4xx responses. A 412 requires fetching theirs and a field-level decision, not a blind retry. Never log headers, bodies, tokens or raw AppAuth exceptions. Losing authorization must not authorize sending another subject?s preserved queue.

## Try it
Calculate exponential backoff for three previous attempts, capped at one hour. The small exercise omits jitter for readable output; the real engine adds jitter.

Copy exercise/starter to a separate work folder before editing; do not overwrite lib/main.dart. For example, from the extracted `04-offline` folder:

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
import 'dart:math';
void main() {
  const attempts = 3;
  // TODO: double a 1000 ms delay for every attempt, capped at 3600000 ms.
  print(min(attempts,10));
}
```

Edit, save, then later run `dart run main.dart` from your copied exercise folder. It uses only Dart?s standard library, not a Flutter engine or a test runner.

<details><summary>Solution</summary>

**File: `exercise/solution/main.dart`**
```dart
import 'dart:math';
void main() {
  const attempts = 3;
  final delay = min(3600000,1000 * (1 << min(attempts,10)));
  print('Retry in $delay ms (before jitter)');
}
```

This implements the one requested rule, not platform integration. Expected output (final exercise delivery not yet run):

```text
Retry in 8000 ms (before jitter)
```

</details>

## Check yourself
1. Why a transaction for cache and outbox?
   <details><summary>Answer</summary>A crash must not separate the local change from its delivery record.</details>

2. Why block later writes for one failed entity?
   <details><summary>Answer</summary>They depend on its earlier writes and versions; other entities can continue.</details>

3. When may a create body be merged?
   <details><summary>Answer</summary>Only before any dispatch may have occurred.</details>

4. Is connectivity proof of API reachability?
   <details><summary>Answer</summary>No; transport failures still need backoff.</details>

5. Why a cross-isolate refresh lock?
   <details><summary>Answer</summary>A background isolate does not share the foreground Future.</details>

## Common mistakes
These excerpts were **actually captured before executable work was stopped**. Reproduction actions are for a later authorized session, not a new verification claim.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Expected to find project root in current working directory.` | The author deliberately ran flutter pub get in the capstone documentation folder. | Change to this phase?s code folder or your app workspace; inspect the prompt. |
| `PathNotFoundException: Cannot open file, path = 'config/missing.json'` | Captured by running `dart run tool/url_probe.dart config/missing.json`. This is a path error, not failed login. | Use the exact shipped configuration path and save it before running. |
| `FormatException: Use HTTPS, or a debug-only loopback host.` | Captured with `dart run tool/url_probe.dart --release` against dev.json. | Release rejects HTTP deliberately; use a real HTTPS release configuration, not a broader exception. |
| `Expected a column name (got keyword KEY, try wrapping it in double quotes to escape it).` | The author generated drift from an unquoted key column. | Keep `"key"` quoted in schema.drift, regenerate parts, then analyze before building later. |

## Best practice
Coordinate local and remote data in repositories and state the actual durability/retry policy. Source: [Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) (Tier 1).

Also keep [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) checks manual: defaults and a passing analyzer do not prove a usable screen. Package behavior is pinned/sourced in VERSION-NOTES.md. No outside art is used.

## Next lesson
05. Build, run and ship: separate building from device acceptance and real signing.
