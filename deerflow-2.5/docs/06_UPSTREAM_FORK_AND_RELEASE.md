# DeerFlow 2.5 — Upstream Fork and Release Procedure

## Current upstream pin

At the time this document was prepared, the upstream `bytedance/deer-flow` main branch resolved to commit:

`14c9d44440780e63563e935046db8708e121a5b1`

Pinning a commit makes the evolved distribution reproducible and makes upstream changes auditable.

## Correct fork strategy

1. Keep a clean record of the upstream DeerFlow commit used as the base.
2. Preserve upstream copyright and MIT license text.
3. Apply DeerFlow 2.5 changes as clearly separated commits where practical.
4. Keep third-party components in an explicit inventory.
5. Never commit API keys, OAuth secrets, browser cookies, private endpoints, or user data.
6. Provide a documented path for updating from a newer DeerFlow upstream commit.
7. Run tests and dependency/license checks before each public release.

## Distribution choices

### Overlay distribution

The repository ships integration/configuration code and fetches a pinned upstream DeerFlow source at build time. This is small and easier to maintain, but it is not a self-contained vendor tree.

### Vendored distribution

The repository contains the upstream DeerFlow source plus the DeerFlow 2.5 changes. This is closer to a conventional fork but requires repeated upstream merge/rebase work and careful third-party notice management.

### Recommended for DeerFlow 2.5

Use a true fork/vendored distribution for the public project once the source tree has been imported and tested. Until then, the current branch's integration overlay must be described honestly as an overlay.

## Public-release checklist

- upstream commit pinned
- LICENSE present
- THIRD_PARTY_NOTICES present
- dependency license scan passes
- secrets scan passes
- unit/integration tests pass
- MCP permission tests pass
- research mission resume/checkpoint tests pass
- tool-routing tests pass
- clean installation test succeeds
- documentation identifies optional paid APIs
