# DeerFlow 2.5 — Deep Research Mission Contract

## Mission model

A research run is a bounded, resumable mission. The mission contains:

- project brief
- explicit research objectives
- time target
- hard time limit
- source requirements
- verification requirements
- output requirements
- completion criteria

Default policy:

```yaml
time_target_minutes: 45
hard_limit_minutes: 60
checkpoint_minutes: 10
min_independent_sources_for_high_impact_claims: 2
require_source_provenance: true
require_contradiction_review: true
require_final_synthesis: true
```

## Adaptive loop

```text
Plan
  -> Search
  -> Read / Extract
  -> Record evidence
  -> Reflect
  -> Identify missing questions
  -> Expand research graph
  -> Verify important claims
  -> Synthesize
  -> Quality gate
```

The loop can end before the time limit only if required objectives and quality gates are satisfied. It must not keep searching simply to fill the clock.

## Game-research objective template

For a new game/app, the planner may activate:

- product/game concept
- genre and market landscape
- comparable products/games
- gameplay loop and controls
- progression, economy and retention
- world/content structure
- art direction, 2D/3D assets and pipeline
- audio and feedback systems
- engine/technical architecture
- performance and scalability
- networking/backend
- security and abuse risks
- platform/store requirements
- accessibility/localization
- monetization/live operations
- legal/licensing
- implementation risks and unknowns

## Evidence record

Every important finding should carry:

- source URL or repository identifier
- retrieval timestamp when available
- evidence excerpt/summary
- confidence
- affected decision(s)
- contradiction links, if any

## Checkpointing

At each checkpoint, persist mission state, completed objectives, open questions, source index, findings, decisions and next actions. A run can resume from the latest consistent checkpoint.

## Final outputs

```text
game-research-pack.md
sources.json
findings.json
contradictions.json
decisions.json
atomic-task-dag.json
```

## Quality gate

A completed mission must answer:

1. What did we learn?
2. Which claims are strongly supported?
3. Which claims conflict?
4. What remains unknown?
5. What decisions follow from the evidence?
6. What tasks must downstream execution perform?
