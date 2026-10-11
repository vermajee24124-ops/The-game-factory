#!/usr/bin/env python3
"""Bounded construction agent: summarize the source PDF, generate allowlisted factory files, and save an audit report."""
from __future__ import annotations
import argparse, ast, json, os, re, sys
from datetime import datetime, timezone
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[1]
BASE_URL = os.getenv("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1").rstrip("/")
SOURCE = ROOT / "docs/reference/AI_AGENT_GODOT_GAME_STUDIO_PDF_EXTRACT.md"
MAX_FILE_SIZE = 45000
TARGETS = [
 ("game_factory/state_manager.py", "Atomic versioned JSON state, checkpoint/restore, phase/cycle tracking; no secrets in state."),
 ("game_factory/core/research_agent.py", "Accessible public source research with URLs/timestamps/confidence; three original twists; never invent fetched results."),
 ("game_factory/core/asset_scout.py", "Use verified CC0/public-domain assets or procedural assets; preserve source/license/hash; reject unknown/restricted licenses."),
 ("game_factory/core/ponytail_coder.py", "NVIDIA NIM coder using NVIDIA_FACTORY_KEY; one file per task, safe paths, timeouts, bounded calls, no logged keys, minimal GDScript."),
 ("game_factory/core/laya_router.py", "Zero-cost rule fallback returning SCREENSHOT_ONLY or VIDEO_AND_AUDIO_REQUIRED; optional local model only if truly installed; do not fake Laya availability."),
 ("game_factory/core/av_recorder.py", "Xvfb/Mesa software render + screenshot + FFmpeg MP4 + PulseAudio capture; ffprobe verifies video and audio streams; never call silent audio evidence."),
 ("game_factory/core/gemini_qa.py", "Gemma screenshot QA and Gemini 3.1 Flash-Lite video/audio QA with google-genai; GEMINI_API_KEY only here; model IDs configurable; max one call per modality/run; no retries on 401/403/404/429."),
 ("game_factory/core/strix_audit.py", "Verify Strix CLI before use, safe local static/dependency fallback, report exactly what ran."),
 ("game_factory/orchestrator.py", "Phases: develop,capture,visual-qa,video-audio-qa,repair,verify,relay. Use state/checkpoints, NVIDIA_FACTORY_KEY for coding, Gemini only for QA, bounded retries, verified tests and real audiovisual capture."),
 ("game_factory/cli.py", "CLI supports --idea, --phase, --state-path, --budget-minutes, --resume and --max-cycles; dispatches to orchestrator and exits nonzero on required test failure."),
 ("games/01_runner_classic/project.godot", "Valid Godot 4.7.2 project.godot for an original procedural 3D runner demo; main scene res://scenes/Main.tscn; Compatibility renderer."),
 ("games/01_runner_classic/scenes/Main.tscn", "Valid Godot 4.7.2 scene with coherent stylized procedural track, camera, light, player, obstacles and res://scripts/main.gd."),
 ("games/01_runner_classic/scripts/main.gd", "Valid playable Godot 4.7 GDScript 3D runner: forward movement, lane/jump/dodge controls, obstacle collision/restart, score HUD, coherent materials/camera and original procedural demo sound. Generate an AudioStreamPlayer, load res://assets/demo_sfx.wav, play it at startup and trigger it on a gameplay action. This WAV is procedurally created by factory_builder/generate_demo_audio.py. No copied IP/external assets.")
]
SPECS = {
 "01_GAME_DESIGN_DOCUMENT.md": "# Game Design Document\n\nIdea: {idea}\n\nDefine core loop, controls, audience, progression, fail/retry/reward and at least three original evolutions. Never clone a named game.",
 "02_SCENE_TREE_ARCHITECTURE.md": "# Scene Tree Architecture\n\nDefine node hierarchy, resources, signals, paths, audio buses and ownership; verify APIs against the pinned Godot version.",
 "03_STATE_MACHINE_SPEC.md": "# State Machine\n\nSpecify states/transitions, input triggers, collision sizes, animation/audio effects, restart/pause behavior and automated tests.",
 "04_PROCEDURAL_TRACK_ALGO.md": "# Procedural Track Algorithm\n\nDefine deterministic seeds, object pooling (PDF baseline: 12 tiles), spawn zones, difficulty curve and a guaranteed reachable path through every obstacle sequence.",
 "05_ASSET_AND_PALETTE_MANIFEST.md": "# Asset and Palette Manifest\n\nFor each asset record source URL, creator, exact license/evidence, date, SHA-256, target path and modification notes. Unknown licenses are blocked; prefer verified CC0 or procedural assets.",
 "06_SECURITY_AND_PERFORMANCE_BUDGET.md": "# Security and Performance\n\nDocument secret boundaries, safe paths, timeouts, retries, save validation, security checks and measured frame time/memory/package size. 60 FPS is a goal, not a guarantee. Never put keys in game code/artifacts.",
 "07_PLAY_STORE_COMPLIANCE.md": "# Store Compliance\n\nVerify current official SDK, 64-bit, consent/privacy, data-safety, ads/billing, permissions, signing, templates, AAB and device QA. Record date, source and blockers."
}

class AgentError(RuntimeError): pass

class Agent:
 def __init__(self, max_calls=24, model=""):
  self.key=os.getenv("NVIDIA_BUILDER_KEY","").strip()
  if not self.key: raise AgentError("Missing NVIDIA_BUILDER_KEY GitHub Actions secret.")
  self.max_calls=max(1,min(int(max_calls),30)); self.calls=0
  self.model=model.strip() or os.getenv("NVIDIA_BUILDER_MODEL","").strip()
  self.s=requests.Session()
  self.s.headers.update({"Authorization":"Bearer "+self.key,"Content-Type":"application/json"})
 def budget(self):
  if self.calls>=self.max_calls: raise AgentError("Builder call budget reached; persist progress and stop.")
 def select_model(self):
  if self.model: return self.model
  self.budget(); self.calls+=1
  ids=[]
  try:
   r=self.s.get(BASE_URL+"/models",timeout=(10,25))
   if r.ok: ids=[str(x.get("id","")) for x in r.json().get("data",[]) if isinstance(x,dict)]
  except (requests.RequestException,ValueError): pass
  self.model=next((x for x in ids if x.startswith("nvidia/") and any(y in x.lower() for y in ("nemotron","coder","instruct")) and not any(y in x.lower() for y in ("embed","rerank","guard"))),"nvidia/llama-3.1-nemotron-70b-instruct")
  print("[builder] model id:",self.model)
  return self.model
 def ask(self,system,user,tokens=2500):
  self.budget(); model=self.select_model(); self.budget(); self.calls+=1
  try: r=self.s.post(BASE_URL+"/chat/completions",json={"model":model,"messages":[{"role":"system","content":system},{"role":"user","content":user}],"temperature":0.15,"max_tokens":tokens,"stream":False},timeout=(20,180))
  except requests.RequestException as e: raise AgentError("NVIDIA request failed: "+type(e).__name__) from None
  if r.status_code in (401,403,404,429): raise AgentError(f"NVIDIA HTTP {r.status_code}; check key/model/quota. No automatic retry.")
  if not r.ok: raise AgentError(f"NVIDIA HTTP {r.status_code}.")
  try:
   d=r.json(); c=d["choices"][0]; out=str(c["message"]["content"]).strip(); reason=str(c.get("finish_reason","")).lower()
  except (ValueError,KeyError,IndexError,TypeError): raise AgentError("Unexpected NVIDIA response format.") from None
  if not out: raise AgentError("NVIDIA returned empty output.")
  if reason in ("length","max_tokens"): raise AgentError("NVIDIA output was truncated.")
  return out
 @staticmethod
 def clean(s):
  fence=chr(96)*3
  s=s.strip()
  if s.startswith(fence):
   s=re.sub(r"^"+re.escape(fence)+r"[A-Za-z0-9_+-]*\s*","",s)
   s=re.sub(r"\s*"+re.escape(fence)+r"$","",s)
  return s.strip()+"\n"
 def summarize(self,source):
  sysmsg="Extract engineering requirements faithfully. Think through requirements deeply and use the maximum reasoning configuration actually supported by this model endpoint; do not invent unsupported API parameters. Mark incomplete/outdated snippets as items to verify; never invent facts."
  chunks=[source[i:i+10500] for i in range(0,len(source),10500)]
  if len(chunks)>8: raise AgentError("PDF text too large; inspect source chunks before API use.")
  summaries=[]
  for i,ch in enumerate(chunks,1):
   summaries.append(self.ask(sysmsg,f"Summarize source chunk {i}/{len(chunks)}: required architecture/tools, CPU visual/audio QA, licenses/originality, seven specs, game curriculum, secret boundaries, checkpoints and must-verify items. Under 800 words.\n\n{ch}",1100))
   print(f"[builder] source chunk {i}/{len(chunks)} summarized")
  return self.ask(sysmsg,"Merge these source summaries into a complete implementation contract. Preserve uncertainty and conflicting examples in a Must Verify section; under 3500 words.\n\n"+"\n\n".join(summaries),3500)
 def write_generated(self,path,purpose,idea,summary,force):
  if not path.startswith(("game_factory/","specs/","games/01_runner_classic/")) or ".." in Path(path).parts or Path(path).is_absolute(): raise AgentError("Unsafe generated path rejected.")
  p=ROOT/path
  if p.exists() and not force: print("[builder] keeping existing",path); return "preserved"
  system="You are a senior Godot 4.7.2/Python engineer. Think deeply and use the highest reasoning/thinking configuration genuinely supported by the selected model API; verify parameter support before emitting it, and never invent generic max-thinking settings. Output the entire contents of exactly one file, no markdown or explanation. Use safe paths, timeouts, bounded retries, no secrets in generated code and no shell=True. Never copy commercial IP."
  user=f"TARGET FILE: {path}\nPURPOSE/CONTRACT: {purpose}\nGAME IDEA: {idea}\nPDF IMPLEMENTATION SUMMARY:\n{summary}\nFull source extract: docs/reference/AI_AGENT_GODOT_GAME_STUDIO_PDF_EXTRACT.md. Verify uncertain code snippets rather than copying them."
  data=self.clean(self.ask(system,user,3900))
  if len(data)>MAX_FILE_SIZE: raise AgentError("Generated file exceeds size limit.")
  if path.endswith(".py"):
   try: ast.parse(data,filename=path)
   except SyntaxError as e:
    data=self.clean(self.ask(system,f"Fix Python syntax error line {e.lineno}: {e.msg}. Return the entire corrected file only.\n\n{data}",3900))
    ast.parse(data,filename=path)
  p.parent.mkdir(parents=True,exist_ok=True); p.write_text(data,encoding="utf-8")
  print("[builder] wrote",path,len(data),"chars"); return "created"
 def run(self,idea,force,demo):
  summary=self.summarize(SOURCE.read_text(encoding="utf-8"))
  (ROOT/"game_factory").mkdir(parents=True,exist_ok=True)
  for d in ("game_factory/core","specs","deliverables/gameplay_clips","deliverables/screenshots","deliverables/qa_reports"): (ROOT/d).mkdir(parents=True,exist_ok=True)
  (ROOT/"game_factory/blueprint_summary.md").write_text("# PDF-derived implementation contract\n\n"+summary+"\n",encoding="utf-8")
  for name,content in SPECS.items():
   p=ROOT/"specs"/name
   if not p.exists() or force: p.write_text(content.format(idea=idea)+"\n",encoding="utf-8")
  for p in ("game_factory/__init__.py","game_factory/core/__init__.py"):
   f=ROOT/p
   if not f.exists() or force: f.parent.mkdir(parents=True,exist_ok=True); f.write_text('"""Autonomous Godot Game Factory."""\n',encoding="utf-8")
  created={}
  for path,purpose in TARGETS:
   if path.startswith("games/") and not demo: continue
   created[path]=self.write_generated(path,purpose,idea,summary,force)
  state=ROOT/"game_factory/factory_state.json"
  if not state.exists() or force:
   state.write_text(json.dumps({"schema_version":1,"status":"construction_smoke_pending","active_idea":idea,"phase":"construction","cycle":0,"repair_attempts":0,"updated_at":datetime.now(timezone.utc).isoformat(),"curriculum":["01_runner_classic","02_runner_cyberpunk_gravity_shift","03_racer_arcade","04_racer_highway","05_combat_arena","06_survival_arena"],"pending_tasks":["run demo import/runtime test","capture verified screenshot and audiovisual clip","verify each factory phase"],"completed_tasks":[],"qa":{"status":"not_run","score":None,"evidence":[]},"api_usage":{"builder_calls":self.calls,"model_id":self.model}},indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
  report={"schema_version":1,"status":"generated_pending_validation","created_at":datetime.now(timezone.utc).isoformat(),"model_id":self.model,"api_calls":self.calls,"max_calls":self.max_calls,"idea":idea,"generated_files":created,"source_pdf_extract":str(SOURCE.relative_to(ROOT)),"warnings":["Generated files are not proof of a working factory.","Tool availability, visual/audio capture, security audit and Android export require separate validation."]}
  out=ROOT/"deliverables/qa_reports/builder_report.json"; out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
  return report

def main():
 p=argparse.ArgumentParser(); p.add_argument("--idea",default="Original 3D cyberpunk runner with gravity-shift lanes and reactive sound"); p.add_argument("--max-calls",type=int,default=int(os.getenv("NVIDIA_BUILDER_MAX_CALLS","24"))); p.add_argument("--model",default=""); p.add_argument("--force",action="store_true"); p.add_argument("--no-demo",action="store_true"); a=p.parse_args()
 try:
  if not SOURCE.is_file(): raise AgentError("Missing PDF source extract in repository.")
  result=Agent(a.max_calls,a.model).run(a.idea,a.force,not a.no_demo); print(json.dumps(result,indent=2,ensure_ascii=False)); return 0
 except AgentError as e:
  print("[builder] BLOCKED:",str(e),file=sys.stderr); return 2
 except (OSError,ValueError,requests.RequestException) as e:
  print("[builder] BLOCKED:",type(e).__name__,"; credentials were not logged.",file=sys.stderr); return 2
if __name__=="__main__": raise SystemExit(main())
