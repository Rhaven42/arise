"""Calques du personnage en pixel art (images générées avec SpriteCook).

Toutes les images partagent le même cadrage (pose et plan identiques) :
on les ramène sur une toile commune, on recale chaque édition sur sa base,
puis on garde les pixels qui ont changé (coiffure, barbe, armure).
"""

from __future__ import annotations

import numpy as np
from PIL import Image
from scipy import ndimage

# Toile commune (9:16), en pixels d'art.
CANVAS_W, CANVAS_H = 144, 256


def load(path: str) -> np.ndarray:
    """Charge une image et la ramène sur la toile commune (alpha binaire)."""
    src = Image.open(path).convert("RGBA")
    # Mise à l'échelle sur la hauteur (proportions gardées), centrage horizontal.
    w = max(1, round(src.width * CANVAS_H / src.height))
    src = src.resize((w, CANVAS_H), Image.NEAREST)
    im = Image.new("RGBA", (CANVAS_W, CANVAS_H))
    im.paste(src, ((CANVAS_W - w) // 2, 0))
    a = np.asarray(im).astype(np.int16).copy()
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    a[a[..., 3] == 0, :3] = 0
    return a


def save(a: np.ndarray, path: str) -> None:
    Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA").save(path, optimize=True)


def shift(a: np.ndarray, dx: int, dy: int) -> np.ndarray:
    out = np.zeros_like(a)
    h, w = a.shape[:2]
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    out[yd, xd] = a[ys, xs]
    return out


def color_dist(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    return np.abs(a[..., :3] - b[..., :3]).sum(axis=-1)


def _scaled(a: np.ndarray, scale: float) -> np.ndarray:
    """Mise à l'échelle autour du point bas-centre de la toile (les pieds)."""
    if abs(scale - 1) < 1e-6:
        return a
    h, w = a.shape[:2]
    im = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    im = im.resize((nw, nh), Image.NEAREST)
    out = Image.new("RGBA", (w, h))
    out.paste(im, ((w - nw) // 2, h - nh))
    return np.asarray(out).astype(np.int16).copy()


def align(edit: np.ndarray, base: np.ndarray, rows: slice, radius: int = 5,
          scales: tuple[float, ...] = tuple(np.round(np.arange(0.9, 1.101, 0.02), 2))) -> np.ndarray:
    """Recale [edit] (échelle puis décalage) pour coller au mieux à [base]
    sur les lignes [rows]."""
    best, best_score = edit, None
    for sc in scales:
        es = _scaled(edit, float(sc))
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                e = shift(es, dx, dy)
                both = (e[rows, :, 3] > 0) & (base[rows, :, 3] > 0)
                either = (e[rows, :, 3] > 0) | (base[rows, :, 3] > 0)
                overlap = both.sum() / max(either.sum(), 1)
                dist = color_dist(e[rows], base[rows])[both].mean() if both.any() else 999
                score = overlap * 100 - dist / 10
                if best_score is None or score > best_score:
                    best, best_score = e, score
    return best


def prealign(edit: np.ndarray, base: np.ndarray) -> np.ndarray:
    """Recalage grossier : même hauteur de corps (sommet de la tête aux
    pieds) et même centre, avant le recalage fin."""
    def span(a):
        al = a[..., 3] > 0
        ys = np.where(al.any(axis=1))[0]
        xs = np.where(al.any(axis=0))[0]
        return ys[0], ys[-1], (xs[0] + xs[-1]) / 2
    et, eb, ec = span(edit)
    bt, bb, bc = span(base)
    scale = (bb - bt) / max(eb - et, 1)
    h, w = edit.shape[:2]
    im = Image.fromarray(edit.clip(0, 255).astype(np.uint8), "RGBA")
    im = im.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.NEAREST)
    out = Image.new("RGBA", (w, h))
    out.paste(im, (round(bc - ec * scale), round(bb - eb * scale)), im)
    return np.asarray(out).astype(np.int16).copy()


def head_box(base: np.ndarray) -> tuple[int, int, int, int]:
    """Boîte de la tête : du sommet jusqu'au cou (ligne la plus étroite)."""
    alpha = base[..., 3] > 0
    rows = np.where(alpha.any(axis=1))[0]
    top = rows[0]
    widths = alpha.sum(axis=1)
    # Le cou : largeur minimale entre 8 % et 30 % de la hauteur du corps.
    h = rows[-1] - top
    lo, hi = top + int(0.06 * h), top + int(0.30 * h)
    neck = lo + int(np.argmin(widths[lo:hi]))
    cols = np.where(alpha[top:neck].any(axis=0))[0]
    return int(cols[0]), int(top), int(cols[-1] + 1), int(neck)


def changed_layer(base: np.ndarray, edit: np.ndarray, region: np.ndarray,
                  threshold: int = 70, min_size: int = 6) -> np.ndarray:
    """Pixels de [edit] qui diffèrent de [base] dans [region]."""
    opaque = edit[..., 3] > 0
    diff = (base[..., 3] == 0) | (color_dist(edit, base) > threshold)
    mask = opaque & diff & region
    mask = ndimage.binary_opening(mask, np.ones((2, 2))) | (mask & ndimage.binary_erosion(mask))
    labels, n = ndimage.label(mask)
    if n:
        sizes = ndimage.sum(mask, labels, range(1, n + 1))
        keep = np.isin(labels, [i + 1 for i, s in enumerate(sizes) if s >= min_size])
        mask = keep
    # Bouche les petits trous (reflets proches de la couleur de base).
    mask = ndimage.binary_closing(mask, np.ones((3, 3))) & opaque & region
    out = np.zeros_like(edit)
    out[mask] = edit[mask]
    return out



def _hue_sat_val(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    r, g, b = (rgb[..., i] / 255.0 for i in range(3))
    mx, mn = np.maximum(np.maximum(r, g), b), np.minimum(np.minimum(r, g), b)
    d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6
    return h, np.where(mx > 0, d / (mx + 1e-6), 0), mx


# Teinte de détourage des coiffures et barbes (magenta vif).
KEY_HUE = 0.87


def key_layer(base: np.ndarray, edit: np.ndarray, hue: float | None = None,
              tol: float = 0.05, min_sat: float = 0.35,
              seed_rows: tuple[float, float] | None = (0.0, 0.3)) -> np.ndarray:
    """Calque des pixels de la teinte clé (coiffure, barbe), avec leur
    contour sombre. Les couleurs sont ensuite recolorées dans l'appli."""
    x0, top, x1, neck = head_box(base)
    edit = align(edit, base, slice(neck + 20, CANVAS_H))
    h, s, v = _hue_sat_val(edit)
    opaque = edit[..., 3] > 0
    if hue is None:
        # Teinte clé : pic des teintes saturées de la famille magenta-rose
        # (0,8 à 1), où la peau n'apparaît jamais, affiné par la moyenne
        # autour du pic.
        sat = opaque & (s > 0.4) & (v > 0.3)
        he, _ = np.histogram(h[sat], bins=40, range=(0, 1))
        peak = (32 + int(np.argmax(he[32:])) + 0.5) / 40
        near = sat & (np.abs(((h - peak + 0.5) % 1) - 0.5) < 0.04)
        ang = h[near] * 2 * np.pi
        hue = (np.arctan2(np.sin(ang).mean(), np.cos(ang).mean()) / (2 * np.pi)) % 1
    dh = np.abs(((h - hue + 0.5) % 1) - 0.5)
    key = opaque & (dh < tol) & (s > min_sat) & (v > 0.18)
    labels, n = ndimage.label(key, np.ones((3, 3)))
    if n:
        sizes = ndimage.sum(key, labels, range(1, n + 1))
        key = np.isin(labels, [i + 1 for i, s_ in enumerate(sizes) if s_ >= 6])
    if seed_rows is not None:
        # Coiffure : morceaux d'au moins 15 pixels qui commencent au-dessus
        # du cou (mèches, tresse derrière l'oreille), et ceux qui les
        # touchent à 2 pixels près ; les lèvres et les reflets rouges de la
        # chemise sont écartés.
        parts, n = ndimage.label(key, np.ones((3, 3)))
        seeds = [i for i, sl in enumerate(ndimage.find_objects(parts), 1)
                 if sl[0].start < neck + 2 and (parts[sl] == i).sum() >= 15]
        grown, _ = ndimage.label(ndimage.binary_dilation(key, np.ones((5, 5))))
        keep = set(np.unique(grown[np.isin(parts, seeds)]))
        keep.discard(0)
        key &= np.isin(grown, list(keep))
    # Trous internes (reflets désaturés) et contour sombre d'un pixel.
    key = ndimage.binary_fill_holes(key) & opaque
    ring = ndimage.binary_dilation(key, np.ones((3, 3))) & ~key & opaque
    outline = ring & (v < 0.35) & (color_dist(edit, base) > 40)
    mask = key | outline
    out = np.zeros_like(edit)
    out[mask] = edit[mask]
    return out


def luminance(a: np.ndarray) -> np.ndarray:
    return (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]) / 255.0


def recolor(layer: np.ndarray, color: tuple[int, int, int]) -> np.ndarray:
    """Recoloration par carte de dégradé : la luminance du calque garde le
    modelé, la couleur choisie donne la teinte (aperçu des outils ; l'appli
    applique la même formule)."""
    lum = luminance(layer)
    m = layer[..., 3] > 0
    ref = np.median(lum[m]) if m.any() else 0.5
    k = np.clip(lum / max(ref, 1e-3), 0, 2.2)[..., None]
    c = np.array(color, float)[None, None, :]
    # En dessous du ton moyen : on assombrit ; au-dessus : on éclaircit vers le blanc.
    dark = c * k
    light = c + (255 - c) * (k - 1) * 0.55
    rgb = np.where(k <= 1, dark, light)
    out = layer.copy()
    out[..., :3] = np.where(m[..., None], rgb, 0)
    return out


def skull(name: str) -> tuple[float, float, float]:
    """Crâne mesuré d'un corps de base : (gauche, sommet, droite)."""
    import json
    import os
    heads = json.load(open(os.path.join(os.path.dirname(__file__), "heads.json")))
    return tuple(heads[name])


def fit_to_head(layer: np.ndarray, src: str, dst: str) -> np.ndarray:
    """Pose un calque de tête dessiné sur le corps [src] sur la tête du corps
    [dst] : mise à l'échelle sur la largeur du crâne, sommet et centre alignés.
    L'appli applique la même transformation (assets/sprites/heads.json)."""
    sx0, st, sx1 = skull(src)
    dx0, dt, dx1 = skull(dst)
    scale = (dx1 - dx0) / (sx1 - sx0)
    h, w = layer.shape[:2]
    im = Image.fromarray(layer.clip(0, 255).astype(np.uint8), "RGBA")
    im = im.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.NEAREST)
    out = Image.new("RGBA", (w, h))
    ox = round((dx0 + dx1) / 2 - (sx0 + sx1) / 2 * scale)
    oy = round(dt - st * scale)
    out.paste(im, (ox, oy), im)
    a = np.asarray(out).astype(np.int16).copy()
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    return a


# Alpha réservé aux pixels de peau d'un calque (recolorés à la teinte du
# personnage dans l'appli) ; les autres pixels opaques ont l'alpha 255.
SKIN_ALPHA = 254


def face_palette(base: np.ndarray, sample: tuple[int, int], radius: int = 6) -> np.ndarray:
    """Couleurs de peau du visage autour de [sample] (sans contours ni yeux)."""
    x, y = sample
    patch = base[y - radius: y + radius + 1, x - radius: x + radius + 1].reshape(-1, 4)
    patch = patch[patch[:, 3] > 0][:, :3]
    v = patch.max(axis=1) / 255
    patch = patch[v > 0.3]
    return np.unique(patch // 6 * 6, axis=0)


def skin_mask(img: np.ndarray, palette: np.ndarray, tol: int = 36) -> np.ndarray:
    """Pixels de [img] proches d'une couleur de la palette de peau."""
    m = img[..., 3] > 0
    ys, xs = np.nonzero(m)
    d = np.abs(img[ys, xs, None, :3] - palette[None, :, :]).sum(-1).min(1)
    out = np.zeros(m.shape, bool)
    out[ys, xs] = d < tol
    return out


def cloth_palette(base: np.ndarray, neck: int, hands: int, bottom: int,
                  face: np.ndarray, legs: bool = True) -> np.ndarray:
    """Couleurs des habits de base, ombres comprises : chemise (torse entre
    le cou et les mains) et pantalon (bande des jambes sous les mains)."""
    al = base[..., 3] > 0
    xs = np.where(al.any(axis=0))[0]
    cx = (xs[0] + xs[-1]) / 2
    h = bottom - neck
    a0, a1 = neck + int(0.12 * (hands - neck)), neck + int(0.7 * (hands - neck))
    b0, b1 = hands + int(0.1 * (bottom - hands)), hands + int(0.6 * (bottom - hands))
    box = np.zeros(al.shape, bool)
    # Chemise : deux bandes de part et d'autre de l'encolure (épaules
    # comprises), sans la peau du col en V.
    box[a0:a1, int(cx - 0.11 * h): int(cx - 0.04 * h)] = True
    box[a0:a1, int(cx + 0.04 * h): int(cx + 0.11 * h)] = True
    if legs:
        box[b0:b1] = True
    px = base[box & al][:, :3]
    # Peau verte ou rouge du col ouvert (large chez l'orque) écartée ; les
    # peaux de teinte voisine des habits (beige, brun) ne sont pas touchées.
    hue, _, _ = _hue_sat_val(px[None].astype(float))
    colored = np.abs(((hue[0] - 0.08 + 0.5) % 1) - 0.5) > 0.05
    px = px[~(colored & (np.abs(px[:, None, :] - face[None]).sum(-1).min(1) < 30))]
    return np.unique(px // 6 * 6, axis=0)


def body_skin(base: np.ndarray, sample: tuple[int, int], neck: int, skull_top: float,
              arms: list | None = None, tol: int = 34) -> np.ndarray:
    """Peau d'un corps de base : pixels plus proches des couleurs du visage
    que de celles des habits de base (chemise, pantalon), reliés au visage ou
    aux mains, même à travers un contour d'un pixel. Les peaux saturées
    (vert, rouge) gardent leurs ombres de même teinte."""
    sx, sy = sample
    alpha = base[..., 3] > 0
    ys = np.where(alpha.any(axis=1))[0]
    # Hauteur du corps depuis le sommet du crâne (cornes non comprises).
    top, bottom = int(skull_top), int(ys[-1])
    pal = face_palette(base, sample)
    h = bottom - top
    # Bout des doigts vers 80 % de la hauteur.
    chest, hands = top + int(0.40 * h), top + int(0.80 * h)
    cloth = cloth_palette(base, neck, hands, bottom, pal)
    hh, ss, v = _hue_sat_val(base)
    h0 = float(np.median(hh[sy - 1: sy + 2, sx - 1: sx + 2]))
    s0 = float(np.median(ss[sy - 1: sy + 2, sx - 1: sx + 2]))
    v0 = float(np.median(v[sy - 1: sy + 2, sx - 1: sx + 2]))
    py, px = np.nonzero(alpha)
    rgb = base[py, px, None, :3]
    d_face = np.full(alpha.shape, 9999.0)
    d_cloth = np.full(alpha.shape, 9999.0)
    d_face[py, px] = np.abs(rgb - pal[None]).sum(-1).min(1)
    d_cloth[py, px] = np.abs(rgb - cloth[None]).sum(-1).min(1)
    cand = alpha & (d_face < tol) & (v > 0.55 * v0)
    if s0 > 0.45:
        dh = np.abs(((hh - h0 + 0.5) % 1) - 0.5)
        cand |= alpha & (dh < 0.06) & (ss > 0.45) & (v > 0.2)
    # Sous le cou, un pixel plus proche des couleurs des habits que de
    # celles du visage n'est pas de la peau.
    cand[neck:] &= (d_face < d_cloth)[neck:]
    # Sous la poitrine, la peau n'est que sur les bras et les mains, au bord
    # de la silhouette ; plus bas que les mains, aucune peau (pantalon,
    # bottes). Les liserés de moins de 3 pixels d'épaisseur sont écartés.
    # Entre le cou et la poitrine, manches et épaules sont de la chemise :
    # la peau n'est que dans l'encolure.
    xs_all = np.where(alpha.any(axis=0))[0]
    cx = (xs_all[0] + xs_all[-1]) / 2
    upper = np.zeros(alpha.shape, bool)
    upper[neck + 3: chest, : max(0, int(cx - 0.07 * h))] = True
    upper[neck + 3: chest, int(cx + 0.07 * h):] = True
    cand &= ~upper
    # Mains : leur propre couleur, prise au pixel le plus proche de la peau
    # du visage dans la zone de chaque bras (ombres et fourrure comprises).
    reach = int(0.085 * h)
    hand_skin = np.zeros(alpha.shape, bool)
    for side in (0, 1):
        zone = np.zeros(alpha.shape, bool)
        for y in range(chest, hands):
            xs = np.where(alpha[y])[0]
            if len(xs):
                if side == 0:
                    zone[y, xs[0]: xs[0] + reach + 1] = True
                else:
                    zone[y, max(0, xs[-1] - reach): xs[-1] + 1] = True
        zone &= alpha & (d_face < d_cloth)
        if not zone.any():
            continue
        zy, zx = np.nonzero(zone)
        k = int(np.argmin(d_face[zy, zx]))
        hand = face_palette(base, (int(zx[k]), int(zy[k])), 3)
        if len(hand):
            d_hand = np.full(alpha.shape, 9999.0)
            d_hand[py, px] = np.abs(rgb - hand[None]).sum(-1).min(1)
            # Seule la tache reliée au point choisi (sans franchir les
            # contours) : la fourrure du minotaure et son pantalon brun ont
            # la même couleur.
            parts, _ = ndimage.label(zone & (d_hand < 40))
            seed = parts[int(zy[k]), int(zx[k])]
            if seed:
                hand_skin |= parts == seed
    cand[hands:] = False
    for y in range(chest, hands):
        xs = np.where(alpha[y])[0]
        if len(xs):
            row = np.zeros(alpha.shape[1], bool)
            row[xs[0]: xs[0] + reach + 1] = True
            row[max(0, xs[-1] - reach): xs[-1] + 1] = True
            cand[y] &= row
    cand[chest:] = ndimage.binary_opening(cand[chest:], np.ones((3, 3)))
    seeds = [(sx, sy)]
    # Mains : pixels opaques les plus à gauche et à droite au niveau des hanches.
    for y in range(top + int(0.48 * (bottom - top)), top + int(0.66 * (bottom - top))):
        xs = np.where(alpha[y])[0]
        seeds += [(int(xs[0]) + 1, y), (int(xs[-1]) - 1, y)]
    labels, _ = ndimage.label(ndimage.binary_dilation(cand, np.ones((3, 3))))
    keep = {labels[y, x] for x, y in seeds if cand[y, x]}
    keep.discard(0)
    hand_skin[hands:] = False
    hand_skin = ndimage.binary_opening(hand_skin, np.ones((3, 3)))
    skin = (cand & np.isin(labels, list(keep))) | hand_skin
    if arms:
        # Avant-bras relevés à la main : tout ce qui n'est pas la chemise.
        shirt = cloth_palette(base, neck, hands, bottom, pal, legs=False)
        # Beige de la chemise seulement (la fourrure brune du poitrail du
        # minotaure, visible dans le col, n'en fait pas partie).
        _, s_sh, v_sh = _hue_sat_val(shirt[None].astype(float))
        shirt = shirt[(s_sh[0] < 0.4) & (v_sh[0] > 0.5)]
        d_shirt = np.full(alpha.shape, 9999.0)
        d_shirt[py, px] = np.abs(rgb - shirt[None]).sum(-1).min(1)
        box = np.zeros(alpha.shape, bool)
        for x0, y0, x1, y1 in arms:
            box[y0:y1, x0:x1] = True
        skin[chest:] &= ~box[chest:]
        skin |= ndimage.binary_opening(box & alpha & ((d_shirt > 30) | (d_face < d_shirt)),
                                       np.ones((3, 3)))
    return skin


def outfit_layer(base: np.ndarray, edit: np.ndarray, neck: int,
                 skin_sample: tuple[int, int], skull_top: float,
                 arms: list | None = None) -> np.ndarray:
    """Tenue : tout le corps de l'édition sous le cou. La peau restée nue
    (cou, mains, avant-bras) est marquée par l'alpha de peau."""
    edit = align(prealign(edit, base), base, slice(0, neck - 2),
                 scales=(0.96, 0.98, 1.0, 1.02, 1.04))
    out = np.zeros_like(edit)
    rows = np.zeros(base.shape[:2], bool)
    rows[neck:] = True
    body = (edit[..., 3] > 0) & rows
    out[body] = edit[body]
    base_skin = body_skin(base, skin_sample, neck, skull_top, arms)
    near = ndimage.binary_dilation(base_skin, np.ones((3, 3)), iterations=2)
    _, _, v = _hue_sat_val(edit)
    x, y = skin_sample
    bright = v > 0.55 * float(np.median(_hue_sat_val(base)[2][y - 1: y + 2, x - 1: x + 2]))
    skin = skin_mask(edit, face_palette(base, skin_sample), 24) & bright & near & body
    # Peau du corps de base restée telle quelle (cou vert de l'orque compris).
    skin |= base_skin & body & (color_dist(edit, base) < 40)
    # Peau nue (cou, mains, avant-bras) : marquée par l'alpha de peau,
    # recolorée à la teinte du personnage dans l'appli.
    out[skin, 3] = SKIN_ALPHA
    return out


# Alphas réservés des corps : zones recolorées dans l'appli.
EYE_ALPHA = 253
LIP_ALPHA = 252
SHADOW_ALPHA = 251
BLUSH_ALPHA = 250


def best_skin(base: np.ndarray, skull: tuple[float, float, float],
              neck: int, arms: list | None = None) -> tuple[np.ndarray, tuple[int, int]]:
    """Peau du corps, avec l'échantillon du visage qui en couvre le plus."""
    x0, t, x1 = skull
    w = x1 - x0
    cx = (x0 + x1) / 2
    best = None
    for fx, fy in ((0, 0.62), (-0.22, 0.62), (0.22, 0.62), (0, 0.3), (0, 0.8)):
        p = (int(cx + fx * w), int(t + fy * w))
        if base[p[1], p[0], 3] == 0:
            continue
        m = body_skin(base, p, neck, t, arms)
        if best is None or m.sum() > best[0].sum():
            best = (m, p)
    return best


def eye_mask(base: np.ndarray, skin: np.ndarray, centres, radius: float = 2.2) -> np.ndarray:
    """Iris : pixels autour du centre relevé de chaque œil qui ne sont ni de
    la peau, ni le contour sombre, ni le blanc de l'œil."""
    h, s, v = _hue_sat_val(base)
    yy, xx = np.mgrid[0: base.shape[0], 0: base.shape[1]]
    out = np.zeros(base.shape[:2], bool)
    for cx, cy in centres:
        near = (xx - cx) ** 2 + ((yy - cy) * 1.4) ** 2 <= radius ** 2
        out |= near & ~skin & (base[..., 3] > 0) & (v > 0.24) & ((s > 0.16) | (v < 0.75))
    return out


def neck_row(base: np.ndarray, skull: tuple[float, float, float]) -> int:
    """Ligne du cou : la plus étroite sous le menton, cherchée entre 0,8 et
    1,8 largeur de crâne sous le sommet (les grosses têtes des gnomes et des
    gobelins comprises)."""
    x0, t, x1 = skull
    w = x1 - x0
    alpha = base[..., 3] > 0
    lo, hi = int(t + 0.8 * w), min(base.shape[0] - 1, int(t + 1.8 * w))
    cx = int((x0 + x1) / 2)
    widths = []
    for y in range(lo, hi):
        row = alpha[y]
        # Largeur du segment opaque qui contient l'axe du visage.
        if not row[cx]:
            widths.append(999)
            continue
        l = cx
        while l > 0 and row[l - 1]:
            l -= 1
        r = cx
        while r < len(row) - 1 and row[r + 1]:
            r += 1
        widths.append(r - l)
    return lo + int(np.argmin(widths))
