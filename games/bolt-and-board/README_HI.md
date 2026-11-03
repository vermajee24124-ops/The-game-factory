# Bolt & Board Puzzle — Godot 4.7.2

यह आपका अलग पहचान वाला 3D screw-removal puzzle prototype है। यह सामान्य screw/board puzzle genre से प्रेरित है; किसी commercial game का source code, logo, exact level, UI या artwork कॉपी नहीं किया गया है।

## प्रोजेक्ट में क्या है
- Godot 4.7.2 Stable target, GDScript और Mobile Renderer।
- हर layer में H, X, cross-frame और zig-zag जैसे interlocked wooden beams, metallic screws, washers और thread details।
- Original wood-grain और brushed-metal PBR normal maps, roughness map और हल्की maple-table texture।
- Android touch और desktop mouse के लिए screen-space screw picking, ताकि board पर सीधा tap करने से screw चुने।
- अलग रंग के screw heads और तीन matching colour toolboxes।
- Five-slot spare tray: screw निकालकर tray में रखें, फिर matching colour box दबाकर sort करें।
- हर beam पर आमतौर पर 2 से 4 screws हैं, ताकि board साफ़ पढ़ा जा सके।
- Full-screen UI root अब gameplay touch को block नहीं करता; covered screws फिर भी select नहीं हो सकते।
- ऊपरी बोर्ड के collider से नीचे छिपे screw पर tap रोकना।
- Screw removal और board-clear animations।
- Generated sound effects।
- 30 procedural level variations, 2 से 5 layers और हर level में अलग beam arrangements।
- हर beam पर संतुलित screw count, running timer और mobile-friendly soft shadow setup।
- Branded splash/loading screen, first-run tutorial, level select, restart, Hint, progress HUD, level-complete screen और local save।
- Headless gameplay tests और Xvfb screenshot capture।

## Cloud validation
2 नवंबर 2026 को GitHub Actions पर Godot Engine 4.7.2 Stable चलाया गया। Headless project import/parse, gameplay smoke tests और Xvfb preview capture सफल हुए। Rendered preview GitHub Actions artifact में उपलब्ध है।

यह cloud runner Mesa software OpenGL पर चला; इसका प्रदर्शन आपके Android फोन के प्रदर्शन का प्रमाण नहीं है। शुरुआती prototype के tests पास हुए थे। Level Select, pause और progression के नए regression tests जोड़े गए हैं; उनका नया CI result आने के बाद ही उन्हें verified माना जाएगा। पूरा रिकॉर्ड `docs/TEST_STATUS.md` में है।

## प्रोजेक्ट खोलना
1. ZIP को extract करें।
2. Godot 4.7.2 Stable में `project.godot` import करें।
3. `Main.tscn` run करें।
4. PLAY दबाएँ. चमकते/दिख रहे screw head पर tap करें. ऊपर की board पहले हटेगी; उसके नीचे के screws उसके बाद खुलेंगे।

## Headless checks
Godot executable और Python dependencies मौजूद हों तो:

```bash
python -m pip install pillow numpy
python tools/generate_assets.py
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/headless_tests.gd
```

Screenshot के लिए display या Xvfb चाहिए:

```bash
xvfb-run -a godot --path . --script res://tests/capture_preview.gd
```

Screenshot `artifacts/godot_preview.png` में बनेगा।

## Android export
`export_presets.cfg` में ARM64 debug APK preset है। `.github/workflows/screw-puzzle-android.yml` GitHub Actions में Android SDK, JDK 17 और matching Godot templates लगाकर test APK बनाने के लिए है। सफल build पर `bolt-and-board-android-debug` artifact में APK मिलेगा। यह debug/test APK है, Play Store release नहीं। Package ID `com.example.boltandboard` placeholder है और publish करने से पहले बदलना होगा। Release AAB, निजी release signing key और physical Android QA अभी बाकी हैं। किसी भी signing key या password को public repository में commit न करें।

## जरूरी स्थिति
यह एक tested prototype है, final commercial release नहीं। इसमें अभी सीमित procedural board patterns हैं; 30 levels 30 अलग hand-designed puzzles नहीं हैं। पहले Android device test और फिर level variety, art polish, settings/accessibility, monetization, privacy और store policy का काम जरूरी है।

## License
इस folder के original game files MIT-licensed हैं। `LICENSE` और `THIRD_PARTY_NOTICES.md` पढ़ें। Godot engine और भविष्य में जोड़े जाने वाले third-party components अपने license notices के अधीन रहेंगे।
