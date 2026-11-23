# Local machine configuration is created in the disposable verification copy.
from pathlib import Path
import os
import sys

sdk = os.environ.get("ANDROID_HOME")
if not sdk:
    if sys.platform == "win32":
        sdk = str(Path(os.environ["LOCALAPPDATA"]) / "Android/Sdk")
    elif sys.platform == "darwin":
        sdk = str(Path.home() / "Library/Android/sdk")
    else:
        sdk = str(Path.home() / "Android/Sdk")
path = Path(sdk)
if not (path / "platforms/android-37.2/android.jar").exists():
    raise SystemExit("Install Android SDK Platform 37.2 or set ANDROID_HOME.")
Path("local.properties").write_text("sdk.dir=" + path.as_posix() + "\n", encoding="utf-8")
print("Android SDK configured; local.properties is not shipped.")
