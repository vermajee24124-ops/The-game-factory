#!/usr/bin/env python3
"""Generate original game textures and sound effects (no external assets)."""
from pathlib import Path
import math, random, struct, wave
import numpy as np
from PIL import Image, ImageDraw

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

# Fine surface maps make the wood respond to light instead of looking like a flat colored box.
wood_height = (base[:, :, 0] * 0.55 + base[:, :, 1] * 0.30 + base[:, :, 2] * 0.15)
wood_height += grain * 1.8 + layer * 1.2
gy, gx = np.gradient(wood_height.astype(np.float32))
normal = np.stack((-gx * 2.2, -gy * 2.2, np.ones_like(gx) * 42.0), axis=-1)
normal /= np.maximum(np.linalg.norm(normal, axis=-1, keepdims=True), 1e-6)
normal_rgb = np.uint8(np.clip((normal * 0.5 + 0.5) * 255, 0, 255))
Image.fromarray(normal_rgb, "RGB").save(TEXTURES / "wood_oak_normal.png", optimize=True)
wood_roughness = np.uint8(np.clip(218 + np.sin(x * 0.07 + y * 0.018) * 8 + noise * 1.3, 175, 245))
Image.fromarray(wood_roughness, "L").save(TEXTURES / "wood_oak_roughness.png", optimize=True)

steel_noise = rng.normal(0, 2.0, (SIZE, SIZE)) + np.sin(y * 0.9) * 1.7
steel = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for c, value in enumerate((181, 195, 207)):
    steel[:, :, c] = value + steel_noise
Image.fromarray(np.uint8(np.clip(steel, 0, 255)), "RGB").save(TEXTURES / "brushed_steel.png", optimize=True)

steel_height = (np.sin(y * 0.9) * 1.7 + rng.normal(0, 2.0, (SIZE, SIZE))).astype(np.float32)
sgy, sgx = np.gradient(steel_height)
steel_normal = np.stack((-sgx * 4.0, -sgy * 4.0, np.ones_like(sgx) * 48.0), axis=-1)
steel_normal /= np.maximum(np.linalg.norm(steel_normal, axis=-1, keepdims=True), 1e-6)
steel_normal_rgb = np.uint8(np.clip((steel_normal * 0.5 + 0.5) * 255, 0, 255))
Image.fromarray(steel_normal_rgb, "RGB").save(TEXTURES / "brushed_steel_normal.png", optimize=True)
Image.fromarray(np.uint8(np.clip(72 + np.abs(np.sin(y * 0.9)) * 20 + rng.normal(0, 3, (SIZE, SIZE)), 45, 125)), "L").save(TEXTURES / "brushed_steel_roughness.png", optimize=True)

surface_noise = rng.normal(0, 2.4, (SIZE, SIZE)) + np.sin(x * 0.25) * 0.5
surface = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for c, value in enumerate((32, 49, 65)):
    surface[:, :, c] = value + surface_noise
Image.fromarray(np.uint8(np.clip(surface, 0, 255)), "RGB").save(TEXTURES / "dark_surface.png", optimize=True)

def make_icon(size: int, transparent: bool = False) -> Image.Image:
    scale = size / 512.0
    bg = (0, 0, 0, 0) if transparent else (23, 35, 51, 255)
    image = Image.new("RGBA", (size, size), bg)
    draw = ImageDraw.Draw(image)

    def pts(values):
        return [(int(x * scale), int(y * scale)) for x, y in values]

    if not transparent:
        draw.rounded_rectangle((int(12 * scale), int(12 * scale), int(500 * scale), int(500 * scale)),
                               radius=int(104 * scale), fill=(23, 35, 51, 255),
                               outline=(91, 115, 136, 255), width=max(1, int(5 * scale)))

    # Three original wooden planks, drawn in a simple isometric style.
    planks = [
        ([(76, 176), (405, 176), (448, 240), (119, 240)], [(119, 240), (448, 240), (448, 276), (119, 276)], (183, 121, 68, 255), (112, 68, 40, 255)),
        ([(76, 126), (405, 126), (448, 190), (119, 190)], [(119, 190), (448, 190), (448, 226), (119, 226)], (201, 143, 83, 255), (126, 78, 44, 255)),
        ([(76, 76), (405, 76), (448, 140), (119, 140)], [(119, 140), (448, 140), (448, 176), (119, 176)], (219, 162, 99, 255), (143, 88, 48, 255)),
    ]
    for top, side, top_color, side_color in planks:
        draw.polygon(pts(side), fill=side_color)
        draw.polygon(pts(top), fill=top_color, outline=(91, 57, 34, 255))
        draw.line(pts([(95, top[0][1] + 12), (390, top[0][1] + 12)]),
                 fill=(237, 190, 132, 180), width=max(1, int(5 * scale)))

    # Four steel screw heads on the top plank.
    for cx, cy in [(145, 97), (379, 97), (165, 140), (360, 140)]:
        r = 17
        box = (int((cx-r)*scale), int((cy-r)*scale), int((cx+r)*scale), int((cy+r)*scale))
        draw.ellipse(box, fill=(46, 61, 74, 255), outline=(226, 235, 239, 255), width=max(1, int(5 * scale)))
        inner = (int((cx-11)*scale), int((cy-11)*scale), int((cx+11)*scale), int((cy+11)*scale))
        draw.ellipse(inner, fill=(194, 207, 216, 255), outline=(87, 104, 119, 255), width=max(1, int(2 * scale)))
        draw.line(pts([(cx-8, cy), (cx+8, cy)]), fill=(44, 56, 68, 255), width=max(2, int(5 * scale)))
        draw.line(pts([(cx, cy-8), (cx, cy+8)]), fill=(44, 56, 68, 255), width=max(2, int(5 * scale)))
    return image


ICONS = ROOT / "assets" / "icons"
ICONS.mkdir(parents=True, exist_ok=True)
make_icon(192, False).save(ICONS / "main_192x192.png", optimize=True)
make_icon(432, True).save(ICONS / "adaptive_foreground_432x432.png", optimize=True)
Image.new("RGBA", (432, 432), (23, 35, 51, 255)).save(ICONS / "adaptive_background_432x432.png", optimize=True)


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
tone("match_clear", [740, 880, 1108, 1480], 0.32, 6.0, 0.19)
print("Generated original wood/steel PBR texture sets, 3 Android launcher icons and 5 original SFX files.")
