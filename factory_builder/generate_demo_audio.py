#!/usr/bin/env python3
"""Generate an original tiny WAV sound effect for the construction smoke-test demo."""
from __future__ import annotations
import math
import wave
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "games/01_runner_classic/assets/demo_sfx.wav"

def main() -> None:
    sample_rate = 22050
    duration = 1.15
    count = int(sample_rate * duration)
    samples = []
    for i in range(count):
        t = i / sample_rate
        # A short upward synthetic game chirp with a gentle, fast-decaying envelope.
        frequency = 420.0 + 820.0 * (t / duration)
        envelope = min(1.0, t / 0.025) * math.exp(-3.0 * t / duration)
        value = (0.48 * math.sin(2.0 * math.pi * frequency * t)
                 + 0.17 * math.sin(2.0 * math.pi * (frequency * 1.49) * t))
        sample = max(-1.0, min(1.0, value * envelope))
        samples.append(struct.pack("<h", int(sample * 32767)))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(b"".join(samples))
    print(f"Generated procedural SFX: {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)")

if __name__ == "__main__":
    main()
