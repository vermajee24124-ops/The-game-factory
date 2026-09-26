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
