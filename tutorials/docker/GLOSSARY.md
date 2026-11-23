# Docker glossary

| Term | Plain meaning | First lesson |
|---|---|---|
| Container | An isolated running program with its own filesystem and processes, sharing a kernel | 01 |
| Image | A packaged filesystem and instructions used to create containers | 01 |
| Engine / daemon | The background service that builds and runs containers | 01 |
| Terminal | A window where you type commands | 01 |
| CLI | Command-line interface: the docker command talking to the engine | 01 |
| WSL2 | Windows Subsystem for Linux version 2, a Linux environment in a lightweight virtual machine | 01 |
| Kernel | The operating system core that manages hardware and processes | 01 |
| Virtual machine | Software that supplies a separate operating system | 01 |
| Registry | An online store of images, such as Docker Hub | 02 |
| Tag | The label after an image colon, such as 17-alpine | 02 |
| Host | The computer running Docker | 02 |
| Port | A numbered network doorway for a service | 02 |
| Loopback | 127.0.0.1: an address reachable only on this computer | 02 |
| Logs | Text a program writes to its output streams | 02 |
| Dockerfile | A recipe for building an image | 03 |
| Build context | Files made available to an image build | 03 |
| Layer | A filesystem change saved in an image | 03 |
| Volume | Storage managed by Docker, separate from a container | 04 |
| Bind mount | A host file or folder made visible inside a container | 04 |
| Environment variable | A named value passed to a process | 05 |
| Secret | A value such as a real password that must not be shared | 05 |
| Git | A tool that records changes to project files | 05 |
| Compose | A tool that starts related containers from a YAML file | 05 |
| YAML | A text format where indentation groups settings | 05 |
| Service | A named container configuration in Compose | 05 |
| Network | A communication space connecting containers | 06 |
| DNS | The system translating a name such as db to a network address | 06 |
| Database | A program that stores and retrieves structured information | 06 |
| SQL | Structured Query Language, used to work with database tables | 06 |
| Healthcheck | A repeated command checking whether a service is ready | 07 |
| Prune | Delete unused Docker resources; scope matters | 07 |
| API | Application programming interface, here web addresses returning JSON | 08 |
| JSON | A text format for exchanging named values, lists and objects | 06 |
| IDE | Integrated development environment: an editor with programming/database tools | 08 |
| HTTP | Hypertext Transfer Protocol: browser requests and server responses | 03 |
| Request / response | A client's question and a server's answer | 03 |
| Header | Response metadata such as Content-Type, sent before the body | 03 |
| Body | The content of a web response | 03 |
| Byte | A unit of binary data; the app sends text as bytes | 03 |
| Detached | Running in the background while the terminal is free | 02 |
| Project | The Compose name grouping a stack's containers, networks and volumes | 05 |
| Dependency | A service that another service needs before starting | 06 |
| Readiness | Whether a service can do the work requested, not merely whether its process is running | 07 |
| Driver | A library that lets a program communicate with a database | 06 |
| Commit | Make a successful database transaction's changes permanent | 08 |
| Build cache | Reusable results of unchanged image-build instructions | 03 |
| Label | Named Docker metadata for identifying resources; not a secret | 03 |
| PATH | The list of folders searched for terminal commands | 01 |
| SSL / TLS | Secure Sockets Layer / Transport Layer Security: protocols for encrypted connections; modern systems use TLS | 08 |
| URL | Uniform Resource Locator: an address identifying a web or database connection destination | 08 |
| IP address | Internet Protocol address: a numerical network destination | 06 |

## Docker 301 terms (lesson numbers refer to level 301)

| Term | Plain meaning | First lesson |
|---|---|---|
| Threat model | A written list of what could go wrong, who would cause it, and the decision that addresses each risk | 301/01 |
| Trust boundary | A line that data or code crosses where the receiving side must decide whether to believe it | 301/01 |
| STRIDE | A memory aid for threat types: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege | 301/01 |
| Attack surface | Everything an attacker can reach or influence in a system | 301/01 |
| Docker socket | The local file through which clients control the Docker engine; whoever can use it has root on the host | 301/01 |
| Privileged container | A container started with almost all isolation removed | 301/01 |
| Lint | A tool that checks text against rules without running it | 301/01 |
| Regular expression | A text pattern used to search lines | 301/01 |
| ADR | Architecture decision record: context, decision, consequences, alternatives and when to revisit | 301/01 |
| Supply chain | Everything that contributes to an image: base image, packages, build system, registry | 301/02 |
| Digest | The hash of an image manifest; it names exactly one image | 301/02 |
| Manifest | A small JSON file listing an image's layers and settings | 301/02 |
| Index | A manifest that lists one image per platform (for example Intel and Arm) | 301/02 |
| Pinning | Referring to one exact version, for images by digest | 301/02 |
| SBOM | Software bill of materials: a machine-readable list of the packages inside an image | 301/02 |
| SPDX | A standard file format for SBOMs | 301/02 |
| Attestation | Metadata attached to an image that describes what is in it or how it was built | 301/02 |
| Provenance | Evidence of where and how an artifact was built | 301/02 |
| Signature | Proof that the holder of a key or identity vouched for exact bytes | 301/02 |
| cosign | A tool from the Sigstore project that signs and verifies container images | 301/02 |
| OCI annotation | A standard label such as org.opencontainers.image.revision stored in an image | 301/02 |
| Allow list | A list of the only things permitted | 301/02 |
| seccomp | A Linux feature that filters which system calls a process may make | 301/03 |
| AppArmor | A Linux security module that confines a program to listed files, network and capabilities | 301/03 |
| Capability | One of the separate root-like powers Linux can grant a process, such as binding a low port | 301/03 |
| Bounding set | The most capabilities a process can ever hold | 301/03 |
| no-new-privileges | A flag that stops a process gaining privileges through set-uid programs | 301/03 |
| Read-only root filesystem | A container whose main filesystem cannot be written | 301/03 |
| tmpfs | A writable in-memory directory that disappears when the container stops | 301/03 |
| User namespace | A Linux feature that maps ids inside a container to different ids on the host | 301/03 |
| userns-remap | A Docker setting that maps container root to an unprivileged host user | 301/03 |
| Rootless mode | Running the Docker daemon and containers without root privileges | 301/03 |
| Init process | A tiny process 1 that forwards signals and reaps child processes | 301/03 |
| Repository | A named collection of image versions in a registry | 301/04 |
| Blob | A stored layer or configuration file in a registry, named by its digest | 301/04 |
| Promotion | Moving an image to the next environment by copying a reference, not rebuilding | 301/04 |
| Immutable tag | A tag that is never pushed twice | 301/04 |
| Garbage collection | Deleting registry data that no manifest references | 301/04 |
| Retention | The rules for how long images are kept | 301/04 |
| Mirror | A nearby copy or cache of a registry | 301/04 |
| Kubernetes | A system that keeps a declared number of containers running across many machines | 301/05 |
| Cluster | The set of machines managed together by Kubernetes | 301/05 |
| Node | One machine in a cluster | 301/05 |
| Pod | The smallest Kubernetes unit: one or more containers sharing a network address and volumes | 301/05 |
| Deployment | An object that keeps N identical pods running and rolls out changes | 301/05 |
| ReplicaSet | The controller object that keeps the right number of pods for one pod template | 301/05 |
| Kubernetes Service | A stable name and address for a changing set of ready pods | 301/05 |
| ConfigMap | A Kubernetes object holding non-secret configuration | 301/05 |
| Kubernetes Secret | A Kubernetes object holding sensitive values, base64-encoded but not encrypted by default | 301/05 |
| Namespace | A scope for names, quotas and access rules inside a cluster | 301/05 |
| Label | A key and value on an object used to select it | 301/05 |
| Selector | A rule that picks objects by their labels | 301/05 |
| Startup probe | A check that gives a slow container time to start before other probes begin | 301/05 |
| Readiness probe | A check that decides whether a pod receives traffic | 301/05 |
| Liveness probe | A check that decides whether a container is restarted | 301/05 |
| Controller | A loop that compares desired and actual state and acts to close the gap | 301/05 |
| kubectl | The command-line client for Kubernetes | 301/05 |
| kind | A tool that runs a local Kubernetes cluster inside Docker containers | 301/05 |
| Pod Security Admission | A built-in check that refuses pods that break a chosen security level | 301/05 |
| NetworkPolicy | A Kubernetes rule that limits which pods may talk to which | 301/05 |
| Rolling update | Replacing pods gradually so the service stays available | 301/05 |
| Kustomize | A tool that builds variants of plain manifests from a base and overlays | 301/06 |
| Overlay | A folder that changes a base for one environment | 301/06 |
| Helm | A tool that renders templates with values and tracks numbered releases | 301/06 |
| Chart | A Helm package: templates, default values and metadata | 301/06 |
| Release | One installed instance of a Helm chart, with its own history | 301/06 |
| Values | The settings that fill a Helm chart's templates | 301/06 |
| maxSurge | How many extra pods a rolling update may create | 301/06 |
| maxUnavailable | How many pods may be missing during a rolling update | 301/06 |
| Blue/green | Running a full new copy and switching all traffic to it at once | 301/06 |
| Canary | Sending a small share of traffic to a new version first | 301/06 |
| Shadow traffic | Copying real requests to a new version and discarding its answers | 301/06 |
| Expand then contract | A change order that keeps old and new versions working together | 301/06 |
| Feature flag | A switch that turns a feature on without deploying new code | 301/06 |
| Observability | The ability to ask new questions about a running system from its data | 301/07 |
| Structured log | A log line written as machine-readable fields such as JSON | 301/07 |
| Metric | A number measured over time, such as requests per second | 301/07 |
| Trace | The recorded path and timing of one request through a system | 301/07 |
| Span | One timed step inside a trace | 301/07 |
| Counter | A metric that only goes up | 301/07 |
| Histogram | A metric that counts observations in value ranges so percentiles can be computed | 301/07 |
| Percentile | The value below which a given share of observations fall | 301/07 |
| Cardinality | The number of distinct label combinations, and so of time series | 301/07 |
| Prometheus | A system that scrapes and stores metrics | 301/07 |
| Scrape | One fetch of metrics from a target | 301/07 |
| PromQL | The query language of Prometheus | 301/07 |
| Grafana | A tool that draws dashboards from data sources | 301/07 |
| OpenTelemetry | A vendor-neutral standard and toolkit for traces, metrics and logs | 301/07 |
| OTLP | The OpenTelemetry protocol for sending telemetry | 301/07 |
| Collector | A service that receives, processes and forwards telemetry | 301/07 |
| RED | Rate, Errors, Duration: the first metrics for a service | 301/07 |
| USE | Utilisation, Saturation, Errors: the first metrics for a resource | 301/07 |
| Alert rule | A query that, when true for long enough, raises an alert | 301/07 |
| Alertmanager | The Prometheus component that routes, groups and silences alerts | 301/07 |
| Provisioning | Loading configuration from files at start-up instead of through a UI | 301/07 |
| Request | The amount of a resource the scheduler reserves for a container | 301/08 |
| Limit | The most of a resource a container may use | 301/08 |
| QoS class | Guaranteed, Burstable or BestEffort: how Kubernetes ranks pods for eviction | 301/08 |
| OOM kill | The kernel ending a process that exceeded its memory limit | 301/08 |
| CPU throttling | Slowing a container that reached its CPU limit | 301/08 |
| HorizontalPodAutoscaler | An object that changes the replica count to follow a metric | 301/08 |
| Metrics server | A cluster add-on that supplies current CPU and memory use | 301/08 |
| ResourceQuota | A cap on what a namespace may request or create | 301/08 |
| LimitRange | Default and maximum resource values for containers in a namespace | 301/08 |
| Slack | Reserved capacity that measured use does not explain | 301/08 |
| Right-sizing | Setting requests from measured use | 301/08 |
| Flapping | Replica counts or states oscillating as a signal wobbles | 301/08 |
| RPO | Recovery point objective: how much data, as time, you can afford to lose | 301/09 |
| RTO | Recovery time objective: how long you can be down | 301/09 |
| Backup | A separate, restorable copy of data at a point in time | 301/09 |
| Restore drill | A rehearsal that proves a backup restores and measures how long it takes | 301/09 |
| Logical backup | A backup of data as SQL-level objects, such as pg_dump output | 301/09 |
| Point-in-time recovery | Restoring a database to a chosen moment using archived logs | 301/09 |
| Runbook | A step-by-step guide for handling a specific alert or failure | 301/09 |
| Incident | An event that harms or threatens a service and needs a response | 301/09 |
| Blameless review | A review of an incident that asks what allowed it, not who caused it | 301/09 |
| PodDisruptionBudget | A limit on how many pods of a service may be evicted voluntarily at once | 301/09 |
| Drain | Evicting the pods from a node so it can be maintained | 301/09 |
| Readiness review | A scored checklist, with evidence, that gates a launch | 301/09 |
| Multi-stage build | A Dockerfile with several FROM stages; only the last (or chosen) stage becomes the image | 201-01 |
| Stage | One FROM block of a Dockerfile, with its own filesystem; later stages can COPY --from it | 201-01 |
| scratch | A reserved empty base image with no shell and no files, used for static programs | 201-01 |
| Artifact | A file produced by a build, such as a compiled program or a dist folder | 201-01 |
| Cache mount | A builder-side scratch folder for one RUN (RUN --mount=type=cache); not stored in the image | 201-02 |
| BuildKit | Docker's modern build engine, with parallel stages, cache mounts and build secrets | 201-02 |
| .dockerignore | A file listing paths that are left out of the build context | 201-02 |
| Capability (Linux) | One small piece of root's power, such as CHOWN; containers get a default subset | 201-03 |
| Read-only root filesystem | A container whose image filesystem cannot be written; writable paths are volumes or tmpfs | 201-03 |
| tmpfs | A folder kept in memory that disappears when the container stops | 201-03 |
| Least privilege | Giving a process only the access it needs | 201-03 |
| CVE | Common Vulnerabilities and Exposures: the public id of a known security flaw | 201-04 |
| Supply chain | Everything that goes into an image before your own code: base image, packages, libraries, build tools | 201-04 |
| Digest | A sha256 value that names exactly one image build; unlike a tag it never moves | 201-04 |
| SBOM | Software bill of materials: the list of packages inside an image | 201-04 |
| Provenance | A record of how and from what source an image was built | 201-04 |
| Profile (Compose) | A label on a service so that it starts only when that profile is enabled | 201-05 |
| Override file | A Compose file merged over the base file to change settings per environment | 201-05 |
| Extension field | A top-level Compose key starting with x- that Compose ignores; holds reusable pieces | 201-05 |
| Anchor and alias (YAML) | A name for a block (&name) and a reference to it (*name), used to avoid repetition inside one file | 201-05 |
| Config (Compose) | A non-secret configuration file mounted into a service | 201-06 |
| Build secret | A value mounted for one build step only and never stored in an image layer | 201-06 |
| Secret manager | A service that stores, encrypts, audits and rotates secrets | 201-06 |
| Published port | A container port made reachable from the host with ports: or -p | 201-07 |
| Exposed port | A port documented with EXPOSE or expose:; it is reachable only from containers on a shared network | 201-07 |
| Internal network | A Docker network with no route to the outside world | 201-07 |
| cgroup | A Linux kernel feature that limits the memory, CPU and processes of a group of processes | 201-07 |
| OOM kill | The kernel ending a process that used more memory than its limit (exit code 137) | 201-07 |
| .wslconfig | A Windows file that sets global limits (memory, processors, swap) for the WSL 2 virtual machine | 201-07 |
| Dev container | A container, described by devcontainer.json, that holds a project's development tools | 201-08 |
| Compose watch | Compose syncing, restarting or rebuilding a service when watched files change | 201-08 |
| CI | Continuous integration: a machine builds and tests every change in a clean environment | 201-09 |
| Runner | The temporary machine that executes a CI job | 201-09 |
| Workflow (GitHub Actions) | A YAML file that defines jobs and steps run on repository events | 201-09 |
| GITHUB_TOKEN | A temporary token GitHub creates for each workflow run | 201-09 |
| Logical backup | A dump that describes the data (pg_dump) and can be loaded into another version | 201-10 |
| Major version | A release whose data format changes, such as Postgres 16 to 17; minor updates keep the format | 201-10 |
| Dangling | An image or volume that nothing references any more | 201-10 |
