# Video + Audio Understanding Skill

Target: Godot 4.7.2 game-development research agent.

## Goal

Learn from game-development videos using visual and audio evidence, not only transcripts.

## Current pipeline

research/gemini_youtube.py
research/gemini_batch.py
research/select_visual.py

These send public YouTube video URLs to Gemini for multimodal analysis and request technical notes instead of transcript reproduction.

## Extract

- editor workflow
- scene construction
- node creation
- inspector/property changes
- project organization
- asset importing
- plugin usage
- 2D and 3D workflows
- materials
- shaders
- lighting
- particles
- animation
- physics
- navigation
- UI
- audio
- scripting
- debugging
- profiling
- optimization
- mobile optimization
- export workflow
- reusable procedures

## Audio evidence

Use speech for:
- explanations
- tool names
- warnings
- workflow decisions
- step transitions
- reasons for a change

Cross-check important spoken claims against Godot documentation or live ClassDB/tool behavior.

## Visual evidence

Use frames/timeline to verify:
- clicks and editor actions
- visible node/property changes
- viewport before/after
- asset/plugin behavior
- demonstrated results

## Timestamped evidence

Record:
{
  "timestamp": "...",
  "observation": "...",
  "technical_action": "...",
  "godot_domain": "...",
  "verification_needed": true
}

## Skill extraction

Convert evidence into:
1. skill
2. procedure
3. tools
4. expected result
5. verification
6. pitfalls
7. benchmark prompt

Do not store entire transcripts.

## Confidence

HIGH = visual/audio evidence plus independent verification.
MEDIUM = clear demonstrated evidence but not independently verified.
LOW = ambiguous or unsupported.

Low-confidence knowledge must not become an automatic executable playbook.

## Benchmarks

- identify a workflow from video
- locate useful timestamps
- distinguish spoken claims from demonstrated actions
- extract a reusable procedure
- map it to Godot AI tools
- generate a smoke test
- flag unsupported claims
