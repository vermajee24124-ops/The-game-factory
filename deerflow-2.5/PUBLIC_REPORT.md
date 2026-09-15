# DeerFlow 2.5 — Research and Planning Upgrade Report

## Executive summary

DeerFlow 2.5 keeps DeerFlow as the Game Factory's Research + Understanding + Planning brain. It does not replace Ruflo, OpenSandbox, DeepSeek Harness, Godot, or the existing project registry.

The upgrade focuses on making long-horizon research reliable and repeatable instead of simply adding many tools.

## Target workflow

`Game Bible -> DeerFlow 2.5 -> Deep Research -> Verified Findings -> Game Research Pack -> Atomic Task DAG -> Ruflo -> OpenSandbox -> DeepSeek Harness -> Godot -> QA`

## What DeerFlow 2.5 adds

### 1. Adaptive research mission

Every research run has:

- a target time (default 45 minutes)
- a hard limit (default 60 minutes)
- explicit research objectives
- quality gates
- resumable checkpoints

The agent is allowed to finish early only after objectives and quality checks are complete.

### 2. Parallel research branches

The mission can fan out into independent research workers for:

- game/genre landscape
- comparable games
- gameplay and controls
- progression/economy
- world/content structure
- art/3D/asset requirements
- audio/feedback
- Godot/technical architecture
- performance/scalability
- backend/networking
- security/abuse risks
- platform/store requirements
- localization/accessibility
- monetization/live operations
- risks/unknowns

The outputs are later merged by a synthesis stage.

### 3. Evidence-first research

Each important finding records its source URL and evidence note. High-impact claims should be cross-checked against multiple independent sources. Contradictions are retained rather than silently averaged away.

### 4. Reflection and re-planning

After each research wave, DeerFlow checks what remains unanswered. Newly discovered questions can create additional research branches before synthesis.

### 5. Durable project memory

Research output is separated into raw notes, sources, findings, contradictions, decisions, checkpoints and final reports so a later run can resume instead of starting from zero.

### 6. Dynamic MCP tool discovery

MCP servers are discovered and loaded on demand. The project should not expose every tool schema to every model call. Tool permissions are explicit and writes require an allowlist.

### 7. Open-source default stack

The default research/runtime distribution prefers open-source software and local/self-hosted components. External paid/proprietary services remain optional adapters and are not bundled as hard dependencies.

## Recommended default tool classes

| Capability | Default component | Why |
|---|---|---|
| Agent runtime | DeerFlow | Existing long-horizon orchestration foundation |
| Web search | Self-hosted/open search adapter or optional Tavily | Fresh web retrieval; external service remains optional |
| Browser | Playwright | Deterministic browser automation |
| Web extraction | Crawl4AI + Trafilatura | Open-source crawling and article extraction |
| Documents/PDF | Docling | Structured document parsing |
| Memory | Qdrant | Durable semantic retrieval |
| Code/repo context | GitHub MCP | Repository and engineering context |
| Academic evidence | Optional Consensus adapter | Specialized research corpus |

## What is deliberately not bundled

No proprietary model weights, API keys, paid SaaS binaries, or vendor SDK is required for the open-source baseline.

Cloud services can be connected through MCP or API adapters by an operator without making them mandatory for the core project.

## Model strategy

The model is an interchangeable runtime dependency. For a low-cost T4 deployment, use a suitably quantized open-weight reasoning model through Ollama or another supported runtime. Keep the model layer separate from the research orchestration so a larger local GPU or a remote API can be selected later without rewriting the research system.

## Game Factory hand-off contract

DeerFlow 2.5 must output at least:

1. `game-research-pack.md`
2. `sources.json`
3. `findings.json`
4. `contradictions.json`
5. `decisions.json`
6. `atomic-task-dag.json`

The downstream system consumes the task DAG. DeerFlow 2.5 does not silently take over coding or engine execution.

## Why this architecture

Research on deep-research agents consistently emphasizes dynamic reasoning, adaptive planning, multi-hop retrieval, iterative tool use and structured synthesis as distinct capabilities. A larger tool list by itself does not guarantee better research.

## Upstream/license

Upstream DeerFlow is distributed under the MIT License. Preserve its copyright/license text and the licenses/notices of all third-party components. See `LICENSES.md`.

## Release note

This repository branch currently contains the DeerFlow 2.5 integration/overlay, policy, MCP registry and public report. It is not a claim that the entire upstream DeerFlow source has already been vendored into this small Game Factory repository.
