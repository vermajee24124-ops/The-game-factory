# Game Factory Live Research Watch

- Retrieved at (UTC): 2026-11-08T11:54:22.329674+00:00
- Uses public metadata endpoints only; no LLM/Gemini quota is consumed by this watcher.
- A result is a candidate for human/agent review, not automatic approval to install or ship it.

## Godot stable releases

Source: https://api.github.com/repos/godotengine/godot/releases?per_page=10
Status: **ok**

- [3.6.3-stable](https://github.com/godotengine/godot/releases/tag/3.6.3-stable) | 3.6.3-stable | published: 2026-08-22T14:05:19Z
- [4.7.2-stable](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) | 4.7.2-stable | published: 2026-08-18T16:12:28Z
- [4.7.1-stable](https://github.com/godotengine/godot/releases/tag/4.7.1-stable) | 4.7.1-stable | published: 2026-07-14T18:03:10Z
- [4.7-stable](https://github.com/godotengine/godot/releases/tag/4.7-stable) | 4.7-stable | published: 2026-06-18T12:06:17Z
- [4.6.3-stable](https://github.com/godotengine/godot/releases/tag/4.6.3-stable) | 4.6.3-stable | published: 2026-05-20T20:49:16Z

## GitHub Godot AI/MCP repositories

Source: https://api.github.com/search/repositories?q=Godot%20MCP%20AI%20agent&sort=updated&per_page=8
Status: **ok**

- [RizgarOzan/playcal](https://github.com/RizgarOzan/playcal) | updated: 2026-11-08T10:25:29Z | stars: 0 | license: Apache-2.0
  - An edit-settle-verify loop for AI agents working in Unity and Godot, plus flaky-vs-real playtests and bot-vs-human calibration.
- [laaielichter/Reverseport](https://github.com/laaielichter/Reverseport) | updated: 2026-11-08T10:15:05Z | stars: 18 | license: MIT
  - Reverse engineer anything. Port it anywhere. MCP server, CLI and Claude Code plugin for AI coding agents: read Godot .pck, Unity IL2CPP, .NET and native builds (via your own Ghidra, IDA or Hopper), compare builds, keep proof for every claim, and port games between Godot, Unity, Unreal and three.js with parity checks. Local, MIT.
- [genex-games/genex-desktop](https://github.com/genex-games/genex-desktop) | updated: 2026-11-08T08:49:51Z | stars: 810 | license: MIT
  - Desktop app for game dev with AI: make games in Unreal Engine, Unity, Godot or the browser. The agent sets up the engine, builds your game and play-tests it by itself.
- [swarvex-ai/swarvex](https://github.com/swarvex-ai/swarvex) | updated: 2026-11-08T07:21:12Z | stars: 0 | license: AGPL-3.0
  - The coordination layer for agent-built software – many AI agents build open-source software together, sandboxed and traceable.
- [hybridindie/godot-mcp](https://github.com/hybridindie/godot-mcp) | updated: 2026-11-08T07:44:07Z | stars: 54 | license: MIT
  - Combination of Godot Addon and MCP server for AI driven development — drive a live Godot editor from an AI agent
- [fennaraOfficial/fennara-godot-ai](https://github.com/fennaraOfficial/fennara-godot-ai) | updated: 2026-11-08T01:47:56Z | stars: 318 | license: MIT
  - AI chat and agent tooling for Godot, with both MCP support and in-built native chat window.
- [laaielichter/Agentdisk](https://github.com/laaielichter/Agentdisk) | updated: 2026-11-07T11:34:30Z | stars: 1 | license: MIT
  - Disk report and safe, reversible cleanup for AI coding agents: worktrees, checkpoints, node_modules, .godot. CLI + MCP server.
- [zhuyansen/awesome-3d-skills](https://github.com/zhuyansen/awesome-3d-skills) | updated: 2026-11-07T10:03:37Z | stars: 0 | license: NOASSERTION
  - MCP servers and skills that let AI agents work in 3D: Blender, Unity, Godot, Unreal, CAD, Three.js and 3D model generation. By type, each security-graded. English / 中文.

## Hugging Face Godot models

Source: https://huggingface.co/api/models?search=godot&limit=10&sort=lastModified&direction=-1
Status: **ok**

- [rbrasga/Godoter3.8-27B-GGUF](https://huggingface.co/rbrasga/Godoter3.8-27B-GGUF) | updated: 2026-10-22T17:32:19.000Z | task: image-text-to-text
- [rbrasga/Godoter3.8-27B](https://huggingface.co/rbrasga/Godoter3.8-27B) | updated: 2026-10-22T17:31:02.000Z | task: image-text-to-text
- [mradermacher/Godoter3.8-27B-i1-GGUF](https://huggingface.co/mradermacher/Godoter3.8-27B-i1-GGUF) | updated: 2026-10-21T11:59:08.000Z | task: not stated
- [mradermacher/Godoter3.8-27B-GGUF](https://huggingface.co/mradermacher/Godoter3.8-27B-GGUF) | updated: 2026-10-21T09:23:39.000Z | task: not stated
- [arunsrajan/qwen3.5-2b-godot-thinking-GGUF](https://huggingface.co/arunsrajan/qwen3.5-2b-godot-thinking-GGUF) | updated: 2026-10-11T11:14:03.000Z | task: not stated
- [arunsrajan/qwen3.5-2b-godot-thinking](https://huggingface.co/arunsrajan/qwen3.5-2b-godot-thinking) | updated: 2026-10-11T10:59:30.000Z | task: image-text-to-text
- [arunsrajan/qwen3.5-2b-godot-docs-GGUF](https://huggingface.co/arunsrajan/qwen3.5-2b-godot-docs-GGUF) | updated: 2026-10-11T08:45:38.000Z | task: not stated
- [arunsrajan/qwen3.5-2b-godot-docs](https://huggingface.co/arunsrajan/qwen3.5-2b-godot-docs) | updated: 2026-10-11T08:29:54.000Z | task: image-text-to-text
- [mradermacher/Godoter-27B-GGUF](https://huggingface.co/mradermacher/Godoter-27B-GGUF) | updated: 2026-10-07T19:33:35.000Z | task: not stated
- [Janstnkel/Godoter-27B](https://huggingface.co/Janstnkel/Godoter-27B) | updated: 2026-09-07T17:03:35.000Z | task: text-generation

## Review rules

- Confirm version compatibility with the pinned Godot version before use.
- Verify each source's license and dependency permissions before adding it.
- Do not upload private material or secrets to public locations.
- Public repository/model discovery does not prove commercial-use or training rights.
