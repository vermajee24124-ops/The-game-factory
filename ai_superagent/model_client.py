from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


def _clean(value: str) -> str:
    value = (value or '').strip()
    if value.startswith('\\'):
        value = value[1:].strip()
    return value


@dataclass(frozen=True)
class LLMConfig:
    base_url: str
    api_key: str
    model: str
    gemini_api_key: str = ''
    gemini_model: str = 'gemini-3.8-flash'
    timeout: int = 90

    @classmethod
    def from_env(cls) -> 'LLMConfig':
        return cls(
            _clean(os.getenv('FREELLMAPI_BASE_URL', '')).rstrip('/'),
            _clean(os.getenv('FREELLMAPI_API_KEY', '')),
            _clean(os.getenv('FREELLMAPI_MODEL', 'auto')) or 'auto',
            _clean(os.getenv('GEMINI_API_KEY', '')),
            _clean(os.getenv('GEMINI_TEXT_MODEL', 'gemini-3.8-flash')) or 'gemini-3.8-flash',
        )


class OpenAICompatibleClient:
    # External inference only. No model training or weight updates happen here.
    def __init__(self, config: LLMConfig | None = None) -> None:
        self.config = config or LLMConfig.from_env()

    def enabled(self) -> bool:
        return bool((self.config.base_url and self.config.api_key) or self.config.gemini_api_key)

    @staticmethod
    def _gemini_messages(messages: list[dict[str, str]]) -> tuple[str, list[dict[str, Any]]]:
        system_parts = []
        contents = []
        for msg in messages:
            role = str(msg.get('role', 'user'))
            content = str(msg.get('content', ''))
            if not content:
                continue
            if role == 'system':
                system_parts.append(content)
            else:
                contents.append({'role': 'model' if role == 'assistant' else 'user', 'parts': [{'text': content}]})
        if not contents:
            contents.append({'role': 'user', 'parts': [{'text': ''}]})
        return '\n\n'.join(system_parts), contents

    def _chat_freellm(self, messages: list[dict[str, str]], temperature: float, max_tokens: int) -> dict[str, Any]:
        url = self.config.base_url
        if not url.endswith('/v1'):
            url += '/v1'
        url += '/chat/completions'
        payload = {'model': self.config.model, 'messages': messages, 'temperature': temperature, 'max_tokens': max_tokens}
        request = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method='POST', headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {self.config.api_key}'})
        with urllib.request.urlopen(request, timeout=self.config.timeout) as response:
            body = json.loads(response.read().decode('utf-8'))
        choices = body.get('choices') or []
        if not choices:
            raise RuntimeError('FreeLLMAPI response contains no choices')
        message = choices[0].get('message') or {}
        return {'content': str(message.get('content', '')), 'model': body.get('model', self.config.model), 'usage': body.get('usage', {}), 'provider': 'freellmapi'}

    def _chat_gemini(self, messages: list[dict[str, str]], temperature: float, max_tokens: int) -> dict[str, Any]:
        if not self.config.gemini_api_key:
            raise RuntimeError('GEMINI_API_KEY is not configured')
        system_text, contents = self._gemini_messages(messages)
        url = 'https://generativelanguage.googleapis.com/v1beta/models/' + self.config.gemini_model + ':generateContent'
        payload: dict[str, Any] = {'contents': contents, 'generationConfig': {'temperature': temperature, 'maxOutputTokens': max_tokens}}
        if system_text:
            payload['systemInstruction'] = {'parts': [{'text': system_text}]}
        request = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method='POST', headers={'Content-Type': 'application/json', 'x-goog-api-key': self.config.gemini_api_key})
        with urllib.request.urlopen(request, timeout=max(self.config.timeout, 120)) as response:
            body = json.loads(response.read().decode('utf-8'))
        candidates = body.get('candidates') or []
        if not candidates:
            raise RuntimeError('Gemini response contains no candidates')
        parts = ((candidates[0].get('content') or {}).get('parts') or [])
        content = ''.join(str(p.get('text', '')) for p in parts if isinstance(p, dict))
        if not content:
            raise RuntimeError('Gemini response contains no text')
        return {'content': content, 'model': self.config.gemini_model, 'usage': body.get('usageMetadata', {}), 'provider': 'gemini'}

    def chat(self, messages: list[dict[str, str]], *, temperature: float = 0.2, max_tokens: int = 1800) -> dict[str, Any]:
        if not self.enabled():
            raise RuntimeError('Configure FREELLMAPI_BASE_URL/FREELLMAPI_API_KEY or GEMINI_API_KEY')
        errors = []
        if self.config.base_url and self.config.api_key:
            try:
                return self._chat_freellm(messages, temperature, max_tokens)
            except (urllib.error.URLError, urllib.error.HTTPError, RuntimeError) as exc:
                errors.append(f'FreeLLMAPI: {exc}')
        if self.config.gemini_api_key:
            try:
                return self._chat_gemini(messages, temperature, max_tokens)
            except (urllib.error.URLError, urllib.error.HTTPError, RuntimeError) as exc:
                errors.append(f'Gemini: {exc}')
        raise RuntimeError('All external LLM providers failed: ' + ' | '.join(errors))
