# Bolt & Board Puzzle

**Godot 4.7.2 Stable · Android ARM64 debug build · 3 नवंबर 2026**

यह एक original 3D screw-removal और color-sorting puzzle game है। इसका gameplay सामान्य screw puzzle genre से प्रेरित है, लेकिन किसी commercial game का source code, logo, artwork या exact level copy नहीं किया गया है।

## अभी क्या शामिल है

- 30 procedural levels, 2 से 5 stacked layers और हर layer में अलग-अलग wooden plates।
- छह plate-layout families: paired planks, vertical planks, side-and-center, horizontal strips, L-shape और four-corner layout।
- PBR wood और brushed-steel textures, normal maps और roughness maps।
- Walnut-style stage, brass-colored rounded plate edges, metallic screws, washers, helical threads और recessed cross-drive details।
- चार रंगों के screws, active color toolboxes और पाँच-slot temporary storage।
- गलत रंग के screws temporary storage में जाते हैं। अगले toolbox का रंग active होने पर matching stored screws अपने-आप उसमें transfer होते हैं।
- पाँचों temporary slots भरने पर level retry screen दिखती है।
- Android touch और desktop mouse picking, camera drag-orbit और pinch-to-zoom।
- Screw removal, plate-fall animations और fall पूरी होने तक नीचे के screws का सही तरीके से blocked रहना।
- Studio splash, local loading screen, first-run tutorial, level select, timer, hint, pause, restart और local progress save।
- Original generated sound effects और launcher icons।

## Project खोलना

1. Source ZIP को extract करें।
2. Godot 4.7.2 Stable में project.godot import करें।
3. Main.tscn run करें।
4. CONTINUE दबाएँ और खुले screw को चुनें। Active toolbox के रंग से अलग screw temporary tray में जाएगा।

## Validation

3 नवंबर 2026 को GitHub Actions पर Godot 4.7.2 के headless gameplay tests और Xvfb screenshot capture सफल हुए।

- Godot validation run: https://github.com/vermajee24124-ops/The-game-factory/actions/runs/41593473319
- Android ARM64 debug export: https://github.com/vermajee24124-ops/The-game-factory/actions/runs/41593473277

Regression tests में touch picking, covered screw blocking, toolbox batches, temporary storage, buffered screw transfer, retry state, multi-piece layouts, plate-fall blocking, pause/back navigation और level progression जाँचे गए।

Cloud screenshot और CI tests आपके Android फोन पर वास्तविक FPS, heat, touch accuracy या memory use साबित नहीं करते। Physical-device QA अभी बाकी है।

## Android build की स्थिति

- ABI: ARM64
- Package ID: com.example.boltandboard (placeholder)
- Build type: Debug/test APK
- APK ZIP integrity check: PASS
- यह Play Store release APK या signed release AAB नहीं है।

Release package name, private signing key, AAB, device QA, accessibility, privacy, ads consent और store-policy checks अभी बाकी हैं। किसी signing key या password को public repository में commit न करें।

## जरूरी सीमा

30 levels procedural variations हैं, 30 अलग hand-designed और solver-validated commercial puzzles नहीं। गेम अभी development build है, production-ready release नहीं।

## License

इस folder के original game files MIT-licensed हैं। LICENSE और THIRD_PARTY_NOTICES.md पढ़ें। Godot Engine और third-party components अपने-अपने license के अधीन हैं।
