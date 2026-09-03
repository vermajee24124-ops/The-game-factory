from __future__ import annotations

import ast
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_PATTERNS = ("BEGIN PRIVATE KEY", "ghp_", "github_pat_", "AIza")
TEXT_SUFFIXES = {".py", ".yml", ".yaml", ".json", ".md", ".txt", ".toml", ".cfg", ".ini"}


def _scan_for_leaks() -> None:
    validator = Path(__file__).resolve()
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts or path.resolve() == validator:
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if any(pattern in text for pattern in FORBIDDEN_PATTERNS):
            raise SystemExit(f"Potential credential material found in tracked file: {path}")


def _compile_python() -> None:
    for path in [ROOT / "main.py", *sorted((ROOT / "factory").glob("*.py"))]:
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))


def main() -> int:
    required = [
        "main.py",
        ".github/workflows/game-factory.yml",
        "requirements.txt",
        "factory/config.py",
        "factory/bible.py",
        "factory/cli.py",
    ]
    missing = [p for p in required if not (ROOT / p).exists()]
    if missing:
        raise SystemExit(f"Missing required files: {missing}")

    registry = ROOT / "project_registry" / "projects.json"
    try:
        data = json.loads(registry.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit("Project registry is missing or invalid") from exc
    if not isinstance(data, dict) or not isinstance(data.get("projects"), list):
        raise SystemExit("Project registry must contain a projects list")

    _scan_for_leaks()
    _compile_python()
    print("Repository validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
