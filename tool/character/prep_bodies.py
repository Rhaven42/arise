"""Prépare les corps (modèles fournis par la propriétaire du projet) pour
build_characters.py : socle retiré, debout, centré, face vers -Y, allégés
(60 000 triangles), peau mate, exportés dans external/bodies/<sexe>.glb.

Usage (module « bpy ») :
    python tool/character/prep_bodies.py <corps.glb> <female|male>
"""

import os
import sys

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
MAX_TRIS = 100000


def main(src, sex):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
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
    obj.name = "body_" + sex
    # Socle : tranche basse bien plus large que les pieds ; tout ce qui
    # est sous son dessus est retiré.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    zs = [v.co.z for v in bm.verts]
    lo, hi = min(zs), max(zs)
    height = hi - lo
    top = None
    steps = 60
    for i in range(steps):
        z0 = lo + height * 0.1 * i / steps
        z1 = z0 + height * 0.1 / steps
        xs = [v.co.x for v in bm.verts if z0 <= v.co.z < z1]
        if xs and max(xs) - min(xs) > 0.3 * height:
            top = z1
    if top is not None:
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z < top + 0.002 * height], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    pts = [v.co for v in obj.data.vertices]
    lo = Vector([min(p[k] for p in pts) for k in range(3)])
    hi = Vector([max(p[k] for p in pts) for k in range(3)])
    scale = 1.8 / (hi.z - lo.z)
    obj.data.transform(Matrix.Scale(scale, 4) @ Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))))
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris > MAX_TRIS:
        mod = obj.modifiers.new("dec", "DECIMATE")
        mod.ratio = MAX_TRIS / tris
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier="dec")
    for img in bpy.data.images:
        if max(img.size) > 2048:
            img.scale(2048, 2048)
    out = os.path.join(HERE, "external", "bodies", sex + ".glb")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_image_format="WEBP", export_apply=True)
    print("CORPS", sex, sum(len(p.vertices) - 2 for p in obj.data.polygons), flush=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
