#!/usr/bin/env python3
"""Capture and verify a real Godot demo screenshot and gameplay MP4 with audio."""
from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def run(args, timeout=30, check=True, **kwargs):
    result = subprocess.run(args, timeout=timeout, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, check=False, **kwargs)
    if check and result.returncode:
        raise RuntimeError(f"Command failed ({result.returncode}): {Path(str(args[0])).name}\n{result.stdout[-4000:]}")
    return result

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--project", default="games/01_runner_classic")
    p.add_argument("--duration", type=int, default=10)
    a = p.parse_args()
    project = (ROOT / a.project).resolve()
    if ROOT not in project.parents or not (project / "project.godot").is_file():
        raise SystemExit("Project path is missing or outside repository root.")
    godot = shutil.which("godot")
    for utility in ("Xvfb", "ffmpeg", "ffprobe", "pulseaudio", "pactl", "xdpyinfo"):
        if not shutil.which(utility):
            raise SystemExit(f"Missing required capture utility: {utility}")
    report_path = ROOT / "deliverables/qa_reports/demo-capture.json"
    video_path = ROOT / "deliverables/gameplay_clips/demo.mp4"
    screenshot_path = ROOT / "deliverables/screenshots/demo.png"
    log_path = ROOT / "deliverables/qa_reports/demo-godot.log"
    for path in (report_path, video_path, screenshot_path, log_path):
        path.parent.mkdir(parents=True, exist_ok=True)

    report = {"status": "running", "created_at": datetime.now(timezone.utc).isoformat(),
              "project": str(project.relative_to(ROOT)), "checks": {}, "limitations": []}
    xvfb = None
    game = None
    capture = None
    try:
        report["checks"]["godot_version"] = run([godot, "--version"], timeout=10).stdout.strip()
        ver = report["checks"]["godot_version"]
        if not ver.startswith("4.7.2"):
            raise RuntimeError(f"Expected pinned Godot 4.7.2 but got {ver!r}")
        import_result = run([godot, "--headless", "--path", str(project), "--editor", "--quit"], timeout=90, check=False)
        report["checks"]["headless_import_exit"] = import_result.returncode
        report["checks"]["headless_import_log_tail"] = import_result.stdout[-6000:]
        if import_result.returncode:
            raise RuntimeError("Godot headless project import returned nonzero.")
        audio_asset = project / "assets/demo_sfx.wav"
        if not audio_asset.is_file() or audio_asset.stat().st_size < 1000:
            raise RuntimeError("Original procedural demo audio asset assets/demo_sfx.wav is missing.")
        main_script = project / "scripts/main.gd"
        if not main_script.is_file():
            raise RuntimeError("Demo main script is missing.")
        source = main_script.read_text(encoding="utf-8", errors="replace")
        if "demo_sfx.wav" not in source or "AudioStreamPlayer" not in source:
            raise RuntimeError("Demo must play its procedural demo_sfx.wav through Godot AudioStreamPlayer. No synthetic FFmpeg overlay is accepted.")
        pulse = run(["pulseaudio", "--start", "--exit-idle-time=-1"], timeout=10, check=False)
        report["checks"]["pulseaudio_start"] = pulse.returncode
        load = run(["pactl", "load-module", "module-null-sink", "sink_name=game_factory_null",
                    "sink_properties=device.description=GameFactoryNullSink"], timeout=10, check=False)
        if load.returncode and "game_factory_null" not in run(["pactl", "list", "short", "sinks"], check=False).stdout:
            raise RuntimeError("Could not create PulseAudio null sink for game capture.")
        run(["pactl", "set-default-sink", "game_factory_null"], timeout=10, check=False)
        env = os.environ.copy()
        env.update({"DISPLAY": ":99", "LIBGL_ALWAYS_SOFTWARE": "1",
                    "GALLIUM_DRIVER": "llvmpipe", "ALSOFT_DRIVERS": "pulse"})
        xvfb = subprocess.Popen(["Xvfb", ":99", "-screen", "0", "1280x720x24",
                                  "-ac", "+extension", "GLX", "+render", "-noreset"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env)
        for _ in range(20):
            display = run(["xdpyinfo", "-display", ":99"], timeout=3, check=False)
            if display.returncode == 0:
                break
            time.sleep(.5)
        else:
            raise RuntimeError("Xvfb display did not become ready.")
        game = subprocess.Popen([godot, "--path", str(project), "--rendering-method", "gl_compatibility",
                                 "--rendering-driver", "opengl3"], stdout=open(log_path, "w", encoding="utf-8"),
                                stderr=subprocess.STDOUT, env=env)
        time.sleep(2)
        if game.poll() is not None:
            raise RuntimeError(f"Godot exited before visual capture; inspect {log_path.relative_to(ROOT)}.")
        capture = subprocess.Popen([
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-thread_queue_size", "1024", "-f", "x11grab", "-video_size", "1280x720",
            "-framerate", "20", "-i", ":99.0",
            "-thread_queue_size", "1024", "-f", "pulse", "-i", "game_factory_null.monitor",
            "-t", str(max(5, min(int(a.duration), 15))), "-c:v", "libx264", "-preset", "ultrafast",
            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "128k", str(video_path)
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
        _, fferr = capture.communicate(timeout=max(25, min(int(a.duration), 15) + 15))
        if capture.returncode:
            raise RuntimeError("FFmpeg capture failed: " + fferr.decode("utf-8", "replace")[-3000:])
        if not video_path.is_file() or video_path.stat().st_size < 10_000:
            raise RuntimeError("Recorded MP4 is missing or unexpectedly small.")
        probe = run(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(video_path)], timeout=15)
        metadata = json.loads(probe.stdout)
        streams = metadata.get("streams", [])
        video_streams = [s for s in streams if s.get("codec_type") == "video"]
        audio_streams = [s for s in streams if s.get("codec_type") == "audio"]
        if not video_streams or not audio_streams:
            raise RuntimeError("Recorded MP4 must contain both video and audio streams.")
        volume = run(["ffmpeg", "-hide_banner", "-i", str(video_path), "-vn", "-af", "volumedetect",
                      "-f", "null", "-"], timeout=25, check=False)
        volume_text = volume.stdout
        peaks = []
        for line in volume_text.splitlines():
            if "max_volume:" in line:
                try: peaks.append(float(line.split("max_volume:", 1)[1].strip().split()[0].replace("dB", "")))
                except (ValueError, IndexError): pass
        if not peaks or max(peaks) <= -55:
            raise RuntimeError("Recorded audio appears silent (peak <= -55 dB or unavailable). Refusing to treat it as gameplay audio.")
        shot = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(video_path),
                    "-frames:v", "1", str(screenshot_path)], timeout=15, check=False)
        if shot.returncode or not screenshot_path.is_file() or screenshot_path.stat().st_size < 1000:
            raise RuntimeError("Could not extract a valid screenshot from the captured gameplay.")
        duration = float(metadata.get("format", {}).get("duration", 0))
        report["checks"].update({"headless_import": "passed", "godot_window_started": True,
                                  "video_stream": video_streams[0].get("codec_name"),
                                  "audio_stream": audio_streams[0].get("codec_name"),
                                  "duration_seconds": duration, "audio_peak_db": max(peaks),
                                  "video_bytes": video_path.stat().st_size,
                                  "screenshot_bytes": screenshot_path.stat().st_size,
                                  "screenshot": str(screenshot_path.relative_to(ROOT)),
                                  "video": str(video_path.relative_to(ROOT)),
                                  "godot_log": str(log_path.relative_to(ROOT))})
        report["status"] = "passed"
        return_code = 0
    except Exception as exc:
        report["status"] = "failed"
        report["error"] = f"{type(exc).__name__}: {exc}"
        return_code = 1
    finally:
        if capture is not None and capture.poll() is None:
            capture.terminate()
            try: capture.wait(timeout=4)
            except subprocess.TimeoutExpired: capture.kill()
        if game is not None and game.poll() is None:
            game.terminate()
            try: game.wait(timeout=5)
            except subprocess.TimeoutExpired: game.kill()
        if xvfb is not None and xvfb.poll() is None:
            xvfb.terminate()
            try: xvfb.wait(timeout=4)
            except subprocess.TimeoutExpired: xvfb.kill()
        report["completed_at"] = datetime.now(timezone.utc).isoformat()
        report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(json.dumps(report, indent=2, ensure_ascii=False))
    return return_code

if __name__ == "__main__":
    raise SystemExit(main())
