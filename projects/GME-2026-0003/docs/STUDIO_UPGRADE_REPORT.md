# Turbo Rush Studio Upgrade Report

## Scope
Turbo Rush remains a Godot 4.x, Android/iOS, 3D, finite level-based arcade racing game. The existing project and gameplay loop were preserved as the foundation.

## Implemented in this pass
- Version line advanced to the 1.7.x release track.
- Branded Turbo Rush project icon/splash references retained in Android export configuration.
- Main menu uses a persistent 3D hero-car showcase with controlled lighting and camera.
- Main menu hero refreshes to the selected player car.
- Race presentation uses environment/condition-aware background, fog, ambient light and sun tuning.
- Racing surface received curb detailing and a starting-grid treatment.
- Roadside landmark/sign dressing was added to break up empty track space.
- Vehicle presentation received underglow, mirrors, boost flame/light and brake-light feedback.
- Race camera adapts FOV with speed and boost state.
- Collision feedback includes impact flash and camera response.
- Existing car/wheel/skin/card catalog, economy and offline-first save/progression remain intact.
- External billing and paid-content systems are absent from the Turbo Rush runtime.
- Native Android advertising is isolated behind a Godot v2 plugin adapter.
- Web advertising is isolated behind the JavaScriptBridge-compatible host adapter.

## Asset policy
The supplied asset archive was audited. CC0 packages are permitted for the project. The unverified Ignition Labs model remains excluded from runtime use until its license can be independently confirmed.

## QA
The GitHub Actions pipeline performs:
1. Godot 4.7.2 headless import.
2. Script-error detection during import.
3. Turbo Rush smoke tests.
4. Release APK export.
5. Release AAB export.
6. Android APK signature/badging/hash validation.
7. AAB structure/hash validation.
8. Web export generation.

## Device testing
The engineering environment has no connected physical Android/iOS device, so device-specific FPS, thermals, touch latency, installation/upgrade behavior and live ad runtime behavior are not claimed as verified until tested on real hardware.
