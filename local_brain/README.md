# Local SmolLM2 Micro-Brain

Selected model: `HuggingFaceTB/SmolLM2-360M-Instruct`.

Role: very small, fast CPU assistant for repetitive Godot micro-actions. It is not the main reasoning model.

Local responsibilities:
- intent classification
- tool selection
- compact action JSON
- small file and scene organization
- repeated editor operations
- escalation decisions

Remote responsibilities: image/video understanding, complex debugging, long code generation, large architectural decisions, and image-to-3D reconstruction.

Training strategy: LoRA/SFT on verified Godot micro-task data, research-derived procedures, tool schemas, and regression examples. The model itself is not pretrained from scratch.

The runtime target is a sub-500 MB GGUF. Do not commit the model binary to Git.
