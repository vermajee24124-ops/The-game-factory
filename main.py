#!/usr/bin/env python3
"""The Game Factory orchestration entrypoint.

The entrypoint is intentionally provider- and tool-agnostic. It resolves an
existing project by explicit ID or known project name, otherwise allocates a
new ID. Secrets are always read from the runtime environment.
"""
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
ID_PATTERN = re.compile(r"\bGME-\d{4}-\d{4}\b", re.IGNORECASE)


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
            value = json.loads(self.path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid project registry: {self.path}") from exc
        if not isinstance(value, dict) or not isinstance(value.get("projects"), list):
            raise RuntimeError("Project registry must contain a projects list")
        return value

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self.data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def find_by_id(self, project_id: str) -> dict[str, Any] | None:
        target = project_id.upper()
        return next((p for p in self.data["projects"] if str(p.get("project_id", "")).upper() == target), None)

    def find_by_name(self, text: str) -> dict[str, Any] | None:
        normalized = re.sub(r"\s+", " ", text.casefold()).strip()
        for project in self.data["projects"]:
            name = re.sub(r"\s+", " ", str(project.get("name", "")).casefold()).strip()
            if name and name in normalized:
                return project
        return None

    def next_id(self) -> str:
        year = datetime.now(timezone.utc).year
        used = []
        for project in self.data["projects"]:
            match = re.fullmatch(r"GME-(\d{4})-(\d{4})", str(project.get("project_id", "")), re.I)
            if match and int(match.group(1)) == year:
                used.append(int(match.group(2)))
        return f"GME-{year}-{max(used, default=0) + 1:04d}"

    def add(self, record: ProjectRecord) -> None:
        self.data["projects"].append(asdict(record))
        self.save()


def extract_project_id(text: str) -> str | None:
    match = ID_PATTERN.search(text)
    return match.group(0).upper() if match else None


def scaffold_project(project: dict[str, Any]) -> Path:
    root = ROOT / "projects" / project["project_id"]
    for name in ("godot", "tests", "backend", "assets", "compliance", "store", "builds", "docs", "logs", "state", "tools"):
        (root / name).mkdir(parents=True, exist_ok=True)
    (root / "manifest.json").write_text(json.dumps(project, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return root


def resolve_project(instruction: str, registry: ProjectRegistry) -> tuple[dict[str, Any], bool]:
    project_id = extract_project_id(instruction)
    if project_id:
        existing = registry.find_by_id(project_id)
        if existing:
            return existing, False
        raise ValueError(f"Unknown project ID: {project_id}")

    existing_by_name = registry.find_by_name(instruction)
    if existing_by_name:
        return existing_by_name, False

    now = datetime.now(timezone.utc).isoformat()
    record = ProjectRecord(
        project_id=registry.next_id(),
        name="Unspecified Game",
        created_at=now,
        updated_at=now,
    )
    return asdict(record), True


def main() -> int:
    parser = argparse.ArgumentParser(description="The Game Factory")
    parser.add_argument("--instruction", required=True, help="New game request or update instruction")
    parser.add_argument("--apply", action="store_true", help="Persist a new project scaffold")
    args = parser.parse_args()

    instruction = args.instruction.strip()
    if not instruction:
        print("Instruction cannot be empty", file=sys.stderr)
        return 2

    registry = ProjectRegistry(REGISTRY)
    project, created = resolve_project(instruction, registry)

    if created:
        if args.apply:
            registry.add(ProjectRecord(**project))
            project_root = scaffold_project(project)
            action = "create_project"
        else:
            project_root = ROOT / "projects" / project["project_id"]
            action = "create_project_dry_run"
    else:
        project_root = ROOT / "projects" / project["project_id"]
        action = "update_project"

    print(json.dumps({
        "action": action,
        "project_id": project["project_id"],
        "project_root": str(project_root),
        "engine": project.get("engine", "Godot"),
        "engine_channel": project.get("engine_channel", "stable"),
        "instruction": instruction,
        "apply": bool(args.apply),
    }, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
