# Turbo Rush Claude Code instructions

## Scope
Work primarily inside:
- projects/GME-2026-0003/godot
- projects/GME-2026-0003/docs
- projects/GME-2026-0003/state
- projects/GME-2026-0003/compliance
- projects/GME-2026-0003/store

## Canonical requirements
Read:
1. projects/GME-2026-0003/state/FINAL_BUILD_PROMPT.md
2. game_bible/GME-2026-0003/game_bible.yaml
3. projects/GME-2026-0003/docs/TRACEABILITY.md
4. the original six specification documents when present in the conversation/repository

## Engineering rules
- Godot 4.7.2
- Mobile renderer
- Landscape
- Offline-first
- 1 player + 5 AI
- Finite races, never endless
- Deterministic level generation
- Preserve the canonical race-time ranges
- Never invent Godot APIs
- Inspect before editing
- Test after meaningful changes
- Never commit secrets
- Keep ads/IAP behind adapters
- Do not let online services block core gameplay

## Asset rule
Use the repository's Godot Asset Library/Asset Store skill before installing any third-party package. Inspect license, dependencies, engine compatibility, native binaries, permissions and platform constraints. Prefer procedural/Godot-native content for the mobile baseline.

## Completion rule
Do not say "production ready" unless:
- headless import passes
- smoke tests pass
- final build artifact exists
- Android/iOS export checks pass for the targeted platforms
- release blockers are documented
