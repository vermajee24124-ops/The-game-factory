from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class LLMConfig:
    base_url: str
    api_key: str
    model: str
    timeout: int = 90

    @classmethod
    def from_env(cls) -> "LLMConfig":
        return cls(
            os.getenv("FREELLMAPI_BASE_URL", "").strip().rstrip("/"),
            os.getenv("FREELLMAPI_API_KEY", "").strip(),
            os.getenv("FREELLMAPI_MODEL", "auto").strip() or "auto",
        )


class OpenAICompatibleClient:
    def __init__(self, config: LLMConfig | None = None) -> None:
        self.config = config or LLMConfig.from_env()

    def enabled(self) -> bool:
        return bool(self.config.base_url and self.config.api_key)

    def chat(self, messages: list[dict[str, str]], *, temperature: float = 0.2,
             max_tokens: int = 1800) -> dict[str, Any]:
        if not self.enabled():
            raise RuntimeError("FREELLMAPI_BASE_URL and FREELLMAPI_API_KEY are required")

        url = self.config.base_url
        if not url.endswith("/v1"):
            url += "/v1"
        url += "/chat/completions"

        payload = {
            "model": self.config.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            method="POST",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.config.api_key}",
            },
        )

        try:
            with urllib.request.urlopen(request, timeout=self.config.timeout) as response:
                body = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "ignore")
            raise RuntimeError(f"LLM HTTP {exc.code}: {detail[:1200]}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f"LLM connection error: {exc}") from exc

        choices = body.get("choices") or []
        if not choices:
            raise RuntimeError("LLM response contains no choices")

        message = choices[0].get("message") or {}
        return {
            "content": str(message.get("content", "")),
            "model": body.get("model", self.config.model),
            "usage": body.get("usage", {}),
        }
