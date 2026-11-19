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
        # Teinte dominante des pixels saturés qui ont changé.
        changed = opaque & (color_dist(edit, base) > 80) & (s > 0.45)
        if seed_rows is not None:
            band = np.zeros_like(changed)
            band[top + int((neck - top) * seed_rows[0]): top + int((neck - top) * seed_rows[1])] = True
            changed &= band
        ang = h[changed] * 2 * np.pi
        hue = (np.arctan2(np.sin(ang).mean(), np.cos(ang).mean()) / (2 * np.pi)) % 1
    dh = np.abs(((h - hue + 0.5) % 1) - 0.5)
    key = opaque & (dh < tol) & (s > min_sat) & (v > 0.18)
    labels, n = ndimage.label(key, np.ones((3, 3)))
    if n:
        sizes = ndimage.sum(key, labels, range(1, n + 1))
        key = np.isin(labels, [i + 1 for i, s_ in enumerate(sizes) if s_ >= 6])
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


def body_skin(base: np.ndarray, sample: tuple[int, int], tol: int = 34) -> np.ndarray:
    """Peau d'un corps de base : pixels de la couleur du visage reliés au
    visage ou aux mains (le pantalon brun, de teinte voisine, est écarté)."""
    cand = skin_mask(base, face_palette(base, sample), tol)
    # Ombres de peau, mais pas le tissu brun foncé : au moins 55 % de la
    # luminosité du visage.
    _, _, v = _hue_sat_val(base)
    x, y = sample
    cand &= v > 0.55 * float(np.median(v[y - 1: y + 2, x - 1: x + 2]))
    labels, _ = ndimage.label(cand)
    keep = {labels[sample[1], sample[0]]}
    alpha = base[..., 3] > 0
    ys = np.where(alpha.any(axis=1))[0]
    top, bottom = ys[0], ys[-1]
    # Mains : pixels opaques les plus à gauche et à droite au niveau des hanches.
    for y in range(top + int(0.48 * (bottom - top)), top + int(0.66 * (bottom - top))):
        xs = np.where(alpha[y])[0]
        for x in (xs[0] + 1, xs[-1] - 1):
            if cand[y, x]:
                keep.add(labels[y, x])
    keep.discard(0)
    return np.isin(labels, list(keep))


def outfit_layer(base: np.ndarray, edit: np.ndarray, neck: int,
                 skin_sample: tuple[int, int]) -> np.ndarray:
    """Tenue : tout le corps de l'édition sous le cou. La peau restée nue
    (mains, avant-bras) est transparente."""
    edit = align(prealign(edit, base), base, slice(0, neck - 2),
                 scales=(0.96, 0.98, 1.0, 1.02, 1.04))
    out = np.zeros_like(edit)
    rows = np.zeros(base.shape[:2], bool)
    rows[neck:] = True
    body = (edit[..., 3] > 0) & rows
    out[body] = edit[body]
    near = ndimage.binary_dilation(body_skin(base, skin_sample), np.ones((3, 3)), iterations=2)
    _, _, v = _hue_sat_val(edit)
    x, y = skin_sample
    bright = v > 0.55 * float(np.median(_hue_sat_val(base)[2][y - 1: y + 2, x - 1: x + 2]))
    skin = skin_mask(edit, face_palette(base, skin_sample), 24) & bright & near & body
    # La peau nue est percée : celle du personnage, dessinée dessous, apparaît.
    out[skin] = 0
    return out


# Alphas réservés des corps : zones recolorées dans l'appli.
EYE_ALPHA = 253
LIP_ALPHA = 252
SHADOW_ALPHA = 251
BLUSH_ALPHA = 250


def best_skin(base: np.ndarray, skull: tuple[float, float, float]) -> tuple[np.ndarray, tuple[int, int]]:
    """Peau du corps, avec l'échantillon du visage qui en couvre le plus."""
    x0, t, x1 = skull
    w = x1 - x0
    cx = (x0 + x1) / 2
    best = None
    for fx, fy in ((0, 0.62), (-0.22, 0.62), (0.22, 0.62), (0, 0.3), (0, 0.8)):
        p = (int(cx + fx * w), int(t + fy * w))
        if base[p[1], p[0], 3] == 0:
            continue
        m = body_skin(base, p)
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
