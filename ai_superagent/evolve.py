from __future__ import annotations
import json, os, re
from datetime import datetime, timezone
from pathlib import Path
from .model_client import OpenAICompatibleClient
from .research_context import load_research_context

ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / "ai_superagent" / "tasks.jsonl"
OUT = ROOT / "build" / "ai_superagent"
OUT.mkdir(parents=True, exist_ok=True)
SYSTEM = (ROOT / "ai_superagent" / "system_prompt.md").read_text(encoding="utf-8")
RESEARCH = load_research_context()
MAX_TASKS = int(os.getenv("SUPERAGENT_MAX_TASKS", "10"))

def parse_json(text: str) -> dict | None:
    text = text.strip()
    try:
        value = json.loads(text)
        return value if isinstance(value, dict) else None
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, re.S)
        if not match:
            return None
        try:
            value = json.loads(match.group(0))
            return value if isinstance(value, dict) else None
        except json.JSONDecodeError:
            return None

def main() -> int:
    client = OpenAICompatibleClient()
    if not client.enabled():
        report = {"status":"skipped","reason":"FREELLMAPI credentials not configured",
                  "timestamp":datetime.now(timezone.utc).isoformat()}
        (OUT / "latest_evolution.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
        print(json.dumps(report, indent=2))
        return 0
    tasks = [json.loads(x) for x in TASKS.read_text(encoding="utf-8").splitlines() if x.strip()][:MAX_TASKS]
    rows = []
    for task in tasks:
        user_prompt = (
            "Task ID: %s\nGoal: %s\n"
            "Return exactly one JSON object using action=tool_call or action=final. "
            "Do not invent Godot APIs."
        ) % (task["id"], task["prompt"])
        response = client.chat([
            {"role":"system","content":SYSTEM + ("\n\nResearch context:\n" + RESEARCH if RESEARCH else "")},
            {"role":"user","content":user_prompt}
        ], temperature=0.15, max_tokens=1600)
        parsed = parse_json(response["content"])
        rows.append({
            "task_id":task["id"], "difficulty":task["difficulty"],
            "response":parsed, "raw":response["content"][:8000],
            "valid_schema":isinstance(parsed, dict) and parsed.get("action") in {"tool_call","final"},
            "model":response.get("model"), "usage":response.get("usage", {})
        })
    score = sum(1 for r in rows if r["valid_schema"]) / max(1, len(rows))
    report = {"status":"completed","timestamp":datetime.now(timezone.utc).isoformat(),
              "tasks":len(rows),"strict_json_rate":score}
    (OUT / "latest_evolution.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    with (OUT / "tool_use_trajectories.jsonl").open("w", encoding="utf-8") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False)+"\n")
    print(json.dumps(report, indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
