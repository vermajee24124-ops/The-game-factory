from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


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
            parts.append("SOURCE: " + str(item.get("source_file", "")) + "\n" + str(item.get("summary", "")))
        elif label == "visual":
            src = item.get("source", {}) or {}
            parts.append("VIDEO: " + str(src.get("title", "")) + "\n" + json.dumps(item.get("analysis", {}), ensure_ascii=False)[:5000])
        elif label == "discovery":
            parts.append("VIDEO CANDIDATE: " + str(item.get("title", "")) + " | " + str(item.get("url", "")))
    return parts


def load_research_context(limit: int = 12) -> str:
    parts: list[str] = []
    parts += _read_jsonl(ROOT / "build" / "agent_research" / "summaries.jsonl", limit, "summary")
    parts += _read_jsonl(ROOT / "build" / "agent_research" / "gemini_visual_notes.jsonl", limit, "visual")
    if not parts:
        shards = sorted((ROOT / "build" / "agent_research").glob("shard-*.jsonl"))
        for path in shards[:4]:
            parts += _read_jsonl(path, max(1, limit // 2), "discovery")
            if len(parts) >= limit:
                break
    return "\n\n".join(parts[:limit])
