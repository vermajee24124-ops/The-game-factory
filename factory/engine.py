from __future__ import annotations

import json
import urllib.request
from dataclasses import dataclass
from typing import Any


GODOT_RELEASES_API = "https://api.github.com/repos/godotengine/godot/releases?per_page=30"


@dataclass(frozen=True)
class EngineRelease:
    version: str
    tag: str
    published_at: str
    prerelease: bool


def fetch_releases(timeout: int = 15) -> list[EngineRelease]:
    request = urllib.request.Request(
        GODOT_RELEASES_API,
        headers={"Accept": "application/vnd.github+json", "User-Agent": "The-Game-Factory"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        data: list[dict[str, Any]] = json.load(response)
    releases: list[EngineRelease] = []
    for item in data:
        tag = str(item.get("tag_name", ""))
        name = str(item.get("name", tag))
        if item.get("draft") or item.get("prerelease"):
            continue
        if tag.endswith("-stable") and name:
            version = tag.removesuffix("-stable")
            releases.append(EngineRelease(version, tag, str(item.get("published_at", "")), False))
    return releases


def latest_stable(timeout: int = 15) -> EngineRelease:
    releases = fetch_releases(timeout)
    if not releases:
        raise RuntimeError("No stable Godot release was returned by the official release API")
    return releases[0]
