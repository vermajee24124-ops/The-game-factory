from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'training'/'data'

def fail(msg):
    print('DATASET_CHECK_FAILED:',msg)
    raise SystemExit(1)

def main():
    train=DATA/'train.jsonl'; ev=DATA/'eval.jsonl'
    for p in [train,ev]:
        if not p.exists(): fail(f'missing {p}')
    total=0
    tool_calls=0
    for p in [train,ev]:
        for line_no,line in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
            if not line.strip(): continue
            total+=1
            try: row=json.loads(line)
            except json.JSONDecodeError as e: fail(f'{p}:{line_no}: invalid JSON: {e}')
            msgs=row.get('messages'); tools=row.get('tools')
            if not isinstance(msgs,list) or not msgs: fail(f'{p}:{line_no}: messages missing')
            if not isinstance(tools,list) or not tools: fail(f'{p}:{line_no}: tools missing')
            for tcmsg in [m for m in msgs if m.get('role')=='assistant' and m.get('tool_calls')]:
                for tc in tcmsg['tool_calls']:
                    tool_calls+=1
                    fn=tc.get('function',{})
                    if not tc.get('id') or tc.get('type')!='function': fail(f'{p}:{line_no}: malformed tool call')
                    if not fn.get('name'): fail(f'{p}:{line_no}: tool name missing')
                    args=fn.get('arguments')
                    if not isinstance(args,str): fail(f'{p}:{line_no}: arguments must be JSON string')
                    try: json.loads(args)
                    except json.JSONDecodeError: fail(f'{p}:{line_no}: arguments invalid JSON')
            for m in msgs:
                if m.get('role')=='tool' and not m.get('tool_call_id'): fail(f'{p}:{line_no}: tool response missing tool_call_id')
    if total<100: fail('dataset unexpectedly small')
    if tool_calls<total: fail('not every example has a tool call')
    print(json.dumps({'ok':True,'examples':total,'tool_calls':tool_calls}))

if __name__=='__main__': main()
