"""Mouvements originaux des exercices (figure 2D), avec contrôle visuel."""
import json, math, sys

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

# hd : inclinaison de la tête par rapport au tronc (degrés) ; sl : épaules
# haussées le long du tronc (mètres).
# tz, shz_n, shz_f : facteurs de longueur apparente du tronc et des tibias
# (segments vus en raccourci, par exemple à quatre pattes vu de dos).
DEFAULT = dict(t=180, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=0, sh_n=0,
               th_f=0, sh_f=0, ft_n=90, ft_f=90, hd=0, sl=0,
               tz=1, shz_n=1, shz_f=1)

def joints(k, view, root=(0.0, 0.0)):
    k = {**DEFAULT, **k}
    j = {"root": root}
    neck = add(root, k["t"], L["torso"] * k["tz"])
    j["neck"] = neck
    j["head"] = add(neck, k["t"] + k["hd"], L["neck"])
    sh = add(root, k["t"], L["torso"] * k["tz"] * SHOULDER_AT + k["sl"])
    for side, sgn in (("n", 1), ("f", -1)):
        mir = (lambda a: a) if view == "side" else (lambda a, s=sgn: a * s)
        s0 = sh if view == "side" else (sh[0] + sgn * FRONT_SHOULDER_DX, sh[1])
        hip = root if view == "side" else (root[0] + sgn * FRONT_HIP_DX, root[1])
        j[f"shoulder_{side}"] = s0
        j[f"elbow_{side}"] = add(s0, mir(k[f"ua_{side}"]), L["upper_arm"])
        j[f"hand_{side}"] = add(j[f"elbow_{side}"], mir(k[f"fa_{side}"]), L["forearm"])
        j[f"hip_{side}"] = hip
        j[f"knee_{side}"] = add(hip, mir(k[f"th_{side}"]), L["thigh"])
        j[f"ankle_{side}"] = add(j[f"knee_{side}"], mir(k[f"sh_{side}"]), L["shin"] * k[f"shz_{side}"])
        ft = k[f"ft_{side}"] if view == "side" else 0
        j[f"toe_{side}"] = add(j[f"ankle_{side}"], ft, L["foot"] if view == "side" else 0.05)
    return j

def solve_root(k, view):
    """Place la racine pour que l'articulation d'ancrage tombe sur sa cible."""
    anchor, target = k.get("anchor", ("root", (0, 0)))
    j = joints(k, view)
    p = j[anchor]
    return (round(target[0] - p[0], 4), round(target[1] - p[1], 4))

def ik(base, goal, l1, l2, bend):
    """Angles (segment 1, segment 2) qui amènent l'extrémité sur `goal`.
    `bend` (+1 / -1) choisit le côté vers lequel plie l'articulation."""
    dx, dy = goal[0] - base[0], goal[1] - base[1]
    dist = min(math.hypot(dx, dy), l1 + l2 - 1e-6)
    phi = math.degrees(math.atan2(dx, dy))
    cos_a = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)
    a1 = phi + bend * math.degrees(math.acos(max(-1, min(1, cos_a))))
    elbow = add(base, a1, l1)
    a2 = math.degrees(math.atan2(goal[0] - elbow[0], goal[1] - elbow[1]))
    return round(a1, 2), round(a2, 2)

def placed(pose, root, arm_n=None, arm_f=None, leg_n=None, leg_f=None, hold=1.0):
    """Pose de profil dont la racine est en `root` ; chaque membre donné
    (cible, sens de flexion) est amené sur son appui. Un bras ou une jambe
    proche sans pendant éloigné est recopié de l'autre côté."""
    pose = {**DEFAULT, **pose}
    j = joints(pose, "side", root)
    arms = {"n": arm_n, "f": arm_n if arm_f is None else (arm_f or None)}
    legs = {"n": leg_n, "f": leg_n if leg_f is None else (leg_f or None)}
    for side in ("n", "f"):
        arm, leg = arms[side], legs[side]
        if arm:
            ua, fa = ik(j[f"shoulder_{side}"], arm[0], L["upper_arm"], L["forearm"], arm[1])
            pose.update({f"ua_{side}": ua, f"fa_{side}": fa})
        if leg:
            th, sh = ik(j[f"hip_{side}"], leg[0], L["thigh"], L["shin"], leg[1])
            pose.update({f"th_{side}": th, f"sh_{side}": sh})
    return kf(pose, "root", root, hold)

def solve(f, lo, hi, goal):
    """Valeur x dans [lo, hi] telle que f(x) = goal (f monotone)."""
    flo = f(lo) - goal
    for _ in range(60):
        mid = (lo + hi) / 2
        if (f(mid) - goal) * flo > 0:
            lo, flo = mid, f(mid) - goal
        else:
            hi = mid
    return round((lo + hi) / 2, 3)

def body_line(e):
    """Corps gainé incliné de `e` degrés au-dessus du sol, tête vers l'avant."""
    return dict(t=90 + e, th_n=e - 90, sh_n=e - 90, th_f=e - 90, sh_f=e - 90)

def root_from(anchor, target, pose):
    """Racine d'une pose de profil pour que `anchor` tombe sur `target`."""
    p = joints(pose, "side")[anchor]
    return (round(target[0] - p[0], 4), round(target[1] - p[1], 4))

S = {}  # debout, bras le long du corps
SQUAT_LOW = dict(t=148, th_n=82, sh_n=-22, th_f=82, sh_f=-22, ua_n=90, fa_n=90, ua_f=90, fa_f=90)
PLANK_HANDS = dict(t=109.4, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=-70.6, sh_n=-70.6, th_f=-70.6, sh_f=-70.6, ft_n=15, ft_f=15)
PUSH_DOWN = dict(t=93.7, ua_n=-100, fa_n=20, ua_f=-100, fa_f=20, th_n=-86.3, sh_n=-86.3, th_f=-86.3, sh_f=-86.3, ft_n=15, ft_f=15)

# À quatre pattes : mains sous les épaules, genoux sous les hanches.
QUAD = dict(t=103.7, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=0, sh_n=-90, th_f=0, sh_f=-90, ft_n=-90, ft_f=-90)
# Allongé sur le dos, jambes tendues.
SUPINE = dict(t=-90, ua_n=-90, fa_n=-90, ua_f=-90, fa_f=-90, th_n=90, sh_n=90, th_f=90, sh_f=90, ft_n=180, ft_f=180)
# Burpee : accroupi, mains posées au sol devant les pieds.
BURPEE_CROUCH = dict(t=140, th_n=115, sh_n=-35, th_f=115, sh_f=-35, ua_n=15, fa_n=5, ua_f=15, fa_f=5, ft_n=110, ft_f=110)
BURPEE_HAND = (0.27, 0)

def _burpee_floor():
    """Accroupi → saut des pieds en arrière → planche → retour, mains au sol."""
    crouch = {**DEFAULT, **BURPEE_CROUCH}
    r0 = root_from("ankle_n", (0, 0), crouch)
    plank = {**DEFAULT, **PLANK_HANDS}
    r2 = root_from("hand_n", BURPEE_HAND, plank)
    r1 = (round((r0[0] + r2[0]) / 2, 3), round(min(r0[1], r2[1]) - 0.12, 3))
    hands = (BURPEE_HAND, -1)
    kick = placed(dict(t=125, ft_n=60, ft_f=60), r1, arm_n=hands, leg_n=((r2[0] - 0.75, -0.18), 1), hold=0.3)
    # Genoux repliés sous les hanches pendant le saut : les pieds ne
    # touchent pas le sol en passant.
    tuck = placed(dict(t=132, th_n=20, sh_n=-140, th_f=20, sh_f=-140, ft_n=-60, ft_f=-60),
                  (round((r0[0] + r1[0]) / 2, 3), -0.55), arm_n=hands, hold=0.2)
    return [kf(BURPEE_CROUCH, hold=0.45),
            placed(BURPEE_CROUCH, r0, arm_n=hands, hold=0.2), tuck, kick,
            placed(PLANK_HANDS, r2, arm_n=hands, hold=0.4), kick, tuck,
            placed(BURPEE_CROUCH, r0, arm_n=hands, hold=0.45)]
# Garde de boxe.
GUARD = dict(t=175, ua_n=30, fa_n=170, ua_f=20, fa_f=165, th_n=12, sh_n=-5, th_f=-12, sh_f=-15)

def kf(pose, anchor="ankle_n", target=(0, 0), hold=1.0):
    return dict(pose=pose, anchor=(anchor, target), hold=hold)

def box(x0, y0, x1, y1):
    """Accessoire : banc, box ou mur (rectangle, sol en y = 0)."""
    return dict(type="box", rect=[x0, y0, x1, y1])

def bar(x, y):
    """Accessoire : barre vue en coupe."""
    return dict(type="bar", at=[x, y])

def arm_on(pose, anchor, target, goal, bend):
    """Angles du bras proche pour poser la main sur `goal` (pose de profil
    ancrée par `anchor`). `goal` peut être une articulation de la pose."""
    j = joints(pose, "side", root_from(anchor, target, pose))
    g = j[goal] if isinstance(goal, str) else goal
    return ik(j["shoulder_n"], g, L["upper_arm"], L["forearm"], bend)

_QUAD_LEG = [dict(th_n=-5, sh_n=-170, ft_n=-80), dict(th_n=-12, sh_n=-172, ft_n=-80)]
QUAD_ARM = [arm_on({**DEFAULT, **leg}, "ankle_f", (0, 0), "ankle_n", -1) for leg in _QUAD_LEG]

def _cobra():
    low = {**DEFAULT, "t": 96}
    j = joints(low, "side")
    hand = (j["shoulder_n"][0] + 0.02, 0.0)
    return [ik(j["shoulder_n"], hand, L["upper_arm"], L["forearm"], 1),
            ik(joints({**DEFAULT, "t": 130}, "side")["shoulder_n"], hand, L["upper_arm"], L["forearm"], 1)]
COBRA_ARM = _cobra()
BURPEE_FLOOR = _burpee_floor()

def _climber():
    plank = {**DEFAULT, **PLANK_HANDS}
    hip = joints(plank, "side", root_from("hand_n", (0, 0), plank))["hip_n"]
    th, sh = ik(hip, (hip[0] + 0.2, -0.24), L["thigh"], L["shin"], 1)
    return dict(th_n=th, sh_n=sh, ft_n=150), dict(th_f=th, sh_f=sh, ft_f=150)
CLIMBER_N, CLIMBER_F = _climber()
# Croisement des jambes : genoux fléchis, pieds au-dessus du sol.
CLIMBER_SWAP = dict(th_n=-10, sh_n=-115, th_f=-10, sh_f=-115, ft_n=15, ft_f=15)

def _crunch_arms(t):
    """Mains derrière la tête, coudes ouverts vers le haut."""
    pose = {**DEFAULT, "t": t}
    j = joints(pose, "side")
    head = j["head"]
    return ik(j["shoulder_n"], (head[0] + 0.02, head[1] + 0.03), L["upper_arm"], L["forearm"], -1)
CRUNCH_LOW, CRUNCH_UP = _crunch_arms(-90), _crunch_arms(-122)

MOTIONS = {
    "squat": dict(view="side", keys=[kf(S), kf(SQUAT_LOW)]),
    "lunge": dict(view="side", keys=[
        kf(dict(th_n=22, sh_n=0, th_f=-20, sh_f=-25)),
        kf(dict(th_n=88, sh_n=-2, th_f=-12, sh_f=-92, ft_f=-170))]),
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
        kf(dict(t=-90, ua_n=90, fa_n=90, ua_f=90, fa_f=90, th_n=132, sh_n=-45, th_f=132, sh_f=-45, ft_n=90, ft_f=90), "neck", (-0.05, 0)),
        kf(dict(t=-68, ua_n=96, fa_n=96, ua_f=96, fa_f=96, th_n=103, sh_n=-44, th_f=103, sh_f=-44, ft_n=90, ft_f=90, hd=-22), "neck", (-0.05, 0))]),
    "calf_raise": dict(view="side", keys=[
        kf(dict(ft_n=90, ft_f=90), "toe_n"),
        kf(dict(ft_n=40, ft_f=40), "toe_n")]),
    "plank": dict(view="side", keys=[
        kf(dict(t=97.9, ua_n=0, fa_n=90, ua_f=0, fa_f=90, th_n=-82.1, sh_n=-82.1, th_f=-82.1, sh_f=-82.1, ft_n=15, ft_f=15), "toe_n", hold=1.6),
        kf(dict(t=98.5, ua_n=0, fa_n=90, ua_f=0, fa_f=90, th_n=-81.5, sh_n=-81.5, th_f=-81.5, sh_f=-81.5, ft_n=15, ft_f=15), "toe_n", hold=1.6)]),
    "side_plank": dict(view="front", keys=[
        kf(dict(t=-102.5, ua_n=0, fa_n=-90, ua_f=180, fa_f=180, th_n=77.5, sh_n=77.5, th_f=-77.5, sh_f=-77.5), "ankle_n", hold=1.6),
        kf(dict(t=-104, ua_n=2, fa_n=-90, ua_f=180, fa_f=180, th_n=76, sh_n=76, th_f=-76, sh_f=-76), "ankle_n", hold=1.6)]),
    "crunch": dict(view="side", keys=[
        kf(dict(t=-90, ua_n=CRUNCH_LOW[0], fa_n=CRUNCH_LOW[1], ua_f=CRUNCH_LOW[0], fa_f=CRUNCH_LOW[1], th_n=140, sh_n=30, th_f=140, sh_f=30), "root"),
        kf(dict(t=-122, ua_n=CRUNCH_UP[0], fa_n=CRUNCH_UP[1], ua_f=CRUNCH_UP[0], fa_f=CRUNCH_UP[1], th_n=140, sh_n=30, th_f=140, sh_f=30), "root")]),
    "leg_raise": dict(view="side", keys=[
        kf(dict(t=-90, ua_n=90, fa_n=90, ua_f=90, fa_f=90, th_n=95, sh_n=95, th_f=95, sh_f=95, ft_n=180, ft_f=180), "root"),
        kf(dict(t=-90, ua_n=90, fa_n=90, ua_f=90, fa_f=90, th_n=175, sh_n=175, th_f=175, sh_f=175, ft_n=-90, ft_f=-90), "root")]),
    "superman": dict(view="side", keys=[
        kf(dict(t=90, ua_n=90, fa_n=90, ua_f=90, fa_f=90, th_n=-90, sh_n=-90, th_f=-90, sh_f=-90, ft_n=-90, ft_f=-90), "root"),
        kf(dict(t=106, ua_n=108, fa_n=110, ua_f=108, fa_f=110, th_n=-102, sh_n=-104, th_f=-102, sh_f=-104, ft_n=-100, ft_f=-100), "root")]),
    "burpee": dict(view="side", keys=[
        kf(S, hold=0.8),
        *BURPEE_FLOOR,
        kf(dict(ua_n=175, fa_n=180, ua_f=175, fa_f=180, ft_n=60, ft_f=60), "ankle_n", (0, -0.18), hold=0.8)]),
    "jumping_jack": dict(view="front", keys=[
        kf(dict(ua_n=6, fa_n=8, ua_f=6, fa_f=8, th_n=3, sh_n=3, th_f=3, sh_f=3), "root", (0, 0)),
        kf(dict(ua_n=160, fa_n=170, ua_f=160, fa_f=170, th_n=20, sh_n=22, th_f=20, sh_f=22), "root", (0, -0.06))]),
    "mountain_climber": dict(view="side", keys=[
        kf({**PLANK_HANDS, **CLIMBER_N}, "hand_n", hold=0.22),
        kf({**PLANK_HANDS, **CLIMBER_SWAP}, "hand_n", hold=0.22),
        kf({**PLANK_HANDS, **CLIMBER_F}, "hand_n", hold=0.22),
        kf({**PLANK_HANDS, **CLIMBER_SWAP}, "hand_n", hold=0.22)]),
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
    # Lot 2 : mobilité et étirements.
    "cat_cow": dict(view="side", keys=[
        kf({**QUAD, "t": 107, "hd": 45}, "knee_n", hold=1.5),
        kf({**QUAD, "t": 99, "hd": -55, "sl": 0.03}, "knee_n", hold=1.5)]),
    "child_pose": dict(view="side", keys=[
        kf(dict(t=80, ua_n=95, fa_n=92, ua_f=95, fa_f=92, th_n=62, sh_n=-90, th_f=62, sh_f=-90, ft_n=-90, ft_f=-90, hd=5), "knee_n", hold=2),
        kf(dict(t=84, ua_n=99, fa_n=93, ua_f=99, fa_f=93, th_n=60, sh_n=-90, th_f=60, sh_f=-90, ft_n=-90, ft_f=-90, hd=5), "knee_n", hold=2)]),
    "hip_flexor_stretch": dict(view="side", keys=[
        kf(dict(ua_n=25, fa_n=60, ua_f=25, fa_f=60, th_n=87.5, sh_n=-10, th_f=-10, sh_f=-90, ft_f=-90), "knee_f", hold=1.8),
        kf(dict(ua_n=35, fa_n=70, ua_f=35, fa_f=70, th_n=90, sh_n=-25, th_f=-30, sh_f=-90, ft_f=-90), "knee_f", hold=1.8)]),
    "hamstring_stretch": dict(view="side", keys=[
        kf(dict(t=95, ua_n=5, fa_n=10, ua_f=5, fa_f=10, th_n=-6, sh_n=-6, th_f=-6, sh_f=-6, hd=-20), hold=1.8),
        kf(dict(t=82, ua_n=15, fa_n=25, ua_f=15, fa_f=25, th_n=-8, sh_n=-8, th_f=-8, sh_f=-8, hd=-20), hold=1.8)]),
    "quad_stretch": dict(view="side", keys=[
        kf(dict(ua_n=QUAD_ARM[0][0], fa_n=QUAD_ARM[0][1], ua_f=15, fa_f=20, th_n=-5, sh_n=-170, ft_n=-80), "ankle_f", hold=1.8),
        kf(dict(ua_n=QUAD_ARM[1][0], fa_n=QUAD_ARM[1][1], ua_f=18, fa_f=25, th_n=-12, sh_n=-172, ft_n=-80), "ankle_f", hold=1.8)]),
    "calf_stretch": dict(view="side", keys=[
        kf(dict(t=160, ua_n=110, fa_n=110, ua_f=110, fa_f=110, th_n=40, sh_n=10, th_f=-25, sh_f=-25), "ankle_f", hold=1.8),
        kf(dict(t=155, ua_n=105, fa_n=105, ua_f=105, fa_f=105, th_n=48, sh_n=12, th_f=-30, sh_f=-30), "ankle_f", hold=1.8)]),
    "chest_stretch": dict(view="side", keys=[
        kf(dict(ua_n=-70, fa_n=-70, ua_f=-70, fa_f=-70, hd=8), hold=1.8),
        kf(dict(ua_n=-82, fa_n=-82, ua_f=-82, fa_f=-82, hd=12), hold=1.8)]),
    "shoulder_stretch": dict(view="front", keys=[
        kf(dict(ua_n=-80, fa_n=-85, ua_f=-20, fa_f=-110), "root", hold=1.8),
        kf(dict(ua_n=-88, fa_n=-92, ua_f=-25, fa_f=-125), "root", hold=1.8)]),
    "cobra_stretch": dict(view="side", keys=[
        kf(dict(t=96, ua_n=COBRA_ARM[0][0], fa_n=COBRA_ARM[0][1], ua_f=COBRA_ARM[0][0], fa_f=COBRA_ARM[0][1], th_n=-90, sh_n=-90, th_f=-90, sh_f=-90, ft_n=-90, ft_f=-90), "root", hold=1.6),
        kf(dict(t=130, ua_n=COBRA_ARM[1][0], fa_n=COBRA_ARM[1][1], ua_f=COBRA_ARM[1][0], fa_f=COBRA_ARM[1][1], th_n=-92, sh_n=-90, th_f=-92, sh_f=-90, ft_n=-90, ft_f=-90, hd=15), "root", hold=1.6)]),
    "lunge_twist_stretch": dict(view="side", keys=[
        kf(dict(ua_n=0, fa_n=5, ua_f=10, fa_f=10, th_n=88, sh_n=-2, th_f=-15, sh_f=-92, ft_f=-170), hold=1.5),
        kf(dict(ua_n=175, fa_n=178, ua_f=60, fa_f=40, th_n=88, sh_n=-2, th_f=-15, sh_f=-92, ft_f=-170, hd=10), hold=1.5)]),
    # Lot 3 : mobilité et échauffement.
    "butterfly_stretch": dict(view="front", keys=[
        kf(dict(ua_n=12, fa_n=-20, ua_f=12, fa_f=-20, th_n=95, sh_n=-95, th_f=95, sh_f=-95), "root", hold=1),
        kf(dict(ua_n=10, fa_n=-25, ua_f=10, fa_f=-25, th_n=103, sh_n=-100, th_f=103, sh_f=-100), "root", hold=1)]),
    "pigeon_stretch": dict(view="side", keys=[
        kf(dict(t=165, ua_n=8, fa_n=8, ua_f=8, fa_f=8, th_n=80, sh_n=-80, th_f=-80, sh_f=-80, ft_n=180, ft_f=-90), "root", (0, -0.15), hold=1.8),
        kf(dict(t=120, ua_n=45, fa_n=45, ua_f=45, fa_f=45, th_n=80, sh_n=-80, th_f=-80, sh_f=-80, ft_n=180, ft_f=-90, hd=-10), "root", (0, -0.15), hold=1.8)]),
    "thoracic_rotation": dict(view="side", keys=[
        kf({**QUAD}, "knee_n", hold=1.3),
        kf({**QUAD, "ua_n": 170, "fa_n": 175, "hd": 30}, "knee_n", hold=1.3)]),
    "downward_dog": dict(view="side", keys=[
        kf(dict(t=45, ua_n=50, fa_n=50, ua_f=50, fa_f=50, th_n=-35, sh_n=-35, th_f=-35, sh_f=-35, ft_n=45, ft_f=45, hd=-10), "toe_n", hold=1.8),
        kf(dict(t=40, ua_n=45, fa_n=45, ua_f=45, fa_f=45, th_n=-40, sh_n=-40, th_f=-40, sh_f=-40, ft_n=60, ft_f=60, hd=-10), "toe_n", hold=1.8)]),
    "neck_mobility": dict(view="front", keys=[
        kf(dict(hd=-35), "root", hold=1.2),
        kf(dict(hd=0), "root", hold=0.8),
        kf(dict(hd=35), "root", hold=1.2),
        kf(dict(hd=0), "root", hold=0.8)]),
    "arm_circles": dict(view="front", keys=[
        kf(dict(ua_n=78, fa_n=88, ua_f=78, fa_f=88), "root", hold=0.3),
        kf(dict(ua_n=90, fa_n=102, ua_f=90, fa_f=102), "root", hold=0.3),
        kf(dict(ua_n=102, fa_n=92, ua_f=102, fa_f=92), "root", hold=0.3),
        kf(dict(ua_n=90, fa_n=78, ua_f=90, fa_f=78), "root", hold=0.3)]),
    "hip_circles": dict(view="front", keys=[
        kf(dict(t=188, ua_n=-35, fa_n=60, ua_f=-35, fa_f=60, th_n=-8, sh_n=-8, th_f=8, sh_f=8), "ankle_n", (0, 0), hold=0.8),
        kf(dict(t=180, ua_n=-35, fa_n=60, ua_f=-35, fa_f=60, th_n=0, sh_n=0, th_f=0, sh_f=0, sl=0.02), "ankle_n", (0, 0), hold=0.8),
        kf(dict(t=172, ua_n=-35, fa_n=60, ua_f=-35, fa_f=60, th_n=8, sh_n=8, th_f=-8, sh_f=-8), "ankle_n", (0, 0), hold=0.8),
        kf(dict(t=180, ua_n=-35, fa_n=60, ua_f=-35, fa_f=60, th_n=0, sh_n=0, th_f=0, sh_f=0), "ankle_n", (0, 0), hold=0.8)]),
    "deep_squat_hold": dict(view="side", keys=[
        kf(dict(t=150, th_n=105, sh_n=-28, th_f=105, sh_f=-28, ua_n=70, fa_n=120, ua_f=70, fa_f=120), hold=2),
        kf(dict(t=154, th_n=108, sh_n=-30, th_f=108, sh_f=-30, ua_n=72, fa_n=122, ua_f=72, fa_f=122), hold=2)]),
    # Lot 4 : haut du corps et gainage.
    "plank_shoulder_taps": dict(view="side", keys=[
        kf(PLANK_HANDS, "toe_n", hold=0.7),
        kf({**PLANK_HANDS, "ua_n": 45, "fa_n": 200}, "toe_n", hold=0.7)]),
    "russian_twist": dict(view="side", keys=[
        kf(dict(t=210, ua_n=70, fa_n=60, ua_f=35, fa_f=25, th_n=125, sh_n=80, th_f=125, sh_f=80), "root", hold=0.7),
        kf(dict(t=206, ua_n=35, fa_n=25, ua_f=70, fa_f=60, th_n=125, sh_n=80, th_f=125, sh_f=80), "root", hold=0.7)]),
    "dead_bug": dict(view="side", keys=[
        kf(dict(SUPINE, ua_n=180, fa_n=180, ua_f=180, fa_f=180, th_n=180, sh_n=90, th_f=180, sh_f=90, ft_n=180, ft_f=180), "root", hold=1),
        kf(dict(SUPINE, ua_n=265, fa_n=265, ua_f=180, fa_f=180, th_n=180, sh_n=90, th_f=105, sh_f=95, ft_n=180, ft_f=180), "root", hold=1)]),
    "hollow_hold": dict(view="side", keys=[
        kf(dict(SUPINE, t=-112, ua_n=-110, fa_n=-110, ua_f=-110, fa_f=-110, th_n=110, sh_n=110, th_f=110, sh_f=110, ft_n=200, ft_f=200), "root", hold=1.8),
        kf(dict(SUPINE, t=-115, ua_n=-112, fa_n=-112, ua_f=-112, fa_f=-112, th_n=113, sh_n=113, th_f=113, sh_f=113, ft_n=203, ft_f=203), "root", hold=1.8)]),
    "flutter_kicks": dict(view="side", keys=[
        kf(dict(SUPINE, t=-100, th_n=125, sh_n=125, th_f=100, sh_f=100, ft_n=215, ft_f=190), "root", hold=0.35),
        kf(dict(SUPINE, t=-100, th_n=100, sh_n=100, th_f=125, sh_f=125, ft_n=190, ft_f=215), "root", hold=0.35)]),
    "wall_sit": dict(view="side", keys=[
        kf(dict(t=180, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=90, sh_n=0, th_f=90, sh_f=0), hold=2),
        kf(dict(t=182, ua_n=2, fa_n=2, ua_f=2, fa_f=2, th_n=88, sh_n=0, th_f=88, sh_f=0), hold=2)]),
    # Lot 5 : bas du corps et cardio.
    "side_lunge": dict(view="front", keys=[
        kf(dict(th_n=18, sh_n=18, th_f=18, sh_f=18, ua_n=5, ua_f=5, fa_n=5, fa_f=5), "ankle_f", hold=1),
        kf(dict(t=170, th_n=75, sh_n=-5, th_f=40, sh_f=40, ua_n=-20, fa_n=-60, ua_f=-20, fa_f=-60), "ankle_f", hold=1)]),
    "single_leg_glute_bridge": dict(view="side", keys=[
        kf(dict(t=-90, ua_n=90, fa_n=90, ua_f=90, fa_f=90, th_n=132, sh_n=-45, th_f=120, sh_f=120, ft_n=90, ft_f=200), "neck", (-0.05, 0)),
        kf(dict(t=-68, ua_n=96, fa_n=96, ua_f=96, fa_f=96, th_n=103, sh_n=-44, th_f=112, sh_f=112, ft_n=90, ft_f=200, hd=-22), "neck", (-0.05, 0))]),
    "donkey_kick": dict(view="side", keys=[
        kf(QUAD, "knee_f", hold=0.8),
        kf({**QUAD, "th_n": -95, "sh_n": -185, "ft_n": -90}, "knee_f", hold=0.8)]),
    "squat_jump": dict(view="side", keys=[
        kf(SQUAT_LOW, hold=0.6),
        kf(dict(ua_n=-20, fa_n=-15, ua_f=-20, fa_f=-15, ft_n=50, ft_f=50), "ankle_n", (0, -0.2), hold=0.6)]),
    "high_knees": dict(view="side", keys=[
        kf(dict(t=176, th_n=95, sh_n=0, th_f=-3, sh_f=-3, ua_n=-40, fa_n=50, ua_f=40, fa_f=130), "root", hold=0.3),
        kf(dict(t=176, th_f=95, sh_f=0, th_n=-3, sh_n=-3, ua_f=-40, fa_f=50, ua_n=40, fa_n=130), "root", (0, -0.03), hold=0.3)]),
    "butt_kicks": dict(view="side", keys=[
        kf(dict(t=176, th_n=-5, sh_n=-165, ft_n=-80, th_f=2, sh_f=2, ua_n=40, fa_n=130, ua_f=-40, fa_f=50), "root", hold=0.3),
        kf(dict(t=176, th_f=-5, sh_f=-165, ft_f=-80, th_n=2, sh_n=2, ua_f=40, fa_f=130, ua_n=-40, fa_n=50), "root", (0, -0.03), hold=0.3)]),
    "skater_jump": dict(view="front", keys=[
        kf(dict(t=165, th_n=40, sh_n=-10, th_f=-35, sh_f=-20, ua_n=-40, fa_n=-30, ua_f=50, fa_f=60), "ankle_n", (-0.35, 0), hold=0.6),
        kf(dict(t=195, th_f=40, sh_f=-10, th_n=-35, sh_n=-20, ua_f=-40, fa_f=-30, ua_n=50, fa_n=60), "ankle_f", (0.35, 0), hold=0.6)]),
    # Lot 6 : matériel et coordination.
    "shadow_boxing": dict(view="side", keys=[
        kf(GUARD, hold=0.3),
        kf({**GUARD, "ua_n": 88, "fa_n": 90}, hold=0.3),
        kf(GUARD, hold=0.3),
        kf({**GUARD, "t": 170, "ua_f": 85, "fa_f": 88}, hold=0.3)]),
    "reverse_fly": dict(view="side", keys=[
        kf(dict(t=112, th_n=15, sh_n=-10, th_f=15, sh_f=-10, ua_n=10, fa_n=15, ua_f=10, fa_f=15)),
        kf(dict(t=112, th_n=15, sh_n=-10, th_f=15, sh_f=-10, ua_n=-45, fa_n=-40, ua_f=-45, fa_f=-40, hd=10))]),
    "kettlebell_swing": dict(view="side", keys=[
        kf(dict(t=115, th_n=25, sh_n=-15, th_f=25, sh_f=-15, ua_n=-25, fa_n=-25, ua_f=-25, fa_f=-25), hold=0.7),
        kf(dict(t=182, ua_n=92, fa_n=92, ua_f=92, fa_f=92), hold=0.7)]),
    "shrug": dict(view="front", keys=[
        kf(dict(ua_n=4, fa_n=4, ua_f=4, fa_f=4), "root"),
        kf(dict(ua_n=4, fa_n=4, ua_f=4, fa_f=4, sl=0.07), "root")]),
    "triceps_extension": dict(view="side", keys=[
        kf(dict(ua_n=172, fa_n=178, ua_f=172, fa_f=178)),
        kf(dict(ua_n=168, fa_n=15, ua_f=168, fa_f=15, hd=-5))]),
    "band_pull_apart": dict(view="front", keys=[
        kf(dict(ua_n=70, fa_n=-80, ua_f=70, fa_f=-80), "root"),
        kf(dict(ua_n=90, fa_n=90, ua_f=90, fa_f=90, hd=0), "root")]),
}


# Lot 7 : mouvements dédiés aux variantes (11/2026), avec leurs accessoires.
def _shoulder(pose, anchor, target):
    pose = {**DEFAULT, **pose}
    return joints(pose, "side", root_from(anchor, target, pose))["shoulder_n"]

def _cycle(make, params, anchor, target, hand, bend, hold=0.5):
    """Aller-retour entre les poses `make(p)` (p parcourant `params`), mains
    maintenues sur `hand` par cinématique inverse à chaque pose clé."""
    keys = []
    for p in list(params) + list(reversed(params))[1:-1]:
        pose = {**DEFAULT, **make(p)}
        ua, fa = ik(_shoulder(pose, anchor, target), hand, L["upper_arm"], L["forearm"], bend)
        pose.update(ua_n=ua, fa_n=fa, ua_f=ua, fa_f=fa)
        keys.append(kf(pose, anchor, target, hold))
    return keys

def _press(base, anchor, target, hand_y, top_h, low_h, e_range, bend=-1, hand_dx=0):
    """Pompes : corps gainé, mains fixes en `hand_y`, épaules à `top_h`
    (bras tendus) puis `low_h` au-dessus des mains."""
    lo, hi = e_range
    height = lambda e: -_shoulder({**base, **body_line(e)}, anchor, target)[1] - (-hand_y)
    e_top = solve(height, lo, hi, top_h)
    e_low = solve(height, lo, hi, low_h)
    hand = (_shoulder({**base, **body_line(e_top)}, anchor, target)[0] + hand_dx, hand_y)
    steps = [e_top + (e_low - e_top) * i / 3 for i in range(4)]
    return _cycle(lambda e: {**base, **body_line(e)}, steps, anchor, target, hand, bend), hand

def _dedicated():
    m = {}
    # Pompes : corps gainé, mains fixes au sol.
    m["push_up"] = dict(view="side", keys=_press(dict(ft_n=15, ft_f=15), "toe_n", (0, 0), 0, 0.57, 0.16, (0, 60))[0])
    # Pompes sur les genoux : appui genoux, tibias relevés.
    keys, hand = _press(dict(ft_n=-90, ft_f=-90), "knee_n", (0, 0), 0, 0.57, 0.2, (0, 80))
    for k in keys:
        k["pose"].update(sh_n=-115, sh_f=-115)

    m["knee_push_up"] = dict(view="side", keys=keys)
    # Pompes inclinées : mains sur un banc.
    keys, hand = _press(dict(ft_n=15, ft_f=15), "toe_n", (0, 0), -0.45, 0.57, 0.2, (0, 80))
    m["incline_push_up"] = dict(view="side", keys=keys,
                                props=[box(hand[0] - 0.3, -0.45, hand[0] + 0.25, 0)])
    # Pompes déclinées : pieds sur un banc.
    keys, hand = _press(dict(ft_n=15, ft_f=15), "toe_n", (0, -0.45), 0, 0.56, 0.24, (-40, 40), hand_dx=0.1)
    m["decline_push_up"] = dict(view="side", keys=keys, props=[box(-0.35, -0.45, 0.12, 0)])
    # Pompes piquées : hanches hautes, la tête descend entre les mains.
    legs = dict(th_n=-35, sh_n=-35, th_f=-35, sh_f=-35, ft_n=45, ft_f=45)
    top = {**DEFAULT, **legs, "t": 42, "hd": -10}
    sh_top = _shoulder(top, "toe_n", (0, 0))
    a = math.degrees(math.acos(-sh_top[1] / (L["upper_arm"] + L["forearm"])))
    hand = (round(sh_top[0] + math.sin(math.radians(a)) * 0.57, 3), 0)
    head_y = lambda t: joints({**DEFAULT, **legs, "t": t, "hd": -10}, "side", root_from("toe_n", (0, 0), {**DEFAULT, **legs, "t": t}))["head"][1]
    t_low = solve(head_y, 42, 0, -0.16)
    keys = _cycle(lambda t: {**legs, "t": t, "hd": -10}, [42 + (t_low - 42) * i / 3 for i in range(4)], "toe_n", (0, 0), hand, -1)
    m["pike_push_up"] = dict(view="side", keys=keys)
    # Rowing inversé : sous une barre, talons au sol, poitrine vers la barre.
    base = dict(ft_n=170, ft_f=170)
    hang = {**DEFAULT, **base, **body_line(22)}
    s0 = _shoulder(hang, "ankle_n", (0, 0))
    grip = (round(s0[0], 3), round(s0[1] - 0.57, 3))
    e_up = solve(lambda e: -_shoulder({**base, **body_line(e)}, "ankle_n", (0, 0))[1], 22, 80, -grip[1] - 0.14)
    keys = _cycle(lambda e: {**base, **body_line(e)}, [22 + (e_up - 22) * i / 3 for i in range(4)], "ankle_n", (0, 0), grip, 1)
    m["inverted_row"] = dict(view="side", keys=keys, props=[bar(*grip)])
    # Dips sur banc : mains sur le banc derrière, talons au sol devant.
    hand, heel = (-0.2, -0.45), (0.52, 0)
    m["bench_dips"] = dict(view="side", props=[box(-0.8, -0.45, -0.15, 0)], keys=[
        placed(dict(t=178, ft_n=170, ft_f=170), (-0.12, -0.52), arm_n=(hand, 1), leg_n=(heel, 1)),
        placed(dict(t=175, ft_n=170, ft_f=170), (-0.1, -0.24), arm_n=(hand, 1), leg_n=(heel, 1))])
    # Montées sur banc.
    step = (0.42, -0.4)
    m["step_up"] = dict(view="side", props=[box(0.15, -0.4, 0.8, 0)], keys=[
        placed(dict(t=176, ua_n=-15, fa_n=-10, ua_f=15, fa_f=20), (0.0, -0.87), leg_n=(step, -1), leg_f=((0.0, 0), -1)),
        placed(dict(t=178, ua_n=15, fa_n=20, ua_f=-15, fa_f=-10, th_f=70, sh_f=-10), (0.4, -1.27), leg_n=(step, -1), leg_f=False)])
    # Squat bulgare : pied arrière posé sur un banc.
    front, rear = (0.22, 0), (-0.55, -0.49)
    m["bulgarian_split_squat"] = dict(view="side", props=[box(-1.05, -0.45, -0.5, 0)], keys=[
        placed(dict(t=176, ft_f=-95), (-0.12, -0.85), leg_n=(front, -1), leg_f=(rear, 1)),
        placed(dict(t=174, ft_f=-95), (-0.2, -0.47), leg_n=(front, -1), leg_f=(rear, 1))])
    # Hip thrust : haut du dos sur un banc, hanches qui montent.
    feet = (0.45, 0)
    m["hip_thrust"] = dict(view="side", props=[box(-1.0, -0.42, -0.35, 0)], keys=[
        placed(dict(t=-125, ua_n=55, fa_n=55, ua_f=55, fa_f=55), (0.05, -0.12), leg_n=(feet, 1)),
        placed(dict(t=-90, ua_n=90, fa_n=90, ua_f=90, fa_f=90), (0.0, -0.47), leg_n=(feet, 1))])
    # Crunch vélo : coude vers le genou opposé, jambes en pédalage.
    arms = dict(ua_n=-110, fa_n=30, ua_f=-110, fa_f=30)
    m["bicycle_crunch"] = dict(view="side", keys=[
        kf(dict(SUPINE, t=-122, **arms, th_n=152, sh_n=92, th_f=102, sh_f=102, ft_n=170, ft_f=190), "root", hold=0.6),
        kf(dict(SUPINE, t=-122, **arms, th_f=152, sh_f=92, th_n=102, sh_n=102, ft_f=170, ft_n=190), "root", hold=0.6)])
    # Bird dog : bras et jambe opposés tendus, en alternance.
    root = root_from("knee_n", (0, 0), {**DEFAULT, **QUAD})
    ext_n = {**QUAD, "ua_n": 92, "fa_n": 92, "th_f": -90, "sh_f": -90, "ft_f": 0, "hd": 8}
    ext_f = {**QUAD, "ua_f": 92, "fa_f": 92, "th_n": -90, "sh_n": -90, "ft_n": 0, "hd": 8}
    m["bird_dog"] = dict(view="side", keys=[
        kf(QUAD, "root", root, hold=0.8), kf(ext_n, "root", root, hold=1.0),
        kf(QUAD, "root", root, hold=0.8), kf(ext_f, "root", root, hold=1.0)])
    # Abductions à quatre pattes, vues de dos : le genou s'écarte sur le côté.
    back = dict(t=180, tz=0.3, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=0, sh_n=180, th_f=0, sh_f=180, shz_n=0.12, shz_f=0.12)
    m["fire_hydrant"] = dict(view="front", keys=[
        kf(back, "root", (0, -0.45), hold=0.8),
        kf({**back, "t": 184, "th_n": 82, "sh_n": 0, "shz_n": 0.25}, "root", (0, -0.45), hold=0.8)])
    # Squat sumo, de face : pieds écartés, genoux vers l'extérieur.
    m["sumo_squat"] = dict(view="front", keys=[
        kf(dict(th_n=20, sh_n=20, th_f=20, sh_f=20, ua_n=-10, fa_n=-14, ua_f=-10, fa_f=-14), "ankle_n"),
        kf(dict(th_n=70, sh_n=-16.5, th_f=70, sh_f=-16.5, ua_n=-6, fa_n=-24, ua_f=-6, fa_f=-24), "ankle_n")])
    # Squat gobelet : charge tenue contre la poitrine.
    m["goblet_squat"] = dict(view="side", keys=[
        kf(dict(ua_n=12, fa_n=168, ua_f=12, fa_f=168)),
        kf({**SQUAT_LOW, "ua_n": 38, "fa_n": 172, "ua_f": 38, "fa_f": 172})])
    return m

MOTIONS.update(_dedicated())

def _wall(motion, joint, side, gap=0.04):
    """Mur vertical touchant l'articulation `joint` de la première pose."""
    k = motion["keys"][0]
    pose = {**DEFAULT, **k["pose"]}
    x = joints(pose, motion["view"], solve_root({**pose, "anchor": k["anchor"]}, motion["view"]))[joint][0]
    x0 = x + gap if side > 0 else x - gap - 0.1
    return box(round(x0, 3), -1.9, round(x0 + 0.1, 3), 0)

MOTIONS["pull_up"].update(props=[bar(0, 0)], ground=False)
MOTIONS["dips"].update(props=[bar(0, 0)], ground=False)
MOTIONS["wall_sit"]["props"] = [_wall(MOTIONS["wall_sit"], "root", -1, 0.1)]
MOTIONS["calf_stretch"]["props"] = [_wall(MOTIONS["calf_stretch"], "hand_n", 1, 0.0)]
MOTIONS["chest_stretch"]["props"] = [_wall(MOTIONS["chest_stretch"], "hand_n", -1, 0.0)]

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
        if m.get("props"):
            out[mid]["props"] = m["props"]
        if m.get("ground") is False:
            out[mid]["ground"] = False
    return out

def draw_sheet(data, path):
    from PIL import Image, ImageDraw  # seulement pour la planche de contrôle
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
