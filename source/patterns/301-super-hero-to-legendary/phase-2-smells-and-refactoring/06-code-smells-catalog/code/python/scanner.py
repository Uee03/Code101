import ast
from pathlib import Path

MAX_LINES = 20
MAX_PARAMS = 4
MAX_NESTING = 2
MAX_METHODS = 5


def measure(function, lines):
    start, end = function.lineno, function.end_lineno
    own_lines = [line for line in lines[start - 1:end] if line.strip()]
    def_indent = len(lines[start - 1]) - len(lines[start - 1].lstrip())
    deepest = max(len(line) - len(line.lstrip()) for line in own_lines)
    params = [a.arg for a in function.args.args if a.arg != "self"]
    return {
        "name": function.name,
        "lines": end - start + 1,
        "params": len(params),
        "nesting": max(0, (deepest - def_indent) // 4 - 1),
    }


def scan(path):
    source = Path(path).read_text(encoding="utf-8")
    lines = source.splitlines()
    functions, classes = [], []
    for node in ast.parse(source).body:
        if isinstance(node, ast.FunctionDef):
            functions.append(measure(node, lines))
        elif isinstance(node, ast.ClassDef):
            methods = [m for m in node.body if isinstance(m, ast.FunctionDef) and not m.name.startswith("__")]
            functions.extend(measure(m, lines) for m in methods)
            classes.append((node.name, len(methods)))
    return functions, classes


def flags(measurement):
    found = []
    if measurement["lines"] > MAX_LINES:
        found.append("long method")
    if measurement["params"] > MAX_PARAMS:
        found.append("long parameter list")
    if measurement["nesting"] > MAX_NESTING:
        found.append("deep nesting")
    return found
