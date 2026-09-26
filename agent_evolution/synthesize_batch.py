from __future__ import annotations
import json,os,re,urllib.request
from datetime import datetime,timezone
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
NOTES=ROOT/'build'/'agent_research'/'gemini_visual_notes.jsonl'
CURRICULUM=ROOT/'knowledge'/'agent_curriculum.json'
OUT=ROOT/'agent_evolution'/'learned'
OUT.mkdir(parents=True,exist_ok=True)
base=os.getenv('FREELLMAPI_BASE_URL','').strip().rstrip('/')
key=os.getenv('FREELLMAPI_API_KEY','').strip()
model=os.getenv('FREELLMAPI_MODEL','').strip() or 'auto'
if not base or not key: raise SystemExit('FreeLLMAPI credentials are required')
notes=[]
for line in NOTES.read_text(encoding='utf-8').splitlines():
    if line.strip():
        item=json.loads(line)
        notes.append({'url':item.get('source',{}).get('url'),'title':item.get('source',{}).get('title'),'notes':json.dumps(item.get('analysis',{}),ensure_ascii=False)[:7000]})
system='You are the skill architect for a Godot 4.7.2 autonomous game-development agent. Do not train an LLM. Convert research into durable agent skills, tool playbooks, verification procedures and benchmark tasks. Do not copy long source text. Return a JSON array with name, domain, skill, tools, procedure, verification, pitfalls, benchmark_prompt.'
user='Synthesize these research notes into reusable agent skills. Merge duplicates and ignore unsupported claims.\n\n'+json.dumps(notes,ensure_ascii=False)+'\n\nCurriculum inventory:\n'+CURRICULUM.read_text(encoding='utf-8')[:18000]
url=base+('/v1' if base.endswith('/v1') else '/v1')+'/chat/completions'
payload={'model':model,'messages':[{'role':'system','content':system},{'role':'user','content':user}],'temperature':0.1,'max_tokens':5000}
req=urllib.request.Request(url,data=json.dumps(payload).encode(),method='POST',headers={'Content-Type':'application/json','Authorization':f'Bearer {key}'})
with urllib.request.urlopen(req,timeout=600) as resp: data=json.loads(resp.read().decode())
content=str(data['choices'][0]['message']['content'])
if content.startswith('```'): content=re.sub(r'^```(?:json)?\s*','',content); content=re.sub(r'\s*```$','',content).strip()
items=json.loads(content)
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
path=OUT/f'research-batch-{stamp}.json'
path.write_text(json.dumps({'generated_at':stamp,'model':data.get('model',model),'skills':items},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'skills':len(items),'output':str(path),'model':data.get('model',model)}))