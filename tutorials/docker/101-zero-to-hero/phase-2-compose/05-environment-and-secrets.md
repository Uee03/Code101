---
track: docker
level: 101
phase: 2
phase_name: compose
lesson: 05
title: Environment variables and secrets
time: 40 min
prerequisites: [101.1.04]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-2-compose/05-environment-and-secrets/
assets: []
---

# 05. Environment variables and secrets

## Why it matters
A theatre uses the same script with different signs and a locked backstage key. **Environment variables** are named settings like the signs; a **secret** is a value such as a real password that should never be printed or shared. Separating them from an image lets you reuse that image safely.

## What you will build
A configurable web greeting with a demonstration secret mounted as a file. The page says whether it loaded, never what the secret contains.

## Before you start
- Complete lesson 04. Docker must be running: docker info must show a Server section.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 40 minutes (about 5 minutes per new idea plus setup; Docker is already installed).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-2-compose/05-environment-and-secrets/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson05" | Out-Null
Set-Location "$HOME\code101\docker\lesson05"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson05
cd ~/code101/docker/lesson05
```

Expected result: your terminal is inside `lesson05`. The prompt usually shows the folder; check with `Get-Location`
(Windows) or `pwd` (macOS/Linux). If lost, the Set-Location/cd line above returns here. All subsequent commands run here
unless marked otherwise. Stop other Docker lessons before using port 8080.

Create each file in a plain-text editor: **File > New**, paste its full contents, **File > Save As**, save in this folder.
Windows Notepad: **Save as type: All files**, encoding **UTF-8**, exact filename. In File Explorer enable
**View > Show > File name extensions** to catch accidental `.txt` suffixes. macOS TextEdit: **Format > Make Plain Text**;
disable automatic `.txt` extension when saving. Linux: use your plain-text editor. Save before running;
a dot on an editor tab usually means unsaved changes.
### Step 2. Create the supplied web app
Copy this complete Python program into app.py. It is a supplied program for learning Docker; no host Python install is needed.

**File: `app.py`**
```python
import os
from pathlib import Path
from http.server import BaseHTTPRequestHandler, HTTPServer


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        secret_loaded = bool(Path("/run/secrets/demo_token").read_text().strip())
        message = os.environ["GREETING"]
        body = f"{message}; secret-loaded={str(secret_loaded).lower()}\n".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
```
The app imports settings (os), file access (Path) and web tools. For each GET it reads /run/secrets/demo_token,
checks whether it has contents, and returns GREETING plus a true/false result. It never prints the token itself.
It sends success 200 with plain-text content, then waits for another request. Python booleans become lowercase strings here.

### Step 3. Create the image files

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

The Dockerfile instructions are not terminal commands. Its build context is this folder; COPY takes only the app and dependency list.
RUN installs dependencies during the build, while CMD starts the finished container. Changing .env does not need a build;
changing app.py or requirements.txt does.

### Step 4. Create local settings and the safe example
Create these as **two separate files** in your lesson folder. The second is safe to share; the first is where local values belong.
The password below is deliberately public and disposable. Never reuse it on a real service or replace it with a real secret in shared files.

**File: `.env.example`**
```dotenv
GREETING=Hello from settings
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Public displayed message. Changing this requires recreation, not an image rebuild. Spaces belong to the value. |

**File: `.env`**
```dotenv
GREETING=Hello from settings
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Public displayed message. Changing this requires recreation, not an image rebuild. Spaces belong to the value. |

An **environment variable** is a named value passed to a process. A real **secret** is a password/token that must not be shared.
.env is plain text, not encryption. Compose reads .env for `${NAME}` substitution; the service must also specify environment/env_file
for values to reach its process. A host environment variable can override the .env interpolation value; use a fresh terminal if results differ.
If you take the files from the optional pack instead, note that it ships `.env.example`, not `.env`: copy it to `.env` first (Windows PowerShell: `Copy-Item .env.example .env`; macOS and Linux: `cp .env.example .env`). Your own project should track only the safe `.env.example` and keep the real `.env` out of Git.

### Step 5. Ignore local files in Git
**Git** records project-file changes. If you later use Git, create this full .gitignore first:

**File: `.gitignore`**
```gitignore
.env
.env.*
!.env.example
secrets/
__pycache__/
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Do not track local settings in Git. This does not remove files already tracked. |
| 2 | Also ignore alternate environment files. |
| 3 | The ! exception allows the safe example to be tracked; order after the broad rule matters. |
| 4 | Do not track secret files; this is not encryption. |
| 5 | Do not track generated Python bytecode. |

Never commit real .env files or secrets. An ignore file does not undo an earlier commit; if a real secret was shared,
rotate/revoke it rather than assuming deletion makes it safe. We intentionally do not require Git installed for this lesson.

### Step 6. Create a demonstration secret file
In the editor's file browser create a folder named secrets under your lesson folder, then create demo_token.txt inside it:

**File: `secrets/demo_token.txt`**
```text
demo-only-not-a-real-secret
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | A public demo-only value. The app checks whether the file has contents, without displaying them. |

This exact value is public, not a credential. With a real local secret, keep the file private, restrict file permissions,
and do not paste it into screenshots/logs. The .dockerignore keeps it out of the image; .gitignore keeps it out of new commits.

### Step 7. Create the complete Compose configuration
**Compose** starts related containers from a configuration. **YAML** is the text format it reads: indentation groups settings.
A **service** is a named container configuration. Use spaces, never tabs; child keys are two spaces deeper than their parent.
Save docker-compose.yml next to Dockerfile and .env:

**File: `docker-compose.yml`**
```yaml
services:
  web:
    image: "${COMPOSE_PROJECT_NAME}-web:demo"
    build: .
    ports:
      - "127.0.0.1:8080:8000"
    env_file: .env
    secrets:
      - demo_token
secrets:
  demo_token:
    file: ./secrets/demo_token.txt
```

| Line | Explanation (changing a path/value requires matching its consumer) |
|---|---|
| 1 | Group named container configurations in this project. |
| 2 | Name the web service; peers can reach it as web. |
| 3 | Name the built image with the project prefix. Compose sets COMPOSE_PROJECT_NAME automatically from -p; demo is the tag. |
| 4 | Build the Dockerfile from this folder; the dot selects the build context. |
| 5 | Group host-to-container port mappings. |
| 6 | Bind host loopback only: host port 8080 forwards to web port 8000. Change the middle number if occupied. |
| 7 | Inject variables from this host file. Compose interpolation alone does not inject every .env variable. |
| 8 | Inside web: grant access. At the left edge: define available secret sources. |
| 9 | Grant web the file at /run/secrets/demo_token; peers do not automatically receive it. |
| 10 | Inside web: grant access. At the left edge: define available secret sources. |
| 11 | Name the top-level secret definition. |
| 12 | Read this host file at runtime. Local Compose uses a file mount, not an encrypted vault. |
This is a one-service preview of Compose; lesson 06 adds a database and explains service networking.
A secret needs both a top-level definition and a service grant. It is mounted at runtime, not baked into the image.
Local Compose secrets are file mounts, not an encrypted vault; authorized host/engine users can still access them.
## Run it
From your lesson folder, start this throwaway project. `-p` supplies a project name that groups its containers, network and volumes;
`up` creates/starts services, `-d` detaches, `--build` builds the web image. Keep the same project name for every command.

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets up -d --build
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#10 naming to docker.io/library/code101-verify-05-environment-and-secrets-web:demo done
 Network code101-verify-05-environment-and-secrets_default Created 
 Network code101-verify-05-environment-and-secrets_default Created 
 Container code101-verify-05-environment-and-secrets-web-1 Created 
 Container code101-verify-05-environment-and-secrets-web-1 Started
```
Check status; fields are name, state, health, ports:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets ps --format "{{.Name}} | {{.State}} | {{.Health}} | {{.Ports}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-05-environment-and-secrets-web-1 | running |  | 127.0.0.1:8080->8000/tcp
```
Also check which services are running:

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets ps --services --status running
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
web
```
Open `http://127.0.0.1:8080` or send a terminal request:

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from settings; secret-loaded=true
```
If the first request arrives before readiness, wait a few seconds and try again. Read web logs (the container's printed output, not a secret dump):

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets logs --no-color --tail 3 web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
web-1  | Code101 web listening on 8000
web-1  | 172.18.0.1 - - [23/Nov/2026 06:17:58] "GET / HTTP/1.1" 200 -
```
Stop and remove this project when finished. **Warning:** `-v` deletes its declared named volumes and all data inside them.
For valuable data, omit -v and take a backup first. `--remove-orphans` also removes services from this project no longer present in the file.

**Commands — folder: `your lesson folder`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets down -v --remove-orphans
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-05-environment-and-secrets-web-1 Stopping 
 Container code101-verify-05-environment-and-secrets-web-1 Stopped 
 Container code101-verify-05-environment-and-secrets-web-1 Removing 
 Container code101-verify-05-environment-and-secrets-web-1 Removed 
 Network code101-verify-05-environment-and-secrets_default Removing 
 Network code101-verify-05-environment-and-secrets_default Removed
```
Remove just your built web image (the downloaded base images/build cache are separate):

**Commands — folder: `your lesson folder`**
```powershell
docker image rm code101-verify-05-environment-and-secrets-web:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-05-environment-and-secrets-web:demo
Deleted: sha256:c269bdf3d81caee16ad3e8c19fcf21ec26e98d811fcb4e4f03c5166a1be6bae9
```

## How it works
Compose builds the image, creates web, injects GREETING through env_file, and mounts only the granted secret file at runtime. The HTTP handler reads the setting and checks whether the secret has contents. .dockerignore protects the build context; .gitignore protects new Git tracking. Neither is encryption, and secret file mounts do not protect against a host administrator.

New terms for this lesson (also in the track glossary):

- **environment variable**: A named value passed to a process.
- **secret**: A password or token that must not be printed or shared.
- **`.env` file**: A plain-text file of settings that Compose reads; it is not encrypted.
- **Compose**: The Docker tool that starts related containers from one configuration file.
- **YAML**: The indentation-based text format Compose reads.
- **service**: A named container configuration inside a Compose file.
- **project name (`-p`)**: A name that groups one Compose run's containers, network and volumes.
- **Git**: A tool that records project-file changes.

## Try it
Stop/clean up your lesson first. Make a new folder `practice` inside your lesson folder and copy every file of your finished lesson into it, including the dotfiles (`.env`, `.env.example`, `.gitignore`, `.dockerignore`) and the `secrets` folder (not `practice` itself). This is the finished baseline from the Steps. Open a terminal inside practice:

**Commands — folder: `your lesson folder`**
```powershell
Set-Location practice
```

**Commands — folder: `your lesson folder`**
```bash
cd practice
```
Expected result: you are inside `practice`, working on your own copy.
**Exercise:** make the public greeting say `Hello from the studio` without changing the image recipe. Decide which files hold that setting; never put a real token in either of them.
Everything else stays as in the Steps.
<details><summary>Solution</summary>

**File: `practice/.env`**
```dotenv
GREETING=Hello from the studio
```

**File: `practice/.env.example`**
```dotenv
GREETING=Hello from the studio
```
All other files are genuinely identical to the full Steps versions; keep their exact filenames and contents.
From practice repeat the same startup/status/logs/cleanup procedure in Run it: the only folder difference is practice,
and the same project name is reused after the original has been removed. Here are start and response for this exact solution:

**Commands — folder: `practice`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets up -d --build
```
Expected output, **excerpt** (progress is longer):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
#10 naming to docker.io/library/code101-verify-05-environment-and-secrets-web:demo done
 Network code101-verify-05-environment-and-secrets_default Created 
 Network code101-verify-05-environment-and-secrets_default Created 
 Container code101-verify-05-environment-and-secrets-web-1 Created 
 Container code101-verify-05-environment-and-secrets-web-1 Started
```

**Commands — folder: `practice`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Hello from the studio; secret-loaded=true
```
Check status and logs in practice with the identical commands from Run it (same project name).
Then clean up **from practice** using the exact final commands below:

**Commands — folder: `practice`**
```powershell
docker compose -p code101-verify-05-environment-and-secrets down -v --remove-orphans
docker image rm code101-verify-05-environment-and-secrets-web:demo
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Container code101-verify-05-environment-and-secrets-web-1 Stopping 
 Container code101-verify-05-environment-and-secrets-web-1 Stopped 
 Container code101-verify-05-environment-and-secrets-web-1 Removing 
 Container code101-verify-05-environment-and-secrets-web-1 Removed 
 Network code101-verify-05-environment-and-secrets_default Removing 
 Network code101-verify-05-environment-and-secrets_default Removed
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
Untagged: code101-verify-05-environment-and-secrets-web:demo
Deleted: sha256:2835ce9ce5e0976659d3e6f82d9e0021670276149468eeead80487007d1f7315
```
On macOS/Linux the Docker commands are identical; use curl instead of curl.exe. Ubuntu: sudo before Docker.
</details>


## Check yourself
1. Does Compose automatically pass every .env value into web?
   <details><summary>Answer</summary>No. Use environment or env_file in the service.</details>
2. Does .env encrypt a password?
   <details><summary>Answer</summary>No; it is a plain-text settings file.</details>
3. Where does the demo secret appear in the container?
   <details><summary>Answer</summary>/run/secrets/demo_token.</details>
4. Does changing GREETING require rebuilding the app image?
   <details><summary>Answer</summary>No; recreate the container with Compose up to refresh the runtime setting.</details>

## Common mistakes
These error excerpts were deliberately triggered. IDs vary. Never remove an unfamiliar container to fix a conflict.

| Real error text | Cause | Fix |
|---|---|---|
| `Bind for 127.0.0.1:8080 failed: port is already allocated` | Another running container owns host port 8080 | Run docker ps; stop only your earlier container, or change host 8080 to 8081 (leave the container port unchanged). |
| `did not find expected key` | ports indented 3 spaces instead of 4 | Use spaces, align ports with image under web, restore the full file, then docker compose config --quiet. |
| `check if the path is correct and if the daemon is running` | No reachable engine endpoint; author used a nonexistent pipe without stopping Desktop | Start Desktop and wait for Engine running; on Ubuntu use sudo systemctl start docker. Inspect docker context ls; do not change a working context blindly. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to your lesson folder (the `Set-Location` or `cd` line in Step 1) and repeat the command. |
| `env file` ... `.env not found: stat` ... `no such file or directory` (typical message) | `.env` is missing, for example you only created `.env.example` or copied from the pack without copying it to `.env` | Create `.env` (Step 4) or run the copy command shown there, then run `up` again. |

Rows marked typical message were not captured here.

## Best practice
Use file-mounted secrets rather than baking secrets into an image; keep real secret files out of version control. Source: Docker Compose secrets https://docs.docker.com/compose/how-tos/use-secrets/

## Next lesson
**06. Networks and Compose basics:** connect two services by name.
