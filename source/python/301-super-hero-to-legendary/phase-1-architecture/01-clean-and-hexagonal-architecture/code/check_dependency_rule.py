import ast
from pathlib import Path

INFRASTRUCTURE = ("sqlite3", "sqlalchemy", "fastapi", "requests", "httpx")

FORBIDDEN = {
    "domain.py": ("taskapp.ports", "taskapp.use_cases", "taskapp.adapters") + INFRASTRUCTURE,
    "ports.py": ("taskapp.use_cases", "taskapp.adapters") + INFRASTRUCTURE,
    "use_cases.py": ("taskapp.adapters",) + INFRASTRUCTURE,
}


def imported_modules(source: str) -> set[str]:
    modules: set[str] = set()
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.Import):
            modules.update(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module and node.level == 0:
            modules.add(node.module)
    return modules


def violations(package_dir: Path) -> list[str]:
    found: list[str] = []
    for filename, forbidden in FORBIDDEN.items():
        source = (package_dir / filename).read_text(encoding="utf-8")
        for module in sorted(imported_modules(source)):
            if module.startswith(forbidden):
                found.append(f"{filename} must not import {module}")
    return found


if __name__ == "__main__":
    problems = violations(Path(__file__).parent / "taskapp")
    print("\n".join(problems) if problems else "dependency rule holds")
    raise SystemExit(1 if problems else 0)
