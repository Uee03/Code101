# Compile the base English resources and exercise British-English override in one APK.
from pathlib import Path
import shutil

relative = Path("app/src/main/res/values-en-rGB/strings.xml")
source = Path("../exercise/solution") / relative
target = relative
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(source, target)
print("Exercise solution installed as English UK resources; both variants build in one APK.")
