"""Mouvements originaux des exercices (figure 2D), avec contrôle visuel."""
import json, math, sys
from PIL import Image, ImageDraw

L = dict(torso=0.55, neck=0.17, head_r=0.11, upper_arm=0.30, forearm=0.27,
         thigh=0.45, shin=0.43, foot=0.13)
SHOULDER_AT = 0.92  # position de l'épaule le long du tronc
FRONT_SHOULDER_DX = 0.17
FRONT_HIP_DX = 0.08

def d(a):
    r = math.radians(a)
    return (math.sin(r), math.cos(r))

def add(p, a, l):
    v = d(a); return (p[0] + v[0] * l, p[1] + v[1] * l)

DEFAULT = dict(t=180, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=0, sh_n=0,
               th_f=0, sh_f=0, ft_n=90, ft_f=90)

def joints(k, view, root=(0.0, 0.0)):
    k = {**DEFAULT, **k}
    j = {"root": root}
    neck = add(root, k["t"], L["torso"])
    j["neck"] = neck
    j["head"] = add(neck, k["t"], L["neck"])
    sh = add(root, k["t"], L["torso"] * SHOULDER_AT)
    for side, sgn in (("n", 1), ("f", -1)):
        mir = (lambda a: a) if view == "side" else (lambda a, s=sgn: a * s)
        s0 = sh if view == "side" else (sh[0] + sgn * FRONT_SHOULDER_DX, sh[1])
        hip = root if view == "side" else (root[0] + sgn * FRONT_HIP_DX, root[1])
        j[f"shoulder_{side}"] = s0
        j[f"elbow_{side}"] = add(s0, mir(k[f"ua_{side}"]), L["upper_arm"])
        j[f"hand_{side}"] = add(j[f"elbow_{side}"], mir(k[f"fa_{side}"]), L["forearm"])
        j[f"hip_{side}"] = hip
        j[f"knee_{side}"] = add(hip, mir(k[f"th_{side}"]), L["thigh"])
        j[f"ankle_{side}"] = add(j[f"knee_{side}"], mir(k[f"sh_{side}"]), L["shin"])
        ft = k[f"ft_{side}"] if view == "side" else 0
        j[f"toe_{side}"] = add(j[f"ankle_{side}"], ft, L["foot"] if view == "side" else 0.05)
    return j

def solve_root(k, view):
    """Place la racine pour que l'articulation d'ancrage tombe sur sa cible."""
    anchor, target = k.get("anchor", ("root", (0, 0)))
    j = joints(k, view)
    p = j[anchor]
    return (round(target[0] - p[0], 4), round(target[1] - p[1], 4))

S = {}  # debout, bras le long du corps
SQUAT_LOW = dict(t=148, th_n=82, sh_n=-22, th_f=82, sh_f=-22, ua_n=90, fa_n=90, ua_f=90, fa_f=90)
PLANK_HANDS = dict(t=109.4, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=-70.6, sh_n=-70.6, th_f=-70.6, sh_f=-70.6, ft_n=15, ft_f=15)
PUSH_DOWN = dict(t=93.7, ua_n=-100, fa_n=20, ua_f=-100, fa_f=20, th_n=-86.3, sh_n=-86.3, th_f=-86.3, sh_f=-86.3, ft_n=15, ft_f=15)

def kf(pose, anchor="ankle_n", target=(0, 0), hold=1.0):
    return dict(pose=pose, anchor=(anchor, target), hold=hold)

MOTIONS = {
    "squat": dict(view="side", keys=[kf(S), kf(SQUAT_LOW)]),
    "lunge": dict(view="side", keys=[
        kf(dict(th_n=22, sh_n=0, th_f=-20, sh_f=-25)),
        kf(dict(th_n=88, sh_n=-2, th_f=-12, sh_f=-92, ft_f=-170))]),
    "push_up": dict(view="side", keys=[
        kf(PLANK_HANDS, "toe_n"), kf(PUSH_DOWN, "toe_n")]),
    "dips": dict(view="side", keys=[
        kf(dict(th_n=-10, sh_n=-70, th_f=-10, sh_f=-70), "hand_n"),
        kf(dict(ua_n=-95, fa_n=0, ua_f=-95, fa_f=0, t=172, th_n=-5, sh_n=-75, th_f=-5, sh_f=-75), "hand_n")]),
    "pull_up": dict(view="side", keys=[
        kf(dict(ua_n=180, fa_n=180, ua_f=180, fa_f=180, th_n=8, sh_n=-25, th_f=8, sh_f=-25), "hand_n"),
        kf(dict(ua_n=15, fa_n=175, ua_f=15, fa_f=175, th_n=15, sh_n=-30, th_f=15, sh_f=-30), "hand_n")]),
    "row": dict(view="side", keys=[
        kf(dict(t=118, th_n=18, sh_n=-12, th_f=18, sh_f=-12, ua_n=0, fa_n=0, ua_f=0, fa_f=0)),
        kf(dict(t=118, th_n=18, sh_n=-12, th_f=18, sh_f=-12, ua_n=-70, fa_n=-5, ua_f=-70, fa_f=-5))]),
    "overhead_press": dict(view="side", keys=[
        kf(dict(ua_n=25, fa_n=175, ua_f=25, fa_f=175)),
        kf(dict(ua_n=178, fa_n=180, ua_f=178, fa_f=180))]),
    "lateral_raise": dict(view="front", keys=[
        kf(dict(ua_n=8, fa_n=10, ua_f=8, fa_f=10), "root"),
        kf(dict(ua_n=88, fa_n=92, ua_f=88, fa_f=92), "root")]),
    "biceps_curl": dict(view="side", keys=[
        kf(dict(ua_n=2, fa_n=5, ua_f=2, fa_f=5)),
        kf(dict(ua_n=-5, fa_n=160, ua_f=-5, fa_f=160))]),
    "romanian_deadlift": dict(view="side", keys=[
        kf(S), kf(dict(t=100, th_n=8, sh_n=-4, th_f=8, sh_f=-4, ua_n=0, fa_n=0, ua_f=0, fa_f=0))]),
    "glute_bridge": dict(view="side", keys=[
        kf(dict(t=-90, ua_n=-88, fa_n=-88, ua_f=-88, fa_f=-88, th_n=132, sh_n=-45, th_f=132, sh_f=-45, ft_n=90, ft_f=90), "neck", (-0.05, 0)),
        kf(dict(t=-68, ua_n=-80, fa_n=-80, ua_f=-80, fa_f=-80, th_n=103, sh_n=-44, th_f=103, sh_f=-44, ft_n=90, ft_f=90), "neck", (-0.05, 0))]),
    "calf_raise": dict(view="side", keys=[
        kf(dict(ft_n=90, ft_f=90), "toe_n"),
        kf(dict(ft_n=40, ft_f=40), "toe_n")]),
    "plank": dict(view="side", keys=[
        kf(dict(t=97.9, ua_n=0, fa_n=90, ua_f=0, fa_f=90, th_n=-82.1, sh_n=-82.1, th_f=-82.1, sh_f=-82.1, ft_n=15, ft_f=15), "toe_n", hold=1.6),
        kf(dict(t=98.5, ua_n=0, fa_n=90, ua_f=0, fa_f=90, th_n=-81.5, sh_n=-81.5, th_f=-81.5, sh_f=-81.5, ft_n=15, ft_f=15), "toe_n", hold=1.6)]),
    "side_plank": dict(view="front", keys=[
        kf(dict(t=125, ua_n=180, fa_n=180, ua_f=0, fa_f=90, th_n=-55, sh_n=-55, th_f=-55, sh_f=-55), "ankle_n", hold=1.6),
        kf(dict(t=122, ua_n=180, fa_n=180, ua_f=0, fa_f=90, th_n=-58, sh_n=-58, th_f=-58, sh_f=-58), "ankle_n", hold=1.6)]),
    "crunch": dict(view="side", keys=[
        kf(dict(t=-90, ua_n=-80, fa_n=60, ua_f=-80, fa_f=60, th_n=140, sh_n=30, th_f=140, sh_f=30), "root"),
        kf(dict(t=-122, ua_n=-110, fa_n=30, ua_f=-110, fa_f=30, th_n=140, sh_n=30, th_f=140, sh_f=30), "root")]),
    "leg_raise": dict(view="side", keys=[
        kf(dict(t=-90, ua_n=-90, fa_n=-90, ua_f=-90, fa_f=-90, th_n=95, sh_n=95, th_f=95, sh_f=95, ft_n=180, ft_f=180), "root"),
        kf(dict(t=-90, ua_n=-90, fa_n=-90, ua_f=-90, fa_f=-90, th_n=175, sh_n=175, th_f=175, sh_f=175, ft_n=-90, ft_f=-90), "root")]),
    "superman": dict(view="side", keys=[
        kf(dict(t=90, ua_n=90, fa_n=90, ua_f=90, fa_f=90, th_n=-90, sh_n=-90, th_f=-90, sh_f=-90, ft_n=-90, ft_f=-90), "root"),
        kf(dict(t=106, ua_n=108, fa_n=110, ua_f=108, fa_f=110, th_n=-102, sh_n=-104, th_f=-102, sh_f=-104, ft_n=-100, ft_f=-100), "root")]),
    "burpee": dict(view="side", keys=[
        kf(S, hold=0.8),
        kf(dict(t=140, th_n=115, sh_n=-35, th_f=115, sh_f=-35, ua_n=15, fa_n=5, ua_f=15, fa_f=5, ft_n=110, ft_f=110), hold=0.8),
        kf(PLANK_HANDS, "hand_n", (0.55, 0), hold=0.8),
        kf(dict(t=140, th_n=115, sh_n=-35, th_f=115, sh_f=-35, ua_n=15, fa_n=5, ua_f=15, fa_f=5, ft_n=110, ft_f=110), hold=0.8),
        kf(dict(ua_n=175, fa_n=180, ua_f=175, fa_f=180, ft_n=60, ft_f=60), "ankle_n", (0, -0.18), hold=0.8)]),
    "jumping_jack": dict(view="front", keys=[
        kf(dict(ua_n=6, fa_n=8, ua_f=6, fa_f=8, th_n=3, sh_n=3, th_f=3, sh_f=3), "root", (0, 0)),
        kf(dict(ua_n=160, fa_n=170, ua_f=160, fa_f=170, th_n=20, sh_n=22, th_f=20, sh_f=22), "root", (0, -0.06))]),
    "mountain_climber": dict(view="side", keys=[
        kf({**PLANK_HANDS, "th_n": 55, "sh_n": -40, "ft_n": 150}, "hand_n"),
        kf({**PLANK_HANDS, "th_f": 55, "sh_f": -40, "ft_f": 150}, "hand_n")]),
    "walking": dict(view="side", keys=[
        kf(dict(th_n=24, sh_n=12, th_f=-20, sh_f=-35, ua_n=-22, fa_n=-10, ua_f=22, fa_f=35), "root"),
        kf(dict(th_n=2, sh_n=-8, th_f=2, sh_f=-8, ua_n=0, fa_n=8, ua_f=0, fa_f=8), "root", (0, -0.02)),
        kf(dict(th_f=24, sh_f=12, th_n=-20, sh_n=-35, ua_f=-22, fa_f=-10, ua_n=22, fa_n=35), "root"),
        kf(dict(th_n=2, sh_n=-8, th_f=2, sh_f=-8, ua_n=0, fa_n=8, ua_f=0, fa_f=8), "root", (0, -0.02))]),
    "running": dict(view="side", keys=[
        kf(dict(t=170, th_n=55, sh_n=0, th_f=-30, sh_f=-95, ua_n=-45, fa_n=40, ua_f=50, fa_f=140), "root"),
        kf(dict(t=170, th_f=55, sh_f=0, th_n=-30, sh_n=-95, ua_f=-45, fa_f=40, ua_n=50, fa_n=140), "root", (0, -0.05))]),
    "cycling": dict(view="side", keys=[
        kf(dict(t=150, ua_n=60, fa_n=85, ua_f=60, fa_f=85, th_n=95, sh_n=10, th_f=40, sh_f=-15), "root"),
        kf(dict(t=150, ua_n=60, fa_n=85, ua_f=60, fa_f=85, th_n=65, sh_n=-25, th_f=70, sh_f=30), "root"),
        kf(dict(t=150, ua_n=60, fa_n=85, ua_f=60, fa_f=85, th_f=95, sh_f=10, th_n=40, sh_n=-15), "root"),
        kf(dict(t=150, ua_n=60, fa_n=85, ua_f=60, fa_f=85, th_f=65, sh_f=-25, th_n=70, sh_n=30), "root")]),
    "jump_rope": dict(view="front", keys=[
        kf(dict(ua_n=15, fa_n=70, ua_f=15, fa_f=70, th_n=2, sh_n=0, th_f=2, sh_f=0), "root", (0, 0)),
        kf(dict(ua_n=18, fa_n=55, ua_f=18, fa_f=55, th_n=2, sh_n=0, th_f=2, sh_f=0), "root", (0, -0.07))]),
}

def export():
    out = {}
    for mid, m in MOTIONS.items():
        keys = []
        for k in m["keys"]:
            pose = {**DEFAULT, **k["pose"]}
            pose_with = {**pose, "anchor": k["anchor"]}
            root = solve_root(pose_with, m["view"])
            anchor, target = k["anchor"]
            keys.append({"root": list(root), "hold": k["hold"], "anchor": anchor,
                         "target": [float(target[0]), float(target[1])],
                         "angles": {a: pose[a] for a in DEFAULT}})
        out[mid] = {"view": m["view"], "keys": keys}
    return out

def draw_sheet(data, path):
    names = list(data)
    cols = 6; cw, ch = 220, 230
    rows_needed = 0
    cells = [(n, i) for n in names for i in range(len(data[n]["keys"]))]
    rows = math.ceil(len(cells) / cols)
    img = Image.new("RGB", (cols * cw, rows * ch), (20, 17, 15))
    dr = ImageDraw.Draw(img)
    for idx, (n, i) in enumerate(cells):
        m = data[n]; k = m["keys"][i]
        j = joints(k["angles"], m["view"], tuple(k["root"]))
        ox = (idx % cols) * cw + cw / 2; oy = (idx // cols) * ch + 170; s = 90
        P = lambda p: (ox + p[0] * s, oy + p[1] * s)
        dr.line([P((-1.2, 0)), P((1.2, 0))], fill=(90, 70, 50), width=1)
        for side, col in (("f", (110, 100, 90)), ("n", (230, 220, 200))):
            for a, b in (("shoulder", "elbow"), ("elbow", "hand"), ("hip", "knee"), ("knee", "ankle"), ("ankle", "toe")):
                dr.line([P(j[f"{a}_{side}"]), P(j[f"{b}_{side}"])], fill=col, width=5)
        dr.line([P(j["root"]), P(j["neck"])], fill=(212, 168, 75), width=7)
        hx, hy = P(j["head"]); r = L["head_r"] * s
        dr.ellipse([hx - r, hy - r, hx + r, hy + r], outline=(212, 168, 75), width=3)
        dr.text(((idx % cols) * cw + 6, (idx // cols) * ch + 6), f"{n} #{i}", fill=(240, 220, 180))
    img.save(path)

if __name__ == "__main__":
    data = export()
    json.dump(data, open(sys.argv[1], "w"), indent=1)
    draw_sheet(data, sys.argv[2])
    print(len(data), "mouvements")
