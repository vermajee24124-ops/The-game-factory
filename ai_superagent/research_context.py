from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CURRICULUM = ROOT / "knowledge" / "agent_curriculum.json"


def _read_jsonl(path: Path, limit: int, label: str) -> list[str]:
    parts: list[str] = []
    if not path.exists():
        return parts
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines()[:limit]:
        if not line.strip():
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        if label == "summary":
            parts.append(
                "SOURCE: " + str(item.get("source_file", "")) + "\n"
                + str(item.get("summary", ""))
            )
        elif label == "visual":
            src = item.get("source", {}) or {}
            parts.append(
                "VIDEO: " + str(src.get("title", "")) + "\n"
                + json.dumps(item.get("analysis", {}), ensure_ascii=False)[:5000]
            )
        elif label == "discovery":
            parts.append(
                "VIDEO CANDIDATE: " + str(item.get("title", ""))
                + " | " + str(item.get("url", ""))
            )
        elif label == "skill":
            parts.append(
                "LEARNED SKILL: " + str(item.get("name", ""))
                + "\n" + str(item.get("skill", ""))
            )
    return parts


def _curriculum_context() -> str:
    if not CURRICULUM.exists():
        return ""
    try:
        data = json.loads(CURRICULUM.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return ""
    inventory = data.get("inventory", {})
    domains = data.get("domains", [])
    return (
        "GODOT KNOWLEDGE CONTRACT: engine=4.7.2; "
        + "classes=" + str(data.get("class_count", 0))
        + "; methods=" + str(inventory.get("methods", 0))
        + "; members=" + str(inventory.get("members", 0))
        + "; signals=" + str(inventory.get("signals", 0))
        + "; constants=" + str(inventory.get("constants", 0))
        + "\nDOMAINS: " + ", ".join(str(x) for x in domains)
    )


def load_research_context(limit: int = 12) -> str:
    parts: list[str] = []
    # The static Godot 4.7.2 curriculum is always available, even when video
    # research is temporarily empty or a provider is offline.
    curriculum = _curriculum_context()
    if curriculum:
        parts.append(curriculum)

    parts += _read_jsonl(
        ROOT / "build" / "agent_research" / "summaries.jsonl",
        limit,
        "summary",
    )
    parts += _read_jsonl(
        ROOT / "build" / "agent_research" / "gemini_visual_notes.jsonl",
        limit,
        "visual",
    )

    learned_paths = sorted((ROOT / "agent_evolution" / "learned").glob("*.json"))
    for path in learned_paths[: max(1, min(6, limit // 2 or 1))]:
        parts += _read_jsonl(path, 3, "skill")

    if len(parts) <= 1:
        shards = sorted((ROOT / "build" / "agent_research").glob("shard-*.jsonl"))
        for path in shards[:4]:
            parts += _read_jsonl(path, max(1, limit // 2), "discovery")
            if len(parts) >= limit + 1:
                break

    return "\n\n".join(parts[: max(1, limit + 1)])
