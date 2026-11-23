# Convert only the CC0 24x24 stroke shapes used by this pack.
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ICONS = ["arrows/log-in", "arrows/log-out", "arrows/refresh-cw", "users/team",
         "files/folder", "ui/list", "ui/plus", "ui/settings", "devices/wifi-off",
         "communication/message-square"]

def path_data(node):
    a = node.attrib
    tag = node.tag.split("}")[-1]
    if tag == "path":
        return a["d"]
    if tag == "line":
        return f'M{a["x1"]},{a["y1"]} L{a["x2"]},{a["y2"]}'
    if tag in ("polyline", "polygon"):
        return "M" + " L".join(a["points"].split()[i] + "," + a["points"].split()[i+1]
                              for i in range(0, len(a["points"].split()), 2)) + (" Z" if tag == "polygon" else "")
    if tag == "circle":
        x, y, r = (float(a[k]) for k in ("cx", "cy", "r"))
        return f"M{x-r},{y} a{r},{r} 0 1,0 {2*r},0 a{r},{r} 0 1,0 {-2*r},0"
    if tag == "rect":
        x, y = float(a.get("x", 0)), float(a.get("y", 0))
        w, h = float(a["width"]), float(a["height"])
        return f"M{x},{y} h{w} v{h} h{-w} Z"
    raise ValueError(f"Unsupported SVG shape: {tag}")

def main():
    source = Path(sys.argv[1])
    target = Path("app/src/main/res/drawable")
    target.mkdir(parents=True, exist_ok=True)
    for icon in ICONS:
        svg = ET.parse(source / (icon + ".svg")).getroot()
        lines = ['<vector xmlns:android="http://schemas.android.com/apk/res/android"',
                 '    android:width="24dp" android:height="24dp"',
                 '    android:viewportWidth="24" android:viewportHeight="24">']
        for node in svg:
            data = path_data(node)
            lines.append('    <path android:fillColor="@android:color/transparent" android:strokeColor="#FF000000"')
            lines.append('        android:strokeWidth="2" android:strokeLineCap="round" android:strokeLineJoin="round"')
            lines.append(f'        android:pathData="{data}" />')
        lines.append('</vector>')
        name = 'ic_' + icon.split('/')[-1].replace('-', '_') + '.xml'
        (target / name).write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print("Converted 10 CC0 icons")

if __name__ == "__main__":
    main()
