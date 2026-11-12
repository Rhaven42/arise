"""Vidéos des profs : le prof d'un monde exécute chaque exercice.

Les mouvements viennent de `assets/animations/motions.json` (ceux du
mannequin 2D, vérifiés image par image) : chaque segment du mannequin donne
la direction d'un os du squelette du prof, dans le plan de la vue (profil ou
face). Le rendu (Cycles) se fait dans un décor du monde, puis les images
sont assemblées en WebP animé par `encode.sh`.

Usage (module « bpy » de PyPI, même version de Blender) :
    python tool/coach/animate_coach.py <prof.glb> <monde> <sortie> [mouvement ...]

Variables : ARISE_PBR (matières ambientCG décompressées), ARISE_SAMPLES
(échantillons Cycles, 16 par défaut), ARISE_FRAMES (indices des images à
rendre, pour un contrôle rapide).
"""

import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from motions import joints as stick_joints  # noqa: E402

MOTIONS = os.path.join(HERE, "..", "..", "assets", "animations", "motions.json")
FPS = 15
SIZE = (600, 450)

# Longueurs du mannequin 2D (identiques à tool/motions.py).
STICK_LEG = 0.45 + 0.43

# Os du squelette, selon la convention de nommage du fichier.
BONES = {
    "ue": {
        "pelvis": "pelvis", "spine": ["spine_01", "spine_02", "spine_03"],
        "neck": "neck_01", "head": "head",
        "upper_arm": "upperarm_{s}", "forearm": "lowerarm_{s}", "hand": "hand_{s}",
        "thigh": "thigh_{s}", "shin": "calf_{s}", "foot": "foot_{s}",
        "sides": {"l": "l", "r": "r"},
    },
    "mixamo": {
        "pelvis": "mixamorig:Hips", "spine": ["mixamorig:Spine", "mixamorig:Spine1", "mixamorig:Spine2"],
        "neck": "mixamorig:Neck", "head": "mixamorig:Head",
        "upper_arm": "mixamorig:{S}Arm", "forearm": "mixamorig:{S}ForeArm", "hand": "mixamorig:{S}Hand",
        "thigh": "mixamorig:{S}UpLeg", "shin": "mixamorig:{S}Leg", "foot": "mixamorig:{S}Foot",
        "sides": {"l": "Left", "r": "Right"},
    },
}

# Décor de chaque monde : sol, fond et lumières.
WORLDS = {
    "medieval": {
        "floor": "PavingStones092", "floor_tile": 1.6, "floor_tint": (0.42, 0.34, 0.27),
        "back": "Bricks076C", "back_tile": 2.0, "back_tint": (0.36, 0.29, 0.23),
        "sky": (0.045, 0.032, 0.024), "key": (1.0, 0.78, 0.55), "rim": (1.0, 0.62, 0.32),
    },
}


def pose_at(motion, t):
    """Même interpolation que FigureMotion.poseAt (application)."""
    keys = motion["keys"]
    total = sum(k["hold"] for k in keys)
    elapsed = (t % 1) * total
    for i, key in enumerate(keys):
        if elapsed <= key["hold"] or i == len(keys) - 1:
            nxt = keys[(i + 1) % len(keys)]
            raw = 0 if key["hold"] == 0 else max(0.0, min(1.0, elapsed / key["hold"]))
            k = 0.5 - math.cos(raw * math.pi) / 2
            lerp = lambda a, b: a + (b - a) * k  # noqa: E731
            angles = {n: lerp(v, nxt["angles"].get(n, v)) for n, v in key["angles"].items()}
            if key["anchor"] == nxt["anchor"]:
                tx = lerp(key["target"][0], nxt["target"][0])
                ty = lerp(key["target"][1], nxt["target"][1])
                free = stick_joints(angles, motion["view"], (0, 0))[key["anchor"]]
                return (tx - free[0], ty - free[1]), angles
            return (lerp(key["root"][0], nxt["root"][0]), lerp(key["root"][1], nxt["root"][1])), angles
        elapsed -= key["hold"]
    return tuple(keys[0]["root"]), keys[0]["angles"]


def to_world(vec2, view):
    """Vecteur du plan du mannequin (x écran, y vers le bas) → monde Blender.
    Profil : l'avant du prof (−Y) va vers la droite de l'écran. Face : la
    gauche du prof (+X) est à droite de l'écran."""
    x, y = vec2
    if view == "side":
        return Vector((0.0, -x, -y))
    return Vector((x, 0.0, -y))


def load_coach(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj.parent is None and not obj.vertex_groups:
            bpy.data.objects.remove(obj, do_unlink=True)  # sphère d'aide de l'export
    names = {b.name for b in arm.data.bones}
    rig = "mixamo" if "mixamorig:Hips" in names else "ue"
    return arm, BONES[rig]


def bone(arm, rig, part, side=None):
    name = rig[part]
    if side is not None:
        s = rig["sides"][side]
        name = name.replace("{s}", s).replace("{S}", s)
    return arm.pose.bones[name]


def align(pb, direction):
    """Tourne l'os pour que son axe (tête → queue) suive `direction`."""
    m = pb.matrix.copy()
    current = (m.to_3x3() @ Vector((0, 1, 0))).normalized()
    q = current.rotation_difference(direction.normalized())
    head = m.translation.copy()
    pb.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ m
    bpy.context.view_layer.update()


def set_pose(arm, rig, motion, t, scale, rest):
    view = motion["view"]
    root, angles = pose_at(motion, t)
    a = lambda n, d=0.0: angles.get(n, d)  # noqa: E731

    def dir_of(deg, mirror=1.0):
        r = math.radians(deg * mirror)
        return to_world((math.sin(r), math.cos(r)), view)

    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()

    # Bassin : position du mannequin, orienté comme le tronc.
    pelvis = bone(arm, rig, "pelvis")
    torso = dir_of(a("t", 180))
    offset = to_world((root[0] * scale, root[1] * scale), view)
    target = Vector((rest["pelvis"].x, rest["pelvis"].y, rest["floor"])) + offset + Vector((0, 0, rest["leg"]))
    if view == "front":
        target.y = rest["pelvis"].y
    else:
        target.x = rest["pelvis"].x
    m = pelvis.matrix.copy()
    q = (m.to_3x3() @ Vector((0, 1, 0))).normalized().rotation_difference(torso)
    rot = q.to_matrix().to_4x4() @ Matrix(m.to_3x3()).to_4x4()
    pelvis.matrix = Matrix.Translation(target) @ rot
    bpy.context.view_layer.update()

    for name in rig["spine"]:
        align(arm.pose.bones[name], torso)
    align(bone(arm, rig, "neck"), dir_of(a("t", 180) + a("hd")))
    align(bone(arm, rig, "head"), dir_of(a("t", 180) + a("hd")))

    # Côté proche du mannequin : la droite du prof de profil, sa gauche de face.
    near, far = ("r", "l") if view == "side" else ("l", "r")
    for stick_side, side, mirror in (("n", near, 1.0), ("f", far, -1.0 if view == "front" else 1.0)):
        align(bone(arm, rig, "upper_arm", side), dir_of(a(f"ua_{stick_side}"), mirror))
        align(bone(arm, rig, "forearm", side), dir_of(a(f"fa_{stick_side}"), mirror))
        align(bone(arm, rig, "hand", side), dir_of(a(f"fa_{stick_side}"), mirror))
        align(bone(arm, rig, "thigh", side), dir_of(a(f"th_{stick_side}"), mirror))
        align(bone(arm, rig, "shin", side), dir_of(a(f"sh_{stick_side}"), mirror))
        if view == "side":
            align(bone(arm, rig, "foot", side), dir_of(a(f"ft_{stick_side}", 90)))


def rest_measures(arm, rig):
    bones = arm.data.bones
    hip = bones[bone(arm, rig, "thigh", "l").name]
    shin = bones[bone(arm, rig, "shin", "l").name]
    foot = bones[bone(arm, rig, "foot", "l").name]
    # Longueurs entre articulations (la queue des os n'est pas toujours sur
    # l'articulation suivante).
    leg = (shin.head_local - hip.head_local).length + (foot.head_local - shin.head_local).length
    pelvis = bones[bone(arm, rig, "pelvis").name]
    return {
        "scale": leg / STICK_LEG,
        "pelvis": arm.matrix_world @ pelvis.head_local,
        "floor": (arm.matrix_world @ foot.head_local).z,
        "height": (arm.matrix_world @ bones[bone(arm, rig, "head").name].tail_local).z,
        # Hauteur du bassin au-dessus des chevilles, debout.
        "leg": (arm.matrix_world @ hip.head_local).z - (arm.matrix_world @ foot.head_local).z - leg,
    }


def pbr_material(name, folder, tile, tint=(1.0, 1.0, 1.0)):
    root = os.environ.get("ARISE_PBR", "")
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    coord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (tile, tile, tile)
    links.new(coord.outputs["UV"], mapping.inputs["Vector"])

    def tex(kind, color=True):
        path = os.path.join(root, folder, f"{folder}_1K-JPG_{kind}.jpg")
        node = nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(path)
        if not color:
            node.image.colorspace_settings.name = "Non-Color"
        links.new(mapping.outputs["Vector"], node.inputs["Vector"])
        return node

    # Teinte du monde (pierre plus sombre et plus chaude).
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    links.new(tex("Color").outputs["Color"], mix.inputs[6])
    mix.inputs[7].default_value = (*tint, 1)
    links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    links.new(tex("Roughness", False).outputs["Color"], bsdf.inputs["Roughness"])
    normal = nodes.new("ShaderNodeNormalMap")
    links.new(tex("NormalGL", False).outputs["Color"], normal.inputs["Color"])
    links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def stick_point(p, view, rest):
    """Point du plan du mannequin → monde (même repère que le bassin)."""
    base = Vector((rest["pelvis"].x, rest["pelvis"].y, rest["floor"] + rest["leg"]))
    return base + to_world((p[0] * rest["scale"], p[1] * rest["scale"]), view)


def props(motion, rest, floor_z):
    """Accessoires du mouvement : banc, box ou mur en bois sombre, barre de fer."""
    view = motion["view"]
    wood = bpy.data.materials.new("prop_wood")
    wood.diffuse_color = (0.22, 0.13, 0.07, 1)
    wood.use_nodes = True
    wood.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.09, 0.05, 0.025, 1)
    wood.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.7
    iron = bpy.data.materials.new("prop_iron")
    iron.use_nodes = True
    bsdf = iron.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.3, 0.3, 0.32, 1)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.35
    for prop in motion.get("props", []):
        if prop["type"] == "box":
            x0, y0, x1, y1 = prop["rect"]
            a = stick_point((x0, y0), view, rest)
            b = stick_point((x1, y1), view, rest)
            lo = Vector(map(min, a, b))
            hi = Vector(map(max, a, b))
            if y1 >= 0:
                lo.z = floor_z  # posé sur le sol
            width = 0.5
            if view == "side":
                lo.x, hi.x = rest["pelvis"].x - width / 2, rest["pelvis"].x + width / 2
            else:
                lo.y, hi.y = rest["pelvis"].y - width / 2, rest["pelvis"].y + width / 2
            bpy.ops.mesh.primitive_cube_add(size=1, location=(lo + hi) / 2)
            obj = bpy.context.active_object
            obj.scale = hi - lo
            obj.data.materials.append(wood)
        else:
            c = rest.get("grip") or stick_point(prop["at"], view, rest)
            h = rest["height"]
            axis = (0, math.radians(90), 0) if view == "side" else (math.radians(90), 0, 0)
            along = Vector((1, 0, 0)) if view == "side" else Vector((0, 1, 0))
            c = c + Vector((0, 0, 0.02 * h))
            bpy.ops.mesh.primitive_cylinder_add(radius=0.022 * h, depth=0.9 * h, location=c, rotation=axis)
            bpy.context.active_object.data.materials.append(iron)
            # Montants en bois jusqu'au sol.
            for side in (-1, 1):
                top = c + along * side * 0.45 * h
                post_h = top.z - floor_z
                bpy.ops.mesh.primitive_cube_add(size=1, location=(top.x, top.y, floor_z + post_h / 2))
                post = bpy.context.active_object
                post.scale = (0.06 * h, 0.06 * h, post_h)
                post.data.materials.append(wood)


def stage(world, view, box, motion=None, rest=None):
    """Décor : sol et mur du monde, éclairage chaud, caméra cadrée."""
    cfg = WORLDS[world]
    scene = bpy.context.scene
    lo, hi = box
    center = (lo + hi) / 2
    floor_z = lo.z
    if motion is not None and motion.get("ground") is False:
        floor_z = lo.z - 0.35  # mouvement suspendu : le sol est plus bas
    if motion is not None and rest is not None:
        props(motion, rest, floor_z)
    bpy.ops.mesh.primitive_plane_add(size=1, location=(center.x, center.y, floor_z))
    floor = bpy.context.active_object
    floor.scale = (12, 12, 1)
    floor.data.materials.append(pbr_material("floor", cfg["floor"], cfg["floor_tile"] * 6, cfg["floor_tint"]))
    # Mur du fond, derrière le prof par rapport à la caméra.
    depth = 1.6
    if view == "side":
        wall_loc = (center.x + depth, center.y, floor_z + 3)
        wall_rot = (math.radians(90), 0, math.radians(90))
    else:
        wall_loc = (center.x, center.y + depth, floor_z + 3)
        wall_rot = (math.radians(90), 0, 0)
    bpy.ops.mesh.primitive_plane_add(size=1, location=wall_loc, rotation=wall_rot)
    wall = bpy.context.active_object
    wall.scale = (12, 6, 1)
    wall.data.materials.append(pbr_material("wall", cfg["back"], cfg["back_tile"] * 6, cfg["back_tint"]))

    scene.world = bpy.data.worlds.new("sky")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (*cfg["sky"], 1)

    size = max(hi.x - lo.x if view == "front" else hi.y - lo.y, hi.z - lo.z * 0 - floor_z) * 1.0
    span = max(size, 0.6)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 50
    distance = span * 2.6
    look = Vector((center.x, center.y, floor_z + (hi.z - floor_z) * 0.48))
    # Trois quarts : le mouvement reste lisible et les accessoires (barre,
    # banc) se voient en volume.
    if view == "side":
        turn = math.radians(32)
        cam.location = look + Vector((-math.cos(turn), -math.sin(turn), 0)) * distance + Vector((0, 0, span * 0.3))
    else:
        turn = math.radians(22)
        cam.location = look + Vector((math.sin(turn), -math.cos(turn), 0)) * distance + Vector((0, 0, span * 0.3))
    cam.rotation_euler = (look - cam.location).to_track_quat("-Z", "Y").to_euler()

    def light(name, loc, energy, color, size):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.color = color
        data.size = size
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = (look - Vector(loc)).to_track_quat("-Z", "Y").to_euler()

    side_axis = Vector((-1, 0, 0)) if view == "side" else Vector((0, -1, 0))
    across = Vector((0, -1, 0)) if view == "side" else Vector((1, 0, 0))
    light("key", look + side_axis * 2.5 + across * 1.5 + Vector((0, 0, 2.2)), 260 * span, cfg["key"], 2.5)
    light("fill", look + side_axis * 2.5 - across * 2.0 + Vector((0, 0, 0.8)), 70 * span, (0.8, 0.85, 1.0), 3)
    light("rim", look - side_axis * 1.5 + Vector((0, 0, 2.5)), 220 * span, cfg["rim"], 1.5)

    scene.render.engine = "CYCLES"
    scene.cycles.samples = int(os.environ.get("ARISE_SAMPLES", "16"))
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = SIZE
    scene.view_settings.look = "AgX - Medium High Contrast" if "AgX - Medium High Contrast" in [
        i.identifier for i in scene.view_settings.bl_rna.properties["look"].enum_items] else "None"


def render_motion(coach_path, world, motion_id, out_dir):
    motions = json.load(open(MOTIONS))
    motion = motions[motion_id]
    arm, rig = load_coach(coach_path)
    rest = rest_measures(arm, rig)
    frames = max(12, round(sum(k["hold"] for k in motion["keys"]) * FPS))
    # Cadre : enveloppe des positions du mannequin sur tout le cycle.
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    # Sol : calé sur le squelette (les vêtements qui pendent ne comptent
    # pas), avec l'épaisseur du corps autour de chaque os.
    height = rest["height"]
    margins = {}
    for s in "lr":
        margins[bone(arm, rig, "foot", s).name] = 0.012
        margins[bone(arm, rig, "hand", s).name] = 0.012
        margins[bone(arm, rig, "forearm", s).name] = 0.03
    floor = 1e9
    for f in range(0, frames, max(1, frames // 12)):
        set_pose(arm, rig, motion, f / frames, rest["scale"], rest)
        depsgraph = bpy.context.evaluated_depsgraph_get()
        for obj in meshes:
            ev = obj.evaluated_get(depsgraph)
            for c in ev.bound_box:
                p = ev.matrix_world @ Vector(c)
                lo = Vector(map(min, lo, p))
                hi = Vector(map(max, hi, p))
        for pb in arm.pose.bones:
            if any(k in pb.name.lower() for k in ("twist", "index", "middle", "ring", "pinky", "thumb", "root")):
                continue
            margin = margins.get(pb.name, 0.055)
            if "ball" in pb.name.lower() or "toe" in pb.name.lower():
                margin = 0.008  # bout du pied
            for point in (pb.head, pb.tail):
                z = (arm.matrix_world @ point).z
                floor = min(floor, z - margin * height)
    lo.z = floor
    # Barre : dans les mains du prof au début du cycle.
    set_pose(arm, rig, motion, 0, rest["scale"], rest)
    hands = [arm.matrix_world @ bone(arm, rig, "hand", s).tail for s in "lr"]
    rest["grip"] = (hands[0] + hands[1]) / 2
    stage(world, motion["view"], (lo, hi), motion, rest)
    scene = bpy.context.scene
    os.makedirs(out_dir, exist_ok=True)
    # ARISE_FRAMES="0,8,15" : contrôle rapide de quelques images seulement.
    only = os.environ.get("ARISE_FRAMES")
    picked = [int(i) for i in only.split(",")] if only else range(frames)
    for f in picked:
        set_pose(arm, rig, motion, f / frames, rest["scale"], rest)
        scene.render.filepath = os.path.join(out_dir, f"{motion_id}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    return frames


if __name__ == "__main__":
    coach, world_id, out = sys.argv[1:4]
    ids = sys.argv[4:] or list(json.load(open(MOTIONS)))
    motions_all = json.load(open(MOTIONS))
    for mid in ids:
        # Reprise : un mouvement dont la dernière image existe est déjà fait.
        count = max(12, round(sum(k["hold"] for k in motions_all[mid]["keys"]) * FPS))
        if os.path.exists(os.path.join(out, f"{mid}_{count - 1:03d}.png")):
            print("DEJA", mid, flush=True)
            continue
        n = render_motion(coach, world_id, mid, out)
        print("RENDU", mid, n, flush=True)
