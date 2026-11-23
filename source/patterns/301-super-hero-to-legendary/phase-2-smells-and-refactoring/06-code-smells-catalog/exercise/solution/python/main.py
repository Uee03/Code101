import ast

SOURCE = '''
def price(kind, qty):
    if kind == "a":
        return qty * 3
    elif kind == "b":
        return qty * 4
    elif kind == "c":
        return qty * 5
    return 0


def double(x):
    return x * 2
'''

MAX_BRANCHES = 2


def count_branches(function):
    return sum(isinstance(node, ast.If) for node in ast.walk(function))


for node in ast.parse(SOURCE).body:
    if isinstance(node, ast.FunctionDef):
        branches = count_branches(node)
        verdict = "too many branches" if branches > MAX_BRANCHES else "ok"
        print(f"{node.name}: branches={branches} -> {verdict}")
