# Turbo Rush Acceptance Matrix

| Area | Gate | Status |
|---|---|---|
| Engine | Godot 4.7.2 pinned | PASS |
| Race | Finite race with finish line | PASS |
| Racers | 1 player + 5 AI | PASS |
| Procedural | Deterministic level seed | PASS |
| Procedural | 10,000-level smoke coverage | PASS |
| Economy | Coins / Diamonds / rewards | PASS |
| Save | Local JSON + backup + checksum | PASS |
| Progression | Top-5 unlock rule + assist | PASS |
| Cosmetics | Cars / paints / wheels | PASS |
| UI | Core menu / race / garage / shop / settings | PASS |
| Ads | Deferred provider adapter | DEFERRED |
| IAP | Deferred provider adapter | DEFERRED |
| Epic / Online | Deferred | DEFERRED |
| Security | Code / dependency / repository gates | PASS FOR CODEBASE, DEVICE AUDIT PENDING |
| Performance | Mobile device matrix | DEVICE TEST REQUIRED |
| Compliance | Standalone offline release audit | FINAL CHECK REQUIRED |
| Android Build | Debug APK export | WORKFLOW READY |
| Android Release | Publisher-signed release APK/AAB | SIGNING KEY REQUIRED |

## Definition

The standalone 1.0 game does not require Ads, Aptoide Billing or Epic services to function.

A production store build is only marked ready after a real-device install test, performance check, compliance check and publisher-controlled release signing.
