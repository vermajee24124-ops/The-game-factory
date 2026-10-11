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

The foundation is ready for the next expansion: runtime screenshots, input simulation, profiler/log ingestion, visual regression, broader Godot tool coverage, asset-generation adapters, and a real GPU trainer.

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

To enable private QA artifact storage, add the GitHub repository variable `HF_PRIVATE_REPO_ID` and the `HF_TOKEN` Actions secret. Add `GEMINI_API_KEY` only as a GitHub Actions secret, never to source code or chat. See the quota guide for all names.

**Honest status:** the repository contains meaningful foundations and the new safety/reporting paths, but the complete factory has not yet demonstrated the full multi-genre end-to-end acceptance test. A real Turbo Rush `godot/tests/qa_playthrough.gd` now exists, but it still needs to pass CI. Final Gemini review stops before any model call if that playthrough or the video/audio recording fails.
