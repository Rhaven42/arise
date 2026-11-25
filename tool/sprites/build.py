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
from scipy import ndimage
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from layers import (CANVAS_H, CANVAS_W, SKIN_ALPHA, best_skin,  # noqa: E402
                    fill_crown, key_layer, load, race_beard_layer, neck_row, outfit_layer, recolor, save)

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
# Races dont chaque barbe est générée sur leur propre visage (homme).
RACE_BEARDS = ["dwarf", "gnome", "goblin", "minotaur", "orc"]
# Barbes recalées sur le visage redessiné (le modèle grossit ou décale
# souvent la tête), sauf pour le gnome : son grand visage de dessin animé
# trompe le recalage, le recalage sur le corps y est plus juste.
BODY_ALIGNED_BEARDS = {"gnome"}
# Vignettes : hauteur maximale de l'image générée.
ICON_MAX_H = 224
# Repères des pieds et des mains (fractions de la hauteur du corps) : bande
# des pieds, bande des mains au-dessus / au-dessous de la paume, et écart
# horizontal maximal à la main.
FOOT_BAND = 0.075
HAND_BAND = (0.05, 0.06)
HAND_REACH = 0.07



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
PROFILE_LIMIT = {"goblin": 0.85, "demon": 0.85}


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


def chin_row(skin: np.ndarray, neck: int, skull: tuple) -> int:
    """Bas réel du menton : premier pixel hors peau (contour de la mâchoire)
    sur l'axe du visage, à partir de la ligne du cou. Sous cette ligne, une
    tenue remplace le corps."""
    cx = int((skull[0] + skull[2]) / 2)
    for y in range(neck, min(neck + 12, skin.shape[0])):
        if not skin[y, cx]:
            return y
    return neck


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
    band[sp["top"] + int(0.42 * h): sp["top"] + int(0.80 * h), : int(sp["cx"])] = True
    m = skin & band
    ys, xs = np.nonzero(m)
    if len(ys) == 0:
        return [sp["cx"] - 20, sp["top"] + 0.6 * h]
    # Paume : le creux du poing, sous le poignet et au-dessus du bout des
    # doigts (le poing fait environ 7 % de la hauteur du corps).
    tip = ys.max()
    palm = (ys >= tip - 0.065 * h) & (ys <= tip - 0.015 * h)
    if not palm.any():
        palm = ys >= np.percentile(ys, 80)
    return [round(float(xs[palm].mean()), 1), round(float(ys[palm].mean()), 1)]


def extremity_boxes(a: np.ndarray, skin: np.ndarray, sp: dict, hand_pt: list[float]) -> dict:
    """Boîtes des pieds (bande du bas, tout ce qui est opaque : sabots
    compris) et des mains (peau autour de la main et de son symétrique),
    côté gauche puis droit de l'image : bottes et gants s'y ajustent."""
    h = sp["feet"] - sp["top"]
    cx = sp["cx"]
    opaque = a[..., 3] > 0

    def box(mask: np.ndarray) -> list[int]:
        ys, xs = np.nonzero(mask)
        if len(ys) == 0:
            return [0, 0, 0, 0]
        return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]

    feet = np.zeros_like(opaque)
    feet[int(sp["feet"] - FOOT_BAND * h): sp["feet"] + 1] = True
    hands = np.zeros_like(opaque)
    hy = hand_pt[1]
    hands[int(hy - HAND_BAND[0] * h): int(hy + HAND_BAND[1] * h) + 1] = True
    cols = np.arange(a.shape[1])[None, :]
    out = {"feetBoxes": [], "handBoxes": []}
    for side in (0, 1):
        half = cols < cx if side == 0 else cols >= cx
        hx = hand_pt[0] if side == 0 else 2 * cx - hand_pt[0]
        near = np.abs(cols - hx) <= HAND_REACH * h
        out["feetBoxes"].append(box(opaque & feet & half))
        # La main seule : la plage de peau reliée qui touche la paume (pas une
        # bande voisine prise pour de la peau).
        cand = skin & hands & half & near
        parts, n = ndimage.label(cand, np.ones((3, 3)))
        if n:
            ys_, xs_ = np.nonzero(cand)
            d = (xs_ - hx) ** 2 + (ys_ - hy) ** 2
            cand = parts == parts[ys_[np.argmin(d)], xs_[np.argmin(d)]]
        out["handBoxes"].append(box(cand))
    return out


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
                "chin": chin_row(skin, neck, skull),
                "profile": profile(a, skull, neck, PROFILE_LIMIT.get(race, 1.0 if race in HORNED else 1.15)), **sp, "hand": hand(a, skin, sp),
                "skinRef": [int(c) for c in np.median(a[skin][:, :3], axis=0)],
            }
            body = meta["bodies"][f"{race}_{sex}"]
            body.update(extremity_boxes(a, skin, sp, body["hand"]))

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
        save(fill_crown(key_layer(hm, load(raw(f"hair_m{i:02d}")), tol=0.09, min_sat=0.25), hm),
             os.path.join(OUT, "hair", f"m{i:02d}.png"))
        save(fill_crown(key_layer(hf, load(raw(f"hair_f{i:02d}")), tol=0.09, min_sat=0.25), hf),
             os.path.join(OUT, "hair", f"f{i:02d}.png"))
    for i in range(1, BEARD_COUNT + 1):
        lay = race_beard_layer(hm, load(raw(f"beard_{i:02d}")))
        save(lay, os.path.join(OUT, "beards", f"b{i:02d}.png"))
    # Barbes dessinées sur le visage de chaque race trop éloignée de l'humain
    # (raw/beard_<race>_NN.png) : posées telles quelles dans l'appli.
    for race in RACE_BEARDS:
        base = load(raw(body_name(race, "male")))
        os.makedirs(os.path.join(OUT, "beards", race), exist_ok=True)
        for i in range(1, BEARD_COUNT + 1):
            lay = race_beard_layer(base, load(raw(f"beard_{race}_{i:02d}")),
                                   face=race not in BODY_ALIGNED_BEARDS)
            save(lay, os.path.join(OUT, "beards", race, f"b{i:02d}.png"))
    meta["raceBeards"] = list(RACE_BEARDS)

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
        thand = hand(b, tskin, sp)
        meta["templates"][g] = {"neck": neck, **sp, "hand": thand, **extremity_boxes(b, tskin, sp, thand),
                                "skinRef": [int(c) for c in np.median(b[tskin][:, :3], axis=0)]}
        for oid in outfits["outfits"]:
            lay = outfit_layer(b, load(raw(f"armor_{oid}_{g}")),
                               chin_row(tskin, neck, tuple(heads[tpl["base"]])), sample, t,
                               heads["arms"].get(tpl["base"]))
            save(lay, os.path.join(OUT, "outfits", f"{oid}_{g}.png"))

    # Pièces séparées (haut, bas, chaussures, gants) : retirées de l'appli le
    # 25/11/2026 (seules restent les tenues complètes) ; leurs images
    # générées restent dans raw/piece_*.

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

    # Tenues et pièces : l'image générée telle quelle (personnage entier
    # qui la porte, comme sur SpriteCook) ; une pièce est cadrée sur sa zone.
    def generated(name: str) -> Image.Image:
        im = Image.open(raw(name)).convert("RGBA")
        im = im.crop(im.getchannel("A").getbbox())
        if im.height > ICON_MAX_H:
            s = ICON_MAX_H / im.height
            im = im.resize((max(1, round(im.width * s)), ICON_MAX_H), Image.NEAREST)
        return im

    for oid in outfits["outfits"]:
        crop_save(generated(f"armor_{oid}_mm"), oid)

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
