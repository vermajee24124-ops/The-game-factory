from __future__ import annotations

import hashlib
import json
import os
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "training" / "data"
OUT.mkdir(parents=True, exist_ok=True)


def load_tool_catalog() -> list[dict]:
    catalog_path = ROOT / "knowledge" / "godot_ai_tool_catalog.json"
    names: list[str] = []
    if catalog_path.exists():
        try:
            payload = json.loads(catalog_path.read_text(encoding="utf-8"))
            names = [str(x) for x in payload.get("tools", [])]
        except Exception:
            names = []
    if not names:
        names = [
            "project.summary", "scene.tree", "scene.node_info", "scene.verify_property",
            "scene.save", "script.current", "editor.play", "editor.stop",
            "scene.add_node", "scene.set_property", "file.read_text", "file.write_text",
            "asset.create_3d_character", "asset.import_glb", "godot.api.summary",
            "godot.api.query_classes", "godot.api.class_info",
        ]
    return [
        {
            "type": "function",
            "function": {
                "name": name,
                "description": f"Godot AI operation: {name}",
                "parameters": {
                    "type": "object",
                    "properties": {},
                    "additionalProperties": True,
                },
            },
        }
        for name in dict.fromkeys(names)
    ]


TOOLS = load_tool_catalog()

DEVELOPER = (
    "You are the local Godot micro-action model for Godot 4.7.2. "
    "Return exactly one small action as JSON. Use only supplied tool names. "
    "For complex coding, architecture, multimodal reasoning, large refactors, or uncertain tasks, "
    "return an escalation action instead of inventing an API."
)

VARIANTS = [
    "Please {task}.", "Can you {task}?", "Do this in my Godot project: {task}.",
    "In Godot, {task}.", "I only need this small change: {task}.",
    "Make this quick editor change: {task}.", "Please handle just this tiny task: {task}.",
    "Do not rewrite unrelated things; {task}.",
]


def stable_seed(value: str) -> int:
    return int(hashlib.sha256(value.encode("utf-8")).hexdigest()[:8], 16)


def add(rows: list[dict], task: str, action: dict) -> None:
    user = random.choice(VARIANTS).format(task=task)
    action_json = json.dumps(action, ensure_ascii=False, separators=(",", ":"))
    # Plain-text target is deliberate: it avoids requiring SmolLM2's chat template
    # to implement native tool calling while teaching the exact project action contract.
    training_text = (
        DEVELOPER
        + "\nUSER: "
        + user
        + "\nASSISTANT: "
        + action_json
        + "\n"
    )
    rows.append({
        "text": training_text,
        "task": user,
        "expected_tool": action.get("tool", ""),
        "expected_args": action.get("args", {}),
        "tools": TOOLS,
    })


def tool(name: str, args: dict | None = None) -> dict:
    return {"action": "tool_call", "tool": name, "args": args or {}}


def escalate(reason: str) -> dict:
    return {"action": "final", "result": "escalate", "evidence": [reason]}


def main() -> None:
    seed = int(os.getenv("DATASET_SEED", "20260928"))
    random.seed(seed)
    target = int(os.getenv("TARGET_EXAMPLES", "6000"))
    rows: list[dict] = []

    # Start from the repository's actual micro-task set.
    tasks_path = ROOT / "ai_superagent" / "tasks.jsonl"
    if tasks_path.exists():
        for line in tasks_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            prompt = json.loads(line)["prompt"]
            add(rows, prompt, tool("project.summary"))
            add(rows, prompt, tool("scene.tree"))

    # Explicitly teach retrieval against the complete 4.7.2 curriculum.
    curriculum_path = ROOT / "knowledge" / "agent_curriculum.json"
    if curriculum_path.exists():
        curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
        for row in curriculum.get("class_reference", []):
            name = str(row.get("name", ""))
            if not name:
                continue
            add(rows, f"inspect the live 4.7.2 API for {name} before using it",
                tool("godot.api.class_info", {"class_name": name}))
            add(rows, f"search whether the live Godot ClassDB contains {name}",
                tool("godot.api.query_classes", {"query": name}))
            if len(rows) >= target:
                break

    research_files = []
    for pattern in [
        "build/agent_research/gemini_visual_notes.jsonl",
        "agent_evolution/learned/*.json",
    ]:
        research_files.extend(ROOT.glob(pattern))

    evidence = []
    for path in research_files:
        if not path.is_file():
            continue
        try:
            if path.suffix == ".jsonl":
                evidence.extend(
                    json.loads(line)
                    for line in path.read_text(encoding="utf-8").splitlines()
                    if line.strip()
                )
            else:
                evidence.extend(
                    json.loads(path.read_text(encoding="utf-8")).get("skills", [])
                )
        except Exception:
            continue

    for item in evidence:
        title = str(item.get("title") or item.get("name") or item.get("domain") or "Godot workflow")
        seed_text = json.dumps(item, ensure_ascii=False)[:1500]
        random.seed(seed + stable_seed(seed_text))
        recipes = [
            ("inspect the scene tree before changing anything", "scene.tree", {}),
            ("inspect the root node before making a change", "scene.node_info", {"node_path": "."}),
            ("read back a property after a scene change", "scene.verify_property", {"node_path": "Camera3D", "property": "position"}),
            ("save the edited scene after a meaningful change", "scene.save", {}),
            ("inspect the current project state", "project.summary", {}),
            ("create a simple 3D character named Runner", "asset.create_3d_character", {"name": "Runner", "save_path": "res://assets/generated/Runner.tscn"}),
            ("create a simple enemy character named Enemy", "asset.create_3d_character", {"name": "Enemy"}),
            ("read res://project.godot before editing it", "file.read_text", {"path": "res://project.godot"}),
            ("read the current gameplay script", "script.current", {}),
            ("run the main scene for a quick visual check", "editor.play", {}),
            ("stop the game after the check", "editor.stop", {}),
            ("create a Camera3D under the scene root", "scene.add_node", {"parent_path": ".", "node_type": "Camera3D", "name": "AICamera"}),
            ("create a GPUParticles3D node under the scene root", "scene.add_node", {"parent_path": ".", "node_type": "GPUParticles3D", "name": "AIParticles"}),
            ("set a visible node position to a safe test value", "scene.set_property", {"node_path": "Camera3D", "property": "position", "value": {"x": 0, "y": 3, "z": 6}}),
            ("import a generated character GLB into the assets folder", "asset.import_glb", {"source_path": "/tmp/generated_character.glb", "destination_path": "res://assets/generated/generated_character.glb"}),
            ("read the Godot 4.7.2 API inventory", "godot.api.summary", {}),
            ("search live Godot classes for CharacterBody3D", "godot.api.query_classes", {"query": "CharacterBody3D"}),
            ("inspect the live API of Node3D", "godot.api.class_info", {"class_name": "Node3D"}),
        ]
        for task, name, args in recipes:
            add(rows, f"Use this Godot research context as guidance: {title}. Then {task}", tool(name, args))
        add(
            rows,
            f"Use this research context: {title}. Decide whether the task needs a stronger remote model before acting",
            escalate("Complexity or uncertainty must be handled by the remote reasoner."),
        )
        if len(rows) >= target:
            break

    # Fill remaining examples with balanced micro-actions rather than only one task type.
    variants = [
        ("create a coin pickup", "scene.add_node", {"parent_path": ".", "node_type": "MeshInstance3D", "name": "Coin"}),
        ("create a 3D player body", "scene.add_node", {"parent_path": ".", "node_type": "CharacterBody3D", "name": "Player"}),
        ("inspect the scene before making a file change", "scene.tree", {}),
        ("inspect a player node before editing it", "scene.node_info", {"node_path": "Player"}),
        ("verify a node property after editing it", "scene.verify_property", {"node_path": "Player", "property": "position"}),
        ("save the scene after a completed edit", "scene.save", {}),
        ("check whether the main scene is ready to run", "project.summary", {}),
        ("run the game once for a smoke test", "editor.play", {}),
        ("stop the game after the smoke test", "editor.stop", {}),
        ("create a stylized 3D character", "asset.create_3d_character", {"name": "Character"}),
        ("read a scene file before editing it", "file.read_text", {"path": "res://main.tscn"}),
        ("import a previously generated GLB after checking its path", "asset.import_glb", {"source_path": "/tmp/model.glb", "destination_path": "res://assets/generated/model.glb"}),
        ("inspect the API for Node3D before using it", "godot.api.class_info", {"class_name": "Node3D"}),
        ("search the live ClassDB for a particle node", "godot.api.query_classes", {"query": "GPUParticles3D"}),
        ("ask for escalation instead of guessing a complex task", None, None),
    ]
    while len(rows) < target:
        task, name, args = random.choice(variants)
        add(rows, task, escalate("Escalate complex or uncertain tasks.")) if name is None else add(rows, task, tool(name, args))

    random.shuffle(rows)
    split = max(1, int(len(rows) * 0.9))
    train, test = rows[:split], rows[split:]
    (OUT / "train.jsonl").write_text(
        "".join(json.dumps(x, ensure_ascii=False) + "\n" for x in train),
        encoding="utf-8",
    )
    (OUT / "eval.jsonl").write_text(
        "".join(json.dumps(x, ensure_ascii=False) + "\n" for x in test),
        encoding="utf-8",
    )
    (OUT / "manifest.json").write_text(
        json.dumps(
            {
                "train_examples": len(train),
                "eval_examples": len(test),
                "total": len(rows),
                "source_evidence_files": len(research_files),
                "seed": seed,
                "task_style": "runtime_action_json",
                "tool_count": len(TOOLS),
                "runtime_contract": "action_json_v1",
                "includes_escalation_examples": True,
                "knowledge_classes_used": curriculum.get("class_reference", [])[:810] if curriculum_path.exists() else [],
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    print(json.dumps({"total": len(rows), "train": len(train), "eval": len(test), "tools": len(TOOLS)}))


if __name__ == "__main__":
    main()
