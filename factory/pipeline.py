from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .bible import find_bible, read_bible, extract_project_id, extract_title
from .research import research_manifest
from .router import available, select

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "project_registry" / "projects.json"


def _load_registry() -> dict[str, Any]:
    if not REGISTRY.exists():
        return {"schema_version": 1, "projects": []}
    return json.loads(REGISTRY.read_text(encoding="utf-8"))


def _next_id(registry: dict[str, Any]) -> str:
    year = datetime.now(timezone.utc).year
    nums = []
    for project in registry.get("projects", []):
        value = str(project.get("project_id", ""))
        if value.startswith(f"GME-{year}-"):
            try:
                nums.append(int(value.rsplit("-", 1)[1]))
            except ValueError:
                pass
    return f"GME-{year}-{max(nums, default=0) + 1:04d}"


def resolve_bible() -> dict[str, Any]:
    bible = find_bible(ROOT)
    if bible is None:
        raise FileNotFoundError("No Game Bible found in game_bible/inbox")
    text = read_bible(bible)
    return {
        "path": str(bible),
        "title": extract_title(text),
        "project_id": extract_project_id(text),
        "text": text,
    }


def plan() -> dict[str, Any]:
    bible = resolve_bible()
    registry = _load_registry()
    project_id = bible["project_id"]
    action = "update" if project_id and any(p.get("project_id", "").upper() == project_id.upper() for p in registry.get("projects", [])) else "create"
    if action == "create":
        project_id = project_id or _next_id(registry)
    model_route = select("code")
    return {
        "action": action,
        "project_id": project_id,
        "title": bible["title"],
        "bible_path": bible["path"],
        "available_providers": [p.name for p in available()],
        "preferred_provider": model_route.name if model_route else None,
        "research": research_manifest(),
    }
