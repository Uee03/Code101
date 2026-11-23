---
track: docker
level: 101
phase: 1
phase_name: containers
lesson: 03
title: Your first Dockerfile
time: 30 min
prerequisites: [101.1.02]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-1-containers/03-your-first-dockerfile/
assets: []
---

# 03. Your first Dockerfile

## Why it matters
A recipe card tells a kitchen which ingredients to use and what to do first. A **Dockerfile** is that card for an image. Building packages your saved files so starting the resulting container does not depend on your host Python installation.

## What you will build
A tiny Python HTTP page built into your own image, with an explicit image recipe and ignored build files.

## Before you start
- Complete lesson 02. Docker must be running: docker info must show a Server section.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 30 minutes (about 5 minutes per new idea plus setup; Docker is already installed).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-1-containers/03-your-first-dockerfile/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson03" | Out-Null
Set-Location "$HOME\code101\docker\lesson03"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson03
cd ~/code101/docker/lesson03
```

Expected result: your terminal is inside `lesson03`. The prompt usually shows the folder; check with `Get-Location`
(Windows) or `pwd` (macOS/Linux). If lost, the Set-Location/cd line above returns here. All subsequent commands run here
unless marked otherwise. Stop other Docker lessons before using port 8080.

Create each file in a plain-text editor: **File > New**, paste its full contents, **File > Save As**, save in this folder.
Windows Notepad: **Save as type: All files**, encoding **UTF-8**, exact filename. In File Explorer enable
**View > Show > File name extensions** to catch accidental `.txt` suffixes. macOS TextEdit: **Format > Make Plain Text**;
disable automatic `.txt` extension when saving. Linux: use your plain-text editor. Save before running;
a dot on an editor tab usually means unsaved changes.

### Step 2. Create the app file
Create app.py in your lesson folder. This is a small supplied Python program; the Python track teaches writing programs from scratch.
Here you only need to understand where it lives and what it answers. **HTTP** is the request/response protocol used by web browsers.

**File: `app.py`**
```python
from http.server import BaseHTTPRequestHandler, HTTPServer


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"Hello from my image!\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
```

The first line imports Python's built-in web server tools. Page handles each GET request (asking for a page). The body is bytes
(the `b` prefix), with a newline (`\n`). `200` means success. The Content-Type header identifies plain text; end_headers finishes
those metadata lines, and write sends the body. The print goes to logs; HTTPServer listens on **0.0.0.0 inside the container**,
port 8000. This allows Docker's forwarding to reach it. That is different from publishing the host port on 127.0.0.1.

### Step 3. Create the complete image recipe
Create Dockerfile, with no extension, alongside app.py. A **build context** is the set of host files made available to the image build.
A **layer** is a filesystem change saved in an image; builders can reuse unchanged steps to speed later builds.

**File: `Dockerfile`**
```dockerfile
FROM python:3.13-slim
LABEL code101.owner="docker-101"
WORKDIR /app
COPY app.py .
RUN python -m compileall -q app.py
CMD ["python", "-u", "app.py"]
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Start with this tagged Python/Linux image; changing it changes the runtime. The slim variant has fewer extra tools. |
| 2 | Attach course ownership metadata. Labels are not a secret store. |
| 3 | Make /app the folder for later instructions and the running command. |
| 4 | Copy the app into /app; host edits require a rebuild. |
| 5 | Quietly compile the file during the build, catching syntax errors; not a test suite. |
| 6 | Default startup command as a JSON list. -u sends logs immediately; app.py must match the copied filename. |

FROM, WORKDIR, COPY, RUN and CMD are Dockerfile instructions, not terminal commands. RUN happens while building;
CMD is used when a container starts. Changing app.py does not change an already-built image.

### Step 4. Keep unwanted files out of the build
Create the full .dockerignore in the same folder. Its leading dot is part of its name:

**File: `.dockerignore`**
```text
__pycache__/
*.pyc
.git/
.env
.env.*
secrets/
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Exclude generated Python bytecode folders from the build context. |
| 2 | Exclude individual bytecode files; * matches any name. |
| 3 | Exclude version-history files from the image build. |
| 4 | Exclude local runtime settings; Compose can still read them on the host. |
| 5 | Exclude alternate environment files, including .env.example, from the build. |
| 6 | Exclude the entire host secrets directory from images. |

These rules affect the build context, not which host files exist. We use explicit COPY instructions as well as exclusions.

## Run it
Build in your lesson folder; the final dot means use **this folder**, not the parent:

**Commands — folder: `your lesson folder`**
```powershell
docker build -t code101-verify-03-your-first-dockerfile:demo .
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#9 naming to docker.io/library/code101-verify-03-your-first-dockerfile:demo done
```

**Commands — folder: `your lesson folder`**
```powershell
docker run -d --name code101-verify-03-web -p 127.0.0.1:8080:8000 code101-verify-03-your-first-dockerfile:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
9eebc729a13da8e150cdf58424e7afa2ba447d75ffb634fb90b5b2e78d42822b
```

**Commands — folder: `your lesson folder`**
```powershell
docker ps --filter name=code101-verify-03-web --format "{{.Names}} | {{.State}} | {{.Ports}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-03-web | running | 127.0.0.1:8080->8000/tcp
```

Open `http://127.0.0.1:8080` in a browser, or make a terminal request:

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from my image!
```


**Commands — folder: `your lesson folder`**
```powershell
docker logs --tail 3 code101-verify-03-web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Code101 web listening on 8000
```
The printed startup message and GET 200 line prove the process started and received the request. Stop/remove it:

**Commands — folder: `your lesson folder`**
```powershell
docker stop code101-verify-03-web
docker rm code101-verify-03-web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-03-web
code101-verify-03-web
```

These exact stop/remove commands were also run and captured on the author machine. Remove your built image when done:

**Commands — folder: `your lesson folder`**
```powershell
docker image rm code101-verify-03-your-first-dockerfile:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-03-your-first-dockerfile:demo
Deleted: sha256:ed77bbe8a9b759d149c507641fa66735a819e0a12dfc1fa058c19c650ff306be
```

Image deletion outputs include a variable content hash. They do not remove the Python base image or shared build cache.

## How it works
Build starts with Python/Linux, sets /app, copies the saved app, compiles it, and records its startup command. run starts that command; the HTTP server then waits for a request. Port 8080 on the host routes to 8000 in the container. The standard-library server is a local teaching tool, not a production server.

New terms for this lesson (also in the track glossary):

- **Dockerfile**: A text file of instructions (the recipe card) for building an image.
- **HTTP**: The request/response protocol used by web browsers.
- **build context**: The set of host files made available to an image build.
- **layer**: A filesystem change saved in an image; unchanged layers can be reused to speed later builds.
- **`.dockerignore`**: A file listing paths to leave out of the build context.
- **instruction**: A Dockerfile line such as FROM, COPY, RUN or CMD (not a terminal command).

## Try it
Stop/clean up your lesson first. Make a new folder `practice` inside your lesson folder and copy your three finished files into it: `app.py`, `Dockerfile` and `.dockerignore` (the last one starts with a dot and may be hidden in your file manager). Open a terminal inside practice:

**Commands — folder: `your lesson folder`**
```powershell
New-Item -ItemType Directory -Force practice | Out-Null
Copy-Item app.py, Dockerfile, .dockerignore practice
Set-Location practice
```

**Commands — folder: `your lesson folder`**
```bash
mkdir -p practice
cp app.py Dockerfile .dockerignore practice/
cd practice
```
Expected result: you are inside `practice`, working on your own copy.
**Exercise:** make the page greet visitors with `Hello from the bakery!` (still followed by a newline) instead of the current greeting. Then get the new greeting to appear in your browser: think about what must happen to the image before the change can show up. Dockerfile and .dockerignore need no changes.
<details><summary>Solution</summary>

**File: `practice/app.py`**
```python
from http.server import BaseHTTPRequestHandler, HTTPServer


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"Hello from the bakery!\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
```

From practice, after the original container/image are removed:

**Commands — folder: `practice`**
```powershell
docker build -t code101-verify-03-your-first-dockerfile:demo .
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#9 naming to docker.io/library/code101-verify-03-your-first-dockerfile:demo done
```

**Commands — folder: `practice`**
```powershell
docker run -d --name code101-verify-03-solution -p 127.0.0.1:8080:8000 code101-verify-03-your-first-dockerfile:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
2a475d9f3bbcf52f2f8895e86e54f8adf4e4044d2613c390e3d096a980feb5b9
```

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from the bakery!
```


**Commands — folder: `practice`**
```powershell
docker logs --tail 3 code101-verify-03-solution
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Code101 web listening on 8000
```

**Commands — folder: `practice`**
```powershell
docker stop code101-verify-03-solution
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-03-solution
```

**Commands — folder: `practice`**
```powershell
docker rm code101-verify-03-solution
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-03-solution
```

**Commands — folder: `practice`**
```powershell
docker image rm code101-verify-03-your-first-dockerfile:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-03-your-first-dockerfile:demo
Deleted: sha256:9192aa1162d5c2434b3e06a9e8467aa9ed622ea8596320d7f4febb23f36331be
```
On macOS/Linux the Docker commands are identical (Ubuntu: sudo).
</details>


## Check yourself
1. When does RUN execute?
   <details><summary>Answer</summary>During the image build.</details>
2. When does CMD execute?
   <details><summary>Answer</summary>When a container starts, unless overridden.</details>
3. What does the final build dot mean?
   <details><summary>Answer</summary>Use the current folder as the build context.</details>
4. Will editing a host file change a running container image?
   <details><summary>Answer</summary>No: rebuild and recreate the container.</details>

## Common mistakes
The port conflict row was deliberately triggered. IDs vary. Never remove an unfamiliar container to fix a conflict. Rows marked typical message were not captured here.

| Error text | Cause | Fix |
|---|---|---|
| `Bind for 127.0.0.1:8080 failed: port is already allocated` | Another running container owns host port 8080 | Run docker ps; stop only your earlier container, or change host 8080 to 8081 (leave the container port unchanged). |
| `failed to read dockerfile: open Dockerfile: no such file or directory` (typical message, shown after `ERROR: failed to solve:`) | You ran `docker build` in the wrong folder, or saved the file as `Dockerfile.txt` | Move to the folder holding `Dockerfile` (the `Set-Location` or `cd` line in Step 1) and turn on **File name extensions** to remove any `.txt`. |
| `check if the path is correct and if the daemon is running` (captured in lesson 01; the full line varies by system) | Docker Desktop is not running | Start Docker Desktop, wait for **Engine running**, then repeat the command. |
| The old greeting is still shown after your edit (no error) | You edited `app.py` but did not rebuild, or an old container still owns port 8080 | Remove the old container, run the `docker build` line again, then start a new container. |

## Best practice
Keep secrets and unnecessary files out of the build context; copy only needed files. Source: Dockerfile reference https://docs.docker.com/reference/dockerfile/

## Next lesson
**04. Data that survives:** keep data outside replaceable containers.
