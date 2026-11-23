import sys

INSTRUCTIONS = {"FROM", "PARAMETER", "TEMPLATE", "SYSTEM", "LICENSE", "MESSAGE", "REQUIRES", "CAPABILITY"}
PARAMETERS = {
    "num_ctx": int,
    "repeat_last_n": int,
    "repeat_penalty": float,
    "temperature": float,
    "seed": int,
    "stop": str,
    "num_predict": int,
    "top_k": int,
    "top_p": float,
    "min_p": float,
}
ROLES = {"system", "user", "assistant"}


def check_parameter(number, rest, seen, problems):
    name, _, value = rest.strip().partition(" ")
    value = value.strip()
    if name not in PARAMETERS:
        problems.append(f"line {number}: unknown parameter {name!r}")
        return
    if name != "stop" and name in seen:
        problems.append(f"line {number}: parameter {name!r} is set twice")
    seen.add(name)
    kind = PARAMETERS[name]
    if kind is not str:
        try:
            kind(value)
        except ValueError:
            problems.append(f"line {number}: {name} needs a {kind.__name__}, got {value!r}")


def lint(text):
    problems = []
    seen = set()
    has_from = False
    in_block = False
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if in_block:
            if line.endswith('"""'):
                in_block = False
            continue
        if not line or line.startswith("#"):
            continue
        word, _, rest = line.partition(" ")
        word = word.upper()
        if word not in INSTRUCTIONS:
            problems.append(f"line {number}: unknown instruction {word!r}")
            continue
        if rest.count('"""') == 1:
            in_block = True
        if word == "FROM":
            has_from = True
        elif word == "PARAMETER":
            check_parameter(number, rest, seen, problems)
        elif word == "MESSAGE":
            role = rest.split(" ")[0]
            if role not in ROLES:
                problems.append(f"line {number}: MESSAGE role must be one of {sorted(ROLES)}")
    if not has_from:
        problems.append("no FROM instruction")
    if in_block:
        problems.append("a triple-quoted block is never closed")
    return problems


def main():
    if len(sys.argv) != 2:
        print("usage: python modelfile_lint.py <Modelfile>")
        raise SystemExit(2)
    path = sys.argv[1]
    with open(path, encoding="utf-8") as handle:
        problems = lint(handle.read())
    if not problems:
        print(f"{path}: OK")
        return
    for problem in problems:
        print(f"{path}: {problem}")
    raise SystemExit(1)


if __name__ == "__main__":
    main()
