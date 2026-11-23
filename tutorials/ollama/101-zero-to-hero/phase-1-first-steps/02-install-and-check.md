---
track: ollama
level: 101
phase: 1
phase_name: first-steps
lesson: 02
title: 'Install and check Ollama on your OS'
time: '60-75 min'
prerequisites: [101.1.01]
versions: { ollama: 'current native stable; docs checked 2026-11-23' }
verified: not yet run
source: source/ollama/101-zero-to-hero/phase-1-first-steps/02-install-and-check/
assets: []
---

# 02. Install and check Ollama on your OS

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Install Ollama natively using the correct official OS script, after reading it.
- Distinguish an installed client from a running server without auto-starting the app.
- Start and stop one native server intentionally while keeping port 11434 on loopback.


## Recap
1. Is Ollama itself a model?
   <details><summary>Answer</summary>No. It downloads and runs separate model files.</details>
2. Does local inference make private records safe to use in exercises?
   <details><summary>Answer</summary>No. Use public or invented data; the computer and other apps may expose private text.</details>


## Why it matters
Installing a kitchen appliance is different from switching it on. Likewise, finding an Ollama command does not prove a server is listening. Some convenient commands even start the application, so we inspect state before using them.


## What you will build
One native Ollama installation and a setup record. No model is downloaded in this lesson. Follow only your operating system's branch.


## Before you start
- Time: 60-75 minutes; downloads or driver problems may take longer. Pause after Step 3 if needed.
- Permission to install background software and use internet access. Installation can start the app/service automatically; that is an installation side effect, not a passive check.
- Requirements checked **2026-11-23**: Windows 10 22H2+; macOS Sonoma 14+ (Apple Silicon CPU/GPU, supported Intel Macs CPU only). Linux: a supported native distribution/architecture with `curl`; the usual installer uses systemd, a Linux service manager, where available. Consult your administrator if tools or privileges are missing.
- Windows installation needs at least 4 GB for the application per the Windows docs, plus room for future models. GPU acceleration is optional. A **driver** is software that lets the operating system use a hardware device. Do not install random driver overrides from a forum.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished example, exercise starter and solution are in https://github.com/Uee03/Code101 under `source/ollama/101-zero-to-hero/phase-1-first-steps/02-install-and-check/`. Choose **Code > Download ZIP**, or use `git clone https://github.com/Uee03/Code101.git` if you already use Git.
- To extract a ZIP: Windows, right-click > **Extract All > Extract**; macOS, double-click; Linux, right-click > **Extract Here** in your archive manager. Open `Code101-main`, then the source path above. A phase ZIP instead starts with its phase-pack folder.
- Model responses below are documented **shapes**, not captured output. Answers, timings and streaming chunk boundaries vary.

## Steps
### Step 1. Open a terminal and a work folder

A **terminal** is a window for typing commands. Windows: Start > type **PowerShell** > open it, not Python. macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from your applications menu. Do not type the prompt's leading `>` or `$`. The text before that symbol usually shows the current folder.

Create a separate practice folder. `$HOME` (PowerShell) and `~` (macOS/Linux) mean your home folder. These commands start in any folder; the second line is also your recovery command if you get lost.

**File: `Terminal, Windows PowerShell; starting anywhere`**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/ollama02" -Force | Out-Null
Set-Location "$HOME/code101/ollama02"
```

**File: `Terminal, macOS/Linux; starting anywhere`**
```bash
mkdir -p ~/code101/ollama02
cd ~/code101/ollama02
```
Expected result, not yet run: the folder exists and the terminal is inside it; these commands normally print nothing.
Use a plain-text editor for files below. Windows: Notepad, **Save As**, choose **All files**, UTF-8; turn on File Explorer **View > Show > File name extensions** so `.json` does not become `.json.txt`. macOS: TextEdit > **Format > Make Plain Text**, disable smart quotes and automatic `.txt` extension. Linux: your plain-text Text Editor. An existing VS Code install is also fine: **File > Open Folder**, select this folder, then **Terminal > New Terminal**. A dot on an editor tab means unsaved; save with Ctrl+S (macOS Cmd+S). No editor extension or account is needed.

A **client** sends requests; the **server** is the background program that answers them. **HTTP (Hypertext Transfer Protocol)** is the request/response protocol used here. A **port** is a numbered network endpoint, like an apartment number at an address. Ollama's default is **11434**. **Loopback** (`127.0.0.1`, commonly reached as `localhost`) refers to this computer, not the whole local network. **PATH** is the OS list of folders searched for commands.

### Step 2. Read the installer, then decide to install
The official quick commands are shown for recognition. **Choose either the read-first route or the quick route, not both.** A **shell** interprets terminal commands. A pipe (`|`) sends downloaded text to another program; `iex` evaluates PowerShell text and `sh` runs a shell script. Reading first lets you examine what will change. It is not proof of safety: verify the official HTTPS address and ask a knowledgeable person if you do not understand it. Do not bypass an organisation's script policy.

**File: `PowerShell; folder ~/code101/ollama02; official quick route (alternative)`**
```powershell
irm https://ollama.com/install.ps1 | iex
```

**File: `PowerShell; same folder; recommended read-first route, first part only`**
```powershell
Invoke-RestMethod https://ollama.com/install.ps1 -OutFile install-ollama.ps1
notepad install-ollama.ps1
```
Read the downloaded script in Notepad, including its download source and installation actions. Close Notepad. Only if you approve it, enter this separate command. If the execution policy blocks it, stop and consult the official installer/your administrator; do not weaken the machine's policy.

**File: `PowerShell; folder ~/code101/ollama02; after reading`**
```powershell
.\install-ollama.ps1
```
The Windows script installs the signed application for your account, normally under `%LOCALAPPDATA%\Programs\Ollama`, and adds the command to your user PATH. Administrator mode is not normally required. The native app can run in the background after installation.

**File: `macOS/Linux terminal; folder ~/code101/ollama02; official quick route (alternative)`**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**File: `macOS/Linux terminal; same folder; recommended read-first route, first part only`**
```bash
curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
```
Open `install-ollama.sh` in your plain-text editor using **File > Open**. Read it and close the editor. Only after approving its actions, enter:

**File: `macOS/Linux terminal; folder ~/code101/ollama02; after reading`**
```bash
sh install-ollama.sh
```
`curl` downloads data; `-f` treats HTTP failures as errors, `-sS` hides progress but keeps errors, `-L` follows redirects and `-o` chooses a file. The script handles macOS and Linux natively. It may ask for your password for system changes. On a normal systemd Linux install it configures a native service, a background program managed by the operating system. On macOS it installs the native application. This is not Docker or WSL setup.

Expected result, not yet run: installer progress appropriate to your OS. Exact messages change; there is no captured installer output in this draft. Read any failure before proceeding. **Close your terminal and open a new one** after installing so the updated PATH is visible. Return with `cd ~/code101/ollama02` (works in both shells).

### Step 3. Inspect without starting anything
Do **not** begin with `ollama list`, `ollama ps` or `ollama run`. On Windows/macOS these may launch the app when the server is absent. Predict: if the executable exists but the API does not answer, must you reinstall? Check yourself before taking action.

**File: `Windows PowerShell; folder ~/code101/ollama02`**
```powershell
Get-Command ollama | Select-Object Source
Get-Process *ollama* -ErrorAction SilentlyContinue | Select-Object Name,Id
Get-NetTCPConnection -LocalPort 11434 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess
Invoke-RestMethod -Uri http://127.0.0.1:11434/api/version -TimeoutSec 5
```
The first line locates the client without running it. The second observes processes. The third observes listeners and their process ID. If an unknown process owns the port, inspect its exact ID in Task Manager; do not kill processes by name. The last line asks an **already listening** server for its version; an HTTP GET does not launch Ollama. A connection failure when no server is listening is useful information, not an instruction to reinstall.

**File: `macOS terminal; folder ~/code101/ollama02`**
```bash
command -v ollama
ps -axo pid,comm | grep -i '[o]llama'
lsof -nP -iTCP:11434 -sTCP:LISTEN
curl --fail --show-error --silent --max-time 5 http://127.0.0.1:11434/api/version
```

**File: `Linux terminal; folder ~/code101/ollama02`**
```bash
command -v ollama
ps -eo pid,comm | grep -i '[o]llama'
ss -ltnp 'sport = :11434'
systemctl status ollama --no-pager
curl --fail --show-error --silent --max-time 5 http://127.0.0.1:11434/api/version
```
On Linux without systemd, skip only `systemctl status`; the process, socket and HTTP checks still apply. `--no-pager` avoids an interactive full-screen viewer. Some systems hide other users' process owners; ask your administrator rather than changing permissions.

Inspect the listening address: `127.0.0.1` or `::1` is loopback. `0.0.0.0`, `::` or a LAN address is not loopback-only: stop and review the existing configuration. Do not expose port 11434 or change a firewall. Local API access has no built-in authentication.

**File: `Documented JSON shape from /api/version; not captured output`**
```json
{"version":"<installed server version>"}
```
PowerShell displays an object/table rather than necessarily printing raw JSON. Missing process/socket rows mean nothing matching was observed; they do not prove an installation failed. There can be a short startup delay after an installer.

### Step 4. Start deliberately only if needed
If `/api/version` already answers from your intended server, **skip starting**. Never start a second listener on the same port.

| OS | Intentional start | Intentional stop |
|---|---|---|
| Windows | Start menu > type **Ollama** > open the app | Right-click the Ollama tray icon (possibly under hidden icons) > **Quit** |
| macOS | Finder > Applications > **Ollama** | Ollama menu-bar icon > **Quit** |
| Linux with systemd | In the current terminal: `sudo systemctl start ollama` | In the current terminal: `sudo systemctl stop ollama` |
| Native terminal-only installation, any OS | In a dedicated terminal: `ollama serve`; leave it open | Press Ctrl+C in that same terminal |

Choose only one route. For a terminal-only installation, open a second terminal for future client requests. Repeat the Step 3 checks verbatim after your intentional start; no file or command changes are needed. A version response is the success condition, not any one startup message.

### Step 5. Save the setup record
Fill the blanks from your observations; do not paste private logs. Create this complete template as `setup-checklist.md` in the current folder.

**File: `~/code101/ollama02/setup-checklist.md`**
```markdown
# Native setup record

Operating system and version:
Installer source: https://ollama.com/download or the official install script.
Read the script before running it: yes / not yet.
Permission to install and start background software: yes / not yet.
Free space includes the app, model downloads and spare working space: yes / not yet.
Executable location found after opening a new terminal:
Existing process observed, without using list/ps/run:
Port 11434 listening address and owner:
GET /api/version: answered / no server listening.
Explicit decision to start the app or service, if needed:
Loopback only: yes / stop and investigate.
Model downloads: none in this lesson.
```


## Run it
Repeat only your OS branch of Step 3, from `~/code101/ollama02`; these are passive checks, not another installation. Expected result, not yet run: an executable location and, if intentionally started, a loopback listener and version field. If you stop the app using Step 4, repeat the API check: it should no longer connect. Do not use list/ps/run to prove it is stopped.


## How it works
Command discovery proves the client exists. Process and port inspection find background state. `/api/version` tests the HTTP server without loading a model. Most common misconception: **a missing server response means the client is missing**. They are separate. A GPU is not needed for any of these checks.

Windows needs a current NVIDIA driver if using NVIDIA; AMD ROCm on Windows requires a ROCm v7/HIP7-capable stack for supported cards. Vulkan can cover additional AMD/Intel/NVIDIA hardware when available. Apple Silicon uses Metal; supported Intel Macs use CPU. AMD support differs between Windows and Linux: do not copy Linux override settings onto Windows. Check the [official GPU list](https://docs.ollama.com/gpu) and your vendor's driver instructions rather than promising acceleration. Lesson 03 checks actual memory placement.


## Try it
**Guided:** diagnose the invented scenario below without running any command. Fill four TODOs. Without a pack, create `~/code101/ollama02/exercise/diagnosis.md` with the full starter. With a pack, instead copy `02-install-and-check/exercise/starter` **as a folder** into `ollama02`, rename the copy `exercise`; do not nest `starter` inside it.

**File: `~/code101/ollama02/exercise/diagnosis.md`**
```markdown
# Invented setup scenario, not captured terminal output

The executable was found. No Ollama process was observed. Port 11434 has no listener.
A request to /api/version did not connect.
Diagnosis: TODO
Next action requiring explicit permission: TODO
Health check to repeat without starting the app: TODO
Command to avoid as an initial health check: TODO
```

**Change:** explain what you would investigate if a different application owned 11434. Do not stop or modify it. **Stretch (optional):** find the official log location for your OS and write its path without sharing the log. Success is a diagnosis, not a model reply.

<details><summary>Solution</summary>

**File: `~/code101/ollama02/exercise/diagnosis.md`**
```markdown
# Invented setup scenario, not captured terminal output

The executable was found. No Ollama process was observed. Port 11434 has no listener.
A request to /api/version did not connect.
Diagnosis: the client is installed, but no server is listening on the expected port.
Next action requiring explicit permission: open the native app or start the native service.
Health check to repeat without starting the app: request GET /api/version on loopback.
Command to avoid as an initial health check: ollama list, because it may start the app.
```

A deliberate start may be needed; reinstallation is not the first response.
</details>


## Check yourself
1. Why read the install script before piping it into a shell?
   <details><summary>Answer</summary>A shell executes downloaded instructions with your permissions. Read the saved file, verify the official source and approve the changes first.</details>
2. Predict: client found, but no process/listener and no version response. Must you reinstall?
   <details><summary>Answer</summary>No. The client can be installed while the server is stopped. Start intentionally if you want it running.</details>
3. Why is `ollama list` a poor first check of whether the app is stopped?
   <details><summary>Answer</summary>It may start the native app. Observe processes, sockets and /api/version instead, and keep the listener on loopback.</details>


## Common mistakes
| Symptom or typical message, not captured | Cause | Fix |
|---|---|---|
| Command discovery finds nothing just after installation | Old terminal PATH | Close the terminal, open a new one, then locate the command again. |
| The saved script has an extra `.txt` extension | Editor filename handling | Enable extensions and save the exact filename. |
| Script execution is blocked | PowerShell or organisation policy | Do not bypass it; consult the official download page/administrator for the approved installer route. |
| API connection fails | No listener, startup still in progress, or wrong owner | Inspect process and port, then deliberately start the intended app once if needed. |
| Typical message: address already in use | A second server was started | Keep the existing intended server; stop only your extra foreground server with Ctrl+C. |


## Best practice
Keep the default loopback binding; do not open the unauthenticated API to a network to solve a local connection issue. Source: Ollama Local FAQ, network binding https://docs.ollama.com/faq


## Going further
Official OS guides: [Windows](https://docs.ollama.com/windows), [macOS](https://docs.ollama.com/macos), [Linux](https://docs.ollama.com/linux). These also describe logs and removal. Do not delete the model directory as a troubleshooting shortcut.


## Summary
- You selected a native official installer and a read-first route.
- You distinguished command availability from running-server health without auto-start commands.
- You learned deliberate start/stop routes and the loopback safety boundary.


<details><summary>Draft text/source consistency record, 2026-11-23</summary>

This recorded result checked text/source consistency only. It did not run this example or contact Ollama. Runtime behaviour remains unverified.

**File: `Authoring record; not example output`**
```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/02-install-and-check
```

</details>

## Next lesson
[03. Pull and chat with a model in the terminal](03-pull-and-chat.md): download one small local model and distinguish disk storage from loaded memory.
