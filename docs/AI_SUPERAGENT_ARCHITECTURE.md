# AI SuperAgent architecture

The target system is an autonomous Godot game-development agent, not a chat-only helper.

Execution loop:
inspect -> plan -> act -> observe -> verify -> repair -> retest -> remember

Godot layer:
EditorPlugin provides the in-editor surface. Tool Registry exposes scene, project, runtime and file actions. Permission Gate separates safe, write, destructive and export operations. Agent Loop performs bounded model/tool iterations.

Model layer:
The model client speaks the OpenAI-compatible chat-completions protocol. FreeLLMAPI can be used as the gateway, and a different compatible base URL can be substituted without changing the agent.

Knowledge layer:
Use the supplied Godot 4.7.2 knowledge base as a version-pinned reference. The build manifest hashes the file and records its headings and selected inventory claims.

Evolution layer:
1. Build knowledge manifest.
2. Validate code.
3. Generate synthetic tool-use trajectories through the configured model endpoint.
4. Measure strict tool-protocol compliance.
5. Store non-secret regression reports.
6. Feed successful trajectories into a later SFT/LoRA stage when a GPU runner is available.

Visual QA:
The next expansion should add screenshot capture, runtime input simulation, console ingestion, profiler snapshots, scene diffs and visual regression scoring. The agent should require evidence before declaring a build complete.

Training data policy:
Only use material whose license and terms permit the intended training or retrieval use. Preserve attribution/license metadata. Public reachability alone is not permission to ingest proprietary code or assets.
