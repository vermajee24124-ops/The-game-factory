# DeerFlow 2.5 for Game Factory

> Public architecture/report for the DeerFlow 2.5 research and planning fork.

## Scope

DeerFlow 2.5 is intended to strengthen only the **Research + Understanding + Planning** stage of the Game Factory. It does not replace or merge the downstream Ruflo, OpenSandbox, DeepSeek Harness, Godot, QA, security, cross-platform, or packaging systems.

## Deep Game Research mission

For each project brief (`bible.md`), DeerFlow 2.5 should create a research mission with explicit domains, questions, evidence requirements, completion criteria, and a time budget.

Default research budget:

- target: 30–45 minutes
- hard maximum: 60 minutes
- minimum useful pass: 20 minutes

The time budget is not the only stopping rule. The run should stop when the required objectives, verification checks, and synthesis criteria are satisfied, or when the hard limit is reached. Interrupted runs must be resumable.

## Research domains

Select domains dynamically from the brief rather than running every domain every time:

- genre and game concept
- similar/competitor games
- gameplay loop and mechanics
- controls and UX
- progression and difficulty
- world and level design
- procedural generation
- characters, environments, props, VFX, textures
- art direction and asset pipeline
- audio
- UI/UX
- Godot implementation approaches
- performance and memory budgets
- target platform requirements
- networking/backend/database/authentication
- security and abuse risks
- monetization/economy
- localization/accessibility
- distribution/store requirements
- licensing/legal risks
- technical risks and alternatives

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

## Tool strategy

Use a small number of strong integrations and load tools on demand.

### Primary web research

Tavily is the primary web research provider when configured.

### Repository research

GitHub tooling/MCP is used for repository, code, documentation, issues, pull requests, releases, and implementation-pattern research.

### Academic evidence

Consensus is used selectively for peer-reviewed scientific/technical evidence when the question warrants it.

### MCP

DeerFlow 2.5 should remain broadly MCP-compatible and preserve DeerFlow's deferred tool discovery/loading model. Supported adapters should cover stdio and remote HTTP/streamable MCP servers where compatible. Tool schemas should not all be injected into every model call.

Security requirements for MCP:

- explicit per-server permissions
- optional per-tool allow/deny rules
- isolated namespaces/tool prefixes
- secrets outside Git
- validation before enabling an adapter
- graceful failure and fallback
- audit logging for consequential actions

## Source verification

Important claims should retain source URLs and evidence notes. Prefer primary/official documentation and repositories, then peer-reviewed research, reputable technical sources, and community sources as supplemental evidence.

Conflicts must be recorded as conflicts. The system must not silently convert uncertain information into fact.

## Research memory

```text
research/
  raw/
  sources/
  findings/
  decisions/
  contradictions/
  reports/
```

The research state should survive interruptions and support resume/follow-up runs.

## Outputs

Every completed mission should be able to produce:

- research mission and objectives
- research plan and branch status
- source index
- evidence/findings
- confidence and verification notes
- contradictions and unresolved questions
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

DeerFlow 2.5 ends at the planning/task boundary unless an explicit integration requests otherwise.

## Model abstraction

Do not hard-code one LLM into the product. Keep a model adapter/router so local Ollama/vLLM models and compatible hosted APIs can be selected by task capability. Research, summarization/compression, and final synthesis may use separate model slots in future versions.

## Open-source policy

Retain upstream DeerFlow license and notices as required. Every added dependency must have its license recorded. Optional provider integrations should remain optional adapters when licensing, credentials, or service terms make bundling inappropriate.

Do not describe a third-party API as unlimited or free unless its current terms explicitly support that claim.

## Engineering principles

- preserve upstream compatibility where practical
- prefer extensions/adapters over invasive rewrites
- keep secrets out of source control
- use deferred tool loading
- parallelize independent research
- reflect and re-plan instead of stopping after the first useful search
- separate raw evidence from synthesized decisions
- make long-running research resumable
- keep the downstream Game Factory pipeline unchanged

## Success criteria

DeerFlow 2.5 is successful when a serious game/app brief can trigger a structured long-horizon research mission that gathers and verifies evidence, explores missing questions, synthesizes the findings, and emits an execution-ready Game Bible plus Atomic Task DAG for the existing Game Factory.
