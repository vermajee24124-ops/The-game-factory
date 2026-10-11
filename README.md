# The Game Factory

AI-assisted game-development pipeline centered on a persistent, versioned project registry.

## Godot AI SuperAgent

This branch adds a Godot 4.7.2-first autonomous agent under `addons/godot_ai_superagent` and `ai_superagent`.

Core loop:

inspect -> plan -> act -> observe -> verify -> repair -> retest -> remember

The editor plugin has:
- live dock UI
- model endpoint adapter
- project and scene inspection
- bounded scene mutations
- file read/write tools
- runtime start/stop
- permission gating
- persistent memory
- strict JSON tool protocol

## Evolution pipeline

The GitHub CPU workflow prepares the knowledge manifest, calls the configured OpenAI-compatible gateway, generates tool-use trajectories, measures protocol compliance, and stores a non-secret regression report.

This is deliberately not described as frontier-model weight training on CPU. The generated trajectories are training-ready input for a later GPU SFT/LoRA stage.

## FreeLLMAPI

The supplied FreeLLMAPI project can be used as the OpenAI-compatible gateway.

Configure GitHub Actions secrets:
- FREELLMAPI_BASE_URL
- FREELLMAPI_API_KEY
- FREELLMAPI_MODEL

Never commit real credentials.

## Knowledge base

Keep the supplied Godot-4.7.2 knowledge file under `knowledge/Godot-4.7.2-Exhaustive-Knowledge-Base.md`. The indexer records its hash, line count and headings.

## Current scope

The original Godot AI SuperAgent foundation remains separate from the new autonomous multi-game factory construction workflow below. The construction workflow is not considered successful until GitHub Actions has actually run its checks and saved evidence.

See `docs/AI_SUPERAGENT_ARCHITECTURE.md`.

## Autonomous Game Factory plan and operations

This repository is being expanded toward the two-phase design in the 112-page planning PDF: a builder agent constructs the durable factory, then the factory independently accepts one-line game ideas. Read the public implementation/readiness report before treating the factory as complete:

- [Public PDF-alignment and readiness report](docs/PDF_ALIGNMENT_PUBLIC_REPORT.md)
- [Construction task for OpenBot/OpenDot-style builder agents](docs/CONSTRUCTION_AGENT_TASK.md)
- [Secrets, quota and private storage setup](docs/SECRETS_AND_QUOTAS.md)
- [Persistent factory contract](docs/FACTORY_CONTRACT.md)

## Added quota-safe workflows

- **Live Research Watch**: weekly/manual public Godot, GitHub and Hugging Face metadata checks; does not call an LLM.
- **Final Gameplay Video and Audio QA**: manual only. It requires a project-specific Godot autoplay test, a valid video/audio recording, a private Hugging Face archive, and a private rolling-24-hour quota reservation before calling Gemini 3.8/3.7/3.6 Flash once each.
- **Routine code/evolution workflows** no longer receive the Gemini secret. NVIDIA NIM is preferred for general coding/reasoning, subject to account/model availability and the configured quota guard.

To enable private QA artifact storage, add the GitHub repository variable `HF_PRIVATE_REPO_ID`, the archive-write `HF_TOKEN` secret, and `GEMINI_API_KEY` (final QA only). Add `HF_INFERENCE_TOKEN` separately only if you want Hugging Face inference as a model route. Never put keys in source code or chat. See the quota guide for all names.

**Honest status:** the repository contains meaningful foundations and the new safety/reporting paths, but the complete factory has not yet demonstrated the full multi-genre end-to-end acceptance test. A real Turbo Rush `godot/tests/qa_playthrough.gd` now exists, but it still needs to pass CI. Final Gemini review stops before any model call if that playthrough or the video/audio recording fails.


## Start the two-phase Autonomous Godot Game Factory

**Repository:** `vermajee24124-ops/The-game-factory`

The uploaded 26-page Godot-studio PDF's extracted text and implementation contract are now included for the construction agent to read:
- [Extracted full PDF text](docs/reference/AI_AGENT_GODOT_GAME_STUDIO_PDF_EXTRACT.md)
- [Factory implementation blueprint](docs/GODOT_GAME_STUDIO_BLUEPRINT.md)
- [Construction agent system instructions](factory_builder/AGENT_SYSTEM_PROMPT.md)
- [Construction implementation task](docs/CONSTRUCTION_AGENT_TASK.md)
- [Secret and quota setup guide](docs/SECRETS_AND_QUOTAS.md)

### Phase 1 — Build the reusable factory
Open **Actions → Phase 1 - Build Autonomous Godot Game Factory → Run workflow**. It uses `NVIDIA_BUILDER_KEY` only in the construction step, installs Godot 4.7.2 and CPU audiovisual test dependencies, asks the bounded meta-agent to create the permanent `game_factory/` modules and seven planning specs, and validates an original demo. Failed validation creates a pending checkpoint/report instead of being described as completion.

### Phase 2 — Run a game idea through the persistent factory
After Phase 1 has successfully produced and tested `game_factory/cli.py`, `orchestrator.py` and `state_manager.py`, open **Actions → Phase 2 - Autonomous Game Factory Relay → Run workflow**. It separates NVIDIA coding/repair steps from Gemini screenshot/video/audio review steps, saves per-idea state, and can dispatch bounded follow-up runs. The default is at most 16 automatic handoffs; provider quota, runner time, access or validation failures can stop earlier.

### Required repository secrets
- `NVIDIA_BUILDER_KEY` — Phase 1 construction only.
- `NVIDIA_FACTORY_KEY` — Phase 2 research/coding/repair only.
- `GEMINI_API_KEY` — Phase 2 screenshot/video/audio QA only after capture succeeds.

Optional model IDs and endpoints belong in repository **Variables**, not in source code. Exact instructions and existing legacy-workflow credentials are listed in [the secret guide](docs/SECRETS_AND_QUOTAS.md). Never paste a real key into chat or a commit.

### Important status note
The workflow definitions and source-informed construction agent have been committed, but the Phase 1/2 workflows have **not** been run in this setup session: the new secrets have not yet been supplied through GitHub Settings. Do not regard the full game factory, video/audio QA, security audit, or Android AAB as proven until their actual runs pass. The repository is currently public, so anything committed under `games/` and `deliverables/` can be visible publicly.
