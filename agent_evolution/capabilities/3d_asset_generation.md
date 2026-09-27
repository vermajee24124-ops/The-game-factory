# Advanced 3D Asset Capability

## Goal
The SuperAgent should accept natural-language asset requests and choose the appropriate Godot-native or external asset path.

## Supported paths

### 1. Native Godot procedural 3D
For requests such as creating a stylized 3D character, low-poly enemy, tree, rock, coin, crate, or simple prop, the agent uses Godot scene/node APIs and the 3D asset factory to create native MeshInstance3D nodes, materials, transforms, and collision nodes directly in the edited scene.

### 2. Image-to-3D reconstruction
For a supplied reference image, the target flow is:
1. Inspect the image and infer subject, camera, pose, materials, and target style.
2. Select a configured image-to-3D backend.
3. Generate a GLB or GLTF asset externally on GPU.
4. Import the generated asset into res://assets/generated/.
5. Wait for Godot import and instantiate the resulting scene.
6. Validate mesh count, material slots, bounds, scale, collision needs, and mobile performance.
7. Repair or regenerate when validation fails.

### 3. Game-ready character processing
For humanoids, the pipeline should additionally check skeleton structure, skinning, animation compatibility, collision shapes, LOD needs, texture sizes, and mobile draw cost before declaring the character ready.

## Production rule
Do not claim an image has been converted successfully until the generated asset is actually imported into Godot and passes scene and runtime validation.

## Current implementation
The Godot-side SuperAgent can already create a procedural 3D character and import a generated GLB. A full one-click photo-to-production-character path still requires a deployed GPU reconstruction service plus rigging, retargeting, LOD, collision, animation, and validation stages.

## Research backends
Open-source research options include Microsoft's TRELLIS family and Stability AI Stable Fast 3D. TRELLIS supports image-to-3D and GLB extraction. Check each model and submodule license before commercial distribution.
