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
