"""Construit les sprites du personnage de l'appli (assets/sprites/) à partir
des images SpriteCook brutes de tool/sprites/raw/.

    python3 tool/sprites/build.py

Sorties : corps (peau marquée par l'alpha 254), coiffures et barbes (couleur
clé, recolorées dans l'appli), tenues par gabarit (peau nue percée), armes
recadrées et assets/sprites/sprites.json (repères de pose).
"""

from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from layers import (CANVAS_H, CANVAS_W, SKIN_ALPHA, best_skin,  # noqa: E402
                    key_layer, load, neck_row, outfit_layer, piece_layer, recolor, save)

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")

RACES = ["human", "elf", "high_elf", "orc", "dwarf", "gnome", "goblin", "demon", "minotaur", "undead"]
# Nom des fichiers bruts (le haut-elfe s'appelle « highelf »).
RAW_RACE = {"high_elf": "highelf"}
# Gabarit de tenue de chaque corps (5 modèles générés).
GABARIT = {
    "male": {"human": "mm", "elf": "mm", "high_elf": "mm", "undead": "mm", "demon": "mm",
             "orc": "large", "minotaur": "large", "dwarf": "stocky", "gnome": "small", "goblin": "small"},
    "female": {"human": "mf", "elf": "mf", "high_elf": "mf", "undead": "mf", "demon": "mf",
               "orc": "mf", "minotaur": "large", "dwarf": "stocky", "gnome": "small", "goblin": "small"},
}
# Point de prise des armes (fraction de la hauteur depuis le haut).
GRIP = {"sword": 0.86, "dagger": 0.8, "scimitar": 0.86, "axe": 0.72, "mace": 0.74,
        "hammer": 0.74, "staff": 0.62, "halberd": 0.6, "bow": 0.5, "rifle": 0.62,
        "spear": 0.6, "wand": 0.78, "scythe": 0.6}


# Coiffures par sexe et barbes (raw/hair_mNN, raw/hair_fNN, raw/beard_NN).
HAIR_COUNT = 14
BEARD_COUNT = 10
# Races à cornes : les cornes passent devant la coiffure.
HORNED = {"demon", "minotaur"}
# Alpha des pixels d'un corps dessinés devant la coiffure (cornes).
FRONT_ALPHA = 253


def horns(a: np.ndarray, skin: np.ndarray, skull: tuple, neck: int) -> np.ndarray:
    """Cornes : pixels du corps au-dessus du cou, hors peau, qui dépassent
    du crâne sur les côtés."""
    x0, _, x1 = skull
    yy, xx = np.mgrid[0: a.shape[0], 0: a.shape[1]]
    out = (a[..., 3] > 0) & ~skin & (yy < neck)
    return out & ((xx < x0 - 1) | (xx > x1 + 1))


def neck_of(heads: dict, name: str, a: np.ndarray) -> int:
    """Ligne du menton : imposée dans heads.json, sinon la plus étroite."""
    return heads["necks"].get(name) or neck_row(a, tuple(heads[name]))


# Demi-largeur maximale de la tête (en demi-crânes) pour les races aux
# grandes oreilles : la barbe épouse la mâchoire, pas les oreilles.
PROFILE_LIMIT = {"goblin": 0.85}


def profile(a: np.ndarray, skull: tuple, neck: int, limit: float = 1.15) -> list[float]:
    """Demi-largeur de la tête, de la ligne du sommet du crâne au menton :
    segment opaque qui contient l'axe du visage, borné à [limit] demi-crâne
    (oreilles et cornes écartées). Sert à épouser la tête (coiffures, barbes)."""
    x0, t, x1 = skull
    cx, half = (x0 + x1) / 2, (x1 - x0) / 2
    al = a[..., 3] > 0
    out = []
    for y in range(int(t), neck + 1):
        row, c = al[y], int(cx)
        if not row[c]:
            out.append(0.0)
            continue
        l = r = c
        while l > 0 and row[l - 1]:
            l -= 1
        while r < len(row) - 1 and row[r + 1]:
            r += 1
        out.append(round(min(max(cx - l, r + 1 - cx), limit * half), 1))
    return out


def raw(name: str) -> str:
    return os.path.join(RAW, name + ".png")


def body_name(race: str, sex: str) -> str:
    return f"{RAW_RACE.get(race, race)}_{sex}"


def span(a: np.ndarray, neck: int) -> dict:
    """Sommet, pieds, axe et largeur du torse (épaules aux hanches, bras compris)."""
    al = a[..., 3] > 0
    ys = np.where(al.any(axis=1))[0]
    xs = np.where(al.any(axis=0))[0]
    feet = int(ys[-1])
    rows = al[neck + int(0.15 * (feet - neck)): neck + int(0.35 * (feet - neck))]
    torso = float(np.median([np.nonzero(r)[0][-1] - np.nonzero(r)[0][0] for r in rows if r.any()]))
    return {"top": int(ys[0]), "feet": feet, "cx": round(float(xs[0] + xs[-1]) / 2, 1),
            "torso": torso}


def hand(a: np.ndarray, skin: np.ndarray, sp: dict) -> list[float]:
    """Main droite du personnage (à gauche de l'image) : peau la plus basse
    du côté gauche, entre 45 et 75 % de la hauteur."""
    h = sp["feet"] - sp["top"]
    band = np.zeros_like(skin)
    band[sp["top"] + int(0.42 * h): sp["top"] + int(0.78 * h), : int(sp["cx"])] = True
    m = skin & band
    ys, xs = np.nonzero(m)
    if len(ys) == 0:
        return [sp["cx"] - 20, sp["top"] + 0.6 * h]
    low = ys >= np.percentile(ys, 60)
    return [round(float(xs[low].mean()), 1), round(float(ys[low].mean()), 1)]


def main() -> None:
    heads = json.load(open(os.path.join(HERE, "heads.json")))
    outfits = json.load(open(os.path.join(HERE, "outfits.json")))
    for sub in ("bodies", "hair", "beards", "outfits", "weapons"):
        os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    meta: dict = {"canvas": [CANVAS_W, CANVAS_H], "skinAlpha": SKIN_ALPHA,
                  "frontAlpha": FRONT_ALPHA,
                  "bodies": {}, "templates": {}, "hairSources": {}, "weapons": {}}

    # Corps.
    for race in RACES:
        for sex in ("male", "female"):
            name = body_name(race, sex)
            a = load(raw(name))
            skull = tuple(heads[name])
            neck = neck_of(heads, name, a)
            skin, _ = best_skin(a, skull, neck, heads["arms"].get(name))
            out = a.copy()
            out[skin, 3] = SKIN_ALPHA
            if race in HORNED:
                out[horns(a, skin, skull, neck), 3] = FRONT_ALPHA
            save(out, os.path.join(OUT, "bodies", f"{race}_{sex}.png"))
            sp = span(a, neck)
            meta["bodies"][f"{race}_{sex}"] = {
                "gabarit": GABARIT[sex][race], "skull": list(skull),
                "brow": heads["brows"][name], "neck": neck,
                "profile": profile(a, skull, neck, PROFILE_LIMIT.get(race, 1.0 if race in HORNED else 1.15)), **sp, "hand": hand(a, skin, sp),
                "skinRef": [int(c) for c in np.median(a[skin][:, :3], axis=0)],
            }

    # Coiffures et barbes : couleur clé, sur le crâne de leur corps source.
    hm, hf = load(raw("human_male")), load(raw("human_female"))

    def source(name: str) -> dict:
        a = load(raw(name))
        neck = neck_of(heads, name, a)
        return {"skull": heads[name], "brow": heads["brows"][name], "neck": neck,
                "profile": profile(a, tuple(heads[name]), neck)}

    meta["hairSources"] = {"male": source("human_male"), "female": source("human_female"),
                           "beard": source("human_male")}
    for i in range(1, HAIR_COUNT + 1):
        save(key_layer(hm, load(raw(f"hair_m{i:02d}")), tol=0.09, min_sat=0.25), os.path.join(OUT, "hair", f"m{i:02d}.png"))
        save(key_layer(hf, load(raw(f"hair_f{i:02d}")), tol=0.09, min_sat=0.25), os.path.join(OUT, "hair", f"f{i:02d}.png"))
    for i in range(1, BEARD_COUNT + 1):
        lay = key_layer(hm, load(raw(f"beard_{i:02d}")), hue=0.952, tol=0.065, min_sat=0.15)
        save(lay, os.path.join(OUT, "beards", f"b{i:02d}.png"))

    # Tenues par gabarit.
    templates_raw = {}
    for g, tpl in outfits["templates"].items():
        b = load(raw(tpl["base"]))
        n = neck_of(heads, tpl["base"], b)
        templates_raw[g] = {"neck": n, **span(b, n)}
    for body in meta["bodies"].values():
        def distortion(g):
            t = templates_raw[g]
            sy = (body["feet"] - body["neck"]) / (t["feet"] - t["neck"])
            sx = body["torso"] / t["torso"]
            return abs(np.log(sy)) + abs(np.log(sx))
        body["gabarit"] = min(templates_raw, key=distortion)
    for g, tpl in outfits["templates"].items():
        b = load(raw(tpl["base"]))
        x0, t, x1 = heads[tpl["base"]]
        neck = neck_of(heads, tpl["base"], b)
        sample = (int((x0 + x1) / 2), int(t + 0.62 * (x1 - x0)))
        tskin, _ = best_skin(b, tuple(heads[tpl["base"]]), neck, heads["arms"].get(tpl["base"]))
        sp = span(b, neck)
        meta["templates"][g] = {"neck": neck, **sp, "hand": hand(b, tskin, sp),
                                "skinRef": [int(c) for c in np.median(b[tskin][:, :3], axis=0)]}
        for oid in outfits["outfits"]:
            lay = outfit_layer(b, load(raw(f"armor_{oid}_{g}")), neck, sample, t,
                               heads["arms"].get(tpl["base"]))
            save(lay, os.path.join(OUT, "outfits", f"{oid}_{g}.png"))

    # Pièces séparées (haut, bas, chaussures, gants) par gabarit.
    pieces = json.load(open(os.path.join(HERE, "pieces.json")))
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    meta["pieces"] = {}
    for g, tpl in outfits["templates"].items():
        b = load(raw(tpl["base"]))
        x0, t, x1 = heads[tpl["base"]]
        neck = neck_of(heads, tpl["base"], b)
        feet = int(np.where((b[..., 3] > 0).any(axis=1))[0][-1])
        sample = (int((x0 + x1) / 2), int(t + 0.62 * (x1 - x0)))
        for pid, (slot, _) in pieces["pieces"].items():
            lay = piece_layer(b, load(raw(f"piece_{pid}_{g}")), slot, neck, feet, sample, t,
                              heads["arms"].get(tpl["base"]))
            save(lay, os.path.join(OUT, "pieces", f"{pid}_{g}.png"))
            meta["pieces"][pid] = slot

    # Armes recadrées, prise de la main.
    for f in sorted(os.listdir(RAW)):
        if not f.startswith("weapon_"):
            continue
        wid = f[len("weapon_"):-4]
        im = Image.open(os.path.join(RAW, f)).convert("RGBA")
        im = im.crop(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox())
        # Hauteur commune : 96 pixels d'art (proportions gardées).
        s = 96 / im.height
        im = im.resize((max(1, round(im.width * s)), 96), Image.NEAREST)
        a = np.asarray(im).copy()
        a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
        Image.fromarray(a, "RGBA").save(os.path.join(OUT, "weapons", f"{wid}.png"), optimize=True)
        kind = wid.split("_")[0]
        meta["weapons"][wid] = {"size": [im.width, im.height], "grip": GRIP[kind]}

    # Vignettes de la boutique : tenue sur le gabarit moyen, arme, coiffure.
    icons = os.path.join(OUT, "icons")
    os.makedirs(icons, exist_ok=True)

    def crop_save(img: Image.Image, name: str) -> None:
        box = img.getchannel("A").getbbox()
        img.crop(box).save(os.path.join(icons, name + ".png"), optimize=True)

    for oid in outfits["outfits"]:
        crop_save(Image.open(os.path.join(OUT, "outfits", f"{oid}_mm.png")).convert("RGBA"), oid)
    for pid in meta["pieces"]:
        crop_save(Image.open(os.path.join(OUT, "pieces", f"{pid}_mm.png")).convert("RGBA"), pid)
    for wid in meta["weapons"]:
        crop_save(Image.open(os.path.join(OUT, "weapons", f"{wid}.png")).convert("RGBA"), wid)
    for i in range(1, HAIR_COUNT + 1):
        lay = load(os.path.join(OUT, "hair", f"f{i:02d}.png"))
        crop_save(Image.fromarray(recolor(lay, (106, 64, 38)).clip(0, 255).astype(np.uint8), "RGBA"),
                  f"hairstyle_{i:02d}")

    json.dump(meta, open(os.path.join(OUT, "sprites.json"), "w"), indent=1)
    print("ok", len(meta["bodies"]), "corps,", len(outfits["outfits"]), "tenues,", len(meta["weapons"]), "armes")


if __name__ == "__main__":
    main()
