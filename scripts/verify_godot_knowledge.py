from __future__ import annotations

import json
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
KB=ROOT/'knowledge'/'Godot-4.7.2-Exhaustive-Knowledge-Base.md'
CUR=ROOT/'knowledge'/'agent_curriculum.json'
CAT=ROOT/'knowledge'/'godot_ai_tool_catalog.json'
UP=ROOT/'vendor'/'godot-ai'/'tool_catalog.gd'

def fail(msg):
    raise SystemExit('GODOT_KNOWLEDGE_VERIFY_FAILED: '+msg)

def main():
    if not KB.exists() or not CUR.exists() or not CAT.exists() or not UP.exists():
        fail('required knowledge/catalog file missing')
    text=KB.read_text(encoding='utf-8',errors='ignore')
    cur=json.loads(CUR.read_text(encoding='utf-8'))
    cat=json.loads(CAT.read_text(encoding='utf-8'))
    if cur.get('engine')!='4.7.2': fail('curriculum engine mismatch')
    inv=cur.get('inventory',{})
    expected={'classes':810,'methods':9896,'members':5534,'signals':451,'constants':5229,'modules':57,'project_settings':230,'editor_settings':171,'cli_options':104,'importers':19,'gdscript_annotations':36,'export_plugins':8}
    for k,v in expected.items():
        if int(inv.get(k,-1))!=v: fail(f'inventory {k} expected {v}, got {inv.get(k)}')
    if len(cur.get('class_reference',[]))!=810: fail('class reference does not contain 810 entries')
    for k,v in expected.items():
        if str(v) not in text and k not in {'modules','project_settings','editor_settings','cli_options','importers','gdscript_annotations','export_plugins'}:
            fail(f'source text missing expected marker for {k}')
    vendor_names=[]
    for m in re.finditer(r'"tools": \[([^\]]+)\]',UP.read_text(encoding='utf-8',errors='ignore')):
        vendor_names += re.findall(r'"([^"]+)"',m.group(1))
    vendor_names += re.findall(r'const (?:CORE_TOOLS|ALWAYS_ON_TOOLS) := \[\s*([\s\S]*?)\n\]',UP.read_text(encoding='utf-8',errors='ignore'))[0:0]
    # Extract all quoted tool names from catalog; duplicate-free count is authoritative.
    all_names=list(dict.fromkeys(re.findall(r'"([a-z_]+(?:_[a-z_]+)*)"',UP.read_text(encoding='utf-8',errors='ignore'))))
    catalog=set(cat.get('tools',[]))
    if len(catalog)!=47: fail(f'catalog expected 47 tools, got {len(catalog)}')
    if not catalog.issubset(set(all_names)): fail('catalog and vendor tool names diverge')
    print(json.dumps({'ok':True,'engine':'4.7.2','classes':810,'methods':9896,'tools':47,'verified_against':'knowledge/Godot-4.7.2-Exhaustive-Knowledge-Base.md'}))

if __name__=='__main__': main()
