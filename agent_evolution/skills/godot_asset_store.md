# Godot Asset Store / Asset Library Master Skill

Target: Godot 4.7.2.

The agent must treat the Asset Store and legacy Asset Library as a first-class development capability.

## Coverage

Learn to search, inspect, compare, validate, install, enable, test, update, remove, and document Godot assets.

For every asset inspect:
- name and author
- description and tags
- supported Godot version
- exact asset version and changelog
- license and attribution
- source repository when available
- dependencies
- preview images/video
- whether it is a template/standalone project or an addon/resource for an existing project

## Safe workflow

1. Understand the requested game feature.
2. Search exact feature terms and useful tags.
3. Inspect several relevant candidates.
4. Check Godot 4.7.2 compatibility.
5. Check license and dependencies.
6. Inspect changelog and preview media.
7. Snapshot the project before installation.
8. Install in a sandbox when risk or complexity is non-trivial.
9. Let Godot import the files.
10. Enable the plugin when applicable.
11. Check logs and dependencies.
12. Run a minimal smoke test.
13. Test the asset in the target scene.
14. Record the exact version used.
15. Promote it to production only after verification.

## Legacy Asset Library

Godot 4.7 uses the newer Asset Store. The older Asset Library remains online, and older assets were not automatically migrated. The agent must distinguish the two.

## Verification

An asset is not considered integrated just because it downloaded.

Verify:
- intended files exist under res://
- plugin metadata is valid when applicable
- plugin loads without errors
- dependencies resolve
- requested nodes/resources/scripts can be instantiated
- main scene opens
- game runs
- requested feature works
- no unrelated files or nodes changed
- license/attribution record exists

## Security and quality

Never silently install an unknown addon into a production project.

If compatibility, license, dependency, or behavior is uncertain, sandbox it or escalate.

Never treat preview media as proof of compatibility.

Never copy proprietary source/assets beyond their license.

## Tool mapping

Prefer live Godot AI tools:
filesystem_manage, project_manage, project_run, editor_manage, editor_state,
scene_open, scene_manage, scene_save, node_find, node_manage,
resource_manage, logs_read, test_run, test_manage.

## Asset Decision Record

Store:
{
  "name": "...",
  "source": "...",
  "asset_version": "...",
  "godot_version": "...",
  "license": "...",
  "dependencies": [],
  "install_path": "res://...",
  "tested": true,
  "smoke_test": "...",
  "notes": "..."
}

## Benchmarks

Pass tests for:
- finding a 3D character asset
- finding a terrain/animation/tool addon
- inspecting license and changelog
- identifying template versus addon
- checking Godot 4.7.2 compatibility
- installing and enabling a plugin in a sandbox
- verifying and removing the plugin
- detecting a dependency problem
- creating an asset decision record
