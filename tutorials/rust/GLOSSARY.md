# Rust glossary

Introduced in lesson order. Examples use edition 2024.

## 01. Hello, Rust

- **terminal**: A window where you type commands and see text replies.
- **shell**: The program interpreting commands in a terminal; this course uses PowerShell on Windows.
- **prompt**: The text before the place where you type a terminal command.
- **current folder**: The folder a command uses as its starting location.
- **PATH**: The list of folders a shell searches for tools such as cargo.
- **rustup**: The installer and manager for Rust toolchains.
- **toolchain**: A matching collection of compiler and support tools.
- **MSVC**: Microsoft Visual C++, whose build tools provide Rust with Windows linking tools and libraries.
- **linker**: A tool that combines compiled pieces and system libraries into an executable.
- **SDK**: A software development kit, a bundle of platform libraries and tools.
- **source code**: Program instructions saved as text.
- **compiler**: A tool that translates source code into an executable and reports mistakes.
- **executable**: A program the operating system can run.
- **Cargo**: Rust's project, build and dependency manager.
- **manifest**: Cargo.toml, the file describing a Cargo package.
- **TOML**: The configuration-file format used by Cargo.toml.
- **package**: A Cargo project described by one manifest.
- **dependency**: Another package a program uses.
- **edition**: A named set of Rust language rules, selected in Cargo.toml.
- **lockfile**: Cargo.lock, Cargo's record of the exact resolved package versions.
- **function**: A named group of instructions.
- **block**: Instructions or an expression enclosed in braces.
- **indentation**: Spaces at the start of a line showing nesting.
- **macro**: A tool that expands into Rust code; its calls use !.
- **string literal**: Text written directly between double quotes.
- **comment**: A note for people, ignored by Rust; // starts a line comment.
- **build artifact**: A generated build file, such as a file in target.

- **standard library**: Tools distributed with Rust, under std.
- **standard output**: The program's normal text output stream.
- **standard error**: The output stream for diagnostic messages rather than ordinary results.

## 02. Variables and types

- **variable**: A name bound to a value.
- **binding**: The association between a name and a value.
- **type**: The kind of value Rust expects.
- **integer**: A whole number; i32 is a signed 32-bit integer.
- **floating-point number**: An approximate decimal number; f64 uses 64 bits.
- **boolean**: A true or false value, written bool in a Rust type.
- **char**: One Unicode scalar value in single quotes.
- **Unicode**: A standard numbering system for text characters.
- **immutable**: Not assignable again through that binding.
- **mutable**: Assignable again, declared with mut.
- **shadowing**: Creating a new binding with the same name using another let.
- **type inference**: Rust working out a type from values and uses.
- **String**: An owned, growable text container.
- **string slice**: A borrowed view of text, written &str.
- **formatting**: Choosing how a value is displayed, for example two decimal places.

- **warning**: Compiler advice that does not prevent the program from running.
- **owned text**: Text stored in a String that is responsible for keeping its own storage alive.

## 03. Input and math

- **module**: A named group of related Rust items.
- **input/output**: Receiving information and sending information, often shortened to I/O.
- **standard input**: The input stream read by stdin, usually the keyboard.
- **method**: A function called on a value using a dot.
- **method chain**: Several method calls linked so each uses the previous result.
- **parse**: Convert text into a typed value.
- **whitespace**: Spacing characters, including spaces, tabs and line endings.
- **panic**: A program-stopping failure such as a failed expect.
- **operator**: A symbol that acts on values, such as + or /.
- **remainder**: What is left after whole-number division.

## 04. Making decisions

- **comparison**: A question comparing values and producing bool.
- **condition**: A boolean expression deciding whether a block runs.
- **branch**: One alternative path through a decision.
- **boolean expression**: An expression whose value is true or false.
- **short-circuiting**: Skipping the right side of && or || when the left already determines the answer.
- **pattern**: A value or shape that match tries to recognize.
- **arm**: One pattern and action in a match.
- **wildcard**: The _ pattern, accepting any value.
- **exhaustive**: Covering every possible value in a match.

## 05. Loops

- **loop**: A block repeated until a stopping rule applies.
- **iteration**: One pass through a loop.
- **range**: A sequence of values, with an excluded (..) or included (..=) endpoint.
- **accumulator**: A changing value holding a running result.

- **sequence**: Values visited in a particular order.

## 06. Functions

- **parameter**: A named, typed input in a function definition.
- **argument**: A value supplied to a function call.
- **expression**: Code that produces a value.
- **statement**: An instruction that does not supply a result value to its surrounding block.
- **return type**: The type a function promises to give back.
- **unit**: The () value and type, representing no useful result.
- **scope**: The region where a name can be used.

- **caller**: The code making a function call.
- **body**: The code inside a function's braces.

## 07. Vectors and HashMaps

- **collection**: A container holding multiple values.
- **vector**: A growable ordered collection, Vec<T>, with one element type.
- **element**: One value stored in a collection.
- **index**: A zero-based position in a vector or similar sequence.
- **HashMap**: A collection associating unique keys with values.
- **key-value pair**: One lookup name and the value associated with it.
- **generic type**: A type with a type parameter, such as the T in Vec<T>.

## 08. Files

- **CSV**: Comma-separated values: rows of text with fields separated by commas.
- **file system**: The operating-system facilities for storing files and folders.
- **relative path**: A file location interpreted from the current folder.
- **UTF-8**: A text encoding describing how characters are represented as bytes.
- **header**: A first data row naming the columns.
- **field**: One value in a row or one named member of a struct.
- **iterator**: A value that yields other values one at a time.
- **newline**: A line-ending character, written \n inside a Rust string.

## 09. Handling errors

- **Option**: An enum representing a present Some(value) or absent None value.
- **Result**: An enum representing Ok(value) success or Err(error) failure.
- **error propagation**: Returning a failure to the caller instead of handling it locally.
- **propagation operator**: The ? suffix, extracting success or returning a compatible error.
- **EOF**: End of input: no more input data is available.
- **validation**: Checking whether a successfully read value is allowed.
- **re-ask loop**: A loop that asks again after input is rejected.

## 10. Ownership and borrowing basics

- **trait**: A named capability or set of capabilities a type can support (such as Copy).

- **ownership**: The rule giving each owned value one responsible owner.
- **move**: Transferring ownership so the previous binding cannot use the value.
- **Copy**: The trait allowing assignment to duplicate a value implicitly.
- **clone**: An explicit duplicate of a value, separate from a borrow.
- **reference**: A borrowed way to access a value without owning it.
- **borrow**: Temporary access to a value without taking ownership.
- **shared borrow**: Read-only access through &, allowing multiple readers.
- **exclusive borrow**: Access through &mut, allowing changes with no overlapping loans in use.
- **drop**: Releasing resources when an owning value leaves scope.

## 11. Structs, enums and impl blocks

- **struct**: A named record grouping related fields.
- **enum**: A type representing one of a fixed set of variants.
- **variant**: One alternative of an enum.
- **impl block**: A block attaching functions and methods to a type.
- **associated function**: A function attached to a type, called through that type rather than a receiver.
- **constructor**: A function, often named new, that creates a value.
- **Self**: The type currently being implemented inside an impl block.
- **self**: The existing value a method operates on.
- **receiver**: The self input to a method.
- **field shorthand**: Writing a field name alone when its local variable has the same name.

- **lifetime**: The period during which a borrowed reference may safely be used; lesson 11 avoids storing borrowed text by using String.

## 12. Project: expense tracker

- **slice**: A borrowed view of a contiguous sequence, such as &[Expense].
- **type alias**: A shorter name for an existing type, such as io::Result<T>.
- **i64**: A signed 64-bit integer type.
- **assert!**: A macro that panics when its condition is false.
- **self-check**: A small known example checked during an ordinary program run.
- **serialization**: Turning an in-memory value into text or bytes for storage.
- **persistence**: Keeping information in a file after a program exits.
- **continue**: A loop instruction that skips to the next iteration.

- **ErrorKind**: A category of input/output failure, such as NotFound, InvalidData or UnexpectedEof.


# Rust 201 - Hero to Super Hero

New uses of Rust 101 concepts build on the definitions above; lesson numbers below restart at 01 for level 201.

## 201.01 Lifetimes demystified
- **lifetime parameter**: A name such as 'a describing relationships between borrowed inputs and outputs, without extending any owner's life.
- **lifetime elision**: Rust's rules for inferring lifetime relationships in signatures when explicit names are unnecessary.
- **borrowed view**: A reference into storage owned elsewhere, such as a returned &str.
- **'static bound**: A bound meaning a type contains no shorter-lived borrowed data, not a requirement that every value live forever.

## 201.02 Traits and generics
- **trait bound**: A requirement on a generic type parameter, such as T: Summary, stating the capabilities its code may use.
- **static dispatch**: Selecting a concrete method implementation at compile time.
- **monomorphization**: Producing concrete versions of generic code for the types used.
- **trait object**: A runtime-dispatched interface to an implementing value, written with dyn, such as &dyn Summary.
- **heterogeneous collection**: A collection representing different concrete kinds through a shared element type, such as an enum or trait object.

## 201.03 Iterators and closures
- **closure**: An anonymous function that may capture surrounding values.
- **capture**: Bringing a surrounding value into a closure by borrowing, mutable borrowing or moving it.
- **iterator adapter**: An operation such as filter or map that creates a new iterator from another.
- **iterator consumer**: An operation such as sum that requests items to produce a final result.
- **lazy iterator**: An iterator pipeline that performs work when items are requested rather than merely when adapters are constructed.
- **Fn / FnMut / FnOnce**: Closure-call traits describing shared, mutable or consuming access needed to call a closure.
- **Item**: The associated type describing the values yielded by a particular iterator.

## 201.04 Errors in libraries and apps
- **domain error**: A typed failure of an application's rule, distinct from a lower-level parsing or I/O error.
- **source error**: An underlying error preserved as the cause of a higher-level failure.
- **error context**: A higher-level description of the operation that failed, added without losing its source error.
- **error chain**: The sequence of outer context and underlying causes of a failure.
- **thiserror**: A crate deriving standard Error and display implementations for user-defined error types.
- **anyhow**: A crate providing an application-oriented error wrapper, context and source-chain handling.
- **From conversion**: A conversion between error/value types that can support the ? operator's early-return path.

## 201.05 Async Rust and Tokio
- **future**: A value representing work that can make progress when polled and eventually produce a result.
- **runtime**: Infrastructure that schedules async work and drives supported timers and I/O.
- **task**: A runtime-scheduled unit of asynchronous work.
- **await**: A language operation that waits for a future, allowing the task to yield while it is pending.
- **concurrency**: Overlapping progress of multiple operations, including overlapping waits on one thread.
- **parallelism**: Executing operations simultaneously on multiple execution resources.
- **spawn**: Schedule an independent task rather than only composing futures in the current task.
- **JoinHandle**: A handle used to await a spawned task's completion or observe its failure.
- **deadline / timeout**: A time budget after which waiting returns an elapsed failure; it is not proof of remote rollback.
- **cancellation**: Stopping local future work, commonly by dropping a future; external effects may already have occurred.
- **Send**: A marker trait for values whose ownership can safely transfer between threads.
- **idempotency**: Designing repeated attempts so retrying the same operation does not multiply its intended effect.

## 201.06 A web API with Axum
- **router**: A service choosing handlers by an HTTP request's path and method.
- **handler**: The async function that receives extracted request values and produces a response.
- **extractor**: A type that reads and converts part of a request, such as Path, State or Json.
- **DTO**: Data transfer object: a type defining an input or output wire shape independently of storage layout.
- **Serde**: A framework supplying serialization/deserialization traits, with derive support for data types.
- **deserialization**: Converting a wire format such as JSON into typed Rust data.
- **extractor rejection**: A response generated when typed request extraction fails before the handler receives a valid argument.
- **IntoResponse**: Axum's conversion trait for types that can become HTTP responses, including application errors.
- **body limit**: A maximum number of request-body bytes accepted by the configured extraction path.
- **loopback**: A local-only network interface, such as 127.0.0.1, that does not publish a service on external interfaces.
- **oneshot**: A Tower utility calling a service once with a request, useful for in-memory HTTP checks without a listener.

## 201.07 Postgres with SQLx
- **runtime query**: SQL text executed and checked against a database at runtime rather than through compile-time query macros.
- **parameter placeholder**: SQL syntax such as $1 identifying a separately bound value rather than interpolated query text.
- **parameter binding**: Supplying data separately from SQL syntax so the value cannot alter the statement structure.
- **connection pool**: A bounded set of reusable database connections shared by operations.
- **transaction**: A group of database operations ended explicitly by commit or rollback.
- **commit**: Make a transaction's changes durable according to the database's guarantees.
- **rollback**: Discard a transaction's uncommitted changes; identity sequence allocation need not be undone.
- **FromRow**: SQLx's trait for mapping database rows into Rust values, implemented for the tuples used here.
- **migration**: A deliberate, versioned schema change; CREATE TABLE IF NOT EXISTS is not a migration strategy.
- **least privilege**: Giving an application identity only the database/resource permissions it needs.
- **TLS**: Transport Layer Security, used to protect and authenticate connections when configured with appropriate certificate verification.
- **control character**: A Unicode character used for controls rather than ordinary display text, such as a tab or newline.

## 201.08 Authentication middleware with Tower
- **middleware**: Behavior applied before or after a service's handling of a request.
- **Tower service**: An asynchronous request-to-response abstraction used by Axum and composable middleware.
- **layer**: A wrapper that takes a service and returns one with additional behavior.
- **authentication**: Establishing which identity presented valid credentials.
- **authorization**: Deciding whether an established identity may perform an action on a resource.
- **JWT**: JSON Web Token: signed claim data requiring signature and policy validation before trust.
- **claim**: A token field describing identity or permitted use, such as issuer, subject, audience or expiry.
- **HS256**: A shared-secret signature algorithm based on HMAC-SHA-256; a holder of the verification secret can also sign.
- **issuer / iss**: The trusted entity identified as issuing a token.
- **audience / aud**: The intended recipient API or service for a token.
- **subject / sub**: The identity represented by a token, distinct from a resource permission.
- **expiry / exp**: A token's end-of-validity time in seconds since the Unix epoch.
- **not-before / nbf**: A time before which the token must not be accepted.
- **clock leeway**: An explicit time allowance for clock skew during time-claim validation.
- **request extension**: Typed per-request storage used here for claims that middleware has already verified.
- **JWKS**: JSON Web Key Set, a public-key publication format used by issuers such as Keycloak; the full flow belongs in the capstone.

## 201.09 Testing Rust code
- **unit test**: A focused test placed next to implementation code, including access to private parent items through a child module.
- **documentation test**: A Rust example in documentation that rustdoc can compile and execute as a test.
- **integration test**: A separate test crate in tests/ exercising the public library contract as an external caller.
- **test fixture**: Deliberate example data for tests, not a production credential or an observed runtime capture.
- **contract assertion**: A check of promised behavior or values rather than incidental timing, ordering or diagnostic wording.

## 201.10 Mini project
- **Arc**: Atomically reference-counted shared ownership of one allocation; cloning the pointer does not duplicate its inner value.
- **mutex**: A synchronization primitive allowing one holder exclusive access to shared mutable data at a time.
- **guard**: A scoped value holding a mutex lock until it is dropped.
- **BTreeMap**: An ordered map whose iteration follows key order.
- **tracing**: Structured diagnostic events and spans; this project records metadata rather than sensitive content.
- **subscriber**: A component collecting/formatting tracing events.
- **graceful shutdown**: Stop accepting work and allow in-flight operations to finish within a deliberate shutdown policy.
- **multi-stage build**: A Docker build separating compilation stages from the final runtime filesystem.
- **dependency cache layer**: A reusable image layer building dependencies before frequently changing application sources.
- **build context**: Files sent to the Docker build, restricted here by .dockerignore.
- **non-root runtime**: Running the application under an unprivileged user instead of uid 0.
- **image digest**: A content-addressed image identifier useful for reviewed reproducible deployment inputs; checked mutable tags are not equivalent.

## 301.01 Advanced traits and type-state
- **type-state**: A design in which an object's current state is part of its type, so calling a method in the wrong state does not compile.
- **marker type**: A type, often empty, that exists only to name a state or a property at compile time.
- **PhantomData**: A zero-size field that tells the compiler a generic type parameter is "used" although no value of it is stored.
- **sealed trait**: A public trait that only its own crate can implement, because it requires a supertrait from a private module.
- **associated type**: A type named inside a trait that each implementor fixes once (for example `Iterator::Item`).
- **associated const**: A constant declared in a trait and given a value by each implementor, resolved at compile time.
- **supertrait**: A trait that another trait requires (`trait A: B` means every `A` is also a `B`).
- **blanket impl**: An implementation of a trait for every type that meets a bound, such as `impl<T: Display> Describe for T`.
- **generic associated type (GAT)**: An associated type with its own generics or lifetime, used when the type must borrow from `&self`.
- **dyn compatibility**: The rules a trait must meet (no generic methods, no `Self` returns) before it can be used as `dyn Trait`.

## 301.02 Unsafe Rust and FFI
- **unsafe**: A keyword that unlocks five operations (raw pointer dereference, unsafe calls, mutable statics, unsafe traits, union fields) whose correctness the programmer vouches for.
- **undefined behaviour (UB)**: A program state the language forbids; the compiler may assume it never happens, so a violation can change code far from the bug.
- **soundness**: The property that no safe caller can trigger UB through an API.
- **SAFETY comment**: A comment before an unsafe block that states the facts that make it correct.
- **raw pointer**: A `*const T` or `*mut T` that the compiler does not track for validity or aliasing.
- **FFI (foreign function interface)**: Calling code written in another language, usually C, through a fixed binary convention.
- **build script**: A `build.rs` program that Cargo compiles and runs before the crate to generate code or compile native libraries.
- **cbindgen**: A separate tool that writes a C header from the public `extern "C"` items of a Rust crate.
- **Miri**: An interpreter for Rust's mid-level code that detects many kinds of undefined behaviour in tests; it runs on the nightly toolchain.

## 301.03 Declarative and procedural macros
- **macro_rules!**: Declarative macros defined by pattern arms that match tokens and produce new tokens.
- **fragment specifier**: The kind of syntax a macro variable captures, such as `expr`, `ident`, `ty` or `tt`.
- **repetition**: The `$( ... ) sep rep` form that matches or produces a list in a macro.
- **hygiene**: The rule that local variables made inside a `macro_rules!` expansion do not clash with the caller's variables.
- **`$crate`**: The path of the crate that defines a macro, used so that it works when called from another crate.
- **procedural macro**: A Rust function that turns a token stream into another one; kinds are derive, attribute and function-like.
- **derive macro**: A procedural macro invoked with `#[derive(Name)]` that adds items next to a struct or enum.
- **syn and quote**: Libraries that parse tokens into a syntax tree and turn templates back into tokens, used by procedural macros.
- **workspace**: A set of packages in one folder tree that share one lockfile and one build output folder.

## 301.04 Send, Sync and fearless concurrency
- **Send**: A marker trait for types whose values may be moved to another thread.
- **Sync**: A marker trait for types whose shared references may be used from several threads at once.
- **auto trait**: A trait the compiler implements automatically for a type when all of its parts have it.
- **scoped thread**: A thread started inside `thread::scope`, which guarantees it ends before the scope returns, so it may borrow local data.
- **channel**: A one-way queue between threads; the sender and receiver ends move or clone separately.
- **lock poisoning**: The state of a mutex after a thread panicked while holding it; later `lock` calls return an error.
- **atomic**: A shared integer or flag whose reads and updates are indivisible without a lock.
- **memory ordering**: The rule (`Relaxed`, `Acquire`, `Release`, `SeqCst`) that says what other memory operations an atomic one orders.
- **deadlock**: A state in which threads wait for each other's locks forever.

## 301.05 Hexagonal architecture
- **hexagonal architecture (ports and adapters)**: A design in which the core depends on nothing outside it and talks to the world through ports implemented by adapters.
- **port**: A trait, written in the core's vocabulary, that describes what the core needs from or offers to the outside.
- **adapter**: Code that implements or calls a port for one technology, such as a database or an HTTP framework.
- **driving adapter**: An adapter that calls into the core, such as an HTTP handler or a command-line parser.
- **driven adapter**: An adapter the core calls through a port, such as a repository or a clock.
- **composition root**: The one place, usually `main`, that chooses concrete adapters and wires them together.
- **fitness function**: An automated check that an architectural rule still holds, such as "the domain imports no other layer".
- **ADR (architecture decision record)**: A short written record of a decision, its context and its consequences.

## 301.06 Performance and benchmarks
- **benchmark**: A repeatable measurement of the time or resources a piece of code uses.
- **Criterion**: A statistics-driven benchmarking library that reports confidence intervals and changes against a baseline.
- **black_box**: A function that hides a value from the optimiser so that benchmarked work is not removed.
- **baseline**: A saved earlier measurement that a new run is compared against.
- **profiler / flame graph**: A tool that samples where a running program spends time, and a picture of the result.
- **allocation**: A request to the memory allocator for a block of heap memory.
- **global allocator**: The allocator used for the whole program, replaceable with `#[global_allocator]`.
- **link-time optimisation (LTO)**: Optimising across crate boundaries when the program is linked.
- **performance budget**: A stated limit, such as a latency percentile, that a change must stay within.

## 301.07 gRPC with tonic
- **gRPC**: A remote-call system that sends protobuf messages over HTTP/2 with built-in streaming, deadlines and status codes.
- **Protocol Buffers (protobuf)**: A schema language and compact binary format for structured messages.
- **proto file**: The `.proto` source that defines messages and services; every language generates its code from it.
- **field number**: The number that identifies a field on the wire; it must never be changed or reused.
- **reserved**: A protobuf statement that blocks a removed field's number or name from being reused.
- **server streaming**: A call with one request and many responses.
- **gRPC status code**: A standard result code such as `NOT_FOUND` or `INVALID_ARGUMENT` returned with every call.
- **deadline**: A time limit sent with a call; the server and client give up when it passes.
- **tonic / prost**: The Rust gRPC library and the Rust protobuf library that it builds on.

## 301.08 Supply chain and security
- **supply chain**: Everything your software is built from and by: dependencies, tools, build scripts, base images and CI.
- **RustSec advisory**: An entry in the RustSec database that describes a vulnerability, unmaintained crate or unsound API in a crate.
- **cargo audit**: A tool that checks `Cargo.lock` against the RustSec database.
- **cargo deny**: A tool that enforces a policy on advisories, licences, banned crates and sources from `deny.toml`.
- **MSRV (minimum supported Rust version)**: The oldest compiler a crate promises to build with, declared as `rust-version`.
- **`--locked`**: A Cargo flag that fails the build instead of changing `Cargo.lock`.
- **reproducible build**: A build whose output is bit-for-bit identical when repeated from the same inputs.
- **distroless image**: A container image with only the runtime libraries a program needs, without a shell or package manager.
- **constant-time comparison**: Comparing secrets in time that does not depend on how many bytes match.
- **provenance**: Signed information about how, where and from what an artefact was built.

## 301.09 WebAssembly and release engineering
- **WebAssembly (Wasm)**: A compact binary format that runs in a sandboxed virtual machine in browsers and other hosts.
- **wasm-bindgen**: A tool and library that generate the glue between Rust and JavaScript in a WebAssembly module.
- **linear memory**: The single growable block of bytes that a WebAssembly module uses as its memory.
- **cdylib**: A crate type that produces a dynamic library with a C-style interface; the form of a `.wasm` module.
- **Content-Security-Policy (CSP)**: A browser setting that limits where a page may load scripts and other resources from.
- **SemVer**: A versioning scheme where major changes break the API, minor changes add features and patch changes fix bugs.
- **yank**: Withdrawing a published crate version so new projects avoid it, while existing lockfiles keep working.
- **canary release**: Sending a new version to a small share of traffic first and watching metrics before continuing.
- **rollback**: Returning to the previous known-good version of a release.
- **production checklist**: A written list of checks, each with evidence, that a service must pass before shipping.
