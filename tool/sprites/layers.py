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
    if eb >= h - 2:
        # Image coupée en bas (pieds absents) : échelle par la largeur du
        # corps (épaules et bras), recalage sur le sommet de la tête.
        def width(a):
            xs = np.where((a[..., 3] > 0).any(axis=0))[0]
            return xs[-1] - xs[0]
        scale = width(base) / max(width(edit), 1)
        im = Image.fromarray(edit.clip(0, 255).astype(np.uint8), "RGBA")
        im = im.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.NEAREST)
        out = Image.new("RGBA", (w, h))
        out.paste(im, (round(bc - ec * scale), round(bt - et * scale)), im)
        return np.asarray(out).astype(np.int16).copy()
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
              seed_rows: tuple[float, float] | None = (0.0, 0.3),
              open_mouth: bool = False) -> np.ndarray:
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
    # Écart de teinte signé : côté rouge (au-delà du magenta, vers la peau)
    # limité à 0,045 pour ne jamais prendre un visage voisin d'une frange.
    dh = ((h - hue + 0.5) % 1) - 0.5
    key = opaque & (dh > -tol) & (dh < min(tol, 0.045)) & (s > min_sat) & (v > 0.18)
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
    filled = ndimage.binary_fill_holes(key) & opaque
    if open_mouth:
        # Barbe : les trous qui ne sont pas de la teinte clé (bouche, lèvres)
        # restent transparents, la bouche du visage apparaît.
        filled &= key | (np.abs(dh) < 0.1) | (v < 0.2)
    key = filled
    ring = ndimage.binary_dilation(key, np.ones((3, 3))) & ~key & opaque
    outline = ring & (v < 0.35) & (color_dist(edit, base) > 40)
    mask = key | outline
    out = np.zeros_like(edit)
    out[mask] = edit[mask]
    return out


def race_beard_layer(base: np.ndarray, edit: np.ndarray) -> np.ndarray:
    """Barbe dessinée sur le corps d'une race : recalage grossier puis fin,
    tout le magenta (sans graine au-dessus du cou), bouche transparente ; les
    miettes détachées de la barbe (perles, reflets isolés) sont écartées."""
    lay = key_layer(base, prealign(edit, base), hue=0.952, tol=0.065, min_sat=0.15,
                    seed_rows=None, open_mouth=True)
    m = lay[..., 3] > 0
    parts, n = ndimage.label(m, np.ones((3, 3)))
    if n > 1:
        sizes = ndimage.sum(m, parts, range(1, n + 1))
        main = parts == int(np.argmax(sizes)) + 1
        near = ndimage.binary_dilation(main, np.ones((3, 3)), iterations=3)
        keep = set(np.unique(parts[near])) - {0}
        lay[~np.isin(parts, list(keep))] = 0
    return lay


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
                  face: np.ndarray, legs: bool = True,
                  width: tuple[float, float] = (0.04, 0.11)) -> np.ndarray:
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
    w0, w1 = width
    box[a0:a1, int(cx - w1 * h): int(cx - w0 * h)] = True
    box[a0:a1, int(cx + w0 * h): int(cx + w1 * h)] = True
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


# Bande de lignes de chaque pièce, en fraction de la hauteur cou → pieds.
PIECE_BANDS = {"top": (0.0, 0.62), "legs": (0.40, 0.88), "feet": (0.76, 1.01), "hands": (0.2, 0.75)}


def piece_layer(base: np.ndarray, edit: np.ndarray, slot: str, neck: int, feet: int,
                skin_sample: tuple[int, int], skull_top: float,
                arms: list | None = None) -> np.ndarray:
    """Pièce séparée (haut, bas, chaussures, gants) : pixels de l'édition qui
    diffèrent du corps de base dans la bande de la pièce, trous internes
    bouchés et contour sombre compris. Le bas et les chaussures excluent les
    mains ; les gants ne gardent que les mains et avant-bras. La peau dévoilée
    (bras d'un haut sans manches) reste transparente : le corps de base
    apparaît dessous."""
    edit = align(prealign(edit, base), base, slice(0, neck - 2),
                 scales=(0.96, 0.98, 1.0, 1.02, 1.04))
    f0, f1 = PIECE_BANDS[slot]
    rows = np.zeros(base.shape[:2], bool)
    rows[max(neck, int(neck + f0 * (feet - neck))): int(neck + f1 * (feet - neck)) + 1] = True
    base_skin = body_skin(base, skin_sample, neck, skull_top, arms)
    hands = base_skin.copy()
    hands[: int(neck + 0.15 * (feet - neck))] = False
    near_hands = ndimage.binary_dilation(hands, np.ones((3, 3)), iterations=3)
    if slot in ("legs", "feet"):
        rows &= ~near_hands
    elif slot == "hands":
        rows &= ndimage.binary_dilation(hands, np.ones((3, 3)), iterations=4)
    opaque = edit[..., 3] > 0
    # Chaussures : teintes sombres voisines (vert foncé sur brun) : seuil bas.
    limit = 32 if slot == "feet" else 60
    changed = opaque & rows & ((color_dist(edit, base) > limit) | (base[..., 3] == 0))
    # Petits écarts isolés (recalage, bruit) écartés.
    changed = ndimage.binary_opening(changed, np.ones((2, 2)))
    labels, n = ndimage.label(changed, np.ones((3, 3)))
    if n:
        sizes = ndimage.sum(changed, labels, range(1, n + 1))
        changed = np.isin(labels, [i + 1 for i, s_ in enumerate(sizes) if s_ >= 12])
    mask = ndimage.binary_fill_holes(changed) & rows
    if slot == "legs":
        # Tout le pantalon du corps de base, même là où l'édition a gardé la
        # couleur d'origine ; sans les pans de chemise (couleurs de la
        # chemise de base).
        span = feet - neck
        cx = int(np.mean(np.nonzero(base[..., 3] > 0)[1]))
        pants = base[int(neck + 0.55 * span): int(neck + 0.75 * span), cx - 8: cx + 9]
        pants = np.unique(pants[pants[..., 3] > 0][:, :3] // 6 * 6, axis=0)
        shirt = base[int(neck + 0.15 * span): int(neck + 0.35 * span), cx - 12: cx + 13]
        shirt = np.unique(shirt[shirt[..., 3] > 0][:, :3] // 6 * 6, axis=0)
        # Beige de la chemise seulement (sans lacets ni ceinture, sombres).
        _, s_sh, v_sh = _hue_sat_val(shirt[None].astype(float))
        shirt = shirt[(v_sh[0] > 0.55) & (s_sh[0] < 0.4)]
        ba = base[..., 3] > 0
        py_, px_ = np.nonzero(ba & rows)
        rgb_ = base[py_, px_, None, :3]
        is_pants = np.zeros_like(mask)
        is_pants[py_, px_] = (np.abs(rgb_ - pants[None]).sum(-1).min(1)
                              < np.abs(rgb_ - shirt[None]).sum(-1).min(1))
        is_pants &= ~base_skin
        is_pants = ndimage.binary_opening(is_pants, np.ones((2, 2)))
        mask |= ndimage.binary_dilation(is_pants, np.ones((3, 3))) & opaque & rows
        ey, ex = np.nonzero(mask)
        d_sh = np.abs(edit[ey, ex, None, :3] - shirt[None]).sum(-1).min(1)
        mask[ey[d_sh < 14], ex[d_sh < 14]] = False
    if slot == "feet":
        # Seuls les morceaux qui touchent le sol (les chaussures) ; les
        # revers de pantalon redessinés au-dessus sont écartés.
        parts, n = ndimage.label(mask, np.ones((3, 3)))
        ground = set(np.unique(parts[feet - int(0.05 * (feet - neck)): feet + 1]))
        ground.discard(0)
        mask = np.isin(parts, list(ground))
        # Revers du pantalon de base collés au haut de la chaussure : retirés
        # dans la moitié haute de la pièce.
        span = feet - neck
        cx = int(np.mean(np.nonzero(base[..., 3] > 0)[1]))
        pants = base[int(neck + 0.55 * span): int(neck + 0.75 * span), cx - 14: cx + 15]
        pants = np.unique(pants[pants[..., 3] > 0][:, :3] // 6 * 6, axis=0)
        ys_ = np.nonzero(mask.any(axis=1))[0]
        if len(ys_) and len(pants):
            top_half = np.zeros_like(mask)
            top_half[ys_[0]: (ys_[0] + ys_[-1]) // 2] = True
            ey, ex = np.nonzero(mask & top_half)
            d_p = np.abs(edit[ey, ex, None, :3] - pants[None]).sum(-1).min(1)
            mask[ey[d_p < 16], ex[d_p < 16]] = False
            mask = ndimage.binary_opening(mask, np.ones((2, 2)))
    if slot == "top":
        # Sous la taille, un pixel plus proche du pantalon de base que du
        # vêtement n'en fait pas partie (pantalon retouché par l'édition).
        span = feet - neck
        # Pantalon du corps de base et de l'édition (retouché parfois d'un ton).
        pants = np.concatenate([base[int(neck + 0.55 * span): int(neck + 0.75 * span)],
                                edit[int(neck + 0.66 * span): int(neck + 0.80 * span)]])
        pants = np.unique(pants[pants[..., 3] > 0][:, :3] // 6 * 6, axis=0)
        cx = int(np.mean(np.nonzero(base[..., 3] > 0)[1]))
        torso = edit[int(neck + 0.15 * span): int(neck + 0.35 * span), cx - 6: cx + 7]
        garment = np.unique(torso[torso[..., 3] > 0][:, :3] // 6 * 6, axis=0)
        low = np.zeros_like(mask)
        low[int(neck + 0.45 * span):] = True
        ys_, xs_ = np.nonzero(mask & low)
        if len(ys_) and len(pants) and len(garment):
            px_ = edit[ys_, xs_, None, :3]
            d_p = np.abs(px_ - pants[None]).sum(-1).min(1)
            d_g = np.abs(px_ - garment[None]).sum(-1).min(1)
            # Pantalon reconnu, ou couleur loin de toutes celles du vêtement.
            drop = (d_p < d_g) | (d_g > 30)
            mask[ys_[drop], xs_[drop]] = False
            mask = ndimage.binary_opening(mask, np.ones((2, 2))) | (mask & ~low)
    mask |= ndimage.binary_dilation(mask, np.ones((3, 3))) & opaque & rows & (luminance(edit) < 0.25)
    out = np.zeros_like(edit)
    out[mask] = edit[mask]
    _, _, v = _hue_sat_val(edit)
    x, y = skin_sample
    bright = v > 0.55 * float(np.median(_hue_sat_val(base)[2][y - 1: y + 2, x - 1: x + 2]))
    # Peau dévoilée : seulement pour un haut ou des gants (bras nus) ; sur le
    # bas et les chaussures, les reflets du métal ressemblent à de la peau.
    if slot == "hands":
        # Gants : seulement ce qui a changé (la peau intacte de l'avant-bras
        # reste celle du corps, sous une éventuelle manche).
        out[mask & (color_dist(edit, base) < 40)] = 0
        out[skin_mask(edit, face_palette(base, skin_sample), 20) & mask] = 0
        # Manches de la chemise de base (beige clair) écartées.
        span = feet - neck
        cx = int(np.mean(np.nonzero(base[..., 3] > 0)[1]))
        shirt = base[int(neck + 0.15 * span): int(neck + 0.35 * span), cx - 12: cx + 13]
        shirt = np.unique(shirt[shirt[..., 3] > 0][:, :3] // 6 * 6, axis=0)
        _, s_sh, v_sh = _hue_sat_val(shirt[None].astype(float))
        shirt = shirt[(v_sh[0] > 0.55) & (s_sh[0] < 0.4)]
        ey, ex = np.nonzero(out[..., 3] > 0)
        if len(ey) and len(shirt):
            d_sh = np.abs(out[ey, ex, None, :3] - shirt[None]).sum(-1).min(1)
            out[ey[d_sh < 24], ex[d_sh < 24]] = 0
        keep = ndimage.binary_opening(out[..., 3] > 0, np.ones((2, 2)))
        out[~keep] = 0
        return out
    skin = base_skin & mask & (color_dist(edit, base) < 40)
    if slot == "top":
        # Plus proche de la peau du visage que des couleurs du vêtement
        # (prises sur le torse de l'édition) : le cuir vert d'un haut n'est
        # pas la peau verte d'un orque.
        pal = face_palette(base, skin_sample)
        new_skin = skin_mask(edit, pal, 34) & bright & mask
        hands_ = int(neck + 0.62 * (feet - neck))
        garment = cloth_palette(edit, neck, hands_, feet, pal, legs=False, width=(0.03, 0.065))
        if len(garment):
            ys_, xs_ = np.nonzero(new_skin)
            px_ = edit[ys_, xs_, None, :3]
            d_face = np.abs(px_ - pal[None]).sum(-1).min(1)
            d_garm = np.abs(px_ - garment[None]).sum(-1).min(1)
            new_skin[ys_[d_garm <= d_face], xs_[d_garm <= d_face]] = False
        skin |= new_skin
    # Aucune peau dans une pièce : là où l'édition dévoile la peau (bras nus,
    # col ouvert), la pièce est transparente et laisse voir le corps et la
    # chemise de base. Les petits restes isolés sont écartés.
    if slot == "top":
        # Tons de peau clairs (bras nus, parfois mouchetés de poils) : le
        # cuir brun, plus sombre, reste.
        face_v = float(np.median(_hue_sat_val(pal[None].astype(float))[2]))
        # Seulement sur les bras, hors du torse (broderies dorées, reflets
        # du métal intacts).
        span = feet - neck
        cx = int(np.mean(np.nonzero(base[..., 3] > 0)[1]))
        chest = np.nonzero(base[int(neck + 0.25 * span), :, 3] > 0)[0]
        half = 0.55 * max(cx - chest[0], chest[-1] - cx) if len(chest) else 0
        arms_zone = np.zeros_like(mask)
        arms_zone[:, : max(0, int(cx - half))] = True
        arms_zone[:, int(cx + half) + 1:] = True
        ys_, xs_ = np.nonzero(mask & ~skin & arms_zone)
        if len(ys_):
            px_ = edit[ys_, xs_, None, :3].astype(int)
            d_f = np.abs(px_ - pal[None].astype(int)).sum(-1).min(1)
            v_ = _hue_sat_val(edit[ys_, xs_][None].astype(float))[2][0]
            drop = (d_f < 45) & (v_ >= 0.8 * face_v)
            skin[ys_[drop], xs_[drop]] = True
        # Bras mouchetés (poils, ombres) : un pixel entouré surtout de peau en
        # fait partie.
        near = ndimage.uniform_filter(skin.astype(float), 7)
        skin |= (near > 0.3) & mask & arms_zone
    out[skin] = 0
    keep = ndimage.binary_opening(out[..., 3] > 0, np.ones((2, 2)))
    keep |= (out[..., 3] > 0) & (luminance(out) < 0.25) & ndimage.binary_dilation(keep, np.ones((3, 3)))
    # Miettes isolées (moins de 25 pixels) écartées.
    parts, n = ndimage.label(keep, np.ones((3, 3)))
    if n:
        sizes = ndimage.sum(keep, parts, range(1, n + 1))
        keep = np.isin(parts, [i + 1 for i, s_ in enumerate(sizes) if s_ >= 25])
    if slot == "top":
        # Morceaux détachés sous la taille (bords du pantalon) écartés.
        parts, _ = ndimage.label(keep, np.ones((3, 3)))
        upper = set(np.unique(parts[: int(neck + 0.45 * (feet - neck))])) - {0}
        keep = np.isin(parts, list(upper))
    out[~keep] = 0
    return out
