# Code101 art assets

Icons and logos shared by the tutorials and source packs. Use them in labs for buttons, navigation,
empty states and dashboards (Angular, React, Flutter, Compose, Unity UI, desktop apps).

## What is included

| Folder | What | License |
|--------|------|---------|
| `icons/<category>/*.svg` | 549 minimalist line icons, 24x24 grid, `stroke="currentColor"` so they take the text colour | CC0 1.0, see [LICENSE-ICONS-CC0.txt](LICENSE-ICONS-CC0.txt) |
| `loaders/*.svg` | 12 simple loading indicators (a small sample) | CC0 1.0, same set |
| `brand/*.svg` | Uee03 logo, circle logo, wordmark, banner | (c) Uee03, use for Code101 branding only |

Source: `F:\Projects\Git\Art` (`src/saas-icons`). Only the CC0 plain icon set is copied here. The animated,
weather-animation, moon, particle and loader packs in that repo are **proprietary** and are deliberately
**not** included, so Code101 can be shared freely.

## Categories

| Category | Icons | Examples |
|----------|-------|----------|
| `arrows` | 51 | arrow-down-left, arrow-down-right, arrow-down, arrow-left-right, arrow-left, arrow-right |
| `charts` | 26 | activity, analytics, area-chart, bar-chart-2, bar-chart-box, bar-chart |
| `cloud-network` | 24 | api, broadcast, cloud-check, cloud-download, cloud-lock, cloud-off |
| `commerce` | 40 | award, banknote, barcode, bitcoin, box, calculator |
| `communication` | 28 | at-sign, chat-bubble, frown, headphones, inbox-full, mail-open |
| `dev-code` | 32 | bash, binary, braces, bracket-curly, brackets, bug-off |
| `devices` | 30 | battery-charging, battery, bluetooth, chip, cpu, database |
| `editing` | 31 | align-center, align-justify, align-left, align-right, bold, brush |
| `files` | 34 | archive, book-open, book, clipboard-check, clipboard-list, clipboard |
| `location` | 23 | building-2, building, compass, directions, earth, factory |
| `media` | 31 | airplay, aperture, camera-off, camera, cast, disc |
| `saas` | 30 | automation, bell-dot, brain, briefcase, building-office, bulb-on |
| `security` | 24 | alarm, bug-security, cookie, encrypted, fingerprint, firewall-shield |
| `shapes` | 22 | arc, blob, circle-dot, circle, cross, diamond |
| `time` | 20 | alarm-clock, calendar-check, calendar-clock, calendar-days, calendar-plus, calendar-x |
| `ui` | 48 | alert-circle, alert-octagon, alert-triangle, bell-off, bell, bookmark |
| `users` | 24 | avatar, baby, contact, group, headset, id-badge |
| `weather` | 16 | cloud-drizzle, cloud-fog, cloud-lightning, cloud-rain, cloud-snow, cloud-weather |

## How lessons use them

1. A lesson that needs icons lists them in its front matter (`assets: [ui/search, ui/bell]`).
2. `scripts/build_packs.py` copies **only those icons** into that lesson's source pack under `assets/`
   (so each pack stays small and self-contained) and adds the license file.
3. Whole-library access: `dist/packs/code101-art-assets.zip`.

Usage in each stack (full steps are in the lessons):

- HTML / Angular / React: `<img src="assets/icons/ui/search.svg" width="24" height="24" alt="Search">`, or inline the SVG so
  `currentColor` follows CSS `color`.
- Flutter: add `flutter_svg`, list the folder under `flutter: assets:` in `pubspec.yaml`, use `SvgPicture.asset(...)`.
- Compose: convert with Android Studio *Vector Asset* import, then `Icon(painterResource(...))`.
- Unity: import with the Vector Graphics package or rasterize to PNG.
