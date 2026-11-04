"""Génère les silhouettes SVG face/dos d'ARISE (zones musculaires originales)."""
import json, sys

W = 200

def mirror(pts):
    return [(2 * 100 - x, y) for x, y in pts]

def smooth(pts, closed=True):
    """Catmull-Rom → courbes de Bézier cubiques (commandes M, C, Z absolues)."""
    n = len(pts)
    d = [f"M{pts[0][0]:.1f} {pts[0][1]:.1f}"]
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n]; p1 = pts[i]; p2 = pts[(i + 1) % n]; p3 = pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d.append(f"C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f}")
    if closed:
        d.append("Z")
    return " ".join(d)

# Demi-contour du corps (côté droit de l'image, x >= 100), du sommet au pied.
HALF_OUTLINE = [
    (100, 13), (114, 18), (120, 34), (117, 52), (110, 62), (110, 74),
    (130, 80), (148, 84), (156, 96), (157, 118), (156, 150), (160, 190),
    (158, 226), (156, 248), (148, 252), (146, 228), (140, 192), (140, 160),
    (138, 128), (134, 150), (130, 185), (135, 214), (136, 250), (130, 300),
    (126, 330), (127, 360), (122, 410), (126, 434), (112, 440), (108, 420),
    (110, 380), (106, 340), (107, 300), (103, 250), (100, 240),
]

def outline():
    right = HALF_OUTLINE
    left = list(reversed(mirror(right[1:-1])))
    return smooth(right + left)

FRONT = {
    "sternocleidomastoid": [(103, 60), (107, 59), (110, 74), (106, 78)],
    "pectoralis_upper": [(102, 86), (124, 84), (131, 92), (118, 100), (102, 101)],
    "pectoralis_mid_lower": [(102, 103), (120, 102), (131, 97), (131, 114), (120, 124), (102, 123)],
    "deltoid_anterior": [(132, 84), (142, 85), (146, 98), (140, 110), (135, 98)],
    "deltoid_lateral": [(144, 84), (154, 92), (156, 110), (148, 114), (147, 98)],
    "biceps_brachii": [(140, 113), (149, 115), (150, 140), (146, 156), (140, 150), (138, 128)],
    "brachialis": [(150, 126), (155, 130), (155, 154), (149, 156), (151, 142)],
    "brachioradialis": [(147, 160), (156, 160), (157, 182), (150, 196), (147, 180)],
    "forearm_flexors": [(140, 162), (146, 162), (147, 186), (151, 222), (145, 226), (141, 196)],
    "rectus_abdominis": [(89, 126), (111, 126), (114, 160), (112, 198), (100, 204), (88, 198), (86, 160)],
    "obliques": [(118, 130), (131, 124), (131, 160), (128, 190), (118, 194), (120, 160)],
    "transversus_abdominis": [(114, 199), (128, 196), (131, 210), (118, 218), (112, 212)],
    "serratus_anterior": [(131, 110), (137, 116), (136, 132), (130, 126)],
    "hip_flexors": [(108, 214), (118, 220), (120, 236), (110, 240), (106, 228)],
    "adductors": [(102, 240), (110, 243), (114, 270), (110, 300), (104, 300)],
    "abductors": [(128, 206), (135, 214), (136, 244), (130, 240)],
    "quadriceps": [(121, 232), (134, 246), (131, 290), (126, 322), (114, 322), (112, 280), (116, 246)],
    "tibialis_anterior": [(117, 338), (124, 338), (123, 376), (119, 404), (116, 404), (115, 370)],
}

BACK = {
    "trapezius_upper": [(102, 62), (108, 64), (128, 80), (114, 90), (102, 88)],
    "trapezius_mid_lower": [(102, 90), (109, 92), (111, 104), (106, 134), (102, 146)],
    "rhomboids": [(113, 106), (119, 105), (121, 118), (114, 127), (112, 118)],
    "rotator_cuff": [(116, 92), (130, 88), (134, 100), (122, 104)],
    "teres_major": [(124, 106), (136, 102), (138, 114), (126, 116)],
    "latissimus_dorsi": [(112, 132), (122, 120), (138, 117), (136, 150), (126, 182), (110, 184), (108, 150)],
    "deltoid_posterior": [(130, 82), (146, 84), (156, 98), (150, 112), (138, 102)],
    "triceps_brachii": [(141, 112), (152, 114), (155, 140), (150, 156), (142, 154), (139, 132)],
    "forearm_extensors": [(141, 160), (155, 160), (157, 186), (151, 222), (145, 224), (141, 190)],
    "erector_spinae": [(101, 152), (107, 148), (110, 186), (108, 202), (101, 204)],
    "gluteus_medius": [(114, 202), (130, 198), (135, 216), (122, 218)],
    "gluteus_maximus": [(102, 212), (120, 218), (135, 222), (134, 248), (118, 258), (102, 252)],
    "hamstrings": [(104, 260), (118, 262), (133, 254), (128, 316), (112, 320), (106, 300)],
    "gastrocnemius": [(108, 332), (126, 332), (127, 352), (121, 374), (112, 374), (107, 352)],
    "soleus": [(112, 376), (121, 376), (121, 400), (116, 410), (112, 400)],
}

CENTRAL = {"rectus_abdominis"}

def build(zones, view):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} 450" data-view="{view}">',
           f'  <path id="outline" d="{outline()}"/>']
    for mid, pts in zones.items():
        paths = [smooth(pts)]
        if mid in CENTRAL:
            # zone centrale : on la redessine symétrique en une seule forme
            right = [p for p in pts]
            paths = [smooth(pts)]
        else:
            paths.append(smooth(list(reversed(mirror(pts)))))
        out.append(f'  <g id="{mid}">')
        for d in paths:
            out.append(f'    <path d="{d}"/>')
        out.append('  </g>')
    out.append('</svg>')
    return "\n".join(out) + "\n"

if __name__ == "__main__":
    dest = sys.argv[1]
    open(f"{dest}/body_front.svg", "w").write(build(FRONT, "front"))
    open(f"{dest}/body_back.svg", "w").write(build(BACK, "back"))
    print(len(FRONT), len(BACK))
