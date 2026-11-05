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
from mathutils import Vector

_MPFB = "bl_ext.blender_org.mpfb.services."

SEXES = {"female": 0.0, "male": 1.0}

# Réglages de base par race (valeurs MPFB entre 0 et 1).
RACES = {
    "human": {"height": 0.5, "proportions": 0.55},
    "elf": {"height": 0.7, "proportions": 0.85},
    "orc": {"height": 0.65, "proportions": 0.35},
}

# États de morphologie : (nom de la forme, poids, musculature).
STATES = [
    ("base", 0.5, 0.5),
    ("corp_low", 0.0, 0.5),
    ("corp_high", 1.0, 0.5),
    ("musc_low", 0.5, 0.0),
    ("musc_high", 0.5, 1.0),
]

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
}


def _services():
    hs = importlib.import_module(_MPFB + "humanservice").HumanService
    return hs


def _material(name):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = COLORS[name]
    bsdf.inputs["Roughness"].default_value = 0.45 if name in ("skin", "hair", "tusk") else 0.9
    mat.use_backface_culling = False
    return mat


def _state_coords(sex, race, weight, muscle):
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


def _extract(template, keep, name, states, offset=0.0, flare=None, normal_source=None):
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
    for state_name, _, _ in STATES[1:]:
        key = obj.shape_key_add(name=state_name)
        for i, co in enumerate(positions(states[state_name])):
            key.data[i].co = co
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
    for state_name, _, _ in STATES[1:]:
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


def _clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def build(sex, race, out_dir):
    _clear_scene()
    states = {}
    groups = None
    template = None
    for state_name, weight, muscle in STATES:
        coords, membership, mesh = _state_coords(sex, race, weight, muscle)
        groups = groups or membership
        template = template or mesh
        states[state_name] = _race_deform(race, coords, groups)
    for i, co in enumerate(states["base"]):
        template.vertices[i].co = co
    mats = {name: _material(name) for name in COLORS}

    body = _extract(template, groups["body"], "body", states)
    body.data.materials.append(mats["skin"])
    eyes = groups.get("helper-l-eye", set()) | groups.get("helper-r-eye", set())
    eye_obj = _extract(template, eyes, "eyes", states)
    eye_obj.data.materials.append(mats["eyes"])

    tights = groups["helper-tights"]
    co = states["base"]
    # Seuils exprimés en fraction de la taille du corps (toutes les races).
    height = max(co[i].z for i in groups["body"])
    z = {i: co[i].z / height for i in tights}
    x = {i: abs(co[i].x) / height for i in tights}
    legs = {i for i in tights if z[i] < 0.39 or x[i] < 0.138}
    pieces = [
        ("outfit_tunic", {i for i in tights if 0.585 < z[i] < 0.86 and x[i] < 0.157}, 0.014, None, "linen"),
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
