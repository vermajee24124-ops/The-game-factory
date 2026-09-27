from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from ai_superagent.model_client import OpenAICompatibleClient

ROOT = Path(__file__).resolve().parents[1]
NOTES = ROOT / 'build' / 'agent_research' / 'gemini_visual_notes.jsonl'
CURRICULUM = ROOT / 'knowledge' / 'agent_curriculum.json'
OUT = ROOT / 'agent_evolution' / 'learned'
OUT.mkdir(parents=True, exist_ok=True)


def extract_json_array(text: str):
    text = text.strip()
    if text.startswith('```'):
        text = re.sub(r'^```(?:json)?\s*', '', text)
        text = re.sub(r'\s*```$', '', text).strip()
    try:
        value = json.loads(text)
        if isinstance(value, list):
            return value
    except json.JSONDecodeError:
        pass
    start = text.find('[')
    end = text.rfind(']')
    if start >= 0 and end > start:
        try:
            value = json.loads(text[start:end + 1])
            if isinstance(value, list):
                return value
        except json.JSONDecodeError:
            pass
    raise RuntimeError('Skill synthesis did not return a valid JSON array')


def main() -> int:
    if not NOTES.exists():
        raise SystemExit('Gemini visual research notes are missing')

    client = OpenAICompatibleClient()
    if not client.enabled():
        raise SystemExit('Configure FREELLMAPI_BASE_URL/FREELLMAPI_API_KEY or GEMINI_API_KEY')

    notes = []
    for line in NOTES.read_text(encoding='utf-8').splitlines():
        if line.strip():
            item = json.loads(line)
            notes.append({
                'url': item.get('source', {}).get('url'),
                'title': item.get('source', {}).get('title'),
                'notes': json.dumps(item.get('analysis', {}), ensure_ascii=False)[:7000],
            })

    system = (
        'You are the skill architect for a Godot 4.7.2 autonomous game-development agent. '
        'Do not train an LLM. Convert research into durable agent skills, tool playbooks, '
        'verification procedures and benchmark tasks. Do not copy long source text. '
        'Return ONLY a JSON array where each item contains: name, domain, skill, tools, '
        'procedure, verification, pitfalls, benchmark_prompt.'
    )
    user = (
        'Synthesize these research notes into reusable agent skills. '
        'Merge duplicates and ignore unsupported claims.\n\n'
        + json.dumps(notes, ensure_ascii=False)
        + '\n\nCurriculum inventory:\n'
        + CURRICULUM.read_text(encoding='utf-8')[:18000]
    )

    data = client.chat(
        [{'role': 'system', 'content': system}, {'role': 'user', 'content': user}],
        temperature=0.1,
        max_tokens=5000,
    )

    items = extract_json_array(data['content'])
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    path = OUT / f'research-batch-{stamp}.json'
    path.write_text(
        json.dumps(
            {
                'generated_at': stamp,
                'model': data.get('model'),
                'provider': data.get('provider'),
                'skills': items,
            },
            ensure_ascii=False,
            indent=2,
        ) + '\n',
        encoding='utf-8',
    )
    print(json.dumps({
        'skills': len(items),
        'output': str(path),
        'model': data.get('model'),
        'provider': data.get('provider'),
    }))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
