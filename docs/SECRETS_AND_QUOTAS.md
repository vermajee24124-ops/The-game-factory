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


## New two-phase builder + permanent factory workflow

These are the three credentials for the new manual workflows:

| Name | GitHub setting | Required for | Exactly how it is used |
|---|---|---|---|
| `NVIDIA_BUILDER_KEY` | **Repository secret** | Phase 1 only | Construction meta-agent reads the committed PDF text extract, summarizes the requirements, creates `game_factory/`, seven planning specs, and an original demo. This key is scoped to the builder step and is never passed to the permanent game runtime. |
| `NVIDIA_FACTORY_KEY` | **Repository secret** | Phase 2 | Permanent factory's research, coding and repair phases. It is not passed to screenshot/video QA steps or the commit step. |
| `GEMINI_API_KEY` | **Repository secret** | Phase 2 visual/audio QA only | Used only after deterministic Godot checks and valid screenshot/video/audio capture succeed. It must not be used for general research, code generation, or repair. |

Optional configuration (these are **repository variables**, not secrets):
- `NVIDIA_BASE_URL`: normally leave unset; default is `https://integrate.api.nvidia.com/v1`.
- `NVIDIA_BUILDER_MODEL`: optional exact native NVIDIA NIM model ID if automatic model discovery does not find a working one.
- `NVIDIA_FACTORY_MODEL`: optional exact model ID for permanent factory coding.
- `GEMINI_SCREENSHOT_MODEL`: optional image-capable model override. Default policy is to try the PDF's Gemma image-review model only if the API currently exposes it.
- `GEMINI_VIDEO_MODEL`: optional video/audio model override. PDF baseline is `gemini-3.1-flash-lite`; model availability and accepted thinking settings must be checked by the runtime.

Do not create placeholder values for missing secrets. Add the actual API keys directly in GitHub. Never paste them into ChatGPT or commit them to a file. The Actions-provided `GITHUB_TOKEN` is automatic; do not create a user-generated PAT for these workflows.

### Running the two phases
1. Open **Settings → Secrets and variables → Actions → New repository secret** and add `NVIDIA_BUILDER_KEY`, `NVIDIA_FACTORY_KEY`, and `GEMINI_API_KEY` (case-sensitive).
2. Open **Actions → Phase 1 - Build Autonomous Godot Game Factory → Run workflow**. Use the default original demo idea for the first run. Leave `rebuild_generated_files` off initially.
3. Only after Phase 1 has saved a factory CLI, state manager, demo project and validation evidence, open **Actions → Phase 2 - Autonomous Game Factory Relay → Run workflow**, enter your game idea, and leave `auto_continue` enabled if you want bounded continuation.
4. Review the workflow's report/artifacts and the saved `game_factory/runs/<idea-id>/factory_state.json`. A workflow can fail or stop with a resumable checkpoint; a saved file or model response is not proof that the game passed.

### Important safety and runtime boundaries
- Phase 1 and Phase 2 are manual entry points; Phase 2's automatic handoff is bounded by `max_continuations` (default 16). It will not provide an unlimited background worker and may stop because of quota, runtime, permission, or test failures.
- The construction workflow runs on GitHub's hosted CPU runner; Godot headless mode validates scripts/scenes, while Xvfb/Mesa and FFmpeg are required for actual visual/gameplay capture. Audio QA must not proceed on a silent or missing audio stream.
- Before each Phase 2 Gemini call, `factory_builder/gemini_quota_guard.py` reserves one request in the committed non-secret `game_factory/gemini_usage_ledger.json`. The safe default is **8 reservations per exact model per rolling 24 hours**. Reservations are not refunded after failed API calls, which avoids accidental retries. Phase 2 and the older final-gameplay QA workflow share a concurrency group, so their Gemini work is serialized.
- An image/video model only provides review evidence. It does not certify that a game is bug-free or store-compliant. Android AAB creation requires a working Godot export preset, templates, JDK/SDK, signing and a passing export test.
- The repository currently has **public** visibility. Any committed game source, screenshot, logs, or gameplay media under `games/` and `deliverables/` can be publicly visible; do not use it to store confidential unreleased material unless repository visibility and artifact handling are made private first.
- The uploaded PDF's extracted text has been added at `docs/reference/AI_AGENT_GODOT_GAME_STUDIO_PDF_EXTRACT.md` with the implementation contract at `docs/GODOT_GAME_STUDIO_BLUEPRINT.md`. The repository contains the text extract, not the original PDF binary or its page-layout screenshots.
