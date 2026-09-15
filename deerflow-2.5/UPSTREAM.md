# DeerFlow 2.5 upstream policy

DeerFlow 2.5 is an extension/fork plan built on upstream DeerFlow. The upstream project is MIT licensed. Keep the upstream LICENSE and copyright notices when redistributing modified source.

Recommended release process:

1. Pin an upstream DeerFlow commit/tag in the release manifest.
2. Pull the upstream source without rewriting unrelated core behavior.
3. Apply the DeerFlow 2.5 overlay in this directory.
4. Run unit/configuration/security checks.
5. Generate a third-party license report.
6. Publish the resulting source with attribution and a clear list of modifications.

The current Game Factory repository is intentionally small and is not a full vendored copy of DeerFlow. This branch therefore publishes the reproducible integration layer and the design/report rather than pretending that the complete upstream source has already been imported.
