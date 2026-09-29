# Godot Asset Library / Asset Store Master Skill

Target engine: Godot 4.7.2.

This skill covers the complete lifecycle of the legacy Godot Asset Library and the newer Godot Asset Store. The catalog is dynamic external data, so the agent must inspect live metadata and source rather than rely on stale memory.

## 0. Terminology
Godot 4.7 uses the newer Asset Store. The older Asset Library remains online. Distinguish:
- legacy Asset Library
- current Asset Store
- standalone project/template
- addon/resource for an existing project

Never assume an old Asset Library entry was automatically migrated.

## 1. Discovery
Search by exact name, feature, synonym, category, tag, author/publisher, Godot version, asset type, and technical domain.

Domains include 2D, 3D, rendering, materials, shaders, particles, animation, characters, terrain, navigation, audio, UI, dialogue, networking, multiplayer, save systems, debugging, profiling, editor tooling, import/export, XR, localization, procedural generation, and workflow automation.

Search iteratively:
exact query -> synonyms -> domain/tag -> compatibility -> candidate inspection -> evidence-based selection.

Do not assume search-result ordering means quality.

## 2. Asset inspection
Collect when available:
- name
- author/publisher
- description
- tags
- asset type
- supported Godot version
- asset version
- changelog
- source repository
- source branch/release
- issues tracker
- license
- attribution requirements
- dependencies
- external libraries/services
- preview images/video
- documentation
- examples/demos
- installation instructions
- update history
- last update date
- package/download information

Unknown values remain UNKNOWN.

## 3. Compatibility
Check engine version, GDScript/API compatibility, renderer assumptions, GDExtension/native binaries, architecture/platform restrictions, imports, and external dependencies.

For Godot 4.7.2, prefer explicitly compatible assets or verify source against the live engine.

Uncertain compatibility:
SANDBOX -> TEST -> VERIFY -> PROMOTE or REJECT.

## 4. License
Inspect license name, license file, copyright holder, attribution, commercial-use terms, redistribution/modification terms, and bundled third-party licenses.

Never infer a license from a repository name or preview.

Keep an asset decision record.

## 5. Dependency graph
Build:
asset -> addon/plugin -> dependency -> version -> native binary/GDExtension -> external service.

Detect missing/incompatible/circular dependencies, duplicate plugins, conflicting autoloads, input actions, project settings, classes, namespaces, and native binaries.

## 6. Package inspection
Before installation inspect ZIP/archive structure, addons/, plugin.cfg, project files, scripts, native/GDExtension files, README/license, imported resources, and unexpected executable/binary content.

Never blindly install an unknown addon into production.

## 7. Template vs addon
Standalone templates belong in a project-level sandbox.
Addons/resources are integrated into an existing project.
For editor plugins, identify plugin.cfg under addons/.
Do not enable a normal runtime script merely because its repository calls it a plugin.

## 8. Safe installation
Record current project state -> create sandbox/isolated branch -> download/import -> inspect -> install required files -> import -> scan filesystem -> enable plugin when applicable -> inspect logs -> resolve dependencies -> smoke test -> test requested feature -> compare before/after -> record exact version -> promote.

## 9. Plugin lifecycle
Understand install, enable, disable, reload, update, rollback, remove, orphan cleanup, plugin.cfg validation, and editor plugin state verification.

## 10. Resource lifecycle
For non-plugin assets: import -> inspect -> instantiate -> configure import settings -> use -> save -> test -> update/remove.

Respect Godot's import pipeline. Do not depend on hidden .godot/imported files in exported-game logic.

## 11. Visual and video evidence
Preview media proves appearance or demonstrated behavior, not compatibility.
Use the multimodal skills to inspect appearance, materials, animation, UI, artifacts, and demonstrated workflows.

## 12. Comparison
Use factual fields:
compatibility, feature coverage, license, dependencies, maintenance, documentation, platform support, performance evidence, integration complexity, verification status.

Do not use a vague overall score.

## 13. Verification
An asset is not integrated merely because it downloaded.

Verify:
- expected files under res://
- plugin metadata
- plugin load
- dependencies
- expected classes/nodes/resources
- scenes open
- requested feature works
- game runs
- no unexpected errors
- no unrelated project changes
- export test where relevant

## 14. Runtime QA
Run the main scene, instantiate the asset, exercise its primary feature, inspect logs, capture a screenshot, compare expected vs actual result, run target-platform smoke tests, and record performance observations when relevant.

## 15. Updates
Record old version/source revision -> inspect changelog -> check breaking/dependency changes -> create rollback point -> update -> import -> smoke/regression tests -> export test.

## 16. Removal
Identify installed files, plugin registration, autoloads, project settings, input actions, script/scene/resource references, and shared dependencies before removal.

Do not delete shared dependencies used elsewhere.

## 17. Asset Decision Record
Store:
{
  "name":"...",
  "source":"...",
  "author":"...",
  "asset_type":"addon|template|resource|project|unknown",
  "asset_version":"...",
  "source_revision":"...",
  "godot_min":"...",
  "godot_max":"...",
  "tested_engine":"4.7.2",
  "license":"...",
  "attribution":"...",
  "dependencies":[],
  "install_path":"res://...",
  "sandbox_test":true,
  "smoke_test":"...",
  "runtime_test":"...",
  "export_test":"...",
  "status":"verified|needs_review|rejected|unknown",
  "evidence":[],
  "notes":"..."
}

## 18. Required benchmark classes
The agent must be able to:
find 3D characters, terrain, animation, editor plugins, UI/audio/navigation/procedural-generation assets; inspect license/changelog/version; identify template vs addon; inspect dependencies/package contents; install and enable in sandbox; smoke test; detect failures; rollback; update; remove; verify no unrelated damage; create decision records; and inspect preview media without treating it as compatibility proof.

## 19. Core rule
DISCOVER -> INSPECT -> LICENSE -> COMPATIBILITY -> DEPENDENCIES -> SANDBOX -> INSTALL -> IMPORT -> ENABLE -> TEST -> VISUAL_QA -> RUNTIME_QA -> EXPORT_QA -> RECORD -> PROMOTE.

For uncertainty:
UNKNOWN + evidence request + escalation.

## 20. Source policy
Use official Godot 4.7 documentation and the actual asset repository/source as primary evidence. Query the live store for dynamic information.
