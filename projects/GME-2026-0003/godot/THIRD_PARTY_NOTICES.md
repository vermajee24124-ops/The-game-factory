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
