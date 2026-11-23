# Python glossary

Terms are grouped by the lesson that introduces them, including optional Going further notes.

| Term | Meaning | Lesson |
|------|---------|--------|
| --version | A command option asking a tool to print its version and stop | 101.01 |
| apt | The Debian/Ubuntu system software installer | 101.01 |
| code editor | A notepad made for writing code (VS Code) | 101.01 |
| command | A written instruction typed in the terminal | 101.01 |
| comment | A note for humans starting with `#`, ignored by Python | 101.01 |
| folder (directory) | A container that holds files | 101.01 |
| function | A named helper that does one job, e.g. `print` | 101.01 |
| interpreter | The part of Python that reads your file and follows it line by line | 101.01 |
| parentheses | Round brackets `( )` enclosing a function's inputs | 101.01 |
| program | A list of instructions a computer follows exactly, in order | 101.01 |
| py | The Windows Python manager command that selects an installed Python | 101.01 |
| python3-venv | The Debian/Ubuntu component enabling isolated Python environments | 101.01 |
| script | A file of Python instructions you run | 101.01 |
| statement | One instruction on one line | 101.01 |
| string | Text between quote marks | 101.01 |
| sudo | A Linux command asking to run another command with administrator permission | 101.01 |
| terminal | A window where you type commands | 101.01 |
| TODO | A reminder in a comment to replace or finish something | 101.01 |
| boolean (`bool`) | A yes/no value: `True` or `False` | 101.02 |
| concatenate | Join text with `+` | 101.02 |
| curly brackets (braces) | The `{ }` symbols enclosing expressions to insert in an f-string | 101.02 |
| f-string | Text with an `f` before the quote; `{ }` inserts variables | 101.02 |
| float | A number with a decimal point | 101.02 |
| integer (`int`) | A whole number | 101.02 |
| type | The kind of value: `str`, `int`, `float`, `bool` | 101.02 |
| variable | A labelled jar that stores a value under a name | 101.02 |
| input | Asks the user to type something; always returns text | 101.03 |
| operator | A symbol that does a calculation, e.g. `+` | 101.03 |
| power | Repeated multiplication; `7 ** 2` multiplies 7 by itself | 101.03 |
| type conversion | Changing a value's type, e.g. `float("80")` | 101.03 |
| block | The indented lines that belong to an `if`, `elif` or `else` | 101.04 |
| boolean expression | Anything that works out to `True` or `False` | 101.04 |
| comparison | A yes/no question about two values, e.g. `5 > 3` | 101.04 |
| condition | A boolean expression after `if` or `elif` that decides whether the block runs | 101.04 |
| elif | Short for else if; checks another condition if earlier conditions were false | 101.04 |
| indentation | Spaces at the start of a line that show which block it belongs to | 101.04 |
| break | An instruction that ends the nearest surrounding loop | 101.05 |
| continue | An instruction that skips the rest of an iteration and starts the next | 101.05 |
| for loop | A loop that visits each item in a sequence | 101.05 |
| infinite loop | A loop with no reachable stopping point | 101.05 |
| iteration | One trip through a loop's block | 101.05 |
| loop | A block repeated under a counting or condition rule | 101.05 |
| range | A sequence of whole numbers whose stop value is excluded | 101.05 |
| sequence | A group of things in order, such as the numbers supplied by range | 101.05 |
| traceback | The trail of file locations printed for an unhandled exception | 101.05 |
| while loop | A loop that repeats while its condition is true | 101.05 |
| argument | An actual value supplied to a function call | 101.06 |
| body | The indented lines under a function definition | 101.06 |
| call | Running a function by writing its name and parentheses with any arguments | 101.06 |
| caller | The line of code that used a function | 101.06 |
| local variable | A name belonging to one function call rather than its caller | 101.06 |
| parameter | A named input in a function definition | 101.06 |
| positional argument | An argument matched to a parameter by its position in the call | 101.06 |
| return value | The result a function sends back to its caller with return | 101.06 |
| scope | The region of code where a name can be used | 101.06 |
| collection | A container holding several values together | 101.07 |
| dictionary | A changeable collection of unique keys and their associated values | 101.07 |
| index | A numbered position in a list, starting at zero | 101.07 |
| insertion order | The order in which dictionary keys were added; updating a value does not move its key | 101.07 |
| key-value pair | A lookup label (key) and the associated data (value) in a dictionary | 101.07 |
| list | An ordered, changeable collection written with square brackets | 101.07 |
| membership | Whether an item is present, checked with in or not in; dictionaries check keys | 101.07 |
| method | A function attached to a value, called using a dot | 101.07 |
| __file__ | The path of the currently running script | 101.08 |
| byte | A small unit of stored data | 101.08 |
| context manager | A with-block helper that manages setup and cleanup, such as closing a file | 101.08 |
| CSV | Comma-separated values, a text format for rows and columns | 101.08 |
| file mode | The open setting selecting reading, writing or appending | 101.08 |
| file path | A description of a file's location | 101.08 |
| header | A table's first row, naming its columns | 101.08 |
| import | An instruction that makes a module or selected names available | 101.08 |
| keyword argument | An argument supplied by parameter name, such as encoding="utf-8" | 101.08 |
| module | A named unit of Python code made available with import | 101.08 |
| parent | The containing folder of a Path | 101.08 |
| Path | The pathlib helper representing a file or folder location | 101.08 |
| pathlib | Python's standard-library module for working with file paths | 101.08 |
| resolve | A Path method producing an absolute, full file location | 101.08 |
| standard library | The ready-made modules shipped with Python | 101.08 |
| text encoding | A rule for storing characters as bytes; UTF-8 supports many languages | 101.08 |
| UTF-8 | A text encoding supporting characters from many languages | 101.08 |
| with | Starts a block whose context manager performs cleanup on leaving it | 101.08 |
| exception | An error detected while a program runs | 101.09 |
| finite number | An ordinary number rather than infinity or the special not-a-number value | 101.09 |
| handler | An except block that responds to a specific exception from a try block | 101.09 |
| try/except | Marks a risky operation and a handler for a specified exception | 101.09 |
| validation | Checking whether input is acceptable, beyond whether it converts successfully | 101.09 |
| activation | Changes a terminal so short Python commands select a virtual environment | 101.10 |
| dependency | A library another project needs | 101.10 |
| dotted import | An import path naming a module inside a package, such as helpers.formatting | 101.10 |
| execution policy | A PowerShell setting controlling whether scripts may run | 101.10 |
| main guard | The __name__ == "__main__" condition, running code for direct execution but not imports | 101.10 |
| metadata | Information about a package, such as its installed version | 101.10 |
| package | A group of modules under one name; this course uses folders marked with __init__.py | 101.10 |
| pip | Python's package installer | 101.10 |
| requirements file | A text list of dependencies for pip to install | 101.10 |
| semicolon | The `;` symbol separating Python statements in the lesson's one-line commands | 101.10 |
| sys.prefix | The current Python environment's folder; sys.base_prefix is the base installation's folder | 101.10 |
| venv | Python's standard-library tool for creating virtual environments | 101.10 |
| version pin | A requirement selecting one exact dependency release | 101.10 |
| virtual environment | A folder containing a project-specific Python environment and installed packages | 101.10 |
| attribute | A named value belonging to an object, accessed with a dot | 101.11 |
| bare return | Ends a function call without an explicit return value | 101.11 |
| class | A definition for a kind of object | 101.11 |
| initializer | The __init__ method that sets up a new instance's starting data | 101.11 |
| instance | An individual object made from a class | 101.11 |
| object | A value with its own data and behaviour | 101.11 |
| self | The conventional parameter name for the instance receiving a method call | 101.11 |
| assert | A developer check that stops with AssertionError when false; removable with Python's -O option | 101.12 |
| constant | A name intended not to change, conventionally written in capitals | 101.12 |
| csv.Error | An exception for a problem detected by the CSV reader | 101.12 |
| except ... as | Gives a caught exception a local name so its message can be used | 101.12 |
| None | Python's special value for absence, distinct from zero or an empty string | 101.12 |
| operating system | Software such as Windows, macOS or Linux managing files and devices | 101.12 |
| OSError | An exception for an operating-system failure, such as denied file access | 101.12 |
| raise | An instruction that deliberately signals an exception | 101.12 |
| reader.fieldnames | The column names read from a CSV header | 101.12 |
| schema | The expected column names and order for the project's CSV | 101.12 |
| self-check | A small program exercising a few known examples | 101.12 |
| strip | A string method returning text without leading or trailing spaces | 101.12 |
| TemporaryDirectory | A helper making a disposable folder and removing it on leaving its with block | 101.12 |
| tuple | An ordered group of values that cannot be changed in place | 101.12 |

## Python 201: Hero to Super Hero

| Term | Meaning | Lesson |
|------|---------|--------|
| composition | Keeping collaborating objects as attributes instead of making one a subtype of another | 201.1.01 |
| dataclass | A class decorator that generates methods such as initialization and value equality from annotated fields | 201.1.01 |
| default factory | A zero-argument callable invoked separately to make each instance's default field value | 201.1.01 |
| dunder method | A double-underscore method implementing a Python protocol, such as __len__ or __str__ | 201.1.01 |
| frozen dataclass | A dataclass that blocks ordinary field reassignment, without freezing referenced mutable objects deeply | 201.1.01 |
| inheritance | Defining a subtype that should be usable where its parent type is expected | 201.1.01 |
| property | An attribute interface whose value is computed or controlled by methods | 201.1.01 |
| slots | Restricted instance attribute storage selected here with dataclass(slots=True), not an access-control feature | 201.1.01 |
| type annotation | A declaration of an intended value type, not automatic runtime validation | 201.1.01 |
| unit test | A developer check for one small behavior, here collected with unittest | 201.1.01 |
| iterable | An object from which an iterator can be obtained, such as a list, tuple or generator | 201.1.02 |
| mypy | A static type checker that reads annotated Python without running the target program | 201.1.02 |
| narrowing | Using a condition to eliminate possible types from a union within a branch | 201.1.02 |
| protocol (typing) | A structural interface describing required behavior without requiring explicit inheritance | 201.1.02 |
| structural compatibility | Satisfying an interface by providing its required operations rather than inheriting its name | 201.1.02 |
| TOML | A configuration format of named sections and key/value settings, used by pyproject.toml | 201.1.02 |
| union type | A type that permits multiple alternatives, such as Note or None | 201.1.02 |
| exhaustion | The state after an iterator has no values remaining; another pass does not reset it | 201.1.03 |
| generator | An iterator produced by a function containing yield, preserving local state between requests | 201.1.03 |
| iterator | A stateful stream supporting iter and next until StopIteration | 201.1.03 |
| lazy evaluation | Deferring work until a consumer asks for its result | 201.1.03 |
| materialize | Consume a stream into a stored collection such as a list | 201.1.03 |
| single-pass | A consumption contract in which an iterator's values cannot automatically be revisited | 201.1.03 |
| yield | Suspend a generator and provide a value while preserving its local execution state | 201.1.03 |
| callable signature | The accepted parameter types and returned result described here by Callable | 201.1.04 |
| decorator | A callable applied at definition time that returns the value bound to the decorated name | 201.1.04 |
| finally | A cleanup block run when control leaves its protected try block, including by exception | 201.1.04 |
| function metadata | Information such as a function's name, documentation and annotations, preserved by wraps | 201.1.04 |
| generator context manager | A context manager expressed by a decorated generator yielding exactly once between setup and cleanup | 201.1.04 |
| wrapper | A callable delegating to another callable while optionally changing its behavior | 201.1.04 |
| cancellation | A cooperative request for asynchronous work to stop at a suspension point, allowing cleanup | 201.2.05 |
| coroutine | A suspendable asynchronous operation created by calling an async def function | 201.2.05 |
| event loop | The scheduler that resumes asynchronous operations when they can make progress | 201.2.05 |
| ExceptionGroup | An exception containing a structured group of underlying failures | 201.2.05 |
| task | A coroutine scheduled for execution on an event loop | 201.2.05 |
| TaskGroup | An asynchronous context that owns related tasks and waits for or cancels them as a group | 201.2.05 |
| timeout scope | A lifetime boundary that cancels cooperative work if its deadline expires | 201.2.05 |
| build backend | A tool such as Hatchling that creates distribution artifacts from a project's source and metadata | 201.2.06 |
| CLI | Command-line interface, such as the installed note-words command | 201.2.06 |
| console entry point | An installed command mapped to an importable Python function | 201.2.06 |
| editable install | An installation pointing to development source so ordinary source edits are observed without reinstalling | 201.2.06 |
| lockfile | A tool-generated record of exact resolved dependency choices, distinct from a list of direct requirements | 201.2.06 |
| source distribution | A distributable source archive containing code and build metadata | 201.2.06 |
| src layout | A project layout keeping importable packages under src so installation is explicit | 201.2.06 |
| uv | A Python project/environment manager coordinating dependency resolution, synchronization and project commands | 201.2.06 |
| wheel | An installable Python distribution archive | 201.2.06 |
| dotenv file | A local plaintext file of environment-like assignments, not encrypted credential storage | 201.2.07 |
| Literal | A typing form limiting an accepted value to listed alternatives, used by Pydantic for runtime validation here | 201.2.07 |
| logger | A named source of operational events carrying severity levels | 201.2.07 |
| logging formatter | A rule choosing the fields and layout of displayed log records | 201.2.07 |
| logging threshold | The minimum severity selected for emitted or handled logging events | 201.2.07 |
| secret | Information whose disclosure grants access or exposes protected data | 201.2.07 |
| SecretStr | A Pydantic secret-string representation that masks normal display but does not encrypt storage | 201.2.07 |
| API | An application programming interface through which another program requests behavior or data | 201.3.08 |
| application factory | A function creating an app and its owned dependencies, enabling independent instances and tests | 201.3.08 |
| ASGI | Asynchronous server gateway interface, the application/server boundary used by FastAPI and Uvicorn | 201.3.08 |
| dependency injection | Supplying a handler's dependencies through a declared boundary rather than constructing them in its body | 201.3.08 |
| DTO | Data transfer object describing data accepted or returned across a boundary | 201.3.08 |
| entity | An internal object with an identity, here a note identified by an ID | 201.3.08 |
| HTTP | The request/response protocol used by the API in these lessons | 201.3.08 |
| JSON | A text format used for API request and response data | 201.3.08 |
| lock | A synchronization primitive protecting a compound operation within this process, not persistence across processes | 201.3.08 |
| response model | The declared public output shape used to validate and filter API results | 201.3.08 |
| route | A mapping from HTTP method/path to a handler | 201.3.08 |
| TestClient | An in-process application client that exercises HTTP semantics without starting Uvicorn or binding a port | 201.3.08 |
| bound parameter | A value supplied separately from SQL text so data is not interpreted as query syntax | 201.3.09 |
| database engine | SQLAlchemy's connectivity and connection-pool boundary | 201.3.09 |
| database session | A short-lived SQLAlchemy unit of ORM/database work, not an object to share between concurrent requests | 201.3.09 |
| integration test | A developer check of collaborating components, such as Python, a driver and PostgreSQL | 201.3.09 |
| migration | A versioned schema change, unlike one-time initialization or create_all on a new temporary database | 201.3.09 |
| ORM | Object-relational mapper connecting Python objects and relational tables | 201.3.09 |
| SQL injection | A failure where untrusted input is interpreted as SQL structure rather than solely as data | 201.3.09 |
| stored procedure | A named database operation invoked with CALL, distinct from a function used in a SELECT expression | 201.3.09 |
| transaction | A group of database changes committed together or rolled back on failure | 201.3.09 |
| Argon2 | A password-hashing algorithm supported by pwdlib and selected for new verifiers in these examples | 201.3.10 |
| authentication | Establishing a caller's identity within a configured trust model | 201.3.10 |
| authorization | Deciding whether an authenticated subject may perform an operation on a resource | 201.3.10 |
| bearer token | A credential granting access to whoever possesses it | 201.3.10 |
| claim | A token field carrying an assertion such as subject, issuer, audience or expiry | 201.3.10 |
| HS256 | A symmetric JWT signing algorithm in which possession of the shared secret allows signing and verification | 201.3.10 |
| JWT | JSON Web Token, a claims container signed in this lesson but not encrypted | 201.3.10 |
| password hash | A deliberately expensive one-way verifier used instead of storing a plaintext password | 201.3.10 |
| salt | Random data incorporated into password hashing so independent encodings of the same password differ | 201.3.10 |
| signature | Cryptographic data allowing detection of token changes and verification against a trusted key | 201.3.10 |
| conftest.py | Pytest's fixture-sharing module for a test directory and its descendants | 201.4.11 |
| fixture | Named reusable test setup resolved from a test function's parameters | 201.4.11 |
| flush | Sending pending ORM changes to the database within the current transaction, without committing it | 201.4.11 |
| index | A database structure helping find rows with a storage/write cost; not a measured performance guarantee | 201.4.11 |
| lifespan | A context bracketing an application's startup and shutdown resource ownership | 201.4.11 |
| parametrization | Running one test function as independent cases for a declared set of inputs | 201.4.11 |
| tmp_path | Pytest's unique temporary-directory fixture, used for isolated file-backed test databases | 201.4.11 |
| yield fixture | A fixture yielding its resource to a test and running teardown after the test finishes | 201.4.11 |
| adapter | Code at the edge that implements a port for one technology, such as SQLite or HTTP | 301.1.01 |
| composition root | The one place (usually the entry point) that creates concrete objects and wires them together | 301.1.01 |
| dependency rule | Source-code imports point inward, from adapters to use cases to the domain, never the reverse | 301.1.01 |
| hexagonal architecture | Another name for ports and adapters: the core talks to the outside only through ports | 301.1.01 |
| port | An interface owned by the inner layers describing what they need from the outside, here a typing.Protocol | 301.1.01 |
| use case | A class or function that sequences one business action: load, ask the domain, save, notify | 301.1.01 |
| aggregate root | The entity through which a group of related objects is changed, owning the rules that span the group | 301.1.02 |
| contract test | A test every adapter of a port must pass, proving the adapters are substitutable | 301.1.02 |
| entity (domain model) | A domain object defined by an identity that survives changes to its attributes | 301.1.02 |
| invariant | A rule that must hold whenever the model is observed, such as at most three open tasks | 301.1.02 |
| SOLID | Five design principles (single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion) for keeping change local | 301.1.02 |
| unit of work | An object that scopes one all-or-nothing change, committed explicitly and otherwise discarded | 301.1.02 |
| value object | An immutable domain object defined only by its value, validated when created | 301.1.02 |
| breaking change | A change that can make an existing client fail, such as removing or renaming a field | 301.1.03 |
| cursor pagination (keyset) | Paging by "items after the last one seen" using an indexed key, instead of an offset | 301.1.03 |
| idempotency key | A client-supplied identifier that makes a repeated request produce one effect | 301.1.03 |
| problem details | The RFC 9457 JSON error format served as application/problem+json | 301.1.03 |
| Sunset header | An HTTP header (RFC 8594) announcing the date after which a resource may stop working | 301.1.03 |
| tolerant reader | A client rule: ignore response fields you do not know, so additive changes are safe | 301.1.03 |
| event-loop lag | The delay between when an asyncio task should wake and when it does, caused by blocking work | 301.2.04 |
| free-threaded build | A CPython build with the global interpreter lock disabled so threads run Python code in parallel | 301.2.04 |
| global interpreter lock (GIL) | A lock in CPython that lets only one thread run Python bytecode at a time on a standard build | 301.2.04 |
| race condition | A bug whose result depends on the timing of threads, such as a lost update in counter += 1 | 301.2.04 |
| cache-aside | Look in the cache first; on a miss load from the source and store the result with a time to live | 301.2.05 |
| cache stampede | Many requests missing the same expired key at once and all hitting the source | 301.2.05 |
| deterministic profiler | A profiler that hooks every call and return (cProfile): exact counts, higher overhead | 301.2.05 |
| fail open | Treat a failing helper (such as a cache) as absent so the request still succeeds | 301.2.05 |
| flame graph | A picture of sampled call stacks where box width shows time spent | 301.2.05 |
| sampling profiler | A profiler that looks at the call stack many times per second, with little overhead (py-spy) | 301.2.05 |
| TTL (time to live) | How long a cached value may be served before it must be reloaded | 301.2.05 |
| at-least-once delivery | A guarantee that a message is never lost but may be delivered more than once | 301.2.06 |
| dead-letter | The state or queue for messages that exhausted their retries and need a human | 301.2.06 |
| dual-write problem | Updating two systems (a database and a broker) cannot be made atomic by either one alone | 301.2.06 |
| exponential backoff | Waiting longer after each failure (1 s, 2 s, 4 s, up to a cap) before retrying | 301.2.06 |
| idempotent consumer | A receiver that produces one effect however many times it receives the same message | 301.2.06 |
| jitter | Random variation added to a retry delay so many clients do not retry at the same instant | 301.2.06 |
| outbox pattern | Saving a message in the same transaction as the state change, then delivering it from the table | 301.2.06 |
| poison message | A message that can never be processed successfully and would otherwise be retried forever | 301.2.06 |
| Collector (OpenTelemetry) | A separate process that receives, processes and forwards telemetry to backends | 301.3.07 |
| label cardinality | The number of distinct values a metric label can take; unbounded labels multiply stored series | 301.3.07 |
| observability | The ability to answer questions you did not predict about a running system from its telemetry | 301.3.07 |
| OTLP | The OpenTelemetry protocol for sending traces, metrics and logs, over gRPC or HTTP | 301.3.07 |
| RED metrics | Rate, errors and duration of requests, the first three numbers to watch for a service | 301.3.07 |
| span | One timed operation in a trace, with a name, attributes and a parent | 301.3.07 |
| structured logging | Writing each log event as machine-readable fields, usually one JSON object per line | 301.3.07 |
| trace | The tree of spans describing one request across the components that served it | 301.3.07 |
| allow-list | A list of the only values accepted, with everything else refused | 301.3.08 |
| broken object level authorization (BOLA) | Returning or changing an object by id without checking that the caller may | 301.3.08 |
| constant-time comparison | Comparing secrets in time that does not reveal where they first differ (hmac.compare_digest) | 301.3.08 |
| fail closed | Refuse to start or to proceed when a required control or secret is missing | 301.3.08 |
| mass assignment | A client setting fields it should not, such as owner, because the server accepts unknown input | 301.3.08 |
| server-side request forgery (SSRF) | Making a server fetch an attacker-chosen URL, often to reach internal services | 301.3.08 |
| supply chain (software) | Everything your build and runtime depend on: packages, base images, tools and their publishers | 301.3.08 |
| immutable artifact | A built file or image that is never modified after release, only replaced by a new version | 301.3.09 |
| liveness probe | A check that the process is alive; failing it makes the platform restart the instance | 301.3.09 |
| production readiness review | A structured review of a service against a checklist before launch, ending in go or no-go | 301.3.09 |
| readiness probe | A check that an instance can serve traffic now; failing it removes it from traffic without restarting it | 301.3.09 |
| rollback | Returning to the previous known-good version after a failed release | 301.3.09 |
| SBOM | A software bill of materials: an inventory of the components inside an artifact | 301.3.09 |
| sdist | A source distribution archive of a Python project | 301.3.09 |
| semantic versioning | MAJOR.MINOR.PATCH numbering where major means breaking, minor compatible features, patch compatible fixes | 301.3.09 |
