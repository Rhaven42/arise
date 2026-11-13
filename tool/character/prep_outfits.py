"""Prépare les tenues Sketchfab listées dans outfits.json pour build_characters.py.

Chaque tenue est importée depuis le dossier des téléchargements bruts,
débarrassée de ce qui n'est pas de l'armure (corps, cheveux, accessoires
listés), posée debout (pieds à z = 0, centrée, face vers -Y, 1,8 m de haut),
allégée (30 000 triangles au plus, textures de 1024 px au plus) puis exportée
dans external/outfits/<tenue>.glb.

Usage (module « bpy ») :
    python tool/character/prep_outfits.py <dossier des .glb Sketchfab> [tenue ...]
"""

import json
import math
import os
import sys

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "external", "outfits")
MAX_TRIS = 30000
MAX_TEXTURE = 1024


def _dropped(obj, keys):
    names = [obj.name] + [m.name for m in obj.data.materials if m]
    return any(k.lower() in n.lower() for k in keys for n in names)


def prepare(set_id, cfg, src_dir):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(src_dir, cfg["uid"] + ".glb"))
    objs = list(bpy.context.scene.objects)
    meshes = [o for o in objs if o.type == "MESH" and not _dropped(o, cfg.get("drop", []))]
    for o in meshes:
        world = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = world
        # Maillages animés : on garde la géométrie de repos.
        for mod in list(o.modifiers):
            o.modifiers.remove(mod)
        o.vertex_groups.clear()
        if o.data.shape_keys:
            o.shape_key_clear()
    for o in objs:
        if o not in meshes:
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = "outfit"
    # Redressement : « rotx » (tenue couchée), puis « rotz » (face vers -Y).
    for axis in ("X", "Z"):
        degrees = cfg.get("rot" + axis.lower())
        if degrees:
            obj.data.transform(Matrix.Rotation(math.radians(degrees), 4, axis))
    pts = [v.co for v in obj.data.vertices]
    lo = Vector([min(p[k] for p in pts) for k in range(3)])
    hi = Vector([max(p[k] for p in pts) for k in range(3)])
    scale = 1.8 / (hi.z - lo.z)
    center = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    obj.data.transform(Matrix.Scale(scale, 4) @ Matrix.Translation(-center))
    obj.data.update()
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris > MAX_TRIS:
        mod = obj.modifiers.new("dec", "DECIMATE")
        mod.ratio = MAX_TRIS / tris
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier="dec")
    # Textures illisibles (format non pris en charge) : retirées plutôt
    # qu'exportées en rose.
    for img in list(bpy.data.images):
        if not img.has_data and img.size[0] == 0:
            for mat in bpy.data.materials:
                if mat.use_nodes:
                    for node in list(mat.node_tree.nodes):
                        if node.type == "TEX_IMAGE" and node.image == img:
                            mat.node_tree.nodes.remove(node)
            bpy.data.images.remove(img)
    for img in bpy.data.images:
        w, h = img.size
        if max(w, h) > MAX_TEXTURE:
            k = MAX_TEXTURE / max(w, h)
            img.scale(max(1, int(w * k)), max(1, int(h * k)))
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, set_id + ".glb")
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True,
        export_image_format="WEBP", export_apply=True,
    )
    final = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    print("TENUE", set_id, "triangles", final, flush=True)


def main(src_dir, only):
    with open(os.path.join(HERE, "outfits.json"), encoding="utf-8") as f:
        sets = {k: v for k, v in json.load(f).items() if not k.startswith("_")}
    for set_id, cfg in sets.items():
        if only and set_id not in only:
            continue
        prepare(set_id, cfg, src_dir)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
