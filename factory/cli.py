from __future__ import annotations

import argparse
import json
from pathlib import Path

from .bible import find_bible, summarize
from .compliance import check_project
from .config import available_providers
from .engine import latest_stable

ROOT = Path(__file__).resolve().parents[1]


def analyze(instruction: str) -> int:
    providers = [
        {"name": p.name, "priority": p.priority, "capabilities": list(p.capabilities)}
        for p in available_providers()
    ]
    result = {
        "instruction_received": bool(instruction.strip()),
        "provider_policy": "prefer the highest-ranked eligible provider and fail over on configured transient/provider errors",
        "available_providers": providers,
        "project_policy": "explicit project ID means update; otherwise resolve by title or create a new project",
        "security_policy": "never print secret values; use runtime/CI secret stores only",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


def bible_plan(path_text: str | None = None) -> int:
    path = Path(path_text) if path_text else find_bible(ROOT)
    if path is None or not path.exists():
        print(json.dumps({"bible_found": False, "message": "No Game Bible found in game_bible/inbox"}, indent=2))
        return 0
    result = summarize(path)
    result["bible_found"] = True
    result["policy"] = "preserve source Bible, resolve project ID, archive the processed Bible, then build/update the project"
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


def engine_check() -> int:
    release = latest_stable()
    print(json.dumps({
        "name": "Godot",
        "latest_stable": release.version,
        "tag": release.tag,
        "published_at": release.published_at,
        "policy": "latest stable compatible version only; no automatic production migration across major versions",
    }, indent=2, ensure_ascii=False))
    return 0


def compliance_check(project_id: str | None = None) -> int:
    report = check_project(ROOT, project_id)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["status"] in {"pass", "not_applicable"} else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="The Game Factory utility CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    analyze_parser = sub.add_parser("analyze", help="Analyze a request")
    analyze_parser.add_argument("instruction", nargs="+", help="Instruction text")

    bible_parser = sub.add_parser("bible-plan", help="Inspect the newest Game Bible")
    bible_parser.add_argument("path", nargs="?", help="Optional Bible path")

    sub.add_parser("engine-check", help="Check the latest stable Godot release")

    compliance_parser = sub.add_parser("compliance-check", help="Run the local project compliance audit")
    compliance_parser.add_argument("--project-id", default=None)

    args = parser.parse_args()

    if args.command == "analyze":
        return analyze(" ".join(args.instruction))
    if args.command == "bible-plan":
        return bible_plan(args.path)
    if args.command == "engine-check":
        return engine_check()
    if args.command == "compliance-check":
        return compliance_check(args.project_id)
    parser.error(f"Unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
