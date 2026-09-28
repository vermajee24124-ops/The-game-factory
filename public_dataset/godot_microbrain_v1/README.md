# Public Godot 4.7.2 Micro-Brain Training Dataset

6,000-example master JSONL corpus for the local Godot 4.7.2 micro-brain.
All 810 classes from the repository curriculum are represented.
All examples are intended for the final training fit.

## Assemble
cat dataset-0001.jsonl dataset-0002.jsonl dataset-0003.jsonl dataset-0004.jsonl dataset-0005.jsonl dataset-0006.jsonl dataset-0007.jsonl dataset-0008.jsonl dataset-0009.jsonl dataset-0010.jsonl dataset-0011.jsonl dataset-0012.jsonl > train_all.jsonl

Train on all 6,000 examples. The old 90/10 split is not used for the final fit.

Model: HuggingFaceTB/SmolLM2-135M-Instruct
Method: LoRA SFT
Preferred GPU: NVIDIA Tesla T4
Use FP16 and keep BF16 disabled on T4.
