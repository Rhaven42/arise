"""Référence du héros d'ARISE en pixel art 32 bits (96 × 160).

Ce script est la spécification exacte du générateur de l'application
(`lib/features/avatar/domain/pixel/`) : mêmes formes, mêmes couleurs, mêmes
arrondis. Il produit :
- des planches d'aperçu (PNG agrandis) pour régler le style ;
- les images de contrôle des tests Dart (`test/fixtures/pixel/*.rgba`, octets
  RGBA bruts), comparées pixel par pixel au rendu de l'application.

Le personnage est dessiné par code, calque par calque, sur un squelette 2D vu
de face : chaque membre est une capsule dont l'épaisseur dépend du sexe, de la
corpulence et de la musculature. Vêtements et armures réutilisent les mêmes
capsules, un peu plus larges : ils suivent la morphologie sans traverser le
corps. Lumière en haut à gauche, rampes de 4 teintes à décalage de teinte et
contour sombre par calque.

Règles de portabilité (pour un résultat identique en Dart) :
- toute forme est testée au centre du pixel (x + 0,5 ; y + 0,5) ;
- arrondi « au plus proche, demi vers le haut » : rnd(x) = floor(x + 0,5) ;
- aucune bibliothèque de dessin : les masques sont calculés ici.

    python3 tool/pixel/pixel_hero.py apercu <dossier>
    python3 tool/pixel/pixel_hero.py controle test/fixtures/pixel
"""

import json
import math
import os
import sys

import numpy as np

W, H = 96, 160
CX = W / 2
GROUND = 156

YY, XX = np.mgrid[0:H, 0:W].astype(np.float64)
PX = XX + 0.5  # centres des pixels
PY = YY + 0.5


def rnd(x):
    return math.floor(x + 0.5)


# --- Couleurs -----------------------------------------------------------------


def _hls(r, g, b):
    mx, mn = max(r, g, b), min(r, g, b)
    light = (mx + mn) / 2
    if mx == mn:
        return 0.0, light, 0.0
    d = mx - mn
    sat = d / (mx + mn) if light <= 0.5 else d / (2 - mx - mn)
    if mx == r:
        hue = ((g - b) / d) % 6
    elif mx == g:
        hue = (b - r) / d + 2
    else:
        hue = (r - g) / d + 4
    return hue / 6, light, sat


def _rgb(hue, light, sat):
    if sat == 0:
        return light, light, light
    q = light * (1 + sat) if light < 0.5 else light + sat - light * sat
    p = 2 * light - q

    def channel(t):
        t %= 1.0
        if t < 1 / 6:
            return p + (q - p) * 6 * t
        if t < 1 / 2:
            return q
        if t < 2 / 3:
            return p + (q - p) * (2 / 3 - t) * 6
        return p

    return channel(hue + 1 / 3), channel(hue), channel(hue - 1 / 3)


def ramp(argb):
    """Contour + 4 teintes (ombre, ombre douce, base, lumière), ombres froides
    et lumières chaudes."""
    r, g, b = ((argb >> 16) & 255) / 255, ((argb >> 8) & 255) / 255, (argb & 255) / 255
    hue, light, sat = _hls(r, g, b)
    out = []
    for k in (-1.0, -0.5, 0.0, 0.6):
        hh = (hue + (-0.035 if k < 0 else 0.02) * abs(k)) % 1.0
        ll = min(max(light + 0.15 * k, 0.03), 0.93)
        ss = min(max(sat * (1 - 0.15 * k), 0.0), 1.0)
        out.append(tuple(rnd(c * 255) for c in _rgb(hh, ll, ss)))
    outline = tuple(rnd(c * 0.42) for c in out[0])
    return [outline] + out


def darker(color, k):
    return tuple(min(255, rnd(c * k)) for c in color)


# --- Formes -------------------------------------------------------------------


def capsule(p0, p1, r0, r1):
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = x1 - x0, y1 - y0
    length2 = dx * dx + dy * dy
    if length2 < 1e-9:
        t = np.zeros_like(PX)
    else:
        t = np.clip(((PX - x0) * dx + (PY - y0) * dy) / length2, 0.0, 1.0)
    cx, cy = x0 + t * dx, y0 + t * dy
    r = r0 + (r1 - r0) * t
    return (PX - cx) ** 2 + (PY - cy) ** 2 <= r * r


def ellipse(cx, cy, rx, ry):
    return ((PX - cx) / rx) ** 2 + ((PY - cy) / ry) ** 2 <= 1.0


def polygon(points):
    """Pair-impair au centre des pixels."""
    inside = np.zeros((H, W), dtype=bool)
    n = len(points)
    for i in range(n):
        x0, y0 = points[i]
        x1, y1 = points[(i + 1) % n]
        if y0 == y1:
            continue
        cond = (y0 > PY) != (y1 > PY)
        xs = x0 + (PY - y0) * (x1 - x0) / (y1 - y0)
        inside ^= cond & (PX < xs)
    return inside


def rect(x0, y0, x1, y1):
    return (PX >= x0) & (PX < x1) & (PY >= y0) & (PY < y1)


def shift(mask, dx, dy):
    """out[y][x] = mask[y - dy][x - dx] (hors toile = faux)."""
    out = np.zeros_like(mask)
    ys, yd = slice(max(dy, 0), H + min(dy, 0)), slice(max(-dy, 0), H + min(-dy, 0))
    xs, xd = slice(max(dx, 0), W + min(dx, 0)), slice(max(-dx, 0), W + min(-dx, 0))
    out[ys, xs] = mask[yd, xd]
    return out


# --- Toile --------------------------------------------------------------------


class Canvas:
    def __init__(self):
        self.rgb = np.zeros((H, W, 3), dtype=np.uint8)
        self.alpha = np.zeros((H, W), dtype=bool)

    def paint(self, mask, colors, outline=True, flat=False):
        """Calque ombré : [colors] = rampe (contour + 4 teintes)."""
        if not mask.any():
            return
        shade = np.full((H, W), 3, dtype=np.int8)
        if not flat:
            shade[mask & ~shift(mask, -4, -2)] = 2
            shade[mask & ~shift(mask, -2, -1)] = 1
            shade[mask & ~shift(mask, 2, 2)] = 4
        if outline:
            inner = shift(mask, 1, 0) & shift(mask, -1, 0) & shift(mask, 0, 1) & shift(mask, 0, -1)
            shade[mask & ~inner] = 0
        for i, color in enumerate(colors):
            sel = mask & (shade == i)
            self.rgb[sel] = color
        self.alpha |= mask

    def dot(self, x, y, color):
        x, y = int(x), int(y)
        if 0 <= x < W and 0 <= y < H:
            self.rgb[y, x] = color
            self.alpha[y, x] = True

    def rgba(self):
        return np.dstack([self.rgb, np.where(self.alpha, 255, 0).astype(np.uint8)])


# --- Squelette ----------------------------------------------------------------

POSES = {
    # (angle du bras, angle de l'avant-bras par rapport au bras), en degrés,
    # côté droit de l'écran puis côté gauche.
    "a": ((38, 0), (38, 0)),
    "relaxed": ((9, 4), (9, 4)),
    "heroic": ((32, -80), (32, -80)),
    "combat": ((40, -150), (30, -125)),
}


class Rig:
    pass


def make_rig(a):
    fem = a["sex"] == "female"
    c, m = a["corpulence"], a["musculature"]
    race = a["race"]
    bulk = 1.12 if race == "orc" else 1.0
    stretch = 1 + (a["height"] - 0.5) * 0.16 + {"human": 0.0, "elf": 0.06, "orc": 0.04}[race]
    lift = a["breath"]
    posture = a["posture"]
    rig = Rig()
    leg = (54 if fem else 55) * stretch
    torso = (34 if fem else 36) * stretch
    rig.pelvis_y = GROUND - leg
    shoulder_y = rig.pelvis_y - torso - lift - (1 if posture == "upright" else 0)
    rig.head_r = (9.5 if fem else 10.0, 11.5 if fem else 12.0)
    rig.neck = (CX, shoulder_y - 4)
    slouch = 2 if posture == "slouched" else 0
    rig.head = (CX, shoulder_y - 4 - rig.head_r[1] + 1 + slouch)
    rig.chest_y = shoulder_y + 9 - (1 if posture == "arched" else 0)
    rig.waist_y = rig.pelvis_y - 12
    rig.shoulder_y = shoulder_y
    w = {}
    w["shoulder"] = ((10.0 if fem else 12.5) + m * 2.5 + c * 1.5) * bulk - (1 if posture == "slouched" else 0)
    w["hip"] = ((11.0 if fem else 9.0) + c * 5) * bulk
    w["upper_arm"] = ((3.0 if fem else 3.6) + m * 1.6 + c * 1.0) * bulk
    w["fore_arm"] = ((2.6 if fem else 3.0) + m * 1.0 + c * 0.8) * bulk
    w["thigh"] = (5.0 + c * 2.6 + m * 1.2) * bulk
    w["calf"] = ((3.4 if fem else 3.6) + c * 1.2 + m * 0.9) * bulk
    w["neck"] = (3.0 if fem else 3.8) + m * 1.0
    w["waist"] = ((7.5 if fem else 9.5) + c * 6 + m * 1.0) * bulk
    w["chest"] = ((10.5 if fem else 12.5) + c * 3 + m * 2.5) * bulk + (0.5 if posture == "arched" else 0)
    w["bust"] = (2.0 + c * 1.5) if fem else 0.0
    rig.w = w
    upper, fore = 18 * stretch, 17 * stretch
    pose = POSES[a["pose"]]
    rig.shoulder, rig.elbow, rig.wrist = {}, {}, {}
    rig.hip, rig.knee, rig.ankle = {}, {}, {}
    stance = 4 + c * 2 + (3 if a["pose"] in ("heroic", "combat") else 0)
    for s in (-1, 1):
        sx, sy = CX + s * (w["shoulder"] - 1.5), shoulder_y + 3
        a1, a2 = pose[0] if s == 1 else pose[1]
        r1 = math.radians(a1)
        ex, ey = sx + s * math.sin(r1) * upper, sy + math.cos(r1) * upper
        r2 = math.radians(a1 + a2)
        wx, wy = ex + s * math.sin(r2) * fore, ey + math.cos(r2) * fore
        rig.shoulder[s], rig.elbow[s], rig.wrist[s] = (sx, sy), (ex, ey), (wx, wy)
        rig.hip[s] = (CX + s * (w["hip"] * 0.45 + 1), rig.pelvis_y + 3)
        rig.knee[s] = (CX + s * (w["hip"] * 0.42 + stance * 0.5), rig.pelvis_y + leg * 0.5)
        rig.ankle[s] = (CX + s * (w["hip"] * 0.35 + stance), GROUND - 5)
    return rig


def torso_shape(rig, grow=0.0):
    w = rig.w
    sy = rig.shoulder_y + 1
    return polygon([
        (CX - w["shoulder"] - grow * 0.5, sy + 1),
        (CX - w["chest"] - grow, rig.chest_y),
        (CX - w["waist"] - grow, rig.waist_y),
        (CX - w["hip"] - grow, rig.pelvis_y + 4),
        (CX + w["hip"] + grow, rig.pelvis_y + 4),
        (CX + w["waist"] + grow, rig.waist_y),
        (CX + w["chest"] + grow, rig.chest_y),
        (CX + w["shoulder"] + grow * 0.5, sy + 1),
        (CX + w["neck"] + 2, sy - 2 - grow),
        (CX - w["neck"] - 2, sy - 2 - grow),
    ])


def arm_shapes(rig, s, grow=0.0):
    w = rig.w
    upper = capsule(rig.shoulder[s], rig.elbow[s], w["upper_arm"] + grow, w["fore_arm"] + 0.6 + grow)
    fore = capsule(rig.elbow[s], rig.wrist[s], w["fore_arm"] + grow, w["fore_arm"] * 0.75 + grow)
    (ex, ey), (hx, hy) = rig.elbow[s], rig.wrist[s]
    d = math.hypot(hx - ex, hy - ey) or 1.0
    hand = ellipse(hx + (hx - ex) / d * 3, hy + (hy - ey) / d * 3, 2.6 + grow, 3.4 + grow)
    return upper, fore, hand


def short_sleeve(rig, s, grow):
    (sx, sy), (ex, ey) = rig.shoulder[s], rig.elbow[s]
    r = rig.w["upper_arm"] + grow
    return capsule((sx, sy), (sx + (ex - sx) * 0.5, sy + (ey - sy) * 0.5), r, r - 0.2)


def leg_shapes(rig, s, grow=0.0):
    w = rig.w
    thigh = capsule(rig.hip[s], rig.knee[s], w["thigh"] + grow, w["calf"] + 0.8 + grow)
    calf = capsule(rig.knee[s], rig.ankle[s], w["calf"] + 0.6 + grow, w["calf"] * 0.62 + grow)
    ax, ay = rig.ankle[s]
    foot = ellipse(ax + s * 1.2, ay + 3, 3.4 + grow, 2.6 + grow * 0.5) & (PY < GROUND + 0.5)
    return thigh, calf, foot


def head_shape(rig, a, grow=0.0):
    cx, cy = rig.head
    rx, ry = rig.head_r
    jaw = 0.52 + a["faceJaw"] * 0.24
    cheek = rx + (a["faceCheeks"] - 0.5) * 1.2
    skull = ellipse(cx, cy - 0.5, rx + grow, ry * 0.9 + grow)
    face = polygon([
        (cx - cheek - grow, cy - 1), (cx + cheek + grow, cy - 1),
        (cx + rx * jaw + grow, cy + ry * 0.74), (cx, cy + ry + grow * 0.4),
        (cx - rx * jaw - grow, cy + ry * 0.74),
    ])
    return skull | face


# --- Visage -------------------------------------------------------------------

LASH = (34, 22, 20)
WHITE = (238, 230, 218)
SHINE = (255, 255, 250)
TUSK = (236, 226, 200)


def eye_columns(rig, s):
    """Colonnes (intérieure, milieu, extérieure) de l'œil du côté [s]."""
    cx = int(rig.head[0])
    if s > 0:
        return cx + 2, cx + 3, cx + 4
    return cx - 3, cx - 4, cx - 5


def draw_face(cv, rig, a, skin):
    cx, cy = int(rig.head[0]), int(rig.head[1])
    eye = ramp(a["eyeColor"])
    hair = ramp(a["hairColor"])
    brow = darker(hair[2], 0.55)
    ey = cy + 1
    makeup = a["makeupStyle"]
    for s in (-1, 1):
        inner, mid, outer = eye_columns(rig, s)
        for x in (inner, mid, outer):
            cv.dot(x, ey - 1, LASH)
        if a["sex"] == "female" or makeup == 1:
            cv.dot(outer + s, ey - 2, LASH)
        if makeup == 1:
            cv.dot(outer + s, ey - 1, LASH)
            cv.dot(outer, ey + 2, darker(LASH, 1.6))
        cv.dot(inner, ey, WHITE)
        cv.dot(mid, ey, eye[2])
        cv.dot(outer, ey, SHINE)
        cv.dot(inner, ey + 1, WHITE)
        cv.dot(mid, ey + 1, eye[1])
        cv.dot(outer, ey + 1, eye[3])
        draw_brow(cv, a["eyebrowStyle"], s, inner, ey, brow)
        if makeup == 4:
            for k in range(3):
                cv.dot(outer - s * k + s, ey + 3 + k % 2, (170, 52, 34))
                cv.dot(outer - s * k + s, ey + 5 + k % 2, (196, 140, 48))
    # Nez : longueur réglable (1 à 3 pixels d'ombre).
    nose = 1 + rnd(a["faceNose"] * 2)
    for k in range(nose):
        cv.dot(cx - 1, cy + 3 + k, skin[2])
    cv.dot(cx - 1, cy + 3 + nose, skin[1])
    # Bouche : largeur réglable (2 à 4 pixels).
    width = 2 + rnd(a["faceMouth"] * 2)
    color = (160, 72, 74) if a["sex"] == "female" else darker(skin[2], 0.72)
    if makeup == 2:
        color = (176, 34, 52)
    start = cx - 1 - width // 2
    for k in range(width):
        cv.dot(start + k, cy + 8, color)
    if makeup == 2:
        cv.dot(start + width // 2, cy + 9, darker(color, 0.8))
    if a["sex"] == "female" or makeup == 3:
        blush = (226, 120, 112) if makeup == 3 else (230, 140, 130)
        for s in (-1, 1):
            x = cx + s * 6 - (1 if s < 0 else 0)
            cv.dot(x, cy + 5, blush)
            if makeup == 3:
                cv.dot(x + s, cy + 5, blush)
                cv.dot(x, cy + 6, blush)
    if a["race"] == "orc":
        for s in (-1, 1):
            tx = cx + s * 3 - (1 if s < 0 else 0)
            cv.dot(tx, cy + 8, TUSK)
            cv.dot(tx, cy + 7, TUSK)


def draw_brow(cv, style, s, inner, ey, color):
    # cols[0] = côté nez … cols[4] = côté tempe.
    cols = [inner + s * (k - 1) for k in range(5)]
    if style == 1:  # fins
        spots = [(1, 4), (2, 4), (3, 4)]
    elif style == 2:  # épais
        spots = [(k, r) for k in range(4) for r in (4, 3)]
    elif style == 3:  # arqués
        spots = [(0, 3), (1, 4), (2, 5), (3, 4)]
    elif style == 4:  # droits
        spots = [(k, 4) for k in range(5)]
    elif style == 5:  # courts
        spots = [(1, 4), (2, 4)]
    else:  # broussailleux
        spots = [(k, 4) for k in range(5)] + [(0, 5), (2, 5), (1, 3)]
    for k, up in spots:
        cv.dot(cols[k], ey - up, color)


def draw_beard(cv, rig, a):
    style = a["beardStyle"]
    if a["sex"] != "male" or style == 0:
        return
    color = ramp(a["beardColor"] if a["beardColor"] is not None else a["hairColor"])
    cx, cy = rig.head
    rx, ry = rig.head_r
    head = head_shape(rig, a)
    mouth = ellipse(cx - 0.5, cy + 8.5, 2.6, 1.2)
    if style == 1:  # collier
        mask = head & ~head_shape(rig, a, grow=-1.6) & (PY > cy + 3)
    elif style == 2:  # bouc
        mask = head & ellipse(cx - 0.5, cy + ry - 1.5, 2.6, 3.0)
    elif style == 3:  # moustache
        mask = head & (rect(cx - 4, cy + 6, cx + 3, cy + 7.5) | rect(cx - 5, cy + 7, cx - 3, cy + 9) | rect(cx + 2, cy + 7, cx + 4, cy + 9))
    elif style == 4:  # courte
        mask = head & (PY > cy + 4) & ~mouth
    elif style == 5:  # longue tressée
        mask = (head & (PY > cy + 4) & ~mouth) | capsule((cx - 0.5, cy + ry), (cx - 0.5, cy + ry + 9), 2.6, 1.4)
    else:  # favoris
        mask = head & (PY > cy - 3) & (PY < cy + 7) & ((PX < cx - rx + 2.2) | (PX > cx + rx - 2.2))
    cv.paint(mask, color, outline=style in (4, 5))


# --- Cheveux ------------------------------------------------------------------


def draw_hair_back(cv, rig, a, colors):
    cx, cy = rig.head
    rx, ry = rig.head_r
    style = a["hairStyle"]
    if style == 5:
        cv.paint(polygon([(cx - rx - 2, cy - 4), (cx + rx + 2, cy - 4), (cx + rx + 3, cy + 26), (cx - rx - 3, cy + 26)]), colors)
    elif style == 10:
        cv.paint(ellipse(cx, cy + 6, rx + 6, ry + 10), colors)
    elif style == 9:
        cv.paint(polygon([(cx - rx - 2, cy - 4), (cx + rx + 2, cy - 4), (cx + rx + 2, cy + 9), (cx - rx - 2, cy + 9)]), colors)


def draw_hair_front(cv, rig, a, colors):
    cx, cy = rig.head
    rx, ry = rig.head_r
    style = a["hairStyle"]
    top = cy - ry * 0.9
    if style == 7:  # rasé
        cv.paint(ellipse(cx, cy - 3, rx + 0.5, ry * 0.8) & (PY < cy - 4), [colors[1], colors[2], colors[2], colors[3], colors[3]], outline=False)
        return
    if style == 6:  # crête
        cv.paint(ellipse(cx, cy - 3, rx + 0.5, ry * 0.8) & (PY < cy - 4), [colors[0], colors[2], colors[2], colors[2], colors[2]], outline=False)
        cv.paint(polygon([(cx - 3, top + 2), (cx + 3, top + 2), (cx + 2, top - 7), (cx - 2, top - 7)]), colors)
        return
    dome = ellipse(cx, cy - 4.5, rx + 2.2, ry * 0.98)
    strands = (XX % 5 == 0) | (XX % 5 == 2)
    cv.paint((dome & (PY < cy - 5)) | (dome & strands & (PY < cy - 3)), colors)
    if style in (5, 9, 10):
        for s in (-1, 1):
            cv.paint(capsule((cx + s * (rx + 0.8), cy - 4), (cx + s * (rx + 1.6), cy + (8 if style == 9 else 13)), 2.8, 2.0), colors)
    if style == 2:
        cv.paint(capsule((cx + rx, cy - 5), (cx + rx + 4, cy + 18), 2.4, 1.2), colors)
    if style == 3:
        for k in range(5):
            cv.paint(ellipse(cx + rx + 1, cy + 2 + k * 4, 2.4 - k * 0.2, 2.2), colors)
    if style == 8:
        for s in (-1, 1):
            for k in range(5):
                cv.paint(ellipse(cx + s * (rx + 1), cy + 1 + k * 4, 2.2 - k * 0.15, 2.1), colors)
    if style == 4:
        cv.paint(ellipse(cx, top - 1, 4.5, 3.5), colors)


# --- Corps --------------------------------------------------------------------


def draw_body(cv, rig, a, skin):
    w = rig.w
    for s in (-1, 1):
        thigh, calf, foot = leg_shapes(rig, s)
        cv.paint(thigh | calf, skin)
        cv.paint(foot, skin)
    torso = torso_shape(rig)
    cv.paint(torso, skin)
    if w["bust"] > 0:
        for s in (-1, 1):
            cv.paint(ellipse(CX + s * 5.5, rig.chest_y + 1, 4.5 + w["bust"] * 0.4, 3.5 + w["bust"] * 0.5) & torso, skin)
    cv.paint(capsule(rig.neck, (CX, rig.shoulder_y + 2), w["neck"], w["neck"] + 0.5), skin)
    cv.paint(head_shape(rig, a), skin)
    cx, cy = rig.head
    rx = rig.head_r[0]
    ears = a["faceEars"]
    for s in (-1, 1):
        if a["race"] == "elf":
            length = 5 + ears * 4
            cv.paint(polygon([(cx + s * rx, cy - 1), (cx + s * (rx + length), cy - 3 - length * 0.6), (cx + s * rx, cy + 3)]), skin)
        else:
            cv.paint(ellipse(cx + s * (rx + 0.5), cy + 1, 1.4 + ears * 0.8, 2.4 + ears * 0.8), skin)


# --- Équipement ---------------------------------------------------------------

LOOKS = {
    "linen": 0xB49A70, "wool": 0x4A3424, "leather": 0x6A4024, "leather_dark": 0x3A2618,
    "mail": 0x8A9098, "steel": 0xB8C0C8, "gold": 0xD8A848, "teal": 0x2E6A70,
    "red": 0x8A2424, "violet": 0x4A2E6A, "rope": 0x9A7A48, "wood": 0x6A4426,
    "ember": 0xFF7828,
}

SLOT_ITEMS = {
    "head": ("mail_head", "plate_head", "hood_twilight"),
    "shoulders": ("plate_shoulders",),
    "chest": ("leather_chest", "mail_chest", "plate_chest"),
    "hands": ("leather_hands", "mail_hands", "plate_hands"),
    "belt": ("leather_belt", "plate_belt"),
    "legs": ("leather_legs", "mail_legs", "plate_legs"),
    "feet": ("leather_feet", "mail_feet", "plate_feet"),
    "back": ("cape_wanderer", "cape_dawn"),
    "weapon": ("sword_dawn", "staff_ember"),
}


def look(a, item, name):
    """Rampe d'une pièce : la teinture choisie, sinon la couleur d'origine."""
    if item is not None and item in a["dyes"]:
        return ramp(a["dyes"][item])
    return ramp(LOOKS[name])


def worn(a):
    slots = {}
    for item in a["items"]:
        for slot, ids in SLOT_ITEMS.items():
            if item in ids:
                slots[slot] = item
    return slots


def draw_cape(cv, rig, a, slots):
    back = slots.get("back")
    if not back:
        return
    sx = rig.w["shoulder"]
    top = rig.shoulder_y + 2
    length = 62 if back == "cape_wanderer" else 82
    spread = 1.35 if back == "cape_wanderer" else 1.6
    cv.paint(polygon([(CX - sx, top), (CX + sx, top), (CX + sx * spread, top + length), (CX - sx * spread, top + length)]),
             look(a, back, "teal" if back == "cape_wanderer" else "red"))


def draw_lower(cv, rig, a, slots):
    legs, feet = slots.get("legs"), slots.get("feet")
    for s in (-1, 1):
        thigh, calf, _ = leg_shapes(rig, s, grow=0.8)
        if legs == "plate_legs":
            cv.paint(thigh | calf, look(a, legs, "steel"))
            kx, ky = rig.knee[s]
            cv.paint(ellipse(kx, ky, rig.w["calf"] + 2.2, 3.2), look(a, legs, "gold"))
        elif legs == "mail_legs":
            cv.paint(thigh | calf, look(a, legs, "mail"))
        elif legs == "leather_legs":
            cv.paint(thigh | calf, look(a, legs, "leather"))
        else:
            cv.paint((thigh | calf) & (PY < rig.ankle[s][1] - 6), look(a, None, "wool"))
        boot_top = rig.knee[s][1] + (4 if feet == "plate_feet" else 10)
        _, calf2, _ = leg_shapes(rig, s, grow=1.3)
        _, _, foot2 = leg_shapes(rig, s, grow=1.0)
        name = "steel" if feet in ("plate_feet", "mail_feet") else "leather_dark"
        cv.paint((calf2 & (PY >= boot_top)) | foot2, look(a, feet, name))


def draw_upper(cv, rig, a, slots):
    chest = slots.get("chest")
    if chest == "plate_chest":
        cv.paint(torso_shape(rig, grow=1.5) & (PY < rig.pelvis_y + 2), look(a, chest, "steel"))
        cv.paint(rect(CX - 1.5, rig.chest_y - 6, CX + 1.5, rig.waist_y + 4), look(a, chest, "gold"), outline=False)
    elif chest == "mail_chest":
        cv.paint(torso_shape(rig, grow=1.2) & (PY < rig.pelvis_y + 12), look(a, chest, "mail"))
    elif chest == "leather_chest":
        cv.paint(torso_shape(rig, grow=1.0) & (PY < rig.pelvis_y + 6), look(a, chest, "leather"))
        cv.paint(rect(CX - 0.5, rig.shoulder_y + 2, CX + 0.5, rig.chest_y + 4), look(a, None, "leather_dark"), outline=False)
    else:
        cv.paint(torso_shape(rig, grow=1.0) & (PY < rig.pelvis_y + 10), look(a, None, "linen"))
    belt = slots.get("belt")
    band = torso_shape(rig, grow=1.8) & (PY >= rig.pelvis_y - 3) & (PY < rig.pelvis_y + 1)
    if belt == "plate_belt":
        cv.paint(torso_shape(rig, grow=2.5) & (PY >= rig.pelvis_y - 3) & (PY < rig.pelvis_y + 10), look(a, belt, "gold"))
    elif belt == "leather_belt":
        cv.paint(band, look(a, belt, "leather_dark"))
        cv.paint(ellipse(CX, rig.pelvis_y - 1.5, 2.0, 2.0), look(a, belt, "gold"))
    else:
        cv.paint(band & (PY >= rig.pelvis_y - 2), look(a, None, "rope"), outline=False)


def draw_arms(cv, rig, a, slots, skin):
    chest, hands, shoulders = slots.get("chest"), slots.get("hands"), slots.get("shoulders")
    for s in (-1, 1):
        upper, fore, hand = arm_shapes(rig, s)
        cv.paint(upper | fore, skin)
        _, f2, h2 = arm_shapes(rig, s, grow=0.9)
        if chest == "mail_chest":
            cv.paint(arm_shapes(rig, s, grow=0.9)[0], look(a, chest, "mail"))
        elif chest != "plate_chest":
            cv.paint(short_sleeve(rig, s, 1.2), look(a, chest, "leather" if chest == "leather_chest" else "linen"))
        if hands == "plate_hands":
            cv.paint(f2 | h2, look(a, hands, "steel"))
        elif hands in ("mail_hands", "leather_hands"):
            (ex, ey), (wx, wy) = rig.elbow[s], rig.wrist[s]
            cuff = capsule((ex + (wx - ex) * 0.55, ey + (wy - ey) * 0.55), (wx, wy), rig.w["fore_arm"] + 1.0, rig.w["fore_arm"] * 0.75 + 1.0)
            cv.paint(h2 | cuff, look(a, hands, "mail" if hands == "mail_hands" else "leather_dark"))
        else:
            cv.paint(hand, skin)
        if shoulders == "plate_shoulders":
            sx, sy = rig.shoulder[s]
            cv.paint(ellipse(sx + s * 1.5, sy + 1, rig.w["upper_arm"] + 3.5, 5.5) & (PY < sy + 5.5), look(a, shoulders, "gold"))


def draw_head_gear(cv, rig, a, slots):
    head = slots.get("head")
    cx, cy = rig.head
    rx, ry = rig.head_r
    if head == "plate_head":
        helm = ellipse(cx, cy - 1, rx + 2, ry + 1.5) & (PY < cy + 6.5)
        slit = rect(cx - rx + 1.5, cy - 0.5, cx + rx - 1.5, cy + 3)
        cv.paint(helm & ~slit, look(a, head, "steel"))
        cv.paint(rect(cx - 1, cy - ry - 4, cx + 1, cy - 3), look(a, head, "gold"), outline=False)
        return True
    if head == "mail_head":
        coif = (ellipse(cx, cy, rx + 2, ry + 2) & ~ellipse(cx, cy + 3, rx - 2.2, ry - 2.5)) | (ellipse(cx, cy - 3, rx + 2, ry - 1) & (PY < cy - 3))
        cv.paint(coif & (PY < cy + ry + 3.5), look(a, head, "mail"))
        return True
    if head == "hood_twilight":
        opening = ellipse(cx, cy + 3, rx - 1.5, ry - 2)
        hood = (ellipse(cx, cy - 1, rx + 3.5, ry + 3) & ~opening) | (ellipse(cx, cy - 4, rx + 3, ry) & (PY < cy - 4))
        drape = polygon([(cx - rx - 3, cy + 4), (cx + rx + 3, cy + 4), (cx + rx + 8, cy + ry + 8), (cx - rx - 8, cy + ry + 8)]) & ~opening
        cv.paint(hood | drape, look(a, head, "violet"))
        return True
    return False


def draw_weapon(cv, rig, a, slots):
    weapon = slots.get("weapon")
    if not weapon:
        return
    hx, hy = rig.wrist[1]
    hx += 1
    if weapon == "sword_dawn":
        cv.paint(polygon([(hx - 1.5, hy + 4), (hx + 1.5, hy + 4), (hx + 1.5, hy + 40), (hx, hy + 44), (hx - 1.5, hy + 40)]), look(a, weapon, "steel"))
        cv.paint(rect(hx - 5, hy + 1, hx + 5, hy + 3.5), look(a, None, "gold"))
        cv.paint(capsule((hx, hy - 6), (hx, hy), 1.3, 1.3), look(a, None, "leather_dark"))
    else:
        cv.paint(capsule((hx, hy - 34), (hx, hy + 30), 1.5, 1.5), look(a, weapon, "wood"))
        cv.paint(ellipse(hx, hy - 37, 3.5, 4.0), look(a, None, "ember"))


DEFAULTS = {
    "sex": "female", "race": "human", "corpulence": 0.5, "musculature": 0.5,
    "height": 0.5, "skinColor": 0xD9A982, "hairColor": 0x6A4026,
    "eyeColor": 0x5A3A22, "beardColor": None, "hairStyle": 1, "eyebrowStyle": 1,
    "beardStyle": 0, "makeupStyle": 0, "faceJaw": 0.5, "faceNose": 0.5,
    "faceMouth": 0.5, "faceCheeks": 0.5, "faceEars": 0.5, "pose": "relaxed",
    "posture": "neutral", "breath": 0, "items": [], "dyes": {},
}


def render(appearance):
    """Image RGBA (96 × 160) d'une apparence (dictionnaire, cf. DEFAULTS)."""
    a = {**DEFAULTS, **appearance}
    cv = Canvas()
    rig = make_rig(a)
    skin = ramp(a["skinColor"])
    hair = ramp(a["hairColor"])
    slots = worn(a)
    draw_cape(cv, rig, a, slots)
    if slots.get("head") is None and a["hairStyle"]:
        draw_hair_back(cv, rig, a, hair)
    draw_body(cv, rig, a, skin)
    draw_lower(cv, rig, a, slots)
    draw_upper(cv, rig, a, slots)
    draw_face(cv, rig, a, skin)
    draw_beard(cv, rig, a)
    if not draw_head_gear(cv, rig, a, slots) and a["hairStyle"]:
        draw_hair_front(cv, rig, a, hair)
    draw_arms(cv, rig, a, slots, skin)
    draw_weapon(cv, rig, a, slots)
    return cv.rgba()


# --- Planches et images de contrôle -------------------------------------------

LEATHER = ["leather_chest", "leather_hands", "leather_belt", "leather_legs", "leather_feet"]
MAIL = ["mail_head", "mail_chest", "mail_hands", "mail_legs", "mail_feet", "cape_wanderer"]
PLATE = ["plate_head", "plate_shoulders", "plate_chest", "plate_hands", "plate_belt", "plate_legs", "plate_feet", "cape_dawn", "sword_dawn"]

# Cas de contrôle partagés avec les tests Dart (test/fixtures/pixel/cases.json).
CASES = {
    "default": {},
    "male_mohawk": {"sex": "male", "hairStyle": 6, "skinColor": 0xA86E45, "hairColor": 0x1C1512, "beardStyle": 3, "eyebrowStyle": 2},
    "elf_long": {"race": "elf", "hairStyle": 5, "hairColor": 0xD8B26E, "skinColor": 0xF3D9C9, "corpulence": 0.25, "eyeColor": 0x4C7A3E, "makeupStyle": 1, "faceEars": 1.0},
    "orc_mane": {"sex": "male", "race": "orc", "skinColor": 0x6E8B4A, "hairStyle": 10, "hairColor": 0x1C1512, "musculature": 1.0, "corpulence": 0.75, "beardStyle": 5, "posture": "upright"},
    "leather_ponytail": {"items": LEATHER, "hairStyle": 2, "makeupStyle": 4, "pose": "heroic", "eyebrowStyle": 3},
    "mail_elf": {"sex": "male", "race": "elf", "items": MAIL, "skinColor": 0xC48A5C, "pose": "a", "faceJaw": 1.0},
    "plate_knight": {"sex": "male", "items": PLATE, "musculature": 0.75, "pose": "combat", "breath": 1},
    "hood_orc": {"race": "orc", "skinColor": 0x5E6A6E, "hairStyle": 8, "hairColor": 0xE8E4DE, "items": ["hood_twilight", "cape_wanderer", "staff_ember", "leather_hands", "leather_legs", "leather_feet", "leather_belt"], "dyes": {"cape_wanderer": 0x5A3A7A}, "posture": "slouched", "height": 0.0, "makeupStyle": 3},
}


def planche(cases, path, scale=4):
    from PIL import Image

    tiles = [Image.fromarray(render(c), "RGBA").resize((W * scale, H * scale), Image.NEAREST) for c in cases]
    out = Image.new("RGBA", (W * scale * len(tiles), H * scale), (28, 22, 18, 255))
    for i, tile in enumerate(tiles):
        out.alpha_composite(tile, (i * W * scale, 0))
    out.save(path)


if __name__ == "__main__":
    mode, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    if mode == "controle":
        for name, case in CASES.items():
            with open(os.path.join(out_dir, name + ".rgba"), "wb") as f:
                f.write(render(case).tobytes())
        with open(os.path.join(out_dir, "cases.json"), "w") as f:
            json.dump(CASES, f, indent=2)
            f.write("\n")
    else:
        planche(list(CASES.values()), os.path.join(out_dir, "cas.png"))
        planche(
            [{"hairStyle": i, "sex": "male" if i % 2 else "female", "eyebrowStyle": (i % 6) + 1, "beardStyle": (i % 7) if i % 2 else 0} for i in range(1, 11)],
            os.path.join(out_dir, "coiffures.png"),
            scale=3,
        )
