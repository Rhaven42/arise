"""Prépare les coiffures et les barbes listées dans pieces.json pour
build_characters.py : allégées (25 000 triangles), centrées, textures
ramenées au gris clair pour être teintées par la couleur des cheveux
(pas les armures : 20 000 triangles, couleurs d'origine), exportées dans
external/hair, external/beards et external/armor.

Usage (module « bpy ») :
    python tool/character/prep_pieces.py <dossier des .glb fournis> [id ...]
"""

import json
import os
import sys

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
MAX_TRIS = 25000
MAX_TEXTURE = 512


def _gray(img):
    """Texture ramenée au gris clair (moyenne 0,75) : la teinte des cheveux
    choisie dans l'application la colore."""
    import numpy as np

    px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
    lum = 0.3 * px[:, 0] + 0.59 * px[:, 1] + 0.11 * px[:, 2]
    lum = np.clip(lum / max(float(lum.mean()), 1e-3) * 0.75, 0, 1)
    for k in range(3):
        px[:, k] = lum
    img.pixels[:] = px.ravel()


def prepare(entry, src_dir, folder):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(src_dir, entry["src"]))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for o in list(bpy.context.scene.objects):
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        world = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = world
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = entry["id"]
    pts = [v.co for v in obj.data.vertices]
    lo = Vector([min(p[k] for p in pts) for k in range(3)])
    hi = Vector([max(p[k] for p in pts) for k in range(3)])
    obj.data.transform(Matrix.Translation(-(lo + hi) / 2))
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    limit = 20000 if folder == "armor" else MAX_TRIS
    if tris > limit:
        mod = obj.modifiers.new("dec", "DECIMATE")
        mod.ratio = limit / tris
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier="dec")
    for img in bpy.data.images:
        if img.size[0] == 0:
            continue
        if max(img.size) > MAX_TEXTURE:
            img.scale(MAX_TEXTURE, MAX_TEXTURE)
        if folder != "armor":
            _gray(img)
    for mat in ([] if folder == "armor" else bpy.data.materials):
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED" and not node.inputs["Base Color"].is_linked:
                    node.inputs["Base Color"].default_value = (0.75, 0.75, 0.75, 1.0)
    out = os.path.join(HERE, "external", folder, entry["id"] + ".glb")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_image_format="WEBP", export_apply=True)
    print("PIÈCE", entry["id"], sum(len(p.vertices) - 2 for p in obj.data.polygons), flush=True)


def main(src_dir, only):
    with open(os.path.join(HERE, "pieces.json"), encoding="utf-8") as f:
        pieces = json.load(f)
    for folder, key in (("hair", "hair"), ("beards", "beards"), ("armor", "armor")):
        for entry in pieces[key]:
            if not only or entry["id"] in only:
                prepare(entry, src_dir, folder)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
