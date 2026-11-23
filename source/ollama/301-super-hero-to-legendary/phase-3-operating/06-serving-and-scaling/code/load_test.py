import argparse
import csv
import json
import time
import urllib.error
from concurrent.futures import ThreadPoolExecutor

from ollama_http import get_json, post_json, run_cli
from stats import summarise

MAX_REQUESTS = 40
MAX_CONCURRENCY = 8
PROMPT = "Write one short sentence about the sea."
FIELDS = ["label", "concurrency", "requests", "ok", "statuses", "p50_s", "p95_s", "max_s", "requests_per_s", "tokens_per_s"]


def request_body(model):
    return {
        "model": model,
        "messages": [{"role": "user", "content": PROMPT}],
        "stream": False,
        "options": {"temperature": 0, "num_predict": 40},
    }


def one_request(model, timeout):
    started = time.perf_counter()
    try:
        data = post_json("/api/chat", request_body(model), timeout=timeout)
        return {"status": 200, "seconds": time.perf_counter() - started, "tokens": data.get("eval_count", 0)}
    except urllib.error.HTTPError as error:
        return {"status": error.code, "seconds": time.perf_counter() - started, "tokens": 0}
    except OSError:
        return {"status": "error", "seconds": time.perf_counter() - started, "tokens": 0}


def run_level(model, concurrency, total, timeout):
    started = time.perf_counter()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        results = list(pool.map(lambda _: one_request(model, timeout), range(total)))
    return results, time.perf_counter() - started


def placement(model):
    for item in get_json("/api/ps").get("models", []):
        if item.get("name") == model or item.get("model") == model:
            return {"size": item.get("size"), "size_vram": item.get("size_vram")}
    return None


def format_number(value):
    return "n/a" if value is None else f"{value:.2f}"


def main():
    parser = argparse.ArgumentParser(description="A small, bounded concurrency test for one model.")
    parser.add_argument("--model", default="llama3.2:1b")
    parser.add_argument("--levels", type=int, nargs="+", default=[1, 2, 4], help="concurrency levels to try")
    parser.add_argument("--requests", type=int, default=8, help="requests per level")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--label", default="run", help="a name for the server settings you are testing")
    args = parser.parse_args()
    if not 1 <= args.requests <= MAX_REQUESTS:
        raise SystemExit(f"--requests must be between 1 and {MAX_REQUESTS}")
    if any(not 1 <= level <= MAX_CONCURRENCY for level in args.levels):
        raise SystemExit(f"each level must be between 1 and {MAX_CONCURRENCY}")
    print("ollama version:", get_json("/api/version").get("version"))
    print("warm-up request (not counted)...")
    one_request(args.model, args.timeout)
    print("loaded model placement:", placement(args.model))
    rows = []
    for level in args.levels:
        results, wall = run_level(args.model, level, args.requests, args.timeout)
        summary = summarise(results, wall)
        print(
            f"concurrency={level} | requests={summary['requests']} | ok={summary['ok']} | statuses={summary['statuses']} | "
            f"p50={format_number(summary['p50_s'])}s p95={format_number(summary['p95_s'])}s max={format_number(summary['max_s'])}s | "
            f"req/s={format_number(summary['requests_per_s'])} | tokens/s={format_number(summary['tokens_per_s'])}"
        )
        rows.append({"label": args.label, "concurrency": level, **summary, "statuses": json.dumps(summary["statuses"])})
    out = f"load-{args.label}.csv"
    with open(out, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    print(f"rows written to {out}")


if __name__ == "__main__":
    run_cli(main)
