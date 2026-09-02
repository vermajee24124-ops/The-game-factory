from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class ResearchTarget:
    name: str
    urls: tuple[str, ...]
    purpose: str


OFFICIAL_RESEARCH_TARGETS: tuple[ResearchTarget, ...] = (
    ResearchTarget("Godot", ("https://godotengine.org/download/archive/", "https://docs.godotengine.org/"), "engine release and compatibility"),
    ResearchTarget("Google Play", ("https://support.google.com/googleplay/android-developer/", "https://developer.android.com/"), "store, billing, ads and policy requirements"),
    ResearchTarget("Apple", ("https://developer.apple.com/app-store/review/guidelines/", "https://developer.apple.com/kids/"), "store, billing, privacy and kids requirements"),
    ResearchTarget("Amazon Appstore", ("https://developer.amazon.com/docs/appstore/",), "store and monetization requirements"),
    ResearchTarget("Hugging Face", ("https://huggingface.co/docs/hub/",), "models, datasets and storage policy"),
    ResearchTarget("GitHub", ("https://docs.github.com/",), "repository, Actions and security requirements"),
)


def research_manifest() -> dict[str, Any]:
    return {
        "priority": ["official", "verified-open-source", "other"],
        "targets": [
            {"name": t.name, "urls": list(t.urls), "purpose": t.purpose}
            for t in OFFICIAL_RESEARCH_TARGETS
        ],
        "policy": {
            "never_claim_approval": True,
            "block_release_on_known_critical_issue": True,
            "record_sources_and_retrieval_time": True,
        },
    }
