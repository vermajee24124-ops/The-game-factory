from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KB = ROOT / "knowledge" / "Godot-4.7.2-Exhaustive-Knowledge-Base.md"
OUT = ROOT / "build" / "agent_evolution"
OUT.mkdir(parents=True, exist_ok=True)

text = KB.read_text(encoding="utf-8")
tasks = []

# A-Z built-in class curriculum.
in_table = False
for line in text.splitlines():
    if line.startswith("| Class | Inherits"):
        in_table = True
        continue
    if in_table:
        if line.startswith("|---|"):
            continue
        if not line.startswith("|"):
            if tasks:
                in_table = False
            continue
        parts = [p.strip() for p in line.strip().strip("|").split("|")]
        if len(parts) < 7 or not parts[0] or not parts[3].isdigit():
            continue
        name, inherits, brief = parts[0], parts[1], parts[2]
        tasks.append({
            "id": f"class-{len(tasks)+1:04d}-inspect",
            "type": "builtin_class",
            "subject": name,
            "goal": f"Learn how to use {name} safely in Godot 4.7.2. Inspect its inheritance, properties, methods, signals and constants, then produce a minimal practical example.",
            "requires_evidence": True,
        })
        tasks.append({
            "id": f"class-{len(tasks)+1:04d}-apply",
            "type": "builtin_class",
            "subject": name,
            "goal": f"Apply {name} to a real game-development task appropriate to its type. Choose the smallest correct API surface, then describe how to verify the result at runtime or in the editor.",
            "requires_evidence": True,
        })

# Engine-level learning domains.
domains = [
    "2D", "3D", "rendering", "physics", "animation", "audio", "GUI",
    "navigation", "particles", "materials", "shaders", "lighting",
    "asset import", "asset export", "networking", "multiplayer", "XR",
    "GDScript", "editor scripting", "debugging", "profiling", "optimization",
    "project settings", "editor settings", "command line", "GDExtension",
    "headless automation", "mobile deployment", "web deployment",
]
for domain in domains:
    tasks.append({
        "id": f"domain-{len(tasks)+1:05d}",
        "type": "domain",
        "subject": domain,
        "goal": f"Master the Godot 4.7.2 {domain} workflow from project setup through verification, including relevant tools and common failure modes.",
        "requires_evidence": True,
    })

# Plugin / ecosystem names explicitly present in Section 20.
section = text[text.find("## 20. Ecosystem"):]
names = []
for match in re.finditer(r"^\-\s+\*\*([^*]+)\*\*", section, re.M):
    name = match.group(1).strip()
    if name not in {"Web:", "In-editor:", "API:"} and name not in names:
        names.append(name)
for name in names:
    tasks.append({
        "id": f"ecosystem-{len(tasks)+1:05d}",
        "type": "ecosystem",
        "subject": name,
        "goal": f"Learn the documented purpose, install/integration path, Godot-version status, permissions, and safe usage pattern for {name}. Do not execute untrusted plugin code automatically.",
        "requires_evidence": False,
    })

# Convert to stable JSONL.
path = OUT / "curriculum_tasks.jsonl"
with path.open("w", encoding="utf-8") as fh:
    for task in tasks:
        fh.write(json.dumps(task, ensure_ascii=False) + "\n")

summary = {
    "engine": "4.7.2",
    "class_tasks": sum(1 for t in tasks if t["type"] == "builtin_class"),
    "domain_tasks": sum(1 for t in tasks if t["type"] == "domain"),
    "ecosystem_tasks": sum(1 for t in tasks if t["type"] == "ecosystem"),
    "total_tasks": len(tasks),
}
(OUT / "curriculum_summary.json").write_text(
    json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)
print(json.dumps(summary, indent=2, ensure_ascii=False))
