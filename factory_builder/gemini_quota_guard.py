#!/usr/bin/env python3
"""Reserve a rolling-24-hour Gemini QA slot before calling a model; the API key is never read here."""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LEDGER = ROOT / "game_factory/gemini_usage_ledger.json"

def parse_time(value: str) -> datetime:
    dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)

def run(argv: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(argv, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, check=False, timeout=45)
    if check and result.returncode:
        raise RuntimeError(f"Command failed ({result.returncode}): {argv[0]}\n{result.stdout[-2500:]}")
    return result

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", required=True)
    parser.add_argument("--kind", required=True, choices=("screenshot", "video-audio"))
    parser.add_argument("--max-per-model-24h", type=int, default=8)
    parser.add_argument("--ledger", default=str(DEFAULT_LEDGER.relative_to(ROOT)))
    args = parser.parse_args()
    model = args.model.strip()
    if not model or len(model) > 200 or "\n" in model:
        raise SystemExit("Invalid model identifier.")
    ledger_path = (ROOT / args.ledger).resolve()
    if ROOT not in ledger_path.parents:
        raise SystemExit("Ledger path must remain inside this repository.")
    now = datetime.now(timezone.utc)
    limit = max(1, min(int(args.max_per_model_24h), 20))
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    if ledger_path.exists():
        try:
            ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            raise SystemExit("Gemini usage ledger is invalid; stopping before any Gemini API request.")
    else:
        ledger = {"schema_version": 1, "reservations": []}
    if not isinstance(ledger, dict) or not isinstance(ledger.get("reservations"), list):
        raise SystemExit("Gemini usage ledger schema is invalid; stopping before any Gemini API request.")
    recent = []
    for item in ledger["reservations"]:
        try:
            if now - parse_time(str(item["reserved_at"])) < timedelta(hours=24):
                recent.append(item)
        except (KeyError, ValueError, TypeError):
            # A malformed entry must not silently free quota.
            raise SystemExit("Gemini usage ledger contains a malformed reservation; stopping before any API request.")
    used = sum(1 for item in recent if str(item.get("model")) == model)
    if used >= limit:
        print(f"QUOTA BLOCK: {model} already has {used}/{limit} reserved requests in the rolling last 24 hours.", file=sys.stderr)
        return 3
    entry = {
        "reserved_at": now.isoformat(),
        "model": model,
        "kind": args.kind,
        "workflow": os.getenv("GITHUB_WORKFLOW", "local"),
        "run_id": os.getenv("GITHUB_RUN_ID", "local"),
        "run_attempt": os.getenv("GITHUB_RUN_ATTEMPT", "1")
    }
    ledger["reservations"] = recent + [entry]
    ledger["schema_version"] = 1
    tmp = ledger_path.with_suffix(ledger_path.suffix + ".tmp")
    tmp.write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    tmp.replace(ledger_path)
    try:
        run(["git", "config", "user.name", "github-actions[bot]"])
        run(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"])
        run(["git", "add", "--", str(ledger_path.relative_to(ROOT))])
        staged = run(["git", "diff", "--cached", "--quiet"], check=False)
        if staged.returncode == 0:
            print("No new quota reservation to commit.")
        elif staged.returncode == 1:
            run(["git", "commit", "-m", f"quota: reserve Gemini {args.kind} review slot"])
            run(["git", "fetch", "origin", "main"])
            run(["git", "rebase", "--autostash", "origin/main"])
            run(["git", "push", "origin", "HEAD:main"])
        else:
            raise RuntimeError("Could not inspect staged quota ledger.")
    except Exception as exc:
        print(f"QUOTA BLOCK: could not persist reservation ({type(exc).__name__}); stopping before Gemini call.", file=sys.stderr)
        return 4
    print(f"Reserved one {args.kind} request for {model}: {used + 1}/{limit} in rolling 24 hours.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
