import math
from collections import Counter


def percentile(values, p):
    if not values:
        return None
    ordered = sorted(values)
    rank = math.ceil(p / 100 * len(ordered))
    return ordered[max(rank, 1) - 1]


def summarise(results, wall_seconds):
    ok = [result for result in results if result["status"] == 200]
    latencies = [result["seconds"] for result in ok]
    codes = Counter(str(result["status"]) for result in results)
    tokens = sum(result.get("tokens", 0) for result in ok)
    return {
        "requests": len(results),
        "ok": len(ok),
        "statuses": dict(sorted(codes.items())),
        "p50_s": percentile(latencies, 50),
        "p95_s": percentile(latencies, 95),
        "max_s": max(latencies) if latencies else None,
        "requests_per_s": len(ok) / wall_seconds if wall_seconds > 0 else None,
        "tokens_per_s": tokens / wall_seconds if wall_seconds > 0 else None,
    }
