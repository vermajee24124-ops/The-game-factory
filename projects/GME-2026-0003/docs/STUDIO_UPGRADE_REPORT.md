# Turbo Rush Studio Upgrade Report

## Scope
Turbo Rush remains a Godot 4.x, Android/iOS, 3D, finite level-based arcade racing game. The existing project and gameplay loop were preserved as the foundation.

## Implemented in this pass
- Version bumped to 1.2.0.
- Branded Turbo Rush project icon/splash references retained in the Android export configuration.
- Main menu now includes a persistent 3D hero-car showcase with controlled lighting and camera.
- Main menu hero rotates subtly and refreshes to the selected player car.
- Race presentation now uses environment/condition-aware background, fog, ambient light and sun tuning.
- Racing surface received curb detailing and a starting-grid treatment.
- Roadside landmark/sign dressing was added to break up empty track space.
- Vehicle presentation received underglow, mirrors, boost flame/light and brake-light feedback.
- Race camera now adapts its distance/FOV with speed and boost state.
- Player vehicle gets subtle steering lean.
- Collision feedback includes a brief impact flash and camera response.
- Existing car/wheel/skin/card catalog and economy remain intact.
- Existing offline-first save/progression systems remain intact.

## Asset policy
The supplied asset ZIP was inspected. The existing third-party notice records CC0 packages and keeps the unverified Ignition Labs model out of production until its license is independently verified.

## QA
The GitHub Actions pipeline performs:
1. Godot 4.7.2 headless import.
2. Script-error detection during import.
3. Existing Turbo Rush smoke tests.
4. Release APK export.
5. Release AAB export.
6. Android APK signature/badging/hash validation.
7. AAB structure/hash validation.

## Release note
The CI pipeline currently generates a temporary release keystore per run. That is suitable for build verification, but a persistent production upload key must be stored securely for long-term store updates. Native Unity Ads and Aptoide Billing bridges are still gated because their live native adapters and exact production ad-unit/account setup are not present in the repository.

## Device testing
No physical Android/iOS device is connected to the current engineering environment. Therefore device-level FPS, thermals, touch latency, install/upgrade behavior and store-service runtime behavior are not claimed as verified.
