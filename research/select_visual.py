from __future__ import annotations
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
base=ROOT/'build'/'agent_research'
rows=[]
for path in sorted(base.glob('shard-*.jsonl')):
    for line in path.read_text(encoding='utf-8').splitlines():
        if line.strip():
            try: rows.append(json.loads(line))
            except json.JSONDecodeError: pass
def score(row):
    text=' '.join(str(row.get(k,'')) for k in ('query','title','channel')).lower()
    points=0
    for term,weight in [('godot 4.7',12),('godot 4',8),('3d',6),('2d',5),('advanced',5),('workflow',4),('shader',3),('animation',3),('blender',3),('optimization',3),('open world',4),('level design',4),('asset',3)]:
        if term in text: points+=weight
    d=row.get('duration')
    if isinstance(d,(int,float)):
        if 120<=d<=900: points+=4
        elif d>1800: points-=5
    return points
best={}
for row in rows:
    u=row.get('url')
    if u:
        s=score(row)
        if u not in best or s>best[u][0]: best[u]=(s,row)
selected=[row for _,row in sorted(best.values(),key=lambda x:x[0],reverse=True)[:30]]
out=base/'visual_queue.jsonl'
with out.open('w',encoding='utf-8') as fh:
    for row in selected: fh.write(json.dumps(row,ensure_ascii=False)+'\n')
print(json.dumps({'candidates':len(best),'selected_for_gemini':len(selected)}))