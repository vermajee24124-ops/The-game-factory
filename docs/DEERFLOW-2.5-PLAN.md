# DeerFlow 2.5 for Game Factory

## Status

Architecture/report proposal for the Game Factory integration. This document defines the planned DeerFlow 2.5 research and planning layer while keeping the existing Ruflo, OpenSandbox, DeepSeek Harness, Godot, QA, security, and packaging pipeline unchanged.

## Goal

Build a DeerFlow 2.5 fork/extension focused on deep, long-horizon research and planning for complex game/app projects. The goal is not to replace the game engine or coding pipeline. DeerFlow 2.5 produces a verified research package, Game Bible, and Atomic Task DAG that downstream workers execute.

## Core research loop

1. Read the project brief/bible.md.
2. Decompose the goal into research domains and explicit completion criteria.
3. Run parallel research branches where useful.
4. Search the web and primary documentation.
5. Read and extract source content rather than relying only on snippets.
6. Use GitHub for implementation and ecosystem research.
7. Use academic search (Consensus when configured) for scientific/technical evidence.
8. Maintain source notes, findings, decisions, and contradictions.
9. Reflect after research rounds and add missing research questions.
10. Cross-check important claims across independent sources.
11. Compress findings into structured knowledge.
12. Produce the final Game Blueprint/Game Bible.
13. Convert the approved blueprint into an Atomic Task DAG.
14. Stop when completion criteria are satisfied or the configured research budget is reached.

## Research budget

Default policy:

- Target: 30–45 minutes
- Maximum: 60 minutes
- Minimum useful pass: 20 minutes

Time is not the only completion rule. The agent should finish only when the required research objectives, evidence checks, and synthesis criteria are satisfied, or when the hard limit is reached. Partial research must remain resumable.

## Research domains

For a game project, DeerFlow 2.5 should dynamically consider the domains relevant to the brief:

- Game concept and genre
- Similar/competitor games
- Core gameplay loop
- Mechanics and controls
- Progression and difficulty
- World/level design
- Procedural generation
- Art direction and asset requirements
- Character/environment/prop requirements
- Audio
- UI/UX
- Godot implementation approaches
- Performance and memory budgets
- Android/iOS/Web/Windows requirements as applicable
- Networking/backend/database
- Authentication
- Security and abuse risks
- Monetization and economy
- Localization/accessibility
- Distribution/store requirements
- Legal/licensing risks
- Technical risks and alternatives

The agent must not blindly research every domain for every project. It should select domains based on the actual brief.

## Tools and integrations

The design intentionally prefers a small number of strong integrations over permanently loading a large toolbox.

### Primary web research

Tavily is the primary configured web research provider when available. DeerFlow should be able to perform search, retrieval/extraction, iterative follow-up research, and source comparison.

### Repository research

GitHub MCP/tooling is a first-class source for repository discovery, code/documentation inspection, issues, pull requests, releases, and implementation patterns where configured.

### Academic/technical evidence

Consensus can be used for peer-reviewed academic evidence and technical literature when the research question benefits from it. It should be invoked selectively, not for every web research task.

### MCP compatibility

DeerFlow 2.5 should preserve and strengthen DeerFlow's existing MCP architecture. MCP servers should be discoverable and loadable on demand instead of exposing every tool schema on every model call. Prefer namespace/prefix isolation and explicit permissions.

The intended compatibility model is:

- stdio MCP servers
- remote HTTP/streamable MCP servers where supported
- per-server tool prefixes
- tool discovery/deferred loading
- per-tool or per-server allow/deny policy
- credentials kept outside source control
- graceful handling of unavailable or failing servers

## Tool-routing policy

The model should not see every available tool all the time. The router should select tools from the current task context.

Example:

- competitor research -> web search + page retrieval
- technical implementation research -> GitHub + official docs + web search
- scientific question -> Consensus + web sources
- cloud architecture question -> Cloudflare MCP + official docs + GitHub
- project-specific question -> repository files + project memory

## Source quality policy

Research should prioritize:

1. Primary/official documentation
2. Official repositories and release notes
3. Peer-reviewed papers for scientific/technical claims
4. Reputable technical sources
5. Community sources only as supplemental evidence

Important claims should retain source URLs and a short evidence note. Conflicting claims should be recorded instead of silently choosing one.

## Research memory layout

Suggested project state:

```text
research/
  raw/
  sources/
  findings/
  decisions/
  contradictions/
  reports/
```

This allows interrupted research to resume without throwing away previous work.

## Outputs

DeerFlow 2.5 should produce at least:

- research mission
- research plan
- source index
- findings
- confidence/verification notes
- unresolved questions
- risk register
- technical recommendations
- complete Game Blueprint/Game Bible
- Atomic Task DAG
- research report with citations

## Integration boundary

DeerFlow 2.5 stops at research, understanding, planning, and task decomposition.

The existing downstream pipeline remains:

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

## Open-source policy

The DeerFlow 2.5 project should keep the upstream DeerFlow license and notices where required, while documenting the licenses of every added dependency. Only dependencies whose license is compatible with the distribution strategy should be bundled directly. Optional integrations can remain separately installed adapters.

Do not claim every external tool is "unlimited" or "free" unless its current provider terms explicitly support that claim.

## Engineering principles

- Preserve upstream compatibility where practical.
- Prefer adapters/extensions over invasive core rewrites.
- Keep secrets out of Git.
- Make tool permissions explicit.
- Make long-running research resumable.
- Cache research artifacts when appropriate.
- Use parallelism for independent research branches.
- Use reflection and re-planning to avoid premature completion.
- Keep raw evidence separate from synthesized decisions.
- Make the final plan deterministic enough for downstream execution.

## Success criteria

A DeerFlow 2.5 research run is successful when it can take a serious game/app brief, perform a structured long-horizon research mission, preserve evidence and decisions, identify missing information, revise its research plan, and emit a complete, execution-ready Game Bible plus Atomic Task DAG for the existing Game Factory pipeline.
