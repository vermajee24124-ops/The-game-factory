# Test status — 2026-11-03

## Latest Godot validation
<https://github.com/vermajee24124-ops/The-game-factory/actions/runs/41560470638>

<badge>PASS</badge> Godot 4.7.2 Stable imported the project, parsed the scripts, ran the expanded gameplay regression tests and rendered the screenshot under Xvfb/Mesa software OpenGL.

The passing regression suite covers:
- Screw occlusion and exposed-screw access.
- Board clearing and sequential screw removal.
- Level layer bounds, unlock rules and pattern variation.
- Level Select, pause and resume state transitions.
- Escape/back-key pause and resume navigation.
- Level completion, next-level progression and save unlock behavior.

The cloud screenshot is a rendering check only. It does not prove Android device performance.

## Android debug build
A prior ARM64 Android debug APK export succeeded and the APK archive passed ZIP integrity validation. The latest camera/back-navigation code has a new Android export workflow queued/running; use its artifact once it completes rather than treating the older APK as the latest build.

The debug APK is for local testing only, not a Play Store release. The package ID is still the placeholder `com.example.boltandboard`.

## Not yet verified
- Latest ARM64 APK export for commit `07d9d615`.
- Installation, touch accuracy, frame rate, memory and thermal behavior on a physical Android phone.
- A release AAB signed with a private release key.
- 30 individually authored and professionally balanced levels.
- Full accessibility, privacy, monetization and store-policy readiness.

## CI environment note
Xvfb/Mesa software rendering and a dummy audio driver do not represent a real Android device. Passing cloud tests cannot prove phone performance or touch quality.

This project remains a development build, not a final commercial release. Do not label it production-ready until Android device QA and the release checklist are complete.
