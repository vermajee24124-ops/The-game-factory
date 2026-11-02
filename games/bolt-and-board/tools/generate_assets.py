#!/usr/bin/env python3
"""Generate original game textures and sound effects (no external assets)."""
from pathlib import Path
import math, random, struct, wave
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TEXTURES = ROOT / "assets" / "textures"
AUDIO = ROOT / "assets" / "audio"
TEXTURES.mkdir(parents=True, exist_ok=True)
AUDIO.mkdir(parents=True, exist_ok=True)
SIZE = 512
rng = np.random.default_rng(24)
y, x = np.mgrid[0:SIZE, 0:SIZE]
noise = rng.normal(0, 2.8, (SIZE, SIZE))
grain = np.sin(x * 0.105 + np.sin(y * 0.025) * 2.4) * 7
layer = np.sin(x * 0.035 + y * 0.012) * 4 + np.sin(x * 0.42 + np.sin(y * 0.11)) * 1.8
base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for c, value in enumerate((157, 101, 58)):
    base[:, :, c] = value
for c, scale in enumerate((1.0, 0.83, 0.62)):
    base[:, :, c] += grain * scale + layer * scale + noise * scale
for cx, cy, rx, ry in ((125, 140, 22, 10), (385, 350, 31, 13), (270, 65, 17, 8)):
    d = np.sqrt(((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2)
    knot = np.sin(d * 9) * np.exp(-d * 0.7) * 8
    for c, scale in enumerate((1.0, 0.8, 0.58)):
        base[:, :, c] += knot * scale
Image.fromarray(np.uint8(np.clip(base, 0, 255)), "RGB").save(TEXTURES / "wood_oak.png", optimize=True)

steel_noise = rng.normal(0, 2.0, (SIZE, SIZE)) + np.sin(y * 0.9) * 1.7
steel = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for c, value in enumerate((181, 195, 207)):
    steel[:, :, c] = value + steel_noise
Image.fromarray(np.uint8(np.clip(steel, 0, 255)), "RGB").save(TEXTURES / "brushed_steel.png", optimize=True)

surface_noise = rng.normal(0, 2.4, (SIZE, SIZE)) + np.sin(x * 0.25) * 0.5
surface = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for c, value in enumerate((32, 49, 65)):
    surface[:, :, c] = value + surface_noise
Image.fromarray(np.uint8(np.clip(surface, 0, 255)), "RGB").save(TEXTURES / "dark_surface.png", optimize=True)

def tone(name: str, frequencies: list[float], duration: float, decay: float, volume: float, noise: float = 0.0) -> None:
    rate = 22050
    count = int(rate * duration)
    random.seed(name)
    pcm = bytearray()
    for i in range(count):
        t = i / rate
        envelope = math.exp(-decay * t)
        value = sum(math.sin(2 * math.pi * f * t + j * 0.3) / (j + 1) for j, f in enumerate(frequencies))
        value *= volume * envelope * 2 / max(1, len(frequencies))
        if noise:
            value += (random.random() * 2 - 1) * noise * envelope
        value = max(-0.98, min(0.98, value))
        pcm.extend(struct.pack("<h", int(value * 32767)))
    with wave.open(str(AUDIO / f"{name}.wav"), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(rate)
        out.writeframes(pcm)

tone("ui_click", [620, 880], 0.085, 15, 0.16)
tone("screw_remove", [260, 390, 520], 0.24, 7, 0.20, 0.035)
tone("board_clear", [110, 165, 220], 0.45, 4, 0.28, 0.025)
tone("level_complete", [523, 659, 784, 1046], 0.72, 1.8, 0.18)
print("Generated 3 original textures and 4 original SFX files.")
