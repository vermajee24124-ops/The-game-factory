from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

SCAN_ROOTS = [
    ROOT / "godot",
    ROOT / "android_plugins",
]

FORBIDDEN = [
    re.compile(r"(?i)Aptoide"),
    re.compile(r"(?i)BillingClient"),
    re.compile(r"(?i)Google Play Billing"),
    re.compile(r"(?i)StoreKit"),
    re.compile(r"(?i)IAPManager"),
    re.compile(r"(?i)restore[_ -]?purchases"),
    re.compile(r"(?i)pending[_ -]?purchase"),
    re.compile(r"(?i)receipt[_ -]?validation"),
    re.compile(r"(?i)billing[_ -]?permission"),
]

# These legacy-save migration lines are intentionally allowed because they
# only remove obsolete fields and never execute a purchase entitlement.
ALLOWED_LEGACY = [
    'data.erase("iap")',
    'data.erase("in_app_purchases")',
    'data.erase("monetization_entitlements")',
    'data["monetization"].erase("iap")',
    'data["monetization"].erase("remove_ads")',
]

TEXT_EXTENSIONS = {".gd", ".cfg", ".ini", ".gradle", ".gradle.kts", ".xml", ".json", ".properties", ".java", ".kt", ".py"}

problems = []

for scan_root in SCAN_ROOTS:
    if not scan_root.exists():
        continue
    for path in scan_root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXTENSIONS:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            if any(allowed in line for allowed in ALLOWED_LEGACY):
                continue
            for rx in FORBIDDEN:
                if rx.search(line):
                    problems.append(f"{path.relative_to(ROOT)}:{lineno}: {line.strip()}")
                    break

# Explicitly check the Android export config/manifest-adjacent project files.
for path in [
    ROOT / "godot" / "project.godot",
    ROOT / "godot" / "export_presets.cfg",
]:
    if path.exists():
        text = path.read_text(encoding="utf-8")
        if re.search(r'(?i)(BILLING|Aptoide|StoreKit|BillingClient|IAPManager)', text):
            problems.append(f"{path.relative_to(ROOT)} contains a billing/IAP token")

if problems:
    print("Turbo Rush monetization audit: FAIL")
    print("\n".join(problems))
    sys.exit(1)

print("Turbo Rush monetization audit: PASS")
print("No active Aptoide/billing/IAP implementation found in the audited build surface.")
