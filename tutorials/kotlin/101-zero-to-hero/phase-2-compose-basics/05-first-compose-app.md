---
track: kotlin
level: 101
phase: 2
phase_name: compose-basics
lesson: 05
title: Your first Compose app
time: 90-120 min (two sittings are fine; break after Step 7)
prerequisites: [01, 02, 03, 04]
versions: { android-gradle-plugin: "9.5.1", kotlin: "2.4.21", gradle: "9.6.0", compose-bom: "2026.11.01", activity-compose: "1.13.0", compileSdk: "37", minSdk: "26" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-2-compose-basics/05-first-compose-app/
assets: []
---

# 05. Your first Compose app

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- create an Android project from its files and let Gradle build it;
- explain what an Android app, an activity and a composable function are;
- run the app on an emulator or a real phone;
- write and preview a composable function that shows text.

## Recap
1. What does a `data class` give you that a normal class does not? <details><summary>Answer</summary>A readable `toString()`, content-based `==` and `copy(...)`.</details>
2. How do you pass a lambda to `filter`? <details><summary>Answer</summary>In braces after the function: `list.filter { it > 3 }`.</details>

## Why it matters
Until now the output was text in a window. An Android app draws a screen. **Jetpack Compose** is Android's modern way to describe a screen: you write functions that say what the screen should show ("a title, then a list"), and Compose draws it. Think of a floor plan drawn by an architect: you describe the rooms, the builder does the work.

## What you will build
An app called **Tasks Start** that shows one line, "Hello, Tasks!", on a phone. It is small on purpose: every file of a real Android project appears here once, so later lessons only change a few of them.

## Before you start
- Android Studio installed (lesson 01) and internet for downloads.
- Time: 90 to 120 minutes, mostly downloads and typing the project files. Take a break after Step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-2-compose-basics/05-first-compose-app/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`). If you use the pack, open its `code` folder and skip to Step 5.

New words: Android app, activity, manifest, resource, composable function, `@Composable`, `Modifier`, `Scaffold`, preview, emulator, AVD, theme, `strings.xml`.

## Steps

### Step 1. Make and open the project folder
Create `Documents/code101/tasks-start`. In Android Studio choose **File > Open** and select that folder (use **Trust Project**). In the Project panel choose the **Project** view in the drop-down, as in lesson 01.

### Step 2. The settings file
Create the files below with right-click **New > File** (type a path with slashes to create folders; if Studio refuses, create the folder first with **New > Directory**).

**File: `settings.gradle.kts`**
```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "TasksStart"
include(":app")
```
- `google()` is Google's download place, where the Android plugin and Compose live. `mavenCentral()` and `gradlePluginPortal()` are the public ones from lesson 01.
- `FAIL_ON_PROJECT_REPOS` makes Gradle refuse download places declared anywhere else, so every download place is in this one file.
- `include(":app")` says the project has one **module** (a part that builds on its own) named `app`.

### Step 3. The root build file, versions and properties
**File: `build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
```
- This file only names the plugins; `apply false` means "make them known, but use them in the `app` module".

**File: `gradle/libs.versions.toml`**
```toml
[versions]
agp = "9.5.1"
kotlin = "2.4.21"
compose = "2026.11.01"
activity = "1.13.0"

[libraries]
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "compose" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activity" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```
- `agp` is the **Android Gradle Plugin**: the add-on that knows how to build Android apps. Version 9.5.1 needs Gradle 9.6.0 (set in the wrapper file below) and Java 17 or newer.
- `compose-bom` is a **BOM** (bill of materials): one version number that fixes matching versions for all Compose libraries, so you never mix incompatible ones. The libraries that follow it have no version of their own.
- `kotlin-compose` is the **Compose compiler plugin**; its version always equals the Kotlin version.
- `activity-compose` connects Compose to an Android screen.

**File: `gradle.properties`**
```properties
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.builtInKotlin=true
```
- `-Xmx2g` gives Gradle 2 GB of memory.
- `android.useAndroidX=true` uses the current Android support libraries (AndroidX).
- `android.builtInKotlin=true`: with AGP 9 the Android plugin compiles Kotlin itself, so the old `org.jetbrains.kotlin.android` plugin is not used.

**File: `gradle/wrapper/gradle-wrapper.properties`**
```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.6.0-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```
Identical to lesson 01 (it pins Gradle 9.6.0). Android Studio creates `gradlew`, `gradlew.bat` and the wrapper jar for you; do not copy them from anywhere.

**File: `.gitignore`**
```text
.gradle/
build/
.idea/
local.properties
*.hprof
*.apk
*.aab
```
Same as lesson 01 plus two finished-app types. `local.properties` holds the path of the SDK on your machine; Android Studio creates it by itself, and you never share it.

### Step 4. The app module build file
**File: `app/build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.code101.taskstart"
    compileSdk { version = release(37) }

    defaultConfig {
        applicationId = "com.code101.taskstart"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
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
    debugImplementation(libs.compose.ui.tooling)
}
```
- `namespace` is the name Kotlin code uses for generated things such as `R` (resources). `applicationId` is the unique name of the installed app on a phone.
- `compileSdk` is the Android version the code is built against (37 here). `minSdk = 26` is the oldest Android (8.0) that may install the app; `targetSdk = 36` is the version the app declares it was tested for.
- `buildFeatures { compose = true }` switches Compose support on.
- `implementation(platform(libs.compose.bom))` imports the BOM; the next lines add Compose libraries. `debugImplementation` adds the preview tooling only to debug builds, not to a release.
- A note for later: the finished capstone project writes `release(37) { minorApiLevel = 2 }` because the author installed platform 37.2; you only need the Android 37 platform that your SDK Manager offers.

### Step 5. The manifest and the text resources
Create the folders `app/src/main/res/values` and then the files.

**File: `app/src/main/AndroidManifest.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="false"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```
The **manifest** is the app's ID card for Android.
- `<application>` describes the app: `allowBackup="false"` keeps its data out of cloud backups; `label` is the name under the icon (taken from `strings.xml`, below); `theme` is the window style.
- `<activity>` declares one **activity**, a screen entry point. `.MainActivity` means the class `MainActivity` in the package of the namespace. `exported="true"` lets the launcher start it.
- The **intent-filter** with `MAIN` and `LAUNCHER` marks it as the activity that starts when the user taps the app icon.
- There is no icon line, so Android shows its default icon.

**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="greeting">Hello, %1$s!</string>
</resources>
```
A **resource** is a file that is not code, such as text or pictures. Texts belong here so that they can be translated later. `%1$s` is a **placeholder**: the first value (`1`) is inserted as a string (`s`).

### Step 6. The theme and the activity
Create the folders `app/src/main/kotlin/com/code101/taskstart/ui/theme`.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/theme/Theme.kt`**
```kotlin
package com.code101.taskstart.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

@Composable
fun TasksTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) darkColorScheme() else lightColorScheme(),
        content = content,
    )
}
```
- `@Composable` marks a function that draws part of the screen.
- `isSystemInDarkTheme()` asks the phone whether dark mode is on, so the app follows it.
- `MaterialTheme` hands colours and text styles to everything inside it (`content`). **Material 3** is Google's design system.

**File: `app/src/main/kotlin/com/code101/taskstart/MainActivity.kt`**
```kotlin
package com.code101.taskstart

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.ui.theme.TasksTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TasksTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        name = "Tasks",
                        modifier = Modifier.padding(innerPadding),
                    )
                }
            }
        }
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.greeting, name),
        modifier = modifier,
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    TasksTheme {
        Greeting(name = "Preview")
    }
}
```

### Step 7. Sync, then check the SDK
Click **Sync Now** (or the elephant icon). The first sync downloads Gradle 9.6.0, the Android plugin and Compose libraries: expect several minutes.

If the Build window says that an SDK platform is missing (typical wording: a license or "failed to find Platform SDK with path: platforms;android-37"), click the link it offers to install it, or open **Settings > Languages & Frameworks > Android SDK > SDK Platforms**, tick **Android 37** (the entry may show the newest 37.x), press **Apply** and accept the license. Android Studio then writes `local.properties` for you.

If Studio says your Android Studio version is too old for Android Gradle Plugin 9.5.1, use **Help > Check for Updates**. The compatibility table is in the official release notes: https://developer.android.com/build/releases/agp-9-5-0-release-notes

Expected result: the Build window finishes without red errors. **Break point:** you can stop here and continue later.

### Step 8. Create an emulator
An **emulator** is a pretend phone that runs on your computer. Open **View > Tool Windows > Device Manager**, press **+** (**Create Virtual Device**), choose a **Phone** such as a Pixel model, press **Next**, pick a recent system image (download it if it shows a download arrow; it is large), press **Next** and **Finish**. An **AVD** (Android Virtual Device) is the saved emulator.

If the emulator refuses to start, your computer may need hardware virtualization switched on (BIOS) or a Windows feature; the official guide is https://developer.android.com/studio/run/emulator-acceleration. You can use a real phone instead: on the phone open **Settings > About phone**, tap **Build number** seven times, then **Settings > System > Developer options > USB debugging**, connect with a USB cable and accept the "Allow USB debugging" prompt.

Predict before you run: where on the screen will the text appear, and why do you think `innerPadding` is used?

## Run it
Choose the device in the drop-down at the top (**app** next to it), then press the green **Run** triangle. The first build takes a few minutes; the emulator starts and installs the app.

Expected result (described, not yet seen): a white screen (or dark, if the phone is in dark mode) with the text **Hello, Tasks!** near the top, below the status bar.

To see the screen without running, open `MainActivity.kt`, choose **Split** at the top right of the editor, and press **Build & Refresh** if shown: the **Preview** pane shows `GreetingPreview`, with the text "Hello, Preview!".

## How it works
**Activity.** Android starts your app by creating `MainActivity`, a subclass of `ComponentActivity`. `onCreate` runs once when the screen is created. `super.onCreate(...)` lets Android do its own set-up first. `enableEdgeToEdge()` lets your content draw behind the system bars.

**`setContent`.** Everything inside `setContent { ... }` is Compose. `TasksTheme { ... }` applies your colours. `Scaffold` is a ready layout frame (later it holds a top bar and a button). It passes `innerPadding`, the room that the system bars need, so your content is not hidden behind them.

**Composable functions.** `Greeting` is a function marked `@Composable`. It does not return text; it **emits** a piece of the screen (`Text`). A composable can call other composables, and the result is a tree. Names of composables start with a capital letter, by convention.

**Modifier.** A `Modifier` is a chain of small decorations: size, spacing, clicks. `Modifier.fillMaxSize()` makes the Scaffold as big as the screen; `Modifier.padding(innerPadding)` adds the space. A composable usually takes `modifier: Modifier = Modifier` as a parameter, so its caller can place it.

**Resources.** `stringResource(R.string.greeting, name)` reads the text from `strings.xml` and fills in the `%1$s` placeholder. `R` is a class that Android generates with an entry for every resource.

**Preview.** `@Preview` lets Android Studio draw a composable without running the app. A misconception: the preview is not the real app; it cannot run the activity, only the composable you mark.

## Try it
1. **Guided:** in your project replace `MainActivity.kt` by this starter and `strings.xml` by the one below, then finish the two TODOs. The new `Column` stacks its children vertically.

**File: `app/src/main/kotlin/com/code101/taskstart/MainActivity.kt`**
```kotlin
package com.code101.taskstart

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.ui.theme.TasksTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TasksTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Column(modifier = Modifier.padding(innerPadding).padding(16.dp)) {
                        Greeting(name = "Tasks")
                        // TODO 1: call Subtitle with the text stringResource(R.string.subtitle)
                    }
                }
            }
        }
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.greeting, name),
        modifier = modifier,
    )
}

// TODO 2: write @Composable fun Subtitle(text: String) that shows the text with MaterialTheme.typography.bodyLarge

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    TasksTheme {
        Greeting(name = "Preview")
    }
}
```

**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="greeting">Hello, %1$s!</string>
    <string name="subtitle">Your tasks, in one place.</string>
</resources>
```
Expected screen: "Hello, Tasks!" and, below it, "Your tasks, in one place.". (`MaterialTheme` needs an import, which Studio offers with **Alt+Enter**.)
2. **Change:** pass your own name to `Greeting` and change the `subtitle` text.
3. **Stretch (optional):** turn the phone's dark mode on and off in the emulator settings and watch the colours follow. Where in the code does that happen?

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/MainActivity.kt`**
```kotlin
package com.code101.taskstart

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.ui.theme.TasksTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TasksTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Column(modifier = Modifier.padding(innerPadding).padding(16.dp)) {
                        Greeting(name = "Tasks")
                        Subtitle(text = stringResource(R.string.subtitle))
                    }
                }
            }
        }
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.greeting, name),
        modifier = modifier,
    )
}

@Composable
fun Subtitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = MaterialTheme.typography.bodyLarge,
        modifier = modifier,
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    TasksTheme {
        Greeting(name = "Preview")
    }
}
```
`Subtitle` is one more composable function; `Column` places the two texts one under the other. The dark-mode switch happens in `TasksTheme`, through `isSystemInDarkTheme()`.

</details>

## Check yourself
1. What is the job of the manifest? <details><summary>Answer</summary>It tells Android about the app: its name, its activities and which one starts from the launcher.</details>
2. Why are texts kept in `strings.xml` and not typed in code? <details><summary>Answer</summary>So they can be translated and changed in one place.</details>
3. What does `@Composable` mean on a function? <details><summary>Answer</summary>The function describes part of the screen and may only be called from other composable functions or from `setContent`.</details>
4. Predict: what happens to the text if you remove `Modifier.padding(innerPadding)`? <details><summary>Answer</summary>The text moves under the status bar at the top and may be partly hidden.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Red `R` (`Unresolved reference 'R'`, typical) | Resources not generated yet, or a wrong `namespace` | Sync Gradle; check `namespace` equals the package of your Kotlin files |
| A message that a platform or SDK component is missing (typical) | The Android 37 platform is not installed | Install it in **SDK Manager** (Step 7) |
| Sync error about the Android Gradle Plugin and the Studio version (typical) | Android Studio is older than AGP 9.5.1 needs | Update Android Studio, then sync again |
| `Unresolved reference` on a Compose name | A missing `import` | Press **Alt+Enter** on the red name and choose the import |
| `@Composable invocations can only happen from the context of a @Composable function` (typical) | A composable was called from a normal function | Make the caller `@Composable`, or call it inside `setContent` |
| The emulator does not start | Virtualization is off or no system image is installed | Follow the acceleration guide in Step 8, or use a real phone |

## Best practice
Give every composable a `modifier: Modifier = Modifier` parameter as its first optional parameter, and keep texts in resources. Source: Compose API guidelines https://github.com/androidx/androidx/blob/androidx-main/compose/docs/compose-api-guidelines.md and Android resources overview https://developer.android.com/guide/topics/resources/providing-resources

## Going further
- Jetpack Compose basics course: https://developer.android.com/develop/ui/compose/documentation
- Thinking in Compose: https://developer.android.com/develop/ui/compose/mental-model

## Summary
- You created an Android project from its files and synced it with Gradle.
- You explained the manifest, an activity, a resource and a composable function.
- You ran (or previewed) a Compose screen.
- You added a second composable in the exercise.

## Next lesson
06. Layouts and Material 3: rows, columns, cards, buttons, and icons that you convert from the course art library.
