"""Génère les modèles 3D de substitution d'ARISE (Blender + extension MPFB).

Six corps originaux (3 races × 2 sexes), chacun exporté en .glb avec :
- le corps (matériau « skin »), les yeux et, pour les orques, les défenses ;
- quatre formes de morphologie : corp_low / corp_high (corpulence) et
  musc_low / musc_high (musculature), appliquées au corps, à la tenue et à la
  calotte des coiffures, pour que tout suive les proportions ;
- la tenue de départ (outfit_tunic, outfit_pants, outfit_boots), vraies pièces
  de vêtement MakeHuman ajustées sur chaque morphologie, et les
  sous-vêtements outfit_under_top / outfit_under_pants tirés de la peau ;
- une peau texturée neutre, teintée par l'application ;
- dix coiffures et six barbes MakeHuman (CC0 et CC BY, voir docs/ASSETS.md).

Lancement dans Blender (avec MPFB installé) :
    exec(open(".../tool/character/build_characters.py").read())
    build_all(r"C:/chemin/de/sortie")

ou sans interface, avec le module « bpy » de PyPI (même version de Blender) :
    python3 tool/character/build_characters.py <dossier de sortie>

Ressources tierces : uniquement des paquets MakeHuman sous licence CC0 ou
CC BY (auteurs cités dans l'écran Crédits et dans docs/ASSETS.md).
"""

import importlib
import importlib.util
import math
import os

import bpy  # avant bmesh : le module bpy de PyPI rend bmesh importable
import bmesh
from mathutils import Matrix, Quaternion, Vector

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
    "under_linen": (0.20, 0.16, 0.11, 1.0),
    "under_wool": (0.05, 0.035, 0.025, 1.0),
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
        # Oreilles longues et pointues, vers le haut et l'arrière, de façon
        # progressive (nettement plus marquées le 13/11/2026).
        reach = (0.02, 0.04, 0.085)
        zs = [coords[i].z for i in ears]
        z0, z1 = min(zs), max(zs)
        for i in ears:
            t = (coords[i].z - z0) / max(z1 - z0, 1e-6)
            t = t * t
            side = 1 if coords[i].x > 0 else -1
            out[i] += Vector((side * reach[0] * t, reach[1] * t, reach[2] * t))
    if race == "elf":
        # Visage plus fin : mâchoire resserrée, pommettes hautes.
        lips = groups.get("lips", set())
        mouth_z = sum(coords[i].z for i in lips) / max(len(lips), 1)
        head = groups.get("body", set())
        top = max(coords[i].z for i in head)
        for i in head:
            c = coords[i]
            if top - 0.30 < c.z < mouth_z + 0.01 and c.y < 0.03:
                k = min(1.0, (mouth_z + 0.01 - c.z) / 0.06)
                out[i].x *= 1 - 0.08 * k
            if mouth_z + 0.03 < c.z < mouth_z + 0.06 and c.y < -0.04 and abs(c.x) > 0.03:
                out[i].z += 0.003
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
                out[i].x *= 1 + 0.28 * k
                out[i].y -= 0.006 * k
            # Arcade sourcilière lourde.
            if mouth_z + 0.065 < c.z < mouth_z + 0.105 and c.y < -0.05:
                out[i].y -= 0.014
                out[i].z -= 0.004
            # Nez épaté et large.
            if mouth_z + 0.015 < c.z < mouth_z + 0.055 and c.y < -0.07 and abs(c.x) < 0.025:
                out[i].x *= 1.35
                out[i].y += 0.005
            # Carrure plus large du buste et des épaules, avec une transition
            # douce (sans cassure aux poignets ni à la taille).
            t = (c.z / top - 0.60) / 0.12
            t = max(0.0, min(1.0, t))
            u = (top - 0.18 - c.z) / 0.06
            u = max(0.0, min(1.0, u))
            out[i].x *= 1 + 0.12 * (t * t * (3 - 2 * t)) * u
    return out


def _extract(template, keep, name, states, offset=0.0, flare=None, refine=None, smooth=0):
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
        if smooth:
            # Lissage (Laplacien) : la pièce perd le relief du corps (seins,
            # abdominaux) et prend la forme d'une plaque forgée.
            neighbours = [set() for _ in result]
            for e in tmp.edges:
                a, b = e.vertices
                neighbours[a].add(b)
                neighbours[b].add(a)
            # Le bord de la pièce reste en place (pas de bord effrangé).
            uses = {}
            for poly in tmp.polygons:
                for key in poly.edge_keys:
                    uses[key] = uses.get(key, 0) + 1
            for (a, b), n in uses.items():
                if n == 1:
                    neighbours[a] = set()
                    neighbours[b] = set()
            for _ in range(smooth):
                result = [
                    co * 0.5 + sum((result[n] for n in near), Vector()) / len(near) * 0.5
                    if near
                    else co
                    for co, near in zip(result, neighbours)
                ]
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
    """Six barbes en mèches (MakeHuman, CC0 et CC-BY), texture teintée par
    la couleur de la barbe (matériau « beard »)."""
    objs = []
    for name, folder in BEARD_SOURCES.items():
        image = _tintable_image(_diffuse_texture(folder), name + "_tex", gain=1.0)
        normal = _normal_texture(folder)
        material = _textured_material(
            name,
            image,
            normal=_image(normal, name + "_nrm") if normal else None,
            roughness=0.55,
        )
        objs.append(_proxy(folder, name, states, material))
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
    "hair_01": "hair/elvs_grump_hair",  # courte (CC-BY, Elvaerwyn)
    "hair_02": "hair/ponytail01",  # queue de cheval
    "hair_03": "hair/elvs_unkempt_french_braid",  # natte
    "hair_04": "hair/elvs_braid_bun",  # chignon (CC-BY, Elvaerwyn)
    "hair_05": "hair/punkduck_alpha7_long",  # longue (CC-BY, punkduck)
    "hair_06": "hair/culturalibre_hair_02",  # mèches rebelles
    "hair_07": "hair/short02",  # très courte
    "hair_08": "hair/elvs_double_mh_braid",  # double natte
    "hair_09": "hair/elvs_wavy_bob",  # carré (CC-BY, Elvaerwyn)
    "hair_10": "hair/punkduck_alpha7_curly",  # bouclée (CC-BY, punkduck)
}

# Barbes en mèches (paquets « bodyparts05 », CC0, et « bodyparts06 », CC-BY).
BEARD_SOURCES = {
    "beard_01": "clothes/grinsegold_full_beard",  # collier (CC-BY)
    "beard_02": "clothes/culturalibre_faun_beard",  # bouc
    "beard_03": "clothes/rehmanpolanski_moustache_viking",  # moustache
    "beard_04": "clothes/elvs_scruffy_beard1",  # courte (CC-BY, Elvaerwyn)
    "beard_05": "clothes/rehmanpolanski_beard_viking",  # longue
    "beard_06": "clothes/culturalibre_dal_moustache",  # moustache en guidon (CC-BY)
}

# Tenue de départ : vraies pièces de vêtement ajustées sur le corps.
OUTFIT_TINTS = {"outfit_tunic": (0.92, 0.84, 0.70)}

OUTFIT_SOURCES = {
    "outfit_tunic": ("clothes/punkduck_lace_up_blouse", "linen"),  # CC-BY
    "outfit_pants": ("clothes/rehmanpolanski_viking_pants", "wool"),
    "outfit_boots": ("clothes/rehmanpolanski_viking_boots", "leather"),
}

# Peaux réalistes (paquets « skins », CC0) : texture ramenée à une teinte
# neutre (l'application applique la couleur de peau) et relief (normal map).
SKIN_SOURCES = {
    "male": "skins/young_caucasian_male",
    "female": "skins/young_caucasian_female",
}

EYEBROW_SOURCES = {
    "brow_01": "eyebrows/eyebrow006",  # fins
    "brow_02": "eyebrows/eyebrow001",  # épais
    "brow_03": "eyebrows/eyebrow002",  # arqués
    "brow_04": "eyebrows/eyebrow004",  # droits
    "brow_05": "eyebrows/eyebrow012",  # courts
    "brow_06": "eyebrows/eyebrow009",  # broussailleux
}

EYELASHES_SOURCE = "eyelashes/eyelashes01"
EYES_SOURCE = "eyes/high-poly"
EYES_TEXTURE = "eyes/materials/brown_eye.png"
TEXTURE_SIZE = 512
SKIN_TEXTURE_SIZE = 1024


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
    # Contraste adouci : les zones très sombres d'une texture ne donnent
    # plus de mèches presque noires quand la couleur choisie est claire.
    grey = 0.22 + 0.78 * grey
    out = px.copy()
    mask = np.ones((h, w), bool) if region is None else region(w, h)
    for c in range(3):
        out[..., c] = np.where(mask, grey, px[..., c])
    img.pixels[:] = out.ravel()
    img.name = name
    img.pack()
    return img


def _textured_material(name, image, alpha=True, roughness=0.6, normal=None):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = next(n for n in nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if alpha:
        links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        mat.surface_render_method = "DITHERED"
    if normal is not None:
        # Relief : carte de normales (espace tangent), exportée en glTF.
        ntex = nodes.new("ShaderNodeTexImage")
        ntex.image = normal
        ntex.image.colorspace_settings.name = "Non-Color"
        nmap = nodes.new("ShaderNodeNormalMap")
        links.new(ntex.outputs["Color"], nmap.inputs["Color"])
        links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.use_backface_culling = False
    return mat


def _image(path, name, size=TEXTURE_SIZE):
    """Image d'un paquet, réduite à [size] et intégrée au fichier."""
    img = bpy.data.images.load(path, check_existing=False)
    if img.size[0] > size:
        img.scale(size, size)
    img.name = name
    img.pack()
    return img


def _normal_texture(folder):
    """Carte de normales d'une pièce MakeHuman, ou `None`."""
    mhmat = _mh_file(folder, ".mhmat")
    with open(mhmat, encoding="utf-8", errors="ignore") as f:
        for line in f:
            words = line.split()
            if len(words) >= 2 and words[0] == "normalmapTexture":
                path = os.path.join(os.path.dirname(mhmat), os.path.basename(words[1]))
                if os.path.exists(path):
                    return path
    return None


def _neutral_skin_image(source, name, size=SKIN_TEXTURE_SIZE):
    """Peau ramenée à une teinte neutre : chaque pixel est divisé par la
    couleur moyenne de la peau. Les variations (pores, lèvres, joues,
    ombres) sont gardées, la couleur de peau choisie dans l'application est
    appliquée par-dessus (couleur du matériau)."""
    import numpy as np

    img = bpy.data.images.load(source, check_existing=False)
    if img.size[0] > size:
        img.scale(size, size)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = px[..., :3]
    lum = rgb.mean(axis=2)
    skin = (lum > np.percentile(lum, 20)) & (lum < np.percentile(lum, 95))
    mean = rgb[skin].mean(axis=0)
    out = rgb / np.maximum(mean, 1e-3)
    out = out / max(np.percentile(out[skin].max(axis=1), 99), 1e-3)
    px[..., :3] = np.clip(out, 0.0, 1.0)
    px[..., 3] = 1.0
    img.pixels[:] = px.ravel()
    img.name = name
    img.pack()
    return img


def _proxy(folder, name, states, material, face_keys=True, inflate=0.0):
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
        if inflate:
            # Pièce un peu plus ample (gants, bottes) : le corps ne la traverse
            # plus (orteils, doigts).
            tmp = bpy.data.meshes.new("tmp")
            tmp.from_pydata(out, [], [[v for v, _ in f] for f in faces])
            tmp.update()
            out = [v.co + v.normal * inflate for v in tmp.vertices]
            bpy.data.meshes.remove(tmp)
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


MAKEUP_LOOKS = tuple(f"makeup_{i:02d}" for i in range(1, 10))
MAKEUP_TEXTURE = 512


def _makeups(template, groups, states, marks):
    """Maquillages peints dans une texture (512 px, dégradés fins) posée
    sur une fine pellicule du visage, en projection de face : khôl fumé,
    trait de chat, fard doré, rouge à lèvres, lèvres prune, teint rosé,
    taches de rousseur, peinture de guerre, tatouage tribal."""
    import numpy as np

    co = states["base"]
    eyes = marks["eyes"]
    r = marks["eye_radius"]
    lc = marks["lips_center"]
    lips = [co[i] for i in groups.get("lips", set())]
    lip_w = max(abs(p.x - lc.x) for p in lips) if lips else 0.025
    lip_h = (marks["lips_top"] - marks["lips_bottom"]) / 2 or 0.008
    face = _faces_where(template, co, groups["body"], lambda c: _front(c, marks) and c.z > marks["chin"].z - 0.01)
    xs = [co[i].x for i in groups["body"] if _front(co[i], marks) and co[i].z > marks["chin"].z - 0.01]
    zs = [co[i].z for i in groups["body"] if _front(co[i], marks) and co[i].z > marks["chin"].z - 0.01]
    x0, x1, z0, z1 = min(xs), max(xs), min(zs), max(zs)
    n = MAKEUP_TEXTURE
    gx, gz = np.meshgrid(np.linspace(x0, x1, n), np.linspace(z0, z1, n))

    def sm(x, a, b):
        t = np.clip((x - a) / (b - a), 0, 1)
        return t * t * (3 - 2 * t)

    def eye(e, sx=1.0, sz=0.55):
        return np.sqrt(((gx - e.x) / (r * sx)) ** 2 + ((gz - e.z) / (r * sz)) ** 2)

    inside = np.zeros_like(gx, dtype=bool)
    for e in eyes:
        inside |= eye(e, 0.95, 0.5) < 1.0
    lipd = np.sqrt(((gx - lc.x) / lip_w) ** 2 + ((gz - lc.z) / lip_h) ** 2)
    lips_a = 1 - sm(lipd, 0.85, 1.08)

    def wing(e, length=0.8, thick=0.12):
        side = 1 if e.x > 0 else -1
        out = (gx - e.x) * side - r * 0.75
        line = e.z + r * 0.15 + out * 0.45
        return (1 - sm(np.abs(gz - line), r * thick * 0.5, r * thick)) * sm(out, -r * 0.1, 0) * (1 - sm(out, r * length * 0.7, r * length))

    def smoky():
        a = np.zeros_like(gx)
        for e in eyes:
            d = eye(e, 1.15, 0.75)
            lid = (1 - sm(d, 1.0, 1.7)) * np.where(gz > e.z - r * 0.25, 1.0, 0.55)
            a = np.maximum(a, lid * 0.85)
            a = np.maximum(a, wing(e, 0.9, 0.2) * 0.9)
        return (0.05, 0.035, 0.045), a

    def cat():
        a = np.zeros_like(gx)
        for e in eyes:
            d = eye(e, 0.98, 0.52)
            rim = (1 - sm(np.abs(d - 1.0), 0.04, 0.12)) * np.where(gz > e.z - r * 0.05, 1.0, 0.35)
            a = np.maximum(a, np.maximum(rim, wing(e, 1.1, 0.13)) * 0.95)
        return (0.02, 0.015, 0.02), a

    def gold():
        a = np.zeros_like(gx)
        for e in eyes:
            d = eye(e, 1.1, 0.7)
            lid = (1 - sm(d, 0.95, 1.45)) * sm(gz - e.z, -r * 0.05, r * 0.2)
            a = np.maximum(a, lid * 0.8)
        return (0.85, 0.6, 0.2), a

    def red_lips():
        return (0.62, 0.04, 0.08), lips_a * 0.9

    def berry():
        return (0.36, 0.05, 0.18), lips_a * 0.9

    def rosy():
        a = lips_a * 0.45
        for e in eyes:
            c = Vector((e.x * 1.2, 0, e.z - r * 2.7))
            d = np.sqrt((gx - c.x) ** 2 + (gz - c.z) ** 2)
            a = np.maximum(a, (1 - sm(d, 0, r * 2.3)) * 0.45)
        return (0.75, 0.25, 0.28), a

    def freckles():
        rng = np.random.default_rng(7)
        a = np.zeros_like(gx)
        zone = (np.abs(gx) < r * 4.2) & (gz < eyes[0].z - r * 0.9) & (gz > lc.z + lip_h * 3)
        for _ in range(140):
            px = rng.uniform(-r * 4.2, r * 4.2)
            pz = rng.uniform(lc.z + lip_h * 3.2, eyes[0].z - r * 1.0)
            rad = rng.uniform(0.0007, 0.0014)
            d = np.sqrt((gx - px) ** 2 + (gz - pz) ** 2)
            a = np.maximum(a, (1 - sm(d, rad * 0.4, rad)) * rng.uniform(0.35, 0.7))
        return (0.36, 0.18, 0.09), a * zone

    def war():
        e = eyes[0]
        ex = abs(e.x)
        band = (1 - sm(np.abs(gz - (e.z + r * 0.1)), r * 0.85, r * 1.0)) * (1 - sm(np.abs(gx), ex + r * 1.7, ex + r * 1.9))
        stripe = (1 - sm(np.abs(np.abs(gx) - ex), r * 0.28, r * 0.4)) * (1 - sm(e.z - gz, r * 2.6, r * 2.9)) * sm(e.z - gz, 0, r * 0.2)
        return (0.42, 0.04, 0.03), np.maximum(band, stripe) * 0.92

    def tribal():
        e = eyes[0]
        a = np.zeros_like(gx)
        for k in range(3):
            # Trois arcs sur chaque joue, et un chevron sur le front.
            zc = e.z - r * (1.6 + 0.55 * k)
            arc = np.abs(np.abs(gx) - (abs(e.x) + r * (0.2 + 0.25 * k)) - (gz - zc) ** 2 / (r * 2.5))
            a = np.maximum(a, (1 - sm(arc, r * 0.07, r * 0.13)) * sm(gz, zc - r * 0.9, zc - r * 0.5) * (1 - sm(gz, zc + r * 0.4, zc + r * 0.8)))
        brow = e.z + r * 2.2
        chev = np.abs(gz - (brow + 0.5 * np.abs(gx)))
        a = np.maximum(a, (1 - sm(chev, r * 0.08, r * 0.15)) * (1 - sm(np.abs(gx), r * 1.6, r * 2.0)))
        return (0.1, 0.18, 0.42), a * 0.9

    looks = dict(zip(MAKEUP_LOOKS, (smoky, cat, gold, red_lips, berry, rosy, freckles, war, tribal)))
    objs = []
    for name, paint in looks.items():
        rgb, alpha = paint()
        alpha = np.where(inside, 0.0, alpha) if name not in ("makeup_04", "makeup_05") else alpha
        img = bpy.data.images.new(name + "_tex", n, n, alpha=True)
        px = np.zeros((n, n, 4), dtype=np.float32)
        px[..., 0], px[..., 1], px[..., 2] = rgb
        px[..., 3] = np.clip(alpha, 0, 1)
        img.pixels[:] = px.ravel()
        img.pack()
        obj = _extract(template, face, name, states, offset=0.00045)
        mesh = obj.data
        uv = mesh.uv_layers.new(name="MakeupUV")
        mesh.uv_layers.active = uv
        for loop in mesh.loops:
            v = mesh.vertices[loop.vertex_index].co
            uv.data[loop.index].uv = ((v.x - x0) / (x1 - x0), (v.z - z0) / (z1 - z0))
        for layer in [l for l in mesh.uv_layers if l.name != "MakeupUV"]:
            mesh.uv_layers.remove(layer)
        # Seules les faces peintes sont gardées (fichier plus léger).
        keep = set()
        a_img = px[..., 3]
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                u, v = uv.data[li].uv
                if a_img[min(n - 1, int(v * (n - 1))), min(n - 1, int(u * (n - 1)))] > 0.01:
                    keep.add(poly.index)
                    break
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(mesh)
        bm.free()
        mat = _textured_material(name, img, alpha=True, roughness=0.5)
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

# Pose de repos naturelle (13/11/2026) : bras le long du corps, paumes vers
# les cuisses, doigts relâchés ; poids du corps sur la jambe gauche. Deux
# variantes pour les armes : poing droit fermé (arme à une main), avant-bras
# droit levé vers l'avant (bâton, sceptre, hallebarde). Les bras sont orientés
# par la direction voulue de chaque os (repère du corps : X vers la gauche du
# personnage, -Y vers l'avant, Z vers le haut).
POSES = ("pose_a", "pose_relaxed", "pose_hold", "pose_staff")
ARM_HANG = (0.13, 0.03)      # écart vers l'extérieur, recul du bras
ELBOW_BEND = 0.2             # avancée de l'avant-bras (coude un peu fléchi)
STAFF_UPPER = (-0.12, -0.12, -1.0)
STAFF_FORE = (-0.05, -1.0, 0.12)
FINGERS_SOFT = (-18, -22, -14)
THUMB_SOFT = (-8, -10, 0)
FINGERS_FIST = (-78, -95, -60)
THUMB_FIST = (-30, -35, -20)


def _hand_frame(arm, side):
    """Repère de la main au repos : poignet, direction de l'avant-bras, axe
    du poing (de l'auriculaire vers l'index), normale de la paume, base du
    majeur."""
    bones = arm.data.bones
    def h(n):
        return bones[n].head_local.copy()
    wrist, elbow = h("hand_" + side), h("lowerarm_" + side)
    fore = (wrist - elbow).normalized()
    across = (h("index_01_" + side) - h("pinky_01_" + side)).normalized()
    normal = fore.cross(across).normalized()
    # En pose A, la paume regarde vers le bas.
    if normal.z > 0:
        normal = -normal
    return wrist, fore, across, normal, h("middle_01_" + side)


def _aim(arm, name, child, target):
    """Oriente l'os [name] (vers la tête de [child]) dans la direction voulue."""
    bpy.context.view_layer.update()
    pb = arm.pose.bones[name]
    current = (arm.pose.bones[child].head - pb.head).normalized()
    q = current.rotation_difference(Vector(target).normalized())
    m = pb.matrix.copy()
    r = (q.to_matrix() @ m.to_3x3()).to_4x4()
    r.translation = m.translation
    pb.matrix = r


def _palm_towards(arm, side, want, sign):
    """Tourne l'avant-bras autour de son axe pour que la paume regarde [want]."""
    bpy.context.view_layer.update()
    pb = arm.pose.bones["lowerarm_" + side]
    bones = arm.pose.bones
    axis = (bones["hand_" + side].head - pb.head).normalized()
    across = (bones["index_01_" + side].head - bones["pinky_01_" + side].head).normalized()
    normal = axis.cross(across).normalized() * sign
    w = Vector(want)
    w = (w - axis * w.dot(axis)).normalized()
    n = (normal - axis * normal.dot(axis)).normalized()
    angle = math.atan2(axis.dot(n.cross(w)), n.dot(w))
    m = pb.matrix.copy()
    r = (Quaternion(axis, angle).to_matrix() @ m.to_3x3()).to_4x4()
    r.translation = m.translation
    pb.matrix = r


def _curl(arm, side, fingers, thumb):
    """Plie les doigts (et le pouce) vers la paume."""
    _, _, _, normal, _ = _hand_frame(arm, side)
    for finger, amounts in [(f, fingers) for f in ("index", "middle", "ring", "pinky")] + [("thumb", thumb)]:
        for k, degrees in zip(("01", "02", "03"), amounts):
            name = f"{finger}_{k}_{side}"
            bone = arm.data.bones[name]
            d = (bone.tail_local - bone.head_local).normalized()
            _rotate(arm, name, d.cross(normal).normalized(), degrees)


def _pose_body(arm, kind):
    """Pose [kind] : « relaxed », « hold » (arme à une main) ou « staff »."""
    for side, sx in (("l", 1), ("r", -1)):
        _, fore, across, normal, _ = _hand_frame(arm, side)
        sign = 1 if fore.cross(across).normalized().dot(normal) > 0 else -1
        upper = (sx * ARM_HANG[0], ARM_HANG[1], -1.0)
        lower = (sx * 0.04, -ELBOW_BEND, -1.0)
        if side == "r" and kind == "staff":
            upper, lower = STAFF_UPPER, STAFF_FORE
        _aim(arm, "upperarm_" + side, "lowerarm_" + side, upper)
        _aim(arm, "lowerarm_" + side, "hand_" + side, lower)
        _aim(arm, "hand_" + side, "middle_01_" + side, lower)
        _palm_towards(arm, side, (-sx, 0, 0), sign)
        bpy.context.view_layer.update()
        fist = side == "r" and kind != "relaxed"
        _curl(arm, side, FINGERS_FIST if fist else FINGERS_SOFT, THUMB_FIST if fist else THUMB_SOFT)
    for bone, axis, degrees in (
        ("pelvis", (0, 1, 0), 2.5), ("thigh_l", (0, 1, 0), 1.5), ("thigh_r", (0, -1, 0), 0.5),
        ("thigh_r", (1, 0, 0), -5), ("calf_r", (1, 0, 0), 10), ("spine_02", (0, -1, 0), 2.0),
        ("neck_01", (1, 0, 0), 2.0), ("head", (0, 1, 0), 2.5), ("head", (0, 0, 1), 4.0),
    ):
        _rotate(arm, bone, axis, degrees)


def _rotate(arm, name, axis, degrees):
    pose_bone = arm.pose.bones[name]
    pose_bone.rotation_mode = "QUATERNION"
    bone = arm.data.bones[name]
    # « twist » : rotation autour de l'axe de l'os lui-même (avant-bras).
    if axis == "twist":
        local = Vector((0, 1, 0))
    else:
        local = (bone.matrix_local.inverted().to_3x3() @ Vector(axis)).normalized()
    pose_bone.rotation_quaternion = Quaternion(local, math.radians(degrees)) @ pose_bone.rotation_quaternion


def _reset_pose(arm):
    for pose_bone in arm.pose.bones:
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = (1, 0, 0, 0)
        pose_bone.location = (0, 0, 0)
        pose_bone.scale = (1, 1, 1)


def _key_all(arm, frame):
    for pose_bone in arm.pose.bones:
        pose_bone.keyframe_insert("rotation_quaternion", frame=frame)


def _make_actions(arm):
    arm.animation_data_create()
    actions = []
    for name in POSES:
        _reset_pose(arm)
        action = bpy.data.actions.new(name)
        arm.animation_data.action = action
        if name != "pose_a":
            _pose_body(arm, name[len("pose_"):])
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


# --- Démonstration des exercices (3D) -----------------------------------------
#
# Les mouvements 2D de assets/animations/motions.json (angles des segments,
# articulation ancrée au sol, durée des transitions) sont reportés sur le
# squelette : chaque os prend la direction du segment correspondant, puis le
# corps est replacé pour que l'articulation d'ancrage reste à sa place. Une
# animation `ex_<mouvement>` par mouvement, en boucle.

# Chemin du fichier des mouvements : variable ARISE_MOTIONS, sinon à côté du
# script (lancement direct) ou dans le dossier courant (dépôt).
def _motions_path():
    path = os.environ.get("ARISE_MOTIONS")
    if path:
        return path
    here = globals().get("__file__")
    base = os.path.join(os.path.dirname(os.path.abspath(here)), "..", "..") if here else os.getcwd()
    return os.path.join(base, "assets", "animations", "motions.json")

MOTION_DEFAULT = dict(t=180, ua_n=0, fa_n=0, ua_f=0, fa_f=0, th_n=0, sh_n=0, th_f=0, sh_f=0, ft_n=90, ft_f=90, hd=0, sl=0)
MOTION_FPS = 24
MOTION_STEPS = 6  # poses intermédiaires calculées par transition

# Segment 2D → os (côté proche « n » = gauche, côté lointain « f » = droit).
MOTION_BONES = [
    ("t", "pelvis"),
    ("th_n", "thigh_l"), ("sh_n", "calf_l"), ("ft_n", "foot_l"),
    ("th_f", "thigh_r"), ("sh_f", "calf_r"), ("ft_f", "foot_r"),
    ("ua_n", "upperarm_l"), ("fa_n", "lowerarm_l"),
    ("ua_f", "upperarm_r"), ("fa_f", "lowerarm_r"),
]
MOTION_ANCHORS = {
    "root": ("thigh_l", "thigh_r"),
    "neck": ("neck_01",),
    "ankle_n": ("foot_l",),
    "toe_n": ("ball_l",),
    "hand_n": ("hand_l",),
    "ankle_f": ("foot_r",),
    "toe_f": ("ball_r",),
    "knee_n": ("calf_l",),
    "knee_f": ("calf_r",),
}

# Distance entre l'articulation et la surface du corps (contact au sol).
CLEARANCE = {
    "ball_l": 0.025, "ball_r": 0.025, "foot_l": 0.07, "foot_r": 0.07,
    "calf_l": 0.06, "calf_r": 0.06, "hand_l": 0.035, "hand_r": 0.035,
    "lowerarm_l": 0.04, "lowerarm_r": 0.04, "pelvis": 0.11, "thigh_l": 0.09,
    "thigh_r": 0.09, "spine_02": 0.11, "spine_03": 0.1, "head": 0.1,
}


def _motion_direction(angle, view):
    """Direction 3D d'un segment 2D (angle en degrés, 0 = vers le bas, 180 =
    vers le haut). De profil, l'avant du personnage est -Y ; de face, les
    angles positifs vont vers le côté gauche du personnage (+X)."""
    r = math.radians(angle)
    if view == "side":
        return Vector((0.0, -math.sin(r), -math.cos(r)))
    return Vector((math.sin(r), 0.0, -math.cos(r)))


def _motion_pose(arm, angles, view):
    """Oriente les os du squelette selon les angles d'une pose 2D."""
    # Épaules haussées : rotation des clavicules (comme la respiration).
    lift = angles.get("sl", 0.0)
    if lift:
        length = (arm.data.bones["clavicle_l"].tail_local - arm.data.bones["clavicle_l"].head_local).length
        degrees = math.degrees(math.asin(min(0.9, lift / length)))
        _rotate(arm, "clavicle_l", (0, 1, 0), -degrees)
        _rotate(arm, "clavicle_r", (0, -1, 0), -degrees)
        bpy.context.view_layer.update()
    for key, bone in MOTION_BONES:
        side = None if key == "t" else key[-1]
        angle = angles[key]
        if view == "front":
            if key.startswith("ft"):
                continue
            # De face, les angles du côté lointain sont en miroir (motions.py).
            if side == "f":
                angle = -angle
        target = _motion_direction(angle, view)
        pb = arm.pose.bones[bone]
        bpy.context.view_layer.update()
        head, tail = pb.head.copy(), pb.tail.copy()
        # Le tronc suit la ligne bassin → cou (comme la figure 2D), pas l'os
        # du bassin, incliné vers l'arrière au repos.
        if bone == "pelvis":
            tail = arm.pose.bones["neck_01"].head.copy()
        current = (tail - head).normalized()
        rot = current.rotation_difference(target.normalized()).to_matrix().to_4x4()
        pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()
    # Tête inclinée par rapport au tronc (hochement de profil, inclinaison
    # latérale de face).
    tilt = angles.get("hd", 0.0)
    if tilt:
        pb = arm.pose.bones["neck_01"]
        head = pb.head.copy()
        rot = Matrix.Rotation(math.radians(-tilt), 4, "X" if view == "side" else "Y")
        pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
        bpy.context.view_layer.update()


# Figure 2D (mêmes longueurs que tool/motions.py) : sert à repérer les appuis
# au sol de chaque pose.
FIGURE = dict(torso=0.55, upper_arm=0.30, forearm=0.27, thigh=0.45, shin=0.43, foot=0.13)
FIGURE_SHOULDER_AT = 0.92


def _figure_joints(angles, root):
    """Articulations de la figure 2D (y vers le bas, comme motions.py)."""
    def add(p, a, length):
        r = math.radians(a)
        return (p[0] + math.sin(r) * length, p[1] + math.cos(r) * length)

    sh = add(root, angles["t"], FIGURE["torso"] * FIGURE_SHOULDER_AT + angles.get("sl", 0.0))
    joints = {}
    for side in ("n", "f"):
        elbow = add(sh, angles["ua_" + side], FIGURE["upper_arm"])
        joints["hand_" + side] = add(elbow, angles["fa_" + side], FIGURE["forearm"])
    for side in ("n", "f"):
        knee = add(root, angles["th_" + side], FIGURE["thigh"])
        ankle = add(knee, angles["sh_" + side], FIGURE["shin"])
        joints["knee_" + side] = knee
        joints["ankle_" + side] = ankle
        joints["toe_" + side] = add(ankle, angles["ft_" + side], FIGURE["foot"])
    return joints


# Points de contact 3D (os, hauteur de l'articulation au-dessus du sol).
CONTACTS = {
    "hand_n": ("hand_l", 0.035),
    "hand_f": ("hand_r", 0.035),
    "knee_n": ("calf_l", 0.06),
    "knee_f": ("calf_r", 0.06),
    "toe_n": ("ball_l", 0.025),
    "toe_f": ("ball_r", 0.025),
}


def _ground_contacts(angles, root, anchor):
    """Second appui au sol d'une pose de profil au sol (ancrage mains ou
    pointes de pieds) : l'articulation loin de l'ancrage la plus proche du
    niveau du sol."""
    if anchor not in ("hand_n", "toe_n", "knee_n", "knee_f"):
        return []
    joints = _figure_joints(angles, root)
    ax, ay = joints[anchor]
    near = [
        name for name, (x, y) in joints.items()
        if name in CONTACTS and name != anchor and abs(x - ax) > 0.3 and abs(y - ay) < 0.12
    ]
    # Mains d'abord quand l'appui est aux pieds ou aux genoux, pieds d'abord
    # quand il est aux mains.
    if anchor.startswith("knee"):
        # À genoux : seules les mains cherchent le sol.
        near = [n for n in near if n.startswith("hand")]
    hands_first = not anchor.startswith("hand")
    return sorted(near, key=lambda n: (n.startswith("hand") != hands_first, abs(joints[n][1] - ay)))


def _flatten_hands(arm, forward, names=("hand_l", "hand_r")):
    """Mains à plat au sol, doigts vers l'avant."""
    for name in names:
        pb = arm.pose.bones[name]
        bpy.context.view_layer.update()
        head = pb.head.copy()
        current = (pb.tail - head).normalized()
        rot = current.rotation_difference(forward).to_matrix().to_4x4()
        pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()


def _anchor_point(arm, anchor):
    points = [arm.pose.bones[b].head for b in MOTION_ANCHORS[anchor]]
    return sum(points, Vector()) / len(points)


def _motion_frames(motion):
    """Poses (angles, ancrage, cible) échantillonnées sur le cycle, avec le
    même lissage que la figure 2D, et leur instant en secondes."""
    keys = motion["keys"]
    total = sum(k["hold"] for k in keys)
    frames = []
    t = 0.0
    for i, key in enumerate(keys):
        nxt = keys[(i + 1) % len(keys)]
        a = {**MOTION_DEFAULT, **key["angles"]}
        b = {**MOTION_DEFAULT, **nxt["angles"]}
        steps = MOTION_STEPS if key["hold"] > 0 and len(keys) > 1 else 1
        for step in range(steps):
            u = step / steps
            k = u * u * (3 - 2 * u)
            angles = {n: a[n] + (b[n] - a[n]) * k for n in a}
            target = [key["target"][c] + (nxt["target"][c] - key["target"][c]) * k for c in (0, 1)]
            root = [key["root"][c] + (nxt["root"][c] - key["root"][c]) * k for c in (0, 1)]
            frames.append((t + key["hold"] * u, angles, key["anchor"], target, root))
        t += key["hold"]
    return frames, total


def _is_rest(pb):
    """Os laissé dans sa position de repos."""
    q = pb.rotation_quaternion
    return abs(q.w) > 0.99999 and pb.location.length < 1e-6


# Os qui délimitent la silhouette pendant un mouvement.
EXTENT_BONES = ("head", "hand_l", "hand_r", "foot_l", "foot_r", "pelvis")


def _exercise_actions(arm):
    """Une animation par mouvement d'exercice (`ex_<id>`), en boucle."""
    import json

    with open(_motions_path(), encoding="utf-8") as f:
        motions = json.load(f)
    bones = arm.pose.bones
    _reset_pose(arm)
    bpy.context.view_layer.update()
    # Échelle 2D → 3D : longueur de la jambe (cuisse + jambe).
    leg = (bones["thigh_l"].tail - bones["thigh_l"].head).length + (bones["calf_l"].tail - bones["calf_l"].head).length
    scale = leg / 0.88
    rest = {a: _anchor_point(arm, a) for a in MOTION_ANCHORS}
    floor_z = rest["ankle_n"].z
    ground = bones["ball_l"].head.z - CLEARANCE["ball_l"]
    actions = []
    for name, motion in motions.items():
        view = motion["view"]
        action = bpy.data.actions.new("ex_" + name)
        arm.animation_data.action = action
        frames, total = _motion_frames(motion)
        samples = frames + [(total, *frames[0][1:])]
        root2d = {f[0]: f[4] for f in samples}
        def place(seconds, angles, anchor, target):
            _reset_pose(arm)
            _motion_pose(arm, angles, view)
            # Le corps est replacé : l'articulation d'ancrage va à sa cible
            # (cible 2D (0, 0) = sol pour les pieds, position de repos sinon).
            point = _anchor_point(arm, anchor)
            base = rest[anchor]
            goal = Vector((
                base.x if view == "side" else base.x + target[0] * scale,
                -target[0] * scale if view == "side" else base.y,
                (floor_z if anchor in ("ankle_n", "toe_n", "hand_n") else base.z) - target[1] * scale,
            ))
            if anchor in ("toe_n", "toe_f", "hand_n"):
                goal.z = floor_z - 0.06 - target[1] * scale
            elif anchor in ("knee_n", "knee_f", "ankle_f"):
                # Genou au sol (à genoux, à quatre pattes) ou pied éloigné.
                goal.z = (floor_z if anchor != "ankle_f" else base.z) - target[1] * scale
            delta = goal - point
            root = bones["Root"]
            root.matrix = Matrix.Translation(delta) @ root.matrix
            bpy.context.view_layer.update()
            # Exercices au sol : le corps bascule autour de l'ancrage jusqu'à
            # ce que le second appui (mains, pieds, genoux) touche le sol.
            if view == "side":
                contacts = _ground_contacts(angles, root2d[seconds], anchor)
                if contacts:
                    bone, lift = CONTACTS[contacts[0]]
                    pivot = _anchor_point(arm, anchor)
                    c = arm.pose.bones[bone].head
                    v = c - pivot
                    floor_c = floor_z - 0.06 + lift
                    length = math.hypot(v.y, v.z)
                    if length > 1e-4 and abs(floor_c - pivot.z) < length:
                        phi = math.atan2(v.z, v.y)
                        want = math.asin((floor_c - pivot.z) / length)
                        if v.y < 0:
                            want = math.pi - want
                        theta = want - phi
                        theta = (theta + math.pi) % (2 * math.pi) - math.pi
                        # Bascule limitée : au-delà, la pose 2D ne convient pas.
                        if abs(theta) > math.radians(40):
                            theta = 0.0
                        rot = Matrix.Rotation(theta, 4, "X")
                        root.matrix = Matrix.Translation(pivot) @ rot @ Matrix.Translation(-pivot) @ root.matrix
                        bpy.context.view_layer.update()
                # Seules les mains posées au sol sont mises à plat.
                flat = [CONTACTS[c][0] for c in contacts if c.startswith("hand")]
                if anchor == "hand_n":
                    flat = ["hand_l", "hand_r"]
                if flat:
                    _flatten_hands(arm, Vector((0, -1, -0.12)).normalized(), flat)

        # Première passe : étendue du mouvement d'avant en arrière, pour le
        # centrer devant la caméra.
        ys = []
        lows = []
        moved = {"Root"}
        for seconds, angles, anchor, target, _ in samples:
            place(seconds, angles, anchor, target)
            ys += [bones[b].head.y for b in EXTENT_BONES]
            ys += [bones[b].tail.y for b in EXTENT_BONES]
            lows.append(min(bones[b].head.z - c for b, c in CLEARANCE.items()))
            moved |= {pb.name for pb in bones if not _is_rest(pb)}
        # Centré devant la caméra, et posé au sol : la pose la plus basse du
        # cycle touche le sol (les sauts gardent leur élan).
        shift = Vector((0, -(min(ys) + max(ys)) / 2 if view == "side" else 0, ground - min(lows)))
        for seconds, angles, anchor, target, _ in samples:
            place(seconds, angles, anchor, target)
            root = bones["Root"]
            root.matrix = Matrix.Translation(shift) @ root.matrix
            bpy.context.view_layer.update()
            frame = 1 + round(seconds * MOTION_FPS)
            # Seuls les os qui bougent sont animés (taille du fichier) ; le
            # visualiseur remet le squelette au repos avant de jouer le clip.
            for pb in bones:
                if pb.name in moved:
                    pb.keyframe_insert("rotation_quaternion", frame=frame)
                    if pb.name == "Root":
                        pb.keyframe_insert("location", frame=frame)
        action.use_fake_user = True
        actions.append(action)
    _reset_pose(arm)
    arm.animation_data.action = None
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
    _seat_weapons(arm, {o.name: o for o in objects})
    # Les poses se calculent squelette seul : sans cela, chaque mise à jour
    # redéformerait toutes les pièces (des centaines), ce qui prend des heures.
    mods = [m for o in objects for m in o.modifiers if m.type == "ARMATURE"]
    for m in mods:
        m.show_viewport = False
    _make_actions(arm)
    # Les démonstrations d'exercices sont des vidéos rendues à part
    # (tool/exercise3d) : plus d'animations d'exercice dans le modèle.
    if os.environ.get("ARISE_EXERCISE_CLIPS"):
        _exercise_actions(arm)
    for m in mods:
        m.show_viewport = True
    return arm



# --- Équipement de la boutique (phase 7) ---------------------------------------
#
# Chaque objet est une pièce `item_<id>` tirée du corps (mêmes formes de
# morphologie, mêmes poids de peau) ou, pour les armes, une pièce rigide liée à
# la main droite et déplacée avec elle d'un état à l'autre. Les matériaux
# `dye_<id>` peuvent être teints par l'application.

# Matières réalistes (ambientCG, CC0) : texture répétée sur la pièce, relief
# et rugosité. La couleur est ramenée en niveaux de gris puis multipliée par
# la teinte de la pièce, ce qui garde la teinture de la boutique.
PBR_SETS = {
    # matière : (dossier ambientCG, répétitions sur les UV du corps)
    "leather": ("Leather037", 9.0),
    "mail": ("Chainmail004", 16.0),
    "steel": ("Metal009", 3.0),
    "gold": ("Metal048A", 3.0),
    "cloth": ("Fabric061", 10.0),
    "wood": ("Leather026", 3.0),
}
PBR_TEXTURE_SIZE = 512

ITEM_MATERIALS = {
    # nom : (matière, couleur linéaire, métal, rugosité de base)
    "leather_brown": ("leather", (0.16, 0.075, 0.035, 1.0), 0.0, 0.82),
    "leather_dark": ("leather", (0.05, 0.028, 0.016, 1.0), 0.0, 0.78),
    "mail": ("mail", (0.55, 0.56, 0.58, 1.0), 1.0, 0.45),
    "steel": ("steel", (0.62, 0.63, 0.65, 1.0), 1.0, 0.3),
    "gold": ("gold", (0.85, 0.60, 0.22, 1.0), 1.0, 0.3),
    "cloth_teal": ("cloth", (0.04, 0.16, 0.17, 1.0), 0.0, 0.9),
    "cloth_red": ("cloth", (0.40, 0.04, 0.04, 1.0), 0.0, 0.9),
    "cloth_violet": ("cloth", (0.14, 0.07, 0.22, 1.0), 0.0, 0.9),
    "wood": ("wood", (0.20, 0.10, 0.045, 1.0), 0.0, 0.8),
    "ember": (None, (1.0, 0.22, 0.02, 1.0), 0.0, 0.4),
}

# Objets teignables : matériau de base de leur teinture.
DYEABLE = {
    "leather_chest": "leather_brown",
    "leather_legs": "leather_brown",
    "cape_wanderer": "cloth_teal",
    "cape_dawn": "cloth_red",
    "hood_twilight": "cloth_violet",
}

_PBR_IMAGES = {}


def _pbr_root():
    root = os.environ.get("ARISE_PBR")
    if not root or not os.path.isdir(root):
        raise RuntimeError("ARISE_PBR doit désigner le dossier des matières ambientCG décompressées")
    return root


def _pbr_images(material):
    """Couleur (niveaux de gris normalisés), relief et rugosité d'une matière."""
    import numpy as np

    if material in _PBR_IMAGES:
        return _PBR_IMAGES[material]
    folder, _ = PBR_SETS[material]
    base = os.path.join(_pbr_root(), folder, f"{folder}_1K-JPG_")
    color = _image(base + "Color.jpg", f"pbr_{material}_col", size=PBR_TEXTURE_SIZE)
    w, h = color.size
    px = np.array(color.pixels[:], dtype=np.float32).reshape(h, w, 4)
    lum = px[..., :3] @ np.array([0.3, 0.59, 0.11], dtype=np.float32)
    grey = np.clip(lum / max(np.percentile(lum, 97), 1e-3), 0.0, 1.0)
    # Contraste adouci : le grain reste visible sans taches marquées.
    grey = 0.55 + 0.45 * grey
    for c in range(3):
        px[..., c] = grey
    color.pixels[:] = px.ravel()
    color.pack()
    normal = _image(base + "NormalGL.jpg", f"pbr_{material}_nrm", size=PBR_TEXTURE_SIZE)
    rough = _image(base + "Roughness.jpg", f"pbr_{material}_rgh", size=PBR_TEXTURE_SIZE)
    normal.colorspace_settings.name = "Non-Color"
    rough.colorspace_settings.name = "Non-Color"
    _PBR_IMAGES[material] = (color, normal, rough)
    return _PBR_IMAGES[material]


def _pbr_material(name, look):
    """Matériau réaliste : texture de la matière × couleur de la pièce."""
    material, color, metal, rough = ITEM_MATERIALS[look]
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = next(n for n in nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    mat.use_backface_culling = False
    if material is None:
        bsdf.inputs["Base Color"].default_value = color
        if look == "ember":
            bsdf.inputs["Emission Color"].default_value = color
            bsdf.inputs["Emission Strength"].default_value = 1.2
        return mat
    col_img, nrm_img, rgh_img = _pbr_images(material)
    _, repeat = PBR_SETS[material]
    coord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (repeat, repeat, 1.0)
    links.new(coord.outputs["UV"], mapping.inputs["Vector"])

    def tex(image):
        node = nodes.new("ShaderNodeTexImage")
        node.image = image
        links.new(mapping.outputs["Vector"], node.inputs["Vector"])
        return node

    # Couleur : texture × teinte (exportée comme baseColorFactor).
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    rgba_in = [i for i in mix.inputs if i.type == "RGBA"]
    rgba_out = [o for o in mix.outputs if o.type == "RGBA"]
    links.new(tex(col_img).outputs["Color"], rgba_in[0])
    rgba_in[1].default_value = color
    links.new(rgba_out[0], bsdf.inputs["Base Color"])
    nmap = nodes.new("ShaderNodeNormalMap")
    links.new(tex(nrm_img).outputs["Color"], nmap.inputs["Color"])
    links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    if metal > 0:
        links.new(tex(rgh_img).outputs["Color"], bsdf.inputs["Roughness"])
    return mat


def _item_material(item_id, look):
    if item_id in DYEABLE:
        return _pbr_material("dye_" + item_id, DYEABLE[item_id])
    return _pbr_material("item_" + look, look)


# Vraies pièces MakeHuman pour l'équipement de la boutique : (dossier, matière
# imposée ou None pour garder la texture d'origine, os des pièces rigides).
ITEM_SOURCES = {
    "leather_chest": ("clothes/elvs_male_boho_top1", "leather_brown", None),  # CC-BY
    "leather_legs": ("clothes/toigo_wool_pants", "leather_brown", None),
    "leather_hands": ("clothes/toigo_gloves_short", "leather_dark", None),
    "leather_feet": ("clothes/punkduck_medieval_boots", None, None),  # CC-BY
    "mail_chest": ("clothes/rehmanpolanski_viking_tunic", None, None),
    "mail_hands": ("clothes/toigo_gloves_medium", "mail", None),
    "mail_feet": ("clothes/madmanny_tight_leather_boots", None, None),  # CC-BY
    "plate_head": ("clothes/javherre_casco_caballero_templario_templar_knight_helmet", None, "head"),
    "plate_hands": ("clothes/toigo_gloves_long", "steel", None),
    "plate_feet": ("clothes/culturalibre_hero_boots_4", "steel", None),
    "hood_twilight": ("clothes/donitz_monk_robe_hood", "cloth_violet", None),
}

# Gonflement des vraies pièces (mètres) : les vêtements du torse et des
# jambes tombent plus amples (13/11/2026).
ITEM_INFLATE = {
    "leather_chest": 0.015,
    "leather_legs": 0.011,
    "leather_hands": 0.003,
    "leather_feet": 0.006,
    "mail_hands": 0.003,
    "mail_feet": 0.006,
    "plate_hands": 0.004,
    "plate_feet": 0.007,
}


def _item_proxy(item_id, states):
    """Objet de la boutique fait d'une vraie pièce MakeHuman ajustée au corps."""
    folder, look, _ = ITEM_SOURCES[item_id]
    name = "item_" + item_id
    if look is not None:
        material = _item_material(item_id, look)
    else:
        normal = _normal_texture(folder)
        material = _textured_material(
            name,
            _image(_diffuse_texture(folder), name + "_tex"),
            alpha=False,
            roughness=0.6,
            normal=_image(normal, name + "_nrm") if normal else None,
        )
    obj = _proxy(folder, name, states, material, inflate=ITEM_INFLATE.get(item_id, 0.0))
    if look is not None and not obj.data.uv_layers:
        obj.data.uv_layers.new(name="UVMap")
    return obj


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


# Lissage des pièces tirées du corps (nombre de passes).
ITEM_SMOOTH = {
    "leather_chest": 3,
    "leather_legs": 1,
    "mail_head": 2,
    "mail_legs": 2,
    "plate_shoulders": 4,
    "plate_chest": 25,
    "plate_belt": 4,
    "plate_legs": 5,
}


def _item_from_body(template, groups, states, j, height, item_id, look, test, offset, flare=None):
    base = states["base"]
    keep = _faces_where(template, base, groups["body"], lambda c: test(c, _part(c, j, height)))
    if not keep:
        return None
    obj = _extract(
        template,
        keep,
        "item_" + item_id,
        states,
        offset=offset,
        flare=flare,
        smooth=ITEM_SMOOTH.get(item_id, 0),
    )
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


# Casques importés : fichier dans tool/character/external, largeur rapportée
# à celle de la tête, hauteur du sommet au-dessus du crâne et recul (en
# fraction de la taille du personnage).
EXTERNAL_HELMS = {
    "great_helm_gilded": ("great_helm_gilded.glb", 1.5, 0.022, 0.006, 90),
    "horned_helm_void": ("horned_helm_void.glb", 2.1, 0.03, 0.006, 0),
}

# Armes en main : objet -> (tenue « up » ou « down », point de poignée au
# moment de la construction, pointe construite vers le bas).
WEAPON_FRAMES = {}
WEAPON_TILT = 58     # lame inclinée vers le bas (degrés), arme à une main
WEAPON_FLARE = 0.18   # écart de la lame vers l'extérieur, loin de la jambe


def _seat_weapons(arm, objects):
    """Met chaque arme dans le poing droit : poignée au creux de la main, axe
    du poing pour un bâton (vertical une fois l'avant-bras levé), lame vers
    l'avant, le bas et l'extérieur pour une arme à une main."""
    wrist, fore, across, normal, middle = _hand_frame(arm, "r")
    height = max(v.co.z for v in objects["body"].data.vertices)
    seat = (wrist + middle) / 2 + normal * 0.0065 * height
    back = -normal  # dos de la main : vers l'extérieur une fois le bras baissé
    for name, (hold, grip, flipped) in WEAPON_FRAMES.items():
        obj = objects.get(name)
        if obj is None:
            continue
        if hold == "up":
            tip = across
        else:
            a = math.radians(WEAPON_TILT)
            tip = (across * math.cos(a) + fore * math.sin(a) + back * WEAPON_FLARE).normalized()
        y = (normal - tip * normal.dot(tip)).normalized()
        x = y.cross(tip)
        rot = Matrix((x, y, tip)).transposed()
        if flipped:
            rot = rot @ Matrix.Rotation(math.radians(180), 3, "X")
        basis = [v.co.copy() for v in obj.data.vertices]
        moved = [seat + rot @ (co - grip) for co in basis]
        keys = obj.data.shape_keys.key_blocks if obj.data.shape_keys else []
        for key in keys:
            for i, kd in enumerate(key.data):
                kd.co = moved[i] + (kd.co - basis[i])
        for i, v in enumerate(obj.data.vertices):
            v.co = moved[i]


# Armes importées (tool/character/external/weapons, préparées par
# prep_weapons.py : poignée à l'origine, tête vers le haut) : tenue (« up »
# tête en haut, « down » pointe vers le bas) et longueur en fraction de la
# taille du personnage.
EXTERNAL_WEAPONS = {
    "staff_solar_crystal": ("up", 0.95), "scepter_lunar_orb": ("up", 0.9),
    "staff_rose_amethyst": ("up", 0.95), "staff_dusk": ("up", 0.95),
    "halberd_silver": ("up", 1.0),
    "sword_warden": ("down", 0.55), "sword_curved_shade": ("down", 0.5),
    "sword_carved_bone": ("down", 0.5), "sword_frost": ("down", 0.55),
    "sword_dusk": ("down", 0.52), "sword_ember": ("down", 0.52),
    "scimitar_jade": ("down", 0.5), "glaive_curved": ("down", 0.6),
    "dagger_desert": ("down", 0.24), "dagger_golden": ("down", 0.24),
    "dagger_ice": ("down", 0.24), "dagger_amethyst": ("down", 0.24),
    "dagger_fire_fang": ("down", 0.24), "dagger_sun": ("down", 0.24),
    "dagger_blaze": ("down", 0.24),
    "mace_spiked": ("down", 0.42), "mace_moon": ("down", 0.42),
    "axe_war": ("down", 0.45), "cleaver_battle": ("down", 0.45),
    "hammer_runic": ("down", 0.45),
}


def _rigid_item(item_id, parts, anchor_of, states, look_of, smooth=False):
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
        poly.use_smooth = smooth
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
    uv = mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            v = mesh.loops[li].vertex_index
            uv.data[li].uv = ((v % cols) / (cols - 1) * 0.15, (v // cols) / (rows - 1) * 0.25)
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
        ("mail_legs", "mail", lambda c, p: p in ("thigh", "shin"), 0.024, None),
        ("mail_feet", "steel", lambda c, p: p == "foot", 0.02, None),
        # Plates de l'Aube.
        ("plate_head", "steel", lambda c, p: p == "head" and not face_open(c), 0.026, None),
        ("plate_shoulders", "gold", lambda c, p: p in ("upperarm", "torso") and abs(c.x) > abs(j["shoulder_l"].x) * 0.55 and c.z > j["shoulder_l"].z - 0.045 * H and c.z < neck_z, 0.045, None),
        ("plate_chest", "steel", torso(0, 0.585), 0.055, None),
        ("plate_hands", "steel", lambda c, p: p == "hand" or p == "forearm", 0.016, None),
        ("plate_belt", "gold", lambda c, p: p in ("torso", "thigh") and 0.47 * H < c.z < 0.585 * H, 0.05, (0.56 * H, 1.6)),
        ("plate_legs", "steel", lambda c, p: p in ("thigh", "shin") and c.z > j["ankle_l"].z + 0.07 * H, 0.04, None),
        ("plate_feet", "steel", lambda c, p: p == "foot" or (p == "shin" and c.z < j["ankle_l"].z + 0.1 * H), 0.028, None),
        # Capuche du Crépuscule : tête, nuque et haut des épaules.
        ("hood_twilight", "cloth_violet", lambda c, p: (p == "head" and not face_open(c)) or p == "neck" or (p == "torso" and c.z > j["shoulder_l"].z and abs(c.x) < abs(j["shoulder_l"].x)), 0.032, None),
    ]
    held = {}
    for item_id in ITEM_SOURCES:
        obj = _item_proxy(item_id, states)
        bone = ITEM_SOURCES[item_id][2]
        if bone is not None:
            held[obj.name] = bone
        if not item_id.endswith("_head") and not item_id.startswith("hood"):
            _drop_face_keys(obj)
    for item_id, look, test, offset, flare in items:
        if item_id in ITEM_SOURCES:
            continue
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
    # Lame construite vers le bas : retournée avant d'être mise en main.
    WEAPON_FRAMES["item_sword_dawn"] = ("down", grip.copy(), True)

    held["item_sword_dawn"] = "hand_r"

    # Bâton de Braise : hampe de bois, bague dorée, orbe incandescent.
    wood = _item_material("staff_ember", "wood")
    ember = _item_material("staff_ember", "ember")
    staff = [
        _cylinder("shaft", grip + Vector((0, 0, -0.5 * H)), grip + Vector((0, 0, 0.5 * H)), 0.016, mat=wood),
        _blob("orb", grip + Vector((0, 0, 0.53 * H)), (0.04, 0.04, 0.05)),
        _cylinder("band", grip + Vector((0, 0, 0.44 * H)), grip + Vector((0, 0, 0.47 * H)), 0.022, mat=gold),
    ]
    staff[1].data.materials.append(ember)
    _rigid_item("staff_ember", staff, hand_r, states, None)
    WEAPON_FRAMES["item_staff_ember"] = ("up", grip - Vector((0, 0, 0.08 * H)), False)
    held["item_staff_ember"] = "hand_r"

    # Casques importés (modèles 3D créés par la propriétaire du projet, déjà
    # allégés) : posés sur la tête puis portés par l'os de la tête.
    head_ids = [i for i in groups["body"] if _part(base[i], j, H) == "head"]
    xs = [base[i].x for i in head_ids]
    ys = [base[i].y for i in head_ids]
    top = max(base[i].z for i in head_ids)
    head_width = max(xs) - min(xs)
    head_center = Vector(((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, 0))

    def head(coords):
        return _joints(coords, groups)["head"]

    for item_id, (file, width_ratio, lift, back, quarter) in EXTERNAL_HELMS.items():
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "external", file)
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        parts = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
        for extra in [o for o in bpy.data.objects if o not in before and o.type != "MESH"]:
            bpy.data.objects.remove(extra, do_unlink=True)
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.parent = None
            part.select_set(True)
            bpy.context.view_layer.objects.active = part
            # Face du casque ramenée vers l'avant du personnage (-Y).
            part.rotation_mode = "XYZ"
            part.rotation_euler = (0, 0, 0)
            part.matrix_world = Matrix.Rotation(math.radians(quarter), 4, "Z") @ part.matrix_world
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        pts = [v.co for part in parts for v in part.data.vertices]
        lo = Vector([min(p[k] for p in pts) for k in range(3)])
        hi = Vector([max(p[k] for p in pts) for k in range(3)])
        scale = head_width * width_ratio / (hi.x - lo.x)
        anchor = Vector(((hi.x + lo.x) / 2, (hi.y + lo.y) / 2, hi.z))
        target = Vector((head_center.x, head_center.y + back * H, top + lift * H))
        for part in parts:
            for v in part.data.vertices:
                v.co = target + (v.co - anchor) * scale
        _rigid_item(item_id, parts, head, states, None, smooth=True)
        held["item_" + item_id] = "head"

    # Armes importées, dans la main droite.
    for item_id, (hold, length) in EXTERNAL_WEAPONS.items():
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "external", "weapons", item_id + ".glb")
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        parts = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
        for extra in [o for o in bpy.data.objects if o not in before and o.type != "MESH"]:
            bpy.data.objects.remove(extra, do_unlink=True)
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.parent = None
            part.select_set(True)
            bpy.context.view_layer.objects.active = part
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        zs = [v.co.z for part in parts for v in part.data.vertices]
        scale = length * H / (max(zs) - min(zs))
        # Bâtons tenus vers 40 % de leur longueur ; les autres armes gardent
        # la poignée préparée par prep_weapons.py. Pointe vers +Z, puis mise
        # dans le poing une fois le squelette créé (_seat_weapons).
        shift = Vector((0, 0, min(zs) + 0.4 * (max(zs) - min(zs)))) if hold == "up" else Vector()
        for part in parts:
            for v in part.data.vertices:
                v.co = grip + (v.co - shift) * scale
        _rigid_item(item_id, parts, hand_r, states, None, smooth=True)
        WEAPON_FRAMES["item_" + item_id] = (hold, grip.copy(), False)
        held["item_" + item_id] = "hand_r"
    return held


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
    skin_folder = SKIN_SOURCES[sex]
    skin = _textured_material(
        "skin",
        _neutral_skin_image(_diffuse_texture(skin_folder), "skin_tex"),
        alpha=False,
        roughness=0.5,
    )
    body.data.materials.append(skin)
    # Corps réaliste fourni (sous le cou), si présent : la tête MPFB reste.
    fit = _fit_module()
    real_body = os.path.join(os.path.dirname(os.path.abspath(__file__)), "external", "bodies", sex + ".glb")
    if os.path.exists(real_body):
        height0 = max(states["base"][i].z for i in groups["body"])
        fit.replace_body(body, real_body, _joints(states["base"], groups), height0, _part)
    marks = _landmarks(states["base"], groups)
    _eye_parts(template, groups, states, mats)
    _eyebrows(template, groups, states, marks, mats["brow"])
    if sex == "male":
        _beards(template, groups, states, marks, mats["beard"])
    _makeups(template, groups, states, marks)

    # Tenue de départ : vraies pièces de vêtement (MakeHuman), texturées.
    co = states["base"]
    height = max(co[i].z for i in groups["body"])
    # Sous-vêtements ajustés (maillot et collant), tirés de la peau juste
    # au-dessus d'elle : affichés seulement quand un objet de la boutique
    # remplace la blouse ou le pantalon, ils couvrent le corps sous l'objet
    # (les sous-vêtements ne sont décalés que de 1,5 mm).
    body_faces = groups["body"]
    hand_x = 0.165 * height

    def top(c):
        return 0.555 * height < c.z < 0.83 * height and abs(c.x) < 0.157 * height

    def bottom(c):
        return 0.17 * height < c.z < 0.62 * height and abs(c.x) < hand_x * 0.85

    # Sous-vêtements : ceux du corps réaliste ; sans lui, maillot et
    # collant tirés de la peau (montrés quand un objet remplace la tenue).
    for name, test, look in ([] if os.path.exists(real_body) else (
        ("outfit_under_top", top, "under_linen"),
        ("outfit_under_pants", bottom, "under_wool"),
    )):
        keep = _faces_where(template, co, body_faces, test)
        if keep:
            obj = _extract(template, keep, name, states, offset=0.0015)
            obj.data.materials.append(mats[look])
    for name, (folder, look) in OUTFIT_SOURCES.items():
        normal = _normal_texture(folder)
        texture = _image(_diffuse_texture(folder), name + "_tex")
        if name in OUTFIT_TINTS:
            import numpy as np

            px = np.array(texture.pixels[:], dtype=np.float32).reshape(-1, 4)
            px[:, :3] *= np.array(OUTFIT_TINTS[name], dtype=np.float32)
            texture.pixels[:] = px.ravel()
            texture.pack()
        material = _textured_material(
            look,
            texture,
            alpha=False,
            roughness=0.85,
            normal=_image(normal, name + "_nrm") if normal else None,
        )
        _proxy(folder, name, states, material)

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
    # Coiffures et barbes fournies (pieces.json), posées sur la tête MPFB.
    head_ids = {i for i in groups["body"] if co[i].z > _joints(co, groups)["neck"].z}
    head_bm = bmesh.new()
    head_verts = {i: head_bm.verts.new(co[i]) for i in head_ids}
    for poly in template.polygons:
        if all(v in head_ids for v in poly.vertices):
            try:
                head_bm.faces.new([head_verts[v] for v in poly.vertices])
            except ValueError:
                pass
    head_bm.normal_update()
    from mathutils.bvhtree import BVHTree

    head_pieces = fit.add_head_pieces(BVHTree.FromBMesh(head_bm), [co[i] for i in head_ids], marks)
    head_bm.free()
    held = _equipment(template, groups, states, marks)
    # Vêtements tirés du corps MPFB : poussés hors du corps réaliste.
    if os.path.exists(real_body):
        fit.push_out(
            [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(("outfit_", "item_")) and o.name not in held],
            bpy.data.objects["body"],
        )
    # Tenues Sketchfab (fit_outfits.py) : ajustées sur ce corps, exportées
    # chacune dans son propre fichier.
    # ARISE_NO_OUTFITS=1 : essai rapide sans les tenues.
    outfit_sets = {} if os.environ.get("ARISE_NO_OUTFITS") else fit.add_outfits(bpy.data.objects["body"], _joints(co, groups), height, _part)
    # Pièces d'armure fournies (pieces.json) : un fichier par pièce.
    outfit_sets.update(fit.add_slot_pieces(bpy.data.objects["body"], _joints(co, groups), height, _part))
    for set_id, pieces in outfit_sets.items():
        tint = fit.load_outfits().get(set_id, {}).get("tint")
        if tint:
            # Tenue sans texture : teinte de base, et teignable en boutique
            # (matériau « dye_<objet> »).
            for piece in pieces:
                fit.tint_material(piece, tint)
                for slot in piece.material_slots:
                    if slot.material:
                        slot.material.name = "dye_" + piece.name[len("item_"):]
    bpy.data.meshes.remove(template)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    rigid = {o.name: "head" for o in meshes if o.name.startswith(("hair_", "tusks", "eye_", "brow_", "lashes"))}
    rigid.update(held)
    rigid.update({o.name: "head" for o in head_pieces})
    rigid.update({o.name: o["rigid_bone"] for o in meshes if "rigid_bone" in o})
    _rig_and_skin(sex, race, meshes, rigid)

    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{race}_{sex}.glb")
    outfit_objects = {o for pieces in outfit_sets.values() for o in pieces}
    bpy.ops.object.select_all(action="SELECT")
    for o in outfit_objects:
        o.select_set(False)
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
    # Une tenue par fichier (squelette + pièces), chargée à la demande par
    # la visionneuse : outfits/<tenue>/<race>_<sexe>.glb.
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for set_id, pieces in outfit_sets.items():
        bpy.ops.object.select_all(action="DESELECT")
        rig.select_set(True)
        for piece in pieces:
            piece.select_set(True)
        folder = os.path.join(out_dir, "outfits", set_id)
        os.makedirs(folder, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=os.path.join(folder, f"{race}_{sex}.glb"),
            export_format="GLB",
            use_selection=True,
            export_morph=True,
            export_morph_normal=False,
            export_apply=False,
            export_materials="EXPORT",
            export_texcoords=True,
            export_image_format="AUTO",
            export_yup=True,
            export_skins=True,
            export_animations=False,
            export_try_sparse_sk=True,
        )
    return path


def _fit_module():
    """Module fit_outfits.py, voisin de ce script."""
    spec = importlib.util.spec_from_file_location(
        "fit_outfits", os.path.join(os.path.dirname(os.path.abspath(__file__)), "fit_outfits.py")
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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
