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
    # API secrets/URLs should be ASCII. Remove invisible direction/format marks
    # that can be introduced by mobile clipboard or web forms.
    return ''.join(ch for ch in value if ord(ch) < 128).strip()


@dataclass(frozen=True)
class LLMConfig:
    local_base_url: str
    local_model: str
    freellm_base_url: str
    freellm_api_key: str
    freellm_model: str
    nara_api_key: str
    nara_base_url: str
    nara_model: str
    zai_api_key: str
    zai_base_url: str
    zai_model: str
    nvidia_api_key: str
    nvidia_base_url: str
    nvidia_model: str
    gemini_api_key: str
    gemini_model: str
    hf_token: str
    hf_model: str
    timeout: int = 90

    @classmethod
    def from_env(cls) -> 'LLMConfig':
        return cls(
            _clean(os.getenv('LOCAL_LLM_BASE_URL', '')),
            _clean(os.getenv('LOCAL_LLM_MODEL', 'HuggingFaceTB/SmolLM2-360M-Instruct-Q4_K_M.gguf')) or 'HuggingFaceTB/SmolLM2-360M-Instruct-Q4_K_M.gguf',
            _clean(os.getenv('FREELLMAPI_BASE_URL', '')),
            _clean(os.getenv('FREELLMAPI_API_KEY', '')),
            _clean(os.getenv('FREELLMAPI_MODEL', 'auto')) or 'auto',
            _clean(os.getenv('NARAROUTER_API_KEY', '')),
            _clean(os.getenv('NARAROUTER_BASE_URL', 'https://router.bynara.id/v1')).rstrip('/'),
            _clean(os.getenv('NARA_MODEL', os.getenv('NARAROUTER_MODEL', 'auto/bynara'))) or 'auto/bynara',
            _clean(os.getenv('Z_AI_API_KEY', '')),
            _clean(os.getenv('ZAI_BASE_URL', 'https://api.z.ai/api/paas/v4')).rstrip('/'),
            _clean(os.getenv('Z_AI_MODEL', os.getenv('ZAI_MODEL', 'glm-4.5-flash'))) or 'glm-4.5-flash',
            _clean(os.getenv('NVIDIA_API_KEY', '')),
            _clean(os.getenv('NVIDIA_BASE_URL', 'https://integrate.api.nvidia.com/v1')).rstrip('/'),
            _clean(os.getenv('NVIDIA_MODEL', 'meta/llama-3.3-70b-instruct')) or 'meta/llama-3.3-70b-instruct',
            _clean(os.getenv('GEMINI_API_KEY', '')),
            _clean(os.getenv('GEMINI_TEXT_MODEL', 'gemini-3.8-flash')) or 'gemini-3.8-flash',
            _clean(os.getenv('HF_TOKEN', '')),
            _clean(os.getenv('HF_MODEL', 'openai/gpt-oss-20b:fastest')) or 'openai/gpt-oss-20b:fastest',
        )


class OpenAICompatibleClient:
    # This is provider failover only. No model training or weight updates occur.
    def __init__(self, config: LLMConfig | None = None) -> None:
        self.config = config or LLMConfig.from_env()

    def enabled(self) -> bool:
        c = self.config
        return any([
            c.local_base_url,
            c.freellm_base_url and c.freellm_api_key,
            c.nara_api_key, c.zai_api_key, c.nvidia_api_key, c.gemini_api_key, c.hf_token,
        ])

    @staticmethod
    def _chat_openai(base_url: str, key: str, model: str, messages: list[dict[str, str]],
                     temperature: float, max_tokens: int, provider: str) -> dict[str, Any]:
        url = base_url.rstrip('/')
        if not url.endswith('/v1') and provider == 'freellmapi':
            url += '/v1'
        url += '/chat/completions'
        payload = {'model': model, 'messages': messages, 'temperature': temperature, 'max_tokens': max_tokens}
        request = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method='POST',
                                          headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {key}'})
        with urllib.request.urlopen(request, timeout=120) as response:
            body = json.loads(response.read().decode('utf-8'))
        choices = body.get('choices') or []
        if not choices:
            raise RuntimeError(f'{provider} response contains no choices')
        message = choices[0].get('message') or {}
        return {'content': str(message.get('content', '')), 'model': body.get('model', model),
                'usage': body.get('usage', {}), 'provider': provider}

    @staticmethod
    def _chat_gemini(key: str, model: str, messages: list[dict[str, str]],
                     temperature: float, max_tokens: int) -> dict[str, Any]:
        system_parts=[]; contents=[]
        for msg in messages:
            role=str(msg.get('role','user')); content=str(msg.get('content',''))
            if not content: continue
            if role == 'system': system_parts.append(content)
            else: contents.append({'role':'model' if role == 'assistant' else 'user','parts':[{'text':content}]})
        if not contents: contents=[{'role':'user','parts':[{'text':''}]}]
        url='https://generativelanguage.googleapis.com/v1beta/models/'+model+':generateContent'
        payload={'contents':contents,'generationConfig':{'temperature':temperature,'maxOutputTokens':max_tokens}}
        if system_parts: payload['systemInstruction']={'parts':[{'text':'\n\n'.join(system_parts)}]}
        request=urllib.request.Request(url,data=json.dumps(payload).encode('utf-8'),method='POST',
                                      headers={'Content-Type':'application/json','x-goog-api-key':key})
        with urllib.request.urlopen(request, timeout=120) as response:
            body=json.loads(response.read().decode('utf-8'))
        candidates=body.get('candidates') or []
        if not candidates: raise RuntimeError('Gemini response contains no candidates')
        parts=((candidates[0].get('content') or {}).get('parts') or [])
        content=''.join(str(p.get('text','')) for p in parts if isinstance(p,dict))
        if not content: raise RuntimeError('Gemini response contains no text')
        return {'content':content,'model':model,'usage':body.get('usageMetadata',{}),'provider':'gemini'}

    def chat(self, messages: list[dict[str, str]], *, temperature: float = 0.2, max_tokens: int = 1800) -> dict[str, Any]:
        if not self.enabled():
            raise RuntimeError('Configure at least one external LLM provider secret')
        c=self.config
        providers=[
            ('local', 'local', c.local_base_url, c.local_model),
            ('nvidia', c.nvidia_api_key, c.nvidia_base_url, c.nvidia_model),
            ('zai', c.zai_api_key, c.zai_base_url, c.zai_model),
            ('nara', c.nara_api_key, c.nara_base_url, c.nara_model),
            ('gemini', c.gemini_api_key, '', c.gemini_model),
            ('huggingface', c.hf_token, 'https://router.huggingface.co/v1', c.hf_model),
            ('freellmapi', c.freellm_api_key, c.freellm_base_url, c.freellm_model),
        ]
        errors=[]
        for provider,key,base_url,model in providers:
            if provider == 'local':
                if not base_url: continue
            elif not key:
                continue
            try:
                if provider == 'local':
                    return self._chat_openai(base_url, '', model, messages, temperature, max_tokens, provider)
                if provider == 'gemini':
                    return self._chat_gemini(key, model, messages, temperature, max_tokens)
                return self._chat_openai(base_url, key, model, messages, temperature, max_tokens, provider)
            except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, RuntimeError) as exc:
                errors.append(f'{provider}: {exc}')
        raise RuntimeError('All configured external LLM providers failed: ' + ' | '.join(errors))
