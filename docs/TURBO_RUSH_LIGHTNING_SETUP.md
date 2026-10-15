# Turbo Rush Asset Factory — Lightning AI Studio Setup

This guide is for the prepared notebook **Turbo_Rush_Lightning_L4_Asset_Factory.ipynb** attached in the ChatGPT conversation. This repository guide does not contain any credentials.

## 1. Create/open a Studio

1. Open Lightning AI in your mobile or desktop browser and sign in.
2. Create a Studio or open an existing one.
3. Select an L4 instance only if it is actually available to your account. Check the instance panel after launch; do not assume an L4 was allocated just because it was requested.
4. Upload/import the notebook from the ChatGPT attachment into the Studio workspace.

## 2. Configure secrets safely

In the Studio's secret/environment settings, create:

- `HF_TOKEN`: a Hugging Face token with permission to create/write the intended private dataset.

Do not paste the token into a code cell, public GitHub file, notebook output, issue, or chat. If you have already exposed a token, revoke it and create a new one.

Optional environment variable:

- `GODOT_PROJECT_PATH`: path to a Godot project directory that already exists inside the same Studio filesystem. Leave unset if the project is not present there.

The notebook uses a private Hugging Face dataset for asset storage. Confirm the dataset owner/account and visibility before uploading. A token is not proof that the dataset was successfully created.

## 3. Run a small smoke test first

1. Run the notebook's setup cell.
2. If Blender installation fails because package installation is blocked, install Blender using a supported package/runtime method in the Studio, then rerun.
3. Keep `MAX_ASSETS_THIS_RUN = 30` for the first test.
4. Confirm that GLB files and metadata exist locally, QA results are recorded, and the Hugging Face upload succeeds.
5. Open at least one car, one wheel and one track GLB in Godot or another glTF viewer. Inspect orientation, scale, materials and geometry.

## 4. Scale gradually

Only after the smoke test passes, increase the per-run limit in controlled steps. Do not immediately start a 1,500-asset run. Monitor storage, runtime, GPU credits, RAM, failed assets and upload errors. Preserve the manifest/checkpoint between runs.

The current generator creates procedural blockout/prototype assets. It is not a substitute for production art direction, high-quality textures, collision validation, mobile performance testing or gameplay testing.

## 5. Godot import

If `GODOT_PROJECT_PATH` is configured correctly, the notebook can copy generated files into the project's `assets/generated/` folders. Open the project in Godot 4.x and allow the editor to import the GLBs. Then test each asset in a scene. The notebook does not automatically prove that assets are playable or correctly integrated into Turbo Rush.

## Troubleshooting

- **L4 not listed:** use an available instance or wait for quota/availability; do not claim L4 execution.
- **Blender install denied:** use the Studio-supported installation method and confirm `blender --version`.
- **HF upload fails:** verify the secret name is exactly `HF_TOKEN`, token write permissions, dataset ID and network access. Never print the token to debug.
- **Notebook restarts:** inspect the local manifest and generated output before restarting; keep the output directory persistent.
- **GLB passes header check but looks broken:** the current QA is only structural. Inspect it in a viewer and Godot.
