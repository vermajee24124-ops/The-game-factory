from __future__ import annotations

import re
from pathlib import Path
from typing import Any

PROJECT_ID = re.compile(r"\bGME-\d{4}-\d{4}\b", re.I)
SUPPORTED = {".docx", ".txt", ".md"}


def find_bible(root: Path) -> Path | None:
    inbox = root / "game_bible" / "inbox"
    if not inbox.exists():
        return None
    files = [p for p in inbox.rglob("*") if p.is_file() and p.suffix.lower() in SUPPORTED]
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime_ns)


def read_bible(path: Path) -> str:
    if path.suffix.lower() == ".docx":
        from docx import Document
        doc = Document(path)
        return "\n".join(p.text for p in doc.paragraphs if p.text.strip())
    return path.read_text(encoding="utf-8", errors="replace")


def extract_project_id(text: str) -> str | None:
    match = PROJECT_ID.search(text)
    return match.group(0).upper() if match else None


def extract_title(text: str) -> str:
    patterns = [
        r"GAME TITLE \(English\)\s*:\s*(.+)",
        r"GAME TITLE\s*:\s*(.+)",
        r"^#\s+(.+)$",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, re.I | re.M)
        if match:
            return match.group(1).strip()
    return "Untitled Game"


def summarize(path: Path) -> dict[str, Any]:
    text = read_bible(path)
    return {
        "source": str(path),
        "project_id": extract_project_id(text),
        "title": extract_title(text),
        "characters": len(re.findall(r"(?:character|vehicle|npc)", text, re.I)),
        "word_count": len(re.findall(r"\S+", text)),
    }
