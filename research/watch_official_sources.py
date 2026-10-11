#!/usr/bin/env python3
"""Fetch a small, source-attributed live update for the Game Factory.

Uses public endpoints only. No model/API key is required and Gemini is never called.
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "research" / "live_watch_latest.json"
OUT_MD = ROOT / "research" / "live_watch_latest.md"
TIMEOUT = 20
USER_AGENT = "The-Game-Factory-Live-Research-Watch/1.0"


def get_json(url: str, accept: str = "application/json") -> Any:
    request = urllib.request.Request(
        url,
        headers={"Accept": accept, "User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return json.load(response)


def attempt(name: str, url: str, fn) -> dict[str, Any]:
    entry: dict[str, Any] = {
        "source": name,
        "url": url,
        "retrieved_at": datetime.now(timezone.utc).isoformat(),
        "status": "ok",
        "items": [],
    }
    try:
        entry["items"] = fn()
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError, KeyError, TypeError) as exc:
        entry["status"] = "error"
        entry["error"] = f"{type(exc).__name__}: {str(exc)[:300]}"
    return entry


def godot_releases() -> list[dict[str, Any]]:
    url = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
    data = get_json(url, "application/vnd.github+json")
    results = []
    for item in data:
        tag = str(item.get("tag_name", ""))
        if item.get("draft") or item.get("prerelease") or not tag.endswith("-stable"):
            continue
        results.append({
            "name": item.get("name") or tag,
            "tag": tag,
            "published_at": item.get("published_at"),
            "url": item.get("html_url"),
        })
    return results[:5]


def github_godot_ai() -> list[dict[str, Any]]:
    query = urllib.parse.quote("Godot MCP AI agent")
    url = f"https://api.github.com/search/repositories?q={query}&sort=updated&per_page=8"
    data = get_json(url, "application/vnd.github+json")
    results = []
    for item in data.get("items", []):
        license_info = item.get("license") or {}
        results.append({
            "name": item.get("full_name"),
            "description": item.get("description"),
            "url": item.get("html_url"),
            "updated_at": item.get("updated_at"),
            "stars": item.get("stargazers_count"),
            "license": license_info.get("spdx_id"),
        })
    return results


def huggingface_godot_models() -> list[dict[str, Any]]:
    query = urllib.parse.quote("godot")
    url = f"https://huggingface.co/api/models?search={query}&limit=10&sort=lastModified&direction=-1"
    data = get_json(url)
    results = []
    for item in data:
        model_id = item.get("id") or item.get("modelId")
        if not model_id:
            continue
        results.append({
            "id": model_id,
            "url": f"https://huggingface.co/{model_id}",
            "last_modified": item.get("lastModified"),
            "pipeline_tag": item.get("pipeline_tag"),
            "downloads": item.get("downloads"),
            "likes": item.get("likes"),
        })
    return results


def write_reports(payload: dict[str, Any]) -> None:
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    lines = [
        "# Game Factory Live Research Watch",
        "",
        f"- Retrieved at (UTC): {payload['retrieved_at']}",
        "- Uses public metadata endpoints only; no LLM/Gemini quota is consumed by this watcher.",
        "- A result is a candidate for human/agent review, not automatic approval to install or ship it.",
        "",
    ]
    for section in payload["sections"]:
        lines.extend([f"## {section['source']}", "", f"Source: {section['url']}", f"Status: **{section['status']}**", ""])
        if section.get("error"):
            lines.extend([f"Request note: {section['error']}", ""])
        if not section.get("items"):
            lines.extend(["No items returned.", ""])
            continue
        for item in section["items"]:
            if section["source"] == "Godot stable releases":
                lines.append(f"- [{item.get('name')}]({item.get('url')}) | {item.get('tag')} | published: {item.get('published_at')}")
            elif section["source"] == "GitHub Godot AI/MCP repositories":
                lines.append(
                    f"- [{item.get('name')}]({item.get('url')}) | updated: {item.get('updated_at')} "
                    f"| stars: {item.get('stars')} | license: {item.get('license') or 'not stated'}"
                )
                if item.get("description"):
                    lines.append(f"  - {item['description']}")
            else:
                lines.append(
                    f"- [{item.get('id')}]({item.get('url')}) | updated: {item.get('last_modified')} "
                    f"| task: {item.get('pipeline_tag') or 'not stated'}"
                )
        lines.append("")
    lines.extend([
        "## Review rules",
        "",
        "- Confirm version compatibility with the pinned Godot version before use.",
        "- Verify each source's license and dependency permissions before adding it.",
        "- Do not upload private material or secrets to public locations.",
        "- Public repository/model discovery does not prove commercial-use or training rights.",
        "",
    ])
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    now = datetime.now(timezone.utc).isoformat()
    sections = [
        attempt(
            "Godot stable releases",
            "https://api.github.com/repos/godotengine/godot/releases?per_page=10",
            godot_releases,
        ),
        attempt(
            "GitHub Godot AI/MCP repositories",
            "https://api.github.com/search/repositories?q=Godot%20MCP%20AI%20agent&sort=updated&per_page=8",
            github_godot_ai,
        ),
        attempt(
            "Hugging Face Godot models",
            "https://huggingface.co/api/models?search=godot&limit=10&sort=lastModified&direction=-1",
            huggingface_godot_models,
        ),
    ]
    payload = {
        "schema_version": 1,
        "retrieved_at": now,
        "purpose": "low-cost live discovery for the Autonomous Godot Game Factory",
        "model_calls": 0,
        "gemini_calls": 0,
        "sections": sections,
    }
    write_reports(payload)
    errors = sum(1 for section in sections if section["status"] != "ok")
    print(f"Wrote live research report; sections={len(sections)}, errors={errors}, Gemini calls=0.")
    return 0 if errors < len(sections) else 1


if __name__ == "__main__":
    raise SystemExit(main())
