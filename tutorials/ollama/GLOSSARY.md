# Ollama glossary

Terms are introduced in the numbered lesson shown. Python programming terms are assumed from Python 101.

| Term | Plain-language meaning | Lesson |
|---|---|---|
| LLM (large language model) | A learned system that predicts pieces of text from other text | 01 |
| Ollama | Native software that downloads compatible models and runs inference | 01 |
| Model | Learned numerical weights and the information needed to use them | 01 |
| Weights / parameters | Numerical values learned during training; a parameter count is not a byte count | 01 |
| Native | Installed directly on the operating system, not in Docker/a virtual machine | 01 |
| Prompt | Input supplied to a model for the current task | 01 |
| Inference | Using learned weights to produce a result, not training new weights | 01 |
| Token | A piece of text; not necessarily a whole word or one character | 01 |
| Context window | The token budget available to the current input/history and generated reply | 01 |
| Local inference | Model computation performed on your computer | 01 |
| Cloud service | Computation performed on someone else's computers | 01 |
| Disk storage | Persistent file space used by the app and downloaded weights | 01 |
| RAM | Main working memory used while software runs | 01 |
| CPU | General-purpose central processor; can run local inference without a supported GPU | 01 |
| GPU | Processor suited to many numerical operations at once; acceleration depends on support | 01 |
| VRAM | Dedicated GPU working memory; Apple Silicon instead shares system memory | 01 |
| Tag | A model variant name after a colon, such as the checked 1b variant | 01 |
| Hallucination | Plausible generated content that is fabricated or incorrect | 01 |
| Privacy | Control over access to information about people; local inference is not complete privacy | 01 |
| Terminal | A window for entering commands into a shell | 01 |
| Shell | The program interpreting terminal commands, such as PowerShell or a Unix shell | 02 |
| Client | A program that sends requests to a server | 02 |
| Server | A program that listens for and answers requests | 02 |
| HTTP | The request/response protocol used by this local API | 02 |
| Port | A numbered network endpoint; Ollama's default is 11434 | 02 |
| Loopback | The local machine's network interface: 127.0.0.1 or ::1, not a LAN address | 02 |
| localhost | A name usually resolving to a loopback address | 02 |
| Driver | Software connecting an operating system to a hardware device | 02 |
| systemd | A Linux service manager used by the normal native installation | 02 |
| PATH | The OS list of directories searched for executable commands | 02 |
| Pipe | An operator sending one command's output into another command | 02 |
| Service | A background program managed by the operating system | 02 |
| Listener | A process/socket accepting connections at an address and port | 02 |
| Authentication | Checking who a caller is; the default local Ollama API has none | 02 |
| Environment variable | A named OS setting read by a program | 03 |
| Pull | Download a model's files for local use | 03 |
| Quantization | Storing learned numbers with fewer bits, usually reducing size with quality trade-offs | 03 |
| Loaded model | Weights occupying working memory for inference, not merely stored on disk | 03 |
| PROCESSOR | The ollama ps column indicating CPU/GPU model placement, not instantaneous utilisation | 03 |
| API | Application programming interface: an agreed program-to-program interaction | 04 |
| REST API | Here, an HTTP interface organised into named endpoint paths | 04 |
| Endpoint | A named server path handling a kind of request, such as /api/chat | 04 |
| URL | Network address including scheme, host, optional port and path | 04 |
| GET | HTTP method used here to read existing server state | 04 |
| POST | HTTP method used here to submit a JSON body for work | 04 |
| JSON | JavaScript Object Notation, a text format for objects, arrays and primitive values | 04 |
| Request body | The data submitted with the HTTP request | 04 |
| Header | Request/response metadata such as Content-Type | 04 |
| Status code | HTTP result category/number, not a judgement of model-answer truth | 04 |
| Message | A role-labelled content item in a chat transcript | 04 |
| Role | The speaker label: system, user or assistant in these examples | 04 |
| Envelope | The outer API JSON carrying metadata and generated content | 04 |
| Streaming | Delivering result pieces before the full answer is ready | 04 |
| NDJSON | Newline-delimited JSON: one separate JSON object per line | 04 |
| Chunk / event | One streamed piece/event; not necessarily one word or token | 04 |
| Standard library | Modules shipped with Python; no pip install required here | 05 |
| Serialization | Converting Python values to a transfer format such as JSON text | 05 |
| Deserialization | Converting JSON back into Python values | 05 |
| UTF-8 | A standard encoding converting Unicode text to/from bytes | 05 |
| Timeout | A limit on network waiting; urllib's blocking timeout is not a whole-stream deadline | 05 |
| Proxy | An intermediary forwarding network requests; disabled for these fixed-loopback Python clients | 05 |
| System prompt | A system-role instruction describing intended model behaviour, not access control | 06 |
| Few-shot prompting | Giving a few input/output examples in the conversation to teach a pattern | 06 |
| Temperature | A generation randomness setting, not a correctness guarantee | 06 |
| Structured output | Content requested in an explicit machine-readable form | 06 |
| JSON Schema | A description of allowed JSON fields, types and values | 06 |
| Validation | Checking data against the application's rules before accepting it | 06 |
| Embedding | A numerical representation of aspects of input meaning | 07 |
| Vector | An ordered list of numerical coordinates | 07 |
| Dimension | One coordinate position in a vector | 07 |
| Semantic search | Finding related meaning rather than just identical words | 07 |
| Query | The user's search text | 07 |
| Batch | Several inputs submitted in one request | 07 |
| Dot product | The sum of products of corresponding vector coordinates | 07 |
| Cosine similarity | Dot product divided by both nonzero vector lengths; compares direction | 07 |
| Task prefix | Model-specific text identifying document versus query use | 07 |
| Top-k | The k highest-ranked candidates; here 3, not a generation sampling setting | 07 |
| Corpus / collection | The source texts being searched; exactly ten invented sentences here | 07 |
| Retrieval | Selecting source material instead of generating an answer | 07 |
| Modelfile | An Ollama configuration recipe for a model's base and defaults | 08 |
| Local alias | A locally created model name, not necessarily a published library tag | 08 |
| Turn | A user message together with its assistant reply | 08 |
| Conversation history / transcript | The messages the client explicitly resends for the next answer | 08 |
| In-memory state | Data held in the running Python process, not saved as a conversation file | 08 |
| Prompt injection | Instructions smuggled into input data to redirect intended behaviour | 08 |
| Untrusted text | Text to inspect as data, not automatically execute as instructions or commands | 08 |
| TLS | Transport Layer Security, a protocol for encrypting network transport; not configured here | 08 |
| Rate limiting | Caps on request frequency, outside this loopback beginner project | 08 |
| Scrollback | Earlier text still visible/stored by a terminal, not cleared by resetting a Python list | 08 |
| Static check | A text/source consistency check that does not execute lesson programs | Authoring |
| Runtime verification | Actually following/running the example; not performed for this draft | Authoring |

## Checked model names (2026-11-23)
`llama3.2:1b` and `nomic-embed-text:v1.5` were checked on the live official library pages listed in `_BRIEF.md`.
`code101-study:local` is explicitly created by lesson 08 and is not represented as a library tag.
A shape placeholder such as `<variable answer>` describes a field, never an expected model answer.

## Level 201 and 301 terms (written 2026-11-23, not run)
| Term | Plain-language meaning | Lesson |
|---|---|---|
| Modelfile layering | A derived model records parameters, system text, messages and template on top of a base model | 201.01 |
| Template (Go template) | The recipe turning messages into the model's native prompt text; overriding it replaces the inherited one | 201.01 |
| Stop parameter | A string at which generation halts; travels with the template | 201.01 |
| `done_reason` | Why a reply ended: `stop` (finished) or `length` (cut off by a cap) | 201.01 |
| Cold start | The first request after a model is unloaded, including load time | 201.02 |
| `time.perf_counter` | A monotonic high-resolution clock for measuring durations | 201.02 |
| Quantisation levels (q8_0, q4_K_M) | Named weight formats with different bits per weight, size and quality | 201.02 |
| KV cache | Memory remembering earlier tokens; grows with context and parallel slots | 201.02 |
| Decision record | A dated note choosing an option from your own measurements | 201.02 |
| `format` schema | Request field constraining a reply to a JSON schema | 201.03 |
| Enum | A closed list of allowed values | 201.03 |
| Bounded retry | A retry loop with a fixed attempt limit | 201.03 |
| `ResponseHeadersRead` | .NET option returning when headers arrive so a body can be streamed | 201.04 |
| Typed client | An HTTP client wrapper with typed requests and replies | 201.04 |
| `AbortSignal` | A JavaScript object that cancels a pending request | 201.05 |
| Line splitter | Code that reassembles NDJSON lines cut across network packets | 201.05 |
| OpenAI-compatible endpoint | `/v1/...` paths implementing a subset of the OpenAI API | 201.06 |
| SSE (server-sent events) | Streaming lines starting `data:` and ending with `data: [DONE]` | 201.06 |
| Normalisation (L2) | Dividing a vector by its length so its length is 1 | 201.07 |
| Chunk overlap | Words repeated between neighbouring chunks | 201.07 |
| pgvector | A Postgres extension adding a vector type and distance operators | 201.08 |
| HNSW | An approximate nearest-neighbour index built as a layered graph | 201.08 |
| `<=>` / `<->` / `<#>` | Cosine distance, L2 distance, negative inner product | 201.08 |
| Parameterised query | SQL with values passed separately from the statement text | 201.08 |
| Idempotent ingest | Re-running ingest changes nothing unless a file changed | 201.09 |
| RAG | Retrieval-augmented generation: answer from retrieved passages with sources | 301.01 |
| Golden set | Fixed questions with known answers used to measure a system | 301.03 |
| Hit rate at k | Share of questions whose first relevant result ranks within k | 301.03 |
| MRR | Mean of 1 divided by the rank of the first relevant result | 301.03 |
| Refusal accuracy | Share of unanswerable questions correctly refused | 301.03 |
| Tool calling | The model requests a function call; your code runs it | 301.04 |
| Allow-list | Only named items are permitted; everything else is refused | 301.04 |
| Propose-then-confirm | A write-shaped tool only records a proposal that a human confirms | 301.04 |
| Prompt injection | Instructions hidden in data that try to steer the model | 301.05 |
| Canary | A random marker in the system prompt whose appearance in output signals a leak | 301.05 |
| Exfiltration | Sending data out, for example through an image or link URL | 301.05 |
| HMAC fingerprint | A keyed hash used to count repeats without storing text | 301.05 |
| `OLLAMA_NUM_PARALLEL` | Parallel requests per loaded model; multiplies context memory | 301.06 |
| `OLLAMA_MAX_QUEUE` | Queue length before the server answers 503 | 301.06 |
| p50 / p95 | Median and 95th-percentile latency (nearest rank here) | 301.06 |
| Reverse proxy | A server in front that adds authentication, limits and filtering | 301.07 |
| Rate limiting (429) | Rejecting requests above an allowed frequency | 301.07 |
| Review exercise | Reading a configuration or service against a checklist and ranking findings | 301.07 |
| Constant-time comparison | Comparing secrets without timing differences that leak them | 301.08 |
| Acceptance record | Your own filled-in evidence that requirements were met | 301.08 |
