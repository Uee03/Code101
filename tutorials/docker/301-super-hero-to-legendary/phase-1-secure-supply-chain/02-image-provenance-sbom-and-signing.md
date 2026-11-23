---
track: docker
level: 301
phase: 1
phase_name: secure-supply-chain
lesson: 02
title: Image provenance - SBOM, signing, digest pinning and base-image policy
time: 75 min
prerequisites: ["docker 301 lesson 01", "docker 201 lessons 01, 09"]
versions: { docker: "29.9.3 (inherited authoring baseline, not re-checked)", buildx: "bundled with Docker 29, not re-checked", python_image: "3.13-slim", python: "3.13" }
verified: not yet run
source: source/docker/301-super-hero-to-legendary/phase-1-secure-supply-chain/02-image-provenance-sbom-and-signing/
assets: []
---

# 02. Image provenance - SBOM, signing, digest pinning and base-image policy

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain the difference between a tag and a digest, and pin a base image by digest.
- Produce an SBOM for an image build and query it for a package.
- Describe what image signing proves (and what it does not), and write the verification step a deploy pipeline needs.
- Enforce a base-image policy (allow list, no `latest`, digest required) with a small script and justify its trade-offs.

## Recap
- Which boundary does "a tag is moved to a different image" cross, and what was the decision for it in lesson 01?
  <details><summary>Answer</summary>Registry to host (boundary 4). Decision T5: deploy by digest and promote instead of rebuilding.</details>
- What does a multi-stage build remove from the final image? ([Docker 201 lesson 01](../../201-hero-to-super-hero/phase-1-better-images/01-multi-stage-builds.md))
  <details><summary>Answer</summary>Build tools and intermediate files, which shrinks the attack surface and the package list an SBOM must describe.</details>
- Why does a green line-based lint not prove a system is secure?
  <details><summary>Answer</summary>It matches text patterns only (lesson 01).</details>

## Why it matters
When you run `python:3.13-slim` you trust that the publisher built it honestly, that nobody replaced it between your review and your deploy, and that nothing in it is unknown to you. Provenance is the evidence for those three claims: where an image came from (provenance), what is in it (SBOM), who vouches for it (signature) and which exact bytes you mean (digest). Without them an incident response starts with "we are not sure what was running".

## What you will build
A tiny Python image built from a base image that is pinned by digest, a base-image policy check you can run in CI, and a small SBOM query tool. You will generate a real SBOM from your own build, and read how signing with Sigstore's `cosign` fits in. Signing commands are shown as reference only: they need keys or a CI identity and are not part of the lab.

## Before you start
- **Prerequisites:** [Docker 301 lesson 01, threat model for containers](01-threat-model-for-containers.md); Docker 201 lessons [01, multi-stage builds](../../201-hero-to-super-hero/phase-1-better-images/01-multi-stage-builds.md) and [09, CI with GitHub Actions](../../201-hero-to-super-hero/phase-3-workflows/09-ci-with-github-actions.md).
- Docker running (Docker 101 lesson 01) and Python 3.13 on the host, or the container route used in lesson 01 for Python.
- Time: 75 minutes. Two sittings are fine: stop after Step 6.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/301-super-hero-to-legendary/phase-1-secure-supply-chain/02-image-provenance-sbom-and-signing/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Image tag `python:3.13-slim` was found on Docker Hub on 2026-11-23 (a lookup, not a pull). Tags move; that is the point of this lesson.
- Everything here uses public demonstration values. The all-zero digests in the sample files are not real images.

## Tags versus digests
A **tag** (`3.13-slim`) is a name the publisher can point at a different image tomorrow. A **digest** (`sha256:` followed by 64 hexadecimal characters) is the hash of an image's manifest, a JSON file listing its layers. Change one byte anywhere and the digest changes, so a digest names exactly one image. The OCI specifications define this content addressing (Tier 1: https://github.com/opencontainers/image-spec/blob/main/spec.md).

| | Tag | Digest |
|---|---|---|
| Moves over time | Yes (that is its purpose) | Never |
| Human friendly | Yes | No |
| Gets security patches automatically | Yes, on next pull | No: you must update it |
| Reproducible build input | No | Yes |
| What to sign, scan and deploy | Not alone | Yes |

For multi-architecture images the tag points to an **index** (a list of per-platform manifests). Pin the index digest and the same line works on Intel and Arm machines; the builder picks the right platform entry.

The trade-off is the key failure mode of this lesson: **a pinned digest freezes the image, including its vulnerabilities.** Pinning without an update process turns "unreviewed change" into "unpatched forever". The answer is automation (a bot such as Renovate or Dependabot that opens a pull request when the tag's digest changes) plus a rebuild cadence you measure.

## Steps

### Step 1. Make the lesson folder
**Terminal (PowerShell)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker301\lesson02\code" | Out-Null
Set-Location "$HOME\code101\docker301\lesson02\code"
```

**Terminal (macOS/Linux)**
```bash
mkdir -p ~/code101/docker301/lesson02/code
cd ~/code101/docker301/lesson02/code
```
Expected result: no output; the prompt is inside `code`. Return here with the same command if you get lost.

### Step 2. The Dockerfile
**File: `Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1
ARG BASE_IMAGE=python:3.13-slim
FROM ${BASE_IMAGE}
ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="code101-provenance-demo" \
      org.opencontainers.image.source="https://github.com/Uee03/Code101" \
      org.opencontainers.image.revision="${VCS_REF}"
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY app.py .
USER 10001:10001
CMD ["python", "app.py"]
```
Line by line:
- `# syntax=docker/dockerfile:1` selects the current stable Dockerfile frontend, so parser fixes arrive without upgrading Docker.
- `ARG BASE_IMAGE=python:3.13-slim` declares a build argument **before** `FROM` so it can be used in `FROM`. The default is a convenient tag for local work. A pipeline overrides it with a digest-pinned reference. The risk of the default: someone builds locally with a tag and ships it. The policy check in Step 5 is what catches that in CI.
- `FROM ${BASE_IMAGE}` starts from whatever the argument says.
- `ARG VCS_REF=unknown` declares a second argument (after `FROM`, so it is visible in this stage). The pipeline passes the Git commit.
- `LABEL org.opencontainers.image.*` stores standard **OCI annotations**: title, where the source lives, and the revision it was built from. Registries, scanners and humans read them. A label is not proof: anyone can write any label, which is why signing exists.
- `RUN useradd ...` creates a numeric non-root user (uid 10001) with no home directory and no login shell.
- `WORKDIR /app`, `COPY app.py .` set the folder and copy the program.
- `USER 10001:10001` makes the process run as that user. A numeric id lets Kubernetes verify "non-root" (lesson 05).
- `CMD [...]` runs the program in exec form (no shell).

**File: `app.py`**
```python
import os

print("provenance demo running as uid", os.getuid(), flush=True)
```
It prints the numeric user id, so you can see the container is not root.

**File: `.dockerignore`**
```text
.git
out
*.md
__pycache__
```
Keeps Git history, the SBOM output folder `out` (Step 6), Markdown files and bytecode caches out of the build context, so they cannot leak into the image or invalidate the build cache.

### Step 3. Find the digest of your base image
Ask the registry, not your local cache, what the tag points at today:

**Terminal (any OS; folder: `code`)**
```bash
docker buildx imagetools inspect python:3.13-slim
```
The first lines have this shape (typical output, values vary and are not shown):
```text
Name:      docker.io/library/python:3.13-slim
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:<64 hexadecimal characters>
```
The `Digest:` line is the index digest. Copy it. Your pinned reference is `python:3.13-slim@sha256:<that digest>`: the tag stays as a human hint; the digest decides what is pulled.

If you prefer a local route: `docker pull python:3.13-slim` followed by `docker image inspect --format "{{index .RepoDigests 0}}" python:3.13-slim` prints `python@sha256:...`. Compare it with the registry line; with some image stores the local value can differ from the index digest, which is one reason to take the value from `imagetools inspect`.

### Step 4. Build with the pinned base and run it
Replace `<DIGEST>` with the hexadecimal part you copied (everything after `sha256:`).

**Terminal (PowerShell; folder: `code`)**
```powershell
docker build -t code101/provenance-demo:1.0.0 --build-arg BASE_IMAGE=python:3.13-slim@sha256:<DIGEST> --build-arg VCS_REF=local .
docker run --rm code101/provenance-demo:1.0.0
```
macOS/Linux: the same two commands work unchanged.

Expected output of the second command (derived from `app.py`; not yet run):
```text
provenance demo running as uid 10001
```
Check that the labels made it into the image:

**Terminal (any OS; folder: `code`)**
```bash
docker image inspect --format "{{json .Config.Labels}}" code101/provenance-demo:1.0.0
```
Expected output (not yet run): one line of JSON that contains `"org.opencontainers.image.revision":"local"`, the `source` URL and the `title`. The base image may add labels of its own. The format string has no inner quotes on purpose: nested quotes are where PowerShell and bash disagree.

### Step 5. The base-image policy as code
A policy nobody can run is a wish. This file states the policy; the script enforces it.

**File: `base-image-policy.json`**
```json
{
  "allowed_repositories": ["python", "alpine", "postgres", "localhost:5050/team/base"],
  "forbidden_tags": ["latest"],
  "require_digest": true
}
```
- `allowed_repositories`: the only repositories a Dockerfile may start from. Short names such as `python` mean the Docker Official Image on Docker Hub; `localhost:5050/team/base` is an internal base image from the registry of lesson 04.
- `forbidden_tags`: tags that are never allowed.
- `require_digest`: every reference must carry a `@sha256:` digest.

**File: `sample-references.txt`**
```text
# One image reference per line. The digests below are all zeros: format-only examples, not real images.
python:3.13-slim
python:latest
python:3.13-slim@sha256:0000000000000000000000000000000000000000000000000000000000000000
ubuntu:24.04@sha256:0000000000000000000000000000000000000000000000000000000000000000
localhost:5050/team/base:1.2.0@sha256:0000000000000000000000000000000000000000000000000000000000000000
alpine
```

**File: `check_base_image.py`**
```python
"""Check image references against a base-image policy (format and allow list only)."""
import json
import re
import sys

DIGEST = re.compile(r"sha256:[0-9a-f]{64}")


def split_reference(reference):
    name, _, digest = reference.partition("@")
    last_part = name.rsplit("/", 1)[-1]
    tag = ""
    if ":" in last_part:
        name, _, tag = name.rpartition(":")
    return name, tag, digest


def check(reference, policy):
    name, tag, digest = split_reference(reference)
    problems = []
    if name not in policy["allowed_repositories"]:
        problems.append(f"repository {name} is not on the allow list")
    if tag in policy["forbidden_tags"] or (not tag and not digest):
        problems.append("mutable tag (latest or no tag)")
    if policy["require_digest"] and not DIGEST.fullmatch(digest):
        problems.append("no sha256 digest pin")
    return problems


def main():
    if len(sys.argv) != 3:
        print("usage: python check_base_image.py <policy.json> <references.txt>")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        policy = json.load(handle)
    failed = 0
    with open(sys.argv[2], encoding="utf-8") as handle:
        for line in handle:
            reference = line.strip()
            if not reference or reference.startswith("#"):
                continue
            problems = check(reference, policy)
            print(("FAIL " if problems else "PASS ") + reference)
            for problem in problems:
                print("  - " + problem)
            failed += bool(problems)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
```
How it works:
- `DIGEST` is a regular expression: the text `sha256:` and exactly 64 characters from `0-9a-f`.
- `split_reference` cuts a reference into name, tag and digest. `partition("@")` separates the digest. The tag is the part after the last colon **only if that colon is in the last path segment**; that is why `localhost:5050/team/base` (a registry port, not a tag) is handled correctly.
- `check` applies the three policy rules and returns a list of problems. A reference with no tag and no digest is treated as mutable, because Docker would use `latest`.
- `main` reads the policy and the references file, prints `PASS` or `FAIL` plus the reasons, and returns exit code 1 if anything failed, so a CI job can stop the pipeline.

**Predict first:** which of the six references pass? Write your answer, then run:

**Terminal (PowerShell; folder: `code`)**
```powershell
python check_base_image.py base-image-policy.json sample-references.txt
```
macOS/Linux: `python3 check_base_image.py base-image-policy.json sample-references.txt`.

Expected output (derived by reading the script; not yet run):
```text
FAIL python:3.13-slim
  - no sha256 digest pin
FAIL python:latest
  - mutable tag (latest or no tag)
  - no sha256 digest pin
PASS python:3.13-slim@sha256:0000000000000000000000000000000000000000000000000000000000000000
FAIL ubuntu:24.04@sha256:0000000000000000000000000000000000000000000000000000000000000000
  - repository ubuntu is not on the allow list
PASS localhost:5050/team/base:1.2.0@sha256:0000000000000000000000000000000000000000000000000000000000000000
FAIL alpine
  - mutable tag (latest or no tag)
  - no sha256 digest pin
```
The exit code is 1. **What this check cannot do:** it validates the form of a digest, not that the digest exists, not that the image is free of vulnerabilities, and not that it was built by who you think. The all-zero digest passes the format test. A real pipeline pulls the reference and verifies the signature (Step 7).

### Step 6. Generate and query an SBOM
An **SBOM** (software bill of materials) is a machine-readable list of the packages inside an image. BuildKit can generate one during the build and records it as an **attestation**: signed or unsigned metadata attached to an image describing how or from what it was made. Docker documents the SPDX format it produces: https://docs.docker.com/build/metadata/attestations/sbom/.

Build with the SBOM and a provenance attestation, writing the result to a local folder instead of an image store (this is the verification route the Docker documentation shows):

**Terminal (PowerShell; folder: `code`)**
```powershell
docker buildx build --sbom=true --provenance=mode=max --build-arg BASE_IMAGE=python:3.13-slim@sha256:<DIGEST> --output type=local,dest=out .
Get-ChildItem out | Select-Object -First 20 Name
```
macOS/Linux: the same `docker buildx build ...` command, then `ls out | head -20`.

Expected result (not yet run): an `out` folder that contains the image's files and, per the Docker documentation, an `sbom.spdx.json` file. A provenance file may appear next to it; list the folder and see what your Docker version wrote.

If the build stops with a message that attestations are not supported by the `docker` driver (typical wording; the exact text varies with version), your engine uses the classic image store and the default builder. Two ways out: in Docker Desktop turn on **Settings > General > Use containerd for pulling and storing images**, or create a builder just for this lesson and remove it afterwards:
```bash
docker buildx create --name code101-builder --driver docker-container --use
docker buildx rm code101-builder
```
(Run the first before the build, the second when finished. Then `docker buildx use default` if you had another builder selected.) Changing a Docker Desktop setting changes it for every project: note the old value and restore it.

Now the query tool. First the sample, which needs no Docker:

**File: `sample-sbom.json`**
```json
{
  "spdxVersion": "SPDX-2.3",
  "name": "sample-sbom (hand-written, abbreviated, made-up versions)",
  "packages": [
    {"SPDXID": "SPDXRef-Package-1", "name": "bash", "versionInfo": "0.0.1-sample"},
    {"SPDXID": "SPDXRef-Package-2", "name": "libssl3", "versionInfo": "0.0.1-sample"},
    {"SPDXID": "SPDXRef-Package-3", "name": "libexpat1", "versionInfo": "0.0.1-sample"},
    {"SPDXID": "SPDXRef-Package-4", "name": "zlib1g", "versionInfo": "0.0.1-sample"}
  ]
}
```
This is hand-written and abbreviated: the real file has many more fields and packages, and the versions here are made up.

**File: `sbom_query.py`**
```python
"""List packages in an SPDX JSON SBOM whose names contain any search word."""
import json
import sys


def main():
    if len(sys.argv) < 3:
        print("usage: python sbom_query.py <sbom.json> <word> [word ...]")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        document = json.load(handle)
    packages = document.get("packages", [])
    words = [word.lower() for word in sys.argv[2:]]
    print(f"{len(packages)} packages in {sys.argv[1]}")
    hits = 0
    for package in sorted(packages, key=lambda item: item.get("name", "")):
        name = package.get("name", "")
        if any(word in name.lower() for word in words):
            print(f"  {name} {package.get('versionInfo', '(no version)')}")
            hits += 1
    return 0 if hits else 1


if __name__ == "__main__":
    sys.exit(main())
```
How it works: it loads the JSON, reads the `packages` list (SPDX's list of components), prints how many there are, then prints the name and version of each package whose lower-cased name contains any search word. It exits 0 when something matched and 1 when nothing did, so a pipeline can ask "does this image contain `libexpat1`?" and react.

**Terminal (PowerShell; folder: `code`)**
```powershell
python sbom_query.py sample-sbom.json ssl zlib
```
Expected output (derived by reading the script; not yet run):
```text
4 packages in sample-sbom.json
  libssl3 0.0.1-sample
  zlib1g 0.0.1-sample
```
Now point it at your real SBOM: `python sbom_query.py out/sbom.spdx.json openssl` (Windows: `out\sbom.spdx.json`). The package count and names depend on the image at build time and are not shown here. Real SPDX documents can name the same library more than once and may list base-image packages differently from your language ecosystem's tooling; treat a count as a rough measure, not a fact.

### Step 7. Signing: what it proves, and the verification step
Signing answers "who vouches for these bytes?". The tool most used with registries is **cosign** from the Sigstore project. The commands below are a **reference for the concept, not run in this lesson**: they need either a key pair or an identity from your CI system, and a registry you can push to (lesson 04 builds a local one).

Key-based, simplest to understand:
```bash
cosign generate-key-pair
cosign sign --key cosign.key REGISTRY/NAME@sha256:<DIGEST>
cosign verify --key cosign.pub REGISTRY/NAME@sha256:<DIGEST>
```
`generate-key-pair` writes `cosign.key` (private, protect it like a password) and `cosign.pub` (public, share it). `sign` attaches a signature to the **digest** (not the tag: signing a movable tag proves little). `verify` succeeds only if a signature made by the matching private key exists for that digest.

Keyless signing in CI signs with a short-lived certificate tied to the CI job's identity (for example a GitHub Actions workflow), and verification states which identity and issuer you trust:
```bash
cosign verify REGISTRY/NAME@sha256:<DIGEST> --certificate-identity IDENTITY --certificate-oidc-issuer ISSUER
```
Read the cosign documentation for the exact flags of your version before using them.

What a signature **proves**: someone holding that key (or CI identity) vouched for exactly those bytes at signing time. What it does **not** prove: that the code is free of vulnerabilities, that the build was honest (a compromised build server signs malware happily), or that the key was not stolen. That is why provenance (how it was built) and SBOM (what is inside) are separate evidence, and why verification must happen where the image is **used**: an admission policy in the cluster or a deploy script that refuses unsigned or wrongly signed digests. Signing without verifying is decoration.

Trade-offs to decide before adopting it:
- Key management: a key file is a secret to rotate and revoke. Keyless moves that burden to your CI identity provider, and by default records signing events in a public transparency log, which may reveal names you consider private; check how to run a private instance if that matters.
- Older mechanisms exist (Docker Content Trust with Notary v1; the Notary Project's `notation`). Check the current Docker documentation for what is recommended before building on one.
- Everything downstream must verify, or an attacker simply uses an unsigned path.

## How it works
Put the pieces in the order of an image's life: the Dockerfile starts from a **digest-pinned base** (stable input), BuildKit emits an **SBOM and provenance attestation** (what and how), CI **signs the resulting digest** (who vouches), and the deploy step **verifies the signature and the policy** before running it. Each piece defends a different attack from lesson 01's table: pinning stops a tag swap, the SBOM speeds the answer to "are we affected by this CVE?", signing stops an unauthorised push from being run, and provenance lets you check that the build came from your repository and pipeline.

The misconception to correct: "pinning by digest is the same as being secure". It is a reproducibility and tamper-evidence control. Security needs the update process around it.

## Decision record (ADR-02): digest pins with automated refresh
- **Context:** the team ships Python services built on `python:3.13-slim`. The tag moves weekly; builds are not reproducible.
- **Decision:** CI builds only from `BASE_IMAGE` values that pass `check_base_image.py` (allow list, no `latest`, digest required). A bot opens a pull request when the digest for a tag changes; a merged pull request triggers a rebuild, a scan, an SBOM and a signature.
- **Consequences:** builds are reproducible with respect to the base image; patch uptake is bounded by how fast pull requests are merged (measure it); an extra bot to maintain; developers must not bypass CI with local pushes.
- **Alternatives rejected:** floating tags with a nightly rebuild (cheaper, but you cannot say what was reviewed); vendoring a private base image mirror only (good for air-gapped sites, extra operations work).
- **Revisit when:** the update pull requests are routinely ignored for more than a few days (then the pin has become a liability).

## When not to use this
- Local experiments and short-lived dev containers do not need digest pins or signatures; the tag default in the Dockerfile is for them.
- Do not sign if nothing verifies. Do not generate SBOMs that nobody reads: pick one question they answer (for example "are we affected by CVE-X?") and wire that into a job.
- Digest pins are the wrong tool for images you must patch in hours without review (internal tools with a trusted base): use a rebuild cadence and a scanner instead.

## Failure modes
- **Frozen vulnerabilities:** pins nobody updates. Measure the age of each pinned digest (days since the base image was published) and alert beyond a threshold you choose.
- **Pinning the wrong digest:** a per-platform manifest digest copied from a Dockerfile written on an Intel laptop breaks Arm builds. Pin the index digest.
- **Signing the tag:** the signature is attached to a digest; if your deploy pulls by tag, nothing ties the pull to the signature.
- **Attestation drift:** the SBOM is generated from a different build than the one pushed. Generate it in the same build that produces the image.
- **SBOM blind spots:** statically linked binaries, vendored code and files copied in without a package manager may not appear. BuildKit scans the final stage by default (see the Docker documentation for `BUILDKIT_SBOM_SCAN_STAGE`).
- **Registry credential theft:** a signature made by a stolen CI credential is valid. Short-lived credentials and separate signing identity reduce, but do not remove, the risk.

## Measurements to take (do not guess them)
- Build time with and without `--sbom=true --provenance=mode=max` (use `Measure-Command { ... }` in PowerShell or `time` in bash).
- Size of the SBOM file and the number of packages it lists.
- Days since the pinned base image was published, per service.
- Hours from "base image fixed upstream" to "our fixed image running".
- Number of images deployed without a verified signature (target: zero).

## Production checklist
- [ ] Every Dockerfile's `FROM` resolves to an allow-listed repository and a digest in CI.
- [ ] A bot or scheduled job proposes digest updates; someone owns merging them.
- [ ] Each release image has an SBOM and provenance attestation from the same build.
- [ ] Images are signed by digest; the deploy path verifies the signature and refuses failures.
- [ ] Signing keys (or the CI identity) have an owner, a rotation plan and a revocation plan.
- [ ] The base-image policy is in version control and changes need review.

## Try it
Work in a new folder `exercise`. Copy `exercise/starter/policy.json` and `exercise/starter/references.txt` (shown below) and the `check_base_image.py` from `code` into it.

**File: `exercise/policy.json` (starter)**
```json
{
  "allowed_repositories": ["python"],
  "forbidden_tags": [],
  "require_digest": false
}
```

**File: `exercise/references.txt` (starter)**
```text
# Goal: after the policy.json fix the 1st, 3rd and 6th references PASS; after the script change only the 1st and 3rd PASS.
python:3.13-slim@sha256:0000000000000000000000000000000000000000000000000000000000000000
alpine:3.22@sha256:0000000000000000000000000000000000000000000000000000000000000000
postgres:17-alpine@sha256:0000000000000000000000000000000000000000000000000000000000000000
python:latest@sha256:0000000000000000000000000000000000000000000000000000000000000000
ubuntu:24.04@sha256:0000000000000000000000000000000000000000000000000000000000000000
python:edge-nightly@sha256:0000000000000000000000000000000000000000000000000000000000000000
```

1. **Guided:** edit `policy.json` only (no script changes) so that the 1st, 3rd and 6th references pass and the others fail. Run the checker and compare with the goal comment.
2. **Change:** make the 6th reference fail too, with a policy key `forbidden_tag_prefixes` (values `edge` and `nightly`). You must change `check` in the script. The new message should say that the tag prefix is forbidden.
3. **Stretch (no single answer):** write a five-line ADR: how often should the digest pins be refreshed, who approves a refresh, and what happens when a refresh fails the tests? State what you would measure to know whether your answer works.

<details><summary>Solution</summary>

**File: `exercise/solution/policy.json`**
```json
{
  "allowed_repositories": ["python", "postgres"],
  "forbidden_tags": ["latest"],
  "forbidden_tag_prefixes": ["edge", "nightly"],
  "require_digest": true
}
```
Step 1 needs `allowed_repositories`, `forbidden_tags` and `require_digest`. Step 2 adds one rule to `check` in `check_base_image.py`, between the tag rule and the digest rule:
```python
    if tag.startswith(tuple(policy.get("forbidden_tag_prefixes", []))):
        problems.append("tag prefix is forbidden")
```
`str.startswith` accepts a tuple of prefixes; with an empty tuple it returns `False`, so policies without the key keep working (`policy.get` supplies the empty default). Expected result with the solution (not yet run): the 1st and 3rd references print `PASS`; the 2nd and 5th fail on the allow list; the 4th fails with `mutable tag (latest or no tag)`; the 6th fails with `tag prefix is forbidden`. The full solution script is in `exercise/solution/check_base_image.py` of the source pack.

For the stretch there is no single answer. A defensible one: weekly bot pull requests, owner is the platform team, merge needs a green build plus the scan job, and a failing refresh keeps the old pin while an issue is opened. Measure the age of the oldest pin and the time from upstream fix to deploy.

</details>

## Check yourself
1. What does a digest name that a tag does not? <details><summary>Answer</summary>Exactly one image (content-addressed): changing any byte changes it. A tag can be moved.</details>
2. Predict the output: `python check_base_image.py base-image-policy.json refs.txt` where `refs.txt` contains only `postgres:17-alpine`. <details><summary>Answer</summary><code>FAIL postgres:17-alpine</code> followed by <code>  - no sha256 digest pin</code>; the repository is allowed and the tag is not forbidden, but the policy requires a digest. Exit code 1.</details>
3. Why sign the digest instead of the tag? <details><summary>Answer</summary>A tag can be moved to different bytes after signing; the digest cannot.</details>
4. A teammate says "we sign every image, so a stolen CI token cannot hurt us". What is wrong? <details><summary>Answer</summary>A stolen CI credential may also be able to sign. The signature proves who vouched, not that the vouching party was uncompromised. Reduce the blast radius with short-lived credentials and verification of the signing identity.</details>
5. Find the bug: a developer builds with the Dockerfile default and pushes `team/base:2.0`. Which control in this lesson catches it? <details><summary>Answer</summary>The CI policy check on <code>BASE_IMAGE</code> (it has no digest), and the deploy-time signature verification, since the push was not made by the pipeline.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `not found` or `failed to resolve source metadata` for a `@sha256:` reference (typical wording) | The digest was mistyped or truncated, or is a per-platform digest not available on your platform | Copy the whole `Digest:` line from `docker buildx imagetools inspect` |
| `base name (${BASE_IMAGE}) should not be blank` (typical wording) | `BASE_IMAGE` was passed as an empty value | Pass a non-empty `--build-arg BASE_IMAGE=...` or remove the argument to use the default |
| Message that attestations are not supported by the `docker` driver (typical wording) | Classic image store with the default builder | Enable the containerd image store or use a `docker-container` builder, then clean up |
| `python: command not found` | macOS/Linux has only `python3` | Use `python3`, or the Docker route from lesson 01 |
| Policy check prints `PASS` for an all-zero digest | The checker validates form only | Pull and verify the image, and verify the signature, in the pipeline |
| Pinned reference breaks on an Arm laptop | A per-platform digest was pinned | Pin the index digest from `imagetools inspect` |

## Best practice
Pin base images by digest, keep the tag in the reference for humans, update pins through reviewed automation, and rebuild regularly so pinned images still get patches. Source: Docker Build best practices https://docs.docker.com/build/building/best-practices/

## Going further
- SBOM attestations: https://docs.docker.com/build/metadata/attestations/sbom/
- Provenance attestations and SLSA: https://docs.docker.com/build/metadata/attestations/slsa-provenance/
- OCI image-spec (manifests, digests, annotations): https://github.com/opencontainers/image-spec/blob/main/spec.md
- Sigstore cosign documentation (upstream project, not a Tier 1 source; check the flags of your version): https://docs.sigstore.dev/
- Next lesson's runtime controls are what remains when an image you trusted turns out to be bad.

## Summary
- You explained why a digest, not a tag, names an image, and pinned a base image by digest.
- You built an image with an SBOM and queried an SBOM for a package.
- You described what a signature proves and what it does not, and where verification must happen.
- You enforced a base-image policy with a script and recorded the trade-off as an ADR.

## Next lesson
03. Runtime hardening: seccomp, AppArmor, user namespaces, rootless Docker and read-only roots, tested on a running container.
