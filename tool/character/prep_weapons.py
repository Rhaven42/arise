"""Prépare les armes Tripo pour build_characters.py.

Un fichier peut contenir une seule arme ou une panoplie posée côte à côte :
les morceaux sont regroupés par recouvrement (vue de dessus), puis chaque
arme est allégée, sa poignée placée à l'origine, la tête vers le haut (+Z),
et exportée seule en .glb (textures WebP 512 px).

Usage (module « bpy ») :
    python tool/character/prep_weapons.py <fichier.glb> <dossier de sortie> <préfixe> [triangles] [degrés] [tour]

« degrés » tourne une panoplie posée en diagonale pour que ses armes se
séparent bien (rotation autour de l'axe de la vue de face) ; « tour » remet
ensuite chaque arme debout, tête vers le haut.
"""

import os
import sys

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
import bmesh
from mathutils import Vector


def clusters(obj):
    """Groupes de faces connexes formant chacun une arme."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    seen = set()
    islands = []
    for face in bm.faces:
        if face.index in seen:
            continue
        stack, island = [face], []
        seen.add(face.index)
        while stack:
            f = stack.pop()
            island.append(f.index)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen:
                        seen.add(g.index)
                        stack.append(g)
        pts = [v.co for i in island for v in bm.faces[i].verts]
        lo = Vector([min(p[k] for p in pts) for k in range(3)])
        hi = Vector([max(p[k] for p in pts) for k in range(3)])
        islands.append([island, lo, hi])
    bm.free()
    # Fusion : deux îles vont ensemble quand la plus petite est en grande
    # partie dans le volume de l'autre (garde sur une poignée, gemme sur un
    # bâton) ; des armes voisines, même en diagonale, se touchent à peine.
    def volume(lo, hi):
        size = hi - lo
        return max(size.x, 1e-4) * max(size.y, 1e-4) * max(size.z, 1e-4)

    def inside(a, b):
        lo = Vector(map(max, a[1], b[1]))
        hi = Vector(map(min, a[2], b[2]))
        if any(hi[k] <= lo[k] for k in range(3)):
            return 0.0
        return volume(lo, hi) / min(volume(a[1], a[2]), volume(b[1], b[2]))

    def stacked(a, b):
        """Tête posée sur un manche : l'une au-dessus de l'autre, alignées."""
        lo_x, hi_x = max(a[1].x, b[1].x), min(a[2].x, b[2].x)
        narrow = min(a[2].x - a[1].x, b[2].x - b[1].x)
        if narrow <= 0 or (hi_x - lo_x) / narrow < 0.6:
            return False
        gap = max(a[1].z, b[1].z) - min(a[2].z, b[2].z)
        tall = max(a[2].z - a[1].z, b[2].z - b[1].z)
        return gap < 0.03 * tall

    merged = True
    while merged:
        merged = False
        for a in range(len(islands)):
            for b in range(a + 1, len(islands)):
                ia, ib = islands[a], islands[b]
                if inside(ia, ib) > 0.5 or stacked(ia, ib):
                    ia[0] += ib[0]
                    ia[1] = Vector(map(min, ia[1], ib[1]))
                    ia[2] = Vector(map(max, ia[2], ib[2]))
                    islands.pop(b)
                    merged = True
                    break
            if merged:
                break
    tallest = max(i[2].z - i[1].z for i in islands)
    return [i for i in islands if i[2].z - i[1].z > 0.3 * tallest]


def upright(obj, degrees):
    """Redresse une panoplie posée en diagonale (vue de face, plan X/Z)."""
    import math
    from mathutils import Matrix
    if not degrees:
        return
    rot = Matrix.Rotation(math.radians(degrees), 4, "Y")
    for v in obj.data.vertices:
        v.co = rot @ v.co
    obj.data.update()


def main(src, out_dir, prefix, target=6000, degrees=0.0, turn=0.0):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0005)
    bpy.ops.object.mode_set(mode="OBJECT")
    upright(obj, degrees)
    groups = sorted(clusters(obj), key=lambda g: (round(-g[2].z, 1), g[1].x))
    for img in bpy.data.images:
        if img.size[0] > 512:
            img.scale(512, 512)
    os.makedirs(out_dir, exist_ok=True)
    for n, (faces, lo, hi) in enumerate(groups, 1):
        # Copie de l'objet, puis suppression des faces des autres armes.
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.duplicate()
        part = bpy.context.active_object
        keep = set(faces)
        bm = bmesh.new()
        bm.from_mesh(part.data)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
        bm.to_mesh(part.data)
        bm.free()
        if turn:
            # Arme découpée couchée : remise debout, tête vers le haut.
            import math
            from mathutils import Matrix
            rot = Matrix.Rotation(math.radians(turn), 4, "Y")
            for v in part.data.vertices:
                v.co = rot @ v.co
            part.data.update()
            pts = [v.co for v in part.data.vertices]
            lo = Vector([min(p[k] for p in pts) for k in range(3)])
            hi = Vector([max(p[k] for p in pts) for k in range(3)])
        # Les morceaux trapus (gemme, décor) ne sont pas des armes.
        if hi.z - lo.z < 1.6 * max(hi.x - lo.x, hi.y - lo.y):
            bpy.data.objects.remove(part, do_unlink=True)
            continue
        tris = sum(len(p.vertices) - 2 for p in part.data.polygons)
        if tris > target:
            mod = part.modifiers.new("dec", "DECIMATE")
            mod.ratio = target / tris
            mod.use_collapse_triangulate = True
            bpy.ops.object.modifier_apply(modifier="dec")
        # Poignée à l'origine : centre de la section, au cinquième de la
        # hauteur pour une arme courte, au milieu bas pour un bâton.
        height = hi.z - lo.z
        width = max(hi.x - lo.x, hi.y - lo.y)
        staff = height > 6 * width
        grip_z = lo.z + height * (0.42 if staff else 0.12)
        band = [v.co for v in part.data.vertices if abs(v.co.z - grip_z) < 0.03 * height] or [v.co for v in part.data.vertices]
        grip = Vector((sum(p.x for p in band) / len(band), sum(p.y for p in band) / len(band), grip_z))
        for v in part.data.vertices:
            v.co -= grip
        part.name = f"{prefix}_{n:02d}"
        bpy.ops.object.select_all(action="DESELECT")
        part.select_set(True)
        path = os.path.join(out_dir, f"{prefix}_{n:02d}.glb")
        bpy.ops.export_scene.gltf(
            filepath=path, export_format="GLB", use_selection=True,
            export_image_format="WEBP", export_apply=True,
        )
        print("ARME", path, "triangles", min(tris, target), "bâton" if staff else "arme courte", flush=True)
        bpy.data.objects.remove(part, do_unlink=True)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3],
         int(sys.argv[4]) if len(sys.argv) > 4 else 6000,
         float(sys.argv[5]) if len(sys.argv) > 5 else 0.0,
         float(sys.argv[6]) if len(sys.argv) > 6 else 0.0)
