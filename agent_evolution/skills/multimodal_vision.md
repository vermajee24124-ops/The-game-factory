# Multimodal Vision Skill

Target: Godot 4.7.2 autonomous game-development agent.

## Goal

Use images as evidence, not decoration.

Supported evidence:
- Godot editor screenshots
- running-game screenshots
- UI screenshots
- scene screenshots
- asset previews
- error screenshots
- reference images

## Current architecture

vendor/godot-ai/vision_routing.gd already provides screenshot vision routing. A screenshot can be sent to a configured vision provider and returned as a bounded textual description when the reasoning model cannot consume images directly.

Preferred flow:

image -> vision model -> structured observations -> reasoning -> Godot tool action

When the reasoning model natively supports images, raw image input may pass through.

## Visual evidence contract

Separate every observation into:

OBSERVED: directly visible.
INFERRED: likely but not directly visible.
UNKNOWN: cannot be determined from the image.

Never invent hidden node names, file paths, scripts, physics settings, or exact numeric values from pixels alone.

## Godot editor inspection

When visible, inspect:
- active workspace
- scene tree
- selected node
- inspector
- FileSystem dock
- warnings/errors
- viewport
- gizmos
- camera
- lighting
- materials
- geometry
- UI
- debug/output panels
- play state

## Game inspection

Inspect:
- composition
- player visibility
- camera framing
- UI readability
- missing textures
- clipping
- lighting/shadows
- animation anomalies
- obvious visual performance problems
- mobile-safe layout

## Action rule

Do not make destructive edits from a screenshot alone.

Example:
1. Observe the image.
2. Find the relevant node with Godot tools.
3. Read its actual properties.
4. Make the smallest required change.
5. Run/inspect again.
6. Save after verification.

## Benchmarks

- identify selected node when visible
- identify active workspace
- detect missing texture
- detect UI overlap
- detect likely camera-framing issue
- compare before/after screenshots
- verify a requested visual change
- escalate ambiguous images
