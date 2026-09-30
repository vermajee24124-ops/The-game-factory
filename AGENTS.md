# Turbo Rush AI Engineering Contract

## Mission
Finish projects/GME-2026-0003/godot as a mobile-first Godot 4.7.2 release candidate using the canonical Turbo Rush specification.

## Hard constraints
- Keep the game finite level-based racing, not endless.
- 1 player + 5 AI.
- 3-second countdown.
- Deterministic level generation from level number + game salt.
- Standard 120–170s, Sprint 85–115s, Endurance 175–215s, Elite 130–180s.
- Top-5 finish unlocks the next level.
- Assist after two failures on the same level.
- Coins and Diamonds rules must stay consistent with the PRD.
- Local JSON save, backup, checksum and migration boundary.
- Core play must remain offline.
- Ads and IAP stay behind adapters and never fabricate success offline.
- Never commit API keys, tokens, cookies, signing material or other secrets.
- Never weaken repository security to make a build pass.

## Asset policy
Use the official Godot Asset Library only for small, clearly useful additions.
Before importing an asset, confirm Godot compatibility and record source, version and license in projects/GME-2026-0003/docs/ASSET_MANIFEST.md.
Prefer compatible permissive licenses. Do not bulk-copy unrelated assets.

## AI stack
- Lead implementation: CodeCraft API. Select the exact account-visible model dynamically. Prefer claude-opus-5.5 only if the account /models endpoint exposes that exact ID; otherwise use the highest available Claude Opus model.
- Review: NaraRouter and NVIDIA NIM when secrets are configured.
- DeepSeek Harness: optional development harness only. Do not make the shipped game depend on it.
- Strix: optional security stage. Basic secret and dependency checks remain mandatory.

## Definition of done
- Godot project imports headlessly without script parse errors.
- Smoke tests pass.
- git diff --check passes.
- No tracked secrets.
- Canonical gameplay rules remain intact.
- A machine-readable report is written to agent_stack/reports/latest.json.