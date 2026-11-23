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
    # TODO 1: return how many ast.If nodes are inside the function (ast.walk visits every node).
    return 0


for node in ast.parse(SOURCE).body:
    if isinstance(node, ast.FunctionDef):
        branches = count_branches(node)
        # TODO 2: print "<name>: branches=<n> -> too many branches" when branches is above MAX_BRANCHES,
        #         otherwise "<name>: branches=<n> -> ok".
        print(f"{node.name}: branches={branches}")
