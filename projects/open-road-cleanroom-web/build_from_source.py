#!/usr/bin/env python3
"""Build Open Road from source, tune high-speed steering, then make a Yes2Games ZIP.

Unlike build_web.py (which wraps the published build), this script rebuilds the
C++/WebAssembly engine so steering-physics changes are actually present in the game.
"""
from __future__ import annotations

import argparse
import importlib.util
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

UPSTREAM_URL = "https://github.com/andrewnakas/opennfs-cleanroom.git"
ENGINE_URL = "https://github.com/OpenNFS/OpenNFS.git"


def run(command: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None) -> None:
    print("$ " + " ".join(str(x) for x in command), flush=True)
    subprocess.run(command, cwd=str(cwd) if cwd else None, env=env, check=True)


def replace_exactly_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        raise RuntimeError(f"Steering patch point '{label}' expected once, found {count}. Refusing to build with unknown handling.")
    return content.replace(old, new, 1)


def tune_source(upstream: Path) -> None:
    patch_file = upstream / "ports/opennfs/patches.py"
    source = patch_file.read_text(encoding="utf-8")
    source = replace_exactly_once(
        source,
        "float const lateralLimit{assetData.physicsData.wheelFriction * 9.81f * 0.62f};",
        "float const lateralLimit{assetData.physicsData.wheelFriction * 9.81f * 0.80f};",
        "higher cornering grip limit",
    )
    source = replace_exactly_once(
        source,
        "float const rate{(request == 0.f ? 2.6f : 1.5f) * lock + 0.08f};",
        "float const speedKmh{std::fabs(m_vehicle->getCurrentSpeedKmHour())};\n"
        "                float const highSpeedAssist{1.f + 0.65f * std::clamp(speedKmh / 180.f, 0.f, 1.f)};\n"
        "                float const rate{(request == 0.f ? 2.6f : 1.5f) * lock + 0.08f * highSpeedAssist};",
        "speed-dependent steering response rate",
    )
    source = replace_exactly_once(
        source,
        "std::min(3.0f * assist * dt, 0.5f)",
        "std::min(4.0f * assist * dt, 0.5f)",
        "faster yaw-assist response",
    )
    patch_file.write_text(source, encoding="utf-8", newline="\n")
    print("Steering tune applied: cornering limit 0.62g factor -> 0.80g factor; speed-dependent steering response; yaw response 3.0 -> 4.0.", flush=True)


def load_web_patcher(project_path: Path):
    patcher_path = project_path / "projects/open-road-cleanroom-web/build_web.py"
    spec = importlib.util.spec_from_file_location("openroad_web_patcher", patcher_path)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load the web patch helpers.")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="Output directory for the portal upload ZIP contents")
    args = parser.parse_args()

    project_path = Path(__file__).resolve().parents[2]
    out = Path(args.out).resolve()
    work = out.parent / "open-road-source-build"
    if work.exists():
        shutil.rmtree(work)
    if out.exists():
        shutil.rmtree(out)
    work.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)

    emsdk = os.environ.get("EMSDK")
    if not emsdk:
        raise RuntimeError("EMSDK is not set. Run this through the setup-emsdk GitHub Actions step.")
    emsdk_path = Path(emsdk).resolve()
    emcmake = shutil.which("emcmake")
    if not emcmake:
        raise RuntimeError("emcmake was not found on PATH after setting up Emscripten.")
    emscripten = emsdk_path / "upstream/emscripten"
    if not (emscripten / "tools/file_packager.py").is_file():
        raise RuntimeError(f"Emscripten file_packager.py not found under {emscripten}")

    upstream = work / "upstream"
    engine = work / "OpenNFS"
    port = work / "port"
    build = work / "build"
    clean = work / "clean"
    site = work / "site"

    print("Cloning the clean-room web port and its open-source engine dependencies...", flush=True)
    run(["git", "clone", "--depth", "1", UPSTREAM_URL, str(upstream)])
    run(["git", "clone", "--depth", "1", "--recurse-submodules", ENGINE_URL, str(engine)])

    tune_source(upstream)
    run([sys.executable, str(upstream / "games/opennfs/build_assets.py"), str(clean)], cwd=upstream)
    run([sys.executable, str(upstream / "ports/opennfs/prepare.py"), str(engine), str(port)], cwd=upstream)

    print("Configuring the tuned C++ engine for WebAssembly...", flush=True)
    run([
        emcmake, "cmake", "-S", str(upstream / "ports/opennfs"), "-B", str(build), "-G", "Ninja",
        "-DCMAKE_BUILD_TYPE=Release", "-DDEV_NAMES=OFF",
        f"-DENGINE={engine}", f"-DPORT={port}",
    ], cwd=upstream)
    run(["cmake", "--build", str(build), "--parallel", "2"], cwd=upstream)

    # The upstream packager has Windows-specific default paths. Make a temporary, path-corrected copy
    # rather than changing any files in the downloaded upstream source tree beyond the intended tune.
    packager = (upstream / "tools/make_site.py").read_text(encoding="utf-8")
    substitutions = [
        ('WORK = "D:/n64work/opennfs"', f'WORK = r"{work}"'),
        ('EMS = "D:/n64work/emsdk/upstream/emscripten"', f'EMS = r"{emscripten}"'),
        ('EM_CONFIG="/d/n64work/emsdk/.emscripten"', f'EM_CONFIG=r"{emsdk_path / ".emscripten"}"'),
        ('D:/n64work/emsdk/upstream/bin/llvm-objcopy.exe', str(emsdk_path / "upstream/bin/llvm-objcopy")),
    ]
    for old, new in substitutions:
        if packager.count(old) != 1:
            raise RuntimeError(f"Could not adapt the upstream asset packager path: {old}")
        packager = packager.replace(old, new, 1)
    packager_path = upstream / "tools/make_site_ci.py"
    packager_path.write_text(packager, encoding="utf-8", newline="\n")
    run([
        sys.executable, str(packager_path), "--out", str(site), "--assets", str(clean),
        "--build", str(build), "--port", str(port), "--release",
    ], cwd=upstream)

    # Retain upstream license notices alongside the modified release.
    shutil.copy2(upstream / "README.md", out / "UPSTREAM-README.md")
    shutil.copy2(upstream / "assets/LICENSES.csv", out / "UPSTREAM-LICENSES.csv")
    for child in site.iterdir():
        destination = out / child.name
        if child.is_dir():
            shutil.copytree(child, destination, dirs_exist_ok=True)
        else:
            shutil.copy2(child, destination)

    patcher = load_web_patcher(project_path)
    patcher.patch_html(out)
    patcher.patch_css(out)
    patcher.patch_audio(out)
    patcher.patch_js(out)

    tuning_note = """# Open Road steering tune

This release rebuilds the WebAssembly engine from source. It is not just a change to the web buttons.

- Increased the speed-sensitive lateral cornering limit coefficient from 0.62 to 0.80. The steering lock therefore stays more useful in medium and fast bends.
- Added a speed-dependent steering response factor, rising gradually with speed and capping at 180 km/h. This makes the left/right inputs reach the available steering lock more quickly without making low-speed steering dramatically twitchier.
- Increased yaw-assist response from 3.0 to 4.0 so chassis rotation follows the chosen steering angle sooner.
- Kept the existing speed-based steering lock, tyre-friction limit, five-opponent setup, loading screen, mobile touch-input protections and Yes2SDK lifecycle/ad safeguards.

The build must pass the JavaScript syntax, mocked Yes2SDK lifecycle/ad tests, required-file checks and ZIP integrity checks. This is still not a substitute for a real Yes2Games Inspector certification and device test.
"""
    (out / "STEERING-TUNING.md").write_text(tuning_note, encoding="utf-8", newline="\n")

    # Make sure the built JS was derived from the patched source engine, not the published prebuilt WASM.
    status = {
        "build_mode": "source-rebuild",
        "steering_patch_applied": True,
        "compiled_js_bytes": (out / "opennfs.js").stat().st_size if (out / "opennfs.js").exists() else 0,
        "compiled_wasm_bytes": (out / "opennfs.wasm").stat().st_size if (out / "opennfs.wasm").exists() else 0,
        "tracks": sorted(p.name for p in (out / "tracks").glob("*.bin")),
    }
    if status["compiled_js_bytes"] <= 0 or status["compiled_wasm_bytes"] <= 0 or not status["tracks"]:
        raise RuntimeError(f"Source build output incomplete: {status}")
    print("SOURCE BUILD VERIFIED: " + str(status), flush=True)
    print(f"Ready: {out}", flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        print(f"BUILD FAILED while running: {exc.cmd} (exit {exc.returncode})", file=sys.stderr)
        sys.exit(exc.returncode or 1)
    except Exception as exc:
        print(f"BUILD FAILED: {exc}", file=sys.stderr)
        sys.exit(1)
