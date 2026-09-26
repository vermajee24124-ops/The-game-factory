from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CURRICULUM = ROOT / "knowledge" / "agent_curriculum.json"
OUT = ROOT / "build" / "agent_research" / "video_queries.generated.txt"
OUT.parent.mkdir(parents=True, exist_ok=True)

data = json.loads(CURRICULUM.read_text(encoding="utf-8"))
classes = [x["name"] for x in data.get("class_reference", [])]
domains = data.get("domains", []) or [
    "Godot 2D", "Godot 3D", "Godot rendering", "Godot shaders", "Godot animation",
    "Godot physics", "Godot UI", "Godot navigation", "Godot optimization",
]

templates = [
    "Godot 4.7.2 {subject} tutorial",
    "Godot 4.7.2 {subject} game development",
    "Godot 4.x {subject} workflow",
]
extra = [
    "Godot 4.7.2 complete {subject} guide",
    "Godot 4.7.2 {subject} advanced tutorial",
    "Godot 4.7.2 {subject} production workflow",
]

queries = set()
for subject in domains:
    for template in templates + extra[:1]:
        queries.add(template.format(subject=subject))

# Sample every built-in class, but keep queries compact enough for rolling batches.
for name in classes:
    for template in templates[:2]:
        queries.add(template.format(subject=name))

# High-value production topics.
for subject in [
    "AAA game workflow", "open world", "third person controller",
    "first person controller", "terrain", "foliage", "level design",
    "asset pipeline", "Blender to Godot", "gltf pipeline",
    "mobile optimization", "draw calls", "occlusion culling", "LOD",
    "lightmap GI", "VoxelGI", "SDFGI", "volumetric fog",
    "animation tree", "state machine", "shader graph", "visual shader",
    "multiplayer replication", "dedicated server", "profiling",
]:
    queries.add(f"Godot 4.7.2 {subject}")

OUT.write_text("\n".join(sorted(queries)) + "\n", encoding="utf-8")
print(f"generated {len(queries)} queries")
