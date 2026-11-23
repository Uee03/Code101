---
track: docker
level: 301
phase: 3
phase_name: operations
lesson: 08
title: Resource management, autoscaling concepts and cost
time: 100 min
prerequisites: ["docker 301 lessons 05 to 07", "docker 201 lessons 05, 07"]
versions: { docker: "29.9.3 (inherited authoring baseline, not re-checked)", compose: "5.7.0 (inherited)", kubernetes: "client and cluster versions not pinned: use the current stable release", metrics_server: "v0.9.1 (latest release found on 2026-11-23, a lookup)", python_image: "3.13-slim", python: "3.13" }
verified: not yet run
source: source/docker/301-super-hero-to-legendary/phase-3-operations/08-resources-autoscaling-and-cost/
assets: []
---

# 08. Resource management, autoscaling concepts and cost

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain requests and limits, what happens when a container reaches each, and the three Kubernetes quality-of-service classes.
- Trigger an out-of-memory kill and a CPU throttle on purpose with Compose and read the evidence.
- Configure a HorizontalPodAutoscaler, predict its replica count from its formula, and list what makes it fail.
- Build a simple cost model from requests and measured usage, and use it to decide what to right-size.

## Recap
- What did lesson 03 say about `mem_limit` and `pids_limit`? <details><summary>Answer</summary>Set them from measurements; too low causes out-of-memory kills or thread-creation failures.</details>
- Which metric families did lesson 07 say it could not provide, and why? <details><summary>Answer</summary>Per-container CPU and memory (the USE data): they come from the runtime or kubelet, and a collector that reads them from the host needs privileges lesson 01 warned about.</details>
- What does a Kubernetes readiness probe do during a rollout? (lessons 05 and 06) <details><summary>Answer</summary>It gates traffic and lets a stalled rollout leave the old pods serving.</details>

## Why it matters
Two opposite mistakes cost money or availability. **Too little** reserved for a container and it is killed (memory) or starved (CPU) at the worst moment. **Too much** and you pay for capacity nobody uses. Autoscaling is the attempt to match supply to demand automatically; it works only when the numbers it reads are honest and when scaling out does not break something else, such as the database. Cost is not an afterthought: in Kubernetes the **requests** you write are what the scheduler reserves, and reserved capacity is what you pay for.

## What you will build
Two small Compose experiments (a program that eats memory until the kernel kills it, and a busy loop limited to half a CPU), a Kubernetes namespace with a quota and default limits, a Deployment with an autoscaler driven by CPU load (using the example image from the Kubernetes documentation), and a short Python cost model. Every cost figure in this lesson comes from **made-up placeholder inputs** you must replace with your own.

## Before you start
- **Prerequisites:** Docker 301 lessons [05, from Compose to Kubernetes](../phase-2-registries-and-orchestration/05-from-compose-to-kubernetes.md) to [07, observability for containers](07-observability-for-containers.md); Docker 201 lessons [05, Compose profiles](../../201-hero-to-super-hero/phase-2-compose-in-depth/05-profiles-overrides-extensions.md) and [07, networking and limits](../../201-hero-to-super-hero/phase-2-compose-in-depth/07-networking-and-limits.md).
- Docker running. For Steps 5 to 8 also `kubectl` and `kind` (lesson 05). Python 3.13 is optional (a container route exists).
- Time: 100 minutes. Two sittings: stop after Step 4 (Docker-level limits), do the cluster steps later.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/301-super-hero-to-legendary/phase-3-operations/08-resources-autoscaling-and-cost/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- **Warning:** the CPU experiment keeps one core of your machine busy for 60 seconds, and the autoscaling experiment can use several. Close heavy applications first. On Docker Desktop the limits you can use are bounded by the VM's own CPU and memory settings.
- The example image `registry.k8s.io/hpa-example` is taken from the Kubernetes documentation's autoscaling walkthrough, which uses it **without a tag** (meaning `latest`). That contradicts lesson 02's policy; it is recorded here as a lab exception because the tutorial is the documented reference. Do not copy it into production.

## Requests, limits and what they mean
| | Request | Limit |
|---|---|---|
| Meaning | The amount the scheduler **reserves** for the container | The most the container may use |
| CPU at the limit | Not applicable | The container is **throttled** (it keeps running but slower) |
| Memory at the limit | Not applicable | The kernel kills the process (`OOMKilled`, exit code 137) |
| Affects scheduling | Yes: a pod only fits on a node with that much unreserved | No |
| Affects cost | Yes: reserved capacity is what a node must provide | Only indirectly |
| Affects autoscaling | CPU utilisation percentages are **relative to the request** | No |

CPU is **compressible** (you can give a process less time and it just runs slower); memory is **not** (you cannot take it back without killing something). Kubernetes derives a **quality-of-service class** from the numbers and uses it to choose victims under node memory pressure:
- **Guaranteed:** every container has CPU and memory requests equal to limits. Evicted last.
- **Burstable:** at least one request or limit is set, but not Guaranteed. The common case.
- **BestEffort:** no requests or limits at all. Evicted first. Avoid for anything that matters.

There is a real debate about **CPU limits**. Setting one protects neighbours from a runaway process, but a container can be throttled even when the node has idle CPU, which shows up as latency spikes. Many teams set CPU **requests** (so scheduling and autoscaling are right) and omit CPU limits for latency-sensitive services, while always setting **memory** limits, often equal to the request for predictability. Treat this as a measured choice for each service: compare latency percentiles with and without the limit (lesson 07), do not copy a rule.

Language runtimes need to know the limit. The kernel enforces it, but a runtime that sizes its heap from the machine's memory instead of the container's can be killed before its own garbage collector acts. Current Go, Java and .NET runtimes read container limits; check your runtime's documentation, and consider explicit settings (for example Go's `GOMEMLIMIT`, the JVM's `-XX:MaxRAMPercentage`). Python and Node.js do not size themselves to the limit: leave headroom.

## Steps

### Step 1. Make the lesson folder
**Terminal (PowerShell)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker301\lesson08\code\k8s" | Out-Null
Set-Location "$HOME\code101\docker301\lesson08\code"
```

**Terminal (macOS/Linux)**
```bash
mkdir -p ~/code101/docker301/lesson08/code/k8s
cd ~/code101/docker301/lesson08/code
```
Expected result: no output; you are inside `code`. All commands run here unless stated.

### Step 2. The Compose experiment files
**File: `memhog.py`**
```python
import time

chunks = []
while True:
    chunks.append(b"x" * (10 * 1024 * 1024))
    print(f"allocated {len(chunks) * 10} MiB", flush=True)
    time.sleep(0.2)
```
- It appends a 10 MiB block of real data every 0.2 seconds (`b"x" * n` writes every byte, so the memory is genuinely used, not just promised) and prints the running total. It never frees anything: it must end by being killed.

**File: `cpuburn.py`**
```python
import time

deadline = time.monotonic() + 60
count = 0
while time.monotonic() < deadline:
    count += 1
print(f"iterations in 60 seconds: {count}", flush=True)
```
- It counts loop iterations for 60 seconds of wall-clock time and prints the count. The count is a **measurement of the CPU time the container actually received**: halve the CPU and it should drop accordingly. Its value depends on your machine and is not predicted here.

**File: `docker-compose.yml`**
```yaml
name: code101-resources
services:
  memhog:
    image: python:3.13-slim
    profiles: ["memory"]
    command: ["python", "/app/memhog.py"]
    volumes:
      - ./memhog.py:/app/memhog.py:ro
    user: "10001:10001"
    mem_limit: 64m
    memswap_limit: 64m
    restart: "no"
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
  cpuburn:
    image: python:3.13-slim
    profiles: ["cpu"]
    command: ["python", "/app/cpuburn.py"]
    volumes:
      - ./cpuburn.py:/app/cpuburn.py:ro
    user: "10001:10001"
    cpus: 0.5
    mem_limit: 64m
    restart: "no"
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```
Line by line:
- `profiles: ["memory"]` and `["cpu"]`: a service with a profile starts only when you ask for that profile (`--profile memory`). So the two experiments never run together by accident.
- `command` runs the mounted script. The script files are mounted read-only from your folder, so no image build is needed.
- `user: "10001:10001"`: non-root, numeric (lesson 03).
- `mem_limit: 64m`: a hard memory limit of 64 mebibytes. `memswap_limit: 64m`: memory plus swap may not exceed 64 MiB, which means **no swap**. Without it, the process may be allowed to push pages to swap and survive far longer than you expect, which makes the experiment slow and the result less clear.
- `restart: "no"` (quoted: unquoted `no` is a YAML boolean): do not restart after the kill, so you can inspect the stopped container.
- `cpus: 0.5`: the container may use at most half a CPU's worth of time, enforced by CFS (the Linux scheduler) quota. `mem_limit: 64m` there caps the second experiment too.
- `read_only`, `cap_drop`, `security_opt`: lesson 03.

### Step 3. Hit the memory limit
**Predict first:** at roughly what total will the program die, and what exit code will the container have? Then run:

**Terminal (any OS; folder: `code`)**
```bash
docker compose --profile memory up --exit-code-from memhog
```
Expected output shape (not yet run): lines `memhog-1  | allocated 10 MiB`, `allocated 20 MiB` and so on, then the output stops and Compose reports that the container exited with code 137 (typical wording: `memhog-1 exited with code 137`). The last number printed depends on how much memory the Python interpreter itself used; it will be **below 64**. This lesson does not predict it. Now ask Docker why it stopped:

**Terminal (any OS; folder: `code`)**
```bash
docker inspect --format "{{.State.OOMKilled}} {{.State.ExitCode}}" code101-resources-memhog-1
```
Expected output (not yet run):
```text
true 137
```
`OOMKilled` is `true`: the kernel's out-of-memory killer ended the process. Exit code 137 is 128 plus 9, the number of the `SIGKILL` signal (a process killed by a signal reports 128 plus the signal number). Without the `memswap_limit` line, the number of lines printed before the kill would likely be larger and less predictable. Remove the stopped container:

**Terminal (any OS; folder: `code`)**
```bash
docker compose --profile memory down
```

### Step 4. Hit the CPU limit
**Terminal (any OS; folder: `code`)**
```bash
docker compose --profile cpu up -d
docker stats --no-stream code101-resources-cpuburn-1
```
Expected result (not yet run): a table with the columns `CONTAINER ID`, `NAME`, `CPU %`, `MEM USAGE / LIMIT` and others. For a container that keeps one thread busy under a limit of 0.5 CPU, `CPU %` should be near 50 (Docker reports it relative to one CPU), and the memory limit column shows 64MiB. The exact value fluctuates; do not expect precisely 50.0. Wait 60 seconds, then read the result:

**Terminal (any OS; folder: `code`)**
```bash
docker compose --profile cpu logs cpuburn
```
Expected output (not yet run): one line like `cpuburn-1  | iterations in 60 seconds: <a number>`. **Write the number down.** Now change `cpus: 0.5` to `cpus: 1.0` in `docker-compose.yml`, run `docker compose --profile cpu down`, repeat the two commands and compare the two numbers. If your machine has a free core, the second should be larger. By how much is something you measure, not guess; this is the point: a limit costs throughput, and you can measure the price. Clean up:

**Terminal (any OS; folder: `code`)**
```bash
docker compose --profile cpu down
```

### Step 5. A namespace with a quota and default limits (Kubernetes)
Create the cluster first: `kind create cluster --name code101` (lesson 05).

**File: `k8s/00-namespace.yaml`**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: code101-scale
  labels:
    pod-security.kubernetes.io/enforce: baseline
```
- A new namespace for this experiment. The Pod Security level is `baseline` here, not `restricted` as in lesson 05: the documentation's example image runs as root and would be refused by `restricted`. Real workloads should be fixed to meet `restricted`; this is a lab exception.

**File: `k8s/01-quota-and-limits.yaml`**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: code101-scale
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.memory: 4Gi
    pods: "20"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: code101-scale
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: 100m
        memory: 64Mi
      default:
        memory: 256Mi
      max:
        memory: 1Gi
```
- One file can hold several objects separated by a line containing three dashes.
- **ResourceQuota** caps what the whole namespace may request: at most 2 CPUs of total requests, 2 GiB of requested memory, 4 GiB of memory limits and 20 pods. It is the safety net against a runaway autoscaler or a mistake: new pods beyond the quota are **rejected** (the ReplicaSet reports `exceeded quota` events). Once a quota covers CPU or memory, **every pod must declare those values**; the LimitRange below supplies defaults so it does not fail.
- **LimitRange** sets per-container rules: `defaultRequest` is the request given to containers that declare none (100 millicores and 64 MiB); `default` is the **limit** given to containers that declare none (256 MiB of memory; no CPU limit); `max` is the largest memory limit any container may ask for (1 GiB). Defaults are a safety net, not a design: a workload relying on them was never sized.

### Step 6. The workload and the autoscaler
**File: `k8s/02-php-apache.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
  namespace: code101-scale
spec:
  selector:
    matchLabels:
      run: php-apache
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
        - name: php-apache
          image: registry.k8s.io/hpa-example
          ports:
            - containerPort: 80
          resources:
            limits:
              cpu: 500m
            requests:
              cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  namespace: code101-scale
  labels:
    run: php-apache
spec:
  ports:
    - port: 80
  selector:
    run: php-apache
```
- This is the Kubernetes documentation's autoscaling example, with a namespace added. The Deployment **does not set `replicas`**: if it did, every `kubectl apply` would reset the count and fight the autoscaler.
- `image: registry.k8s.io/hpa-example` is a small web server that burns CPU for each request. No tag: see the exception in "Before you start".
- `resources.requests.cpu: 200m` is 200 millicores (0.2 of a core): the CPU the scheduler reserves and the baseline for the utilisation percentage. `limits.cpu: 500m` caps it at half a core. The memory request and limit come from the LimitRange (64 MiB and 256 MiB).
- The `Service` gives pods a stable name (`php-apache`) inside the namespace so the load generator can reach them.

**File: `k8s/03-hpa.yaml`**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
  namespace: code101-scale
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 4
          periodSeconds: 30
    scaleDown:
      stabilizationWindowSeconds: 120
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
```
- `autoscaling/v2` is the current API version (it supports several metrics and `behavior`).
- `scaleTargetRef` names what to scale: the Deployment `php-apache`.
- `minReplicas: 1`, `maxReplicas: 10`: the bounds. **The maximum is a cost and a blast-radius decision**: it caps spending in a traffic spike or a runaway loop, and it caps how many connections you can open to the database behind this service.
- `metrics`: one metric, the pods' average CPU **utilisation** (usage divided by the **request**), with a target of 50 percent. With a 200 millicore request, 50 percent is 100 millicores of use per pod.
- `behavior` controls the speed. `scaleUp`: no stabilisation window and at most 4 more pods every 30 seconds. `scaleDown`: use the highest recommendation of the last 120 seconds, and remove at most 1 pod per 60 seconds. Scaling up fast and down slowly avoids **flapping** (replica counts oscillating as load wobbles). The defaults are different; these values are for the lab.
- **The formula**, from the Kubernetes documentation: `desiredReplicas = ceil[currentReplicas × (currentMetricValue / desiredMetricValue)]`. Worked example (an illustration, not observed output): 1 pod using 250 millicores of its 200-millicore request is 125 percent utilisation; with a 50 percent target, `ceil(1 × 125 / 50) = ceil(2.5) = 3` replicas.

### Step 7. Install the metrics server and run the experiment
The autoscaler reads CPU use from the **Metrics API**, which the **metrics-server** add-on provides. A fresh `kind` cluster does not have it.

**Terminal (any OS; folder: `code`)**
```bash
kubectl --context kind-code101 apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.1/components.yaml
```
This downloads a manifest from the internet and applies it to your cluster. That is exactly the supply-chain action lesson 02 warned about: it is acceptable in a throwaway lab, pinned to a version, and **you should open the URL and read the manifest first**. In production, mirror and review it, or use your platform's managed metrics component. Then, because `kind` nodes present certificates metrics-server does not trust, add one flag for this lab only:

**File: `metrics-server-kind-patch.json`**
```json
[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]
```
- A JSON Patch: one operation that **adds** (`op`) a new element at the end (`/-`) of the first container's `args` list, with the value `--kubelet-insecure-tls`. That flag turns off verification of the node's certificate: never do that on a real cluster.

**Terminal (any OS; folder: `code`)**
```bash
kubectl --context kind-code101 -n kube-system patch deployment metrics-server --type=json --patch-file metrics-server-kind-patch.json
kubectl --context kind-code101 -n kube-system rollout status deployment/metrics-server
```
Expected output (not yet run): `deployment.apps/metrics-server patched`, then a final line `deployment "metrics-server" successfully rolled out`. Metrics appear about a minute after the pod is Ready. Now apply the lab:

**Terminal (any OS; folder: `code`)**
```bash
kubectl --context kind-code101 apply -f k8s/
kubectl --context kind-code101 -n code101-scale get hpa
```
Expected output of the second command (typical; not yet run; `TARGETS` shows `<unknown>/50%` until metrics-server has data, then a small percentage):
```text
NAME         REFERENCE               TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   <unknown>/50%   1         10        1          10s
```
Now generate load from inside the cluster (a pod that calls the Service in a loop; this is the load generator from the Kubernetes tutorial):

**Terminal 1 (any OS)**
```bash
kubectl --context kind-code101 -n code101-scale run load-generator --rm -i --tty --image=busybox:1.37 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```
It prints `OK!` repeatedly. In a second terminal watch the autoscaler:

**Terminal 2 (any OS)**
```bash
kubectl --context kind-code101 -n code101-scale get hpa php-apache --watch
```
**Predict first:** within a few minutes, will `REPLICAS` rise above 1, and what stops it rising to 10? Expected behaviour (not yet run): `TARGETS` climbs above 50 percent, `REPLICAS` grows in steps of up to 4 every 30 seconds, and settles when the average utilisation falls back near 50 percent. The ceiling you may hit is **your cluster**: a single-node `kind` cluster on a laptop has limited CPU, and the quota allows at most 2 CPUs of requests (10 pods x 200m is exactly 2). If pods stay `Pending`, run `kubectl --context kind-code101 -n code101-scale describe quota` and `describe pod` to see whether the quota or the node is the limit. Stop the load with Ctrl+C in terminal 1. Then watch the replicas fall slowly: with the 120-second stabilisation window and one pod removed per 60 seconds, it takes minutes. Check what the quota has reserved:

**Terminal (any OS)**
```bash
kubectl --context kind-code101 -n code101-scale describe quota compute-quota
```
Expected output shape (not yet run): a table with `Resource`, `Used` and `Hard` columns for `limits.memory`, `pods`, `requests.cpu` and `requests.memory`.

### Step 8. The cost model
Autoscaling decides how many pods exist; **requests** decide how much each one reserves, and reserved capacity is what you pay for. This model makes slack visible.

**File: `cost-inputs.json`**
```json
{
  "note": "Illustrative placeholder numbers for the exercise, not real prices. Replace them with your own.",
  "node": {"vcpu": 4, "memory_gib": 16, "price_per_hour": 0.16},
  "hours_per_month": 730,
  "cpu_share": 0.5,
  "workloads": [
    {"name": "api", "replicas": 4, "cpu_request_m": 250, "memory_request_mib": 512, "cpu_used_p95_m": 100, "memory_used_p95_mib": 256},
    {"name": "worker", "replicas": 2, "cpu_request_m": 1000, "memory_request_mib": 2048, "cpu_used_p95_m": 250, "memory_used_p95_mib": 1024}
  ]
}
```
- `node`: one node type: 4 vCPUs, 16 GiB, and an hourly price. **The price is a placeholder, not a real price.** `hours_per_month` is 730 (about the average month).
- `cpu_share: 0.5` is an **allocation assumption**: half of a node's price is attributed to CPU and half to memory. Real cost tools use their own allocation rules; changing this number changes which workloads look expensive.
- `workloads`: for each, the `replicas`, the **requests** per pod in millicores and MiB, and the **p95 usage** per pod (the 95th percentile of what it actually used over a representative period, taken from monitoring, lesson 07). The numbers here are made up.

**File: `cost_model.py`**
```python
"""Estimate what requested and used resources cost on one node type (illustrative inputs)."""
import json
import sys


def main():
    if len(sys.argv) != 2:
        print("usage: python cost_model.py <inputs.json>")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        data = json.load(handle)
    node = data["node"]
    month = node["price_per_hour"] * data["hours_per_month"]
    cpu_price = month * data["cpu_share"] / node["vcpu"]
    memory_price = month * (1 - data["cpu_share"]) / node["memory_gib"]
    print(f"Node: {month:.2f} per month; {cpu_price:.2f} per vCPU, {memory_price:.2f} per GiB")
    total = {"requested": 0.0, "used": 0.0, "cpu": 0.0, "memory": 0.0}
    for item in data["workloads"]:
        replicas = item["replicas"]
        request_cpu = replicas * item["cpu_request_m"] / 1000
        request_memory = replicas * item["memory_request_mib"] / 1024
        used_cpu = replicas * item["cpu_used_p95_m"] / 1000
        used_memory = replicas * item["memory_used_p95_mib"] / 1024
        requested = request_cpu * cpu_price + request_memory * memory_price
        used = used_cpu * cpu_price + used_memory * memory_price
        slack = (requested - used) / requested * 100 if requested else 0.0
        print(f"{item['name']:<8} requested {requested:.2f} used {used:.2f} slack {slack:.1f}%")
        total["requested"] += requested
        total["used"] += used
        total["cpu"] += request_cpu
        total["memory"] += request_memory
    slack = (total["requested"] - total["used"]) / total["requested"] * 100 if total["requested"] else 0.0
    print(f"{'total':<8} requested {total['requested']:.2f} used {total['used']:.2f} slack {slack:.1f}%")
    cpu_fill = total["cpu"] / node["vcpu"] * 100
    memory_fill = total["memory"] / node["memory_gib"] * 100
    print(f"Requests fill {cpu_fill:.1f}% of the node's CPU and {memory_fill:.1f}% of its memory")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```
How it works:
- `month` is the node's monthly price. The node price is split into a price per vCPU and a price per GiB using `cpu_share`.
- For each workload it multiplies replicas by per-pod values (converting millicores to cores and MiB to GiB) to get total **requested** and total **used** resources, prices both, and prints the **slack**: the share of the reserved cost that p95 usage does not explain. Slack is not all waste: you need headroom for spikes, rolling updates and failures; the question is whether the headroom is a decision or an accident.
- The last line says how much of one node the requests reserve, a rough view of how many nodes you need.

**Predict first:** which workload has the larger slack percentage? Then run:

**Terminal (PowerShell; folder: `code`)**
```powershell
python cost_model.py cost-inputs.json
```
macOS/Linux: `python3 cost_model.py cost-inputs.json`. Expected output (derived by hand from the numbers above; not yet run):
```text
Node: 116.80 per month; 14.60 per vCPU, 3.65 per GiB
api      requested 21.90 used 9.49 slack 56.7%
worker   requested 43.80 used 14.60 slack 66.7%
total    requested 65.70 used 24.09 slack 63.3%
Requests fill 75.0% of the node's CPU and 37.5% of its memory
```
Read it: the worker reserves four times its measured use of CPU and twice its memory. The CPU fill is 75 percent but memory fill only 37.5 percent: this node type is **CPU-bound for scheduling and memory-rich**, so a node type with a different CPU-to-memory ratio would host the same pods more cheaply. The model is deliberately crude: it ignores system overhead per node, discounts, storage and network, and it prices requests, not the nodes you actually run (with autoscaling you pay per node, and nodes are bought in whole units). Use it to find candidates for right-sizing, and take real prices from your provider.

### Step 9. Clean up
**Terminal (any OS)**
```bash
kind delete cluster --name code101
docker compose --profile memory --profile cpu down -v
```
Deleting the cluster removes the quota, autoscaler and metrics-server with it. Remove the `python:3.13-slim` and `busybox` images from your cache if you need the space.

## How it works
Two control loops are at work. The kernel enforces **limits** immediately and locally: a cgroup counts a container's memory and CPU time and either throttles or kills. The **HorizontalPodAutoscaler** is a slow loop in the control plane: every 15 seconds by default it reads the Metrics API, applies the formula to the average utilisation, applies the `behavior` rules and writes a new `replicas` value to the Deployment, whose controller then creates pods, which the scheduler places by **requests**, which the cluster autoscaler may answer by adding nodes. Each hop adds delay: metrics lag, pod scheduling, image pull, start-up and readiness warm-up. A sudden spike reaches users before new capacity does.

Misconceptions to correct. First, "limits make scheduling decisions": requests do. Second, "autoscaling means no capacity planning": it moves the question to the maximum, the quota and the node supply. Third, "high utilisation is good": a service run at 95 percent of its request has no headroom for a spike or a rollout.

**Other autoscalers**, so you know what exists: the **Vertical Pod Autoscaler** recommends (and can apply) better requests from observed use; applying changes usually means recreating pods, unless your Kubernetes version supports in-place resizing: read the current documentation. **KEDA** scales on events such as queue length and can scale to zero. The **cluster autoscaler** (or tools such as Karpenter on some clouds) adds or removes **nodes** when pods cannot be scheduled or nodes are idle. Scaling on CPU alone is the weakest signal for I/O-bound services: request rate per pod or queue depth is usually closer to the user's experience.

## Decision record (ADR-08): sizing and scaling policy
- **Context:** the cluster bill grew faster than traffic; two services were OOM-killed during a promotion; the autoscaler for the checkout service flapped.
- **Decision:** every workload declares CPU and memory requests derived from the p95 of two weeks of measured use plus a stated headroom (for example 30 percent); memory limits are set equal to memory requests; CPU limits are omitted for latency-sensitive services and reviewed per service. Autoscaling uses CPU utilisation for stateless web tiers and a queue-depth metric for workers, with `maxReplicas` set from the downstream database's connection capacity. Every namespace has a ResourceQuota and a LimitRange. A monthly report shows slack per workload.
- **Consequences:** sizing needs monitoring data (lesson 07) before launch; new services start with estimates and get revisited after two weeks; teams own their own slack numbers.
- **Alternatives rejected:** no limits anywhere (outages from neighbours); the same defaults for everything (waste); autoscale on everything (flapping and cost spikes).
- **Revisit when:** the node types, the traffic profile or the autoscaling tooling change.

## When not to use autoscaling
- Do not autoscale a service whose load is flat or whose scaling is blocked downstream: a database with a fixed connection limit is the real capacity. More pods then means more errors.
- Do not autoscale stateful workloads without a plan for state: adding replicas of a database changes its consistency model, it does not add capacity by itself.
- Do not use CPU utilisation as the signal when work arrives from a queue or when the service is bound by waiting on I/O: use a metric that tracks the work.
- Do not rely on autoscaling for a spike that arrives faster than your pods start. Pre-scale for known events or keep headroom.

## Failure modes
- **OOM kill loop:** a memory leak or an undersized limit makes pods restart repeatedly (`CrashLoopBackOff` with `OOMKilled`). Alert on restarts and compare working-set memory with the limit.
- **CPU throttling:** latency spikes with low average CPU. The cgroup throttling counters in your metrics show it; lesson 07's stack does not collect them.
- **No CPU request:** the HPA reports `failed to get cpu utilization: missing request for cpu` (typical wording), because utilisation is relative to the request.
- **No metrics-server:** `TARGETS` stays `<unknown>`.
- **Flapping:** load oscillates around the target and replicas follow. Longer scale-down windows and a wider target band help.
- **Scaling into the database:** each new pod opens connections; the database saturates and every pod gets slower, which raises CPU, which scales out further. Cap `maxReplicas` and pool connections.
- **Quota exhaustion:** the autoscaler asks for pods the quota refuses; the Deployment shows fewer ready pods than desired. Alert on quota usage.
- **Over-provisioning by copy and paste:** requests copied from a template and never measured.
- **Cost surprises:** an autoscaler at `maxReplicas` all month, or logs and metrics storage growing unnoticed.

## Measurements to take
- Per workload over two weeks: p50, p95 and maximum of CPU use and memory working set, compared with requests and limits (Prometheus metric families such as `container_cpu_usage_seconds_total` and `container_memory_working_set_bytes` from the kubelet or cAdvisor, and `kube_pod_container_resource_requests` from kube-state-metrics).
- CPU throttled time per container, and its relation to p99 latency.
- OOM kills and restarts per workload per week.
- Time from load increase to extra pods **Ready** (the scale-up delay), measured in a test.
- Node utilisation by requests and by usage; the number of nodes the cluster runs over a day.
- Slack per workload (requested minus used) in money, from your real prices.

## Production checklist
- [ ] Every container has CPU and memory requests; memory limits are set; CPU limits are a decision.
- [ ] Requests come from measured p95 use plus stated headroom, reviewed on a schedule.
- [ ] Every namespace has a ResourceQuota and a LimitRange.
- [ ] HPAs have honest metrics, bounded `maxReplicas`, and `behavior` tuned against flapping; downstream capacity is known.
- [ ] Alerts exist for OOM kills, restart loops, HPA at maximum and quota near its limit.
- [ ] Runtimes are container-aware or configured explicitly.
- [ ] A cost report shows slack and the top spenders; someone acts on it.
- [ ] The scale-up delay was measured and fits the traffic pattern.

## Try it
Work in a folder `exercise` and use `cost_model.py` from `code`. Copy the starter input:

**File: `exercise/cost-inputs.json` (starter)**
```json
{
  "note": "Illustrative placeholder numbers for the exercise, not real prices. Replace them with your own.",
  "node": {"vcpu": 4, "memory_gib": 16, "price_per_hour": 0.16},
  "hours_per_month": 730,
  "cpu_share": 0.5,
  "workloads": [
    {"name": "web", "replicas": 2, "cpu_request_m": 500, "memory_request_mib": 1024, "cpu_used_p95_m": 250, "memory_used_p95_mib": 512}
  ]
}
```
1. **Guided:** predict the `web` slack, then run `python ../code/cost_model.py cost-inputs.json` (from `exercise`; adjust the path to where you saved `cost_model.py`). Then lower only `cpu_request_m` to `300` (still above the 250 millicores of p95 use) and predict the new total and slack before running again.
2. **Change:** set `hours_per_month` to 365 (a node that runs half the month). **Predict** which printed numbers change and which do not, then run it and check. (Do not predict the exact digits.)
3. **Stretch (no single answer):** `web` now uses 250 millicores at p95 but 450 at its daily peak for ten minutes. Argue for a CPU request and say what an HPA with a 50 percent target would do at the peak. Name the measurement that decides it.

<details><summary>Solution</summary>

The starter prints (derived by hand; not yet run):
```text
Node: 116.80 per month; 14.60 per vCPU, 3.65 per GiB
web      requested 21.90 used 10.95 slack 50.0%
total    requested 21.90 used 10.95 slack 50.0%
Requests fill 25.0% of the node's CPU and 12.5% of its memory
```
**File: `exercise/solution/cost-inputs.json`**
```json
{
  "note": "Illustrative placeholder numbers for the exercise, not real prices. Replace them with your own.",
  "node": {"vcpu": 4, "memory_gib": 16, "price_per_hour": 0.16},
  "hours_per_month": 730,
  "cpu_share": 0.5,
  "workloads": [
    {"name": "web", "replicas": 2, "cpu_request_m": 300, "memory_request_mib": 1024, "cpu_used_p95_m": 250, "memory_used_p95_mib": 512}
  ]
}
```
With `cpu_request_m` 300 the output becomes (not yet run):
```text
Node: 116.80 per month; 14.60 per vCPU, 3.65 per GiB
web      requested 16.06 used 10.95 slack 31.8%
total    requested 16.06 used 10.95 slack 31.8%
Requests fill 15.0% of the node's CPU and 12.5% of its memory
```
For part 2: every **money** figure changes (the node costs half as much per month, so the prices per vCPU and per GiB halve, and so do requested and used cost), but the **percentages** (slack, node fill) do not, because they are ratios. For the stretch: a 300 millicore request leaves little room for a 450 millicore peak: the pod uses 150 percent of its request at the peak, the HPA (target 50 percent) would compute `ceil(2 x 150 / 50) = 6` replicas from 2 (an illustration), but only after its metric delay, so a ten-minute peak may be mostly over before capacity arrives; an alternative is a higher request or scheduled pre-scaling. The deciding measurement is the real distribution of load over the day and the measured scale-up time.

</details>

## Check yourself
1. A container exits with code 137 and `OOMKilled` is `true`. What happened? <details><summary>Answer</summary>It exceeded its memory limit and the kernel sent `SIGKILL` (128 plus 9).</details>
2. Predict: current 3 replicas at 90 percent average utilisation, target 60 percent. What does the formula give? <details><summary>Answer</summary><code>ceil(3 x 90 / 60) = ceil(4.5) = 5</code> replicas (subject to <code>maxReplicas</code> and the behaviour rules).</details>
3. Why does an HPA need CPU requests? <details><summary>Answer</summary>Utilisation is usage divided by the request; with no request it cannot be computed.</details>
4. Why is slack not automatically waste? <details><summary>Answer</summary>Headroom covers spikes, rollouts and failures; the question is whether the amount is deliberate.</details>
5. What stops an autoscaler from running up a huge bill during a runaway loop? <details><summary>Answer</summary><code>maxReplicas</code>, and a namespace ResourceQuota, plus alerts on both.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `memhog` keeps going far past 64 MiB | Swap is allowed (`memswap_limit` removed) | Keep `memswap_limit` equal to `mem_limit` |
| `no such container: code101-resources-memhog-1` | Project name or profile differs | `docker ps -a` and use the real name |
| `yes`/`no` read as booleans: `restart: no` becomes `false` | YAML boolean rule | Quote it: `restart: "no"` |
| HPA `TARGETS` `<unknown>/50%` | metrics-server missing or not yet ready | Install it (Step 7) and wait a minute |
| `failed to get cpu utilization: missing request for cpu` (typical wording) | No CPU request on the pods | Add `resources.requests.cpu` |
| Pods `Pending` after scaling up | Node or quota has no room | `describe pod`, `describe quota` |
| `Forbidden: ... exceeded quota` (typical wording) | The ResourceQuota limit was reached | Raise the quota deliberately, or reduce `maxReplicas` |
| `error: unknown flag: --patch-file` (typical wording) | An old kubectl | Update kubectl |

## Best practice
Set requests from measured usage, set memory limits, bound autoscalers with a maximum and a quota, and review slack regularly. Source: Kubernetes documentation, Resource Management for Pods and Containers https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ and Docker documentation, Resource constraints https://docs.docker.com/engine/containers/resource_constraints/

## Going further
- Horizontal Pod Autoscaling (concepts): https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/
- HPA walkthrough (the source of this lesson's example): https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
- Pod quality of service classes: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/
- Resource quotas and limit ranges: https://kubernetes.io/docs/concepts/policy/resource-quotas/ and https://kubernetes.io/docs/concepts/policy/limit-range/

## Summary
- You triggered an OOM kill and measured the cost of a CPU limit.
- You configured a quota, default limits and an autoscaler, and computed its replica count by hand.
- You built a cost model, read slack and fill, and listed what the model ignores.
- You recorded a sizing and scaling policy as an ADR with its failure modes.

## Next lesson
09. Production readiness: incident runbooks, a backup and restore drill, upgrade strategy and a review exercise.
