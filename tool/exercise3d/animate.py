"""Démonstrations d'exercices en 3D : le héros (modèle de build_characters.py)
exécute chaque exercice, filmé dans la cour d'entraînement.

Les mouvements sont décrits par des poses clés (poses.py) : position et
inclinaison du bassin, flexion du dos, cibles des mains et des pieds. Les
bras et les jambes sont résolus par cinématique inverse (IK) : les pieds
restent au sol, les mains sur la barre ou au sol, les coudes et les genoux
plient dans le bon sens. Rendu Cycles, images assemblées en WebP animé par
tool/coach/encode.sh.

Usage (module « bpy ») :
    python tool/exercise3d/animate.py <modèle .glb brut> <sortie> [exercice ...]

Variables : ARISE_PBR (matières ambientCG), ARISE_SAMPLES (16 par défaut),
ARISE_FRAMES (indices des images à rendre, pour un contrôle rapide).
"""

import math
import os
import sys

import bpy
from mathutils import Euler, Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "coach"))
from poses import EXERCISES, REST  # noqa: E402

FPS = 15
SIZE = (600, 450)
# Pièces visibles : corps, tête, tenue de départ, coiffure courte.
VISIBLE = ("body", "eye_", "lashes", "brow_01", "hair_07", "outfit_tunic", "outfit_pants", "outfit_boots")


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    if arm.animation_data:
        for t in arm.animation_data.nla_tracks:
            t.mute = True
        arm.animation_data.action = None
    for o in list(bpy.context.scene.objects):
        if o.type != "MESH":
            continue
        n = o.name
        keep = n == "body" or any(n.startswith(p) for p in VISIBLE[1:])
        if not keep:
            bpy.data.objects.remove(o, do_unlink=True)
        elif o.data.shape_keys:
            for kb in o.data.shape_keys.key_blocks[1:]:
                kb.value = 0
    return arm


def empty(name, loc=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    e.location = loc
    return e


def setup_ik(arm):
    """Cibles et pôles (objets vides) des bras et des jambes."""
    rig = {}
    for side in ("l", "r"):
        for limb, bone, chain in (("hand", "lowerarm_" + side, 2), ("foot", "calf_" + side, 2)):
            target = empty(f"{limb}_{side}")
            pole = empty(f"{limb}_pole_{side}")
            c = arm.pose.bones[bone].constraints.new("IK")
            c.target = target
            c.pole_target = pole
            c.chain_count = chain
            c.use_tail = True
            rig[f"{limb}_{side}"] = (target, pole, c)
    return rig


def pole_angles(arm, rig):
    """Angle de pôle de chaque chaîne (il dépend du roulis des os) : celui
    pour lequel le coude ou le genou, la chaîne pliée, part vers le pôle."""
    bpy.context.view_layer.update()
    for key, (target, pole, c) in rig.items():
        side = key[-1]
        limb = key[:-2]
        lower = ("lowerarm_" if limb == "hand" else "calf_") + side
        upper = arm.data.bones[lower].parent.name
        root = arm.matrix_world @ arm.data.bones[upper].head_local
        tip = arm.matrix_world @ arm.data.bones[lower].tail_local
        # Chaîne pliée : cible rapprochée de la racine.
        target.location = root + (tip - root) * 0.7
        axis = (target.location - root).normalized()
        out = Vector((0, -1, 0)) if limb == "foot" else Vector((0, 1, 0))
        pole.location = root + (tip - root) * 0.5 + out * 0.5
        want = (pole.location - root) - axis * (pole.location - root).dot(axis)
        best, best_dot = 0.0, None
        for deg in range(-180, 180, 5):
            c.pole_angle = math.radians(deg)
            bpy.context.view_layer.update()
            mid = arm.matrix_world @ arm.pose.bones[lower].head
            bend = (mid - root) - axis * (mid - root).dot(axis)
            d = bend.normalized().dot(want.normalized()) if bend.length > 1e-5 else -1
            if best_dot is None or d > best_dot:
                best, best_dot = deg, d
        c.pole_angle = math.radians(best)


def smooth(t):
    return 0.5 - math.cos(t * math.pi) / 2


def lerp(a, b, t):
    if isinstance(a, (tuple, list)):
        return tuple(x + (y - x) * t for x, y in zip(a, b))
    return a + (b - a) * t


def pose_at(ex, t):
    """Pose interpolée au temps t (0 à 1) du cycle : les clés sont (instant,
    pose) ; chaque champ absent reprend la pose de repos."""
    keys = ex["keys"]
    full = [(k[0], {**REST, **ex.get("base", {}), **k[1]}) for k in keys]
    full.append((1.0, full[0][1]))
    for (t0, p0), (t1, p1) in zip(full, full[1:]):
        if t0 <= t <= t1:
            u = smooth((t - t0) / max(t1 - t0, 1e-6))
            return {k: lerp(p0[k], p1[k], u) if k in p1 and not isinstance(p0[k], str) else p0[k] for k in p0}
    return full[0][1]


def apply(arm, rig, pose):
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    pelvis = arm.pose.bones["pelvis"]
    rot = Euler([math.radians(a) for a in pose["body"]], "XYZ").to_matrix().to_4x4()
    m = pelvis.matrix.copy()
    pelvis.matrix = Matrix.Translation(Vector(pose["pelvis"])) @ rot @ Matrix(m.to_3x3()).to_4x4()
    bpy.context.view_layer.update()
    # Flexion du dos répartie sur les trois vertèbres, torsion, tête.
    bend, twist, side = pose["spine"]
    for name in ("spine_01", "spine_02", "spine_03"):
        pb = arm.pose.bones[name]
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (math.radians(bend / 3), math.radians(twist / 3), math.radians(side / 3))
    head = arm.pose.bones["head"]
    head.rotation_mode = "XYZ"
    head.rotation_euler = (math.radians(pose["head"]), 0, 0)
    # Clavicules (épaules haussées) et poignets.
    for s in ("l", "r"):
        cl = arm.pose.bones["clavicle_" + s]
        cl.rotation_mode = "XYZ"
        cl.rotation_euler = (0, 0, math.radians(pose["shrug"]) * (1 if s == "l" else -1))
    for key, (target, pole, c) in rig.items():
        target.location = Vector(pose[key])
        pole.location = Vector(pose[key + "_pole"])
    bpy.context.view_layer.update()
    # Pieds : à plat au sol, ou sur la pointe (planche, pompes).
    for s in ("l", "r"):
        foot = arm.pose.bones["foot_" + s]
        foot.rotation_mode = "XYZ"
        foot.rotation_euler = (math.radians(pose["toes_" + s]), 0, 0)
    bpy.context.view_layer.update()


def stage(view, props, arm):
    """Cour d'entraînement : sol pavé, mur de pierre, lumière chaude, caméra
    de trois quarts (ou de profil) ; accessoires de l'exercice."""
    from animate_coach import WORLDS, pbr_material

    cfg = WORLDS["medieval"]
    scene = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.scale = (14, 14, 1)
    floor.data.materials.append(pbr_material("floor", cfg["floor"], cfg["floor_tile"] * 7, cfg["floor_tint"]))
    wall_mat = pbr_material("wall", cfg["back"], cfg["back_tile"] * 7, cfg["back_tint"])
    for loc, rot in (((0, 2.6, 3), (math.radians(90), 0, 0)), ((2.6, 0, 3), (math.radians(90), 0, math.radians(90)))):
        bpy.ops.mesh.primitive_plane_add(size=1, location=loc, rotation=rot)
        wall = bpy.context.active_object
        wall.scale = (14, 6, 1)
        wall.data.materials.append(wall_mat)
    _tint_hero()
    scene.world = bpy.data.worlds.new("sky")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (*cfg["sky"], 1)
    for p in props:
        add_prop(p, arm)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 42
    look = Vector((0, 0, 0.8))
    if view == "side":
        cam.location = Vector((-3.6, -1.6, 1.25))
        look = Vector((0, -0.1, 0.55))
    elif view == "front":
        cam.location = Vector((0.7, -4.0, 1.3))
    else:
        cam.location = Vector((2.3, -3.3, 1.35))
    cam.rotation_euler = (look - cam.location).to_track_quat("-Z", "Y").to_euler()
    for name, loc, energy, color, size in (
        ("key", (2.5, -2.5, 3.2), 650, cfg["key"], 3),
        ("fill", (-3, -2, 1.5), 180, (0.8, 0.85, 1.0), 3),
        ("rim", (-1.5, 1.5, 3), 450, cfg["rim"], 2),
    ):
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.color, data.size = energy, color, size
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = (look - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    scene.render.engine = "CYCLES"
    scene.cycles.samples = int(os.environ.get("ARISE_SAMPLES", "16"))
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = SIZE


SKIN = (0.62, 0.42, 0.3, 1.0)
HAIR = (0.13, 0.07, 0.03, 1.0)


def _tint_hero():
    """Teintes du héros de démonstration (peau, cheveux), comme dans
    l'application (texture grise × couleur)."""
    for mat in bpy.data.materials:
        rgba = SKIN if mat.name == "skin" or mat.name.startswith("skin_body") else HAIR if mat.name.startswith(("hair_", "brow_")) else None
        if rgba is None or not mat.use_nodes:
            continue
        nt = mat.node_tree
        bsdf = next((n for n in nt.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled"), None)
        tex = next((n for n in nt.nodes if n.bl_idname == "ShaderNodeTexImage"), None)
        if bsdf is None:
            continue
        if tex is None:
            bsdf.inputs["Base Color"].default_value = rgba
            continue
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        ins = [i for i in mix.inputs if i.type == "RGBA"]
        outs = [o for o in mix.outputs if o.type == "RGBA"]
        nt.links.new(tex.outputs["Color"], ins[0])
        ins[1].default_value = rgba
        nt.links.new(outs[0], bsdf.inputs["Base Color"])


def _mat(name, rgb, metal=0.0, rough=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    return m


def add_prop(prop, arm):
    """Accessoires : haltères dans les mains, barre fixe, banc, caisse,
    tapis, corde."""
    kind = prop["type"]
    iron = _mat("iron", (0.18, 0.18, 0.2), 1.0, 0.35)
    wood = _mat("wood", (0.28, 0.16, 0.08), 0.0, 0.7)
    if kind == "dumbbells":
        bones = arm.data.bones
        for s in ("l", "r"):
            # Haltère dans le poing (pose de repos) : poignée selon l'axe des
            # doigts (index → auriculaire), au creux de la main.
            idx = arm.matrix_world @ bones["index_01_" + s].head_local
            pinky = arm.matrix_world @ bones["pinky_01_" + s].head_local
            wrist = arm.matrix_world @ bones["hand_" + s].head_local
            across = (idx - pinky).normalized()
            grip = (idx + pinky) / 2 * 0.6 + wrist * 0.4
            parts = []
            bpy.ops.mesh.primitive_cylinder_add(radius=0.016, depth=0.2, location=(0, 0, 0))
            parts.append(bpy.context.active_object)
            for off in (-0.08, 0.08):
                bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.05, location=(0, 0, off))
                parts.append(bpy.context.active_object)
            bpy.ops.object.select_all(action="DESELECT")
            for o in parts:
                o.select_set(True)
            bpy.context.view_layer.objects.active = parts[0]
            bpy.ops.object.join()
            bar = bpy.context.active_object
            bar.data.materials.append(iron)
            bar.matrix_world = Matrix.Translation(grip) @ Vector((0, 0, 1)).rotation_difference(across).to_matrix().to_4x4()
            world = bar.matrix_world.copy()
            bar.parent = arm
            bar.parent_type = "BONE"
            bar.parent_bone = "hand_" + s
            bpy.context.view_layer.update()
            bar.matrix_world = world
    elif kind == "bar":
        bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=1.6, location=(0, prop.get("y", -0.02), prop["z"]), rotation=(0, math.radians(90), 0))
        bpy.context.active_object.data.materials.append(iron)
        for x in (-0.8, 0.8):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=prop["z"], location=(x, prop.get("y", -0.02), prop["z"] / 2))
            bpy.context.active_object.data.materials.append(wood)
    elif kind in ("bench", "box"):
        w, d, h = prop.get("size", (0.5, 1.2, 0.45))
        bpy.ops.mesh.primitive_cube_add(size=1, location=(prop.get("x", 0), prop.get("y", 0.4), h / 2))
        o = bpy.context.active_object
        o.scale = (w, d, h)
        o.data.materials.append(wood)
    elif kind == "mat":
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, prop.get("y", 0.2), 0.006))
        o = bpy.context.active_object
        o.scale = (0.7, 1.9, 0.012)
        o.data.materials.append(_mat("mat", (0.25, 0.12, 0.07), 0.0, 0.9))


def render(arm, rig, ex, name, out):
    frames = int(ex.get("seconds", 2.0) * FPS)
    only = os.environ.get("ARISE_FRAMES")
    wanted = {int(x) for x in only.split(",")} if only else None
    scene = bpy.context.scene
    stage(ex.get("view", "three_quarter"), ex.get("props", []), arm)
    os.makedirs(out, exist_ok=True)
    for f in range(frames):
        if wanted is not None and f not in wanted:
            continue
        apply(arm, rig, pose_at(ex, f / frames))
        scene.render.filepath = os.path.join(out, f"{name}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)


def main(model, out, names):
    for name in names or list(EXERCISES):
        arm = load(model)
        rig = setup_ik(arm)
        pole_angles(arm, rig)
        render(arm, rig, EXERCISES[name], name, out)
        print("EXERCICE", name, flush=True)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(args[0], args[1], args[2:])
