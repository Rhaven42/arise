"""Aperçu d'assemblage du personnage (même logique que l'appli,
lib/features/avatar/domain/sprite_layout.dart) : sert à vérifier les calques.

    python3 tool/sprites/preview.py sortie.png
"""

from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "..", "..", "assets", "sprites")
META = json.load(open(os.path.join(ASSETS, "sprites.json")))
WEAPON_LENGTH = {"sword": 0.5, "dagger": 0.28, "scimitar": 0.46, "axe": 0.5, "mace": 0.42,
                 "hammer": 0.48, "staff": 0.8, "halberd": 0.9}


def img(path: str) -> np.ndarray:
    return np.asarray(Image.open(os.path.join(ASSETS, path)).convert("RGBA")).astype(float)


def lum(c: np.ndarray) -> np.ndarray:
    return 0.299 * c[..., 0] + 0.587 * c[..., 1] + 0.114 * c[..., 2]


def tint(px: np.ndarray, ref: float, color: tuple[int, int, int]) -> np.ndarray:
    """Teinte par carte de dégradé (formule partagée avec l'appli)."""
    k = np.clip(lum(px) / max(ref, 1), 0, 2.2)[..., None]
    c = np.array(color, float)
    return np.where(k <= 1, c * k, c + (255 - c) * (k - 1) * 0.55)


def place(canvas: np.ndarray, layer: np.ndarray, scale: float, ox: float, oy: float,
          scale_x: float | None = None) -> None:
    """Pose [layer] mis à l'échelle (plus proche voisin) avec son origine en (ox, oy)."""
    sx = scale if scale_x is None else scale_x
    h, w = layer.shape[:2]
    H, W = canvas.shape[:2]
    nh, nw = max(1, round(h * scale)), max(1, round(w * sx))
    ys = (np.arange(nh) / scale).astype(int).clip(0, h - 1)
    xs = (np.arange(nw) / sx).astype(int).clip(0, w - 1)
    src = layer[ys][:, xs]
    y0, x0 = round(oy), round(ox)
    for j in range(nh):
        y = y0 + j
        if not 0 <= y < H:
            continue
        row = src[j]
        m = row[:, 3] > 0
        for i in np.nonzero(m)[0]:
            x = x0 + i
            if 0 <= x < W:
                canvas[y, x] = row[i]


def compose(race, sex, skin=None, hair=None, hair_color=(70, 45, 30), beard=None,
            beard_color=None, outfit=None, weapon=None) -> np.ndarray:
    key = f"{race}_{sex}"
    b = META["bodies"][key]
    body = img(f"bodies/{key}.png")
    skin_px = body[..., 3] == META["skinAlpha"]
    if skin is not None:
        body[skin_px, :3] = tint(body[skin_px, :3], lum(np.array(b["skinRef"], float)), skin)
    canvas = np.zeros_like(body)
    if outfit:
        # Tête et peau nue seulement ; la tenue remplace le reste du corps.
        keep = skin_px.copy()
        keep[: b["neck"] + 1] = body[: b["neck"] + 1, :, 3] > 0
        canvas[keep] = body[keep]
        t = META["templates"][b["gabarit"]]
        lay = img(f"outfits/{outfit}_{b['gabarit']}.png")
        s = (b["feet"] - b["neck"]) / (t["feet"] - t["neck"])
        sx = b["torso"] / t["torso"]
        place(canvas, lay, s, b["cx"] - t["cx"] * sx, b["feet"] - t["feet"] * s, sx)
        canvas[skin_px & (canvas[..., 3] == 0)] = body[skin_px & (canvas[..., 3] == 0)]
    else:
        canvas[body[..., 3] > 0] = body[body[..., 3] > 0]
    canvas[..., 3] = np.where(canvas[..., 3] > 0, 255, 0)
    for layer_path, src_key, color in ((f"beards/{beard}.png" if beard else None, "beard", beard_color or hair_color),
                                       (f"hair/{hair}.png" if hair else None,
                                        "male" if hair and hair[0] == "m" else "female", hair_color)):
        if not layer_path:
            continue
        lay = img(layer_path)
        m = lay[..., 3] > 0
        lay[m, :3] = tint(lay[m, :3], float(np.median(lum(lay[m, :3]))), color)
        sx0, st, sx1 = META["hairSources"][src_key]
        dx0, dt, dx1 = b["skull"]
        s = (dx1 - dx0) / (sx1 - sx0)
        place(canvas, lay, s, (dx0 + dx1) / 2 - (sx0 + sx1) / 2 * s, dt - st * s)
    if weapon:
        w = META["weapons"][weapon]
        lay = img(f"weapons/{weapon}.png")
        length = WEAPON_LENGTH[weapon.split("_")[0]] * (b["feet"] - b["top"])
        s = length / w["size"][1]
        hx, hy = b["hand"]
        place(canvas, lay, s, hx - w["size"][0] * s / 2, hy - w["grip"] * w["size"][1] * s)
    return canvas


if __name__ == "__main__":
    import random
    random.seed(4)
    races = ["human", "elf", "high_elf", "orc", "dwarf", "gnome", "goblin", "demon", "minotaur", "undead"]
    outfits = [None] + list(json.load(open(os.path.join(HERE, "outfits.json")))["outfits"])
    weapons = [None] + list(META["weapons"])
    colors = [(70, 45, 30), (230, 200, 120), (25, 25, 30), (170, 60, 30), (210, 210, 220), (60, 90, 170), (120, 40, 140)]
    tiles = []
    for race in races:
        for sex in ("male", "female"):
            hair = random.choice([None] + [f"{sex[0]}{i:02d}" for i in range(1, 11)])
            tiles.append(compose(race, sex, hair=hair, hair_color=random.choice(colors),
                                 beard=random.choice([None, "b01", "b02", "b04"]) if sex == "male" else None,
                                 outfit=random.choice(outfits), weapon=random.choice(weapons)))
    rows = [np.concatenate(tiles[i: i + 10], 1) for i in (0, 10)]
    im = np.concatenate(rows, 0)
    bg = np.zeros_like(im)
    bg[..., :3] = (60, 60, 70)
    bg[..., 3] = 255
    m = im[..., 3] > 0
    bg[m] = im[m]
    Image.fromarray(bg.astype(np.uint8)).resize((im.shape[1] * 2, im.shape[0] * 2), Image.NEAREST).save(sys.argv[1])
