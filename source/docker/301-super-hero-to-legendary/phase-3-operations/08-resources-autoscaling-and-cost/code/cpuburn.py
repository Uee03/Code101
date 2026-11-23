import time

deadline = time.monotonic() + 60
count = 0
while time.monotonic() < deadline:
    count += 1
print(f"iterations in 60 seconds: {count}", flush=True)
