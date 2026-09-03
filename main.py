#!/usr/bin/env python3
"""The Game Factory orchestration entrypoint.

A Game Bible in game_bible/inbox is the primary user input. The factory resolves
an existing project by explicit project ID/name or creates a new project, then
records a versioned request state. Real credentials are always read from the
runtime environment and never written to the repository.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from factory.bible import find_bible, read_bible, extract_project_id, extract_title

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
    launch_profile: str = "generic"
    accounts_enabled: bool = False
    backend_enabled: bool = False
    ads_enabled: bool = False
    purchases_enabled: bool = False
    created_at: str = ""
    updated_at: str = ""


class ProjectRegistry:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data = self._load()

    def _load(self) -> dict[str, Any]:
        if not self.path.exists():
            return {"schema_version": 2, "projects": []}
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
        used: list[int] = []
        for project in self.data["projects"]:
            match = re.fullmatch(r"GME-(\d{4})-(\d{4})", str(project.get("project_id", "")), re.I)
            if match and int(match.group(1)) == year:
                used.append(int(match.group(2)))
        return f"GME-{year}-{max(used, default=0) + 1:04d}"

    def add(self, record: ProjectRecord) -> None:
        self.data["projects"].append(asdict(record))
        self.save()

    def update(self, project: dict[str, Any], **changes: Any) -> dict[str, Any]:
        project.update(changes)
        self.save()
        return project


def extract_project_id(text: str) -> str | None:
    match = ID_PATTERN.search(text)
    return match.group(0).upper() if match else None


def parse_version(version: str) -> tuple[int, int, int]:
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
    return tuple(map(int, match.groups())) if match else (0, 1, 0)


def bump_patch(version: str) -> str:
    major, minor, patch = parse_version(version)
    return f"{major}.{minor}.{patch + 1}"


def scaffold_project(project: dict[str, Any]) -> Path:
    root = ROOT / "projects" / project["project_id"]
    for name in ("godot", "tests", "backend", "assets", "compliance", "store", "builds", "docs", "logs", "state", "tools"):
        (root / name).mkdir(parents=True, exist_ok=True)
    (root / "manifest.json").write_text(json.dumps(project, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return root


def archive_bible(source: Path, project_root: Path, version: str) -> str | None:
    if not source.exists():
        return None
    archive_dir = project_root / "docs" / "game_bibles"
    archive_dir.mkdir(parents=True, exist_ok=True)
    safe_name = re.sub(r"[^A-Za-z0-9._-]+", "_", source.name)
    destination = archive_dir / f"{version}__{safe_name}"
    if destination.exists() or source.resolve() == destination.resolve():
        return str(destination.relative_to(ROOT))
    shutil.copy2(source, destination)
    return str(destination.relative_to(ROOT))


def update_state(project_root: Path, *, instruction: str, bible_path: Path | None, version: str, action: str) -> None:
    state_dir = project_root / "state" / "requests"
    state_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    state = {
        "schema_version": 1,
        "action": action,
        "version": version,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        "instruction": instruction,
        "bible": str(bible_path.relative_to(ROOT)) if bible_path and bible_path.is_relative_to(ROOT) else (str(bible_path) if bible_path else None),
    }
    (state_dir / f"{stamp}.json").write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def resolve_from_bible(bible_path: Path, registry: ProjectRegistry) -> tuple[dict[str, Any], bool, str]:
    text = read_bible(bible_path)
    project_id = extract_project_id(text)
    title = extract_title(text)
    existing = registry.find_by_id(project_id) if project_id else None
    if existing:
        return existing, False, text
    if not project_id:
        existing_by_name = registry.find_by_name(text)
        if existing_by_name:
            return existing_by_name, False, text

    now = datetime.now(timezone.utc).isoformat()
    record = ProjectRecord(
        project_id=registry.next_id(),
        name=title if title != "Untitled Game" else "Untitled Game",
        created_at=now,
        updated_at=now,
    )
    return asdict(record), True, text


def apply_project(project: dict[str, Any], *, created: bool, bible_path: Path | None, instruction: str, registry: ProjectRegistry) -> dict[str, Any]:
    root = scaffold_project(project)
    if created:
        version = str(project.get("latest_version", "0.1.0"))
        registry.add(ProjectRecord(**project))
        action = "create_project"
    else:
        version = bump_patch(str(project.get("latest_version", "0.1.0")))
        project = registry.update(project, latest_version=version, updated_at=datetime.now(timezone.utc).isoformat(), status="development")
        (root / "manifest.json").write_text(json.dumps(project, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        action = "update_project"

    archived = archive_bible(bible_path, root, version) if bible_path else None
    update_state(root, instruction=instruction, bible_path=bible_path, version=version, action=action)
    result = dict(project)
    result["processed_bible_archive"] = archived
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="The Game Factory")
    parser.add_argument("--instruction", help="Direct new game/update instruction")
    parser.add_argument("--bible", help="Path to a Game Bible (.docx/.md/.txt); defaults to newest inbox Bible")
    parser.add_argument("--apply", action="store_true", help="Persist project resolution and state")
    args = parser.parse_args()

    bible_path = Path(args.bible).resolve() if args.bible else (find_bible(ROOT) if not args.instruction else None)
    instruction = args.instruction.strip() if args.instruction else ""

    registry = ProjectRegistry(REGISTRY)
    if bible_path:
        if not bible_path.exists():
            print(f"Game Bible not found: {bible_path}", file=sys.stderr)
            return 2
        project, created, bible_text = resolve_from_bible(bible_path, registry)
        instruction = bible_text
    elif instruction:
        project_id = extract_project_id(instruction)
        existing = registry.find_by_id(project_id) if project_id else registry.find_by_name(instruction)
        if existing:
            project, created = existing, False
        else:
            now = datetime.now(timezone.utc).isoformat()
            project = asdict(ProjectRecord(project_id=registry.next_id(), name=extract_title(instruction), created_at=now, updated_at=now))
            created = True
    else:
        print("Provide --bible, --instruction, or place a Game Bible in game_bible/inbox", file=sys.stderr)
        return 2

    result = {
        "action": "create_project" if created else "update_project",
        "project_id": project["project_id"],
        "project_name": project["name"],
        "current_version": project.get("latest_version"),
        "engine": project.get("engine", "Godot"),
        "engine_channel": project.get("engine_channel", "stable"),
        "bible": str(bible_path) if bible_path else None,
        "apply": bool(args.apply),
    }

    if args.apply:
        result["project"] = apply_project(project, created=created, bible_path=bible_path, instruction=instruction, registry=registry)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
