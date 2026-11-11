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

ou sans interface, avec le module « bpy » de PyPI (même version de Blender) :
    python3 tool/character/build_characters.py <dossier de sortie>

Aucun asset tiers : seuls le maillage de base MakeHuman (CC0) et des formes
créées ici sont utilisés.
"""

import importlib
import math
import os

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
import bmesh
from mathutils import Quaternion, Vector

def _mpfb_prefix():
    """Paquet de services MPFB (installé depuis le site ou depuis un fichier)."""
    import addon_utils

    for repo in ("blender_org", "user_default"):
        name = f"bl_ext.{repo}.mpfb"
        try:
            # Active l'extension si besoin (lancement sans interface).
            if addon_utils.enable(name, default_set=True) is None:
                continue
            importlib.import_module(name + ".services")
        except ImportError:
            continue
        return name + ".services."
    raise RuntimeError("Extension MPFB introuvable")


_MPFB = _mpfb_prefix()

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


def _material(name, color=None, metallic=0.0, roughness=None):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = color or COLORS[name]
    if roughness is None:
        roughness = 0.45 if name in ("skin", "hair", "tusk") else 0.9
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
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


# --- Visage : yeux, sourcils, barbes, maquillages ---------------------------


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



# --- Ressources MakeHuman (CC0) : cheveux, sourcils, cils, yeux --------------
#
# Les coiffures, sourcils, cils et yeux viennent des paquets officiels de la
# communauté MakeHuman, publiés sous licence CC0 (« makehuman_system_assets »
# et « hair01 », sur makehumancommunity.org). Le dossier qui contient leurs
# deux sous-dossiers décompressés (« sys » et « hair ») est donné par la
# variable d'environnement ARISE_MH_ASSETS. Chaque pièce est ajustée sur le
# corps (fichier .mhclo) pour chaque état de morphologie, ce qui donne ses
# formes ; les textures sont passées en niveaux de gris pour que l'application
# puisse les teinter (couleur des cheveux, des yeux).

HAIR_SOURCES = {
    "hair_01": "sys/hair/short02",
    "hair_02": "sys/hair/ponytail01",
    "hair_03": "sys/hair/braid01",
    "hair_04": "hair/hair/rehmanpolanski_hair_bun_brown",
    "hair_05": "sys/hair/long01",
    "hair_06": "hair/hair/culturalibre_hair_05",
    "hair_07": "sys/hair/short04",
    "hair_08": "hair/hair/elvs_double_mh_braid",
    "hair_09": "hair/hair/toigo_blunt_bob",
    "hair_10": "sys/hair/afro01",
}

EYEBROW_SOURCES = {
    "brow_01": "sys/eyebrows/eyebrow006",  # fins
    "brow_02": "sys/eyebrows/eyebrow001",  # épais
    "brow_03": "sys/eyebrows/eyebrow002",  # arqués
    "brow_04": "sys/eyebrows/eyebrow004",  # droits
    "brow_05": "sys/eyebrows/eyebrow012",  # courts
    "brow_06": "sys/eyebrows/eyebrow009",  # broussailleux
}

EYELASHES_SOURCE = "sys/eyelashes/eyelashes01"
EYES_SOURCE = "sys/eyes/high-poly"
EYES_TEXTURE = "sys/eyes/materials/brown_eye.png"
TEXTURE_SIZE = 512


def _mh_root():
    root = os.environ.get("ARISE_MH_ASSETS")
    if not root or not os.path.isdir(root):
        raise RuntimeError("ARISE_MH_ASSETS doit désigner le dossier des paquets MakeHuman décompressés")
    return root


def _mh_file(folder, ext):
    path = os.path.join(_mh_root(), folder)
    for name in sorted(os.listdir(path)):
        if name.endswith(ext):
            return os.path.join(path, name)
    raise FileNotFoundError(f"{ext} introuvable dans {path}")


def _read_obj(path):
    """Sommets, coordonnées de texture et faces (avec leurs UV) d'un .obj."""
    verts, uvs, faces = [], [], []
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            words = line.split()
            if not words:
                continue
            if words[0] == "v":
                verts.append(tuple(float(w) for w in words[1:4]))
            elif words[0] == "vt":
                uvs.append((float(words[1]), float(words[2])))
            elif words[0] == "f":
                face = []
                for w in words[1:]:
                    parts = w.split("/")
                    vi = int(parts[0]) - 1
                    ti = int(parts[1]) - 1 if len(parts) > 1 and parts[1] else None
                    face.append((vi, ti))
                faces.append(face)
    return verts, uvs, faces


def _diffuse_texture(folder):
    mhmat = _mh_file(folder, ".mhmat")
    with open(mhmat, encoding="utf-8", errors="ignore") as f:
        for line in f:
            words = line.split()
            if len(words) >= 2 and words[0] == "diffuseTexture":
                return os.path.join(os.path.dirname(mhmat), os.path.basename(words[1]))
    raise FileNotFoundError("Texture diffuse absente de " + mhmat)


def _tintable_image(source, name, gain=1.0, region=None, size=TEXTURE_SIZE):
    """Image en niveaux de gris (éclaircie) : l'application la teinte avec la
    couleur du matériau. [region] limite la conversion à un masque."""
    import numpy as np

    img = bpy.data.images.load(source, check_existing=False)
    if img.size[0] > size:
        img.scale(size, size)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    lum = px[..., 0] * 0.3 + px[..., 1] * 0.59 + px[..., 2] * 0.11
    opaque = px[..., 3] > 0.3
    ref = np.percentile(lum[opaque], 92) if opaque.any() else 1.0
    grey = np.clip(lum / max(ref, 1e-3) * gain, 0.0, 1.0)
    out = px.copy()
    mask = np.ones((h, w), bool) if region is None else region(w, h)
    for c in range(3):
        out[..., c] = np.where(mask, grey, px[..., c])
    img.pixels[:] = out.ravel()
    img.name = name
    img.pack()
    return img


def _textured_material(name, image, alpha=True, roughness=0.6):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if alpha:
        mat.node_tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        mat.surface_render_method = "DITHERED"
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.use_backface_culling = False
    return mat


def _proxy(folder, name, states, material, face_keys=True):
    """Pièce MakeHuman ajustée sur le corps, avec une forme par état."""
    mod = importlib.import_module(_MPFB[: -len("services.")] + "entities.clothes.mhclo")
    mhclo = mod.Mhclo()
    mhclo.load(_mh_file(folder, ".mhclo"))
    obj_verts, uvs, faces = _read_obj(_mh_file(folder, ".obj"))
    count = len(obj_verts)

    def fit(coords):
        xs, ys, zs = mhclo.x_scale, mhclo.y_scale, mhclo.z_scale
        if xs:
            x_size = abs(coords[xs[0]].x - coords[xs[1]].x) / xs[2]
            y_size = abs(coords[ys[0]].z - coords[ys[1]].z) / ys[2]
            z_size = abs(coords[zs[0]].y - coords[zs[1]].y) / zs[2]
        else:
            x_size = y_size = z_size = 0.1
        out = []
        for i in range(count):
            info = mhclo.verts[i]
            (a, b, c), (wa, wb, wc), off = info["verts"], info["weights"], info["offsets"]
            out.append(
                coords[a] * wa + coords[b] * wb + coords[c] * wc
                + Vector((off[0] * x_size, off[1] * z_size, off[2] * y_size))
            )
        return out

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(fit(states["base"]), [], [[v for v, _ in f] for f in faces])
    if uvs:
        layer = mesh.uv_layers.new(name="UVMap")
        k = 0
        for f in faces:
            for _, t in f:
                layer.data[k].uv = uvs[t] if t is not None else (0, 0)
                k += 1
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.shape_key_add(name="Basis")
    for state_name, *_ in STATES[1:]:
        if not face_keys and state_name.startswith("face_"):
            continue
        key = obj.shape_key_add(name=state_name)
        for i, co in enumerate(fit(states[state_name])):
            key.data[i].co = co
    for poly in mesh.polygons:
        poly.use_smooth = True
    mesh.materials.append(material)
    return obj


def _hair_styles(template, groups, states, hair_mat):
    """Dix coiffures MakeHuman (CC0), texture teintée par la couleur des
    cheveux (matériau `hair_<n>`)."""
    styles = []
    for name, folder in HAIR_SOURCES.items():
        image = _tintable_image(_diffuse_texture(folder), name + "_tex", gain=1.05)
        mat = _textured_material(name, image)
        styles.append(_proxy(folder, name, states, mat, face_keys=False))
    return styles


def _eyebrows(template, groups, states, marks, mat):
    """Six sourcils MakeHuman (CC0), teintés comme les cheveux."""
    objs = []
    for name, folder in EYEBROW_SOURCES.items():
        image = _tintable_image(_diffuse_texture(folder), name + "_tex", gain=0.9, size=256)
        objs.append(_proxy(folder, name, states, _textured_material("brow_" + name[-2:], image)))
    image = _tintable_image(_diffuse_texture(EYELASHES_SOURCE), "lashes_tex", gain=0.5, size=256)
    objs.append(_proxy(EYELASHES_SOURCE, "lashes", states, _textured_material("lashes", image)))
    return objs


def _eye_parts(template, groups, states, mats):
    """Yeux MakeHuman (CC0) : le blanc garde sa texture, l'iris (et la
    pupille) forment une pièce à part dont la couleur est réglable."""
    import numpy as np

    source = os.path.join(_mh_root(), EYES_TEXTURE)
    probe = bpy.data.images.load(source, check_existing=False)
    w, h = probe.size
    px = np.array(probe.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(probe)
    # Iris : zones nettement plus foncées et plus colorées que le blanc.
    sat = px[..., :3].max(axis=2) - px[..., :3].min(axis=2)
    val = px[..., :3].max(axis=2)
    iris_px = (sat > 0.12) & (val < 0.75)
    ys, xs = np.nonzero(iris_px)
    circles = []
    for side in (xs + ys < w, xs + ys >= w):
        cx, cy = xs[side].mean() / w, ys[side].mean() / h
        radius = (side.sum() / math.pi) ** 0.5 / w
        circles.append((cx, cy, radius * 1.12))

    def iris_region(rw, rh):
        yy, xx = np.mgrid[0:rh, 0:rw]
        mask = np.zeros((rh, rw), bool)
        for cx, cy, r in circles:
            mask |= ((xx / rw - cx) ** 2 + (yy / rh - cy) ** 2) < r * r
        return mask

    sclera = _textured_material("sclera", _tintable_image(source, "sclera_tex", region=lambda rw, rh: np.zeros((rh, rw), bool), size=256), alpha=False, roughness=0.2)
    iris = _textured_material("iris", _tintable_image(source, "iris_tex", gain=1.0, region=iris_region, size=256), alpha=False, roughness=0.2)
    eyes = _proxy(EYES_SOURCE, "eye_sclera", states, sclera)
    # Les faces dont les UV tombent dans un iris passent dans « eye_iris ».
    bm = bmesh.new()
    bm.from_mesh(eyes.data)
    uv = bm.loops.layers.uv.active
    inside = []
    cornea = []
    for f in bm.faces:
        # Les lignes de pixels de Blender partent du bas, comme les UV.
        u = sum(l[uv].uv.x for l in f.loops) / len(f.loops)
        v = sum(l[uv].uv.y for l in f.loops) / len(f.loops)
        if u > 0.85 and v < 0.15:
            # Cornée : coque transparente dans MakeHuman, inutile ici.
            cornea.append(f.index)
        elif any((u - cx) ** 2 + (v - cy) ** 2 < r * r for cx, cy, r in circles):
            inside.append(f.index)
    bm.free()
    iris_obj = eyes.copy()
    iris_obj.data = eyes.data.copy()
    iris_obj.name = "eye_iris"
    iris_obj.data.name = "eye_iris"
    bpy.context.collection.objects.link(iris_obj)
    iris_obj.data.materials[0] = iris
    keep_iris = set(inside)
    dropped = set(cornea)
    for obj, keep in ((eyes, lambda i: i not in keep_iris and i not in dropped), (iris_obj, lambda i: i in keep_iris)):
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if not keep(f.index)], context="FACES")
        bm.to_mesh(obj.data)
        bm.free()
    return [eyes, iris_obj]


MAKEUP_LOOKS = ("makeup_01", "makeup_02", "makeup_03", "makeup_04")


def _makeups(template, groups, states, marks):
    """Maquillages peints en dégradés doux (couleurs de sommets avec
    transparence) sur une fine pellicule du visage."""
    co = states["base"]
    eyes = marks["eyes"]
    r = marks["eye_radius"]
    lips = [co[i] for i in groups.get("lips", set())]
    lc = marks["lips_center"]

    def smooth(x, a, b):
        t = max(0.0, min(1.0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)

    def eye_frame(c, e):
        # Distance à l'œil (ellipse plus large que haute), côté extérieur.
        dx = (c.x - e.x) / (r * 0.95)
        dz = (c.z - e.z) / (r * 0.5)
        outward = (c.x - e.x) * (1 if e.x > 0 else -1)
        return (dx * dx + dz * dz) ** 0.5, outward

    def kohl(c):
        a = 0.0
        for e in eyes:
            d, outward = eye_frame(c, e)
            ring = 1.0 - smooth(abs(d - 1.0), 0.0, 0.18)
            wing = 0.0
            if outward > 0:
                t = (outward - r * 0.8) / (r * 0.7)
                wing = (1 - smooth(t, 0.5, 1.0)) * smooth(t, -0.2, 0.0) * (1 - smooth(abs(c.z - (e.z + outward * 0.3)), 0.0, r * 0.12))
            shadow = (1 - smooth(d, 1.0, 1.6)) * smooth(c.z - e.z, 0.0, r * 0.3) * 0.35
            a = max(a, ring * 0.95, wing * 0.9, shadow)
        return (0.015, 0.008, 0.01, a)

    def lipstick(c):
        if not lips:
            return (0, 0, 0, 0)
        d = min((c - p).length for p in lips)
        a = 1.0 - smooth(d, 0.0008, 0.0035)
        return (0.22, 0.012, 0.03, a * 0.8)

    def blush(c):
        a = 0.0
        for e in eyes:
            center = Vector((e.x * 1.25, e.y, e.z - r * 2.6))
            d = ((c.x - center.x) ** 2 + (c.z - center.z) ** 2) ** 0.5
            a = max(a, (1 - smooth(d, 0.0, r * 2.4)) * 0.5)
        return (0.55, 0.12, 0.12, a)

    def war(c):
        # Bandeau à travers les yeux et trois traits sur chaque joue.
        e = eyes[0]
        band = (1 - smooth(abs(c.z - e.z), r * 0.9, r * 1.2)) * (1 - smooth(abs(c.x), abs(e.x) + r * 1.6, abs(e.x) + r * 2.4))
        stripes = 0.0
        for k in (-1, 0, 1):
            x0 = abs(e.x) + k * r * 0.7
            z0 = e.z - r * 1.6
            stripes = max(stripes, (1 - smooth(abs(abs(c.x) - x0), r * 0.12, r * 0.25)) * (1 - smooth(abs(c.z - z0), r * 0.5, r * 0.8)))
        inside_eye = any(eye_frame(c, ee)[0] < 1.0 for ee in eyes)
        a = 0.0 if inside_eye else max(band * 0.85, stripes * 0.9)
        return (0.28, 0.07, 0.015, a)

    looks = dict(zip(MAKEUP_LOOKS, (kohl, lipstick, blush, war)))
    face = _faces_where(template, co, groups["body"], lambda c: _front(c, marks) and c.z > marks["chin"].z - 0.01)
    objs = []
    for name, paint in looks.items():
        obj = _extract(template, face, name, states, offset=0.00045)
        mesh = obj.data
        colors = mesh.color_attributes.new("Color", "BYTE_COLOR", "POINT")
        for i, v in enumerate(mesh.vertices):
            colors.data[i].color = paint(v.co)
        mesh.color_attributes.active_color = colors
        # Seules les faces peintes sont gardées (fichier plus léger).
        bm = bmesh.new()
        bm.from_mesh(mesh)
        layer = bm.verts.layers.color.get("Color")
        drop = [f for f in bm.faces if max(v[layer][3] for v in f.verts) < 0.02]
        bmesh.ops.delete(bm, geom=drop, context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(mesh)
        bm.free()
        mat = _material(name, (1.0, 1.0, 1.0, 1.0))
        mat.surface_render_method = "BLENDED"
        mesh.materials.append(mat)
        objs.append(obj)
    return objs


# Musculature sans grossir ni maigrir : dans MakeHuman, retirer du muscle à
# poids égal ajoute de la graisse. L'état « peu musclé » baisse donc aussi le
# poids, jusqu'à garder le même tour de taille que le corps de base (mesuré
# sur les maillages), et l'état « très musclé » accentue le relief.
MUSC_LOW_WEIGHT = {"female": 0.4, "male": 0.3}
MUSC_HIGH_GAIN = 1.5


def _muscle_states(states):
    base = states["base"]
    states["musc_high"] = [b + (m - b) * MUSC_HIGH_GAIN for b, m in zip(base, states["musc_high"])]


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
    for name, ops in POSES.items():
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
            group = obj.vertex_groups.new(name=rigid[obj.name])
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



# --- Équipement de la boutique (phase 7) ---------------------------------------
#
# Chaque objet est une pièce `item_<id>` tirée du corps (mêmes formes de
# morphologie, mêmes poids de peau) ou, pour les armes, une pièce rigide liée à
# la main droite et déplacée avec elle d'un état à l'autre. Les matériaux
# `dye_<id>` peuvent être teints par l'application.

ITEM_MATERIALS = {
    # nom : (couleur linéaire, métal, rugosité)
    "leather_brown": ((0.10, 0.045, 0.02, 1.0), 0.0, 0.75),
    "leather_dark": ((0.03, 0.017, 0.01, 1.0), 0.0, 0.7),
    "mail": ((0.30, 0.31, 0.33, 1.0), 0.9, 0.45),
    "steel": ((0.55, 0.56, 0.58, 1.0), 1.0, 0.3),
    "gold": ((0.80, 0.55, 0.18, 1.0), 1.0, 0.3),
    "cloth_teal": ((0.03, 0.12, 0.13, 1.0), 0.0, 0.9),
    "cloth_red": ((0.30, 0.03, 0.03, 1.0), 0.0, 0.9),
    "cloth_violet": ((0.10, 0.05, 0.16, 1.0), 0.0, 0.9),
    "wood": ((0.12, 0.06, 0.025, 1.0), 0.0, 0.8),
    "ember": ((1.0, 0.28, 0.04, 1.0), 0.0, 0.4),
}

# Objets teignables : matériau de base de leur teinture.
DYEABLE = {
    "leather_chest": "leather_brown",
    "leather_legs": "leather_brown",
    "cape_wanderer": "cloth_teal",
    "cape_dawn": "cloth_red",
    "hood_twilight": "cloth_violet",
}


def _item_material(item_id, look):
    if item_id in DYEABLE:
        color, metal, rough = ITEM_MATERIALS[DYEABLE[item_id]]
        return _material("dye_" + item_id, color, metal, rough)
    color, metal, rough = ITEM_MATERIALS[look]
    return _material("item_" + look, color, metal, rough)


def _joints(coords, groups):
    """Centres des articulations MPFB (cubes « joint-* »)."""

    def center(name):
        pts = [coords[i] for i in groups.get(name, ())]
        if not pts:
            return None
        return sum(pts, Vector()) / len(pts)

    j = {}
    for side in ("l", "r"):
        for key, name in (
            ("shoulder", "shoulder"), ("elbow", "elbow"), ("wrist", "hand"),
            ("hip", "upper-leg"), ("knee", "knee"), ("ankle", "ankle"),
        ):
            j[f"{key}_{side}"] = center(f"joint-{side}-{name}")
    j["neck"] = center("joint-neck")
    j["head"] = center("joint-head")
    j["pelvis"] = center("joint-pelvis")
    return j


def _segment(c, a, b):
    """Position (0 à 1) et distance de [c] le long du segment a-b."""
    ab = b - a
    t = (c - a).dot(ab) / max(ab.length_squared, 1e-9)
    closest = a + ab * max(0.0, min(1.0, t))
    return t, (c - closest).length


def _part(c, j, height):
    """Partie du corps sous un point : hand, forearm, upperarm, foot, shin,
    thigh, head, neck ou torso."""
    side = "l" if c.x > 0 else "r"
    s, e, w = j[f"shoulder_{side}"], j[f"elbow_{side}"], j[f"wrist_{side}"]
    knee_z = j[f"knee_{side}"].z
    if abs(c.x) > abs(s.x) * 0.9 and knee_z + 0.1 * height < c.z < s.z + 0.04 * height:
        t, d = _segment(c, e, w)
        if (c - w).dot(w - e) > 0 and (c - w).length < 0.14 * height:
            return "hand"
        if 0 <= t <= 1 and d < 0.08 * height:
            return "forearm"
        t, d = _segment(c, s, e)
        if t >= 0.12 and d < 0.09 * height:
            return "upperarm"
    hip, knee, ankle = j[f"hip_{side}"], j[f"knee_{side}"], j[f"ankle_{side}"]
    if c.z < ankle.z + 0.035 * height:
        return "foot"
    if c.z < knee.z:
        return "shin"
    if c.z < hip.z - 0.02 * height and abs(c.x) > 0.012 * height:
        return "thigh"
    if c.z > j["head"].z - 0.03 * height:
        return "head"
    if c.z > j["neck"].z - 0.01 * height:
        return "neck"
    return "torso"


def _item_from_body(template, groups, states, j, height, item_id, look, test, offset, flare=None):
    base = states["base"]
    keep = _faces_where(template, base, groups["body"], lambda c: test(c, _part(c, j, height)))
    if not keep:
        return None
    obj = _extract(template, keep, "item_" + item_id, states, offset=offset, flare=flare)
    obj.data.materials.append(_item_material(item_id, look))
    return obj


def _drop_face_keys(obj):
    """Les formes du visage ne bougent pas les pièces du corps : on les retire
    pour alléger le fichier."""
    keys = obj.data.shape_keys
    if keys is None:
        return
    for block in list(keys.key_blocks):
        if block.name.startswith("face_"):
            obj.shape_key_remove(block)


def _rigid_item(item_id, parts, anchor_of, states, look_of):
    """Pièce rigide (arme) : jointe, matériaux par pièce, déplacée avec la main
    dans chaque état (formes de morphologie)."""
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = "item_" + item_id
    obj.data.name = obj.name
    for poly in obj.data.polygons:
        poly.use_smooth = False
    base = anchor_of(states["base"])
    obj.shape_key_add(name="Basis")
    for state_name, *_ in STATES[1:]:
        key = obj.shape_key_add(name=state_name)
        delta = anchor_of(states[state_name]) - base
        for i, v in enumerate(obj.data.vertices):
            key.data[i].co = v.co + delta
    _drop_face_keys(obj)
    return obj


def _cylinder(name, start, end, radius, vertices=12, mat=None):
    direction = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=direction.length, location=(start + end) / 2)
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    bpy.ops.object.transform_apply(rotation=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def _box(name, center, size, mat=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def _cape(item_id, look, groups, states, j, height, length, flare):
    """Cape : nappe tendue entre les épaules et le bas du dos, posée derrière
    le corps et recalculée pour chaque état."""
    rows, cols = 14, 12
    body = list(groups["body"])

    def grid(coords, joints):
        top = (joints["shoulder_l"].z + joints["neck"].z) / 2
        half = abs(joints["shoulder_l"].x - joints["shoulder_r"].x) / 2 * 1.05
        bottom = top - length * height
        verts = []
        for r in range(rows):
            z = top - (top - bottom) * r / (rows - 1)
            band = [coords[i] for i in body if abs(coords[i].z - z) < 0.02 * height and abs(coords[i].x) < half * 0.9]
            back = max((p.y for p in band), default=0.05)
            spread = half * (1 + flare * r / (rows - 1))
            for k in range(cols):
                x = -spread + 2 * spread * k / (cols - 1)
                curve = (1 - (x / spread) ** 2) * 0.03 * height
                verts.append(Vector((x, back + 0.025 * height + curve * 0.4 + 0.02 * height * r / (rows - 1), z)))
        return verts

    faces = []
    for r in range(rows - 1):
        for k in range(cols - 1):
            a = r * cols + k
            faces.append((a, a + 1, a + cols + 1, a + cols))
    name = "item_" + item_id
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(grid(states["base"], j), [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.shape_key_add(name="Basis")
    for state_name, *_ in STATES[1:]:
        key = obj.shape_key_add(name=state_name)
        joints = _joints(states[state_name], groups)
        for i, co in enumerate(grid(states[state_name], joints)):
            key.data[i].co = co
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj.data.materials.append(_item_material(item_id, look))
    _drop_face_keys(obj)
    return obj


def _equipment(template, groups, states, marks):
    """Les trois ensembles, les capes, la capuche et les armes d'apparat.
    Renvoie les pièces rigides et l'os qui les porte."""
    base = states["base"]
    height = max(base[i].z for i in groups["body"])
    j = _joints(base, groups)
    H = height
    neck_z = j["neck"].z

    def torso(top, bottom, arms=()):
        return lambda c, p: (p == "torso" and bottom * H < c.z) or (p == "neck" and c.z < top * H) or p in arms

    def face_open(c):
        # Ouverture du visage pour les coiffes : devant, sous le front.
        return _front(c, marks) and c.z < marks["eyes"][0].z + 0.035 and abs(c.x) < 0.055

    items = [
        # Cuir de l'Éveillé.
        ("leather_chest", "leather_brown", torso(0, 0.555, ("upperarm",)), 0.02, None),
        ("leather_hands", "leather_dark", lambda c, p: p == "hand" or (p == "forearm" and _segment(c, j["elbow_l" if c.x > 0 else "elbow_r"], j["wrist_l" if c.x > 0 else "wrist_r"])[0] > 0.6), 0.006, None),
        ("leather_legs", "leather_brown", lambda c, p: p in ("thigh", "shin") or (p == "torso" and c.z < 0.57 * H), 0.013, None),
        ("leather_feet", "leather_dark", lambda c, p: p == "foot" or (p == "shin" and c.z < j["ankle_l"].z + 0.09 * H), 0.016, None),
        # Maille du Veilleur.
        ("mail_head", "mail", lambda c, p: (p == "head" and not face_open(c)) or (p == "neck"), 0.012, None),
        ("mail_chest", "mail", torso(0, 0.47, ("upperarm",)), 0.024, (0.53 * H, 0.9)),
        ("mail_hands", "mail", lambda c, p: p == "hand", 0.009, None),
        ("mail_legs", "mail", lambda c, p: p in ("thigh", "shin"), 0.017, None),
        ("mail_feet", "steel", lambda c, p: p == "foot", 0.02, None),
        # Plates de l'Aube.
        ("plate_head", "steel", lambda c, p: p == "head" and not face_open(c), 0.026, None),
        ("plate_shoulders", "gold", lambda c, p: p in ("upperarm", "torso") and abs(c.x) > abs(j["shoulder_l"].x) * 0.55 and c.z > j["shoulder_l"].z - 0.045 * H and c.z < neck_z, 0.045, None),
        ("plate_chest", "steel", torso(0, 0.585), 0.04, None),
        ("plate_hands", "steel", lambda c, p: p == "hand" or p == "forearm", 0.016, None),
        ("plate_belt", "gold", lambda c, p: p in ("torso", "thigh") and 0.47 * H < c.z < 0.585 * H, 0.05, (0.56 * H, 1.6)),
        ("plate_legs", "steel", lambda c, p: p in ("thigh", "shin") and c.z > j["ankle_l"].z + 0.07 * H, 0.03, None),
        ("plate_feet", "steel", lambda c, p: p == "foot" or (p == "shin" and c.z < j["ankle_l"].z + 0.1 * H), 0.028, None),
        # Capuche du Crépuscule : tête, nuque et haut des épaules.
        ("hood_twilight", "cloth_violet", lambda c, p: (p == "head" and not face_open(c)) or p == "neck" or (p == "torso" and c.z > j["shoulder_l"].z and abs(c.x) < abs(j["shoulder_l"].x)), 0.032, None),
    ]
    for item_id, look, test, offset, flare in items:
        obj = _item_from_body(template, groups, states, j, H, item_id, look, test, offset, flare)
        if obj is not None and not item_id.endswith("_head") and not item_id.startswith("hood"):
            _drop_face_keys(obj)
        if obj is not None and item_id.endswith(("_hands", "_feet")):
            # Mains et pieds changent à peine avec la morphologie : sans formes,
            # ces pièces très détaillées pèsent deux fois moins.
            obj.shape_key_clear()

    belt_band = [i for i in groups["body"] if 0.578 < base[i].z / H < 0.597 and _part(base[i], j, H) == "torso"]
    belt = _ring("item_leather_belt", belt_band, states, 0.045, 0.012, sides=4)
    belt.data.materials.append(_item_material("leather_belt", "leather_dark"))
    _drop_face_keys(belt)

    _cape("cape_wanderer", "cloth_teal", groups, states, j, H, 0.5, 0.5)
    _cape("cape_dawn", "cloth_red", groups, states, j, H, 0.68, 0.8)

    # Armes tenues dans la main droite, pointe vers le bas.
    def hand_r(coords):
        joints = _joints(coords, groups)
        w, e = joints["wrist_r"], joints["elbow_r"]
        return w + (w - e).normalized() * 0.045 * H

    grip = hand_r(base)
    steel = _item_material("sword_dawn", "steel")
    gold = _item_material("sword_dawn", "gold")
    leather = _item_material("sword_dawn", "leather_dark")
    blade_end = grip + Vector((0, 0, -0.42 * H))
    sword = [
        _cylinder("grip", grip + Vector((0, 0, 0.05 * H)), grip - Vector((0, 0, 0.02 * H)), 0.012, mat=leather),
        _box("guard", grip - Vector((0, 0, 0.03 * H)), (0.11 * H, 0.02, 0.015), mat=gold),
        _box("blade", (grip + blade_end) / 2 - Vector((0, 0, 0.02 * H)), (0.035, 0.008, 0.40 * H), mat=steel),
        _blob("pommel", grip + Vector((0, 0, 0.06 * H)), (0.018, 0.018, 0.018)),
    ]
    sword[-1].data.materials.append(gold)
    _rigid_item("sword_dawn", sword, hand_r, states, None)

    wood = _item_material("staff_ember", "wood")
    ember = _item_material("staff_ember", "ember")
    staff = [
        _cylinder("shaft", grip + Vector((0, 0, -0.5 * H)), grip + Vector((0, 0, 0.5 * H)), 0.016, mat=wood),
        _blob("orb", grip + Vector((0, 0, 0.53 * H)), (0.04, 0.04, 0.05)),
        _cylinder("band", grip + Vector((0, 0, 0.44 * H)), grip + Vector((0, 0, 0.47 * H)), 0.022, mat=gold),
    ]
    staff[1].data.materials.append(ember)
    _rigid_item("staff_ember", staff, hand_r, states, None)
    return {"item_sword_dawn": "hand_r", "item_staff_ember": "hand_r"}


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
        if state_name == "musc_low":
            weight = MUSC_LOW_WEIGHT[sex]
        coords, membership, mesh = _state_coords(sex, race, weight, muscle, targets)
        groups = groups or membership
        template = template or mesh
        states[state_name] = _race_deform(race, coords, groups)
    _muscle_states(states)
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
    held = _equipment(template, groups, states, marks)
    bpy.data.meshes.remove(template)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    rigid = {o.name: "head" for o in meshes if o.name.startswith(("hair_", "tusks", "eye_", "brow_", "lashes"))}
    rigid.update(held)
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
        export_texcoords=True,
        export_vertex_color="ACTIVE",
        export_image_format="AUTO",
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


if __name__ == "__main__":
    import sys

    build_all(sys.argv[1])
