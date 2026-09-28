import os
from pathlib import Path

import modal

APP_NAME = "the-game-factory-smollm2-training"
MODEL_ID = os.getenv("MICROBRAIN_BASE_MODEL", "HuggingFaceTB/SmolLM2-135M-Instruct")
TRAIN_FILE = "/workspace/train.jsonl"
EVAL_FILE = "/workspace/eval.jsonl"
OUTPUT_DIR = "/workspace/smollm2-godot-microbrain"

# CUDA-enabled PyTorch is required. The previous run installed the CPU wheel,
# so merely attaching a GPU was not enough.
image = (
    modal.Image.from_registry(
        "nvidia/cuda:12.8.1-runtime-ubuntu22.04",
        add_python="3.11",
    )
    .pip_install(
        "torch",
        index_url="https://download.pytorch.org/whl/cu128",
    )
    .pip_install(
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
    gpu="T4",
    cpu=8,
    memory=16384,
    timeout=60 * 60,
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
        raise FileNotFoundError(
            "Training data was not uploaded to the game-factory-smollm2 Modal Volume."
        )

    # Hard guard: never silently fall back to CPU again.
    if not torch.cuda.is_available():
        raise RuntimeError(
            "CUDA is unavailable. Refusing to train on CPU. "
            "The micro-brain training requires the requested T4 GPU."
        )

    device_name = torch.cuda.get_device_name(0)
    total_vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
    print(f"Model: {MODEL_ID}")
    print("CUDA available: True")
    print(f"GPU: {device_name}")
    print(f"GPU memory: {total_vram_gb:.2f} GiB")

    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        MODEL_ID,
        torch_dtype=torch.float16,
        attn_implementation="sdpa",
    )

    data = load_dataset("json", data_files={"train": train_file, "test": eval_file})

    args = SFTConfig(
        output_dir=OUTPUT_DIR,
        dataset_text_field="text",
        max_length=384,
        packing=True,
        num_train_epochs=float(os.getenv("MICROBRAIN_EPOCHS", "1")),
        per_device_train_batch_size=64,
        per_device_eval_batch_size=64,
        gradient_accumulation_steps=1,
        learning_rate=float(os.getenv("MICROBRAIN_LR", "0.0001")),
        logging_steps=10,
        eval_strategy="epoch",
        save_strategy="epoch",
        save_total_limit=1,
        fp16=True,
        bf16=False,
        gradient_checkpointing=False,
        report_to="none",
        dataloader_num_workers=4,
        dataloader_pin_memory=True,
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
    Path(OUTPUT_DIR, "TRAINING_COMPLETE").write_text(
        "ok\nGPU=T4\n", encoding="utf-8"
    )
    volume.commit()

    return metrics


@app.local_entrypoint()
def main():
    print(train.remote())
