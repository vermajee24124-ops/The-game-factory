# Local FunctionGemma Micro-Brain

The selected local model is **Google FunctionGemma 270M Instruct**. A current GGUF Q4_K_M build is about **253 MB**, comfortably below the 500 MB target. FunctionGemma is explicitly designed for function calling and Google documents fine-tuning and model distillation for custom tool use.

## What it handles locally

- classify short user intent
- select the correct Godot tool
- create compact function-call arguments
- small scene/file organization actions
- repeated editor micro-operations
- route difficult work to the remote model

## What stays remote

Long code generation, difficult debugging, broad game design, multimodal image/video reasoning, and image-to-3D reconstruction remain on stronger external or GPU services.

The local model does **not** need to see the raw photo itself. The main agent sends the image to a vision-capable provider, turns the result into structured intent, and then the tiny model selects and calls the Godot tools.

## Training

The training pipeline builds a FunctionGemma-specific function-calling dataset from verified Godot tool schemas, existing agent tasks, learned research notes, and selected multimodal research summaries. The final model is fine-tuned with SFT and then evaluated on held-out tasks.

The repository never stores the large model binary. The trained model is published externally and the target device downloads the final GGUF.

## Runtime

Start a local llama.cpp OpenAI-compatible server and point:

`LOCAL_LLM_BASE_URL=http://127.0.0.1:8080/v1`

`LOCAL_LLM_MODEL=functiongemma-270m-it.Q4_K_M.gguf`

The agent treats this as the fast local lane and escalates to remote providers when confidence, complexity, multimodal input, or verification requirements exceed the local model's scope.
