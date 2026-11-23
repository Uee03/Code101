---
track: flutter
level: 101
phase: 1
phase_name: first-app
lesson: "01"
title: "Install Flutter and the Android toolchain, create and run a first app"
time: "90-120 min"
prerequisites: [none]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", android_studio: "current stable" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-1-first-app/01-install-and-first-app/
assets: []
---

# 01. Install Flutter and the Android toolchain, create and run a first app

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Install the Flutter SDK and Android Studio and check them with `flutter doctor`.
- Create a Flutter project, run it on an emulator or a phone and change it while it runs.
- Explain what a widget is and name the three parts of the smallest Flutter app.

## Recap
None, this is the start of the Flutter track. If you finished Python 101 or C# 101 you already know what a terminal, a folder and a source file are; this lesson explains them again briefly anyway.

## Why it matters
Think of Flutter as a box of building blocks and Android as the table you build on. Before you can build, the blocks (the Flutter SDK) and the table's rulebook (the Android SDK) must be on your computer. Do this once, carefully, and every later lesson starts with one command.

## What you will build
An app that shows the words "Hello, Flutter!" on a phone screen, running on an Android emulator (a pretend phone inside your computer) or on your own phone. It is small on purpose: the goal is a working toolchain.

## Before you start
- A computer with Windows 10 or 11, macOS or Linux, about 15 GB of free disk space, and an internet connection. 8 GB of memory is enough, 16 GB is more comfortable for the emulator.
- No programming experience is needed.
- Time: 90-120 minutes for a first-timer. Most of it is downloading. Break after Step 5 (installation done) and start again at Step 6.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-1-first-app/01-install-and-first-app/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Versions used: Flutter 3.50.1 with Dart 3.14.0. A newer stable Flutter may print slightly different text; the steps stay the same.

**Terms used in this lesson.** A **terminal** is a window where you type commands and read the replies. A **command** is one instruction you type, then press Enter. The **current folder** is the folder a command works in; the prompt (the text before your cursor) usually shows it. An **SDK** (software development kit) is a bundle of tools for building one kind of software. **Dart** is the programming language Flutter apps are written in. **Flutter** is the toolkit that draws the screen. A **widget** is one building block of the screen: a piece of text, a button, a row. An **emulator** is a pretend phone that runs on your computer.

## Steps
### Step 1. Open a terminal
Windows: press the Windows key, type **PowerShell**, press Enter. macOS: open **Applications > Utilities > Terminal**. Linux: open **Terminal** from your applications menu.

Type only the command, never the prompt or the code fences. You will keep this terminal for the whole lesson. After any installation below, close it and open a new one: old terminals do not see newly installed programs.

### Step 2. Install Git
Flutter needs Git, a tool that downloads and tracks source code. Windows: install **Git for Windows** from https://git-scm.com/downloads/win and accept the default choices. macOS: run `xcode-select --install` in the terminal and click **Install** in the dialog. Linux (Ubuntu or Debian): run the commands from the official page https://docs.flutter.dev/install/manual (they also install `curl`, `unzip`, `xz-utils`, `zip` and `libglu1-mesa`).

Check it. Close the terminal, open a new one and type:

**File: `terminal (any folder)`**
```text
git --version
```
Expected result: one line that starts with `git version`, then a number. If the terminal says the command is not found, Git is not installed or the terminal is old; reopen it.

### Step 3. Install Android Studio
Android Studio is the official Android tool. You need it for the Android SDK (the Android tools Flutter builds with) and for the emulator. You can also write your Dart code in it.

1. Open https://developer.android.com/studio and download the installer for your system.
2. Run the installer and accept the defaults.
3. Start Android Studio. The first-run wizard offers a **Standard** installation: choose it. It downloads the Android SDK. Wait until it finishes (several minutes).
4. On the welcome screen open **More Actions** (or **Customize** in some versions), then **SDK Manager**. On the **SDK Tools** tab tick **Android SDK Command-line Tools (latest)** and click **Apply**, then **OK**. Flutter needs these command-line tools to accept Android's licences.
5. Still in Android Studio open **Plugins** (File > Settings > Plugins on Windows and Linux, Android Studio > Settings > Plugins on macOS), search for **Flutter** on the **Marketplace** tab, click **Install** and accept the Dart plugin it asks for. Restart Android Studio when asked.

Menu names change a little between Android Studio versions. If a name differs, look for the same word in the nearest menu or the search field.

### Step 4. Install the Flutter SDK
Follow the official page https://docs.flutter.dev/install/manual. In short:

1. Download the stable bundle for your system from the **Flutter SDK archive** (https://docs.flutter.dev/install/archive). This course uses 3.50.1.
2. Create a folder without spaces or special characters, for example `develop` in your home folder.
3. Extract the bundle into it. Windows PowerShell (adjust the file name to the version you downloaded):

**File: `terminal (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\develop"
Expand-Archive -Path "$env:USERPROFILE\Downloads\flutter_windows_3.50.1-stable.zip" -DestinationPath "$env:USERPROFILE\develop"
```

macOS and Linux (adjust the file name; macOS uses `.zip`, Linux uses `.tar.xz`):

**File: `terminal (macOS)`**
```bash
mkdir -p ~/develop
unzip ~/Downloads/flutter_macos_arm64_3.50.1-stable.zip -d ~/develop/
```

**File: `terminal (Linux)`**
```bash
mkdir -p ~/develop
tar -xf ~/Downloads/flutter_linux_3.50.1-stable.tar.xz -C ~/develop/
```

4. Add Flutter to your **PATH**. The PATH is the list of folders where the terminal looks for commands; without this entry the terminal does not know the word `flutter`.

Windows (this changes only your own user's PATH):

**File: `terminal (Windows PowerShell)`**
```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\develop\flutter\bin", "User")
```

macOS (zsh) and Linux (bash use `~/.bashrc` instead of `~/.zshrc`):

**File: `terminal (macOS or Linux)`**
```bash
echo 'export PATH="$HOME/develop/flutter/bin:$PATH"' >> ~/.zshrc
```

5. **Close the terminal and open a new one.** Then check:

**File: `terminal (any folder)`**
```text
flutter --version
```
Expected result (typical, the build details differ on your machine): a first line like `Flutter 3.50.1 • channel stable`, then lines starting with `Framework`, `Engine` and `Tools • Dart 3.14.0`. The very first run downloads extra files and can take a few minutes. If the terminal says `flutter` is not recognised, the PATH step was missed or the terminal is old.

PowerShell note: if Windows says running scripts is disabled when you start a tool, that is the PowerShell execution policy. `flutter` itself is a `.bat` file and normally works; if you only see the script error, tell PowerShell to allow scripts for your user with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Step 5. Accept the Android licences and run the doctor
`flutter doctor` is Flutter's checklist: it inspects your installation and prints what is missing. Run:

**File: `terminal (any folder)`**
```text
flutter doctor --android-licenses
```
Type `y` and press Enter every time it asks to accept a licence. Then run the checklist:

**File: `terminal (any folder)`**
```text
flutter doctor
```
Expected result (typical shape, versions and details differ): a list in which the **Flutter**, **Android toolchain** and **Android Studio** lines start with a green check mark. Lines for Chrome, Visual Studio or Xcode may show a warning because this course targets Android only; you can ignore them. Read any red `[✗]` line: it names the missing piece and often the command that fixes it. If Android toolchain complains about missing command-line tools, repeat Step 3 point 4. Run `flutter doctor` again until Flutter and the Android toolchain are green.

First builds may download more Android components (platform, build tools, NDK). That is normal and needs the licences accepted above.

Good place for a break: the toolchain is installed.

### Step 6. Get a phone to run on
Pick one of the two routes.

**Route A, the emulator.** In Android Studio open **More Actions > Virtual Device Manager** (also under **Tools > Device Manager**), click **Create Device**, choose a phone such as **Pixel**, click **Next**, pick a recent system image (download it if it shows a download link; images marked *Google APIs* work), click **Next** and **Finish**. Press the green play button next to the device to start it. A phone window appears; the first start takes a minute or two. Leave it open.

**Route B, your own Android phone.** Open **Settings > About phone** and tap **Build number** seven times to unlock developer options. In **Settings > System > Developer options** switch on **USB debugging**. Connect the phone with a USB cable and accept the "Allow USB debugging" question on the phone.

Check that Flutter sees a device:

**File: `terminal (any folder)`**
```text
flutter devices
```
Expected result: a list that includes your emulator or phone (for example a line with the word `android`). If your device is missing, start the emulator first or reconnect the cable.

### Step 7. Create the project
Choose a work folder for the whole course. These commands create it and move into it (`cd` means change directory, that is, current folder):

**File: `terminal (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\flutter101"
Set-Location "$HOME\code101\flutter101"
```

**File: `terminal (macOS or Linux)`**
```bash
mkdir -p ~/code101/flutter101
cd ~/code101/flutter101
```

The terminal prompt now ends with `flutter101`. If you ever get lost, run the same two lines again.

Now ask Flutter to make a project. `--platforms=android` limits it to Android, which keeps the project small:

**File: `terminal (folder flutter101)`**
```text
flutter create --platforms=android first_app
```
Expected result (typical): several lines about creating files, then `All done!` and a hint to run `cd first_app` and `flutter run`. The first run needs internet to resolve packages.

Move into the new project:

**File: `terminal (folder flutter101)`**
```text
cd first_app
```

Look at what Flutter made:

- `lib/main.dart`: your Dart code. Almost all your work happens here.
- `pubspec.yaml`: the project's settings and the list of packages it uses.
- `android/`: the Android part. You will rarely touch it in this course.
- `test/`: sample tests. The tests of the generated sample app would fail after we replace `main.dart`, so delete this folder now. The course does not use tests.

Delete it (Windows PowerShell, then macOS or Linux):

**File: `terminal (folder first_app, Windows PowerShell)`**
```powershell
Remove-Item -Recurse -Force test
```

**File: `terminal (folder first_app, macOS or Linux)`**
```bash
rm -rf test
```

### Step 8. Replace the project settings
Open the `first_app` folder in Android Studio (**File > Open**, choose the `first_app` folder) or in any text editor. Open `pubspec.yaml`, select everything, delete it and type this file. Save with Ctrl+S (Cmd+S on macOS); a dot on the editor tab means the file is not saved yet.

**File: `pubspec.yaml`**
```yaml
name: first_app
description: My first Flutter app for Code101.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.14.0

dependencies:
  flutter:
    sdk: flutter
  material_ui: 1.11.1

dev_dependencies:
  flutter_lints: 6.0.0

flutter:
  uses-material-design: true
```

What each part means:
- `name`: the project name. It must be lower case with underscores, and it must match the folder name here.
- `description`, `publish_to: none`, `version`: label information. `none` stops you publishing by accident.
- `environment: sdk: ^3.14.0`: the Dart version this project needs (3.14.0 or newer, below 4).
- `dependencies`: packages the app uses. `flutter` comes with the SDK. `material_ui` holds the Material widgets (buttons, app bars, text fields). Since Flutter 3.50 the Material library is a separate package; `1.11.1` is the exact version checked for this course.
- `dev_dependencies`: tools only used while writing code. `flutter_lints` gives hints about style.
- `flutter: uses-material-design: true`: the default switch for Material.

Download the packages. This command also creates `pubspec.lock`, a file that records the exact versions found (do not edit it, and you do not have to type it):

**File: `terminal (folder first_app)`**
```text
flutter pub get
```
Expected result: the last line says `Got dependencies!`. If the message says it could not find the package, check your internet connection and the spelling in `pubspec.yaml`.

### Step 9. Write the app
Open `lib/main.dart`, select everything, delete it and type this file:

**File: `lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const FirstApp());
}

class FirstApp extends StatelessWidget {
  const FirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('First app')),
        body: const Center(child: Text('Hello, Flutter!')),
      ),
    );
  }
}
```

Walk through it from top to bottom:
1. `import ...` makes the Material widgets available.
2. `void main()` is where every Dart program starts. `runApp(...)` hands one widget to Flutter and says: draw this.
3. `FirstApp` is our own widget. A `StatelessWidget` is a widget that does not change after it is drawn (lesson 05 adds widgets that change). `const` means the object is created once at build time; Flutter can reuse it.
4. `build` describes the screen. It returns a `MaterialApp` (the Material wrapper for a whole app) whose `home` is a `Scaffold` (the standard page skeleton) with an `AppBar` (the top bar) and a `body`.
5. `Center(child: Text('Hello, Flutter!'))` puts one piece of text in the middle.

Everything on the screen is a widget placed inside another widget. That is the whole idea of Flutter.

## Run it
Make sure the emulator is running or the phone is connected, then in the `first_app` folder:

**File: `terminal (folder first_app)`**
```text
flutter run
```
The first build is slow (several minutes) because Gradle, Android's build tool, downloads and compiles things. Later runs are much faster. Expected result: the app opens on the phone with a teal top bar saying "First app" and the text "Hello, Flutter!" in the middle. In the terminal Flutter prints a line about the app running and keys you can press. I describe what to expect from the code; your first run is the real test.

Keep it running and try **hot reload**: change `'Hello, Flutter!'` to `'Hello, world!'` in `main.dart`, save, then click in the terminal and press `r`. The phone updates in about a second without restarting. Useful keys in that terminal: `r` hot reload, `R` hot restart (restart the app state), `q` quit.

## How it works
Flutter draws every pixel itself instead of using phone buttons. Your Dart code builds a **widget tree**: `MaterialApp` contains `Scaffold`, which contains `AppBar` and `Center`, which contains `Text`. When something changes, Flutter rebuilds the affected part of the tree and redraws it. Hot reload sends the changed code to the running app and rebuilds the tree.

Common misconception: "Flutter apps are websites in a wrapper." They are not; Flutter compiles your Dart code to real Android code and draws with its own engine.

## Try it
Copy the exercise starter's `lib/main.dart` over yours (or edit your own file). The starter is in `exercise/starter`:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyGreetingApp());
}

class MyGreetingApp extends StatelessWidget {
  const MyGreetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Greeting',
      // TODO 2: change Colors.teal to another color, for example Colors.orange
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('My greeting')),
        // TODO 1: replace 'Hello, Flutter!' with a greeting that contains your own name
        body: const Center(child: Text('Hello, Flutter!')),
      ),
    );
  }
}
```

1. **Guided:** complete TODO 1: put your own name into the greeting. Hot reload and look at the phone.
2. **Change:** complete TODO 2: change the seed colour and see the top bar change. Then make the greeting text bigger with a `style:` argument on `Text`.
3. **Stretch (optional):** make a mistake on purpose (delete one closing bracket), save and read Flutter's error. Fix it again. What does the error tell you about where the mistake is?

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyGreetingApp());
}

class MyGreetingApp extends StatelessWidget {
  const MyGreetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Greeting',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('My greeting')),
        body: const Center(
          child: Text(
            'Hello, Sam!',
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
```

`TextStyle(fontSize: 32)` makes the letters 32 logical pixels tall. `Colors.orange` is only the seed: Flutter derives a whole colour scheme from it.

</details>

## Check yourself
1. Which command lists what is missing in your installation? <details><summary>Answer</summary>`flutter doctor`.</details>
2. What does `runApp` do? <details><summary>Answer</summary>It gives Flutter the root widget to draw.</details>
3. You edit `main.dart`, save, press `r`, and nothing changes. Name two likely causes. <details><summary>Answer</summary>The file was not saved (dot on the tab), or you pressed `r` in another window than the one running `flutter run`.</details>
4. Why does `pubspec.yaml` list `material_ui`? <details><summary>Answer</summary>It provides the Material widgets such as `Scaffold`, `AppBar` and `Text` styles used by the app.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `flutter` is not recognised (Windows) or `command not found` | PATH not set, or the terminal was opened before | Redo Step 4 point 4 and open a new terminal |
| `flutter doctor` shows a red mark for Android licences | Licences not accepted | Run `flutter doctor --android-licenses` and answer `y` |
| `flutter devices` shows no Android device | Emulator not started or USB debugging off | Start the emulator (Step 6) or enable USB debugging and accept the phone's prompt |
| `Could not find a file named "pubspec.yaml"` (typical message) | The terminal is in the wrong folder | `cd` into `first_app`; the prompt must end with `first_app` |
| Red error screen after editing | A typo in Dart (missing bracket, quote or semicolon) | Read the first error line, it names the file and line number; fix and save |
| Hot reload does nothing | File not saved or wrong terminal | Save (dot gone) and press `r` in the terminal running `flutter run` |

## Best practice
Run `flutter doctor` first whenever something builds strangely; it checks the common causes in seconds. Source: [Install Flutter](https://docs.flutter.dev/install)

## Going further
- Read the first section of [Flutter's documentation](https://docs.flutter.dev/) to see the full widget catalogue.
- Install the Flutter extension in VS Code if you prefer it to Android Studio: https://docs.flutter.dev/install/with-vs-code.

## Summary
- You installed Git, Android Studio, the Android SDK and Flutter and checked them with `flutter doctor`.
- You created a project, wrote `pubspec.yaml` and `lib/main.dart` and ran them on an Android device.
- You used hot reload and explained that a Flutter screen is a tree of widgets.

## Next lesson
02. Dart basics: the language of Flutter, without a screen yet, so mistakes are easy to read.
