# Post-Training Micro-Brain Export and Godot Integration Skill

Target: Game Factory / Godot 4.7.2.

The trained SmolLM2-135M micro-brain is a local action-selection component, not the main reasoning model.

Architecture:
User -> external reasoning model -> micro-brain for simple actions -> Godot AI/MCP tools -> verification -> visual/runtime QA.

Complex or uncertain tasks remain with the external reasoning model.

## Required export artifacts
- LoRA adapter directory
- tokenizer files
- adapter_config.json
- adapter_model.safetensors (or equivalent)
- training metadata
- evaluation metrics

Never claim export complete until these files exist.

## Suggested layout
models/godot-microbrain/
  adapter_config.json
  adapter_model.safetensors
  tokenizer.json
  tokenizer_config.json
  special_tokens_map.json
  training_metrics.json
  base_model.txt
  MODEL_CARD.md

Large binaries should use an artifact/model registry or Git LFS rather than ordinary Git history.

## Runtime
1. Load HuggingFaceTB/SmolLM2-135M-Instruct.
2. Load the LoRA adapter.
3. Put inference on the available local device.
4. Apply the training developer instruction.
5. Require one JSON action.
6. Parse JSON strictly.
7. Validate tool name against the live Godot tool catalog.
8. Validate arguments.
9. Escalate invalid/complex/uncertain requests.
10. Execute only after validation.
11. Verify execution result.

Never execute raw model text as code.

## Evaluation
Measure valid JSON rate, known-tool selection accuracy, argument validity, escalation accuracy, unknown-tool rejection, latency, and consistency before automatic execution.

## Rollback
Keep the previous adapter available and make activation reversible.
