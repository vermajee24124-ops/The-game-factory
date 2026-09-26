from __future__ import annotations
import json, os, subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
queries_path=ROOT/'build'/'agent_research'/'video_queries.generated.txt'
out_path=ROOT/'build'/'agent_research'/('shard-'+os.getenv('SHARD','0')+'.jsonl')
out_path.parent.mkdir(parents=True,exist_ok=True)
shard=int(os.getenv('SHARD','0'))
shards=int(os.getenv('SHARDS','16'))
max_queries=int(os.getenv('MAX_QUERIES_PER_SHARD','120'))
results_per_query=int(os.getenv('RESULTS_PER_QUERY','3'))
queries=[q.strip() for q in queries_path.read_text(encoding='utf-8').splitlines() if q.strip()]
queries=[q for i,q in enumerate(queries) if i % shards == shard][:max_queries]
rows=[]
for q in queries:
    cmd=['yt-dlp',f'ytsearch{results_per_query}:{q}','--flat-playlist','--dump-json','--skip-download','--ignore-errors','--no-warnings','--quiet']
    try: completed=subprocess.run(cmd,capture_output=True,text=True,timeout=90)
    except subprocess.TimeoutExpired: continue
    for line in completed.stdout.splitlines():
        try: item=json.loads(line)
        except json.JSONDecodeError: continue
        url=item.get('webpage_url') or item.get('original_url')
        if not url: continue
        rows.append({'query':q,'id':item.get('id'),'url':url,'title':item.get('title'),'channel':item.get('channel') or item.get('uploader'),'duration':item.get('duration'),'view_count':item.get('view_count'),'upload_date':item.get('upload_date'),'source':'youtube'})
seen=set()
with out_path.open('w',encoding='utf-8') as fh:
    for row in rows:
        if row['url'] in seen: continue
        seen.add(row['url'])
        fh.write(json.dumps(row,ensure_ascii=False)+'\n')
print(json.dumps({'shard':shard,'queries':len(queries),'videos':len(seen)}))