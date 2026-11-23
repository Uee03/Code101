---
track: docker
level: 101
phase: 1
phase_name: containers
lesson: 02
title: Images and containers
time: 30 min
prerequisites: [101.1.01]
versions: { docker: "29.9.3", desktop: "4.99.0", compose: "5.7.0", wsl: "3.0.5 / Ubuntu-26.04" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose v5.7.0
source: source/docker/101-zero-to-hero/phase-1-containers/02-images-and-containers/
assets: []
---

# 02. Images and containers

## Why it matters
A cake recipe is not a cake. An **image** is the recipe and ingredients; a **container** is one cake made from them. You can create two containers from the same image and stop one without deleting the image.

## What you will build
An nginx web page reachable only from your computer at http://127.0.0.1:8080, and its full container lifecycle.

## Before you start
- Complete lesson 01. Docker must be running: docker info must show a Server section.
- Author baseline: Windows 11, CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04, 2026-11-23.
  Windows labs actually ran. macOS/Linux installation routes are official-docs checked, not machine-tested.
  WSL integration is off on the author machine; use PowerShell with Desktop rather than installing a second engine in Ubuntu.
- Time: about 30 minutes (about 5 minutes per new idea plus setup; Docker is already installed).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/101-zero-to-hero/phase-1-containers/02-images-and-containers/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Force "$HOME\code101\docker\lesson02" | Out-Null
Set-Location "$HOME\code101\docker\lesson02"
```
macOS/Linux, from any folder:

**Commands — folder: `any folder`**
```bash
mkdir -p ~/code101/docker/lesson02
cd ~/code101/docker/lesson02
```

Expected result: your terminal is inside `lesson02`. The prompt usually shows the folder; check with `Get-Location`
(Windows) or `pwd` (macOS/Linux). If lost, the Set-Location/cd line above returns here. All subsequent commands run here
unless marked otherwise. Stop other Docker lessons before using port 8080.

Create each file in a plain-text editor: **File > New**, paste its full contents, **File > Save As**, save in this folder.
Windows Notepad: **Save as type: All files**, encoding **UTF-8**, exact filename. In File Explorer enable
**View > Show > File name extensions** to catch accidental `.txt` suffixes. macOS TextEdit: **Format > Make Plain Text**;
disable automatic `.txt` extension when saving. Linux: use your plain-text editor. Save before running;
a dot on an editor tab usually means unsaved changes.

### Step 2. Read an image name and save the checklist
A **registry** is an online image store, such as Docker Hub. A **tag** is the label after the colon:
`nginx:1.28-alpine` selects nginx 1.28 on Alpine Linux. Tags can receive patch updates; this tag was pulled successfully on
2026-11-23, with digest `sha256:a8b39bd9cf0f83869a2162827a0caf6137ddf759d50a171451b335cecc87d236`.
nginx is a web server: a program answering web requests. Save this complete PowerShell checklist in your lesson folder:

**File: `lifecycle.ps1`**
```powershell
docker pull nginx:1.28-alpine
docker run -d --name code101-verify-02-web -p 127.0.0.1:8080:80 nginx:1.28-alpine
docker ps --filter name=code101-verify-02-web --format "{{.Names}} | {{.State}} | {{.Ports}}"
docker exec code101-verify-02-web nginx -v
docker logs --tail 3 code101-verify-02-web
docker stop code101-verify-02-web
docker rm code101-verify-02-web
```

Do not run it all at once yet: it would stop the page before you visit it. Use the individual commands below.
On macOS/Linux the Docker lines are identical; type them directly (Ubuntu: sudo). `pull` downloads the image, `run -d`
starts a container in the background (detached), `ps` lists running containers, `exec` runs a command inside one,
`logs` reads its output, `stop` asks it to finish, and `rm` removes the stopped container.
`--format` selects fields rather than displaying a wide table; the double braces belong to Docker's formatting syntax.

### Step 3. Understand the numbered doorways
Your **host** is your computer. A **port** is a numbered network doorway.
`-p 127.0.0.1:8080:80` means: bind host address 127.0.0.1, host port 8080, forward to container port 80.
**Loopback**, 127.0.0.1, is reachable only on this computer. Your browser uses 8080; nginx listens on 80 inside its own container.
Changing 8080 to 8081 moves the host doorway; changing 80 without reconfiguring nginx breaks the route.
Omitting 127.0.0.1 can expose the server on your other network interfaces. Keep it for a beginner local lab.

## Run it
Pull (repeated pulls reuse downloaded layers):

**Commands — folder: `your lesson folder`**
```powershell
docker pull nginx:1.28-alpine
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
1.28-alpine: Pulling from library/nginx
Digest: sha256:a8b39bd9cf0f83869a2162827a0caf6137ddf759d50a171451b335cecc87d236
Status: Image is up to date for nginx:1.28-alpine
docker.io/library/nginx:1.28-alpine
```

**Commands — folder: `your lesson folder`**
```powershell
docker run -d --name code101-verify-02-web -p 127.0.0.1:8080:80 nginx:1.28-alpine
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
b6fba0c3b73900c429889f176a7b484a462e19039da7977768feb124956b2106
```

The long string is a container ID, not an error. Check status:

**Commands — folder: `your lesson folder`**
```powershell
docker ps --filter name=code101-verify-02-web --format "{{.Names}} | {{.State}} | {{.Ports}}"
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-02-web | running | 127.0.0.1:8080->80/tcp
```

Open your browser, enter `http://127.0.0.1:8080`, press Enter. You should see **Welcome to nginx!**.
Or probe from the terminal:

**Commands — folder: `your lesson folder`**
```powershell
curl.exe -fsS http://127.0.0.1:8080/
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Read the last three log lines (**logs** are text a program writes to its output streams) and run a command inside the container:

**Commands — folder: `your lesson folder`**
```powershell
docker logs --tail 3 code101-verify-02-web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
172.17.0.1 - - [23/Nov/2026:06:17:44 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.22.0" "-"
```

**Commands — folder: `your lesson folder`**
```powershell
docker exec code101-verify-02-web nginx -v
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
nginx version: nginx/1.28.3
```

nginx writes its version to the error stream; this is normal for `nginx -v`, not a failing command.
Stop and remove only this container:

**Commands — folder: `your lesson folder`**
```powershell
docker stop code101-verify-02-web
docker rm code101-verify-02-web
```

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
code101-verify-02-web
code101-verify-02-web
```

`stop` retains the container and its logs; `rm` removes it. The downloaded image is not removed by either command.

## How it works
The registry supplies an image. The engine creates an isolated container and installs a host port forwarding rule. Your browser sends a request to the host port; nginx handles it on container port 80. exec launches a separate process inside the existing container, while logs reads saved process output.

New terms for this lesson (also in the track glossary):

- **image**: The recipe and files from which containers are made.
- **container**: One running (or stopped) instance made from an image.
- **registry**: An online image store, such as Docker Hub.
- **tag**: The label after the colon in an image name, such as `1.28-alpine`.
- **nginx**: A web server, a program that answers web requests.
- **host**: Your own computer.
- **port**: A numbered network doorway.
- **loopback**: The address 127.0.0.1, reachable only on this computer.
- **detached (`-d`)**: Running in the background so the terminal stays free.

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
**Exercise:** run a second copy of the same nginx image that is reachable in your browser on host port 8081, with the container name `code101-verify-02-exercise`.
Follow the same lifecycle as in Run it (pull, start, list, nginx version, last 3 log lines, stop, remove), changing only what the new name and port require. Before running, explain to yourself which of the two port numbers must stay unchanged and why. Visit the page before you stop the container.
<details><summary>Solution</summary>

**File: `practice/lifecycle.ps1`**
```powershell
docker pull nginx:1.28-alpine
docker run -d --name code101-verify-02-exercise -p 127.0.0.1:8081:80 nginx:1.28-alpine
docker ps --filter name=code101-verify-02-exercise --format "{{.Names}} | {{.State}} | {{.Ports}}"
docker exec code101-verify-02-exercise nginx -v
docker logs --tail 3 code101-verify-02-exercise
docker stop code101-verify-02-exercise
docker rm code101-verify-02-exercise
```

In practice, type the first four Docker lines, then visit `http://127.0.0.1:8081` before executing the log/stop/remove lines.
macOS/Linux use these identical Docker commands directly (Ubuntu: sudo). The page says `Welcome to nginx!`, nginx reports the same
version, and stop/remove each print `code101-verify-02-exercise`. The same full page shown above was received on 8081.

Full output from the executed Windows solution checklist (stdout and stderr shown separately):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
1.28-alpine: Pulling from library/nginx
Digest: sha256:a8b39bd9cf0f83869a2162827a0caf6137ddf759d50a171451b335cecc87d236
Status: Image is up to date for nginx:1.28-alpine
docker.io/library/nginx:1.28-alpine
1dba761d665eb6383e7ba2bca646f3560f0023eff93a674671e44646ab063a17
code101-verify-02-exercise | running | 127.0.0.1:8081->80/tcp
code101-verify-02-exercise
code101-verify-02-exercise
```
The program error stream (not necessarily an error):

**Captured output (2026-11-23; IDs, timings and timestamps vary):**
```text
nginx version: nginx/1.28.3
2026/11/23 06:17:37 [notice] 1#1: start worker process 43
2026/11/23 06:17:37 [notice] 1#1: start worker process 44
2026/11/23 06:17:37 [notice] 1#1: start worker process 45
```
</details>


## Check yourself
1. What changes if you run the same image twice?
   <details><summary>Answer</summary>You get independent containers with different names/IDs; the image is shared.</details>
2. Which port goes in the browser?
   <details><summary>Answer</summary>8080, the published host port.</details>
3. Does docker ps show stopped containers?
   <details><summary>Answer</summary>No; use docker ps -a.</details>
4. Does stop delete the container?
   <details><summary>Answer</summary>No. Remove it with rm afterward.</details>

## Common mistakes
The author triggered the name conflict by running the start command twice. The port conflict used a different name but the same
host mapping: `docker run -d --name code101-verify-02-port -p 127.0.0.1:8080:80 nginx:1.28-alpine`.
The failed container was removed with `docker rm -f code101-verify-02-port`. Do not reproduce conflicts on an unfamiliar machine.
These error excerpts were deliberately triggered. IDs vary. Never remove an unfamiliar container to fix a conflict.

| Real error text | Cause | Fix |
|---|---|---|
| `Bind for 127.0.0.1:8080 failed: port is already allocated` | Another running container owns host port 8080 | Run docker ps; stop only your earlier container, or change host 8080 to 8081 (leave the container port unchanged). |
| `The container name "/code101-verify-02-web" is already in use` | Stopped containers retain names too | Run docker ps -a. Remove only your own old container, or choose a new name. |
| `check if the path is correct and if the daemon is running` (captured in lesson 01; the full line varies by system) | Docker Desktop is not running, so the docker command has no engine to talk to | Start Docker Desktop, wait for **Engine running**, then repeat the command. |

## Best practice
Bind beginner development ports to loopback rather than all interfaces. Source: Docker port publishing https://docs.docker.com/engine/network/port-publishing/

## Next lesson
**03. Your first Dockerfile:** build an image from your files.
