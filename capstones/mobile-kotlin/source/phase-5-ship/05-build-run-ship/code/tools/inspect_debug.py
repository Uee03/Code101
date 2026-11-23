# Inspect the built APK once. No adb server or emulator is started.
from pathlib import Path
import subprocess
import re

settings = Path("local.properties").read_text(encoding="utf-8")
sdk = Path(settings.strip().split("=", 1)[1])
exe = sdk / "build-tools/36.0.0" / ("aapt2.exe" if __import__("os").name == "nt" else "aapt2")
apk = Path("app/build/outputs/apk/debug/app-debug.apk")
assert apk.stat().st_size > 0
result = subprocess.run([str(exe), "dump", "xmltree", "--file", "AndroidManifest.xml", str(apk)],
                        capture_output=True, text=True, check=True)
assert "networkSecurityConfig" in result.stdout
assert re.search(r'android:scheme[^\n]*"com\.code101\.tasks"', result.stdout)
assert "com.code101.tasks.kotlin" in result.stdout
assert len(list(Path("app/src/main/res/drawable").glob("ic_*.xml"))) == 10
print("Debug APK exists; application id, redirect scheme, network config and 10 icons checked.")
