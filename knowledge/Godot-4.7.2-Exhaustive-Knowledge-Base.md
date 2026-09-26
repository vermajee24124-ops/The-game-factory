# Godot Engine 4.7.2 — EXHAUSTIVE TECHNICAL KNOWLEDGE BASE

> **Version identity (source-verified):** यह document Godot के **official source code tag `4.7.2-stable`** (commit `ed1daf0bf001b61586d9930840f2f1394092c079`) से extract किया गया है — `version.py` में `major=4, minor=7, patch=2, status="stable"` confirm होता है। Release date: **18 August 2026** (maintenance release; 4.7 feature release: 18 June 2026)।
> **Sources (priority order):** Godot source code (doc/classes/*.xml — official class reference), official release notes, official documentation (docs.godotengine.org), official changelog। Community sources सिर्फ़ Section 20 (ecosystem) में हैं और clearly labeled हैं।
> **Language note:** विवरण हिंदी में, सारे technical names/identifiers exact English में — ताकि copy-paste करके docs में ढूँढा जा सके।

---

## 0. Executive Summary — hard numbers (source-extracted)

| Inventory | Count (verified from 4.7.2 source) |
|---|---|
| Documented built-in classes (doc/classes/*.xml) | **810** |
| — Node types (Node से derive) | **260** |
| — Resource types (Resource से derive) | **259** |
| — Other classes (servers, singletons, utilities, editors…) | **291** |
| Total properties/members in class reference | **5,534** |
| Total methods | **9,896** |
| Total signals | **451** |
| Total constants/enums values | **5,229** |
| Theme items | **635** |
| @GlobalScope constants | **528** (+41 properties) |
| Engine modules (config.py वाले) | **57** |
| Bundled third-party libraries (thirdparty/) | **67** |
| Project settings with engine-registered defaults (GLOBAL_DEF) | **230** in 17 categories |
| Editor settings keys | **171** |
| Command-line options | **104** |
| SCons build options | **156** |
| Importers (editor/import) | **19** |
| Resource format loaders/savers | **10** |
| GDScript annotations | **36** |
| Platforms with export plugins | 8 (Windows, Linux, macOS, Android, iOS, Web, visionOS + Web test server) |

**पूरा class reference (9,896 methods का पूरा text) इस document में physically embed नहीं हो सकता** — Godot का अपना class reference ही उसका official form है। इसकी जगह यहाँ: (a) सभी 810 classes की full table (Section 4), (b) हर class के members/methods/signals की exact counts, (c) machine-readable पूरी API निकालने का official तरीका:

```bash
# Poora machine-readable API dump (official tarika):
godot --headless --dump-extension-api            # extension_api.json (saare classes/methods/properties)
godot --headless --dump-extension-api-with-docs  # docs ke saath
# Ya XML source dekho: doc/classes/<Class>.xml (is document ka bhi source)
```

---

## 1. Architecture — source tree (4.7.2)

Top-level directories और उनका काम (हर directory की full listing neeche relevant sections में):

| Directory | क्या है |
|---|---|
| `core/` | Engine core — Object system, Variant types, math (Vector2/3/4, Quaternion, AABB…), io, config, templates, crypto, String, OS abstraction (29 subdirectories) |
| `servers/` | Engine servers — RenderingServer, PhysicsServer2D/3D, AudioServer, DisplayServer, NavigationServer2D/3D, TextServer, CameraServer, XRServer (17 entries) |
| `scene/` | Scene system — nodes (2d, 3d, gui, audio, animation, main, resources), resources, registration |
| `editor/` | पूरा editor (Section 9 में detail) |
| `modules/` | 57 modules (Section 13) |
| `platform/` | Platform ports: SCsub, android, ios, linuxbsd, macos, platform_builders.py, register_platform_apis.h, visionos, web, windows |
| `thirdparty/` | Bundled third-party libraries (Section 14) |
| `drivers/` | Low-level drivers — audio drivers, gles3, vulkan, metal rendering contexts |
| `main/` | main.cpp — startup, command-line parsing (Section 12) |
| `misc/`, `doc/`, `tests/`, `tools/` | helper scripts, class reference XML, unit tests |

**Rendering drivers (drivers/):** SCsub, accesskit, alsa, alsamidi, apple, apple_embedded, backtrace, coreaudio, coremidi, d3d12, egl, gl_context, gles3, metal, png, pulseaudio, register_driver_types.cpp, register_driver_types.h, sdl, unix, vulkan, wasapi, windows, winmidi, xaudio2 — Vulkan (Forward+/Mobile), OpenGL 3 (Compatibility), Metal (macOS) contexts यहीं से आते हैं।

---

## 2. Rendering pipelines

Godot 4.7.2 में 3 official rendering methods हैं (selection: Project Settings → `rendering/renderer/rendering_method`):

| Pipeline | Backend | Default | Key characteristics |
|---|---|---|---|
| **Forward+** (forward_plus) | Vulkan (Windows/Linux/Android), D3D12 (Windows, optional), Metal (macOS) | Desktop projects | Clustered forward rendering, compute-based occlusion culling, SDFGI, VoxelGI, SSR, volumetric fog, 2D HDR pipeline; 4.7 में **experimental Vulkan raytracing groundwork** भी |
| **Mobile** (mobile) | Vulkan, Metal | Mobile projects | Single-pass forward, hardcoded per-mesh light limits, GPU-efficient for mobile |
| **Compatibility** (gl_compatibility) | OpenGL 3.3 / WebGL 2 / OpenGL ES 3 | Web default | सबसे wide support; no compute; limited SDFGI (no); web export का default |

4.7-specific rendering additions (official release notes + source): HDR output (Windows/macOS/iOS/visionOS/Wayland), Vulkan subsampled images, `AreaLight3D` (rectangular light, नया node), PCSS shadow correctness fix (4.7.2), nearest-neighbor scaling for 3D viewports (`rendering/scaling_3d/mode` + `texture` filter), clearcoat improvements, Metal residency sets (Apple6+)। पूरा detail Section 19 (release changes) में।

---

## 3. Physics

**दो 3D physics engines built-in हैं:**
- `godot_physics_3d` — default; `physics/3d/physics_engine = "DEFAULT"`
- `jolt_physics` — Jolt integration; `physics/3d/physics_engine = "JOLT"` पर switch होता है (advanced features; 4.x में status के लिए Section 19 देखें)
- 2D: सिर्फ़ `godot_physics_2d` built-in है

**Physics node families (source-verified groups, Section 5 की table से):** PhysicsBody2D/3D और उनकी children (CharacterBody2D/3D, RigidBody2D/3D, StaticBody2D/3D, AnimatableBody2D/3D), CollisionObject2D/3D + Area2D/3D, CollisionShape2D/3D, CollisionPolygon2D/3D, joints — Joint2D family (5 types: DampedSpringJoint2D, DistanceJoint2D, GrooveJoint2D, PinJoint2D) और Joint3D family (DampedSpringJoint3D, DistanceJoint3D, ConeTwistJoint3D, Generic6DOFJoint3D, HingeJoint3D, PinJoint3D, SliderJoint3D), RayCast2D/3D, ShapeCast2D/3D, DirectSpaceState queries (PhysicsRayQueryParameters2D/3D…), physics interpolation, one-way collisions — `CollisionShape2D.one_way_collision` + नया `one_way_collision_direction` (4.7)।

---

## 4. POORI Class Reference — सभी 810 built-in classes

नीचे हर documented class है — inheritance, brief description, और exact counts (members/methods/signals/constants) — **सीधे `doc/classes/*.xml` से parsed**। हर class का पूरा detail (हर method के parameters, हर constant का value) class reference में है: https://docs.godotengine.org/en/stable/classes/ या `--dump-extension-api`।

# Godot 4.7.2 — ALL built-in classes (810)
nodes: 260 | resources: 259 | other: 291

| Class | Inherits | Brief | Members | Methods | Signals | Constants |
|---|---|---|---|---|---|---|
| @GlobalScope | — | Global scope constants and functions. | 41 | 114 | 0 | 528 |
| AABB | — | A 3D axis-aligned bounding box. | 3 | 25 | 0 | 0 |
| AESContext | RefCounted | Provides access to AES encryption/decryption of raw data. | 0 | 4 | 0 | 5 |
| AStar2D | RefCounted | An implementation of A* for finding the shortest path between two vertices on a connected graph in 2D space. | 1 | 26 | 0 | 0 |
| AStar3D | RefCounted | An implementation of A* for finding the shortest path between two vertices on a connected graph in 3D space. | 1 | 26 | 0 | 0 |
| AStarGrid2D | RefCounted | An implementation of A* for finding the shortest path between two points on a partial 2D grid. | 9 | 17 | 0 | 14 |
| AcceptDialog | Window | A base dialog used for user notification. | 13 | 6 | 3 | 0 |
| AccessibilityServer | Object | A server interface for screen reader support. | 0 | 75 | 0 | 96 |
| AimModifier3D | BoneConstraint3D | The [AimModifier3D] rotates a bone to look at a reference bone. | 1 | 10 | 0 | 0 |
| AnimatableBody2D | StaticBody2D | A 2D physics body that can't be moved by external forces. When moved manually, it affects other bodies in its  | 1 | 0 | 0 | 0 |
| AnimatableBody3D | StaticBody3D | A 3D physics body that can't be moved by external forces. When moved manually, it affects other bodies in its  | 1 | 0 | 0 | 0 |
| AnimatedSprite2D | Node2D | Sprite node that contains multiple textures as frames to play for animation. | 10 | 7 | 5 | 0 |
| AnimatedSprite3D | SpriteBase3D | 2D sprite node in 3D world, that can use multiple 2D textures for animation. | 6 | 7 | 5 | 0 |
| AnimatedTexture | Texture2D | Proxy texture for simple frame-based animations. | 6 | 4 | 0 | 1 |
| Animation | Resource | Holds data that can be used to animate anything in the engine. | 4 | 78 | 0 | 26 |
| AnimationLibrary | Resource | Container for [Animation] resources. | 0 | 7 | 4 | 0 |
| AnimationMixer | Node | Base class for [AnimationPlayer] and [AnimationTree]. | 10 | 21 | 7 | 8 |
| AnimationNode | Resource | Base class for [AnimationTree] nodes. Not related to scene nodes. | 1 | 23 | 4 | 4 |
| AnimationNodeAdd2 | AnimationNodeSync | Blends two animations additively inside of an [AnimationNodeBlendTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeAdd3 | AnimationNodeSync | Blends two of three animations additively inside of an [AnimationNodeBlendTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeAnimation | AnimationRootNode | An input animation for an [AnimationNodeBlendTree]. | 8 | 0 | 0 | 2 |
| AnimationNodeBlend2 | AnimationNodeSync | Blends two animations linearly inside of an [AnimationNodeBlendTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeBlend3 | AnimationNodeSync | Blends two of three animations linearly inside of an [AnimationNodeBlendTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeBlendSpace1D | AnimationRootNode | A set of [AnimationRootNode]s placed on a virtual axis, crossfading between the two adjacent ones. Used by [An | 8 | 11 | 0 | 7 |
| AnimationNodeBlendSpace2D | AnimationRootNode | A set of [AnimationRootNode]s placed on 2D coordinates, crossfading between the three adjacent ones. Used by [ | 10 | 15 | 1 | 7 |
| AnimationNodeBlendTree | AnimationRootNode | A sub-tree of many type [AnimationNode]s used for complex animations. Used by [AnimationTree]. | 1 | 10 | 1 | 6 |
| AnimationNodeExtension | AnimationNode | Base class for extending [AnimationRootNode]s from GDScript, C#, or C++. | 0 | 3 | 0 | 0 |
| AnimationNodeOneShot | AnimationNodeSync | Plays an animation once in an [AnimationNodeBlendTree]. | 10 | 0 | 0 | 6 |
| AnimationNodeOutput | AnimationNode | The animation output node of an [AnimationNodeBlendTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeStateMachine | AnimationRootNode | A state machine with multiple [AnimationRootNode]s, used by [AnimationTree]. | 3 | 20 | 0 | 3 |
| AnimationNodeStateMachinePlayback | Resource | Provides playback control for an [AnimationNodeStateMachine]. | 1 | 14 | 2 | 0 |
| AnimationNodeStateMachineTransition | Resource | A transition within an [AnimationNodeStateMachine] connecting two [AnimationRootNode]s. | 9 | 0 | 1 | 6 |
| AnimationNodeSub2 | AnimationNodeSync | Blends two animations subtractively inside of an [AnimationNodeBlendTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeSync | AnimationNode | Base class for [AnimationNode]s with multiple input ports that must be synchronized. | 1 | 0 | 0 | 0 |
| AnimationNodeTimeScale | AnimationNode | A time-scaling animation node used in [AnimationTree]. | 0 | 0 | 0 | 0 |
| AnimationNodeTimeSeek | AnimationNode | A time-seeking animation node used in [AnimationTree]. | 1 | 0 | 0 | 0 |
| AnimationNodeTransition | AnimationNodeSync | A transition within an [AnimationTree] connecting two [AnimationNode]s. | 4 | 6 | 0 | 0 |
| AnimationPlayer | AnimationMixer | A node used for animation playback. | 12 | 32 | 2 | 5 |
| AnimationRootNode | AnimationNode | Base class for [AnimationNode]s that hold one or multiple composite animations. Usually used for [member Anima | 0 | 0 | 0 | 0 |
| AnimationTree | AnimationMixer | A node used for advanced animation transitions in an [AnimationPlayer]. | 5 | 2 | 1 | 3 |
| Area2D | CollisionObject2D | A region of 2D space that detects other [CollisionObject2D]s entering or exiting it. | 15 | 6 | 8 | 5 |
| Area3D | CollisionObject3D | A region of 3D space that detects other [CollisionObject3D]s entering or exiting it. | 22 | 6 | 8 | 5 |
| AreaLight3D | Light3D | An area light, such as a neon light tube or a screen. | 7 | 0 | 0 | 0 |
| Array | — | A built-in data structure that holds a sequence of elements. | 0 | 51 | 0 | 0 |
| ArrayMesh | Mesh | [Mesh] type that provides utility for constructing a surface from arrays. | 3 | 20 | 0 | 0 |
| ArrayOccluder3D | Occluder3D | 3D polygon shape for use with occlusion culling in [OccluderInstance3D]. | 2 | 1 | 0 | 0 |
| AspectRatioContainer | Container | A container that preserves the proportions of its child controls. | 4 | 0 | 0 | 7 |
| AtlasTexture | Texture2D | A texture that crops out part of another Texture2D. | 5 | 0 | 0 | 0 |
| AudioBusLayout | Resource | Stores information about the audio buses. | 0 | 0 | 0 | 0 |
| AudioEffect | Resource | Base class for audio effect resources. | 0 | 1 | 0 | 0 |
| AudioEffectAmplify | AudioEffect | Adds a volume manipulation audio effect to an audio bus. | 2 | 0 | 0 | 0 |
| AudioEffectBandLimitFilter | AudioEffectFilter | Adds a band-limit filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectBandPassFilter | AudioEffectFilter | Adds a band-pass filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectCapture | AudioEffect | Exposes audio samples from an audio bus in real-time, such that it can be accessed as data. | 1 | 7 | 0 | 0 |
| AudioEffectChorus | AudioEffect | Adds a chorus audio effect to an audio bus. 		Gives the impression of multiple audio sources. | 27 | 12 | 0 | 0 |
| AudioEffectCompressor | AudioEffect | Adds a downward compressor audio effect to an audio bus. 		Allows control of the dynamic range via a volume th | 7 | 0 | 0 | 0 |
| AudioEffectDelay | AudioEffect | Adds a delay audio effect to an audio bus. 		Emulates an echo by playing the input audio back after a period o | 13 | 0 | 0 | 0 |
| AudioEffectDistortion | AudioEffect | Adds a distortion audio effect to an audio bus. 		Remaps audio samples using a nonlinear function to achieve a | 5 | 0 | 0 | 5 |
| AudioEffectEQ | AudioEffect | Base class for audio equalizers (EQ). Gives you control over frequencies. 		Use it to create a custom equalize | 0 | 3 | 0 | 0 |
| AudioEffectEQ10 | AudioEffectEQ | Adds a 10-band equalizer audio effect to an audio bus. 		Gives you control over frequencies from 31 Hz to 1600 | 0 | 0 | 0 | 0 |
| AudioEffectEQ21 | AudioEffectEQ | Adds a 21-band equalizer audio effect to an audio bus. 		Gives you control over frequencies from 22 Hz to 2200 | 0 | 0 | 0 | 0 |
| AudioEffectEQ6 | AudioEffectEQ | Adds a 6-band equalizer audio effect to an audio bus. 		Gives you control over frequencies from 32 Hz to 10000 | 0 | 0 | 0 | 0 |
| AudioEffectFilter | AudioEffect | Base class for filters. Use effects that inherit this class instead of using it directly. | 4 | 0 | 0 | 4 |
| AudioEffectHardLimiter | AudioEffect | Adds a limiter audio effect to an audio bus. 		Prevents audio signals from exceeding a specified volume level. | 3 | 0 | 0 | 0 |
| AudioEffectHighPassFilter | AudioEffectFilter | Adds a high-pass filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectHighShelfFilter | AudioEffectFilter | Adds a high-shelf filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectInstance | RefCounted | Manipulates the audio it receives for a given effect. | 0 | 2 | 0 | 0 |
| AudioEffectLimiter | AudioEffect | Adds a soft-clip limiter audio effect to an audio bus. | 4 | 0 | 0 | 0 |
| AudioEffectLowPassFilter | AudioEffectFilter | Adds a low-pass filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectLowShelfFilter | AudioEffectFilter | Adds a low-shelf filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectNotchFilter | AudioEffectFilter | Adds a notch filter to an audio bus. | 0 | 0 | 0 | 0 |
| AudioEffectPanner | AudioEffect | Adds a panner audio effect to an audio bus. 		Pans the sound left or right. | 1 | 0 | 0 | 0 |
| AudioEffectPhaser | AudioEffect | Adds a phaser audio effect to an audio bus. 		Creates several notch and peak filters that sweep across the spe | 5 | 0 | 0 | 0 |
| AudioEffectPitchShift | AudioEffect | Adds a pitch-shifting audio effect to an audio bus. 		Raises or lowers the pitch of the input audio. | 3 | 0 | 0 | 6 |
| AudioEffectRecord | AudioEffect | Audio effect used for recording the sound from an audio bus. | 1 | 3 | 0 | 0 |
| AudioEffectReverb | AudioEffect | Adds a reverberation audio effect to an audio bus. 		Emulates an echo by playing a blurred version of the inpu | 8 | 0 | 0 | 0 |
| AudioEffectSpectrumAnalyzer | AudioEffect | Creates an [AudioEffectInstance] which performs frequency analysis and exposes results to be accessed in real- | 2 | 0 | 0 | 6 |
| AudioEffectSpectrumAnalyzerInstance | AudioEffectInstance | Queryable instance of an [AudioEffectSpectrumAnalyzer]. | 0 | 1 | 0 | 2 |
| AudioEffectStereoEnhance | AudioEffect | Adds a stereo manipulation audio effect to an audio bus. 		Controls gain of the side channels, and widens the  | 3 | 0 | 0 | 0 |
| AudioListener2D | Node2D | Overrides the location sounds are heard from. | 0 | 3 | 0 | 0 |
| AudioListener3D | Node3D | Overrides the location sounds are heard from. | 1 | 4 | 0 | 3 |
| AudioSample | RefCounted | Base class for audio samples. | 0 | 0 | 0 | 0 |
| AudioSamplePlayback | RefCounted | Meta class for playing back audio samples. | 0 | 0 | 0 | 0 |
| AudioServer | Object | Server interface for low-level audio access. | 4 | 49 | 2 | 8 |
| AudioStream | Resource | Base class for audio streams. | 0 | 16 | 1 | 0 |
| AudioStreamGenerator | AudioStream | An audio stream with utilities for procedural sound generation. | 3 | 0 | 0 | 4 |
| AudioStreamGeneratorPlayback | AudioStreamPlaybackResampled | Plays back audio generated using [AudioStreamGenerator]. | 0 | 6 | 0 | 0 |
| AudioStreamMicrophone | AudioStream | Plays real-time audio input data. | 0 | 0 | 0 | 0 |
| AudioStreamPlayback | RefCounted | Meta class for playing back audio. | 0 | 19 | 0 | 0 |
| AudioStreamPlaybackPolyphonic | AudioStreamPlayback | Playback instance for [AudioStreamPolyphonic]. | 0 | 5 | 0 | 1 |
| AudioStreamPlaybackResampled | AudioStreamPlayback | Playback class used for resampled [AudioStream]s. | 0 | 3 | 0 | 0 |
| AudioStreamPlayer | Node | A node for audio playback. | 11 | 6 | 1 | 3 |
| AudioStreamPlayer2D | Node2D | Plays positional sound in 2D space. | 14 | 6 | 1 | 0 |
| AudioStreamPlayer3D | Node3D | Plays positional sound in 3D space. | 22 | 6 | 1 | 7 |
| AudioStreamPolyphonic | AudioStream | AudioStream that lets the user play custom streams at any time from code, simultaneously using a single player | 1 | 0 | 0 | 0 |
| AudioStreamRandomizer | AudioStream | Wraps a pool of audio streams with pitch and volume shifting. | 7 | 7 | 0 | 3 |
| AudioStreamWAV | AudioStream | Stores audio data loaded from WAV files. | 8 | 3 | 0 | 8 |
| AwaitTweener | Tweener | Awaits a specified signal. | 0 | 1 | 0 | 0 |
| BackBufferCopy | Node2D | A node that copies a region of the screen to a buffer for access in shader code. | 2 | 0 | 0 | 3 |
| BaseButton | Control | Abstract base class for GUI buttons. | 11 | 5 | 4 | 7 |
| BaseMaterial3D | Material | Abstract base class for defining the 3D rendering properties of meshes. | 131 | 6 | 0 | 131 |
| Basis | — | A 3×3 matrix for representing 3D rotation and scale. | 3 | 21 | 0 | 4 |
| BitMap | Resource | Boolean matrix. | 0 | 13 | 0 | 0 |
| BlitMaterial | Material | A material that processes blit calls to a DrawableTexture. | 1 | 0 | 0 | 5 |
| Bone2D | Node2D | A joint used with [Skeleton2D] to control and animate other nodes. | 1 | 9 | 0 | 0 |
| BoneAttachment3D | Node3D | А node that dynamically copies or overrides the 3D transform of a bone in its parent [Skeleton3D]. | 6 | 2 | 0 | 0 |
| BoneConstraint3D | SkeletonModifier3D | A node that may modify Skeleton3D's bone with associating the two bones. | 0 | 17 | 0 | 2 |
| BoneMap | Resource | Describes a mapping of bone names for retargeting [Skeleton3D] into common names defined by a [SkeletonProfile | 1 | 3 | 2 | 0 |
| BoneTwistDisperser3D | SkeletonModifier3D | A node that propagates and disperses the child bone's twist to the parent bones. | 2 | 30 | 0 | 3 |
| BoxContainer | Container | A container that arranges its child controls horizontally or vertically. | 2 | 1 | 0 | 3 |
| BoxMesh | PrimitiveMesh | Generate an axis-aligned box [PrimitiveMesh]. | 4 | 0 | 0 | 0 |
| BoxOccluder3D | Occluder3D | Cuboid shape for use with occlusion culling in [OccluderInstance3D]. | 1 | 0 | 0 | 0 |
| BoxShape3D | Shape3D | A 3D box shape used for physics collision. | 1 | 0 | 0 | 0 |
| Button | BaseButton | A themed button that can contain text and an icon. | 13 | 0 | 0 | 0 |
| ButtonGroup | Resource | A group of buttons that doesn't allow more than one button to be pressed at a time. | 2 | 2 | 1 | 0 |
| CCDIK3D | IterateIK3D | Rotation based cyclic coordinate descent inverse kinematics solver. | 0 | 0 | 0 | 0 |
| CPUParticles2D | Node2D | A CPU-based 2D particle emitter. | 70 | 11 | 1 | 27 |
| CPUParticles3D | GeometryInstance3D | A CPU-based 3D particle emitter. | 77 | 12 | 1 | 28 |
| Callable | — | A built-in type representing a method or a standalone function. | 0 | 21 | 0 | 0 |
| CallbackTweener | Tweener | Calls the specified method after optional delay. | 0 | 1 | 0 | 0 |
| Camera2D | Node2D | Camera node for 2D scenes. | 28 | 12 | 0 | 4 |
| Camera3D | Node3D | Camera node, displays from a point of view. | 15 | 19 | 0 | 8 |
| CameraAttributes | Resource | Parent class for camera settings. | 5 | 0 | 0 | 0 |
| CameraAttributesPhysical | CameraAttributes | Physically-based camera settings. | 8 | 1 | 0 | 0 |
| CameraAttributesPractical | CameraAttributes | Camera settings in an easy to use format. | 9 | 0 | 0 | 0 |
| CameraFeed | RefCounted | A camera feed gives you access to a single physical camera attached to your device. | 3 | 16 | 2 | 8 |
| CameraServer | Object | Server keeping track of different cameras accessible in Godot. | 1 | 5 | 3 | 4 |
| CameraTexture | Texture2D | Texture provided by a [CameraFeed]. | 4 | 0 | 0 | 0 |
| CanvasGroup | Node2D | Merges several 2D nodes into a single draw operation. | 3 | 0 | 0 | 0 |
| CanvasItem | Node | Abstract base class for everything in 2D space. | 16 | 62 | 4 | 28 |
| CanvasItemMaterial | Material | A material for [CanvasItem]s. | 6 | 0 | 0 | 8 |
| CanvasLayer | Node | A node used for independent rendering of objects within a 2D scene. | 9 | 4 | 1 | 0 |
| CanvasModulate | Node2D | A node that applies a color tint to a canvas. | 1 | 0 | 0 | 0 |
| CanvasTexture | Texture2D | Texture with optional normal and specular maps for use in 2D rendering. | 8 | 0 | 0 | 0 |
| CapsuleMesh | PrimitiveMesh | Class representing a capsule-shaped [PrimitiveMesh]. | 4 | 0 | 0 | 0 |
| CapsuleShape2D | Shape2D | A 2D capsule shape used for physics collision. | 3 | 0 | 0 | 0 |
| CapsuleShape3D | Shape3D | A 3D capsule shape used for physics collision. | 3 | 0 | 0 | 0 |
| CenterContainer | Container | A container that keeps child controls in its center. | 1 | 0 | 0 | 0 |
| ChainIK3D | IKModifier3D | A [SkeletonModifier3D] to apply inverse kinematics to bone chains containing an arbitrary number of bones. | 0 | 17 | 0 | 0 |
| CharFXTransform | RefCounted | Controls how an individual character will be displayed in a [RichTextEffect]. | 13 | 0 | 0 | 0 |
| CharacterBody2D | PhysicsBody2D | A 2D physics body specialized for characters moved by script. | 15 | 18 | 0 | 5 |
| CharacterBody3D | PhysicsBody3D | A 3D physics body specialized for characters moved by script. | 15 | 19 | 0 | 5 |
| CheckBox | Button | A button that represents a binary choice. | 2 | 0 | 0 | 0 |
| CheckButton | Button | A button that represents a binary choice. | 2 | 0 | 0 | 0 |
| CircleShape2D | Shape2D | A 2D circle shape used for physics collision. | 1 | 0 | 0 | 0 |
| ClassDB | Object | A class information repository. | 0 | 30 | 0 | 5 |
| CodeEdit | TextEdit | A multiline text editor designed for editing code. | 24 | 73 | 5 | 15 |
| CodeHighlighter | SyntaxHighlighter | A syntax highlighter intended for code. | 7 | 14 | 0 | 0 |
| CollisionObject2D | Node2D | Abstract base class for 2D physics objects. | 5 | 31 | 5 | 3 |
| CollisionObject3D | Node3D | Abstract base class for 3D physics objects. | 6 | 23 | 3 | 3 |
| CollisionPolygon2D | Node2D | A node that provides a polygon shape to a [CollisionObject2D] parent. | 6 | 0 | 0 | 2 |
| CollisionPolygon3D | Node3D | A node that provides a thickened polygon shape (a prism) to a [CollisionObject3D] parent. | 6 | 0 | 0 | 0 |
| CollisionShape2D | Node2D | A node that provides a [Shape2D] to a [CollisionObject2D] parent. | 6 | 0 | 0 | 0 |
| CollisionShape3D | Node3D | A node that provides a [Shape3D] to a [CollisionObject3D] parent. | 4 | 2 | 0 | 0 |
| Color | — | A color represented in RGBA format. | 14 | 26 | 0 | 146 |
| ColorPalette | Resource | A resource class for managing a palette of colors, which can be loaded and saved using [ColorPicker]. | 1 | 0 | 0 | 0 |
| ColorPicker | VBoxContainer | A widget that provides an interface for selecting or modifying a color. | 12 | 6 | 3 | 12 |
| ColorPickerButton | Button | A button that brings up a [ColorPicker] when pressed. | 4 | 2 | 3 | 0 |
| ColorRect | Control | A control that displays a solid color rectangle. | 1 | 0 | 0 | 0 |
| Compositor | Resource | Stores attributes used to customize how a Viewport is rendered. | 1 | 0 | 0 | 0 |
| CompositorEffect | Resource | This resource allows for creating a custom rendering effect. | 7 | 1 | 0 | 6 |
| CompressedCubemap | CompressedTextureLayered | An optionally compressed [Cubemap]. | 0 | 0 | 0 | 0 |
| CompressedCubemapArray | CompressedTextureLayered | An optionally compressed [CubemapArray]. | 0 | 0 | 0 | 0 |
| CompressedTexture2D | Texture2D | Texture with 2 dimensions, optionally compressed. | 2 | 1 | 0 | 0 |
| CompressedTexture2DArray | CompressedTextureLayered | Array of 2-dimensional textures, optionally compressed. | 0 | 0 | 0 | 0 |
| CompressedTexture3D | Texture3D | Texture with 3 dimensions, optionally compressed. | 1 | 1 | 0 | 0 |
| CompressedTextureLayered | TextureLayered | Base class for texture arrays that can optionally be compressed. | 1 | 1 | 0 | 0 |
| ConcavePolygonShape2D | Shape2D | A 2D polyline shape used for physics collision. | 1 | 0 | 0 | 0 |
| ConcavePolygonShape3D | Shape3D | A 3D trimesh shape used for physics collision. | 1 | 2 | 0 | 0 |
| ConeTwistJoint3D | Joint3D | A physics joint that connects two 3D physics bodies in a way that simulates a ball-and-socket joint. | 5 | 2 | 0 | 6 |
| ConfigFile | RefCounted | Helper class to handle INI-style files. | 0 | 17 | 0 | 0 |
| ConfirmationDialog | AcceptDialog | A dialog used for confirmation of actions. | 4 | 1 | 0 | 0 |
| Container | Control | Base class for all GUI containers. | 3 | 4 | 2 | 2 |
| Control | CanvasItem | Base class for all GUI controls. Adapts its position and size based on its parent control. | 62 | 100 | 10 | 83 |
| ConvertTransformModifier3D | BoneConstraint3D | A [SkeletonModifier3D] that apply transform to the bone which converted from reference. | 1 | 20 | 0 | 3 |
| ConvexPolygonShape2D | Shape2D | A 2D convex polygon shape used for physics collision. | 1 | 1 | 0 | 0 |
| ConvexPolygonShape3D | Shape3D | A 3D convex polyhedron shape used for physics collision. | 1 | 0 | 0 | 0 |
| CopyTransformModifier3D | BoneConstraint3D | A [SkeletonModifier3D] that apply transform to the bone which copied from reference. | 1 | 28 | 0 | 8 |
| Crypto | RefCounted | Provides access to advanced cryptographic functionalities. | 0 | 9 | 0 | 0 |
| CryptoKey | Resource | A cryptographic key (RSA or elliptic-curve). | 0 | 5 | 0 | 0 |
| Cubemap | ImageTextureLayered | Six square textures representing the faces of a cube. Commonly used as a skybox. | 0 | 1 | 0 | 0 |
| CubemapArray | ImageTextureLayered | An array of [Cubemap]s, stored together and with a single reference. | 0 | 1 | 0 | 0 |
| Curve | Resource | A mathematical curve. | 11 | 20 | 2 | 3 |
| Curve2D | Resource | Describes a Bézier curve in 2D space. | 5 | 19 | 0 | 0 |
| Curve3D | Resource | Describes a Bézier curve in 3D space. | 8 | 24 | 0 | 0 |
| CurveTexture | Texture2D | A 1D texture where pixel brightness corresponds to points on a curve. | 4 | 0 | 0 | 2 |
| CurveXYZTexture | Texture2D | A 1D texture where the red, green, and blue color channels correspond to points on 3 curves. | 5 | 0 | 0 | 0 |
| CylinderMesh | PrimitiveMesh | Class representing a cylindrical [PrimitiveMesh]. | 7 | 0 | 0 | 0 |
| CylinderShape3D | Shape3D | A 3D cylinder shape used for physics collision. | 2 | 0 | 0 | 0 |
| DPITexture | Texture2D | An automatically scalable [Texture2D] based on an SVG image. | 6 | 5 | 0 | 0 |
| DTLSServer | RefCounted | Helper class to implement a DTLS server. | 0 | 2 | 0 | 0 |
| DampedSpringJoint2D | Joint2D | A physics joint that connects two 2D physics bodies with a spring-like force. | 4 | 0 | 0 | 0 |
| Decal | VisualInstance3D | Node that projects a texture onto a [MeshInstance3D]. | 15 | 2 | 0 | 5 |
| Dictionary | — | A built-in data structure that holds key-value pairs. | 0 | 34 | 0 | 0 |
| DirAccess | RefCounted | Provides methods for managing directories and their content. | 2 | 38 | 0 | 0 |
| DirectionalLight2D | Light2D | Directional 2D light from a distance. | 2 | 0 | 0 | 0 |
| DirectionalLight3D | Light3D | Directional light from a distance, as from the Sun. | 9 | 0 | 0 | 6 |
| DisplayServer | Object | A server interface for low-level window management. | 0 | 287 | 1 | 243 |
| DrawableTexture2D | Texture2D | A 2D texture that supports drawing to itself via Blit calls. | 1 | 7 | 0 | 4 |
| EditorCommandPalette | ConfirmationDialog | Godot editor's command palette. | 0 | 2 | 0 | 0 |
| EditorContextMenuPlugin | RefCounted | Plugin for adding custom context menus in the editor. | 0 | 5 | 0 | 8 |
| EditorDebuggerPlugin | RefCounted | A base class to implement debugger plugins. | 0 | 8 | 0 | 0 |
| EditorDebuggerSession | RefCounted | A class to interact with the editor debugger. | 0 | 8 | 4 | 0 |
| EditorDock | MarginContainer | Dockable container for the editor. | 13 | 6 | 2 | 17 |
| EditorExportPlatform | RefCounted | Identifies a supported export platform, and internally provides the functionality of exporting to that platfor | 0 | 27 | 0 | 9 |
| EditorExportPlatformAppleEmbedded | EditorExportPlatform | Base class for the Apple embedded platform exporters (iOS and visionOS). | 0 | 0 | 0 | 0 |
| EditorExportPlatformExtension | EditorExportPlatform | Base class for custom [EditorExportPlatform] implementations (plugins). | 0 | 35 | 0 | 0 |
| EditorExportPlatformPC | EditorExportPlatform | Base class for the desktop platform exporter (Windows and Linux/BSD). | 0 | 0 | 0 | 0 |
| EditorExportPlugin | RefCounted | A script that is executed when exporting the project. | 0 | 47 | 0 | 0 |
| EditorExportPreset | RefCounted | Export preset configuration. | 0 | 25 | 0 | 12 |
| EditorFeatureProfile | RefCounted | An editor feature profile which can be used to disable specific features. | 0 | 11 | 0 | 12 |
| EditorFileDialog | FileDialog | A modified version of [FileDialog] used by the editor. | 1 | 1 | 0 | 0 |
| EditorFileSystem | Node | Resource filesystem, as the editor sees it. | 0 | 10 | 6 | 0 |
| EditorFileSystemDirectory | Object | A directory for the resource filesystem. | 0 | 14 | 0 | 0 |
| EditorFileSystemImportFormatSupportQuery | RefCounted | Used to query and configure import format support. | 0 | 3 | 0 | 0 |
| EditorImportPlugin | ResourceImporter | Registers a custom resource importer in the editor. Use the class to parse any file and import it as a new res | 0 | 15 | 0 | 0 |
| EditorInspector | ScrollContainer | A control used to edit properties of an object. | 4 | 8 | 9 | 0 |
| EditorInspectorPlugin | RefCounted | Plugin for adding custom property editors on the inspector. | 0 | 9 | 0 | 0 |
| EditorInterface | Object | Godot editor's interface. | 2 | 67 | 0 | 0 |
| EditorNode3DGizmo | Node3DGizmo | Gizmo for editing [Node3D] objects. | 0 | 25 | 0 | 0 |
| EditorNode3DGizmoPlugin | Resource | A class used by the editor to define Node3D gizmo types. | 0 | 24 | 0 | 0 |
| EditorPaths | Object | Editor-only singleton that returns paths to various OS-specific data folders and files. | 0 | 6 | 0 | 0 |
| EditorPlugin | Node | Used by the editor to extend its functionality. | 0 | 76 | 6 | 26 |
| EditorProperty | Container | Custom control for editing properties that can be added to the [EditorInspector]. | 13 | 13 | 13 | 0 |
| EditorResourceConversionPlugin | RefCounted | Plugin for adding custom converters from one resource format to another in the editor resource picker context  | 0 | 3 | 0 | 0 |
| EditorResourcePicker | HBoxContainer | Godot editor's control for selecting [Resource] type properties. | 4 | 4 | 2 | 0 |
| EditorResourcePreview | Node | A node used to generate previews of resources or files. | 0 | 5 | 1 | 0 |
| EditorResourcePreviewGenerator | RefCounted | Custom generator of previews. | 0 | 6 | 0 | 0 |
| EditorResourceTooltipPlugin | RefCounted | A plugin that advanced tooltip for its handled resource type. | 0 | 3 | 0 | 0 |
| EditorSceneFormatImporter | RefCounted | Imports scenes from third-parties' 3D files. | 0 | 6 | 0 | 7 |
| EditorScenePostImport | RefCounted | Post-processes scenes after import. | 0 | 2 | 0 | 0 |
| EditorScenePostImportPlugin | RefCounted | Plugin to control and modifying the process of importing a scene. | 0 | 11 | 0 | 8 |
| EditorScript | RefCounted | Base script that can be used to add extension functions to the editor. | 0 | 4 | 0 | 0 |
| EditorScriptPicker | EditorResourcePicker | Godot editor's control for selecting the [code]script[/code] property of a [Node]. | 1 | 0 | 0 | 0 |
| EditorSelection | Object | Manages the SceneTree selection in the editor. | 0 | 6 | 1 | 0 |
| EditorSettings | Resource | Object that holds the project-independent editor settings. | 472 | 22 | 1 | 1 |
| EditorSpinSlider | Range | Godot editor's control for editing numeric values. | 11 | 0 | 5 | 3 |
| EditorSyntaxHighlighter | SyntaxHighlighter | Base class for [SyntaxHighlighter] used by the [ScriptEditor]. | 0 | 3 | 0 | 0 |
| EditorToaster | HBoxContainer | Manages toast notifications within the editor. | 0 | 1 | 0 | 3 |
| EditorTranslationParserPlugin | RefCounted | Plugin for adding custom parsers to extract strings that are to be translated from custom files (.csv, .json e | 0 | 3 | 0 | 0 |
| EditorUndoRedoManager | Object | Manages undo history of scenes opened in the editor. | 0 | 13 | 2 | 3 |
| EditorVCSInterface | Object | Version Control System (VCS) interface, which reads and writes to the local VCS in use. | 0 | 32 | 0 | 9 |
| EncodedObjectAsID | RefCounted | Holds a reference to an [Object]'s instance ID. | 1 | 0 | 0 | 0 |
| Engine | Object | Provides access to engine properties. | 7 | 27 | 0 | 0 |
| EngineDebugger | Object | Exposes the internal debugger. | 0 | 23 | 0 | 0 |
| EngineProfiler | RefCounted | Base class for creating custom profilers. | 0 | 3 | 0 | 0 |
| Environment | Resource | Resource for environment nodes (like [WorldEnvironment]) that define multiple rendering options. | 100 | 2 | 0 | 29 |
| Expression | RefCounted | A class that stores an expression you can execute. | 0 | 4 | 0 | 0 |
| ExternalTexture | Texture2D | Texture which displays the content of an external buffer. | 2 | 2 | 0 | 0 |
| FABRIK3D | IterateIK3D | Position based forward and backward reaching inverse kinematics solver. | 0 | 0 | 0 | 0 |
| FileAccess | RefCounted | Provides methods for file reading and writing operations. | 1 | 66 | 0 | 21 |
| FileDialog | ConfirmationDialog | A dialog for selecting files or directories in the filesystem. | 28 | 24 | 4 | 19 |
| FileSystemDock | EditorDock | Godot editor's dock for managing files in the project. | 0 | 3 | 10 | 0 |
| FlowContainer | Container | A container that arranges its child controls horizontally or vertically and wraps them around at the borders. | 4 | 1 | 0 | 7 |
| FogMaterial | Material | A material that controls how volumetric fog is rendered, to be assigned to a [FogVolume]. | 6 | 0 | 0 | 0 |
| FogVolume | VisualInstance3D | A region that contributes to the default volumetric fog from the world environment. | 3 | 0 | 0 | 0 |
| FoldableContainer | Container | A container that can be expanded/collapsed. | 10 | 4 | 1 | 2 |
| FoldableGroup | Resource | A group of foldable containers that doesn't allow more than one container to be expanded at a time. | 2 | 2 | 1 | 0 |
| Font | Resource | Abstract base class for fonts and font variations. | 1 | 35 | 0 | 0 |
| FontFile | Font | Holds font source data and prerendered glyph cache, imported from a dynamic or a bitmap font. | 22 | 67 | 0 | 0 |
| FontVariation | Font | A variation of a font with additional settings. | 13 | 1 | 0 | 0 |
| FramebufferCacheRD | Object | Framebuffer cache manager for Rendering Device based renderers. | 0 | 1 | 0 | 0 |
| GDExtension | Resource | A native library for GDExtension. | 0 | 2 | 0 | 4 |
| GDExtensionManager | Object | Provides access to GDExtension functionality. | 0 | 7 | 3 | 5 |
| GPUParticles2D | Node2D | A 2D particle emitter. | 26 | 5 | 1 | 8 |
| GPUParticles3D | GeometryInstance3D | A 3D particle emitter. | 32 | 7 | 1 | 15 |
| GPUParticlesAttractor3D | VisualInstance3D | Abstract base class for 3D particle attractors. | 4 | 0 | 0 | 0 |
| GPUParticlesAttractorBox3D | GPUParticlesAttractor3D | A box-shaped attractor that influences particles from [GPUParticles3D] nodes. | 1 | 0 | 0 | 0 |
| GPUParticlesAttractorSphere3D | GPUParticlesAttractor3D | A spheroid-shaped attractor that influences particles from [GPUParticles3D] nodes. | 1 | 0 | 0 | 0 |
| GPUParticlesAttractorVectorField3D | GPUParticlesAttractor3D | A box-shaped attractor with varying directions and strengths defined in it that influences particles from [GPU | 2 | 0 | 0 | 0 |
| GPUParticlesCollision3D | VisualInstance3D | Abstract base class for 3D particle collision shapes affecting [GPUParticles3D] nodes. | 1 | 0 | 0 | 0 |
| GPUParticlesCollisionBox3D | GPUParticlesCollision3D | A box-shaped 3D particle collision shape affecting [GPUParticles3D] nodes. | 1 | 0 | 0 | 0 |
| GPUParticlesCollisionHeightField3D | GPUParticlesCollision3D | A real-time heightmap-shaped 3D particle collision shape affecting [GPUParticles3D] nodes. | 5 | 2 | 0 | 9 |
| GPUParticlesCollisionSDF3D | GPUParticlesCollision3D | A baked signed distance field 3D particle collision shape affecting [GPUParticles3D] nodes. | 5 | 2 | 0 | 7 |
| GPUParticlesCollisionSphere3D | GPUParticlesCollision3D | A sphere-shaped 3D particle collision shape affecting [GPUParticles3D] nodes. | 1 | 0 | 0 | 0 |
| Generic6DOFJoint3D | Joint3D | A physics joint that allows for complex movement and rotation between two 3D physics bodies. | 84 | 12 | 0 | 30 |
| Geometry2D | Object | Provides methods for some common 2D geometric operations. | 0 | 24 | 0 | 12 |
| Geometry3D | Object | Provides methods for some common 3D geometric operations. | 0 | 15 | 0 | 0 |
| GeometryInstance3D | VisualInstance3D | Base node for geometry-based visual instances. | 16 | 2 | 0 | 15 |
| GodotInstance | Object | Provides access to an embedded Godot instance. | 0 | 7 | 0 | 0 |
| Gradient | Resource | A color transition. | 4 | 9 | 0 | 6 |
| GradientTexture1D | Texture2D | A 1D texture that uses colors obtained from a [Gradient]. | 4 | 0 | 0 | 0 |
| GradientTexture2D | Texture2D | A 2D texture that creates a pattern with colors obtained from a [Gradient]. | 9 | 0 | 0 | 7 |
| GraphEdit | Control | An editor for graph-like structures, using [GraphNode]s. | 27 | 29 | 19 | 4 |
| GraphElement | Container | A container that represents a basic element that can be placed inside a [GraphEdit] control. | 6 | 0 | 8 | 0 |
| GraphFrame | GraphElement | GraphFrame is a special [GraphElement] that can be used to organize other [GraphElement]s inside a [GraphEdit] | 7 | 1 | 1 | 0 |
| GraphNode | GraphElement | A container with connection ports, representing a node in a [GraphEdit]. | 5 | 37 | 2 | 0 |
| GridContainer | Container | A container that arranges its child controls in a grid layout. | 1 | 0 | 0 | 0 |
| GrooveJoint2D | Joint2D | A physics joint that restricts the movement of two 2D physics bodies to a fixed axis. | 2 | 0 | 0 | 0 |
| HBoxContainer | BoxContainer | A container that arranges its child controls horizontally. | 0 | 0 | 0 | 0 |
| HFlowContainer | FlowContainer | A container that arranges its child controls horizontally and wraps them around at the borders. | 0 | 0 | 0 | 0 |
| HMACContext | RefCounted | Used to create an HMAC for a message using a key. | 0 | 3 | 0 | 0 |
| HScrollBar | ScrollBar | A horizontal scrollbar that goes from left (min) to right (max). | 0 | 0 | 0 | 0 |
| HSeparator | Separator | A horizontal line used for separating other controls. | 0 | 0 | 0 | 0 |
| HSlider | Slider | A horizontal slider that goes from left (min) to right (max). | 0 | 0 | 0 | 0 |
| HSplitContainer | SplitContainer | A container that splits two child controls horizontally and provides a grabber for adjusting the split ratio. | 0 | 0 | 0 | 0 |
| HTTPClient | RefCounted | Low-level hyper-text transfer protocol client. | 3 | 16 | 0 | 81 |
| HTTPRequest | Node | A node with the ability to send HTTP(S) requests. | 7 | 9 | 1 | 14 |
| HashingContext | RefCounted | Provides functionality for computing cryptographic hashes chunk by chunk. | 0 | 3 | 0 | 3 |
| HeightMapShape3D | Shape3D | A 3D heightmap shape used for physics collision. | 3 | 3 | 0 | 0 |
| HingeJoint3D | Joint3D | A physics joint that restricts the rotation of a 3D physics body around an axis relative to another physics bo | 10 | 4 | 0 | 12 |
| IKModifier3D | SkeletonModifier3D | A node for inverse kinematics which may modify more than one bone. | 1 | 4 | 0 | 0 |
| IP | Object | Internet protocol (IP) support functions such as DNS resolution. | 0 | 10 | 0 | 10 |
| Image | Resource | Image datatype. | 1 | 76 | 0 | 75 |
| ImageFormatLoader | RefCounted | Base class to add support for specific image formats. | 0 | 0 | 0 | 3 |
| ImageFormatLoaderExtension | ImageFormatLoader | Base class for creating [ImageFormatLoader] extensions (adding support for extra image formats). | 0 | 4 | 0 | 0 |
| ImageTexture | Texture2D | A [Texture2D] based on an [Image]. | 1 | 4 | 0 | 0 |
| ImageTexture3D | Texture3D | Texture with 3 dimensions. | 0 | 2 | 0 | 0 |
| ImageTextureLayered | TextureLayered | Base class for texture types which contain the data of multiple [ImageTexture]s. Each image is of the same siz | 0 | 2 | 0 | 0 |
| ImmediateMesh | Mesh | Mesh optimized for creating geometry manually. | 0 | 10 | 0 | 0 |
| ImporterMesh | Resource | A [Resource] that contains vertex array-based geometry during the import process. | 0 | 25 | 0 | 0 |
| ImporterMeshInstance3D | Node3D |  | 10 | 0 | 0 | 0 |
| Input | Object | A singleton for handling inputs. | 5 | 67 | 1 | 23 |
| InputEvent | Resource | Abstract base class for input events. | 1 | 13 | 0 | 3 |
| InputEventAction | InputEvent | An input event type for actions. | 4 | 0 | 0 | 0 |
| InputEventFromWindow | InputEvent | Abstract base class for [Viewport]-based input events. | 1 | 0 | 0 | 0 |
| InputEventGesture | InputEventWithModifiers | Abstract base class for touch gestures. | 2 | 0 | 0 | 0 |
| InputEventJoypadButton | InputEvent | Represents a gamepad button being pressed or released. | 3 | 0 | 0 | 0 |
| InputEventJoypadMotion | InputEvent | Represents axis motions (such as joystick or analog triggers) from a gamepad. | 2 | 0 | 0 | 0 |
| InputEventKey | InputEventWithModifiers | Represents a key on a keyboard being pressed or released. | 7 | 7 | 0 | 0 |
| InputEventMIDI | InputEvent | Represents a MIDI message from a MIDI device, such as a musical keyboard. | 8 | 0 | 0 | 0 |
| InputEventMagnifyGesture | InputEventGesture | Represents a magnifying touch gesture. | 1 | 0 | 0 | 0 |
| InputEventMouse | InputEventWithModifiers | Base input event type for mouse events. | 4 | 0 | 0 | 0 |
| InputEventMouseButton | InputEventMouse | Represents a mouse button being pressed or released. | 5 | 0 | 0 | 0 |
| InputEventMouseMotion | InputEventMouse | Represents a mouse or a pen movement. | 7 | 0 | 0 | 0 |
| InputEventPanGesture | InputEventGesture | Represents a panning touch gesture. | 1 | 0 | 0 | 0 |
| InputEventScreenDrag | InputEventFromWindow | Represents a screen drag event. | 9 | 0 | 0 | 0 |
| InputEventScreenTouch | InputEventFromWindow | Represents a screen touch event. | 5 | 0 | 0 | 0 |
| InputEventShortcut | InputEvent | Represents a triggered keyboard [Shortcut]. | 1 | 0 | 0 | 0 |
| InputEventWithModifiers | InputEventFromWindow | Abstract base class for input events affected by modifier keys like [kbd]Shift[/kbd] and [kbd]Alt[/kbd]. | 6 | 2 | 0 | 0 |
| InputMap | Object | A singleton that manages all [InputEventAction]s. | 0 | 14 | 1 | 0 |
| InstancePlaceholder | Node | Placeholder for the root [Node] of a [PackedScene]. | 0 | 3 | 0 | 0 |
| IntervalTweener | Tweener | Creates an idle interval in a [Tween] animation. | 0 | 0 | 0 | 0 |
| ItemList | Control | A vertical list of selectable items with one or multiple columns. | 24 | 49 | 5 | 9 |
| IterateIK3D | ChainIK3D | A [SkeletonModifier3D] to approach the goal by repeating small rotations. | 5 | 14 | 0 | 0 |
| JNISingleton | Object | Singleton that connects the engine with Android plugins to interface with native Android code. | 0 | 1 | 0 | 0 |
| JSON | Resource | Helper class for creating and parsing JSON data. | 1 | 8 | 0 | 0 |
| JSONRPC | Object | A helper to handle dictionaries which look like JSONRPC documents. | 0 | 7 | 0 | 5 |
| JacobianIK3D | IterateIK3D | Jacobian transpose based inverse kinematics solver. | 0 | 0 | 0 | 0 |
| JavaClass | RefCounted | Represents a class from the Java Native Interface. | 0 | 4 | 0 | 0 |
| JavaClassWrapper | Object | Provides access to the Java Native Interface. | 0 | 4 | 0 | 0 |
| JavaObject | RefCounted | Represents an object from the Java Native Interface. | 0 | 2 | 0 | 0 |
| JavaScriptBridge | Object | Singleton that connects the engine with the browser's JavaScript context in Web export. | 0 | 10 | 1 | 0 |
| JavaScriptObject | RefCounted | A wrapper class for web native JavaScript objects. | 0 | 0 | 0 | 0 |
| Joint2D | Node2D | Abstract base class for all 2D physics joints. | 4 | 1 | 0 | 0 |
| Joint3D | Node3D | Abstract base class for all 3D physics joints. | 4 | 1 | 0 | 0 |
| JointLimitation3D | Resource | A base class of the limitation that interacts with [ChainIK3D]. | 0 | 0 | 0 | 0 |
| JointLimitationCone3D | JointLimitation3D | A cone shape limitation that interacts with [ChainIK3D]. | 1 | 0 | 0 | 0 |
| KinematicCollision2D | RefCounted | Holds collision data from the movement of a [PhysicsBody2D]. | 0 | 13 | 0 | 0 |
| KinematicCollision3D | RefCounted | Holds collision data from the movement of a [PhysicsBody3D]. | 0 | 14 | 0 | 0 |
| Label | Control | A control for displaying plain text. | 24 | 5 | 0 | 0 |
| Label3D | GeometryInstance3D | A node for displaying plain text in 3D space. | 35 | 3 | 0 | 9 |
| LabelSettings | Resource | Provides common settings to customize the text in a [Label]. | 17 | 16 | 0 | 0 |
| Light2D | Node2D | Casts light in a 2D environment. | 15 | 2 | 0 | 6 |
| Light3D | VisualInstance3D | Provides a base class for different kinds of light nodes. | 27 | 3 | 0 | 25 |
| LightOccluder2D | Node2D | Occludes light cast by a Light2D, casting shadows. | 3 | 0 | 0 | 0 |
| LightmapGI | VisualInstance3D | Computes and stores baked lightmaps for fast global illumination. | 22 | 0 | 0 | 25 |
| LightmapGIData | Resource | Contains baked lightmap and dynamic object probe data for [LightmapGI]. | 3 | 6 | 0 | 3 |
| LightmapProbe | Node3D | Represents a single manually placed probe for dynamic object lighting with [LightmapGI]. | 0 | 0 | 0 | 0 |
| Lightmapper | RefCounted | Abstract class extended by lightmappers, for use in [LightmapGI]. | 0 | 0 | 0 | 0 |
| LightmapperRD | Lightmapper | The built-in GPU-based lightmapper for use with [LightmapGI]. | 0 | 0 | 0 | 0 |
| LimitAngularVelocityModifier3D | SkeletonModifier3D | Limit bone rotation angular velocity. | 4 | 10 | 0 | 0 |
| Line2D | Node2D | A 2D polyline that can optionally be textured. | 14 | 6 | 0 | 9 |
| LineEdit | Control | An input field for single-line text. | 38 | 25 | 4 | 43 |
| LinkButton | BaseButton | A button that represents a link. | 11 | 0 | 0 | 3 |
| Logger | RefCounted | Custom logger to receive messages from the internal error/warning stream. | 0 | 2 | 0 | 4 |
| LookAtModifier3D | SkeletonModifier3D | The [LookAtModifier3D] rotates a bone to look at a target. | 30 | 3 | 0 | 3 |
| MainLoop | Object | Abstract base class for the game's main loop. | 0 | 4 | 1 | 12 |
| MarginContainer | Container | A container that keeps a margin around its child controls. | 0 | 0 | 0 | 0 |
| Marker2D | Node2D | Generic 2D position hint for editing. | 1 | 0 | 0 | 0 |
| Marker3D | Node3D | Generic 3D position hint for editing. | 1 | 0 | 0 | 0 |
| Marshalls | Object | Data transformation (marshaling) and encoding helpers. | 0 | 6 | 0 | 0 |
| Material | Resource | Virtual base class for applying visual properties to an object, such as color and roughness. | 2 | 6 | 0 | 2 |
| MenuBar | Control | A horizontal menu bar that creates a menu for each [PopupMenu] child. | 7 | 12 | 0 | 0 |
| MenuButton | Button | A button that brings up a [PopupMenu] when clicked. | 13 | 3 | 1 | 0 |
| Mesh | Resource | A [Resource] that contains vertex array-based geometry. | 1 | 26 | 0 | 57 |
| MeshConvexDecompositionSettings | RefCounted | Parameters to be used with a [Mesh] convex decomposition operation. | 13 | 0 | 0 | 2 |
| MeshDataTool | RefCounted | Helper tool to access and edit [Mesh] data. | 0 | 38 | 0 | 0 |
| MeshInstance2D | Node2D | Node used for displaying a [Mesh] in 2D. | 2 | 0 | 1 | 0 |
| MeshInstance3D | GeometryInstance3D | Node that instances meshes into a scenario. | 3 | 15 | 0 | 0 |
| MeshLibrary | Resource | Library of meshes. | 0 | 25 | 0 | 0 |
| MeshTexture | Texture2D | Simple texture that uses a mesh to draw itself. | 4 | 0 | 0 | 0 |
| MethodTweener | Tweener | Interpolates an abstract value and supplies it to a method called over time. | 0 | 3 | 0 | 0 |
| MissingNode | Node | An internal editor class intended for keeping the data of unrecognized nodes. | 4 | 0 | 0 | 0 |
| MissingResource | Resource | An internal editor class intended for keeping the data of unrecognized resources. | 2 | 0 | 0 | 0 |
| ModifierBoneTarget3D | SkeletonModifier3D | А node that dynamically copies the 3D transform of a bone in its parent [Skeleton3D]. | 2 | 0 | 0 | 0 |
| MovieWriter | Object | Abstract class for non-real-time video recording encoders. | 0 | 8 | 0 | 0 |
| MultiMesh | Resource | Provides high-performance drawing of a mesh multiple times using GPU instancing. | 13 | 12 | 0 | 4 |
| MultiMeshInstance2D | Node2D | Node that instances a [MultiMesh] in 2D. | 2 | 0 | 1 | 0 |
| MultiMeshInstance3D | GeometryInstance3D | Node that instances a [MultiMesh]. | 1 | 0 | 0 | 0 |
| MultiplayerAPI | RefCounted | High-level multiplayer API interface. | 1 | 12 | 5 | 3 |
| MultiplayerAPIExtension | MultiplayerAPI | Base class used for extending the [MultiplayerAPI]. | 0 | 9 | 0 | 0 |
| MultiplayerPeer | PacketPeer | Abstract class for specialized [PacketPeer]s used by the [MultiplayerAPI]. | 3 | 11 | 2 | 8 |
| MultiplayerPeerExtension | MultiplayerPeer | Class that can be inherited to implement custom multiplayer API networking layers via GDExtension. | 0 | 23 | 0 | 0 |
| Mutex | RefCounted | A binary [Semaphore] for synchronization of multiple [Thread]s. | 0 | 3 | 0 | 0 |
| NativeMenu | Object | A server interface for OS native menus. | 0 | 69 | 0 | 11 |
| NavigationAgent2D | Node | A 2D agent used to pathfind to a position while avoiding obstacles. | 30 | 20 | 6 | 0 |
| NavigationAgent3D | Node | A 3D agent used to pathfind to a position while avoiding obstacles. | 33 | 20 | 6 | 0 |
| NavigationLink2D | Node2D | A link between two positions on [NavigationRegion2D]s that agents can be routed through. | 7 | 9 | 0 | 0 |
| NavigationLink3D | Node3D | A link between two positions on [NavigationRegion3D]s that agents can be routed through. | 7 | 9 | 0 | 0 |
| NavigationMesh | Resource | A navigation mesh that defines traversable areas and obstacles. | 24 | 10 | 0 | 12 |
| NavigationMeshGenerator | Object | Helper class for creating and clearing navigation meshes. | 0 | 4 | 0 | 0 |
| NavigationMeshSourceGeometryData2D | Resource | Container for parsed source geometry data used in navigation mesh baking. | 0 | 16 | 0 | 0 |
| NavigationMeshSourceGeometryData3D | Resource | Container for parsed source geometry data used in navigation mesh baking. | 0 | 16 | 0 | 0 |
| NavigationObstacle2D | Node2D | 2D obstacle used to affect navigation mesh baking or constrain velocities of avoidance controlled agents. | 7 | 5 | 0 | 0 |
| NavigationObstacle3D | Node3D | 3D obstacle used to affect navigation mesh baking or constrain velocities of avoidance controlled agents. | 9 | 5 | 0 | 0 |
| NavigationPathQueryParameters2D | RefCounted | Provides parameters for 2D navigation path queries. | 15 | 0 | 0 | 9 |
| NavigationPathQueryParameters3D | RefCounted | Provides parameters for 3D navigation path queries. | 15 | 0 | 0 | 9 |
| NavigationPathQueryResult2D | RefCounted | Represents the result of a 2D pathfinding query. | 5 | 1 | 0 | 2 |
| NavigationPathQueryResult3D | RefCounted | Represents the result of a 3D pathfinding query. | 5 | 1 | 0 | 2 |
| NavigationPolygon | Resource | A 2D navigation mesh that describes a traversable surface for pathfinding. | 10 | 18 | 0 | 11 |
| NavigationRegion2D | Node2D | A traversable 2D region that [NavigationAgent2D]s can use for pathfinding. | 6 | 9 | 2 | 0 |
| NavigationRegion3D | Node3D | A traversable 3D region that [NavigationAgent3D]s can use for pathfinding. | 6 | 9 | 2 | 0 |
| NavigationServer2D | Object | A server interface for low-level 2D navigation access. | 0 | 137 | 3 | 10 |
| NavigationServer2DManager | Object | A singleton for managing [NavigationServer2D] implementations. | 0 | 2 | 0 | 0 |
| NavigationServer3D | Object | A server interface for low-level 3D navigation access. | 0 | 154 | 3 | 10 |
| NavigationServer3DManager | Object | A singleton for managing [NavigationServer3D] implementations. | 0 | 2 | 0 | 0 |
| NinePatchRect | Control | A control that displays a texture by keeping its corners intact, but tiling its edges and center. | 10 | 2 | 1 | 3 |
| Node | Object | Base class for all scene objects. | 14 | 106 | 11 | 75 |
| Node2D | CanvasItem | A 2D game object, inherited by all 2D-related nodes. Has a position, rotation, scale, and skew. | 12 | 11 | 0 | 0 |
| Node3D | Node | Base object in 3D space, inherited by all 3D nodes. | 17 | 37 | 1 | 8 |
| Node3DGizmo | RefCounted | Abstract class to expose editor gizmos for [Node3D]. | 0 | 0 | 0 | 0 |
| NodePath | — | A pre-parsed scene tree path. | 0 | 11 | 0 | 0 |
| ORMMaterial3D | BaseMaterial3D | A PBR (Physically Based Rendering) material to be used on 3D objects. Uses an ORM texture. | 0 | 0 | 0 | 0 |
| OS | Object | Provides access to common operating system functionalities. | 3 | 77 | 0 | 17 |
| Object | — | Base class for all other classes in the engine. | 0 | 62 | 2 | 8 |
| Occluder3D | Resource | Occluder shape resource for use with occlusion culling in [OccluderInstance3D]. | 0 | 2 | 0 | 0 |
| OccluderInstance3D | VisualInstance3D | Provides occlusion culling for 3D nodes, which improves performance in closed areas. | 3 | 2 | 0 | 0 |
| OccluderPolygon2D | Resource | Defines a 2D polygon for LightOccluder2D. | 3 | 0 | 0 | 3 |
| OmniLight3D | Light3D | Omnidirectional light, such as a light bulb or a candle. | 5 | 0 | 0 | 2 |
| OptimizedTranslation | Translation | An optimized translation. | 0 | 1 | 0 | 0 |
| OptionButton | Button | A button that brings up a dropdown with selectable options when pressed. | 16 | 29 | 2 | 0 |
| PCKPacker | RefCounted | Creates packages that can be loaded into a running project. | 0 | 5 | 0 | 0 |
| PackedByteArray | — | A packed array of bytes. | 0 | 69 | 0 | 0 |
| PackedColorArray | — | A packed array of [Color]s. | 0 | 23 | 0 | 0 |
| PackedDataContainer | Resource | Efficiently packs and serializes [Array] or [Dictionary]. | 0 | 2 | 0 | 0 |
| PackedDataContainerRef | RefCounted | An internal class used by [PackedDataContainer] to pack nested arrays and dictionaries. | 0 | 1 | 0 | 0 |
| PackedFloat32Array | — | A packed array of 32-bit floating-point values. | 0 | 23 | 0 | 0 |
| PackedFloat64Array | — | A packed array of 64-bit floating-point values. | 0 | 23 | 0 | 0 |
| PackedInt32Array | — | A packed array of 32-bit integers. | 0 | 23 | 0 | 0 |
| PackedInt64Array | — | A packed array of 64-bit integers. | 0 | 23 | 0 | 0 |
| PackedScene | Resource | An abstraction of a serialized scene. | 0 | 4 | 0 | 4 |
| PackedStringArray | — | A packed array of [String]s. | 0 | 23 | 0 | 0 |
| PackedVector2Array | — | A packed array of [Vector2]s. | 0 | 23 | 0 | 0 |
| PackedVector3Array | — | A packed array of [Vector3]s. | 0 | 23 | 0 | 0 |
| PackedVector4Array | — | A packed array of [Vector4]s. | 0 | 23 | 0 | 0 |
| PacketPeer | RefCounted | Abstraction and base class for packet-based protocols. | 1 | 6 | 0 | 0 |
| PacketPeerDTLS | PacketPeer | DTLS packet peer. | 0 | 4 | 0 | 5 |
| PacketPeerExtension | PacketPeer |  | 0 | 4 | 0 | 0 |
| PacketPeerStream | PacketPeer | Wrapper to use a PacketPeer over a StreamPeer. | 3 | 0 | 0 | 0 |
| PacketPeerUDP | PacketPeer | UDP packet peer. | 0 | 13 | 0 | 0 |
| Panel | Control | A GUI control that displays a [StyleBox]. | 0 | 0 | 0 | 0 |
| PanelContainer | Container | A container that keeps its child controls within the area of a [StyleBox]. | 1 | 0 | 0 | 0 |
| PanoramaSkyMaterial | Material | A material that provides a special texture to a [Sky], usually an HDR panorama. | 3 | 0 | 0 | 0 |
| Parallax2D | Node2D | A node used to create a parallax scrolling background. | 11 | 0 | 0 | 0 |
| ParallaxBackground | CanvasLayer | A node used to create a parallax scrolling background. | 7 | 0 | 0 | 0 |
| ParallaxLayer | Node2D | A parallax scrolling layer to be used with [ParallaxBackground]. | 4 | 0 | 0 | 0 |
| ParticleProcessMaterial | Material | Holds a particle configuration for [GPUParticles2D] or [GPUParticles3D] nodes. | 107 | 10 | 1 | 43 |
| Path2D | Node2D | Contains a [Curve2D] path for [PathFollow2D] nodes to follow. | 1 | 0 | 0 | 0 |
| Path3D | Node3D | Contains a [Curve3D] path for [PathFollow3D] nodes to follow. | 2 | 0 | 2 | 0 |
| PathFollow2D | Node2D | Point sampler for a [Path2D]. | 7 | 0 | 0 | 0 |
| PathFollow3D | Node3D | Point sampler for a [Path3D]. | 9 | 1 | 0 | 5 |
| Performance | Object | Exposes performance-related data. | 0 | 8 | 0 | 64 |
| PhysicalBone2D | RigidBody2D | A [RigidBody2D]-derived node used to make [Bone2D]s in a [Skeleton2D] react to physics. | 5 | 2 | 0 | 0 |
| PhysicalBone3D | PhysicsBody3D | A physics body used to make bones in a [Skeleton3D] react to physics. | 16 | 6 | 0 | 8 |
| PhysicalBoneSimulator3D | SkeletonModifier3D | Node that can be the parent of [PhysicalBone3D] and can apply the simulation results to [Skeleton3D]. | 0 | 5 | 0 | 0 |
| PhysicalSkyMaterial | Material | A material that defines a sky for a [Sky] resource by a set of physical properties. | 11 | 0 | 0 | 0 |
| PhysicsBody2D | CollisionObject2D | Abstract base class for 2D game objects affected by physics. | 1 | 6 | 0 | 0 |
| PhysicsBody3D | CollisionObject3D | Abstract base class for 3D game objects affected by physics. | 6 | 8 | 0 | 0 |
| PhysicsDirectBodyState2D | Object | Provides direct access to a physics body in the [PhysicsServer2D]. | 14 | 28 | 0 | 0 |
| PhysicsDirectBodyState2DExtension | PhysicsDirectBodyState2D | Provides virtual methods that can be overridden to create custom [PhysicsDirectBodyState2D] implementations. | 0 | 48 | 0 | 0 |
| PhysicsDirectBodyState3D | Object | Provides direct access to a physics body in the [PhysicsServer3D]. | 16 | 28 | 0 | 0 |
| PhysicsDirectBodyState3DExtension | PhysicsDirectBodyState3D | Provides virtual methods that can be overridden to create custom [PhysicsDirectBodyState3D] implementations. | 0 | 50 | 0 | 0 |
| PhysicsDirectSpaceState2D | Object | Provides direct access to a physics space in the [PhysicsServer2D]. | 0 | 6 | 0 | 0 |
| PhysicsDirectSpaceState2DExtension | PhysicsDirectSpaceState2D | Provides virtual methods that can be overridden to create custom [PhysicsDirectSpaceState2D] implementations. | 0 | 7 | 0 | 0 |
| PhysicsDirectSpaceState3D | Object | Provides direct access to a physics space in the [PhysicsServer3D]. | 0 | 6 | 0 | 0 |
| PhysicsDirectSpaceState3DExtension | PhysicsDirectSpaceState3D | Provides virtual methods that can be overridden to create custom [PhysicsDirectSpaceState3D] implementations. | 0 | 8 | 0 | 0 |
| PhysicsMaterial | Resource | Holds physics-related properties of a surface, namely its roughness and bounciness. | 4 | 0 | 0 | 0 |
| PhysicsPointQueryParameters2D | RefCounted | Provides parameters for [method PhysicsDirectSpaceState2D.intersect_point]. | 6 | 0 | 0 | 0 |
| PhysicsPointQueryParameters3D | RefCounted | Provides parameters for [method PhysicsDirectSpaceState3D.intersect_point]. | 5 | 0 | 0 | 0 |
| PhysicsRayQueryParameters2D | RefCounted | Provides parameters for [method PhysicsDirectSpaceState2D.intersect_ray]. | 7 | 1 | 0 | 0 |
| PhysicsRayQueryParameters3D | RefCounted | Provides parameters for [method PhysicsDirectSpaceState3D.intersect_ray]. | 8 | 1 | 0 | 0 |
| PhysicsServer2D | Object | A server interface for low-level 2D physics access. | 0 | 119 | 0 | 79 |
| PhysicsServer2DExtension | PhysicsServer2D | Provides virtual methods that can be overridden to create custom [PhysicsServer2D] implementations. | 0 | 140 | 0 | 0 |
| PhysicsServer2DManager | Object | A singleton for managing [PhysicsServer2D] implementations. | 0 | 2 | 0 | 0 |
| PhysicsServer3D | Object | A server interface for low-level 3D physics access. | 0 | 175 | 0 | 148 |
| PhysicsServer3DExtension | PhysicsServer3D | Provides virtual methods that can be overridden to create custom [PhysicsServer3D] implementations. | 0 | 196 | 0 | 0 |
| PhysicsServer3DManager | Object | A singleton for managing [PhysicsServer3D] implementations. | 0 | 2 | 0 | 0 |
| PhysicsServer3DRenderingServerHandler | Object | A class used to provide [method PhysicsServer3DExtension._soft_body_update_rendering_server] with a rendering  | 0 | 6 | 0 | 0 |
| PhysicsShapeQueryParameters2D | RefCounted | Provides parameters for [PhysicsDirectSpaceState2D]'s methods. | 9 | 0 | 0 | 0 |
| PhysicsShapeQueryParameters3D | RefCounted | Provides parameters for [PhysicsDirectSpaceState3D]'s methods. | 9 | 0 | 0 | 0 |
| PhysicsTestMotionParameters2D | RefCounted | Provides parameters for [method PhysicsServer2D.body_test_motion]. | 7 | 0 | 0 | 0 |
| PhysicsTestMotionParameters3D | RefCounted | Provides parameters for [method PhysicsServer3D.body_test_motion]. | 8 | 0 | 0 | 0 |
| PhysicsTestMotionResult2D | RefCounted | Describes the motion and collision result from [method PhysicsServer2D.body_test_motion]. | 0 | 13 | 0 | 0 |
| PhysicsTestMotionResult3D | RefCounted | Describes the motion and collision result from [method PhysicsServer3D.body_test_motion]. | 0 | 14 | 0 | 0 |
| PinJoint2D | Joint2D | A physics joint that attaches two 2D physics bodies at a single point, allowing them to freely rotate. | 6 | 0 | 0 | 0 |
| PinJoint3D | Joint3D | A physics joint that attaches two 3D physics bodies at a single point, allowing them to freely rotate. | 3 | 2 | 0 | 3 |
| PlaceholderCubemap | PlaceholderTextureLayered | A [Cubemap] without image data. | 0 | 0 | 0 | 0 |
| PlaceholderCubemapArray | PlaceholderTextureLayered | A [CubemapArray] without image data. | 0 | 0 | 0 | 0 |
| PlaceholderMaterial | Material | Placeholder class for a material. | 0 | 0 | 0 | 0 |
| PlaceholderMesh | Mesh | Placeholder class for a mesh. | 1 | 0 | 0 | 0 |
| PlaceholderTexture2D | Texture2D | Placeholder class for a 2-dimensional texture. | 2 | 0 | 0 | 0 |
| PlaceholderTexture2DArray | PlaceholderTextureLayered | Placeholder class for a 2-dimensional texture array. | 0 | 0 | 0 | 0 |
| PlaceholderTexture3D | Texture3D | Placeholder class for a 3-dimensional texture. | 1 | 0 | 0 | 0 |
| PlaceholderTextureLayered | TextureLayered | Placeholder class for a 2-dimensional texture array. | 2 | 0 | 0 | 0 |
| Plane | — | A plane in Hessian normal form. | 5 | 11 | 0 | 3 |
| PlaneMesh | PrimitiveMesh | Class representing a planar [PrimitiveMesh]. | 5 | 0 | 0 | 3 |
| PointLight2D | Light2D | Positional 2D light source. | 4 | 0 | 0 | 0 |
| PointMesh | PrimitiveMesh | Mesh with a single point primitive. | 0 | 0 | 0 | 0 |
| Polygon2D | Node2D | A 2D polygon. | 15 | 8 | 0 | 0 |
| PolygonOccluder3D | Occluder3D | Flat 2D polygon shape for use with occlusion culling in [OccluderInstance3D]. | 1 | 0 | 0 | 0 |
| PolygonPathFinder | Resource |  | 0 | 8 | 0 | 0 |
| Popup | Window | Base class for contextual windows and panels with fixed position. | 9 | 0 | 1 | 0 |
| PopupMenu | Popup | A modal window used to display a list of options. | 25 | 74 | 4 | 0 |
| PopupPanel | Popup | A popup with a panel background. | 4 | 0 | 0 | 0 |
| PortableCompressedTexture2D | Texture2D | Provides a compressed texture for disk and/or VRAM in a way that is portable. | 3 | 5 | 0 | 7 |
| PrimitiveMesh | Mesh | Base class for all primitive meshes. Handles applying a [Material] to a primitive mesh. | 5 | 3 | 0 | 0 |
| PrismMesh | PrimitiveMesh | Class representing a prism-shaped [PrimitiveMesh]. | 5 | 0 | 0 | 0 |
| ProceduralSkyMaterial | Material | A material that defines a simple sky for a [Sky] resource. | 14 | 0 | 0 | 0 |
| ProgressBar | Range | A control used for visual representation of a percentage. | 4 | 0 | 0 | 4 |
| ProjectSettings | Object | Stores globally-accessible variables. | 941 | 21 | 1 | 0 |
| Projection | — | A 4×4 matrix for 3D projective transformations. | 4 | 26 | 0 | 8 |
| PropertyTweener | Tweener | Interpolates an [Object]'s property over time. | 0 | 7 | 0 | 0 |
| QuadMesh | PlaneMesh | Class representing a square mesh facing the camera. | 2 | 0 | 0 | 0 |
| QuadOccluder3D | Occluder3D | Flat plane shape for use with occlusion culling in [OccluderInstance3D]. | 1 | 0 | 0 | 0 |
| Quaternion | — | A unit quaternion used for representing 3D rotations. | 4 | 19 | 0 | 1 |
| RDAccelerationStructureGeometry | RefCounted | Acceleration structure geometry (used by [RenderingDevice]). | 9 | 0 | 0 | 0 |
| RDAccelerationStructureInstance | RefCounted | Acceleration structure instance (used by [RenderingDevice]). | 6 | 0 | 0 | 0 |
| RDAttachmentFormat | RefCounted | Attachment format (used by [RenderingDevice]). | 3 | 0 | 0 | 0 |
| RDFramebufferPass | RefCounted | Framebuffer pass attachment description (used by [RenderingDevice]). | 5 | 0 | 0 | 1 |
| RDHitGroup | RefCounted | Hit group (used by [RenderingDevice]). | 3 | 0 | 0 | 0 |
| RDPipelineColorBlendState | RefCounted | Pipeline color blend state (used by [RenderingDevice]). | 4 | 0 | 0 | 0 |
| RDPipelineColorBlendStateAttachment | RefCounted | Pipeline color blend state attachment (used by [RenderingDevice]). | 11 | 1 | 0 | 0 |
| RDPipelineDepthStencilState | RefCounted | Pipeline depth/stencil state (used by [RenderingDevice]). | 21 | 0 | 0 | 0 |
| RDPipelineMultisampleState | RefCounted | Pipeline multisample state (used by [RenderingDevice]). | 6 | 0 | 0 | 0 |
| RDPipelineRasterizationState | RefCounted | Pipeline rasterization state (used by [RenderingDevice]). | 11 | 0 | 0 | 0 |
| RDPipelineShader | RefCounted | Pipeline shader (used by [RenderingDevice]). | 2 | 0 | 0 | 0 |
| RDPipelineSpecializationConstant | RefCounted | Pipeline specialization constant (used by [RenderingDevice]). | 2 | 0 | 0 | 0 |
| RDSamplerState | RefCounted | Sampler state (used by [RenderingDevice]). | 15 | 0 | 0 | 0 |
| RDShaderFile | Resource | Compiled shader file in SPIR-V form (used by [RenderingDevice]). Not to be confused with Godot's own [Shader]. | 1 | 3 | 0 | 0 |
| RDShaderSPIRV | Resource | SPIR-V intermediate representation as part of an [RDShaderFile] (used by [RenderingDevice]). | 20 | 4 | 0 | 0 |
| RDShaderSource | RefCounted | Shader source code (used by [RenderingDevice]). | 11 | 2 | 0 | 0 |
| RDTextureFormat | RefCounted | Texture format (used by [RenderingDevice]). | 11 | 2 | 0 | 0 |
| RDTextureView | RefCounted | Texture view (used by [RenderingDevice]). | 5 | 0 | 0 | 0 |
| RDUniform | RefCounted | Shader uniform (used by [RenderingDevice]). | 2 | 3 | 0 | 0 |
| RDVertexAttribute | RefCounted | Vertex attribute (used by [RenderingDevice]). | 6 | 0 | 0 | 0 |
| RID | — | A handle for a [Resource]'s unique identifier. | 0 | 2 | 0 | 0 |
| RandomNumberGenerator | RefCounted | Provides methods for generating pseudo-random numbers. | 2 | 7 | 0 | 0 |
| Range | Control | Abstract base class for controls that represent a number within a range. | 11 | 4 | 2 | 0 |
| RayCast2D | Node2D | A ray in 2D space, used to find the first collision object it intersects. | 7 | 14 | 0 | 0 |
| RayCast3D | Node3D | A ray in 3D space, used to find the first collision object it intersects. | 10 | 15 | 0 | 0 |
| Rect2 | — | A 2D axis-aligned bounding box using floating-point coordinates. | 3 | 16 | 0 | 0 |
| Rect2i | — | A 2D axis-aligned bounding box using integer coordinates. | 3 | 13 | 0 | 0 |
| RectangleShape2D | Shape2D | A 2D rectangle shape used for physics collision. | 1 | 0 | 0 | 0 |
| RefCounted | Object | Base class for reference-counted objects. | 0 | 4 | 0 | 0 |
| ReferenceRect | Control | A rectangular box for designing UIs. | 3 | 0 | 0 | 0 |
| ReflectionProbe | VisualInstance3D | Captures its surroundings to create fast, accurate reflections from a given point. | 15 | 0 | 0 | 5 |
| RemoteTransform2D | Node2D | RemoteTransform2D pushes its own [Transform2D] to another [Node2D] derived node in the scene. | 5 | 1 | 0 | 0 |
| RemoteTransform3D | Node3D | RemoteTransform3D pushes its own [Transform3D] to another [Node3D] derived Node in the scene. | 5 | 1 | 0 | 0 |
| RenderData | Object | Abstract render data object, holds frame data related to rendering a single frame of a viewport. | 0 | 4 | 0 | 0 |
| RenderDataExtension | RenderData | This class allows for a RenderData implementation to be made in GDExtension. | 0 | 4 | 0 | 0 |
| RenderDataRD | RenderData | Render data implementation for the RenderingDevice based renderers. | 0 | 0 | 0 | 0 |
| RenderSceneBuffers | RefCounted | Abstract scene buffers object, created for each viewport for which 3D rendering is done. | 0 | 1 | 0 | 0 |
| RenderSceneBuffersConfiguration | RefCounted | Configuration object used to setup a [RenderSceneBuffers] object. | 10 | 0 | 0 | 0 |
| RenderSceneBuffersExtension | RenderSceneBuffers | This class allows for a RenderSceneBuffer implementation to be made in GDExtension. | 0 | 5 | 0 | 0 |
| RenderSceneBuffersRD | RenderSceneBuffers | Render scene buffer implementation for the RenderingDevice based renderers. | 0 | 27 | 0 | 0 |
| RenderSceneData | Object | Abstract render data object, holds scene data related to rendering a single frame of a viewport. | 0 | 6 | 0 | 0 |
| RenderSceneDataExtension | RenderSceneData | This class allows for a RenderSceneData implementation to be made in GDExtension. | 0 | 6 | 0 | 0 |
| RenderSceneDataRD | RenderSceneData | Render scene data implementation for the RenderingDevice based renderers. | 0 | 0 | 0 | 0 |
| RenderingDevice | Object | Abstraction for working with modern low-level graphics APIs. | 0 | 135 | 0 | 574 |
| RenderingServer | Object | Server for anything visible. | 1 | 533 | 2 | 515 |
| Resource | RefCounted | Base class for serializable objects. | 4 | 18 | 2 | 3 |
| ResourceFormatLoader | RefCounted | Loads a specific resource type from a file. | 0 | 11 | 0 | 5 |
| ResourceFormatSaver | RefCounted | Saves a specific resource type to a file. | 0 | 5 | 0 | 0 |
| ResourceImporter | RefCounted | Base class for resource importers. | 0 | 1 | 0 | 2 |
| ResourceImporterBMFont | ResourceImporter | Imports a bitmap font in the BMFont ([code].fnt[/code]) format. | 3 | 0 | 0 | 0 |
| ResourceImporterBitMap | ResourceImporter | Imports a [BitMap] resource (2D array of boolean values). | 2 | 0 | 0 | 0 |
| ResourceImporterCSVTranslation | ResourceImporter | Imports comma-separated values as [Translation]s. | 4 | 0 | 0 | 0 |
| ResourceImporterDynamicFont | ResourceImporter | Imports a TTF, TTC, OTF, OTC, WOFF or WOFF2 font file for font rendering that adapts to any size. | 19 | 0 | 0 | 0 |
| ResourceImporterImage | ResourceImporter | Imports an image for use in scripting, with no rendering capabilities. | 0 | 0 | 0 | 0 |
| ResourceImporterImageFont | ResourceImporter | Imports a bitmap font where all glyphs have the same width and height. | 11 | 0 | 0 | 0 |
| ResourceImporterLayeredTexture | ResourceImporter | Imports a 3-dimensional texture ([Texture3D]), a [Texture2DArray], a [Cubemap] or a [CubemapArray]. | 10 | 0 | 0 | 0 |
| ResourceImporterOBJ | ResourceImporter | Imports an OBJ 3D model as an independent [Mesh] or scene. | 8 | 0 | 0 | 0 |
| ResourceImporterSVG | ResourceImporter | Imports an SVG file as an automatically scalable texture for use in UI elements and 2D rendering. | 6 | 0 | 0 | 0 |
| ResourceImporterScene | ResourceImporter | Imports a glTF, FBX, COLLADA, or Blender 3D scene. | 27 | 0 | 0 | 0 |
| ResourceImporterShaderFile | ResourceImporter | Imports native GLSL shaders (not Godot shaders) as an [RDShaderFile]. | 0 | 0 | 0 | 0 |
| ResourceImporterTexture | ResourceImporter | Imports an image for use in 2D or 3D rendering. | 26 | 0 | 0 | 0 |
| ResourceImporterTextureAtlas | ResourceImporter | Imports a collection of textures from a PNG image into an optimized [AtlasTexture] for 2D rendering. | 4 | 0 | 0 | 0 |
| ResourceImporterWAV | ResourceImporter | Imports a WAV audio file for playback. | 10 | 0 | 0 | 0 |
| ResourceLoader | Object | A singleton for loading resource files. | 0 | 14 | 0 | 9 |
| ResourcePreloader | Node | A node used to preload sub-resources inside a scene. | 0 | 6 | 0 | 0 |
| ResourceSaver | Object | A singleton for saving [Resource]s to the filesystem. | 0 | 6 | 0 | 8 |
| ResourceUID | Object | A singleton that manages the unique identifiers of all resources within a project. | 0 | 12 | 0 | 1 |
| RetargetModifier3D | SkeletonModifier3D | A modifier to transfer parent skeleton poses (or global poses) to child skeletons in model space with differen | 3 | 6 | 0 | 4 |
| RibbonTrailMesh | PrimitiveMesh | Represents a straight ribbon-shaped [PrimitiveMesh] with variable width. | 6 | 0 | 0 | 2 |
| RichTextEffect | Resource | A custom effect for a [RichTextLabel]. | 0 | 1 | 0 | 0 |
| RichTextLabel | Control | A control for displaying text that can contain different font styles, images, and basic formatting. | 32 | 78 | 4 | 21 |
| RigidBody2D | PhysicsBody2D | A 2D physics body that is moved by a physics simulation. | 23 | 13 | 5 | 9 |
| RigidBody3D | PhysicsBody3D | A 3D physics body that is moved by a physics simulation. | 23 | 14 | 5 | 6 |
| RootMotionView | VisualInstance3D | Editor-only helper for setting up root motion in [AnimationMixer]. | 5 | 0 | 0 | 0 |
| SceneState | RefCounted | Provides access to a scene file's information. | 0 | 23 | 0 | 4 |
| SceneTree | MainLoop | Manages the game loop via a hierarchy of nodes. | 11 | 26 | 9 | 4 |
| SceneTreeTimer | RefCounted | One-shot timer. | 1 | 0 | 1 | 0 |
| Script | Resource | A class stored as a resource. | 1 | 17 | 0 | 0 |
| ScriptBacktrace | RefCounted | A captured backtrace of a specific script language. | 0 | 16 | 0 | 0 |
| ScriptCreateDialog | ConfirmationDialog | Godot editor's popup dialog for creating new [Script] files. | 3 | 1 | 1 | 0 |
| ScriptEditor | PanelContainer | Godot editor's script editor. | 0 | 16 | 2 | 0 |
| ScriptEditorBase | VBoxContainer | Base editor for editing scripts in the [ScriptEditor]. | 0 | 2 | 10 | 0 |
| ScriptExtension | Script |  | 0 | 37 | 0 | 0 |
| ScriptLanguage | Object |  | 0 | 0 | 0 | 5 |
| ScriptLanguageExtension | ScriptLanguage |  | 0 | 60 | 0 | 28 |
| ScrollBar | Range | Abstract base class for scrollbars. | 3 | 0 | 1 | 0 |
| ScrollContainer | Container | A container used to provide scrollbars to a child control when needed. | 14 | 3 | 2 | 10 |
| SegmentShape2D | Shape2D | A 2D line segment shape used for physics collision. | 2 | 0 | 0 | 0 |
| Semaphore | RefCounted | A synchronization mechanism used to control access to a shared resource by [Thread]s. | 0 | 3 | 0 | 0 |
| SeparationRayShape2D | Shape2D | A 2D ray shape used for physics collision that tries to separate itself from any collider. | 2 | 0 | 0 | 0 |
| SeparationRayShape3D | Shape3D | A 3D ray shape used for physics collision that tries to separate itself from any collider. | 2 | 0 | 0 | 0 |
| Separator | Control | Abstract base class for separators. | 0 | 0 | 0 | 0 |
| Shader | Resource | A shader implemented in the Godot shading language. | 1 | 5 | 0 | 6 |
| ShaderGlobalsOverride | Node | A node used to override global shader parameters' values in a scene. | 0 | 0 | 0 | 0 |
| ShaderInclude | Resource | A snippet of shader code to be included in a [Shader] with [code]#include[/code]. | 1 | 0 | 0 | 0 |
| ShaderIncludeDB | Object | Internal database of built in shader include files. | 0 | 3 | 0 | 0 |
| ShaderMaterial | Material | A material defined by a custom [Shader] program and the values of its shader parameters. | 1 | 2 | 0 | 0 |
| Shape2D | Resource | Abstract base class for 2D shapes used for physics collision. | 1 | 6 | 0 | 0 |
| Shape3D | Resource | Abstract base class for 3D shapes used for physics collision. | 2 | 1 | 0 | 0 |
| ShapeCast2D | Node2D | A 2D shape that sweeps a region of space to detect [CollisionObject2D]s. | 10 | 17 | 0 | 0 |
| ShapeCast3D | Node3D | A 3D shape that sweeps a region of space to detect [CollisionObject3D]s. | 11 | 18 | 0 | 0 |
| Shortcut | Resource | A shortcut for binding input. | 1 | 3 | 0 | 0 |
| Signal | — | A built-in type representing a signal of an [Object]. | 0 | 10 | 0 | 0 |
| Skeleton2D | Node2D | The parent of a hierarchy of [Bone2D]s, used to create a 2D skeletal animation. | 0 | 8 | 1 | 0 |
| Skeleton3D | Node3D | A node containing a bone hierarchy, used to create a 3D skeletal animation. | 4 | 48 | 6 | 4 |
| SkeletonIK3D | SkeletonModifier3D | A node used to rotate all bones of a [Skeleton3D] bone chain a way that places the end bone at a desired 3D po | 10 | 4 | 0 | 0 |
| SkeletonModification2D | Resource | Base class for resources that operate on [Bone2D]s in a [Skeleton2D]. | 2 | 9 | 0 | 0 |
| SkeletonModification2DCCDIK | SkeletonModification2D | A modification that uses CCDIK to manipulate a series of bones to reach a target in 2D. | 3 | 14 | 0 | 0 |
| SkeletonModification2DFABRIK | SkeletonModification2D | A modification that uses FABRIK to manipulate a series of [Bone2D] nodes to reach a target. | 2 | 8 | 0 | 0 |
| SkeletonModification2DJiggle | SkeletonModification2D | A modification that jiggles [Bone2D] nodes as they move towards a target. | 7 | 21 | 0 | 0 |
| SkeletonModification2DLookAt | SkeletonModification2D | A modification that rotates a [Bone2D] node to look at a target. | 3 | 10 | 0 | 0 |
| SkeletonModification2DPhysicalBones | SkeletonModification2D | A modification that applies the transforms of [PhysicalBone2D] nodes to [Bone2D] nodes. | 1 | 5 | 0 | 0 |
| SkeletonModification2DStackHolder | SkeletonModification2D | A modification that holds and executes a [SkeletonModificationStack2D]. | 0 | 2 | 0 | 0 |
| SkeletonModification2DTwoBoneIK | SkeletonModification2D | A modification that rotates two bones using the law of cosines to reach the target. | 4 | 8 | 0 | 0 |
| SkeletonModificationStack2D | Resource | A resource that holds a stack of [SkeletonModification2D]s. | 3 | 9 | 0 | 0 |
| SkeletonModifier3D | Node3D | A node that may modify a Skeleton3D's bones. | 2 | 5 | 1 | 26 |
| SkeletonProfile | Resource | Base class for a profile of a virtual skeleton used as a target for retargeting. | 4 | 21 | 1 | 3 |
| SkeletonProfileHumanoid | SkeletonProfile | A humanoid [SkeletonProfile] preset. | 4 | 0 | 0 | 0 |
| Skin | Resource |  | 0 | 11 | 0 | 0 |
| SkinReference | RefCounted | A reference-counted holder object for a skeleton RID used in the [RenderingServer]. | 0 | 2 | 0 | 0 |
| Sky | Resource | Defines a 3D environment's background by using a [Material]. | 3 | 0 | 0 | 12 |
| Slider | Range | Abstract base class for sliders. | 7 | 0 | 2 | 4 |
| SliderJoint3D | Joint3D | A physics joint that restricts the movement of a 3D physics body along an axis relative to another physics bod | 22 | 2 | 0 | 23 |
| SocketServer | RefCounted | An abstract class for servers based on sockets. | 0 | 4 | 0 | 0 |
| SoftBody3D | MeshInstance3D | A deformable 3D physics mesh. | 12 | 15 | 0 | 2 |
| SphereMesh | PrimitiveMesh | Class representing a spherical [PrimitiveMesh]. | 5 | 0 | 0 | 0 |
| SphereOccluder3D | Occluder3D | Spherical shape for use with occlusion culling in [OccluderInstance3D]. | 1 | 0 | 0 | 0 |
| SphereShape3D | Shape3D | A 3D sphere shape used for physics collision. | 1 | 0 | 0 | 0 |
| SpinBox | Range | An input field for numbers. | 10 | 2 | 0 | 0 |
| SplineIK3D | ChainIK3D | A [SkeletonModifier3D] for aligning bones along a [Path3D]. | 1 | 8 | 0 | 0 |
| SplitContainer | Container | A container that arranges child controls horizontally or vertically and provides grabbers for adjusting the sp | 12 | 3 | 3 | 3 |
| SpotLight3D | Light3D | A spotlight, such as a reflector spotlight or a lantern. | 7 | 0 | 0 | 0 |
| SpringArm3D | Node3D | A 3D raycast that dynamically moves its children near the collision point. | 4 | 4 | 0 | 0 |
| SpringBoneCollision3D | Node3D | A base class of the collision that interacts with [SpringBoneSimulator3D]. | 4 | 1 | 0 | 0 |
| SpringBoneCollisionCapsule3D | SpringBoneCollision3D | A capsule shape collision that interacts with [SpringBoneSimulator3D]. | 4 | 0 | 0 | 0 |
| SpringBoneCollisionPlane3D | SpringBoneCollision3D | An infinite plane collision that interacts with [SpringBoneSimulator3D]. | 0 | 0 | 0 | 0 |
| SpringBoneCollisionSphere3D | SpringBoneCollision3D | A sphere shape collision that interacts with [SpringBoneSimulator3D]. | 2 | 0 | 0 | 0 |
| SpringBoneSimulator3D | SkeletonModifier3D | A [SkeletonModifier3D] to apply inertial wavering to bone chains. | 3 | 77 | 0 | 3 |
| Sprite2D | Node2D | General-purpose sprite node. | 12 | 2 | 2 | 0 |
| Sprite3D | SpriteBase3D | 2D sprite node in a 3D world. | 7 | 0 | 2 | 0 |
| SpriteBase3D | GeometryInstance3D | 2D sprite node in 3D environment. | 20 | 4 | 0 | 10 |
| SpriteFrames | Resource | Sprite frame library for AnimatedSprite2D and AnimatedSprite3D. | 0 | 20 | 0 | 3 |
| StandardMaterial3D | BaseMaterial3D | A PBR (Physically Based Rendering) material to be used on 3D objects. | 0 | 0 | 0 | 0 |
| StaticBody2D | PhysicsBody2D | A 2D physics body that can't be moved by external forces. When moved manually, it doesn't affect other bodies  | 3 | 0 | 0 | 0 |
| StaticBody3D | PhysicsBody3D | A 3D physics body that can't be moved by external forces. When moved manually, it doesn't affect other bodies  | 3 | 0 | 0 | 0 |
| StatusIndicator | Node | Application status indicator (aka notification area icon). 		[b]Note:[/b] Status indicator is implemented on m | 4 | 1 | 1 | 0 |
| StreamPeer | RefCounted | Abstract base class for interacting with streams. | 1 | 33 | 0 | 0 |
| StreamPeerBuffer | StreamPeer | A stream peer used to handle binary data streams. | 1 | 6 | 0 | 0 |
| StreamPeerExtension | StreamPeer |  | 0 | 5 | 0 | 0 |
| StreamPeerGZIP | StreamPeer | A stream peer that handles GZIP and deflate compression/decompression. | 0 | 4 | 0 | 0 |
| StreamPeerSocket | StreamPeer | Abstract base class for interacting with socket streams. | 0 | 3 | 0 | 4 |
| StreamPeerTCP | StreamPeerSocket | A stream peer that handles TCP connections. | 0 | 6 | 0 | 0 |
| StreamPeerTLS | StreamPeer | A stream peer that handles TLS connections. | 0 | 6 | 0 | 5 |
| StreamPeerUDS | StreamPeerSocket | A stream peer that handles UNIX Domain Socket (UDS) connections. | 0 | 3 | 0 | 0 |
| String | — | A built-in type for strings. | 0 | 116 | 0 | 0 |
| StringName | — | A built-in type for unique strings. | 0 | 110 | 0 | 0 |
| StyleBox | Resource | Abstract base class for defining stylized boxes for UI elements. | 4 | 13 | 0 | 0 |
| StyleBoxEmpty | StyleBox | An empty [StyleBox] (does not display anything). | 0 | 0 | 0 | 0 |
| StyleBoxFlat | StyleBox | A customizable [StyleBox] that doesn't use a texture. | 23 | 10 | 0 | 0 |
| StyleBoxLine | StyleBox | A [StyleBox] that displays a single line of a given color and thickness. | 5 | 0 | 0 | 0 |
| StyleBoxTexture | StyleBox | A texture-based nine-patch [StyleBox]. | 14 | 6 | 0 | 3 |
| SubViewport | Viewport | An interface to a game world that doesn't create a window or draw to the screen directly. | 6 | 0 | 0 | 8 |
| SubViewportContainer | Container | A container used for displaying the contents of a [SubViewport]. | 4 | 1 | 0 | 0 |
| SubtweenTweener | Tweener | Runs a [Tween] nested within another [Tween]. | 0 | 1 | 0 | 0 |
| SurfaceTool | RefCounted | Helper tool to create geometry. | 0 | 33 | 0 | 11 |
| SyntaxHighlighter | Resource | Base class for syntax highlighters. Provides syntax highlighting data to a [TextEdit]. | 0 | 7 | 0 | 0 |
| SystemFont | Font | A font loaded from a system font. Falls back to a default theme font if not implemented on the host OS. | 17 | 0 | 0 | 0 |
| TCPServer | SocketServer | A TCP server. | 0 | 3 | 0 | 0 |
| TLSOptions | RefCounted | TLS configuration for clients and servers. | 0 | 9 | 0 | 0 |
| TabBar | Control | A control that provides a horizontal bar with tabs. | 19 | 32 | 8 | 8 |
| TabContainer | Container | A container that creates a tab for each child control, displaying only the active tab's control. | 16 | 27 | 7 | 3 |
| TextEdit | Control | A multiline text editor. | 49 | 161 | 7 | 51 |
| TextLine | RefCounted | Holds a line of text. | 9 | 21 | 0 | 0 |
| TextMesh | PrimitiveMesh | Generate a [PrimitiveMesh] from the text. | 18 | 0 | 0 | 0 |
| TextParagraph | RefCounted | Holds a paragraph of text. | 13 | 36 | 0 | 0 |
| TextServer | RefCounted | A server interface for font management and text rendering. | 0 | 244 | 0 | 115 |
| TextServerDummy | TextServerExtension | A dummy text server that can't render text or manage fonts. | 0 | 0 | 0 | 0 |
| TextServerExtension | TextServer | Base class for custom [TextServer] implementations (plugins). | 0 | 249 | 0 | 0 |
| TextServerManager | Object | A singleton for managing [TextServer] implementations. | 0 | 8 | 2 | 0 |
| Texture | Resource | Base class for all texture types. | 0 | 0 | 0 | 0 |
| Texture2D | Texture | Texture for 2D and 3D. | 0 | 23 | 0 | 0 |
| Texture2DArray | ImageTextureLayered | A single texture resource which consists of multiple, separate images. Each image has the same dimensions and  | 0 | 1 | 0 | 0 |
| Texture2DArrayRD | TextureLayeredRD | Texture Array for 2D that is bound to a texture created on the [RenderingDevice]. | 0 | 0 | 0 | 0 |
| Texture2DRD | Texture2D | Texture for 2D that is bound to a texture created on the [RenderingDevice]. | 2 | 0 | 0 | 0 |
| Texture3D | Texture | Base class for 3-dimensional textures. | 0 | 13 | 0 | 0 |
| Texture3DRD | Texture3D | Texture for 3D that is bound to a texture created on the [RenderingDevice]. | 1 | 0 | 0 | 0 |
| TextureButton | BaseButton | Texture-based button. Supports Pressed, Hover, Disabled and Focused states. | 10 | 0 | 0 | 7 |
| TextureCubemapArrayRD | TextureLayeredRD | Texture Array for Cubemaps that is bound to a texture created on the [RenderingDevice]. | 0 | 0 | 0 | 0 |
| TextureCubemapRD | TextureLayeredRD | Texture for Cubemap that is bound to a texture created on the [RenderingDevice]. | 0 | 0 | 0 | 0 |
| TextureLayered | Texture | Base class for texture types which contain the data of multiple [Image]s. Each image is of the same size and f | 0 | 14 | 0 | 3 |
| TextureLayeredRD | TextureLayered | Abstract base class for layered texture RD types. | 1 | 0 | 0 | 0 |
| TextureProgressBar | Range | Texture-based progress bar. Useful for loading screens and life or stamina bars. | 19 | 2 | 0 | 9 |
| TextureRect | Control | A control that displays a texture. | 6 | 0 | 0 | 13 |
| Theme | Resource | A resource used for styling/skinning [Control]s and [Window]s. | 3 | 63 | 0 | 7 |
| ThemeDB | Object | A singleton that provides access to static information about [Theme] resources used by the engine and by your  | 5 | 2 | 1 | 0 |
| Thread | RefCounted | A unit of execution in a process. | 0 | 7 | 0 | 3 |
| TileData | Object | Settings for a single tile in a [TileSet]. | 11 | 32 | 1 | 0 |
| TileMap | Node2D | Node for 2D tile-based maps. | 5 | 53 | 1 | 3 |
| TileMapLayer | Node2D | Node for 2D tile-based maps. | 13 | 32 | 1 | 3 |
| TileMapPattern | Resource | Holds a pattern to be copied from or pasted into [TileMap]s. | 0 | 10 | 0 | 0 |
| TileSet | Resource | Tile library for tilemaps. | 5 | 80 | 0 | 31 |
| TileSetAtlasSource | TileSetSource | Exposes a 2D atlas texture as a set of tiles for a [TileSet] resource. | 5 | 31 | 0 | 6 |
| TileSetScenesCollectionSource | TileSetSource | Exposes a set of scenes as tiles for a [TileSet] resource. | 0 | 11 | 0 | 0 |
| TileSetSource | Resource | Exposes a set of tiles for a [TileSet] resource. | 0 | 6 | 0 | 0 |
| Time | Object | A singleton for working with time data. | 0 | 21 | 0 | 19 |
| Timer | Node | A countdown timer. | 7 | 3 | 1 | 2 |
| TorusMesh | PrimitiveMesh | Class representing a torus [PrimitiveMesh]. | 4 | 0 | 0 | 0 |
| TouchScreenButton | Node2D | Button for touch screen devices for gameplay use. | 9 | 1 | 2 | 2 |
| Transform2D | — | A 2×3 matrix representing a 2D transformation. | 3 | 21 | 0 | 3 |
| Transform3D | — | A 3×4 matrix representing a 3D transformation. | 2 | 13 | 0 | 4 |
| Translation | Resource | A language translation that maps a collection of strings to their individual translations. | 2 | 10 | 0 | 0 |
| TranslationDomain | RefCounted | A self-contained collection of [Translation] resources. | 10 | 13 | 0 | 0 |
| TranslationServer | Object | The server responsible for language translations. | 1 | 32 | 0 | 0 |
| Tree | Control | A control used to show a set of internal [TreeItem]s in a hierarchical structure. | 18 | 40 | 15 | 10 |
| TreeItem | Object | An internal control for a single item inside [Tree]. | 4 | 117 | 0 | 5 |
| TriangleMesh | RefCounted | Triangle geometry for efficient, physicsless intersection queries. | 0 | 4 | 0 | 0 |
| TubeTrailMesh | PrimitiveMesh | Represents a straight tube-shaped [PrimitiveMesh] with variable width. | 8 | 0 | 0 | 0 |
| Tween | RefCounted | Lightweight object used for general-purpose animation via script, using [Tweener]s. | 0 | 28 | 3 | 21 |
| Tweener | RefCounted | Abstract class for all Tweeners used by [Tween]. | 0 | 0 | 1 | 0 |
| TwoBoneIK3D | IKModifier3D | Rotation based intersection of two circles inverse kinematics solver. | 1 | 28 | 0 | 0 |
| UDPServer | RefCounted | Helper class to implement a UDP server. | 1 | 7 | 0 | 0 |
| UDSServer | SocketServer | A Unix Domain Socket (UDS) server. | 0 | 2 | 0 | 0 |
| UndoRedo | Object | Provides a high-level interface for implementing undo and redo operations. | 1 | 21 | 1 | 3 |
| UniformSetCacheRD | Object | Uniform set cache manager for Rendering Device based renderers. | 0 | 1 | 0 | 0 |
| VBoxContainer | BoxContainer | A container that arranges its child controls vertically. | 0 | 0 | 0 | 0 |
| VFlowContainer | FlowContainer | A container that arranges its child controls vertically and wraps them around at the borders. | 0 | 0 | 0 | 0 |
| VScrollBar | ScrollBar | A vertical scrollbar that goes from top (min) to bottom (max). | 2 | 0 | 0 | 0 |
| VSeparator | Separator | A vertical line used for separating other controls. | 0 | 0 | 0 | 0 |
| VSlider | Slider | A vertical slider that goes from bottom (min) to top (max). | 2 | 0 | 0 | 0 |
| VSplitContainer | SplitContainer | A container that splits two child controls vertically and provides a grabber for adjusting the split ratio. | 0 | 0 | 0 | 0 |
| Variant | — | The most important data type in Godot. | 0 | 0 | 0 | 0 |
| Vector2 | — | A 2D vector using floating-point coordinates. | 2 | 48 | 0 | 9 |
| Vector2i | — | A 2D vector using integer coordinates. | 2 | 17 | 0 | 10 |
| Vector3 | — | A 3D vector using floating-point coordinates. | 3 | 48 | 0 | 18 |
| Vector3i | — | A 3D vector using integer coordinates. | 3 | 16 | 0 | 13 |
| Vector4 | — | A 4D vector using floating-point coordinates. | 4 | 32 | 0 | 7 |
| Vector4i | — | A 4D vector using integer coordinates. | 4 | 16 | 0 | 8 |
| VehicleBody3D | RigidBody3D | A 3D physics body that simulates the behavior of a car. | 4 | 0 | 0 | 0 |
| VehicleWheel3D | Node3D | A 3D physics body for a [VehicleBody3D] that simulates the behavior of a wheel. | 15 | 6 | 0 | 0 |
| VideoStream | Resource | Base resource for video streams. | 1 | 1 | 0 | 0 |
| VideoStreamPlayback | Resource | Internal class used by [VideoStream] to manage playback state when played from a [VideoStreamPlayer]. | 0 | 14 | 0 | 0 |
| VideoStreamPlayer | Control | A control used for video playback. | 12 | 6 | 1 | 0 |
| Viewport | Node | Abstract base class for viewports. Encapsulates drawing and interaction with a game world. | 51 | 38 | 2 | 95 |
| ViewportTexture | Texture2D | Provides the content of a [Viewport] as a dynamic texture. | 1 | 0 | 0 | 0 |
| VirtualJoystick | Control | A virtual joystick control for touchscreen devices. | 11 | 0 | 5 | 5 |
| VisibleOnScreenEnabler2D | VisibleOnScreenNotifier2D | A rectangular region of 2D space that, when visible on screen, enables a target node. | 2 | 0 | 0 | 3 |
| VisibleOnScreenEnabler3D | VisibleOnScreenNotifier3D | A box-shaped region of 3D space that, when visible on screen, enables a target node. | 2 | 0 | 0 | 3 |
| VisibleOnScreenNotifier2D | Node2D | A rectangular region of 2D space that detects whether it is visible on screen. | 2 | 1 | 2 | 0 |
| VisibleOnScreenNotifier3D | VisualInstance3D | A box-shaped region of 3D space that detects whether it is visible on screen. | 1 | 1 | 2 | 0 |
| VisualInstance3D | Node3D | Parent of all visual 3D nodes. | 3 | 7 | 0 | 0 |
| VoxelGI | VisualInstance3D | Real-time global illumination (GI) probe. | 4 | 2 | 0 | 5 |
| VoxelGIData | Resource | Contains baked voxel global illumination data for use in a [VoxelGI] node. | 7 | 7 | 0 | 0 |
| WeakRef | RefCounted | Holds an [Object]. If the object is [RefCounted], it doesn't update the reference count. | 0 | 1 | 0 | 0 |
| Window | Viewport | Base class for all windows, dialogs, and popups. | 41 | 78 | 16 | 44 |
| WorkerThreadPool | Object | A singleton that allocates some [Thread]s on startup, used to offload tasks to these threads. | 0 | 9 | 0 | 0 |
| World2D | Resource | A resource that holds all components of a 2D world, such as a canvas and a physics space. | 4 | 0 | 0 | 0 |
| World3D | Resource | A resource that holds all components of a 3D world, such as a visual scenario and a physics space. | 7 | 0 | 0 | 0 |
| WorldBoundaryShape2D | Shape2D | A 2D world boundary (half-plane) shape used for physics collision. | 2 | 0 | 0 | 0 |
| WorldBoundaryShape3D | Shape3D | A 3D world boundary (half-space) shape used for physics collision. | 1 | 0 | 0 | 0 |
| WorldEnvironment | Node | Default environment properties for the entire scene (post-processing effects, lighting and background settings | 3 | 0 | 0 | 0 |
| X509Certificate | Resource | An X509 certificate (e.g. for TLS). | 0 | 4 | 0 | 0 |
| XMLParser | RefCounted | Provides a low-level interface for creating parsers for XML files. | 0 | 17 | 0 | 7 |
| XRAnchor3D | XRNode3D | An anchor point in AR space. | 0 | 2 | 0 | 0 |
| XRBodyModifier3D | SkeletonModifier3D | A node for driving body meshes from [XRBodyTracker] data. | 3 | 0 | 0 | 6 |
| XRBodyTracker | XRPositionalTracker | A tracked body in XR. | 3 | 4 | 0 | 95 |
| XRCamera3D | Camera3D | A camera node which automatically positions itself based on XR tracking data. | 1 | 0 | 0 | 0 |
| XRController3D | XRNode3D | A 3D node representing a spatially-tracked controller. | 0 | 5 | 5 | 0 |
| XRControllerTracker | XRPositionalTracker | A tracked controller. | 1 | 0 | 0 | 0 |
| XRFaceModifier3D | Node3D | A node for driving standard face meshes from [XRFaceTracker] weights. | 2 | 0 | 0 | 0 |
| XRFaceTracker | XRTracker | A tracked face. | 2 | 2 | 0 | 144 |
| XRHandModifier3D | SkeletonModifier3D | A node for driving hand meshes from [XRHandTracker] data. | 2 | 0 | 0 | 3 |
| XRHandTracker | XRPositionalTracker | A tracked hand in XR. | 4 | 10 | 0 | 38 |
| XRInterface | RefCounted | Base class for an XR interface implementation. | 4 | 22 | 1 | 24 |
| XRInterfaceExtension | XRInterface | Base class for XR interface extensions (plugins). | 0 | 37 | 0 | 0 |
| XRNode3D | Node3D | A 3D node that has its position automatically updated by the [XRServer]. | 4 | 4 | 1 | 0 |
| XROrigin3D | Node3D | The origin point in AR/VR. | 2 | 0 | 0 | 0 |
| XRPose | RefCounted | This object contains all data related to a pose on a tracked object. | 6 | 1 | 0 | 3 |
| XRPositionalTracker | XRTracker | A tracked object. | 2 | 6 | 7 | 4 |
| XRServer | Object | Server for AR and VR features. | 4 | 14 | 7 | 13 |
| XRTracker | RefCounted | A tracked object. | 3 | 0 | 0 | 0 |
| XRVRS | Object | Helper class for XR interfaces that generates VRS images. | 3 | 1 | 0 | 0 |
| bool | — | A built-in boolean type. | 0 | 0 | 0 | 0 |
| float | — | A built-in type for floating-point numbers. | 0 | 0 | 0 | 0 |
| int | — | A built-in type for integers. | 0 | 0 | 0 | 0 |

---

## 5. Node inventory — सभी 260 node types (parent-wise groups)

हर node apne **direct parent class** के under grouped है (source-verified)। Parent count बताता है कि उस family में कितने direct children nodes हैं:

**Node2D (37):** AnimatedSprite2D, AudioListener2D, AudioStreamPlayer2D, BackBufferCopy, Bone2D, CPUParticles2D, Camera2D, CanvasGroup, CanvasModulate, CollisionObject2D, CollisionPolygon2D, CollisionShape2D, GPUParticles2D, Joint2D, Light2D, LightOccluder2D, Line2D, Marker2D, MeshInstance2D, MultiMeshInstance2D, NavigationLink2D, NavigationObstacle2D, NavigationRegion2D, Parallax2D, ParallaxLayer, Path2D, PathFollow2D, Polygon2D, RayCast2D, RemoteTransform2D, ShapeCast2D, Skeleton2D, Sprite2D, TileMap, TileMapLayer, TouchScreenButton, VisibleOnScreenNotifier2D

**Node3D (28):** AudioListener3D, AudioStreamPlayer3D, BoneAttachment3D, Camera3D, CollisionObject3D, CollisionPolygon3D, CollisionShape3D, ImporterMeshInstance3D, Joint3D, LightmapProbe, Marker3D, NavigationLink3D, NavigationObstacle3D, NavigationRegion3D, Path3D, PathFollow3D, RayCast3D, RemoteTransform3D, ShapeCast3D, Skeleton3D, SkeletonModifier3D, SpringArm3D, SpringBoneCollision3D, VehicleWheel3D, VisualInstance3D, XRFaceModifier3D, XRNode3D, XROrigin3D

**Control (20):** BaseButton, ColorRect, Container, GraphEdit, ItemList, Label, LineEdit, MenuBar, NinePatchRect, Panel, Range, ReferenceRect, RichTextLabel, Separator, TabBar, TextEdit, TextureRect, Tree, VideoStreamPlayer, VirtualJoystick

**Node (19):** AnimationMixer, AudioStreamPlayer, CanvasItem, CanvasLayer, EditorFileSystem, EditorPlugin, EditorResourcePreview, HTTPRequest, InstancePlaceholder, MissingNode, NavigationAgent2D, NavigationAgent3D, Node3D, ResourcePreloader, ShaderGlobalsOverride, StatusIndicator, Timer, Viewport, WorldEnvironment

**Container (14):** AspectRatioContainer, BoxContainer, CenterContainer, EditorProperty, FlowContainer, FoldableContainer, GraphElement, GridContainer, MarginContainer, PanelContainer, ScrollContainer, SplitContainer, SubViewportContainer, TabContainer

**SkeletonModifier3D (12):** BoneConstraint3D, BoneTwistDisperser3D, IKModifier3D, LimitAngularVelocityModifier3D, LookAtModifier3D, ModifierBoneTarget3D, PhysicalBoneSimulator3D, RetargetModifier3D, SkeletonIK3D, SpringBoneSimulator3D, XRBodyModifier3D, XRHandModifier3D

**VisualInstance3D (12):** Decal, FogVolume, GPUParticlesAttractor3D, GPUParticlesCollision3D, GeometryInstance3D, Light3D, LightmapGI, OccluderInstance3D, ReflectionProbe, RootMotionView, VisibleOnScreenNotifier3D, VoxelGI

**GeometryInstance3D (6):** CPUParticles3D, GPUParticles3D, Label3D, MeshInstance3D, MultiMeshInstance3D, SpriteBase3D

**Range (6):** EditorSpinSlider, ProgressBar, ScrollBar, Slider, SpinBox, TextureProgressBar

**Button (5):** CheckBox, CheckButton, ColorPickerButton, MenuButton, OptionButton

**Joint3D (5):** ConeTwistJoint3D, Generic6DOFJoint3D, HingeJoint3D, PinJoint3D, SliderJoint3D

**Light3D (4):** AreaLight3D, DirectionalLight3D, OmniLight3D, SpotLight3D

**PhysicsBody3D (4):** CharacterBody3D, PhysicalBone3D, RigidBody3D, StaticBody3D

**GPUParticlesCollision3D (4):** GPUParticlesCollisionBox3D, GPUParticlesCollisionHeightField3D, GPUParticlesCollisionSDF3D, GPUParticlesCollisionSphere3D

**BoneConstraint3D (3):** AimModifier3D, ConvertTransformModifier3D, CopyTransformModifier3D

**BaseButton (3):** Button, LinkButton, TextureButton

**IterateIK3D (3):** CCDIK3D, FABRIK3D, JacobianIK3D

**PhysicsBody2D (3):** CharacterBody2D, RigidBody2D, StaticBody2D

**Joint2D (3):** DampedSpringJoint2D, GrooveJoint2D, PinJoint2D

**ConfirmationDialog (3):** EditorCommandPalette, FileDialog, ScriptCreateDialog

**GPUParticlesAttractor3D (3):** GPUParticlesAttractorBox3D, GPUParticlesAttractorSphere3D, GPUParticlesAttractorVectorField3D

**SpringBoneCollision3D (3):** SpringBoneCollisionCapsule3D, SpringBoneCollisionPlane3D, SpringBoneCollisionSphere3D

**Window (2):** AcceptDialog, Popup

**SpriteBase3D (2):** AnimatedSprite3D, Sprite3D

**AnimationMixer (2):** AnimationPlayer, AnimationTree

**CollisionObject2D (2):** Area2D, PhysicsBody2D

**CollisionObject3D (2):** Area3D, PhysicsBody3D

**IKModifier3D (2):** ChainIK3D, TwoBoneIK3D

**VBoxContainer (2):** ColorPicker, ScriptEditorBase

**CanvasItem (2):** Control, Node2D

**Light2D (2):** DirectionalLight2D, PointLight2D

**HBoxContainer (2):** EditorResourcePicker, EditorToaster

**GraphElement (2):** GraphFrame, GraphNode

**BoxContainer (2):** HBoxContainer, VBoxContainer

**FlowContainer (2):** HFlowContainer, VFlowContainer

**ScrollBar (2):** HScrollBar, VScrollBar

**Separator (2):** HSeparator, VSeparator

**Slider (2):** HSlider, VSlider

**SplitContainer (2):** HSplitContainer, VSplitContainer

**ChainIK3D (2):** IterateIK3D, SplineIK3D

**Popup (2):** PopupMenu, PopupPanel

**Viewport (2):** SubViewport, Window

**XRNode3D (2):** XRAnchor3D, XRController3D

**StaticBody2D (1):** AnimatableBody2D

**StaticBody3D (1):** AnimatableBody3D

**TextEdit (1):** CodeEdit

**AcceptDialog (1):** ConfirmationDialog

**MarginContainer (1):** EditorDock

**FileDialog (1):** EditorFileDialog

**ScrollContainer (1):** EditorInspector

**EditorResourcePicker (1):** EditorScriptPicker

**EditorDock (1):** FileSystemDock

**Object (1):** Node

**CanvasLayer (1):** ParallaxBackground

**RigidBody2D (1):** PhysicalBone2D

**PanelContainer (1):** ScriptEditor

**MeshInstance3D (1):** SoftBody3D

**RigidBody3D (1):** VehicleBody3D

**VisibleOnScreenNotifier2D (1):** VisibleOnScreenEnabler2D

**VisibleOnScreenNotifier3D (1):** VisibleOnScreenEnabler3D

**Camera3D (1):** XRCamera3D

---

## 6. Resource types — सभी 259 resource classes

Resources `Resource` से derive होते हैं (disk पर save/load हो सकते हैं, `preload()`/`load()` से मिलते हैं):

AnimatedTexture, Animation, AnimationLibrary, AnimationNode, AnimationNodeAdd2, AnimationNodeAdd3, AnimationNodeAnimation, AnimationNodeBlend2, AnimationNodeBlend3, AnimationNodeBlendSpace1D, AnimationNodeBlendSpace2D, AnimationNodeBlendTree, AnimationNodeExtension, AnimationNodeOneShot, AnimationNodeOutput, AnimationNodeStateMachine, AnimationNodeStateMachinePlayback, AnimationNodeStateMachineTransition, AnimationNodeSub2, AnimationNodeSync, AnimationNodeTimeScale, AnimationNodeTimeSeek, AnimationNodeTransition, AnimationRootNode, ArrayMesh, ArrayOccluder3D, AtlasTexture, AudioBusLayout, AudioEffect, AudioEffectAmplify, AudioEffectBandLimitFilter, AudioEffectBandPassFilter, AudioEffectCapture, AudioEffectChorus, AudioEffectCompressor, AudioEffectDelay, AudioEffectDistortion, AudioEffectEQ, AudioEffectEQ10, AudioEffectEQ21, AudioEffectEQ6, AudioEffectFilter, AudioEffectHardLimiter, AudioEffectHighPassFilter, AudioEffectHighShelfFilter, AudioEffectLimiter, AudioEffectLowPassFilter, AudioEffectLowShelfFilter, AudioEffectNotchFilter, AudioEffectPanner, AudioEffectPhaser, AudioEffectPitchShift, AudioEffectRecord, AudioEffectReverb, AudioEffectSpectrumAnalyzer, AudioEffectStereoEnhance, AudioStream, AudioStreamGenerator, AudioStreamMicrophone, AudioStreamPolyphonic, AudioStreamRandomizer, AudioStreamWAV, BaseMaterial3D, BitMap, BlitMaterial, BoneMap, BoxMesh, BoxOccluder3D, BoxShape3D, ButtonGroup, CameraAttributes, CameraAttributesPhysical, CameraAttributesPractical, CameraTexture, CanvasItemMaterial, CanvasTexture, CapsuleMesh, CapsuleShape2D, CapsuleShape3D, CircleShape2D, CodeHighlighter, ColorPalette, Compositor, CompositorEffect, CompressedCubemap, CompressedCubemapArray, CompressedTexture2D, CompressedTexture2DArray, CompressedTexture3D, CompressedTextureLayered, ConcavePolygonShape2D, ConcavePolygonShape3D, ConvexPolygonShape2D, ConvexPolygonShape3D, CryptoKey, Cubemap, CubemapArray, Curve, Curve2D, Curve3D, CurveTexture, CurveXYZTexture, CylinderMesh, CylinderShape3D, DPITexture, DrawableTexture2D, EditorNode3DGizmoPlugin, EditorSettings, EditorSyntaxHighlighter, Environment, ExternalTexture, FogMaterial, FoldableGroup, Font, FontFile, FontVariation, GDExtension, Gradient, GradientTexture1D, GradientTexture2D, HeightMapShape3D, Image, ImageTexture, ImageTexture3D, ImageTextureLayered, ImmediateMesh, ImporterMesh, InputEvent, InputEventAction, InputEventFromWindow, InputEventGesture, InputEventJoypadButton, InputEventJoypadMotion, InputEventKey, InputEventMIDI, InputEventMagnifyGesture, InputEventMouse, InputEventMouseButton, InputEventMouseMotion, InputEventPanGesture, InputEventScreenDrag, InputEventScreenTouch, InputEventShortcut, InputEventWithModifiers, JSON, JointLimitation3D, JointLimitationCone3D, LabelSettings, LightmapGIData, Material, Mesh, MeshLibrary, MeshTexture, MissingResource, MultiMesh, NavigationMesh, NavigationMeshSourceGeometryData2D, NavigationMeshSourceGeometryData3D, NavigationPolygon, ORMMaterial3D, Occluder3D, OccluderPolygon2D, OptimizedTranslation, PackedDataContainer, PackedScene, PanoramaSkyMaterial, ParticleProcessMaterial, PhysicalSkyMaterial, PhysicsMaterial, PlaceholderCubemap, PlaceholderCubemapArray, PlaceholderMaterial, PlaceholderMesh, PlaceholderTexture2D, PlaceholderTexture2DArray, PlaceholderTexture3D, PlaceholderTextureLayered, PlaneMesh, PointMesh, PolygonOccluder3D, PolygonPathFinder, PortableCompressedTexture2D, PrimitiveMesh, PrismMesh, ProceduralSkyMaterial, QuadMesh, QuadOccluder3D, RDShaderFile, RDShaderSPIRV, RectangleShape2D, RibbonTrailMesh, RichTextEffect, Script, ScriptExtension, SegmentShape2D, SeparationRayShape2D, SeparationRayShape3D, Shader, ShaderInclude, ShaderMaterial, Shape2D, Shape3D, Shortcut, SkeletonModification2D, SkeletonModification2DCCDIK, SkeletonModification2DFABRIK, SkeletonModification2DJiggle, SkeletonModification2DLookAt, SkeletonModification2DPhysicalBones, SkeletonModification2DStackHolder, SkeletonModification2DTwoBoneIK, SkeletonModificationStack2D, SkeletonProfile, SkeletonProfileHumanoid, Skin, Sky, SphereMesh, SphereOccluder3D, SphereShape3D, SpriteFrames, StandardMaterial3D, StyleBox, StyleBoxEmpty, StyleBoxFlat, StyleBoxLine, StyleBoxTexture, SyntaxHighlighter, SystemFont, TextMesh, Texture, Texture2D, Texture2DArray, Texture2DArrayRD, Texture2DRD, Texture3D, Texture3DRD, TextureCubemapArrayRD, TextureCubemapRD, TextureLayered, TextureLayeredRD, Theme, TileMapPattern, TileSet, TileSetAtlasSource, TileSetScenesCollectionSource, TileSetSource, TorusMesh, Translation, TubeTrailMesh, VideoStream, VideoStreamPlayback, ViewportTexture, VoxelGIData, World2D, World3D, WorldBoundaryShape2D, WorldBoundaryShape3D, X509Certificate

---

## 7. Project Settings — सभी engine-registered defaults

**Important:** ये 230 keys वे हैं जो engine source में `GLOBAL_DEF` से **default value के साथ registered** हैं (`project.godot` में ये लिखे जाते हैं जब बदले जाते हैं)। Input maps, autoloads, custom settings इसके **अलावा** project settings का हिस्सा हैं (arbitrary keys allowed)। UI में: Project → Project Settings।

### animation/ (3)
```
animation/warnings/check_angle_interpolation_type_conflicting
animation/warnings/check_invalid_skeleton_modifier_node_paths
animation/warnings/check_invalid_track_paths
```

### application/ (19)
```
application/boot_splash/bg_color
application/boot_splash/show_image
application/boot_splash/use_filter
application/config/auto_accept_quit
application/config/custom_user_dir_name
application/config/disable_project_settings_override
application/config/name
application/config/project_settings_override
application/config/quit_on_go_back
application/config/use_custom_user_dir
application/config/version
application/run/delta_smoothing
application/run/disable_stderr
application/run/disable_stdout
application/run/enable_alt_space_menu
application/run/load_shell_environment
application/run/low_processor_mode
application/run/main_loop_type
application/run/print_header
```

### audio/ (1)
```
audio/general/ios/mix_with_others
```

### collada/ (1)
```
collada/use_ambient
```

### debug/ (66)
```
debug/file_logging/enable_file_logging
debug/file_logging/enable_file_logging.pc
debug/file_logging/log_path
debug/gdscript/warnings/enable
debug/gdscript/warnings/renamed_in_godot_4_hint
debug/settings/crash_handler/message
debug/settings/crash_handler/message.editor
debug/settings/physics_interpolation/enable_warnings
debug/settings/stdout/print_fps
debug/settings/stdout/print_gpu_profile
debug/settings/stdout/verbose_stdout
debug/shader_language/warnings/
debug/shader_language/warnings/enable
debug/shader_language/warnings/treat_warnings_as_errors
debug/shapes/avoidance/2d/agents_radius_color
debug/shapes/avoidance/2d/enable_agents_radius
debug/shapes/avoidance/2d/enable_obstacles_radius
debug/shapes/avoidance/2d/enable_obstacles_static
debug/shapes/avoidance/2d/obstacles_radius_color
debug/shapes/avoidance/2d/obstacles_static_edge_pushin_color
debug/shapes/avoidance/2d/obstacles_static_edge_pushout_color
debug/shapes/avoidance/2d/obstacles_static_face_pushin_color
debug/shapes/avoidance/2d/obstacles_static_face_pushout_color
debug/shapes/avoidance/3d/agents_radius_color
debug/shapes/avoidance/3d/enable_agents_radius
debug/shapes/avoidance/3d/enable_obstacles_radius
debug/shapes/avoidance/3d/enable_obstacles_static
debug/shapes/avoidance/3d/obstacles_radius_color
debug/shapes/avoidance/3d/obstacles_static_edge_pushin_color
debug/shapes/avoidance/3d/obstacles_static_edge_pushout_color
debug/shapes/avoidance/3d/obstacles_static_face_pushin_color
debug/shapes/avoidance/3d/obstacles_static_face_pushout_color
debug/shapes/collision/contact_color
debug/shapes/collision/draw_2d_outlines
debug/shapes/collision/shape_color
debug/shapes/navigation/2d/agent_path_color
debug/shapes/navigation/2d/edge_connection_color
debug/shapes/navigation/2d/enable_agent_paths
debug/shapes/navigation/2d/enable_edge_connections
debug/shapes/navigation/2d/enable_edge_lines
debug/shapes/navigation/2d/enable_geometry_face_random_color
debug/shapes/navigation/2d/enable_link_connections
debug/shapes/navigation/2d/geometry_edge_color
debug/shapes/navigation/2d/geometry_edge_disabled_color
debug/shapes/navigation/2d/geometry_face_color
debug/shapes/navigation/2d/geometry_face_disabled_color
debug/shapes/navigation/2d/link_connection_color
debug/shapes/navigation/2d/link_connection_disabled_color
debug/shapes/navigation/3d/agent_path_color
debug/shapes/navigation/3d/edge_connection_color
debug/shapes/navigation/3d/enable_agent_paths
debug/shapes/navigation/3d/enable_agent_paths_xray
debug/shapes/navigation/3d/enable_edge_connections
debug/shapes/navigation/3d/enable_edge_connections_xray
debug/shapes/navigation/3d/enable_edge_lines
debug/shapes/navigation/3d/enable_edge_lines_xray
debug/shapes/navigation/3d/enable_geometry_face_random_color
debug/shapes/navigation/3d/enable_link_connections
debug/shapes/navigation/3d/enable_link_connections_xray
debug/shapes/navigation/3d/geometry_edge_color
debug/shapes/navigation/3d/geometry_edge_disabled_color
debug/shapes/navigation/3d/geometry_face_color
debug/shapes/navigation/3d/geometry_face_disabled_color
debug/shapes/navigation/3d/link_connection_color
debug/shapes/navigation/3d/link_connection_disabled_color
debug/shapes/paths/geometry_color
```

### display/ (23)
```
display/display_server/driver
display/mouse_cursor/custom_image_hotspot
display/mouse_cursor/tooltip_position_offset
display/window/dpi/allow_hidpi
display/window/energy_saving/keep_screen_on
display/window/frame_pacing/android/enable_frame_pacing
display/window/handheld/orientation
display/window/hdr/request_hdr_output
display/window/ios/allow_high_refresh_rate
display/window/ios/hide_home_indicator
display/window/ios/hide_status_bar
display/window/ios/suppress_ui_gesture
display/window/size/always_on_top
display/window/size/borderless
display/window/size/extend_to_title
display/window/size/maximize_disabled
display/window/size/minimize_disabled
display/window/size/no_focus
display/window/size/resizable
display/window/size/sharp_corners
display/window/size/transparent
display/window/subwindows/embed_subwindows
display/window/vsync/vsync_mode
```

### dotnet/ (2)
```
dotnet/project/assembly_name
dotnet/project/solution_directory
```

### editor/ (9)
```
editor/export/convert_text_resources_to_binary
editor/import/reimport_missing_imported_files
editor/import/use_multiple_threads
editor/movie_writer/disable_vsync
editor/movie_writer/movie_file
editor/naming/default_signal_callback_name
editor/naming/default_signal_callback_to_self_name
editor/version_control/autoload_on_startup
editor/version_control/plugin_name
```

### gui/ (5)
```
gui/common/default_scroll_deadzone
gui/common/drag_threshold
gui/common/snap_controls_to_pixels
gui/fonts/dynamic_fonts/use_oversampling
gui/timers/tooltip_delay_sec.editor_hint
```

### input_devices/ (8)
```
input_devices/buffering/agile_event_flushing
input_devices/compatibility/legacy_just_pressed_behavior
input_devices/pointing/android/disable_scroll_deadzone
input_devices/pointing/android/enable_long_press_as_right_click
input_devices/pointing/android/enable_pan_and_scale_gestures
input_devices/pointing/android/override_volume_buttons
input_devices/pointing/emulate_mouse_from_touch
input_devices/pointing/emulate_touch_from_mouse
```

### internationalization/ (13)
```
internationalization/locale/fallback
internationalization/locale/include_text_server_data
internationalization/locale/test
internationalization/pseudolocalization/double_vowels
internationalization/pseudolocalization/expansion_ratio
internationalization/pseudolocalization/fake_bidi
internationalization/pseudolocalization/override
internationalization/pseudolocalization/prefix
internationalization/pseudolocalization/replace_with_accents
internationalization/pseudolocalization/skip_placeholders
internationalization/pseudolocalization/suffix
internationalization/pseudolocalization/use_pseudolocalization
internationalization/rendering/root_node_auto_translate
```

### navigation/ (15)
```
navigation/2d/use_edge_connections
navigation/2d/warnings/navmesh_cell_size_mismatch
navigation/2d/warnings/navmesh_edge_merge_errors
navigation/3d/default_up
navigation/3d/use_edge_connections
navigation/3d/warnings/navmesh_cell_size_mismatch
navigation/3d/warnings/navmesh_edge_merge_errors
navigation/avoidance/thread_model/avoidance_use_high_priority_threads
navigation/avoidance/thread_model/avoidance_use_multiple_threads
navigation/baking/thread_model/baking_use_high_priority_threads
navigation/baking/thread_model/baking_use_multiple_threads
navigation/baking/use_crash_prevention_checks
navigation/pathfinding/max_threads
navigation/world/map_use_async_iterations
navigation/world/region_use_async_iterations
```

### network/ (1)
```
network/tls/enable_tls_v1.3
```

### physics/ (5)
```
physics/2d/run_on_separate_thread
physics/3d/physics_interpolation/scene_traversal
physics/3d/run_on_separate_thread
physics/common/enable_object_picking
physics/common/physics_interpolation
```

### rendering/ (36)
```
rendering/2d/snap/snap_2d_transforms_to_pixel
rendering/2d/snap/snap_2d_vertices_to_pixel
rendering/anti_aliasing/quality/use_debanding
rendering/anti_aliasing/quality/use_taa
rendering/anti_aliasing/screen_space_roughness_limiter/enabled
rendering/camera/depth_of_field/depth_of_field_use_jitter
rendering/driver/threads/thread_model
rendering/environment/defaults/default_clear_color
rendering/environment/glow/upscale_mode.mobile
rendering/environment/screen_space_reflection/half_size
rendering/environment/ssao/half_size
rendering/environment/ssil/half_size
rendering/global_illumination/gi/use_half_resolution
rendering/lightmapping/lightmap_gi/use_bicubic_filter
rendering/lights_and_shadows/directional_shadow/16_bits
rendering/lights_and_shadows/directional_shadow/size.mobile
rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile
rendering/lights_and_shadows/positional_shadow/atlas_16_bits
rendering/lights_and_shadows/positional_shadow/atlas_size.mobile
rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality.mobile
rendering/lights_and_shadows/tighter_shadow_caster_culling
rendering/occlusion_culling/use_occlusion_culling
rendering/reflections/sky_reflections/fast_filter_high_quality
rendering/reflections/sky_reflections/texture_array_reflections.mobile
rendering/shader_compiler/shader_cache/compress
rendering/shader_compiler/shader_cache/enabled
rendering/shader_compiler/shader_cache/strip_debug
rendering/shader_compiler/shader_cache/strip_debug.release
rendering/shader_compiler/shader_cache/use_zstd_compression
rendering/shading/overrides/force_lambert_over_burley
rendering/shading/overrides/force_lambert_over_burley.mobile
rendering/textures/lossless_compression/force_png
rendering/textures/vram_compression/cache_gpu_compressor
rendering/textures/vram_compression/compress_with_gpu
rendering/viewport/hdr_2d
rendering/viewport/transparent_background
```

### threading/ (2)
```
threading/worker_pool/low_priority_thread_ratio
threading/worker_pool/max_threads
```

### xr/ (21)
```
xr/openxr/binding_modifiers/analog_threshold
xr/openxr/extensions/frame_synthesis
xr/openxr/extensions/hand_tracking
xr/openxr/extensions/hand_tracking_controller_data_source
xr/openxr/extensions/hand_tracking_unobstructed_data_source
xr/openxr/extensions/render_model
xr/openxr/extensions/spatial_entity/enable_builtin_anchor_detection
xr/openxr/extensions/spatial_entity/enable_builtin_marker_tracking
xr/openxr/extensions/spatial_entity/enable_builtin_plane_detection
xr/openxr/extensions/spatial_entity/enable_marker_tracking
xr/openxr/extensions/spatial_entity/enable_persistent_anchors
xr/openxr/extensions/spatial_entity/enable_plane_tracking
xr/openxr/extensions/spatial_entity/enable_spatial_anchors
xr/openxr/extensions/spatial_entity/enabled
xr/openxr/extensions/user_presence
xr/openxr/foveation_dynamic
xr/openxr/foveation_eye_tracked
xr/openxr/foveation_with_subsampled_images
xr/openxr/in_editor
xr/openxr/startup_alert
xr/openxr/submit_depth_buffer
```

**Hidden/uncommon gems इनमें:** `debug/gdscript/...` (profiler switches), `rendering/...` के dozens रेयर options, `internationalization/...` (locale fallback), `xr/...` (21 keys), `navigation/...` (15), `input_devices/...` (8, incl. 4.7 का joypad-on-unfocused-window)।

---

## 8. Editor Settings — सभी 171 keys

UI में: Editor → Editor Settings। ये project नहीं, **user-specific** settings हैं (per-user config directory में save होती हैं)। Categories: asset_store (नया, 4.7), docks/*, editors/2d, editors/3d, editors/animation, editors/audio_buses, text_editor/*, filesystem/*, network/*, run/*, interface/*, shortcuts…

```
asset_store/available_urls
asset_store/use_threads
docks/filesystem/always_show_folders
docks/filesystem/ask_before_moving_files
docks/filesystem/automatically_open_created_scripts
docks/filesystem/other_file_extensions
docks/filesystem/textfile_extensions
docks/scene_tree/accessibility_warnings
docks/scene_tree/ask_before_deleting_related_animation_tracks
docks/scene_tree/ask_before_revoking_unique_name
docks/scene_tree/auto_expand_to_selected
docks/scene_tree/center_node_on_reparent
docks/scene_tree/hide_filtered_out_parents
docks/scene_tree/start_create_dialog_fully_expanded
editors/2d/bone_color1
editors/2d/bone_color2
editors/2d/bone_ik_color
editors/2d/bone_outline_color
editors/2d/bone_selected_color
editors/2d/grid_color
editors/2d/guides_color
editors/2d/locked_selection_rectangle_color
editors/2d/selection_rectangle_color
editors/2d/smart_snapping_line_color
editors/2d/use_integer_zoom_by_default
editors/2d/viewport_border_color
editors/3d/freelook/freelook_invert_y_axis
editors/3d/freelook/freelook_speed_zoom_link
editors/3d/grid_xy_plane
editors/3d/grid_xz_plane
editors/3d/grid_yz_plane
editors/3d/navigation/emulate_3_button_mouse
editors/3d/navigation/emulate_numpad
editors/3d/navigation/invert_x_axis
editors/3d/navigation/invert_y_axis
editors/3d/navigation/show_viewport_navigation_gizmo
editors/3d/navigation/show_viewport_rotation_gizmo
editors/3d/navigation/warped_mouse_panning
editors/3d_gizmos/gizmo_settings/bone_axis_length
editors/3d_gizmos/gizmo_settings/show_collision_shapes_only_when_selected
editors/animation/autorename_animation_tracks
editors/animation/confirm_insert_track
editors/animation/default_create_bezier_tracks
editors/animation/default_create_reset_tracks
editors/animation/default_fps_compatibility
editors/animation/insert_at_current_time
editors/animation/onion_layers_future_color
editors/animation/onion_layers_past_color
editors/bone_mapper/handle_colors/error
editors/bone_mapper/handle_colors/missing
editors/bone_mapper/handle_colors/set
editors/bone_mapper/handle_colors/unset
editors/panning/2d_editor_pan_speed
editors/panning/simple_panning
editors/panning/warped_mouse_panning
editors/polygon_editor/point_grab_radius
editors/polygon_editor/show_previous_outline
editors/shader_editor/behavior/files/restore_shaders_on_load
editors/tiles_editor/display_grid
editors/tiles_editor/grid_color
editors/tiles_editor/highlight_selected_layer
editors/visual_editors/category_colors/color_color
editors/visual_editors/category_colors/conditional_color
editors/visual_editors/category_colors/input_color
editors/visual_editors/category_colors/output_color
editors/visual_editors/category_colors/particle_color
editors/visual_editors/category_colors/scalar_color
editors/visual_editors/category_colors/special_color
editors/visual_editors/category_colors/textures_color
editors/visual_editors/category_colors/transform_color
editors/visual_editors/category_colors/utility_color
editors/visual_editors/category_colors/vector_color
editors/visual_editors/connection_colors/boolean_color
editors/visual_editors/connection_colors/sampler_color
editors/visual_editors/connection_colors/scalar_color
editors/visual_editors/connection_colors/transform_color
editors/visual_editors/connection_colors/vector2_color
editors/visual_editors/connection_colors/vector3_color
editors/visual_editors/connection_colors/vector4_color
export/ssh/scp
export/ssh/ssh
filesystem/file_dialog/show_hidden_files
filesystem/file_server/password
filesystem/file_server/port
filesystem/on_save/compress_binary_resources
filesystem/on_save/safe_save_on_backup_then_rename
filesystem/on_save/warn_on_saving_large_text_resources
filesystem/quick_open_dialog/enable_fuzzy_matching
filesystem/quick_open_dialog/include_addons
filesystem/quick_open_dialog/instant_preview
filesystem/quick_open_dialog/show_search_highlight
interface/editor/behavior/automatically_open_screenshots
interface/editor/behavior/save_each_scene_on_quit
interface/editor/behavior/separate_distraction_mode
interface/editor/display/keep_screen_on
interface/editor/fonts/code_font_custom_opentype_features
interface/editor/fonts/code_font_custom_variations
interface/editor/fonts/main_font_custom_opentype_features
interface/editor/input/mouse_extra_buttons_navigate_history
interface/editors/derive_script_globals_by_name
interface/inspector/resources_to_open_in_new_inspector
interface/scene_tabs/restore_scenes_on_load
interface/scene_tabs/show_script_button
interface/scene_tabs/show_thumbnail_on_hover
network/debug/remote_host
network/http_proxy/host
network/language_server/remote_host
run/auto_save/save_before_running
run/output/always_clear_output_on_play
run/platforms/linuxbsd/prefer_wayland
run/window_placement/rect_custom_position
text_editor/appearance/caret/caret_blink
text_editor/appearance/caret/highlight_all_occurrences
text_editor/appearance/caret/highlight_current_line
text_editor/appearance/drag_and_drop_info/show_drag_and_drop_info
text_editor/appearance/guidelines/show_line_length_guidelines
text_editor/appearance/gutters/highlight_type_safe_lines
text_editor/appearance/gutters/line_numbers_zero_padded
text_editor/appearance/gutters/show_info_gutter
text_editor/appearance/gutters/show_line_numbers
text_editor/appearance/lines/code_folding
text_editor/appearance/minimap/show_minimap
text_editor/appearance/whitespace/draw_spaces
text_editor/appearance/whitespace/draw_tabs
text_editor/behavior/documentation/enable_tooltips
text_editor/behavior/files/auto_reload_and_parse_scripts_on_save
text_editor/behavior/files/auto_reload_scripts_on_external_change
text_editor/behavior/files/autosave_interval_secs
text_editor/behavior/files/convert_indent_on_save
text_editor/behavior/files/drop_preload_resources_as_uid
text_editor/behavior/files/open_dominant_script_on_scene_change
text_editor/behavior/files/restore_scripts_on_load
text_editor/behavior/files/trim_final_newlines_on_save
text_editor/behavior/files/trim_trailing_whitespace_on_save
text_editor/behavior/general/empty_selection_clipboard
text_editor/behavior/indent/auto_indent
text_editor/behavior/indent/indent_wrapped_lines
text_editor/behavior/navigation/custom_word_separators
text_editor/behavior/navigation/drag_and_drop_selection
text_editor/behavior/navigation/move_caret_on_right_click
text_editor/behavior/navigation/open_script_when_connecting_signal_to_existing_method
text_editor/behavior/navigation/scroll_past_end_of_file
text_editor/behavior/navigation/smooth_scrolling
text_editor/behavior/navigation/stay_in_script_editor_on_node_selected
text_editor/behavior/navigation/use_custom_word_separators
text_editor/behavior/navigation/use_default_word_separators
text_editor/completion/add_node_path_literals
text_editor/completion/add_string_name_literals
text_editor/completion/add_type_hints
text_editor/completion/auto_brace_complete
text_editor/completion/code_complete_enabled
text_editor/completion/colorize_suggestions
text_editor/completion/complete_file_paths
text_editor/completion/put_callhint_tooltip_below_current_line
text_editor/completion/use_single_quotes
text_editor/external/exec_path
text_editor/external/use_external_editor
text_editor/help/show_help_index
text_editor/help/sort_functions_alphabetically
text_editor/script_list/group_help_pages
text_editor/script_list/highlight_scene_scripts
text_editor/script_list/script_temperature_enabled
text_editor/script_list/script_temperature_history_size
text_editor/script_list/show_members_overview
text_editor/script_list/sort_members_outline_alphabetically
text_editor/theme/highlighting/comment_markers/critical_list
text_editor/theme/highlighting/comment_markers/notice_list
text_editor/theme/highlighting/comment_markers/warning_list
version_control/ssh_private_key_path
version_control/ssh_public_key_path
version_control/username
```

---

## 9. Editor UI — screens, docks, panels, dialogs, tools

4.7 में editor का directory structure reorganized है (यही इस section का source है)। **हर editor tool अपनी source file से verified:**

### Docks (11): FileSystem dock (editor/file_system), Scene tree dock (scene_tree_do), Inspector dock, Import dock, History dock, Groups dock, Signals dock, Dock tab container, Editor dock manager, Groups editor, …
### Main screens: 2D, 3D, Script, AssetLib/Asset Store (4.7 rework), plus bottom panels — Output, Debugger, Audio, Animation, Debugger profilers (editor/editor_bottom_panel, editor/debugger/*)
### Dialogs (editor/gui — 21 files): create_dialog, directory_create_dialog, editor_about, credits_roll, editor_file_dialog, editor_dir_dialog, editor_quick_open_dialog, editor_spin_slider, editor_toaster, editor_validation_panel, editor_variant_type_selectors, editor_title_bar, editor_version_button, editor_zoom_widget, editor_object_selector, filter_line_edit, progress_dialog, touch_actions_panel, window_wrapper, code_edit…
### Debugger tools (editor/debugger): script editor debugger, debugger server, inspector, tree, plugin, node dock, expression evaluator, file server, performance profiler, visual profiler (4.7.2 में cursor fix), DAP (Debug Adapter Protocol, editor/debugger/debug_adapter — editor-pid/dap-port CLI)
### 2D node editors (editor/scene/2d): Camera2D, LightOccluder2D, Line2D, ParallaxBackground, GPUParticles2D, Path2D, Polygon2D, AbstractPolygon2D, ScenePaint2D (नया 4.7 Scene Paint tool), Skeleton2D, Sprite2D editors
### 3D node editors (editor/scene/3d): Node3D (gizmos समेत), MeshInstance3D, Mesh, MultiMesh, Skeleton3D, SkeletonIK3D, BoneMap, Path3D, Polygon3D, Particles3D, GPUParticlesCollision3D (SDF bake), LightmapGI (bake), OccluderInstance3D, VoxelGI (bake), RootMotionView, MeshLibrary (नया 4.7 editor), Camera3D, material conversion
### GUI/Control editors (editor/scene/gui): Control editor, theme editor + preview, stylebox editor, font config, margin container, virtual joystick editor
### Animation editors (editor/animation — 10): AnimationPlayer editor, AnimationTree + state machine editor, blend tree editor, BlendSpace1D/2D editors, bezier editor, track editor, animation library editor
### Script/shader editors: Script editor (editor/script — 9 files), shader editor (editor/shader — 9 files, नया 4.7 shader documentation viewer integration)
### Import tools (editor/import — 19 files): नीचे Section 10
### Inspector (editor/inspector — 17 files): property editors, EditorInspectorPlugin extension points
### Project Manager (6), Run/remote debug (6), Version control (2 — VCS plugins via EditorVCSInterface), Project upgrade (3→4 converter: `--convert-3to4`), Asset library/store (editor/asset_library)

---

## 10. Import system

**Importers (editor/import):** audio_stream_import_settings, dynamic_font_import_settings, editor_atlas_packer, editor_import_plugin, fbx_importer_manager, import_defaults_editor, resource_importer_bitmask, resource_importer_bmfont, resource_importer_csv_translation, resource_importer_dynamic_font, resource_importer_image, resource_importer_imagefont, resource_importer_layered_texture, resource_importer_shader_file, resource_importer_svg, resource_importer_texture, resource_importer_texture_atlas, resource_importer_texture_settings, resource_importer_wav

**In practice — जो file formats engine import करता है:** images (png, jpg, webp, svg, bmp, tga, dds, ktx2, exr/hdr, basis), textures atlas packing, layered/compressed textures, fonts (ttf/otf/woff via dynamic_font importer + msdfgen), audio (wav import के साथ mp3/ogg/vorbis सीधे stream होते हैं), theora video, models (glTF .gltf/.glb official recommended, .blend via Blender background export, FBX official module), translations (csv), shader files (.gdshader/.res), SVG (ThorVG), bitmask (Godot palette images), bmfont (.fnt)।

**Resource format loaders/savers (native formats):** ResourceFormatLoaderCompressedTexture2D, ResourceFormatLoaderCompressedTexture3D, ResourceFormatLoaderCompressedTextureLayered, ResourceFormatLoaderShader, ResourceFormatLoaderShaderInclude, ResourceFormatLoaderText, ResourceFormatSaverShader, ResourceFormatSaverShaderInclude, ResourceFormatSaverText, ResourceFormatSaverTextInstance — plus binary/text .tres/.tscn via ResourceFormatLoaderText/SaverText (.res/.scn binary)

---

## 11. Export system (8 platform ports)

- **android**: android_editor_gradle_runner, export, export_plugin, godot_plugin_config, gradle_export_util
- **ios**: export, export_plugin
- **linuxbsd**: export, export_plugin
- **macos**: export, export_plugin
- **visionos**: export, export_plugin
- **web**: editor_http_server, export, export_plugin
- **windows**: export, export_plugin, template_modifier

Export flow: Project → Export → presets; `--export-release "Preset" output` (headless)। Per-platform capabilities का detail Section 18 (docs deep-dive §8) में।

---

## 12. Command-line interface — सभी 104 options

(main.cpp से extracted; `godot --help` से भी दिखते हैं)

```
--accessibility
--accessibility-driver
--accurate-breadcrumbs
--always-on-top
--audio-driver
--audio-output-latency
--benchmark
--benchmark-file
--breakpoints
--build-solutions
--check-only
--convert-3to4
--dap-port
--debug
--debug-avoidance
--debug-canvas-item-redraw
--debug-collisions
--debug-mute-audio
--debug-navigation
--debug-paths
--debug-server
--debug-stringnames
--delta-smoothing
--disable-crash-handler
--disable-render-loop
--disable-vsync
--display-driver
--doctool
--dump-extension-api
--dump-extension-api-with-docs
--dump-gdextension-interface
--dump-gdextension-interface-json
--editor
--editor-pid
--editor-pseudolocalization
--embedded
--export
--export-
--export-debug
--export-pack
--export-patch
--export-release
--extra-gpu-memory-tracking
--fixed-fps
--frame-delay
--fullscreen
--gdextension-docs
--gdscript-docs
--generate-spirv-debug-info
--gpu-abort
--gpu-index
--gpu-profile
--gpu-validation
--headless
--help
--ignore-error-breaks
--import
--install-android-build-template
--language
--log-file
--lsp-port
--main-loop
--main-pack
--max-fps
--maximized
--no-docbase
--no-header
--patches
--path
--position
--print-fps
--profiling
--project-manager
--quiet
--quit
--quit-after
--recovery-mode
--remote-debug
--remote-fs
--remote-fs-password
--render-thread
--rendering-driver
--rendering-method
--resolution
--scene
--screen
--script
--single-threaded-scene
--single-window
--skip-breakpoints
--tablet-driver
--test
--test-rd-creation
--test-rd-support
--text-driver
--time-scale
--validate-conversion-3to4
--validate-extension-api
--verbose
--version
--wid
--windowed
--write-movie
--xr-mode
```

**कम-इस्तेमाल होने वाले powerful ones:** `--headless` (no window; CI/servers), `--import` (batch re-import), `--export-release`/`--export-pack`/`--export-debug`, `--dump-extension-api`, `--doctool` (class reference बनाओ), `--convert-3to4` (पुराना project upgrade), `--debug-*` family (collisions/navigation/paths/avoidance/canvas-item-redraw/stringnames), `--remote-debug`, `--audio-driver Dummy`, `--rendering-driver`, `--benchmark`/`--benchmark-file`, `--quit-after`, `--write-movie` (AVI/PNG/MJPEG movie output), `--fixed-fps`, `--editor-pid`/`--dap-port` (debug adapter protocol)।

---

## 13. Modules — सभी 57 engine modules

(हर module `modules/<name>/` में है, `config.py` से build system में register होता है, SCons से enable/disable हो सकता है)

- **astcenc** — ASTC texture compression encoder (GPU-compressible ASTC format)
- **basis_universal** — Basis Universal / .basis texture transcoder (LDR + HDR)
- **bcdec** — BC1-BC7 (DXT) texture block decoder on CPU
- **betsy** — GPU-side BC/ETC compression via compute shaders
- **bmp** — BMP image format loader
- **camera** — Camera access on Android and iOS (CameraFeed)
- **csg** — Constructive Solid Geometry — CSGBox3D, CSGSphere3D, etc. + CSG combiner
- **cvtt** — Convection Kernels texture compressor (BC/ASTC)
- **dds** — DirectDraw Surface (.dds) texture loader (incl. block-compressed)
- **enet** — ENet reliable UDP networking library bindings
- **etcpak** — ETC1/ETC2 texture compression (fast CPU)
- **fbx** — FBX 3D asset importer (official, replaces ufbx)
- **freetype** — FreeType font rendering for text servers
- **gdscript** — GDScript language: tokenizer, parser, analyzer, compiler, VM
- **glslang** — GLSL shader compiler (Vulkan-validating, used for shader compilation)
- **gltf** — glTF 2.0 importer/exporter (.gltf/.glb, also .blend via Blender export)
- **godot_physics_2d** — Default built-in 2D physics engine
- **godot_physics_3d** — Default built-in 3D physics engine
- **gridmap** — GridMap node — 3D grid-based level building with MeshLibrary
- **hdr** — Radiance HDR (.hdr) image loader
- **interactive_music** — Interactive music system (AudioStreamInteractive, transitions/fill/beat matching)
- **jolt_physics** — Jolt 3D physics engine integration (advanced default-capable 3D physics)
- **jpg** — JPEG image loader
- **jsonrpc** — JSON-RPC protocol implementation (used by debugger/LSP)
- **ktx** — KTX2 texture container loader
- **lightmapper_rd** — GPU-based lightmapper (BakedLightmap, LightmapGI uses this)
- **mbedtls** — mbedTLS — TLS/SSL, certs, crypto, HTTPS (used by HTTPClient etc.)
- **meshoptimizer** — Mesh optimization library (vertex cache/overdraw/fetch optimization, simplification)
- **mobile_vr** — Simple mobile VR (cardboard-style) XR backend
- **mono** — C# / .NET language support
- **mp3** — MP3 audio decoder
- **msdfgen** — Multi-channel signed distance field font generation (MSDF fonts)
- **multiplayer** — High-level multiplayer: SceneMultiplayer, MultiplayerSpawner, replication API
- **navigation_2d** — 2D navigation: NavigationRegion2D, agents, obstacles, pathfinding
- **navigation_3d** — 3D navigation: NavigationRegion3D, NavigationMesh baking, agents
- **noise** — Noise generation (FastNoiseLite) + noise textures
- **objectdb_profiler** — ObjectDB memory profiling support
- **ogg** — Ogg container + Vorbis audio support
- **openxr** — OpenXR runtime integration (VR headsets, actions, hand tracking)
- **raycast** — Raycast (CPU raytracing BVH library, used by 3D picking/RaycastSource3D)
- **regex** — RegEx class (PCRE-style regular expressions)
- **svg** — SVG vector image loading (via ThorVG)
- **text_server_adv** — Advanced text server — complex scripts, BiDi, ICU, HarfBuzz
- **text_server_fb** — Fallback text server — simpler, for less common platforms
- **tga** — TGA image loader
- **theora** — Theora video decoding (VideoStreamTheora)
- **tinyexr** — OpenEXR (.exr) HDR image loader
- **upnp** — UPnP (universal plug and play) for NAT traversal
- **vhacd** — VHACD convex decomposition (concave → convex hulls for physics)
- **visual_shader** — Visual Shader editor — VisualShader nodes
- **vorbis** — Ogg Vorbis audio decoding
- **webp** — WebP image encode/decode
- **webrtc** — WebRTC data channels for high-level multiplayer
- **websocket** — WebSocket networking (client + server)
- **webxr** — WebXR — VR/AR in web exports
- **xatlas_unwrap** — UV atlas unwrapping (lightmap bake parameterization)
- **zip** — ZIP archive read/write (ZIPReader, ZIPPacker)

---

## 14. Third-party libraries (bundled)

पूरा official inventory (upstream URLs + exact versions + licenses) — सीधे source के `thirdparty/README.md` से:

# Third party libraries

Please keep categories (`##` level) listed alphabetically and matching their
respective folder names. Use two empty lines to separate categories for
readability.


## accesskit

- Upstream: https://github.com/AccessKit/accesskit-c
- Version: 0.22.3 (826d672661f9453c8b269ab3946dbcbae6300555, 2026)
- License: MIT

Files extracted from upstream source:

- `accesskit.h`
- `LICENSE-MIT`


## amd-fsr

- Upstream: https://github.com/GPUOpen-Effects/FidelityFX-FSR
- Version: 1.0.2 (a21ffb8f6c13233ba336352bdff293894c706575, 2021)
- License: MIT

Files extracted from upstream source:

- `ffx_a.h` and `ffx_fsr1.h` from `ffx-fsr`
- `license.txt`


## amd-fsr2

- Upstream: https://github.com/GPUOpen-Effects/FidelityFX-FSR2
- Version: 2.2.1 (1680d1edd5c034f88ebbbb793d8b88f8842cf804, 2023)
- License: MIT

Files extracted from upstream source:

- `ffx_*.cpp` and `ffx_*.h` from `src/ffx-fsr2-api`
- `shaders` folder from `src/ffx-fsr2-api` with `ffx_*.hlsl` files excluded
- `LICENSE.txt`

Patches:

- `0001-build-fixes.patch` ([GH-81197](https://github.com/godotengine/godot/pull/81197))
- `0002-godot-fsr2-options.patch` ([GH-81197](https://github.com/godotengine/godot/pull/81197))


## angle

- Upstream: https://chromium.googlesource.com/angle/angle/
- Version: git (chromium/5907, 430a4f559cbc2bcd5d026e8b36ee46ddd80e9651, 2023)
- License: BSD-3-Clause

Files extracted from upstream source:

- `include/*`
- `LICENSE`


## astcenc

- Upstream: https://github.com/ARM-software/astc-encoder
- Version: 5.3.0 (bf32abd05eccaf3042170b2a85cebdf0bfee5873, 2025)
- License: Apache 2.0

Files extracted from upstream source:

- `astcenc_*` and `astcenc.h` files from `Source`
- `LICENSE.txt`


## basis_universal

- Upstream: https://github.com/BinomialLLC/basis_universal
- Version: git (b1110111d4a93c7dd7de93ce3d9ed8fcdfd114f2, 2025)
- License: Apache 2.0

Files extracted from upstream source:

- `encoder/` and `transcoder/` folders, with the following files removed from `encoder`:
  `3rdparty/{qoi.h,tinydds.h,tinyexr.cpp,tinyexr.h}`
- `LICENSE`

Patches:

- `0001-external-zstd-pr344.patch` ([GH-73441](https://github.com/godotengine/godot/pull/73441))
- `0002-external-tinyexr.patch` ([GH-97582](https://github.com/godotengine/godot/pull/97582))
- `0003-remove-tinydds-qoi.patch` ([GH-97582](https://github.com/godotengine/godot/pull/97582))
- `0004-clang-warning-exclude.patch` ([GH-111346](https://github.com/godotengine/godot/pull/111346))
- `0005-unused-typedef.patch` ([GH-111445](https://github.com/godotengine/godot/pull/111445))
- `0006-explicit-includes.patch` ([GH-111557](https://github.com/godotengine/godot/pull/111557))


## brotli

- Upstream: https://github.com/google/brotli
- Version: 1.2.0 (028fb5a23661f123017c060daa546b55cf4bde29, 2025)
- License: MIT

Files extracted from upstream source:

- `common/`, `dec/` and `include/` folders from `c/`,
  minus the `dictionary.bin*` files
- `LICENSE`


## certs

- Upstream: Mozilla, via https://github.com/bagder/ca-bundle
- Version: git (cc4096bef208d35e2884571046c75a726185c358, 2025)
- License: MPL 2.0

Files extracted from upstream source:

- `ca-bundle.crt`


## clipper2

- Upstream: https://github.com/AngusJohnson/Clipper2
- Version: 1.5.4 (ef88ee97c0e759792e43a2b2d8072def6c9244e8, 2025)
- License: BSL 1.0

Files extracted from upstream source:

- `CPP/Clipper2Lib/` folder (in root)
- `LICENSE`

Patches:

- `0001-disable-exceptions.patch` ([GH-80796](https://github.com/godotengine/godot/pull/80796))
- `0002-llvm-21-header.patch` ([GH-113850](https://github.com/godotengine/godot/pull/113850))


## cvtt

- Upstream: https://github.com/elasota/ConvectionKernels
- Version: git (350416daa4e98f1c17ffc273b134d0120a2ef230, 2022)
- License: MIT

Files extracted from upstream source:

- All `.cpp` and `.h` files except the folders `MakeTables` and `etc2packer`
- `LICENSE.txt`

Patches:

- `0001-revert-bc6h-reorg.patch` ([GH-73715](https://github.com/godotengine/godot/pull/73715))


## d3d12ma

- Upstream: https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator
- Version: 3.1.0 (0fa62ed3a0a69b73230a8ec1faa752d4061c8dc8, 2026)
- License: MIT

Files extracted from upstream source:

- `src/D3D12MemAlloc.cpp`, `src/D3D12MemAlloc.natvis`
- `include/D3D12MemAlloc.h`
- `LICENSE.txt`, `NOTICES.txt`

Patches:

- `0001-mingw-support.patch` ([GH-83452](https://github.com/godotengine/godot/pull/83452))


## directx_headers

- Upstream: https://github.com/microsoft/DirectX-Headers
- Version: main (25411c74bb9cc7c416b2ff01b3ad8a306811dfdd, 2025)
- License: MIT

Files extracted from upstream source:

- `include/directx/*.h`
- `include/dxguids/*.h`
- `LICENSE`

Patches:

- `0001-win7-8-dynamic-load.patch` ([GH-88496](https://github.com/godotengine/godot/pull/88496))


## doctest

- Upstream: https://github.com/onqtam/doctest
- Version: 2.4.12 (1da23a3e8119ec5cce4f9388e91b065e20bf06f5, 2025)
- License: MIT

Files extracted from upstream source:

- `doctest/doctest.h` as `doctest.h`
- `LICENSE.txt`

Patches:

- `0001-ciso646-version.patch` ([GH-105913](https://github.com/godotengine/godot/pull/105913))


## dr_libs

- Upstream: https://github.com/mackron/dr_libs
- Version: mp3-0.7.3 (5690d4671d7ad07ae6021756d7222eb159745f06, 2026)
- License: Public Domain or Unlicense or MIT-0

Files extracted from upstream source:

- `dr_mp3.h`
- `LICENSE`

`dr_bridge.h` is a Godot file and should be preserved on updates.


## embree

- Upstream: https://github.com/embree/embree
- Version: 4.4.0 (ff9381774dc99fea81a932ad276677aad6a3d4dd, 2025)
- License: Apache 2.0

Files extracted from upstream:

- All `.cpp` files listed in `modules/raycast/godot_update_embree.py`
- All header files in the directories listed in `modules/raycast/godot_update_embree.py`
- All config files listed in `modules/raycast/godot_update_embree.py`
- `LICENSE.txt`

Patches:

- `0001-disable-exceptions.patch` ([GH-48050](https://github.com/godotengine/godot/pull/48050))
- `0002-godot-config.patch` ([GH-88783](https://github.com/godotengine/godot/pull/88783))
- `0003-emscripten-nthreads.patch` ([GH-69799](https://github.com/godotengine/godot/pull/69799))
- `0004-mingw-no-cpuidex.patch` ([GH-92488](https://github.com/godotengine/godot/pull/92488))
- `0005-mingw-llvm-arm64.patch` ([GH-93364](https://github.com/godotengine/godot/pull/93364))
- `0006-explicit-includes.patch` ([GH-111557](https://github.com/godotengine/godot/pull/111557))

The `modules/raycast/godot_update_embree.py` script can be used to pull the
relevant files from the latest Embree release and apply patches automatically.


## enet

- Upstream: https://github.com/lsalzman/enet
- Version: 1.3.18 (2662c0de09e36f2a2030ccc2c528a3e4c9e8138a, 2024)
- License: MIT

Files extracted from upstream source:

- All `.c` files in the main directory (except `unix.c` and `win32.c`)
- The `include/enet/` folder as `enet/` (except `unix.h` and `win32.h`)
- `LICENSE` file
- Added 3 files `enet_godot.cpp`, `enet/enet_godot.h`, and `enet/enet_godot_ext.h`,
  providing ENet socket implementation using Godot classes, allowing IPv6 and DTLS.

Patches:

- `0001-godot-socket.patch` ([GH-7985](https://github.com/godotengine/godot/pull/7985))

Important: Building against a system wide ENet is possible, but will limit its
functionality to IPv4 only and no DTLS. We recommend against it.


## etcpak

- Upstream: https://github.com/wolfpld/etcpak
- Version: 2.0 (a43d6925bee49277945cf3e311e4a022ae0c2073, 2024)
- License: BSD-3-Clause

Files extracted from upstream source:

- Only the files relevant for compression (i.e. `Process*.cpp` and their deps):
  ```
  Dither.{cpp,hpp} ForceInline.hpp Math.hpp ProcessCommon.hpp ProcessRGB.{cpp,hpp}
  ProcessDxtc.{cpp,hpp} Tables.{cpp,hpp} Vector.hpp
  ```
- The files `DecodeRGB.{cpp.hpp}` are based on the code from the original repository.
- `AUTHORS.txt` and `LICENSE.txt`

Patches:

- `0001-remove-bc7enc.patch` ([GH-101362](https://github.com/godotengine/godot/pull/101362))


## fonts

- `DroidSans*.woff2`:
  * Upstream: https://android.googlesource.com/platform/frameworks/base/+/master/data/fonts/
  * Version: ? (pre-2014 commit when DroidSansJapanese.ttf was obsoleted)
  * License: Apache 2.0
- `Inter*.woff2`:
  * Upstream: https://github.com/rsms/inter
  * Version: v4.1 (e3a3d4c57d5ecc01453a575621882a384c1995a3, 2024)
  * License: OFL-1.1
- `JetBrainsMono_Regular.woff2`:
  * Upstream: https://github.com/JetBrains/JetBrainsMono
  * Version: 2.304 (cd5227bd1f61dff3bbd6c814ceaf7ffd95e947d9, 2023)
  * License: OFL-1.1
- `NotoSansBengali*.woff2`:
  * Upstream: https://github.com/notofonts/bengali
  * Version: 3.011 (85d80394cbbbb798ca0a41c983902e6cf77be3a3, 2026)
  * License: OFL-1.1
- `NotoSansDevanagari*.woff2`:
  * Upstream: https://github.com/notofonts/devanagari
  * Version: 2.006 (bb8d2566a1708ef2dcc6396ee2eb261a18967f76, 2024)
  * License: OFL-1.1
- `NotoSansGeorgian*.woff2`:
  * Upstream: https://github.com/notofonts/georgian
  * Version: 2.005 (c02e5483c2dd63c5cf223845010ebd6e6dc56aec, 2024)
  * License: OFL-1.1
- `NotoSansHebrew*.woff2`:
  * Upstream: https://github.com/notofonts/hebrew
  * Version: 3.001 (caa7ab0614fb5b37cc003d9bf3d7d3e765331110, 2024)
  * License: OFL-1.1
- `NotoSansMalayalam*.woff2`:
  * Upstream: https://github.com/notofonts/malayalam
  * Version: 2.104 (0fd65e553a6af3dc1c09ed39dfe8933e01c17b32, 2023)
  * License: OFL-1.1
- `NotoSansOriya*.woff2`:
  * Upstream: https://github.com/notofonts/oriya
  * Version: 2.006 (97abab82ec512f8a4a98c389352f194a03385ce2, 2024)
  * License: OFL-1.1
- `NotoSansSinhala*.woff2`:
  * Upstream: https://github.com/notofonts/sinhala
  * Version: 3.000 (032355e96de5bac83fd996535af3d13b1fbfeccf, 2025)
  * License: OFL-1.1
- `NotoSansTamil*.woff2`:
  * Upstream: https://github.com/notofonts/tamil
  * Version: 2.004 (f34a08d1ae3fa810581f63410296d971bdcd62dc, 2023)
  * License: OFL-1.1
- `NotoSansTelugu*.woff2`:
  * Upstream: https://github.com/notofonts/telugu
  * Version: 2.005 (e97c3409a8347d68cccd06a82a68b418c315ee0c, 2023)
  * License: OFL-1.1
- `NotoSansThai*.woff2`:
  * Upstream: https://github.com/notofonts/thai
  * Version: 2.002 (f8b482c158650260bba5d5edba9da3e8bb7185b4, 2023)
  * License: OFL-1.1
- `OpenSans_SemiBold.woff2`:
  * Upstream: https://github.com/googlefonts/opensans
  * Version: git (bd7e37632246368c60fdcbd374dbf9bad11969b6, 2023)
  * License: OFL-1.1
- `Vazirmatn*.woff2`:
  * Upstream: https://github.com/rastikerdar/vazirmatn
  * Version: 33.003 (83629f877e8f084cc07b47030b5d3a0ff06c76ec, 2022)
  * License: OFL-1.1

All fonts are converted from the unhinted `.ttf` sources using the
`https://github.com/google/woff2` tool.

Use UI font variant if available, because it has tight vertical metrics and good
for UI.


## freetype

- Upstream: https://gitlab.freedesktop.org/freetype/freetype
- Version: 2.14.3 (0a0221a1347e2f1e07c395263540026e9a0aa7c7, 2026)
- License: FreeType License (BSD-like)

Files extracted from upstream source:

- `src/` folder, minus the `dlg` and `tools` subfolders
  * These files can be removed: `.dat`, `.diff`, `.mk`, `.rc`, `README*`
  * In `src/gzip/`, keep only `ftgzip.c`
- `include/` folder, minus the `dlg` subfolder
- `LICENSE.TXT` and `docs/FTL.TXT`


## gamepadmotionhelpers

- Upstream: https://github.com/JibbSmart/GamepadMotionHelpers
- Version: 39b578aacf34c3a1c584d8f7f194adc776f88055, 2023
- License: MIT

Files extracted from upstream source:

- `GamepadMotion.hpp`
- `LICENSE.TXT`

Patches:

- `0001-fix-warnings.patch` ([GH-111679](https://github.com/godotengine/godot/pull/111679))

## glad

- Upstream: https://github.com/Dav1dde/glad
- Version: 2.0.8 (73db193f853e2ee079bf3ca8a64aa2eaf6459043, 2024)
- License: CC0 1.0 and Apache 2.0

Files extracted from upstream source:
- `LICENSE`

Files generated from [upstream web instance](https://gen.glad.sh/):
- `EGL/eglplatform.h`
- `KHR/khrplatform.h`
- `egl.c`
- `glad/egl.h`
- `gl.c`
- `glad/gl.h`
- `glx.c`
- `glad/glx.h`

See the permalinks in `glad/egl.h`, `glad/gl.h` and `glad/glx.h`
to regenerate the files with a new version of the web instance.

Patches:

- `0001-enable-both-gl-and-gles.patch` ([GH-72831](https://github.com/godotengine/godot/pull/72831))
- `0002-revert-egl_static-removal.patch` ([GH-107312](https://github.com/godotengine/godot/pull/107312))


## glslang

- Upstream: https://github.com/KhronosGroup/glslang
- Version: vulkan-sdk-1.4.335.0 (b5782e52ee2f7b3e40bb9c80d15b47016e008bc9, 2025)
- License: glslang

Version should be kept in sync with the one of the used Vulkan SDK (see `vulkan`
section).

Files extracted from upstream source:

- `glslang/` folder (except the `glslang/HLSL` and `glslang/ExtensionHeaders`
  subfolders), `SPIRV/` folder
  * Remove C interface code: `CInterface/` folders, files matching `"*_c[_\.]*"`
  * Remove `glslang/stub.cpp`
  * Remove `SPIRV/spirv.hpp11` (should use copy from `thirdparty/spirv-headers`)
- Run `cmake . && make` and copy generated `include/glslang/build_info.h`
  to `glslang/build_info.h`
- `LICENSE.txt`
- Unnecessary files like `CMakeLists.txt` or `updateGrammar` removed

Patches:

- `0001-apple-disable-absolute-paths.patch` ([GH-92010](https://github.com/godotengine/godot/pull/92010))
- `0002-apple-m1-msaa-fix.patch` ([GH-115893](https://github.com/godotengine/godot/issues/115893))


## graphite

- Upstream: https://github.com/silnrsi/graphite
- Version: 1.3.14 (27572742003b93dc53dc02c01c237b72c6c25f54, 2022)
- License: MIT

Files extracted from upstream source:

- The `include` folder
- The `src` folder (minus `CMakeLists.txt` and `files.mk`)
- `COPYING`


## grisu2

- Upstream: https://github.com/simdjson/simdjson/blob/master/src/to_chars.cpp
- Version: git (667d0ed3c77f55cbda2082b034168d69898d1f88, 2025)
- License: Apache and MIT

Files extracted from upstream source:

- The `src/to_chars.cpp` file renamed to `grisu2.h` and slightly modified.

Patches:

- `0001-godot-changes.patch` ([GH-98750](https://github.com/godotengine/godot/pull/98750))


## harfbuzz

- Upstream: https://github.com/harfbuzz/harfbuzz
- Version: 14.2.0 (b0ffab42d473eb380ad0fcf42730e0f1868cbc97, 2026)
- License: MIT

Files extracted from upstream source:

- `AUTHORS`, `COPYING`, `THANKS`
- From the `src` folder, recursively:
  - All the `.cc`, `.h`, `.hh` files
  - Except `main.cc`, `harfbuzz*.cc`, `harfrust.cc`, `failing-alloc.c`, `test*.cc`, `hb-gpu*.*`, `hb-wasm*.*`, `hb-harfrust.cc`, `wasm/*`, `ms-use/*`, `rust/*`


## icu4c

- Upstream: https://github.com/unicode-org/icu
- Version: 78.3 (21d1eb0f306e1141c10931e914dfc038c06121da, 2026)
- License: Unicode

Files extracted from upstream source:

- The `common` folder
- `scriptset.*`, `ucln_in.*`, `uspoof.cpp` and `uspoof_impl.*` from the `i18n` folder
- `uspoof.h` from the `i18n/unicode` folder
- `LICENSE`

Files generated from upstream source:

- The `icudt_godot.dat` built with the provided `godot_data.json` config file (see
  https://github.com/unicode-org/icu/blob/master/docs/userguide/icu_data/buildtool.md
  for instructions).

1. Download and extract both `icu4c-{version}-src.tgz` and `icu4c-{version}-data.zip`
  (replace `data` subfolder from the main source archive)
2. Build ICU with default options: `./runConfigureICU {PLATFORM} && make`
3. Reconfigure ICU with custom data config:
   `ICU_DATA_FILTER_FILE={GODOT_SOURCE}/thirdparty/icu4c/godot_data.json ./runConfigureICU {PLATFORM} --with-data-packaging=common`
4. Delete `data/out` folder and rebuild data: `cd data && rm -rf ./out && make`
5. Copy `source/data/out/icudt{ICU_VERSION}l.dat` to the `{GODOT_SOURCE}/thirdparty/icu4c/icudt_godot.dat`


## jolt_physics

- Upstream: https://github.com/jrouwe/JoltPhysics
- Version: 5.5.0 (23dadd0e603f1b321142d4c74df07fce85064989, 2025)
- License: MIT

Files extracted from upstream source:

- All files in `Jolt/`, except `Jolt/Jolt.cmake` and any files dependent on `ENABLE_OBJECT_STREAM`, as seen in `Jolt/Jolt.cmake`
- `LICENSE`

Patches:

- `0001-backport-upstream-commit-ee3725250.patch` (GH-115089)
- `0002-backport-upstream-commit-bc7f1fb8c.patch` (GH-115305)
- `0003-backport-upstream-commit-365a15367.patch` (GH-115305)
- `0004-backport-upstream-commit-e0a6a9a16.patch` (GH-115327)
- `0005-backport-upstream-commit-449b645.patch` (GH-117194)
- `0006-backport-upstream-commit-63765d1.patch` (GH-118393)


## libbacktrace

- Upstream: https://github.com/ianlancetaylor/libbacktrace
- Version: git (4d2dd0b172f2c9192f83ba93425f868f2a13c553, 2022)
- License: BSD-3-Clause

Files extracted from upstream source:

- `*.{c,h}` files for Windows platform, i.e. remove the following:
  * `allocfail.c`, `instrumented_alloc.c`, `*test*.{c,h}`
  * `elf.c`, `macho.c`, `mmap.c`, `mmapio.c`, `nounwind.c`, `unknown.c`, `xcoff.c`
- `LICENSE`

Patches:

- `0001-big-files-support.patch` ([GH-100281](https://github.com/godotengine/godot/pull/100281))


## libjpeg-turbo

- Upstream: https://github.com/libjpeg-turbo/libjpeg-turbo
- Version: 3.1.3 (af9c1c268520a29adf98cad5138dafe612b3d318, 2025)
- License: BSD-3-Clause and IJG

Files extracted from upstream source:

- `src/*.{c,h}` except for:
  * `cdjpeg.c cjpeg.c djpeg.c example.c jcdiffct.c jclhuff.c jclossls.c jcstest.c jddiffct.c jdlhuff.c jdlossls.c jlossls.h jpegtran.c rdbmp.c rdcolmap.c rdgif.c rdjpgcom.c rdppm.c rdswitch.c rdtarga.c strtest.c tjbench.c tjcomp.c tjdecomp.c tjtran.c tjunittest.c tjutil.c wrbmp.c wrgif.c wrjpgcom.c wrppm.c wrtarga.c`
- `LICENSE.md`
- `README.ijg`

Patches:

- `0001-cmake-generated-headers.patch` ([GH-104347](https://github.com/godotengine/godot/pull/104347))
  * Compare with CMake-generated headers to bump version and added potential new config values.
- `0002-disable-16bitlossless.patch` ([GH-104347](https://github.com/godotengine/godot/pull/104347))
- `0003-remove-bmp-ppm-support.patch` ([GH-104347](https://github.com/godotengine/godot/pull/104347))


## libktx

- Upstream: https://github.com/KhronosGroup/KTX-Software
- Version: 4.4.2 (4d6fc70eaf62ad0558e63e8d97eb9766118327a6, 2025)
- License: Apache 2.0

Files extracted from upstream source:

- `LICENSE.md`
- `include/` minus `.clang-format`
- `external/dfdutils/LICENSE.adoc` as `LICENSE.dfdutils.adoc` (in root)
- `external/dfdutils/LICENSES/Apache-2.0.txt` as `Apache-2.0.txt` (in root)
- `external/dfdutils/{KHR/,dfd.h,colourspaces.c,createdfd.c,interpretdfd.c,printdfd.c,queries.c,dfd2vk.inl,vk2dfd.*}`
- `lib/{basis_sgd.h,formatsize.h,gl_format.h,ktxint.h,uthash.h,vk_format.h,vkformat_enum.h,checkheader.c,swap.c,hashlist.c,vkformat_check*.c,vkformat_typesize.c,basis_transcode.cpp,miniz_wrapper.cpp,filestream.*,memstream.*,texture*}`
- `other_include/KHR/`
- `utils/unused.h`

Patches:

- `0001-external-basisu.patch` ([GH-76572](https://github.com/godotengine/godot/pull/76572))
- `0002-disable-astc-block-ext.patch` ([GH-76572](https://github.com/godotengine/godot/pull/76572))
- `0003-basisu-1.60.patch` ([GH-103968](https://github.com/godotengine/godot/pull/103968))


## libogg

- Upstream: https://www.xiph.org/ogg
- Version: 1.3.6 (be05b13e98b048f0b5a0f5fa8ce514d56db5f822, 2025)
- License: BSD-3-Clause

Files extracted from upstream source:

- `src/*.{c,h}`
- `include/ogg/*.h` in `ogg/` (run `configure` to generate `config_types.h`)
- `COPYING`


## libpng

- Upstream: http://libpng.org/pub/png/libpng.html
- Version: 1.6.58 (3061454d980de7d53608f594194cfac722721d2a, 2026)
- License: libpng/zlib

Files extracted from upstream source:

- All `.c` and `.h` files of the main directory, apart from `example.c` and `pngtest.c`
- `arm/`, `intel/`, `loongarch/`, and `powerpc/` folders, except `arm/filter_neon.S` and `.editorconfig` files
- `scripts/pnglibconf.h.prebuilt` as `pnglibconf.h`
- `LICENSE`


## libtheora

- Upstream: https://www.theora.org
- Version: 1.2.0 (8e4808736e9c181b971306cc3f05df9e61354004, 2025)
- License: BSD-3-Clause

Files extracted from upstream source:

- All `.c` and `.h` files in `lib/`, except `arm/` and `c64x/` folders
- All `.h` files in `include/theora/` as `theora/`
- `COPYING` and `LICENSE`


## libvorbis

- Upstream: https://www.xiph.org/vorbis
- Version: 1.3.7 (0657aee69dec8508a0011f47f3b69d7538e9d262, 2020)
- License: BSD-3-Clause

Files extracted from upstream source:

- `lib/*` except from: `lookups.pl`, `Makefile.*`
- `include/vorbis/*.h` as `vorbis/`
- `COPYING`


## libwebp

- Upstream: https://chromium.googlesource.com/webm/libwebp/
- Version: 1.6.0 (4fa21912338357f89e4fd51cf2368325b59e9bd9, 2025)
- License: BSD-3-Clause

Files extracted from upstream source:

- `src/` and `sharpyuv/` except from `.am`, `.rc` and `.in` files
- `AUTHORS`, `COPYING`, `PATENTS`

Patches:

- `0001-msvc-node-debug-rename.patch` ([GH-75769](https://github.com/godotengine/godot/pull/75769))
- `0002-msvc-arm64-fpstrict.patch` ([GH-94655](https://github.com/godotengine/godot/pull/94655))
- `0003-clang-cl-sse2-sse41-avx2.patch` ([GH-92316](https://github.com/godotengine/godot/pull/92316))


## linuxbsd_headers

See `linuxbsd_headers/README.md`.


## manifold

- Upstream: https://github.com/elalish/manifold
- Version: 3.3.2 (798d83c8d7fabcddd23c1617097b95ba40f2597c, 2025)
- License: Apache 2.0

File extracted from upstream source:

- `src/` and `include/`, except from `CMakeLists.txt`, `cross_section.h` and `meshIO.{cpp,h}`
- `AUTHORS`, `LICENSE`


## mbedtls

- Upstream: https://github.com/Mbed-TLS/mbedtls
- Version: 3.6.7 (068ff080b369adfac81509f9b57b2afabaf82dc5, 2026)
- License: Apache 2.0

File extracted from upstream release tarball:

- All `.h` from `include/mbedtls/` to `thirdparty/mbedtls/include/mbedtls/`
  and all `.h` from `include/psa/` to `thirdparty/mbedtls/include/psa/`
- From `library/` to `thirdparty/mbedtls/library/`:
  - All `.c` and `.h` files
  - Except `bignum_mod.c`, `block_cipher.c`, `ecp_curves_new.c`, `lmots.c`,
    `lms.c`
- The `LICENSE` file (edited to keep only the Apache 2.0 variant)
- Added 2 files `godot_core_mbedtls_platform.c` and `godot_core_mbedtls_config.h`
  providing configuration for light bundling with core
- Added 2 files `godot_module_mbedtls_config.h` and `threading_alt.h`
  to customize the build configuration when bundling the full library

Patches:

- `0001-msvc-2019-psa-redeclaration.patch` ([GH-90535](https://github.com/godotengine/godot/pull/90535))


## metal-cpp

- Upstream: https://developer.apple.com/metal/cpp/
- Version: 26.0 (2025)
- License: Apache 2.0

Update instructions:

- Download latest metal-cpp ZIP from https://developer.apple.com/metal/cpp/:
- Run `update-metal-cpp.sh <path to the downloaded zip>` to extract the relevant files and apply patches.


## meshoptimizer

- Upstream: https://github.com/zeux/meshoptimizer
- Version: 1.1.1 (b22872835dbabc56a6e4a366ea9917f62b7daf1a, 2026)
- License: MIT

Files extracted from upstream repository:

- All files in `src/`
- `LICENSE.md`


## mingw-std-threads

- Upstream: https://github.com/meganz/mingw-std-threads
- Version: git (c931bac289dd431f1dd30fc4a5d1a7be36668073, 2023)
- License: BSD-2-clause

Files extracted from upstream repository:

- `LICENSE`
- `mingw.condition_variable.h`
- `mingw.invoke.h`
- `mingw.mutex.h`
- `mingw.shared_mutex.h`
- `mingw.thread.h`

Patches:

- `0001-disable-exceptions.patch` ([GH-85039](https://github.com/godotengine/godot/pull/85039))
- `0002-clang-std-replacements-leak.patch` ([GH-85208](https://github.com/godotengine/godot/pull/85208))
- `0003-explicit-includes.patch` ([GH-111557](https://github.com/godotengine/godot/pull/111557))


## miniupnpc

- Upstream: https://github.com/miniupnp/miniupnp
- Version: 2.3.3 (bf4215a7574f88aa55859db9db00e3ae58cf42d6, 2025)
- License: BSD-3-Clause

Files extracted from upstream source:

- `miniupnpc/src/` as `src/`
- `miniupnpc/include/` as `include/miniupnpc/`
- Remove the following test or sample files:
  `listdevices.c,minihttptestserver.c,miniupnpcmodule.c,upnpc.c,upnperrors.*,test*`
- `LICENSE`
- `src/miniupnpcstrings.h` was created manually for Godot (it is usually generated
  by CMake). Bump the version number for miniupnpc in that file when upgrading.


## minizip

- Upstream: https://github.com/madler/zlib
- Version: 1.3.2 (da607da739fa6047df13e66a2af6b8bec7c2a498, 2026)
- License: zlib

Files extracted from the upstream source:

- From `contrib/minizip`:
  `{crypt.h,ints.h,ioapi.{c,h},skipset.h,unzip.{c,h},zip.{c,h}}`
  `MiniZip64_info.txt`

Patches:

- `0001-godot-seek.patch` ([GH-10428](https://github.com/godotengine/godot/pull/10428))


## misc

Collection of single-file libraries used in Godot components.

- `bcdec.h`
  * Upstream: https://github.com/iOrange/bcdec
  * Version: git (3b29f8f44466c7d59852670f82f53905cf627d48, 2024)
  * License: MIT
- `cubemap_coeffs.h`
  * Upstream: https://research.activision.com/publications/archives/fast-filtering-of-reflection-probes
    File coeffs_const_8.txt (retrieved April 2020)
  * License: MIT
- `fastlz.{c,h}`
  * Upstream: https://github.com/ariya/FastLZ
  * Version: 0.5.0 (4f20f54d46f5a6dd4fae4def134933369b7602d2, 2020)
  * License: MIT
- `FastNoiseLite.h`
  * Upstream: https://github.com/Auburn/FastNoiseLite
  * Version: 1.1.0 (f7af54b56518aa659e1cf9fb103c0b6e36a833d9, 2023)
  * License: MIT
  * Patches:
    - `FastNoiseLite-0001-namespace-warnings.patch` ([GH-88526](https://github.com/godotengine/godot/pull/88526))
- `ifaddrs-android.{cc,h}`
  * Upstream: https://chromium.googlesource.com/external/webrtc/stable/talk/+/master/base/ifaddrs-android.h
  * Version: git (5976650443d68ccfadf1dea24999ee459dd2819d, 2013)
  * License: BSD-3-Clause
  * Patches:
    - `ifaddrs-android-0001-complete-struct.patch` ([GH-34101](https://github.com/godotengine/godot/pull/34101))
- `mikktspace.{c,h}`
  * Upstream: https://archive.blender.org/wiki/index.php/Dev:Shading/Tangent_Space_Normal_Maps/
  * Version: 1.0 (2011)
  * License: zlib
- `nvapi_minimal.h`
  * Upstream: http://download.nvidia.com/XFree86/nvapi-open-source-sdk
  * Version: R525
  * License: MIT
  * Modifications: Created from upstream `nvapi.h` by removing unnecessary code.
- `ok_color.h`
  * Upstream: https://github.com/bottosson/bottosson.github.io/blob/master/misc/ok_color.h
  * Version: git (d69831edb90ffdcd08b7e64da3c5405acd48ad2c, 2022)
  * License: MIT
  * Modifications: License included in header.
- `ok_color_shader.h`
  * https://www.shadertoy.com/view/7sK3D1
  * Version: 2021-09-13
  * License: MIT
- `pcg.{cpp,h}`
  * Upstream: http://www.pcg-random.org
  * Version: minimal C implementation, http://www.pcg-random.org/download.html
  * License: Apache 2.0
- `polypartition.{cpp,h}`
  * Upstream: https://github.com/ivanfratric/polypartition (`src/polypartition.{cpp,h}`)
  * Version: git (7bdffb428b2b19ad1c43aa44c714dcc104177e84, 2021)
  * License: MIT
  * Patches:
    - `polypartition-0001-godot-types.patch` (2185c018f)
    - `polypartition-0002-shadow-warning.patch` ([GH-66808](https://github.com/godotengine/godot/pull/66808))
- `qoa.{c,h}`
  * Upstream: https://github.com/phoboslab/qoa
  * Version: git (ae07b57deb98127a5b40916cb57775823d7437d2, 2025)
  * License: MIT
  * Modifications: Added implementation through `qoa.c`.
- `r128.{c,h}`
  * Upstream: https://github.com/fahickman/r128
  * Version: git (6fc177671c47640d5bb69af10cf4ee91050015a1, 2023)
  * License: Public Domain or Unlicense
- `smaz.{c,h}`
  * Upstream: https://github.com/antirez/smaz
  * Version: git (2f625846a775501fb69456567409a8b12f10ea25, 2012)
  * License: BSD-3-Clause
  * Modifications: License included in header.
  * Patches:
    - `smaz-0001-write-string-warning.patch` ([GH-8572](https://github.com/godotengine/godot/pull/8572))
- `smolv.{cpp,h}`
  * Upstream: https://github.com/aras-p/smol-v
  * Version: git (9dd54c379ac29fa148cb1b829bb939ba7381d8f4, 2024)
  * License: Public Domain or MIT
- `stb_rect_pack.h`
  * Upstream: https://github.com/nothings/stb
  * Version: 1.01 (af1a5bc352164740c1cc1354942b1c6b72eacb8a, 2021)
  * License: Public Domain or Unlicense or MIT
- `yuv2rgb.h`
  * Upstream: http://wss.co.uk/pinknoise/yuv2rgb/ (to check)
  * Version: ?
  * License: BSD


## msdfgen

- Upstream: https://github.com/Chlumsky/msdfgen
- Version: 1.13 (1874bcf7d9624ccc85b4bc9a85d78116f690f35b, 2025)
- License: MIT

Files extracted from the upstream source:

- `msdfgen.h`
- Files in `core/` folder, minus `export-svg.*` and `save-*.*` files
- `LICENSE.txt`

Patches:

- `0001-remove-unused-save-features.patch` ([GH-113965](https://github.com/godotengine/godot/issues/113965))


## openxr

- Upstream: https://github.com/KhronosGroup/OpenXR-SDK
- Version: 1.1.54 (c15d38cb4bb10a5b7e075f74493ff13896e2597a, 2025)
- License: Apache 2.0

Files extracted from upstream source:

- `include/`
- `src/common/`
- `src/loader/`
- `src/*.{c,h}`
- `src/external/jsoncpp/include/`
- `src/external/jsoncpp/src/lib_json/`
- `src/external/jsoncpp/{AUTHORS,LICENSE}`
- `LICENSE` and `COPYING.adoc`

Exclude:

- `src/external/android-jni-wrappers` and `src/external/jnipp` (not used yet)
- Obsolete `src/xr_generated_dispatch_table.{c,h}`
- All CMake stuff: `cmake/`, `CMakeLists.txt` and `*.cmake`
- All Gradle stuff: `*gradle*`, `AndroidManifest.xml`
- All following files (and their `.license` files):
  `*.{def,expsym,in,json,map,pom,rc,txt}`
- All dotfiles

Additional:
- Update `openxrLoaderVersion` in `platform/android/java/app/config.gradle`


## pcre2

- Upstream: http://www.pcre.org
- Version: 10.47 (f454e231fe5006dd7ff8f4693fd2b8eb94333429, 2025)
- License: BSD-3-Clause

Files extracted from upstream source:

- Files listed in the file `NON-AUTOTOOLS-BUILD` steps 1-4
- All `.h` files in `src/` apart from `pcre2posix.h`, `pcre2_printint_inc.h`, `pcre2test_inc.h`
- `src/pcre2_compile_cgroup.c`
- `src/pcre2_match_next.c`
- `src/pcre2_{jit_char,jit_match,jit_misc,jit_simd,ucptables}_inc.h`
- `deps/sljit/sljit_src`
- `AUTHORS.md` and `LICENCE.md`


## recastnavigation

- Upstream: https://github.com/recastnavigation/recastnavigation
- Version: 1.6.0 (6dc1667f580357e8a2154c28b7867bea7e8ad3a7, 2023)
- License: zlib

Files extracted from upstream source:

- `Recast/` folder without `CMakeLists.txt`
- `License.txt`


## re-spirv

- Upstream: https://github.com/renderbag/re-spirv
- Version: git (29a77fca357567d00aa37b8ffde19c19cfe477c4, 2026)
- License: MIT

Files extracted from upstream source:

- `re-spirv.cpp`
- `re-spirv.h`
- `LICENSE`


## rvo2

For 2D in `rvo2_2d` folder

- Upstream: https://github.com/snape/RVO2
- Version: git (f7c5380235f6c9ac8d19cbf71fc94e2d4758b0a3, 2021)
- License: Apache 2.0

For 3D in `rvo2_3d` folder

- Upstream: https://github.com/snape/RVO2-3D
- Version: git (bfc048670a4e85066e86a1f923d8ea92e3add3b2, 2021)
- License: Apache 2.0

Files extracted from upstream source:

- All `.cpp` and `.h` files in the `src/` folder except for `Export.h` and `RVO.h`
- `LICENSE`

Important: Nearly all files have Godot-made changes and renames
to make the 2D and 3D rvo libraries compatible with each other
and solve conflicts and also enrich the feature set originally
proposed by these libraries and better integrate them with Godot.


## smaa

- Upstream: https://github.com/iryoku/smaa
- Version: git (71c806a838bdd7d517df19192a20f0c61b3ca29d, 2013)
- License: MIT

Files extracted from upstream source:

- `LICENSE`
- Textures generated using the Python scripts in the `Scripts` folder


## sdl

- Upstream: https://github.com/libsdl-org/SDL
- Version: 3.2.28 (7f3ae3d57459e59943a4ecfefc8f6277ec6bf540, 2025)
- License: Zlib
- Vendored: hidapi 0.14.0, license BSD-3-Clause

Files extracted from upstream source:

- See `thirdparty/sdl/update-sdl.sh`

Patches:

- `0001-remove-unnecessary-subsystems.patch` ([GH-106218](https://github.com/godotengine/godot/pull/106218))
- `0003-std-include.patch` ([GH-108144](https://github.com/godotengine/godot/pull/108144))
- `0004-errno-include.patch` ([GH-108354](https://github.com/godotengine/godot/pull/108354))
- `0005-fix-libudev-dbus.patch` ([GH-108373](https://github.com/godotengine/godot/pull/108373))
- `0006-fix-cs-environ.patch` ([GH-109283](https://github.com/godotengine/godot/pull/109283))
- `0007-shield-duplicate-macos.patch` ([GH-115510](https://github.com/godotengine/godot/pull/115510))
- `0008-fix-linux-joycon-serial-num.patch` ([GH-113873](https://github.com/godotengine/godot/pull/113873))
- `0009-update-device-blocklist.patch` ([GH-119403](https://github.com/godotengine/godot/pull/119403))


## spirv-cross

- Upstream: https://github.com/KhronosGroup/SPIRV-Cross
- Version: git (fb0c1a307cca4b4a9d891837bf4c44d17fe2d324, 2025)
- License: Apache 2.0

Files extracted from upstream source:

- All `.cpp`, `.hpp` and `.h` files, minus `main.cpp`, `spirv.h*`, `spirv_cross_c.*`, `spirv_hlsl.*`, `spirv_cpp.*`
- `include/` folder
- `LICENSE` and `LICENSES/` folder, minus `CC-BY-4.0.txt`

Versions of this SDK do not have to match the `vulkan` section, as this SDK is required
to generate Metal source from Vulkan SPIR-V.


## spirv-headers

- Upstream: https://github.com/KhronosGroup/SPIRV-Headers
- Version: vulkan-sdk-1.4.335.0 (b824a462d4256d720bebb40e78b9eb8f78bbb305, 2025)
- License: MIT

Files extracted from upstream source:

- `include/spirv/unified1/spirv.{h,hpp,hpp11}` with the same folder structure
- `LICENSE` (edited to keep only relevant license)


## spirv-reflect

- Upstream: https://github.com/KhronosGroup/SPIRV-Reflect
- Version: vulkan-sdk-1.4.335.0 (ef913b3ab3da1becca3cf46b15a10667c67bebe5, 2025)
- License: Apache 2.0

Version should be kept in sync with the one of the used Vulkan SDK (see `vulkan`
section).

Files extracted from upstream source:

- `spirv_reflect.h`, `spirv_reflect.c`
- `LICENSE`

Patches:

- `0001-zero-size-for-sc-sized-arrays.patch` ([GH-94985](https://github.com/godotengine/godot/pull/94985))
- `0002-spirv-headers.patch` ([GH-111452](https://github.com/godotengine/godot/pull/111452))


## swappy-frame-pacing

- Upstream: https://android.googlesource.com/platform/frameworks/opt/gamesdk/ via https://github.com/godotengine/godot-swappy
- Version: git (1198bb06b041e2df5d42cc5cf18fac81fcefa03f, 2025)
- License: Apache 2.0

Files extracted from upstream source:

- `include/common/`
- `include/swappy/{swappy_common.h,swappyVk.h}`
- `LICENSE`


## thorvg

- Upstream: https://github.com/thorvg/thorvg
- Version: 1.0.3 (d114cd9e3c32d7f77bc9b324ae5c71d7775cb7ae, 2026)
- License: MIT

Files extracted from upstream source:

- See `thorvg/update-thorvg.sh` for extraction instructions.
  Set the version number and run the script.

Patches:

- `0001-let-delete-be-delete.patch` ([GH-116024](https://github.com/godotengine/godot/pull/116024))


## tinyexr

- Upstream: https://github.com/syoyo/tinyexr
- Version: 1.0.13 (4946b5d92e13bcc8102ac2c8efd129596a90bf75, 2026)
- License: BSD-3-Clause

Files extracted from upstream source:

- `exr_reader.hh`
- `streamreader.hh`
- `tinyexr.{cc,h}`
- `LICENSE`

Patches:

- `0001-external-zlib.patch` ([GH-55115](https://github.com/godotengine/godot/pull/55115))


## ufbx

- Upstream: https://github.com/ufbx/ufbx
- Version: 0.21.3 (83bc7cf44f76bc8622de63b809a42b5d557cd733, 2026)
- License: MIT

Files extracted from upstream source:

- `ufbx.{c,h}`
- `LICENSE`


## vhacd

- Upstream: https://github.com/kmammou/v-hacd
- Version: git (1a49edf29c69039df15286181f2f27e17ceb9aef, 2020)
- License: BSD-3-Clause

Files extracted from upstream source:

- From `src/VHACD_Lib/`: `inc`, `public` and `src`
- `LICENSE`

Patches:

- `0001-bullet-namespace.patch` ([GH-27929](https://github.com/godotengine/godot/pull/27929))
- `0002-fpermissive-fix.patch` ([GH-27929](https://github.com/godotengine/godot/pull/27929))
- `0003-fix-musl-build.patch` ([GH-34250](https://github.com/godotengine/godot/pull/34250))
- `0004-fix-msvc-arm-build.patch` ([GH-34331](https://github.com/godotengine/godot/pull/34331))
- `0005-fix-scale-calculation.patch` ([GH-38506](https://github.com/godotengine/godot/pull/38506))
- `0006-gcc13-include-fix.patch` ([GH-77949](https://github.com/godotengine/godot/pull/77949))


## volk

- Upstream: https://github.com/zeux/volk
- Version: vulkan-sdk-1.4.335.0 (4f3bcee79618a9abe79f4c717c50379197c77512, 2025)
- License: MIT

Version should be kept in sync with the one of the used Vulkan SDK (see `vulkan`
section).

Files extracted from upstream source:

- `volk.h`, `volk.c`
- `LICENSE.md`


## vulkan

- Upstream: https://github.com/KhronosGroup/Vulkan-Headers
- Version: vulkan-sdk-1.4.335.0 (2fa203425eb4af9dfc6b03f97ef72b0b5bcb8350, 2025)
- License: Apache 2.0

Unless there is a specific reason to package a more recent version, please stick
to tagged SDK releases. All Vulkan libraries and headers should be kept in sync so:

- Update Vulkan SDK components to the matching tag (see "vulkan")
- Update volk (see "volk")
- Update glslang (see "glslang")
- Update spirv-headers (see "spriv-headers")
- Update spirv-cross (see "spirv-cross")
- Update spirv-reflect (see "spirv-reflect")

Files extracted from upstream source:

- `include/`
- `LICENSE.md`

`vk_enum_string_helper.h` is taken from the matching `Vulkan-Utility-Libraries`
SDK release: https://github.com/KhronosGroup/Vulkan-Utility-Libraries/blob/main/include/vulkan/vk_enum_string_helper.h

`vk_mem_alloc.h` is taken from https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator
Version: 3.3.0 (1d8f600fd424278486eade7ed3e877c99f0846b1, 2025)
`vk_mem_alloc.cpp` is a Godot file and should be preserved on updates.

Patches:

- `0001-VKEnumStringHelper-godot-vulkan.patch` ([GH-97510](https://github.com/godotengine/godot/pull/97510))
- `0002-VMA-godot-vulkan.patch` ([GH-97510](https://github.com/godotengine/godot/pull/97510))
- `0003-VMA-add-vmaCalculateLazilyAllocatedBytes.patch` ([GH-99257](https://github.com/godotengine/godot/pull/99257))


## wayland

- Upstream: https://gitlab.freedesktop.org/wayland/wayland
- Version: 1.24.0 (736d12ac67c20c60dc406dc49bb06be878501f86, 2025)
- License: MIT

Files extracted from upstream source:

- `protocol/wayland.xml`
- `COPYING`


# wayland-protocols

- Upstream: https://gitlab.freedesktop.org/wayland/wayland-protocols
- Version: 1.47 (88223018d1b578d0d8869866da66d9608e05f928, 2025)
- License: MIT

Files extracted from upstream source:

- `stable/tablet/README`
- `stable/tablet/tablet-unstable-v2.xml`
- `stable/viewporter/README`
- `stable/viewporter/viewporter.xml`
- `stable/xdg-shell/README`
- `stable/xdg-shell/xdg-shell.xml`
- `staging/color-management/README.md`
- `staging/color-management/color-management-v1.xml`
- `staging/fractional-scale/README`
- `staging/fractional-scale/fractional-scale-v1.xml`
- `staging/xdg-activation/README`
- `staging/xdg-activation/xdg-activation-v1.xml`
- `staging/xdg-system-bell/xdg-system-bell-v1.xml`
- `staging/pointer-warp/pointer-warp-v1.xml`
- `staging/pointer-warp/README`
- `unstable/idle-inhibit/README`
- `unstable/idle-inhibit/idle-inhibit-unstable-v1.xml`
- `unstable/pointer-constraints/README`
- `unstable/pointer-constraints/pointer-constraints-unstable-v1.xml`
- `unstable/pointer-gestures/README`
- `unstable/pointer-gestures/pointer-gestures-unstable-v1.xml`
- `unstable/primary-selection/README`
- `unstable/primary-selection/primary-selection-unstable-v1.xml`
- `unstable/relative-pointer/README`
- `unstable/relative-pointer/relative-pointer-unstable-v1.xml`
- `unstable/text-input/README`
- `unstable/text-input/text-input-unstable-v3.xml`
- `unstable/xdg-decoration/README`
- `unstable/xdg-decoration/xdg-decoration-unstable-v1.xml`
- `unstable/xdg-foreign/README`
- `unstable/xdg-foreign/xdg-foreign-unstable-v1.xml`
- `COPYING`

The following files are extracted from thirdparty sources:

- `mesa/wayland-drm.xml`: https://gitlab.freedesktop.org/mesa/mesa/-/blob/mesa-25.3.0/src/egl/wayland/wayland-drm/wayland-drm.xml


## wslay

- Upstream: https://github.com/tatsuhiro-t/wslay
- Version: 1.1.1+git (0e7d106ff89ad6638090fd811a9b2e4c5dda8d40, 2022)
- License: MIT

File extracted from upstream release tarball:

- Run `cmake .` to generate `config.h` and `wslayver.h`
  Contents might need tweaking for Godot, review diff
- All `.c` and `.h` files from `lib/`
- All `.h` in `lib/includes/wslay/` as `wslay/`
- `COPYING`

Patches:

- `0001-msvc-build-fix.patch` ([GH-30263](https://github.com/godotengine/godot/pull/30263))


## xatlas

- Upstream: https://github.com/jpcy/xatlas
- Version: git (f700c7790aaa030e794b52ba7791a05c085faf0c, 2022)
- License: MIT

Files extracted from upstream source:

- `source/xatlas/xatlas.{cpp,h}`
- `LICENSE`


## zlib

- Upstream: https://github.com/madler/zlib
- Version: 1.3.2 (da607da739fa6047df13e66a2af6b8bec7c2a498, 2026)
- License: zlib

Files extracted from upstream source:

- All `.c` and `.h` files, except `gz*.c` and `infback.c`
- `LICENSE`


## zstd

- Upstream: https://github.com/facebook/zstd
- Version: 1.5.7 (f8745da6ff1ad1e7bab384bd1f9d742439278e99, 2025)
- License: BSD-3-Clause

Files extracted from upstream source:

- `lib/{common/,compress/,decompress/,zstd.h,zstd_errors.h}`
- `LICENSE`

---

## 15. Build system (SCons) — 156 options

```
accesskit
agility_sdk_multiarch
alsa
angle
arch
auto
brotli
builtin_brotli
builtin_certs
builtin_clipper2
builtin_embree
builtin_enet
builtin_freetype
builtin_glslang
builtin_graphite
builtin_harfbuzz
builtin_icu4c
builtin_libjpeg_turbo
builtin_libogg
builtin_libpng
builtin_libtheora
builtin_libvorbis
builtin_libwebp
builtin_mbedtls
builtin_miniupnpc
builtin_msdfgen
builtin_openxr
builtin_pcre2
builtin_pcre2_with_jit
builtin_recastnavigation
builtin_rvo2_2d
builtin_rvo2_3d
builtin_sdl
builtin_wslay
builtin_xatlas
builtin_zlib
builtin_zstd
cc
cl
clang
compiledb
compiledb_gen_only
custom_modules_recursive
d3d12
dbus
debug_crt
debug_paths_relative
debug_symbols
default
deprecated
dev_build
dev_mode
disable_3d
disable_advanced_gui
disable_exceptions
disable_navigation_2d
disable_navigation_3d
disable_overrides
disable_path_overrides
disable_physics_2d
disable_physics_3d
disable_xr
dlink_enabled
dxgi
editor
engine_update_check
execinfo
extra
fast_unsafe
fontconfig
freetype
generate_bundle
glslang
gui
incremental_link
javascript_eval
libdecor
library
library_type
limit_transitive_includes
linker
linux
lto
macports_clang
mbedtls
metal
minizip
modules_enabled_by_default
msvc
ninja
ninja_auto_run
no
no_editor_splash
none
opengl3
optimize
platform
precision
production
profiler
profiler_path
profiler_record_on_demand
profiler_sample_callstack
profiler_track_memory
progress
proxy_to_pthread
psapi
pthread
pulseaudio
redirect_build_objects
scu_build
sdl
separate_debug_symbols
silence_msvc
simulator
single
speechd
steamapi
store_release
strict_checks
swappy
target
tests
threads
touch
udev
use_asan
use_assertions
use_closure_compiler
use_coverage
use_llvm
use_lsan
use_mingw
use_msan
use_pix
use_precise_math_checks
use_safe_heap
use_sowrap
use_static_cpp
use_tsan
use_ubsan
use_volk
verbose
vsproj
vulkan
warnings
wasm32
wasm_simd
wayland
werror
windows_subsystem
winrt
x11
x86_32
x86_64
xaudio2
```

---

## 16. @GlobalScope & GDScript

**@GlobalScope — 528 global constants** (enums के values समेत — print(), abs() जैसी utility functions इनमें शामिल नहीं; full list class reference में)। Notable: OK/FAILED, KEY_*, MOUSE_BUTTON_*, JOY_*, OP_*, PROPERTY_HINT_*, TYPE_*, SIDE_*, CORNER_*, KEY_MODIFIER_*, MARGIN_*…

**GDScript की सभी 36 annotations (source-extracted):**

@abstract, @export, @export_category, @export_color_no_alpha, @export_custom, @export_dir, @export_enum, @export_exp_easing, @export_file, @export_file_path, @export_flags, @export_flags_2d_navigation, @export_flags_2d_physics, @export_flags_2d_render, @export_flags_3d_navigation, @export_flags_3d_physics, @export_flags_3d_render, @export_flags_avoidance, @export_global_dir, @export_global_file, @export_group, @export_multiline, @export_node_path, @export_placeholder, @export_range, @export_storage, @export_subgroup, @export_tool_button, @icon, @onready, @rpc, @static_unload, @tool, @warning_ignore, @warning_ignore_restore, @warning_ignore_start

---

## 17. Editor extension points (BUILT-IN APIs)

जिन classes से editor extend होता है (सभी built-in; full method detail class reference में):

EditorCommandPalette, EditorContextMenuPlugin, EditorDebuggerPlugin, EditorDebuggerSession, EditorDock, EditorExportPlatform, EditorExportPlatformAppleEmbedded, EditorExportPlatformExtension, EditorExportPlatformPC, EditorExportPlugin, EditorExportPreset, EditorFeatureProfile, EditorFileDialog, EditorFileSystem, EditorFileSystemDirectory, EditorFileSystemImportFormatSupportQuery, EditorImportPlugin, EditorInspector, EditorInspectorPlugin, EditorInterface, EditorNode3DGizmo, EditorNode3DGizmoPlugin, EditorPaths, EditorPlugin, EditorProperty, EditorResourceConversionPlugin, EditorResourcePicker, EditorResourcePreview, EditorResourcePreviewGenerator, EditorResourceTooltipPlugin, EditorSceneFormatImporter, EditorScenePostImport, EditorScenePostImportPlugin, EditorScript, EditorScriptPicker, EditorSelection, EditorSettings, EditorSpinSlider, EditorSyntaxHighlighter, EditorToaster, EditorTranslationParserPlugin, EditorUndoRedoManager, EditorVCSInterface

**4 category clarity (user rule ke liye):** EditorPlugin/EditorImportPlugin/EditorExportPlugin/EditorInspectorPlugin/EditorScenePostImportPlugin आदि = BUILT-IN extension point APIs। इनके ऊपर बने plugins (Asset Library/Store से) = COMMUNITY PLUGIN।

---

## 18. Official Documentation Deep-Dive

(Official docs से research — English technical reference)

# Godot 4.7 Official Documentation Deep-Dive

> Scope: This reference was researched directly against the official Godot documentation at `docs.godotengine.org/en/stable`, which currently reflects the Godot 4.7 series (4.7-stable released 18 June 2026; the docs header on every fetched page reads "Godot Engine 4.7 documentation in English"). The latest maintenance release in the series is 4.7.2 (18 August 2026). All setting keys, class names, and identifiers are kept in exact English as they appear in the docs. Items that could not be verified against the fetched pages are explicitly marked **[unverified]**.

---

## 1. Project Settings

### How the system works

Project settings are stored in the plain-text INI file `project.godot` at the project root. They can be edited three ways: the Project Settings window (Project > Project Settings), from code via `ProjectSettings.set_setting()` / `get_setting()` / `has_setting()`, or by hand-editing the file. Settings only appear in `project.godot` when they differ from the default; a missing key means the default value applies. The Project Settings window has tabs: **General**, **Input Map**, **Localization**, **Globals** (autoloads), **Plugins**, and **Import Defaults**. By default only some settings are shown; the **Advanced Settings** toggle reveals everything (most advanced entries are hidden to reduce clutter).

Key mechanics documented on the ProjectSettings class page:

- Settings are addressed by full path including category, e.g. `"application/config/name"`.
- **Feature tags**: any setting can be overridden per platform/configuration (`.windows`, `.android`, `.web`, `.debug`, `.release`, `.editor`…) by adding the suffix to the key. `get_setting_with_override()` (and `get_setting_with_override_and_custom_features()`) resolves these at runtime.
- **`override.cfg`**: a file in the project root (or next to the exported binary) that overrides any project setting, still honoring the base settings' feature tags.
- Many settings are read once at startup; their runtime equivalents live in `Engine`, `DisplayServer`, `RenderingServer`, `PhysicsServer2D/3D`, `Viewport`, and `Window` — read from those instead after startup.
- Useful ProjectSettings methods: `set_as_basic()`, `set_as_internal()`, `set_restart_if_changed()`, `add_property_info()`, `load_resource_pack()`, `globalize_path()` / `localize_path()`.

### Top-level categories (General tab)

Verified against the ProjectSettings class reference (alphabetical):

- **accessibility** — new accessibility support settings: `accessibility/general/accessibility_support` (Auto / Always Active / Disabled) and `accessibility/general/updates_per_second` (default 60). Auto only processes accessibility updates when an assistive app (screen reader, Braille display) is active.
- **animation** — AnimationMixer behavior: `animation/compatibility/default_parent_skeleton_in_mesh_instance_3d` (compatibility toggle for the pre-4.6 `MeshInstance3D.skeleton` default) and warnings toggles such as `animation/warnings/check_angle_interpolation_type_conflicting`, `animation/warnings/check_invalid_track_paths`.
- **application** — the largest user-facing category. `application/config/*` (name, `name_localized`, description, icon, `windows_native_icon`, `macos_native_icon`, version, `custom_user_dir_name`, `use_custom_user_dir`, `use_hidden_project_data_directory`, `auto_accept_quit`, `quit_on_go_back`, `disable_project_settings_override`, `project_settings_override`) and `application/boot_splash/*` (bg_color, image, show_image, `minimum_display_time`, stretch_mode, use_filter), plus `application/run/*` (main_scene, `main_loop_type` default `"SceneTree"`, max_fps, `low_processor_mode`, `low_processor_mode_sleep_usec` default 6900, `delta_smoothing`, `frame_delay_msec`, `disable_stderr`, `disable_stdout`, `flush_stdout_on_print`, `load_shell_environment`, `enable_alt_space_menu`).
- **audio** — `audio/buses/*` (`channel_disable_threshold_db`, `channel_disable_time`, `default_bus_layout`), `audio/driver/*` (driver, `enable_input`, `mix_rate` default 44100, `mix_rate.web`, `output_latency`, `output_latency.web`), `audio/general/*` (`2d_panning_strength`, `3d_panning_strength`, `default_playback_type`, `default_playback_type.web`, `text_to_speech`, iOS-specific `mix_with_others` and `session_category`), and `audio/video/video_delay_compensation_ms`.
- **collada** — `collada/use_ambient` (import option for the legacy COLLADA importer).
- **collision** — defaults for 2D and 3D collision shape drawing/debug (layer names live in layer_names). **[Contents of this exact group in 4.7 not re-verified in the fetched excerpt.]**
- **compression** — `compression/formats/*` for gzip, zlib, zstd: `compression_level`, plus zstd `long_distance_matching` and `window_log_size`. These govern resource compression levels for saving.
- **debug** — `debug/canvas_items/*` (`debug_redraw_color`, `debug_redraw_time`), `debug/file_logging/*` (`enable_file_logging`, `enable_file_logging.pc`, `log_path` default `user://logs/godot.log`, `max_log_files`), `debug/gdscript/warnings/*` (a large set: `enable`, plus per-warning severities such as `assert_always_false`, `confusable_identifier`, `inference_on_variant`, `get_node_default_without_onready`, `int_as_enum_without_cast`, `deprecated_keyword`, and the `directory_rules` Dictionary defaulting to `{"res://addons": 0}`), and other `debug/settings/*` entries. Many debug settings only exist in editor/debug builds.
- **display** — `display/window/size/*` (viewport_width/height, `initial_position`, mode, `resizable`, `borderless`, `fullscreen`, `always_on_top`, `transparent`, `extend_to_title`), `display/window/stretch/*` (`mode`, `aspect` — **note the 4.7 default for new projects is now `canvas_items` + `expand`**, previously `disabled` + `keep`, per the 4.7 migration guide), `display/window/handheld/*` (orientation), per-mobile subgroups (android/ios), `display/mouse_cursor/*` (`custom_image`, `tooltip_position_offset`, `custom_image_hotspot`).
- **dotnet** — `dotnet/project/*` (C#/.NET project options, e.g. solution name and other .NET build settings used by the mono module).
- **file_customization** — `file_customization/action` and `file_customization/color`: per-file action (e.g. exclude from export) and color annotations shown in the FileSystem dock.
- **gui** — `gui/theme/custom` (custom theme/font resources), `gui/common/*` (e.g. `swap_cancel_ok`, `font_antialiasing`, `font_hinting`, `default_font_scale_factor`, `snap_controls_to_pixels`, `font_multichannel_signed_distance_field`), `gui/timers/*` (`incremental_search_max_time_msec`, `tooltip_delay_sec`, `text_edit_idle_detect_sec`, etc.).
- **input_devices** — `input_devices/pointing/*` (`emulate_touch_from_mouse`, `emulate_mouse_from_touch`, `emulate_touch_from_mouse` sub-options, `android/enable_long_press_as_right_click`, `android/enable_pan_and_scale_gestures`, `pen_tablet/driver`, `pen_tablet/driver.windows`) — the Input Map itself is defined under `input/*` and edited in the Input Map tab.
- **internationalization** — `internationalization/locale/*` (`fallback`, `allow`, `test`, `include_text_server_data`), `internationalization/locale/translation_remaps`, `internationalization/locale/translations`, `internationalization/locale/translation_add_builtin_strings_when_remote`, and `internationalization/rendering/*` (font fallbacks, `force_right_to_left_layout_direction`, direction handling, `shaped_text_padding` etc.).
- **layer_names** — friendly names for physics/render/navigation bit layers: `layer_names/2d_physics`, `layer_names/2d_render`, `layer_names/2d_navigation`, `layer_names/3d_physics`, `layer_names/3d_render`, `layer_names/3d_navigation`, and the avoidance group. Each is an Array of 21 strings (layers 1–20 + extra). **[Array length not re-verified for 4.7.]**
- **logging** — per-section log level overrides (`logging/*` sections such as `logging/file_logging`, each with `max_files`-style sub-options) used to tune verbose logs.
- **navigation** — `navigation/2d/*` and `navigation/3d/*` (default navigation maps, `default_cell_size`, `default_edge_connection_margin`, `default_link_connection_radius`), `navigation/avoidance/*` config, and navigation baking defaults.
- **network** — `network/limits/*` (`max_packet_size`, `websocket/max_buffer_size`…), `network/tls/*` (`tls/certificates/bundle`, editor bundle), SSL settings used by HTTP/HTTPS and WebSocket.
- **physics** — `physics/common/*` (notably `physics/common/physics_engine` — selects the 3D physics engine, e.g. GodotPhysics3D vs **Jolt Physics**; `physics/common/physics_ticks_per_second` default 60; `max_physics_steps_per_frame`; `enable_object_picking`; `physics/common/physics_interpolation` group), `physics/2d/*` (run on separate thread, `solver_iterations` group, `default_gravity`, `default_linear_damp`/`angular_damp`), `physics/3d/*` (same family plus `sleep_threshold`, `time_before_sleep`, `solver_iterations/solver_iterations`), and `physics/warnings/*`.
- **rendering** — the biggest category: `rendering/rendering_method` (`forward_plus` | `mobile` | `gl_compatibility`) and `rendering/rendering_method.mobile`/`.web`; `rendering/rendering_device/*` (driver selection incl. Vulkan/D3D12/Metal/OpenGL, `staging_buffer_block_size_kb`, **`fallback_to_opengl3`** which controls the "Fallback to OpenGL 3" behavior, `vrs_mode`); `rendering/anti_aliasing/quality/*` (MSAA 2D/3D, screen-space AA, TAA, FXAA, use_taa/hybrid); `rendering/environment/*` (defaults for background, glow, SSAO, SSIL, adjustments); `rendering/camera/*`; `rendering/culling/*` (occlusion culling BVH); `rendering/lights_and_shadows/*`; `rendering/meshes/*` (LOD bias); `rendering/reflections/*` (reflection atlas / probe sizes); `rendering/scaling_3d/*` (FSR upscaling, scale mode); `rendering/shader_compiler` / shader cache groups; `rendering/textures/*` (canvas textures, VRAM compression, default filters/mipmaps); `rendering/viewport/*` (HDR, `hdr_2d`, `transparent_background`, snapping, `snap_2d_transforms_to_pixel`); `rendering/low_end_mode/*`; `rendering/global_shader_parameters/…`? (global shader parameter groups); `rendering/mobile/*` (mobile-specific overrides). A top-level **`shaders`** group (e.g. `xr/shaders/enabled` sits under **xr** instead) — shader cache/compilation settings live under `rendering/shader_*`. **[Exact grouping of a few rendering subkeys is from 4.x knowledge and not re-verified verbatim for 4.7.]**
- **threading** — `threading/worker_pool/*`: `max_threads` (default `-1` = one thread per logical CPU core) and `low_priority_thread_ratio` (default 0.3) — controls `WorkerThreadPool`.
- **xr** — `xr/shaders/enabled` (fallback shaders for VR rendering, needed for mobile/compatibility-style shaders in XR) and OpenXR-related defaults (`xr/openxr/*` default action maps etc.).

### Notable advanced/hidden settings

- Everything behind the **Advanced Settings** toggle (most of `physics/*` internals, `rendering/*` internals, `debug/settings/*`, `application/run/*` extras).
- `application/config/project_settings_override` and `application/config/disable_project_settings_override` — control `override.cfg` behavior itself.
- `application/run/main_loop_type` — replace `SceneTree` with a custom `MainLoop` subclass (used together with `--main-loop`).
- `physics/common/physics_engine` — swap 3D physics to Jolt Physics. Jolt-related behavior changes in 4.7 are listed in the migration guide (see Section 9).
- `rendering/rendering_device/fallback_to_opengl3` — toggles the automatic Compatibility fallback (see Section 6).
- `audio/general/default_playback_type.web` — Sample vs Stream playback on web exports.
- Feature-tag suffixed variants (`.web`, `.debug`, `.release`, `.editor`, `.android`, `.ios`, `.windows`, `.macos`, `.linuxbsd`, `.patch_debug`…) — "hidden" per-platform variants visible mainly when editing `project.godot` directly.

Source: https://docs.godotengine.org/en/stable/tutorials/editor/project_settings.html
Source: https://docs.godotengine.org/en/stable/classes/class_projectsettings.html

---

## 2. Editor Settings

EditorSettings is a singleton class (`EditorInterface.get_editor_settings()`) that holds **project-independent, per-user** settings, visible under Editor > Editor Settings. Property names use slash delimiters; values can be any Variant; settings are saved automatically when changed. It also stores editor shortcuts (`add_shortcut`, `get_shortcut`, `get_shortcut_list`, `is_shortcut`), favorites and recent dirs for the FileSystem dock, and project metadata.

### Top-level sections (EditorSettings class reference, verified entries)

- **asset_store** — `asset_store/available_urls`, `asset_store/use_threads`. This is the editor-side configuration of Godot 4.7's new built-in **Asset Store** (the successor to the old Asset Library tab; 4.7's release notes headline the new Asset Store with preview zooming and asset ratings).
- **debugger** — `debugger/auto_switch_to_remote_scene_tree`, `debugger/auto_switch_to_stack_trace`, `debugger/max_node_selection`, `debugger/profile_native_calls`, `debugger/profiler_frame_history_size`, `debugger/profiler_frame_max_functions`, `debugger/profiler_target_fps`, `debugger/remote_inspect_refresh_interval`, `debugger/remote_scene_tree_refresh_interval`.
- **docks** — `docks/filesystem/*` (`always_show_folders`, `ask_before_moving_files`, `automatically_open_created_scripts`, `other_file_extensions`, `textfile_extensions`, `thumbnail_size`), `docks/property_editor/*` (`auto_refresh_interval`, `subresource_hue_tint`), `docks/scene_tree/*` (`ask_before_deleting_related_animation_tracks`, `ask_before_revoking_unique_name`, `auto_expand_to_selected`, `center_node_on_reparent`, `hide_filtered_out_parents`, `start_create_dialog_fully_expanded`, `accessibility_warnings`).
- **editors/2d** — bone editor colors (`bone_color1`, `bone_color2`, `bone_ik_color`, `bone_outline_color`, `bone_selected_color`), `bone_outline_size`, `bone_width`, grid/guides colors, `selection_rectangle_color`, `smart_snapping_line_color`, `viewport_border_color`, `zoom_speed_factor`, `use_integer_zoom_by_default`, `ruler_width`, `auto_resample_delay` (for FreeType font hinting in the 2D editor).
- **editors/3d** — `default_fov`, `default_z_far`, `default_z_near`; grid (`grid_color`, `primary_grid_color`, `secondary_grid_color`, `grid_size`, `grid_division_level_min/max/bias`, grid plane toggles `grid_xy_plane`/`grid_xz_plane`/`grid_yz_plane`, `primary_grid_steps`); navigation (`navigation_scheme`, `pan_mouse_button`, `zoom_mouse_button`, `orbit_mouse_button`, `zoom_style`, `emulate_3_button_mouse`, `emulate_numpad`, `warped_mouse_panning`, `invert_x_axis`, `invert_y_axis`, `show_viewport_navigation_gizmo`, `show_viewport_rotation_gizmo`); navigation feel (orbit/translation inertia and sensitivity, zoom inertia, `angle_snap_threshold`); freelook (`freelook_base_speed`, `freelook_inertia`, `freelook_sensitivity`, `freelook_activation_modifier`, `freelook_navigation_scheme`, `freelook_invert_y_axis`, `freelook_speed_zoom_link`); gizmo sizing (`manipulator_gizmo_size`, `manipulator_gizmo_opacity`), `active_selection_box_color`, `selection_box_color`, `show_gizmo_during_rotation`, `view_plane_rotation_gizmo_scale`.
- **editors/3d_gizmos** — dozens of `gizmo_colors/*` (aabb, camera, csg, decal, fog_volume, gridmap_grid, ik_chain, instantiated, joint, joint_body_a/b, lightmap_lines, lightprobe_lines, occluder, particle_attractor, particle_collision, particles, path_tilt, reflection_probe, selected_bone, skeleton, spring_bone_collision, spring_bone_inside_collision, spring_bone_joint, stream_player_3d, visibility_notifier, voxel_gi) and `gizmo_settings/*` (`bone_axis_length`, `bone_shape`, `lightmap_gi_probe_size`, `path3d_tilt_disk_size`, `show_collision_shapes_only_when_selected`).
- **editors/animation** — `autorename_animation_tracks`, `confirm_insert_track`, `default_animation_step`, `default_create_bezier_tracks`, `default_create_reset_tracks`, `default_fps_mode`, `default_fps_compatibility`, `insert_at_current_time`, onion skins (`onion_layers_past_color`, `onion_layers_future_color`).
- **editors/audio_buses** — dB meter colors (active/inactive max/min/normalized, `tint_over_color`, `tint_under_color`).

Other standard sections of the Editor Settings dialog (verified via cross-references on other pages and the 4.x settings tree; not all re-verified verbatim in 4.7):

- **text_editor** — appearance (theme, font, gutters, minimap, lines), behavior (indent, auto-brace, completion, callhints), files (trim whitespace, autosave, restore on load), script list, external editor choice.
- **interface** — editor (main theme, scale, display scale, single-window mode), scene tabs, theme (preset + accent colors + contrast), multiplayer (profile visibility).
- **network** — `network/http_proxy/*` (host, port, use custom) and editor update-check/asset download settings. **[Exact subkeys not re-verified for 4.7.]**
- **filesystem** — directories (default project path), `directories_autoscan`, on_save (safe save on exit, compress), import (keep `.import` files, metadata save format, AVIF/WebP import quality).
- **run** — window placement (rect, force font, auto save before run, output font size).
- **shortcuts** — every editor action's `Shortcut` resource, editable per-user and exportable.
- **dotnet** — external editor (Visual Studio 2022, VS Code, MonoDevelop, Visual Studio for Mac, JetBrains Rider), solutions, build options. Rider's Godot support has been built-in since 2024.2.
- **export** — per-platform tooling paths: Windows (`Sign Tool` path for `SignTool.exe`/`osslsigncode`), macOS (`rcodesign` path), Android (`Java SDK Path`, `Android SDK Path`), Web (HTTP/HTTPS proxy + firewall exception lists for external docs/class reference), plus `export/automatic_project_version`? **[last item unverified]**.
- Additional per-editor option groups exist for GridMap, polygon editor, shader editor, tile map/tile pattern editors, version control (VCS plugin settings), and XR. **[Individual subkeys not re-verified for 4.7.]**

Source: https://docs.godotengine.org/en/stable/classes/class_editorsettings.html
Source: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html (Dotnet / external editors section)
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html (Android SDK / Java SDK paths)

---

## 3. GDScript in 4.7

GDScript is a high-level, object-oriented, imperative, **gradually typed** language built for Godot, with Python-like indentation syntax — but it is entirely independent of Python. The reference page documents: identifiers (ASCII + most UAX#31 Unicode; "confusable" characters and emoji disallowed), the full keyword table (`if/elif/else`, `for`, `while`, `match` with `when` pattern guards, `class`, `class_name`, `extends`, `is`, `as`, `in`, `signal`, `func`, `static`, `const`, `enum`, `var`, `breakpoint`, `preload`, `await`, `yield` — kept only as a transition keyword from 3.x, `assert`, `void`, `PI`, `TAU`, `INF`, `NAN`), operator precedence, and semantics quirks worth memorizing: `/` on two ints is integer division; `%` is int-only (use `fmod()` for floats, `posmod()` for mathematically correct signs); `is_same()` for strict comparisons; `is_equal_approx()` for floats.

### Features

- **Static typing**: explicit types (`var x: int`), inference (`var y := 5`), typed function signatures and return types. Since 4.7, a method overriding a method with a typed return inherits the return type and requires an explicit `return` (a breaking change listed in the 4.7 migration guide, GH-115763).
- **Typed arrays**: `Array[int]`, `Array[String]`, etc. (e.g. `var xs: Array[int] = []`), plus the packed arrays `PackedInt32Array`, `PackedFloat32Array`, `PackedVector2Array`, `PackedStringArray`, `PackedByteArray`, … Typed arrays are checked at assignment and are faster than untyped `Array`; you can still get an untyped view via `Array` assignment with a runtime conversion. **[Exact doc phrasing on typed-array conversion not re-verified for 4.7.]**
- **Async**: `await` on signals or coroutines. A function that calls `await` becomes a coroutine; the reference page explicitly lists `await` as a keyword awaiting "signals or coroutines". Signals can carry typed arguments; lambdas and `Callable` are first-class.
- **class_name / @icon**: scripts can register as global classes with an optional icon; `preload`, inner classes, `super` calls.

### Export annotations

`@export` makes a member saved with the resource, editable in the Inspector, and transferred over RPCs. An exported variable must be initialized with a constant or have a type specifier. The full documented family:

- `@export`, `@export_group`, `@export_subgroup`, `@export_category` (Inspector grouping — categories break inheritance organization, use carefully).
- `@export_file`, `@export_file("*.txt")`, `@export_dir`, `@export_global_file`, `@export_global_dir` (global filesystem paths; global ones are tool-mode only), `@export_multiline`.
- `@export_range(min, max, step, "or_less", "or_greater", "exp", "hide_slider", "suffix:unit")` — range with snapping, exponential slider, and unit suffix; `@export_enum`, `@export_exp_easing`, `@export_node_path("Node2D", ...)`, `@export_flags("Fire", "Water", "Earth", "Wind")` and flag variants for 2D/3D physics, navigation and avoidance layers.
- `@export_storage` — serializes a property without showing it in the Inspector (stored + duplicated, unlike plain vars).
- `@export_custom(PROPERTY_HINT_*, hint_string, usage_flags)` — arbitrary property hints; the page showcases `PROPERTY_HINT_INPUT_NAME` (with `show_builtin` and `loose_mode` hint strings) and a `suffix:m` example.
- `@export_tool_button("Label", "IconName")` — exports a `Callable` as a clickable Inspector button for `@tool` scripts; icons must be built-in editor icons, custom project icons are not supported.
- Documented pitfalls: values changed from a tool script need `notify_property_list_changed()` to refresh the Inspector; reading an exported variable in `_init()` returns the annotation default (scene/resource values are applied after construction — read them in `_ready()` or in a setter).

### @rpc

```gdscript
@rpc(mode, sync, transfer_mode, transfer_channel)
```

Equivalent to `@rpc("authority", "call_remote", "reliable", 0)`:

- `mode`: `"authority"` (only the multiplayer authority — the server by default, changeable with `Node.set_multiplayer_authority()`) or `"any_peer"` (clients may call remotely; use for user input).
- `sync`: `"call_remote"` (not executed locally) or `"call_local"` (executed on the calling peer too — needed when the server is also a player).
- `transfer_mode`: `"unreliable"`, `"unreliable_ordered"` (late packets dropped), or `"reliable"` (resends until acknowledged; significant performance penalty).
- `transfer_channel`: channel index; the first three arguments may be given in any order but the channel must always be last. The default channel 0 is actually three channels — one per transfer mode.

Calls are made with `Callable.rpc()` (all peers) or `Callable.rpc_id(peer)`; `multiplayer.get_remote_sender_id()` identifies the caller. C# equivalent is the `[Rpc]` attribute.

### Limitations

- Gradual typing — untyped code remains valid, with reduced performance and fewer compile-time checks.
- Per the docs' networking page, the high-level multiplayer API is UDP-based (ENet/WebRTC/WebSocket backends); the web platform lacks raw TCP/UDP and some higher-level features.
- Operator semantics differences vs Python/JS (int division, `%` truncation) as noted above.
- Lambdas capture and some warning classes (e.g. `confusable_capture_reassignment`) exist as documented warnings rather than errors — the `debug/gdscript/warnings/*` project settings let you re-scope warnings per directory (`directory_rules`, default `{ "res://addons": 0 }`).
- Performance-critical code is a fit for GDExtension/C++ instead; GDScript compiles to its own bytecode/interpreter.
- **[Unverified for 4.7 from fetched pages]**: GDScript's claimed "allow implementing Java interfaces from GDScript" — listed as a 4.7 release-notes headline for Android — was seen only in the announcement, not in the fetched reference pages.

Source: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
Source: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html
Source: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
Source: https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html

---

## 4. C# / .NET support

- C# is implemented on the **modern .NET runtime** and requires the special **.NET-enabled editor build** from the Godot website; the standard executable has no C# support. Godot bundles the runtime parts needed to run compiled games, but build tools (MSBuild, compiler) come from the separately installed **.NET SDK**.
- **Required .NET version (current stable docs, C# basics page):** "Godot 4.5 requires .NET 8 or later, but exporting to Android requires .NET 9 or later." This sentence appears verbatim in the 4.7 documentation — treat it as the operative requirement for the 4.7 series (the wording referencing 4.5 appears not to have been updated; **verify against 4.7 release notes before relying on it**). Install the 64-bit SDK with a 64-bit editor.
- **Platform support:** Since Godot 4.2, C# projects support all desktop platforms (Windows, Linux, macOS) plus Android and iOS. Android and iOS support is **experimental** with limitations: iOS export can only be done from macOS, and the official iOS simulator export templates support only the `x64` architecture. C# projects **cannot be exported to the web at all** — the docs explicitly recommend Godot 3 for C# on web. (WebAssembly/.NET support is tracked upstream but not shipped in 4.7.)
- **Workflow:** attaching the first C# script generates a `.sln`/`.csproj` plus `.godot/mono` utilities; everything except `.godot` should be committed. The C# API uses PascalCase, `GD.Print()` style statics, properties instead of getters/setters; external editors supported: Visual Studio 2022, VS Code, MonoDevelop, Visual Studio for Mac, JetBrains Rider (built-in Godot support since Rider 2024.2). Assemblies must be rebuilt (the editor's Build button) for new exported variables, signals, or tool-script changes to appear.
- **Known limitations / gotchas (documented):** editor plugin authoring is possible but convoluted; hot-reload does not preserve state except exported variables; class names must match file names; `Call()`/`CallDeferred()`/`Get()`/`Set()`/`Connect()` string APIs expect the original snake_case names (use the generated `StringName` caches: `PropertyName`, `MethodName`, `SignalName`).
- **GDExtension interplay:** GDExtension and C#/.NET are separate extension systems — GDExtension loads native shared libraries via the `.gdextension` mechanism, while C# code runs on the .NET runtime; both can coexist in one project. Native GDExtension classes appear to C# as engine types, but there is no direct C#-to-native-code bridge through GDExtension — C++ interop still goes through the engine API. **[The preceding interplay statement is a summary of standard 4.x behavior; the exact 4.7 wording was not captured in the fetched pages — marked accordingly.]**

Source: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html
Source: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html

---

## 5. GDExtension

GDExtension is a Godot-specific technology that lets the engine **interact with native shared libraries at runtime** — native code without compiling it into the engine. It is explicitly *not* a scripting language and has no relation to GDScript.

### How it works — three components

1. `gdextension_interface.h` — the set of C functions Godot and the extension use to communicate.
2. `extension_api.json` — the machine-readable list of C functions exposed from Godot's APIs (core features); generated at build time from the engine, and what bindings use to generate their code.
3. `*.gdextension` — the config file Godot reads to load an extension (INI-style, with sections).

### The `.gdextension` file — Configuration section (verified table)

| Property | Type | Description |
| --- | --- | --- |
| `entry_symbol` | String | Name of the entry function for initializing the extension (defined in `register_types.cpp` when using godot-cpp). Required. |
| `compatibility_minimum` | String | Minimum compatible engine version; stops older Godot builds from loading the extension. Supported since Godot 4.1. |
| `compatibility_maximum` | String | Maximum compatible engine version; stops newer Godot builds from loading it. Supported since Godot 4.3. |
| `reloadable` | Boolean | Reload the extension on recompilation (godot-cpp supports this since 4.2); mainly for development/debugging. |

The file additionally carries `[libraries]` sections listing the per-platform binary (with feature tags such as `windows.debug.x86_64`, `linux.release.arm64`, `macos.debug`, `web.wasm32`, …), `[dependencies]` entries, and an `[icons]` section. **[The libraries/dependencies/icons sections are documented on the same page but their full tables were not captured in the fetched excerpt — see the page itself.]**

### API versioning

`extension_api.json` carries a built-in version and hashes; bindings like godot-cpp must match the engine's API. The docs state godot-cpp's version-compatibility rules "apply to all GDExtensions": each extension declares `compatibility_minimum` (and optionally `compatibility_maximum`) so the engine refuses to load binaries against incompatible API versions. `extension_api.json` also contains per-build options that can change the exposed API. **[Statement about version/hash mechanics beyond the compatibility table is standard 4.x knowledge.]**

### Limitations vs modules

- A **module** is compiled into the engine binary and can touch engine internals directly; a **GDExtension** only sees the public C API surface — it cannot modify engine internals or use private APIs.
- Each platform/architecture (and web, where supported) needs its own compiled library; distribution means shipping multiple binaries.
- Editor integration and debugging are more limited than for GDScript or built-in modules; hot-reload is opt-in (`reloadable`) and intended for development.
- Community bindings (Rust, D, Swift, etc.) are built on the same C interface; the docs direct users to godot-cpp or community bindings rather than writing extensions from scratch.

Source: https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/index.html
Source: https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/what_is_gdextension.html
Source: https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/gdextension_file.html

---

## 6. Rendering: Forward+ vs Mobile vs Compatibility

Godot ships **three renderers** (the "rendering method"): **Forward+** (most advanced, desktop-only, default on desktop), **Mobile** (fewer features, faster on simple scenes, default on mobile), and **Compatibility** ("GL Compatibility", least advanced, default on web). Forward+ and Mobile are **RenderingDevice-based** renderers — RenderingDevice is the abstraction between renderer and rendering driver — and use **Vulkan, Direct3D 12, or Metal** as the driver; Compatibility uses **OpenGL** (the fallback setting is literally named "Fallback to OpenGL 3").

Supported method + driver combinations (internal rendering architecture page):

- Vulkan + Forward+ / Vulkan + Mobile (optionally through **MoltenVK** on macOS and iOS)
- Direct3D 12 + Forward+ / Direct3D 12 + Mobile
- Metal + Forward+ / Metal + Mobile
- OpenGL + Compatibility (optionally through **ANGLE** on Windows and macOS)

Since Godot 4.4, with Forward+/Mobile, if Vulkan isn't supported the engine falls back to Direct3D 12 and vice versa, then to Compatibility if no RenderingDevice backend works; this fallback can be disabled via Rendering > Rendering Device > Fallback to OpenGL 3 in the Project Settings.

### Overall comparison (full table content from "Overview of renderers")

| Feature | Compatibility | Mobile | Forward+ |
| --- | --- | --- | --- |
| Required hardware | Older or low-end. | Newer or high-end; requires Vulkan, Direct3D 12, or Metal. | Newer or high-end; requires Vulkan, Direct3D 12, or Metal. |
| Runs on new hardware | Yes. | Yes. | Yes. |
| Runs on old / low-end hardware | Yes. | Yes, but slower than Compatibility. | Yes, but slowest of all renderers. |
| Runs on hardware without RenderingDevice support | Yes. | No. | No. |
| Target platforms | Mobile, low-end desktop, web. | Mobile, desktop. | Desktop. |
| Desktop | Yes. | Yes. | Yes. |
| Mobile | Yes (low-end). | Yes (high-end). | Supported, but poorly optimized — use Mobile or Compatibility. |
| XR | Supported, but not recommended — use Mobile. | Yes; recommended for desktop and standalone headsets. | Supported, but poorly optimized — use Mobile or Compatibility. |
| Web | Yes. | No. | No. |
| 2D games | Yes. | Yes, but Compatibility is usually good enough for 2D. | Yes, but Compatibility is usually good enough for 2D. |
| 3D games | Yes. | Yes. | Yes. |
| Feature set | 2D and core 3D features. | Most rendering features. | All rendering features. |
| 2D rendering features | Yes. | Yes. | Yes. |
| Core 3D rendering features | Yes. | Yes. | Yes. |
| Advanced rendering features | No. | Yes, limited by mobile hardware. | Yes — all rendering features are supported. |
| New features | Some new rendering features are added to Compatibility, after Mobile and Forward+. | Most new rendering features are added to Mobile, usually together with Forward+. | All new features are added to Forward+ first, as the focus of new development. |
| Rendering cost | Low base cost, but high scaling cost. | Medium base cost, medium scaling cost. | Highest base cost, and low scaling cost. |
| Rendering driver | OpenGL. | Vulkan, Direct3D 12, or Metal. | Vulkan, Direct3D 12, or Metal. |

### Technical notes (internal rendering architecture)

- **Forward+** is a clustered renderer supporting effectively unlimited lights (performance depends on screen coverage; shadow-less lights are nearly free when small on screen).
- **Mobile** is a forward renderer with a traditional single-pass approach: **8 OmniLights + 8 SpotLights per Mesh resource, and 256 + 256 in the camera view — hardcoded limits**. It uses an R10G10B10A2 UNORM buffer for 3D (or RGBA16F when `rendering/viewport/hdr_2d` is enabled for full HDR), uses Vulkan sub-passes, and relies on raster-only shaders (fragment/vertex) because compute-shader support is limited on mobile GPUs. It can beat Forward+ in simple scenes, on low-end GPUs/iGPUs and in VR.
- **Compatibility** is a traditional non-clustered forward renderer ("GL Compatibility"): single-pass for lights without shadows, multi-pass for shadow-casting lights (first pass draws all shadow-less lights + up to one shadowed DirectionalLight3D; each additional pass adds one shadowed OmniLight3D + one SpotLight3D + one DirectionalLight3D). Output is tonemapped/sRGB with **no HDR support**; most post-processing effects are unavailable; the max lights visible at once is adjustable in project settings. VoxelGI and SDFGI are Forward+-only; LightmapGI works in all.
- 4.7's release announcement highlights **HDR output** ("colors of never-before-reached intensity") as a flagship rendering feature of this version — the docs' rendering pages above don't yet detail it in the fetched excerpts. **[Details of HDR output config not verified in docs.]**

Source: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
Source: https://docs.godotengine.org/en/stable/engine_details/architecture/internal_rendering_architecture.html

---

## 7. Platform-specific export capabilities

All export pages note the common mechanism: project files are packed into a `data.pck` bundled with a stripped, optimized export-template binary (no editor/debugger). Full per-platform option lists live in the `EditorExportPlatform*` class references (e.g. `EditorExportPlatformWindows`, `EditorExportPlatformLinuxBSD`), and export options can be overridden with `GODOT_*` environment variables in CI.

- **Windows** — Architectures: `x86_64` (default), `x86_32`, `arm64` (native Windows-on-ARM, e.g. Snapdragon X Elite; avoids the Prism emulator). PCK embedding is supported only up to ~3.89 GB total (executable + embedded PCK, so ~3.75 GB practical PCK). Automatic icon conversion from the project icon to ICO. Code signing via the Windows SDK's `SignTool.exe` or cross-platform `osslsigncode` (configured under Editor Settings > Export > Windows `Sign Tool`, then preset options `Enabled`, `Identity`, etc.). Env vars: `GODOT_SCRIPT_ENCRYPTION_KEY`, `GODOT_WINDOWS_CODESIGN_*`.
- **Linux/BSD** — Seven architectures: `x86_64` (default), `x86_32`, `arm64` (Raspberry Pi 3+), `arm32`, `rv64` (RISC-V), `ppc64`, `loongarch64` — the last three have **no official export templates** and must be self-compiled. Env var: `GODOT_SCRIPT_ENCRYPTION_KEY`.
- **macOS** — Official templates produce a Universal 2 (x86_64 + ARM64) `.app` bundle; distribution as raw `.app`, `.zip`, or `.dmg` (DMG only when exporting from macOS). `.app` bundles exported from Windows lack the executable flag — fix with `chmod +x` on the `Contents/MacOS` executable and any `Contents/Helpers`. Signing + notarization: from macOS with Xcode (`codesign` + `notarytool`), or cross-platform with `rcodesign` (Editor Settings > Export > macOS > rcodesign); without an Apple Developer ID, ad-hoc signing via "Built-in (ad-hoc only)" (Gatekeeper will still block non-notarized downloads). Hardened Runtime entitlements (Allow JIT, Allow Unsigned Executable Memory, Allow DYLD Environment Variables, Disable Library Validation — needed for GDExtension add-ons), App Sandbox entitlements (Network Server/Client, Device USB/Bluetooth for controllers, Files Downloads/Pictures/Music/Movies/User Selected, Helper Executables) — App Sandbox is mandatory for App Store distribution. Env vars: `GODOT_MACOS_CODESIGN_*`, `GODOT_MACOS_NOTARIZATION_*`.
- **Android** — Requires OpenJDK 17 (recommended; higher works) and the Android SDK (Platform-Tools ≥ 35.0.0, Build-Tools 35.1, Platform 35, NDK r28b / 28.1.13356709, CMake 3.10.2.4988404), configured via `Java SDK Path` and `Android SDK Path` in Editor Settings. Launcher icons: Main (≥192×192, pre-Android 8), Adaptive foreground/background (≥432×432, Android 8+, 66dp safe zone), optional Themed monochrome (Android 13+), with documented fallback chains. Google Play requires **AAB** (mandatory for new apps since August 2021) signed with a non-debug keystore (`keytool -genkey`; uncheck "Export With Debug"). APKs contain both ARMv7 + ARMv8 libraries unless one is unchecked. C# export exists since 4.2 but is **experimental**. 4.7 adds streamlined standalone Android exporting/publishing and Android XR support (release notes). Env vars: `GODOT_ANDROID_KEYSTORE_*`.
- **iOS** — Export only from macOS with Xcode (produces an Xcode project, not a store-ready IPA directly). `App Store Team ID` (10-char code, e.g. `ABCDE12XYZ`) and unique `Bundle Identifier` are required. **The iOS simulator only supports the Compatibility renderer.** Apple Silicon Macs can run exported iOS apps natively. iOS plugins are supported; C# export since 4.2 is experimental (simulator templates x64-only, export from macOS only). Env vars: `GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG/RELEASE`.
- **Web (HTML5/WASM)** — Requires WebAssembly + **WebGL 2.0**; Godot 4 targets WebGL 2 only, so the **Compatibility renderer is the only choice** (no WebGPU yet — a prerequisite for Forward+/Mobile on web). **C# cannot be exported to the web** (use Godot 3 for that). Single-threaded export is the default (since 4.3) — recommended for itch.io/Poki/CrazyGames compatibility and better macOS/iOS behavior; multithreading needs `SharedArrayBuffer` plus `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers (or the Progressive Web App service-worker workaround, still requiring a secure HTTPS context). **GDExtensions can be loaded on web only if "Extensions Support" is enabled and the extension is specifically compiled for web** (WASM), with the same cross-origin-isolation requirements. Web audio defaults to the Web Audio API "Sample" playback mode: no AudioEffects, reverb, doppler, or procedural audio, and positional audio may misbehave (switch to `Stream` playback via `Audio > General > Default Playback Type` `.web` override for full features at higher latency). Persistence uses IndexedDB cookies; `user://` won't persist in private browsing/iframes without third-party cookies. Export produces `.html` + `.js` + `.wasm` (engine) + `.pck` (game) + `.png` (splash); renaming exported files is not supported.

Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_linux.html
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

---

## 8. Headless, command-line and CI usage

On Windows/Linux, run the editor binary from a terminal directly; on macOS run `Godot.app/Contents/MacOS/Godot`. Unknown command-line arguments are silently ignored (no warning). Key options from the command line reference:

- **Running**: `--path` (project path containing `project.godot`), `-e/--editor`, `-p/--project-manager`, `--recovery-mode` (disables tool scripts, editor plugins, GDExtension addons — things that typically crash startup), `--scene`, `--main-pack`, `--rendering-method` (`forward_plus` | `mobile` | `gl_compatibility`), `--rendering-driver`, `--render-thread`, `--gpu-index` (Forward+/Mobile only), `-l/--language`, `--log-file`, `--quit`, `--quit-after N`.
- **Headless**: `--headless` = `--display-driver headless --audio-driver Dummy`; useful for servers and with `--script`. Any Godot binary (editor or export template) can run headless since 4.0 — no special server binary needed (unlike Godot 3.x). Editor binary can run servers but the export template is smaller/optimized.
- **Scripting/CI**: `-s, --script` (run a `.gd` script as resource path or absolute path), `--check-only` (parse only, quit — validation in CI), `--main-loop <ClassName>`, `--import` (starts the editor, waits for resource import, quits — implies `--editor` and `--quit`; essential before first export in CI), `--export-release <preset> <path>`, `--export-debug` (implies `--import`), `--export-pack` (PCK or ZIP by extension), `--export-patch` + `--patches` (changed files only), `--install-android-build-template`.
- **Export in CI**: `godot --headless --path <project> --export-release "Linux/X11" /var/builds/project` — `--headless` is **required** on machines without GPU (CI); with GPU it merely suppresses the window. The preset name must match `export_presets.cfg` (quote names with spaces, e.g. `"Windows Desktop"`); the target directory must exist; export templates must be installed.
- **Dedicated servers**: create a dedicated-server export preset and switch its Resources tab export mode to **Export as dedicated server** — adds the `dedicated_server` feature tag automatically (which also forces headless) and lets you **Strip Visuals** (textures/materials replaced by placeholder classes that keep image size), **Keep**, or **Remove** resources. Alternative: export a PCK next to a renamed export-template binary. Detect server mode in code via `DisplayServer.get_name() == "headless"` or a custom user argument checked with `"--server" in OS.get_cmdline_user_args()` (arguments after the `--`/`++` separator). 4.7 also ships a new per-platform export-template downloader for CI-friendly template management (release notes).

Source: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
Source: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html

---

## 9. Deprecated / experimental items in current stable docs

### Explicitly experimental (flagged in stable docs)

- **C# on Android and iOS** — experimental since 4.2; iOS simulator templates are x64-only and iOS export requires macOS.
- **C# on Web** — not supported at all (docs recommend Godot 3).
- **Web GDExtensions and multithreading** — require explicit opt-in and cross-origin isolation; extensions must be compiled for WASM.
- **iOS simulator** — Compatibility renderer only.
- 4.7's release notes also describe the new **Asset Store**, **Android XR / Steam Frame support**, and Perfetto tracing defaults as new headline features whose long-term stability is not yet promised. **[Whether any of these carry an official "experimental" label in the class docs was not verified page-by-page.]**

### Breaking changes / deprecations (from "Upgrading from Godot 4.6 to Godot 4.7")

- New-project defaults changed: stretch mode `canvas_items` + aspect `expand` (was `disabled`/`keep`) — `display/window/stretch/mode` and `.../aspect`.
- `AudioStreamPlayer` default `area_mask` changed from `1` to `0` (disabled) — affects `audio_bus_override` on Area2D/Area3D setups.
- Mouse/keyboard device IDs changed from `0` to `InputEvent.DEVICE_ID_MOUSE` / `InputEvent.DEVICE_ID_KEYBOARD`.
- Setting an element of a packed array no longer triggers the setter for the whole packed-array property.
- Overriding a method with a typed return now inherits the return type (requires explicit `return`).
- **Jolt Physics** (the alternate 3D physics engine): `WorldBoundaryShape3D.plane.d` sign convention now matches Godot Physics (flip signs when migrating); `SoftBody3D` mass now defaults to 1 kg for the whole body (not auto ~1 kg/point); `SoftBody3D.linear_stiffness` applies like Godot Physics (re-tweak `linear_stiffness`/`damping_coefficient`); `Area3D` now reports overlaps with `SoftBody3D` (fix collision layers if unwanted).
- `LinearToSRGB` visual shader no longer clamps to `[0, 1]` on Mobile/Forward+.
- API table changes: `Object`'s `is_*` class parameter `String`→`StringName`; `ZIPPacker.start_file` gained `permissions` and time parameters; `OptimizedTranslation.generate` returns `bool` (C# binary incompatible); `Control.accessibility_*` moved to `AccessibilityServer.Accessibility*Mode` (C# source/binary incompatible); `RichTextLabel` `ITEM_UNIT` enum renames; various methods gained optional parameters (`Image`, `Font`, etc.).
- The 4.7.1 changelog notes further maintenance fixes after the feature release; the engine C++ API deprecates `ScriptLanguage::instance_has` (GH-118217) and a handful of other internal bindings (not user-facing GDScript).

### Maintenance context

Godot 4.7 (feature release) shipped 18 June 2026; 4.7.1 followed 14 July 2026 and 4.7.2 on 18 August 2026. The stable docs track the 4.7 series; feature releases preserve compatibility with previous 4.x releases, so the migration-guide changes above are the complete set of documented breakages.

Source: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
Source: https://godotengine.org/releases/4.7/
Source: https://github.com/godotengine/godot/releases/tag/4.7-stable

---

## 19. Release Changes — 4.7 / 4.7.1 / 4.7.2

(Official release notes, changelog, migration guide से)

# Godot 4.7 / 4.7.1 / 4.7.2 — The Definitive "What's New, Changed, Deprecated, Experimental, Removed" Reference

> Scope: Godot 4.7-stable (feature release, 18 June 2026, announcement "Godot 4.7, Lights, Camera, Action!"), plus the 4.7.1 (14 July 2026) and 4.7.2 (18 August 2026) maintenance releases. All items below are sourced from the official release announcement, the 4.7 branch `CHANGELOG.md`, the official migration guide and the maintenance-release announcements. Anything I could not verify from an official source is explicitly marked **[unverified]**.
>
> Primary sources: https://godotengine.org/releases/4.7/ • https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md • https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html • https://godotengine.org/article/maintenance-release-godot-4-7-1/ • https://godotengine.org/article/maintenance-release-godot-4-7-2/ • https://godotengine.github.io/godot-interactive-changelog/

---

## 1. Release identity at a glance

| Release | Date | Type | Build commit | Scale |
| --- | --- | --- | --- | --- |
| 4.7-stable | 18 June 2026 | Feature release | (see release tag) | Well over 300 contributors, over 1,600 pull requests |
| 4.7.1-stable | 14 July 2026 | Maintenance | `a13da4feb` | 42 contributors, 78 fixes |
| 4.7.2-stable | 18 August 2026 | Maintenance | `ed1daf0bf` | 39 contributors, 57 fixes |

The 4.7 `CHANGELOG.md` groups its roughly 1,673 listed entries under these table-of-contents categories (with entry counts): 2D (15), 3D (86), Animation (75), Assetlib (11), Audio (18), Buildsystem (136), C# (10), Codestyle (23), Core (91), Documentation (81), Editor (347), Export (27), GDExtension (26), GDScript (63), GUI (173), I18n (10), Import (28), Input (32), Navigation (2), Network (7), Particles (12), Physics (25), Platforms (90), Plugin (12), Rendering (141), Shaders (26), Tests (10), Thirdparty (21), XR (42).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md and https://godotengine.org/releases/4.7/)

---

## 2. Major new features in Godot 4.7

### 2.1 HDR output

Godot has rendered internally in HDR for years, but 4.7 is the first release that can actually *display* HDR to the user. HDR output is supported on Windows, macOS, iOS, visionOS, and Linux (Wayland). Key pull requests:

- Windows: Support output to HDR monitors (GH-94496)
- Apple: Support output to EDR (HDR) displays (GH-106814)
- LinuxBSD: Add support for HDR output (Wayland) (GH-102987)
- Platforms: Add HDR output support to Vulkan on macOS (GH-118083)
- Platforms: [Apple, Wayland] HDR Output: Emit window events when HDR state changes (GH-118076)
- Rendering: `display/window/hdr/request_hdr_output` project setting, now a basic setting (GH-118355); check whether the surface supports HDR output (GH-119091)
- Rendering: HDR screenshots via new `color_image` / `max_linear_value` parameters on `Image.save_exr` and `Image.save_exr_to_buffer` (GH-117800)
- Editor: Rework updating editor viewport HDR (GH-116248); fix editor screenshots with HDR enabled (GH-119013)
- Platforms: Windows: remove polling of SDR white level when HDR output is enabled (GH-117837)

The engine blog includes a dedicated write-up on how HDR output was implemented. Note the official docs warning that HDR previews may render differently (or not at all) depending on browser (Firefox does not support HDR images).

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.2 Asset Store rework (replaces the old Asset Library)

The Asset Library was reworked into the new **Asset Store** (GH-112992 — "Improve asset store and port it to the new API", contributed by Michael Alexsander). Highlights: polished asset item display, zoomable preview images, visible **asset ratings**, and background **threading** so store tasks no longer block the editor UI. Supporting changes in 4.7:

- Show "Verified" badge for verified asset authors (GH-119581)
- Improve the look of the asset rating indicator (GH-119635)
- Improve the visual of the Asset Store's page selector (GH-119719)
- Fix some issues and crashes in the asset store (GH-120164); fix incorrect release order for items (GH-120239); fix version querying problems (GH-119126); fix assets with license type "Other" not showing up (GH-120120)
- Move asset store repo list to the editor settings file and rename it (GH-118891)

4.7.1 follow-up: Set the Asset Store's default sorting to highest scored (GH-121112). 4.7.2 follow-up: Asset Store: Fix image width on different Editor Scales (GH-121470).

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.3 DrawableTexture / 2D drawing API

New **`DrawableTexture2D`** (and the `DrawableTexture` family) — a simple API layer that abstracts `RenderingDevice` plumbing and gives users of all skill levels an approachable way to draw to textures from GDScript (Implement DrawableTextures, GH-105701). Previously you had to either draw into a `Viewport` (limited and costly) or write low-level `RenderingDevice` code. Follow-ups: `RenderingServer` `drawable_type` property properly set (GH-118242); `set_width`/`set_height` removed from `DrawableTexture` since they were not functional (GH-118535). The methods are flagged experimental in the documentation (generic experimental description, GH-120092). **[Experimental]**

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.4 AreaLight3D — rectangular area lights

New `AreaLight3D` node for real-time light emitted from a rectangle in 3D space (Add Rectangular Area Light Source, GH-108219). Use cases highlighted by the announcement: glowing TV screens, illuminated billboards, light through frosted windows — without needing an emissive material + Global Illumination. Rectangular area lights produce softer shadows and more realistic reflections; they use PCSS-style variable penumbra by default (controlled by `Light3D.size`). Follow-ups: fix compatibility-renderer vertex shading compilation error (GH-118617); fix VoxelGI center calculated incorrectly for AreaLight3Ds (GH-120254); documentation clarifying performance impact (GH-119983) and linking the 3D lights and shadows tutorial (GH-120198).

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.5 Vulkan raytracing groundwork **[Experimental]**

Foundational (not yet user-facing production) raytracing work landed in 4.7:

- Vulkan raytracing plumbing (GH-99119)
- Raytracing API adjustments (GH-117148)
- Refactor raytracing pipelines (GH-118044)
- Random raytracing fixes (GH-118405)
- Shaders: Fix RD header generation for raytracing shaders (GH-118082)
- Documentation: **Mark all raytracing functionality experimental** (GH-118377)

All raytracing functionality in 4.7 is explicitly experimental and subject to change.

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.6 Control offset transforms

One of the most long-awaited GUI features: `Control`'s new `offset_transform_*` properties let you translate, rotate, or scale a `Control` *without* the transform being lost when a parent `Container` re-sorts (add transform offset to Control nodes, GH-87081, contributed by Timo Schwarzer). It works analogously to the CSS `transform` property — self-contained and purely visual by default. You can choose whether the transform offset affects mouse input; by default it does not, so buttons do not lose hover status after being transformed. This is primarily aimed at UI animation (buttons sliding into view, scaling away, etc.).

(Source: https://godotengine.org/releases/4.7/)

### 2.7 One-way collision direction on CollisionShape2D

Physics: Add one-way collision direction for `CollisionShape2D`s (GH-104736). One-way collision is now configured per shape with an arbitrary direction instead of the old node-wide "up only" behavior; `PhysicsServer2D.body_set_shape_as_one_way_collision` gained a `direction` parameter (see breaking changes, section 5).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.8 MeshLibrary editor

3D: Create a proper editor for `MeshLibrary` (GH-117376) — GridMap/`MeshLibrary` assets finally get a dedicated editing workflow instead of only being produced via scene export. Follow-ups: fix `MeshLibrary` crash (GH-118591); fix the editor not updating correctly in certain cases (GH-118917); fix it taking priority over `GridMap` when it shouldn't (GH-118648); typo fix (GH-119883); fix `mesh_library_editor_plugin.cpp` compilation with `deprecated=no` (GH-117815). Related: 3D scene import can now import files as Mesh or MeshLibrary via `ResourceImporterScene` (GH-107856), and the `GridMap` editor gained mesh preview fallback (GH-117792), octant querying (GH-118280), cursor coordinates (GH-116973), rotation clear/undo (GH-116685, GH-116565) and collider display (GH-103005).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.9 Scene Paint tool (2D)

2D: Add a **scene painter tool** (GH-109360) — paint scenes/objects directly into the 2D viewport. Follow-ups: fix scene paint tool updating info (GH-116691), strings improved in `ScenePaint2DEditor` (GH-119880), "Improve 2D editor dropping code" (GH-119418, landed in 4.7.1). Also in 2D: moving + ratio-locked scaling in the region editor (GH-117835), canvas selection color (GH-104860), random tile painting previews (GH-118315), and a `TileSet` editor proxy-object rework (GH-117574).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.10 GDExtensions viewer in Project Settings

GDExtension: Allow viewing GDExtensions from inside Project Settings (GH-118063) — a new Project Settings tab lists the GDExtensions loaded by your project.

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.11 Nearest-neighbor viewport scaling for 3D

Rendering: Add a nearest-neighbor scaling option to Viewport's **Scaling 3D Mode** property (GH-79731) — a pixel-art-friendly upscaling mode for 3D content (pairing well with the 2D `canvas_items` stretch defaults, see section 5). Related: FileSystemDock now uses nearest-neighbor filtering for textures (GH-112426), and screen-space AA is fixed when scaling using bilinear filtering (GH-113413).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.12 Android XR and Steam Frame — day-one support

Per the official announcement: "Godot continues the trend of being one of the best engines for XR development, with Godot 4.7 adding day one production-ready support for Android XR and Steam Frame." Steam Frame support is production-ready ahead of that headset's planned summer release; the 4.7 documentation describes it as "the Linux-based standalone Steam Frame using OpenXR". Supporting changelog entries include: fix OpenXR with Vulkan on Android (GH-116226), `XR_EXT_frame_synthesis` fixes on Meta Quest (GH-119659, GH-115603), projection layer extensions (GH-116207), `XR_KHR_generic_controller` support (GH-110778), eye-tracked foveation setting with subsampled images enabled by default (GH-117868), composition layers anywhere in the tree (GH-114324), `XR_EXT_user_presence` (GH-115190), Spatial Entities extensibility (GH-118128), and updated default OpenXR action map (GH-118975). Individual "Android XR enablement" PR numbers beyond the above were not itemized in the changelog; the day-one claim itself is from the official announcement. **[PR-level attribution for Android XR/Steam Frame enablement: unverified]**

(Source: https://godotengine.org/releases/4.7/ and https://docs.godotengine.org/en/4.7/about/list_of_features.html)

### 2.13 GABE — standalone Android export/publishing

With the stable release of the **Godot Android Build Environment (GABE)** companion app (Gradle export support for the Android editor), developers can now export *and publish* games entirely from an Android device. Godot 4.7 shipped QOL improvements to better integrate and leverage GABE on Android devices. Changelog entries: Remove experimental warning from `Use Gradle Build` option on Android (GH-119172) — Gradle export is now considered stable; update the GABE download URL (GH-120001); Android plugin Gradle platform dependencies (GH-115888); APK/AAB as base packs for patch PCKs (GH-116553); copy keystore to temp file during export (GH-116161); Android splash-screen export options (GH-114671); Android editor `project.godot` file associations (GH-116153); moving/resizing the embedded game window on Android (GH-118417). Related removal: deprecated Google Play OBB support was removed (GH-118283).

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.14 Conic gradients in GradientTexture2D

GUI: Add conic gradient to `GradientTexture2D` (GH-115394) — CSS-conic-gradient-style radial-sweep fills for 2D decoration and UI.

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.15 Landmark navigation & accessibility

Accessibility work is a major 4.7 theme (continuing 4.5's "making dreams accessible" push):

- GUI: Add accessibility region role for **landmark navigation** (GH-114449) — screen-reader users can jump between landmarks
- Accessibility methods/enums moved from `DisplayServer` to a dedicated **`AccessibilityServer` singleton** (GH-116839) — see breaking changes
- Accessibility: CodeEdit code completion support (GH-117283); property/category/section descriptions in the inspector (GH-117358); i18n extraction of Control accessibility name/description in the POT generator (GH-117134); numerous popup/slider/Tree fixes
- Thirdparty: **AccessKit** updated to 0.21.1 (GH-114596) and 0.21.2 (GH-117361); dynamic wrappers removed in favor of a download script with a build warning if libs are missing (GH-117313). (4.7.2 later updated AccessKit to 0.22.3, GH-121393.)

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.16 Trackball rotation & unified 3D view manipulation

- 3D: Add trackball-style rotation for the 3D transform gizmo (GH-109976); make it an optional toggle of Node3DEditorTool (GH-115794); consecutive presses of `Begin Rotate Transformation` enable it (GH-115856); fixes for highlight-on-toggle (GH-115992) and local-space use (GH-120063)
- 3D: Add **`View3DController`** for editor 3D view manipulation (GH-115957) — a unified, refactored view-manipulation backend; "Fix some issues with 3D view manipulation" (GH-118659); ability to cancel pan/zoom/orbit navigation (GH-105791)
- 3D: Freelook improvements — separate Freelook Invert Y Axis option (GH-116991), fixed viewport camera inertia in freelook (GH-117179), no gizmo highlight while freelooking (GH-115543), freelook/navigation control for the preview camera (GH-109945)
- 3D: Vertex snapping (GH-117235), vertex snap for subgizmo points (GH-117922) and collision-shape vertices (GH-117887), snap base setting Vertex/Origin (GH-117380), "Follow Selection" via double Center Selection (GH-99499), 3D ruler vector components (GH-106785)

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.17 Tweens can wait for signals

New `Tween.tween_await(signal: Signal)` method returning an **`AwaitTweener`** — pauses the tween until a specific signal is emitted (use `AwaitTweener.set_timeout()` if emission may never happen). The official announcement calls it out as ideal for dialogue and cutscenes. Also new: `Tween::has_tweeners()` (GH-92429). **[PR number for `tween_await` itself: not itemized in CHANGELOG.md — unverified]**

(Source: https://godotengine.org/releases/4.7/ and https://docs.godotengine.org/en/4.7/classes/class_tween.html)

### 2.18 Wayland touch support

Input: Wayland — Implement touch support (GH-113886). Related Wayland work: pointer warping (GH-112287), HDR-output warnings (GH-117530, GH-117913). 4.7.2 later fixed the IME popup position under fractional scaling on KDE Plasma (GH-121571).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.19 iOS controller support & gyro aiming

- Input: Add support for **joypad motion sensors** (GH-111679) — accelerometer and gyroscope inputs from controllers can now be read, enabling responsive-yet-smooth **gyro aiming** by tilting the controller (per the official announcement). The 4.7 docs add APIs such as `Input.set_joy_motion_sensors_enabled()`, `Input.get_joy_gyroscope()`, and motion-sensor calibration.
- Input: Add support for the **SDL3 joystick input driver for iOS** (GH-114316) — "Better controller support on iOS": iOS now gets the same SDL-based database previously available on Windows/macOS/Linux, so more controllers get correct default mappings.
- Input: joypad vibration checking (GH-114895), Home LED on Nintendo Switch controllers (GH-115114), `misc2`–`misc6` gamepad button constants (GH-116418), joypad serial numbers (GH-113873), device IDs on keyboard/mouse events (GH-116274), ignore-joypads-when-unfocused project setting (GH-115119)

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.20 PCSS shadows — status in the 4.7 line

Percentage-closer soft (contact-hardening) shadows are **not new in 4.7** — they predate this release and are enabled by raising `DirectionalLight3D.light_angular_distance` or `OmniLight3D`/`SpotLight3D.light_size` above `0.0`. What 4.7 adds around PCSS: `AreaLight3D` uses PCSS by default for its variable penumbra, directional lights got truly tight per-cascade shadow caster culling (GH-114678), and **4.7.2 shipped a significant correctness fix: "Fix PCSS shadows using shadow range begin in the wrong space" (GH-120774)** — the shadow-range-begin value was in world space while the shader computed in view space; after the fix, angular distance/blur on existing directional lights may look different (they were view-dependent and never worked correctly before). **[4.7-introduction claim: unverified/incorrect — PCSS predates 4.7]**

(Source: https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html and https://github.com/godotengine/godot/pull/120774)

### 2.21 Metal residency sets & driver work

Metal renderer improvements: a big refactor with fixed dynamic uniforms and **acyclic render graph support** (GH-114484); residency set support **restricted to Apple6+ (M-series and newer) GPUs** (GH-119451); shader baking improvements (GH-118541); fixes for NULL PixelFormats (GH-117744), linking to older SDK versions (GH-116419), offscreen rendering in the context driver (GH-117192), VM crashes (GH-118510 — also forces ANGLE when running in a VM, GH-117371), removal of glslang memory decorations (GH-116225), and a build fix with Xcode 26.4 (GH-117819).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

### 2.22 Tracy integration

Tracy profiler support itself was introduced in Godot 4.6 (SCons `profiler_path` option supporting `tracy` and `perfetto`, GH-104851). In 4.7 the integration matured: `TRACY_ON_DEMAND` is now used by default for Tracy integration (GH-117583), plus Perfetto hook-up and frame profiling logic (GH-118503) and Perfetto enabled by default for Android debug builds (GH-118401).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md and https://github.com/godotengine/godot/blob/4.6-stable/CHANGELOG.md)

### 2.23 Other headline-quality 4.7 features

- Shaders: **inline previews of text-based shader operations** (GH-117726, with layout improvements GH-118865 and loop-detection safeguards GH-118783/GH-118712) — preview shader results live in the editor as you type
- GUI: **VirtualJoystick** node (GH-110933) with StyleBox theming (GH-116428); `PopupMenu` search bar (GH-114236) with fuzzy search (GH-117958); tiling `AtlasTexture` in `TextureRect` (GH-113808); translation context for Controls (GH-115340); `custom_maximum_size` property on `Control` (GH-116640); auto oversampling adjustment with canvas item scale (GH-119692); triple-click paragraph selection in `RichTextLabel` (GH-116868)
- Platforms: **picture-in-picture** support (GH-114505); **taskbar progress and state** for Windows & macOS (GH-106560); device orientation change signal on `DisplayServer` (GH-115434)
- Animation: ping-pong playback for SpriteFrames/AnimatedSprite2D/AnimatedSprite3D (GH-114556); `SyncMode::CYCLIC` for BlendSpaces (GH-117275); particles seeking tools (GH-109142, also breaking-change related); aggregate keys drawn on folded node groups (GH-117321)
- Particles: "Inherit Emitter Scale" flag (GH-112184); scale-3D and rotation-3D in particle process (GH-112447); particle orientation options (GH-116620); velocity in userdata passed as `VELOCITY` to copy shader (GH-113509)
- Rendering: bent normal map support in the compatibility renderer (GH-114336); volumetric fog sanitization fix (GH-118198) with an opt-out project setting (GH-119414); Compatibility RenderTarget backbuffer size limit removed (GH-114957); view count support in Viewport (GH-115799); D3D12 `gl_NumWorkGroups` (GH-118812); Android Vulkan minimum API/hardware bump (GH-117355)
- Physics (Jolt): `Area3D` can detect/influence `SoftBody3D` (GH-114198); gravity application reworked to prevent energy increase on elastic collisions (GH-115305)
- GDScript: `CONFUSABLE_TEMPORARY_MODIFICATION` warning (GH-118002); LSP highlight support for external editors (GH-114186) and columns for external editors (GH-114185); declaration completion & lambda tooltips (GH-102937)
- C#: "Build C# project" in the command palette (GH-118169); faster source-generated `EmitSignal{...}` (GH-115741); `AddRange(ROS)` for `Godot.Collections.Array<T>` (GH-106765)
- Import: R8/R8G8 DDS textures (GH-116307); merge multiple ImporterMeshes (GH-116269); SVG DPITexture `fix_alpha_border`/`premult_alpha` options (GH-117088)
- Network: HTTPRequest missing redirect status codes (GH-91261); WebAssembly WebSocket send optimization (GH-104433)
- Editor: extra bottom dock slots (GH-116312); auto update check mode (GH-111168); `H` shortcut to toggle node visibility (GH-104628); VCS **commit amend** support (GH-117968); "Replace" in SceneTree context menu (GH-112985); export-template dialog reworked for individual templates (GH-117072)

(Source: https://godotengine.org/releases/4.7/ and https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

---

## 3. Editor workflow changes

- **Copy/paste whole property categories**: Add support for copy/paste of section/category properties (GH-111469), reworked copy-pasting of section/category values (GH-117998), inspector clipboard improvements (GH-117600, GH-119108), and copy/paste icons on `EditorResourcePicker` (GH-119314)
- **Monospace font in the docs/UI**: Use a monospaced font for code names (methods, signals, properties) in UI (GH-112219) — class reference and editor UI now render identifiers in monospace; related: improved appearance of built-in help (GH-107597) and `EditorHelpHighlighter` in the Project Manager (GH-116014)
- **Collapsible animation editor nodes**: aggregate animation keys are drawn on top of folded node groups (GH-117321); animation folding config handling fixed in 4.7.1 (GH-120403)
- **Dialog filters**: type filters in the Create Dialog (GH-111518); unified `FilterLineEdit` navigation for editor filter fields (GH-98667); search bars for the Opened Scenes List (GH-118711) and inspector resource/variant popups (GH-118413)
- **Documented dynamically generated properties**: documentation is now generated and displayed for properties created via `PropertyListHelper` (GH-115253), plus `PropertyListHelper` support for Curves (GH-92282)
- Other quality-of-life: revert button on `EditorInspectorSection` (GH-117692); floating debugger dock (GH-115390); pinnable bottom panel (GH-115978); searchable shortcuts by path (GH-117633); `EditorInterface::get_unsaved_scenes()` (GH-113767); script editor `close_file()`/`save_all_scripts()`/`reload_open_files()` APIs (GH-113772, GH-113765, GH-116187); Visual Profiler folding (GH-118120); long project title wrapping (fixed in 4.7.1, GH-119580); favorite-nodes auto-translation disabled (4.7.2, GH-122260)

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)

---

## 4. Behavior changes and migration notes (official migration guide, 4.6 → 4.7)

The official migration guide states that for most projects it should be "relatively safe" to migrate to 4.7, and rates each breaking change for GDScript and C# (binary/source compatibility).

### 4.1 API breaking changes (with introducing PRs)

- **Core**: `Object.is_class` parameter type String → StringName (GH-118582); `ZIPPacker.start_file` adds optional `permissions`/`modified_time` (GH-115946); `OptimizedTranslation.generate` return type void → bool (GH-119563)
- **2D/3D particles**: `CPUParticles2D/3D`, `GPUParticles2D/3D` `request_particles_process` adds optional `process_time_residual` (GH-109142)
- **GUI**: `Control.accessibility_live` type moves from `DisplayServer.AccessibilityLiveMode` to `AccessibilityServer.AccessibilityLiveMode` (GH-116839); `RichTextLabel` image API rework — enum `ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` renamed to `UPDATE_WIDTH_UNIT`; `add_image`/`update_image` width/height parameters int → float; `width_in_percent`/`height_in_percent` renamed to `width_unit`/`height_unit` with type `RichTextLabel.ImageUnit` (GH-112617)
- **Text**: `Font.find_variation` adds optional `palette_index`/`custom_colors` (GH-117149); `TreeItem.select` adds optional `set_as_cursor` (GH-119367)
- **Rendering**: `Image.save_exr`/`save_exr_to_buffer` add `color_image`/`max_linear_value` (GH-117800); `ImageTexture`/`PortableCompressedTexture2D.get_format` moved up to `Texture2D` (GH-109004); `RenderingServer.particles_request_process_time` parameter renamed to `process_time` + new `process_time_residual` (GH-109142); `RenderingServer.viewport_set_size` adds `view_count` (GH-115799)
- **Animation**: `Animation.length` metadata float → double (GH-116394); `AnimationNodeBlendSpace1D/2D.add_blend_point` adds optional `name` (GH-110369)
- **Physics**: `PhysicsServer2D.body_set_shape_as_one_way_collision` adds optional `direction`; `PhysicsServer2DExtension._body_set_shape_as_one_way_collision` gains a required `direction` parameter (both GH-104736 — custom 2D physics extensions must be updated)
- **Audio**: `AudioEffectSpectrumAnalyzer` property `tap_back_pos` **removed** (GH-114355)
- **XR**: `OpenXRExtensionWrapper._on_register_metadata` adds `interaction_profile_metadata` parameter (GH-117399); `OpenXRSpatialAnchorCapability.create_new_anchor` adds optional `next` (GH-118128)
- **Editor**: `EditorSceneFormatImporter` import constants (`IMPORT_ANIMATION`, `IMPORT_DISCARD_MESHES_AND_MATERIALS`, `IMPORT_FAIL_ON_MISSING_DEPENDENCIES`, `IMPORT_FORCE_DISABLE_MESH_COMPRESSION`, `IMPORT_GENERATE_TANGENT_ARRAYS`, `IMPORT_SCENE`, `IMPORT_USE_NAMED_SKIN_BINDS`) moved into the `ImportFlags` enum (GH-115788); `EditorVCSInterface._commit` adds a required `amend` parameter (GH-117968)

### 4.2 Behavior changes

- **Animation**: `AnimationNodeBlendSpace1D/2D` replace the boolean `sync` property with a new `SyncMode` enum — if AnimationTree transitions misbehave after upgrading, set the sync mode in each blend space
- **Rendering**: `LinearToSRGB` visual shader no longer clamps to [0, 1] on Mobile/Forward+ (GH-113956); `CanvasItem` no longer adds the antialiasing feather when drawing lines (GH-105122) — lines appear thinner; draw a thicker width if you relied on the old look
- **Physics/Audio crossover**: `AudioStreamPlayer` default `area_mask` changed from `1` to `0` (disabled) (GH-107679) — if you use `audio_bus_override` on `Area2D`/`Area3D` with the default mask, re-tick layer 1 or bus overrides stop working
- **Jolt Physics**: `WorldBoundaryShape3D.plane.d` sign convention now matches Godot Physics (GH-118948) — flip the sign to keep 4.6 behavior; `SoftBody3D` mass now defaults to 1 kg for the whole body instead of 1 kg per point (GH-116041), and `linear_stiffness` is applied differently — re-tweak `linear_stiffness`/`damping_coefficient`; `Area3D` now reports overlaps with `SoftBody3D` (GH-114198) — use layers/masks to filter unwanted interactions
- **Input**: mouse/keyboard device IDs changed from `0` to `InputEvent.DEVICE_ID_MOUSE`/`InputEvent.DEVICE_ID_KEYBOARD` because some joypads use ID 0 (GH-116274)
- **GDScript**: setting an element of a packed array no longer calls the setter for the whole packed array property (GH-113228); overrides of methods with typed returns now inherit the return type, requiring an explicit `return` (add `return null`) (GH-115763)
- **Platforms**: minimum macOS version raised from 10.13 (High Sierra) to **macOS 11 (Big Sur)**

### 4.3 Changed defaults

- **New projects**: default stretch mode is now `canvas_items` and stretch aspect `expand` (previously `disabled` / `keep`) — configurable in Project Settings under `display/window/stretch/mode` and `.../aspect`
- `LookAtModifier3D.relative`: true → false
- `ProjectSettings rendering/reflections/sky_reflections/roughness_layers`: 7 → 8
- `RichTextLabel.add_image`/`update_image` `width_in_percent`/`height_in_percent` parameter defaults: false → 0 (consequence of the GH-112617 rework)
- `ResourceImporterDynamicFont.hinting` default: 1 → 3

(Source: https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html)

---

## 5. Deprecated, removed, and experimental in the 4.7 line

### Deprecated

- GDExtension's `object_cast_to` and `classdb_get_class_tag`, in favor of `is_class` casts (GH-119254)
- GDScript global function `type_exists()` (GH-116899)
- `TabContainer.all_tabs_in_front` — now useless, deprecated (GH-118623)
- `ScriptLanguage::instance_has` (GH-118217)
- Android Studio `dev` buildtype (GH-113469)
- GDScript LSP: type bind marked experimental and direct LSP access deprecated (GH-105016)

### Removed

- Android export: deprecated **Google Play OBB support** removed (GH-118283)
- Buildsystem/platforms: dynamically linked ANGLE support removed (flag added to enable/disable ANGLE) (GH-117445)
- Core/TextServer: **TextServer GDExtension build support removed** (GH-117056) — TextServers now build in-tree only
- Platforms: unused and broken **big-endian support code** removed (GH-118514)
- Editor: `show_scene_tree_root_selection` EditorSettings entry removed (GH-116940)
- Audio: `AudioEffectSpectrumAnalyzer.tap_back_pos` removed (GH-114355)
- Rendering: `set_width`/`set_height` removed from `DrawableTexture` (GH-118535); `is_discardable` removed from render targets and several textures (GH-115530, GH-118396)

### Experimental

- **All raytracing functionality** is marked experimental (GH-118377) — API subject to change
- **`DrawableTexture2D` methods** carry an experimental flag in the docs (GH-120092)
- Moving *out* of experimental: Android's **`Use Gradle Build`** export option lost its experimental warning (GH-119172)
- Per the 4.7 feature list, the **Android editor** remains experimental, and web export for C# remains unsupported

### Not deprecated but notable API additions adjacent to this list

`AccessibilityServer` singleton (GH-116839), `Variant::get_type_by_name` in the GDExtension interface (GH-117160), refcount-aware `classdb_construct_object3`/`classdb_register_extension_class6` (GH-118214), `Tween.tween_await()`/`AwaitTweener`, and `Input` motion-sensor APIs (GH-111679).

(Source: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md and https://docs.godotengine.org/en/4.7/about/list_of_features.html)

---

## 6. Godot 4.7.1 (14 July 2026) — curated fix list

42 contributors submitted 78 fixes; built from commit `a13da4feb`. Curated highlights from the official announcement:

- 2D: Improve 2D editor dropping code (GH-119418)
- 3D: Fix closed `Curve3D` first/last point missing in/out control point (GH-120684)
- Animation: Make animation folding access cfg only at save/load project time (GH-120403)
- Assetlib: Set the Asset Store's default sorting to highest scored (GH-121112)
- Editor: Guard against non-main-thread emission of EditorFileSystem changed signal (GH-115083)
- Editor: Wrap long project title (GH-119580)
- GUI: Don't automatically open virtual keyboard when popup menu shows (GH-120768)
- GUI: Fix crash in `Tree::_get_item_focus_rect` (GH-120538)
- GUI: Fix scene tree drag-n-drop regression on touchscreens (GH-120456)
- GUI: Fix visual glitch with connections lines in `GraphEdit` (GH-120488)
- Input: Android: Fix EditorSettings not instantiated error when running game (GH-120723)
- Input: Fix backspace being unable to delete pre-existing text in any input field when using a soft keyboard on Android (GH-119798)
- Navigation: Fix navigation agent unconditionally getting added to avoidance simulation after pause resume (GH-120249)
- Network: Set inited=false on `CookieContextMbedTLS::clear` to avoid accidental double destruction (GH-120371)
- Rendering: Fix flickering lighting on mesh-instances with non-uniform scale (GH-119784)
- Rendering: Fix orthographic camera directional shadow culling (GH-120711)
- Rendering: Fix previous transform getting remembered for 2 frames after the instance stops moving (GH-119941)
- Rendering: Seek past skipped shader variant payloads to avoid reading incorrect data (GH-119792)

Known incompatibilities: **none** with 4.7 — the team encourages all users to upgrade.

(Source: https://godotengine.org/article/maintenance-release-godot-4-7-1/)

---

## 7. Godot 4.7.2 (18 August 2026) — curated fix list

39 contributors submitted 57 fixes; built from commit `ed1daf0bf`. Curated highlights from the official announcement:

- 3D: Fix 3D ruler tool tooltip (GH-120890)
- Assetlib: Asset Store: Fix image width on different Editor Scales (GH-121470)
- Core: Fix crash when failing to open log file for writing (GH-121926)
- Core: Forbid negative weights in `RandomPCG::rand_weighted` (GH-120004)
- Core: Make it impossible to have more than one main thread, and don't release unnecessarily (GH-121161)
- Core: Update `DirAccess::create_temp` to not fail on empty `prefix` parameter (GH-121315)
- Editor: Don't auto-translate favorite nodes (GH-122260)
- Editor: Fix Visual Profiler cursor not appearing when graph is partially filled (GH-118294)
- GDExtension: Fix `register_extension_class` never iterating parents for exposed checks (GH-120985)
- GUI: Fix `BaseButton` input when `enable_long_press_as_right_click` is true (GH-120962)
- Input: Fix performance issues when moving the mouse with high polling rate on Windows (GH-109639)
- Input: Fix simultaneous shift release (GH-120327)
- Input: Wayland: Fix IME popup position under fractional scaling on KDE Plasma (GH-121571)
- Multiplayer: Fix peers stopping replication on deleting node they spawned with MultiplayerSpawner (GH-109864)
- Navigation: Fix debug `NavigationRegion3D` colors not updating until project re-start (GH-120939)
- Network: mbedTLS: Always use Godot's OS as entropy source (GH-121759)
- Platforms: Windows: Add exception handling to `DispatcherQueueOptions` init (GH-122261)
- Rendering: **Fix PCSS shadows using shadow range begin in the wrong space** (GH-120774)
- Thirdparty: Update AccessKit to 0.22.3 (GH-121393)

Known incompatibilities: **none** with 4.7.1 — all users are encouraged to upgrade.

(Source: https://godotengine.org/article/maintenance-release-godot-4-7-2/)

---

## 8. Verification notes and caveats

- Dates, fix counts, commit hashes, and the curated 4.7.1/4.7.2 fix lists are taken verbatim from the official maintenance announcements.
- The 4.7 feature list with PR numbers is taken from the 4.7 branch `CHANGELOG.md` (equivalent to the interactive changelog) — the full list there runs to ~1,673 entries across the 29 categories listed in section 1; this document curates the most significant ones plus everything the task named.
- PCSS and Tracy predate 4.7 (PCSS has existed since early 4.x via light size/angular distance; Tracy integration shipped in 4.6 via GH-104851) — 4.7's role was refinements and, for PCSS, a major correctness fix in 4.7.2.
- Items marked **[unverified]** could not be confirmed from an official changelog or announcement: the introducing PR for `Tween.tween_await()`, and PR-level attribution for the Android XR / Steam Frame enablement (the day-one production-ready support claim itself is quoted from the official release notes).
- Godot 4.8 was already in development snapshots when 4.7.1 released, so anything listed here reflects the 4.7 line only.

## 9. Consolidated source list

- Godot 4.7 release announcement: https://godotengine.org/releases/4.7/
- Godot 4.7 CHANGELOG.md (4.7-stable branch): https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md
- Interactive changelog: https://godotengine.github.io/godot-interactive-changelog/
- Migration guide (4.6 → 4.7): https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.7.1 maintenance announcement: https://godotengine.org/article/maintenance-release-godot-4-7-1/
- 4.7.2 maintenance announcement: https://godotengine.org/article/maintenance-release-godot-4-7-2/
- 4.7-stable GitHub release tag: https://github.com/godotengine/godot/releases/tag/4.7-stable
- 4.7 class reference (e.g. Tween, lights and shadows tutorial, list of features): https://docs.godotengine.org/en/4.7/

---

## 20. Ecosystem — Asset Library/Store, Plugins, AI/MCP, External Tools

**Yahā sab kuch THIRD-PARTY / COMMUNITY है (जहाँ labeled है) — built-in se alag।**

# Godot 4.7.x — Asset Library & AI-Tooling Ecosystem Reference (2026 state)

**Scope:** Godot 4.7 feature release (published 18 June 2026) and 4.7.2-stable maintenance release (published 18 August 2026, commit ed1daf0bf, 39 contributors / 57 fixes, no known incompatibilities with 4.7.1). All technical names, settings, and code identifiers are kept in exact English. Every item is labelled **OFFICIAL**, **COMMUNITY PLUGIN**, or **EXTERNAL TOOL**. Where 4.7/4.7.2 compatibility could not be confirmed from primary sources, this is stated explicitly.

---

## 1. The Official Godot Asset Library and the new Asset Store (OFFICIAL)

### 1.1 What the Asset Library is

The Godot Asset Library ("AssetLib") is the official, user-submitted repository of Godot addons, scripts, tools, demos, templates, and other resources, collectively called "assets". It is operated by the Godot Foundation and is free; paid assets are **not** allowed on the official library/store, although authors are free to sell Godot assets outside it.

**Access points:**

- **Web:** `https://godotengine.org/asset-library/asset` (browse, search, download, submit).
- **In-editor:** the `AssetLib` tab inside the editor (next to `2D`, `3D`, `Script`) shows assets meant to be installed into an existing project; the Project Manager's `Asset Library Projects` tab shows standalone projects (Templates, Demos, Projects categories).
- **API:** a REST API under `https://godotengine.org/asset-library/api` (documented in `godotengine/godot-asset-library/API.md` on GitHub) supporting `GET /asset?...` filtering by type, category, support level, godot_version, license, sort, etc. Note: this old API is *not* compatible with the 4.7 editor's new store client (see 1.4).

### 1.2 Categories (complete list)

Every asset belongs to exactly one category. The full set on the Asset Library web frontend is:

**Addon type** (shown inside a project's AssetLib tab): `2D Tools`, `3D Tools`, `Shaders`, `Materials`, `Tools`, `Scripts`, `Misc`.
**Project type** (shown in the Project Manager): `Templates`, `Demos`, `Projects`.

The in-editor store only displays assets whose category matches the context (addons in-project; Templates/Demos/Projects in the Project Manager).

### 1.3 Support levels, version metadata, and moderation

**Support levels:** each asset has exactly one: `Testing` (work-in-progress, may contain bugs), `Community` (submitted and maintained by community members), `Featured` (hand-picked resources recognized for their value). A fourth level, `official`, exists in the API and is set by moderators. In the 4.7 in-editor Asset Store, the old support-level filter surfaced has changed (ratings and a "Verified" badge for verified asset authors now carry this role — GH-119581).

**Godot version compatibility metadata:** submitters pick the engine version an asset targets. The web library's version filter runs from `2.0` through `4.7` plus `Any`, `Unknown`, and `Custom build`. In the editor, the store by default only fetches assets matching the running engine version, so a 4.7.2 editor sees 4.7-compatible listings. (Version-querying bugs in the new store were fixed during the 4.7.x line — GH-119126.)

**License metadata:** the filter includes MIT, MPL-2.0, GPL v3/v2, LGPL v3/v2.1/v2, AGPL v3, EUPL 1.2, Apache 2.0, CC0 1.0, CC BY 4.0/3.0, CC BY-SA 4.0/3.0, BSD 2-clause, BSD 3-clause, Boost, ISC, The Unlicense, zlib, and `Proprietary (see LICENSE file)`.

**Submission requirements (moderation):** the asset must work in the specified Godot version; no essential git submodules (GitHub's ZIP download omits them); the license on the AssetLib must match the repository, which must contain a `LICENSE` or `LICENSE.md` file with license text, copyright years, and holder; name and description in English. Recommendations include fixing/suppressing all script warnings and copying the license + README into the addon folder so it survives installation. Up to three image/video previews can be attached. Approval is manual via a review queue (typically up to a few days); rejected submissions receive a reason and can be resubmitted. Editors' asset edits also go through a moderator review/accept/reject workflow (AssetLib API).

### 1.4 Godot 4.7: the reworked in-editor "Asset Store"

Godot 4.7 replaced the in-editor Asset Library UI with the new **Asset Store**, first announced in the article "Introducing the Godot Asset Store" (22 May 2026) and hosted at `https://store.godotengine.org/`. Key facts:

- The store uses **Godot's shared account system** (the same account as the development fund, forum, developer chat, and showreel voting). The old AssetLib required a separate account.
- New features: **user reviews and ratings**, **analytics for publishers**, **multiple download versions per asset** (versioned downloads), **a changelog page per asset**, **asset tags including custom tags**.
- In-editor rework (PR GH-112992, merged for 4.7): polished asset item display, **asset ratings shown inline** (with a "ThumbsUp" rating indicator), asset changelogs, downloading different asset versions, clickable tags for search, a **zoom mode** that expands preview images fully in the main window, click-to-read full license text, a "Store Page" button, and **threading** so store tasks run in the background without blocking the editor's main UI. The editor icon/tab was renamed from `AssetLib` to `Asset Store` (`FEATURE_ASSET_LIB` enum retained).
- Fixes continued in the 4.7.x maintenance line: assets with license type "Other" not showing (GH-120120), incorrect sort order for store items (GH-120239), improved rating indicator visuals (GH-119635), improved page selector (GH-119719) and version-label visuals (GH-119751), template asset fixes (GH-120164), and the "Verified" badge (GH-119581).
- **The old Asset Library is deprecated**: it is kept running for older engine versions but is slated to become read-only. The 4.7 editor cannot browse the old library (issue #119578) — the old and new APIs are completely different, since the store supports multiple versions, reviews, and more. Editors up to and including 4.6.x continue to use the old AssetLib exclusively.
- Known transition caveat: many older addons exist only on the legacy library; on 4.7 they must be fetched from the website or manually installed. Users upgrading editor settings from 4.6 may hold a stale store URL.

**Example store URLs (4.7 era):** `https://store.godotengine.org/asset/ramokz/phantom-camera/`, `https://store.godotengine.org/asset/nathanhoad/dialogue-manager/`.

Source: https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html
Source: https://docs.godotengine.org/en/stable/community/asset_library/using_assetlib.html
Source: https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html
Source: https://godotengine.org/asset-library/asset
Source: https://github.com/godotengine/godot-asset-library/blob/master/API.md
Source: https://staging.godotengine.org/article/introducing-the-godot-asset-store/
Source: https://godotengine.org/releases/4.7/
Source: https://github.com/godotengine/godot/pull/112992
Source: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
Source: https://github.com/godotengine/godot/issues/119578

---

## 2. Notable community plugins/addons by category

The Godot 4 ecosystem holds over 5,000 addons on the Asset Library plus new listings on the Asset Store. Below are the widely recommended ones. **Compatibility caveat:** unless a source explicitly states 4.7 support, treat "widely used on Godot 4.x" as unverified for 4.7.2 — always check the addon's release notes and the store's minimum-Godot-version field.

**2D / pixel art**
- **Aseprite Wizard** — COMMUNITY PLUGIN (MIT). Imports `.aseprite` files (sprites, animations, slices) into Godot without leaving Aseprite; the de-facto 2D pixel-art pipeline addon. Find: Asset Library / GitHub (by Vinicius Gereginha). 4.7 compatibility unverified from primary sources.

**3D**
- **Terrain3D** — COMMUNITY PLUGIN (MIT, by Tokisan Games). High-performance editable terrain as a C++ GDExtension: sculpting, painting, up to 32 textures, up to 10 LOD levels, foliage instancing, heightmap import from HTerrain/Gaea/World Creator/World Machine/Unity/Unreal exports. Terrains from 64×64 m up to ~65.5×65.5 km. Find: GitHub (outobugi/Terrain3D — note several mirrors exist) / Asset Library. 4.7-compatible builds expected on the 4.7 store; verify per release.
- **ProtonScatter** — COMMUNITY PLUGIN (MIT). Procedural environment dressing/scattering of foliage and props in 3D scenes. Find: GitHub (HolinFang/ProtonScatter) / Asset Library.
- **Godot Jolt** — COMMUNITY PLUGIN (MIT). Full replacement of the built-in 3D physics with the Jolt physics engine, as a GDExtension. Find: GitHub (godot-jolt/godot-jolt) / Asset Library.
- **FuncGodot** — COMMUNITY PLUGIN. Brush-based 3D blockout/level import from TrenchBroom/Brushworks formats (JDKGD/func_godot). Find: GitHub.

**Camera / cinematics**
- **Phantom Camera** — COMMUNITY PLUGIN (MIT, by ramokz). Cinemachine-style virtual cameras for `Camera2D`/`Camera3D`: priority-based switching, follow modes (Glued, Simple, Group, Path, Framed, Third Person), dead zones, damping, tweening, a viewfinder bottom panel. The Asset Store listing (last updated 19 July 2026, minimum Godot 4.4) carries 2026 reviews referencing 4.7-era use; C# is supported. Find: `https://github.com/ramokz/phantom-camera`, `https://phantom-camera.dev`, Asset Store page `ramokz/phantom-camera`.

**AI / behavior trees / state machines**
- **LimboAI** — COMMUNITY PLUGIN (MIT, by limbonaut). C++ GDExtension combining behavior trees and hierarchical state machines (`LimboHSM`, `BTPlayer`, `Blackboard` plans/scopes/parameters), with a BT editor, visual debugger, and performance monitors. Version matrix: 1.7.x targets Godot 4.6+ (so covers the 4.7 line; a dedicated 4.7-tested release note was not confirmed), 1.6.x targets 4.4–4.6, etc. Find: `https://github.com/limbonaut/limboai`, docs at limboai.readthedocs.io.
- **Beehave** — COMMUNITY PLUGIN (MIT). Lightweight pure-GDScript behavior trees. Find: GitHub (bitbrain/beehave) / Asset Library.

**Dialogue**
- **Dialogic 2** — COMMUNITY PLUGIN (MIT). Visual-novel-grade dialogue framework: timeline editor, characters with portraits, branching, variables, save integration, translations. Current release line is 2.0-alpha (latest tagged release 2.0-alpha-19, Jan 2026); some users report instability on alphas. Find: `https://github.com/dialogic-godot/dialogic`, `https://dialogic.pro`.
- **Dialogue Manager** — COMMUNITY PLUGIN (MIT, by Nathan Hoad). Stateless, text-first branching dialogue editor + runtime for Godot 4.6+ (v4 line; v3.10 for 4.4/4.5). Includes `DialogueLabel`, `DialogueResponsesMenu`, debugger, C# wrapper. Store listing last updated 21 August 2026. Find: `https://github.com/nathanhoad/godot_dialogue_manager`, Asset Store `nathanhoad/dialogue-manager`.

**Shaders / materials**
- **Material Maker** — COMMUNITY PLUGIN (MIT, external app + Godot integration). Node-based PBR material authoring (Substance-style), Godot-oriented export. Find: `https://github.com/RodZill4/material-maker`.
- Note: 4.7 itself added **inline shader previews** in the editor as an engine feature (OFFICIAL, not a plugin).

**Animation**
- Engine-native `AnimationPlayer`/`AnimationTree`/`AnimationLibrary` cover most needs (OFFICIAL); glTF animation-library import (import mode *Animation Library*) is the standard cross-tool path (OFFICIAL pipeline, see section 4). No single third-party animation addon dominates; MCP toolkits (section 3) expose programmatic `AnimationTree` editing.

**Audio**
- **Godot Audio Manager** — COMMUNITY PLUGIN (by Saulo Souza). Centralized audio playback bus/autoload manager; exists on both legacy Asset Library and the new store (`saulo-souza/godot-audio-manager`). Version-specific 4.7 support unverified.

**UI**
- No dominant UI framework plugin; common practice uses built-in `Control` nodes and `Theme` resources (OFFICIAL). 4.7's new `Control` offset-transform properties reduce the need for UI-animation addons. Community helpers exist (e.g., addons integrating with Dialogue Manager for quest/UI glue), but none are canonical.

**Networking / multiplayer / platform**
- **GodotSteam** — COMMUNITY PLUGIN (MIT for code, Steamworks SDK terms apply; by Gramps). Full Steamworks SDK bindings for Godot 4 as GDExtension or custom-editor module; also GodotSteam Server edition for dedicated servers. Actively updated in 2026 (4.22, Aug 2026); its changelog explicitly tracks Godot 4.7 engine changes ("Godot 4.7 changed callable_method_pointer.h to callable_mp.h" breaking note in 4.20). Find: `https://godotsteam.com`, `https://codeberg.org/godotsteam/godotsteam`, Asset Library, Asset Store.
- **Nakama Godot client SDK** — COMMUNITY PLUGIN (Apache-2.0, by Heroic Labs). GDScript client for the Nakama open-source game backend (accounts, matchmaking, storage, leaderboards, realtime sockets), integrates with Godot's high-level multiplayer API via `NakamaMultiplayerBridge`. Written for Godot 4.0+. Find: `https://github.com/heroiclabs/nakama-godot`, Asset Library.
- **GD-Sync** — COMMUNITY PLUGIN (BSD-2-Clause). Managed relay/backend suite: lobbies, matchmaking, cloud saves, leaderboards, Steam link-up. Find: `https://www.gd-sync.com`, Asset Library.
- **LinkUx** — COMMUNITY PLUGIN. Multiplayer abstraction with swappable LAN (ENet) and Steam backends. Find: GitHub (IUXGames/LinkUx). Requires Godot 4.4+.

**Editor extensions / testing / tooling**
- **GUT** — COMMUNITY PLUGIN (MIT). The classic GDScript unit-testing framework. Find: GitHub (bitwes/Gut) / Asset Library.
- **GdUnit4** — COMMUNITY PLUGIN (MIT). Modern GDScript/C# testing framework with CI support, by MikeSchulze. Find: `https://github.com/MikeSchulze/gdUnit4`.
- **Godot Git Plugin** — COMMUNITY PLUGIN (MIT). Git version-control dock inside the editor. Find: GitHub (godotengine/godot-git-plugin — note: hosted under the godotengine org but community-maintained).
- **Debug Draw 3D** — COMMUNITY PLUGIN (MIT). Runtime debug drawing of vectors, collisions, paths. Find: GitHub.
- **Limbo Console** — COMMUNITY PLUGIN (MIT). In-game developer/cheat console. Find: GitHub.

**Save systems**
- Godot's built-in `ConfigFile`, `FileAccess`, `JSON`, and `ResourceSaver` cover most save needs (OFFICIAL); no single canonical save-system addon exists. Nakama/GD-Sync provide *cloud* saves (above). Community save-manager addons exist on the Asset Library but none is dominant enough to name as standard.

Sources: https://ziva.sh/blogs/best-godot-plugins-2026 , https://godotawesome.com/best-godot-plugins-2026/ , https://gamineai.com/blog/16-free-godot-4-plugins-worth-installing-before-your-first-vertical-slice-2026 , https://github.com/limbonaut/limboai , https://github.com/ramokz/phantom-camera , https://store.godotengine.org/asset/ramokz/phantom-camera/ , https://github.com/nathanhoad/godot_dialogue_manager , https://store.godotengine.org/asset/nathanhoad/dialogue-manager/ , https://github.com/dialogic-godot/dialogic , https://codeberg.org/godotsteam/godotsteam , https://godotsteam.com , https://github.com/heroiclabs/nakama-godot , https://heroiclabs.com/docs/nakama/client-libraries/godot/ , https://godotengine.org/asset-library/asset/2347

---

## 3. AI & MCP ecosystem for Godot 4.7

### 3.1 How AI tools connect to Godot (connection patterns)

There is no official AI integration in the engine itself (all items below are COMMUNITY PLUGIN / EXTERNAL TOOL). The recurring architectures are:

1. **MCP server + editor plugin over WebSocket/TCP.** A Node.js (or Python/Rust) MCP server speaks stdio (or streamable HTTP) to the AI client (Claude Code, Claude Desktop, Cursor, Windsurf, Cline, Codex CLI, VS Code Copilot, etc.) and forwards JSON-RPC tool calls over a localhost WebSocket/TCP socket to a GDScript/C# `EditorPlugin` running inside Godot, which executes them through `EditorInterface` and engine APIs. Default ports in the wild: **6505** (WebSocket, most Node.js implementations), **6506** (HTTP daemon), **6550/6551** (Rust "director" style), **9876/9877** (TCP editor + runtime bridges), **9090** (TCP runtime autoload). Multi-project setups derive per-project ports via hashing.
2. **Headless Godot.** The server spawns `godot --headless` (headless display driver + Dummy audio driver; the standard flag for CI and servers) and drives it with `--script` running a GDScript operations file (e.g. `godot --headless --script godot_operations.gd <json_params>`), or spawns the editor as a child process communicating over stdin/stdout with a JSON-RPC marker prefix. Headless mode is an OFFICIAL engine capability (documented in the command line tutorial and "Exporting for dedicated servers"), used here by community tools.
3. **Runtime bridges.** An autoload injected into the *running game* listens on loopback and lets the AI inspect the live scene tree, inject input, screenshot the game, and read performance metrics; `EditorDebuggerPlugin` messages or `user://` JSON files are common IPC paths.
4. **`--server` / dedicated-server pattern.** Note that `--server` is *not* a built-in engine flag — the official docs recommend adding `--server` to `OS.get_cmdline_user_args()` yourself (after the `--` separator) to start a game's server code, or using the `dedicated_server` feature tag / `--headless`. AI tooling that advertises "--server mode" is using these official headless/debug facilities or its own convention.

### 3.2 Godot MCP servers (all COMMUNITY PLUGIN unless noted)

- **elfensky/godot-mcp** — Node.js MCP server + Godot 4.x editor plugin; stdio by default with auto-started headless Godot, `--daemon` HTTP mode for multi-client; WebSocket plugin protocol (`tool_invoke`/`tool_result`, ping/pong keepalive); runtime debugging via an injected `__MCPRuntimeBridge__` autoload. `npx @elfensky/godot-mcp`.
- **mkdevkit/godot-mcp** — Node.js server ↔ WebSocket:6505 ↔ editor plugin; `command_router.gd` with 24 modules / 173 handlers; 3 autoloads (`MCPRuntimeBridge`/`MCPInputBridge`/`MCPScreenshotBridge`) using `user://` IPC; UndoRedo integration for mutations; smart type parsing (`Vector2(100, 200)`, `#ff0000`); requires Godot 4.4+.
- **Godot MCP Pro (y1uda)** — proprietary ($15, itch.io) with a free listing on the legacy Asset Library; 163 tools in 23 categories (scenes, nodes, scripts, editor, input, runtime, animation, AnimationTree, 3D, physics, particles, navigation, audio, TileMap, theme/UI, shaders, resources, batch/refactor, analysis, testing/QA, profiling, export); Lite mode (76 tools) for clients with tool limits. Requires Godot 4.4+, Node 18+.
- **Godot MCP Toolkit (NPGameDev)** — MIT, on the legacy Asset Library (category Tools, Godot 4.2, July 2026). 112 built-in tools + extension API to write your own MCP tools in GDScript (hot-reload, C#/.NET supported); session-token auth bound to 127.0.0.1; optional read-only mode (`GODOT_MCP_READ_ONLY=1`); companion bridge `@npgamedev/godot-mcp-server` (Node 22+).
- **yanhuifair/Godot-MCP** — 386 tools / 30 categories / 22 documented AI-client configs; native `.tscn`/`.tres`/`.godot` parsers so many tools work without a running editor; dual-mode editor bridge: TCP on localhost:9876 (default) or stdio child-process with `--editor --path` and a `__MCP__:` JSON-RPC marker prefix; runtime bridge autoload on 127.0.0.1:9877.
- **ChanceFlow/godot-mcp** — Python (`uvx`-installable from PyPI as `godot-mcp`); launches the editor, runs projects, captures debug output; bundled GDScript `godot_operations.gd` for scene/node operations.
- **XOVIET-GAME/godot-mcp** — fork/extension of Coding-Solo's godot-mcp (which supplied the TypeScript server + headless GDScript operations + TCP runtime server architecture); 162 operations exposed through a compact public tool tree (20 public tools + catalog); **explicitly tested and working with Godot 4.7**; runtime autoload `mcp_interaction_server.gd` on 127.0.0.1:9090.
- **Rufaty/godot-mcp-enhanced** — Python MCP server + GDScript plugin exposing a token-protected HTTP API on 127.0.0.1:3571; **requires Godot 4.4+, tested on 4.7**; hardened after a security review (loopback Host check, token auth, no CORS wildcard).
- **LeanderM99/GodotMCP** — C# `EditorPlugin` variant for Godot 4.6+ (.NET); WebSocket server on port 6550 inside the editor; TypeScript MCP server with Zod validation.
- **hybridindie/godot-mcp** — 180 tools in 29 categories with toggleable toolsets to keep agent context small; MCP HTTP on 9090 + WebSocket bridge on 9080; MCP prompts (slash-command style workflows) and installable "AI skills"; Docker image available.
- **godot-theatre "AI Toolkit for Godot"** — Rust `stage`/`director` binaries; editor-plugin backend on port 6551, headless daemon backend on 6550 (a separate `godot --headless` instance), one-shot headless fallback; length-prefixed JSON over TCP to a GDExtension.

**4.7/4.7.2 status:** most of these projects declare "Godot 4.4+" or "4.x" support; only XOVIET-GAME/godot-mcp and Rufaty/godot-mcp-enhanced explicitly state testing on Godot 4.7 in their READMEs. Everything else: **unverified for 4.7.2** — check each repo's issues/releases before relying on it.

### 3.3 AI coding assistants inside the editor (COMMUNITY PLUGIN unless noted)

- **godot-ai-chat / "AI Copilot" (unxsist)** — agentic Copilot/Claude-style chat dock *inside* the Godot editor; 15+ LLM providers (OpenAI, Anthropic, Gemini, DeepSeek, Groq, xAI, Mistral, OpenRouter, Ollama, LM Studio, custom OpenAI-compatible endpoints); tools include `write_file`/`edit_file` with inline diffs, `run_and_capture` (plays the game, captures runtime errors with file:line + backtrace), scene building, screenshots; sandboxed to `res://`; README targets **Godot 4.7**. Find: GitHub `unxsist/godot-ai-chat`, or search "AI Copilot" in the editor's AssetLib/store.
- **AI Coding Assistant for Godot 4 (Godot4-Addons)** — MIT; agentic multi-tool system with project-context blueprint, semantic search, permission manager, @file mentions, persona system (Chat/Plan/Code); providers via OpenRouter (Claude, GPT, Gemini), Gemini, HuggingFace, Cohere. v3.3.0-rc1 (March 2026). Godot 4.x generally; 4.7 unverified.
- **copilot.gd (lrdcxdes)** — GitHub Copilot ghost-text completions in Godot's script editor via a Node.js relay to `@github/copilot-language-server`; device-flow auth; targets **Godot 4.6** (Node ≥ 20.8; active Copilot subscription required). 4.7 unverified.
- **Godot Copilot (minosvasilias)** — the older OpenAI-API completion plugin (shortcut-triggered, GPT-3.5/4-era models; compatible with 4.x/3.x). Largely historical.
- **Ziva** — EXTERNAL TOOL, freemium (free / $20/mo Pro). Closed-source AI agent + asset generation as an editor plugin for Godot 4.2+ (Windows/macOS/Linux); scene/node editing, TileMapLayer tools (4.3+), editor-error reading, playtesting, sprite/3D-model generation, local Streamable HTTP MCP server for connecting external coding agents, local Ollama/LM Studio models. Find: `https://ziva.sh`.
- **Summer Engine** — EXTERNAL TOOL (closed source). An AI-native *editor* compatible with Godot 4 projects (opens standard `project.godot`, `.tscn`, `.gd`, `.tres` directly); the agent writes GDScript, creates nodes, connects signals, runs the scene, and reads back errors; also exposes an MCP endpoint for Cursor/Claude. Find: `https://www.summerengine.com`.
- **Godot_AI native module (spardanviro)** — a C++ `ai_assistant` module for the Godot **4.7+** editor (custom build); docked panel, multi-provider (Anthropic/OpenAI/Gemini/DeepSeek/GLM), executes AI-generated GDScript as `EditorScript` with permission gating and checkpoints, on-demand API-doc/gotcha injection. Niche but explicitly 4.7-targeted.

**Practical connection summary:** AI assistance reaches Godot through (a) MCP tooling that drives a live or headless editor over localhost sockets, (b) chat docks inside the editor calling cloud or local LLM APIs, (c) generic coding agents (Claude Code, Cursor, Copilot) editing project files directly — increasingly combined with (a) so the agent can validate code by running the game.

Sources: https://github.com/elfensky/godot-mcp , https://github.com/mkdevkit/godot-mcp , https://github.com/yanhuifair/Godot-MCP/blob/master/README.md , https://github.com/XOVIET-GAME/godot-mcp , https://github.com/Rufaty/godot-mcp-enhanced , https://github.com/LeanderM99/GodotMCP , https://github.com/hybridindie/godot-mcp , https://pypi.org/project/godot-mcp/ , https://godotengine.org/asset-library/asset/5375 , https://godotengine.org/asset-library/asset/4961 , https://godot-theatre.dev/guide/how-it-works , https://github.com/unxsist/godot-ai-chat/ , https://github.com/Godot4-Addons/ai_assistant_for_godot , https://github.com/lrdcxdes/copilot.gd , https://ziva.sh/ , https://www.summerengine.com , https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html , https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html

---

## 4. External tools commonly used with Godot

**3D / DCC (OFFICIAL pipeline support, EXTERNAL TOOL apps):**
- **Blender** — the recommended 3D DCC. Godot's official import path is **glTF 2.0** (`.gltf`/`.glb`, recommended), and the editor can import `.blend` files *directly and transparently* by invoking Blender's glTF exporter (Blender 3.0+ required, 3.5+ recommended; configure under Editor Settings → `filesystem/import/blender/blender_path`). The `.blend` route still converts to glTF internally, so both paths share the same import code (Import dock, Advanced Import Settings, `ResourceImporterScene`). `.blend` import is unavailable on Android/web editor builds and requires every team member to have Blender installed. glTF import supports animation-only import as `AnimationLibrary`; PBR texture export works from Blender's exporter. The glTF interop work is an active collaboration between Godot, Blender, and the OMI/GD3D groups (e.g. `OMI_physics_body`/`OMI_physics_shape` extensions in Godot 4.3+, `KHR_animation_pointer` in 4.4+, glTFX drafts).
- Other supported 3D formats (OFFICIAL importer support): DAE (COLLADA), OBJ + MTL (limited), FBX via the **ufbx** library (default since 4.3; legacy FBX2glTF workflow deprecated and not recommended), plus heightmaps from external terrain tools (Gaea, World Creator, World Machine) via Terrain3D.
- **Substance, ArmorPaint, Material Maker** — EXTERNAL TOOLS for PBR texture authoring; Godot's PBR materials consume their exports (docs name all three; Material Maker is also a community plugin for round-tripping).

**2D / vector / raster (mix of OFFICIAL import support and EXTERNAL TOOL apps):**
- **Inkscape** — EXTERNAL TOOL. Godot imports SVG via the ThorVG library with limited feature support; text must be converted to paths or it won't render. The official docs specifically recommend rendering complex vectors to PNG with Inkscape, and document its CLI: `inkscape --export-text-to-path --export-filename out.svg in.svg`. SVG is also the only format importable as `DPITexture` for runtime re-rasterization.
- **Aseprite** — EXTERNAL TOOL. Pixel-art/animation editor; ships its own CLI (headless export of spritesheets/GIFs). Godot imports the exported PNG sheets + JSON/XML data natively (OFFICIAL); the community **Aseprite Wizard** addon (COMMUNITY PLUGIN) imports `.aseprite` files directly with animation support.
- **TexturePacker** — EXTERNAL TOOL. Spritesheet packer; consumed via the community **texturepacker-godot-plugin** (COMMUNITY PLUGIN, MIT, Godot 4.0+) which imports sheets + `.tpsheet` data as `AtlasTexture`s (trimmed sprites and MultiPack supported; TileSet import from `.tpsheet` is Godot-3-only). Available from the Asset Library/GitHub (imjp94/texturepacker-godot-plugin).
- **LDtk** — EXTERNAL TOOL (2D level editor by deepnight). No built-in Godot support; the official LDtk API page lists several community Godot importers (e.g. Godot 4 GDScript import plugins by afk_mario and JoshLee0915 that treat `.ldtk` files as native resources and build Godot scenes). All LDtk bridges are COMMUNITY PLUGINs.
- **Tiled** — EXTERNAL TOOL (.tmx/.tmj tile-map editor). Unlike Godot 3.x, which shipped a built-in Tiled map importer, Godot 4.x has **no first-party Tiled import**; community addons/importers on the Asset Library and GitHub handle `.tmx`/`.tmj`/`.json` export instead. (Verify current addon compatibility with 4.7 per release — most declare 4.x support only.) This Godot-3-to-4 change is widely documented but was not re-verified against 4.7.2 docs in this pass.

**Audio:** Godot imports OGG Vorbis, MP3, and WAV natively (OFFICIAL); common external tools (Audacity, Reaper, FMOD/Wwise via community integrations) are beyond the official pipeline.

Source: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
Source: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html
Source: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
Source: https://devtalk.blender.org/t/state-of-interoperability-between-godot-and-blender/38559/26
Source: https://ldtk.io/api/
Source: https://explore.market.dev/ecosystems/godot/projects/texturepacker-godot-plugin

---

## 5. Verification status summary (honesty notes)

- Confirmed against official 2026 sources: Asset Library structure/categories/support levels/submission rules; the 4.7 Asset Store introduction, its features, GH-112992 in-editor rework, and 4.7.x fixes; headless/`--headless` and dedicated-server CLI behavior; Blender/glTF/SVG import pipelines.
- Explicitly stated by their own READMEs as Godot 4.7-tested: XOVIET-GAME/godot-mcp, Rufaty/godot-mcp-enhanced, unxsist/godot-ai-chat ("Godot 4.7"), spardanviro/Godot_AI ("4.7+"), and GodotSteam's 4.7 changelog note. Phantom Camera, Dialogue Manager, LimboAI (1.7.x = "4.6 or higher"), GodotSteam 4.22, and most MCP servers declare 4.4+/4.6+ floors that should include 4.7, but per-release 4.7.2 testing is not independently confirmed.
- Unverified for 4.7/4.7.2 unless noted above: individual plugin versions on the Asset Library, Tiled importer addons, GUT, GdUnit4, ProtonScatter, Godot Jolt, Aseprite Wizard, Dialogic 2 (still 2.0-alpha line), and all smaller MCP forks. The Asset Store's minimum-Godot-version field and per-asset changelogs (new in 4.7) are the correct place to confirm.

---

## 21. VERIFICATION STATUS — Omission Audits

### Audit #1 (structure-level, writing के दौरान)

**Verified directly from 4.7.2 source code (commit ed1daf0bf):**
- Version identity (version.py = 4.7.2 stable), tag match
- 810 classes सभी की inventory + counts (doc/classes/*.xml parse)
- 260 nodes की grouping, 259 resources की list
- 230 project setting keys (GLOBAL_DEF regex extraction, recursive whole-repo scan)
- 171 editor setting keys (editor/settings/editor_settings.cpp parse)
- 104 CLI options (main/main.cpp), 156 SCons options (SConstruct + detect.py)
- 19 importers, 10 resource formats, export plugins of 8 platforms
- 57 modules, thirdparty README (versions/licenses), 36 GDScript annotations

**NOT fully covered (honest limitations):**
- प्रत्येक class के 9,896 methods का पूरा signature text — physically इस doc में नहीं (कहा गया: `--dump-extension-api`/docs से 100% मिल जाता है)
- Editor के हर menu का item-by-item screenshot-level breakdown — structure + settings + tools covered, पर हर dropdown वाला item नहीं (यह UI-dependent भी है)
- Runtime behaviour/performance benchmarks — static audit है, tests नहीं चलाए गए

### Audit #2 (final, user के 22 points के against)

| # | Area | Status |
|---|---|---|
| 1 | Editor screens/panels/docks/menus | ✅ Section 9 (structure + docks + dialogs + tools; menu-item-level detail NOT exhaustive) |
| 2 | Project/Editor Settings | ✅ Sections 7-8 (सारे registered keys) |
| 3 | Node types + differences | ✅ Section 5 + class table |
| 4 | Class reference | ✅ Section 4 (full inventory + counts; full method text via dump-extension-api) |
| 5 | GDScript/C#/GDExtension | ✅ Section 16 + 18 §3-5 |
| 6 | Rendering/Vulkan/GL | ✅ Section 2 + 18 §7 |
| 7 | Physics | ✅ Section 3 |
| 8 | Animation | ✅ Section 9 (animation editors) + node groups |
| 9 | Audio | ✅ modules (ogg/vorbis/mp3/interactive_music) + node groups + 18 |
| 10 | UI/Control | ✅ Section 5 groups (Control 20, Container 14) + 635 theme items |
| 11 | Networking | ✅ modules (enet/webrtc/websocket/upnp/mbedtls/multiplayer) + @rpc |
| 12 | Navigation | ✅ modules + 15 navigation settings |
| 13 | Import/export | ✅ Sections 10-11 |
| 14 | Platforms | ✅ Section 11 + 18 §8 |
| 15 | Editor plugins/extension points | ✅ Section 17 |
| 16 | GDExtension/Android plugins | ✅ Section 18 §5 + 11 |
| 17 | Asset Library | ✅ Section 20 |
| 18 | AI/MCP | ✅ Section 20 (community, labeled) |
| 19 | CLI/headless/CI | ✅ Section 12 + 18 §8 |
| 20 | Source modules/thirdparty | ✅ Sections 13-14 |
| 21 | New/changed/deprecated 4.7.2 | ✅ Section 19 |
| 22 | Hidden/obscure items | ✅ sections में बिखरे + नीचे MISSING list |

**Conflicting/unverified information (explicitly):**
- Asset compatibility ("works in 4.7.2") Asset Library में submitter-declared है — independently verified नहीं (Section 20 marked)
- Sub-agent research में जो items unverified marked हैं (e.g. कुछ PR attributions) — वैसे ही रखे गए हैं
- `@export_tool_button` जैसे newest GDScript annotations का exact 4.7.2 में stable/experimental status — docs से cross-check करें

---

## 22. MISSING / UNVERIFIED ITEMS (final list)

1. **Per-method full signatures (9,896 methods)** — इस doc में counts हैं, पूरा text नहीं। Verbatim source: `godot --headless --dump-extension-api` या https://docs.godotengine.org/en/stable/classes/
2. **Editor menu-item-level enumeration** — हर menu के हर item की list (e.g. हर context-menu option) — structure-level coverage है, pixel-level नहीं।
3. **Runtime performance numbers** — कोई benchmark नहीं चलाया गया (static audit)।
4. **Godot 4.8 dev changes** — यह doc सिर्फ़ 4.7.2-stable तक scoped है।
5. **हर community plugin की 4.7.2 compatibility** — plugin-specific testing नहीं हुई; Asset Store metadata पर भरोसा।
6. **VisionOS/WebXR जैसे niche platforms के runtime behaviour** — official docs + source से capability listed, device testing नहीं।
7. **`editor_plugin_list.cpp`** के registered plugin ordering जैसे internal editor wiring की पूरी detail।
8. **Input map defaults**, theme default palettes जैसे data-driven defaults (XML में नहीं होते)।

---

## 23. Primary sources

- Source code: https://github.com/godotengine/godot/tree/4.7.2-stable (commit ed1daf0bf)
- Release notes 4.7: https://godotengine.org/releases/4.7/
- 4.7.2 announcement: https://godotengine.org/article/maintenance-release-godot-4-7-2/
- Interactive changelog: https://godotengine.github.io/godot-interactive-changelog/
- Official docs: https://docs.godotengine.org/en/stable/
- Asset Library: https://godotengine.org/asset-library

*Document generated: 26 September 2026 — Godot 4.7.2-stable exhaustive audit। Hindi narrative + English technical identifiers।*