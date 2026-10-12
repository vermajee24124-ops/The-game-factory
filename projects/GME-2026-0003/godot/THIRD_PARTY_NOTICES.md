# Turbo Rush third-party assets

Turbo Rush uses selected CC0 assets from the supplied production asset package.

- Kenney Car Kit: CC0 1.0 Universal. Used assets include Race Future and Sedan Sports.
- Kenney City Kit Commercial: CC0 1.0 Universal. Used assets include Building C and Building Skyscraper B.
- Kenney City Kit Roads: CC0 1.0 Universal. Used asset includes Light Square Double.
- Kenney Racing Kit: CC0 1.0 Universal. Used assets include Grand Stand Covered and Barrier Red.
- Kenney City Kit Suburban: CC0 1.0 Universal. Available in the supplied package but not required by the current runtime build.
- Kenney City Kit Industrial: CC0 1.0 Universal. Available in the supplied package but not required by the current runtime build.
- Modular Racetrack: CC0 1.0 Universal. Supplied production reference pack; the current game keeps its procedural track runtime.
- Racing Cars Mega Pack: CC0 1.0 Universal. Available in the supplied package; only selected low-poly assets are pulled into the runtime build.

Excluded: the supplied "CAR Model by Ignition Labs" package is not included in the production build because its supplied archive did not contain a license/readme/credit file that was sufficient to verify redistribution rights.

The current CI release pipeline downloads only the seven selected Kenney GLBs from a pinned public Git commit at build time, instead of shipping the complete source asset libraries.


## Runtime model sources used by the Android build workflow

The Android build downloads selected model files at build time from the source pages below. The source page describes the relevant pack as CC0-1.0. The build records selected-file hashes in `projects/GME-2026-0003/artifacts/SELECTED_ASSETS_SHA256.txt`.

- Kenney Car Kit (vehicle body variants, wheels and textures): CC0-1.0 — https://opengameart.org/content/car-kit
- Kenney Racing Kit (grandstand and barriers): CC0-1.0 — https://opengameart.org/content/racing-kit
- Kenney City Kit Roads (roadside lighting): CC0-1.0 — https://opengameart.org/content/city-kit-roads
- Kenney City Kit Commercial (building variants): CC0-1.0 — https://opengameart.org/content/city-kit-commercial
- Kenney City Kit Suburban (low-rise buildings): CC0-1.0 — https://opengameart.org/content/city-kit-suburban
- Kenney City Kit Industrial (containers and industrial scenery): CC0-1.0 — https://opengameart.org/content/city-kit-industrial
- Modular Racetrack 3D Models: CC0-1.0 — https://opengameart.org/content/modular-racetrack-3d-models
- Racing Assets v1: CC0-1.0 — https://opengameart.org/content/racing-assets-v1
- Quaternius Low Poly Cars: CC0-1.0 — https://opengameart.org/content/low-poly-cars-0
- Free Low Poly Vehicles Pack: CC0-1.0 — https://opengameart.org/content/free-low-poly-vehicles-pack

The supplied Ignition Labs car model files are intentionally excluded because the uploaded archive did not include enough licence/credit evidence to verify redistribution rights. Keep each source's own licence or README where available. A third-party source list is included for auditability even where CC0 does not require attribution.
