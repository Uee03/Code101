---
track: docker
level: 101
phase: 1
phase_name: containers
lesson: 04
title: Data that survives
time: 30 min
prerequisites: [101.1.03]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-1-containers/04-data-that-survives/
assets: []
---

# 04. Data that survives

## Why it matters
A hotel room is temporary, but your suitcase goes with you when you check out. A container is the room; a **volume** is storage kept separately. Removing the room must not remove your saved work.

## What you will build
A named volume whose recipe survives removal of its writer container, contrasted with a read-only host bind mount.

## Before you start
- Complete lesson 03. Docker must be running: docker info must show a Server section.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 30 minutes (about 5 minutes per new idea plus setup; Docker is already installed).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-1-containers/04-data-that-survives/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Image tags were confirmed by successful pulls on **2026-11-23**. Explicit version-family tags can receive patches:
  `python:3.13-slim`, `postgres:17-alpine`, `nginx:1.28-alpine`, `alpine:3.22`.
  `hello-world:latest` is the official diagnostic exception, not a production choice.
- Windows uses PowerShell 5.1. Docker commands are identical on macOS/Linux unless noted. Use `curl.exe` on Windows
  (bare curl is a PowerShell alias); replace it with `curl` on macOS/Linux. Ubuntu Engine users: prefix every Docker command
  with `sudo`. Desktop users: do not use sudo. No host Python installation is needed.

## Steps

### Step 1. Make your working folder
A **terminal** is a window for typed commands. Windows: Start > type PowerShell > **Windows PowerShell**.
macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from the application menu.
Do not type the prompt (`PS ...>` or `$`); type only each command, then press Enter.

Windows, from any folder:

**Commands — folder: `any folder`**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson04" | Out-Null
Set-Location "$HOME\code101\docker\lesson04"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson04
cd ~/code101/docker/lesson04
```

Expected result: your terminal is inside `lesson04`. The prompt usually shows the folder; check with `Get-Location`
(Windows) or `pwd` (macOS/Linux). If lost, the Set-Location/cd line above returns here. All subsequent commands run here
unless marked otherwise. Stop other Docker lessons before using port 8080.

Create each file in a plain-text editor: **File > New**, paste its full contents, **File > Save As**, save in this folder.
Windows Notepad: **Save as type: All files**, encoding **UTF-8**, exact filename. In File Explorer enable
**View > Show > File name extensions** to catch accidental `.txt` suffixes. macOS TextEdit: **Format > Make Plain Text**;
disable automatic `.txt` extension when saving. Linux: use your plain-text editor. Save before running;
a dot on an editor tab usually means unsaved changes.

### Step 2. Create a host file
Save note.txt in your lesson folder:

**File: `note.txt`**
```text
Host recipe
```

A **bind mount** makes a specific host file/folder visible inside a container. This note lives on your computer;
Docker does not manage it. A **volume** is storage Docker manages by name, outside any individual container.
Use named volumes for application-managed data and bind mounts for files you want to edit on the host.

### Step 3. Save the complete storage checklist

**File: `storage.ps1`**
```powershell
docker volume create code101-verify-04-store
docker run --name code101-verify-04-writer --mount type=volume,src=code101-verify-04-store,dst=/data alpine:3.22 sh -c "echo 'Saved recipe' > /data/note.txt"
docker rm code101-verify-04-writer
docker run --name code101-verify-04-reader --mount type=volume,src=code101-verify-04-store,dst=/data alpine:3.22 cat /data/note.txt
docker rm code101-verify-04-reader
docker run --name code101-verify-04-bind --mount "type=bind,src=$($PWD.Path),dst=/host,readonly" alpine:3.22 cat /host/note.txt
docker rm code101-verify-04-bind
docker volume rm code101-verify-04-store
```

This PowerShell file is a checklist. Type its commands individually below to understand the outcomes rather than running both.
Line 1 creates named storage. Line 2 attaches it as /data and writes the recipe; `sh -c` runs a small Linux shell command inside
Alpine. The `>` is **inside the quotes**, so it writes the container file, not a host file. Line 3 removes the exited writer.
Line 4 starts a new container with the same volume and uses `cat` to display the saved file. Line 5 removes that reader.
Line 6 reads your host note through a read-only bind mount, line 7 removes that exited container, and line 8 deletes the volume.

`--mount type=volume,src=...,dst=/data` selects Docker-managed storage; src is its name, dst the container folder.
`type=bind` selects a host directory instead. In PowerShell `$($PWD.Path)` obtains the absolute current host path.
`readonly` prevents container writes to the host directory. Container removal does not delete a bind-mounted host file.
On macOS/Linux, all commands are identical **except** the bind-mount command: replace only `$($PWD.Path)` with `$(pwd)`:

**Commands — folder: `your lesson folder`**
```bash
docker run --name code101-verify-04-bind --mount "type=bind,src=$(pwd),dst=/host,readonly" alpine:3.22 cat /host/note.txt
```

Ubuntu Engine users also prefix Docker commands with sudo. Paths with spaces need the quotes shown. These OS substitutions
are documented variants; Windows is the verified author runtime.

## Run it
Create the volume, write it, then check the exited writer and logs:

**Commands — folder: `your lesson folder`**
```powershell
docker volume create code101-verify-04-store
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-04-store
```

**Commands — folder: `your lesson folder`**
```powershell
docker run --name code101-verify-04-writer --mount type=volume,src=code101-verify-04-store,dst=/data alpine:3.22 sh -c "echo 'Saved recipe' > /data/note.txt"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
(no output)
```

**Commands — folder: `your lesson folder`**
```powershell
docker ps -a --filter name=code101-verify-04-writer --format "{{.Names}} | {{.State}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-04-writer | exited
```

**Commands — folder: `your lesson folder`**
```powershell
docker logs code101-verify-04-writer
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
(no output)
```

**Commands — folder: `your lesson folder`**
```powershell
docker rm code101-verify-04-writer
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-04-writer
```

**Commands — folder: `your lesson folder`**
```powershell
docker run --name code101-verify-04-reader --mount type=volume,src=code101-verify-04-store,dst=/data alpine:3.22 cat /data/note.txt
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Saved recipe
```

**Commands — folder: `your lesson folder`**
```powershell
docker logs code101-verify-04-reader
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Saved recipe
```

The writer's empty logs are normal: echo wrote to /data/note.txt rather than standard output. The reader prints Saved recipe,
and its logs retain that text. Neither one is a long-running server, so a separate stop command is unnecessary.
Remove the reader, then read the host file using a **different** container:

**Commands — folder: `your lesson folder`**
```powershell
docker rm code101-verify-04-reader
docker run --name code101-verify-04-bind --mount "type=bind,src=$($PWD.Path),dst=/host,readonly" alpine:3.22 cat /host/note.txt
docker rm code101-verify-04-bind
docker volume rm code101-verify-04-store
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-04-reader
Host recipe
code101-verify-04-bind
code101-verify-04-store
```

This output is copied from the executed storage checklist. **The final volume rm destroys the saved recipe.** Do it only for this
throwaway lesson, not for valuable data. Your host note.txt is unchanged. A volume surviving removal is not a backup: disk failure
or deliberate volume deletion can still destroy it.

## How it works
Docker mounts named storage at /data before the process runs. echo writes into that storage, not the container-only filesystem. Removing the writer leaves the volume. The reader mounts the same name and sees the recipe. By contrast, the bind mount exposes your host folder at /host; readonly makes it visible but not writable.

New terms for this lesson (also in the track glossary):

- **bind mount**: A specific host file or folder made visible inside a container; Docker does not manage it.
- **volume**: Storage Docker manages by name, outside any individual container.
- **mount**: Attaching storage (a volume or a host folder) at a folder path inside a container.
- **host**: Your own computer.
- **read-only (`readonly`)**: The container can look at the files but not change them.
- **checklist file**: A saved list of commands you type one at a time, not a program to run whole.

## Try it
Stop/clean up your lesson first. Make a new folder `practice` inside your lesson folder and copy `note.txt` into it. Open a terminal inside practice:

**Commands — folder: `your lesson folder`**
```powershell
New-Item -ItemType Directory -Force practice | Out-Null
Copy-Item note.txt practice
Set-Location practice
```

**Commands — folder: `your lesson folder`**
```bash
mkdir -p practice
cp note.txt practice/
cd practice
```
Expected result: you are inside `practice`, working on your own copy.
**Exercise:** keep the text `Saved shopping list` in a new volume named `code101-verify-04-exercise`, and prove it survives: write it with one container, remove that container, then read it back with a second container. Also read `note.txt` from the host through a read-only bind mount; it must still say `Host recipe`. Finally delete only your exercise volume. Use the Step 3 checklist as your pattern, writing your own file `storage.ps1` or typing the commands one at a time.
<details><summary>Solution</summary>

**File: `practice/storage.ps1`**
```powershell
docker volume create code101-verify-04-exercise
docker run --name code101-verify-04-writer --mount type=volume,src=code101-verify-04-exercise,dst=/data alpine:3.22 sh -c "echo 'Saved shopping list' > /data/note.txt"
docker rm code101-verify-04-writer
docker run --name code101-verify-04-reader --mount type=volume,src=code101-verify-04-exercise,dst=/data alpine:3.22 cat /data/note.txt
docker rm code101-verify-04-reader
docker run --name code101-verify-04-bind --mount "type=bind,src=$($PWD.Path),dst=/host,readonly" alpine:3.22 cat /host/note.txt
docker rm code101-verify-04-bind
docker volume rm code101-verify-04-exercise
```

In practice type those lines (macOS/Linux use the exact bind substitution from Step 3; Ubuntu: sudo).
The saved reader message is `Saved shopping list`; the host bind still says `Host recipe`.
The reader step was captured **after** the writer was removed. Each removal prints its target name, and the final
volume removal prints `code101-verify-04-exercise`. All exercise resources are temporary.

Full output from the executed Windows solution checklist (stdout and stderr shown separately):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-04-exercise
code101-verify-04-writer
Saved shopping list
code101-verify-04-reader
Host recipe
code101-verify-04-bind
code101-verify-04-exercise
```
</details>


## Check yourself
1. Where is the named volume stored?
   <details><summary>Answer</summary>Docker manages it independently of containers; do not assume a host path.</details>
2. Does container rm delete the volume?
   <details><summary>Answer</summary>No; the named volume remains until explicitly deleted.</details>
3. Does volume rm delete the bind-mounted note.txt?
   <details><summary>Answer</summary>No; note.txt is a separate host file.</details>
4. Is a surviving volume a backup?
   <details><summary>Answer</summary>No. You still need separate backups for valuable data.</details>

## Common mistakes
Rows marked typical message were not captured on the author machine. IDs vary. Never remove an unfamiliar container or volume to fix a conflict.

| Error text | Cause | Fix |
|---|---|---|
| `Conflict. The container name "/code101-verify-04-writer" is already in use by container` followed by an ID (typical message) | A previous run stopped before its `docker rm` line, so the name is still taken | Run `docker ps -a`, then `docker rm code101-verify-04-writer` (only your own container) and repeat. |
| `cat: can't open '/host/note.txt': No such file or directory` (typical message) | You ran the bind-mount line in a folder that does not contain `note.txt` | Move to the lesson folder (the `Set-Location` or `cd` line in Step 1) and run it again. |
| `volume is in use` inside `Error response from daemon: remove code101-verify-04-store` (typical message) | A container, even a stopped one, still uses the volume | Remove that container with `docker rm`, then run `docker volume rm` again. |
| `check if the path is correct and if the daemon is running` (captured in lesson 01; the full line varies by system) | Docker Desktop is not running | Start Docker Desktop, wait for **Engine running**, then repeat the command. |

## Best practice
Keep persistent data in named volumes, and back it up before deleting storage. Source: Docker volumes https://docs.docker.com/engine/storage/volumes/

## Next lesson
**05. Environment variables and secrets:** start Phase 2 by separating settings from images.
