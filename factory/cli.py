from __future__ import annotations

import json
import sys
from pathlib import Path

from .config import available_providers

ROOT = Path(__file__).resolve().parents[1]


def analyze(instruction: str) -> int:
    providers = [
        {"name": p.name, "priority": p.priority, "capabilities": p.capabilities}
        for p in available_providers()
    ]
    result = {
        "instruction_received": bool(instruction.strip()),
        "provider_policy": "prefer highest-priority available provider; fail over on configured transient/provider errors",
        "available_providers": providers,
        "project_policy": "existing project ID means update; otherwise create a new project ID",
        "security_policy": "never print secret values; use CI/runtime environment only",
    }
    print(json.dumps(result, indent=2))
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python -m factory.cli analyze <instruction>", file=sys.stderr)
        return 2
    command = sys.argv[1]
    if command == "analyze":
        return analyze(" ".join(sys.argv[2:]))
    print(f"Unknown command: {command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
