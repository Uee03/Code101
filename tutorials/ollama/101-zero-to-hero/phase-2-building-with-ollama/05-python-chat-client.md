---
track: ollama
level: 101
phase: 2
phase_name: building-with-ollama
lesson: 05
title: 'Python: a chat client with the standard library'
time: '60-75 min'
prerequisites: [101.1.04, Python 101]
versions: { ollama: 'current native stable; docs checked 2026-11-23', python: '3.12 or newer' }
verified: not yet run
source: source/ollama/101-zero-to-hero/phase-2-building-with-ollama/05-python-chat-client/
assets: []
---

# 05. Python: a chat client with the standard library

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Send a JSON chat request using only Python's standard library.
- Read a complete reply or NDJSON events without treating the stream as one document.
- Handle cancellation, connection failures and incomplete replies without logging prompt text.


## Recap
1. Where does `/api/chat` put generated text?
   <details><summary>Answer</summary>Inside message.content, not the generate endpoint's response field.</details>
2. How do you know a stream finished normally?
   <details><summary>Answer</summary>Read through an event with done:true; a closed connection alone is insufficient.</details>
3. What does Python's `with` do for an open resource?
   <details><summary>Answer</summary>It closes the resource when the block finishes, including when an exception leaves it.</details>


## Why it matters
A waiter can bring a complete meal or bring one course at a time. Your Python client must know which service it ordered: a complete JSON reply or a stream of small JSON events. We will make that choice explicit instead of relying on a default.


## What you will build
A one-question command-line client with optional `--stream`. It requests one answer and exits; persistent conversation memory is reserved for lesson 08. There is no `pip install`, SDK or third-party dependency.


## Before you start
- Time: 60-75 minutes, including the exercise. Finish Python 101: functions, dictionaries, loops, exceptions, imports and reading files should be familiar.
- Python 3.12+ from Python 101; Windows uses `python`, macOS/Linux use `python3`. If typing `python` opens a Store page on Windows, use the Python installation you set up in Python 101; do not install packages to fix an interpreter alias.
- Native Ollama server on loopback and local `llama3.2:1b` from lesson 03. Tag checked **2026-11-23**, https://ollama.com/library/llama3.2.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished example, exercise starter and solution are in https://github.com/Uee03/Code101 under `source/ollama/101-zero-to-hero/phase-2-building-with-ollama/05-python-chat-client/`. Choose **Code > Download ZIP**, or use `git clone https://github.com/Uee03/Code101.git` if you already use Git.
- To extract a ZIP: Windows, right-click > **Extract All > Extract**; macOS, double-click; Linux, right-click > **Extract Here** in your archive manager. Open `Code101-main`, then the source path above. A phase ZIP instead starts with its phase-pack folder.
- Model responses below are documented **shapes**, not captured output. Answers, timings and streaming chunk boundaries vary.

## Steps
### Step 1. Prepare a clean Python workspace

A **terminal** is a window for typing commands. Windows: Start > type **PowerShell** > open it, not Python. macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from your applications menu. Do not type the prompt's leading `>` or `$`. The text before that symbol usually shows the current folder.

Create a separate practice folder. `$HOME` (PowerShell) and `~` (macOS/Linux) mean your home folder. These commands start in any folder; the second line is also your recovery command if you get lost.

**File: `Terminal, Windows PowerShell; starting anywhere`**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/ollama05" -Force | Out-Null
Set-Location "$HOME/code101/ollama05"
```

**File: `Terminal, macOS/Linux; starting anywhere`**
```bash
mkdir -p ~/code101/ollama05
cd ~/code101/ollama05
```
Expected result, not yet run: the folder exists and the terminal is inside it; these commands normally print nothing.
Use a plain-text editor for files below. Windows: Notepad, **Save As**, choose **All files**, UTF-8; turn on File Explorer **View > Show > File name extensions** so `.json` does not become `.json.txt`. macOS: TextEdit > **Format > Make Plain Text**, disable smart quotes and automatic `.txt` extension. Linux: your plain-text Text Editor. An existing VS Code install is also fine: **File > Open Folder**, select this folder, then **Terminal > New Terminal**. A dot on an editor tab means unsaved; save with Ctrl+S (macOS Cmd+S). No editor extension or account is needed.

A **standard library** is the collection of modules shipped with Python. `urllib.request` makes HTTP requests, `json` encodes/decodes JSON, `urllib.error` supplies HTTP/connection exceptions, and `sys.argv` holds command-line arguments. A **timeout** limits a wait for network work; in urllib it applies to blocking operations, not a guaranteed wall-clock deadline for a whole streamed answer.

Before running the client, check the already running server without starting it:

**File: `Windows PowerShell; folder ~/code101/ollama05`**
```powershell
Invoke-RestMethod -Uri http://127.0.0.1:11434/api/version -TimeoutSec 5
```

**File: `macOS/Linux terminal; folder ~/code101/ollama05`**
```bash
curl --fail --show-error --silent --max-time 5 http://127.0.0.1:11434/api/version
```
Expected response shape: a version field as in lesson 02. If absent, deliberately start your native app/service using that lesson. Do not have this client launch a server or download a missing model.

### Step 2. Create the complete client
Save the full file below as `chat.py` in `~/code101/ollama05`. Do not call it `json.py` or `urllib.py`: those names can hide Python's library modules.

**File: `~/code101/ollama05/chat.py`**
```python
import json
import sys
import urllib.error
import urllib.request

URL = "http://127.0.0.1:11434/api/chat"
MODEL = "llama3.2:1b"


def read_reply(response, streaming):
    if not streaming:
        data = json.load(response)
        if data.get("error") or data.get("done") is not True:
            raise ValueError("Incomplete reply")
        print(data["message"]["content"])
        return
    finished = False
    for line in response:
        if not line.strip():
            continue
        event = json.loads(line)
        if event.get("error"):
            raise ValueError("Stream error")
        piece = event.get("message", {}).get("content", "")
        print(piece, end="", flush=True)
        if event.get("done") is True:
            finished = True
            break
    print()
    if not finished:
        raise ValueError("Incomplete stream")


def main():
    if sys.argv[1:] not in ([], ["--stream"]):
        print("Use: chat.py [--stream]")
        return
    streaming = sys.argv[1:] == ["--stream"]
    prompt = input("You (public or invented text only): ").strip()
    if not prompt:
        print("No text sent.")
        return
    if len(prompt) > 600:
        print("Use at most 600 characters.")
        return
    body = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "stream": streaming,
        "options": {"num_ctx": 2048, "num_predict": 160},
    }
    request = urllib.request.Request(
        URL,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        read_reply(response, streaming)


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the server and model tag.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection failed or timed out; check the native Ollama server.")
    except (ValueError, KeyError, TypeError, AttributeError):
        print("Reply incomplete or invalid; discard any partial text.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
```

### Step 3. Trace the non-streaming request before sending it
`main()` accepts no argument or exactly `--stream`. It collects one public/invented prompt, rejects empty/overlong input, and creates a Python dictionary. `json.dumps` **serializes** it: converts Python values to JSON text. `.encode("utf-8")` converts that text to bytes, the form HTTP sends. UTF-8 is a standard way to represent text as bytes. Python `False` becomes JSON `false` automatically.

`Request` specifies the local URL, POST, data and header. A **proxy** forwards network traffic on behalf of a client. `ProxyHandler({})` disables environment proxy forwarding for this fixed-loopback request; it is not a licence to change the server URL to an untrusted host. `with opener.open(..., timeout=180)` closes the response when finished. Non-streaming `json.load(response)` **deserializes** the single JSON envelope into Python values. The client requires `done` to be true and prints `message.content`.

Predict before running: if you enter only spaces, will any HTTP request be sent? Follow the `return` before the body is constructed.

### Step 4. Trace streaming and failure handling
When `--stream` is present, the same request has `stream: True`. Iterating the HTTP response yields byte lines. `json.loads(line)` decodes **each** nonblank NDJSON object. The client checks for `error`, reads optional message content, prints it without adding spaces, and flushes so chunks appear promptly. It reads a final event's content **before** checking `done`.

`finished` records whether `done: true` was seen. A connection that ends early raises an incomplete-stream error in the client. A printed partial answer cannot be undone: discard it when the failure notice appears. A chunk may be less than a word or several words; do not insert separators between chunks.

`HTTPError` is caught before `URLError` because HTTPError is a kind of URLError; we want its status code. Error bodies may echo submitted text, so we never print them. The program reports connection failure, invalid data or cancellation using its own short messages, not raw server bodies or tracebacks. Ctrl+C cancels this client; it does not stop the native Ollama server.


## Run it
Use only your OS branch, current folder `~/code101/ollama05`.

**File: `Windows PowerShell`**
```powershell
Set-Location "$HOME/code101/ollama05"
python chat.py
```

**File: `macOS/Linux terminal`**
```bash
cd ~/code101/ollama05
python3 chat.py
```
At `You (public or invented text only):`, enter `Explain RAM in one sentence.` and press Enter. The program prints a generated answer; **answers vary**. It does not print the JSON envelope itself. The envelope it consumes has this documented shape:

**File: `Response shape only; not captured output`**
```json
{"message":{"role":"assistant","content":"<variable answer>"},"done":true}
```
Now request streaming explicitly:

**File: `Windows PowerShell; folder ~/code101/ollama05`**
```powershell
python chat.py --stream
```

**File: `macOS/Linux terminal; folder ~/code101/ollama05`**
```bash
python3 chat.py --stream
```
Enter the same public prompt. Expected behaviour, not yet run: text appears in pieces and ends with a newline when the stream completes. Neither timing nor wording is guaranteed. The events consumed have this shape; the final event may also contain text:

**File: `NDJSON shape only; actual chunks vary`**
```jsonl
{"message":{"content":"<piece>"},"done":false}
{"message":{"content":""},"done":true}
```
For the prediction check, run the non-streaming command once more and press Enter without text. The following is deterministic client text derived from the source, **expected output, not yet run**:

**File: `Terminal, blank-input client message`**
```text
No text sent.
```
No model answer is involved in that branch.


## How it works
Input validation happens before network work. The stream flag selects one reader; both send JSON over the same fixed loopback endpoint. Non-streaming is simpler when you need the whole answer before using it. Streaming improves perceived responsiveness but needs completion/error tracking. Most common misconception: **`json.load(response)` works for NDJSON too**. It expects one JSON value, not multiple line-separated values.


## Try it
**Guided:** restore extraction of the streamed message content in the starter. Keep missing-message handling because a final event may not include a text piece. Without a pack, create `~/code101/ollama05/exercise/chat.py` with the full starter below. With a pack, copy `05-python-chat-client/exercise/starter` itself into `ollama05`, rename it `exercise`; do not put `starter` inside another exercise folder.

**File: `~/code101/ollama05/exercise/chat.py`**
```python
import json
import sys
import urllib.error
import urllib.request

URL = "http://127.0.0.1:11434/api/chat"
MODEL = "llama3.2:1b"


def read_reply(response, streaming):
    if not streaming:
        data = json.load(response)
        if data.get("error") or data.get("done") is not True:
            raise ValueError("Incomplete reply")
        print(data["message"]["content"])
        return
    finished = False
    for line in response:
        if not line.strip():
            continue
        event = json.loads(line)
        if event.get("error"):
            raise ValueError("Stream error")
        piece = ""  # TODO: read content from this event, allowing a missing message.
        print(piece, end="", flush=True)
        if event.get("done") is True:
            finished = True
            break
    print()
    if not finished:
        raise ValueError("Incomplete stream")


def main():
    if sys.argv[1:] not in ([], ["--stream"]):
        print("Use: chat.py [--stream]")
        return
    streaming = sys.argv[1:] == ["--stream"]
    prompt = input("You (public or invented text only): ").strip()
    if not prompt:
        print("No text sent.")
        return
    if len(prompt) > 600:
        print("Use at most 600 characters.")
        return
    body = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "stream": streaming,
        "options": {"num_ctx": 2048, "num_predict": 160},
    }
    request = urllib.request.Request(
        URL,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        read_reply(response, streaming)


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the server and model tag.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection failed or timed out; check the native Ollama server.")
    except (ValueError, KeyError, TypeError, AttributeError):
        print("Reply incomplete or invalid; discard any partial text.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
```

Run from the exercise folder after replacing the TODO:

**File: `Windows PowerShell`**
```powershell
Set-Location "$HOME/code101/ollama05/exercise"
python chat.py --stream
```

**File: `macOS/Linux terminal`**
```bash
cd ~/code101/ollama05/exercise
python3 chat.py --stream
```
Goal: stream the content, not blank output, and still require normal completion. Do not compare answer wording.
**Change:** change the requested output-token budget from 160 to 80 and compare answer length; a limit does not promise a complete sentence. **Stretch (optional):** explain why automatic retries after partial streaming could duplicate visible text. No retry loop is needed.

<details><summary>Solution</summary>

**File: `~/code101/ollama05/exercise/chat.py`**
```python
import json
import sys
import urllib.error
import urllib.request

URL = "http://127.0.0.1:11434/api/chat"
MODEL = "llama3.2:1b"


def read_reply(response, streaming):
    if not streaming:
        data = json.load(response)
        if data.get("error") or data.get("done") is not True:
            raise ValueError("Incomplete reply")
        print(data["message"]["content"])
        return
    finished = False
    for line in response:
        if not line.strip():
            continue
        event = json.loads(line)
        if event.get("error"):
            raise ValueError("Stream error")
        piece = event.get("message", {}).get("content", "")
        print(piece, end="", flush=True)
        if event.get("done") is True:
            finished = True
            break
    print()
    if not finished:
        raise ValueError("Incomplete stream")


def main():
    if sys.argv[1:] not in ([], ["--stream"]):
        print("Use: chat.py [--stream]")
        return
    streaming = sys.argv[1:] == ["--stream"]
    prompt = input("You (public or invented text only): ").strip()
    if not prompt:
        print("No text sent.")
        return
    if len(prompt) > 600:
        print("Use at most 600 characters.")
        return
    body = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "stream": streaming,
        "options": {"num_ctx": 2048, "num_predict": 160},
    }
    request = urllib.request.Request(
        URL,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        read_reply(response, streaming)


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the server and model tag.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection failed or timed out; check the native Ollama server.")
    except (ValueError, KeyError, TypeError, AttributeError):
        print("Reply incomplete or invalid; discard any partial text.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
```

The nested `.get` calls supply empty defaults when content is absent; the existing `done` logic still verifies stream completion.
</details>


## Check yourself
1. How does a Python dictionary become the HTTP request body?
   <details><summary>Answer</summary>json.dumps makes JSON text, encode("utf-8") makes bytes, and Request sends those bytes as an application/json POST.</details>
2. Find the bug: you call `json.loads` once on the entire streamed body.
   <details><summary>Answer</summary>NDJSON contains separate JSON values. Decode each nonblank line, print its content, then check done.</details>
3. Predict: entering only spaces sends a request. True or false, and why avoid raw error bodies?
   <details><summary>Answer</summary>False: strip produces an empty string and main returns. Raw error bodies can include private request text, so the client reports a short status instead.</details>


## Common mistakes
| Symptom or typical message, not captured | Cause | Fix |
|---|---|---|
| Python cannot open the file | Wrong folder, extra extension or unsaved file | Use the first cd/Set-Location line in Run it and save chat.py. |
| Typical `SyntaxError` or `IndentationError` | Missing colon/quote or altered indentation | Compare the exact saved region with the full listing; use four spaces for indentation. |
| Typical `Extra data` JSON error in a modified reader | Whole NDJSON stream decoded at once | Restore per-line json.loads in the streaming branch. |
| Own client message says connection failed/timed out | Server down or cold/slow model load | Use passive health checks and a short prompt; only increase the timeout deliberately. |
| Text stops, then own client says reply incomplete | Missing done event or stream error | Discard partial text and investigate; do not treat it as a valid complete reply. |
| Imports behave strangely | File named json.py or urllib.py | Rename your file to chat.py; remove only its accidental local cache if necessary. |


## Best practice
Use explicit timeouts and context managers around HTTP resources. Source: Python standard library, urllib.request https://docs.python.org/3/library/urllib.request.html


## Going further
Read the [Ollama streaming contract](https://docs.ollama.com/api/streaming). Lesson 06 uses non-streaming so validation can happen before a result is accepted; lesson 08 adds bounded conversation memory.


## Summary
- You encoded a chat request using only standard-library modules.
- You separated complete-JSON parsing from per-line NDJSON reading.
- You guarded completion and handled failure without recording prompt bodies.


<details><summary>Draft text/source consistency record, 2026-11-23</summary>

This recorded result checked text/source consistency only. It did not run this example or contact Ollama. Runtime behaviour remains unverified.

**File: `Authoring record; not example output`**
```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-2-building-with-ollama/05-python-chat-client
```

</details>

## Next lesson
[06. Prompting basics](06-prompting-basics.md): guide behaviour with roles and examples, then request and validate structured JSON.
