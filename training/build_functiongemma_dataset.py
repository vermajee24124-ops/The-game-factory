from __future__ import annotations

import hashlib
import json
import os
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'training' / 'data'
OUT.mkdir(parents=True, exist_ok=True)

TOOLS = [
  {'type':'function','function':{'name':'project.summary','description':'Inspect current Godot project/editor state.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.tree','description':'Read the current edited Godot scene tree.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'script.current','description':'Read the currently selected script path.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'editor.play','description':'Run the main Godot scene.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'editor.stop','description':'Stop the running Godot game.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.add_node','description':'Create a Godot node below a parent in the edited scene.','parameters':{'type':'object','properties':{'parent_path':{'type':'string'},'node_type':{'type':'string'},'name':{'type':'string'}},'required':['parent_path','node_type','name'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.set_property','description':'Set a property on an existing Godot node.','parameters':{'type':'object','properties':{'node_path':{'type':'string'},'property':{'type':'string'},'value':{}},'required':['node_path','property','value'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'file.read_text','description':'Read a UTF-8 text file under res://.','parameters':{'type':'object','properties':{'path':{'type':'string'}},'required':['path'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'file.write_text','description':'Write a UTF-8 text file under res://.','parameters':{'type':'object','properties':{'path':{'type':'string'},'content':{'type':'string'}},'required':['path','content'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'asset.create_3d_character','description':'Create a stylized procedural 3D character directly in the edited Godot scene.','parameters':{'type':'object','properties':{'name':{'type':'string'},'skin_color':{'type':'string'},'outfit_color':{'type':'string'},'hair_color':{'type':'string'},'save_path':{'type':'string'}},'required':['name'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'asset.import_glb','description':'Import a generated GLB into a res:// path and trigger Godot resource scanning.','parameters':{'type':'object','properties':{'source_path':{'type':'string'},'destination_path':{'type':'string'}},'required':['source_path'],'additionalProperties':False}}},
]

DEVELOPER = 'You are the local Godot micro-action model. Use the available functions for small editor, scene, file and asset operations. Never invent tools. For complex coding, multimodal reasoning or production architecture, return an escalation decision instead of pretending.'

VARIANTS = [
  'Please {task}.', 'Can you {task}?', 'Do this in my Godot project: {task}.',
  'In Godot, {task}.', 'I only need this small change: {task}.',
  'Make this quick editor change: {task}.', 'Please handle just this tiny task: {task}.',
  'Do not rewrite unrelated things; {task}.',
]

def call(name, args=None, call_id='call_1'):
    return {'id':call_id,'type':'function','function':{'name':name,'arguments':json.dumps(args or {}, ensure_ascii=False,separators=(',',':'))}}

def add(rows, task, name, args=None):
    user = random.choice(VARIANTS).format(task=task)
    call_id = f'call_{len(rows)+1}'
    tool_call = call(name, args, call_id)
    tool_result = json.dumps({'ok': True, 'tool': name, 'verified': True}, ensure_ascii=False, separators=(',',':'))
    rows.append({'messages':[
        {'role':'developer','content':DEVELOPER},
        {'role':'user','content':user},
        {'role':'assistant','content':None,'tool_calls':[tool_call]},
        {'role':'tool','tool_call_id':call_id,'content':tool_result},
        {'role':'assistant','content':'Done. The requested small Godot operation was completed and verified.'}
    ],'tools':TOOLS})

def stable_seed(text):
    return int(hashlib.sha256(text.encode('utf-8')).hexdigest()[:8],16)

def main():
    seed=int(os.getenv('DATASET_SEED','20260927'))
    random.seed(seed)
    target=int(os.getenv('TARGET_EXAMPLES','12000'))
    rows=[]
    tasks=list((ROOT/'ai_superagent'/'tasks.jsonl').read_text(encoding='utf-8').splitlines())
    for line in tasks:
        item=json.loads(line)
        p=item['prompt']
        add(rows,p,'project.summary',{})
        add(rows,p,'scene.tree',{})

    research_files=[]
    for pattern in ['build/agent_research/gemini_visual_notes.jsonl','agent_evolution/learned/*.json']:
        research_files += list(ROOT.glob(pattern))
    evidence=[]
    for path in research_files:
        if path.is_file():
            try:
                if path.suffix=='.jsonl':
                    for line in path.read_text(encoding='utf-8').splitlines():
                        if line.strip(): evidence.append(json.loads(line))
                else:
                    obj=json.loads(path.read_text(encoding='utf-8'))
                    evidence.extend(obj.get('skills',[]))
            except Exception:
                continue

    for idx,item in enumerate(evidence):
        title=str(item.get('title') or item.get('name') or item.get('domain') or 'Godot workflow')
        seed_text=json.dumps(item,ensure_ascii=False)[:1500]
        random.seed(seed+stable_seed(seed_text))
        recipes=[
          ('inspect the scene tree before changing anything','scene.tree',{}),
          ('inspect the current project state','project.summary',{}),
          ('create a simple 3D character named Runner','asset.create_3d_character',{'name':'Runner','save_path':'res://assets/generated/Runner.tscn'}),
          ('create a simple enemy character named Enemy','asset.create_3d_character',{'name':'Enemy'}),
          ('read res://project.godot before editing it','file.read_text',{'path':'res://project.godot'}),
          ('read the current gameplay script','script.current',{}),
          ('run the main scene for a quick visual check','editor.play',{}),
          ('stop the running game after the check','editor.stop',{}),
          ('create a Camera3D under the scene root','scene.add_node',{'parent_path':'.','node_type':'Camera3D','name':'AICamera'}),
          ('create a GPUParticles3D node under the scene root','scene.add_node',{'parent_path':'.','node_type':'GPUParticles3D','name':'AIParticles'}),
          ('set a visible node position to a safe test value','scene.set_property',{'node_path':'Camera3D','property':'position','value':[0,3,6]}),
          ('import a generated character GLB into the assets folder','asset.import_glb',{'source_path':'/tmp/generated_character.glb','destination_path':'res://assets/generated/generated_character.glb'}),
        ]
        for task,name,args in recipes:
            add(rows,f'Use this Godot research context as guidance: {title}. Then {task}',name,args)
        if len(rows)>=target: break

    while len(rows)<target:
        idx=len(rows)
        variants=[
          ('create a coin pickup','scene.add_node',{'parent_path':'.','node_type':'MeshInstance3D','name':f'Coin{idx}'}),
          ('create a 3D player body','scene.add_node',{'parent_path':'.','node_type':'CharacterBody3D','name':f'Player{idx}'}),
          ('inspect the scene before making a file change','scene.tree',{}),
          ('check whether the main scene is ready to run','project.summary',{}),
          ('run the game once for a smoke test','editor.play',{}),
          ('stop the game after the smoke test','editor.stop',{}),
          ('create a stylized 3D character','asset.create_3d_character',{'name':f'Character{idx}'}),
          ('read a scene file before editing it','file.read_text',{'path':'res://main.tscn'}),
          ('import a previously generated GLB after checking its path','asset.import_glb',{'source_path':'/tmp/model.glb','destination_path':f'res://assets/generated/model_{idx}.glb'}),
        ]
        task,name,args=random.choice(variants)
        add(rows,task,name,args)

    random.shuffle(rows)
    split=max(1,int(len(rows)*0.9))
    train=rows[:split]; test=rows[split:]
    (OUT/'train.jsonl').write_text(''.join(json.dumps(x,ensure_ascii=False)+'\n' for x in train),encoding='utf-8')
    (OUT/'eval.jsonl').write_text(''.join(json.dumps(x,ensure_ascii=False)+'\n' for x in test),encoding='utf-8')
    (OUT/'manifest.json').write_text(json.dumps({'train_examples':len(train),'eval_examples':len(test),'total':len(rows),'source_evidence_files':len(research_files),'seed':seed},indent=2),encoding='utf-8')
    print(json.dumps({'total':len(rows),'train':len(train),'eval':len(test)}))

if __name__=='__main__':
    main()
