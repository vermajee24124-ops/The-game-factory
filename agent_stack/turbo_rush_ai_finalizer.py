#!/usr/bin/env python3
import json, os, re, shlex, subprocess, sys, time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "projects" / "GME-2026-0003" / "godot"
CC_BASE = os.getenv("CODECRAFT_BASE_URL", "https://codecraftapi.com/v1").rstrip("/")
NARA_BASE = os.getenv("NARA_BASE_URL", "https://router.bynara.id/v1").rstrip("/")
NVIDIA_BASE = os.getenv("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1").rstrip("/")
MAX_LEAD_ROUNDS = int(os.getenv("MAX_LEAD_ROUNDS", "24"))
MAX_REVIEW_CYCLES = int(os.getenv("MAX_REVIEW_CYCLES", "4"))
MAX_TOKENS = int(os.getenv("MAX_TOKENS_PER_CALL", "16000"))

def http_json(url, headers=None, payload=None, method="GET", timeout=120):
    data = None if payload is None else json.dumps(payload).encode()
    req = Request(url, data=data, method=method, headers=headers or {})
    try:
        with urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        return {"_error": str(e)}

def list_models(base, key):
    if not key:
        return []
    out = http_json(base + "/models", {"Authorization": f"Bearer {key}"})
    return out.get("data", []) if isinstance(out, dict) else []

def choose_model(models, preferred, hints):
    ids = [str(x.get("id","")) for x in models]
    if preferred and preferred in ids:
        return preferred
    lowered = [(i, i.lower()) for i in ids]
    for hint in hints:
        for original, low in lowered:
            if hint in low:
                return original
    return ids[0] if ids else ""

def safe_path(rel):
    p = (ROOT / rel).resolve()
    if ROOT not in p.parents and p != ROOT:
        raise RuntimeError("path escapes repository")
    return p

def repo_tree():
    out=[]
    for p in ROOT.rglob("*"):
        if ".git" in p.parts or p.is_dir():
            continue
        rel=p.relative_to(ROOT).as_posix()
        if len(rel)<240:
            out.append(rel)
    return out[:4000]

def read_file(rel, start=1, end=None):
    p=safe_path(rel)
    text=p.read_text(encoding="utf-8")
    lines=text.splitlines()
    s=max(1,int(start))
    e=len(lines) if end is None else min(len(lines),int(end))
    return "
".join(f"{i}: {lines[i-1]}" for i in range(s,e+1))

def write_file(rel, content):
    if rel.startswith(".git/"):
        raise RuntimeError("refusing .git write")
    p=safe_path(rel)
    if len(content.encode()) > 2_000_000:
        raise RuntimeError("file too large")
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return f"wrote {rel}"

def run_shell(command):
    banned = [
        "rm -rf /", "git reset --hard", "git clean -fdx", "shutdown", "reboot",
        "curl http://169.254.169.254", "cat /proc/1/environ"
    ]
    if any(x in command for x in banned):
        raise RuntimeError("blocked shell command")
    proc=subprocess.run(command, cwd=ROOT, shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=300)
    return {"exit_code":proc.returncode,"output":proc.stdout[-20000:]}

def tool_defs():
    return [
      {"type":"function","function":{"name":"repo_tree","description":"List relevant repository files.","parameters":{"type":"object","properties":{}}}},
      {"type":"function","function":{"name":"read_file","description":"Read a UTF-8 repository file with optional line range.","parameters":{"type":"object","properties":{"path":{"type":"string"},"start":{"type":"integer"},"end":{"type":"integer"}},"required":["path"]}}},
      {"type":"function","function":{"name":"write_file","description":"Replace/create a UTF-8 repository file. Use only for text/source/config files needed by Turbo Rush.","parameters":{"type":"object","properties":{"path":{"type":"string"},"content":{"type":"string"}},"required":["path","content"]}}},
      {"type":"function","function":{"name":"run_shell","description":"Run a bounded verification/build command from the repository root.","parameters":{"type":"object","properties":{"command":{"type":"string"}},"required":["command"]}}}
    ]

def execute_tool(name,args):
    if name=="repo_tree": return repo_tree()
    if name=="read_file": return read_file(args["path"],args.get("start",1),args.get("end"))
    if name=="write_file": return write_file(args["path"],args["content"])
    if name=="run_shell": return run_shell(args["command"])
    raise RuntimeError("unknown tool")

def chat(base,key,model,messages,tools=None,max_tokens=MAX_TOKENS):
    payload={"model":model,"messages":messages,"max_tokens":max_tokens,"temperature":0.15}
    if tools:
        payload["tools"]=tools
        payload["tool_choice"]="auto"
    return http_json(base+"/chat/completions",{
        "Authorization":f"Bearer {key}","Content-Type":"application/json"
    },payload,"POST",180)

def extract_text(resp):
    try:
        return resp["choices"][0]["message"].get("content") or ""
    except Exception:
        return ""

def usage(resp):
    return int(resp.get("usage",{}).get("total_tokens",0)) if isinstance(resp,dict) else 0

def lead_rounds(cc_key, cc_model, extra_feedback=""):
    system = """You are the lead senior Godot 4.7.2 mobile game engineer for Turbo Rush.
You have a repository toolset and must actually improve the existing project, not merely describe changes.
Read the game bible and current code before editing. Work incrementally: inspect -> plan -> edit -> run Godot checks -> inspect failures -> repair -> retest.
Hard requirements: finite level-based racing, 1 player + 5 AI, 3-second countdown, deterministic level generation, target race times, traffic, obstacles, coins, rare diamonds, boost, ranking, finish, rewards, stars, top-5 unlock, assist after two failures, local JSON save with checksum+backup, upgrades, cars, cosmetics, offline-first.
Never put API keys in source. Never invent successful purchases or ad rewards. Do not add forced online dependency.
Asset policy: use only assets whose license is compatible with this public project and whose Godot version fits; prefer small curated additions. Do not bulk-copy thousands of unrelated assets.
Finish by running the strongest available headless validation and leave the repository in a buildable state."""
    user = """Open and finish the Turbo Rush project at projects/GME-2026-0003/godot.
Use game_bible/GME-2026-0003/game_bible.yaml and the existing project files as canonical context.
The goal is a release-candidate-quality core game today. Improve code, UI, gameplay feel, procedural validation, save/progression integrity, mobile performance, and test coverage. Use Godot Asset Library only when an asset clearly improves the build and its license is verified.
Do not stop at TODOs when the problem can be solved in source.
""" + extra_feedback
    messages=[{"role":"system","content":system},{"role":"user","content":user}]
    tools=tool_defs()
    total=0
    for turn in range(MAX_LEAD_ROUNDS):
        resp=chat(CC_BASE,cc_key,cc_model,messages,tools)
        total += usage(resp)
        if resp.get("_error"):
            return {"ok":False,"tokens":total,"error":resp["_error"]}
        msg=resp.get("choices",[{}])[0].get("message",{})
        messages.append(msg)
        tool_calls=msg.get("tool_calls") or []
        if not tool_calls:
            return {"ok":True,"tokens":total,"summary":msg.get("content","")}
        for tc in tool_calls:
            fn=tc.get("function",{})
            name=fn.get("name","")
            try:
                args=json.loads(fn.get("arguments","{}"))
                result=execute_tool(name,args)
            except Exception as e:
                result={"error":str(e)}
            messages.append({"role":"tool","tool_call_id":tc.get("id"),"content":json.dumps(result)[:30000]})
    return {"ok":True,"tokens":total,"summary":"Lead reached round cap."}

def reviewer(base,key,model,label,diff):
    if not key or not model:
        return {"ok":False,"skipped":True,"label":label,"feedback":""}
    prompt=f"""Review the Turbo Rush Godot project diff below as a senior {label} reviewer.
Do not rewrite the project. Return a compact list of concrete defects that should be fixed before a release-candidate build.
Focus on correctness, crashes, gameplay regressions, security, offline behavior, save/economy integrity, and mobile performance.
Do not complain about missing production art unless it blocks a build.
DIFF:
{diff[:50000]}"""
    resp=chat(base,key,model,[{"role":"system","content":"You are a rigorous code reviewer."},{"role":"user","content":prompt}],None,7000)
    return {"ok":not bool(resp.get("_error")),"skipped":False,"label":label,"feedback":extract_text(resp),"tokens":usage(resp)}

def main():
    cc_key=os.getenv("CODECRAFT_API","")
    nara_key=os.getenv("NARAROUTER_API_KEY","")
    nv_key=os.getenv("NVIDIA_API_KEY","")
    if not cc_key:
        print("CODECRAFT_API secret is not available; aborting AI finalizer.")
        return 2

    cc_models=list_models(CC_BASE,cc_key)
    preferred=os.getenv("CODECRAFT_MODEL","")
    cc_model=choose_model(cc_models,preferred,["claude-opus-5.5","claude-opus-4.8","claude-opus"])
    if not cc_model:
        print("No CodeCraft chat model is available for this key.")
        return 2
    print("Lead model:",cc_model)

    nara_model=choose_model(list_models(NARA_BASE,nara_key),os.getenv("NARA_MODEL",""),["deepseek","gemini","qwen","glm"])
    nv_model=choose_model(list_models(NVIDIA_BASE,nv_key),os.getenv("NVIDIA_MODEL",""),["nemotron","llama","mistral","qwen"])

    total_tokens=0
    reports=[]
    feedback=""
    for cycle in range(MAX_REVIEW_CYCLES):
        lead=lead_rounds(cc_key,cc_model,feedback)
        total_tokens+=lead.get("tokens",0)
        reports.append({"cycle":cycle+1,"lead":lead})
        if not lead.get("ok"):
            feedback="Lead model error: "+str(lead.get("error"))
            break
        diff=run_shell("git diff -- projects/GME-2026-0003")
        nara=reviewer(NARA_BASE,nara_key,nara_model,"NaraRouter reviewer",diff["output"])
        nv=reviewer(NVIDIA_BASE,nv_key,nv_model,"NVIDIA reviewer",diff["output"])
        total_tokens+=nara.get("tokens",0)+nv.get("tokens",0)
        reports[-1]["nara"]=nara
        reports[-1]["nvidia"]=nv
        joined=(nara.get("feedback","")+"
"+nv.get("feedback","")).strip()
        if not joined or "no concrete" in joined.lower() or "no defects" in joined.lower():
            break
        feedback="Fix these review findings and retest.\n"+joined

    Path("agent_stack/reports").mkdir(parents=True,exist_ok=True)
    Path("agent_stack/reports/latest.json").write_text(json.dumps({
        "project":"GME-2026-0003","lead_model":cc_model,"nara_model":nara_model,
        "nvidia_model":nv_model,"total_tokens_reported":total_tokens,
        "reports":reports
    },indent=2),encoding="utf-8")

    final=run_shell("git status --short && git diff --check")
    print(final["output"])
    print("AI finalizer reported tokens:",total_tokens)
    return 0 if final["exit_code"]==0 else final["exit_code"]

if __name__=="__main__":
    raise SystemExit(main())
