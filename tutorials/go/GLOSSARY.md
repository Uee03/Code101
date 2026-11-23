# Go glossary

Definitions follow the first introduction in the 101 lessons.

## 01. Hello, Go

- **Explorer (VS Code):** The file list on the left; hover over a folder name for New File and New Folder icons.
- **workspace trust:** VS Code's check that you trust the source of the folder you opened.
- **GOPATH:** Go's tools/work folder, mentioned in a missing-module-name error; no change is needed for this course.
- **gopls:** An optional Go editing helper used by the VS Code extension.
- **program:** Instructions a computer carries out.
- **terminal:** A window for typing commands and pressing Enter.
- **prompt:** Text before the command typing area, not part of a command you type.
- **current folder / working directory:** The folder in which a command runs.
- **path:** The location of a file or folder; quote it if it contains spaces.
- **home folder:** Your user folder, represented by $HOME in these shell instructions.
- **PATH:** The environment variable listing folders searched for commands.
- **operating system (OS):** The software platform running your computer, such as Windows, macOS or Linux.
- **processor architecture:** The kind of processor instructions supported; amd64 is Intel/AMD 64-bit, arm64 is ARM 64-bit.
- **compressed archive:** Files bundled and compressed for download and extraction.
- **editor:** An application for writing and saving text files.
- **source file:** A text file of program instructions; Go source uses .go filenames.
- **toolchain:** The Go tools that compile and run source code.
- **compiler:** A tool that checks and translates source into executable instructions.
- **package:** Go source files in one folder, compiled together under a package name.
- **module:** A collection of packages identified by the module path in go.mod.
- **module path:** The module identity and prefix used for imports of its packages.
- **go.mod:** The module file naming the module and its minimum Go version; leave the generated version alone.
- **dependency:** Another module needed by your code; these examples need no external dependencies.
- **import:** A declaration making another package available in a file.
- **standard library:** Packages distributed with Go, including fmt, os and bufio.
- **function:** A named block of instructions that can take inputs and return results.
- **call:** An instruction to run a function or method.
- **string:** A text value; double quotes enclose a string literal.
- **block:** Instructions enclosed by braces.
- **indentation:** Whitespace at the start of a line to show grouping to readers.

## 02. Variables and types

- **variable:** A named value that can change.
- **type:** The kind of value and its allowed operations.
- **int:** An integer type for whole numbers; its size depends on the platform.
- **float64:** A 64-bit floating-point type approximating numbers with fractional parts.
- **bool / boolean:** A type with just true and false values.
- **declaration:** Introducing a name and its type or initial value.
- **short declaration:** The := form declaring a variable and inferring its type inside a function.
- **type inference:** Working out a type from the initial value.
- **assignment:** Replacing an existing variable value with =.
- **constant:** A named value that cannot be reassigned.
- **zero value:** The default for a variable declared without an initial value.
- **format string:** Text containing placeholders such as %d that formatting functions replace.
- **newline:** A line ending, written as \n inside a Go string.

## 03. Input and math

- **address (optional Scan demo):** A value's location in working memory; & lets Scan fill the original variable.
- **return:** End a function, sending back its declared results if any.
- **standard input:** The text a program reads, normally from its terminal.
- **Scanner:** A bufio reader that visits tokens, normally one line at a time.
- **token:** One piece of input; Scanner uses lines by default while fmt.Scan uses whitespace-separated values.
- **parsing:** Interpreting text as a value, such as converting numeric text using Atoi.
- **conversion:** Explicitly changing a value to a compatible type, such as float64(people).
- **operator:** A symbol performing an operation, such as + or /.
- **integer division:** Whole-number division that truncates toward zero.
- **remainder:** The leftover from integer division, calculated with %.
- **guard:** An early check preventing unsafe work or handling a failure.
- **error value:** An ordinary value describing a failure; a nil error means no failure.
- **nil:** The no-value marker for errors, pointers, slices, maps and some other types; a nil error means success.
- **blank identifier:** The underscore _, used to deliberately discard a value.

## 04. Making decisions

- **comparison:** A yes/no relation between values, such as age < 5.
- **boolean expression:** An expression whose result is true or false.
- **condition:** A boolean expression controlling whether a block runs.
- **short-circuit evaluation:** Not evaluating the right side of && or || when the left already determines the result.
- **if/else chain:** Conditions checked in order, using the first matching branch or else.
- **branch:** One choice of block in a decision.
- **switch:** A decision matching a value to a case, with default as a fallback.

## 05. Loops

- **body:** The block of instructions inside a function or loop.
- **loop:** A block repeated according to a stopping rule.
- **accumulator:** A variable holding a running total.
- **scope:** The region in which a declared name is available.
- **iteration:** One pass through a loop.
- **break:** Exit the nearest loop or switch.
- **continue:** Skip the rest of a loop iteration and proceed to the next.
- **infinite loop:** A loop that repeats without a condition stopping it unless its body exits.

## 06. Functions

- **caller:** The code that runs a function.
- **parameter:** A named input in a function definition.
- **argument:** An actual value supplied to a call.
- **multiple return values:** Two or more results sent back by a function in order.
- **named results:** Result variables named in a function definition and initialized to zero values.

## 07. Slices and maps

- **iteration order:** The order in which a loop visits collection items; maps promise no particular order.
- **nil map (reference):** A map not yet given a writable value; this course uses map literals instead.
- **slice:** An ordered collection that can grow; append returns its updated value.
- **slice literal:** A written starting slice such as []string{"tea"}.
- **element:** One value in a collection.
- **index:** An element position, starting at zero for slices.
- **map:** A collection of key/value pairs for lookups.
- **key:** A value identifying a map entry.
- **value:** The data stored in a variable or associated with a map key.
- **range:** The for-loop form visiting collection positions/keys and values.

## 08. Files

- **sequence:** An ordered series of values.
- **byte slice:** An ordered series of bytes, the data form used for file writing.
- **permission code:** A number controlling access to a newly created file; type 0600 exactly in these examples.
- **relative path:** A file location interpreted from the working directory.
- **CSV:** Comma-separated values: a table stored as text rows with comma-separated fields.
- **row:** One line of the restricted CSV table.
- **field:** One struct member or one column value in a CSV row; context distinguishes them.
- **header:** The first table row naming columns.
- **byte:** A small unit of encoded data, represented by Go as an unsigned 8-bit integer.
- **octal:** Base-eight notation, used by 0600 to express file permission codes; octal uses digits 0 to 7.
- **truncation:** Removing old trailing content when replacing a file.

## 09. Errors

- **method:** A function attached to a type; mentioned in error diagnostics here and built in lesson 10.
- **guard clause:** Early failure handling that leaves the successful path simple.
- **validation:** Checking rules about a parsed value, not just whether its text is numeric.
- **error wrapping:** Adding context with %w while preserving the underlying error for inspection.

## 10. Structs and methods

- **struct:** A type grouping named fields.
- **instance:** A concrete value of a type.
- **struct literal:** A written struct value with field assignments.
- **receiver:** The value a method works on, declared between func and its name.
- **value receiver:** A receiver getting a copy of the value.
- **pointer:** A value holding an address; a nil pointer has no target.
- **pointer receiver:** A receiver referring to an original value, allowing changes to it.

## 11. Interfaces and packages

- **interface:** A contract listing required methods.
- **exported name:** A name beginning with an uppercase letter and accessible from another package.
- **unexported name:** A name accessible only inside its package.
- **implementation:** A type satisfying an interface automatically by having its required methods.

## 12. Project: expense tracker

- **ledger:** The list of saved expenses.
- **nil slice:** A slice with no list value; used alongside an error to signal a failed load here.
- **TrimSpace:** Remove spaces and similar whitespace from the beginning and end of text.
- **ContainsAny:** Check whether text includes any character from a supplied set.
- **Itoa:** Convert an int to its text form.
- **short if:** Create a temporary variable before the semicolon, then check a condition; the variable belongs only to that if.
- **persistence:** Keeping data between program runs, here by saving a file.
- **data contract:** Explicit rules for valid records and their file representation.
- **self-check:** A few checks an application runs on its own assumptions, here plain checks in an ordinary function.

# Level 201 terms

Definitions follow the first introduction in the 201 lessons.

## 201-01. Interfaces, embedding and small interfaces

- **small interface:** An interface with one or two methods, declared where it is used (the consumer), so it is easy to satisfy and to fake.
- **embedding:** Listing a type as an unnamed field of a struct; its methods are promoted to the outer type. It is composition, not inheritance.
- **promoted method:** A method of an embedded field that can be called directly on the outer value.
- **override (method):** Declaring a method with the same name on the outer type, which hides the promoted one; the embedded one stays reachable through the field name.
- **type assertion:** `v.(T)` asks whether the value inside an interface has type `T` (or the methods of interface `T`); the comma-ok form `x, ok := v.(T)` does not panic.
- **dynamic type / dynamic value:** The concrete type and value stored inside an interface value.
- **typed nil:** An interface holding a nil pointer of some type; it is not equal to `nil` because its type part is set.
- **compile-time interface check:** `var _ I = (*T)(nil)`, which makes the build fail if `T` stops satisfying `I`.
- **decorator (wrapper):** A type that holds another value of the same interface and adds behaviour around its calls.
- **fake:** A simple stand-in implementation used in tests instead of the real dependency.

## 201-02. Goroutines and channels

- **goroutine:** A function running concurrently, started with `go`; it ends when its function returns.
- **channel:** A typed pipe between goroutines created with `make(chan T)`.
- **unbuffered channel:** A channel where a send waits until a receiver takes the value.
- **buffered channel:** A channel with room for a fixed number of values; a send waits only when it is full.
- **close (channel):** Telling receivers that no more values will be sent; only the sender closes, and sending afterwards panics.
- **directional channel:** A channel type that only sends (`chan<- T`) or only receives (`<-chan T`).
- **WaitGroup:** A counter (`sync.WaitGroup`) used to wait until a group of goroutines has finished.
- **worker pool:** A fixed number of goroutines that take jobs from one channel.
- **pipeline:** Stages connected by channels, each reading from the previous and writing to the next.
- **select:** A statement that waits on several channel operations and runs the one that is ready; `default` makes it non-blocking.
- **deadlock:** A state where every goroutine is blocked, so the program cannot continue.
- **concurrency / parallelism:** Concurrency is structuring work as independent tasks; parallelism is running them at the same moment on several cores.

## 201-03. sync, context and cancellation

- **data race:** Two goroutines access the same variable at the same time and at least one writes, with no synchronisation.
- **mutex:** A lock (`sync.Mutex`) that lets one goroutine at a time into a critical section.
- **RWMutex:** A lock that allows many readers at once or one writer.
- **critical section:** The code between `Lock` and `Unlock`.
- **race detector:** The `-race` build flag that reports data races while the program runs.
- **context:** A value (`context.Context`) carrying a deadline or cancellation signal across function calls.
- **cancellation:** Telling running work to stop; it only works if the work watches `ctx.Done()`.
- **deadline / timeout:** A time limit on a context (`WithDeadline`, `WithTimeout`); expiry gives `context.DeadlineExceeded`.
- **goroutine leak:** A goroutine that can never finish, usually blocked on a channel nobody serves.
- **ticker / timer:** Time values that deliver on a channel repeatedly (`time.Ticker`) or once (`time.Timer`); stop them when done.

## 201-04. Generics

- **generics:** Functions and types written once with type parameters.
- **type parameter:** A placeholder type name in square brackets, as in `Map[T, U any]`.
- **constraint:** An interface that says which types a type parameter accepts.
- **type set:** The list of types in a constraint, such as `~int | ~float64`.
- **tilde (`~T`):** Matches `T` and every type whose underlying type is `T`.
- **comparable:** The constraint for types that support `==` and can be map keys.
- **cmp.Ordered:** The constraint for types that support `<` and `>`.
- **type inference:** The compiler working out the type arguments from the call's arguments.
- **instantiation:** Supplying type arguments to a generic function or type.

## 201-05. net/http server

- **handler:** A value with a `ServeHTTP(w, r)` method (`http.Handler`) that answers one request.
- **ServeMux:** The standard request router; since Go 1.22 it matches methods and path wildcards.
- **route pattern:** Text such as `GET /books/{id}` that selects a handler.
- **path value:** The text matched by a wildcard, read with `r.PathValue`.
- **middleware:** A function from handler to handler that adds behaviour before or after the next handler.
- **status code:** The three-digit number in a response that says what happened (200, 204, 400, 404, 405, 500).
- **ResponseWriter:** The interface a handler uses to write headers, status and body.
- **panic recovery:** Catching a panic with `recover` so one failing request does not break the server.
- **slowloris:** An attack that keeps connections busy by sending data very slowly; timeouts defend against it.
- **loopback address:** `127.0.0.1`, reachable only from the same computer.
- **httptest:** The standard package for testing handlers without a real network.

## 201-06. JSON DTOs, validation and problem+json

- **DTO (data transfer object):** A small struct that describes exactly what crosses the API boundary.
- **over-posting (mass assignment):** A client setting fields it should not by including them in the request body.
- **struct tag:** Text such as `json:"title"` after a field that names its JSON key.
- **strict decoding:** Rejecting unknown fields and trailing data when reading JSON.
- **validation (server side):** Checking business rules (required, length, range) on the server, never only in the client.
- **400 versus 422:** 400 means the request could not be understood; 422 means it was understood but breaks the rules.
- **415 Unsupported Media Type:** The status for a body with the wrong content type.
- **problem details (RFC 9457):** A standard JSON error object with `type`, `title`, `status`, `detail`, `instance`.
- **media type:** The `Content-Type` value, for example `application/problem+json`.
- **Location header:** The response header that gives the URL of a newly created resource.

## 201-07. Configuration, slog and graceful shutdown

- **twelve-factor config:** Keeping settings in the environment, outside the code.
- **environment variable:** A named setting provided to a process by its surroundings.
- **fail fast:** Refusing to start when configuration is invalid.
- **structured logging:** Writing log records as named fields instead of sentences.
- **slog:** The standard `log/slog` package; a `Logger` writes records through a `Handler` (text or JSON).
- **log level:** The importance of a record (debug, info, warn, error); records below the chosen level are skipped.
- **graceful shutdown:** Stopping new connections and letting running requests finish before exit.
- **SIGTERM / SIGINT:** The signals sent by `docker stop` and by Ctrl+C.
- **exit code:** The number a process returns; 0 means success.

## 201-08. Postgres with pgx

- **connection pool:** A shared set of open database connections that calls borrow and return.
- **pgx:** The most used Go driver for PostgreSQL.
- **parameterised query:** SQL with placeholders (`$1`) whose values are sent separately; it prevents SQL injection.
- **SQL injection:** An attack where input becomes part of the SQL text.
- **transaction:** A group of statements that all take effect or none do.
- **commit / rollback:** Making a transaction permanent / discarding it.
- **row lock (`FOR UPDATE`):** Locking selected rows until the transaction ends.
- **deadlock (database):** Two transactions each waiting for a lock the other holds; locking in a fixed order avoids it.
- **constraint:** A rule the database enforces on a table (`UNIQUE`, `CHECK`, `PRIMARY KEY`).
- **stored function:** A function defined and run inside the database.
- **SQLSTATE:** A five-character code that identifies a database error, such as `23505` for a unique violation.
- **sentinel error:** A package-level error value callers compare with `errors.Is`.
- **Compose project / volume / healthcheck:** The named group of containers in a Compose file; storage that outlives a container; a command that tells whether the service is ready.
- **init script:** SQL that the Postgres image runs once, when a new data volume is created.
- **go.sum:** The file of checksums that `go mod tidy` creates for downloaded modules.

## 201-09. Authentication middleware

- **authentication / authorisation:** Who you are / what you may do.
- **JWT (JSON Web Token):** A signed token with a header, a payload of claims and a signature, separated by dots.
- **claim:** A statement in a token, such as `sub`, `iss`, `aud`, `exp` or a role list.
- **bearer token:** A token sent as `Authorization: Bearer <token>`.
- **HS256 / RS256:** Signing with one shared secret (HMAC-SHA256) / with a private key checked by a public key.
- **algorithm confusion:** An attack that exploits a verifier trusting the algorithm named in the token header.
- **401 versus 403:** Not authenticated / authenticated but not allowed.
- **WWW-Authenticate:** The response header that tells a client which authentication scheme to use.
- **context key:** A private type used as the key for a value stored in a context.
- **role:** A named permission group carried by the caller.
- **object-level authorisation:** Checking that the caller may access this particular record.

## 201-10. Testing and shipping

- **table-driven test:** One test function looping over a slice of named cases.
- **subtest:** A named test run with `t.Run`; it can be selected with `-run`.
- **test helper:** A function that calls `t.Helper()` so failures point at its caller.
- **test cache:** Go's reuse of passing test results; `-count=1` bypasses it.
- **coverage:** The share of statements that tests ran (`-cover`).
- **fuzzing:** Running a test with generated inputs to look for failures of a stated property.
- **recorder (httptest):** A fake `ResponseWriter` that records what a handler wrote.
- **multi-stage build:** A Dockerfile that builds in one image and copies only the result into a small final image.
- **distroless image:** A minimal runtime image with no shell or package manager.
- **non-root user:** A user without administrator rights inside the container.
- **static binary:** An executable with no external library dependencies (`CGO_ENABLED=0`).
- **read-only file system / dropped capabilities:** Container settings that stop the process from writing files or using privileged Linux features.
- **exec form (ENTRYPOINT):** The JSON-array form that starts the program directly, so it receives signals.

## 301-01. Concurrency patterns

- **worker pool:** A fixed number of goroutines that take jobs from a channel; the fixed number bounds the concurrency.
- **pipeline:** A chain of stages connected by channels, each stage doing one step and passing its results on.
- **fan-out:** Several goroutines receiving from the same channel so work is shared.
- **fan-in:** Combining the output of several channels into one.
- **errgroup:** A helper in `golang.org/x/sync/errgroup` that runs functions in goroutines, returns the first error and cancels a shared context; `SetLimit` bounds how many run at once.
- **goroutine leak:** A goroutine that can never finish, usually blocked on a channel nobody will use again.
- **back-pressure:** A slow consumer slowing the producer instead of letting work or memory pile up.
- **ownership of close:** The rule that exactly one goroutine, the sender, closes a channel.

## 301-02. Memory model, data races and the race detector

- **data race:** Two goroutines accessing the same variable concurrently, at least one writing, with no synchronisation between them.
- **memory model:** The rules (go.dev/ref/mem) that say when one goroutine is guaranteed to observe another's writes.
- **happens before:** An ordering between two events created by synchronisation (channel operations, mutexes, `Once`, `WaitGroup`, atomics); only ordered events have guaranteed visibility.
- **race detector:** The `-race` build mode that instruments memory accesses and reports races it observes at run time; it needs cgo and a C compiler, and slows programs down.
- **atomic operation:** A read or update that cannot be split by another goroutine, from `sync/atomic`.
- **critical section:** The code between `Lock` and `Unlock`, which one goroutine at a time may run.
- **GORACE:** The environment variable that sets race-detector options such as `halt_on_error` and `log_path`.

## 301-03. Profiling with pprof and benchmarks

- **benchmark:** A function named `BenchmarkXxx` that measures how long an operation takes; `for b.Loop()` repeats it.
- **ns/op, B/op, allocs/op:** Benchmark columns: nanoseconds, bytes allocated and allocations per iteration.
- **benchstat:** A tool that compares benchmark runs and says whether a difference is larger than the noise.
- **profile:** A sampled record of where a program spends CPU time or allocates memory.
- **flat and cum:** In a profile, time in a function itself versus time including the functions it calls.
- **flame graph:** A picture of a profile where box width is cost and stacking shows who called whom.
- **execution trace:** A detailed timeline of goroutine scheduling and garbage collection from `go tool trace`.
- **GOGC and GOMEMLIMIT:** Settings that control how much the heap may grow before collection and a soft total memory limit.

## 301-04. Clean architecture in Go

- **dependency rule:** Imports point inward toward the domain; the domain imports nothing of the application.
- **domain:** The business entities and rules, free of HTTP, databases and logging.
- **use case (application service):** A function that carries out one business operation by combining domain rules and outside services.
- **adapter:** Code that connects the application to something external, such as HTTP or a database.
- **interface at the consumer:** Declaring an interface in the package that uses it, listing only the methods it calls.
- **composition root:** The one place (usually `main`) that builds the concrete types and wires them together.
- **fake (test double):** A small hand-written implementation of an interface used in tests.
- **internal package:** A folder named `internal`; the compiler allows only code in its parent tree to import it.

## 301-05. gRPC services

- **gRPC:** A remote-procedure-call system that carries protobuf messages over HTTP/2.
- **protobuf (Protocol Buffers):** A language for describing messages and services, with a compact binary encoding.
- **field number:** The number that identifies a message field on the wire; it must never change once released.
- **unary RPC:** One request and one response.
- **streaming RPC:** A call where the server, the client or both send a sequence of messages.
- **status code:** The gRPC result of a call, such as `NotFound` or `DeadlineExceeded`.
- **deadline:** The point in time by which a call must finish; gRPC sends it to the server.
- **interceptor:** gRPC's middleware that wraps calls, for logging, metrics or authentication.
- **buf:** A tool that lints protobuf files, checks for breaking changes and runs code generators.
- **bufconn:** An in-memory connection used to test a gRPC server without a network port.

## 301-06. Resilience

- **timeout:** A limit on how long an operation may take before it is abandoned.
- **exponential backoff:** Doubling the wait between retries, up to a maximum.
- **jitter:** Randomness added to a wait so many clients do not retry at the same moment.
- **thundering herd:** Many clients acting at the same instant, overloading a service.
- **circuit breaker:** A guard that stops calls to a failing dependency (open), then tests it with a probe (half-open).
- **token bucket:** A rate limiter that refills tokens at a fixed rate; each request takes one.
- **idempotent:** An operation that has the same effect when done once or many times.
- **idempotency key:** A client-chosen identifier that lets the server run a request once and replay the answer to repeats.
- **retry amplification:** Retries at several layers multiplying the load on a failing service.

## 301-07. Observability

- **observability:** Being able to ask new questions about a running system from its logs, metrics and traces.
- **structured log:** A log record made of a message plus key-value attributes, such as one JSON object per line.
- **metric:** A number measured over time, such as requests per second.
- **counter, gauge, histogram:** Metric types: only goes up, goes up and down, and counts observations into buckets.
- **cardinality:** The number of distinct label combinations of a metric; unbounded labels cause unbounded cost.
- **trace and span:** A trace is one request's path across services; a span is one timed step within it.
- **propagation:** Passing trace context (the `traceparent` header) from one service to the next.
- **sampling:** Recording only a share of traces to limit cost.
- **RED and USE methods:** Rate, Errors, Duration for services; Utilisation, Saturation, Errors for resources.
- **SLO:** A service level objective: a target such as "99% of requests under 300 ms over 30 days".

## 301-08. Security and supply chain

- **threat model:** A short statement of who might attack, what they want and where they can get in.
- **supply chain:** The code and tools you depend on but did not write, and how they reach you.
- **govulncheck:** The Go tool that reports known vulnerabilities in code you actually call.
- **checksum database:** The public log (`sum.golang.org`) that lets everyone verify the same bytes for a module version.
- **allow-list:** A list of permitted values; everything else is rejected.
- **JWT (JSON Web Token):** A signed token with a header, claims and a signature.
- **audience (`aud`):** The claim naming the service a token is meant for.
- **key id (`kid`):** A header naming which key signed a token, used for key rotation.
- **algorithm confusion:** An attack where the token chooses a weak or different signature algorithm.
- **TLS and mTLS:** Encrypted, server-authenticated connections; mutual TLS also authenticates the client by certificate.
- **certificate authority (CA):** An issuer whose signature on a certificate peers choose to trust.

## 301-09. Release engineering and the production checklist

- **ldflags `-X`:** A linker flag that sets a string variable at build time, used to stamp the version.
- **`-trimpath`:** A build flag that removes local file paths from the binary.
- **reproducible build:** A build that gives the same bytes from the same source, flags and toolchain.
- **SBOM (software bill of materials):** A machine-readable list of everything inside an artefact.
- **provenance:** A statement of how an artefact was built, from which source and by which builder.
- **multi-architecture image:** One image name that serves a different build for each CPU type.
- **image digest:** The hash that identifies exactly one image; unlike a tag it cannot be moved.
- **semantic versioning (SemVer):** Version numbers `MAJOR.MINOR.PATCH` that signal how compatible a change is.
- **liveness and readiness probe:** Health checks that decide whether to restart an instance and whether to send it traffic.
- **graceful shutdown:** Stopping by first refusing new work and then letting in-flight work finish.
- **canary release:** Sending a small share of traffic to the new version before the rest.
- **expand and contract:** A two-step database change that keeps old and new code working during a rollout.
