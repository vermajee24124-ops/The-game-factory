# Autonomous Godot Game Studio — Implementation Blueprint

Status: implementation contract derived from the user's uploaded 26-page PDF. The searchable text extract is preserved in [the source extract](reference/AI_AGENT_GODOT_GAME_STUDIO_PDF_EXTRACT.md). The extract preserves extracted text and diagram text, not the PDF's original page artwork.

## Mission
Build a persistent, reusable, autonomous game factory—not just one demo. A user supplies a one-line game idea or a Game Bible. The system researches the genre, proposes original mechanics, creates a Game Design Document and technical plans, selects legally usable assets or creates procedural assets, constructs scenes/scripts, runs the game in a real software-rendered virtual display, captures screenshots and gameplay video with audio, checks results, repairs failures, reruns tests, records evidence and prepares store/export readiness.

## Two separate phases and separate credentials
1. **Builder / construction agent** uses `NVIDIA_BUILDER_KEY` only. It reads this blueprint and the complete source extract, inspects the repository, builds the durable `game_factory/` runtime, writes specifications, builds one demo project, installs/validates compatible tools, runs checks and reports evidence. It must stop after successful construction; the finished factory must not depend on the builder staying alive.
2. **Persistent factory** uses `NVIDIA_FACTORY_KEY` for coding/research/fixes and `GEMINI_API_KEY` only for the visual/video-audio QA phase. The permanent factory continues from committed `game_factory/factory_state.json` and saves checkpoints and deliverables. Never put these secrets in files, generated game projects, artifacts, logs, or prompts.

Do not use the user's keys until GitHub Actions Secrets are configured. Never ask the user to paste keys in chat.

## Required technology and roles
- Godot 4.x, initially pinned to the user's requested 4.7.2 stable; check official current releases and compatibility before upgrading the lock.
- CPU-first Linux execution. Use Godot headless mode for import/script/build validation and Xvfb + Mesa/llvmpipe + a normal Compatibility renderer for actual visual rendering when possible. Headless success alone does not prove good visuals.
- PulseAudio/virtual sink and FFmpeg for short MP4 gameplay capture. Verify both video and audio streams exist and are non-empty; a silent/dummy track must never be reported as recorded game audio.
- NVIDIA NIM native models for reasoning, source planning, GDScript/.tscn generation, repairs and code cleanup. Model IDs must be configurable and checked against the authenticated endpoint. Respect actual account quota; a stated 40 RPM is not a promise of daily quota or model availability.
- Ponytail-style coding rules: minimal/modular code, prefer built-in Godot nodes, avoid unnecessary abstractions, preserve existing project conventions. Install the actual Ponytail skill/plugin only after checking its current source, compatibility and license; keep these coding rules as a fallback.
- Godot-MCP (or compatible Godot MCP) for direct editor/scene operations when the server can actually be run. In CI, text-based .tscn/.tres and script generation can be a fallback. Do not claim MCP is active unless a smoke test proves it.
- Agent Reach-style research for public webpages/videos/reviews, with references and timestamps. If a connector cannot fetch a platform, report the gap and continue with accessible sources instead of fabricating research.
- Laya/local CPU decision gatekeeper only if a real model artifact/package can be verified and runs within the CPU budget. A deterministic rule-based router is the reliable fallback; do not label heuristics as a loaded Laya model.
- Gemma image inspection (PDF baseline: `gemma-3-27b-it`, when available through the configured API) for static screenshot/UI checks. Use `gemini-3.1-flash-lite` for video+audio gameplay review, with thinking/reasoning configuration supported by the current API. Check the model list and model capabilities at runtime. Do not automatically retry quota failures.
- Strix security scanner, when installable and its real CLI is verified. Always run safe local static/dependency checks as fallback and state which security checks ran.
- CC0/public-domain or explicitly permitted assets first (for example, a current official Kenney CC0 pack); preserve the exact asset URL, source, license, license file/hash and modification status in an asset manifest. A free download is not automatically CC0 or commercially usable. If licensing cannot be verified, omit it and generate procedural assets instead.

## Seven mandatory planning documents
Generate and keep these under `specs/` before substantial game code is written:
1. `01_GAME_DESIGN_DOCUMENT.md`: core loop, audience, controls, progression, fail/retry/reward loops and three original mechanic evolutions.
2. `02_SCENE_TREE_ARCHITECTURE.md`: scene/node hierarchy, resources, signals, ownership and script responsibilities.
3. `03_STATE_MACHINE_SPEC.md`: all gameplay states, transitions, input triggers and collision dimensions.
4. `04_PROCEDURAL_TRACK_ALGO.md`: track/level generation, safe path guarantees, object pooling and obstacle difficulty curve.
5. `05_ASSET_AND_PALETTE_MANIFEST.md`: asset names, URLs, verified licenses, palette, shaders, audio and procedural fallback.
6. `06_SECURITY_AND_PERFORMANCE_BUDGET.md`: threat model, persistence, network assumptions, mobile/CPU budgets and measured profiling results. A target of 60 FPS is a goal, never a guarantee.
7. `07_PLAY_STORE_COMPLIANCE.md`: current target SDK/store rules, permissions, privacy/consent, architecture, export configuration and release checklist. Re-verify official current store rules; never hard-code an obsolete year/API level as permanently current.

## Reasoning configuration

- **Reasoning configuration:** use the maximum reasoning/thinking setting genuinely supported by the selected NVIDIA or Gemini model/API. Verify the exact current model documentation first; do not assume every model accepts one universal `max_thinking` field. Record the configured setting and stop safely if an explicitly configured setting is rejected.

## Mandatory development loop
1. Research mechanics, camera, progression, usability complaints and genre trends from multiple accessible public sources. Record source links, retrieval timestamps and confidence.
2. Deconstruct references and evolve them; never copy commercial game assets, proprietary code, logos, exact UI layouts, music, characters or levels. Build an originality matrix and add at least three distinguishable mechanics/theme/progression changes.
3. Produce the seven specs, a task DAG/checklist, acceptance tests and risk list before substantial code generation. Do not make the coding agent guess hidden requirements.
4. Audit and source assets legally or create original procedural meshes/materials/audio; store license/source metadata.
5. Build small, modular GDScript and Godot scenes/resources. Ask the model to return one well-scoped file/change per action. Restrict generated file writes to approved project directories; never execute arbitrary shell commands supplied by a model.
6. Import/parse with Godot CLI. Read logs; run automated gameplay, collision and progression tests; fix failures with a bounded repair loop.
7. Capture a real visual screenshot and, for motion/physics/audio features, an MP4 with gameplay audio. Use screenshots for layout/static checks; use the video+audio inspector when dynamic behavior is material. Record QA scores and evidence.
8. Run security/dependency checks and current Android/export validation. Package as AAB only when Android templates, SDK/JDK and export preset are actually configured. A successful scene test is not proof of an AAB or store approval.
9. Persist state, reports, source/licensing manifest, screenshots, clips and project files. Checkpoint/commit every 30 minutes where possible. Before runner exit, save a resumable state and allow a bounded handoff to another run.
10. Complete the curriculum in this order: classic 3-lane endless runner; original cyberpunk/gravity-shift runner; arcade track racer; highway traffic-dodger racer; third-person arena prototype; survival-arena loop. These are separate projects, not copies of existing games. Save each project and its QA scorecard/clip.

## Required factory interface and layout
```
game_factory/
  cli.py
  orchestrator.py
  state_manager.py
  factory_state.json
  blueprint_summary.md
  core/
    research_agent.py
    asset_scout.py
    ponytail_coder.py
    laya_router.py
    av_recorder.py
    gemini_qa.py
    strix_audit.py
specs/                     # seven planning documents above
games/                     # staged curriculum and demo project(s)
deliverables/
  gameplay_clips/
  screenshots/
  qa_reports/
```

The CLI must support at least: `--idea`, `--phase`, `--budget-minutes`, `--resume`, and a state path. The phase interface must support `develop`, `capture`, `visual-qa`, `video-audio-qa`, `repair`, and `verify` so workflow steps can expose only the relevant API key to each phase. It must also support a single bounded `relay` operation if all keys are present, but the workflow must still prefer key-scoped steps.

## Continuation and reliability
- Durable state records game/project ID, phase, cycle, last verified outputs, pending task, QA score, retry count, and timestamps.
- Each relay run is bounded to less than five hours and commits checkpoints. If incomplete and the user enabled continuation, dispatch a new run with the same idea and incremented counter; impose a maximum continuation count and stop on completion, missing secrets, repeated failures, quota/auth errors or budget exhaustion.
- Default to no more than two Gemini calls per relay run (one static-image inspection and one video/audio inspection, when both are needed); all calls require successful deterministic validation and valid capture first. Enforce a shared rolling-24-hour cap, do not auto-retry Gemini errors and keep quota use in a non-secret ledger.
- Respect the real limits of the connected GitHub account and model providers. No claims of uninterrupted or unlimited operation. Failed tests must block the success status; missing tools must be reported honestly.
- Use least-privilege GitHub Actions permissions. Never give API keys to Godot game processes, generated game code, asset archives, build artifacts or the commit step.
