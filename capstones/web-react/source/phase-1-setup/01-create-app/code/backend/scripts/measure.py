#!/usr/bin/env python3
"""Time some sequential GET requests and print the median, the 95th percentile and the slowest.

  python scripts/measure.py /v1/projects/<project id>/tasks --user bob --count 25
"""
import argparse
import statistics
import time
import urllib.request

from call import API_URL, get_token


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path")
    parser.add_argument("--user", default="bob")
    parser.add_argument("--count", type=int, default=25)
    args = parser.parse_args()
    headers = {"Authorization": f"Bearer {get_token(args.user)}"}
    milliseconds = []
    for _ in range(args.count):
        started = time.perf_counter()
        with urllib.request.urlopen(urllib.request.Request(API_URL + args.path, headers=headers)) as response:
            response.read()
        milliseconds.append((time.perf_counter() - started) * 1000)
    milliseconds.sort()
    p95 = milliseconds[min(len(milliseconds) - 1, int(len(milliseconds) * 0.95))]
    print(f"{args.count} requests to {args.path} as {args.user}: median {statistics.median(milliseconds):.1f} ms, "
          f"p95 {p95:.1f} ms, slowest {milliseconds[-1]:.1f} ms")


if __name__ == "__main__":
    main()
