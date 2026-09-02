from __future__ import annotations

import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_PATTERNS = ("BEGIN PRIVATE KEY", "ghp_", "github_pat_", "AIza")


def main() -> int:
    required = ["main.py", ".github/workflows/game-factory.yml", "requirements.txt", "factory/config.py"]
    missing = [p for p in required if not (ROOT / p).exists()]
    if missing:
        raise SystemExit(f"Missing required files: {missing}")

    # Scan text files for obvious credential leakage without printing matches.
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        if path.suffix.lower() not in {".py", ".yml", ".yaml", ".json", ".md", ".txt", ".toml"}:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if any(pattern in text for pattern in FORBIDDEN_PATTERNS):
            raise SystemExit(f"Potential credential material found in tracked file: {path}")

    compile((ROOT / "main.py").read_text(encoding="utf-8"), "main.py", "exec")
    print("Repository validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
