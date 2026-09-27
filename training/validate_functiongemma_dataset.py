from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'training' / 'data'

EXPECTED_TOOLS = {
    'project.summary','scene.tree','script.current','editor.play','editor.stop',
    'scene.add_node','scene.set_property','file.read_text','file.write_text',
    'asset.create_3d_character','asset.import_glb',
    'godot.api.summary','godot.api.query_classes','godot.api.class_info',
}

def fail(msg):
    print('DATASET_CHECK_FAILED:', msg)
    raise SystemExit(1)

def main():
    total = 0
    actions = 0
    escalations = 0

    for p in [DATA/'train.jsonl', DATA/'eval.jsonl']:
        if not p.exists():
            fail(f'missing {p}')
        for line_no, line in enumerate(p.read_text(encoding='utf-8').splitlines(), 1):
            if not line.strip():
                continue
            total += 1
            try:
                row = json.loads(line)
            except json.JSONDecodeError as exc:
                fail(f'{p}:{line_no}: invalid JSON: {exc}')

            msgs = row.get('messages')
            tools = row.get('tools')
            if not isinstance(msgs, list) or len(msgs) != 3:
                fail(f'{p}:{line_no}: expected exactly developer/user/assistant messages')
            if not isinstance(tools, list) or not tools:
                fail(f'{p}:{line_no}: tools missing')

            assistant = msgs[-1]
            if assistant.get('role') != 'assistant' or not isinstance(assistant.get('content'), str):
                fail(f'{p}:{line_no}: assistant action missing')

            try:
                action = json.loads(assistant['content'])
            except json.JSONDecodeError:
                fail(f'{p}:{line_no}: assistant content must be valid JSON')

            if not isinstance(action, dict) or action.get('action') not in {'tool_call','final'}:
                fail(f'{p}:{line_no}: invalid action schema')

            if action['action'] == 'tool_call':
                actions += 1
                if action.get('tool') not in EXPECTED_TOOLS:
                    fail(f'{p}:{line_no}: unknown tool {action.get("tool")}')
                if not isinstance(action.get('args', {}), dict):
                    fail(f'{p}:{line_no}: args must be an object')
            else:
                escalations += 1
                if action.get('result') != 'escalate':
                    fail(f'{p}:{line_no}: final action must be an escalation record')

    if total < 100:
        fail('dataset unexpectedly small')
    if actions + escalations != total:
        fail('action accounting mismatch')
    if escalations == 0:
        fail('no escalation examples present')

    print(json.dumps({
        'ok':True,
        'examples':total,
        'tool_actions':actions,
        'escalations':escalations,
        'expected_tools':len(EXPECTED_TOOLS),
    }))

if __name__=='__main__':
    main()
