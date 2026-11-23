import sys

if "--selftest" in sys.argv:
    print("selftest ok")
else:
    print("Hello from an image built in CI", flush=True)
