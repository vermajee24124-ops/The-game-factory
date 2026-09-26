from __future__ import annotations
import concurrent.futures,json,os,urllib.error,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
QUEUE=ROOT/'build'/'agent_research'/'visual_queue.jsonl'
OUT=ROOT/'build'/'agent_research'/'gemini_visual_notes.jsonl'
API_KEY=os.getenv('GEMINI_API_KEY','').strip()
MODEL=os.getenv('GEMINI_VIDEO_MODEL','gemini-3.8-flash').strip()
if not API_KEY: raise SystemExit('GEMINI_API_KEY is required')
def analyze(item):
    body={'model':MODEL,'input':[{'type':'video','uri':item['url'],'processing':'agentic'},{'type':'text','text':'Analyze this public Godot/game-development video using visual and audio understanding. Do not reproduce its transcript. Extract original technical notes about editor operations, scene construction, file organization, 2D/3D workflows, asset creation/import, Blender/glTF, materials, shaders, lighting, animation, physics, level design, debugging, performance, mobile optimization, and reusable procedures. Include useful timestamps when available. Return concise structured notes.'}]}
    req=urllib.request.Request('https://generativelanguage.googleapis.com/v1beta/interactions',data=json.dumps(body).encode(),method='POST',headers={'Content-Type':'application/json','x-goog-api-key':API_KEY})
    try:
        with urllib.request.urlopen(req,timeout=900) as resp: data=json.loads(resp.read().decode())
        return {'source':item,'analysis':data}
    except (urllib.error.HTTPError,urllib.error.URLError) as exc:
        return {'source':item,'error':str(exc)}
items=[json.loads(x) for x in QUEUE.read_text(encoding='utf-8').splitlines() if x.strip()]
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(analyze,items))
with OUT.open('w',encoding='utf-8') as fh:
    for row in results: fh.write(json.dumps(row,ensure_ascii=False)+'\n')
print(json.dumps({'processed':len(results),'model':MODEL}))