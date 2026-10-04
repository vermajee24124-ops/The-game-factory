# Turbo Rush Uploaded Asset Package Audit — 2026-10-04

Source package: **Turbo_Rush_All_Assets(2).zip**

The package was inspected before integration. The final game uses a curated
subset rather than importing every source file into the runtime.

## Packages found

| Package | License evidence found | Runtime decision |
|---|---|---|
| Kenney Car Kit | CC0 1.0 | Approved, curated GLB vehicles/wheels/traffic |
| Kenney Racing Kit | CC0 1.0 | Approved, curated race props/barriers/stand assets |
| Kenney City Kit Roads | CC0 1.0 | Approved for road/lighting assets |
| Kenney City Kit Commercial 2.1 | CC0 1.0 | Approved for buildings |
| Kenney City Kit Suburban 2.0 | CC0 1.0 | Approved for selected suburban buildings |
| Kenney City Kit Industrial 2.0 | CC0 1.0 | Approved for selected industrial props |
| Modular Racetrack CC0 | CC0 1.0 | Approved as a source library; not blindly imported |
| Racing Cars Mega Pack | CC0 1.0 according to its supplied README/CREDITS | Approved for curated future/runtime variants |
| CAR Model by Ignition Labs | No license file/evidence inside the supplied ZIP | Excluded from runtime until independent license proof exists |

## Selected runtime assets now used by Turbo Rush

- race-future.glb
- sedan-sports.glb
- hatchback-sports.glb
- suv-luxury.glb
- building-c.glb
- building-skyscraper-b.glb
- building-type-a.glb
- shipping-container-a.glb
- light-square-double.glb
- grandStandCovered.glb
- barrierRed.glb
- ambulance.glb
- police.glb
- firetruck.glb
- race.glb
- wheel-racing.glb

These are sourced from the supplied CC0 packages listed above and are
downloaded into the CI build workspace as curated runtime assets.

## Important decision

The asset package is not copied wholesale into the final APK/WEB build.
Only assets used by the game are included, reducing build size and memory
pressure.

The Ignition Labs car model is not included because the supplied archive
does not provide license evidence for redistribution/commercial runtime
use. This is a deliberate legal-safety exclusion.

## Turbo Rush integration

The StudioPolish runtime layer uses actual 3D assets for the menu hero and
race environment dressing, while the existing gameplay systems remain the
source of truth for progression, racing, save data and economy.
