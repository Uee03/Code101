---
track: ollama
level: 101
phase: 1
phase_name: first-steps
lesson: 04
title: 'Talking to the REST API with curl and PowerShell'
time: '55-65 min'
prerequisites: [101.1.03]
versions: { ollama: 'current native stable; docs checked 2026-11-23' }
verified: not yet run
source: source/ollama/101-zero-to-hero/phase-1-first-steps/04-rest-api/
assets: []
---

# 04. Talking to the REST API with curl and PowerShell

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Send a local generate or chat request using curl or PowerShell.
- Locate generated text in the correct JSON response fields.
- Distinguish one JSON response from a stream of newline-delimited objects.


## Recap
1. Which command shows stored downloads rather than loaded models?
   <details><summary>Answer</summary>`ollama list`; `ollama ps` shows loaded models.</details>
2. Does a successful answer prove GPU placement?
   <details><summary>Answer</summary>No. Check the PROCESSOR column while the model is loaded.</details>


## Why it matters
A restaurant order form lets different people ask the same kitchen for food. An application programming interface (**API**) is an agreed request/response interface that lets programs ask Ollama for work. We will use the documented HTTP interface directly, without writing a program yet.


## What you will build
Three small request files: single-prompt generation, role-labelled chat and streaming chat. You will inspect response shapes, not compare model wording.


## Before you start
- Time: 55-65 minutes. Native server running on loopback; `llama3.2:1b` already pulled in lesson 03. Tag check: **2026-11-23**, https://ollama.com/library/llama3.2.
- Windows: built-in PowerShell route below works without curl. If choosing curl on Windows, use **`curl.exe`**, not `curl`, which can be a PowerShell alias. macOS/Linux use `curl`.
- No Python, account, API key or extra package is required. Requests load a model and consume local resources even though inference is local.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished example, exercise starter and solution are in https://github.com/Uee03/Code101 under `source/ollama/101-zero-to-hero/phase-1-first-steps/04-rest-api/`. Choose **Code > Download ZIP**, or use `git clone https://github.com/Uee03/Code101.git` if you already use Git.
- To extract a ZIP: Windows, right-click > **Extract All > Extract**; macOS, double-click; Linux, right-click > **Extract Here** in your archive manager. Open `Code101-main`, then the source path above. A phase ZIP instead starts with its phase-pack folder.
- Model responses below are documented **shapes**, not captured output. Answers, timings and streaming chunk boundaries vary.

## Steps
### Step 1. Make a folder and learn the envelope

A **terminal** is a window for typing commands. Windows: Start > type **PowerShell** > open it, not Python. macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from your applications menu. Do not type the prompt's leading `>` or `$`. The text before that symbol usually shows the current folder.

Create a separate practice folder. `$HOME` (PowerShell) and `~` (macOS/Linux) mean your home folder. These commands start in any folder; the second line is also your recovery command if you get lost.

**File: `Terminal, Windows PowerShell; starting anywhere`**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/ollama04" -Force | Out-Null
Set-Location "$HOME/code101/ollama04"
```

**File: `Terminal, macOS/Linux; starting anywhere`**
```bash
mkdir -p ~/code101/ollama04
cd ~/code101/ollama04
```
Expected result, not yet run: the folder exists and the terminal is inside it; these commands normally print nothing.
Use a plain-text editor for files below. Windows: Notepad, **Save As**, choose **All files**, UTF-8; turn on File Explorer **View > Show > File name extensions** so `.json` does not become `.json.txt`. macOS: TextEdit > **Format > Make Plain Text**, disable smart quotes and automatic `.txt` extension. Linux: your plain-text Text Editor. An existing VS Code install is also fine: **File > Open Folder**, select this folder, then **Terminal > New Terminal**. A dot on an editor tab means unsaved; save with Ctrl+S (macOS Cmd+S). No editor extension or account is needed.

**REST (Representational State Transfer) API** here means an HTTP interface organised into named paths called **endpoints**. The **URL** is the address including scheme, host, port and path. We use `http://127.0.0.1:11434/api/generate` or `/api/chat`. **GET** reads state, as in lesson 02's `/api/version`; **POST** sends a request body to perform work. **JSON (JavaScript Object Notation)** is a text data format with objects (`{}`), arrays (`[]`), quoted strings and booleans `true`/`false`. JSON is not a Python dictionary: no single-quoted strings, `True`, trailing commas or comments.

A **header** describes request metadata. `Content-Type: application/json` says the body contains JSON. The HTTP response has a status code: 2xx is success; 4xx indicates a rejected request, and 5xx indicates a server failure. A successful transport does not make the answer true. Keep the loopback API private; it has no built-in authentication.

### Step 2. Create and send a generate request
Save the full file below. `model` selects the local tag, `prompt` holds text, and `stream: false` asks for one complete JSON object. `options` limits input/output resource use: `num_ctx` is context tokens and `num_predict` limits generated tokens.

**File: `~/code101/ollama04/generate.json`**
```json
{
  "model": "llama3.2:1b",
  "prompt": "Explain a local language model in one short sentence.",
  "stream": false,
  "options": {"num_ctx": 2048, "num_predict": 128}
}
```

First use lesson 02's version check if you are unsure whether the server is running. Then choose one shell route below; do not send every variant unless you want extra generations.

**File: `PowerShell; folder ~/code101/ollama04`**
```powershell
$body = Get-Content -Raw -Encoding UTF8 .\generate.json
$r = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/generate -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 180
$r | ConvertTo-Json -Depth 10
```

**File: `macOS/Linux curl; folder ~/code101/ollama04`**
```bash
curl --fail-with-body --show-error --max-time 180 http://127.0.0.1:11434/api/generate -H 'Content-Type: application/json' --data-binary '@generate.json'
```

**File: `Windows curl alternative; folder ~/code101/ollama04`**
```powershell
curl.exe --fail-with-body --show-error --max-time 180 http://127.0.0.1:11434/api/generate -H 'Content-Type: application/json' --data-binary '@generate.json'
```
File-based JSON avoids shell-specific nested-quote escaping. `--data-binary @file` sends the file's contents; `-H` sets a header; curl chooses POST when sending a body. `--max-time` bounds the whole curl request. If an older curl lacks `--fail-with-body`, update via your OS or use `--fail` instead (it may hide an error body); PowerShell's route does not need curl at all.

**File: `Documented response SHAPE (selected fields); not expected model output`**
```json
{"model":"llama3.2:1b","created_at":"<timestamp>","response":"<generated text; answers vary>","done":true}
```
There may be extra fields. `response` is the generated text; `done` marks completion. Timing fields such as `total_duration`, `load_duration` and `eval_duration` use nanoseconds; `prompt_eval_count`/`eval_count` count input/output tokens. Their numbers vary by hardware, model and input. In the PowerShell route, `$r.response` selects the text (enter that at the same prompt if desired).

### Step 3. Send a conversation to chat
A **message** has a `role` (who is speaking) and `content` (text). A `system` message sets behaviour, a `user` message asks, and an `assistant` message records a previous model reply. These are roles in JSON, not commands with OS privileges. Save this complete file:

**File: `~/code101/ollama04/chat.json`**
```json
{
  "model": "llama3.2:1b",
  "messages": [
    {"role": "system", "content": "Explain things in plain language."},
    {"role": "user", "content": "What is a local language model?"}
  ],
  "stream": false,
  "options": {"num_ctx": 2048, "num_predict": 128}
}
```

**File: `PowerShell; folder ~/code101/ollama04`**
```powershell
$body = Get-Content -Raw -Encoding UTF8 .\chat.json
$r = Invoke-RestMethod -Uri http://127.0.0.1:11434/api/chat -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 180
$r | ConvertTo-Json -Depth 10
$r.message.content
```

**File: `macOS/Linux curl; folder ~/code101/ollama04`**
```bash
curl --fail-with-body --show-error --max-time 180 http://127.0.0.1:11434/api/chat -H 'Content-Type: application/json' --data-binary '@chat.json'
```

**File: `Windows curl alternative; folder ~/code101/ollama04`**
```powershell
curl.exe --fail-with-body --show-error --max-time 180 http://127.0.0.1:11434/api/chat -H 'Content-Type: application/json' --data-binary '@chat.json'
```

**File: `Documented response SHAPE (selected fields); not expected model output`**
```json
{"model":"llama3.2:1b","message":{"role":"assistant","content":"<generated text; answers vary>"},"done":true}
```
Chat text is in **`message.content`**, not `response`. The response is an outer JSON **envelope**, metadata wrapping the useful answer. `/api/chat` does not remember earlier HTTP requests for you: resend the messages you want it to consider. Lesson 08 does that explicitly.

### Step 4. Observe a stream
**Streaming** delivers pieces before the complete answer is ready. **NDJSON** means newline-delimited JSON: each line is a separate JSON object, not one big array or one JSON document. Streaming is the default for generate/chat when the field is omitted; we always set it explicitly.

Predict before sending: will `stream: true` change where chat text lives, or only how it is delivered? Save this separate file:

**File: `~/code101/ollama04/chat-stream.json`**
```json
{
  "model": "llama3.2:1b",
  "messages": [
    {"role": "user", "content": "Explain a local language model briefly."}
  ],
  "stream": true,
  "options": {"num_ctx": 2048, "num_predict": 128}
}
```

**File: `macOS/Linux curl; folder ~/code101/ollama04`**
```bash
curl --no-buffer --fail-with-body --show-error --max-time 180 http://127.0.0.1:11434/api/chat -H 'Content-Type: application/json' --data-binary '@chat-stream.json'
```

**File: `Windows PowerShell; folder ~/code101/ollama04; curl.exe if available`**
```powershell
curl.exe --no-buffer --fail-with-body --show-error --max-time 180 http://127.0.0.1:11434/api/chat -H 'Content-Type: application/json' --data-binary '@chat-stream.json'
```
`--no-buffer` asks curl not to hold output before displaying it. PowerShell's `Invoke-RestMethod` is convenient for complete JSON, but is not a dependable live NDJSON display across PowerShell versions. If `curl.exe` is unavailable, skip only this live display and use the standard-library streaming client in lesson 05; the non-streaming PowerShell examples above remain complete.

**File: `Documented NDJSON SHAPE; placeholder chunks, number/boundaries vary`**
```jsonl
{"message":{"role":"assistant","content":"<piece A>"},"done":false}
{"message":{"role":"assistant","content":"<piece B>"},"done":false}
{"message":{"role":"assistant","content":""},"done":true}
```
The final event may also contain text, and usually carries completion statistics. Read its content before stopping at `done: true`. Do not assume one chunk equals one word or token. A stream can fail midway, including an event with an `error` field after HTTP headers were sent; HTTP success alone does not prove full completion. Press Ctrl+C to cancel. A generate stream uses the same line delivery but pieces are in `response`, not `message.content`.


## Run it
In `~/code101/ollama04`, choose the complete PowerShell or curl commands from Step 2, then Step 3. If curl is available, also run Step 4. Expected result, not yet run: one generate envelope, one chat envelope, then multiple NDJSON lines for a stream. The JSON shapes above describe fields only. **All answers vary**, including between identical requests; no generated sentence is a pass/fail condition.


## How it works
The client encodes a body as JSON; the loopback server selects a downloaded model and performs inference; the endpoint returns the matching envelope. The chosen stream flag controls one-object versus line-by-line delivery. Most common misconception: **a whole stream can be decoded as one JSON value**. Decode each line separately, which lesson 05 will do in Python.


## Try it
**Guided:** make the starter a valid, non-streaming chat request with a short real question about local models (invented/public text). Create `~/code101/ollama04/exercise/chat.json`, or copy `04-rest-api/exercise/starter` itself into `ollama04` and rename it `exercise`, without nesting another `starter` folder.

**File: `~/code101/ollama04/exercise/chat.json`**
```json
{
  "model": "llama3.2:1b",
  "messages": [
    {"role": "system", "content": "Explain things in plain language."},
    {"role": "user", "content": "TODO: ask a short question about local models."}
  ],
  "stream": true,
  "options": {"num_ctx": 2048, "num_predict": 128}
}
```

To send your saved exercise from `~/code101/ollama04/exercise`, use the Step 3 commands **unchanged**: the filename is still `chat.json`; only the current folder differs. Enter `cd ~/code101/ollama04/exercise` first in either shell. Success is one chat envelope with `done: true`, not particular wording.

**Change:** request a two-sentence explanation and inspect the nested text field. **Stretch (optional):** explain how to detect an interrupted stream without trusting partial text.

<details><summary>Solution</summary>

**File: `~/code101/ollama04/exercise/chat.json`**
```json
{
  "model": "llama3.2:1b",
  "messages": [
    {"role": "system", "content": "Explain things in plain language."},
    {"role": "user", "content": "What is a local language model?"}
  ],
  "stream": false,
  "options": {"num_ctx": 2048, "num_predict": 128}
}
```

The boolean controls delivery; changing the prompt changes requested content, not endpoint shape.
</details>


## Check yourself
1. Which endpoint accepts `prompt`, and which accepts `messages`?
   <details><summary>Answer</summary>/api/generate accepts prompt; /api/chat accepts a messages array. Both requests here use POST.</details>
2. Find the bug: you read chat text from `response`.
   <details><summary>Answer</summary>That is the generate text field. For chat, read message.content.</details>
3. Predict: with streaming true, can a chat line still use `message.content`?
   <details><summary>Answer</summary>Yes. Delivery changes to one object per line. Read each piece and require a final done:true; a final line may contain text too.</details>


## Common mistakes
| Symptom or typical message, not captured | Cause | Fix |
|---|---|---|
| File cannot be found | Wrong folder, extra `.txt`, or unsaved file | Return to `~/code101/ollama04`, verify extensions and save the exact file. |
| JSON rejected | Single quotes, `False`, comments or trailing commas | Use the full JSON shown; JSON uses double quotes and lowercase `false`. |
| curl flags rejected in Windows PowerShell | `curl` resolved to a PowerShell alias | Use `curl.exe` or the explicit Invoke-RestMethod route. |
| Chat text field appears empty | Looking for `response` | Read `message.content`. |
| Many JSON objects cause a parse failure | Stream treated as one document | Set stream false or parse each NDJSON line. |
| Request times out | Cold load or slow CPU inference | Keep prompt short, verify the native server and model; increase the timeout deliberately if needed, not the network exposure. |


## Best practice
Set the streaming mode explicitly and handle that mode's documented response format. Source: Ollama API, Streaming https://docs.ollama.com/api/streaming


## Going further
**Phase 1 mixed review:** explain why a local model can hallucinate; choose a passive health check; distinguish `list` from `ps`; identify both response text paths.
<details><summary>Review answers</summary>Local describes location, not truth; /api/version; stored versus loaded; response versus message.content.</details>
Official endpoints: [generate](https://docs.ollama.com/api/generate) and [chat](https://docs.ollama.com/api/chat).


## Summary
- You prepared and sent generate/chat JSON requests on loopback.
- You located generated text in each endpoint's documented envelope.
- You distinguished complete JSON from NDJSON and recognised interrupted-stream risks.


<details><summary>Draft text/source consistency record, 2026-11-23</summary>

This recorded result checked text/source consistency only. It did not run this example or contact Ollama. Runtime behaviour remains unverified.

**File: `Authoring record; not example output`**
```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/04-rest-api
```

</details>

## Next lesson
[05. Python: a standard-library chat client](../phase-2-building-with-ollama/05-python-chat-client.md): finish Python 101 first, then read both response modes without installing a package.
