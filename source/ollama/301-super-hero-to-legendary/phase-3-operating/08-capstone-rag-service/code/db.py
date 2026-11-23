import math
import os
from pathlib import Path

HERE = Path(__file__).resolve().parent
DIMENSIONS = 768


def parse_env(text):
    values = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, _, value = line.partition("=")
        values[name.strip()] = value.strip()
    return values


def settings():
    path = HERE / ".env"
    from_file = parse_env(path.read_text(encoding="utf-8")) if path.exists() else {}
    from_environment = {name: value for name, value in os.environ.items() if name.startswith("POSTGRES_")}
    return {**from_file, **from_environment}


def to_vector_literal(vector, dimensions=DIMENSIONS):
    if len(vector) != dimensions:
        raise ValueError(f"expected {dimensions} dimensions, got {len(vector)}")
    if not all(math.isfinite(x) for x in vector):
        raise ValueError("the vector contains NaN or infinity")
    return "[" + ",".join(repr(float(x)) for x in vector) + "]"


def connect():
    import psycopg

    config = settings()
    missing = [name for name in ("POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DB") if name not in config]
    if missing:
        raise RuntimeError("copy .env.example to .env and set: " + ", ".join(missing))
    return psycopg.connect(
        host="127.0.0.1",
        port=int(config.get("POSTGRES_PORT", "5432")),
        user=config["POSTGRES_USER"],
        password=config["POSTGRES_PASSWORD"],
        dbname=config["POSTGRES_DB"],
        connect_timeout=5,
        autocommit=True,
    )
