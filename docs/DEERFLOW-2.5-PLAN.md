# DeerFlow 2.5 for Game Factory

> Public architecture/report for a DeerFlow 2.5 research/planning fork. The downstream Game Factory pipeline stays unchanged.

## Scope

DeerFlow 2.5 strengthens only Research + Understanding + Planning for complex game/app projects. Ruflo, OpenSandbox, DeepSeek Harness, Godot, QA, security, cross-platform validation, and packaging remain separate downstream components.

## Deep Game Research mission

For every `bible.md`, create a research mission with explicit domains, questions, evidence requirements, completion criteria, and a time budget.

Default budget:
- target: 30–45 minutes
- hard maximum: 60 minutes
- minimum useful pass: 20 minutes

The timer is not the only completion rule. Finish when required objectives, evidence checks, and synthesis criteria are satisfied, or at the hard limit. Interrupted runs must be resumable.

## Dynamic research domains

Select only domains relevant to the brief:
- genre, concept, USP, competitors/similar games
- gameplay loop, mechanics, controls
- progression, difficulty, economy, retention
- world/level design and procedural generation
- characters, environments, props, VFX, textures
- art direction and asset pipeline
- UI/UX and audio
- Godot implementation approaches
- performance and memory budgets
- Android/iOS/Web/Windows requirements when applicable
- networking, backend, database, authentication
- security and abuse risks
- monetization
- localization/accessibility
- distribution/store requirements
- licensing/legal risks
- technical risks, alternatives, and open questions

## Research loop

```text
Brief
  -> Research Mission
  -> Research Plan
  -> Parallel Research Branches
  -> Search / Browse / Read
  -> Source Extraction
  -> Evidence Notes
  -> Cross-check / Contradiction Detection
  -> Reflection
  -> Re-plan / Follow-up Research
  -> Compression / Synthesis
  -> Quality Gate
  -> Game Blueprint / Game Bible
  -> Atomic Task DAG
```

## Strong tools, loaded on demand

- **Tavily:** primary web research and retrieval when configured.
- **GitHub/MCP:** repositories, code, docs, issues, PRs, releases, implementation patterns.
- **Consensus:** peer-reviewed technical/scientific evidence when useful.
- **Cloudflare MCP (optional):** Cloudflare infrastructure research/operations when the project uses Cloudflare.
- **DeerFlow built-ins:** browser, files, sandbox, skills, memory, subagents, context management.

DeerFlow 2.5 should not permanently inject every tool schema into every model call. Use deferred discovery, namespaces, and task-specific routing.

## Universal MCP compatibility

The fork should preserve and strengthen DeerFlow's MCP support:
- stdio MCP
- remote HTTP/streamable MCP where compatible
- tool-name prefixes/namespaces
- deferred discovery/loading
- per-server and per-tool permissions
- credential references kept outside Git
- adapter validation before enablement
- graceful failure and fallback
- audit logging for consequential operations

## Evidence quality

Prefer, in order:
1. Primary/official documentation and first-party repositories.
2. Official releases/issues/implementation documentation.
3. Peer-reviewed research for scientific/technical claims.
4. Reputable technical sources.
5. Community sources as supplemental evidence.

Important claims retain source URLs and evidence notes. Conflicting claims are recorded instead of silently merged.

## Persistent research memory

```text
research/
  missions/
  raw/
  sources/
  findings/
  decisions/
  contradictions/
  reports/
```

Research state must survive interruption and support resume/follow-up runs.

## Required outputs

- research mission/objectives
- research plan and branch state
- source index
- evidence/findings
- confidence/verification notes
- contradictions/unresolved questions
- technical recommendations
- risk register
- complete Game Blueprint/Game Bible
- Atomic Task DAG
- cited research report

## Existing Game Factory boundary

```text
bible.md
  -> DeerFlow 2.5
  -> Research + Understanding + Planning
  -> Game Bible
  -> Atomic Task DAG
  -> Ruflo
  -> OpenSandbox
  -> DeepSeek Harness
  -> Godot
  -> Build / QA
  -> Diagnose / Fix / Retest
  -> Security
  -> Cross-platform validation
  -> Packaging / Reports
```

## Model abstraction

Do not hard-code a single LLM. Keep a model adapter/router so local Ollama/vLLM and compatible hosted APIs can be selected by capability. Research, compression, and final synthesis may use separate model slots in future versions.

## Open-source policy

Keep upstream DeerFlow license and notices as required. Record the license of every added dependency. Keep provider-specific integrations optional when their credentials or service terms require it. Never claim a provider is unlimited/free unless its current terms explicitly say so.

## Engineering principles

- preserve upstream compatibility where practical
- prefer extensions/adapters over invasive rewrites
- keep secrets out of source control
- use deferred tool loading
- parallelize independent research
- reflect and re-plan instead of stopping after the first useful search
- separate evidence from decisions
- make long-running research resumable
- keep the downstream Game Factory unchanged

## Success criteria

A serious game/app brief should produce a structured long-horizon research mission that explores the relevant research space, preserves evidence, checks contradictions, identifies missing questions, synthesizes findings, and emits an execution-ready Game Bible plus Atomic Task DAG for the existing Game Factory.
