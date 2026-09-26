# Godot AI SuperAgent v1

This layer turns the existing Game Factory into an in-editor, tool-using Godot agent.

Core loop:
User goal -> Supervisor plan -> tool calls -> Godot editor/runtime -> observations -> QA -> repair -> retest.

Model endpoint:
The runtime uses an OpenAI-compatible endpoint. FreeLLMAPI is the preferred gateway, but any compatible endpoint can be used.

Environment variables:
FREELLMAPI_BASE_URL
FREELLMAPI_API_KEY
FREELLMAPI_MODEL

Never commit credentials.

Evolution:
The CPU workflow prepares data, generates tool-use trajectories, evaluates schema compliance, and records regression reports. A GPU environment can later consume these trajectories for SFT/LoRA. CPU time is not presented as equivalent to GPU weight training.

Godot:
Keep addons/godot_ai_superagent inside a Godot 4.7.2 project and enable the plugin.
