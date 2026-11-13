"""Poses clés des exercices (héros masculin de référence, mètres, repère du
corps : X vers la gauche du héros, -Y vers l'avant, Z vers le haut).

Chaque pose donne : position du bassin, rotation du corps (degrés autour de
X, Y, Z), flexion / torsion / inclinaison du dos, tête, cibles des poignets
(hand_l, hand_r) et des chevilles (foot_l, foot_r) avec leurs pôles (vers
où plient coudes et genoux), pointe des pieds (toes_l, toes_r, degrés).
"""

REST = {
    "pelvis": (0.0, 0.0, 0.925),
    "body": (0.0, 0.0, 0.0),
    "spine": (0.0, 0.0, 0.0),
    "head": 0.0,
    "shrug": 0.0,
    "hand_l": (0.24, 0.0, 0.87),
    "hand_r": (-0.24, 0.0, 0.87),
    "hand_l_pole": (0.35, 0.6, 1.15),
    "hand_r_pole": (-0.35, 0.6, 1.15),
    "foot_l": (0.12, 0.0, 0.075),
    "foot_r": (-0.12, 0.0, 0.075),
    "foot_l_pole": (0.15, -0.8, 0.5),
    "foot_r_pole": (-0.15, -0.8, 0.5),
    "toes_l": 0.0,
    "toes_r": 0.0,
}

EXERCISES = {
    "squat": {
        "view": "three_quarter",
        "seconds": 2.4,
        "base": {"foot_l": (0.17, 0.0, 0.075), "foot_r": (-0.17, 0.0, 0.075)},
        "keys": [
            (0.0, {}),
            (0.5, {
                "pelvis": (0.0, 0.2, 0.5),
                "body": (20.0, 0.0, 0.0),
                "spine": (10.0, 0.0, 0.0),
                "head": -20.0,
                "hand_l": (0.18, -0.45, 1.0),
                "hand_r": (-0.18, -0.45, 1.0),
                "hand_l_pole": (0.5, 0.0, 0.8),
                "hand_r_pole": (-0.5, 0.0, 0.8),
            }),
        ],
    },
}

# Corps gainé en planche : épaules au-dessus des mains, pointes de pieds au
# sol. Angle du corps et hauteur du bassin calculés pour un héros de 1,80 m
# (bassin → épaules 0,46 m, bassin → chevilles 0,85 m).
PLANK_UP = {
    "pelvis": (0.0, 0.03, 0.42),
    "body": (68.0, 0.0, 0.0),
    "head": -25.0,
    "hand_l": (0.2, -0.43, 0.06),
    "hand_r": (-0.2, -0.43, 0.06),
    "hand_l_pole": (0.6, 0.2, 0.6),
    "hand_r_pole": (-0.6, 0.2, 0.6),
    "foot_l": (0.1, 0.83, 0.1),
    "foot_r": (-0.1, 0.83, 0.1),
    "foot_l_pole": (0.1, 0.8, -0.5),
    "foot_r_pole": (-0.1, 0.8, -0.5),
    "toes_l": -55.0,
    "toes_r": -55.0,
}
PUSH_DOWN = {
    **PLANK_UP,
    "pelvis": (0.0, -0.01, 0.27),
    "body": (79.0, 0.0, 0.0),
    "head": -15.0,
}
EXERCISES["push_up"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "keys": [(0.0, PLANK_UP), (0.5, PUSH_DOWN)],
}
FOREARM_PLANK = {
    **PLANK_UP,
    "pelvis": (0.0, 0.03, 0.33),
    "body": (75.0, 0.0, 0.0),
    "hand_l": (0.1, -0.66, 0.05),
    "hand_r": (-0.1, -0.66, 0.05),
    "hand_l_pole": (0.25, -0.3, -0.5),
    "hand_r_pole": (-0.25, -0.3, -0.5),
}
EXERCISES["plank"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    # Planche tenue : léger mouvement de respiration.
    "keys": [(0.0, FOREARM_PLANK), (0.5, {**FOREARM_PLANK, "pelvis": (0.0, 0.03, 0.345)})],
}
EXERCISES["lunge"] = {
    "view": "three_quarter",
    "seconds": 2.4,
    # Fente sur place : pieds décalés, on descend et on remonte, le genou
    # arrière vers le sol, le buste droit.
    "base": {
        "hand_l": (0.2, 0.0, 0.92),
        "hand_r": (-0.2, 0.0, 0.92),
        "foot_l": (0.12, -0.38, 0.075),
        "foot_r": (-0.12, 0.42, 0.12),
        "toes_r": -50.0,
        "foot_r_pole": (-0.15, -0.4, -0.3),
    },
    "keys": [
        (0.0, {"pelvis": (0.0, 0.02, 0.86)}),
        (0.5, {"pelvis": (0.0, 0.04, 0.5)}),
    ],
}
EXERCISES["jumping_jack"] = {
    "view": "front",
    "seconds": 1.2,
    "keys": [
        (0.0, {}),
        (0.5, {
            "pelvis": (0.0, 0.0, 0.93),
            "foot_l": (0.38, 0.0, 0.075),
            "foot_r": (-0.38, 0.0, 0.075),
            "hand_l": (0.32, -0.05, 2.0),
            "hand_r": (-0.32, -0.05, 2.0),
            "hand_l_pole": (0.9, 0.3, 1.6),
            "hand_r_pole": (-0.9, 0.3, 1.6),
            "head": 5.0,
        }),
    ],
}
EXERCISES["biceps_curl"] = {
    "view": "three_quarter",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {
        "foot_l": (0.14, 0.0, 0.075),
        "foot_r": (-0.14, 0.0, 0.075),
        "hand_l_pole": (0.25, 0.6, 1.0),
        "hand_r_pole": (-0.25, 0.6, 1.0),
    },
    "keys": [
        (0.0, {"hand_l": (0.22, -0.08, 0.9), "hand_r": (-0.22, -0.08, 0.9)}),
        (0.5, {"hand_l": (0.22, -0.18, 1.33), "hand_r": (-0.22, -0.18, 1.33)}),
    ],
}

# --- Au sol, sur le dos ------------------------------------------------------
# Allongé sur le dos : corps tourné de -90° (visage vers le haut), bassin au
# ras du sol.
SUPINE = {
    "pelvis": (0.0, 0.0, 0.12),
    # Tourné vers l'avant puis retourné sur le dos (visage vers le haut).
    "body": (90.0, 180.0, 0.0),
    "head": 10.0,
    "hand_l": (0.28, -0.2, 0.05),
    "hand_r": (-0.28, -0.2, 0.05),
    "hand_l_pole": (0.6, 0.0, 0.6),
    "hand_r_pole": (-0.6, 0.0, 0.6),
    # Genoux pliés, pieds à plat près des fesses.
    "foot_l": (0.14, 0.42, 0.08),
    "foot_r": (-0.14, 0.42, 0.08),
    "foot_l_pole": (0.15, 0.3, 1.2),
    "foot_r_pole": (-0.15, 0.3, 1.2),
}
EXERCISES["crunch"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "hand_l": (0.1, -0.5, 0.25), "hand_r": (-0.1, -0.5, 0.25)},
    "keys": [
        (0.0, {}),
        (0.5, {"spine": (-45.0, 0.0, 0.0), "head": -10.0, "hand_l": (0.12, -0.42, 0.42), "hand_r": (-0.12, -0.42, 0.42)}),
    ],
}
EXERCISES["glute_bridge"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "foot_l": (0.14, 0.38, 0.08), "foot_r": (-0.14, 0.38, 0.08)},
    "keys": [
        (0.0, {}),
        (0.5, {"pelvis": (0.0, 0.02, 0.36), "body": (70.0, 180.0, 0.0), "spine": (-12.0, 0.0, 0.0), "head": 30.0}),
    ],
}
# --- Au sol, sur le ventre / à quatre pattes ----------------------------------
EXERCISES["mountain_climber"] = {
    "view": "side",
    "seconds": 1.0,
    "props": [{"type": "mat"}],
    "base": PLANK_UP,
    "keys": [
        (0.0, {"foot_l": (0.1, 0.25, 0.25), "foot_l_pole": (0.15, -0.5, 0.0), "toes_l": -20.0}),
        (0.5, {"foot_r": (-0.1, 0.25, 0.25), "foot_r_pole": (-0.15, -0.5, 0.0), "toes_r": -20.0}),
    ],
}
QUADRUPED = {
    "pelvis": (0.0, 0.25, 0.6),
    "body": (90.0, 0.0, 0.0),
    "head": -20.0,
    "hand_l": (0.18, -0.22, 0.06),
    "hand_r": (-0.18, -0.22, 0.06),
    "hand_l_pole": (0.4, 0.3, 0.5),
    "hand_r_pole": (-0.4, 0.3, 0.5),
    "foot_l": (0.12, 0.72, 0.1),
    "foot_r": (-0.12, 0.72, 0.1),
    "foot_l_pole": (0.15, 0.2, -0.6),
    "foot_r_pole": (-0.15, 0.2, -0.6),
    "toes_l": -80.0,
    "toes_r": -80.0,
}
EXERCISES["bird_dog"] = {
    "view": "side",
    "seconds": 3.0,
    "props": [{"type": "mat"}],
    "base": QUADRUPED,
    "keys": [
        (0.0, {}),
        (0.25, {"hand_l": (0.18, -0.9, 0.62), "hand_l_pole": (0.3, -0.5, 1.2), "foot_r": (-0.12, 1.05, 0.62), "foot_r_pole": (-0.15, 0.6, 1.5), "toes_r": 0.0}),
        (0.5, {}),
        (0.75, {"hand_r": (-0.18, -0.9, 0.62), "hand_r_pole": (-0.3, -0.5, 1.2), "foot_l": (0.12, 1.05, 0.62), "foot_l_pole": (0.15, 0.6, 1.5), "toes_l": 0.0}),
    ],
}
EXERCISES["superman"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "mat"}],
    "base": {
        "pelvis": (0.0, 0.0, 0.11),
        "body": (90.0, 0.0, 0.0),
        "head": -10.0,
        "hand_l": (0.2, -1.1, 0.05),
        "hand_r": (-0.2, -1.1, 0.05),
        "hand_l_pole": (0.5, -0.5, 0.6),
        "hand_r_pole": (-0.5, -0.5, 0.6),
        "foot_l": (0.12, 0.85, 0.06),
        "foot_r": (-0.12, 0.85, 0.06),
        "foot_l_pole": (0.15, 0.4, 0.8),
        "foot_r_pole": (-0.15, 0.4, 0.8),
        "toes_l": -70.0,
        "toes_r": -70.0,
    },
    "keys": [
        (0.0, {}),
        (0.5, {"spine": (-25.0, 0.0, 0.0), "head": -20.0, "hand_l": (0.2, -1.0, 0.35), "hand_r": (-0.2, -1.0, 0.35), "foot_l": (0.12, 0.82, 0.25), "foot_r": (-0.12, 0.82, 0.25)}),
    ],
}
# --- Debout ------------------------------------------------------------------
EXERCISES["high_knees"] = {
    "view": "three_quarter",
    "seconds": 0.8,
    "base": {"hand_l_pole": (0.3, 0.5, 1.0), "hand_r_pole": (-0.3, 0.5, 1.0)},
    "keys": [
        (0.0, {"foot_l": (0.12, -0.3, 0.62), "foot_l_pole": (0.15, -1.0, 1.0), "hand_r": (-0.2, -0.3, 1.2), "hand_l": (0.22, 0.2, 0.95)}),
        (0.5, {"foot_r": (-0.12, -0.3, 0.62), "foot_r_pole": (-0.15, -1.0, 1.0), "hand_l": (0.2, -0.3, 1.2), "hand_r": (-0.22, 0.2, 0.95)}),
    ],
}
EXERCISES["overhead_press"] = {
    "view": "three_quarter",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {"foot_l": (0.15, 0.0, 0.075), "foot_r": (-0.15, 0.0, 0.075), "hand_l_pole": (0.8, 0.2, 1.2), "hand_r_pole": (-0.8, 0.2, 1.2)},
    "keys": [
        (0.0, {"hand_l": (0.3, -0.06, 1.48), "hand_r": (-0.3, -0.06, 1.48)}),
        (0.5, {"hand_l": (0.2, -0.04, 2.05), "hand_r": (-0.2, -0.04, 2.05)}),
    ],
}
EXERCISES["lateral_raise"] = {
    "view": "front",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {"foot_l": (0.15, 0.0, 0.075), "foot_r": (-0.15, 0.0, 0.075), "hand_l_pole": (0.4, 0.6, 1.4), "hand_r_pole": (-0.4, 0.6, 1.4)},
    "keys": [
        (0.0, {"hand_l": (0.24, -0.05, 0.9), "hand_r": (-0.24, -0.05, 0.9)}),
        (0.5, {"hand_l": (0.78, -0.05, 1.38), "hand_r": (-0.78, -0.05, 1.38)}),
    ],
}

# --- Debout : jambes -----------------------------------------------------------
WIDE = {"foot_l": (0.17, 0.0, 0.075), "foot_r": (-0.17, 0.0, 0.075)}
SQUAT_LOW = {
    "pelvis": (0.0, 0.2, 0.5),
    "body": (20.0, 0.0, 0.0),
    "spine": (10.0, 0.0, 0.0),
    "head": -20.0,
}
EXERCISES["goblet_squat"] = {
    "view": "three_quarter",
    "seconds": 2.4,
    "props": [{"type": "dumbbells"}],
    "base": {**WIDE, "hand_l": (0.06, -0.25, 1.25), "hand_r": (-0.06, -0.25, 1.25), "hand_l_pole": (0.4, 0.0, 0.9), "hand_r_pole": (-0.4, 0.0, 0.9)},
    "keys": [(0.0, {}), (0.5, {**SQUAT_LOW, "hand_l": (0.06, -0.12, 0.82), "hand_r": (-0.06, -0.12, 0.82)})],
}
EXERCISES["sumo_squat"] = {
    "view": "front",
    "seconds": 2.4,
    "base": {"foot_l": (0.3, 0.0, 0.075), "foot_r": (-0.3, 0.0, 0.075), "foot_l_pole": (0.8, -0.6, 0.5), "foot_r_pole": (-0.8, -0.6, 0.5),
             "hand_l": (0.05, -0.2, 1.15), "hand_r": (-0.05, -0.2, 1.15), "hand_l_pole": (0.5, 0.0, 0.9), "hand_r_pole": (-0.5, 0.0, 0.9)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.05, 0.58), "body": (8.0, 0.0, 0.0), "hand_l": (0.05, -0.2, 0.85), "hand_r": (-0.05, -0.2, 0.85)})],
}
EXERCISES["squat_jump"] = {
    "view": "three_quarter",
    "seconds": 1.6,
    "base": WIDE,
    "keys": [
        (0.0, {**SQUAT_LOW, "pelvis": (0.0, 0.18, 0.55), "hand_l": (0.2, 0.25, 0.8), "hand_r": (-0.2, 0.25, 0.8)}),
        (0.45, {"pelvis": (0.0, 0.0, 1.15), "foot_l": (0.17, 0.0, 0.3), "foot_r": (-0.17, 0.0, 0.3), "toes_l": -40.0, "toes_r": -40.0,
                "hand_l": (0.3, -0.1, 2.05), "hand_r": (-0.3, -0.1, 2.05), "hand_l_pole": (0.9, 0.3, 1.6), "hand_r_pole": (-0.9, 0.3, 1.6)}),
        (0.7, {}),
    ],
}
EXERCISES["deep_squat_hold"] = {
    "view": "three_quarter",
    "seconds": 2.0,
    "base": {**WIDE, "pelvis": (0.0, 0.16, 0.33), "body": (25.0, 0.0, 0.0), "spine": (5.0, 0.0, 0.0), "head": -25.0,
             "hand_l": (0.05, -0.32, 0.65), "hand_r": (-0.05, -0.32, 0.65), "hand_l_pole": (0.5, 0.0, 0.4), "hand_r_pole": (-0.5, 0.0, 0.4)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.16, 0.345)})],
}
EXERCISES["wall_sit"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "box", "size": (1.2, 0.2, 1.6), "y": 0.5}],
    "base": {"pelvis": (0.0, 0.3, 0.5), "foot_l": (0.14, -0.15, 0.075), "foot_r": (-0.14, -0.15, 0.075),
             "hand_l": (0.22, 0.1, 0.6), "hand_r": (-0.22, 0.1, 0.6)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.3, 0.51)})],
}
EXERCISES["side_lunge"] = {
    "view": "front",
    "seconds": 2.6,
    "base": {"foot_l": (0.45, 0.0, 0.075), "foot_r": (-0.45, 0.0, 0.075), "hand_l": (0.06, -0.25, 1.15), "hand_r": (-0.06, -0.25, 1.15),
             "hand_l_pole": (0.5, 0.0, 0.9), "hand_r_pole": (-0.5, 0.0, 0.9), "foot_l_pole": (0.8, -0.6, 0.5), "foot_r_pole": (-0.8, -0.6, 0.5)},
    "keys": [
        (0.0, {"pelvis": (0.0, 0.0, 0.88)}),
        (0.25, {"pelvis": (0.26, 0.1, 0.55), "body": (15.0, 0.0, 0.0)}),
        (0.5, {"pelvis": (0.0, 0.0, 0.88)}),
        (0.75, {"pelvis": (-0.26, 0.1, 0.55), "body": (15.0, 0.0, 0.0)}),
    ],
}
EXERCISES["reverse_lunge"] = {
    "view": "three_quarter",
    "seconds": 2.6,
    "base": {"hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)},
    "keys": [
        (0.0, {}),
        (0.5, {"pelvis": (0.0, 0.18, 0.5), "foot_l": (0.12, -0.2, 0.075), "foot_r": (-0.12, 0.6, 0.12), "toes_r": -50.0,
               "foot_r_pole": (-0.15, -0.4, -0.3)}),
    ],
}
EXERCISES["bulgarian_split_squat"] = {
    "view": "side",
    "seconds": 2.6,
    "props": [{"type": "bench", "size": (0.5, 0.4, 0.45), "y": 0.75}],
    "base": {"foot_l": (0.12, -0.3, 0.075), "foot_r": (-0.12, 0.68, 0.5), "toes_r": -70.0, "foot_r_pole": (-0.15, -0.3, -0.5),
             "hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)},
    "keys": [(0.0, {"pelvis": (0.0, 0.08, 0.85)}), (0.5, {"pelvis": (0.0, 0.12, 0.52), "body": (10.0, 0.0, 0.0)})],
}
EXERCISES["step_up"] = {
    "view": "side",
    "seconds": 2.6,
    "props": [{"type": "box", "size": (0.6, 0.45, 0.4), "y": -0.3}],
    "base": {"hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)},
    "keys": [
        (0.0, {"pelvis": (0.0, 0.12, 0.88), "foot_l": (0.12, -0.3, 0.475), "foot_r": (-0.12, 0.15, 0.075)}),
        (0.5, {"pelvis": (0.0, -0.3, 1.3), "foot_l": (0.12, -0.3, 0.475), "foot_r": (-0.12, -0.3, 0.475)}),
    ],
}
EXERCISES["standing_calf_raise"] = {
    "view": "side",
    "seconds": 1.8,
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.0, 1.0), "foot_l": (0.12, 0.0, 0.15), "foot_r": (-0.12, 0.0, 0.15), "toes_l": -35.0, "toes_r": -35.0})],
}
EXERCISES["butt_kicks"] = {
    "view": "side",
    "seconds": 0.8,
    "base": {"hand_l": (0.2, -0.15, 1.05), "hand_r": (-0.2, -0.15, 1.05)},
    "keys": [
        (0.0, {"foot_l": (0.12, 0.45, 0.62), "foot_l_pole": (0.15, -1.0, 0.0)}),
        (0.5, {"foot_r": (-0.12, 0.45, 0.62), "foot_r_pole": (-0.15, -1.0, 0.0)}),
    ],
}
EXERCISES["skater_jump"] = {
    "view": "front",
    "seconds": 1.6,
    "keys": [
        (0.0, {"pelvis": (0.35, 0.05, 0.75), "body": (20.0, 0.0, 0.0), "foot_l": (0.4, 0.0, 0.075), "foot_r": (0.2, 0.3, 0.2), "toes_r": -40.0,
               "hand_l": (0.0, -0.35, 0.9), "hand_r": (-0.35, 0.3, 1.0)}),
        (0.5, {"pelvis": (-0.35, 0.05, 0.75), "body": (20.0, 0.0, 0.0), "foot_r": (-0.4, 0.0, 0.075), "foot_l": (-0.2, 0.3, 0.2), "toes_l": -40.0,
               "hand_r": (0.0, -0.35, 0.9), "hand_l": (0.35, 0.3, 1.0)}),
    ],
}
EXERCISES["jump_rope"] = {
    "view": "front",
    "seconds": 0.8,
    "base": {"hand_l": (0.3, -0.1, 0.95), "hand_r": (-0.3, -0.1, 0.95), "hand_l_pole": (0.5, 0.5, 1.2), "hand_r_pole": (-0.5, 0.5, 1.2)},
    "keys": [
        (0.0, {}),
        (0.5, {"pelvis": (0.0, 0.0, 1.03), "foot_l": (0.12, 0.0, 0.17), "foot_r": (-0.12, 0.0, 0.17), "toes_l": -30.0, "toes_r": -30.0,
               "hand_l": (0.32, -0.05, 1.0), "hand_r": (-0.32, -0.05, 1.0)}),
    ],
}
# --- Debout : haltères -----------------------------------------------------------
EXERCISES["hammer_curl"] = {**EXERCISES["biceps_curl"]}
EXERCISES["romanian_deadlift"] = {
    "view": "side",
    "seconds": 2.6,
    "props": [{"type": "dumbbells"}],
    "base": {"hand_l": (0.15, -0.06, 0.8), "hand_r": (-0.15, -0.06, 0.8)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.14, 0.88), "body": (65.0, 0.0, 0.0), "head": -15.0,
                                "hand_l": (0.15, -0.12, 0.42), "hand_r": (-0.15, -0.12, 0.42), "foot_l_pole": (0.15, -0.8, 0.5)})],
}
BENT = {"pelvis": (0.0, 0.12, 0.86), "body": (55.0, 0.0, 0.0), "head": -20.0}
EXERCISES["row"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {**BENT, "hand_l_pole": (0.3, 0.8, 1.4), "hand_r_pole": (-0.3, 0.8, 1.4)},
    "keys": [(0.0, {"hand_l": (0.16, -0.35, 0.5), "hand_r": (-0.16, -0.35, 0.5)}), (0.5, {"hand_l": (0.17, -0.05, 0.85), "hand_r": (-0.17, -0.05, 0.85)})],
}
EXERCISES["reverse_fly"] = {
    "view": "front",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {**BENT, "hand_l_pole": (0.5, 0.5, 1.6), "hand_r_pole": (-0.5, 0.5, 1.6)},
    "keys": [(0.0, {"hand_l": (0.12, -0.38, 0.55), "hand_r": (-0.12, -0.38, 0.55)}), (0.5, {"hand_l": (0.72, -0.25, 0.95), "hand_r": (-0.72, -0.25, 0.95)})],
}
EXERCISES["shrug"] = {
    "view": "front",
    "seconds": 1.8,
    "props": [{"type": "dumbbells"}],
    "base": {"hand_l": (0.22, -0.02, 0.86), "hand_r": (-0.22, -0.02, 0.86)},
    "keys": [(0.0, {}), (0.5, {"shrug": 12.0, "hand_l": (0.22, -0.02, 0.93), "hand_r": (-0.22, -0.02, 0.93)})],
}
EXERCISES["triceps_extension"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {"hand_l_pole": (0.1, -0.3, 2.3), "hand_r_pole": (-0.1, -0.3, 2.3)},
    "keys": [(0.0, {"hand_l": (0.06, 0.12, 1.55), "hand_r": (-0.06, 0.12, 1.55)}), (0.5, {"hand_l": (0.06, -0.02, 2.05), "hand_r": (-0.06, -0.02, 2.05)})],
}
EXERCISES["kettlebell_swing"] = {
    "view": "side",
    "seconds": 1.6,
    "props": [{"type": "dumbbells"}],
    "base": WIDE,
    "keys": [
        (0.0, {"pelvis": (0.0, 0.18, 0.78), "body": (50.0, 0.0, 0.0), "hand_l": (0.04, 0.2, 0.5), "hand_r": (-0.04, 0.2, 0.5), "head": -15.0}),
        (0.5, {"hand_l": (0.04, -0.6, 1.35), "hand_r": (-0.04, -0.6, 1.35), "hand_l_pole": (0.3, 0.5, 2.0), "hand_r_pole": (-0.3, 0.5, 2.0)}),
    ],
}
EXERCISES["band_pull_apart"] = {
    "view": "front",
    "seconds": 2.0,
    "base": {"hand_l_pole": (0.3, 0.8, 1.4), "hand_r_pole": (-0.3, 0.8, 1.4)},
    "keys": [(0.0, {"hand_l": (0.15, -0.6, 1.38), "hand_r": (-0.15, -0.6, 1.38)}), (0.5, {"hand_l": (0.75, -0.08, 1.38), "hand_r": (-0.75, -0.08, 1.38)})],
}
EXERCISES["arm_circles"] = {
    "view": "front",
    "seconds": 1.6,
    "base": {"hand_l_pole": (0.5, 0.6, 1.4), "hand_r_pole": (-0.5, 0.6, 1.4)},
    "keys": [
        (0.0, {"hand_l": (0.8, -0.05, 1.5), "hand_r": (-0.8, -0.05, 1.5)}),
        (0.25, {"hand_l": (0.78, -0.18, 1.38), "hand_r": (-0.78, -0.18, 1.38)}),
        (0.5, {"hand_l": (0.8, -0.05, 1.26), "hand_r": (-0.8, -0.05, 1.26)}),
        (0.75, {"hand_l": (0.78, 0.1, 1.38), "hand_r": (-0.78, 0.1, 1.38)}),
    ],
}
EXERCISES["shadow_boxing"] = {
    "view": "three_quarter",
    "seconds": 1.2,
    "base": {"foot_l": (0.14, -0.15, 0.075), "foot_r": (-0.14, 0.15, 0.075), "pelvis": (0.0, 0.0, 0.88),
             "hand_l": (0.12, -0.2, 1.45), "hand_r": (-0.12, -0.15, 1.42), "hand_l_pole": (0.4, 0.4, 0.9), "hand_r_pole": (-0.4, 0.4, 0.9)},
    "keys": [
        (0.0, {}),
        (0.25, {"hand_l": (0.06, -0.7, 1.45), "spine": (0.0, -12.0, 0.0)}),
        (0.5, {}),
        (0.75, {"hand_r": (-0.04, -0.7, 1.45), "spine": (0.0, 15.0, 0.0)}),
    ],
}
EXERCISES["walking"] = {
    "view": "side",
    "seconds": 1.2,
    "keys": [
        (0.0, {"foot_l": (0.11, -0.3, 0.075), "foot_r": (-0.11, 0.3, 0.12), "toes_r": -30.0, "pelvis": (0.0, 0.0, 0.9), "hand_l": (0.22, 0.2, 0.9), "hand_r": (-0.22, -0.2, 0.92)}),
        (0.5, {"foot_r": (-0.11, -0.3, 0.075), "foot_l": (0.11, 0.3, 0.12), "toes_l": -30.0, "pelvis": (0.0, 0.0, 0.9), "hand_r": (-0.22, 0.2, 0.9), "hand_l": (0.22, -0.2, 0.92)}),
    ],
}
EXERCISES["running"] = {
    "view": "side",
    "seconds": 0.8,
    "base": {"body": (10.0, 0.0, 0.0), "hand_l_pole": (0.3, 0.6, 0.9), "hand_r_pole": (-0.3, 0.6, 0.9)},
    "keys": [
        (0.0, {"foot_l": (0.11, -0.4, 0.2), "foot_r": (-0.11, 0.45, 0.45), "foot_r_pole": (-0.15, -1.0, 0.2), "pelvis": (0.0, 0.0, 0.92),
               "hand_l": (0.2, 0.2, 1.0), "hand_r": (-0.2, -0.3, 1.25)}),
        (0.5, {"foot_r": (-0.11, -0.4, 0.2), "foot_l": (0.11, 0.45, 0.45), "foot_l_pole": (0.15, -1.0, 0.2), "pelvis": (0.0, 0.0, 0.92),
               "hand_r": (-0.2, 0.2, 1.0), "hand_l": (0.2, -0.3, 1.25)}),
    ],
}

# --- Pompes et variantes ------------------------------------------------------------
def _push(name, hands_x=0.2, knees=False, incline=None, decline=None, pike=False):
    up, down = dict(PLANK_UP), dict(PUSH_DOWN)
    for p in (up, down):
        p["hand_l"] = (hands_x, p["hand_l"][1], p["hand_l"][2])
        p["hand_r"] = (-hands_x, p["hand_r"][1], p["hand_r"][2])
    if knees:
        for p, z, ang in ((up, 0.4, 55.0), (down, 0.25, 70.0)):
            p.update({"pelvis": (0.0, 0.05, z), "body": (ang, 0.0, 0.0), "foot_l": (0.1, 0.55, 0.3), "foot_r": (-0.1, 0.55, 0.3),
                      "foot_l_pole": (0.15, 0.2, -0.6), "foot_r_pole": (-0.15, 0.2, -0.6), "toes_l": 0.0, "toes_r": 0.0})
    if incline:
        # Mains sur le banc : corps plus redressé.
        up.update({"pelvis": (0.0, 0.25, 0.62), "body": (52.0, 0.0, 0.0), "hand_l": (hands_x, -0.25, 0.48), "hand_r": (-hands_x, -0.25, 0.48), "foot_l": (0.1, 1.0, 0.1), "foot_r": (-0.1, 1.0, 0.1)})
        down.update({"pelvis": (0.0, 0.22, 0.5), "body": (62.0, 0.0, 0.0), "hand_l": (hands_x, -0.25, 0.48), "hand_r": (-hands_x, -0.25, 0.48), "foot_l": (0.1, 1.0, 0.1), "foot_r": (-0.1, 1.0, 0.1)})
    if decline:
        up.update({"pelvis": (0.0, 0.05, 0.52), "body": (80.0, 0.0, 0.0), "foot_l": (0.1, 0.85, 0.5), "foot_r": (-0.1, 0.85, 0.5)})
        down.update({"pelvis": (0.0, -0.02, 0.42), "body": (95.0, 0.0, 0.0), "foot_l": (0.1, 0.85, 0.5), "foot_r": (-0.1, 0.85, 0.5)})
    if pike:
        up.update({"pelvis": (0.0, 0.2, 0.85), "body": (120.0, 0.0, 0.0), "head": -10.0, "hand_l": (hands_x, -0.25, 0.06), "hand_r": (-hands_x, -0.25, 0.06),
                   "foot_l": (0.1, 0.55, 0.1), "foot_r": (-0.1, 0.55, 0.1), "foot_l_pole": (0.15, -0.5, 0.5), "foot_r_pole": (-0.15, -0.5, 0.5)})
        down.update({**up, "pelvis": (0.0, 0.15, 0.8), "body": (130.0, 0.0, 0.0)})
    props = [{"type": "mat"}]
    if incline:
        props.append({"type": "bench", "size": (0.9, 0.4, 0.45), "y": -0.3})
    if decline:
        props.append({"type": "bench", "size": (0.9, 0.4, 0.45), "y": 0.85})
    EXERCISES[name] = {"view": "side", "seconds": 2.0, "props": props, "keys": [(0.0, up), (0.5, down)]}


_push("knee_push_up", knees=True)
_push("wide_push_up", hands_x=0.38)
_push("diamond_push_up", hands_x=0.05)
_push("incline_push_up", incline=True)
_push("decline_push_up", decline=True)
_push("pike_push_up", pike=True)

EXERCISES["plank_shoulder_taps"] = {
    "view": "front",
    "seconds": 1.6,
    "props": [{"type": "mat"}],
    "base": {**PLANK_UP, "foot_l": (0.22, 0.83, 0.1), "foot_r": (-0.22, 0.83, 0.1)},
    "keys": [
        (0.0, {"hand_l": (-0.12, -0.5, 0.55), "hand_l_pole": (0.3, 0.0, 0.0)}),
        (0.5, {"hand_r": (0.12, -0.5, 0.55), "hand_r_pole": (-0.3, 0.0, 0.0)}),
    ],
}
EXERCISES["side_plank"] = {
    "view": "front",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {
        "pelvis": (0.0, 0.0, 0.32),
        "body": (0.0, 0.0, 0.0),
        "head": 0.0,
        "hand_r": (-0.55, 0.0, 0.05),
        "hand_r_pole": (-0.6, 0.6, 0.5),
        "hand_l": (0.2, 0.0, 1.0),
        "foot_l": (0.65, 0.05, 0.11),
        "foot_r": (0.65, -0.05, 0.06),
    },
    "keys": [(0.0, {"body": (0.0, -72.0, 0.0)}), (0.5, {"body": (0.0, -72.0, 0.0), "pelvis": (0.0, 0.0, 0.34)})],
}
EXERCISES["hollow_hold"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "spine": (-20.0, 0.0, 0.0), "head": -15.0, "hand_l": (0.12, -0.95, 0.35), "hand_r": (-0.12, -0.95, 0.35),
             "hand_l_pole": (0.3, -0.5, 1.0), "hand_r_pole": (-0.3, -0.5, 1.0), "foot_l": (0.08, 0.85, 0.3), "foot_r": (-0.08, 0.85, 0.3),
             "foot_l_pole": (0.1, 0.4, 1.2), "foot_r_pole": (-0.1, 0.4, 1.2)},
    "keys": [(0.0, {}), (0.5, {"foot_l": (0.08, 0.85, 0.33), "foot_r": (-0.08, 0.85, 0.33)})],
}
EXERCISES["leg_raise"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "hand_l": (0.25, 0.1, 0.05), "hand_r": (-0.25, 0.1, 0.05), "foot_l_pole": (0.1, 0.5, 1.5), "foot_r_pole": (-0.1, 0.5, 1.5)},
    "keys": [(0.0, {"foot_l": (0.08, 0.88, 0.12), "foot_r": (-0.08, 0.88, 0.12)}), (0.5, {"foot_l": (0.08, 0.08, 0.95), "foot_r": (-0.08, 0.08, 0.95)})],
}
EXERCISES["flutter_kicks"] = {
    "view": "side",
    "seconds": 1.0,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "hand_l": (0.25, 0.1, 0.05), "hand_r": (-0.25, 0.1, 0.05), "foot_l_pole": (0.1, 0.5, 1.5), "foot_r_pole": (-0.1, 0.5, 1.5)},
    "keys": [(0.0, {"foot_l": (0.08, 0.82, 0.4), "foot_r": (-0.08, 0.85, 0.18)}), (0.5, {"foot_r": (-0.08, 0.82, 0.4), "foot_l": (0.08, 0.85, 0.18)})],
}
EXERCISES["bicycle_crunch"] = {
    "view": "three_quarter",
    "seconds": 1.6,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "spine": (-30.0, 0.0, 0.0), "hand_l": (0.15, -0.6, 0.38), "hand_r": (-0.15, -0.6, 0.38), "hand_l_pole": (0.5, -0.2, 0.5), "hand_r_pole": (-0.5, -0.2, 0.5)},
    "keys": [
        (0.0, {"spine": (-30.0, 25.0, 0.0), "foot_l": (0.12, 0.25, 0.45), "foot_r": (-0.12, 0.85, 0.3), "foot_l_pole": (0.1, -0.2, 1.2)}),
        (0.5, {"spine": (-30.0, -25.0, 0.0), "foot_r": (-0.12, 0.25, 0.45), "foot_l": (0.12, 0.85, 0.3), "foot_r_pole": (-0.1, -0.2, 1.2)}),
    ],
}
EXERCISES["dead_bug"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "hand_l": (0.15, -0.3, 0.7), "hand_r": (-0.15, -0.3, 0.7), "hand_l_pole": (0.3, 0.2, 1.0), "hand_r_pole": (-0.3, 0.2, 1.0),
             "foot_l": (0.12, 0.3, 0.5), "foot_r": (-0.12, 0.3, 0.5), "foot_l_pole": (0.15, -0.2, 1.0), "foot_r_pole": (-0.15, -0.2, 1.0)},
    "keys": [
        (0.0, {}),
        (0.25, {"hand_l": (0.15, -0.95, 0.15), "foot_r": (-0.12, 0.9, 0.12)}),
        (0.5, {}),
        (0.75, {"hand_r": (-0.15, -0.95, 0.15), "foot_l": (0.12, 0.9, 0.12)}),
    ],
}
EXERCISES["russian_twist"] = {
    "view": "front",
    "seconds": 1.6,
    "props": [{"type": "mat"}],
    "base": {"pelvis": (0.0, 0.0, 0.12), "body": (-40.0, 0.0, 0.0), "head": 15.0, "foot_l": (0.14, -0.45, 0.2), "foot_r": (-0.14, -0.45, 0.2),
             "foot_l_pole": (0.2, -0.5, 1.2), "foot_r_pole": (-0.2, -0.5, 1.2)},
    "keys": [
        (0.0, {"spine": (0.0, 35.0, 0.0), "hand_l": (0.35, -0.3, 0.3), "hand_r": (0.25, -0.35, 0.3)}),
        (0.5, {"spine": (0.0, -35.0, 0.0), "hand_l": (-0.25, -0.35, 0.3), "hand_r": (-0.35, -0.3, 0.3)}),
    ],
}
EXERCISES["hip_thrust"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "bench", "size": (1.0, 0.4, 0.42), "y": -0.55}],
    "base": {"body": (90.0, 180.0, 0.0), "head": 20.0, "hand_l": (0.4, -0.35, 0.42), "hand_r": (-0.4, -0.35, 0.42),
             "foot_l": (0.18, 0.45, 0.08), "foot_r": (-0.18, 0.45, 0.08), "foot_l_pole": (0.15, 0.3, 1.3), "foot_r_pole": (-0.15, 0.3, 1.3)},
    "keys": [(0.0, {"pelvis": (0.0, -0.05, 0.22), "body": (60.0, 180.0, 0.0)}), (0.5, {"pelvis": (0.0, 0.0, 0.5), "body": (92.0, 180.0, 0.0)})],
}
EXERCISES["single_leg_glute_bridge"] = {
    **EXERCISES["glute_bridge"],
    "base": {**SUPINE, "foot_l": (0.12, 0.38, 0.08), "foot_r": (-0.12, 0.05, 0.7), "foot_r_pole": (-0.1, -0.3, 1.5)},
}
EXERCISES["donkey_kick"] = {
    "view": "side",
    "seconds": 1.8,
    "props": [{"type": "mat"}],
    "base": QUADRUPED,
    "keys": [(0.0, {}), (0.5, {"foot_r": (-0.12, 0.7, 0.75), "foot_r_pole": (-0.15, 0.5, 0.0), "toes_r": 0.0})],
}
EXERCISES["fire_hydrant"] = {
    "view": "front",
    "seconds": 1.8,
    "props": [{"type": "mat"}],
    "base": QUADRUPED,
    "keys": [(0.0, {}), (0.5, {"foot_l": (0.55, 0.5, 0.42), "foot_l_pole": (0.8, -0.2, 0.4)})],
}
EXERCISES["cat_cow"] = {
    "view": "side",
    "seconds": 3.0,
    "props": [{"type": "mat"}],
    "base": QUADRUPED,
    "keys": [(0.0, {"spine": (25.0, 0.0, 0.0), "head": 20.0}), (0.5, {"spine": (-25.0, 0.0, 0.0), "head": -30.0})],
}
EXERCISES["child_pose"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {"pelvis": (0.0, 0.42, 0.32), "body": (120.0, 0.0, 0.0), "spine": (20.0, 0.0, 0.0), "head": 10.0,
             "hand_l": (0.2, -0.55, 0.05), "hand_r": (-0.2, -0.55, 0.05), "hand_l_pole": (0.3, -0.3, 0.8), "hand_r_pole": (-0.3, -0.3, 0.8),
             "foot_l": (0.1, 0.62, 0.06), "foot_r": (-0.1, 0.62, 0.06), "foot_l_pole": (0.15, -0.4, 0.0), "foot_r_pole": (-0.15, -0.4, 0.0),
             "toes_l": -95.0, "toes_r": -95.0},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.42, 0.33)})],
}
EXERCISES["downward_dog"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {"pelvis": (0.0, 0.2, 0.9), "body": (125.0, 0.0, 0.0), "head": 0.0,
             "hand_l": (0.2, -0.45, 0.06), "hand_r": (-0.2, -0.45, 0.06), "hand_l_pole": (0.3, 0.3, 0.6), "hand_r_pole": (-0.3, 0.3, 0.6),
             "foot_l": (0.12, 0.6, 0.075), "foot_r": (-0.12, 0.6, 0.075), "foot_l_pole": (0.15, -0.5, 0.5), "foot_r_pole": (-0.15, -0.5, 0.5)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.22, 0.93)})],
}
EXERCISES["cobra_stretch"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "mat"}],
    "base": {"pelvis": (0.0, 0.0, 0.11), "body": (90.0, 0.0, 0.0), "foot_l": (0.12, 0.85, 0.06), "foot_r": (-0.12, 0.85, 0.06),
             "foot_l_pole": (0.15, 0.4, 0.8), "foot_r_pole": (-0.15, 0.4, 0.8), "toes_l": -70.0, "toes_r": -70.0,
             "hand_l": (0.2, -0.3, 0.05), "hand_r": (-0.2, -0.3, 0.05), "hand_l_pole": (0.4, 0.3, 0.4), "hand_r_pole": (-0.4, 0.3, 0.4)},
    "keys": [(0.0, {"spine": (-10.0, 0.0, 0.0)}), (0.5, {"spine": (-55.0, 0.0, 0.0), "head": -20.0})],
}

# --- Barre et banc -------------------------------------------------------------------
HANG = {
    "pelvis": (0.0, 0.0, 0.95),
    "hand_l": (0.28, -0.02, 2.15),
    "hand_r": (-0.28, -0.02, 2.15),
    "hand_l_pole": (0.8, 0.2, 1.6),
    "hand_r_pole": (-0.8, 0.2, 1.6),
    "foot_l": (0.08, 0.15, 0.2),
    "foot_r": (-0.08, 0.15, 0.2),
    "foot_l_pole": (0.1, 0.8, 0.5),
    "foot_r_pole": (-0.1, 0.8, 0.5),
    "toes_l": -40.0,
    "toes_r": -40.0,
}
EXERCISES["pull_up_pronated"] = {
    "view": "three_quarter",
    "seconds": 2.4,
    "props": [{"type": "bar", "z": 2.2}],
    "keys": [
        (0.0, {**HANG, "pelvis": (0.0, 0.0, 0.88), "foot_l": (0.08, 0.15, 0.13), "foot_r": (-0.08, 0.15, 0.13), "shrug": 10.0}),
        (0.5, {**HANG, "pelvis": (0.0, 0.0, 1.38), "foot_l": (0.08, 0.15, 0.63), "foot_r": (-0.08, 0.15, 0.63), "head": -10.0}),
    ],
}
EXERCISES["chin_up"] = {
    **EXERCISES["pull_up_pronated"],
    "base": {"hand_l": (0.16, -0.02, 2.15), "hand_r": (-0.16, -0.02, 2.15), "hand_l_pole": (0.3, -0.6, 1.6), "hand_r_pole": (-0.3, -0.6, 1.6)},
}
EXERCISES["inverted_row"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "bar", "z": 0.95, "y": -0.45}],
    "base": {"body": (-62.0, 180.0, 0.0), "hand_l": (0.28, -0.45, 0.95), "hand_r": (-0.28, -0.45, 0.95), "hand_l_pole": (0.6, 0.2, 0.2), "hand_r_pole": (-0.6, 0.2, 0.2),
             "foot_l": (0.12, 0.85, 0.08), "foot_r": (-0.12, 0.85, 0.08), "foot_l_pole": (0.15, 0.4, 1.0), "foot_r_pole": (-0.15, 0.4, 1.0)},
    "keys": [(0.0, {"pelvis": (0.0, 0.1, 0.35), "body": (62.0, 180.0, 0.0)}), (0.5, {"pelvis": (0.0, -0.05, 0.6), "body": (72.0, 180.0, 0.0)})],
}
EXERCISES["dips"] = {
    "view": "three_quarter",
    "seconds": 2.2,
    "props": [{"type": "bar", "z": 1.25, "y": -0.02}],
    "base": {"hand_l": (0.28, -0.02, 1.27), "hand_r": (-0.28, -0.02, 1.27), "hand_l_pole": (0.4, 0.8, 1.4), "hand_r_pole": (-0.4, 0.8, 1.4),
             "foot_l": (0.08, 0.3, 0.45), "foot_r": (-0.08, 0.3, 0.45), "foot_l_pole": (0.1, -0.6, 0.5), "foot_r_pole": (-0.1, -0.6, 0.5)},
    "keys": [(0.0, {"pelvis": (0.0, 0.05, 1.0)}), (0.5, {"pelvis": (0.0, 0.1, 0.72), "body": (15.0, 0.0, 0.0)})],
}
EXERCISES["bench_dips"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "bench", "size": (0.9, 0.4, 0.45), "y": 0.3}],
    "base": {"hand_l": (0.2, 0.2, 0.47), "hand_r": (-0.2, 0.2, 0.47), "hand_l_pole": (0.3, 0.8, 0.8), "hand_r_pole": (-0.3, 0.8, 0.8),
             "foot_l": (0.12, -0.75, 0.075), "foot_r": (-0.12, -0.75, 0.075)},
    "keys": [(0.0, {"pelvis": (0.0, 0.0, 0.5)}), (0.5, {"pelvis": (0.0, 0.03, 0.25)})],
}
EXERCISES["cycling"] = {
    "view": "side",
    "seconds": 1.0,
    "props": [{"type": "box", "size": (0.3, 0.3, 0.75), "y": 0.12}],
    "base": {"pelvis": (0.0, 0.1, 0.85), "body": (25.0, 0.0, 0.0), "hand_l": (0.22, -0.45, 1.05), "hand_r": (-0.22, -0.45, 1.05),
             "hand_l_pole": (0.4, 0.3, 0.6), "hand_r_pole": (-0.4, 0.3, 0.6)},
    "keys": [
        (0.0, {"foot_l": (0.14, -0.35, 0.45), "foot_r": (-0.14, -0.1, 0.12)}),
        (0.25, {"foot_l": (0.14, -0.15, 0.25), "foot_r": (-0.14, -0.25, 0.4)}),
        (0.5, {"foot_l": (0.14, -0.1, 0.12), "foot_r": (-0.14, -0.35, 0.45)}),
        (0.75, {"foot_l": (0.14, -0.25, 0.4), "foot_r": (-0.14, -0.15, 0.25)}),
    ],
}
# --- Mobilité et étirements ---------------------------------------------------------
EXERCISES["hip_circles"] = {
    "view": "front",
    "seconds": 2.0,
    "base": {**WIDE, "hand_l": (0.2, 0.05, 1.0), "hand_r": (-0.2, 0.05, 1.0), "hand_l_pole": (0.6, 0.3, 1.0), "hand_r_pole": (-0.6, 0.3, 1.0)},
    "keys": [
        (0.0, {"pelvis": (0.06, 0.0, 0.91)}),
        (0.25, {"pelvis": (0.0, -0.06, 0.91)}),
        (0.5, {"pelvis": (-0.06, 0.0, 0.91)}),
        (0.75, {"pelvis": (0.0, 0.06, 0.91)}),
    ],
}
EXERCISES["neck_mobility"] = {
    "view": "front",
    "seconds": 2.4,
    "keys": [(0.0, {"head": 20.0}), (0.25, {"head": 0.0, "spine": (0.0, 0.0, 6.0)}), (0.5, {"head": -25.0}), (0.75, {"head": 0.0, "spine": (0.0, 0.0, -6.0)})],
}
EXERCISES["thoracic_rotation"] = {
    "view": "front",
    "seconds": 2.4,
    "base": {**WIDE, "hand_l": (0.3, -0.35, 1.42), "hand_r": (-0.3, -0.35, 1.42), "hand_l_pole": (0.6, 0.3, 1.2), "hand_r_pole": (-0.6, 0.3, 1.2)},
    "keys": [(0.0, {"spine": (0.0, 40.0, 0.0)}), (0.5, {"spine": (0.0, -40.0, 0.0)})],
}
EXERCISES["shoulder_stretch"] = {
    "view": "front",
    "seconds": 2.0,
    "keys": [
        (0.0, {"hand_l": (-0.35, -0.2, 1.35), "hand_l_pole": (0.2, -0.6, 1.4), "hand_r": (0.0, -0.28, 1.3)}),
        (0.5, {"hand_r": (0.35, -0.2, 1.35), "hand_r_pole": (-0.2, -0.6, 1.4), "hand_l": (0.0, -0.28, 1.3)}),
    ],
}
EXERCISES["chest_stretch"] = {
    "view": "three_quarter",
    "seconds": 2.0,
    "base": {"hand_l_pole": (0.4, -0.3, 0.6), "hand_r_pole": (-0.4, -0.3, 0.6)},
    "keys": [(0.0, {"hand_l": (0.3, 0.45, 0.95), "hand_r": (-0.3, 0.45, 0.95), "head": 10.0}), (0.5, {"hand_l": (0.32, 0.5, 0.9), "hand_r": (-0.32, 0.5, 0.9), "head": 15.0, "spine": (-8.0, 0.0, 0.0)})],
}
EXERCISES["quad_stretch"] = {
    "view": "side",
    "seconds": 2.4,
    "keys": [
        (0.0, {"foot_l": (0.12, 0.35, 0.72), "foot_l_pole": (0.15, -1.0, 0.0), "hand_l": (0.16, 0.38, 0.78), "hand_r": (-0.4, -0.1, 1.2)}),
        (0.5, {"foot_r": (-0.12, 0.35, 0.72), "foot_r_pole": (-0.15, -1.0, 0.0), "hand_r": (-0.16, 0.38, 0.78), "hand_l": (0.4, -0.1, 1.2)}),
    ],
}
EXERCISES["hamstring_stretch"] = {
    "view": "side",
    "seconds": 2.4,
    "base": {"foot_l": (0.12, -0.45, 0.075), "foot_r": (-0.12, 0.2, 0.075), "toes_l": 30.0},
    "keys": [(0.0, {"pelvis": (0.0, 0.08, 0.86), "body": (35.0, 0.0, 0.0), "hand_l": (0.12, -0.35, 0.55), "hand_r": (-0.12, -0.35, 0.55)}),
             (0.5, {"pelvis": (0.0, 0.12, 0.84), "body": (55.0, 0.0, 0.0), "hand_l": (0.12, -0.45, 0.25), "hand_r": (-0.06, -0.45, 0.25)})],
}
EXERCISES["calf_stretch"] = {
    "view": "side",
    "seconds": 2.0,
    "props": [{"type": "box", "size": (1.2, 0.2, 1.8), "y": -0.85}],
    "base": {"pelvis": (0.0, -0.05, 0.88), "body": (15.0, 0.0, 0.0), "foot_l": (0.12, -0.35, 0.075), "foot_r": (-0.12, 0.35, 0.075),
             "hand_l": (0.22, -0.72, 1.4), "hand_r": (-0.22, -0.72, 1.4), "hand_l_pole": (0.4, 0.2, 0.8), "hand_r_pole": (-0.4, 0.2, 0.8)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, -0.08, 0.86), "body": (20.0, 0.0, 0.0)})],
}
EXERCISES["hip_flexor_stretch"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "mat"}],
    "base": {"foot_l": (0.12, -0.45, 0.075), "foot_r": (-0.12, 0.55, 0.05), "toes_r": -80.0, "foot_r_pole": (-0.15, -0.3, -0.5),
             "hand_l": (0.15, -0.35, 0.55), "hand_r": (-0.15, -0.35, 0.55)},
    "keys": [(0.0, {"pelvis": (0.0, 0.12, 0.5)}), (0.5, {"pelvis": (0.0, 0.02, 0.46), "spine": (-8.0, 0.0, 0.0)})],
}
EXERCISES["lunge_twist_stretch"] = {
    "view": "three_quarter",
    "seconds": 2.6,
    "base": {**EXERCISES["lunge"]["base"], "pelvis": (0.0, 0.04, 0.52)},
    "keys": [(0.0, {"spine": (0.0, 35.0, 0.0), "hand_l": (0.45, 0.1, 1.2), "hand_r": (0.05, -0.4, 0.75)}),
             (0.5, {"spine": (0.0, 0.0, 0.0), "hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)})],
}
EXERCISES["butterfly_stretch"] = {
    "view": "front",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {"pelvis": (0.0, 0.05, 0.13), "body": (-10.0, 0.0, 0.0), "foot_l": (0.04, -0.4, 0.07), "foot_r": (-0.04, -0.4, 0.07),
             "foot_l_pole": (0.9, -0.2, 0.2), "foot_r_pole": (-0.9, -0.2, 0.2), "toes_l": 0.0, "toes_r": 0.0,
             "hand_l": (0.05, -0.42, 0.12), "hand_r": (-0.05, -0.42, 0.12)},
    "keys": [(0.0, {}), (0.5, {"body": (15.0, 0.0, 0.0), "spine": (10.0, 0.0, 0.0)})],
}
EXERCISES["pigeon_stretch"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "mat"}],
    "base": {"pelvis": (0.0, 0.0, 0.2), "body": (10.0, 0.0, 0.0), "foot_l": (-0.2, -0.3, 0.07), "foot_l_pole": (0.8, -0.3, 0.2),
             "foot_r": (-0.12, 0.85, 0.06), "toes_r": -80.0, "foot_r_pole": (-0.15, 0.4, -0.5),
             "hand_l": (0.2, -0.35, 0.05), "hand_r": (-0.2, -0.35, 0.05)},
    "keys": [(0.0, {}), (0.5, {"body": (40.0, 0.0, 0.0), "hand_l": (0.2, -0.55, 0.05), "hand_r": (-0.2, -0.55, 0.05)})],
}

# --- Corrections --------------------------------------------------------------------
# Planche, tapes sur les épaules : la main levée vient toucher l'épaule
# opposée, le bassin reste fixe (pieds écartés pour la stabilité).
EXERCISES["plank_shoulder_taps"] = {
    "view": "three_quarter",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": {**PLANK_UP, "foot_l": (0.2, 0.83, 0.1), "foot_r": (-0.2, 0.83, 0.1)},
    "keys": [
        (0.0, {}),
        (0.25, {"hand_l": (-0.12, -0.42, 0.42), "hand_l_pole": (0.5, -0.2, 0.2)}),
        (0.5, {}),
        (0.75, {"hand_r": (0.12, -0.42, 0.42), "hand_r_pole": (-0.5, -0.2, 0.2)}),
    ],
}
# Assis, buste incliné en arrière, pieds décollés : les mains jointes passent
# d'une hanche à l'autre avec la rotation du buste.
SEATED_V = {
    "pelvis": (0.0, 0.0, 0.14),
    "body": (-35.0, 0.0, 0.0),
    "head": 10.0,
    "foot_l": (0.1, -0.5, 0.22),
    "foot_r": (-0.1, -0.5, 0.22),
    "foot_l_pole": (0.2, -0.5, 1.2),
    "foot_r_pole": (-0.2, -0.5, 1.2),
    "hand_l_pole": (0.5, 0.3, 0.4),
    "hand_r_pole": (-0.5, 0.3, 0.4),
}
EXERCISES["russian_twist"] = {
    "view": "three_quarter",
    "seconds": 2.0,
    "props": [{"type": "mat"}],
    "base": SEATED_V,
    "keys": [
        (0.0, {"spine": (0.0, 30.0, 0.0), "hand_l": (0.3, -0.2, 0.22), "hand_r": (0.22, -0.26, 0.22)}),
        (0.5, {"spine": (0.0, -30.0, 0.0), "hand_l": (-0.22, -0.26, 0.22), "hand_r": (-0.3, -0.2, 0.22)}),
    ],
}
# Rotation thoracique : bras croisés sur la poitrine, bassin immobile.
EXERCISES["thoracic_rotation"] = {
    "view": "front",
    "seconds": 3.0,
    "base": {**WIDE, "hand_l": (-0.14, -0.14, 1.38), "hand_r": (0.14, -0.14, 1.4), "hand_l_pole": (0.4, -0.5, 1.1), "hand_r_pole": (-0.4, -0.5, 1.1)},
    "keys": [(0.0, {}), (0.25, {"spine": (0.0, 40.0, 0.0)}), (0.5, {}), (0.75, {"spine": (0.0, -40.0, 0.0)})],
}

# --- Mouvements du catalogue sans clé propre ------------------------------------------
EXERCISES["calf_raise"] = EXERCISES["standing_calf_raise"]
EXERCISES["pull_up"] = EXERCISES["pull_up_pronated"]
CROUCH_HANDS_DOWN = {
    "pelvis": (0.0, 0.18, 0.5),
    "body": (45.0, 0.0, 0.0),
    "head": -25.0,
    "foot_l": (0.14, 0.0, 0.075),
    "foot_r": (-0.14, 0.0, 0.075),
    "hand_l": (0.2, -0.32, 0.06),
    "hand_r": (-0.2, -0.32, 0.06),
    "hand_l_pole": (0.5, 0.3, 0.5),
    "hand_r_pole": (-0.5, 0.3, 0.5),
}
EXERCISES["burpee"] = {
    "view": "side",
    "seconds": 3.0,
    "props": [{"type": "mat"}],
    "keys": [
        (0.0, {}),
        (0.18, CROUCH_HANDS_DOWN),
        (0.38, {**PLANK_UP}),
        (0.58, CROUCH_HANDS_DOWN),
        (0.78, {"pelvis": (0.0, 0.0, 1.06), "foot_l": (0.12, 0.0, 0.22), "foot_r": (-0.12, 0.0, 0.22), "toes_l": -40.0, "toes_r": -40.0,
                "hand_l": (0.28, -0.08, 1.92), "hand_r": (-0.28, -0.08, 1.92), "hand_l_pole": (0.9, 0.3, 1.6), "hand_r_pole": (-0.9, 0.3, 1.6)}),
    ],
}

# --- Lot 7 (ANATOMY §2 bis, en attente de validation) --------------------------------
LUNGE_L = {"pelvis": (0.0, 0.04, 0.52), "foot_l": (0.12, -0.38, 0.075), "foot_r": (-0.12, 0.42, 0.12), "toes_r": -50.0,
           "foot_r_pole": (-0.15, -0.4, -0.3), "hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)}
LUNGE_R = {"pelvis": (0.0, 0.04, 0.52), "foot_r": (-0.12, -0.38, 0.075), "foot_l": (0.12, 0.42, 0.12), "toes_l": -50.0,
           "foot_l_pole": (0.15, -0.4, -0.3), "hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)}
AIR = {"pelvis": (0.0, 0.02, 1.02), "foot_l": (0.12, -0.05, 0.3), "foot_r": (-0.12, 0.05, 0.3), "toes_l": -30.0, "toes_r": -30.0,
       "hand_l": (0.25, -0.15, 1.1), "hand_r": (-0.25, -0.15, 1.1)}
EXERCISES["jump_lunge"] = {
    "view": "side",
    "seconds": 1.8,
    "keys": [(0.0, LUNGE_L), (0.25, AIR), (0.5, LUNGE_R), (0.75, AIR)],
}
EXERCISES["walking_lunge"] = {
    "view": "side",
    "seconds": 3.0,
    "keys": [(0.0, LUNGE_L), (0.25, {"hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)}),
             (0.5, LUNGE_R), (0.75, {"hand_l": (0.2, 0.0, 0.92), "hand_r": (-0.2, 0.0, 0.92)})],
}
EXERCISES["plank_up_down"] = {
    "view": "side",
    "seconds": 3.2,
    "props": [{"type": "mat"}],
    "keys": [
        (0.0, FOREARM_PLANK),
        (0.25, {**FOREARM_PLANK, "pelvis": (0.0, 0.03, 0.38), "body": (72.0, 0.0, 0.0),
                "hand_r": PLANK_UP["hand_r"], "hand_r_pole": PLANK_UP["hand_r_pole"]}),
        (0.5, PLANK_UP),
        (0.75, {**PLANK_UP, "pelvis": (0.0, 0.03, 0.38), "body": (72.0, 0.0, 0.0),
                "hand_l": FOREARM_PLANK["hand_l"], "hand_l_pole": FOREARM_PLANK["hand_l_pole"]}),
    ],
}
ARCHER_UP = {**PLANK_UP, "hand_l": (0.45, -0.43, 0.06), "hand_r": (-0.45, -0.43, 0.06), "foot_l": (0.2, 0.83, 0.1), "foot_r": (-0.2, 0.83, 0.1)}
EXERCISES["archer_push_up"] = {
    "view": "front",
    "seconds": 3.2,
    "props": [{"type": "mat"}],
    "keys": [
        (0.0, ARCHER_UP),
        (0.25, {**ARCHER_UP, "pelvis": (0.12, 0.0, 0.3), "body": (78.0, 0.0, 0.0), "hand_l_pole": (0.7, 0.3, 0.4), "hand_r_pole": (-0.6, -0.4, 0.3)}),
        (0.5, ARCHER_UP),
        (0.75, {**ARCHER_UP, "pelvis": (-0.12, 0.0, 0.3), "body": (78.0, 0.0, 0.0), "hand_r_pole": (-0.7, 0.3, 0.4), "hand_l_pole": (0.6, -0.4, 0.3)}),
    ],
}
EXERCISES["front_raise"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "dumbbells"}],
    "base": {"foot_l": (0.14, 0.0, 0.075), "foot_r": (-0.14, 0.0, 0.075), "hand_l_pole": (0.3, 0.6, 1.2), "hand_r_pole": (-0.3, 0.6, 1.2)},
    "keys": [
        (0.0, {"hand_l": (0.18, -0.08, 0.86), "hand_r": (-0.18, -0.08, 0.86)}),
        (0.5, {"hand_l": (0.2, -0.68, 1.44), "hand_r": (-0.2, -0.68, 1.44)}),
    ],
}
EXERCISES["deadlift"] = {
    "view": "side",
    "seconds": 2.6,
    "props": [{"type": "dumbbells"}],
    "base": {"foot_l": (0.14, 0.0, 0.075), "foot_r": (-0.14, 0.0, 0.075), "hand_l": (0.16, -0.06, 0.8), "hand_r": (-0.16, -0.06, 0.8)},
    "keys": [(0.0, {}), (0.5, {"pelvis": (0.0, 0.2, 0.62), "body": (52.0, 0.0, 0.0), "head": -20.0,
                                "hand_l": (0.16, -0.12, 0.2), "hand_r": (-0.16, -0.12, 0.2)})],
}
EXERCISES["one_arm_row"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "dumbbells", "sides": ("r",)}, {"type": "bench", "size": (0.5, 0.5, 0.45), "y": -0.42}],
    "base": {**BENT, "body": (65.0, 0.0, 0.0), "foot_l": (0.2, 0.05, 0.075), "foot_r": (-0.2, 0.05, 0.075),
             "hand_l": (0.16, -0.48, 0.47), "hand_l_pole": (0.4, 0.4, 1.0), "hand_r_pole": (-0.3, 0.8, 1.4)},
    "keys": [(0.0, {"hand_r": (-0.18, -0.3, 0.4)}), (0.5, {"hand_r": (-0.2, 0.0, 0.8)})],
}
EXERCISES["floor_press"] = {
    "view": "side",
    "seconds": 2.4,
    "props": [{"type": "mat"}, {"type": "dumbbells"}],
    "base": {**SUPINE, "hand_l_pole": (0.7, -0.35, -0.2), "hand_r_pole": (-0.7, -0.35, -0.2)},
    "keys": [
        (0.0, {"hand_l": (0.2, -0.42, 0.78), "hand_r": (-0.2, -0.42, 0.78)}),
        (0.5, {"hand_l": (0.26, -0.42, 0.32), "hand_r": (-0.26, -0.42, 0.32)}),
    ],
}
EXERCISES["good_morning"] = {
    "view": "side",
    "seconds": 2.6,
    "base": {**WIDE, "hand_l_pole": (0.7, -0.1, 1.5), "hand_r_pole": (-0.7, -0.1, 1.5)},
    "keys": [
        (0.0, {"hand_l": (0.08, 0.1, 1.6), "hand_r": (-0.08, 0.1, 1.6)}),
        (0.5, {"pelvis": (0.0, 0.15, 0.88), "body": (65.0, 0.0, 0.0), "head": -10.0,
               "hand_l": (0.08, -0.4, 1.24), "hand_r": (-0.08, -0.4, 1.24), "hand_l_pole": (0.7, -0.3, 1.0), "hand_r_pole": (-0.7, -0.3, 1.0)}),
    ],
}
EXERCISES["reverse_crunch"] = {
    "view": "side",
    "seconds": 2.2,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "hand_l": (0.25, 0.1, 0.05), "hand_r": (-0.25, 0.1, 0.05), "foot_l_pole": (0.1, -0.3, 1.2), "foot_r_pole": (-0.1, -0.3, 1.2)},
    "keys": [
        (0.0, {"foot_l": (0.08, 0.32, 0.45), "foot_r": (-0.08, 0.32, 0.45)}),
        (0.5, {"pelvis": (0.0, 0.0, 0.17), "foot_l": (0.08, -0.12, 0.7), "foot_r": (-0.08, -0.12, 0.7)}),
    ],
}
SIDE_LYING = {
    "pelvis": (0.0, 0.0, 0.17),
    "body": (0.0, -90.0, 0.0),
    "head": 0.0,
    "hand_r": (-0.72, 0.0, 0.12),
    "hand_r_pole": (-0.5, 0.5, 0.2),
    "hand_l": (-0.2, -0.22, 0.05),
    "hand_l_pole": (-0.2, 0.2, 0.6),
    "foot_r": (0.88, 0.0, 0.06),
    "foot_l": (0.88, 0.0, 0.2),
    "foot_l_pole": (0.4, -0.8, 0.2),
    "foot_r_pole": (0.4, -0.8, 0.06),
}
EXERCISES["side_lying_leg_raise"] = {
    "view": "front",
    "seconds": 2.2,
    "props": [{"type": "mat"}],
    "base": SIDE_LYING,
    "keys": [(0.0, {}), (0.5, {"foot_l": (0.8, 0.0, 0.58)})],
}
EXERCISES["tibialis_raise"] = {
    "view": "side",
    "seconds": 1.8,
    "props": [{"type": "box", "size": (1.2, 0.2, 1.8), "y": 0.3}],
    "base": {"pelvis": (0.0, 0.08, 0.9), "body": (-6.0, 0.0, 0.0), "foot_l": (0.12, -0.25, 0.075), "foot_r": (-0.12, -0.25, 0.075),
             "hand_l": (0.22, 0.12, 0.85), "hand_r": (-0.22, 0.12, 0.85)},
    "keys": [(0.0, {}), (0.5, {"toes_l": 35.0, "toes_r": 35.0, "foot_l": (0.12, -0.25, 0.11), "foot_r": (-0.12, -0.25, 0.11)})],
}
BEAR = {**QUADRUPED, "pelvis": (0.0, 0.25, 0.64), "toes_l": -60.0, "toes_r": -60.0,
        "foot_l": (0.14, 0.55, 0.08), "foot_r": (-0.14, 0.55, 0.08), "foot_l_pole": (0.15, -0.6, 0.5), "foot_r_pole": (-0.15, -0.6, 0.5)}
EXERCISES["bear_crawl"] = {
    "view": "side",
    "seconds": 1.6,
    "props": [{"type": "mat"}],
    "base": BEAR,
    "keys": [
        (0.0, {"hand_l": (0.18, -0.38, 0.06), "foot_r": (-0.14, 0.42, 0.1)}),
        (0.5, {"hand_r": (-0.18, -0.38, 0.06), "foot_l": (0.14, 0.42, 0.1)}),
    ],
}
EXERCISES["star_jump"] = {
    "view": "front",
    "seconds": 1.6,
    "keys": [
        (0.0, {"pelvis": (0.0, 0.12, 0.62), "body": (22.0, 0.0, 0.0), "head": -15.0, "foot_l": (0.15, 0.0, 0.075), "foot_r": (-0.15, 0.0, 0.075),
               "hand_l": (0.16, -0.3, 0.7), "hand_r": (-0.16, -0.3, 0.7)}),
        (0.4, {"pelvis": (0.0, 0.0, 1.2), "foot_l": (0.42, 0.0, 0.35), "foot_r": (-0.42, 0.0, 0.35), "toes_l": -30.0, "toes_r": -30.0,
               "hand_l": (0.8, -0.05, 1.95), "hand_r": (-0.8, -0.05, 1.95), "hand_l_pole": (0.9, 0.3, 1.6), "hand_r_pole": (-0.9, 0.3, 1.6)}),
        (0.7, {}),
    ],
}
EXERCISES["figure_four_stretch"] = {
    "view": "three_quarter",
    "seconds": 2.4,
    "props": [{"type": "mat"}],
    "base": {**SUPINE, "foot_l": (0.12, -0.02, 0.55), "foot_l_pole": (0.15, -0.3, 1.2),
             "foot_r": (0.06, 0.08, 0.5), "foot_r_pole": (-0.7, 0.0, 0.6), "toes_r": 0.0,
             "hand_l": (0.16, -0.1, 0.42), "hand_r": (0.0, -0.1, 0.42), "hand_l_pole": (0.5, -0.3, 0.3), "hand_r_pole": (-0.5, -0.3, 0.3)},
    "keys": [(0.0, {}), (0.5, {"foot_l": (0.12, -0.1, 0.58), "foot_r": (0.06, 0.0, 0.53), "hand_l": (0.16, -0.18, 0.45), "hand_r": (0.0, -0.18, 0.45)})],
}
