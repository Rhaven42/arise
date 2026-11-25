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
HAND_RX, HAND_RY = 0.026, 0.036
POMMEL_ABOVE = 0.035  # main devant la poignée (comme l'appli)
LOWERED = {"sword", "dagger", "scimitar", "axe", "mace", "hammer", "wand"}
FACE_INNER = 0.6  # centre du visage sans mèche (comme l'appli)
NECK_BAND = 0.08  # bande du cou gardée sous le menton (comme l'appli)
WEAPON_LENGTH = {"sword": 0.5, "dagger": 0.28, "scimitar": 0.46, "axe": 0.5, "mace": 0.42,
                 "hammer": 0.48, "staff": 0.8, "halberd": 0.9, "bow": 0.62,
                 "rifle": 0.6, "spear": 0.9, "wand": 0.24, "scythe": 0.88}


def img(path: str) -> np.ndarray:
    return np.asarray(Image.open(os.path.join(ASSETS, path)).convert("RGBA")).astype(float)


def lum(c: np.ndarray) -> np.ndarray:
    return 0.299 * c[..., 0] + 0.587 * c[..., 1] + 0.114 * c[..., 2]


def tint(px: np.ndarray, ref: float, color: tuple[int, int, int]) -> np.ndarray:
    """Teinte par carte de dégradé (formule partagée avec l'appli)."""
    k = np.clip(lum(px) / max(ref, 1), 0, 2.2)[..., None]
    c = np.array(color, float)
    return np.where(k <= 1, c * k, c + (255 - c) * (k - 1) * 0.55)


def tint_hair(px: np.ndarray, ref: float, color: tuple[int, int, int]) -> np.ndarray:
    """Teinte douce des cheveux et barbes : reflets et ombres resserrés, pour
    que les reflets clairs du modèle magenta ne virent pas au blanc (formule
    partagée avec l'appli)."""
    k = np.clip(lum(px) / max(ref, 1), 0.3, 1.6)[..., None]
    c = np.array(color, float)
    return np.where(k <= 1, c * k, c + (255 - c) * (k - 1) * 0.35)


def place(canvas: np.ndarray, layer: np.ndarray, scale: float, ox: float, oy: float,
          scale_x: float | None = None, skip=None) -> None:
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
            if 0 <= x < W and not (skip and skip(x, y, row[i])):
                canvas[y, x] = row[i]


def head_warp(src: dict, b: dict, height: int, hug_jaw: bool = False):
    """Calque de tête (coiffure, barbe) posé sur la tête du corps [b] :
    pour chaque ligne de la toile, ligne source et échelle horizontale.
    Verticalement, sommet → sourcils → menton du corps source sur ceux du
    corps ; horizontalement, la demi-largeur de la tête à chaque ligne
    (la coiffure épouse le crâne, la barbe la mâchoire). Même calcul que
    SpriteComposer.headWarp dans l'appli."""
    sx0, st, sx1 = src["skull"]
    dx0, dt, dx1 = b["skull"]
    s = (dx1 - dx0) / (sx1 - sx0)
    sb, sn, db, dn = src["brow"], src["neck"], b["brow"], b["neck"]
    sy1 = float(np.clip((db - dt) / (sb - st), 0.6 * s, 1.4 * s))
    sy2 = float(np.clip((dn - db) / (sn - sb), 0.6 * s, 1.4 * s))
    chin = db + (sn - sb) * sy2
    rows, ks = [], []
    for y in range(height):
        yc = y + 0.5
        if yc < db:
            r = sb - (db - yc) / sy1
        elif yc < chin:
            r = sb + (yc - db) / sy2
        else:
            r = sn + (yc - chin) / s
        rows.append(r)
    half_s, half_d = (sx1 - sx0) / 2, (dx1 - dx0) / 2

    def width(prof, top, y, half):
        i = int(np.floor(y)) - int(top)
        if 0 <= i < len(prof) and prof[i] >= 0.5 * half:
            return prof[i]
        return None
    for y, r in enumerate(rows):
        # Coiffure : le crâne seulement (au-dessus des sourcils) ; barbe : la
        # mâchoire, des sourcils au menton.
        yc = y + 0.5
        if hug_jaw and yc >= chin:
            ks.append(s)
            continue
        if not hug_jaw and yc >= db:
            # Sous les sourcils : la largeur du front continue (comme l'appli).
            ks.append(None)
            continue
        if hug_jaw and yc < db:
            ks.append(None)
            continue
        wd = width(b["profile"], dt, y, half_d)
        ws = width(src["profile"], st, r, half_s)
        ks.append(float(np.clip(wd / ws, 0.75 * s, 1.35 * s)) if wd and ws else None)
    if hug_jaw:
        # Barbe : une seule échelle (moyenne sur la mâchoire), pour garder sa
        # forme sur une mâchoire très différente (menton pointu, bajoues).
        jaw = [k for y, k in enumerate(ks) if k is not None and db <= y + 0.5 < chin]
        k = sum(jaw) / len(jaw) if jaw else s
        # Même échelle à la verticale, calée sur le menton du corps : pas
        # d'étirement.
        rows = [sn + (y + 0.5 - dn) / k for y in range(height)]
        return rows, [k] * height, (dx0 + dx1) / 2, (sx0 + sx1) / 2
    # Lignes sans mesure (au-dessus du crâne, sous le menton) : échelle de
    # la ligne mesurée la plus proche.
    known = [i for i, k in enumerate(ks) if k is not None and rows[i] >= 0]
    for y in range(height):
        if ks[y] is None:
            ks[y] = ks[min(known, key=lambda i: abs(i - y))] if known else s
    return rows, ks, (dx0 + dx1) / 2, (sx0 + sx1) / 2


def place_warp(canvas, layer, warp, colour=None, skip=None):
    """Pose un calque de tête déformé par [warp] (voir head_warp)."""
    rows, ks, cd, cs = warp
    h, w = layer.shape[:2]
    H, W = canvas.shape[:2]
    for y in range(H):
        r = int(np.floor(rows[y]))
        if not 0 <= r < h:
            continue
        for x in range(W):
            c = int(np.floor(cs + (x + 0.5 - cd) / ks[y]))
            if not 0 <= c < w:
                continue
            px = layer[r, c]
            if px[3] == 0 or (skip is not None and skip(x, y)):
                continue
            canvas[y, x, :3] = colour(px) if colour else px[:3]
            canvas[y, x, 3] = 255


# Marge de la barbe au-delà du contour de la joue (pixels).
JAW_MARGIN = 0.5

# Échelle d'une botte ou d'un gant (bornes, comme l'appli).
EXTREMITY_MIN, EXTREMITY_MAX = 0.8, 1.8


def extremity_scale(src, dst, feet):
    """Échelle d'une botte (couvre la boîte du pied : le plus grand des deux
    rapports) ou d'un gant (longueur de la main, plus stable que sa largeur,
    qui dépend de la pose), bornée."""
    sw, sh = src[2] - src[0], src[3] - src[1]
    dw, dh = dst[2] - dst[0], dst[3] - dst[1]
    if min(sw, sh, dw, dh) <= 0:
        return None
    k = max(dw / sw, dh / sh) if feet else dh / sh
    return min(EXTREMITY_MAX, max(EXTREMITY_MIN, k))


def glove_boxes(b, t, outfit, s_x, s_y):
    """Boîtes des mains sur la toile : celles du corps, ou celles du gabarit
    portées par la tenue."""
    if not outfit:
        return b.get("handBoxes", [])
    ox = b["cx"] - t["cx"] * s_x
    oy = b["feet"] - t["feet"] * s_y
    return [[ox + x0 * s_x, oy + y0 * s_y, ox + x1 * s_x, oy + y1 * s_y]
            for x0, y0, x1, y1 in t.get("handBoxes", [])]


def glove_palms(b, t, outfit, s_x, s_y):
    """Abscisses des deux paumes sur la toile (gauche puis droite)."""
    if not outfit:
        hx, cx = b["hand"][0], b["cx"]
    else:
        cx = b["cx"]
        hx = cx + (t["hand"][0] - t["cx"]) * s_x
    return sorted([hx, 2 * cx - hx])


def paint_glove(canvas, marks, b, t, style, outfit, s_x, s_y, skin_rgb, layer=None):
    """Gant peint sur la main visible (peau de la toile) : la forme est
    celle de la main du personnage, les couleurs celles du gant (rampe
    choisie par la luminance de la peau, manchette au-dessus du poignet).
    Même calcul que l'appli."""
    span = b["feet"] - b["neck"]
    ramp = np.array(style["ramp"], float)
    cuff_ramp = np.array(style["cuffRamp"], float)
    if len(ramp) == 0:
        return
    H, W = canvas.shape[:2]
    palms = glove_palms(b, t, outfit, s_x, s_y)
    src_boxes = t.get("handBoxes", [])
    for side, ((x0, y0, x1, y1), palm) in enumerate(zip(glove_boxes(b, t, outfit, s_x, s_y), palms)):
        if x1 <= x0 or y1 <= y0:
            continue
        top = y0 - style["cuff"] * span
        bottom = (y1 + GLOVE_TIPS * span if style["fingers"]
                  else y0 + GLOVE_FINGERLESS * (y1 - y0))
        half_w = GLOVE_HALF * span
        ys = np.arange(H)[:, None]
        xs = np.arange(W)[None, :]
        region = ((ys >= np.floor(top)) & (ys < np.ceil(bottom))
                  & (np.abs(xs + 0.5 - palm) <= half_w)
                  & (marks[..., 0] == 255) & (marks[..., 3] > 0))
        # Seulement la peau reliée à la main (pas une plage voisine).
        core = region & (ys >= y0) & (ys < y1)
        region = grow_into(core, region)
        if not region.any():
            continue
        # Bords de la main (bouts des doigts, reflets) qui ne sont pas marqués
        # peau mais n'en sont pas loin : un pixel autour, hors contour sombre.
        lums0 = lum(canvas[..., :3].astype(float))
        rgb = canvas[..., :3].astype(float)
        tot = np.maximum(rgb.sum(-1), 1)
        sk = np.array(skin_rgb, float)
        chroma = (np.abs(rgb[..., 0] / tot - sk[0] / sk.sum())
                  + np.abs(rgb[..., 1] / tot - sk[1] / sk.sum()))
        edge_ok = ((lums0 / 255 > GLOVE_OUTLINE) & (canvas[..., 3] > 0) & (chroma < GLOVE_CHROMA)
                   & (ys < np.ceil(bottom)) & (np.abs(xs + 0.5 - palm) <= half_w))
        for _ in range(GLOVE_EDGE):
            near = region.copy()
            near[1:] |= region[:-1]
            near[:-1] |= region[1:]
            near[:, 1:] |= region[:, :-1]
            near[:, :-1] |= region[:, 1:]
            region |= near & edge_ok
        lums = lum(canvas[..., :3].astype(float))
        v = lums[region]
        lo, hi = np.percentile(v, 5), np.percentile(v, 95)
        k = np.clip((lums - lo) / max(hi - lo, 1e-6), 0, 1)
        idx = np.minimum((k * len(ramp)).astype(int), len(ramp) - 1)
        cuff = region & (ys < y0)
        hand_ = region & ~cuff
        canvas[hand_, :3] = ramp[idx[hand_]]
        canvas[cuff, :3] = cuff_ramp[np.minimum(idx[cuff], len(cuff_ramp) - 1)]
        # Reliefs du gant généré (plaques, coutures, fourrure) : son image,
        # ramenée de la main du gabarit sur celle du personnage, colore
        # l'intérieur de la main ; les creux entre les doigts du personnage
        # restent sombres.
        if layer is not None and side < len(src_boxes):
            src = src_boxes[side]
            k = extremity_scale(src, [x0, y0, x1, y1], False)
            if k is not None:
                scx, scy = (src[0] + src[2]) / 2, (src[1] + src[3]) / 2
                dcx, dcy = (x0 + x1) / 2, (y0 + y1) / 2
                ry, rx = np.nonzero(region)
                sxs = np.floor(scx + (rx + 0.5 - dcx) / k).astype(int)
                sys_ = np.floor(scy + (ry + 0.5 - dcy) / k).astype(int)
                ok = ((sxs >= 0) & (sys_ >= 0) & (sxs < layer.shape[1]) & (sys_ < layer.shape[0]))
                ry, rx, sxs, sys_ = ry[ok], rx[ok], sxs[ok], sys_[ok]
                samp = layer[sys_, sxs]
                use = samp[:, 3] == 255
                shade = k_shade = np.clip((lums[ry, rx] - lo) / max(hi - lo, 1e-6), 0, 1)
                use &= shade >= GLOVE_CREASE
                canvas[ry[use], rx[use], :3] = samp[use, :3]
                del k_shade
        # Bord du gant : liseré sombre en haut de la manchette (et au bas
        # d'une mitaine).
        edge_rows = [int(np.floor(top))]
        if not style["fingers"]:
            edge_rows.append(int(np.ceil(bottom)) - 1)
        for ey in edge_rows:
            if 0 <= ey < H:
                row = region[ey]
                canvas[ey, row, :3] = ramp[0]


# Part de la main couverte par une mitaine (depuis le poignet), et écart
# horizontal toléré pour la manchette sur l'avant-bras (fraction de la
# hauteur du cou aux pieds).
GLOVE_FINGERLESS = 0.55
# Demi-largeur de la fenêtre du gant autour de la paume (fraction de la
# hauteur du cou aux pieds) : rien d'autre que la main et l'avant-bras.
GLOVE_HALF = 0.06
# Marge sous la boîte de la main pour les bouts des doigts.
GLOVE_TIPS = 0.02
# Luminance sous laquelle un pixel est le contour sombre (jamais peint).
GLOVE_OUTLINE = 0.22
# Pixels de bord repris (anneaux autour de la peau) et écart de chromaticité
# toléré avec la peau du personnage.
GLOVE_EDGE = 2
GLOVE_CHROMA = 0.06
# Sous cette luminance relative (creux entre les doigts), la main garde la
# rampe sombre plutôt que l'image du gant.
GLOVE_CREASE = 0.12


def grow_into(seed, allowed):
    """Pixels de [allowed] reliés (8 voisins) à [seed]."""
    out = seed & allowed
    while True:
        grown = out.copy()
        grown[1:] |= out[:-1]
        grown[:-1] |= out[1:]
        grown[:, 1:] |= out[:, :-1]
        grown[:, :-1] |= out[:, 1:]
        grown[1:, 1:] |= out[:-1, :-1]
        grown[1:, :-1] |= out[:-1, 1:]
        grown[:-1, 1:] |= out[1:, :-1]
        grown[:-1, :-1] |= out[1:, 1:]
        grown &= allowed
        if (grown == out).all():
            return out
        out = grown

PIECE_ORDER = ["legs", "feet", "top", "hands"]


def compose(race, sex, skin=None, hair=None, hair_color=(70, 45, 30), beard=None,
            beard_color=None, outfit=None, weapon=None, pieces=()) -> np.ndarray:
    key = f"{race}_{sex}"
    b = META["bodies"][key]
    body = img(f"bodies/{key}.png")
    skin = skin or tuple(b["skinRef"])
    skin_px = body[..., 3] == META["skinAlpha"]
    front = body[..., 3] == META["frontAlpha"]
    body[skin_px, :3] = tint(body[skin_px, :3], lum(np.array(b["skinRef"], float)), skin)
    canvas = np.zeros_like(body)
    neck = round(b.get("chin", b["neck"]))
    keep = body[..., 3] > 0
    # Bande du cou sous le menton : le vrai cou du personnage y reste.
    band = neck + round(NECK_BAND * (b["feet"] - b["neck"]))
    own_neck = skin_px.copy()
    own_neck[band + 1:] = False
    if outfit:
        # La tenue remplace le corps sous le cou, sauf la peau du cou.
        keep[neck + 1:] = False
        keep |= own_neck
    canvas[keep] = body[keep]
    canvas[..., 3] = np.where(canvas[..., 3] > 0, 255, 0)
    # Peau visible de la toile (rouge = peau) : les gants y sont peints.
    marks = np.zeros_like(canvas)
    marks[keep & skin_px, 0] = 255
    marks[keep, 3] = 255

    def mark(layer):
        m = np.zeros_like(layer)
        m[..., 3] = layer[..., 3]
        m[layer[..., 3] == META["skinAlpha"], 0] = 255
        return m
    hx, hy = b["hand"]
    if outfit:
        t = META["templates"][b["gabarit"]]
        lay = img(f"outfits/{outfit}_{b['gabarit']}.png")
        s = (b["feet"] - b["neck"]) / (t["feet"] - t["neck"])
        sx = b["torso"] / t["torso"]
        oy = b["feet"] - t["feet"] * s
        tref = lum(np.array(t["skinRef"], float))
        bare = lay[..., 3] == META["skinAlpha"]
        lay[bare, :3] = tint(lay[bare, :3], tref, skin)
        skip_neck = lambda x, y, px: px[3] == META["skinAlpha"] and own_neck[y, x]  # noqa: E731
        m_lay = mark(lay)
        place(canvas, lay, s, b["cx"] - t["cx"] * sx, oy, sx, skip=skip_neck)
        place(marks, m_lay, s, b["cx"] - t["cx"] * sx, oy, sx,
              skip=lambda x, y, px: px[0] == 255 and own_neck[y, x])
        hx = b["cx"] + (t["hand"][0] - t["cx"]) * sx
        hy = oy + t["hand"][1] * s
    # Pièces séparées : même cadrage que les tenues, dans l'ordre de dessin.
    t = META["templates"][b["gabarit"]]
    s_y = (b["feet"] - b["neck"]) / (t["feet"] - t["neck"])
    s_x = b["torso"] / t["torso"]
    gloves = []
    for pid in sorted(pieces, key=lambda q: PIECE_ORDER.index(META["pieces"][q])):
        if pid in META.get("gloves", {}):
            # Gant peint plus bas sur la main elle-même (comme l'appli).
            gloves.append((pid, img(f"pieces/{pid}_{b['gabarit']}.png")))
            continue
        lay = img(f"pieces/{pid}_{b['gabarit']}.png")
        bare = lay[..., 3] == META["skinAlpha"]
        lay[bare, :3] = tint(lay[bare, :3], lum(np.array(t["skinRef"], float)), skin)
        slot = META["pieces"][pid]
        cut = int(np.floor(t["cx"] + 0.5))
        key = "feetBoxes" if slot == "feet" else "handBoxes"
        if (slot in ("feet", "hands") and not outfit
                and len(t.get(key, [])) == 2 and len(b.get(key, [])) == 2):
            # Bottes et gants ajustés au pied et à la main de ce corps (sabots,
            # grandes mains) : chaque côté mis à l'échelle de sa boîte, posé
            # au sol (pieds) ou au centre de la main (comme l'appli).
            for side in (0, 1):
                half = lay.copy()
                if side == 0:
                    half[:, cut:] = 0
                else:
                    half[:, :cut] = 0
                src, dst = t[key][side], b[key][side]
                k = extremity_scale(src, dst, slot == "feet")
                if k is None:
                    continue
                sx_, dx_ = (src[0] + src[2]) / 2, (dst[0] + dst[2]) / 2
                if slot == "feet":
                    sy_, dy_ = src[3], dst[3]
                else:
                    sy_, dy_ = (src[1] + src[3]) / 2, (dst[1] + dst[3]) / 2
                place(canvas, half, k, dx_ - sx_ * k, dy_ - sy_ * k, k)
                place(marks, mark(half), k, dx_ - sx_ * k, dy_ - sy_ * k, k)
            continue
        if slot != "hands":
            place(canvas, lay, s_y, b["cx"] - t["cx"] * s_x, b["feet"] - t["feet"] * s_y, s_x)
            place(marks, mark(lay), s_y, b["cx"] - t["cx"] * s_x, b["feet"] - t["feet"] * s_y, s_x)
            continue
        # Gants sur une tenue : chaque gant calé sur la main de la tenue.
        t_hands = sorted([t["hand"][0], 2 * t["cx"] - t["hand"][0]])
        b_hands = sorted([hx, 2 * b["cx"] - hx])
        for side in (0, 1):
            half = lay.copy()
            if side == 0:
                half[:, cut:] = 0
            else:
                half[:, :cut] = 0
            tx, bx = t_hands[side], b_hands[side]
            place(canvas, half, s_y, bx - tx * s_x, hy - t["hand"][1] * s_y, s_x)
    for pid, glove_lay in gloves:
        paint_glove(canvas, marks, b, t, META["gloves"][pid], bool(outfit), s_x, s_y, skin,
                    glove_lay)
    if outfit or pieces:
        # Visage intact : le col d'une tenue ou d'un haut ne recouvre jamais
        # la peau du visage au-dessus du menton.
        face_skin = skin_px.copy()
        face_skin[neck + 1:] = False
        canvas[face_skin] = body[face_skin]
        canvas[face_skin, 3] = 255
    if beard:
        # Barbe dessinée sur le visage de la race (homme) : posée telle quelle.
        own = sex == "male" and race in META.get("raceBeards", [])
        lay = img(f"beards/{race}/{beard}.png" if own else f"beards/{beard}.png")
        m = lay[..., 3] > 0
        ref = float(np.median(lum(lay[m, :3])))
        src = b if own else META["hairSources"]["beard"]

        def jaw(x, y):
            # Au-dessus du menton, la barbe suit le contour du visage : rien
            # au-delà de la joue (comme l'appli).
            if y > b["neck"]:
                return False
            i = y - int(b["skull"][1])
            prof = b["profile"]
            half = prof[i] if 0 <= i < len(prof) and prof[i] >= 0.25 * (b["skull"][2] - b["skull"][0]) else None
            cx = (b["skull"][0] + b["skull"][2]) / 2
            return half is not None and abs(x + 0.5 - cx) > half + JAW_MARGIN

        place_warp(canvas, lay, head_warp(src, b, canvas.shape[0], True),
                   lambda px: tint_hair(px[:3], ref, beard_color or hair_color), skip=jaw)
    if hair:
        lay = img(f"hair/{hair}.png")
        m = lay[..., 3] > 0
        ref = float(np.median(lum(lay[m, :3])))
        src = META["hairSources"]["male" if hair[0] == "m" else "female"]

        def face(x, y):
            # Visage dégagé : pas de mèche sur le centre du visage (comme
            # l'appli) ; les mèches sur les joues restent entières.
            if not (b["brow"] + 1 <= y <= b["neck"] and skin_px[y, x]):
                return False
            i = y - int(b["skull"][1])
            prof = b["profile"]
            half = prof[i] if 0 <= i < len(prof) and prof[i] >= 0.25 * (b["skull"][2] - b["skull"][0]) else None
            cx = (b["skull"][0] + b["skull"][2]) / 2
            return half is not None and abs(x + 0.5 - cx) < FACE_INNER * half
        place_warp(canvas, lay, head_warp(src, b, canvas.shape[0]),
                   lambda px: tint_hair(px[:3], ref, hair_color), face)
    # Cornes devant la coiffure.
    canvas[front] = body[front]
    canvas[front, 3] = 255
    if weapon:
        w = META["weapons"][weapon]
        lay = img(f"weapons/{weapon}.png")
        length = WEAPON_LENGTH[weapon.split("_")[0]] * (b["feet"] - b["top"])
        s = length / w["size"][1]
        # La main passe devant la poignée (comme l'appli).
        size = b["feet"] - b["top"]
        rx, ry = HAND_RX * size, HAND_RY * size
        yy, xx = np.mgrid[0:canvas.shape[0], 0:canvas.shape[1]]
        hand = (((xx + 0.5 - hx) / rx) ** 2 + ((yy + 0.5 - hy) / ry) ** 2 <= 1) & (canvas[..., 3] > 0)
        saved = canvas[hand].copy()
        # Arme courte au repos : retournée, la poignée reste dans la main.
        if weapon.split("_")[0] in LOWERED:
            # Au repos : le pommeau dépasse juste au-dessus du poing.
            lay = lay[::-1].copy()
            oy = hy - POMMEL_ABOVE * size
        else:
            oy = hy - w["grip"] * w["size"][1] * s
        place(canvas, lay, s, hx - w["size"][0] * s / 2, oy)
        canvas[hand] = saved
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
