from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class ProviderConfig:
    name: str
    env_key: str
    priority: int
    capabilities: tuple[str, ...]


PROVIDERS = (
    # OmniRoute is deliberately represented as an optional runtime integration.
    # It is not required for the repository to boot and no OmniRoute secret is
    # committed here.
    ProviderConfig("omniroute", "OMNIROUTE_API_KEY", 100, ("text", "code", "routing")),
    ProviderConfig("gemini", "GEMINI_API_KEY", 90, ("text", "code", "reasoning")),
    ProviderConfig("nvidia", "NVIDIA_API_KEY", 80, ("text", "code", "reasoning", "multimodal")),
    ProviderConfig("nararouter", "NARAROUTER_API_KEY", 70, ("text", "code")),
    ProviderConfig("huggingface", "HF_TOKEN", 60, ("models", "datasets", "inference")),
)


def available_providers() -> list[ProviderConfig]:
    return [p for p in sorted(PROVIDERS, key=lambda x: x.priority, reverse=True) if os.getenv(p.env_key)]


def required_secret_names() -> list[str]:
    return [p.env_key for p in PROVIDERS]
