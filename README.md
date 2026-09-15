# The Game Factory

AI-assisted game development pipeline centered on a persistent, versioned project registry.

## DeerFlow 2.5

`deerflow-2.5/` is the Research + Understanding + Planning evolution of this Game Factory. It is designed to keep DeerFlow as the research director while leaving the downstream execution stack unchanged:

`Game Bible -> DeerFlow 2.5 -> Deep Research -> Verified Findings -> Game Research Pack -> Atomic Task DAG -> Ruflo -> OpenSandbox -> DeepSeek Harness -> Godot -> QA`

The DeerFlow 2.5 work adds:

- adaptive long-horizon research missions (30–45 minute target, 60 minute hard limit by default)
- objective-based completion and quality gates
- parallel research branches
- evidence/provenance records and contradiction handling
- reflection and dynamic re-planning
- durable checkpoints and resumable research
- dynamic MCP discovery/deferred tool promotion
- explicit tool permission boundaries
- an open-source-first component strategy
- reproducible upstream pinning and release/licensing checks

The public design and research notes are under `deerflow-2.5/docs/`. The most important documents are `PUBLIC_REPORT.md`, `docs/01_SCOPE_AND_ARCHITECTURE.md`, `docs/03_MCP_UNIVERSAL_CONNECTOR.md`, `docs/04_DEEP_RESEARCH_MISSION.md`, and `docs/06_UPSTREAM_FORK_AND_RELEASE.md`.

## Important distribution note

DeerFlow upstream is MIT-licensed and permits modification and redistribution when the required copyright/license notice is retained. This branch currently contains the DeerFlow 2.5 integration and research layer; it is not yet a byte-for-byte vendored copy of the full upstream DeerFlow source tree. The public release procedure therefore requires a final upstream sync/import and a clean dependency/license audit before calling the repository a complete independent DeerFlow 2.5 fork.

## Current Game Factory responsibilities

- Accepts a game request or update instruction.
- Resolves a persistent project ID and avoids accidental duplicates.
- Keeps source, tests, assets, compliance records, store assets, builds and state separated.
- Keeps credentials out of source control.
- Uses capability metadata and fallback-aware orchestration.
- Runs validation and dependency/security checks in CI.

## Repository layout

```text
.
├── .github/workflows/game-factory.yml
├── config/.env.example
├── deerflow-2.5/
│   ├── PUBLIC_REPORT.md
│   ├── LICENSES.md
│   ├── UPSTREAM.md
│   ├── mcp_registry.example.json
│   ├── research_director.py
│   ├── research_policy.yaml
│   └── docs/
├── factory/
├── game_bible/
├── project_registry/
├── projects/
├── main.py
└── requirements.txt
```

## Secrets

Never commit API keys, OAuth refresh tokens, private certificates, service-account files, signing keys, payment credentials, or browser cookies. Use runtime secret injection from the deployment environment or GitHub Actions secrets.

## First run

```bash
python main.py --instruction "Create a new game from the game bible"
python -m factory.validate
python -m factory.cli analyze "Build and test the current project"
```

## License

See the repository license and `deerflow-2.5/LICENSES.md`. Third-party components keep their own licenses and notices. Hosted APIs are optional adapters and are not represented as unlimited or universally free.
