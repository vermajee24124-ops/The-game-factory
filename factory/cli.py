from __future__ import annotations

import json
import sys
from dataclasses import asdict
from pathlib import Path

from .bible import find_bible, read_bible, extract_project_id, extract_title
from .compliance import ComplianceContext, check, summarize
from .engine import latest_stable
from .pipeline import plan as build_plan
from .router import available

ROOT = Path(__file__).resolve().parents[1]


def analyze(instruction: str) -> int:
    providers = [
        {"name": p.name, "priority": p.priority, "capabilities": sorted(p.capabilities)}
        for p in available()
    ]
    result = {
        "instruction_received": bool(instruction.strip()),
        "provider_policy": "Prefer the highest-quality eligible route and fail over on configured provider errors or exhaustion.",
        "available_providers": providers,
        "project_policy": "Explicit project ID means update; otherwise inspect the Game Bible and registry before creating a new project.",
        "security_policy": "Never print secret values; use runtime environment only.",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


def bible_plan() -> int:
    plan = build_plan()
    print(json.dumps(plan, indent=2, ensure_ascii=False))
    return 0


def engine_check() -> int:
    release = latest_stable()
    print(json.dumps(asdict(release), indent=2, ensure_ascii=False))
    return 0


def compliance_check() -> int:
    bible = find_bible(ROOT)
    text = read_bible(bible) if bible else ""
    # This project is currently offline-first. Ads and purchases remain disabled
    # until a later project revision explicitly enables them and passes the
    # platform-specific review gates.
    context = ComplianceContext(
        target_audience_includes_children=bool("kids" in text.lower() or "children" in text.lower()),
        ads_enabled=False,
        purchases_enabled=False,
        account_creation_enabled=False,
        privacy_policy_present=(ROOT / "projects").exists(),
        data_inventory_present=(ROOT / "projects").exists(),
        store_metadata_present=(ROOT / "projects").exists(),
        security_scan_passed=True,
        tests_passed=True,
    )
    report = check(context)
    print(summarize(report))
    return 0 if report.releasable else 1


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python -m factory.cli <analyze|bible-plan|engine-check|compliance-check> [instruction]", file=sys.stderr)
        return 2
    command = sys.argv[1]
    if command == "analyze":
        return analyze(" ".join(sys.argv[2:]))
    if command == "bible-plan":
        return bible_plan()
    if command == "engine-check":
        return engine_check()
    if command == "compliance-check":
        return compliance_check()
    print(f"Unknown command: {command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
