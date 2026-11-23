---
track: ollama
level: 101
phase: 1
phase_name: first-steps
lesson: 03
title: 'Pull and chat with a model in the terminal'
time: '40-50 min plus download'
prerequisites: [101.1.02]
versions: { ollama: 'current native stable; docs checked 2026-11-23' }
verified: not yet run
source: source/ollama/101-zero-to-hero/phase-1-first-steps/03-pull-and-chat/
assets: []
---

# 03. Pull and chat with a model in the terminal

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Pull a checked small model tag and chat with it in the terminal.
- Distinguish stored, loaded, unloaded and removed models.
- Read the PROCESSOR column without assuming a GPU is in use.


## Recap
1. Which HTTP check does not start the app when it is stopped?
   <details><summary>Answer</summary>A GET to http://127.0.0.1:11434/api/version.</details>
2. Does model download size equal inference memory?
   <details><summary>Answer</summary>No. The application and conversation context also use working memory.</details>


## Why it matters
A library book can sit on a shelf without being open on your desk. A model stored on disk is like the shelved book; a loaded model uses working memory like the open book. Removing it from the desk is different from returning it permanently.


## What you will build
One short terminal conversation with `llama3.2:1b` and a model-management record. The library tag was checked on **2026-11-23** at https://ollama.com/library/llama3.2; its advertised download is about **1.3 GB**. Exact progress, IDs and generated answers vary.


## Before you start
- Time: 40-50 minutes plus download time. Finish lesson 02, including the native start and loopback checks.
- Permission for a model download, enough free disk, and internet for the download. Read the model's licence and intended-use notes on its library page.
- Keep the native server running for the exercises. A CPU-only machine is fine; allow longer for replies.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished example, exercise starter and solution are in https://github.com/Uee03/Code101 under `source/ollama/101-zero-to-hero/phase-1-first-steps/03-pull-and-chat/`. Choose **Code > Download ZIP**, or use `git clone https://github.com/Uee03/Code101.git` if you already use Git.
- To extract a ZIP: Windows, right-click > **Extract All > Extract**; macOS, double-click; Linux, right-click > **Extract Here** in your archive manager. Open `Code101-main`, then the source path above. A phase ZIP instead starts with its phase-pack folder.
- Model responses below are documented **shapes**, not captured output. Answers, timings and streaming chunk boundaries vary.

## Steps
### Step 1. Prepare the practice folder and confirm the server

A **terminal** is a window for typing commands. Windows: Start > type **PowerShell** > open it, not Python. macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from your applications menu. Do not type the prompt's leading `>` or `$`. The text before that symbol usually shows the current folder.

Create a separate practice folder. `$HOME` (PowerShell) and `~` (macOS/Linux) mean your home folder. These commands start in any folder; the second line is also your recovery command if you get lost.

**File: `Terminal, Windows PowerShell; starting anywhere`**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/ollama03" -Force | Out-Null
Set-Location "$HOME/code101/ollama03"
```

**File: `Terminal, macOS/Linux; starting anywhere`**
```bash
mkdir -p ~/code101/ollama03
cd ~/code101/ollama03
```
Expected result, not yet run: the folder exists and the terminal is inside it; these commands normally print nothing.
Use a plain-text editor for files below. Windows: Notepad, **Save As**, choose **All files**, UTF-8; turn on File Explorer **View > Show > File name extensions** so `.json` does not become `.json.txt`. macOS: TextEdit > **Format > Make Plain Text**, disable smart quotes and automatic `.txt` extension. Linux: your plain-text Text Editor. An existing VS Code install is also fine: **File > Open Folder**, select this folder, then **Terminal > New Terminal**. A dot on an editor tab means unsaved; save with Ctrl+S (macOS Cmd+S). No editor extension or account is needed.

**File: `Windows PowerShell; folder ~/code101/ollama03`**
```powershell
Invoke-RestMethod -Uri http://127.0.0.1:11434/api/version -TimeoutSec 5
Get-PSDrive -PSProvider FileSystem
```

**File: `macOS/Linux terminal; folder ~/code101/ollama03`**
```bash
curl --fail --show-error --silent --max-time 5 http://127.0.0.1:11434/api/version
df -h ~
```
The first check must answer before proceeding. If not, follow lesson 02's process/port checks and deliberate start route, not a blind `list`. The second shows free space. Look at the drive where models are stored, not just the lesson folder. Defaults: Windows `%USERPROFILE%\.ollama\models`; macOS `~/.ollama/models`; Linux native service `/usr/share/ollama/.ollama/models`. A custom `OLLAMA_MODELS` environment variable can change that path. An **environment variable** is a named OS setting read by a program; we do not change it here. Leave several GB spare for software, working files and later downloads. Do not fill the drive to its last 1.3 GB.

### Step 2. Pull the model intentionally
**Pull** means download model files, not ask a question. Enter this only after checking space and approving the download. Same commands on all three OSes:

**File: `Terminal, any OS; folder ~/code101/ollama03`**
```text
ollama pull llama3.2:1b
ollama list
```
Expected result, not yet run: pull progress and completion, then a list with the downloaded tag and metadata. No exact ID, size formatting or progress text is promised. `list` reports stored downloads, not GPU usage. An explicit tag avoids silently using the default model size, although tags can still be updated by publishers.

**Quantization** stores learned numbers using fewer bits per value, a little like rounding measurements in a recipe. It often reduces storage and memory and can improve speed, but may lose some quality; performance depends on hardware and model. A smaller parameter count and a more compressed quantization are different choices. We use the library's ready-made `1b` variant and do not invent or switch to an unchecked quantization tag. Even if its library page advertises a very long context window, we use short prompts; maximum context is not a promise that it fits your computer.

### Step 3. Run a one-shot question, then an interactive chat
**File: `Terminal, any OS; folder ~/code101/ollama03`**
```text
ollama run llama3.2:1b "Explain a local language model in one short sentence."
```
`run` loads the model as needed and sends the quoted prompt. The model generates text; there is **no exact expected answer**. Check whether it follows the requested length and whether its factual claims are sound. A first answer may take longer while weights load.

Now start an interactive conversation:

**File: `Terminal, any OS; folder ~/code101/ollama03`**
```text
ollama run llama3.2:1b
```
At Ollama's input prompt, type this sentence and press Enter: `Explain RAM using a desk analogy.` Ask a follow-up: `Make that explanation shorter.` These are model inputs, not shell commands. To leave this chat, type `/bye` at Ollama's prompt and press Enter. You return to your normal PowerShell/terminal prompt. Press Ctrl+C to interrupt generation if necessary; `/bye` is the deliberate chat exit, not a command to uninstall Ollama.

### Step 4. Observe loaded memory and processor placement
Immediately after leaving chat, while the model is still loaded, enter:

**File: `Terminal, any OS; folder ~/code101/ollama03`**
```text
ollama ps
```
The **PROCESSOR** column reports where the model was loaded. The following are documented value categories, not captured rows from this machine:

| Value category | Meaning |
|---|---|
| `100% GPU` | Model loaded entirely into GPU memory |
| `100% CPU` | Model loaded in system memory for CPU execution |
| A `CPU/GPU` percentage split | Model spread between system and GPU memory |

A successful chat or the GPU's presence does **not** prove acceleration. `ps` is stronger evidence of model placement; it is not a GPU utilisation meter. An empty table can simply mean the idle model unloaded. If needed, deliberately repeat only the one-shot `run` command in Step 3, then immediately repeat `ps`; neither command changes. If placement is CPU-only, the course still works. For unexpected fallback, compare the OS-specific official GPU list and drivers; prefer a smaller model/context rather than experimental overrides.

### Step 5. Unload versus remove
Predict before running: which operation below keeps the model in `list`?

**File: `Terminal, any OS; folder ~/code101/ollama03`**
```text
ollama stop llama3.2:1b
ollama ps
ollama list
```
`stop` unloads this model from working memory; it does not stop the Ollama server or delete the download. The model should no longer be loaded for `ps`, while its tag remains in `list`. These are expected state relationships, not captured tables.

For **optional cleanup**, after finishing all later lessons or if you choose not to continue, deliberately remove the practice tag:

**File: `Terminal, any OS; folder ~/code101/ollama03; optional removal only`**
```text
ollama rm llama3.2:1b
ollama list
```
`rm` removes the local tag and releases unreferenced model storage; shared data may remain if other tags refer to it. Do not remove it now if proceeding to lesson 04. If you did remove it, repeat Step 2's `pull` command verbatim before lesson 04. This redownload uses network and disk. Stop the native app/service using lesson 02 only when finished; `stop <model>` is not server shutdown.

### Step 6. Save a record
Create the following file in your current folder and add your observed processor category on a new line. Do not paste a made-up benchmark.

**File: `~/code101/ollama03/model-record.md`**
```markdown
# Model record

Library checked: 2026-11-23, https://ollama.com/library/llama3.2
Chat tag: llama3.2:1b
Approximate advertised download: 1.3 GB; working memory is additional.
Before downloading: check free disk on the drive that stores models.
After downloading: list means stored on disk; ps means loaded in memory.
After a short chat: record PROCESSOR exactly; do not assume GPU use.
Unloading a model frees working memory, not its stored download.
Removing a model tag is intentional; reusing it later may need another download.
Never paste private text into a practice conversation.
```


## Run it
From `~/code101/ollama03`, repeat the one-shot `ollama run` command in Step 3, then `ollama ps` from Step 4. Expected result, not yet run: generated text of variable content and a loaded-model row with actual processor placement. Compare your observation with the categories above; do not compare the words with another learner's.


## How it works
Pull stores weights; run loads and performs inference; list reports disk; ps reports loaded models; stop unloads; rm removes a local tag. Most common misconception: **leaving chat deletes the model**. Chat state, model memory and downloaded files are different lifetimes. Lesson 08 will manage conversation memory explicitly.


## Try it
**Guided:** complete the TODO command choices on paper or in the file; you do not need to delete anything to finish the exercise. Create `~/code101/ollama03/exercise/storage-plan.md`, or copy `03-pull-and-chat/exercise/starter` itself into `ollama03` and rename it `exercise` (no nested `starter`).

**File: `~/code101/ollama03/exercise/storage-plan.md`**
```markdown
# Model-management plan

Goal: see models stored on disk. Command: TODO
Goal: see models loaded in memory. Command: TODO
Goal: free working memory without deleting the download. Command: TODO
Goal: deliberately remove the practice model tag. Command: TODO
Does a successful reply prove GPU use? TODO
```

**Change:** add one sentence explaining why `ps` can be empty while `list` is not. **Stretch (optional):** compare two public prompts for instruction following without judging correctness by confidence. Success is choosing the correct state operation, not a particular generated sentence.

<details><summary>Solution</summary>

**File: `~/code101/ollama03/exercise/storage-plan.md`**
```markdown
# Model-management plan

Goal: see models stored on disk. Command: ollama list
Goal: see models loaded in memory. Command: ollama ps
Goal: free working memory without deleting the download. Command: ollama stop llama3.2:1b
Goal: deliberately remove the practice model tag. Command: ollama rm llama3.2:1b
Does a successful reply prove GPU use? No; read the PROCESSOR column in ollama ps.
```

</details>


## Check yourself
1. What does `ollama pull llama3.2:1b` do before any chat?
   <details><summary>Answer</summary>Downloads that local model variant's files; it is not a question to the model.</details>
2. Predict: after `stop`, should the tag still appear in `list`?
   <details><summary>Answer</summary>Yes. Stop unloads working memory; rm removes the local tag/download reference.</details>
3. Does `100% CPU` in PROCESSOR mean Ollama is broken?
   <details><summary>Answer</summary>No. CPU-only is supported. It may be slower; check placement and driver support before claiming GPU use.</details>


## Common mistakes
| Symptom or typical message, not captured | Cause | Fix |
|---|---|---|
| Commands are treated as chat questions | Still inside `ollama run` | Enter `/bye`, then type shell commands at the terminal prompt. |
| Download fails | Network trouble or insufficient model-drive space | Check the official tag, connectivity and free space; do not repeatedly pull different large tags. |
| `ps` shows no row | Model unloaded after idle time or stop | Deliberately run the small prompt again, then inspect promptly. |
| A GPU exists but PROCESSOR says CPU | Unsupported driver/card or memory constraints | CPU is valid; compare official hardware support and reduce resource needs before changing drivers. |


## Best practice
Use observed model placement, not the existence of a GPU, when describing acceleration. Source: Ollama Local FAQ, GPU loading and memory placement https://docs.ollama.com/faq


## Going further
The [library page](https://ollama.com/library/llama3.2) describes model variants and licence notes. Lesson 07 introduces a separate embedding-only tag; it cannot replace the chat model.


## Summary
- You selected a checked small tag and learned one-shot and interactive chat.
- You separated stored, loaded, unloaded and removed states.
- You interpreted processor placement without claiming unobserved acceleration.


<details><summary>Draft text/source consistency record, 2026-11-23</summary>

This recorded result checked text/source consistency only. It did not run this example or contact Ollama. Runtime behaviour remains unverified.

**File: `Authoring record; not example output`**
```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/03-pull-and-chat
```

</details>

## Next lesson
[04. Talking to the REST API](04-rest-api.md): send input as JSON over local HTTP instead of typing into chat.
