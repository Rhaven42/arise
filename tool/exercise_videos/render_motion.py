"""Vidéo de démonstration d'un exercice : mannequin MPFB animé par une
capture de mouvement (BVH de la base CMU, ou FBX Mixamo), rendu Cycles.

Usage :
  python render_motion.py <capture.bvh> <début> <fin> <sortie.mp4> [--frames N]

<début> et <fin> sont des numéros d'image de la capture (120 i/s pour CMU) ;
la vidéo est échantillonnée à 30 i/s et boucle sur cet extrait.
"""
import importlib
import math
import os
import subprocess
import sys
import tempfile

import bpy
from mathutils import Matrix, Vector

FPS = 30
WIDTH, HEIGHT = 720, 480
SAMPLES = 24
# Correspondance des os de la capture CMU vers le squelette MPFB « cmu_mb ».
RENAME = {"LeftHandIndex1": "LeftHandFinger1", "RightHandIndex1": "RightHandFinger1"}


def _mpfb():
    import addon_utils

    for repo in ("blender_org", "user_default"):
        name = f"bl_ext.{repo}.mpfb"
        try:
            if addon_utils.enable(name, default_set=True) is None:
                continue
            importlib.import_module(name + ".services")
        except ImportError:
            continue
        return importlib.import_module(name + ".services.humanservice").HumanService
    raise RuntimeError("Extension MPFB introuvable")


def _material(name, color, roughness=0.5, subsurface=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    if subsurface:
        bsdf.inputs["Subsurface Weight"].default_value = subsurface
        bsdf.inputs["Subsurface Radius"].default_value = (0.6, 0.35, 0.25)
    return mat


def build_human():
    """Mannequin athlétique, matière unie claire (style planche d'exercices)."""
    hs = _mpfb()
    human = hs.create_human(macro_detail_dict={
        "gender": 1.0, "age": 0.45, "muscle": 0.9, "weight": 0.5,
        "proportions": 0.7, "height": 0.55, "cupsize": 0.5, "firmness": 0.5,
        "race": {"asian": 0.33, "caucasian": 0.33, "african": 0.33},
    })
    hs.add_builtin_rig(human, "cmu_mb")
    arm = human.parent
    skin = _material("mannequin", (0.36, 0.42, 0.52), roughness=0.36, subsurface=0.04)
    human.data.materials.clear()
    human.data.materials.append(skin)
    for poly in human.data.polygons:
        poly.material_index = 0
    bpy.ops.object.select_all(action="DESELECT")
    human.select_set(True)
    bpy.context.view_layer.objects.active = human
    bpy.ops.object.shade_smooth()
    sub = human.modifiers.new("lisse", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    return human, arm


def import_capture(path):
    bpy.ops.import_anim.bvh(filepath=path, axis_forward="-Z", axis_up="Y", update_scene_fps=False)
    return bpy.context.object


def _world_rot(obj, pb):
    return (obj.matrix_world @ pb.matrix).to_3x3().normalized()


def retarget(src, dst, start, end):
    """Copie l'animation de [src] (capture) sur [dst] (squelette MPFB) :
    rotation de chaque os = rotation de la capture depuis sa pose de repos,
    appliquée à la pose de repos du mannequin ; le bassin suit la capture
    (mise à l'échelle des jambes), pieds posés au sol."""
    scene = bpy.context.scene
    scene.frame_set(0)
    bpy.context.view_layer.update()
    # Poses de repos (matrices des os au repos, en monde).
    src_rest = {b.name: (src.matrix_world @ b.matrix_local).to_3x3().normalized() for b in src.data.bones}
    dst_rest = {b.name: (dst.matrix_world @ b.matrix_local).to_3x3().normalized() for b in dst.data.bones}
    pairs = [(b.name, RENAME.get(b.name, b.name)) for b in src.data.bones if RENAME.get(b.name, b.name) in dst.data.bones]
    order = {b.name: len(b.parent_recursive) for b in dst.data.bones}
    pairs.sort(key=lambda p: order[p[1]])
    # Échelle : hauteur du bassin du mannequin / celle de la capture debout
    # (première image de l'extrait ; la pose de repos BVH est à l'origine).
    dst_hips_rest = dst.matrix_world @ dst.data.bones["Hips"].head_local
    scene.frame_set(start)
    bpy.context.view_layer.update()
    src_hips_start = src.matrix_world @ src.pose.bones["Hips"].head
    scale = dst_hips_rest.z / max(src_hips_start.z, 1e-6)
    step = 120 / FPS
    frames = []
    t = start
    while t <= end:
        frames.append(int(round(t)))
        t += step
    origin = None
    for out_frame, f in enumerate(frames, start=1):
        scene.frame_set(f)
        bpy.context.view_layer.update()
        for s, d in pairs:
            spb = src.pose.bones[s]
            dpb = dst.pose.bones[d]
            delta = _world_rot(src, spb) @ src_rest[s].inverted()
            world = delta @ dst_rest[d]
            head = (dst.matrix_world @ dpb.matrix).to_translation()
            if d == "Hips":
                hip = src.matrix_world @ spb.head
                if origin is None:
                    origin = Vector((hip.x, hip.y, 0))
                head = Vector(((hip.x - origin.x) * scale, (hip.y - origin.y) * scale, hip.z * scale))
            m = Matrix.Translation(head) @ world.to_4x4()
            dpb.matrix = dst.matrix_world.inverted() @ m
            bpy.context.view_layer.update()
        for pb in dst.pose.bones:
            pb.keyframe_insert("rotation_quaternion" if pb.rotation_mode == "QUATERNION" else "rotation_euler", frame=out_frame)
            if pb.name == "Hips":
                pb.keyframe_insert("location", frame=out_frame)
    return len(frames)


def ground(human):
    """Pose le mannequin au sol (point le plus bas de toute l'animation) et
    renvoie la boîte qui contient tout le mouvement (min, max)."""
    scene = bpy.context.scene
    lo = Vector((math.inf,) * 3)
    hi = Vector((-math.inf,) * 3)
    for f in range(scene.frame_start, scene.frame_end + 1, 3):
        scene.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        ev = human.evaluated_get(dg)
        mesh = ev.to_mesh()
        mw = ev.matrix_world
        for i in range(0, len(mesh.vertices), 7):
            p = mw @ mesh.vertices[i].co
            lo = Vector(min(a, b) for a, b in zip(lo, p))
            hi = Vector(max(a, b) for a, b in zip(hi, p))
        ev.to_mesh_clear()
    human.parent.location.z -= lo.z
    hi.z -= lo.z
    lo.z = 0.0
    return lo, hi


def studio(human, view, box):
    scene = bpy.context.scene
    floor_mat = _material("sol", (0.42, 0.43, 0.46), roughness=0.85)
    bpy.ops.mesh.primitive_plane_add(size=40)
    bpy.context.object.data.materials.append(floor_mat)
    world = bpy.data.worlds.new("fond")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.17, 0.19, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    scene.world = world
    for name, loc, energy, size in (("cle", (2.5, -3.0, 4.0), 320, 2.5), ("douce", (-3.5, -2.0, 2.5), 120, 4.0), ("contre", (0.5, 4.0, 3.5), 380, 1.5)):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.size = size
        obj = bpy.data.objects.new(name, light)
        obj.location = loc
        obj.rotation_euler = (Vector((0, 0, 1.0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(obj)
    cam = bpy.data.cameras.new("camera")
    cam.lens = 50
    cam_obj = bpy.data.objects.new("camera", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    # Cadrage sur tout le mouvement : centre de la boîte, distance selon sa
    # plus grande dimension (marge de 15 %).
    lo, hi = box
    target = (lo + hi) / 2
    size = max(hi.z - lo.z, (hi.x - lo.x) / 1.5, (hi.y - lo.y) / 1.5) * 1.15
    distance = size / (2 * math.tan(cam.angle_y / 2)) + 0.4
    direction = {"front": Vector((0, -1, 0.12)), "side": Vector((1, 0, 0.12)), "three_quarter": Vector((0.65, -0.76, 0.14))}[view].normalized()
    pos = target + direction * distance
    for light in ("cle", "douce", "contre"):
        scene.objects[light].location += Vector((target.x, target.y, 0))
    cam_obj.location = pos
    cam_obj.rotation_euler = (target - pos).to_track_quat("-Z", "Y").to_euler()


def render(out, frame_count):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x = WIDTH
    scene.render.resolution_y = HEIGHT
    scene.render.fps = FPS
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    scene.frame_start = 1
    scene.frame_end = frame_count
    tmp = tempfile.mkdtemp()
    scene.render.filepath = os.path.join(tmp, "f_")
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(animation=True)
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", os.path.join(tmp, "f_%04d.png"),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "26", "-preset", "slow", "-movflags", "+faststart", out,
    ], check=True)


def render_stills(out, frames):
    """Images fixes <out>_<image>.png (contrôle rapide du mouvement)."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x = WIDTH // 2
    scene.render.resolution_y = HEIGHT // 2
    scene.view_settings.view_transform = "AgX"
    scene.render.image_settings.file_format = "PNG"
    for f in frames:
        scene.frame_set(f)
        scene.render.filepath = f"{out}_{f:03d}.png"
        bpy.ops.render.render(write_still=True)


def main():
    args = sys.argv[1:]
    capture, start, end, out = args[0], int(args[1]), int(args[2]), args[3]
    view = args[4] if len(args) > 4 else "three_quarter"
    limit = int(args[args.index("--frames") + 1]) if "--frames" in args else None
    bpy.ops.wm.read_factory_settings(use_empty=True)
    human, arm = build_human()
    src = import_capture(capture)
    count = retarget(src, arm, start, end)
    src.hide_render = True
    src.hide_viewport = True
    scene = bpy.context.scene
    scene.frame_start, scene.frame_end = 1, count
    box = ground(human)
    studio(human, view, box)
    if "--stills" in args:
        # Contrôle : quelques images fixes au lieu de la vidéo.
        stills = [int(x) for x in args[args.index("--stills") + 1].split(",")]
        render_stills(out, stills)
        return
    render(out, limit or count)
    print("vidéo", out, count, "images")


if __name__ == "__main__":
    main()
