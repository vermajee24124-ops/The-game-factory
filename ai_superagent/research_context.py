from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load_research_context(limit: int = 8) -> str:
    path = ROOT / "build" / "agent_research" / "summaries.jsonl"
    if not path.exists():
        return ""
    parts = []
    for line in path.read_text(encoding="utf-8").splitlines()[:limit]:
        if line.strip():
            item = json.loads(line)
            parts.append("SOURCE: " + item.get("source_file", "") + "\n" + item.get("summary", ""))
    return "\n\n".join(parts)
