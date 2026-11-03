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

# Subtle OpenGL-style normal and roughness maps give the wood grain real light response.
wood_height = (
    np.sin(x * 0.085 + np.sin(y * 0.018) * 2.7) * 0.42
    + np.sin(x * 0.027 + y * 0.011) * 0.18
    + np.sin(x * 0.41 + np.sin(y * 0.09)) * 0.05
    + rng.normal(0.0, 0.025, (SIZE, SIZE))
)
for cx, cy, rx, ry in ((125, 140, 22, 10), (385, 350, 31, 13), (270, 65, 17, 8)):
    d = np.sqrt(((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2)
    wood_height += np.sin(d * 8.5) * np.exp(-d * 0.85) * 0.12
dh_y, dh_x = np.gradient(wood_height)
normal_x = -dh_x * 2.8
normal_y = -dh_y * 2.8
normal_z = np.ones_like(normal_x)
normal_length = np.sqrt(normal_x * normal_x + normal_y * normal_y + normal_z * normal_z)
wood_normal = np.stack((
    normal_x / normal_length * 0.5 + 0.5,
    normal_y / normal_length * 0.5 + 0.5,
    normal_z / normal_length * 0.5 + 0.5,
), axis=2)
Image.fromarray(np.uint8(np.clip(wood_normal * 255, 0, 255)), "RGB").save(TEXTURES / "wood_oak_normal.png", optimize=True)
wood_roughness = np.clip(0.76 + (np.sin(x * 0.12 + y * 0.008) * 0.035) + rng.normal(0, 0.018, (SIZE, SIZE)), 0.62, 0.91)
Image.fromarray(np.uint8(wood_roughness * 255), "L").save(TEXTURES / "wood_oak_roughness.png", optimize=True)

# A lighter maple surface keeps the puzzle visually separated from its table.
table_grain = np.sin(x * 0.06 + np.sin(y * 0.012) * 2.0) * 5.0 + np.sin(x * 0.018 + y * 0.01) * 2.5
table_noise = rng.normal(0, 1.7, (SIZE, SIZE))
table_base = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for channel, value in enumerate((207, 178, 139)):
    table_base[:, :, channel] = value + table_grain + table_noise
Image.fromarray(np.uint8(np.clip(table_base, 0, 255)), "RGB").save(TEXTURES / "maple_table.png", optimize=True)

steel_noise = rng.normal(0, 2.0, (SIZE, SIZE)) + np.sin(y * 0.9) * 1.7
steel = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
for c, value in enumerate((181, 195, 207)):
    steel[:, :, c] = value + steel_noise
Image.fromarray(np.uint8(np.clip(steel, 0, 255)), "RGB").save(TEXTURES / "brushed_steel.png", optimize=True)
steel_height = np.sin(y * 0.9) * 0.22 + rng.normal(0.0, 0.015, (SIZE, SIZE))
steel_dy, steel_dx = np.gradient(steel_height)
steel_nx = -steel_dx * 3.5
steel_ny = -steel_dy * 3.5
steel_nz = np.ones_like(steel_nx)
steel_len = np.sqrt(steel_nx * steel_nx + steel_ny * steel_ny + steel_nz * steel_nz)
steel_normal = np.stack((steel_nx / steel_len * 0.5 + 0.5, steel_ny / steel_len * 0.5 + 0.5, steel_nz / steel_len * 0.5 + 0.5), axis=2)
Image.fromarray(np.uint8(np.clip(steel_normal * 255, 0, 255)), "RGB").save(TEXTURES / "brushed_steel_normal.png", optimize=True)

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
print("Generated original wood/table/steel PBR maps, launcher icons and original SFX files.")
