from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "ai_superagent"
OUT.mkdir(parents=True, exist_ok=True)

paths = [
    ROOT / "knowledge" / "Godot-4.7.2-Exhaustive-Knowledge-Base.md",
    ROOT / "Godot-4.7.2-Exhaustive-Knowledge-Base.md",
]

source = next((p for p in paths if p.exists()), None)

if source:
    text = source.read_text(encoding="utf-8", errors="ignore")
    result = {
        "source": str(source.relative_to(ROOT)),
        "bytes": len(text.encode("utf-8")),
        "lines": len(text.splitlines()),
        "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
        "headings": re.findall(r"^#{1,6}\s+(.+)$", text, re.M),
        "godot_class_count_claim": 810 if "Documented built-in classes" in text else None,
        "godot_method_count_claim": 9896 if "Total methods" in text else None,
    }
else:
    result = {
        "status": "waiting_for_knowledge_base",
        "expected": "knowledge/Godot-4.7.2-Exhaustive-Knowledge-Base.md",
    }

(OUT / "knowledge_manifest.json").write_text(
    json.dumps(result, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
print(json.dumps(result, indent=2, ensure_ascii=False))
