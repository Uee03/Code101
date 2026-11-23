import argparse
import csv
import json
import statistics
import time
from pathlib import Path

from ollama_http import get_json, post_json, post_stream, run_cli

HERE = Path(__file__).resolve().parent
FIELDS = ["model", "prompt_id", "run", "total_s", "first_token_s", "tokens", "tokens_per_s", "passed", "gpu_share"]
COLUMNS = ["model", "cold_start_s", "total_s", "first_token_s", "tokens_per_s", "pass_rate", "gpu_share"]


def passes(reply, must_contain):
    text = reply.lower()
    return all(fragment.lower() in text for fragment in must_contain)


def median(values):
    values = [v for v in values if v is not None]
    return statistics.median(values) if values else None


def cell(value, digits=2, percent=False):
    if value is None:
        return "n/a"
    if percent:
        return f"{value * 100:.0f}%"
    return f"{value:.{digits}f}"


def timed_chat(model, prompt, options):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "stream": True,
        "options": options,
    }
    start = time.perf_counter()
    first = None
    parts = []
    final = {}
    for chunk in post_stream("/api/chat", body):
        piece = chunk.get("message", {}).get("content", "")
        if piece and first is None:
            first = time.perf_counter() - start
        parts.append(piece)
        if chunk.get("done"):
            final = chunk
    total = time.perf_counter() - start
    eval_seconds = final.get("eval_duration", 0) / 1e9
    tokens = final.get("eval_count", 0)
    return {
        "reply": "".join(parts),
        "total_s": total,
        "first_token_s": first,
        "tokens": tokens,
        "tokens_per_s": tokens / eval_seconds if eval_seconds > 0 else None,
    }


def unload(model):
    post_json("/api/chat", {"model": model, "keep_alive": 0}, timeout=60)


def gpu_share(model):
    for item in get_json("/api/ps").get("models", []):
        if item.get("model") == model or item.get("name") == model:
            size = item.get("size") or 0
            return (item.get("size_vram") or 0) / size if size else None
    return None


def describe(model):
    details = post_json("/api/show", {"model": model}, timeout=30).get("details", {})
    print(f"{model}: parameter_size={details.get('parameter_size')} quantization={details.get('quantization_level')}")


def measure_model(model, prompts, options, runs):
    unload(model)
    cold = timed_chat(model, prompts[0]["prompt"], options)
    share = gpu_share(model)
    rows = []
    for prompt in prompts:
        for run in range(1, runs + 1):
            result = timed_chat(model, prompt["prompt"], options)
            rows.append({
                "model": model,
                "prompt_id": prompt["id"],
                "run": run,
                "total_s": result["total_s"],
                "first_token_s": result["first_token_s"],
                "tokens": result["tokens"],
                "tokens_per_s": result["tokens_per_s"],
                "passed": passes(result["reply"], prompt["must_contain"]),
                "gpu_share": share,
            })
    unload(model)
    return cold["total_s"], rows


def summarise(models, rows, cold):
    table = []
    for model in models:
        mine = [row for row in rows if row["model"] == model]
        if not mine:
            continue
        table.append({
            "model": model,
            "cold_start_s": cold[model],
            "total_s": median(row["total_s"] for row in mine),
            "first_token_s": median(row["first_token_s"] for row in mine),
            "tokens_per_s": median(row["tokens_per_s"] for row in mine),
            "pass_rate": sum(1 for row in mine if row["passed"]) / len(mine),
            "gpu_share": mine[0]["gpu_share"],
        })
    return table


def print_table(table):
    print(" | ".join(COLUMNS))
    for row in table:
        print(" | ".join([
            row["model"],
            cell(row["cold_start_s"]),
            cell(row["total_s"]),
            cell(row["first_token_s"]),
            cell(row["tokens_per_s"], 1),
            cell(row["pass_rate"], percent=True),
            cell(row["gpu_share"], percent=True),
        ]))


def main():
    parser = argparse.ArgumentParser(description="Time and screen several models on the same prompts.")
    parser.add_argument("--models", nargs="*", help="override the models in models.json")
    parser.add_argument("--runs", type=int, help="override the number of timed runs per prompt")
    parser.add_argument("--out", default="results.csv")
    args = parser.parse_args()
    config = json.loads((HERE / "models.json").read_text(encoding="utf-8"))
    prompts = json.loads((HERE / "prompts.json").read_text(encoding="utf-8"))
    models = args.models or config["models"]
    runs = args.runs or config["runs"]
    installed = {item["name"] for item in get_json("/api/tags").get("models", [])}
    print("ollama version:", get_json("/api/version").get("version"))
    print("options:", json.dumps(config["options"]))
    all_rows = []
    cold = {}
    measured = []
    for model in models:
        if model not in installed:
            print(f"not downloaded, skipped: {model} (run: ollama pull {model})")
            continue
        describe(model)
        cold[model], rows = measure_model(model, prompts, config["options"], runs)
        all_rows.extend(rows)
        measured.append(model)
    with open(args.out, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(all_rows)
    print_table(summarise(measured, all_rows, cold))
    print(f"rows written to {args.out}")


if __name__ == "__main__":
    run_cli(main)
