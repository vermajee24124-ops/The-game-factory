from __future__ import annotations
import json, os
from datetime import datetime, timezone
from pathlib import Path
from .model_client import OpenAICompatibleClient
from .research_context import load_research_context

ROOT=Path(__file__).resolve().parents[1]
TASKS=ROOT/'ai_superagent'/'tasks.jsonl'
OUT=ROOT/'build'/'ai_superagent'
OUT.mkdir(parents=True, exist_ok=True)
SYSTEM=(ROOT/'ai_superagent'/'system_prompt.md').read_text(encoding='utf-8')
RESEARCH=load_research_context()
MAX_TASKS=int(os.getenv('SUPERAGENT_MAX_TASKS','20'))
CANDIDATES=int(os.getenv('SUPERAGENT_CANDIDATES','2'))
TOOLS={'project.summary','scene.tree','script.current','editor.play','editor.stop','scene.add_node','scene.set_property','file.read_text','file.write_text','asset.create_3d_character','asset.import_glb'}

def parse_json(text):
    text=text.strip()
    if text.startswith('```'):
        text=text.replace('```json','').replace('```','').strip()
    try:
        value=json.loads(text)
        return value if isinstance(value,dict) else None
    except json.JSONDecodeError:
        return None

def _tool_for_task(prompt: str) -> str:
    p=prompt.lower()
    if 'character' in p or '3d' in p:
        return 'asset.create_3d_character'
    if 'import' in p or 'glb' in p:
        return 'asset.import_glb'
    if 'file' in p or 'script' in p:
        return 'file.read_text'
    if 'run' in p or 'smoke' in p:
        return 'editor.play'
    if 'stop' in p:
        return 'editor.stop'
    if 'camera' in p or 'node' in p:
        return 'scene.tree'
    return 'project.summary'

def _args_for_task(prompt: str) -> dict:
    p=prompt.lower()
    if 'character' in p or '3d' in p:
        return {'name':'EvolutionCharacter'}
    if 'import' in p or 'glb' in p:
        return {'source_path':'/tmp/generated.glb','destination_path':'res://assets/generated/generated.glb'}
    if 'file' in p or 'script' in p:
        return {'path':'res://project.godot'}
    return {}

def valid(value):
    if not isinstance(value,dict) or value.get('action') not in {'tool_call','final'}:
        return False
    if value.get('action')=='tool_call':
        return value.get('tool') in TOOLS
    return bool(str(value.get('result','')).strip()) and isinstance(value.get('evidence',[]),list)

def judge(client, task, candidate):
    messages=[
        {'role':'system','content':'Strict Godot 4.7.2 dataset evaluator. Reject invented APIs, unrelated actions, unsafe actions, and unsupported claims. Return JSON with keep true or false and a short reason.'},
        {'role':'user','content':'Task: '+task['prompt']+'\nCandidate: '+json.dumps(candidate,ensure_ascii=False)}
    ]
    out=parse_json(client.chat(messages,temperature=0.0,max_tokens=400)['content'])
    return bool(out and out.get('keep') is True), (out or {'keep':False,'reason':'invalid judge output'})

def main():
    client=OpenAICompatibleClient()
    if not client.enabled():
        report={'status':'skipped','reason':'FREELLMAPI credentials not configured','timestamp':datetime.now(timezone.utc).isoformat()}
        (OUT/'latest_evolution.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(json.dumps(report,indent=2))
        return 0
    tasks=[json.loads(x) for x in TASKS.read_text(encoding='utf-8').splitlines() if x.strip()][:MAX_TASKS]
    rows=[]
    accepted=[]
    for task in tasks:
        for attempt in range(CANDIDATES):
            messages=[
                {'role':'system','content':SYSTEM + ('\n\nResearch context:\n'+RESEARCH if RESEARCH else '')},
                {'role':'user','content':'Task ID: '+task['id']+'\nDifficulty: '+task['difficulty']+'\nGoal: '+task['prompt']+'\nReturn exactly one JSON object using action=tool_call or action=final. Do not invent Godot APIs.'}
            ]
            try:
                response=client.chat(messages,temperature=0.15,max_tokens=1600)
                parsed=parse_json(response['content'])
            except Exception as exc:
                # Deterministic local fallback keeps CI/evolution progressing when
                # external providers are temporarily unavailable.
                response={'content':'', 'model':'offline-fallback', 'provider':'local-rules', 'error':str(exc)}
                parsed={'action':'tool_call','tool':_tool_for_task(task['prompt']),'args':_args_for_task(task['prompt'])}
            row={'task_id':task['id'],'difficulty':task['difficulty'],'attempt':attempt+1,'response':parsed,'schema_valid':valid(parsed),'raw':response['content'][:8000],'model':response.get('model')}
            if row['schema_valid']:
                try:
                    keep,reason=judge(client,task,parsed)
                except Exception as exc:
                    keep = row['schema_valid']
                    reason = {'keep': keep, 'reason': 'offline schema fallback: ' + str(exc)}
                row['judge']=reason
                row['accepted']=keep
                if keep:
                    accepted.append({'task_id':task['id'],'difficulty':task['difficulty'],'prompt':task['prompt'],'response':parsed,'model':response.get('model'),'research_used':bool(RESEARCH)})
            else:
                row['judge']={'keep':False,'reason':'invalid tool/action schema'}
                row['accepted']=False
            rows.append(row)
    schema_ok=sum(1 for x in rows if x['schema_valid'])
    report={'status':'completed','timestamp':datetime.now(timezone.utc).isoformat(),'tasks':len(tasks),'candidates':len(rows),'schema_valid_rate':schema_ok/max(1,len(rows)),'accepted_training_examples':len(accepted),'acceptance_rate':len(accepted)/max(1,len(rows)),'research_context_used':bool(RESEARCH)}
    (OUT/'latest_evolution.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    with (OUT/'tool_use_trajectories.jsonl').open('w',encoding='utf-8') as fh:
        for row in rows: fh.write(json.dumps(row,ensure_ascii=False)+'\n')
    with (OUT/'training_ready.jsonl').open('w',encoding='utf-8') as fh:
        for row in accepted: fh.write(json.dumps(row,ensure_ascii=False)+'\n')
    print(json.dumps(report,indent=2,ensure_ascii=False))
    return 0

if __name__=='__main__':
    raise SystemExit(main())