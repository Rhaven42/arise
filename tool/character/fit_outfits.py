"""Ajustement des tenues Sketchfab (external/outfits, voir prep_outfits.py)
sur un corps de build_characters.py.

Pour chaque tenue : mise à l'échelle de la hauteur couverte, bras ramenés de
la pose de la tenue (T ou A) à la pose A du corps, largeur ajustée par
tranches de hauteur, casque ajusté à la tête, tenue poussée hors de la peau,
puis découpe en pièces par emplacement (tête, torse, mains, jambes, pieds)
selon la partie du corps la plus proche. Chaque pièce reçoit les formes de
corpulence et de musculature du corps (déplacement du point de peau le plus
proche) ; les poids de peau sont posés ensuite par build_characters.py.
"""

import json
import math
import os

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
import bmesh
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
OUTFIT_DIR = os.path.join(HERE, "external", "outfits")
BODY_KEYS = ("corp_low", "corp_high", "musc_low", "musc_high")
MARGIN = 0.006          # écart minimal entre la tenue et la peau (m)
WIDTH_SLACK = 1.12      # largeur de la tenue par rapport au corps
SLOT_OF_PART = {
    "head": "head", "neck": "head", "torso": "chest", "upperarm": "chest",
    "forearm": "hands", "hand": "hands", "thigh": "legs", "shin": "legs",
    "foot": "feet",
}
FALLBACK = {"head": "chest", "hands": "chest", "legs": "chest", "feet": "legs", "chest": "legs"}


def load_outfits():
    with open(os.path.join(HERE, "outfits.json"), encoding="utf-8") as f:
        sets = {k: v for k, v in json.load(f).items() if not k.startswith("_")}
    return {k: v for k, v in sets.items() if os.path.exists(os.path.join(OUTFIT_DIR, k + ".glb"))}


def _import(set_id):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(OUTFIT_DIR, set_id + ".glb"))
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.parent = None
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    # Matériaux propres à la tenue (pas de collision de noms entre tenues).
    for i, slot in enumerate(obj.material_slots):
        if slot.material:
            slot.material.name = f"outfit_{set_id}_{i}"
    return obj


def _half_width(points, z, dz, xlim):
    sel = [p for p in points if abs(p.z - z) < dz and abs(p.x) < xlim]
    if len(sel) < 8:
        return None
    xs = sorted(abs(p.x) for p in sel)
    ys = sorted(p.y for p in sel)
    hi = int(len(ys) * 0.95) - 1
    lo = int(len(ys) * 0.05)
    return xs[int(len(xs) * 0.95) - 1], (ys[hi] - ys[lo]) / 2, (ys[hi] + ys[lo]) / 2


def _fit(obj, cfg, j, height, body_points, bvh, part_of=None):
    vs = obj.data.vertices
    zs = [v.co.z for v in vs]
    lo, hi = min(zs), max(zs)
    top, bottom = cfg.get("top", 1.0) * height, cfg.get("bottom", 0.0) * height
    s = (top - bottom) / (hi - lo)
    xs = [v.co.x for v in vs]
    cx = (max(xs) + min(xs)) / 2
    cy = sum(v.co.y for v in vs) / len(vs)
    for v in vs:
        v.co = Vector(((v.co.x - cx) * s, (v.co.y - cy) * s, (v.co.z - lo) * s + bottom))

    hip_z = j["hip_l"].z

    def part_of_point(p):
        return part_of(p, j, height)

    islands = _vertex_islands(obj.data)

    for side in ("l", "r"):
        _fit_arm(vs, j, side, body_points, part_of_point, islands)


    # Largeur, par tranches de hauteur (hors bras), jusqu'au cou.
    shx = abs(j["shoulder_l"].x)
    zmin = min(v.co.z for v in vs)
    zmax = max(v.co.z for v in vs)
    bands = []
    count = 24
    for i in range(count):
        z = zmin + (zmax - zmin) * (i + 0.5) / count
        dz = (zmax - zmin) / count
        if z >= j["neck"].z:
            continue
        xlim = shx * 1.05 if z > hip_z + 0.03 * height else shx * 1.4
        o = _half_width([v.co for v in vs], z, dz, xlim)
        b = _half_width(body_points, z, dz, xlim)
        if o and b:
            sx = (b[0] * WIDTH_SLACK + 0.01) / o[0]
            sy = (b[1] * (WIDTH_SLACK + 0.03) + 0.01) / o[1]
            bands.append((z, min(sx, 1.15), min(sy, 1.15), b[2] - o[2]))
    if bands:
        def at(z):
            if z <= bands[0][0]:
                return bands[0][1:]
            if z >= bands[-1][0]:
                return bands[-1][1:]
            for a, b in zip(bands, bands[1:]):
                if a[0] <= z <= b[0]:
                    t = (z - a[0]) / (b[0] - a[0])
                    return tuple(x + (y - x) * t for x, y in zip(a[1:], b[1:]))
            return bands[-1][1:]

        for v in vs:
            if v.co.z >= j["neck"].z:
                continue
            arm = abs(v.co.x) > shx * 1.05 and v.co.z > hip_z + 0.03 * height
            sx, sy, dy = at(min(v.co.z, j["shoulder_l"].z - 0.03 * height) if arm else v.co.z)
            if not arm:
                v.co.x *= sx
            v.co.y = v.co.y * sy + dy

    # Casque : ramené à la taille de la tête (un peu plus large).
    head = j["head"]
    head_pts = [p for p in body_points if p.z > j["neck"].z + 0.02 * height]
    helm = [v for v in vs if v.co.z > j["neck"].z + 0.02 * height]
    if head_pts and len(helm) > 30:
        bw = max(abs(p.x - head.x) for p in head_pts)
        hw = sorted(abs(v.co.x - head.x) for v in helm)[int(len(helm) * 0.98) - 1]
        k = max(0.8, min(1.4, bw * 1.16 / hw))
        for v in helm:
            v.co = head + (v.co - head) * k

    # Hors de la peau.
    for v in vs:
        loc, nrm, _, _ = bvh.find_nearest(v.co)
        if loc is None:
            continue
        d = (v.co - loc).dot(nrm)
        if d < MARGIN:
            v.co = v.co + nrm * (MARGIN - d)
    obj.data.update()


def _axes(points):
    """Centre et axes principaux (du plus long au plus court) d'un nuage."""
    import numpy as np

    a = np.array([tuple(p) for p in points])
    c = a.mean(axis=0)
    w, v = np.linalg.eigh(np.cov((a - c).T))
    order = np.argsort(w)[::-1]
    return Vector(c), [Vector(v[:, k]) for k in order]


def _vertex_islands(mesh):
    """Groupes de sommets reliés par des arêtes."""
    parent = list(range(len(mesh.vertices)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for e in mesh.edges:
        a, b = find(e.vertices[0]), find(e.vertices[1])
        if a != b:
            parent[a] = b
    groups = {}
    for i in range(len(parent)):
        groups.setdefault(find(i), []).append(i)
    return list(groups.values())


def _fit_arm(vs, j, side, body_points, part_of_point, islands):
    """Bras de la tenue ramenés sur le bras du corps.

    On cherche l'orientation des bras de la tenue (pose T, A, bras le long
    du corps…) : le bras du corps est tourné autour de l'épaule jusqu'à
    recouvrir au mieux la manche. Chaque sommet de la tenue proche de ce
    bras tourné subit ensuite la rotation inverse : la manche revient en
    pose A avec le bras, quelle que soit sa pose d'origine."""
    from mathutils.kdtree import KDTree

    sh, el, wr = j["shoulder_" + side], j["elbow_" + side], j["wrist_" + side]
    sg = 1 if side == "l" else -1
    rest_dir = (wr - sh).normalized()
    sample = [v.co for v in list(vs)[:: max(1, len(vs) // 3000)]]

    def score(q):
        e, w = sh + q @ (el - sh), sh + q @ (wr - sh)
        n = 0
        for p in sample:
            for a, b in ((sh, e), (e, w)):
                ab = b - a
                t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
                if (p - (a + ab * t)).length < 0.055:
                    n += 1
                    break
        return n

    best, best_q = -1, None
    for down in range(-10, 90, 5):
        for fwd in range(-30, 35, 10):
            r, f = math.radians(down), math.radians(fwd)
            d = Vector((sg * math.cos(r) * math.cos(f), -math.cos(r) * math.sin(f), -math.sin(r)))
            q = rest_dir.rotation_difference(d).to_matrix()
            n = score(q)
            if n > best:
                best, best_q = n, q
    q = best_q
    inv = q.inverted()
    # Corps avec ce bras tourné ; on note pour chaque point s'il est du bras.
    tree = KDTree(len(body_points))
    is_arm = []
    for i, p in enumerate(body_points):
        part = part_of_point(p)
        arm = part in ("upperarm", "forearm", "hand") and (p.x > 0) == (side == "l")
        is_arm.append(arm)
        tree.insert(sh + q @ (p - sh) if arm else p, i)
    tree.balance()
    weights = []
    for v in vs:
        near = tree.find_n(v.co, 16)
        frac = sum(1 for _, i, _ in near if is_arm[i]) / len(near) if near else 0.0
        w = max(0.0, min(1.0, (frac - 0.3) / 0.4))
        weights.append(w * w * (3 - 2 * w))
    # Petits morceaux détachés (gant, brassard) : ils suivent le bras en
    # entier ou pas du tout, sans s'étirer.
    for island in islands:
        if len(island) < len(vs) * 0.2:
            mean = sum(weights[i] for i in island) / len(island)
            for i in island:
                weights[i] = 1.0 if mean > 0.35 else 0.0
    for v, w in zip(vs, weights):
        if w > 0:
            v.co = v.co.lerp(sh + inv @ (v.co - sh), w)


def _slot_faces(obj, cfg, j, height, part_of, body_bvh):
    """Emplacement de chaque face : partie du corps la plus proche (vote par
    îlot pour ne pas couper une plaque en deux)."""
    slots = cfg["slots"]
    dropped = set(cfg.get("drop_parts", []))
    mesh = obj.data
    face_slot = []
    for poly in mesh.polygons:
        loc, _, _, _ = body_bvh.find_nearest(poly.center)
        part = part_of(loc if loc is not None else poly.center, j, height)
        if part in dropped or (
            "face" in dropped and part == "head" and poly.center.y < j["head"].y - 0.03 * height
        ):
            face_slot.append(None)
            continue
        slot = SLOT_OF_PART[part]
        while slot not in slots:
            slot = FALLBACK[slot]
        face_slot.append(slot)
    # Îlots (faces reliées) : vote à la majorité pour les petits îlots.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    seen = set()
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
        if len(island) < 4000:
            votes = {}
            for i in island:
                votes[face_slot[i]] = votes.get(face_slot[i], 0) + 1
            best = max(votes, key=votes.get)
            for i in island:
                face_slot[i] = best
    bm.free()
    return face_slot


def _split(obj, face_slot, set_id):
    pieces = {}
    for slot in sorted({s for s in face_slot if s}):
        copy = obj.copy()
        copy.data = obj.data.copy()
        bpy.context.collection.objects.link(copy)
        bm = bmesh.new()
        bm.from_mesh(copy.data)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if face_slot[f.index] != slot], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(copy.data)
        bm.free()
        copy.name = f"item_{set_id}_{slot}"
        copy.data.name = copy.name
        pieces[slot] = copy
    bpy.data.objects.remove(obj, do_unlink=True)
    return pieces


def _morph_keys(obj, body, body_bvh):
    """Formes du corps reportées sur la pièce : déplacement du sommet de peau
    le plus proche, pour chaque forme de corpulence et de musculature."""
    keys = body.data.shape_keys.key_blocks
    basis = keys[0]
    nearest = []
    for v in obj.data.vertices:
        loc, _, face, _ = body_bvh.find_nearest(v.co)
        poly = body.data.polygons[face]
        nearest.append(min(poly.vertices, key=lambda i: (body.data.vertices[i].co - loc).length))
    obj.shape_key_add(name="Basis")
    for name in BODY_KEYS:
        if name not in keys:
            continue
        key = obj.shape_key_add(name=name)
        src = keys[name]
        for i, v in enumerate(obj.data.vertices):
            n = nearest[i]
            key.data[i].co = v.co + (src.data[n].co - basis.data[n].co)


def add_outfits(body, j, height, part_of):
    """Ajoute toutes les tenues au corps [body] (forme de base). Renvoie
    {tenue: [objets]}."""
    dg = bpy.context.evaluated_depsgraph_get()
    bm = bmesh.new()
    bm.from_mesh(body.data)
    body_points = [v.co.copy() for v in bm.verts]
    bvh = BVHTree.FromBMesh(bm)
    bm.free()
    del dg
    result = {}
    for set_id, cfg in load_outfits().items():
        obj = _import(set_id)
        _fit(obj, cfg, j, height, body_points, bvh, part_of)
        face_slot = _slot_faces(obj, cfg, j, height, part_of, bvh)
        pieces = _split(obj, face_slot, set_id)
        for piece in pieces.values():
            for poly in piece.data.polygons:
                poly.use_smooth = True
            _morph_keys(piece, body, bvh)
        result[set_id] = list(pieces.values())
        print("TENUE AJUSTÉE", set_id, sorted(pieces), flush=True)
    return result


def tint_material(obj, rgb):
    """Teinte de base d'une tenue sans texture (manteau blanc)."""
    for slot in obj.material_slots:
        mat = slot.material
        if mat and mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED" and not node.inputs["Base Color"].is_linked:
                    node.inputs["Base Color"].default_value = (*rgb, 1.0)
