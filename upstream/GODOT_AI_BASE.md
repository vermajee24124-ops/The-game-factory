# Godot AI upstream base

This project evolves an existing open-source Godot AI agent instead of training an LLM.

Selected upstream:
- Repository: https://github.com/hi-godot/godot-ai
- License: MIT
- Baseline: v4.2.1
- Baseline source commit: bfc264200584ea5823f18356acb164781f57796d
- Godot compatibility: 4.7+ in the 4.x line
- Current upstream surface: 46 MCP tools / 120+ operations

Why this base:
It is a regular Godot add-on, so it can be downloaded into a normal project and evolved without compiling a custom Godot engine. It already exposes scene editing, scripts, signals, UI, materials, animation, particles, cameras and environments through MCP.

Policy:
Keep the upstream license and notices. Treat our changes as a separate evolution layer. Do not silently replace upstream source with an unrelated implementation.