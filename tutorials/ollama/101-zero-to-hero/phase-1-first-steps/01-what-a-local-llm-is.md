---
track: ollama
level: 101
phase: 1
phase_name: first-steps
lesson: 01
title: 'What a local LLM is'
time: '30 min'
prerequisites: [none]
versions: { ollama: 'current native stable; docs checked 2026-11-23' }
verified: not yet run
source: source/ollama/101-zero-to-hero/phase-1-first-steps/01-what-a-local-llm-is/
assets: []
---

# 01. What a local LLM is

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain the difference between Ollama, a model and a cloud service.
- Compare storage, working memory and CPU/GPU needs for a small local model.
- Identify privacy risks and check a plausible but false answer.


## Recap
None, this is the start. No programming experience is needed for lessons 01-04.


## Why it matters
Think of Ollama as a music player and a model as an album you download. The player runs the album; installing the player does not download every album. A local language model works on your own computer, but unlike an album it produces new text that can be mistaken.


## What you will build
A one-page plan for a safe, small local-model task. You will not install software or run a model in this lesson.


## Before you start
- Time: 30 minutes including the worksheet. No Ollama or Python installation needed.
- You need permission to save a text file. Use invented or already public examples throughout this track.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished example, exercise starter and solution are in https://github.com/Uee03/Code101 under `source/ollama/101-zero-to-hero/phase-1-first-steps/01-what-a-local-llm-is/`. Choose **Code > Download ZIP**, or use `git clone https://github.com/Uee03/Code101.git` if you already use Git.
- To extract a ZIP: Windows, right-click > **Extract All > Extract**; macOS, double-click; Linux, right-click > **Extract Here** in your archive manager. Open `Code101-main`, then the source path above. A phase ZIP instead starts with its phase-pack folder.
- Model responses below are documented **shapes**, not captured output. Answers, timings and streaming chunk boundaries vary.

## Steps
### Step 1. Make a place for your plan

A **terminal** is a window for typing commands. Windows: Start > type **PowerShell** > open it, not Python. macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from your applications menu. Do not type the prompt's leading `>` or `$`. The text before that symbol usually shows the current folder.

Create a separate practice folder. `$HOME` (PowerShell) and `~` (macOS/Linux) mean your home folder. These commands start in any folder; the second line is also your recovery command if you get lost.

**File: `Terminal, Windows PowerShell; starting anywhere`**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/ollama01" -Force | Out-Null
Set-Location "$HOME/code101/ollama01"
```

**File: `Terminal, macOS/Linux; starting anywhere`**
```bash
mkdir -p ~/code101/ollama01
cd ~/code101/ollama01
```
Expected result, not yet run: the folder exists and the terminal is inside it; these commands normally print nothing.
Use a plain-text editor for files below. Windows: Notepad, **Save As**, choose **All files**, UTF-8; turn on File Explorer **View > Show > File name extensions** so `.json` does not become `.json.txt`. macOS: TextEdit > **Format > Make Plain Text**, disable smart quotes and automatic `.txt` extension. Linux: your plain-text Text Editor. An existing VS Code install is also fine: **File > Open Folder**, select this folder, then **Terminal > New Terminal**. A dot on an editor tab means unsaved; save with Ctrl+S (macOS Cmd+S). No editor extension or account is needed.

### Step 2. Separate the player from the model
A **large language model (LLM)** is a system trained to predict pieces of text from other text. A **model** here is the downloaded set of learned numerical values, called **weights**, plus information needed to use them. **Ollama** is the native application that downloads compatible models and runs them. **Native** means installed directly on the operating system, not in Docker or a virtual machine.

A **prompt** is the input you give the model. **Inference** means using its learned values to produce an answer, rather than training new values. A **token** is a small piece of text, not always a whole word. The **context window** limits the tokens available for the conversation and reply. It is not permanent memory.

**Local inference** runs on your computer. A **cloud service** runs on somebody else's computers. Ollama can offer cloud features too: choosing Ollama alone does not guarantee local processing. This track uses only explicitly downloaded local tags. Downloading the app and weights needs the internet; inference with these local models can work offline after download. It does not automatically search the web.

### Step 3. Budget for the desk, not just the filing cabinet
**Disk storage** keeps downloaded files after shutdown. **RAM (random-access memory)** is working memory used while software runs. The **CPU (central processing unit)** is the general-purpose processor. A **GPU (graphics processing unit)** is a processor suited to many numerical operations at once; its dedicated memory is often called **VRAM**. Apple Silicon shares memory between processors. A model's download size is not its total memory requirement: conversation context and the application also need room.

Checked at https://ollama.com/library/llama3.2 on **2026-11-23**: `llama3.2:1b` is about **1.3 GB** to download. A **tag**, the part after `:`, selects a model variant. Here `1b` refers to roughly one billion learned parameters, not one billion bytes. Begin small. As planning guidance, an 8 GB RAM computer may manage this short-context exercise; 16 GB leaves more room for other applications. Neither is a guaranteed minimum or a speed promise. Save work, close heavy apps, keep several GB free beyond downloads, and stop if the machine becomes unresponsive.

A supported GPU is optional, not a course requirement. CPU-only runs can be much slower, especially the first reply. NVIDIA, AMD, Intel and Apple hardware have different support and driver requirements. No course can promise every GPU works; lesson 03 shows how to check actual placement rather than guessing. See the [current hardware list](https://docs.ollama.com/gpu).

### Step 4. Choose a safe input and a checking rule
A **hallucination** is a confident-looking answer that is fabricated or incorrect. A model can invent citations, miss a negation, change a date, or make a calculation error. Fluency is not evidence. Use the original notice or an authoritative source to check factual claims; do not use model agreement as the check. It is not a doctor, lawyer, emergency service or reliable source of current news.

**Privacy** means controlling who can access information about people. Local inference avoids sending prompts to a remote model provider in this setup. It does not protect against a shared computer, malware, screen recording, backups or an application that saves chats. Never use real passwords, medical records or other private text here. We will not log prompts or answers in our Python programs.

Predict before doing the worksheet: if you disconnect from the internet after downloading a local model, does that give it today's news? Write your prediction, then compare with Check yourself.

Create this complete example plan in your practice folder.

**File: `~/code101/ollama01/local-plan.md`**
```markdown
# My local-model plan

Task: rewrite a public club announcement in simpler words.
Input: invented or public text only; no passwords or personal records.
Location: a downloaded model running on this computer, not a cloud model.
Resources: begin with the small chat model; allow extra disk and working memory.
Review: compare names, dates and factual claims with the original announcement.
Limits: generated text may be wrong; it has no automatic access to today's facts.
Privacy: local inference is not permission to store other people's private text.
Exit rule: do not use this assistant for medical, legal or emergency decisions.
```


## Run it
There is no program to run. Open `~/code101/ollama01/local-plan.md` in your editor and read each line. Expected result, not yet run: a saved plan identifying one public task, one resource limit and a way to check facts. Nothing installs, downloads or contacts a server.


## How it works
The task chooses what the model should help with. The input rule keeps private information out. Resource planning limits the first experiment. The review rule makes a human responsible for facts. Most common misconception: **local means correct and automatically private**. Local describes where inference happens, not the truth of an answer or how the rest of the computer handles data. New terms are collected in the [track glossary](../../GLOSSARY.md).


## Try it
**Guided:** fill the three TODOs without changing the task. Save the worksheet as `exercise/my-plan.md` under `ollama01`.
Without a pack, create the `exercise` subfolder in your editor/file manager and the file shown below. With a pack, instead copy the **starter folder itself** from `01-what-a-local-llm-is/exercise/starter` into `~/code101/ollama01` and rename the copy `exercise`. The result must be `ollama01/exercise/my-plan.md`, not `ollama01/exercise/starter/my-plan.md`. Do not overwrite an existing exercise folder.

**File: `~/code101/ollama01/exercise/my-plan.md`**
```markdown
# My practice plan

Task: explain a public library notice to a beginner.
Input choice: TODO: choose public, invented or private text and explain why.
Resource choice: TODO: explain why a small model is a reasonable starting point.
Review choice: TODO: name two things to check before sharing the answer.
```

**Change:** choose a different public notice and specify which dates or names you would check. **Stretch (optional):** explain a situation where you would not use a model at all. Success is a justified plan, not a model's answer.

<details><summary>One possible solution</summary>

**File: `~/code101/ollama01/exercise/my-plan.md`**
```markdown
# My practice plan

Task: explain a public library notice to a beginner.
Input choice: public text, because no person's private information is needed.
Resource choice: a small model uses less storage and working memory; quality may be lower.
Review choice: check opening hours and membership rules against the original notice.
```

This is one safe choice, not the only wording that works.
</details>


## Check yourself
1. Is installing Ollama the same as downloading a model?
   <details><summary>Answer</summary>No. Ollama is the application; a model is a separate download it can run.</details>
2. Does a 1.3 GB model download need exactly 1.3 GB of RAM?
   <details><summary>Answer</summary>No. Download size measures storage; inference also needs working memory for software and context.</details>
3. Predict: will a downloaded local model know today's news when offline, and may its claims be trusted without checking?
   <details><summary>Answer</summary>No to both. It has no automatic current-news feed and may hallucinate. Check an authoritative source.</details>


## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| The plan has an unintended `.txt` suffix | The editor supplied a default extension | Enable filename extensions and save the exact filename with the settings in Step 1. |
| You choose real account details for practice | Local inference was mistaken for complete privacy | Replace them with invented text before continuing. |
| You choose a huge model because you own a GPU | Storage was confused with working memory and GPU compatibility | Begin with the checked small tag and verify actual placement in lesson 03. |


## Best practice
Keep practice inputs public or invented, and distinguish local models from cloud features before entering text. Source: Ollama Local FAQ, privacy and local-only mode https://docs.ollama.com/faq


## Going further
Read the current [hardware support page](https://docs.ollama.com/gpu). Lesson 07 will use a different model to compare meanings, not generate answers.


## Summary
- You separated the Ollama application from model downloads and cloud inference.
- You compared storage, working memory and CPU/GPU needs.
- You chose safe input and a human fact-checking rule.


<details><summary>Draft text/source consistency record, 2026-11-23</summary>

This recorded result checked text/source consistency only. It did not run this example or contact Ollama. Runtime behaviour remains unverified.

**File: `Authoring record; not example output`**
```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-1-first-steps/01-what-a-local-llm-is
```

</details>

## Next lesson
[02. Install and check Ollama on your OS](02-install-and-check.md): install natively, then inspect state without accidentally starting the app.
