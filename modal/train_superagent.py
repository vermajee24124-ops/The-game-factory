from __future__ import annotations

import json
import os
from pathlib import Path

import modal

app = modal.App("godot-ai-superagent-training")

TRAINING_VOLUME = modal.Volume.from_name("godot-superagent-training", create_if_missing=True)
OUTPUT_VOLUME = modal.Volume.from_name("godot-superagent-models", create_if_missing=True)

image = (
    modal.Image.debian_slim(python_version="3.11")
    .uv_pip_install(
        "accelerate==1.9.0",
        "datasets==3.6.0",
        "huggingface_hub==0.34.2",
        "peft==0.16.0",
        "transformers==4.54.0",
        "trl==0.19.1",
        "unsloth[cu128-torch270]==2025.7.8",
        "unsloth_zoo==2025.7.10",
    )
)

DATA_PATH = Path("/training/tool_use_trajectories.jsonl")
OUTPUT_PATH = Path("/models/superagent_lora")
BASE_MODEL_DEFAULT = os.getenv("SUPERAGENT_BASE_MODEL", "Qwen/Qwen3-8B")

@app.function(
    image=image,
    gpu="T4",
    timeout=5 * 60 * 60,
    volumes={"/training": TRAINING_VOLUME, "/models": OUTPUT_VOLUME},
)
def train(base_model: str = BASE_MODEL_DEFAULT, max_steps: int = 150, max_seq_length: int = 4096):
    import torch
    from datasets import Dataset
    from transformers import TrainingArguments
    from trl import SFTTrainer
    from unsloth import FastLanguageModel

    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Training data not found: {DATA_PATH}")

    rows = []
    for line in DATA_PATH.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        item = json.loads(line)
        assistant = item.get("raw") or json.dumps(item.get("response", {}), ensure_ascii=False)
        user = f"Task ID: {item.get('task_id')}\nDifficulty: {item.get('difficulty')}\nProduce the next correct Godot agent action."
        rows.append({
            "text": (
                "### System\nYou are a careful Godot 4.7.2 autonomous game engineer. "
                "Inspect before editing, use real APIs, verify changes, and never claim success without evidence.\n"
                f"### User\n{user}\n### Assistant\n{assistant}"
            )
        })

    if len(rows) < 2:
        raise RuntimeError("Need at least two training examples.")

    dataset = Dataset.from_list(rows)

    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=base_model,
        max_seq_length=max_seq_length,
        dtype=None,
        load_in_4bit=True,
    )

    model = FastLanguageModel.get_peft_model(
        model,
        r=16,
        target_modules=["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"],
        lora_alpha=16,
        lora_dropout=0.0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=42,
    )

    out = OUTPUT_PATH / base_model.replace("/", "--")
    out.mkdir(parents=True, exist_ok=True)

    args = TrainingArguments(
        per_device_train_batch_size=1,
        gradient_accumulation_steps=8,
        learning_rate=2e-4,
        max_steps=max_steps,
        warmup_ratio=0.05,
        logging_steps=1,
        save_steps=50,
        save_strategy="steps",
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        optim="adamw_8bit",
        output_dir=str(out),
        report_to="none",
        seed=42,
    )

    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=dataset,
        dataset_text_field="text",
        max_seq_length=max_seq_length,
        packing=True,
        args=args,
    )

    checkpoints = sorted(out.glob("checkpoint-*"))
    resume = str(checkpoints[-1]) if checkpoints else None
    trainer.train(resume_from_checkpoint=resume)

    final = out / "final_adapter"
    model.save_pretrained(final)
    tokenizer.save_pretrained(final)
    OUTPUT_VOLUME.commit()

    return {
        "status": "completed",
        "base_model": base_model,
        "examples": len(rows),
        "max_steps": max_steps,
        "output": str(final),
    }

@app.local_entrypoint()
def main(
    base_model: str = BASE_MODEL_DEFAULT,
    max_steps: int = 150,
):
    result = train.remote(base_model=base_model, max_steps=max_steps)
    print(json.dumps(result, indent=2))
