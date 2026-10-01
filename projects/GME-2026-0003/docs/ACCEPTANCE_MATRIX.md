# Turbo Rush Acceptance Matrix

| Area | Gate | Current status |
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
| Identity | Android package name fixed | PASS |
| Support | Support email configured in app settings | PASS |
| Unity Ads | Game IDs configured; native bridge pending exact ad-unit IDs | CONFIGURED / BRIDGE PENDING |
| Startup Ads | Two banner instances, top + bottom, startup/loading only | CODE PATH READY |
| Aptoide | Public key configured | PASS |
| Aptoide IAP | Native billing + product registration + validation | PENDING |
| Notifications | Product behavior defined | PENDING NATIVE SCHEDULER |
| Security | Code / dependency / repository gates | PASS FOR CODEBASE, DEVICE AUDIT PENDING |
| Performance | Mobile device matrix | DEVICE TEST REQUIRED |
| Compliance | Store submission metadata/privacy/consent | FINAL CHECK REQUIRED |
| Android Build | Debug APK export workflow | READY |
| Android Release | Publisher-signed release APK/AAB | SIGNING KEY REQUIRED |

The current repository is deliberately not marked as a production release until the external billing/ads inputs, native bridges, signing, store compliance and real-device tests have been completed.
