from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'training' / 'data'

EXPECTED_TOOLS = {
    'project.summary','scene.tree','scene.node_info','scene.verify_property','scene.save','script.current','editor.play','editor.stop',
    'scene.add_node','scene.set_property','file.read_text','file.write_text',
    'asset.create_3d_character','asset.import_glb',
    'godot.api.summary','godot.api.query_classes','godot.api.class_info',
}

def fail(msg):
    print('DATASET_CHECK_FAILED:', msg)
    raise SystemExit(1)

def main():
    train=DATA/'train.jsonl'; ev=DATA/'eval.jsonl'
    for p in [train,ev]:
        if not p.exists(): fail(f'missing {p}')
    total=0; valid=0
    for p in [train,ev]:
        for line_no,line in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
            if not line.strip(): continue
            total+=1
            try: row=json.loads(line)
            except json.JSONDecodeError as e: fail(f'{p}:{line_no}: invalid JSON: {e}')
            text=row.get('text','')
            if not isinstance(text,str) or 'ASSISTANT:' not in text: fail(f'{p}:{line_no}: missing training text')
            marker=text.split('ASSISTANT:',1)[1].split('\n',1)[0].strip()
            try: action=json.loads(marker)
            except json.JSONDecodeError as e: fail(f'{p}:{line_no}: invalid action JSON: {e}')
            if action.get('action') == 'tool_call':
                if not isinstance(action.get('tool'),str) or not isinstance(action.get('args'),dict):
                    fail(f'{p}:{line_no}: invalid tool-call schema')
            elif action.get('action') == 'final':
                if action.get('result') != 'escalate' or not isinstance(action.get('evidence'),list):
                    fail(f'{p}:{line_no}: invalid escalation schema')
            else:
                fail(f'{p}:{line_no}: invalid action schema')
            valid+=1
    if total<100: fail('dataset unexpectedly small')
    if valid!=total: fail('not all examples validated')
    print(json.dumps({'ok':True,'examples':total,'valid_actions':valid}))
if __name__=='__main__':
    main()
