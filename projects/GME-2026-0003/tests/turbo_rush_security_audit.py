from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"

TEXT_EXT = {".gd",".cfg",".ini",".gradle",".gradle.kts",".xml",".json",".properties",".java",".kt",".py",".md",".yaml",".yml"}

patterns = [
    re.compile(r"(?i)-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"(?i)(?:api[_-]?key|secret|token|password)\s*[:=]\s*['\"][^'\"]{16,}['\"]"),
    re.compile(r"(?i)sk-[A-Za-z0-9_-]{16,}"),
    re.compile(r"(?i)AIza[0-9A-Za-z_-]{20,}"),
    re.compile(r"(?i)gh[pousr]_[A-Za-z0-9_]{20,}"),
]

problems=[]
for base in [GODOT, ROOT / "android_plugins" / "turbo_unity_ads"]:
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        try:
            text=path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        rel=path.relative_to(ROOT).as_posix()
        if '"debug_save":true' in text or "'debug_save':true" in text:
            problems.append(f"{rel}: debug_save is enabled")
        if "OS.execute(" in text or "eval(" in text:
            problems.append(f"{rel}: process/eval primitive requires manual review")
        for lineno,line in enumerate(text.splitlines(),1):
            for rx in patterns:
                if rx.search(line):
                    problems.append(f"{rel}:{lineno}: possible hardcoded secret")
                    break

project=(GODOT / "project.godot").read_text(encoding="utf-8") if (GODOT / "project.godot").exists() else ""
for forbidden in ["BillingClient","StoreKit","IAPManager","Aptoide"]:
    if re.search(forbidden, project, re.I):
        problems.append(f"project.godot contains forbidden monetization token: {forbidden}")

if problems:
    print("Turbo Rush security audit: FAIL")
    print("\n".join(problems))
    sys.exit(1)

print("Turbo Rush security audit: PASS")
print("No hardcoded-secret pattern, debug-save flag, or forbidden billing token found in the audited release surface.")
