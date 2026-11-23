---
track: kotlin
level: 101
phase: 1
phase_name: kotlin-basics
lesson: 01
title: Install Android Studio and run your first Kotlin program
time: 75-90 min (most of it is downloading)
prerequisites: [none]
versions: { android-studio: "latest stable", kotlin: "2.4.21", gradle: "9.6.0" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/01-install-and-first-program/
assets: []
---

# 01. Install Android Studio and run your first Kotlin program

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- install Android Studio and explain what it is for;
- open a project folder and create files in it;
- write and run a Kotlin program that prints two lines;
- read the Run window to see whether the program worked.

## Recap
None, this is the start. You need no coding experience.

## Why it matters
Think of cooking. A **recipe** is a list of instructions, a **kitchen** is the place where you follow it, and the **cook** does the work. In this course the recipe is a **program** written in the **Kotlin** language, the kitchen is **Android Studio**, and the cook is your computer. Before you can bake anything you need a kitchen that works, so this lesson installs it and makes one tiny dish.

## What you will build
A project called `KotlinBasics` that prints two lines of text. You will reuse this same project in lessons 02 to 04.

```text
Hello, Kotlin!
I can write a program.
```

## Before you start
- A Windows, macOS or Linux computer with internet and several gigabytes of free disk space. Check the current system requirements on the download page: https://developer.android.com/studio
- Time: about 75 to 90 minutes the first time. The downloads are large; you can read ahead while they run.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/01-install-and-first-program/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

New words in this lesson: IDE, Android Studio, SDK, Gradle, project, folder, file, Kotlin, program, function, string, Run window.

## Steps

### Step 1. Download Android Studio
Open https://developer.android.com/studio in a browser and press the download button for your system. Read and accept the terms the page shows. An **IDE** (integrated development environment) is one program that combines a text editor, a helper that checks your code, and buttons to run it. **Android Studio** is the official IDE for Android; it also runs plain Kotlin programs, which is how we start.

Expected result: an installer file is in your Downloads folder (a `.exe` on Windows, a `.dmg` on macOS, a `.tar.gz` on Linux).

### Step 2. Install it
Pick your system. Button names can differ slightly between releases; follow the installer's own text if it differs.

- **Windows:** double-click the `.exe`. If Windows asks whether to allow the app to make changes, choose **Yes**. Keep the default options and press **Next**, then **Install**, then **Finish** with **Start Android Studio** ticked.
- **macOS:** double-click the `.dmg`, then drag **Android Studio** onto **Applications**. Open it from Applications; if macOS asks whether you are sure, choose **Open**.
- **Linux:** extract the archive (for example `tar -xzf android-studio-*.tar.gz` in your Downloads folder), then run `bin/studio.sh` inside the extracted `android-studio` folder. The official page lists any extra libraries a 64-bit system may need.

### Step 3. Complete the first-run wizard
On first start Android Studio may ask whether to import settings: choose **Do not import settings**. The **Setup Wizard** then offers an install type: choose **Standard**. Pick a colour theme you like, press **Next**, read the summary, and accept the license agreements (each listed item must be accepted). Press **Finish**. The wizard downloads the **SDK** (software development kit: the Android tools and libraries; we need it from lesson 05). This can take 10 to 30 minutes.

Expected result: the **Welcome to Android Studio** window with the buttons **New Project** and **Open** (the exact list varies a little by version).

### Step 4. Create an empty project folder
Android Studio's **New Project** wizard builds Android apps. We want something simpler first, so we make the folder ourselves.

1. Open your file manager and go to **Documents**.
2. Create a folder `code101`, and inside it a folder `kotlin-basics`.

A **folder** (also called a directory) is a container for files. The full name of this folder on Windows looks like `C:\Users\<you>\Documents\code101\kotlin-basics`.

### Step 5. Open the folder in Android Studio
On the Welcome window press **Open**, select the `kotlin-basics` folder, and press **OK** (on macOS **Open**). If a dialog asks whether you trust the project, choose **Trust Project**: it is your own empty folder.

Expected result: the main window opens with the **Project** tool window on the left showing `kotlin-basics` with nothing inside. If the left panel is hidden press **Alt+1** (Windows, Linux) or **Cmd+1** (macOS). At the top of that panel there is a drop-down; choose **Project** (not **Android**), so you see real folders.

### Step 6. Create the build files
A **project** is a folder with your code plus instructions for building it. **Gradle** is the tool that reads those instructions, downloads what is needed and builds the project. Five small text files describe our project.

Right-click `kotlin-basics` in the Project panel, choose **New > File**, type the file name, press **Enter**, and paste the content. If Studio will not accept a name with a slash, create the folder first with **New > Directory**.

**File: `settings.gradle.kts`**
```kotlin
pluginManagement {
    repositories {
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}
rootProject.name = "KotlinBasics"
```
- `pluginManagement { repositories { ... } }` tells Gradle where to download its plugins (add-ons for the build).
- `dependencyResolutionManagement` tells Gradle where to download libraries your code uses (none yet).
- `mavenCentral()` and `gradlePluginPortal()` are two big public download places.
- `rootProject.name` is the project's name.

**File: `build.gradle.kts`**
```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlin.jvm)
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}
```
- `import ...JvmTarget` lets us write `JvmTarget` instead of its long name.
- `plugins { alias(...) }` switches on the Kotlin plugin, so Gradle can compile `.kt` files. `libs.plugins.kotlin.jvm` is defined in the next file.
- `java { ... VERSION_17 }` and `jvmTarget.set(JvmTarget.JVM_17)` say "produce code that runs on Java 17 or newer". Both lines must agree, otherwise Gradle complains about a mismatch.

**File: `gradle/libs.versions.toml`** (a **version catalog**: one place that lists tool versions)
```toml
[versions]
kotlin = "2.4.21"

[plugins]
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
```
- `[versions]` names a version once. `[plugins]` defines `kotlin-jvm`, which `build.gradle.kts` reaches as `libs.plugins.kotlin.jvm` (dashes become dots).

**File: `gradle.properties`**
```properties
org.gradle.jvmargs=-Xmx1g -Dfile.encoding=UTF-8
kotlin.code.style=official
```
- The first line gives Gradle 1 GB of memory and UTF-8 text. The second tells Kotlin tools to use the official code style.

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
- `distributionUrl` pins the Gradle version (9.6.0) the project uses, so every computer builds the same way. Android Studio downloads it for you the first time; it stores it in your user folder (`GRADLE_USER_HOME`).
- The other lines are the standard wrapper settings: where to keep the download, a 10 second network timeout, and a check that the address is an official one.
- A normal Gradle project also holds the files `gradlew`, `gradlew.bat` and `gradle-wrapper.jar`. We do not type those: Android Studio creates them if you ask (Gradle tool window, **Tasks > build setup > wrapper**), and you do not need them to run from the IDE.

**File: `.gitignore`** (lists files that a version-control tool must not store; it also keeps the folder tidy)
```text
.gradle/
build/
.idea/
local.properties
*.hprof
```
- `.gradle/` and `build/` are folders Gradle creates; `.idea/` holds Studio settings; `local.properties` will hold your own machine paths (Android Studio creates it from lesson 05 on, never share it).

### Step 7. Let Gradle load the project
After the files exist Android Studio shows a banner such as **Load Gradle Project** or **Sync Now**, or an elephant icon in the toolbar (**Sync Project with Gradle Files**). Click it. The first sync downloads Gradle 9.6.0, the Kotlin plugin and libraries; this needs internet and can take several minutes. Watch the **Build** tool window at the bottom.

Expected result: the Build window ends with a green check or the words **BUILD SUCCESSFUL** (wording can vary). If it ends in red, read **Common mistakes** below.

### Step 8. Write your first program
1. Right-click `kotlin-basics` and choose **New > Directory**. Type `src/main/kotlin/lesson01` and press **Enter**. After a sync, Studio shows `src/main/kotlin` as a source folder (the folder where Kotlin code lives).
2. Right-click the `lesson01` folder and choose **New > File**. Name it `Hello.kt`. The ending `.kt` marks a Kotlin file.
3. Type the following (typing, not pasting, helps you remember; when Studio suggests completions, press **Tab**):

**File: `src/main/kotlin/lesson01/Hello.kt`**
```kotlin
package lesson01

fun main() {
    println("Hello, Kotlin!")
    println("I can write a program.")
}
```

Predict before you run: how many lines will the program print, and in which order?

## Run it
Look at the left edge of the editor, next to the line `fun main() {`: there is a green triangle. Click it and choose **Run 'HelloKt'** (the name may show slightly differently). The first run builds the project, so give it a minute.

Expected output in the **Run** window at the bottom (the window that shows what your program prints):
```text
Hello, Kotlin!
I can write a program.
```
Studio may also print build messages around these lines and a closing line such as `Process finished with exit code 0`. Exit code 0 means "no problem". Only the two program lines are your program's own output.

If the Run window shows an error instead, you have an everyday problem, not a broken computer. Continue with the **Common mistakes** table.

## How it works
Read the program from top to bottom:
- `package lesson01` says which group of code this file belongs to. The folder name `lesson01` and the package name match; that is the Kotlin convention.
- `fun main()` defines a **function**, a named block of instructions. A function called `main` is the **entry point**: the place where the computer starts running a program.
- The curly braces `{ }` hold the instructions of the function. Each instruction sits on its own line.
- `println("Hello, Kotlin!")` calls a ready-made function called `println`. It prints what is inside the brackets and starts a new line (the `ln` stands for "line").
- `"Hello, Kotlin!"` is a **string**: text between double quotes.

Behind the green triangle three things happened. Gradle (the build tool) compiled your `.kt` file, that means translated it into a form the computer understands; then Java's runtime started it; then the printed text appeared in the Run window.

A common misconception: the quotes are not printed. They only mark where the text starts and ends.

## Try it
Work in the same project; you do not need a new one.
1. **Guided:** create a new file `src/main/kotlin/exercise01/Recipe.kt` (new directory `src/main/kotlin/exercise01` first). Start from this starter:

**File: `src/main/kotlin/exercise01/Recipe.kt`**
```kotlin
package exercise01

fun main() {
    // TODO 1: print the line "Recipe: tea"
    // TODO 2: print the line "1. Heat water."
    // TODO 3: print the line "2. Add tea and water to a cup."
}
```
Replace each `// TODO` comment (a comment is a note for people that the computer ignores) by one instruction. Run it. Expected output:
```text
Recipe: tea
1. Heat water.
2. Add tea and water to a cup.
```
2. **Change:** make the card describe a recipe you know with at least three steps.
3. **Stretch (optional):** what happens if you remove the second `println` line and run again? What if you swap two lines? Write down your guess before you try.

<details><summary>Solution</summary>

**File: `src/main/kotlin/exercise01/Recipe.kt`**
```kotlin
package exercise01

fun main() {
    println("Recipe: tea")
    println("1. Heat water.")
    println("2. Add tea and water to a cup.")
}
```
Each TODO becomes one `println` call. The text inside the quotes is exactly what appears.

</details>

## Check yourself
1. What is the difference between Kotlin and Android Studio? <details><summary>Answer</summary>Kotlin is the language you write in. Android Studio is the program (IDE) in which you write, build and run it.</details>
2. What does `println("Hi")` print, and what do the quotes do? <details><summary>Answer</summary>It prints `Hi` and moves to a new line. The quotes only mark the start and end of the text.</details>
3. A friend's green triangle is missing next to `fun main()`. Name two things to check. <details><summary>Answer</summary>That the file is inside `src/main/kotlin` and that Gradle sync finished without red errors.</details>
4. What is Gradle's job? <details><summary>Answer</summary>It reads the build files, downloads what is needed and compiles and runs the project.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unresolved reference 'printn'` (typical message; the name matches what you typed) | A name is misspelled, for example `printn` instead of `println` | Fix the spelling; names are case sensitive, so `Println` is also wrong |
| Red underline and a message about a missing quote or an unclosed string (typical) | A closing `"` is missing | Add the missing quote at the end of the text |
| No green triangle beside `fun main()` | The file is not in `src/main/kotlin`, or the Gradle sync has not finished | Move the file into the right folder and sync again |
| The Build window shows `Could not resolve` or `Could not GET` lines (typical) | No internet connection or a blocking proxy while Gradle downloads | Connect to the internet and press the sync button again |
| Sync fails with a message about an unsupported Java or Gradle version (typical) | The Gradle JDK setting points to a JDK older than 17 | In **Settings > Build, Execution, Deployment > Build Tools > Gradle** set **Gradle JDK** to the embedded JetBrains Runtime that comes with Studio |

## Best practice
Use lowercase package names without underscores and four spaces for each indentation level, and let the IDE format your code. Source: Kotlin coding conventions https://kotlinlang.org/docs/coding-conventions.html

## Going further
- Try the same program in the browser at https://play.kotlinlang.org (nothing to install) to see that Kotlin itself is the same everywhere.
- The Android Studio user guide: https://developer.android.com/studio/intro

## Summary
- You installed Android Studio and finished its setup wizard.
- You created a project from five small text files and let Gradle load it.
- You wrote `Hello.kt` and ran its `main` function to print two lines.
- You read the Run window and know that exit code 0 means success.

## Next lesson
02. Variables, types and null safety: storing values with names, and what to do when a value might be missing.
