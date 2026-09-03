# Game Bible Inbox

Put exactly one active Game Bible here before manually starting the workflow.

Primary format: `.docx`. Markdown/text may be used for machine-readable or interim inputs.

## Required workflow behavior

1. Read the current Bible before planning work.
2. Detect an explicit Project ID such as `GME-2026-0001`, an existing project name, and whether the request is new or an update.
3. If an existing project is uniquely identified, update that project instead of creating a duplicate.
4. If the Bible describes a genuinely new project with no existing reference, allocate a new Project ID.
5. For updates, load the current source, asset manifest, engine lock, release metadata and prior version history.
6. Create an isolated checkpoint/branch for material changes and preserve the previous stable release.
7. Run build, tests, gameplay QA, performance QA, security checks and required compliance checks before a release is considered complete.
8. Generate/store release metadata and checksums.
9. Archive the processed Bible under the project so replacing the inbox never deletes historical specifications.

The inbox is replaceable input. It must never be treated as the source of truth for credentials or secrets.

## Never put in the Bible inbox

- API keys or access tokens
- passwords
- service-account private keys
- signing certificates/private keys
- production secrets

Those belong in the approved secret manager/runtime environment only.
