#!/usr/bin/env python3
"""Final-only Gemini gameplay review.

This script must be called only after deterministic validation, the project-specific
Godot autoplayer and video/audio capture have all succeeded. It makes at most one
generation request per configured model and deliberately does not retry failures.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_MODELS = ["gemini-3.8-flash", "gemini-3.7-flash", "gemini-3.6-flash"]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def state_text(file_obj: Any) -> str:
    state = getattr(file_obj, "state", None)
    return str(getattr(state, "name", state or "")).upper()


def wait_until_active(client: Any, uploaded: Any, timeout_seconds: int = 300) -> Any:
    name = getattr(uploaded, "name", None)
    if not name:
        raise RuntimeError("Gemini file upload returned no file name.")
    deadline = time.monotonic() + timeout_seconds
    current = uploaded
    while time.monotonic() < deadline:
        state = state_text(current)
        if "ACTIVE" in state:
            return current
        if "FAILED" in state:
            raise RuntimeError(f"Gemini rejected or failed to process the video file (state={state}).")
        time.sleep(5)
        current = client.files.get(name=name)
    raise TimeoutError("Gemini video processing did not become ACTIVE within five minutes.")


def score_from_text(text: str) -> float | None:
    patterns = [
        r'(?i)"?(?:overall_)?score"?\s*[:=]\s*"?([0-9]{1,3}(?:\.[0-9]+)?)',
        r"(?i)score\s*[:=]\s*([0-9]{1,3}(?:\.[0-9]+)?)\s*(?:/\s*100)?",
        r"(?i)([0-9]{1,3}(?:\.[0-9]+)?)\s*/\s*100",
    ]
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            value = float(match.group(1))
            if 0 <= value <= 100:
                return value
    return None


def make_prompt(project_id: str, model_name: str) -> str:
    return f"""
You are a strict, evidence-based game QA reviewer. Review the uploaded complete gameplay
recording (video frames and its audio track) for project {project_id}. Model: {model_name}.

Do not claim you played the game yourself. The project-specific Godot autoplayer played it;
you are reviewing only the supplied recording. Do not infer off-screen functionality or
claim absence of bugs from a short clip.

Return a concise JSON object with these keys:
{{
  "project_id": "{project_id}",
  "model": "{model_name}",
  "overall_score": 0,
  "verdict": "PASS|NEEDS_WORK|BLOCKED",
  "observations": [{{"timestamp": "mm:ss or unknown", "severity": "critical|high|medium|low", "category": "gameplay|visual|audio|UI|controls|performance|other", "finding": "specific finding", "recommended_fix": "actionable fix"}}],
  "audio_review": {{"audible": true, "mixing_or_sync_issues": [], "notes": ""}},
  "visible_gameplay_review": {{"playable_flow_observed": "", "visual_issues": [], "control_feedback": ""}},
  "unknowns_not_verified": [],
  "release_blockers": [],
  "recommendation": "next practical step"
}}

Score each category using observable evidence only: scene clarity and UI; visual consistency;
movement/collision feedback; gameplay flow and feedback; audio/sync; obvious runtime glitches.
A score above 90 is allowed only if the clip supports it and no blocker is visible. If the clip
does not demonstrate the complete core loop, set verdict to NEEDS_WORK or BLOCKED and list
what was not shown. Check that sound effects correspond to visible events where possible.
Do not say the game is perfect. Return only the JSON object, no Markdown wrapper.
""".strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-id", required=True)
    parser.add_argument("--video", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--models", default=",".join(DEFAULT_MODELS))
    args = parser.parse_args()

    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        print("GEMINI_API_KEY is not configured; no Gemini calls made.", file=sys.stderr)
        return 2
    if not args.video.is_file() or args.video.stat().st_size < 10_000:
        print("Gameplay video is missing or too small; no Gemini calls made.", file=sys.stderr)
        return 2

    # Import only after preconditions, and keep the credential out of all output.
    try:
        from google import genai
    except ImportError:
        print("google-genai is not installed; no Gemini calls made.", file=sys.stderr)
        return 2

    args.output.parent.mkdir(parents=True, exist_ok=True)
    client = genai.Client(api_key=api_key)
    started = utc_now()
    report: dict[str, Any] = {
        "schema_version": 1,
        "project_id": args.project_id,
        "started_at": started,
        "completed_at": None,
        "video_file_name": args.video.name,
        "video_size_bytes": args.video.stat().st_size,
        "video_sha256": sha256_file(args.video),
        "policy": {
            "purpose": "final recorded gameplay video/audio review only",
            "one_generation_request_per_model": True,
            "automatic_retry": False,
            "models": [],
        },
        "file_processing": {"status": "not_started"},
        "reviews": [],
        "overall_status": "blocked",
    }

    try:
        uploaded = client.files.upload(file=str(args.video))
        report["file_processing"] = {
            "status": "uploaded",
            "file_name": getattr(uploaded, "name", None),
            "initial_state": state_text(uploaded),
        }
        video_ref = wait_until_active(client, uploaded)
        report["file_processing"]["status"] = "active"
        report["file_processing"]["active_state"] = state_text(video_ref)
    except Exception as exc:
        report["file_processing"] = {
            "status": "error",
            "error_type": type(exc).__name__,
            "error": str(exc)[:1000],
        }
        report["completed_at"] = utc_now()
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("Video upload/processing failed; no model review calls made.")
        return 1

    models = [m.strip() for m in args.models.split(",") if m.strip()]
    report["policy"]["models"] = models
    any_success = False
    for model_name in models:
        item: dict[str, Any] = {
            "model": model_name,
            "attempted_at": utc_now(),
            "status": "error",
            "retry_count": 0,
        }
        try:
            # Exactly one generate_content call per model. Never auto-retry.
            response = client.models.generate_content(
                model=model_name,
                contents=[video_ref, make_prompt(args.project_id, model_name)],
            )
            raw_text = str(getattr(response, "text", "") or "")
            item["status"] = "success"
            item["response_text"] = raw_text
            item["score"] = score_from_text(raw_text)
            try:
                candidate = json.loads(raw_text)
                if isinstance(candidate, dict):
                    item["parsed_review"] = candidate
                    if isinstance(candidate.get("overall_score"), (int, float)):
                        item["score"] = float(candidate["overall_score"])
                    item["verdict"] = candidate.get("verdict")
            except json.JSONDecodeError:
                item["parse_note"] = "Model response was not valid JSON; raw text is preserved for review."
            any_success = True
            print(f"Final review attempted: {model_name}; status=success; score={item.get('score')}")
        except Exception as exc:
            item["status"] = "error"
            item["error_type"] = type(exc).__name__
            item["error"] = str(exc)[:1200]
            print(f"Final review attempted: {model_name}; status=error ({type(exc).__name__})")
        report["reviews"].append(item)
        # Serialize progress after every model so partial results survive a later failure.
        report["completed_at"] = utc_now()
        report["overall_status"] = "reviewed" if any_success else "blocked"
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Remove the uploaded copy after all configured models have reviewed it.
    # The private HF archive remains the durable record; deletion failures are reported.
    try:
        client.files.delete(name=uploaded.name)
        report["file_processing"]["cleanup_status"] = "deleted_from_gemini"
    except Exception as exc:
        report["file_processing"]["cleanup_status"] = "cleanup_failed"
        report["file_processing"]["cleanup_error_type"] = type(exc).__name__
        report["file_processing"]["cleanup_error"] = str(exc)[:500]

    report["completed_at"] = utc_now()
    success_count = sum(1 for x in report["reviews"] if x["status"] == "success")
    failed_count = len(report["reviews"]) - success_count
    if success_count == len(models):
        report["overall_status"] = "reviewed"
    elif success_count:
        report["overall_status"] = "partial"
    else:
        report["overall_status"] = "blocked"
    report["successful_reviews"] = success_count
    report["failed_reviews"] = failed_count
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\\n", encoding="utf-8")
    print(f"Saved final QA report: {args.output}; successful_reviews={success_count}/{len(models)}.")
    # Any successful review produces useful evidence, but this script never labels a build "perfect".
    return 0 if success_count else 1


if __name__ == "__main__":
    raise SystemExit(main())
