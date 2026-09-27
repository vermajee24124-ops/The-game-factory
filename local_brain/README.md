# Local Micro-Brain

Default model: `HuggingFaceTB/SmolLM2-360M-Instruct-GGUF` using Q4_K_M.

The Q4_K_M GGUF is about 271 MB. It is intended as the fast local CPU lane, not as the main reasoning model. The agent uses it for frequent small operations such as intent classification, tool selection, short summaries, JSON/schema formatting, and deciding whether a task should be escalated to a stronger remote model.

Remote escalation remains the default for long code generation, difficult debugging, multimodal image/video reasoning, and image-to-3D reconstruction.

Runtime variables:
- `LOCAL_LLM_BASE_URL` = local llama.cpp OpenAI-compatible server, for example `http://127.0.0.1:8080/v1`
- `LOCAL_LLM_MODEL` = local model identifier

Do not commit the GGUF binary to the Git repository. Download it on the target machine or cache it in the build environment.

llama.cpp supports Android arm64-v8a builds and CPU feature detection, including Arm KleidiAI acceleration paths.

The local model is deliberately kept stateless at the weights level. The agent's project-specific learning is stored in skills, playbooks, tool schemas, benchmarks and memory so that the tiny model can stay small.
