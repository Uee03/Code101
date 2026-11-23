import argparse
import json
import time
from datetime import datetime
from pathlib import Path

import rag_pipeline
import semsearch
from metrics import aggregate, judge, spread
from ollama_http import get_json, run_cli
from rag_core import Settings, answer_question

HERE = Path(__file__).resolve().parent
KS = (1, 3, 6)


def load_golden():
    return json.loads((HERE / "golden.json").read_text(encoding="utf-8"))


def cmd_scores(golden):
    answerable_scores = []
    unanswerable_scores = []
    for entry in golden:
        hits = rag_pipeline.retrieve(entry["question"])
        top = hits[0].score if hits else None
        ranks = [hit.source in entry["gold_sources"] for hit in hits]
        gold_rank = ranks.index(True) + 1 if True in ranks else None
        (answerable_scores if entry["answerable"] else unanswerable_scores).append(top)
        shown = "-" if top is None else f"{top:.3f}"
        print(f"{entry['id']} | {'answerable' if entry['answerable'] else 'unanswerable'} | top={shown} | gold_rank={gold_rank or '-'}")
    print("answerable top scores (min, median, max):", spread(answerable_scores))
    print("unanswerable top scores (min, median, max):", spread(unanswerable_scores))


def run_full(golden, settings):
    records = []
    for entry in golden:
        started = time.perf_counter()
        hits = rag_pipeline.retrieve(entry["question"])
        result = answer_question(entry["question"], lambda question: hits, rag_pipeline.generate, settings)
        record = judge(entry, hits, result)
        record["seconds"] = round(time.perf_counter() - started, 2)
        record["answer"] = result["answer"]
        records.append(record)
    return records


def print_summary(summary):
    print(f"answerable questions: {summary['answerable']}, unanswerable: {summary['unanswerable']}")
    for k, value in summary["hit_rate"].items():
        print(f"hit rate at {k}: {value}")
    print(f"MRR: {summary['mrr']}")
    print(f"correct answers (answered, right text, right source cited): {summary['correct_rate']}")
    print(f"false refusals of answerable questions: {summary['false_refusal_rate']}")
    print(f"correct refusals of unanswerable questions: {summary['refusal_rate']}")
    print(f"unanswerable questions answered anyway: {summary['wrongly_answered']}")
    print(f"score gap (lowest answerable top score, highest unanswerable top score, separable): {summary['score_gap']}")


def print_failures(records):
    for record in records:
        if record["answerable"] and not record["correct"]:
            print(f"FAIL {record['id']}: status={record['status']} rank={record['rank']} text_ok={record['text_ok']} citation_ok={record['citation_ok']}")
        if not record["answerable"] and not record["refused"]:
            print(f"FAIL {record['id']}: an unanswerable question was answered")


def cmd_full(golden, min_score, label):
    settings = Settings(min_score=min_score, max_hits=rag_pipeline.SETTINGS.max_hits,
                        max_context_chars=rag_pipeline.SETTINGS.max_context_chars)
    records = run_full(golden, settings)
    summary = aggregate(records, KS)
    print_summary(summary)
    print_failures(records)
    report = {
        "created": datetime.now().isoformat(timespec="seconds"),
        "label": label,
        "ollama_version": get_json("/api/version").get("version"),
        "embedding_model": semsearch.MODEL,
        "generation_model": rag_pipeline.GENERATION_MODEL,
        "retrieve_k": rag_pipeline.RETRIEVE_K,
        "settings": {"min_score": settings.min_score, "max_hits": settings.max_hits,
                     "max_context_chars": settings.max_context_chars},
        "summary": summary,
        "records": records,
    }
    folder = HERE / "reports"
    folder.mkdir(exist_ok=True)
    path = folder / f"eval-{datetime.now().strftime('%Y%m%d-%H%M%S')}-{label}.json"
    path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"report written to {path.name}")


def main():
    parser = argparse.ArgumentParser(description="Evaluate the RAG pipeline on the golden question set.")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("scores", help="retrieval only: top scores and the rank of the gold source")
    full = commands.add_parser("full", help="retrieval and generation, with a JSON report")
    full.add_argument("--min-score", type=float, default=0.0)
    full.add_argument("--label", default="run")
    args = parser.parse_args()
    golden = load_golden()
    if args.command == "scores":
        cmd_scores(golden)
    else:
        cmd_full(golden, args.min_score, args.label)


if __name__ == "__main__":
    run_cli(main)
