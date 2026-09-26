from __future__ import annotations

import json
import os
from pathlib import Path

import modal

app = modal.App("godot-ai-superagent-training")

TRAINING_VOLUME = modal.Volume.from_name(
    "godot-superagent-training", create_if_missing=True
)
MODEL_VOLUME = modal.Volume.from_name(
    "godot-superagent-models", create_if_missing=True
)

image = (
    modal.Image.debian_slim(python_version="3.11")
    .uv_pip_install(
        "accelerate",
        "datasets",
        "huggingface_hub",
        "peft",
        "transformers",
        "trl",
        "unsloth",
        "unsloth_zoo",
    )
)

DATA_PATH = Path("/training/tool_use_trajectories.jsonl")
OUTPUT_ROOT = Path("/models/superagent_lora")
DEFAULT_BASE_MODEL = os.getenv("SUPERAGENT_BASE_MODEL", "Qwen/Qwen3-8B-Base")


def read_rows() -> list[dict]:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Training data not found: {DATA_PATH}")
    rows = []
    for line in DATA_PATH.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    if len(rows) < 4:
        raise RuntimeError("Need at least four trajectory examples.")
    return rows


@app.function(
    image=image,
    gpu="T4",
    timeout=330 * 60,
    volumes={"/training": TRAINING_VOLUME, "/models": MODEL_VOLUME},
)
def train(
    base_model: str = DEFAULT_BASE_MODEL,
    max_steps: int = 150,
    max_seq_length: int = 4096,
):
    import torch
    from datasets import Dataset
    from transformers import set_seed
    from trl import SFTConfig, SFTTrainer
    from unsloth import FastLanguageModel

    set_seed(42)
    raw = read_rows()

    examples = []
    for item in raw:
        response = item.get("raw")
        if not response:
            response = json.dumps(item.get("response", {}), ensure_ascii=False)
        examples.append(
            {
                "text": (
                    "### System\n"
                    "You are a careful Godot 4.7.2 autonomous game engineer. "
                    "Inspect before editing, use real APIs, verify every mutation, "
                    "and never claim success without evidence.\n"
                    "### User\n"
                    f"Task ID: {item.get('task_id')}\n"
                    f"Difficulty: {item.get('difficulty')}\n"
                    "Produce the next correct Godot agent action.\n"
                    "### Assistant\n"
                    f"{response}"
                )
            }
        )

    split = Dataset.from_list(examples).train_test_split(test_size=0.1, seed=42)
    train_ds = split["train"]
    eval_ds = split["test"]

    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=base_model,
        max_seq_length=max_seq_length,
        load_in_4bit=True,
        dtype=None,
    )

    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = FastLanguageModel.get_peft_model(
        model,
        r=16,
        lora_alpha=16,
        lora_dropout=0.0,
        bias="none",
        target_modules=[
            "q_proj",
            "k_proj",
            "v_proj",
            "o_proj",
            "gate_proj",
            "up_proj",
            "down_proj",
        ],
        use_gradient_checkpointing="unsloth",
        random_state=42,
    )

    model_dir = OUTPUT_ROOT / base_model.replace("/", "--")
    model_dir.mkdir(parents=True, exist_ok=True)

    config = SFTConfig(
        output_dir=str(model_dir),
        dataset_text_field="text",
        max_length=max_seq_length,
        packing=True,
        per_device_train_batch_size=1,
        per_device_eval_batch_size=1,
        gradient_accumulation_steps=8,
        learning_rate=2e-4,
        max_steps=max_steps,
        warmup_ratio=0.05,
        logging_steps=1,
        eval_strategy="steps",
        eval_steps=25,
        save_strategy="steps",
        save_steps=25,
        save_total_limit=3,
        gradient_checkpointing=True,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        optim="adamw_8bit",
        report_to=[],
        seed=42,
    )

    trainer = SFTTrainer(
        model=model,
        args=config,
        train_dataset=train_ds,
        eval_dataset=eval_ds,
        processing_class=tokenizer,
    )

    checkpoints = sorted(model_dir.glob("checkpoint-*"))
    resume = str(checkpoints[-1]) if checkpoints else None
    trainer.train(resume_from_checkpoint=resume)
    metrics = trainer.evaluate()

    adapter_dir = model_dir / "final_adapter"
    model.save_pretrained(adapter_dir)
    tokenizer.save_pretrained(adapter_dir)
    MODEL_VOLUME.commit()

    result = {
        "status": "completed",
        "base_model": base_model,
        "total_examples": len(examples),
        "train_examples": len(train_ds),
        "eval_examples": len(eval_ds),
        "max_steps": max_steps,
        "eval_metrics": metrics,
        "adapter": str(adapter_dir),
    }
    (model_dir / "training_result.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    MODEL_VOLUME.commit()
    return result


@app.local_entrypoint()
def main(
    base_model: str = DEFAULT_BASE_MODEL,
    max_steps: int = 150,
):
    result = train.remote(base_model=base_model, max_steps=max_steps)
    print(json.dumps(result, indent=2, ensure_ascii=False))
