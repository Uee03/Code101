# Mobile Kotlin phase 3: Screens and state

Status: written (not run). No verification claim applies to this final snapshot.

## Open
Windows: Extract All. macOS: double-click. Linux: unzip. Open `03-screens/code` in Android Studio.
This contains the whole Android app, not a delta. Read tutorials/phase-3-screens/03-screens.md in the capstone repository.

## Prerequisites
Android Studio JBR, SDK Platform 37.2, build-tools 36.0.0, accepted licenses, Python 3.10+.
No global Gradle, Docker or emulator is needed to compile. A browser/emulator/USB phone is for manual checks only.
Version evidence is in capstones/mobile-kotlin/VERSIONS.md in the repository.

## Later commands (not executed during this writing-only session)
From 03-screens/code, set ANDROID_HOME to your SDK. Windows:

```powershell
python tools\prepare_sdk.py
python tools\apply_exercise.py
.\gradlew.bat openApiGenerate --console=plain
.\gradlew.bat assembleDebug --console=plain
python tools\inspect_debug.py
.\gradlew.bat --stop
```

Stop after any failing command. Unix: chmod +x gradlew and use ./gradlew.
SDK setup creates ignored local.properties; none is shipped. Reuse the default Gradle cache.
Generated client sources/wrapper jar are supplied; regeneration commands are in the chapter.
The exercise is an English-UK overlay: one APK compiles default and answer resources together.
No unit/instrumented tests, emulator, Docker or HTTP probe are in verify.json.

## Chapter
03. Screens and state, 120 minutes; device checks take additional time.

## Assets/secrets
Only ten declared CC0 SVGs from assets/art, their license and Android vectors are included.
Never distribute build/, .gradle/, .idea/, local.properties, keystore.properties, .jks/.keystore or heap dumps.
Do not edit generated code. Tokens belong only in the encrypted vault.
