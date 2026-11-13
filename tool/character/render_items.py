"""Vignettes de la boutique : chaque objet (et chaque coiffure) rendu seul, sur
fond transparent, à partir du modèle humain masculin de référence.

Lancement sans interface (module « bpy » de PyPI + extension MPFB, voir
build_characters.py) :
    ARISE_MH_ASSETS=<paquets MakeHuman> python3 tool/character/render_items.py assets/items [dossier des modèles]

Avec un dossier des modèles, le modèle humain masculin construit pour les
vignettes y est gardé (évite une seconde construction).
"""

import math
import os
import runpy
import shutil
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SIZE = 256

# Teintes de présentation des pièces teignables et des coiffures.
HAIR_PREVIEW = (0.16, 0.07, 0.03, 1.0)


def _tint_textured(mat, rgba):
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    tex = next((n for n in nodes if n.bl_idname == "ShaderNodeTexImage"), None)
    if tex is None:
        # Pièce sans texture : la teinte devient sa couleur.
        bsdf.inputs["Base Color"].default_value = rgba
        return
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    inputs = [i for i in mix.inputs if i.type == "RGBA"]
    outputs = [o for o in mix.outputs if o.type == "RGBA"]
    mat.node_tree.links.new(tex.outputs["Color"], inputs[0])
    inputs[1].default_value = rgba
    mat.node_tree.links.new(outputs[0], bsdf.inputs["Base Color"])


def _setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.device = "CPU"
    scene.render.film_transparent = True
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.view_settings.exposure = -0.6
    for name, loc, energy, color in [
        ("Key", (2.0, -3.0, 3.0), 500, (1, 0.9, 0.8)),
        ("Fill", (-2.5, -2.0, 1.0), 200, (0.8, 0.85, 1)),
        ("Rim", (0.5, 3.0, 2.5), 300, (1, 0.85, 0.7)),
    ]:
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.color = color
        light.size = 3
        obj = bpy.data.objects.new(name, light)
        scene.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    camera = bpy.data.objects.new("ThumbCam", bpy.data.cameras.new("ThumbCam"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.type = "ORTHO"
    return scene, camera


def _render(scene, camera, objects, path, view=(0.55, -1.0, 0.25), frame=None, one_side=False):
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            obj.hide_render = obj not in objects
    depsgraph = bpy.context.evaluated_depsgraph_get()
    pts = []
    for obj in frame or objects:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        pts += [evaluated.matrix_world @ v.co for v in mesh.vertices]
        if one_side:
            # Pièces en paire (gants, bottes) : cadrage sur le côté gauche.
            pts = [p for p in pts if p.x > 0]
        evaluated.to_mesh_clear()
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (lo + hi) / 2
    direction = Vector(view).normalized()
    camera.location = center + direction * 5
    camera.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = max((hi - lo).length * 0.82, 0.05)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main(out_dir, model_dir=None):
    ns = runpy.run_path(os.path.join(HERE, "build_characters.py"))
    tmp = model_dir or os.path.join(out_dir, "_tmp")
    ns["build"]("male", "human", tmp)
    os.makedirs(out_dir, exist_ok=True)
    for mat in bpy.data.materials:
        if mat.name.startswith("hair_"):
            _tint_textured(mat, HAIR_PREVIEW)
    # Pose détendue (comme dans l'application) : armes dans la main.
    arm = bpy.data.objects.get("rig")
    if arm is not None and arm.animation_data is not None:
        relaxed = bpy.data.actions.get("pose_relaxed")
        for track in arm.animation_data.nla_tracks:
            track.mute = True
        arm.animation_data.action = relaxed
        bpy.context.scene.frame_set(1)
    scene, camera = _setup_scene()
    body = bpy.data.objects["body"]
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            continue
        if obj.name.startswith("item_"):
            view = (0.45, 1.0, 0.2) if obj.name.startswith("item_cape") else (0.55, -1.0, 0.25)
            pair = obj.name.endswith(("_hands", "_feet"))
            if pair:
                view = (1.0, -0.6, 0.2)
            _render(scene, camera, [obj], os.path.join(out_dir, obj.name[5:] + ".png"), view, one_side=pair)
        elif obj.name.startswith("hair_"):
            # Coiffure portée sur une tête neutre, de trois quarts arrière.
            _render(scene, camera, [body, obj], os.path.join(out_dir, "hairstyle_" + obj.name[5:] + ".png"), (0.8, 0.6, 0.15), frame=[obj])
    if model_dir is None:
        shutil.rmtree(tmp)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
