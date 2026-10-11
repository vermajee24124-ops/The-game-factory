# GitHub Actions Secrets and Quota Setup

Set these in the repository's **Settings -> Secrets and variables -> Actions**. Never paste real keys into chat, commit them to Git, place them in a public report, or print them in workflow logs.

## Required for the current manual factory workflows

| Name | Required? | Purpose |
|---|---|---|
| `NVIDIA_API_KEY` | Recommended for AI coding/reasoning steps | NVIDIA NIM API key. Keep the exact model configured in the workflow/provider adapter supported by your account. |
| `GEMINI_API_KEY` | Only for the manual **Final Gameplay QA** workflow | Reserved for the final recorded gameplay video + audio review. Do not expose it to ordinary research or coding jobs. |
| `HF_TOKEN` | Required for private final-QA archive | Dedicated Hugging Face write token used only by the private archive/quota-guard steps. Do not expose it to code-generation or runtime game code. |
| `HF_INFERENCE_TOKEN` | Optional | Separate read/inference-scoped Hugging Face token used by the model router. Do not use the archive write token for inference. |
| `FREELLMAPI_BASE_URL` | Optional, for manual SuperAgent evolution | OpenAI-compatible API base URL for the selected gateway. |
| `FREELLMAPI_API_KEY` | Optional, paired with the URL above | Gateway API key. |
| `FREELLMAPI_MODEL` | Optional, paired with the gateway | Exact model/routing name supported by the selected gateway. |

## Optional model routes

Only add these if you have a working account/endpoint for them and want the factory to use that route:

- `Z_AI_API_KEY`
- `NARAROUTER_API_KEY`
- `OMNIROUTE_API_KEY`

A secret being present does not prove a provider or model is available. Verify the endpoint and quota before running expensive jobs.

## Hugging Face private archive

Create a **private** Hugging Face dataset repository from your Hugging Face account, then add a GitHub repository variable (not a key) named:

- `HF_PRIVATE_REPO_ID` = `your-huggingface-username/your-private-dataset-name`

Then add `HF_TOKEN` as a secret with write permission for the private dataset. Keep a separate optional `HF_INFERENCE_TOKEN` for read/inference model calls. Do not send either token in a chat. Keep unpublished game assets, gameplay recordings and reports private. The archive helper must upload only explicitly approved artifact files and must never upload environment files, tokens, or unrelated repository source. Before final Gemini calls, the workflow runs a tiny temporary upload/delete test to confirm the private repository is writable. After review, the Gemini-hosted upload is deleted where the API permits it; the durable recording/report is retained in the private Hugging Face archive.

Hugging Face storage quotas vary by account and can change. Check the storage page in your account before depending on 40-50 GB.

## Gemini quota rule

The Google AI Studio screenshot provided for this project on 2026-10-11 showed 20 requests/day for each of the listed Gemini 3.8 Flash, 3.7 Flash and 3.6 Flash model entries, with a displayed 5 RPM per entry. Treat this as a dated snapshot, not a permanent quota guarantee.

Gemini is reserved for final gameplay review:
1. Run deterministic validation and the game's real automated playthrough first.
2. Capture a valid video with audio.
3. Only if that succeeds, call each selected Gemini model once, sequentially, to inspect the same recording.
4. Do not run Gemini research during the day, do not use it in routine code/fix loops, and do not blindly retry quota/model errors.

The player/autotest script plays the game; Gemini only reviews the recorded result. A video-review answer is not a guarantee that a game has no bugs.

Before sending reviews, the workflow reserves one request per selected model in a rolling-24-hour usage ledger stored in the private Hugging Face dataset. The workflow is globally serialized, and the guard caps reservations at 18 calls per model per rolling 24 hours, leaving two requests below the screenshot's 20-RPD figure. Reservations are not automatically refunded after failures, which favors avoiding accidental quota overruns over retries.

## NVIDIA quota rule

The PDF's planning figure is 40 requests/minute. The factory should use a conservative internal ceiling of 35 requests/minute, serial requests and bounded backoff. This does not increase or bypass the provider's limit.

## Verify setup without exposing secrets

After adding secrets, run a manual workflow and inspect only whether each credential is detected/configured. Never echo a value, print full headers, or dump environment variables into logs.
