import os
from pathlib import Path

import modal

APP_NAME = 'the-game-factory-functiongemma-training'
MODEL_ID = os.getenv('FUNCTIONGEMMA_BASE_MODEL', 'google/functiongemma-270m-it')
TRAIN_FILE = '/workspace/train.jsonl'
EVAL_FILE = '/workspace/eval.jsonl'
OUTPUT_DIR = '/workspace/functiongemma-godot'

image = (
    modal.Image.debian_slim(python_version='3.11')
    .pip_install(
        'torch', 'transformers>=5.17,<5.18', 'datasets', 'accelerate',
        'trl>=0.28', 'sentencepiece', 'protobuf', 'safetensors',
        'huggingface_hub', 'peft'
    )
)

volume = modal.Volume.from_name('game-factory-functiongemma', create_if_missing=True)
hf_secret = modal.Secret.from_local_environ(['HF_TOKEN'])
app = modal.App(APP_NAME)

@app.function(image=image, gpu='T4', timeout=60*60*4, volumes={'/workspace': volume}, secrets=[hf_secret])
def train(train_path: str = '', eval_path: str = '', output_repo: str = ''):
    import json
    import os
    from datasets import load_dataset
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from trl import SFTConfig, SFTTrainer

    if train_path:
        volume.reload()
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    model = AutoModelForCausalLM.from_pretrained(MODEL_ID, dtype='auto', attn_implementation='eager')

    files = {'train': train_path or TRAIN_FILE, 'test': eval_path or EVAL_FILE}
    data = load_dataset('json', data_files=files)

    args = SFTConfig(
        output_dir=OUTPUT_DIR,
        max_length=768,
        packing=False,
        num_train_epochs=float(os.getenv('FUNCTIONGEMMA_EPOCHS','3')),
        per_device_train_batch_size=4,
        per_device_eval_batch_size=4,
        gradient_accumulation_steps=4,
        learning_rate=float(os.getenv('FUNCTIONGEMMA_LR','5e-5')),
        logging_steps=10,
        eval_strategy='epoch',
        save_strategy='epoch',
        save_total_limit=2,
        bf16=False,
        fp16=True,
        report_to='none',
    )

    trainer = SFTTrainer(
        model=model,
        args=args,
        train_dataset=data['train'],
        eval_dataset=data['test'],
        processing_class=tokenizer,
    )
    trainer.train()
    trainer.save_model(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)

    metrics = trainer.evaluate()
    Path(OUTPUT_DIR, 'training_metrics.json').write_text(json.dumps(metrics, indent=2), encoding='utf-8')
    volume.commit()

    if output_repo:
        trainer.push_to_hub(output_repo)
    return metrics

@app.local_entrypoint()
def main():
    # GitHub Actions prepares and uploads the dataset to this persistent Modal Volume.
    print(train.remote())

