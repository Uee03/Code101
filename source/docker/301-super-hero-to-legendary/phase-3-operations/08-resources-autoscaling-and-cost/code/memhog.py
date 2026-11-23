import time

chunks = []
while True:
    chunks.append(b"x" * (10 * 1024 * 1024))
    print(f"allocated {len(chunks) * 10} MiB", flush=True)
    time.sleep(0.2)
