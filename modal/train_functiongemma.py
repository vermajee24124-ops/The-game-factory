import os
from pathlib import Path

import modal

APP_NAME = 'the-game-factory-smollm2-training'
MODEL_ID = os.getenv('MICROBRAIN_BASE_MODEL', 'HuggingFaceTB/SmolLM2-360M-Instruct')
TRAIN_FILE = '/workspace/train.jsonl'
EVAL_FILE = '/workspace/eval.jsonl'
OUTPUT_DIR = '/workspace/smollm2-godot-microbrain'

image = (
    modal.Image.debian_slim(python_version='3.11')
    .pip_install(
        'torch', 'transformers>=5.17,<5.18', 'datasets', 'accelerate',
        'trl>=0.28', 'sentencepiece', 'protobuf', 'safetensors',
        'huggingface_hub', 'peft'
    )
)

# This MUST match the volume populated by GitHub Actions.
volume = modal.Volume.from_name('game-factory-smollm2', create_if_missing=True)
hf_secret = modal.Secret.from_local_environ(['HF_TOKEN'])
app = modal.App(APP_NAME)

@app.function(
    image=image,
    cpu=8,
    memory=16384,
    gpu='T4',
    timeout=60*60*2,
    volumes={'/workspace': volume},
    secrets=[hf_secret],
    env={'OMP_NUM_THREADS':'8','MKL_NUM_THREADS':'8','TOKENIZERS_PARALLELISM':'false'},
)
def train(train_path: str = '', eval_path: str = '', output_repo: str = ''):
    import json
    import os
    from datasets import load_dataset
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import LoraConfig
    from trl import SFTConfig, SFTTrainer

    # Force the container to see the newest snapshot uploaded by the workflow.
    volume.reload()

    train_file = train_path or TRAIN_FILE
    eval_file = eval_path or EVAL_FILE
    for required in (train_file, eval_file):
        if not Path(required).exists():
            raise FileNotFoundError(
                f'Missing training file {required}. '
                'GitHub Actions must upload it to the game-factory-smollm2 Modal Volume first.'
            )

    processor = AutoTokenizer.from_pretrained(MODEL_ID)
    if processor.pad_token is None:
        processor.pad_token = processor.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        MODEL_ID,
        dtype='auto',
        attn_implementation='eager',
    )

    import torch
    print(f'CUDA available: {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'GPU: {torch.cuda.get_device_name(0)}')
        print(f'GPU memory: {torch.cuda.get_device_properties(0).total_memory / (1024**3):.2f} GiB')

    data = load_dataset('json', data_files={'train': train_file, 'test': eval_file})

    args = SFTConfig(
        output_dir=OUTPUT_DIR,
        max_length=512,
        packing=True,
        num_train_epochs=float(os.getenv('MICROBRAIN_EPOCHS', '1')),
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        gradient_accumulation_steps=1,
        learning_rate=float(os.getenv('MICROBRAIN_LR', '0.0001')),
        logging_steps=10,
        eval_strategy='epoch',
        save_strategy='epoch',
        save_total_limit=2,
        fp16=True,
        bf16=False,
        gradient_checkpointing=False,
        report_to='none',
    )

    trainer = SFTTrainer(
        model=model,
        args=args,
        train_dataset=data['train'],
        eval_dataset=data['test'],
        processing_class=processor,
        peft_config=LoraConfig(
            r=16,
            lora_alpha=32,
            lora_dropout=0.05,
            target_modules='all-linear',
            task_type='CAUSAL_LM',
        ),
    )

    trainer.train()
    trainer.save_model(OUTPUT_DIR)
    processor.save_pretrained(OUTPUT_DIR)

    metrics = trainer.evaluate()
    Path(OUTPUT_DIR, 'training_metrics.json').write_text(
        json.dumps(metrics, indent=2),
        encoding='utf-8',
    )
    Path(OUTPUT_DIR, 'base_model.txt').write_text(MODEL_ID, encoding='utf-8')
    volume.commit()

    if output_repo:
        trainer.push_to_hub(output_repo)
    return metrics

@app.local_entrypoint()
def main():
    print(train.remote())
