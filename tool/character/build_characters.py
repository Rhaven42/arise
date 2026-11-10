"""Génère les modèles 3D de substitution d'ARISE (Blender + extension MPFB).

Six corps originaux (3 races × 2 sexes), chacun exporté en .glb avec :
- le corps (matériau « skin »), les yeux et, pour les orques, les défenses ;
- quatre formes de morphologie : corp_low / corp_high (corpulence) et
  musc_low / musc_high (musculature), appliquées au corps, à la tenue et à la
  calotte des coiffures, pour que tout suive les proportions ;
- la tenue de départ (outfit_tunic, outfit_pants, outfit_boots, outfit_belt),
  tirée de la géométrie d'aide « tights » du maillage MPFB : elle épouse donc
  le corps quelle que soit la morphologie ;
- dix coiffures originales (hair_01 à hair_10, matériau « hair »).

Lancement dans Blender (avec MPFB installé) :
    exec(open(".../tool/character/build_characters.py").read())
    build_all(r"C:/chemin/de/sortie")

Aucun asset tiers : seuls le maillage de base MakeHuman (CC0) et des formes
créées ici sont utilisés.
"""

import importlib
import math
import os

import bmesh
import bpy
from mathutils import Quaternion, Vector

_MPFB = "bl_ext.blender_org.mpfb.services."

SEXES = {"female": 0.0, "male": 1.0}

# Réglages de base par race (valeurs MPFB entre 0 et 1).
RACES = {
    "human": {"height": 0.5, "proportions": 0.55},
    "elf": {"height": 0.7, "proportions": 0.85},
    "orc": {"height": 0.65, "proportions": 0.35},
}

# États de morphologie : (nom de la forme, poids, musculature, cibles MPFB).
# Le visage utilise des cibles MPFB à pleine valeur ; chaque curseur pilote
# une forme « basse » et une forme « haute ».
FACE_TARGETS = {
    "face_jaw": (["chin-width-decr"], ["chin-width-incr"]),
    "face_nose": (["nose-volume-decr"], ["nose-volume-incr"]),
    "face_mouth": (["mouth-scale-horiz-decr"], ["mouth-scale-horiz-incr"]),
    "face_cheeks": (
        ["l-cheek-bones-decr", "r-cheek-bones-decr"],
        ["l-cheek-bones-incr", "r-cheek-bones-incr"],
    ),
    "face_ears": (
        ["l-ear-scale-decr", "r-ear-scale-decr"],
        ["l-ear-scale-incr", "r-ear-scale-incr"],
    ),
}

STATES = [
    ("base", 0.5, 0.5, []),
    ("corp_low", 0.0, 0.5, []),
    ("corp_high", 1.0, 0.5, []),
    ("musc_low", 0.5, 0.0, []),
    ("musc_high", 0.5, 1.0, []),
]
for _name, (_low, _high) in FACE_TARGETS.items():
    STATES.append((_name + "_low", 0.5, 0.5, _low))
    STATES.append((_name + "_high", 0.5, 0.5, _high))

HAIR_STYLES = [
    "hair_01",  # court
    "hair_02",  # queue de cheval
    "hair_03",  # natte
    "hair_04",  # chignon
    "hair_05",  # longs lisses
    "hair_06",  # crête
    "hair_07",  # rasé
    "hair_08",  # double natte
    "hair_09",  # carré
    "hair_10",  # crinière
]

COLORS = {
    "skin": (0.52, 0.30, 0.20, 1.0),
    "hair": (0.12, 0.03, 0.01, 1.0),
    "eyes": (0.05, 0.03, 0.02, 1.0),
    "tusk": (0.80, 0.74, 0.60, 1.0),
    "linen": (0.42, 0.34, 0.22, 1.0),
    "wool": (0.07, 0.04, 0.022, 1.0),
    "leather": (0.035, 0.018, 0.01, 1.0),
    "rope": (0.30, 0.20, 0.09, 1.0),
    "sclera": (0.85, 0.83, 0.80, 1.0),
    "iris": (0.25, 0.14, 0.06, 1.0),
    "pupil": (0.01, 0.01, 0.01, 1.0),
    "brow": (0.12, 0.03, 0.01, 1.0),
    "beard": (0.12, 0.03, 0.01, 1.0),
}


def _services():
    hs = importlib.import_module(_MPFB + "humanservice").HumanService
    return hs


def _material(name, color=None):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = color or COLORS[name]
    bsdf.inputs["Roughness"].default_value = 0.45 if name in ("skin", "hair", "tusk") else 0.9
    mat.use_backface_culling = False
    return mat


def _state_coords(sex, race, weight, muscle, targets=()):
    """Coordonnées (formes MPFB appliquées) du maillage complet, aides comprises."""
    hs = _services()
    macro = {
        "gender": SEXES[sex],
        "age": 0.5,
        "muscle": muscle,
        "weight": weight,
        "proportions": RACES[race]["proportions"],
        "height": RACES[race]["height"],
        "cupsize": 0.5,
        "firmness": 0.5,
        "race": {"asian": 0.33, "caucasian": 0.33, "african": 0.33},
    }
    human = hs.create_human(macro_detail_dict=macro)
    ts = importlib.import_module(_MPFB + "targetservice").TargetService
    for target in targets:
        ts.load_target(human, ts.target_full_path(target), weight=1.0)
    for mod in human.modifiers:
        mod.show_viewport = False
    evaluated = human.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = bpy.data.meshes.new_from_object(evaluated)
    coords = [v.co.copy() for v in mesh.vertices]
    groups = {g.index: g.name for g in human.vertex_groups}
    membership = {}
    for v in human.data.vertices:
        for g in v.groups:
            if g.weight > 0.5:
                membership.setdefault(groups[g.group], set()).add(v.index)
    template = mesh
    bpy.data.objects.remove(human, do_unlink=True)
    return coords, membership, template


def _race_deform(race, coords, groups):
    """Traits de race originaux, appliqués de la même façon à chaque état."""
    if race == "human":
        return coords
    out = [c.copy() for c in coords]
    ears = groups.get("ears", set())
    if race == "elf" and ears:
        # Oreilles allongées vers le haut et l'arrière, de façon progressive.
        zs = [coords[i].z for i in ears]
        z0, z1 = min(zs), max(zs)
        for i in ears:
            t = (coords[i].z - z0) / max(z1 - z0, 1e-6)
            t = t * t
            side = 1 if coords[i].x > 0 else -1
            out[i] += Vector((side * 0.012 * t, 0.022 * t, 0.05 * t))
    if race == "orc":
        lips = groups.get("lips", set())
        mouth_z = sum(coords[i].z for i in lips) / max(len(lips), 1)
        head = groups.get("body", set())
        top = max(coords[i].z for i in head)
        for i in head:
            c = coords[i]
            # Mâchoire plus large sous la bouche.
            if top - 0.30 < c.z < mouth_z + 0.005 and c.y < 0.02:
                k = min(1.0, (mouth_z + 0.005 - c.z) / 0.06)
                out[i].x *= 1 + 0.16 * k
            # Arcade sourcilière marquée.
            if mouth_z + 0.07 < c.z < mouth_z + 0.10 and c.y < -0.06:
                out[i].y -= 0.006
            # Carrure plus large du buste et des épaules, avec une transition
            # douce (sans cassure aux poignets ni à la taille).
            t = (c.z / top - 0.60) / 0.12
            t = max(0.0, min(1.0, t))
            u = (top - 0.18 - c.z) / 0.06
            u = max(0.0, min(1.0, u))
            out[i].x *= 1 + 0.07 * (t * t * (3 - 2 * t)) * u
    return out


def _extract(template, keep, name, states, offset=0.0, flare=None, refine=None):
    """Crée un objet à partir des faces de [keep], avec une forme par état."""
    bm = bmesh.new()
    bm.from_mesh(template)
    bm.verts.ensure_lookup_table()
    # Index d'origine mémorisé avant la suppression (bmesh renumérote).
    layer = bm.verts.layers.int.new("src")
    for v in bm.verts:
        v[layer] = v.index
    remove = [f for f in bm.faces if not all(v.index in keep for v in f.verts)]
    bmesh.ops.delete(bm, geom=remove, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.validate()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    src_layer = mesh.attributes["src"]
    sources = [src_layer.data[i].value for i in range(len(mesh.vertices))]
    mesh.attributes.remove(src_layer)
    base = states["base"]

    def positions(coords):
        tmp = bpy.data.meshes.new("tmp")
        verts = [coords[s] for s in sources]
        tmp.from_pydata(verts, [], [list(p.vertices) for p in mesh.polygons])
        tmp.update()
        result = []
        for v in tmp.vertices:
            co = v.co + v.normal * offset
            if flare:
                z0, k = flare
                if co.z < z0:
                    t = z0 - co.z
                    co = Vector((co.x * (1 + k * t), co.y * (1 + k * 0.6 * t), co.z))
            result.append(co)
        bpy.data.meshes.remove(tmp)
        return result

    for v, co in zip(mesh.vertices, positions(base)):
        v.co = co
    obj.shape_key_add(name="Basis")
    for state_name, *_ in STATES[1:]:
        key = obj.shape_key_add(name=state_name)
        for i, co in enumerate(positions(states[state_name])):
            key.data[i].co = co
    if refine is not None:
        # Contour plus net pour les petites pièces (sourcils, barbes,
        # maquillages) : on subdivise puis on retire les faces hors zone.
        # Les formes de morphologie sont interpolées par bmesh.
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=3, use_grid_fill=True)
        outside = [f for f in bm.faces if not refine(f.calc_center_median())]
        bmesh.ops.delete(bm, geom=outside, context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(mesh)
        bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


def _ring(name, band, states, gap, radius, segments=40, sides=6):
    """Anneau (ceinture) posé autour de [band], recalculé pour chaque état."""

    def ring_points(coords):
        pts = [coords[i] for i in band]
        cx = sum(p.x for p in pts) / len(pts)
        cy = sum(p.y for p in pts) / len(pts)
        cz = sum(p.z for p in pts) / len(pts)
        ring = []
        for k in range(segments):
            ang = 2 * math.pi * k / segments
            best = 0.0
            for p in pts:
                a = math.atan2(p.y - cy, p.x - cx)
                d = abs((a - ang + math.pi) % (2 * math.pi) - math.pi)
                if d < math.pi / segments * 2.5:
                    best = max(best, math.hypot(p.x - cx, p.y - cy))
            ring.append((ang, best + gap))
        # Lissage léger du rayon pour une corde régulière.
        smooth = []
        for k in range(segments):
            r = (ring[k - 1][1] + 2 * ring[k][1] + ring[(k + 1) % segments][1]) / 4
            smooth.append((ring[k][0], r))
        verts = []
        for ang, r in smooth:
            center = Vector((cx + r * math.cos(ang), cy + r * math.sin(ang), cz))
            radial = Vector((math.cos(ang), math.sin(ang), 0))
            for j in range(sides):
                b = 2 * math.pi * j / sides
                verts.append(center + radial * (radius * math.cos(b)) + Vector((0, 0, radius * math.sin(b))))
        return verts

    faces = []
    for k in range(segments):
        for j in range(sides):
            a = k * sides + j
            b = k * sides + (j + 1) % sides
            c = ((k + 1) % segments) * sides + (j + 1) % sides
            d = ((k + 1) % segments) * sides + j
            faces.append((a, b, c, d))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(ring_points(states["base"]), [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.shape_key_add(name="Basis")
    for state_name, *_ in STATES[1:]:
        key = obj.shape_key_add(name=state_name)
        for i, co in enumerate(ring_points(states[state_name])):
            key.data[i].co = co
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


def _join_rigid(target, parts):
    """Ajoute des pièces rigides (sans forme) à un objet qui a des formes."""
    if not parts:
        return target
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.join()
    return target


def _tube(name, points, radii, sides=10):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = 1.0
    curve.bevel_resolution = max(1, sides // 4)
    curve.resolution_u = 6
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, p, r in zip(spline.bezier_points, points, radii):
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = "AUTO"
        bp.radius = r
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return bpy.context.view_layer.objects.active


def _blob(name, center, scale):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return obj


def _head_frame(coords, groups):
    scalp = groups["scalp"]
    pts = [coords[i] for i in scalp]
    top = max(pts, key=lambda p: p.z)
    back = max(pts, key=lambda p: p.y)
    width = max(abs(p.x) for p in pts)
    low = min(p.z for p in pts)
    return top, back, width, low


def _hair_styles(template, groups, states, hair_mat):
    scalp = groups["scalp"]
    base = states["base"]
    top, back, width, low = _head_frame(base, groups)
    styles = []
    for name in HAIR_STYLES:
        thickness = {"hair_07": 0.004, "hair_01": 0.012}.get(name, 0.015)
        cap = _extract(template, scalp, name, states, offset=thickness)
        extras = []
        bz = back.z
        by = back.y
        if name == "hair_02":
            extras.append(_tube(name + "_tail", [(0, by + 0.01, bz + 0.03), (0, by + 0.06, bz - 0.06), (0, by + 0.07, bz - 0.22), (0, by + 0.05, bz - 0.34)], [0.03, 0.028, 0.022, 0.008]))
        if name == "hair_03":
            extras.append(_tube(name + "_braid", [(0, by + 0.005, bz), (0, by + 0.04, bz - 0.12), (0.004, by + 0.05, bz - 0.26), (0, by + 0.04, bz - 0.40)], [0.024, 0.022, 0.018, 0.008]))
        if name == "hair_04":
            extras.append(_blob(name + "_bun", (0, by + 0.035, bz + 0.06), (0.05, 0.045, 0.045)))
        if name == "hair_05":
            for side in (-1, 1):
                extras.append(_tube(name + f"_lock{side}", [(side * width * 0.8, by - 0.03, bz + 0.02), (side * width * 0.9, by + 0.01, bz - 0.12), (side * width * 0.85, by + 0.02, bz - 0.30)], [0.035, 0.04, 0.02]))
            extras.append(_tube(name + "_back", [(0, by + 0.01, bz + 0.04), (0, by + 0.04, bz - 0.14), (0, by + 0.05, bz - 0.34)], [0.06, 0.065, 0.03]))
        if name == "hair_06":
            extras.append(_tube(name + "_crest", [(0, top.y - 0.07, top.z - 0.01), (0, top.y - 0.01, top.z + 0.05), (0, top.y + 0.06, top.z + 0.03), (0, by + 0.02, bz - 0.02)], [0.012, 0.02, 0.02, 0.01]))
        if name == "hair_08":
            for side in (-1, 1):
                extras.append(_tube(name + f"_braid{side}", [(side * width * 0.85, by - 0.05, low + 0.02), (side * width * 0.95, by - 0.07, low - 0.10), (side * width * 0.9, by - 0.09, low - 0.24)], [0.02, 0.018, 0.008]))
        if name == "hair_09":
            extras.append(_tube(name + "_bob", [(-width * 0.95, by - 0.07, low + 0.03), (0, by + 0.02, low + 0.01), (width * 0.95, by - 0.07, low + 0.03)], [0.035, 0.045, 0.035]))
        if name == "hair_10":
            for i, ang in enumerate((-1.0, -0.5, 0.0, 0.5, 1.0)):
                x = math.sin(ang) * width * 0.9
                y = by - 0.02 + math.cos(ang) * 0.02
                extras.append(_tube(name + f"_mane{i}", [(x, y, bz + 0.05), (x * 1.15, y + 0.05, bz - 0.10), (x * 1.1, y + 0.06, bz - 0.30)], [0.04, 0.045, 0.012]))
        for e in extras:
            e.data.materials.clear()
            for poly in e.data.polygons:
                poly.use_smooth = True
        obj = _join_rigid(cap, extras)
        obj.name = name
        obj.data.materials.clear()
        obj.data.materials.append(hair_mat)
        styles.append(obj)
    return styles


# --- Visage : yeux, sourcils, barbes, maquillages ---------------------------

EYEBROW_STYLES = {
    # nom : (bas, haut, demi-largeur, arc, décalage vers le nez)
    "brow_01": (0.013, 0.022, 0.026, 0.003, 0.0),  # fins
    "brow_02": (0.011, 0.026, 0.027, 0.002, 0.0),  # épais
    "brow_03": (0.013, 0.023, 0.026, 0.007, 0.0),  # arqués
    "brow_04": (0.012, 0.022, 0.028, 0.0, 0.0),  # droits
    "brow_05": (0.012, 0.022, 0.017, 0.002, 0.008),  # courts
    "brow_06": (0.010, 0.028, 0.031, 0.003, 0.0),  # broussailleux
}

MAKEUP_COLORS = {
    "makeup_01": (0.02, 0.015, 0.015, 1.0),  # khôl
    "makeup_02": (0.45, 0.04, 0.06, 1.0),  # lèvres
    "makeup_03": (0.70, 0.30, 0.30, 1.0),  # fard à joues
    "makeup_04": (0.55, 0.22, 0.05, 1.0),  # peinture de guerre
}


def _faces_where(template, coords, candidates, test):
    """Sommets des faces dont le centre (état de base) vérifie [test]."""
    keep = set()
    for poly in template.polygons:
        verts = poly.vertices
        if not all(v in candidates for v in verts):
            continue
        n = len(verts)
        c = Vector((
            sum(coords[v].x for v in verts) / n,
            sum(coords[v].y for v in verts) / n,
            sum(coords[v].z for v in verts) / n,
        ))
        if test(c):
            keep.update(verts)
    return keep


def _landmarks(coords, groups):
    """Repères du visage, calculés sur l'état de base."""

    def center(name):
        pts = [coords[i] for i in groups.get(name, set())]
        n = max(len(pts), 1)
        return Vector((sum(p.x for p in pts) / n, sum(p.y for p in pts) / n, sum(p.z for p in pts) / n))

    eye_l, eye_r = center("helper-l-eye"), center("helper-r-eye")
    eye_radius = max((coords[i] - eye_l).length for i in groups.get("helper-l-eye", {0}))
    lips = [coords[i] for i in groups.get("lips", set())]
    lips_center = center("lips")
    lips_bottom = min(p.z for p in lips)
    lips_top = max(p.z for p in lips)
    head = [coords[i] for i in groups["body"] if coords[i].z > lips_bottom - 0.09]
    chin = min((p for p in head if abs(p.x) < 0.01 and p.y < lips_center.y + 0.03), key=lambda p: p.z)
    ears = [coords[i] for i in groups.get("ears", set())]
    ear_x = min(abs(p.x) for p in ears) if ears else 0.07
    ear_y = sum(p.y for p in ears) / max(len(ears), 1) if ears else 0.0
    ear_z = sum(p.z for p in ears) / max(len(ears), 1) if ears else eye_l.z
    return {
        "eyes": (eye_l, eye_r),
        "eye_radius": eye_radius,
        "lips_center": lips_center,
        "lips_bottom": lips_bottom,
        "lips_top": lips_top,
        "chin": chin,
        "ear_x": ear_x,
        "ear_y": ear_y,
        "ear_z": ear_z,
    }


def _front(c, marks):
    # Face avant de la tête : devant les oreilles.
    return c.y < marks["ear_y"] - 0.01


def _eye_parts(template, groups, states, mats):
    """Yeux en trois matériaux : blanc, iris (couleur réglable) et pupille."""
    co = states["base"]
    objs = []
    eyes = []
    for side in ("helper-l-eye", "helper-r-eye"):
        verts = groups.get(side, set())
        if verts:
            n = len(verts)
            c = Vector((sum(co[i].x for i in verts) / n, sum(co[i].y for i in verts) / n, sum(co[i].z for i in verts) / n))
            eyes.append((verts, c))

    def zone(limit):
        keep = set()
        for verts, c in eyes:
            # Le regard est dirigé vers -Y (l'avant du corps).
            keep |= _faces_where(template, co, verts, lambda p, c=c: -(p - c).normalized().y > limit)
        return keep

    all_eyes = set().union(*(v for v, _ in eyes)) if eyes else set()
    for name, keep, offset, mat in (
        ("eye_sclera", all_eyes, 0.0, "sclera"),
        ("eye_iris", zone(0.80), 0.0004, "iris"),
        ("eye_pupil", zone(0.95), 0.0008, "pupil"),
    ):
        if not keep:
            continue
        obj = _extract(template, keep, name, states, offset=offset)
        obj.data.materials.append(mats[mat])
        objs.append(obj)
    return objs


def _eyebrows(template, groups, states, marks, mat):
    co = states["base"]
    body = groups["body"]
    objs = []
    for name, (low, high, half, arch, inner) in EYEBROW_STYLES.items():

        def test(c, low=low, high=high, half=half, arch=arch, inner=inner):
            if not _front(c, marks):
                return False
            for eye in marks["eyes"]:
                cx = eye.x - (inner if eye.x > 0 else -inner)
                dx = (c.x - cx) / half
                if abs(dx) > 1 or c.y > eye.y:
                    continue
                lift = arch * (1 - dx * dx)
                if eye.z + low + lift < c.z < eye.z + high + lift:
                    return True
            return False

        keep = _faces_where(template, co, body, test)
        if not keep:
            continue
        obj = _extract(template, keep, name, states, offset=0.0015)
        obj.data.materials.append(mat)
        objs.append(obj)
    return objs


def _beards(template, groups, states, marks, mat):
    co = states["base"]
    body = groups["body"]
    lc = marks["lips_center"]
    lb, lt = marks["lips_bottom"], marks["lips_top"]
    chin = marks["chin"]
    ex = marks["ear_x"]
    lips = groups.get("lips", set())

    def face(c):
        return _front(c, marks) and abs(c.x) < ex + 0.005

    def full(c):
        return face(c) and chin.z - 0.02 < c.z < lt + 0.012 and not (abs(c.x) < 0.028 and lb - 0.004 < c.z < lt + 0.004)

    styles = {
        "beard_01": (lambda c: full(c) and c.z < lc.z + 0.004 or (full(c) and abs(c.x) < 0.03 and c.z > lt), 0.002),
        "beard_02": (lambda c: face(c) and abs(c.x) < 0.026 and chin.z - 0.01 < c.z < lb - 0.003, 0.0025),
        "beard_03": (lambda c: face(c) and abs(c.x) < 0.032 and lt + 0.002 < c.z < lt + 0.016, 0.002),
        "beard_04": (lambda c: full(c) and c.z < lb - 0.012, 0.002),
        "beard_05": (lambda c: full(c), 0.006),
        "beard_06": (lambda c: _front(c, marks) and ex - 0.012 < abs(c.x) < ex + 0.004 and marks["ear_z"] - 0.03 < c.z < marks["ear_z"] + 0.012 and c.y < marks["ear_y"] - 0.004, 0.002),
    }
    objs = []
    for name, (test, offset) in styles.items():
        keep = _faces_where(template, co, body - lips, test)
        if not keep:
            continue
        obj = _extract(template, keep, name, states, offset=offset)
        if name == "beard_05":
            # Barbe longue : une pointe qui descend sous le menton.
            tip = _tube(name + "_tip", [(0, chin.y - 0.004, chin.z + 0.01), (0, chin.y - 0.008, chin.z - 0.03), (0, chin.y - 0.004, chin.z - 0.07)], [0.028, 0.022, 0.006])
            obj = _join_rigid(obj, [tip])
            obj.name = name
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        objs.append(obj)
    return objs


def _makeups(template, groups, states, marks):
    co = states["base"]
    body = groups["body"]
    r = marks["eye_radius"]
    objs = []
    tests = {
        "makeup_01": lambda c: any(_front(c, marks) and r + 0.0005 < ((c.x - e.x) ** 2 + (c.z - e.z) ** 2) ** 0.5 < r + 0.005 for e in marks["eyes"]),
        "makeup_02": None,
        "makeup_03": lambda c: any(_front(c, marks) and ((c.x - e.x * 1.15) ** 2 + (c.z - (e.z - 0.028)) ** 2) ** 0.5 < 0.009 for e in marks["eyes"]),
        "makeup_04": lambda c: _front(c, marks) and abs(c.x) < abs(marks["eyes"][0].x) + 0.03 and abs(c.z - marks["eyes"][0].z) < 0.007 and all(((c.x - e.x) ** 2 + (c.z - e.z) ** 2) ** 0.5 > r + 0.0005 for e in marks["eyes"]),
    }
    for name, test in tests.items():
        keep = set(groups.get("lips", set())) if test is None else _faces_where(template, co, body, test)
        if not keep:
            continue
        obj = _extract(template, keep, name, states, offset=0.0006)
        obj.data.materials.append(_material(name, MAKEUP_COLORS[name]))
        objs.append(obj)
    return objs


# --- Squelette et poses -------------------------------------------------------

# Rotations (os, axe dans le repère du corps au repos, degrés). L'axe X fait
# avancer un membre vers l'arrière pour les bras et les jambes, et pencher le
# buste ou la tête vers l'avant ; l'axe Y rapproche le bras gauche du corps.
POSES = {
    "pose_a": [],
    "pose_relaxed": [
        ("upperarm_l", (0, 1, 0), 40), ("upperarm_r", (0, -1, 0), 40),
        ("lowerarm_l", (1, 0, 0), -15), ("lowerarm_r", (1, 0, 0), -15),
        ("spine_03", (1, 0, 0), 3), ("head", (1, 0, 0), 3),
    ],
    "pose_heroic": [
        ("upperarm_l", (0, 1, 0), 24), ("upperarm_r", (0, -1, 0), 24),
        ("upperarm_l", (1, 0, 0), 8), ("upperarm_r", (1, 0, 0), 8),
        ("lowerarm_l", (1, 0, 0), -12), ("lowerarm_r", (1, 0, 0), -12),
        ("spine_03", (1, 0, 0), -8), ("head", (1, 0, 0), -6),
        ("thigh_l", (0, -1, 0), 6), ("thigh_r", (0, 1, 0), 6),
    ],
    "pose_combat": [
        ("upperarm_l", (0, 1, 0), 55), ("upperarm_r", (0, -1, 0), 55),
        ("upperarm_l", (1, 0, 0), -30), ("upperarm_r", (1, 0, 0), -25),
        ("lowerarm_l", (0, 0, -1), 72), ("lowerarm_r", (0, 0, 1), 78),
        ("spine_02", (1, 0, 0), 8), ("head", (1, 0, 0), -5),
        ("thigh_l", (1, 0, 0), -16), ("calf_l", (1, 0, 0), 18),
        ("thigh_r", (1, 0, 0), 12), ("calf_r", (1, 0, 0), 22),
    ],
}

# Postures et respiration, ajoutées par-dessus la pose (animations additives).
POSTURES = {
    "posture_neutral": [],
    "posture_upright": [("spine_03", (1, 0, 0), -5), ("neck_01", (1, 0, 0), -4)],
    "posture_slouched": [("spine_02", (1, 0, 0), 9), ("spine_03", (1, 0, 0), 9), ("neck_01", (1, 0, 0), 8)],
    "posture_arched": [("spine_03", (1, 0, 0), -12), ("head", (1, 0, 0), -6)],
}


def _rotate(arm, name, axis, degrees):
    pose_bone = arm.pose.bones[name]
    pose_bone.rotation_mode = "QUATERNION"
    bone = arm.data.bones[name]
    local = (bone.matrix_local.inverted().to_3x3() @ Vector(axis)).normalized()
    pose_bone.rotation_quaternion = Quaternion(local, math.radians(degrees)) @ pose_bone.rotation_quaternion


def _reset_pose(arm):
    for pose_bone in arm.pose.bones:
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = (1, 0, 0, 0)
        pose_bone.location = (0, 0, 0)


def _key_all(arm, frame):
    for pose_bone in arm.pose.bones:
        pose_bone.keyframe_insert("rotation_quaternion", frame=frame)


def _make_actions(arm):
    arm.animation_data_create()
    actions = []
    for name, ops in {**POSES, **POSTURES}.items():
        _reset_pose(arm)
        action = bpy.data.actions.new(name)
        arm.animation_data.action = action
        for bone, axis, degrees in ops:
            _rotate(arm, bone, axis, degrees)
        _key_all(arm, 1)
        _key_all(arm, 2)
        action.use_fake_user = True
        actions.append(action)
    # Respiration : la poitrine se soulève légèrement, en boucle sur 4 s.
    action = bpy.data.actions.new("breath")
    arm.animation_data.action = action
    for frame, amount in ((1, 0.0), (49, 1.0), (97, 0.0)):
        _reset_pose(arm)
        _rotate(arm, "spine_03", (1, 0, 0), -2.2 * amount)
        _rotate(arm, "clavicle_l", (0, 1, 0), -1.5 * amount)
        _rotate(arm, "clavicle_r", (0, -1, 0), -1.5 * amount)
        _key_all(arm, frame)
    action.use_fake_user = True
    actions.append(action)
    _reset_pose(arm)
    arm.animation_data.action = None
    # Chaque action devient une piste NLA pour être exportée séparément.
    for action in actions:
        track = arm.animation_data.nla_tracks.new()
        track.name = action.name
        track.strips.new(action.name, 1, action)
        track.mute = True
    return actions


def _rig_and_skin(sex, race, objects, rigid):
    """Ajoute le squelette MPFB « game_engine » et les poids de peau."""
    hs = _services()
    macro = {
        "gender": SEXES[sex], "age": 0.5, "muscle": 0.5, "weight": 0.5,
        "proportions": RACES[race]["proportions"], "height": RACES[race]["height"],
        "cupsize": 0.5, "firmness": 0.5,
        "race": {"asian": 0.33, "caucasian": 0.33, "african": 0.33},
    }
    source = hs.create_human(macro_detail_dict=macro)
    hs.add_builtin_rig(source, "game_engine")
    arm = source.parent if source.parent and source.parent.type == "ARMATURE" else next(o for o in bpy.data.objects if o.type == "ARMATURE")
    arm.name = "rig"
    for mod in list(source.modifiers):
        if mod.type == "MASK":
            mod.show_viewport = False
    for obj in objects:
        obj.vertex_groups.clear()
        if obj.name in rigid:
            group = obj.vertex_groups.new(name="head")
            group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
        else:
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            source.select_set(True)
            bpy.context.view_layer.objects.active = source
            bpy.ops.object.data_transfer(
                use_reverse_transfer=False,
                data_type="VGROUP_WEIGHTS",
                vert_mapping="POLYINTERP_NEAREST",
                layers_select_src="ALL",
                layers_select_dst="NAME",
            )
            bones = {b.name for b in arm.data.bones}
            for group in list(obj.vertex_groups):
                if group.name not in bones:
                    obj.vertex_groups.remove(group)
        mod = obj.modifiers.new("rig", "ARMATURE")
        mod.object = arm
        obj.parent = arm
    bpy.data.objects.remove(source, do_unlink=True)
    _make_actions(arm)
    return arm



def _clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for armature in list(bpy.data.armatures):
        if armature.users == 0:
            bpy.data.armatures.remove(armature)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def build(sex, race, out_dir):
    _clear_scene()
    states = {}
    groups = None
    template = None
    for state_name, weight, muscle, targets in STATES:
        coords, membership, mesh = _state_coords(sex, race, weight, muscle, targets)
        groups = groups or membership
        template = template or mesh
        states[state_name] = _race_deform(race, coords, groups)
    for i, co in enumerate(states["base"]):
        template.vertices[i].co = co
    mats = {name: _material(name) for name in COLORS}

    body = _extract(template, groups["body"], "body", states)
    body.data.materials.append(mats["skin"])
    marks = _landmarks(states["base"], groups)
    _eye_parts(template, groups, states, mats)
    _eyebrows(template, groups, states, marks, mats["brow"])
    if sex == "male":
        _beards(template, groups, states, marks, mats["beard"])
    _makeups(template, groups, states, marks)

    tights = groups["helper-tights"]
    co = states["base"]
    # Seuils exprimés en fraction de la taille du corps (toutes les races).
    height = max(co[i].z for i in groups["body"])
    z = {i: co[i].z / height for i in tights}
    x = {i: abs(co[i].x) / height for i in tights}
    legs = {i for i in tights if z[i] < 0.39 or x[i] < 0.138}
    pieces = [
        ("outfit_tunic", {i for i in tights if 0.585 < z[i] < 0.835 and x[i] < 0.157}, 0.014, None, "linen"),
        ("outfit_pants", {i for i in legs if 0.17 < z[i] < 0.62}, 0.008, None, "wool"),
        ("outfit_boots", {i for i in tights if z[i] < 0.207}, 0.012, None, "leather"),
    ]
    # Bas de la tunique : la géométrie d'aide « jupe » tombe droit sur les hanches.
    skirt = {i for i in groups["helper-skirt"] if co[i].z / height > 0.40}
    pieces.append(("outfit_tunic_skirt", skirt, 0.012, None, "linen"))
    # Ceinture de corde posée sur la jonction entre le haut et le bas.
    band = [i for i in groups["body"] if 0.588 < co[i].z / height < 0.607 and abs(co[i].x) / height < 0.16]
    for name, keep, offset, flare, mat in pieces:
        if not keep:
            continue
        obj = _extract(template, keep, name, states, offset=offset, flare=flare)
        obj.data.materials.append(mats[mat])

    belt = _ring("outfit_belt", band, states, 0.034, 0.008)
    belt.data.materials.append(mats["rope"])

    if race == "orc":
        lips = [co[i] for i in groups.get("lips", set()) if co[i].z > 0.85 * height]
        if lips:
            mz = min(p.z for p in lips)
            fy = min(p.y for p in lips)
            xs = [p.x for p in lips]
            tusks = []
            for side in (min(xs) * 0.6, max(xs) * 0.6):
                bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.006, radius2=0.0008, depth=0.024, location=(side, fy + 0.006, mz + 0.006))
                cone = bpy.context.active_object
                cone.rotation_euler = (math.radians(-12), 0, 0)
                bpy.ops.object.transform_apply(rotation=True)
                tusks.append(cone)
            bpy.ops.object.select_all(action="DESELECT")
            for t in tusks:
                t.select_set(True)
            bpy.context.view_layer.objects.active = tusks[0]
            bpy.ops.object.join()
            tusk = bpy.context.active_object
            tusk.name = "tusks"
            tusk.data.materials.append(mats["tusk"])

    _hair_styles(template, groups, states, mats["hair"])
    bpy.data.meshes.remove(template)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    rigid = {o.name for o in meshes if o.name.startswith(("hair_", "tusks", "eye_"))}
    _rig_and_skin(sex, race, meshes, rigid)

    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{race}_{sex}.glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_morph=True,
        export_morph_normal=False,
        export_apply=False,
        export_materials="EXPORT",
        export_texcoords=False,
        export_yup=True,
        export_skins=True,
        export_animations=True,
        export_animation_mode="NLA_TRACKS",
        export_try_sparse_sk=True,
    )
    return path


def build_all(out_dir):
    return [build(sex, race, out_dir) for race in RACES for sex in SEXES]


def render_preview(path, hair="hair_01", skin=None, morph=None, width=500, height=1000):
    """Rendu de contrôle du dernier modèle construit (lumière chaude, 3/4 face)."""
    scene = bpy.context.scene
    if skin:
        bsdf = next(n for n in bpy.data.materials["skin"].node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = skin
    for obj in bpy.data.objects:
        if obj.type == "MESH" and obj.data.shape_keys:
            for block in obj.data.shape_keys.key_blocks[1:]:
                block.value = (morph or {}).get(block.name, 0.0)
        if obj.name.startswith("hair_"):
            obj.hide_render = obj.name != hair
    camera = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.location = (1.9, -3.9, 1.1)
    camera.rotation_euler = (math.radians(87), 0, math.radians(26))
    camera.data.lens = 50
    for name, loc, energy, color, size, rot in [
        ("Key", (2.5, -3, 3), 350, (1, 0.85, 0.7), 2, (55, 0, 40)),
        ("Fill", (-2.5, -2.5, 1.5), 120, (0.75, 0.8, 1), 3, (70, 0, -45)),
        ("Rim", (0.6, 2.5, 2.5), 300, (1, 0.8, 0.6), 2, (-60, 0, 0)),
    ]:
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.color = color
        light.size = size
        obj = bpy.data.objects.new(name, light)
        scene.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = [math.radians(a) for a in rot]
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.06, 0.045, 0.035, 1)
    scene.view_settings.exposure = -0.8
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path
