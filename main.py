#!/usr/bin/env python3
"""The Game Factory orchestration entrypoint."""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
REGISTRY = ROOT / "project_registry" / "projects.json"
PROJECT_ID_PATTERN = re.compile(r"\bGME-\d{4}-\d{4}\b", re.IGNORECASE)


@dataclass
class ProjectRecord:
    project_id: str
    name: str
    status: str = "planned"
    latest_version: str = "0.1.0"
    engine: str = "Godot"
    engine_channel: str = "stable"
    engine_version: str | None = None
    created_at: str = ""
    updated_at: str = ""


class ProjectRegistry:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data = self._load()

    def _load(self) -> dict[str, Any]:
        if not self.path.exists():
            return {"schema_version": 1, "projects": []}
        try:
            return json.loads(self.path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid project registry: {self.path}") from exc

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self.data, indent=2), encoding="utf-8")

    def find(self, project_id: str) -> dict[str, Any] | None:
        normalized = project_id.upper()
        return next((p for p in self.data["projects"] if p["project_id"].upper() == normalized), None)

    def next_id(self) -> str:
        year = datetime.now(timezone.utc).year
        nums = []
        for project in self.data["projects"]:
            match = re.fullmatch(r"GME-(\d{4})-(\d{4})", str(project.get("project_id", "")), re.I)
            if match and int(match.group(1)) == year:
                nums.append(int(match.group(2)))
        return f"GME-{year}-{max(nums, default=0) + 1:04d}"

    def add(self, record: ProjectRecord) -> None:
        self.data["projects"].append(asdict(record))
        self.save()


def extract_project_id(text: str) -> str | None:
    match = PROJECT_ID_PATTERN.search(text)
    return match.group(0).upper() if match else None


def slugify(name: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9_-]+", "-", name.strip()).strip("-").lower()
    return value or "game-project"


def create_project_scaffold(root: Path, record: ProjectRecord, bible_source: str | None = None) -> Path:
    project_root = root / "projects" / record.project_id
    for directory in ["godot", "tests", "backend", "assets", "compliance", "store", "builds", "docs", "logs", "state", "tools"]:
        (project_root / directory).mkdir(parents=True, exist_ok=True)
    manifest = {**asdict(record), "slug": slugify(record.name), "schema_version": 1, "bible_source": bible_source}
    (project_root / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    (project_root / "README.md").write_text(
        f"# {record.name}\n\nProject ID: `{record.project_id}`\n\nThis directory is managed by The Game Factory.\n",
        encoding="utf-8",
    )
    return project_root


def resolve_project(instruction: str, registry: ProjectRegistry) -> tuple[dict[str, Any], bool]:
    project_id = extract_project_id(instruction)
    if project_id:
        existing = registry.find(project_id)
        if existing:
            return existing, False
        raise ValueError(f"Project ID {project_id} was supplied but is not registered.")
    now = datetime.now(timezone.utc).isoformat()
    record = ProjectRecord(project_id=registry.next_id(), name="Unspecified Game", created_at=now, updated_at=now)
    return asdict(record), True


def main() -> int:
    parser = argparse.ArgumentParser(description="The Game Factory orchestrator")
    parser.add_argument("--instruction", required=True)
    parser.add_argument("--apply", action="store_true", help="Persist a new project scaffold")
    args = parser.parse_args()
    instruction = args.instruction.strip()
    if not instruction:
        print("Instruction cannot be empty", file=sys.stderr)
        return 2

    registry = ProjectRegistry(REGISTRY)
    project, created = resolve_project(instruction, registry)
    if created and args.apply:
        registry.add(ProjectRecord(**project))
        scaffold = create_project_scaffold(ROOT, ProjectRecord(**project))
        result = {"action": "create_project", "project_id": project["project_id"], "project_path": str(scaffold)}
    elif created:
        result = {"action": "create_project_dry_run", "project_id": project["project_id"], "apply_required": True}
    else:
        result = {"action": "update_project", "project_id": project["project_id"], "instruction": instruction}
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
