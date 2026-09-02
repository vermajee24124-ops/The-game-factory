from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class Provider:
    name: str
    env_key: str | None
    priority: int
    capabilities: frozenset[str]


PROVIDERS: tuple[Provider, ...] = (
    Provider("omniroute", None, 100, frozenset({"text", "code", "reasoning", "multimodal", "routing"})),
    Provider("z-ai", "Z_AI_API_KEY", 95, frozenset({"text", "code", "reasoning"})),
    Provider("gemini", "GEMINI_API_KEY", 90, frozenset({"text", "code", "reasoning", "multimodal"})),
    Provider("nvidia", "NVIDIA_API_KEY", 80, frozenset({"text", "code", "reasoning", "multimodal"})),
    Provider("nararouter", "NARAROUTER_API_KEY", 70, frozenset({"text", "code", "reasoning"})),
    Provider("huggingface", "HF_TOKEN", 60, frozenset({"inference", "models", "datasets", "multimodal"})),
)


def available() -> list[Provider]:
    result: list[Provider] = []
    for provider in sorted(PROVIDERS, key=lambda p: p.priority, reverse=True):
        if provider.env_key is None or os.getenv(provider.env_key):
            result.append(provider)
    return result


def select(capability: str, exclude: Iterable[str] = ()) -> Provider | None:
    excluded = {x.lower() for x in exclude}
    candidates = [p for p in available() if capability in p.capabilities and p.name not in excluded]
    return candidates[0] if candidates else None
