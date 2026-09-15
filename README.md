# The Game Factory

AI-assisted game development pipeline centered on a persistent, versioned project registry.

## What this repository does

- Accepts a game request or an update instruction.
- Detects a supplied `GME-YYYY-NNNN` project ID and updates that project instead of creating a duplicate.
- Creates a persistent project ID for new games.
- Keeps source, tests, assets, compliance records, store assets, builds and state separated.
- Keeps credentials out of source control. Secrets are supplied at runtime through GitHub Actions or the deployment environment.
- Uses provider priority and capability metadata so the orchestration layer can prefer an available provider and fall back when appropriate.
- Runs repository validation and Python dependency/security checks in CI.

## DeerFlow 2.5 research layer

The `deerflow-2.5/` branch/directory defines the Research + Understanding + Planning upgrade used by this Game Factory. It keeps the existing downstream pipeline unchanged:

`Game Bible -> DeerFlow 2.5 -> Research Pack -> Atomic Task DAG -> Ruflo -> OpenSandbox -> DeepSeek Harness -> Godot -> QA`

The DeerFlow 2.5 overlay adds adaptive deep-game research missions, parallel research branches, evidence/source tracking, contradiction handling, reflection/re-planning, resumable checkpoints, dynamic MCP discovery and an open-source-first integration policy.

See `deerflow-2.5/PUBLIC_REPORT.md` for the complete design and `deerflow-2.5/research_policy.yaml` for the default 45-minute target / 60-minute hard-limit research policy.

## Repository layout

```text
.
├── .github/workflows/game-factory.yml   # CI/orchestration entry workflow
├── config/.env.example                  # secret names only
├── deerflow-2.5/                        # research/planning upgrade overlay
├── factory/                             # orchestration package
│   ├── cli.py
│   ├── config.py
│   └── validate.py
├── game_bible/                          # game specifications/templates
├── project_registry/                    # persistent project metadata
├── projects/                            # generated project workspaces
├── main.py                              # entrypoint
└── requirements.txt
```

## Project lifecycle

1. Analyze the request.
2. Resolve an existing project ID or allocate a new ID.
3. Load the game bible and current project state.
4. Run deep research and validate current engine/tool/store requirements before release decisions.
5. Plan changes.
6. Build and test.
7. Run security/compliance checks.
8. Generate release artifacts and documentation.
9. Record the version and immutable commit history.

## Versioning strategy

Never overwrite the only copy of a released project. Each release is tied to a Git commit/tag and a project version. Updates should be made from the latest compatible source and tested before release. If an engine upgrade is not safely compatible, the pipeline must retain the existing engine version and create an upgrade branch rather than silently migrating the project.

## Storage strategy

Git is for source/configuration and small text metadata, not multi-gigabyte game builds. Large assets/builds should use an object-storage or release-artifact backend selected by the deployment configuration. Generated projects should store references/checksums rather than embedding secrets or unnecessarily duplicating large binaries.

## Secrets

Do not put real API keys, passwords, OAuth refresh tokens, service-account JSON, private certificates, signing keys, or payment credentials in this repository. Add them as GitHub Actions secrets or the secret manager of the actual hosting environment.

## First run

```bash
python main.py --instruction "Create a new game from the game bible"
python -m factory.validate
python -m factory.cli analyze "Build and test the current project"
```

The current implementation is the secure orchestration foundation. Provider-specific API calls, Godot builds, Blender generation, store packaging, crash reporting, and support automation should be added as isolated adapters rather than hard-coded into the entrypoint.
