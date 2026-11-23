---
track: ollama
level: 101
phase: 2
phase_name: building-with-ollama
lesson: 07
title: 'Embeddings and a tiny semantic search'
time: '70-85 min plus download'
prerequisites: [101.2.06]
versions: { ollama: 'current native stable; docs checked 2026-11-23', python: '3.12 or newer' }
verified: not yet run
source: source/ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search/
assets: []
---

# 07. Embeddings and a tiny semantic search

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Request one embedding per input string from the current `/api/embed` endpoint.
- Compute cosine similarity in plain Python and explain why it is not a probability.
- Rank ten sentences by meaning while keeping model and task prefixes consistent.


## Recap
1. Does valid JSON guarantee a correct factual answer?
   <details><summary>Answer</summary>No. Validate shape and check meaning separately.</details>
2. What is the difference between downloading a model and loading it?
   <details><summary>Answer</summary>Downloading stores weights on disk; loading uses working memory for inference.</details>
3. Why do the Python clients use fixed loopback URLs and no proxy forwarding?
   <details><summary>Answer</summary>To keep their local requests local and avoid an environment proxy forwarding the request elsewhere.</details>


## Why it matters
A library can group books by subject even when their titles use different words. An **embedding** is a list of numbers representing aspects of meaning so we can compare text numerically. Instead of asking a model to invent an answer, we will choose the most similar sentences from a tiny existing collection.


## What you will build
A semantic search over exactly ten public, invented sentences. **Semantic search** compares meaning rather than just matching identical words. The program sends ten document strings in one batch, one query in a second request, computes cosine similarity and prints the top three original sentences. It does not generate an explanation or need a vector database.


## Before you start
- Time: 70-85 minutes plus the new model download. Two sittings are fine; pause after Step 3. Finish lesson 06 and Python 101.
- Python 3.12+, native server on loopback, internet and permission for a model download.
- Checked **2026-11-23**: https://ollama.com/library/nomic-embed-text lists **`nomic-embed-text:v1.5`**, about **274 MB** to download. This is an embedding-only model, not a chat model. Memory needs exceed the download alone; CPU-only is allowed.
- We use the current `/api/embed` endpoint, not the older singular-result `/api/embeddings` examples in some model-page readmes. The current API is authoritative for the request/response fields.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished example, exercise starter and solution are in https://github.com/Uee03/Code101 under `source/ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search/`. Choose **Code > Download ZIP**, or use `git clone https://github.com/Uee03/Code101.git` if you already use Git.
- To extract a ZIP: Windows, right-click > **Extract All > Extract**; macOS, double-click; Linux, right-click > **Extract Here** in your archive manager. Open `Code101-main`, then the source path above. A phase ZIP instead starts with its phase-pack folder.
- Model responses below are documented **shapes**, not captured output. Answers, timings and streaming chunk boundaries vary.

## Steps
### Step 1. Prepare a workspace, check health and download deliberately

A **terminal** is a window for typing commands. Windows: Start > type **PowerShell** > open it, not Python. macOS: Applications > Utilities > **Terminal**. Linux: open **Terminal** from your applications menu. Do not type the prompt's leading `>` or `$`. The text before that symbol usually shows the current folder.

Create a separate practice folder. `$HOME` (PowerShell) and `~` (macOS/Linux) mean your home folder. These commands start in any folder; the second line is also your recovery command if you get lost.

**File: `Terminal, Windows PowerShell; starting anywhere`**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/ollama07" -Force | Out-Null
Set-Location "$HOME/code101/ollama07"
```

**File: `Terminal, macOS/Linux; starting anywhere`**
```bash
mkdir -p ~/code101/ollama07
cd ~/code101/ollama07
```
Expected result, not yet run: the folder exists and the terminal is inside it; these commands normally print nothing.
Use a plain-text editor for files below. Windows: Notepad, **Save As**, choose **All files**, UTF-8; turn on File Explorer **View > Show > File name extensions** so `.json` does not become `.json.txt`. macOS: TextEdit > **Format > Make Plain Text**, disable smart quotes and automatic `.txt` extension. Linux: your plain-text Text Editor. An existing VS Code install is also fine: **File > Open Folder**, select this folder, then **Terminal > New Terminal**. A dot on an editor tab means unsaved; save with Ctrl+S (macOS Cmd+S). No editor extension or account is needed.

Check health without auto-starting the app and check free space on the model-storage drive (lesson 03 lists defaults).

**File: `Windows PowerShell; folder ~/code101/ollama07`**
```powershell
Invoke-RestMethod -Uri http://127.0.0.1:11434/api/version -TimeoutSec 5
Get-PSDrive -PSProvider FileSystem
```

**File: `macOS/Linux terminal; folder ~/code101/ollama07`**
```bash
curl --fail --show-error --silent --max-time 5 http://127.0.0.1:11434/api/version
df -h ~
```
If no server answers, use lesson 02's deliberate start route, then repeat the health check. After checking space and approving the new download, enter:

**File: `Terminal, any OS; folder ~/code101/ollama07`**
```text
ollama pull nomic-embed-text:v1.5
```
Expected result, not yet run: the embedding tag is stored locally. Exact progress text varies. Do not use `ollama run` to chat with this model; it represents text as numbers rather than generating answers.

### Step 2. Create exactly ten searchable sentences
Save the full collection below as `sentences.json`. The list order connects each returned document vector to its source sentence. A **vector** is an ordered list of numbers; a **dimension** is one position in that list. A **query** is the text the user searches for. A **batch** sends several inputs in one request.

**File: `~/code101/ollama07/sentences.json`**
```json
[
  "The library lends books for three weeks.",
  "A bicycle pump fills a flat tyre with air.",
  "Water the tomato plants when the soil feels dry.",
  "The train station sells tickets at the blue counter.",
  "Save a copy of your document before editing it.",
  "The swimming pool opens at seven in the morning.",
  "Bread dough rises faster in a warm kitchen.",
  "A strong password should be unique to each account.",
  "The museum displays paintings by local artists.",
  "A raincoat helps you stay dry in wet weather."
]
```

These are invented practice facts, not claims about your actual library or train station. Never replace them with private documents for this exercise.

### Step 3. Understand cosine similarity with two arrows
Imagine two arrows from the same starting point. **Cosine similarity** measures how closely their directions align. For lists `a` and `b`, multiply corresponding numbers and sum them (the **dot product**). Divide by the product of their lengths, where each length is the square root of the sum of squared entries. Identical nonzero directions give 1; perpendicular directions give 0; opposite directions give -1, ignoring tiny floating-point rounding effects.

Predict before running any program: vectors `[1, 0]` and `[1, 0]` have dot product 1 and both lengths 1. What score follows? The arithmetic gives 1. In contrast, `[1, 0]` and `[0, 1]` give 0. These are mathematical examples, **not** embeddings captured from this model. A zero-length vector cannot be divided by; unequal dimensions cannot be compared.

A similarity score is **not a probability or a truth score**. Even the best match can be irrelevant if the collection has no useful answer. We rank candidates and show their source text; a human decides whether they answer the query.

### Step 4. Create the complete search program
Save this full file beside `sentences.json`. It uses only Python's standard library. `math` provides square roots and finite-number checks; no NumPy or embedding SDK is installed.

**File: `~/code101/ollama07/search.py`**
```python
import json
import math
import urllib.error
import urllib.request
from pathlib import Path

MODEL = "nomic-embed-text:v1.5"
TOP_K = 3


def embed(texts):
    body = {"model": MODEL, "input": texts, "truncate": False}
    request = urllib.request.Request(
        "http://127.0.0.1:11434/api/embed",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        data = json.load(response)
    vectors = data["embeddings"]
    if not isinstance(vectors, list) or len(vectors) != len(texts):
        raise ValueError("Wrong vector count")
    for vector in vectors:
        if not isinstance(vector, list) or not vector:
            raise ValueError("Empty vector")
        if not all(type(x) in (int, float) and math.isfinite(x) for x in vector):
            raise ValueError("Invalid vector")
    return vectors


def cosine(left, right):
    if not left or len(left) != len(right):
        raise ValueError("Incompatible vectors")
    dot = sum(a * b for a, b in zip(left, right))
    left_length = math.sqrt(sum(a * a for a in left))
    right_length = math.sqrt(sum(b * b for b in right))
    if left_length == 0 or right_length == 0:
        raise ValueError("Zero vector")
    return dot / (left_length * right_length)


def main():
    path = Path(__file__).with_name("sentences.json")
    sentences = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(sentences, list) or len(sentences) != 10:
        raise ValueError("Use exactly ten sentences")
    if not all(isinstance(s, str) and 0 < len(s) <= 300 for s in sentences):
        raise ValueError("Invalid sentence")
    query = input("Search (public or invented text only): ").strip()
    if not query or len(query) > 300:
        print("Use 1 to 300 characters; nothing sent.")
        return
    documents = embed(["search_document: " + s for s in sentences])
    question = embed(["search_query: " + query])[0]
    ranked = [(cosine(question, vector), sentence)
              for sentence, vector in zip(sentences, documents)]
    ranked.sort(key=lambda item: item[0], reverse=True)
    for score, sentence in ranked[:TOP_K]:
        print(f"{score:.3f} | {sentence}")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the embedding model.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection or file access failed; check Ollama and sentences.json.")
    except (ValueError, KeyError, TypeError, AttributeError, OverflowError):
        print("Invalid data or vectors; no ranking accepted.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
```

`embed` POSTs `model`, `input` (a list of strings) and `truncate: False`. The last setting asks the server to reject overlong inputs rather than silently shortening them. These sentences and the query are deliberately short. The result field is **`embeddings`**, a list containing one vector per input, in input order. Even one string input returns a list of vectors. Count/type/finite checks reject malformed results; `cosine` rejects empty, unequal or zero-length vectors.

The model author's [task-prefix instructions](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5) require `search_document: ` for stored text and `search_query: ` for a query. Those prefixes tell this model how each text is used. They are model-specific, not a universal `/api/embed` requirement. We use the same checked embedding model and vector dimensions for both requests. Do not mix vectors from different models or compare chat tokens with embedding coordinates.

`ranked` stores pairs of score and original sentence. Sorting with `reverse=True` puts larger scores first; `[:TOP_K]` selects the top three. The program prints original collection text, **not** generated model prose. It rebuilds vectors on each run to keep the example small and stateless; caching safely is a later design problem, not an unexplained dependency.


## Run it
Use the terminal branch for your OS, then enter `How do I put air in my bike wheel?` at the search prompt.

**File: `Windows PowerShell; starting anywhere`**
```powershell
Set-Location "$HOME/code101/ollama07"
python search.py
```

**File: `macOS/Linux terminal; starting anywhere`**
```bash
cd ~/code101/ollama07
python3 search.py
```
Expected behaviour, not yet run: three lines, each a score rounded to three decimal places, `|`, and one of the ten source sentences. Ranking and scores may vary with model/runtime versions. The bike sentence is a sensible relevance check, **not a guaranteed first result**. If the results are poor, inspect the model/prefixes and source data instead of asserting an exact answer.

**File: `Printed ranking SHAPE only; placeholders are not literal output`**
```text
<score to 3 decimal places> | <one original sentence>
<score to 3 decimal places> | <one original sentence>
<score to 3 decimal places> | <one original sentence>
```
The program consumes this documented API shape; number of coordinates is determined by the model, not this shortened illustration:

**File: `/api/embed response SHAPE; one vector per input`**
```text
{
  "model": "nomic-embed-text:v1.5",
  "embeddings": [[<number>, <number>, ...], ...],
  "total_duration": <integer nanoseconds>,
  "prompt_eval_count": <integer token count>
}
```
This is shape notation, not valid JSON to paste into a request. Answers and model-derived numbers vary. To inspect placement after search, and only while the server is already running, enter `ollama ps` in the same folder/terminal; use lesson 03's PROCESSOR categories, not an assumed GPU.


## How it works
Ten documents and one query become vectors in the same learned coordinate space. Task prefixes differentiate their purposes. The cosine formula compares direction; the ranking preserves the original sentences for inspection. Most common misconception: **embeddings are short generated answers or encoded truth**. They are learned numerical representations; they can be biased, weak on your domain and poor at exact numbers or negations.


## Try it
**Guided:** complete the cosine division in the starter, using the dot product and the two lengths already computed. Keep the existing guard checks. Without a pack, create `~/code101/ollama07/exercise`, save the starter `search.py` below and copy `sentences.json` from Step 2 **unchanged** alongside it. With a pack, copy `07-embeddings-search/exercise/starter` itself into `ollama07`, rename it `exercise`. The resulting folder contains the two files directly, not another `starter` folder.

**File: `~/code101/ollama07/exercise/search.py`**
```python
import json
import math
import urllib.error
import urllib.request
from pathlib import Path

MODEL = "nomic-embed-text:v1.5"
TOP_K = 3


def embed(texts):
    body = {"model": MODEL, "input": texts, "truncate": False}
    request = urllib.request.Request(
        "http://127.0.0.1:11434/api/embed",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        data = json.load(response)
    vectors = data["embeddings"]
    if not isinstance(vectors, list) or len(vectors) != len(texts):
        raise ValueError("Wrong vector count")
    for vector in vectors:
        if not isinstance(vector, list) or not vector:
            raise ValueError("Empty vector")
        if not all(type(x) in (int, float) and math.isfinite(x) for x in vector):
            raise ValueError("Invalid vector")
    return vectors


def cosine(left, right):
    if not left or len(left) != len(right):
        raise ValueError("Incompatible vectors")
    dot = sum(a * b for a, b in zip(left, right))
    left_length = math.sqrt(sum(a * a for a in left))
    right_length = math.sqrt(sum(b * b for b in right))
    if left_length == 0 or right_length == 0:
        raise ValueError("Zero vector")
    return 0.0  # TODO: divide the dot product by both vector lengths.


def main():
    path = Path(__file__).with_name("sentences.json")
    sentences = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(sentences, list) or len(sentences) != 10:
        raise ValueError("Use exactly ten sentences")
    if not all(isinstance(s, str) and 0 < len(s) <= 300 for s in sentences):
        raise ValueError("Invalid sentence")
    query = input("Search (public or invented text only): ").strip()
    if not query or len(query) > 300:
        print("Use 1 to 300 characters; nothing sent.")
        return
    documents = embed(["search_document: " + s for s in sentences])
    question = embed(["search_query: " + query])[0]
    ranked = [(cosine(question, vector), sentence)
              for sentence, vector in zip(sentences, documents)]
    ranked.sort(key=lambda item: item[0], reverse=True)
    for score, sentence in ranked[:TOP_K]:
        print(f"{score:.3f} | {sentence}")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the embedding model.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection or file access failed; check Ollama and sentences.json.")
    except (ValueError, KeyError, TypeError, AttributeError, OverflowError):
        print("Invalid data or vectors; no ranking accepted.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
```

**File: `Windows PowerShell`**
```powershell
Set-Location "$HOME/code101/ollama07/exercise"
python search.py
```

**File: `macOS/Linux terminal`**
```bash
cd ~/code101/ollama07/exercise
python3 search.py
```
Goal: rank by computed similarity, not a constant score. Check the arithmetic example by hand before interpreting model-derived rankings.
**Change:** change `TOP_K` from 3 to 2; the displayed ranking should contain two lines, with variable scores/order. Keep exactly ten sentences. **Stretch (optional):** propose a way to say “no useful match” and explain why a threshold needs evidence from real queries, not a random number.

<details><summary>Guided solution</summary>

**File: `~/code101/ollama07/exercise/search.py`**
```python
import json
import math
import urllib.error
import urllib.request
from pathlib import Path

MODEL = "nomic-embed-text:v1.5"
TOP_K = 3


def embed(texts):
    body = {"model": MODEL, "input": texts, "truncate": False}
    request = urllib.request.Request(
        "http://127.0.0.1:11434/api/embed",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        data = json.load(response)
    vectors = data["embeddings"]
    if not isinstance(vectors, list) or len(vectors) != len(texts):
        raise ValueError("Wrong vector count")
    for vector in vectors:
        if not isinstance(vector, list) or not vector:
            raise ValueError("Empty vector")
        if not all(type(x) in (int, float) and math.isfinite(x) for x in vector):
            raise ValueError("Invalid vector")
    return vectors


def cosine(left, right):
    if not left or len(left) != len(right):
        raise ValueError("Incompatible vectors")
    dot = sum(a * b for a, b in zip(left, right))
    left_length = math.sqrt(sum(a * a for a in left))
    right_length = math.sqrt(sum(b * b for b in right))
    if left_length == 0 or right_length == 0:
        raise ValueError("Zero vector")
    return dot / (left_length * right_length)


def main():
    path = Path(__file__).with_name("sentences.json")
    sentences = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(sentences, list) or len(sentences) != 10:
        raise ValueError("Use exactly ten sentences")
    if not all(isinstance(s, str) and 0 < len(s) <= 300 for s in sentences):
        raise ValueError("Invalid sentence")
    query = input("Search (public or invented text only): ").strip()
    if not query or len(query) > 300:
        print("Use 1 to 300 characters; nothing sent.")
        return
    documents = embed(["search_document: " + s for s in sentences])
    question = embed(["search_query: " + query])[0]
    ranked = [(cosine(question, vector), sentence)
              for sentence, vector in zip(sentences, documents)]
    ranked.sort(key=lambda item: item[0], reverse=True)
    for score, sentence in ranked[:TOP_K]:
        print(f"{score:.3f} | {sentence}")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the embedding model.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection or file access failed; check Ollama and sentences.json.")
    except (ValueError, KeyError, TypeError, AttributeError, OverflowError):
        print("Invalid data or vectors; no ranking accepted.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
```

`sentences.json` is exactly the complete file from Step 2, unchanged. Both source exercise folders include it. Dividing by both lengths prevents vector magnitude alone from controlling the score.
</details>


## Check yourself
1. If input contains ten strings, how many vectors should embeddings contain?
   <details><summary>Answer</summary>Ten, in input order. A query-only request still returns an outer list containing one vector.</details>
2. Predict the cosine of `[1, 0]` and `[0, 1]`. Is that number a probability?
   <details><summary>Answer</summary>Zero: their dot product is zero and both lengths are one. Cosine is a direction similarity, not a probability.</details>
3. Why use the same embedding model with distinct document/query prefixes?
   <details><summary>Answer</summary>Vectors must share the same learned coordinate space; the model-specific prefixes express each input's search task. Different model vectors are not interchangeable.</details>


## Common mistakes
| Symptom or typical message, not captured | Cause | Fix |
|---|---|---|
| Own client says connection or file access failed | Server stopped, wrong filename, missing JSON file | Check health; place saved sentences.json next to search.py with no extra `.txt`. |
| Typical Python syntax/indentation error | Altered colon, bracket or indentation | Compare the full file and save four-space indentation. |
| HTTP failure after switching models | Chat tag used for embeddings, missing embedding tag or wrong endpoint | Pull the checked embedding tag deliberately and use /api/embed with input. |
| Wrong count, empty or incompatible vectors | Data shape/model mismatch | Stop; validate input count and use one model/dimensionality for all vectors. |
| All scores tie in the starter | TODO still returns a constant | Complete the cosine formula, not the sorting code. |
| Poor semantic ranking | Missing prefixes, irrelevant corpus or model limits | Use the documented prefixes and inspect the original sentences; don't treat a score as correctness. |


## Best practice
Use the same embedding model for the texts being compared and follow its documented task-input format. Source: Ollama embed API https://docs.ollama.com/api/embed and Nomic model author's task-prefix instructions https://huggingface.co/nomic-ai/nomic-embed-text-v1.5


## Going further
A larger search system might cache vectors and retrieve documents before asking a chat model for a sourced response. This exercise is **retrieval only**, not that complete system. Never assume embeddings anonymise private text: vectors can reveal information too.


## Summary
- You prepared current /api/embed requests with one vector per input.
- You used a guarded cosine calculation and separated similarity from truth/probability.
- You designed a ten-sentence meaning-based ranking with consistent task prefixes.


<details><summary>Draft text/source consistency record, 2026-11-23</summary>

This recorded result checked text/source consistency only. It did not run this example or contact Ollama. Runtime behaviour remains unverified.

**File: `Authoring record; not example output`**
```text
[STATIC    ] source/ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search
```

</details>

## Next lesson
[08. Project: a conversation assistant](08-conversation-assistant.md): return to chat, retain bounded in-memory history and package behaviour in a native Modelfile.
