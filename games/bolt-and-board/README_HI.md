# Bolt & Board Puzzle — Godot 4.7.2

यह आपका अलग पहचान वाला 3D screw-removal puzzle prototype है। यह सामान्य screw/board puzzle genre से प्रेरित है; किसी commercial game का source code, logo, exact level, UI या artwork कॉपी नहीं किया गया है।

## प्रोजेक्ट में क्या है
- Godot 4.7.2 Stable target, GDScript और Mobile Renderer।
- Procedural 3D लकड़ी के बोर्ड, metallic screws, washers और thread details।
- Original generated wood, brushed-steel और dark-surface textures।
- Android touch और desktop mouse से exposed screw चुनना।
- ऊपरी बोर्ड के collider से नीचे छिपे screw पर tap रोकना।
- Screw removal और board-clear animations।
- Generated sound effects।
- 30 procedural level variations, 2 से 5 board layers।
- Restart, Hint, progress HUD, level-complete screen और local save।
- Headless gameplay tests और Xvfb screenshot capture।

## इस शाखा का GitHub स्थान
`games/bolt-and-board/`

## Godot में खोलना
1. ZIP को extract करें या GitHub से इस branch का source लें।
2. Godot 4.7.2 Stable में `project.godot` import करें।
3. `Main.tscn` run करें।
4. PLAY दबाकर exposed screw heads पर tap करें।

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

## ईमानदार स्थिति
यह एक expanded prototype है, final commercial release नहीं। इस काम के container में Godot binary डाउनलोड/चलाने का नेटवर्क उपलब्ध नहीं था। इसलिए Godot parser/runtime, असली screenshot, Android export और आपके फोन पर performance/touch अभी verified नहीं हैं। GitHub Actions में अलग validation workflow जोड़ा गया है; उसके सफल परिणाम और वास्तविक Android device test के बाद ही build को verified कहा जाएगा।

## Android release
Release APK/AAB के लिए compatible Android SDK, JDK, Godot export templates और signing key चाहिए। Keystore/password को repository या chat में कभी commit न करें। Release signing और Play Store listing अंतिम अलग चरण हैं।

## License
इस folder के original game source MIT-licensed है। Engine और भविष्य में जोड़े जाने वाले third-party components अपने-अपने notices के अधीन रहेंगे। `LICENSE` और `THIRD_PARTY_NOTICES.md` पढ़ें।
