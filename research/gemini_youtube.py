from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API_KEY = os.getenv("GEMINI_API_KEY", "").strip()
MODEL = os.getenv("GEMINI_VIDEO_MODEL", "gemini-3.8-flash").strip()
URL = sys.argv[1] if len(sys.argv) > 1 else ""
if not API_KEY or not URL:
    raise SystemExit("GEMINI_API_KEY and a public YouTube URL are required")

endpoint = "https://generativelanguage.googleapis.com/v1beta/interactions"
prompt = (
    "You are a Godot 4.7.2 game-development research analyst. "
    "Understand this video using both its visuals and audio. "
    "Extract original technical notes, not a transcript. "
    "Focus on scene construction, editor actions, asset workflows, file organization, "
    "rendering, scripting, animation, physics, debugging, optimization, and reusable procedures. "
    "Mention important timestamps when available. Do not copy long quotations."
)
body = {
    "model": MODEL,
    "input": [
        {
            "type": "video",
            "uri": URL,
            "processing": "agentic",
        },
        {"type": "text", "text": prompt},
    ],
}
req = urllib.request.Request(
    endpoint,
    data=json.dumps(body).encode("utf-8"),
    method="POST",
    headers={
        "Content-Type": "application/json",
        "x-goog-api-key": API_KEY,
    },
)
try:
    with urllib.request.urlopen(req, timeout=900) as resp:
        result = json.loads(resp.read().decode("utf-8"))
except urllib.error.HTTPError as exc:
    raise SystemExit(f"Gemini HTTP {exc.code}: {exc.read().decode('utf-8','ignore')[:1200]}") from exc
except urllib.error.URLError as exc:
    raise SystemExit(f"Gemini connection error: {exc}") from exc

print(json.dumps({"url": URL, "model": MODEL, "response": result}, ensure_ascii=False))
