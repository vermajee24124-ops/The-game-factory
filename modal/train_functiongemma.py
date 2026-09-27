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

@app.function(image=image, cpu=8, memory=16384, timeout=60*60*4, volumes={'/workspace': volume}, secrets=[hf_secret], env={'OMP_NUM_THREADS':'8','MKL_NUM_THREADS':'8','TOKENIZERS_PARALLELISM':'false'})
def train(train_path: str = '', eval_path: str = '', output_repo: str = ''):
    import json
    import os
    from datasets import load_dataset
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import LoraConfig
    from trl import SFTConfig, SFTTrainer

    if train_path:
        volume.reload()
    processor = AutoTokenizer.from_pretrained(MODEL_ID)
    if processor.pad_token is None:
        processor.pad_token = processor.eos_token
    model = AutoModelForCausalLM.from_pretrained(MODEL_ID, dtype='auto', attn_implementation='eager')

    files = {'train': train_path or TRAIN_FILE, 'test': eval_path or EVAL_FILE}
    data = load_dataset('json', data_files=files)

    args = SFTConfig(
        output_dir=OUTPUT_DIR,
        max_length=512,
        packing=True,
        num_train_epochs=float(os.getenv('FUNCTIONGEMMA_EPOCHS','1')),
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        gradient_accumulation_steps=1,
        learning_rate=float(os.getenv('FUNCTIONGEMMA_LR','0.0001')),
        logging_steps=10,
        eval_strategy='epoch',
        save_strategy='epoch',
        save_total_limit=2,
        fp16=True,
        gradient_checkpointing=False,
        report_to='none',
    )

    trainer = SFTTrainer(
        model=model,
        args=args,
        train_dataset=data['train'],
        eval_dataset=data['test'],
        processing_class=processor,
        peft_config=LoraConfig(r=16, lora_alpha=32, lora_dropout=0.05, target_modules='all-linear', task_type='CAUSAL_LM'),
    )
    trainer.train()
    trainer.save_model(OUTPUT_DIR)
    processor.save_pretrained(OUTPUT_DIR)

    metrics = trainer.evaluate()
    Path(OUTPUT_DIR, 'training_metrics.json').write_text(json.dumps(metrics, indent=2), encoding='utf-8')
    volume.commit()

    if output_repo:
        trainer.push_to_hub(output_repo)
    return metrics

@app.local_entrypoint()
def main():
    # GitHub Actions uploads the dataset to the persistent Modal Volume before this call.
    print(train.remote())

