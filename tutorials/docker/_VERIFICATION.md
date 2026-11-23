# Docker 101 verification evidence

Date: 2026-11-23. Windows 11, Docker CLI/Engine 29.9.3, Desktop 4.99.0, Compose v5.7.0.
Scope: clean-room smoke runs for code and exercise solutions; not unit tests or production certification.
All image tags were actually pulled. All examples/configurations were copied from source into the lessons.
Installers on macOS/Linux and optional WSL memory configuration are documentation-checked only.

## Actual per-lesson verifier output

```text
[PASS      ] source/docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-1-containers/02-images-and-containers

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-1-containers/03-your-first-dockerfile

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-1-containers/04-data-that-survives

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-2-compose/05-environment-and-secrets

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-2-compose/06-networks-and-compose

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-2-compose/07-healthchecks-and-cleanup

1 passed, 0 failed, 0 unverified (missing tools)
```

```text
[PASS      ] source/docker/101-zero-to-hero/phase-2-compose/08-two-service-project

1 passed, 0 failed, 0 unverified (missing tools)
```

## Final sweep
An overlapping external verification initially occupied 8080 and reused the project counter.
No other process was killed or foreign container removed. After the competing run cleared,
`python scripts/verify_labs.py source/docker/101-zero-to-hero` returned:

```text
8 passed, 0 failed, 0 unverified (missing tools)
```

## Deliberately triggered real errors
The daemon failure used a nonexistent Windows pipe, without stopping the live engine.
The other errors used only this author's temporary containers and malformed temporary YAML.

### port
```text
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint code101-verify-02-port (23015478908dcf57d89bb2bed3fd5d2c9e68c4897e8a71b23879d28a0f5f15d7): Bind for 127.0.0.1:8080 failed: port is already allocated

Run 'docker run --help' for more information
```

### name
```text
docker: Error response from daemon: Conflict. The container name "/code101-verify-02-web" is already in use by container "b6fba0c3b73900c429889f176a7b484a462e19039da7977768feb124956b2106". You have to remove (or rename) that container to be able to reuse that name.

Run 'docker run --help' for more information
```

### image
```text
docker: Error response from daemon: No such image: code101-verify-no-such-image:demo

Run 'docker run --help' for more information
```

### daemon
```text
failed to connect to the docker API at npipe:////./pipe/code101-verify-no-daemon; check if the path is correct and if the daemon is running: open //./pipe/code101-verify-no-daemon: The system cannot find the file specified.
```

### yaml
```text
go-yaml load error in parser (while parsing a block mapping) at L2.C3-L4.C4: did not find expected key
```

## Final Docker resource audit
Author-built images and the four official images downloaded by this author were removed.
The 21 known author cache IDs were pruned explicitly, child-before-parent; no global prune was used.
The shared postgres:17-alpine image belongs to the Databases track's download and was preserved.
No containers, named volumes or non-default networks remained. Desktop settings/live .wslconfig unchanged.

```text
docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```text
docker volume ls
DRIVER    VOLUME NAME
```

```text
docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
2241ff88a2db   bridge    bridge    local
d9f1d5a54f80   host      host      local
f8a2e3425af8   none      null      local
```

```text
docker image ls -a
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
postgres:17-alpine   f9cf3e1f0066        424MB          118MB
```

```text
docker buildx du
ID        RECLAIMABLE   SIZE      LAST ACCESSED
Reclaimable:	0B
Total:		0B
```

```text
docker info --format "{{.ServerVersion}} | {{.OSType}}"
29.9.3 | linux
```
