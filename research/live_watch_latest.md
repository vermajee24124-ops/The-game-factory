# Game Factory Live Research Watch

- Retrieved at (UTC): 2026-11-01T11:48:27.735201+00:00
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

- [nexarioneo/godot-copilot](https://github.com/nexarioneo/godot-copilot) | updated: 2026-11-01T11:18:15Z | stars: 0 | license: MIT
  - AI agent chat dock for the Godot 4 editor: multi-provider (OpenAI-compatible + Anthropic), tool execution, subagents, MCP and an action(target) permission system. Early version, expect bugs.
- [seradotcom/semwright](https://github.com/seradotcom/semwright) | updated: 2026-11-01T07:40:35Z | stars: 7 | license: Apache-2.0
  - Open runtime for AI agents to use real software.
- [gua-project/gua](https://github.com/gua-project/gua) | updated: 2026-11-01T03:50:01Z | stars: 22 | license: MIT
  - Playwright-style UI testing for Godot & Unity. One semantic automation layer for tests, CI, and AI coding agents via MCP.
- [OREBRON/godot-mcp](https://github.com/OREBRON/godot-mcp) | updated: 2026-11-01T01:41:59Z | stars: 0 | license: not stated
  - MCP server that lets AI agents check scripts, run the game and edit scenes in a Godot 4 project
- [hybridindie/godot-mcp](https://github.com/hybridindie/godot-mcp) | updated: 2026-11-01T00:08:00Z | stars: 47 | license: MIT
  - Combination of Godot Addon and MCP server for AI driven development — drive a live Godot editor from an AI agent
- [bagidea/bagidea-office](https://github.com/bagidea/bagidea-office) | updated: 2026-10-31T19:36:50Z | stars: 260 | license: MIT
  - A living AI-agent office on your desktop wallpaper — Claude Code agents that walk, work, delegate, learn & hold meetings. Per-agent swappable models (Claude/GLM/DeepSeek/Qwen/Kimi/OpenAI/Gemini/Groq/Ollama…), workflows, plugins, voice & Telegram/Discord/LINE. Open source.
- [Deejmahal831/godot-ai-game-tester](https://github.com/Deejmahal831/godot-ai-game-tester) | updated: 2026-10-31T17:49:56Z | stars: 0 | license: MIT
  - MCP server that lets AI coding agents (Claude Code, Codex, Cursor) launch, play, screenshot, and inspect a Godot 4 game in a real window.
- [Kysafe/AI-Project-Bridge-for-Godot](https://github.com/Kysafe/AI-Project-Bridge-for-Godot) | updated: 2026-10-31T06:15:54Z | stars: 0 | license: MIT
  - AI assistant and local project tools for Godot: chat with multiple AI providers, inspect and edit project files, search documentation, and connect coding agents via MCP.

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
