# Post-Training Micro-Brain Export and Godot Integration Skill

Target: Game Factory / Godot 4.7.2.

The trained SmolLM2-135M micro-brain is a local action-selection component, not the main reasoning model.

Architecture:
User -> external reasoning model -> micro-brain for simple actions -> Godot AI/MCP tools -> verification -> visual/runtime QA.

Complex or uncertain tasks remain with the external reasoning model.

## Verified model source

Published model repository: `pocketagent98-ai/godot-microbrain-model`.

Verified repository facts:
- `TRAINING_COMPLETE` marker is present.
- Base model: `HuggingFaceTB/SmolLM2-135M-Instruct`.
- GPU: Tesla T4.
- Dataset count: 6000.
- Epochs: 10.
- LoRA: r=8, alpha=16, dropout=0.05.
- `adapter_config.json` and `adapter_model.safetensors` are present.
- Tokenizer files are present.
- The published repository is an adapter repository, not a merged standalone base model. The base model remains a separate dependency.

## Required export artifacts

Treat model export as complete only when these are available and verified:
- LoRA adapter directory
- tokenizer files
- `adapter_config.json`
- `adapter_model.safetensors` or equivalent
- training metadata
- evaluation metrics

The published model repository currently satisfies this artifact contract at repository level.

## Suggested project layout

`models/godot-microbrain/`
  adapter_config.json
  adapter_model.safetensors
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
  training_metrics.json
  base_model.txt
  MODEL_CARD.md
  manifest.json

Large binaries should use an artifact/model registry or Git LFS rather than ordinary Git history.

## Runtime boundary

The Godot editor plugin should not directly execute a Hugging Face transformer inside GDScript.

Use a local inference service/process as the model runtime boundary:
Godot Editor -> local microbrain inference service -> JSON action -> live Godot AI/MCP catalog -> validation -> execution -> verification.

The service should:
1. Load `HuggingFaceTB/SmolLM2-135M-Instruct`.
2. Load the published LoRA adapter.
3. Load the published tokenizer files.
4. Use the available local device for inference.
5. Apply the training developer instruction.
6. Require one JSON action.
7. Parse JSON strictly.
8. Validate the tool name against the live Godot AI catalog.
9. Validate arguments.
10. Escalate invalid, complex, or uncertain requests.
11. Execute only after validation.
12. Return verification evidence.

Never execute raw model text as code.

## Integration target

Do not replace the primary external reasoning model with the micro-brain.

Preferred routing:
- simple, repeated, low-risk Godot action -> micro-brain
- architecture, ambiguity, multimodal interpretation, unfamiliar task, or failed verification -> external reasoning model
- tool execution -> live Godot AI/MCP surface
- post-action -> verification plus visual/runtime QA

The repository currently contains a custom registry of 18 local tools, while the vendored Godot AI baseline exposes a much broader live MCP surface. The integration must therefore validate actions against the vendored/live catalog rather than treating the custom registry as complete.

## Current Godot AI baseline

The repository currently vendors `hi-godot/godot-ai` v4.2.1. Keep the tool catalog generated from the actual pinned version and update it when the pinned version changes.

## Evaluation

Measure:
- valid JSON rate
- known-tool selection accuracy
- argument validity
- escalation accuracy
- unknown-tool rejection
- latency
- consistency
- verification success rate

Do not enable automatic execution merely because training loss is low or the training marker exists. Run a held-out evaluation suite before promotion.

## Rollback

Keep the previous adapter available and make activation reversible. Model activation should be controlled by a manifest/configuration file so a known-good adapter can be restored without changing the Godot plugin itself.
