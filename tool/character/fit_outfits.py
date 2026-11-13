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


def _import(set_id, path=None):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path or os.path.join(OUTFIT_DIR, set_id + ".glb"))
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
        _fit_arm(vs, j, side, body_points, part_of_point, islands, cfg.get("body", False))
    if cfg.get("body"):
        _fit_hands(vs, j, body_points)


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
    if head_pts and len(helm) > 30 and not cfg.get("body"):
        bw = max(abs(p.x - head.x) for p in head_pts)
        hw = sorted(abs(v.co.x - head.x) for v in helm)[int(len(helm) * 0.98) - 1]
        k = max(0.8, min(1.4, bw * 1.16 / hw))
        for v in helm:
            v.co = head + (v.co - head) * k

    # Hors de la peau.
    for v in ([] if cfg.get("body") else vs):
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


def _fit_hands(vs, j, body_points):
    """Corps fourni : sa main est recalée sur la main MPFB autour du poignet
    (direction poignet → centre de la main, et longueur), pour suivre les os
    des doigts."""
    for side in ("l", "r"):
        el, wr = j["elbow_" + side], j["wrist_" + side]
        fore = (wr - el).normalized()
        reach = (wr - el).length

        def along(p):
            d = (p - wr).dot(fore)
            return d, ((p - wr) - fore * d).length

        mine = [p for p in body_points if 0.01 < along(p)[0] < reach and along(p)[1] < reach * 0.45]
        hand = [v for v in vs if -0.03 < along(v.co)[0] < reach * 1.3 and along(v.co)[1] < reach * 0.5]
        theirs = [v.co for v in hand if along(v.co)[0] > 0.01]
        if len(mine) < 30 or len(theirs) < 30:
            continue
        bc = sum(mine, Vector()) / len(mine)
        gc = sum(theirs, Vector()) / len(theirs)
        k = max(0.8, min(1.25, max(along(p)[0] for p in mine) / max(max(along(p)[0] for p in theirs), 1e-4)))
        rot = (gc - wr).normalized().rotation_difference((bc - wr).normalized()).to_matrix()
        for v in hand:
            d, _ = along(v.co)
            w = max(0.0, min(1.0, (d + 0.03) / 0.05))
            w = w * w * (3 - 2 * w)
            v.co = v.co.lerp(wr + rot @ ((v.co - wr) * k), w)


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


def _fit_arm(vs, j, side, body_points, part_of_point, islands, smooth=False):
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
    sample = [v.co for v in list(vs)[:: max(1, len(vs) // 800)]]

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
    for down in range(-10, 90, 8):
        for fwd in range(-20, 25, 10):
            r, f = math.radians(down), math.radians(fwd)
            d = Vector((sg * math.cos(r) * math.cos(f), -math.cos(r) * math.sin(f), -math.sin(r)))
            q = rest_dir.rotation_difference(d).to_matrix()
            n = score(q)
            if n > best:
                best, best_q = n, q
    q = best_q
    # Bras déjà dans la pose du corps : rien à faire (évite de déformer les
    # mains et les flancs pour quelques degrés).
    if rest_dir.angle(q @ rest_dir) < math.radians(12):
        return
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
    if smooth:
        # Corps : le bras pivote autour de l'épaule comme une articulation,
        # avec un fondu le long du bras (pas de déchirure à l'aisselle).
        posed = (q @ (wr - sh)).normalized()
        weights = []
        for v in vs:
            if (v.co.x > 0) != (side == "l"):
                weights.append(0.0)
                continue
            t = (v.co - sh).dot(posed)
            radial = ((v.co - sh) - posed * t).length
            w = max(0.0, min(1.0, (t + 0.04) / 0.14))
            # Loin de l'axe du bras (jambes, flanc) : pas de rotation.
            w *= max(0.0, min(1.0, 1 - (radial - 0.09) / 0.05))
            weights.append(w * w * (3 - 2 * w))
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


def _morph_keys(obj, body, body_bvh, names=BODY_KEYS):
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
    for name in names:
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


def replace_body(body, path, j, height, part_of, overlap=0.012):
    """Remplace le corps MPFB sous le cou par le corps fourni (modèle 3D
    réaliste), ajusté sur le squelette : la tête MPFB (visage réglable,
    yeux, maquillage) est gardée. Le nouveau corps reçoit toutes les formes
    du corps MPFB (déplacement du point de peau le plus proche) et lui est
    joint ; ses matériaux s'appellent « skin_body_<n> » (teintés comme la
    peau)."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    body_points = [v.co.copy() for v in bm.verts]
    bvh = BVHTree.FromBMesh(bm)
    bm.free()
    new = _import("body", path)
    _fit(new, {"top": 1.0, "slots": ["chest"], "body": True}, j, height, body_points, bvh, part_of)
    names = [k.name for k in body.data.shape_keys.key_blocks[1:]]
    _morph_keys(new, body, bvh, names)
    cut = j["neck"].z
    # Nouveau corps : tout ce qui est sous le cou (un peu de recouvrement).
    _delete_faces(new, lambda c: c.z > cut + overlap)
    # Corps MPFB : seulement la tête et le haut du cou.
    _delete_faces(body, lambda c: c.z < cut - overlap)
    _split_skin(new)
    for poly in new.data.polygons:
        poly.use_smooth = True
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    new.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    return body


def _delete_faces(obj, test):
    """Supprime les faces dont le centre vérifie [test] (formes gardées)."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for poly in obj.data.polygons:
        poly.select = test(poly.center)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.delete(type="FACE")
    bpy.ops.object.mode_set(mode="OBJECT")


def push_out(objects, body, margin=0.003):
    """Pousse les vêtements hors du corps (après remplacement du corps) :
    même déplacement pour chaque forme."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bvh = BVHTree.FromBMesh(bm)
    bm.free()
    for obj in objects:
        keys = obj.data.shape_keys.key_blocks if obj.data.shape_keys else []
        for i, v in enumerate(obj.data.vertices):
            loc, nrm, _, _ = bvh.find_nearest(v.co)
            if loc is None:
                continue
            d = (v.co - loc).dot(nrm)
            if d < margin:
                delta = nrm * (margin - d)
                v.co += delta
                for key in keys:
                    key.data[i].co += delta


def _split_skin(obj):
    """Peau et sous-vêtements du corps fourni : la peau passe dans le
    matériau « skin_body » (texture ramenée au gris, teintée par la couleur
    de peau choisie), le reste (sous-vêtements) garde ses couleurs dans
    « body_underwear »."""
    import numpy as np

    mat = obj.material_slots[0].material
    tex = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE")
    img = tex.image
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-5), 0)
    # Teinte : la peau est orangée (rouge > vert > bleu).
    skin = (r > g) & (g > b) & (sat > 0.15) & (sat < 0.8) & (mx > 0.15)
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    gray = np.clip(lum / max(float(lum[skin].mean()), 1e-3) * 0.8, 0, 1)
    out = px.copy()
    for k in range(3):
        out[..., k] = np.where(skin, gray, px[..., k])
    neutral = bpy.data.images.new("skin_body_tex", w, h)
    neutral.pixels[:] = out.ravel()
    neutral.pack()
    underwear = mat
    underwear.name = "body_underwear"
    skin_mat = mat.copy()
    skin_mat.name = "skin_body"
    next(n for n in skin_mat.node_tree.nodes if n.type == "TEX_IMAGE").image = neutral
    for node in skin_mat.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            node.inputs["Roughness"].default_value = 0.55
    obj.data.materials.clear()
    obj.data.materials.append(skin_mat)
    obj.data.materials.append(underwear)
    uv = obj.data.uv_layers.active.data
    mask = skin
    for poly in obj.data.polygons:
        u = sum(uv[i].uv.x for i in poly.loop_indices) / poly.loop_total
        v = sum(uv[i].uv.y for i in poly.loop_indices) / poly.loop_total
        x = min(w - 1, max(0, int(u % 1.0 * w)))
        y = min(h - 1, max(0, int(v % 1.0 * h)))
        poly.material_index = 0 if mask[y, x] else 1


PIECES_DIR = os.path.join(HERE, "external")


def load_pieces():
    with open(os.path.join(HERE, "pieces.json"), encoding="utf-8") as f:
        data = json.load(f)
    return {
        key: [e for e in data[key] if os.path.exists(os.path.join(PIECES_DIR, folder, e["id"] + ".glb"))]
        for key, folder in (("hair", "hair"), ("beards", "beards"))
    }


def _place(obj, points, head_bvh, scales, anchor, target, score_points):
    """Cherche l'échelle qui pose au mieux [obj] : son point d'ancrage
    ([anchor] : fonction des sommets) sur [target], en pénétrant le moins
    possible la tête et en couvrant le mieux [score_points]."""
    from mathutils.kdtree import KDTree

    base = [v.co.copy() for v in obj.data.vertices]
    sample = base[:: max(1, len(base) // 2500)]
    best = None
    for s in scales:
        pts = [p * s for p in sample]
        shift = target - anchor(pts)
        pts = [p + shift for p in pts]
        inside = 0
        for p in pts:
            loc, nrm, _, _ = head_bvh.find_nearest(p)
            if loc is not None and (p - loc).dot(nrm) < -0.002 and (p - loc).length < 0.08:
                inside += 1
        tree = KDTree(len(pts))
        for i, p in enumerate(pts):
            tree.insert(p, i)
        tree.balance()
        gap = sum(min(tree.find(q)[2], 0.05) for q in score_points) / max(len(score_points), 1)
        score = inside / len(pts) * 0.6 + gap * 10
        if best is None or score < best[0]:
            best = (score, s, shift)
    _, s, shift = best
    for v, p in zip(obj.data.vertices, base):
        v.co = p * s + shift
    # Ce qui reste dans la tête en sort, à peine au-dessus de la peau.
    for v in obj.data.vertices:
        loc, nrm, _, _ = head_bvh.find_nearest(v.co)
        if loc is None or (v.co - loc).length > 0.08:
            continue
        d = (v.co - loc).dot(nrm)
        if d < 0.002:
            v.co += nrm * (0.002 - d)
    obj.data.update()


def add_head_pieces(head_bvh, head_points, marks):
    """Coiffures et barbes fournies, posées sur la tête MPFB. Matériaux
    « hair_<n> » / « beard_<n> » (teintés par l'application)."""
    pieces = load_pieces()
    top = max(head_points, key=lambda p: p.z)
    eyes_z = (marks["eyes"][0].z + marks["eyes"][1].z) / 2
    scalp = [p for p in head_points if p.z > eyes_z + 0.035]
    result = []
    for entry in pieces["hair"]:
        obj = _import(entry["id"], os.path.join(PIECES_DIR, "hair", entry["id"] + ".glb"))
        obj.name = entry["id"]

        def crown(pts):
            # Sommet de la coiffure : milieu des points les plus hauts.
            zt = max(p.z for p in pts)
            cap = [p for p in pts if p.z > zt - 0.03]
            return sum(cap, Vector()) / len(cap)

        _place(obj, None, head_bvh, _scales(obj, scalp), crown,
               Vector((0.0, top.y + 0.004, top.z + 0.012)), scalp[:: max(1, len(scalp) // 300)])
        for i, slot in enumerate(obj.material_slots):
            if slot.material:
                slot.material.name = f"{entry['id']}_{i}"
        result.append(obj)
    lips = marks["lips_center"]
    chin = marks["chin"]
    jaw = [p for p in head_points if chin.z - 0.01 < p.z < lips.z + 0.01 and p.y < lips.y + 0.05]
    for entry in pieces["beards"]:
        obj = _import(entry["id"], os.path.join(PIECES_DIR, "beards", entry["id"] + ".glb"))
        obj.name = entry["id"]

        def chin_point(pts):
            zb = min(p.z for p in pts)
            yb = min(p.y for p in pts)
            return Vector((sum(p.x for p in pts) / len(pts), yb, zb))

        _place(obj, None, head_bvh, _scales(obj, jaw), chin_point,
               Vector((0.0, chin.y - 0.012, chin.z - 0.02)), jaw[:: max(1, len(jaw) // 300)])
        for i, slot in enumerate(obj.material_slots):
            if slot.material:
                slot.material.name = f"{entry['id']}_{i}"
        result.append(obj)
    return result


def _scales(obj, region):
    """Échelles essayées : la largeur de la pièce rapportée à celle de la
    région (de 0,8 à 1,6 fois)."""
    xs = [v.co.x for v in obj.data.vertices]
    width = max(xs) - min(xs)
    rx = [p.x for p in region]
    target = max(rx) - min(rx)
    base = target / max(width, 1e-4)
    return [base * (0.8 + 0.05 * k) for k in range(17)]


def _signed(bvh, p):
    loc, nrm, _, _ = bvh.find_nearest(p)
    if loc is None:
        return 1.0
    return (p - loc).dot(nrm)


def _band(points, z0, z1):
    return [p for p in points if z0 <= p.z <= z1]


def _search(obj, scales, place, skin, bvh, margin):
    """Échelle qui colle le mieux la pièce au corps : peu de pénétration,
    peu d'écart avec la peau couverte ([skin])."""
    from mathutils.kdtree import KDTree

    base = [v.co.copy() for v in obj.data.vertices]
    sample = base[:: max(1, len(base) // 2000)]
    best = None
    for s in scales:
        pts = place([p * s for p in sample])
        z0 = min(p.z for p in pts)
        z1 = max(p.z for p in pts)
        covered = [q for q in skin if z0 <= q.z <= z1]
        if not covered:
            continue
        inside = sum(1 for p in pts if _signed(bvh, p) < 0) / len(pts)
        tree = KDTree(len(pts))
        for i, p in enumerate(pts):
            tree.insert(p, i)
        tree.balance()
        gap = sum(min(tree.find(q)[2], 0.06) for q in covered) / len(covered)
        score = inside * 0.5 + gap * 8
        if best is None or score < best[0]:
            best = (score, s)
    s = best[1] if best else scales[len(scales) // 2]
    placed = place([p * s for p in base])
    for v, p in zip(obj.data.vertices, placed):
        v.co = p
    for v in obj.data.vertices:
        d = _signed(bvh, v.co)
        if d < margin:
            loc, nrm, _, _ = bvh.find_nearest(v.co)
            v.co += nrm * (margin - d)
    obj.data.update()


def add_slot_pieces(body, j, height, part_of):
    """Pièces d'armure fournies (pieces.json, « armor ») : torses, pantalons,
    bottes, casques, ajustés sur le corps. Renvoie {objet: [pièce]}."""
    with open(os.path.join(HERE, "pieces.json"), encoding="utf-8") as f:
        armor = [e for e in json.load(f).get("armor", []) if os.path.exists(os.path.join(PIECES_DIR, "armor", e["id"] + ".glb"))]
    bm = bmesh.new()
    bm.from_mesh(body.data)
    pts = [v.co.copy() for v in bm.verts]
    bvh = BVHTree.FromBMesh(bm)
    bm.free()
    shx = abs(j["shoulder_l"].x)
    hip_z, neck_z = j["hip_l"].z, j["neck"].z
    torso = [p for p in pts if hip_z - 0.05 * height < p.z < j["shoulder_l"].z and abs(p.x) < shx * 1.05]
    legs = [p for p in pts if 0.05 * height < p.z < hip_z + 0.05 * height]
    head = [p for p in pts if p.z > neck_z + 0.02 * height]
    result = {}
    for e in armor:
        obj = _import(e["id"], os.path.join(PIECES_DIR, "armor", e["id"] + ".glb"))
        obj.name = "item_" + e["id"]
        vs = [v.co for v in obj.data.vertices]
        zs = [p.z for p in vs]
        lo, hi = min(zs), max(zs)
        slot = e["slot"]
        if slot == "chest":
            band = _band(vs, lo + (hi - lo) * 0.55, lo + (hi - lo) * 0.75)
            core = [p for p in band if abs(p.x) < (max(abs(q.x) for q in band) * 0.55)] or band
            depth = max(p.y for p in core) - min(p.y for p in core)
            chest = _band(torso, j["shoulder_l"].z - 0.12 * height, j["shoulder_l"].z - 0.05 * height)
            bdepth = max(p.y for p in chest) - min(p.y for p in chest)
            base = bdepth * 1.3 / max(depth, 1e-4)
            cy = sum(p.y for p in chest) / len(chest)

            def place(ps, cy=cy):
                top = max(p.z for p in ps)
                yc = (max(p.y for p in ps) + min(p.y for p in ps)) / 2
                return [Vector((p.x, p.y - yc + cy, p.z - top + neck_z + 0.035 * height)) for p in ps]

            _search(obj, [base * (0.75 + 0.05 * k) for k in range(13)], place, torso, bvh, 0.008)
            vco = obj.data.vertices
            islands = _vertex_islands(obj.data)
            for side in ("l", "r"):
                _fit_arm(vco, j, side, pts, lambda p: part_of(p, j, height), islands)
            for v in vco:
                d = _signed(bvh, v.co)
                if d < 0.008:
                    loc, nrm, _, _ = bvh.find_nearest(v.co)
                    v.co += nrm * (0.008 - d)
        elif slot == "legs":
            waist = hip_z + 0.06 * height
            base = (waist - 0.035 * height) / (hi - lo)
            hy = sum(p.y for p in _band(legs, hip_z - 0.05, hip_z + 0.05)) / max(1, len(_band(legs, hip_z - 0.05, hip_z + 0.05)))

            def place(ps, hy=hy, waist=waist):
                top = max(p.z for p in ps)
                yc = (max(p.y for p in ps) + min(p.y for p in ps)) / 2
                return [Vector((p.x, p.y - yc + hy, p.z - top + waist)) for p in ps]

            _search(obj, [base * (0.85 + 0.03 * k) for k in range(11)], place, legs, bvh, 0.006)
        elif slot == "feet":
            _fit_boots(obj, pts, bvh, j, height)
        elif slot == "head":
            hx = [p.x for p in head]
            hw = max(hx) - min(hx)
            xs = [p.x for p in vs]
            base = hw * 1.25 / max(max(xs) - min(xs), 1e-4)
            top = max(head, key=lambda p: p.z)

            def place(ps, top=top):
                zt = max(p.z for p in ps)
                cap = [p for p in ps if p.z > zt - 0.03]
                c = sum(cap, Vector()) / len(cap)
                shift = Vector((0.0, top.y + 0.01, top.z + 0.02)) - c
                return [p + shift for p in ps]

            _search(obj, [base * (0.85 + 0.05 * k) for k in range(8)], place, [p for p in head if p.z > top.z - 0.1], bvh, 0.004)
        for poly in obj.data.polygons:
            poly.use_smooth = True
        for i, mslot in enumerate(obj.material_slots):
            if mslot.material:
                mslot.material.name = f"item_{e['id']}_{i}"
        if slot != "head":
            _morph_keys(obj, body, bvh)
        else:
            obj["rigid_bone"] = "head"
        result[e["id"]] = [obj]
        print("PIÈCE AJUSTÉE", e["id"], slot, flush=True)
    return result


def _fit_boots(obj, pts, bvh, j, height):
    """Paire de bottes : chaque botte (îlot gauche / droit) posée sur son
    pied, semelle au sol, à la longueur du pied."""
    islands = _vertex_islands(obj.data)
    vs = obj.data.vertices
    left = [i for isl in islands for i in isl if sum(vs[k].co.x for k in isl) / len(isl) > 0]
    right = [i for isl in islands for i in isl if sum(vs[k].co.x for k in isl) / len(isl) <= 0]
    for side, ids in (("l", left), ("r", right)):
        if not ids:
            continue
        ankle = j["ankle_" + side]
        foot = [p for p in pts if p.z < ankle.z + 0.02 and (p.x > 0) == (side == "l")]
        if not foot:
            continue
        flen = max(p.y for p in foot) - min(p.y for p in foot)
        fx = sum(p.x for p in foot) / len(foot)
        toe = min(p.y for p in foot)
        b = [vs[i].co.copy() for i in ids]
        blen = max(p.y for p in b) - min(p.y for p in b)
        s = flen * 1.12 / max(blen, 1e-4)
        bx = (max(p.x for p in b) + min(p.x for p in b)) / 2
        by = min(p.y for p in b)
        bz = min(p.z for p in b)
        for i, p in zip(ids, b):
            q = (p - Vector((bx, by, bz))) * s
            vs[i].co = Vector((fx + q.x, toe - 0.012 + q.y, q.z))
    for v in vs:
        d = _signed(bvh, v.co)
        if d < 0.004:
            loc, nrm, _, _ = bvh.find_nearest(v.co)
            v.co += nrm * (0.004 - d)
    obj.data.update()
