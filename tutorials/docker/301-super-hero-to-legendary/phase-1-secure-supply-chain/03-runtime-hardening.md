---
track: docker
level: 301
phase: 1
phase_name: secure-supply-chain
lesson: 03
title: Runtime hardening - seccomp, AppArmor, user namespaces, rootless Docker and read-only roots
time: 90 min
prerequisites: ["docker 301 lesson 01", "docker 301 lesson 02", "docker 201 lessons 03, 05, 06"]
versions: { docker: "29.9.3 (inherited authoring baseline, not re-checked)", compose: "5.7.0 (inherited)", python_image: "3.13-slim", alpine_image: "3.22" }
verified: not yet run
source: source/docker/301-super-hero-to-legendary/phase-1-secure-supply-chain/03-runtime-hardening/
assets: []
---

# 03. Runtime hardening - seccomp, AppArmor, user namespaces, rootless Docker and read-only roots

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Compare a default container with a hardened one by reading what the process inside can see (user, writable paths, capabilities, privilege flags).
- Apply and explain read-only roots, dropped capabilities, `no-new-privileges` and resource limits in Compose.
- Choose between the default engine, user-namespace remapping and rootless Docker for a host, and state what each costs.
- Describe what a custom seccomp or AppArmor profile changes, and why replacing the default seccomp profile is risky.

## Recap
- Which two lesson 01 decisions does this lesson implement? <details><summary>Answer</summary>T1 (non-root, read-only root, no capabilities) and T2 (default seccomp, patched engine, rootless or user namespaces).</details>
- Why sign the digest rather than the tag? <details><summary>Answer</summary>A tag can move after signing; the digest cannot (lesson 02).</details>
- What does `tmpfs` give a container? ([Docker 201 lesson 03](../../201-hero-to-super-hero/phase-1-better-images/03-non-root-and-hardening.md)) <details><summary>Answer</summary>A writable in-memory directory that disappears when the container stops.</details>

## Why it matters
Lessons 01 and 02 reduce the chance that something hostile is *inside* your container. This lesson limits the damage when it happens anyway. Remote code execution in an application is a normal event over a service's life; whether it ends as "one process wrote a file into a throwaway directory" or "the attacker owns the host" is decided by settings you choose now. Each control below removes a capability an attacker needs for the next step. None of them is complete alone.

## What you will build
One small web service that reports its own privileges as JSON, run twice: with no hardening and with hardening. Then you will test a custom seccomp profile with a one-line command, read (and, on Linux with AppArmor, optionally load) an AppArmor profile, and read the daemon settings for user namespaces. Rootless Docker is a host installation and is explained, not scripted.

## Before you start
- **Prerequisites:** Docker 301 lessons [01, threat model for containers](01-threat-model-for-containers.md) and [02, image provenance, SBOM and signing](02-image-provenance-sbom-and-signing.md); Docker 201 lessons [03, non-root users and hardening](../../201-hero-to-super-hero/phase-1-better-images/03-non-root-and-hardening.md), [05, Compose profiles](../../201-hero-to-super-hero/phase-2-compose-in-depth/05-profiles-overrides-extensions.md) and [06, secrets and configs](../../201-hero-to-super-hero/phase-2-compose-in-depth/06-secrets-and-configs.md); [Docker 101 lesson 07, healthchecks and cleanup](../../101-zero-to-hero/phase-2-compose/07-healthchecks-and-cleanup.md).
- Docker running; Windows PowerShell or a macOS/Linux terminal; `curl` (Windows: `curl.exe`).
- Time: 90 minutes. Two sittings: stop after Step 6 (the compose comparison) and do Steps 7 to 9 later.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/301-super-hero-to-legendary/phase-1-secure-supply-chain/03-runtime-hardening/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Port: the lab publishes `127.0.0.1:8090` (loopback only). Run one lab at a time; stop the previous one.
- **Platform honesty:** seccomp and capabilities are Linux kernel features, so on Windows and macOS they apply inside Docker Desktop's Linux VM. AppArmor, `userns-remap` and rootless Docker are properties of a **Linux host**; Docker Desktop manages its VM for you and these are not settings you apply to it. Steps 7 to 9 are therefore for Linux hosts (a Linux server, or a WSL2 distribution running its own engine) and are **not run** in this lesson.
- The Dockerfile uses a tag for readability. Under lesson 02's policy a CI build would pass a digest-pinned `BASE_IMAGE`.

## The layers of a container's isolation
| Control | What it limits | Cost when it is wrong |
|---|---|---|
| Non-root user | What files and ports the process may use | Programs that bind port 80 or write to their own directory fail |
| Read-only root filesystem | Persistence and tampering inside the container | Programs that write temp files, caches or pid files fail until you provide `tmpfs` or a volume |
| Dropped capabilities | Root-like powers (change owner, bind low ports, raw sockets) | Images that start as root and switch user, such as the official database images, can fail |
| `no-new-privileges` | Gaining privileges through set-uid binaries | Rare; some tools that rely on `sudo` or set-uid helpers fail |
| seccomp profile | Which kernel system calls the process may make | Obscure `Operation not permitted` errors that look like file-permission problems |
| AppArmor profile | Which files, networks and capabilities a process may use (Linux security module) | Same: opaque denials; only on hosts that use AppArmor |
| Resource limits | Memory, process count and CPU a container may use | Out-of-memory kills, throttling (lesson 08) |
| User namespace remap / rootless | What "root in the container" maps to on the host | Volume ownership, privileged features, some network features |

## Steps

### Step 1. Make the lesson folder
**Terminal (PowerShell)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker301\lesson03\code" | Out-Null
Set-Location "$HOME\code101\docker301\lesson03\code"
```

**Terminal (macOS/Linux)**
```bash
mkdir -p ~/code101/docker301/lesson03/code
cd ~/code101/docker301/lesson03/code
```
Expected result: no output; you are inside `code`. Every command below runs in this folder unless stated.

### Step 2. The service that reports its own privileges
**File: `app.py`**
```python
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


def writable(directory):
    probe = os.path.join(directory, "probe.txt")
    try:
        with open(probe, "w", encoding="utf-8") as handle:
            handle.write("x")
        os.remove(probe)
        return True
    except OSError:
        return False


def proc_status():
    values = {}
    with open("/proc/self/status", encoding="utf-8") as handle:
        for line in handle:
            key, _, value = line.partition(":")
            values[key] = value.strip()
    return values


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status = proc_status()
        body = json.dumps({
            "uid": os.getuid(),
            "var_tmp_writable": writable("/var/tmp"),
            "tmp_writable": writable("/tmp"),
            "cap_bounding": status.get("CapBnd"),
            "no_new_privs": status.get("NoNewPrivs"),
            "seccomp": status.get("Seccomp"),
        }).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
```
How it works:
- `writable(directory)` tries to create and delete a file there and returns `True` or `False`. The `except OSError` catches "read-only file system" and "permission denied".
- `proc_status()` reads `/proc/self/status`, a kernel-provided file describing the current process, into a dictionary. Lines look like `CapBnd:` then a tab and a value. `partition(":")` splits at the first colon.
- Fields used: `CapBnd` is the capability **bounding set** (the maximum capabilities the process can ever hold, as a hexadecimal mask), `NoNewPrivs` is `1` when the `no-new-privileges` flag is set, and `Seccomp` is `0` (no filter), `1` (strict) or `2` (a filter is installed).
- `Handler.do_GET` answers every GET with that report as JSON. `HTTPServer(("0.0.0.0", 8080), ...)` listens on all interfaces **inside** the container; only the Compose `ports:` line decides who outside can reach it.
- The service is a probe: a real application would not publish this information, since it helps an attacker.

**File: `Dockerfile`**
```dockerfile
FROM python:3.13-slim
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY app.py .
USER 10001:10001
EXPOSE 8080
CMD ["python", "app.py"]
```
- `FROM python:3.13-slim`: the base image (a tag here; see lesson 02 for digest pinning).
- `RUN useradd ...`: a system user with uid 10001, no home directory, no login shell.
- `WORKDIR /app`, `COPY app.py .`: the program lives in `/app`, owned by root and not writable by uid 10001. That already blocks writes to `/app` even without a read-only root.
- `USER 10001:10001`: run as the numeric user and group.
- `EXPOSE 8080` documents the port; it publishes nothing.
- `CMD ["python", "app.py"]`: start the program in exec form.

**File: `.dockerignore`**
```text
.git
*.md
__pycache__
```
Keeps Git data, Markdown and bytecode caches out of the build context.

### Step 3. The baseline Compose file (no hardening)
**File: `docker-compose.baseline.yml`**
```yaml
name: code101-hardening-baseline
services:
  app:
    build: .
    image: code101/hardening-demo:1.0.0
    ports:
      - "127.0.0.1:8090:8080"
```
- `name:` is the Compose project name (lab isolation).
- `build: .` builds the Dockerfile in this folder; `image:` names the result.
- `ports: "127.0.0.1:8090:8080"` publishes container port 8080 on host loopback port 8090 only. The only hardening here is the non-root user from the Dockerfile.

### Step 4. The hardened Compose file
**File: `docker-compose.hardened.yml`**
```yaml
name: code101-hardening
services:
  app:
    build: .
    image: code101/hardening-demo:1.0.0
    init: true
    read_only: true
    tmpfs:
      - /tmp:size=16m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    pids_limit: 64
    mem_limit: 128m
    cpus: 0.5
    ports:
      - "127.0.0.1:8090:8080"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/')"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
```
Line by line (only what differs from the baseline):
- `init: true` runs a tiny init process as process 1 that forwards signals and reaps zombies. A Python program that is process 1 ignores `SIGTERM` unless it installs a handler, so `docker stop` would wait ten seconds and then kill it. Cost: one extra tiny process.
- `read_only: true`: the container's root filesystem is mounted read-only. What breaks if you remove it: nothing visible, but the process can write anywhere its user has permission, for example `/var/tmp`.
- `tmpfs: - /tmp:size=16m`: a 16 MB in-memory writable directory at `/tmp`. The `:size=16m` option caps it so a runaway write cannot use all memory. It is wiped when the container stops, so never put data here that you need.
- `cap_drop: - ALL`: remove all Linux capabilities from the container's bounding set. Anything that needs one (binding a port below 1024 needs `NET_BIND_SERVICE`) fails until you add exactly that capability with `cap_add`.
- `security_opt: - no-new-privileges:true`: sets the kernel flag that stops privilege gain through set-uid programs.
- `pids_limit: 64`: at most 64 processes or threads in the container. Limits a fork bomb. If set too low, a server that uses many threads fails with errors about creating threads.
- `mem_limit: 128m`: hard memory limit; the kernel kills the process if it exceeds it (lesson 08 shows this on purpose).
- `cpus: 0.5`: at most half a CPU's worth of time.
- `healthcheck`: runs a Python one-liner inside the container every 10 seconds; it fails if the HTTP request fails. `start_period` gives the service 5 seconds before failures count (Docker 101 lesson 07).

The default seccomp profile stays active: nothing in this file turns it off. **Never** add `seccomp:unconfined` to "fix" an error without first finding out which call is blocked; the lint from lesson 01 flags it as C8.

### Step 5. Predict, then run the baseline
Predict the JSON before you run it. Which of `var_tmp_writable` and `tmp_writable` are true? Is `cap_bounding` zero? What is `no_new_privs`?

**Terminal (PowerShell; folder: `code`)**
```powershell
docker compose -f docker-compose.baseline.yml up -d --build
curl.exe -s http://127.0.0.1:8090/
```
macOS/Linux: the same, with `curl` instead of `curl.exe`. The first command builds the image and starts the container (several lines of build output; the exact lines vary). If the port is already in use, the message contains `port is already allocated`: stop the other lab first.

Expected output of the `curl` command (derived by reading the code; the `cap_bounding` value depends on your engine, so it is shown as a placeholder; not yet run):
```text
{"uid": 10001, "var_tmp_writable": true, "tmp_writable": true, "cap_bounding": "<non-zero hexadecimal mask>", "no_new_privs": "0", "seccomp": "2"}
```
Meaning: the process is not root (`uid` 10001) but it can write to two directories outside its own, the bounding set still holds Docker's default capabilities (non-zero), nothing stops privilege gain, and a seccomp filter is active (`2`; this is Docker's default profile, typical on standard engines).

Stop it before the next run:

**Terminal (any OS; folder: `code`)**
```bash
docker compose -f docker-compose.baseline.yml down
```

### Step 6. Run the hardened version and compare
**Terminal (PowerShell; folder: `code`)**
```powershell
docker compose -f docker-compose.hardened.yml up -d --build
curl.exe -s http://127.0.0.1:8090/
```
Expected output (derived by reading the code and the Compose file; not yet run):
```text
{"uid": 10001, "var_tmp_writable": false, "tmp_writable": true, "cap_bounding": "0000000000000000", "no_new_privs": "1", "seccomp": "2"}
```
What changed: `/var/tmp` is now on the read-only root (`false`), `/tmp` is the writable in-memory mount (`true`), the bounding set is empty, and `no_new_privs` is `1`. Now play the attacker who has a shell in the container:

**Terminal (any OS; folder: `code`)**
```bash
docker compose -f docker-compose.hardened.yml exec app sh -c "echo owned > /var/tmp/payload"
```
Expected result (typical message; the exact text depends on the shell in the image): an error similar to `cannot create /var/tmp/payload: Read-only file system`, and a non-zero exit code. Check the health state, which needs a few seconds to turn healthy:

**Terminal (any OS; folder: `code`)**
```bash
docker compose -f docker-compose.hardened.yml ps
```
Expected result (not yet run): the `STATUS` column shows `healthy` after about ten seconds (it shows `health: starting` before that). Clean up:

**Terminal (any OS; folder: `code`)**
```bash
docker compose -f docker-compose.hardened.yml down
```

### Step 7. A custom seccomp profile (any engine; try it with `docker run`)
**seccomp** is a kernel feature that filters system calls. Docker applies a default profile that allows most calls and blocks about 44 of 300 or more; the Docker documentation notes that changing the default profile is not recommended. A custom profile **replaces** the default, it does not add to it. This one is a deliberately tiny denylist to show the mechanism.

**File: `seccomp-no-mkdir.json`**
```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["mkdir", "mkdirat"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```
- `defaultAction: SCMP_ACT_ALLOW`: every system call not listed is allowed. **This is the dangerous part:** the default Docker profile is the other way round (deny unless allowed), so this profile also gives up all the calls Docker's profile blocks. It is a demonstration, not a profile to deploy.
- `syscalls`: a list of rules. `names` lists the two calls used to create a directory (`mkdirat` is the form newer programs and some architectures use). `action: SCMP_ACT_ERRNO` makes the call fail with an error instead of running.

First without the profile, then with it (the folder must contain the JSON file; Docker's client reads it from your working directory):

**Terminal (any OS; folder: `code`)**
```bash
docker run --rm alpine:3.22 mkdir /tmp/allowed
docker run --rm --security-opt seccomp=seccomp-no-mkdir.json alpine:3.22 mkdir /tmp/blocked
```
Expected result (not yet run): the first command prints nothing and exits 0. The second prints a message like `mkdir: can't create directory '/tmp/blocked': Operation not permitted` (typical message) and exits with a non-zero code. Note the error text: `Operation not permitted` is the same text as a file-permission problem. That is why seccomp failures are hard to diagnose; when a hardened container fails with "operation not permitted" and file permissions are fine, suspect seccomp and capabilities.

### Step 8. AppArmor (Linux hosts with AppArmor only; not run in this lesson)
**AppArmor** is a Linux security module that confines a program to files, network and capabilities listed in a profile. On Linux hosts that use AppArmor, Docker applies a default profile named `docker-default` to containers. Docker Desktop's VM and hosts without AppArmor do not use it. Rootless Docker does not support AppArmor (see the Docker rootless documentation); that is a real trade-off in the choice below.

**File: `code101-deny-etc-write.apparmor`**
```text
#include <tunables/global>

profile code101-deny-etc-write flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  file,
  network,
  capability,

  deny /etc/** w,
}
```
- `#include <tunables/global>` pulls in standard AppArmor variables.
- `profile code101-deny-etc-write flags=(...)` names the profile and sets two flags Docker's own template uses (handle disconnected paths in mount namespaces, and deleted files).
- `#include <abstractions/base>` adds the minimal rules nearly every program needs.
- `file, network, capability,` allow all file access, all networking and all (already restricted by Docker) capabilities. The profile is a **denylist** with one rule.
- `deny /etc/** w,` forbids writing anything under `/etc`, whatever else is allowed. A `deny` rule overrides allows.

Load and use it on a Linux host (reference commands, not run here; they need administrator rights and change the host's AppArmor state):
```bash
sudo apparmor_parser -r -W code101-deny-etc-write.apparmor
docker run --rm --security-opt apparmor=code101-deny-etc-write alpine:3.22 sh -c "echo x > /etc/probe"
sudo apparmor_parser -R code101-deny-etc-write.apparmor
```
Expected result (typical message): the `docker run` fails with `can't create /etc/probe: Permission denied`. The last line removes the profile again. Confirm which profile a running container uses with `docker inspect --format "{{.AppArmorProfile}}" CONTAINER`.

### Step 9. User namespaces and rootless Docker (Linux hosts; read, do not run)
Two different ideas, often confused:

1. **`userns-remap`** keeps the Docker daemon running as root but maps "root inside the container" (uid 0) to an unprivileged, high-numbered user on the host. It is enabled in the daemon configuration:

**File: `daemon-userns.example.json`** (the real file is `/etc/docker/daemon.json` on Linux; merge the key into any existing content, do not overwrite it)
```json
{
  "userns-remap": "default"
}
```
- `"userns-remap": "default"` tells Docker to create (if needed) a user and group named `dockremap` and use the subordinate id ranges in `/etc/subuid` and `/etc/subgid`. After restarting the daemon, Docker keeps images and containers in a separate directory for the remapped ids, so existing containers and images **seem to disappear**: they still exist under the old mapping. Switching back brings them back.
- Known limits (Docker documentation): sharing host namespaces (`--pid=host`, `--network=host`), `--privileged` mode without opting out, and volumes that cannot be remapped. Bind mounts of host directories need ownership that matches the remapped ids.

2. **Rootless mode** runs **both** the daemon and the containers without root privileges, as a normal user, inside a user namespace. The setup tool for a user is `dockerd-rootless-setuptool.sh install`; prerequisites are `newuidmap`/`newgidmap` and at least 65,536 subordinate ids for the user in `/etc/subuid` and `/etc/subgid`. Documented limits include: only some storage drivers; resource limits need cgroup v2 and systemd; **AppArmor is not supported**; overlay networks are not supported; publishing ports below 1024 needs extra host configuration; and the container's IP address is inside RootlessKit's own network namespace. Read the current list at https://docs.docker.com/engine/security/rootless/troubleshoot/ before choosing it.

| | Default engine | `userns-remap` | Rootless |
|---|---|---|---|
| Daemon runs as | root | root | your user |
| Container root maps to host | root | unprivileged remapped id | your user (or a subordinate id) |
| A daemon or runtime escape yields | root on the host | root on the host (daemon is root) | the user's rights only |
| Compatible with `--privileged`, host networking | yes | no (without opting out) | limited |
| AppArmor profile | yes (if AppArmor host) | yes | no |
| Operational cost | lowest | volume ownership, separate image store | feature gaps, per-user daemons |

## How it works
Walk the attack from lesson 01's T1 and T2 against the hardened container. An attacker with code execution finds: not root; no capabilities; no ability to gain privileges; a filesystem they cannot write to except a small in-memory scratch directory; at most 64 processes; at most 128 MB of memory and half a CPU; and a seccomp filter that blocks calls such as module loading. They cannot install a persistent backdoor or easily escalate. They *can* still read anything the application can read and call anything the application can call: its database credentials, its network access. Hardening limits the blast radius **around** the process, not what the process itself may do. That is why secrets are scoped (files, least-privilege database roles) and why egress networking matters (lesson 05's network policies).

The misconception to correct: "a container is isolated, so a compromised container is harmless". Containers share the kernel, and many incidents come from configuration (privileged mode, mounted sockets, broad capabilities), not from exotic kernel exploits.

## Decision record (ADR-03): where to run untrusted-ish workloads
- **Context:** the team runs a CI host that builds images from contributor pull requests, and application hosts for internal services.
- **Decision:** application services run with the Step 4 settings as a baseline (non-root, read-only root, no capabilities, no-new-privileges, limits). The CI build host uses rootless Docker for the build daemon, because a malicious build step is the more realistic threat there and AppArmor on the build host matters less than not running a root daemon. Application hosts keep the default engine plus the baseline, and use `userns-remap` only where volume ownership has been tested.
- **Consequences:** two operating models to document; builds that need privileged features (for example Docker-in-Docker with `--privileged`) are refused on the CI host and handled by a dedicated, isolated builder.
- **Alternatives rejected:** one hardened profile for everything (too brittle for the stateful official images); full virtual-machine isolation per build (strongest, but more cost and slower).
- **Revisit when:** a workload needs a capability, a host device or privileged mode.

Stronger isolation exists for higher-risk multi-tenant code: user-space kernels and lightweight virtual machines (for example gVisor or Kata Containers) run containers behind an additional boundary, with compatibility and performance costs you must measure for your workload. They are a decision for a threat model that justifies them, not a default.

## When not to use this
- Do not add `cap_drop: ALL` and `read_only: true` blindly to an unfamiliar third-party image in production on a Friday. Test it under load first: images that start as root and then switch user (databases, many web servers) often need specific capabilities or writable paths. The `db` service in lesson 01's reviewed file runs as the numeric `postgres` user to avoid this, and has not been started here.
- Do not write your own seccomp profile for an application you cannot trace. The default profile is the sane default; custom profiles belong where a measured need exists and someone owns the maintenance.
- Do not enable `userns-remap` or rootless mode on a host that depends on privileged containers, host networking or existing bind-mounted data without a migration plan.

## Failure modes
- **Silent breakage:** hardening that works in a quick test but fails when a rarely-used code path writes a file (log rotation, cache, upload) or uses a blocked call. Mitigation: run the full test suite and a soak test against the hardened settings; log write failures.
- **`Operation not permitted` mystery:** caused by capabilities, seccomp or AppArmor; the text does not say which. Mitigation: change one control at a time; check host audit logs on AppArmor/seccomp hosts.
- **Hardening the wrong thing:** read-only root with a writable volume mounted at `/app` defeats the point.
- **Exceptions that stay:** `privileged: true` added for a debug session and never removed. Mitigation: the lesson 01 audit in CI.
- **Resource limits too tight:** services die under real load with an out-of-memory kill, or fail to create threads under `pids_limit`.
- **False sense of safety from a healthy container:** the health check only tests that the HTTP request works.

## Measurements to take
- Memory and process count of the service under normal and peak load (`docker stats`), to set `mem_limit` and `pids_limit` with headroom you can justify.
- The number of write attempts to read-only paths seen in logs during a soak test.
- The time to roll back a hardening change (how quickly could you revert if it broke production?).

## Production checklist
- [ ] Every service runs as a numeric non-root user; the Dockerfile sets `USER`.
- [ ] `read_only: true` with named `tmpfs` or volumes for each writable path.
- [ ] `cap_drop: ALL` with each `cap_add` justified in a comment and reviewed.
- [ ] `no-new-privileges:true` set; seccomp and AppArmor defaults not disabled.
- [ ] `pids_limit`, memory and CPU limits set from measurements.
- [ ] No service uses `privileged`, host namespaces or the Docker socket without a recorded, dated exception.
- [ ] The host's runtime (Docker Engine, containerd, runc) is on a patch schedule; someone watches its security advisories.
- [ ] Decision recorded for rootless or user-namespace remapping on each class of host.

## Try it
Work in a new folder `exercise` and copy `Dockerfile`, `app.py` and `.dockerignore` from `code` into it, so `build: .` works. Create the starter compose file there.

**File: `exercise/docker-compose.exercise.yml` (starter)**
```yaml
name: code101-hardening-exercise
services:
  app:
    build: .
    image: code101/hardening-demo:1.0.0
    # TODO 1: make the root filesystem read-only.
    # TODO 2: give the container an in-memory /tmp (16 MB is enough).
    # TODO 3: drop all capabilities and set no-new-privileges.
    ports:
      - "127.0.0.1:8090:8080"
```
1. **Guided:** complete the three TODOs. Run `docker compose -f docker-compose.exercise.yml up -d --build` and `curl` the service. Goal: `var_tmp_writable` is `false`, `tmp_writable` is `true`, `cap_bounding` is all zeros and `no_new_privs` is `"1"`. Run `docker compose -f docker-compose.exercise.yml down` afterwards.
2. **Change:** make `/var/tmp` writable again, but only as a 16 MB in-memory directory, without removing `read_only`. Predict which JSON field flips before you run it.
3. **Stretch (no single answer):** your team runs a nightly job that unpacks uploaded archives. Which two controls from the table would you add to its container, and which one would you refuse to add because of what the job needs? Write three sentences.

<details><summary>Solution</summary>

**File: `exercise/solution/docker-compose.exercise.yml`**
```yaml
name: code101-hardening-exercise
services:
  app:
    build: .
    image: code101/hardening-demo:1.0.0
    read_only: true
    tmpfs:
      - /tmp:size=16m
      - /var/tmp:size=16m
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    ports:
      - "127.0.0.1:8090:8080"
```
Step 1 uses `read_only`, the `/tmp` tmpfs, `cap_drop` and `security_opt`. Step 2 is the extra line `- /var/tmp:size=16m`; the field that flips is `var_tmp_writable`, from `false` to `true`, because a tmpfs mount is writable even under a read-only root. The expected final JSON (not yet run) is `{"uid": 10001, "var_tmp_writable": true, "tmp_writable": true, "cap_bounding": "0000000000000000", "no_new_privs": "1", "seccomp": "2"}`. For the stretch, a defensible answer: `pids_limit` and a memory limit (archive bombs and fork bombs), a read-only root with one size-capped tmpfs for unpacking, and refuse `no_new_privs` only if the unpacking tool genuinely needs a set-uid helper, which is rare.

</details>

## Check yourself
1. What does `cap_bounding` equal to `0000000000000000` tell you? <details><summary>Answer</summary>The container's bounding set is empty: the process can never hold any Linux capability (typical result of `cap_drop: ALL`).</details>
2. Why is `defaultAction: SCMP_ACT_ALLOW` in the custom profile a bad idea for production? <details><summary>Answer</summary>It turns the default allowlist into a denylist, so every call Docker's default profile blocks becomes allowed again.</details>
3. Predict: in the hardened Compose file you remove `tmpfs`. What happens to the `tmp_writable` value and why? <details><summary>Answer</summary>It becomes <code>false</code>: with a read-only root and no tmpfs, <code>/tmp</code> is read-only. The service would still start and report it.</details>
4. Which choice (default engine, `userns-remap`, rootless) leaves a daemon-level escape with host root, and which does not? <details><summary>Answer</summary>The default engine and <code>userns-remap</code> both run the daemon as root; rootless does not.</details>
5. A teammate sets `seccomp:unconfined` because the app printed "Operation not permitted". What should have happened first? <details><summary>Answer</summary>Identify what is blocked (capabilities, AppArmor, file permissions or seccomp): change one control at a time and add only the minimum back.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `port is already allocated` (typical wording) | A previous lab still holds 127.0.0.1:8090 | `docker compose -f <file> down` for the other lab |
| `Read-only file system` error from the app | `read_only: true` and a path that is not a `tmpfs` or volume | Add a size-capped `tmpfs` or a volume for that path |
| `Operation not permitted` on bind or chown | Dropped capability (`NET_BIND_SERVICE`, `CHOWN`) | Add only the capability the error needs, with a comment |
| `curl.exe` prints nothing or connection refused | The container is still starting, or it crashed | `docker compose -f <file> logs app` and retry after the health check turns healthy |
| `seccomp=...` file not found | The terminal is not in the folder that contains the JSON file | Run the command in `code` |
| Images and containers vanish after enabling `userns-remap` | Docker now uses the remapped storage directory | Revert the setting to see them again; plan a migration |
| `curl` in PowerShell shows a web-request object instead of text | `curl` is an alias for `Invoke-WebRequest` on Windows PowerShell 5.1 | Use `curl.exe` |

## Best practice
Run containers with the least privilege that works: non-root, read-only root, no capabilities, no new privileges, default seccomp and AppArmor profiles, resource limits, and no privileged mode or Docker socket. Source: OWASP Docker Security Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html

## Going further
- seccomp profiles: https://docs.docker.com/engine/security/seccomp/
- AppArmor profiles: https://docs.docker.com/engine/security/apparmor/
- User namespaces (`userns-remap`): https://docs.docker.com/engine/security/userns-remap/
- Rootless mode: https://docs.docker.com/engine/security/rootless/
- Linux kernel features and the OCI runtime specification: https://github.com/opencontainers/runtime-spec

## Summary
- You compared a baseline and a hardened container by reading their own privilege report.
- You applied a read-only root, `tmpfs`, dropped capabilities, `no-new-privileges` and limits, and explained the cost of each.
- You tested a custom seccomp profile and explained why replacing the default profile is risky.
- You compared the default engine, `userns-remap` and rootless Docker and recorded a decision.

## Next lesson
04. Registries and promotion pipelines: tags versus digests in practice, private registries, retention and promoting an image through environments without rebuilding it.
