from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


def _clean(value: str) -> str:
    value = (value or '').strip()
    while value.startswith('\\'):
        value = value[1:].strip()
    return value


@dataclass(frozen=True)
class Provider:
    name: str
    base_url: str
    api_key: str
    model: str


class OpenAICompatibleClient:
    '''Resilient external-LLM router. It never trains or updates model weights.'''

    def __init__(self) -> None:
        self.providers = self._load_providers()

    def _load_providers(self) -> list[Provider]:
        providers: list[Provider] = []
        candidates = [
            ('nvidia', 'https://integrate.api.nvidia.com/v1', 'NVIDIA_API_KEY', 'NVIDIA_MODEL', 'z-ai/glm-5.3-flash'),
            ('gemini', 'https://generativelanguage.googleapis.com/v1beta', 'GEMINI_API_KEY', 'GEMINI_TEXT_MODEL', 'gemini-3.8-flash'),
            ('zai', 'https://api.z.ai/api/paas/v4', 'Z_AI_API_KEY', 'Z_AI_MODEL', 'glm-5.3-flash'),
            ('nara', 'https://router.bynara.id/v1', 'NARAROUTER_API_KEY', 'NARA_MODEL', 'deepseek-v4-flash'),
            ('huggingface', 'https://router.huggingface.co/v1', 'HF_TOKEN', 'HF_MODEL', 'openai/gpt-oss-20b:fastest'),
            ('freellmapi', _clean(os.getenv('FREELLMAPI_BASE_URL', '')).rstrip('/'), 'FREELLMAPI_API_KEY', 'FREELLMAPI_MODEL', 'auto'),
        ]
        for name, base, key_name, model_name, default_model in candidates:
            key = _clean(os.getenv(key_name, ''))
            base_url = _clean(base)
            model = _clean(os.getenv(model_name, default_model)) or default_model
            if key and base_url:
                providers.append(Provider(name, base_url.rstrip('/'), key, model))
        return providers

    def enabled(self) -> bool:
        return bool(self.providers)

    @staticmethod
    def _http_json(url: str, api_key: str, payload: dict[str, Any], timeout: int = 120) -> dict[str, Any]:
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode('utf-8'),
            method='POST',
            headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {api_key}'},
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return json.loads(response.read().decode('utf-8'))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode('utf-8', 'ignore')
            raise RuntimeError(f'HTTP {exc.code}: {detail[:800]}') from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f'connection error: {exc}') from exc

    @staticmethod
    def _extract_openai(body: dict[str, Any], provider: str, model: str) -> dict[str, Any]:
        choices = body.get('choices') or []
        if not choices:
            raise RuntimeError('response contains no choices')
        message = choices[0].get('message') or {}
        return {'content': str(message.get('content', '')), 'model': body.get('model', model), 'usage': body.get('usage', {}), 'provider': provider}

    def _chat_openai_compatible(self, p: Provider, messages: list[dict[str, str]], temperature: float, max_tokens: int) -> dict[str, Any]:
        payload = {'model': p.model, 'messages': messages, 'temperature': temperature, 'max_tokens': max_tokens, 'stream': False}
        body = self._http_json(p.base_url + '/chat/completions', p.api_key, payload)
        return self._extract_openai(body, p.name, p.model)

    def _chat_gemini(self, p: Provider, messages: list[dict[str, str]], temperature: float, max_tokens: int) -> dict[str, Any]:
        system_parts = []
        contents: list[dict[str, Any]] = []
        for msg in messages:
            role = msg.get('role', 'user')
            content = str(msg.get('content', ''))
            if role == 'system':
                system_parts.append(content)
            elif content:
                contents.append({'role': 'model' if role == 'assistant' else 'user', 'parts': [{'text': content}]})
        if not contents:
            contents.append({'role': 'user', 'parts': [{'text': ''}]})
        payload: dict[str, Any] = {'contents': contents, 'generationConfig': {'temperature': temperature, 'maxOutputTokens': max_tokens}}
        if system_parts:
            payload['systemInstruction'] = {'parts': [{'text': '\n\n'.join(system_parts)}]}
        body = self._http_json(p.base_url + '/models/' + p.model + ':generateContent', p.api_key, payload)
        candidates = body.get('candidates') or []
        if not candidates:
            raise RuntimeError('Gemini response contains no candidates')
        parts = ((candidates[0].get('content') or {}).get('parts') or [])
        content = ''.join(str(part.get('text', '')) for part in parts if isinstance(part, dict))
        if not content:
            raise RuntimeError('Gemini response contains no text')
        return {'content': content, 'model': p.model, 'usage': body.get('usageMetadata', {}), 'provider': 'gemini'}

    def chat(self, messages: list[dict[str, str]], *, temperature: float = 0.2, max_tokens: int = 1800) -> dict[str, Any]:
        if not self.providers:
            raise RuntimeError('No external LLM provider credentials are configured')
        errors: list[str] = []
        for p in self.providers:
            try:
                if p.name == 'gemini':
                    result = self._chat_gemini(p, messages, temperature, max_tokens)
                else:
                    result = self._chat_openai_compatible(p, messages, temperature, max_tokens)
                if not result['content'].strip():
                    raise RuntimeError('empty model response')
                return result
            except (urllib.error.URLError, urllib.error.HTTPError, RuntimeError, TimeoutError) as exc:
                errors.append(f'{p.name}: {exc}')
                continue
        raise RuntimeError('All configured external LLM providers failed: ' + ' | '.join(errors))
