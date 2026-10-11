#!/usr/bin/env python3
"""Upload selected non-secret QA artifacts to a private Hugging Face dataset repo."""
from __future__ import annotations

import argparse
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ALLOWED_SUFFIXES = {".mp4", ".json", ".md", ".txt"}
PROJECT_ID_RE = re.compile(r"^GME-\d{4}-\d{4}$")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-id", required=True)
    parser.add_argument("--file", action="append", default=[])
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()

    if not PROJECT_ID_RE.fullmatch(args.project_id):
        parser.error("project-id must match GME-YYYY-NNNN")
    token = os.getenv("HF_TOKEN", "").strip()
    repo_id = os.getenv("HF_PRIVATE_REPO_ID", "").strip()
    if not token or not repo_id:
        print("HF_TOKEN and HF_PRIVATE_REPO_ID are required; no values were printed.", file=sys.stderr)
        return 2

    try:
        from huggingface_hub import HfApi
    except ImportError:
        print("huggingface_hub is not installed.", file=sys.stderr)
        return 2

    api = HfApi(token=token)
    try:
        api.create_repo(repo_id=repo_id, repo_type="dataset", private=True, exist_ok=True)
        info = api.repo_info(repo_id=repo_id, repo_type="dataset")
        if not bool(getattr(info, "private", False)):
            print("Refusing to upload: the target Hugging Face dataset is not private.", file=sys.stderr)
            return 3
        if args.check_only:
            # Prove write access before the final Gemini quota is spent.
            # The tiny probe is immediately removed; if either operation fails,
            # the workflow stops before calling Gemini.
            probe_path = "final-qa/_private_state/preflight-write-check.txt"
            with tempfile.TemporaryDirectory(prefix="game-factory-hf-probe-") as temp_dir:
                probe_file = Path(temp_dir) / "preflight-write-check.txt"
                probe_file.write_text(
                    "Temporary private-archive write check. Safe to delete.\\n",
                    encoding="utf-8",
                )
                api.upload_file(
                    path_or_fileobj=str(probe_file),
                    path_in_repo=probe_path,
                    repo_id=repo_id,
                    repo_type="dataset",
                    commit_message="Preflight private QA archive write permission",
                )
            api.delete_file(
                path_in_repo=probe_path,
                repo_id=repo_id,
                repo_type="dataset",
                commit_message="Remove temporary QA archive write check",
            )
            print("Private Hugging Face dataset is private and read/write access passed a temporary write/delete check.")
            return 0

        files = [Path(item).resolve() for item in args.file]
        if not files:
            parser.error("at least one --file is required unless --check-only is set")

        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        uploaded = 0
        for path in files:
            if not path.is_file():
                raise FileNotFoundError(f"Artifact does not exist: {path.name}")
            if path.suffix.lower() not in ALLOWED_SUFFIXES or path.name.startswith(".") or ".env" in path.name.lower():
                raise ValueError(f"Refusing to upload non-allowlisted artifact: {path.name}")
            destination = f"final-qa/{args.project_id}/{stamp}/{path.name}"
            api.upload_file(
                path_or_fileobj=str(path),
                path_in_repo=destination,
                repo_id=repo_id,
                repo_type="dataset",
                commit_message=f"Archive final QA artifact for {args.project_id}",
            )
            uploaded += 1
            print(f"Archived private artifact: {destination}")
        print(f"Private QA archive complete; files={uploaded}; destination repository is private.")
        return 0
    except Exception as exc:
        print(f"Private archive failed: {type(exc).__name__}: {str(exc)[:800]}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
