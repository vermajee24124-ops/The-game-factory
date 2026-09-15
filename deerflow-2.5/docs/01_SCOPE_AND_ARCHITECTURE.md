# DeerFlow 2.5 — Scope and Architecture

## Purpose

DeerFlow 2.5 is an evolved DeerFlow distribution focused on one responsibility inside The Game Factory: long-horizon research, understanding, planning, and production of a verified research package and atomic task plan.

It does not replace Ruflo, OpenSandbox, DeepSeek Harness, Godot, or downstream QA/build systems.

## Design principle

The project should have a large capability catalog without loading every tool into every model call. Capabilities are discovered and promoted on demand.

```text
bible.md
  -> mission planner
  -> research objectives
  -> parallel research workers
  -> retrieval / browser / documents / repo / academic evidence
  -> verification + contradiction handling
  -> reflection + re-planning
  -> synthesis
  -> Game Research Pack
  -> Atomic Task DAG
  -> Ruflo
```

## Research time policy

- target: 30–45 minutes
- default hard limit: 60 minutes
- completion requires objectives + evidence quality checks
- time alone never marks a run complete
- checkpoints are durable and resumable

## Research domains

The default mission template can dynamically activate game/genre analysis, comparable games, gameplay, controls, progression/economy, world/content, art/3D/assets, audio, Godot/technical architecture, performance, networking/backend, security, platforms/stores, accessibility/localization, monetization/live operations, legal/licensing, and risks/unknowns.

## Boundaries

DeerFlow 2.5 produces decisions and tasks; downstream agents execute the tasks. This separation preserves the current Game Factory architecture.
