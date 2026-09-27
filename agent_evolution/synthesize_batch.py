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

    try:
        data = client.chat(
            [{'role': 'system', 'content': system}, {'role': 'user', 'content': user}],
            temperature=0.1,
            max_tokens=5000,
        )
        items = extract_json_array(data['content'])
    except Exception as exc:
        # Keep the research loop productive during provider outages. This fallback
        # creates concise, non-copied skill records from already extracted Gemini
        # notes; a later cycle can re-synthesize them with a stronger provider.
        data = {'model': 'offline-fallback', 'provider': 'local-extractor', 'error': str(exc)}
        items = []
        for note in notes:
            title = str(note.get('title') or 'Godot workflow')
            analysis = note.get('notes', '')
            items.append({
                'name': 'research_' + re.sub(r'[^a-z0-9]+', '_', title.lower()).strip('_')[:64],
                'domain': 'godot_research',
                'skill': 'Apply the verified technical observations from this research item to future Godot work.',
                'tools': ['scene.tree', 'project.summary', 'file.read_text', 'file.write_text', 'asset.create_3d_character', 'asset.import_glb'],
                'procedure': ['Inspect current project state.', 'Select only relevant Godot tools.', 'Make the smallest change.', 'Run verification before continuing.'],
                'verification': ['Confirm the target exists.', 'Confirm the change is limited to the requested scope.', 'Run a smoke test when practical.'],
                'pitfalls': ['Do not invent APIs.', 'Do not copy source text.', 'Escalate unsupported claims for later review.'],
                'benchmark_prompt': 'Reproduce the useful Godot procedure described by this research item: ' + title,
                'evidence_summary': analysis[:1500],
            })
        # Keep the learning store useful during provider outages.
        # When Gemini notes are empty, derive durable domain playbooks from
        # the verified Godot 4.7.2 curriculum instead of recording zero skills.
        if not items:
            curriculum = json.loads(CURRICULUM.read_text(encoding='utf-8'))
            class_rows = curriculum.get('class_reference', [])
            for domain in curriculum.get('domains', []):
                examples = []
                domain_text = str(domain).lower()
                for row in class_rows:
                    hay = (
                        str(row.get('name', '')) + ' ' +
                        str(row.get('inherits', '')) + ' ' +
                        str(row.get('brief', ''))
                    ).lower()
                    if domain_text in hay:
                        examples.append(row.get('name'))
                    if len(examples) >= 20:
                        break
                items.append({
                    'name': 'curriculum_' + re.sub(r'[^a-z0-9]+', '_', str(domain).lower()).strip('_'),
                    'domain': str(domain),
                    'skill': 'Use verified Godot 4.7.2 API evidence and live ClassDB inspection for ' + str(domain) + ' tasks; prefer small verified edits and escalate uncertain work.',
                    'tools': ['godot.api.summary', 'godot.api.query_classes', 'godot.api.class_info', 'project.summary', 'scene.tree', 'scene.node_info', 'scene.verify_property', 'scene.save'],
                    'procedure': [
                        'Identify the relevant Godot domain.',
                        'Inspect the current project and live API.',
                        'Select only the required executable tools.',
                        'Apply the smallest change.',
                        'Read back the result and save the scene when appropriate.',
                        'Run a smoke test for meaningful changes.',
                    ],
                    'verification': [
                        'The requested target exists.',
                        'The used class/property/method is present in live ClassDB when applicable.',
                        'The final scene/project state matches the request.',
                        'No unrelated files or nodes changed.',
                    ],
                    'pitfalls': [
                        'Never invent Godot APIs.',
                        'Do not assume a community addon is built in.',
                        'Do not skip read-back verification after writes.',
                        'Escalate complex multimodal or architecture tasks.',
                    ],
                    'benchmark_prompt': 'Complete a representative Godot 4.7.2 ' + str(domain) + ' task using API inspection, minimal edits, verification and save.',
                    'curriculum_class_examples': examples,
                })
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
