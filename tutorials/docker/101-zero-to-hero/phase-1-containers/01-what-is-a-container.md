---
track: docker
level: 101
phase: 1
phase_name: containers
lesson: 01
title: What is a container + install Docker
time: 60+ min (two sittings)
prerequisites: [none]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container/
assets: []
---

# 01. What is a container + install Docker

## Why it matters
A shipping container keeps its contents together whether it travels by ship or truck. Docker keeps a program and its files in an isolated **container**. Containers share an operating-system **kernel** (the core that manages hardware and processes); they are not whole separate computers.

## What you will build
A successful hello-world run and a reusable lifecycle checklist, with one installation route per operating system.

## Before you start
- Computer, internet, permission to install software. No programming experience required.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 60 minutes or more, in two sittings: installing Docker (Steps 2 to 4, plus a restart) takes about 30 to 40 minutes on its own, then about 5 minutes for each of the new ideas and the exercise. The break is marked before Step 5.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson01" | Out-Null
Set-Location "$HOME\code101\docker\lesson01"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson01
cd ~/code101/docker/lesson01
```

Expected result: your terminal is inside `lesson01`. The prompt usually shows the folder; check with `Get-Location`
(Windows) or `pwd` (macOS/Linux). If lost, the Set-Location/cd line above returns here. All subsequent commands run here
unless marked otherwise. Stop other Docker lessons before using port 8080.

Create each file in a plain-text editor: **File > New**, paste its full contents, **File > Save As**, save in this folder.
Windows Notepad: **Save as type: All files**, encoding **UTF-8**, exact filename. In File Explorer enable
**View > Show > File name extensions** to catch accidental `.txt` suffixes. macOS TextEdit: **Format > Make Plain Text**;
disable automatic `.txt` extension when saving. Linux: use your plain-text editor. Save before running;
a dot on an editor tab usually means unsaved changes.

### Step 2. Install on Windows (skip this step on other systems)
If `docker info` already shows a Server section, keep your working installation; do not reinstall it.
A **virtual machine** supplies a separate operating system in software. **WSL2** means Windows Subsystem for Linux version 2:
a lightweight Linux virtual machine used by Docker Desktop. We use Linux containers even though your host computer runs Windows.

1. Check the [official Windows requirements](https://docs.docker.com/desktop/setup/install/windows-install/): supported Windows,
   at least 8 GB RAM, hardware virtualization enabled. On a work computer ask IT before changing firmware or installing software.
2. Start > type PowerShell > right-click **Windows PowerShell** > **Run as administrator**. From any folder, on a fresh machine:

**Commands — folder: `any folder`**
```powershell
wsl --install -d Ubuntu-26.04
wsl --update
```

Installation result: WSL and Ubuntu are installed/updated; restart Windows if prompted. Download percentages and installer messages
vary and were not captured here: this machine already had WSL. If this distribution is unavailable, run `wsl --list --online`
and choose the supported Ubuntu name listed there, following Microsoft's [install guide](https://learn.microsoft.com/en-us/windows/wsl/install).
3. After restarting, open **Ubuntu-26.04** from Start. Follow its first-run prompts to choose a Linux username and password.
   Password characters are not displayed while typing; press Enter when finished. Close that window; the course uses PowerShell.
4. Open a new ordinary PowerShell window. From any folder:

**Commands — folder: `any folder`**
```powershell
wsl --version
wsl --list --verbose
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
WSL version: 3.0.5.0
Kernel version: 6.18.58.1-1
WSLg version: 1.0.79
MSRDC version: 1.2.7391
Direct3D version: 1.611.1-81528511
DXCore version: 10.0.26100.1-240331-1435.ge-release
Windows version: 10.0.26300.9974
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
NAME              STATE           VERSION
* Ubuntu-26.04      Stopped         2
  docker-desktop    Running         2
```

The last column is the distribution's WSL version: it must be `2`. A Stopped Ubuntu distribution is fine.
If yours says `1`, run `wsl --set-version Ubuntu-26.04 2` (substitute your listed name); conversion messages/time vary.
5. Open the [official Docker Desktop Windows page](https://docs.docker.com/desktop/setup/install/windows-install/).
   Choose **Docker Desktop for Windows - x86_64** for Intel/AMD; use the Arm installer only on Arm hardware.
6. Double-click **Docker Desktop Installer.exe**. Select **per-user** installation when offered. On **Configuration** choose **WSL 2**;
   older installers label this **Use WSL 2 instead of Hyper-V**. Keep the other defaults. Complete the wizard and select **Close**.
7. Start > **Docker Desktop**. Read the subscription agreement and select **Accept** only if its terms fit your use.
   Personal/education use is normally free; organizations should check the linked licensing terms. Wait for **Engine running**.
   If needed inspect **Settings > General > Use the WSL 2 based engine**; use Linux containers, not Windows containers.
   There is no need to enable Ubuntu WSL integration when working in PowerShell.
8. Close PowerShell and open a new one: old terminals may not see newly installed commands on PATH (the command search list).

### Step 3. Optional Windows memory cap (skip if your setup works)
This is an optional, documentation-checked configuration, **not applied to the author machine**.
It affects all WSL2 distributions, not just this lesson. Save work in Ubuntu and stop your own containers first.
If a `.wslconfig` already exists, back it up and preserve its other settings rather than overwriting it.

Open File Explorer, enter `%USERPROFILE%` in the address bar, and press Enter. This is `C:\Users\<you>`;
`<you>` means your actual Windows account name, not text to type. Create `.wslconfig` in this folder, not inside Ubuntu.
For a new file, its complete contents are:

**File: `C:\Users\<you>\.wslconfig`**
```ini
[wsl2]
memory=8GB
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Apply these settings to all WSL2 distributions in the shared virtual machine. |
| 2 | Cap WSL2 memory at 8 gigabytes, not reserve it. Choose a cap suitable for your machine; too little breaks builds. |

Choose a smaller/larger limit only after considering your total RAM. This example suits a machine with headroom beyond 8 GB.
Quit Docker Desktop from its tray menu **Quit Docker Desktop**, close Ubuntu windows, then run from any PowerShell folder:

**Commands — folder: `any folder`**
```powershell
wsl --shutdown
```

Documented result: WSL stops all running distributions; the command normally prints no text. It was deliberately not run during
this author session because it would interrupt the running engine and other tracks. Start Docker Desktop again, wait for **Engine running**,
and rerun `docker info`. Remove only the memory line (or restore your backup), then perform the same shutdown/restart to undo the cap.
Source for this optional branch: [Microsoft WSL configuration](https://learn.microsoft.com/en-us/windows/wsl/wsl-config).

### Step 4. Install on macOS or Linux (choose only your operating system)
**macOS Desktop:**
1. Apple menu > **About This Mac**: note whether it says Apple silicon (an M-series chip) or Intel.
2. Open the [official macOS installer page](https://docs.docker.com/desktop/setup/install/mac-install/).
   Check supported macOS versions and at least 4 GB memory; download the matching **Apple silicon** or **Intel chip** installer.
3. Double-click `Docker.dmg`; drag **Docker** into **Applications**. Keep the installer volume mounted until copying finishes.
4. Open Applications > **Docker.app**. Read the agreement; select **Accept** if its terms fit. Current Desktop uses unprivileged
   default settings and does not require extra configuration. Wait for the engine to start.
5. Close Terminal and reopen it so Docker's new command location is available. Continue to Step 5.
These are official-docs checked steps, not a claimed macOS installation test.

**Linux Engine (Ubuntu 26.04; one explicit route):**
Do this on a Linux host, **not** inside the WSL distribution already used by Windows Docker Desktop. Other distributions:
choose your distribution at [Docker Engine install](https://docs.docker.com/engine/install/) rather than applying Ubuntu commands.
On an existing Docker host, do not remove packages or data; skip installation and check `sudo docker info` instead.
The route below is for a fresh supported Ubuntu installation. `sudo` requests administrator permission and your Linux password;
password characters are not echoed. Open Terminal in any folder:

**Commands — folder: `any folder`**
```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo nano /etc/apt/sources.list.d/docker.sources
```

`apt` installs packages; answer `Y` when asked. `install -d` creates the key directory; `curl` downloads Docker's signing key;
`chmod a+r` makes the key readable. `nano` opens a text editor with administrator permission.
Paste this whole new repository configuration (for Ubuntu 26.04 on Intel/AMD):

**File: `/etc/apt/sources.list.d/docker.sources`**
```text
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: resolute
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Use binary Debian-style packages. |
| 2 | Use the official Docker Ubuntu package repository. |
| 3 | Select Ubuntu 26.04. Use noble for 24.04; do not guess release names. |
| 4 | Choose the stable release channel. |
| 5 | Choose Intel/AMD 64-bit packages. Use arm64 for Arm hardware. |
| 6 | Verify packages with the official key at this exact path. |

For Ubuntu 24.04 change only line 3 to `Suites: noble`. For Arm hardware change only line 5 to `Architectures: arm64`.
Save in nano with **Ctrl+O**, Enter, then **Ctrl+X**. From any folder:

**Commands — folder: `any folder`**
```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl is-active docker
```

Expected installation result: package downloads finish and the engine service becomes active. `systemctl is-active` should report
`active`; package-manager messages are machine-specific and this installer branch was not executed on the Windows author host.
The packages supply Engine, its command client, the container runtime, image builder and Compose plugin respectively.
For conflicting older packages, follow the official [Ubuntu prerequisites](https://docs.docker.com/engine/install/ubuntu/) first;
never erase `/var/lib/docker` to resolve an installation conflict. Continue using **sudo** before Docker commands in all eight lessons.
Do not add yourself to the docker group casually: it grants effectively administrator-level control of the host.

> **Break point: end of the first sitting.** Docker is installed. Take a break here (a restart is fine). When you return, open a new terminal, move to your lesson folder with the `Set-Location` or `cd` line from Step 1 and continue with Step 5.

### Step 5. Check the installed client and engine
The **CLI** (command-line interface) is the `docker` command. The **engine**, also called the **daemon**, is its background service.
The **image** is the packaged filesystem and startup instructions used to create a container. The client alone being installed
is not enough; the engine must answer.

**Commands — folder: `your lesson folder`**
```powershell
docker --version
docker compose version
docker info --format "{{.ServerVersion}} | {{.OSType}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Docker version 29.9.3, build 5457199
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Docker Compose version v5.7.0
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
29.9.3 | linux
```

Versions may be newer on your computer. `linux` is the required container type for this track. For a fuller health check run
`docker info` in this folder: it lists Client and Server details. The author saw Server Version 29.9.3 and Containers: 0.
If it cannot connect, stop here and read Common mistakes.

### Step 6. Save the lifecycle checklist
Create this PowerShell file in your lesson folder. It is a saved checklist; Run it below shows the individual commands so you can
see each result. Do not run both the entire file and the individual commands without cleaning up between them.

**File: `hello.ps1`**
```powershell
docker run --name code101-verify-01-hello hello-world:latest
docker ps -a --filter name=code101-verify-01-hello --format "{{.Names}}: {{.State}}"
docker logs code101-verify-01-hello
docker rm code101-verify-01-hello
```

Line 1 creates/runs a named diagnostic container. Line 2 lists it including stopped containers (`-a`), filtered by name and formatted
as name/state. Line 3 reads its saved logs. Line 4 removes it. On macOS/Linux type these same Docker lines in Terminal rather than
running a `.ps1` (PowerShell script) file; on Ubuntu add sudo. `--name` gives predictable cleanup; it is not an image tag.

## Run it
Start the named container:

**Commands — folder: `your lesson folder`**
```powershell
docker run --name code101-verify-01-hello hello-world:latest
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

Check its status; the image's program finishes immediately, so an exited container is the expected success:

**Commands — folder: `your lesson folder`**
```powershell
docker ps -a --filter name=code101-verify-01-hello --format "{{.Names}}: {{.State}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-01-hello: exited
```

**Commands — folder: `your lesson folder`**
```powershell
docker logs code101-verify-01-hello
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

**Commands — folder: `your lesson folder`**
```powershell
docker rm code101-verify-01-hello
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-01-hello
```

The plain official quick check also works (optional, after the named container is removed):

**Commands — folder: `your lesson folder`**
```powershell
docker run hello-world
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

Without --name, Docker chooses a name. Find the exited diagnostic's ID, then remove the ID printed on **your** machine:

**Commands — folder: `your lesson folder`**
```powershell
docker ps -a --filter ancestor=hello-world:latest --format "{{.ID}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
a6c55ca1941a
```

**Commands — folder: `your lesson folder`**
```powershell
docker rm a6c55ca1941a
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
a6c55ca1941a
```

The shown ID is the author's; replace it with yours. No server remains running, so there is no stop command needed for hello-world.
The checked hello-world digest was `sha256:1e4c05b897a751332ce85c7e9449da2d93514ea2dea6dbb0e2753c9e949b2bfa`.

## How it works
The CLI contacts the daemon. Docker obtains the hello-world image from Docker Hub, creates an isolated process, streams its message, then the process exits. The stopped container keeps logs until removed; the image remains available for another run. A container is not a security boundary for untrusted software: run images you trust.

New terms for this lesson (also in the track glossary):

- **container**: An isolated running program together with its files, sharing the host's kernel.
- **kernel**: The core of an operating system that manages hardware and processes.
- **virtual machine**: A separate operating system running in software.
- **WSL2**: Windows Subsystem for Linux version 2, the lightweight Linux virtual machine Docker Desktop uses on Windows.
- **terminal**: A window for typed commands.
- **CLI**: Command-line interface; here the `docker` command.
- **engine (daemon)**: The background Docker service that actually creates and runs containers.
- **image**: The packaged filesystem and startup instructions used to create a container.

## Try it
Stop/clean up your lesson first. Make a new folder `practice` inside your lesson folder and open a terminal in it:

**Commands — folder: `your lesson folder`**
```powershell
New-Item -ItemType Directory -Force practice | Out-Null
Set-Location practice
```

**Commands — folder: `your lesson folder`**
```bash
mkdir -p practice
cd practice
```
Expected result: you are inside `practice`, working on your own copy.
**Exercise:** repeat the four-step checklist of Step 6 (run, list including stopped containers, read the logs, remove), but give the container the name `code101-verify-01-exercise` in every step and keep `hello-world:latest` as the image. Before you run it, predict the state the second step will print. Type the four lines one at a time (or into a `hello.ps1` file in `practice`).
<details><summary>Solution</summary>

**File: `practice/hello.ps1`**
```powershell
docker run --name code101-verify-01-exercise hello-world:latest
docker ps -a --filter name=code101-verify-01-exercise --format "{{.Names}}: {{.State}}"
docker logs code101-verify-01-exercise
docker rm code101-verify-01-exercise
```

Type the four lines individually in practice (Ubuntu: sudo before docker). On Windows you may instead run
`powershell -NoProfile -ExecutionPolicy Bypass -File hello.ps1` in practice; Bypass applies only to this known local script invocation,
not your system settings. On macOS/Linux type the four Docker commands directly. Expected first output is the full
`Hello from Docker!` message above; status is exited, logs repeat that message, removal prints the exercise name.

Full output from the executed Windows solution checklist (stdout and stderr shown separately):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

code101-verify-01-exercise: exited

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

code101-verify-01-exercise
```
</details>


## Check yourself
1. Does docker --version prove the engine is running?
   <details><summary>Answer</summary>No: it checks only the client. docker info must reach the Server.</details>
2. Why is hello-world exited?
   <details><summary>Answer</summary>It prints a message and finishes successfully.</details>
3. Is a container a full virtual machine?
   <details><summary>Answer</summary>No: it shares the engine host kernel; Desktop supplies a Linux virtual machine on Windows/macOS.</details>

## Common mistakes
The daemon-connect failure was triggered safely with `docker --host npipe:////./pipe/code101-verify-no-daemon info` against a nonexistent pipe, not by stopping the real engine.
These error excerpts were deliberately triggered. IDs vary. Never remove an unfamiliar container to fix a conflict.

| Error text | Cause | Fix |
|---|---|---|
| `check if the path is correct and if the daemon is running` | No reachable engine endpoint; author used a nonexistent pipe without stopping Desktop | Start Desktop and wait for Engine running; on Ubuntu use sudo systemctl start docker. Inspect docker context ls; do not change a working context blindly. |
| `docker : The term 'docker' is not recognized as the name of a cmdlet, function, script file, or operable program.` (typical message) | PowerShell was opened before Docker finished installing, so it cannot see the new command | Close PowerShell, open a new window (Step 2, item 8) and try again; if it persists, restart Windows. |
| `Conflict. The container name "/code101-verify-01-hello" is already in use by container` followed by an ID (typical message) | You ran the `docker run --name` line twice without removing the first container | Run `docker rm code101-verify-01-hello`, then run the start command again. |

The daemon-connect row is real captured text; the two rows marked typical message were not captured here.

## Best practice
Use official installation instructions and keep the working engine rather than installing a second one. Source: Docker Desktop Windows install https://docs.docker.com/desktop/setup/install/windows-install/

## Next lesson
**02. Images and containers:** inspect running and stopped containers.
