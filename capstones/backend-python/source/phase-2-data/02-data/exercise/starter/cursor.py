"""Exercise 2: an opaque cursor.

A cursor is the position of the last row of a page, hidden inside one string so clients cannot build it.
Finish both functions. Run:  python cursor.py
"""
import base64
import json


def encode_cursor(values):
    # TODO 1: turn the list into compact JSON text (separators=(",", ":")), encode it with
    # base64.urlsafe_b64encode, remove the "=" padding at the end and return the result as a str
    raise NotImplementedError


def decode_cursor(cursor):
    # TODO 2: undo encode_cursor (put the padding back first). Raise ValueError when the text is
    # not valid base64, not valid JSON, or not a JSON list
    raise NotImplementedError


if __name__ == "__main__":
    cursor = encode_cursor(["2026-11-23T08:00:00+00:00", "a11ce000-0000-4000-8000-000000000001"])
    print("cursor:", cursor)
    print("round trip:", decode_cursor(cursor))
    for bad in ("abc", "e30"):  # "e30" is the base64url text of {}
        try:
            decode_cursor(bad)
        except ValueError:
            print("rejected:", bad)
