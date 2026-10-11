# Public Architecture and Readiness Report: Autonomous Godot Game Factory

**Report date:** 2026-10-11  
**Repository:** https://github.com/vermajee24124-ops/The-game-factory  
**Basis:** User's 112-page `pura.pdf`, current repository files/workflows, and the user's stated API-quota policy.

## 1. Mission

Build a persistent, reusable, multi-game AI Game Factory, not just a one-off game generator.

The system has two distinct phases:

1. **Construction phase:** a capable builder agent inspects the repository and its documentation, wires compatible open-source tools and AI endpoints together, implements missing pieces, creates automated test projects across several game genres, runs the workflow, fixes evidenced failures, and leaves a durable factory in the repository.
2. **Operating phase:** the user provides a short game idea or Game Bible. The standalone factory researches the request, plans and generates a Godot project, validates and plays it through automated checks, repairs failures, and produces source/build artifacts with honest QA evidence. The construction agent should not be required for every future game.

The factory must never claim that a game is finished merely because an AI response or shell command returned. Completion requires recorded evidence.

## 2. Intended pipeline

`Idea/Game Bible -> Fresh research -> Design brief -> Project/scene plan -> Licensed assets -> Godot implementation -> Automated playthrough -> Logs/screenshots/video+audio -> Repair/retest -> Security/compliance -> Build artifacts + report`

A durable project registry and Git history preserve project identity and progress. A new game receives a new project ID; an explicit update should update the existing project instead of silently duplicating it.

## 3. Builder and specialist roles

The construction agent may select the best available coding agent from the user's connected OpenBot/OpenDot-style options. It must check what the selected agent can actually access, then build with the least complex compatible set of tools. Candidate workers include:

- Game designer/planner and current-source researcher.
- Godot 4.x/GDScript implementer and scene/node editor.
- Asset/license scout and procedural asset worker.
- Runtime input/autoplayer, smoke-test and log-analysis worker.
- Screenshot/video/audio QA worker.
- Security, store-compliance and release worker.
- Progress/checkpoint and regression-report worker.

Godot-MCP or another verified Godot tool server may be used when its version, license, permissions and methods have been checked. The factory must not assume that any named plugin or MCP implementation is safe or compatible without checking it.

## 4. Multi-game training and acceptance curriculum

The construction builder should not only test itself on an empty demo. It should create and validate a staged curriculum, with each genre kept in a separate project folder:

1. Simple 2D arcade/puzzle game to prove project creation, scene wiring, UI and state.
2. 3D three-lane endless runner with swipe/keyboard controls, hazards, collectibles and game-over/restart.
3. Original sci-fi/gravity-shift runner to exercise more complex movement and world effects.
4. Arcade/waypoint racing with several vehicles, steering/braking, collisions, lap/finish logic and rankings.
5. Highway traffic-dodging racer with traffic spawning, boost/braking and scoring.
6. Third-person arena prototype with player movement, target/bot behaviour, hit logic and round results.
7. One additional genre selected from current research, such as platforming, board simulation or a small co-op-style prototype, only when suitable services and test tooling exist.

This is an internal qualification curriculum, not a promise that one run can ship all of these games at studio quality. Use the same reproducible gates for each project. Do not move to the next complex stage until required automated tests, project import, meaningful gameplay checks, security scans and artifact checks pass.

A 0-100 QA score can be reported only when its rubric and evidence are stored. Target >90/100 as the PDF proposes, but critical failures (crashes, unwinnable gameplay, missing required scenes/assets, failed import/build, serious security/licensing issue) must block release regardless of the numeric score.

## 5. Research that keeps improving

The factory needs a small, independent **Live Research Watch** that checks public, current information without consuming the scarce final-review Gemini quota. It should run weekly and on manual request and record timestamps and source URLs for:

- Official Godot stable release information.
- Public GitHub repositories and changes related to Godot tools, MCP servers, AI agents and game QA.
- Public Hugging Face model/repository metadata relevant to Godot, multimodal QA and game development.
- Official Android/Google Play, Apple, GitHub Actions and Hugging Face docs when relevant.

The watcher records facts and candidate tools. It does not auto-install an arbitrary plugin or assume public code/assets are licensed for commercial use. It keeps a machine-readable JSON result and a short Markdown summary under `research/`, and it does not call Gemini.

Per-game research may additionally examine public gameplay videos/reviews and store feedback when the task needs it. Extract reusable, original technical findings rather than copying another game's assets, UI, maps or expressive content. Every imported asset/model/dataset must have its license/source recorded. Public availability is not proof of permission to use or train on it.

## 6. Model and quota policy

### NVIDIA NIM
- Use NVIDIA NIM as the primary coding/reasoning provider when the configured model is available and suitable.
- The PDF specifies a 40-request-per-minute target. Use an internal ceiling of **35 requests/minute** with serialized requests and backoff for transient failures, leaving safety headroom. Never rotate or evade provider quota restrictions.
- Keep the model name configurable. Before use, verify that the selected model remains available for the user's account and endpoint.

### Gemini final gameplay video/audio review only
The supplied Google AI Studio quota screenshot was reviewed on 2026-10-11. It showed the user's account at **20 requests/day per model** for the Gemini 3.8 Flash, 3.7 Flash and 3.6 Flash entries (and 5 RPM for those displayed entries). Limits can change; re-check the user's live AI Studio page before relying on them.

Policy:
- Do not use Gemini during background research, routine coding, planning, repeated bug-fix loops or regular factory maintenance.
- First run deterministic Godot import/smoke tests and a real, project-specific automated playthrough. Capture gameplay video with synchronized audio. If the playthrough or capture fails, do not spend Gemini quota.
- After a successful playthrough, submit the same short final gameplay video/audio to the configured Gemini models **one model at a time**, at most one review request per model in that final QA run. No automatic retry on quota/auth/model errors. Persist each success or failure in the report.
- Models are reviewers, not players. A project-specific Godot autoplayer/test harness must play through the actual game. Video review complements, but does not replace, deterministic tests or real-device testing.
- Record the video hash, runtime duration, model ID, review time, findings and evidence. A review response is not a guarantee of perfection.

## 7. Changes now installed in this repository

- The previous scheduled Gemini video-research workflow has been paused. The SuperAgent evolution workflow is manual-only and does not receive Gemini credentials. The regular game-factory workflow also no longer receives the Gemini key, and the general model router excludes Gemini; the dedicated final-review script is the only new workflow path that uses it.
- `research/watch_official_sources.py` and `.github/workflows/live-research-watch.yml` provide a weekly/manual public-source metadata watch without LLM calls.
- `research/final_gameplay_qa.py` and `.github/workflows/final-gameplay-qa.yml` implement final-only video/audio review after deterministic checks and a project-specific Godot autoplay script succeed. The workflow reserves no more than 18 requests per model per rolling 24 hours in a private Hugging Face ledger and performs no model retries.
- The private archive helper checks that the Hugging Face destination is private before uploading allowlisted video/report artifacts.

These files have been committed, but the workflows have **not yet been executed end to end**. A project-specific `projects/GME-2026-0003/godot/tests/qa_playthrough.gd` has now been added for Turbo Rush. It navigates the real UI, starts a race, simulates steering/boost input, and requires a completed results state. It has not yet been proven to pass a real CI run. Final Gemini QA must remain blocked until this test and the video/audio capture succeed.

## 8. CPU runner, duration and checkpoints

Use headless Godot for import/script checks. Use a virtual display and software rendering only for appropriate screenshot/video checks; CPU-based 3D rendering may be slow, so benchmark it rather than promising a fixed frame rate. Use a virtual audio sink for recorded game audio where supported.

Split long work into bounded sessions, checkpoint the repository and durable state, and resume from verified state. GitHub Actions jobs have execution limits and free-usage quotas; this architecture does not assume an unlimited server. Keep source/configuration in Git, short reports as files, and large media/model outputs in an external private store when needed.

## 9. Private Hugging Face storage

Use a private Hugging Face Hub dataset repository for large QA recordings, packaged builds, verified datasets and non-secret reports only when the user has configured it. Use `HF_TOKEN` as a GitHub Actions Secret and `HF_PRIVATE_REPO_ID` as a repository variable or secret if preferred. Never add an access token to Git, workflow logs, reports or generated game source. Do not publish private assets without the user's explicit choice.

The user's estimate of 40-50 GB should be checked against the account's current storage/quota page before bulk upload. This report does not guarantee that amount of storage for every account or that all artifacts are stored by GitHub.

## 10. Security and license boundaries

- Secrets only in GitHub Actions Secrets; no tokens in public files, commits, game resources or logs.
- Use least-privilege repository permissions. Never expose a general-purpose credential to untrusted generated code or pull requests.
- Treat external MCP servers, plugins and generated shell commands as untrusted until version, source, license and permissions are reviewed.
- Record third-party asset/model license, source and required attribution before use.
- Security, failed builds, missing legal/compliance evidence, or failed required gameplay tests block a release. Do not claim store approval.

## 11. Current repository readiness (honest status)

The repository already contains a persistent project registry, a Godot AI SuperAgent foundation, a Godot knowledge base, factory modules, a factory contract, research scripts and build/security workflow foundations. The current README itself identifies runtime screenshots, input simulation, profiler/log ingestion, visual regression and broader tool coverage as next expansions.

This means the repository is a meaningful foundation, **not proof that the full two-phase studio-grade Game Factory has already passed end-to-end acceptance**. In particular, each genre still needs an effective project-specific autoplayer and evidence-based runtime QA; video capture must be verified; Android signing/store requirements may need user-provided configuration. A green code/static scan alone is not a complete gameplay test.

## 12. Acceptance definition

Call the factory operational only after it can, without manually editing generated project code:

1. accept one idea and create/resolve a project ID;
2. produce a documented game plan and license manifest;
3. generate a runnable Godot project;
4. pass engine import and static/security checks;
5. run a meaningful automated playthrough with recorded success criteria;
6. capture readable gameplay video and audio when this is supported;
7. detect a seeded/test failure, make a bounded repair and show the re-test result;
8. produce a non-secret QA report, source archive and available build artifacts;
9. resume safely after a job/session ends; and
10. demonstrate the same pipeline on the staged curriculum instead of only one hand-written demo.

Until each item has a run log or file evidence, its status must be marked pending or blocked, not complete.
