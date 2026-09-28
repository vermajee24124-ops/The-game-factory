import os
from pathlib import Path

import modal

APP_NAME = "the-game-factory-smollm2-training"
MODEL_ID = os.getenv("MICROBRAIN_BASE_MODEL", "HuggingFaceTB/SmolLM2-135M-Instruct")
TRAIN_FILE = "/workspace/train.jsonl"
EVAL_FILE = "/workspace/eval.jsonl"
OUTPUT_DIR = "/workspace/smollm2-godot-microbrain"

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "torch",
        "transformers>=5.17,<5.18",
        "datasets",
        "accelerate",
        "trl>=0.28",
        "sentencepiece",
        "protobuf",
        "safetensors",
        "huggingface_hub",
        "peft",
    )
)

volume = modal.Volume.from_name("game-factory-smollm2", create_if_missing=True)
hf_secret = modal.Secret.from_local_environ(["HF_TOKEN"])
app = modal.App(APP_NAME)


@app.function(
    image=image,
    cpu=4,
    memory=16384,
    gpu="T4",
    timeout=60 * 60 * 4,
    volumes={"/workspace": volume},
    secrets=[hf_secret],
    env={
        "OMP_NUM_THREADS": "8",
        "MKL_NUM_THREADS": "8",
        "TOKENIZERS_PARALLELISM": "false",
    },
)
def train(train_path: str = "", eval_path: str = ""):
    import json
    import torch
    from datasets import load_dataset
    from peft import LoraConfig
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from trl import SFTConfig, SFTTrainer

    volume.reload()

    train_file = train_path or TRAIN_FILE
    eval_file = eval_path or EVAL_FILE

    if not Path(train_file).exists() or not Path(eval_file).exists():
        raise FileNotFoundError("Training data was not uploaded to the game-factory-smollm2 Modal Volume.")

    print(f"Model: {MODEL_ID}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    if not torch.cuda.is_available():
        raise RuntimeError("T4 GPU was requested but CUDA is unavailable")

    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(MODEL_ID, dtype=torch.float16)

    data = load_dataset("json", data_files={"train": train_file, "test": eval_file})

    args = SFTConfig(
        output_dir=OUTPUT_DIR,
        dataset_text_field="text",
        max_length=384,
        packing=True,
        num_train_epochs=float(os.getenv("MICROBRAIN_EPOCHS", "1")),
        per_device_train_batch_size=16,
        per_device_eval_batch_size=16,
        gradient_accumulation_steps=1,
        learning_rate=float(os.getenv("MICROBRAIN_LR", "0.00015")),
        logging_steps=20,
        eval_strategy="epoch",
        save_strategy="epoch",
        save_total_limit=1,
        fp16=True,
        bf16=False,
        gradient_checkpointing=False,
        report_to="none",
        dataloader_num_workers=4,
        dataloader_pin_memory=False,
    )

    trainer = SFTTrainer(
        model=model,
        args=args,
        train_dataset=data["train"],
        eval_dataset=data["test"],
        processing_class=tokenizer,
        peft_config=LoraConfig(
            r=8,
            lora_alpha=16,
            lora_dropout=0.05,
            target_modules="all-linear",
            task_type="CAUSAL_LM",
        ),
    )

    trainer.train()
    trainer.save_model(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)

    metrics = trainer.evaluate()
    Path(OUTPUT_DIR, "training_metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )
    Path(OUTPUT_DIR, "base_model.txt").write_text(MODEL_ID, encoding="utf-8")
    Path(OUTPUT_DIR, "TRAINING_COMPLETE").write_text("ok\n", encoding="utf-8")
    volume.commit()

    return metrics


@app.local_entrypoint()
def main():
    print(train.remote())
