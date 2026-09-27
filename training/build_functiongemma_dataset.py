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
  {'type':'function','function':{'name':'scene.node_info','description':'Read one node class, path and selected properties.','parameters':{'type':'object','properties':{'node_path':{'type':'string'}},'required':['node_path'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.verify_property','description':'Read back one node property after a change.','parameters':{'type':'object','properties':{'node_path':{'type':'string'},'property':{'type':'string'}},'required':['node_path','property'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.save','description':'Save the currently edited scene to disk.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'script.current','description':'Read the currently selected script path.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'editor.play','description':'Run the main Godot scene.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'editor.stop','description':'Stop the running Godot game.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.add_node','description':'Create a Godot node below a parent in the edited scene.','parameters':{'type':'object','properties':{'parent_path':{'type':'string'},'node_type':{'type':'string'},'name':{'type':'string'}},'required':['parent_path','node_type','name'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'scene.set_property','description':'Set a property on an existing Godot node.','parameters':{'type':'object','properties':{'node_path':{'type':'string'},'property':{'type':'string'},'value':{}},'required':['node_path','property','value'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'file.read_text','description':'Read a UTF-8 text file under res://.','parameters':{'type':'object','properties':{'path':{'type':'string'}},'required':['path'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'file.write_text','description':'Write a UTF-8 text file under res://.','parameters':{'type':'object','properties':{'path':{'type':'string'},'content':{'type':'string'}},'required':['path','content'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'asset.create_3d_character','description':'Create a stylized procedural 3D character directly in the edited Godot scene.','parameters':{'type':'object','properties':{'name':{'type':'string'},'skin_color':{'type':'string'},'outfit_color':{'type':'string'},'hair_color':{'type':'string'},'save_path':{'type':'string'}},'required':['name'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'asset.import_glb','description':'Import a generated GLB into a res:// path and trigger Godot resource scanning.','parameters':{'type':'object','properties':{'source_path':{'type':'string'},'destination_path':{'type':'string'}},'required':['source_path'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'godot.api.summary','description':'Read the Godot 4.7.2 curriculum inventory.','parameters':{'type':'object','properties':{},'additionalProperties':False}}},
  {'type':'function','function':{'name':'godot.api.query_classes','description':'Search the live Godot ClassDB class list.','parameters':{'type':'object','properties':{'query':{'type':'string'}},'required':['query'],'additionalProperties':False}}},
  {'type':'function','function':{'name':'godot.api.class_info','description':'Inspect live ClassDB properties, methods and signals for a Godot class.','parameters':{'type':'object','properties':{'class_name':{'type':'string'}},'required':['class_name'],'additionalProperties':False}}},
]

DEVELOPER = (
    'You are the local Godot micro-action model for Godot 4.7.2. '
    'Return exactly one small action as JSON. Use only the supplied tool names. '
    'For complex coding, architecture, multimodal reasoning, large refactors, or uncertain tasks, '
    'return an escalation action rather than inventing an API.'
)

VARIANTS = [
  'Please {task}.', 'Can you {task}?', 'Do this in my Godot project: {task}.',
  'In Godot, {task}.', 'I only need this small change: {task}.',
  'Make this quick editor change: {task}.', 'Please handle just this tiny task: {task}.',
  'Do not rewrite unrelated things; {task}.',
]

def stable_seed(text: str) -> int:
    return int(hashlib.sha256(text.encode('utf-8')).hexdigest()[:8], 16)

def add(rows, task: str, action: dict):
    user = random.choice(VARIANTS).format(task=task)
    rows.append({
        'messages': [
            {'role':'developer','content':DEVELOPER},
            {'role':'user','content':user},
            {'role':'assistant','content':json.dumps(action, ensure_ascii=False, separators=(',',':'))},
        ],
        'tools': TOOLS,
    })

def tool(name: str, args=None) -> dict:
    return {'action':'tool_call','tool':name,'args':args or {}}

def escalate(reason: str) -> dict:
    return {'action':'final','result':'escalate','evidence':[reason]}

def main():
    seed = int(os.getenv('DATASET_SEED','20260927'))
    random.seed(seed)
    target = int(os.getenv('TARGET_EXAMPLES','12000'))
    rows = []

    tasks_path = ROOT / 'ai_superagent' / 'tasks.jsonl'
    for line in tasks_path.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        prompt = json.loads(line)['prompt']
        add(rows, prompt, tool('project.summary'))
        add(rows, prompt, tool('scene.tree'))

    research_files = []
    for pattern in [
        'build/agent_research/gemini_visual_notes.jsonl',
        'agent_evolution/learned/*.json',
    ]:
        research_files.extend(ROOT.glob(pattern))

    evidence = []
    for path in research_files:
        if not path.is_file():
            continue
        try:
            if path.suffix == '.jsonl':
                for line in path.read_text(encoding='utf-8').splitlines():
                    if line.strip():
                        evidence.append(json.loads(line))
            else:
                evidence.extend(json.loads(path.read_text(encoding='utf-8')).get('skills', []))
        except Exception:
            continue

    for item in evidence:
        title = str(item.get('title') or item.get('name') or item.get('domain') or 'Godot workflow')
        seed_text = json.dumps(item, ensure_ascii=False)[:1500]
        random.seed(seed + stable_seed(seed_text))
        recipes = [
          ('inspect the scene tree before changing anything','scene.tree',{}),
          ('inspect the root node before making a change','scene.node_info',{'node_path':'.'}),
          ('read back a property after a scene change','scene.verify_property',{'node_path':'Camera3D','property':'position'}),
          ('save the edited scene after a meaningful change','scene.save',{}),
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
          ('read the Godot 4.7.2 API inventory','godot.api.summary',{}),
          ('search live Godot classes for CharacterBody3D','godot.api.query_classes',{'query':'CharacterBody3D'}),
          ('inspect the live API of Node3D','godot.api.class_info',{'class_name':'Node3D'}),
        ]
        for task, name, args in recipes:
            add(rows, f'Use this Godot research context as guidance: {title}. Then {task}', tool(name,args))
        add(rows, f'Use this research context: {title}. Decide whether the task needs a stronger remote model before acting.', escalate('Complexity or uncertainty must be handled by the remote reasoner.'))
        if len(rows) >= target:
            break

    while len(rows) < target:
        idx = len(rows)
        variants = [
          ('create a coin pickup','scene.add_node',{'parent_path':'.','node_type':'MeshInstance3D','name':f'Coin{idx}'}),
          ('create a 3D player body','scene.add_node',{'parent_path':'.','node_type':'CharacterBody3D','name':f'Player{idx}'}),
          ('inspect the scene before making a file change','scene.tree',{}),
          ('inspect a player node before editing it','scene.node_info',{'node_path':'Player'}),
          ('verify a node property after editing it','scene.verify_property',{'node_path':'Player','property':'position'}),
          ('save the scene after a completed edit','scene.save',{}),
          ('check whether the main scene is ready to run','project.summary',{}),
          ('run the game once for a smoke test','editor.play',{}),
          ('stop the game after the smoke test','editor.stop',{}),
          ('create a stylized 3D character','asset.create_3d_character',{'name':f'Character{idx}'}),
          ('read a scene file before editing it','file.read_text',{'path':'res://main.tscn'}),
          ('import a previously generated GLB after checking its path','asset.import_glb',{'source_path':'/tmp/model.glb','destination_path':f'res://assets/generated/model_{idx}.glb'}),
          ('inspect the API for Node3D before using it','godot.api.class_info',{'class_name':'Node3D'}),
          ('search the live ClassDB for a particle node','godot.api.query_classes',{'query':'GPUParticles3D'}),
          ('ask for escalation instead of guessing a complex task',None,None),
        ]
        task, name, args = random.choice(variants)
        add(rows, task, escalate('Escalate complex or uncertain tasks.')) if name is None else add(rows, task, tool(name,args))

    random.shuffle(rows)
    split = max(1, int(len(rows) * 0.9))
    train, test = rows[:split], rows[split:]
    (OUT/'train.jsonl').write_text(
        ''.join(json.dumps(x, ensure_ascii=False) + '\n' for x in train),
        encoding='utf-8'
    )
    (OUT/'eval.jsonl').write_text(
        ''.join(json.dumps(x, ensure_ascii=False) + '\n' for x in test),
        encoding='utf-8'
    )
    (OUT/'manifest.json').write_text(
        json.dumps({
            'train_examples':len(train),
            'eval_examples':len(test),
            'total':len(rows),
            'source_evidence_files':len(research_files),
            'seed':seed,
            'task_style':'runtime_action_json',
            'tool_count':len(TOOLS),
            'runtime_contract':'action_json_v1',
            'includes_escalation_examples':True,
        }, indent=2),
        encoding='utf-8',
    )
    print(json.dumps({'total':len(rows),'train':len(train),'eval':len(test),'tools':len(TOOLS)}))

if __name__=='__main__':
    main()
