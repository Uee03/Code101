"""Exercise 2: an opaque cursor (solution).

Run:  python cursor.py
"""
import base64
import json


def encode_cursor(values):
    raw = json.dumps(values, separators=(",", ":"))
    return base64.urlsafe_b64encode(raw.encode()).rstrip(b"=").decode()


def decode_cursor(cursor):
    values = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
    if not isinstance(values, list):
        raise ValueError("a cursor holds a list")
    return values


if __name__ == "__main__":
    cursor = encode_cursor(["2026-11-23T08:00:00+00:00", "a11ce000-0000-4000-8000-000000000001"])
    print("cursor:", cursor)
    print("round trip:", decode_cursor(cursor))
    for bad in ("abc", "e30"):  # "e30" is the base64url text of {}
        try:
            decode_cursor(bad)
        except ValueError:
            print("rejected:", bad)
