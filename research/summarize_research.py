from __future__ import annotations

import json
import os
from pathlib import Path
import urllib.request
import urllib.error

ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "build" / "agent_research" / "transcripts"
OUTPUT = ROOT / "build" / "agent_research" / "summaries.jsonl"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

base = os.getenv("FREELLMAPI_BASE_URL", "").strip().rstrip("/")
key = os.getenv("FREELLMAPI_API_KEY", "").strip()
model = os.getenv("FREELLMAPI_MODEL", "auto").strip() or "auto"

def call_llm(text: str) -> str:
    if not base or not key:
        return "SKIPPED_NO_FREELLMAPI"
    url = base if base.endswith("/v1") else base + "/v1"
    url += "/chat/completions"
    prompt = (
        "Summarize this game-development video transcript into original technical notes. "
        "Do not reproduce the transcript or long quotations. Extract concepts, workflows, "
        "Godot APIs mentioned, common mistakes, optimization practices, and testable actions. "
        "Keep it under 1200 words. Source material may be copyrighted, so produce a transformative summary only.\n\n"
        + text[:50000]
    )
    payload = {
        "model": model,
        "messages": [
            {"role":"system","content":"You are a game-engine research analyst focused on Godot 4.7.x."},
            {"role":"user","content":prompt},
        ],
        "temperature":0.1,
        "max_tokens":1600,
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type":"application/json","Authorization":f"Bearer {key}"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = json.loads(resp.read().decode())
        return str(body["choices"][0]["message"]["content"])
    except (urllib.error.URLError, urllib.error.HTTPError, KeyError, IndexError) as exc:
        return f"ERROR:{exc}"

rows = []
if INPUT.exists():
    for path in sorted(INPUT.glob("*.vtt")):
        rows.append({
            "source_file": path.name,
            "summary": call_llm(path.read_text(encoding="utf-8", errors="ignore")),
        })

with OUTPUT.open("w", encoding="utf-8") as fh:
    for row in rows:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")

print(f"wrote {len(rows)} research summaries")
