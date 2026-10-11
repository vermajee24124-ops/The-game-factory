# Construction Task for OpenBot/OpenDot-Style Builder Agent

**Target repository:** `vermajee24124-ops/The-game-factory`  
**Primary reference:** `docs/PDF_ALIGNMENT_PUBLIC_REPORT.md`  
**Secret/quotas rulebook:** `docs/SECRETS_AND_QUOTAS.md`  
**Persistent contract:** `docs/FACTORY_CONTRACT.md`

## Mission

You are the construction-stage chief engineer. Do not spend this task making just one attractive demo game. Build, test and document the reusable Autonomous Godot Game Factory so future users can provide one short game idea and the factory carries out the development pipeline itself.

Work inside the target repository with the connected GitHub permissions actually available to you. First inspect the complete repository, existing projects, workflows, dependencies, current branch, open issues and CI results. Do not assume that a file named "engine", "pipeline" or "QA" is complete just because it exists. Run the code and inspect outputs.

## Non-negotiable rules

1. Do not ask the user to hand-write code, install each tool manually or connect every component one by one. Automate routine setup where access and runner limits allow it.
2. Do not report success based on a model response, a created folder, a return message or a shell command alone. Require reproducible tests and saved evidence.
3. Keep Gemini out of routine coding, research, agent evolution and fix/retest loops. Only `.github/workflows/final-gameplay-qa.yml` may use `GEMINI_API_KEY`, and only after a real gameplay playthrough and valid video/audio capture have succeeded. Keep the private rolling-24-hour reservation guard; do not bypass it or retry models automatically.
4. Use NVIDIA NIM as the preferred coding/reasoning provider when available. Respect the repository's conservative limit of 35 calls/minute. Keep model IDs configurable and verify endpoint availability before relying on them.
5. Keep private credentials out of source code, generated game code, public artifacts, commit messages and logs. Hugging Face tokens and API keys belong in GitHub Actions Secrets only.
6. Do not auto-install a community tool or import an asset unless compatibility, permissions and licensing have been checked. Preserve source URLs and license metadata. Publicly accessible does not mean approved for commercial use or model training.
7. Keep the default pipeline CPU-first and Godot-first. Use containers/heavy services only if there is a proven need and an available budget. Avoid promising a fixed FPS based on software rendering.
8. The research watcher may use public official/GitHub/Hugging Face metadata without calling an LLM. Never re-enable the old scheduled Gemini video-research matrix.
9. If a workflow lacks permission, secrets, storage or an actual tool, state the blocker and leave evidence. Do not invent OAuth access or silently bypass failed checks.

## Required construction work

### A. Finish the durable factory runtime
- Complete provider selection, API error handling, bounded retries for non-Gemini calls, rate limiting, timeouts, cancellation, structured logs and resumable project state.
- Turn the current scaffold/resolver into a real request-to-project workflow: research, game-specific design/specs, asset/license manifest, scene/resource creation, GDScript implementation, import validation, playthrough tests, debugging, build and release evidence.
- Preserve project IDs, explicit update-vs-new-project semantics, Git history, checkpointing and safe rollback.
- Make each phase a verified task with inputs, outputs, exit criteria and an audit record. No phase may be marked done before its output is checked.
- Preserve the user's short-prompt workflow. Support a direct instruction and a Game Bible where applicable.

### B. Build a real test curriculum, not just repeated empty scaffolds
Create and actually run separate Godot projects in a staged curriculum:
1. Small 2D arcade/puzzle game.
2. 3D three-lane endless runner.
3. Original sci-fi/gravity-shift runner.
4. Arcade waypoint racer with opponent cars and finish/results.
5. Highway traffic-dodging racer.
6. Third-person arena prototype.
7. One additional genre chosen from current research (for example a board simulation or platformer).

These are qualifying projects used to improve and test the factory. They are not automatically store-ready releases. Record each project's commit, engine version, design files, assets/licences, test commands, test results, screenshots, build outputs and known limitations. Add a project-specific `godot/tests/qa_playthrough.gd` only after understanding the game's actual control scheme and core loop. It must exercise meaningful gameplay, assert observable outcomes and exit nonzero if the test fails. Do not fake a successful playthrough by only loading a scene or taking a screenshot.

### C. Make QA evidence-based
For every project implement:
- Godot editor/import check and parse/compile-error detection.
- Smoke tests and meaningful project-specific input simulation/autoplay.
- Runtime logs and crash detection.
- Screenshot capture and visual inspection when available.
- Video and audio capture with a virtual display/audio sink where supported.
- A bounded bug-fix loop followed by the same failing tests again.
- A machine-readable QA report with scores, timestamps and source artifacts.
- Security/dependency/secret/license checks and a clear release blocker list.

The 90/100 score is only an additional quality target. Missing core gameplay, crashes, impossible progression, failed imports/builds, serious license/security issues or absent required evidence must block release even if a model assigns a high score.

### D. Make the final Gemini gate safe
- Keep the current final-only workflow manual until each project has a valid autoplay script.
- Capture the actual completed playthrough into a video file with both video and audio streams; verify file duration and stream presence.
- Only then reserve daily quota in the private Hugging Face ledger and call each configured Gemini review model once in sequence. No automatic retries. Keep the private full report/video archive, but expose only a non-sensitive run-status artifact on GitHub.
- Review observations should include timestamps and actionable fixes. The game agent, not Gemini, performs playback. Gemini is a reviewer, not proof of a perfect or store-approved game.

### E. Keep live research and learning economical
- Keep `.github/workflows/live-research-watch.yml` low-cost, weekly/manual, and free of AI credentials. Record when sources were checked and their URLs.
- Research official Godot/Android/Apple/Google Play/GitHub/Hugging Face documentation, compatible open-source Godot tools/MCPs, game-development techniques and license details.
- Save concise reusable research as version-controlled skills or manifests after validation. Avoid copying game content or reproducing source transcripts.
- Make expensive model-driven agent evolution manual-only unless a later verified budget policy is explicitly added.

### F. Private storage and release outputs
- Use GitHub for source, small reports and workflow definitions.
- Use a private Hugging Face dataset repo for large gameplay recordings, reports and approved packaged artifacts after confirming that the destination is private and the token has write permission.
- Do not add tokens, private data or large binaries to public commits. Do not claim 40-50 GB of storage unless the account's live quota verifies it.
- Produce a clear output manifest with game project, build status, links to artifacts, license manifest, QA summary, security/compliance findings and unresolved blockers.

## Completion criteria

Do not declare the factory complete until all of these are true:
- A fresh idea can create a new project without hand-editing code.
- The generated Godot project imports successfully and runs.
- The relevant project-specific gameplay test really plays the core loop and verifies its result.
- A deliberate test failure is caught, repaired, and retested with evidence.
- Valid video/audio capture is demonstrated on at least one project.
- Private archive credentials are verified without printing them; the archive destination is confirmed private.
- The quota guard is tested and prevents a reservation when the rolling-24-hour cap is reached.
- The curriculum has actual per-project status, not placeholder "complete" flags.
- CI, security and compliance checks report their real outcomes.
- Documentation distinguishes implemented, tested, pending and blocked items.

## Delivery format

Commit in small checkpoints on a dedicated branch and open a reviewable pull request if the connected permissions allow it. Do not merge automatically unless all required checks pass. Provide a final construction report with commits, workflow run links, tests and logs, created projects, artifact paths, secret names needed, remaining blockers and the exact next action. Never claim that a workflow ran successfully unless a real run record exists.
