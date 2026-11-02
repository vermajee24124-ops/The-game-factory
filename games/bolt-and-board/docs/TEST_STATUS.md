# Test status — 2026-11-02

## Previously verified prototype checks
The earlier prototype CI run passed:
- Godot Engine 4.7.2 Stable imported the project and parsed the original scripts.
- The original gameplay smoke tests passed for screw occlusion, board removal, level layer bounds, scene load and sequential board clearing.
- The project rendered under Xvfb with Mesa software OpenGL.
- The earlier workflow produced a project ZIP and preview artifact.

That pass predates the current Level Select, pause menu, scoring and Android export changes. It is not evidence that the newly added code has passed.

## New regression tests added
The test suite now also checks:
- Level unlock boundaries and progression.
- Deterministic screw pattern variation.
- Level Select and pause overlay creation.
- Pause and resume state transitions.
- Level completion result screen and next-level progression.

A new GitHub Actions validation run must pass before these additions are marked verified.

## Android build automation added
- `export_presets.cfg` contains an ARM64 Android Debug preset.
- `.github/workflows/screw-puzzle-android.yml` installs JDK 17, Android SDK packages and the exact Godot 4.7.2 export templates.
- The workflow is designed to upload a debug APK as `bolt-and-board-android-debug`.

The workflow has no production signing credentials. A debug APK is for local installation and testing only, not a Play Store release.

## Not yet verified
- Latest regression-test execution for the new menu and campaign code.
- Successful Android APK export from the new workflow.
- Installation, touch accuracy, frame rate, memory and thermal behavior on a physical Android phone.
- A release AAB signed with a private release key.
- 30 individually authored and professionally balanced levels.
- Full accessibility, privacy, monetization and store-policy readiness.

## CI environment note
Xvfb/Mesa software rendering and a dummy audio driver do not represent a real Android device. Passing cloud tests cannot prove phone performance or touch quality.

This project remains a development build, not a final commercial release. Do not label it production-ready until the Android build, real-device QA and release checklist are complete.
