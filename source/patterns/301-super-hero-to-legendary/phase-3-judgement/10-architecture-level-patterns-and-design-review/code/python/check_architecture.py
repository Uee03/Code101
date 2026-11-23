import ast
from pathlib import Path

LAYERS = ("domain", "application", "adapters")
FORBIDDEN = {
    "domain": ("application", "adapters"),
    "application": ("adapters",),
    "adapters": (),
}


def imported_layers(source):
    found = []
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.Import):
            names = [alias.name for alias in node.names]
        elif isinstance(node, ast.ImportFrom):
            names = [node.module or ""]
        else:
            continue
        for name in names:
            top = name.split(".")[0]
            if top in LAYERS:
                found.append((top, node.lineno))
    return found


def check_source(layer, source):
    problems = []
    for imported, line in imported_layers(source):
        if imported in FORBIDDEN[layer]:
            problems.append(f"{layer} must not depend on {imported} (line {line})")
    return problems


def check_tree(root):
    files = 0
    problems = []
    for layer in LAYERS:
        for path in sorted((Path(root) / layer).glob("*.py")):
            files += 1
            problems += [f"{path.name}: {p}" for p in check_source(layer, path.read_text(encoding="utf-8"))]
    return files, problems
