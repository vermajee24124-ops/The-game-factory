# The Game Factory: Persistent Operating Contract

This file is the repository-side memory of the agreed Game Factory behavior. Future runs should consult it before planning or changing a project.

## Input model

The operator keeps exactly one current Game Bible in `game_bible/inbox/`. The factory reads it, normalizes it to machine-readable data, and archives the processed Bible under the resolved project.

The current Game Bible is replaceable. A new run must not assume that the previous inbox document is still relevant.

## Project resolution

Before creating anything, the factory analyzes the Bible and the request for:

1. an explicit `GME-YYYY-NNNN` project ID;
2. a known project name that resolves uniquely in the project registry;
3. explicit update/upgrade/migration language.

Behavior:

- Known ID/name + update intent -> update the existing project.
- No existing project reference + new-game intent -> allocate a new project ID.
- Unknown or ambiguous existing-project reference -> stop and report the ambiguity instead of creating a duplicate.

Every project keeps a permanent ID in `project_registry/projects.json`.

## Versioning

Git history is the authoritative source history. Releases use semantic-version tags such as `v1.0.0`, `v1.1.0`, and `v2.0.0`.

Never delete a previous release merely because a new version exists. Rollbacks are performed by checking out/rebuilding a known-good commit or release tag.

A major engine migration is isolated on a migration branch and is merged only after build, automated tests, gameplay QA, performance QA, security QA, and compliance checks pass.

## Engine policy

For new games, use the latest **stable compatible** Godot release discovered from official sources. Do not use development/nightly releases for production unless the operator explicitly changes the policy.

For existing games, do not upgrade the engine just because a newer release exists. First evaluate whether the requested change benefits from the migration and whether required plugins/assets remain compatible.

The project engine version is pinned in an engine lock file. A migration creates a backup/checkpoint first.

## Dynamic tool selection

Tools are capability workers, not mandatory dependencies. For each task use the smallest set needed to achieve the requested result:

1. Godot native capabilities first.
2. Official Godot-supported tooling/addons where compatible.
3. Verified open-source tooling.
4. External services/models only when necessary and currently eligible.

OpenManus/research workers may discover candidates, but a compatibility, license, security and policy gate must approve installation/use.

Blender and NVIDIA Cosmos are on-demand workers for asset/world-generation tasks. Local LLM execution is intentionally disabled for this factory.

## Agent architecture

Use specialized agents only when their capability is relevant. The factory should not inject the entire agent library into every request.

Expected specialist roles include planning/architecture, research, coding, backend, UI/UX, QA, security/adversarial QA, performance, release, payment/entitlement, and advertising/compliance.

Payment and advertising agents remain dormant unless the current Game Bible requests monetization.

## Model routing

OmniRoute is the preferred model-access layer. Provider choice is based on task suitability, current availability, quota/rate limits, reliability and policy eligibility, not simply model name.

Configured provider credentials may include Gemini, NVIDIA, NaraRouter, Z.AI and Hugging Face when legitimately available. No provider password is committed to source control.

No local-model fallback is used.

## Sandbox and execution

Potentially destructive generation/build/test work runs in an isolated execution environment. Generated changes are validated before they are persisted.

The factory must never expose secret values in logs or generated source.

## Security

Generated projects and the factory itself receive dependency, static, secret, configuration and controlled adversarial checks. Adversarial testing is limited to the project/build owned by the operator or an explicitly authorized test environment.

Critical security findings block release.

## Compliance

Before a release targeting an app/game store, a research worker must fetch the current official requirements for each declared target platform and record the checked date and source links.

The factory audits the project for permissions, data handling, third-party SDKs, privacy disclosures, account deletion where applicable, purchase/ads disclosures where applicable, build requirements and other current store requirements.

The factory does not promise store approval. It provides a documented compliance audit and blocks release when configured mandatory checks are missing.

## Permission and data inventory

Each project keeps a machine-readable inventory describing every runtime permission, why it is needed, where it is used, what data is collected/shared, retention/deletion behavior, and third-party services involved when known.

Privacy policy and store data declarations should be generated from this inventory so they remain consistent with the implementation.

## Offline-first rule

If the Game Bible declares the game offline, the runtime project must not activate online authentication, databases, multiplayer servers or unnecessary network capabilities. Future factory adapters may exist, but they remain inactive for the offline project.

## Storage

GitHub stores source/configuration/history. Large assets are kept outside Git history when appropriate. Hugging Face is private by default for proprietary AI/data assets. Public publishing is explicit and opt-in.

Google Drive may be used as a private archive, Cloudflare R2 as production object storage, and Backblaze B2 as an independent backup. Telegram is not the system of record.

## Release artifacts

A successful release should produce, where supported by the available toolchain:

- Android APK/AAB
- desktop artifacts
- platform-specific configuration where signing/toolchains are unavailable
- listing images
- listing video/source clips
- privacy policy
- terms/support documents
- permissions/data inventory
- compliance report
- test/security/performance report
- release manifest and checksums

## Failure-closed behavior

The factory must stop instead of silently doing the wrong thing when it encounters an unknown project ID, ambiguous update, failed validation, unavailable required capability, critical security issue, or missing mandatory compliance evidence.
