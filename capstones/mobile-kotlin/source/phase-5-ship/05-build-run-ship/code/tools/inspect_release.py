from pathlib import Path
import xml.etree.ElementTree as ET

bundle = Path("app/build/outputs/bundle/release/app-release.aab")
assert bundle.stat().st_size > 0
manifests = list(Path("app/build/intermediates/merged_manifests/release").rglob("AndroidManifest.xml"))
assert manifests
app = ET.parse(manifests[0]).getroot().find("application")
assert app is not None
android = "{http://schemas.android.com/apk/res/android}"
assert android + "networkSecurityConfig" not in app.attrib
assert app.attrib[android + "usesCleartextTraffic"] == "false"
assert app.attrib[android + "allowBackup"] == "false"
print("Release bundle exists; merged release manifest forbids cleartext and backup.")
