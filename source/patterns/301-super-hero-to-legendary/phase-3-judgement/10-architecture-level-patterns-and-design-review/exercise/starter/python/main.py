FORBIDDEN = {
    "domain": ["application", "adapters"],
    # TODO 1: add the rule for "application": it must not depend on "adapters".
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
    # TODO 2: print "<layer> imports <names>: ok" when bad is empty, otherwise
    #         "<layer> imports <names>: forbidden (<bad names>)". Join several names with ", ".
    print(layer, imported, bad)
