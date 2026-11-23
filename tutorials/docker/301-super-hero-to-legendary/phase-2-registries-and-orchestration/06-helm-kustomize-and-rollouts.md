---
track: docker
level: 301
phase: 2
phase_name: registries-and-orchestration
lesson: 06
title: Helm, Kustomize and rollout strategies
time: 100 min
prerequisites: ["docker 301 lesson 05", "docker 201 lessons 05, 09"]
versions: { docker: "29.9.3 (inherited authoring baseline, not re-checked)", kubernetes: "client and cluster versions not pinned: use the current stable release", helm: "3 (current release; not pinned)", kind: "current release", python_image: "3.13-slim" }
verified: not yet run
source: source/docker/301-super-hero-to-legendary/phase-2-registries-and-orchestration/06-helm-kustomize-and-rollouts/
assets: []
---

# 06. Helm, Kustomize and rollout strategies

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Produce per-environment variants of one set of manifests with Kustomize overlays, and render them without a cluster.
- Package the same application as a Helm chart, set values, lint and render it, and explain how Helm's release history differs from Kustomize.
- Run a rolling update, a deliberately broken release and a rollback, and read what the Deployment does in each case.
- Choose between rolling, blue/green and canary releases for a given service and state what each requires.

## Recap
- What does a readiness probe change, and a liveness probe? (lesson 05) <details><summary>Answer</summary>Readiness decides whether the pod receives traffic; liveness decides whether the container is restarted.</details>
- What did `rollout undo` fail to roll back in lesson 05, and why? <details><summary>Answer</summary>The ConfigMap: the undo reverts the pod template only, and new pods read the ConfigMap as it is now.</details>
- Why deploy by digest, not tag? (lesson 04) <details><summary>Answer</summary>A tag can move; a digest names exactly one image.</details>

## Why it matters
One service runs in several places: your laptop cluster, staging, production, perhaps several regions. Copying manifests between folders and editing them by hand drifts within weeks. Kustomize and Helm solve "same thing, different settings" in opposite ways, and each has a real cost. The second half of this lesson is about the moment of change itself: a release is where most outages begin, so how you roll out is a decision with consequences for downtime, rollback time and cost.

## What you will build
A Kustomize base with `dev` and `prod` overlays, a small Helm chart with a ConfigMap, Deployment and Service, and a rolling update from version 1.0.0 to 2.0.0 of the lesson 05 image on a local `kind` cluster, followed by a broken release (an image tag that does not exist) and a recovery. Blue/green and canary are covered as concepts with the trade-offs and the exact fields involved, not as a lab.

## Before you start
- **Prerequisites:** [Docker 301 lesson 05, from Compose to Kubernetes](05-from-compose-to-kubernetes.md); Docker 201 lessons [05, Compose profiles](../../201-hero-to-super-hero/phase-2-compose-in-depth/05-profiles-overrides-extensions.md) and [09, CI with GitHub Actions](../../201-hero-to-super-hero/phase-3-workflows/09-ci-with-github-actions.md).
- Lesson 05 finished (or at least its tools): Docker, `kubectl` and `kind`. Helm is new: Windows `winget install Helm.Helm` (if winget cannot find it, `winget search helm`), macOS `brew install helm`, Linux and others see https://helm.sh/docs/intro/install/ (Helm project documentation, not a Tier 1 source). Open a new terminal after installing.
- Time: 100 minutes. Two sittings: stop after Step 7 (everything renders offline) and do the cluster steps later.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/301-super-hero-to-legendary/phase-2-registries-and-orchestration/06-helm-kustomize-and-rollouts/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Steps 1 to 7 need no cluster and no Docker: `kubectl kustomize` and `helm template` only print text.
- To keep a throwaway probe pod allowed, the namespaces in this lesson are **not** labelled with the `restricted` Pod Security level that lesson 05 used. In real namespaces keep the label; the manifests below comply with it.

## Kustomize and Helm: two answers
| | Kustomize | Helm |
|---|---|---|
| Idea | Start from plain manifests (a **base**), then **patch** them in **overlays** | Write **templates** with placeholders, fill them from **values** |
| Built in | Yes: `kubectl kustomize` and `kubectl apply -k` | Separate tool |
| Release history and rollback | None (use Git) | Yes: each install or upgrade is a numbered **release** you can roll back |
| Config changes roll pods | Yes, with generated ConfigMaps (name includes a hash of the content) | Only if you add a checksum annotation, as this chart does |
| Reuse by others | Overlays on someone's base | Charts published to repositories and OCI registries |
| Main risk | Patch sprawl; hard to see the final result without rendering | Template logic in YAML; values sprawl; third-party charts run templated manifests you did not write |
| Good fit | Your own services with a few environments | Third-party software; many installs of the same thing; need for release rollback |

They are not enemies: many teams package their own services with Kustomize and install third-party software with Helm, and GitOps controllers (Argo CD, Flux) apply either from Git. Whichever you choose, render the result in CI and review it; the manifest the cluster receives is the one that matters.

## Rollout strategies and their prices
| Strategy | What it does | Extra capacity | Rollback | What you must have | When not to use it |
|---|---|---|---|---|---|
| Recreate | Stop all old pods, then start new ones | None | Redeploy the old version | Tolerance for downtime | Anything that must stay up |
| Rolling update | Replace pods gradually (Deployment default) | Small (`maxSurge`) | Roll back the Deployment | Old and new versions can run side by side; honest readiness probes | Changes that cannot coexist (an incompatible database change) |
| Blue/green | Run a full new copy ("green"), then switch all traffic from "blue" | A whole second copy while both run | Switch back (fast) | Capacity for two copies; schema compatible with both; a way to switch (Service selector, route) | Large or expensive workloads; sudden all-at-once exposure is unacceptable |
| Canary | Send a small share of traffic to the new version, watch, increase | Small | Send the share back to zero | Traffic splitting, metrics and a rule for "healthy" (lesson 07) | Low-traffic services (no statistical signal); no observability |
| Shadow (mirroring) | Copy real requests to the new version, discard its answers | A second copy | Stop mirroring | Idempotent or side-effect-free handling | Services that send emails, charge cards or write data |

Two facts apply to all of them. First, **during any gradual rollout two versions run at the same time**, so database and API changes must follow **expand, then contract**: first release code that works with both the old and the new schema, migrate, and only a later release removes the old path. Second, **feature flags** separate "deployed" from "released": ship the code dark and enable it for a percentage of users. That is often a better canary than infrastructure traffic splitting. Kubernetes alone offers rolling updates and a replica-ratio approximation of canary; exact percentages and automated analysis come from a gateway or mesh, or a controller such as Argo Rollouts or Flagger.

## Steps

### Step 1. Make the lesson folder and the application
**Terminal (PowerShell)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker301\lesson06\code\kustomize\base", "$HOME\code101\docker301\lesson06\code\kustomize\overlays\dev", "$HOME\code101\docker301\lesson06\code\kustomize\overlays\prod", "$HOME\code101\docker301\lesson06\code\helm\code101-api\templates" | Out-Null
Set-Location "$HOME\code101\docker301\lesson06\code"
```

**Terminal (macOS/Linux)**
```bash
mkdir -p ~/code101/docker301/lesson06/code/kustomize/base ~/code101/docker301/lesson06/code/kustomize/overlays/dev ~/code101/docker301/lesson06/code/kustomize/overlays/prod ~/code101/docker301/lesson06/code/helm/code101-api/templates
cd ~/code101/docker301/lesson06/code
```
Expected result: no output; you are inside `code`.

**`app.py` and `Dockerfile`: identical to lesson 05.** Copy `app.py` and `Dockerfile` from your lesson 05 `code` folder into this `code` folder, unchanged (the source pack for this lesson contains the same two files). There are no differences: same program, same image, version set by the build argument `APP_VERSION`. If you no longer have them, retype them from lesson 05, Step 3.

The only application-related file that differs is `.dockerignore`, because this lesson has different folders to exclude:

**File: `.dockerignore`**
```text
.git
*.md
*.yaml
kustomize
helm
__pycache__
```
Keeps manifests, the Kustomize and Helm folders and Markdown out of the image build context.

### Step 2. The Kustomize base
The base is the common manifest set, without any environment specifics (no namespace, no image tag).

**File: `kustomize/base/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app.kubernetes.io/name: api
spec:
  replicas: 2
  revisionHistoryLimit: 5
  progressDeadlineSeconds: 60
  minReadySeconds: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app.kubernetes.io/name: api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: api
    spec:
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: api
          image: code101/api
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
          envFrom:
            - configMapRef:
                name: api-config
          lifecycle:
            preStop:
              exec:
                command: ["sleep", "5"]
          startupProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 2
            failureThreshold: 15
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            periodSeconds: 5
            failureThreshold: 2
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 10
            failureThreshold: 3
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              memory: 128Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
```
Only what is new compared with lesson 05's Deployment (everything else is the same and was explained there):
- There is no `namespace` in `metadata`: each overlay sets it.
- `revisionHistoryLimit: 5` keeps the five previous ReplicaSets so `rollout undo` has something to return to. The default is ten; each one is a small object. `0` would disable rollback.
- `progressDeadlineSeconds: 60`: if a rollout makes no progress for 60 seconds, the Deployment is marked as failed (`rollout status` then exits with an error). It does **not** roll back by itself; it makes the failure visible.
- `minReadySeconds: 5`: a new pod must stay Ready for 5 seconds before it counts as available. This catches pods that become ready and immediately crash.
- `strategy.type: RollingUpdate` with `maxSurge: 1` (at most one pod above the desired count during the update) and `maxUnavailable: 0` (never fewer Ready pods than desired). Capacity is preserved at the price of needing room for one extra pod and a slower rollout.
- `terminationGracePeriodSeconds: 30`: how long Kubernetes waits between `SIGTERM` and `SIGKILL`.
- `image: code101/api` has **no tag**: the overlay supplies it. A base without a tag cannot be applied by mistake.
- `lifecycle.preStop` runs `sleep 5` before `SIGTERM` is sent. Why: when a pod is deleted, removal from the Service and the shutdown signal happen at about the same time; some proxies still send requests for a moment. The delay lets the endpoint removal propagate so in-flight and new requests are not sent to a pod that is already shutting down. It counts against the grace period. This is a mitigation for a real failure mode (dropped requests during rollouts), not a guarantee.
- `envFrom ... name: api-config`: refers to the ConfigMap that Kustomize **generates** (next file but one); Kustomize rewrites this name to include a content hash.

**File: `kustomize/base/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
  labels:
    app.kubernetes.io/name: api
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: api
  ports:
    - name: http
      port: 80
      targetPort: http
```
Same Service as lesson 05, without a namespace.

**File: `kustomize/base/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
configMapGenerator:
  - name: api-config
    literals:
      - GREETING=hello from base
      - WARMUP_SECONDS=5
```
- `kind: Kustomization` marks this folder as a Kustomize unit; the file name must be `kustomization.yaml`.
- `resources` lists the manifests to include.
- `configMapGenerator` creates a ConfigMap named `api-config` from literal key=value lines. Kustomize appends a **hash of the content** to the real name (for example `api-config-<hash>`) and rewrites every reference. **Why it matters:** when the content changes, the name changes, so the pod template changes, so a rolling update starts. Config and workload roll forward **and back** together; this is the fix for lesson 05's ConfigMap hazard. The cost: old ConfigMaps accumulate until pruned.

### Step 3. The overlays
**File: `kustomize/overlays/dev/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: code101-dev
resources:
  - ../../base
images:
  - name: code101/api
    newTag: 1.0.0
replicas:
  - name: api
    count: 1
configMapGenerator:
  - name: api-config
    behavior: merge
    literals:
      - GREETING=hello from dev
```
- `namespace: code101-dev` sets the namespace on every resource.
- `resources: - ../../base` includes the base two folders up.
- `images`: finds containers using the image name `code101/api` and sets the tag to `1.0.0`. For production you would use `digest:` instead of `newTag:` (lesson 04).
- `replicas`: sets the replica count of the Deployment named `api` to 1.
- `configMapGenerator` with `behavior: merge` combines with the base's ConfigMap: keys listed here override or add; other keys (`WARMUP_SECONDS`) remain.

**File: `kustomize/overlays/prod/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: code101-prod
resources:
  - ../../base
images:
  - name: code101/api
    newTag: 1.0.0
replicas:
  - name: api
    count: 3
configMapGenerator:
  - name: api-config
    behavior: merge
    literals:
      - GREETING=hello from prod
```
Identical to the `dev` overlay except three lines: the namespace is `code101-prod`, `count` is `3`, and the greeting is `hello from prod`.

### Step 4. Render the overlays (no cluster needed)
**Terminal (any OS; folder: `code`)**
```bash
kubectl kustomize kustomize/overlays/dev
```
The command prints the final manifests: a ConfigMap, a Service and a Deployment (order may differ). Lines you should find, derived by reading the files (not yet run):
```text
namespace: code101-dev
image: code101/api:1.0.0
replicas: 1
```
You should also find the generated ConfigMap named `api-config-` followed by a hash, and `GREETING: hello from dev` and `WARMUP_SECONDS: "5"` in its `data`, and the same hashed name inside the Deployment's `envFrom`. Now the production variant:

**Terminal (any OS; folder: `code`)**
```bash
kubectl kustomize kustomize/overlays/prod
```
Lines you should find (not yet run):
```text
namespace: code101-prod
replicas: 3
GREETING: hello from prod
```
**Always render before you apply.** Reviewing the rendered output in CI (and diffing it between commits) is the only way to see what an overlay really does.

### Step 5. The Helm chart
A **chart** is a folder with a `Chart.yaml`, default `values.yaml` and a `templates` folder. Create these files under `helm/code101-api`.

**File: `helm/code101-api/Chart.yaml`**
```yaml
apiVersion: v2
name: code101-api
description: Demo API chart for the Docker 301 course
type: application
version: 0.1.0
appVersion: "1.0.0"
```
- `apiVersion: v2` is the chart format for Helm 3.
- `name` is the chart's name; `description` is free text.
- `type: application` (as opposed to a library chart that only shares templates).
- `version` is the **chart's** version (bump it when templates change). `appVersion` is the version of the **application** the chart deploys; the template below uses it as the default image tag. They are different things.

**File: `helm/code101-api/values.yaml`**
```yaml
replicaCount: 2
image:
  repository: code101/api
  tag: ""
  pullPolicy: IfNotPresent
config:
  greeting: hello from helm
  warmupSeconds: 5
service:
  port: 80
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    memory: 128Mi
rollout:
  maxSurge: 1
  maxUnavailable: 0
```
- The defaults users may override. `image.tag: ""` means "use the chart's `appVersion`". Keep the set of values **small**: every value is a public interface of the chart that you must keep compatible.

**File: `helm/code101-api/templates/_helpers.tpl`**
```text
{{- define "code101-api.fullname" -}}
{{- .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{- define "code101-api.selectorLabels" -}}
app.kubernetes.io/name: code101-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "code101-api.labels" -}}
{{ include "code101-api.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
```
- A file starting with `_` produces no manifest; it defines reusable **named templates** with `define`.
- `{{ ... }}` is Helm's template syntax; a `-` inside the braces trims neighbouring whitespace.
- `code101-api.fullname` uses the release name (the name you give at install time), cut to 40 characters.
- `selectorLabels` are the labels used for selection: they must be **stable**, because a Deployment's selector cannot change after creation; `labels` adds changing information (version) and is used on metadata only.
- `.Release.Name`, `.Release.Service` (always `Helm` for Helm itself) and `.Chart.AppVersion` are built-in values.

**File: `helm/code101-api/templates/configmap.yaml`**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "code101-api.fullname" . }}-config
  labels:
    {{- include "code101-api.labels" . | nindent 4 }}
data:
  GREETING: {{ .Values.config.greeting | quote }}
  WARMUP_SECONDS: {{ .Values.config.warmupSeconds | quote }}
```
- `include "name" .` renders a named template with the current context (`.`); `nindent 4` adds a newline and indents by four spaces.
- `.Values.config.greeting` reads `values.yaml` (or your override). `| quote` wraps the value in quotes, which also turns the number `5` into the string `"5"` that a ConfigMap requires.

**File: `helm/code101-api/templates/service.yaml`**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "code101-api.fullname" . }}
  labels:
    {{- include "code101-api.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  selector:
    {{- include "code101-api.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .Values.service.port }}
      targetPort: http
```
Same Service as before; the name, labels, selector and port now come from helpers and values.

**File: `helm/code101-api/templates/deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "code101-api.fullname" . }}
  labels:
    {{- include "code101-api.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  revisionHistoryLimit: 5
  progressDeadlineSeconds: 60
  minReadySeconds: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: {{ .Values.rollout.maxSurge }}
      maxUnavailable: {{ .Values.rollout.maxUnavailable }}
  selector:
    matchLabels:
      {{- include "code101-api.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "code101-api.selectorLabels" . | nindent 8 }}
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
    spec:
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: api
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8080
          envFrom:
            - configMapRef:
                name: {{ include "code101-api.fullname" . }}-config
          lifecycle:
            preStop:
              exec:
                command: ["sleep", "5"]
          startupProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 2
            failureThreshold: 15
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            periodSeconds: 5
            failureThreshold: 2
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 10
            failureThreshold: 3
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
```
What is new compared with the Kustomize base:
- `replicas`, `maxSurge`, `maxUnavailable` come from values.
- The `selector.matchLabels` uses only the stable `selectorLabels`.
- `annotations: checksum/config: ...` renders the ConfigMap template, hashes it with `sha256sum` and stores the hash on the **pod template**. When the config changes, the hash changes, the template changes and a rolling update starts. This is the Helm idiom for what Kustomize's generator does automatically; forgetting it reproduces lesson 05's hazard.
- `image: "{{ repository }}:{{ tag | default appVersion }}"` builds the reference; `default` supplies the chart's `appVersion` when the tag is empty.
- `toYaml .Values.resources | nindent 12` copies the whole `resources` map from values into the YAML at the right indentation.
- The rest is as in lesson 05.

### Step 6. Lint and render the chart (no cluster needed)
**Terminal (any OS; folder: `code`)**
```bash
helm lint helm/code101-api
```
Expected output (typical; not yet run):
```text
==> Linting helm/code101-api
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```
The `icon` line is an informational suggestion. Now render only the Deployment for a release called `demo`:

**Terminal (any OS; folder: `code`)**
```bash
helm template demo helm/code101-api --show-only templates/deployment.yaml
```
The output starts with `---` and a `# Source:` comment. The first lines of the manifest, derived by reading the templates (not yet run):
```text
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
  labels:
    app.kubernetes.io/name: code101-api
    app.kubernetes.io/instance: demo
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 2
```
Further down you should find `image: "code101/api:1.0.0"` (the tag came from `appVersion`) and a `checksum/config:` annotation holding a long hash. Now override a value on the command line and see it change:

**Terminal (any OS; folder: `code`)**
```bash
helm template demo helm/code101-api --show-only templates/deployment.yaml --set replicaCount=5
```
Expected change (not yet run): the line reads `replicas: 5`. `--set` is fine for experiments; in real releases keep overrides in a values file under version control.

### Step 7. Build the two versions and create the cluster
**Terminal (any OS; folder: `code`)**
```bash
docker build -t code101/api:1.0.0 .
docker build -t code101/api:2.0.0 --build-arg APP_VERSION=2.0.0 .
kind create cluster --name code101
kind load docker-image code101/api:1.0.0 code101/api:2.0.0 --name code101
kubectl --context kind-code101 create namespace code101-prod
```
Expected output of the last command (not yet run): `namespace/code101-prod created`. The two builds differ only in the build argument, so the second reuses the cache for every step before it (a few lines of output each; not shown).

### Step 8. Roll out 1.0.0 with Kustomize, then upgrade to 2.0.0
**Terminal (any OS; folder: `code`)**
```bash
kubectl --context kind-code101 apply -k kustomize/overlays/prod
kubectl --context kind-code101 -n code101-prod rollout status deployment/api
```
Expected output (typical order; not yet run; the ConfigMap name carries a hash):
```text
configmap/api-config-<hash> created
service/api created
deployment.apps/api created
```
followed by progress lines and a final `deployment "api" successfully rolled out`.

Now watch the rollout from the **inside**. In a second terminal start a probe pod that calls the Service once a second (it is removed when you press Ctrl+C):

**Terminal 2 (any OS)**
```bash
kubectl --context kind-code101 -n code101-prod run probe --rm -it --restart=Never --image=busybox:1.37 -- sh -c "while true; do wget -q -T 2 -O- http://api/; echo; sleep 1; done"
```
Each line is the JSON of one request. Expected at this point (not yet run): `"version": "1.0.0"` in every line, with the host names of the three pods varying. (`kubectl port-forward` would not show this: it connects to **one** pod, not through the Service.)

In the first terminal, change the tag in `kustomize/overlays/prod/kustomization.yaml` from `newTag: 1.0.0` to `newTag: 2.0.0`, save, and apply:

**Terminal 1 (any OS; folder: `code`)**
```bash
kubectl --context kind-code101 apply -k kustomize/overlays/prod
kubectl --context kind-code101 -n code101-prod get pods --watch
```
**Predict first:** with 3 replicas, `maxSurge: 1` and `maxUnavailable: 0`, how many pods exist at the most, and how many are Ready at the least? (Four and three.) Expected behaviour (not yet run): a fourth pod appears (`0/1`, then `1/1`), after `minReadySeconds` an old pod terminates, then another new pod appears, and so on, one at a time. In the probe terminal the `version` values mix `1.0.0` and `2.0.0` for a short time and end as `2.0.0` only. If any request fails (an empty line or a `wget` error), do not ignore it: that is the dropped-request failure mode the `preStop` delay mitigates.

### Step 9. A broken release, and two ways back
Set `newTag: 9.9.9` (an image that does not exist anywhere) in the prod overlay and apply:

**Terminal 1 (any OS; folder: `code`)**
```bash
kubectl --context kind-code101 apply -k kustomize/overlays/prod
kubectl --context kind-code101 -n code101-prod get pods
kubectl --context kind-code101 -n code101-prod rollout status deployment/api
```
Expected behaviour (not yet run): one new pod stuck with status `ErrImagePull`, then `ImagePullBackOff`; the three old pods stay `1/1 Running`, so the probe terminal keeps showing `2.0.0` without errors. `rollout status` waits and, after the 60-second progress deadline, ends with an error whose text is typically `error: deployment "api" exceeded its progress deadline`. **The rollout stalled; nothing fell over.** That is `maxUnavailable: 0` plus honest readiness doing its job.

Two ways back:
1. **Fix the source (preferred):** set `newTag: 2.0.0` in the overlay and apply again. The Deployment returns to the existing ReplicaSet. Git and cluster agree.
2. **Roll back the cluster:** `kubectl --context kind-code101 -n code101-prod rollout undo deployment/api`. Fast in an emergency, but the cluster now differs from Git: the next `apply` of the broken overlay re-breaks it. Fix Git afterwards. Because the ConfigMap name carries a hash, the undo restores the matching ConfigMap too.

Look at the history:

**Terminal 1 (any OS)**
```bash
kubectl --context kind-code101 -n code101-prod rollout history deployment/api
```
Expected output shape (not yet run): a table with `REVISION` and `CHANGE-CAUSE` columns; the cause is `<none>` unless you annotate it.

### Step 10. The same service as a Helm release (optional)
**Terminal (any OS; folder: `code`)**
```bash
helm install demo helm/code101-api --namespace code101-helm --create-namespace --wait --timeout 2m
helm upgrade demo helm/code101-api --namespace code101-helm --set image.tag=2.0.0 --wait --timeout 2m
helm history demo --namespace code101-helm
helm rollback demo 1 --namespace code101-helm --wait
```
Typical output (not yet run): the install prints `NAME: demo`, a `LAST DEPLOYED` line, `NAMESPACE: code101-helm`, `STATUS: deployed` and `REVISION: 1`; the upgrade prints `Release "demo" has been upgraded. Happy Helming!`; the history lists revisions 1 and 2 with statuses `superseded` and `deployed`; the rollback prints `Rollback was a success! Happy Helming!` and creates revision 3. `--wait` makes Helm wait until the pods are Ready, and the command fails if they are not within the timeout. In pipelines, `helm upgrade --install --atomic --timeout 2m` rolls the release back automatically when it fails. Unlike `kubectl rollout undo`, a Helm rollback restores **all** manifests of that revision, including the ConfigMap.

### Step 11. Clean up
**Terminal (any OS)**
```bash
helm uninstall demo --namespace code101-helm
kind delete cluster --name code101
docker image rm code101/api:1.0.0 code101/api:2.0.0
```
Deleting the cluster removes everything inside it; `helm uninstall` is shown for completeness (skip it if you already deleted the cluster).

## Blue/green and canary: the fields involved
These are fragments to read, **not applied** in this lesson.

**Blue/green** uses two Deployments, labelled by colour, and a Service whose selector names the live colour. The switch is a change of one selector value:
```yaml
spec:
  selector:
    app.kubernetes.io/name: api
    track: green
```
Everything else about "green" is a normal Deployment with `track: green` in its pod labels **and** selector. You deploy green, test it through a separate test Service or port-forward, then change the Service selector from `blue` to `green`. Rollback is changing it back. Costs: double capacity during the switch; every client sees the new version at once; long-lived connections stay on the old pods until they end; the database must work with both versions.

**Canary by replica ratio** uses two Deployments and **one** Service that selects only the common label, so it spreads connections over every ready pod of both:
```yaml
spec:
  selector:
    app.kubernetes.io/name: api
```
The stable Deployment has 9 replicas and the canary Deployment 1, so roughly one connection in ten reaches the canary. Each Deployment's own `selector.matchLabels` must include its `track` label (`stable` or `canary`); if both Deployments select the same labels they fight over each other's pods. The limits: the split follows pod counts and connection counts, not request counts, so keep-alive connections and uneven load skew it; you cannot send exactly 1 percent; and **you must watch error rate and latency of the canary specifically** (lesson 07) or the canary tells you nothing. For weighted routing use the Gateway API's weighted backends or a controller built for it: https://kubernetes.io/docs/concepts/services-networking/gateway/.

## How it works
Kustomize is a **transformer pipeline**: it reads the base, applies overlay transformations (namespace, image, replicas, generated config) and prints plain manifests. It has no state. Helm is a **template engine plus a release manager**: it renders templates with values, sends the manifests to the cluster, and stores the rendered result of every revision in the cluster so it can show history and roll back. A Deployment rolling update is a controller creating a new ReplicaSet and moving pods across within `maxSurge` and `maxUnavailable`, gated by readiness and `minReadySeconds`.

The misconception to correct: "Helm or Kustomize deploys safely". Neither does anything about safety: the rollout behaviour comes from the Deployment fields, probes and your observability. They only generate the manifests.

## Decision record (ADR-06): rollout and packaging defaults
- **Context:** twelve services, three environments, ad hoc release scripts, two incidents last quarter caused by a config change that nobody rolled back.
- **Decision:** our own services use Kustomize (base plus `dev`, `staging`, `prod` overlays) with generated ConfigMaps; third-party software is installed with pinned Helm chart versions. The default strategy is a rolling update with `maxUnavailable: 0`. Services that handle money or have more than a set traffic level add a canary stage once lesson 07's metrics exist for them. Blue/green is reserved for changes where a fast, all-at-once switch back matters more than the cost of a second copy.
- **Consequences:** reviewers must read rendered output in pull requests; the platform team maintains the base; Helm chart upgrades are reviewed as code, because chart authors can change what is deployed.
- **Alternatives rejected:** Helm for everything (template sprawl for simple services); raw manifests per environment (drift); canary everywhere (needs signal and traffic that low-volume services lack).
- **Revisit when:** a GitOps controller is adopted (it changes how overlays are applied, not whether they are used) or traffic splitting becomes available at the gateway.

## When not to use this
- A single service in a single environment needs neither: plain manifests are enough. Add Kustomize at the second environment, Helm when you publish a package others install.
- Do not write Helm charts for internal services only to template three values; the indirection costs more than it saves.
- Do not use canary releases for services with too little traffic to measure, or without per-version metrics. A canary with no signal is a slow rolling update.
- Do not use blue/green for stateful systems whose data layout the two versions cannot share.

## Failure modes
- **Unrendered review:** a pull request changes an overlay and nobody sees what it renders to. Render in CI and diff.
- **Patch sprawl:** overlays that patch deep into the base until nobody understands the result. Keep overlays to namespace, tag, replicas, config and a few patches.
- **Chart values as an unreviewed API:** a third-party chart update changes defaults (for example a security setting). Pin chart versions and read the diff of `helm template` output between versions.
- **Mixed versions break:** the new version writes data the old version cannot read, and a rolling update runs both. Use expand then contract.
- **Config and code roll separately:** the lesson 05 hazard; generated ConfigMaps or checksum annotations fix it.
- **Stalled rollouts unnoticed:** `progressDeadlineSeconds` only marks the failure; alert on `Progressing=False` or on `rollout status` failing in the pipeline.
- **`latest` or a moved tag in `newTag`:** the same text deploys different bytes. Use a digest.
- **Dropped requests at shutdown:** no `preStop` delay, no `SIGTERM` handler.
- **Rollback to a version whose database migration cannot be undone:** the code rolls back, the schema does not.

## Measurements to take
- Rollout duration for each service (`rollout status` start to finish) and the ratio to your target.
- Error rate and latency percentiles before, during and after each release (lesson 07's metrics).
- Time to roll back (Git revert to healthy pods), measured in a drill (lesson 09).
- Number of releases per week that needed a rollback (a quality signal for your tests, not for your rollout tool).
- For canaries: the traffic share actually received by the canary pods (compare with the intended share).

## Production checklist
- [ ] Rendered manifests are produced and diffed in CI before apply.
- [ ] Images referenced by digest in prod overlays or values.
- [ ] `maxUnavailable` and `maxSurge` chosen per service; `progressDeadlineSeconds` set; the pipeline fails when a rollout does not finish.
- [ ] Config changes roll pods (generated ConfigMaps or checksum annotations).
- [ ] `preStop` delay and `SIGTERM` handling verified under load.
- [ ] Database changes follow expand then contract; the rollback plan names the schema state.
- [ ] A rollback was rehearsed in the last quarter, including its effect on config and data.
- [ ] Third-party chart versions pinned and upgrades reviewed.

## Try it
Work in a folder `exercise` next to `code`. Copy the starter files.

**File: `exercise/kustomize/overlays/staging/kustomization.yaml` (starter)**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
# TODO 1: set the namespace to code101-staging.
# TODO 2: include the base (two folders up).
# TODO 3: use image tag 2.0.0 and 2 replicas.
# TODO 4: merge the greeting "hello from staging" into api-config.
```

**File: `exercise/values-prod.yaml` (starter)**
```yaml
# TODO: make the prod release run 3 replicas and greet "hello from prod".
# Write only the keys that change; Helm merges this file over values.yaml.
```
1. **Guided:** complete the staging overlay (copy it to `code/kustomize/overlays/staging/` so `../../base` resolves) and render it with `kubectl kustomize kustomize/overlays/staging`. Which three lines should you find?
2. **Change:** complete `values-prod.yaml` and render with `helm template demo helm/code101-api -f ../exercise/values-prod.yaml --show-only templates/deployment.yaml` from `code`. Predict the `replicas:` line, and predict whether `warmupSeconds` is lost when you override only `greeting` (it is not).
3. **Stretch (no single answer):** you operate a payments API (steady traffic, no tolerance for double charges) and an internal admin tool (a few users). Choose a rollout strategy for each and write the two things each choice requires. State one metric you would use to decide whether the payments canary proceeds.

<details><summary>Solution</summary>

**File: `exercise/solution/kustomize/overlays/staging/kustomization.yaml`**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: code101-staging
resources:
  - ../../base
images:
  - name: code101/api
    newTag: 2.0.0
replicas:
  - name: api
    count: 2
configMapGenerator:
  - name: api-config
    behavior: merge
    literals:
      - GREETING=hello from staging
```
Expected lines when rendered (not yet run): `namespace: code101-staging`, `image: code101/api:2.0.0` and `replicas: 2`.

**File: `exercise/solution/values-prod.yaml`**
```yaml
replicaCount: 3
config:
  greeting: hello from prod
```
Expected line (not yet run): `replicas: 3`. Helm merges maps key by key, so `config.warmupSeconds` keeps its default of 5. (Lists are replaced, not merged: remember that when you override a list.) For the stretch, a defensible answer: payments gets a canary with a metric such as the canary's 5xx ratio and p99 latency compared with stable, requiring traffic splitting, per-version metrics and backward-compatible schema changes; the admin tool gets a plain rolling update, requiring only honest readiness and a rollback command. Reject blue/green for payments unless both versions can safely share the same idempotency state.

</details>

## Check yourself
1. Why does a Kustomize-generated ConfigMap have a hash in its name? <details><summary>Answer</summary>So that a content change changes the name, which changes the pod template and starts a rolling update; config and workload roll forward and back together.</details>
2. Predict: `replicas: 3`, `maxSurge: 1`, `maxUnavailable: 0`. What is the maximum number of pods during an update, and the minimum number Ready? <details><summary>Answer</summary>Four at most; three Ready at least.</details>
3. A rollout to a non-existent image tag: do users notice? <details><summary>Answer</summary>No, with `maxUnavailable: 0`: the old pods keep serving; the rollout stalls and `rollout status` fails after the progress deadline.</details>
4. What does `helm rollback` restore that `kubectl rollout undo` does not? <details><summary>Answer</summary>All manifests of the earlier revision, including the ConfigMap; `undo` reverts only the Deployment's pod template.</details>
5. Why can a replica-ratio canary not give exactly 1 percent? <details><summary>Answer</summary>The split follows pod and connection counts, so granularity is one pod and long-lived connections skew it; exact weights need a gateway or mesh.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `kubectl: command not found` or an old kubectl without `kustomize` support (typical) | `kubectl` is missing or very old | Install a current kubectl |
| `accumulating resources` or `must build at directory` (typical wording) | Wrong path: the folder has no `kustomization.yaml` | Run from `code` and point at `kustomize/overlays/dev` |
| `Error: INSTALLATION FAILED: ... namespace ... not found` (typical wording) | Namespace does not exist | Add `--create-namespace` |
| `ErrImagePull` / `ImagePullBackOff` right after the 2.0.0 apply | `kind load` was not run for that tag | `kind load docker-image code101/api:2.0.0 --name code101` |
| `error: deployment "api" exceeded its progress deadline` | The new pods did not become Ready in 60 seconds | `describe pod` and read the Events; fix the cause |
| Helm: `YAML parse error` or `nil pointer evaluating interface` (typical wording) | Indentation after `nindent` or a missing value | `helm template` and read the line it names |
| Config edit does not restart pods (Helm) | No checksum annotation | Add the `checksum/config` annotation |
| `kubectl port-forward svc/api` always shows the same host name | It forwards to one pod | Use an in-cluster probe to observe load balancing |

## Best practice
Treat rendered manifests as the artefact you review, pin versions and digests, make config changes roll the pods, and measure every release. Source: Kubernetes documentation, Deployments (rolling updates) https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ and Declarative management with Kustomize https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/

## Going further
- Helm documentation (upstream project, not a Tier 1 source): https://helm.sh/docs/
- Performing a rolling update: https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/
- Gateway API traffic splitting: https://kubernetes.io/docs/concepts/services-networking/gateway/
- Lesson 07 supplies the metrics that make canaries meaningful; lesson 09 turns rollback into a rehearsed drill.

## Summary
- You produced `dev` and `prod` variants with Kustomize overlays and rendered them offline.
- You packaged the same app as a Helm chart, linted and rendered it, and explained release history.
- You ran a rolling update, a stalled bad release and two ways back, and read what each does.
- You compared rolling, blue/green, canary and shadow releases with their prices and prerequisites.

## Next lesson
07. Observability for containers: logs, metrics and traces, with a Prometheus, Grafana and OpenTelemetry collector Compose stack in full.
