#!/usr/bin/env python3
"""Reserve a conservative rolling-24-hour budget for final-only Gemini reviews.

The usage ledger is stored in a private Hugging Face dataset repo, not public GitHub.
Reservations happen before model calls and are intentionally not refunded after failure.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

LEDGER_PATH = "final-qa/_private_state/gemini_daily_usage.json"
PROJECT_ID_RE = re.compile(r"^GME-\d{4}-\d{4}$")
DEFAULT_MODELS = ["gemini-3.8-flash", "gemini-3.7-flash", "gemini-3.6-flash"]
MAX_RESERVATIONS_PER_MODEL_24H = 18  # Leave a two-request margin below the screenshot's 20 RPD.


def parse_time(value: str) -> datetime:
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        raise ValueError("Quota ledger timestamps must include a timezone.")
    return parsed.astimezone(timezone.utc)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-id", required=True)
    parser.add_argument("--models", default=",".join(DEFAULT_MODELS))
    args = parser.parse_args()
    if not PROJECT_ID_RE.fullmatch(args.project_id):
        parser.error("project-id must match GME-YYYY-NNNN")

    token = os.getenv("HF_TOKEN", "").strip()
    repo_id = os.getenv("HF_PRIVATE_REPO_ID", "").strip()
    if not token or not repo_id:
        print("HF_TOKEN and HF_PRIVATE_REPO_ID are required; no values were printed.", file=sys.stderr)
        return 2

    models = list(dict.fromkeys(m.strip() for m in args.models.split(",") if m.strip()))
    if not models:
        parser.error("at least one model must be supplied")

    try:
        from huggingface_hub import HfApi, hf_hub_download
    except ImportError:
        print("huggingface_hub is not installed.", file=sys.stderr)
        return 2

    api = HfApi(token=token)
    try:
        api.create_repo(repo_id=repo_id, repo_type="dataset", private=True, exist_ok=True)
        info = api.repo_info(repo_id=repo_id, repo_type="dataset")
        if not bool(getattr(info, "private", False)):
            print("Refusing quota reservation: archive dataset is not private.", file=sys.stderr)
            return 3

        if api.file_exists(repo_id=repo_id, repo_type="dataset", filename=LEDGER_PATH):
            path = Path(hf_hub_download(
                repo_id=repo_id,
                repo_type="dataset",
                filename=LEDGER_PATH,
                token=token,
            ))
            ledger = json.loads(path.read_text(encoding="utf-8"))
        else:
            ledger = {"schema_version": 1, "reservations": []}
        if not isinstance(ledger, dict) or not isinstance(ledger.get("reservations"), list):
            raise ValueError("Private quota ledger is malformed; refusing to make calls.")

        now = datetime.now(timezone.utc)
        cutoff = now - timedelta(hours=24)
        recent: list[dict] = []
        for reservation in ledger["reservations"]:
            if not isinstance(reservation, dict):
                raise ValueError("Private quota ledger contains a malformed reservation.")
            stamp = parse_time(str(reservation.get("reserved_at", "")))
            if stamp >= cutoff:
                recent.append(reservation)

        blocked = []
        counts: dict[str, int] = {}
        for model in models:
            used = sum(1 for item in recent if model in item.get("models", []))
            counts[model] = used
            if used >= MAX_RESERVATIONS_PER_MODEL_24H:
                blocked.append(f"{model} has {used}/{MAX_RESERVATIONS_PER_MODEL_24H} final reviews reserved in the last 24 hours")
        if blocked:
            print("No Gemini requests reserved; rolling quota safety limit reached:\n- " + "\n- ".join(blocked), file=sys.stderr)
            return 4

        reservation = {
            "reserved_at": now.isoformat(),
            "project_id": args.project_id,
            "models": models,
            "previous_24h_counts": counts,
            "max_reservations_per_model_24h": MAX_RESERVATIONS_PER_MODEL_24H,
            "policy": "one reserved generation request per model in this run; no automatic retries",
        }
        ledger["reservations"] = recent + [reservation]
        ledger["schema_version"] = 1
        with tempfile.TemporaryDirectory(prefix="game-factory-quota-") as temp_dir:
            tmp = Path(temp_dir) / "gemini_daily_usage.json"
            tmp.write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            api.upload_file(
                path_or_fileobj=str(tmp),
                path_in_repo=LEDGER_PATH,
                repo_id=repo_id,
                repo_type="dataset",
                commit_message=f"Reserve final Gemini QA budget for {args.project_id}",
            )
        print(f"Reserved one request each for {len(models)} models; cap={MAX_RESERVATIONS_PER_MODEL_24H}/model per rolling 24h.")
        print("The ledger is private. Reserved slots are not automatically released after failures.")
        return 0
    except Exception as exc:
        print(f"Quota preflight failed closed: {type(exc).__name__}: {str(exc)[:800]}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
