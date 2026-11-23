FORBIDDEN = {
    "domain": ["application", "adapters"],
    "application": ["adapters"],
}


def violations(layer, imported):
    return [name for name in imported if name in FORBIDDEN.get(layer, [])]


SAMPLES = [
    ("domain", ["application"]),
    ("application", ["domain"]),
    ("application", ["adapters"]),
    ("adapters", ["application", "domain"]),
]

for layer, imported in SAMPLES:
    bad = violations(layer, imported)
    names = ", ".join(imported)
    if bad:
        print(f"{layer} imports {names}: forbidden ({', '.join(bad)})")
    else:
        print(f"{layer} imports {names}: ok")
