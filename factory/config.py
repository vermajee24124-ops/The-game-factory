from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class ProviderConfig:
    name: str
    env_key: str | None
    priority: int
    capabilities: tuple[str, ...]


PROVIDERS = (
    # OmniRoute is a gateway installed by the workflow. It can be available
    # without a provider secret when configured with no-auth/free providers.
    # If an authenticated OmniRoute endpoint is used later, its API key can be
    # supplied through OMNIROUTE_API_KEY without changing the orchestrator.
    ProviderConfig("omniroute", "OMNIROUTE_API_KEY", 100, ("text", "code", "reasoning", "routing", "multimodal")),
    ProviderConfig("z-ai", "Z_AI_API_KEY", 95, ("text", "code", "reasoning")),
    ProviderConfig("gemini", "GEMINI_API_KEY", 90, ("text", "code", "reasoning", "multimodal")),
    ProviderConfig("nvidia", "NVIDIA_API_KEY", 80, ("text", "code", "reasoning", "multimodal")),
    ProviderConfig("nararouter", "NARAROUTER_API_KEY", 70, ("text", "code", "reasoning")),
    ProviderConfig("huggingface", "HF_TOKEN", 60, ("models", "datasets", "inference", "multimodal")),
)


def available_providers() -> list[ProviderConfig]:
    """Return providers that have the required runtime credential available.

    OmniRoute itself is installed at runtime. Its provider availability is
    checked by the OmniRoute adapter rather than by requiring a permanent
    GitHub secret in this module.
    """
    result: list[ProviderConfig] = []
    for provider in sorted(PROVIDERS, key=lambda x: x.priority, reverse=True):
        if provider.name == "omniroute":
            result.append(provider)
        elif provider.env_key and os.getenv(provider.env_key):
            result.append(provider)
    return result


def required_secret_names() -> list[str]:
    return [p.env_key for p in PROVIDERS if p.env_key and p.name != "omniroute"]
