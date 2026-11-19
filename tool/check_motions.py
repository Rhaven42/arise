"""Contrôle des mouvements du mannequin sur tout le cycle (même logique que
l'appli, figure_motion.dart) : sol, sens de flexion, à-coups, appuis.

    python3 tool/check_motions.py assets/animations/motions.json [mouvement…]
"""
import json
import math
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from motions import DEFAULT, L, joints  # noqa: E402

FRAMES = 480


def pose_at(m, t):
    keys = m["keys"]
    total = sum(k["hold"] for k in keys)
    elapsed = (t % 1) * total
    for i, frm in enumerate(keys):
        if elapsed <= frm["hold"] or i == len(keys) - 1:
            to = keys[(i + 1) % len(keys)]
            raw = 0 if frm["hold"] == 0 else min(1, max(0, elapsed / frm["hold"]))
            k = 0.5 - math.cos(raw * math.pi) / 2
            lerp = lambda a, b: a + (b - a) * k
            ang = {n: lerp(frm["angles"][n], to["angles"].get(n, frm["angles"][n])) for n in frm["angles"]}
            if frm["anchor"] == to["anchor"]:
                tgt = (lerp(frm["target"][0], to["target"][0]), lerp(frm["target"][1], to["target"][1]))
                free = joints(ang, m["view"])[frm["anchor"]]
                return (tgt[0] - free[0], tgt[1] - free[1]), ang
            return (lerp(frm["root"][0], to["root"][0]), lerp(frm["root"][1], to["root"][1])), ang
        elapsed -= frm["hold"]
    return tuple(keys[0]["root"]), keys[0]["angles"]


def wrap(a):
    return (a + 540) % 360 - 180


def ground_level(m):
    """Ligne du sol dessinée par l'appli (FigurePainter) : sous le point le
    plus bas du mouvement, ou à y = 0."""
    bottom = max(
        p[1] + L["head_r"] + 0.06
        for i in range(24)
        for p in joints(pose_at(m, i / 24)[1], m["view"], pose_at(m, i / 24)[0]).values())
    for prop in m.get("props", []):
        if prop["type"] == "box":
            bottom = max(bottom, prop["rect"][3])
    return max(min(0, bottom), bottom - 0.06)


def check(mid, m):
    faults = []
    prev = None
    steps = []
    ground = ground_level(m)
    for i in range(FRAMES + 1):
        root, ang = pose_at(m, i / FRAMES)
        j = joints(ang, m["view"], root)
        if m.get("ground", True):
            for n, p in j.items():
                lim = ground - L["head_r"] if n == "head" else ground
                if p[1] > lim + 0.005:
                    faults.append(("sol", i, n, round(p[1], 3)))
        if m["view"] == "side" and i % 4 == 0:
            for s in "nf":
                knee = wrap(ang[f"sh_{s}"] - ang[f"th_{s}"])
                if knee > 6 or knee < -165:
                    faults.append(("genou", i, s, round(knee)))
                elbow = wrap(ang[f"fa_{s}"] - ang[f"ua_{s}"])
                if elbow < -12 or elbow > 155:
                    faults.append(("coude", i, s, round(elbow)))
        if prev:
            steps.append(max(math.dist(j[n], prev[n]) for n in j))
        prev = j
    # À-coup : un pas bien plus grand que ses voisins (rupture, pas vitesse).
    for i in range(1, len(steps) - 1):
        nb = max(steps[i - 1], steps[i + 1], 1e-4)
        if steps[i] > 0.02 and steps[i] > 2.5 * nb:
            faults.append(("à-coup", i, "", round(steps[i], 3)))
    return faults


if __name__ == "__main__":
    data = json.load(open(sys.argv[1]))
    only = sys.argv[2:]
    bad = 0
    for mid, m in data.items():
        if only and mid not in only:
            continue
        f = check(mid, m)
        if f:
            bad += 1
            kinds = {}
            for k in f:
                kinds.setdefault(k[0], []).append(k)
            summary = "; ".join(
                f"{k} ×{len(v)} (ex. image {v[0][1]} {v[0][2]} {v[0][3]}, pire {max((x[3] for x in v), key=abs)})"
                for k, v in kinds.items())
            print(f"{mid}: {summary}")
    print(bad, "mouvement(s) en défaut sur", len(data) if not only else len(only))
