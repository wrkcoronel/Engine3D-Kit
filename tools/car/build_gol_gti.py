import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

BODY_STATIONS = [
    (1.97, 0.70, 0.30, 0.60),
    (1.93, 0.77, 0.22, 0.65),
    (1.85, 0.81, 0.19, 0.68),
    (1.55, 0.82, 0.18, 0.76),
    (0.92, 0.82, 0.18, 0.86),
    (0.30, 0.82, 0.18, 0.87),
    (-0.60, 0.82, 0.18, 0.89),
    (-1.40, 0.82, 0.18, 0.93),
    (-1.80, 0.81, 0.19, 0.96),
    (-1.89, 0.79, 0.21, 0.95),
    (-1.94, 0.75, 0.27, 0.90),
]

WINDSHIELD_BASE_Y = 0.92
ROOF_FRONT_Y = 0.29
ROOF_REAR_Y = -1.50
HATCH_BASE_Y = -1.80
ROOF_FRONT_HEIGHT = 1.40
ROOF_REAR_HEIGHT = 1.40
DOOR_WINDOW_END_Y = -0.50
QUARTER_WINDOW_START_Y = -0.58
QUARTER_WINDOW_END_Y = -1.38
ROOF_HALF_WIDTH = 0.64

FRONT_AXLE_Y = 1.20
REAR_AXLE_Y = -1.27
TRACK_HALF = 0.70
WHEEL_RADIUS = 0.29
WHEEL_WIDTH = 0.19
ARCH_RADIUS = 0.33

NINJA_BLACK = (0.012, 0.012, 0.014, 1.0)


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj)


def make_material(name, color, metallic=0.0, roughness=0.5, emission=None):
    material = bpy.data.materials.new(name)
    if hasattr(material, "use_nodes"):
        material.use_nodes = True
    shader = material.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if emission is not None:
        shader.inputs["Emission Color"].default_value = emission
        shader.inputs["Emission Strength"].default_value = 1.5
    material.diffuse_color = color
    return material


def make_materials():
    return {
        "paint": make_material("Pintura", NINJA_BLACK, metallic=0.5, roughness=0.18),
        "chrome": make_material("Cromado", (0.8, 0.8, 0.82, 1.0), metallic=1.0, roughness=0.15),
        "reflector": make_material("Refletor", (0.45, 0.02, 0.02, 1.0), roughness=0.3),
        "glass": make_material("Vidro", (0.03, 0.05, 0.07, 1.0), roughness=0.05),
        "plastic": make_material("Plastico", (0.06, 0.06, 0.065, 1.0), roughness=0.75),
        "tire": make_material("Pneu", (0.02, 0.02, 0.02, 1.0), roughness=0.9),
        "rim": make_material("Roda", (0.7, 0.7, 0.72, 1.0), metallic=1.0, roughness=0.25),
        "headlight": make_material(
            "Farol", (0.85, 0.88, 0.9, 1.0), roughness=0.1, emission=(0.6, 0.6, 0.55, 1.0)
        ),
        "taillight": make_material(
            "Lanterna", (0.6, 0.02, 0.02, 1.0), roughness=0.2, emission=(0.4, 0.0, 0.0, 1.0)
        ),
        "indicator": make_material("Pisca", (0.9, 0.45, 0.05, 1.0), roughness=0.2),
        "plate": make_material("Placa", (0.85, 0.85, 0.85, 1.0), roughness=0.6),
    }


def interpolate_station(y, column):
    stations = sorted(BODY_STATIONS, key=lambda station: station[0])
    if y <= stations[0][0]:
        return stations[0][column]
    for lower, upper in zip(stations, stations[1:]):
        if lower[0] <= y <= upper[0]:
            fraction = (y - lower[0]) / (upper[0] - lower[0])
            return lower[column] + (upper[column] - lower[column]) * fraction
    return stations[-1][column]


def body_half_width(y):
    return interpolate_station(y, 1)


def body_top(y):
    return interpolate_station(y, 3)


def body_ring(half_width, bottom, top):
    corner = 0.12
    return [
        (-half_width + 0.06, bottom),
        (-half_width, bottom + corner),
        (-half_width, top - corner),
        (-half_width + 0.06, top),
        (half_width - 0.06, top),
        (half_width, top - corner),
        (half_width, bottom + corner),
        (half_width - 0.06, bottom),
    ]


def create_object(name, mesh_data):
    obj = bpy.data.objects.new(name, mesh_data)
    bpy.context.collection.objects.link(obj)
    return obj


def build_lower_body(materials):
    mesh = bmesh.new()
    rings = []
    for y, half_width, bottom, top in BODY_STATIONS:
        ring = [mesh.verts.new((x, y, z)) for x, z in body_ring(half_width, bottom, top)]
        rings.append(ring)
    for front_ring, back_ring in zip(rings, rings[1:]):
        count = len(front_ring)
        for index in range(count):
            following = (index + 1) % count
            mesh.faces.new(
                (front_ring[index], front_ring[following], back_ring[following], back_ring[index])
            )
    mesh.faces.new(list(reversed(rings[0])))
    mesh.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(mesh, faces=mesh.faces)
    mesh_data = bpy.data.meshes.new("Carroceria")
    mesh.to_mesh(mesh_data)
    mesh.free()
    body = create_object("Carroceria", mesh_data)
    body.data.materials.append(materials["paint"])
    return body


def roof_line(y):
    if y >= ROOF_FRONT_Y:
        fraction = (WINDSHIELD_BASE_Y - y) / (WINDSHIELD_BASE_Y - ROOF_FRONT_Y)
        base = body_top(WINDSHIELD_BASE_Y)
        return base + (ROOF_FRONT_HEIGHT - base) * fraction
    if y >= ROOF_REAR_Y:
        fraction = (ROOF_FRONT_Y - y) / (ROOF_FRONT_Y - ROOF_REAR_Y)
        return ROOF_FRONT_HEIGHT + (ROOF_REAR_HEIGHT - ROOF_FRONT_HEIGHT) * fraction
    fraction = (ROOF_REAR_Y - y) / (ROOF_REAR_Y - HATCH_BASE_Y)
    base = body_top(HATCH_BASE_Y)
    return ROOF_REAR_HEIGHT + (base - ROOF_REAR_HEIGHT) * fraction


def greenhouse_half_width(y, z):
    belt = body_top(y) - 0.01
    bottom_half_width = body_half_width(y) - 0.04
    height_fraction = (z - belt) / max(ROOF_REAR_HEIGHT - belt, 0.01)
    return bottom_half_width + (ROOF_HALF_WIDTH - bottom_half_width) * height_fraction


def build_greenhouse(materials):
    cuts = [
        WINDSHIELD_BASE_Y + 0.001,
        ROOF_FRONT_Y,
        DOOR_WINDOW_END_Y,
        QUARTER_WINDOW_START_Y,
        QUARTER_WINDOW_END_Y,
        ROOF_REAR_Y,
        HATCH_BASE_Y,
    ]
    side_glass = [True, True, False, True, False, False]
    mesh = bmesh.new()
    columns = []
    for y in cuts:
        belt = body_top(y) - 0.01
        top = max(roof_line(y), belt + 0.002)
        column = {}
        for side in (-1, 1):
            bottom_width = greenhouse_half_width(y, belt)
            top_width = greenhouse_half_width(y, top)
            column[(side, "bottom")] = mesh.verts.new((side * bottom_width, y, belt))
            column[(side, "top")] = mesh.verts.new((side * top_width, y, top))
        columns.append(column)
    glass_faces = []
    for index, (front, back) in enumerate(zip(columns, columns[1:])):
        for side in (-1, 1):
            face = mesh.faces.new(
                (front[(side, "bottom")], back[(side, "bottom")], back[(side, "top")], front[(side, "top")])
            )
            if side_glass[index]:
                glass_faces.append(face)
        mesh.faces.new((front[(-1, "top")], front[(1, "top")], back[(1, "top")], back[(-1, "top")]))
        mesh.faces.new(
            (front[(-1, "bottom")], back[(-1, "bottom")], back[(1, "bottom")], front[(1, "bottom")])
        )
    first, last = columns[0], columns[-1]
    windshield = mesh.faces.new(
        (first[(-1, "bottom")], first[(1, "bottom")], first[(1, "top")], first[(-1, "top")])
    )
    hatch = mesh.faces.new(
        (last[(-1, "bottom")], last[(-1, "top")], last[(1, "top")], last[(1, "bottom")])
    )
    bmesh.ops.recalc_face_normals(mesh, faces=mesh.faces)
    mesh.normal_update()
    mesh_data = bpy.data.meshes.new("Cabine")
    mesh_data.materials.append(materials["paint"])
    mesh_data.materials.append(materials["glass"])
    windshield_strip = [face for face in mesh.faces if _is_windshield(face)]
    hatch_strip = [face for face in mesh.faces if _is_hatch_glass(face)]
    to_glaze = glass_faces + windshield_strip + hatch_strip
    bmesh.ops.inset_individual(mesh, faces=to_glaze, thickness=0.045, depth=0.0)
    for face in to_glaze:
        face.material_index = 1
    windshield.material_index = 0
    hatch.material_index = 0
    mesh.to_mesh(mesh_data)
    mesh.free()
    return create_object("Cabine", mesh_data)


def _face_is_top(face):
    return face.normal.z > 0.3


def _is_windshield(face):
    center = face.calc_center_median()
    return _face_is_top(face) and center.y > ROOF_FRONT_Y and face.normal.y > 0.2


def _is_hatch_glass(face):
    center = face.calc_center_median()
    return _face_is_top(face) and center.y < ROOF_REAR_Y and face.normal.y < -0.2


def add_box(name, size, location, material, bevel=0.015):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    box = bpy.context.active_object
    box.name = name
    box.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    box.data.materials.append(material)
    if bevel > 0.0:
        modifier = box.modifiers.new("Chanfro", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return box


FLOOR_HEIGHT = 0.24


def hide_as_cutter(cutter):
    cutters = bpy.data.collections.get("Cortes")
    if cutters is None:
        cutters = bpy.data.collections.new("Cortes")
        bpy.context.scene.collection.children.link(cutters)
    for collection in list(cutter.users_collection):
        collection.objects.unlink(cutter)
    cutters.objects.link(cutter)
    cutter.hide_set(True)
    cutter.hide_render = True


def cut_wheel_arches(body):
    for axle_y in (FRONT_AXLE_Y, REAR_AXLE_Y):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=ARCH_RADIUS, depth=2.4, vertices=32, location=(0.0, axle_y, WHEEL_RADIUS)
        )
        cutter = bpy.context.active_object
        cutter.name = "CorteRoda"
        cutter.rotation_euler = (0.0, math.radians(90.0), 0.0)
        hide_as_cutter(cutter)
        boolean = body.modifiers.new("CaixaDeRoda", "BOOLEAN")
        boolean.operation = "DIFFERENCE"
        boolean.object = cutter


def build_wheel_well_liners(materials):
    liner_length = 2.0 * TRACK_HALF - WHEEL_WIDTH - 0.02
    keep_height = 1.0 - FLOOR_HEIGHT
    for axle_y in (FRONT_AXLE_Y, REAR_AXLE_Y):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=ARCH_RADIUS - 0.005, depth=liner_length, vertices=32,
            location=(0.0, axle_y, WHEEL_RADIUS),
        )
        liner = bpy.context.active_object
        liner.name = "ForroCaixaDeRoda"
        liner.rotation_euler = (0.0, math.radians(90.0), 0.0)
        liner.data.materials.append(materials["tire"])
        bpy.ops.mesh.primitive_cube_add(
            size=1.0, location=(0.0, axle_y, FLOOR_HEIGHT + keep_height / 2.0)
        )
        above_floor = bpy.context.active_object
        above_floor.name = "AcimaDoAssoalho"
        above_floor.scale = (liner_length + 0.2, 2.0 * ARCH_RADIUS + 0.2, keep_height)
        hide_as_cutter(above_floor)
        keep_above_floor = liner.modifiers.new("SoAcimaDoAssoalho", "BOOLEAN")
        keep_above_floor.operation = "INTERSECT"
        keep_above_floor.object = above_floor


def build_wheel(name, location, materials, side):
    wheel = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(wheel)
    wheel.location = location
    bpy.ops.mesh.primitive_cylinder_add(radius=WHEEL_RADIUS, depth=WHEEL_WIDTH, vertices=28)
    tire = bpy.context.active_object
    tire.name = name + "_Pneu"
    tire.rotation_euler = (0.0, math.radians(90.0), 0.0)
    tire.data.materials.append(materials["tire"])
    tire.parent = wheel
    rim_face_x = side * (WHEEL_WIDTH / 2.0)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.20, depth=0.03, vertices=24)
    rim = bpy.context.active_object
    rim.name = name + "_Aro"
    rim.rotation_euler = (0.0, math.radians(90.0), 0.0)
    rim.location = (rim_face_x, 0.0, 0.0)
    rim.data.materials.append(materials["plastic"])
    rim.parent = wheel
    for spoke_index in range(5):
        angle = math.radians(72.0 * spoke_index)
        spoke_center = Vector((0.0, math.cos(angle), math.sin(angle))) * 0.10
        spoke = add_box(
            name + "_Raio", (0.035, 0.18, 0.10), (0.0, 0.0, 0.0), materials["rim"], bevel=0.01
        )
        spoke.location = (rim_face_x + side * 0.015, spoke_center.y, spoke_center.z)
        spoke.rotation_euler = (angle, 0.0, 0.0)
        spoke.parent = wheel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.20, depth=0.02, vertices=24)
    rim_ring = bpy.context.active_object
    rim_ring.name = name + "_Borda"
    rim_ring.rotation_euler = (0.0, math.radians(90.0), 0.0)
    rim_ring.location = (rim_face_x + side * 0.012, 0.0, 0.0)
    rim_ring.data.materials.append(materials["rim"])
    rim_ring.parent = wheel
    hub = add_box(name + "_Cubo", (0.05, 0.07, 0.07), (0.0, 0.0, 0.0), materials["rim"], 0.02)
    hub.location = (rim_face_x + side * 0.03, 0.0, 0.0)
    hub.parent = wheel
    return wheel


BUMPER_CENTER_HEIGHT = 0.40
BUMPER_HEIGHT = 0.30
FRONT_LIGHT_HEIGHT = 0.585
FRONT_LIGHT_TILT = math.radians(15.0)


def add_disc(name, location, radius, depth, rotation, material):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=20, location=location)
    disc = bpy.context.active_object
    disc.name = name
    disc.rotation_euler = rotation
    disc.data.materials.append(material)
    return disc


def build_bumper(name, center_y, direction, materials):
    add_box(
        name, (1.68, 0.20, BUMPER_HEIGHT), (0.0, center_y, BUMPER_CENTER_HEIGHT),
        materials["paint"], 0.08,
    )
    wrap_center_y = center_y - direction * 0.18
    for side in (-1, 1):
        add_box(
            name + "Lateral", (0.06, 0.36, BUMPER_HEIGHT),
            (side * 0.81, wrap_center_y, BUMPER_CENTER_HEIGHT), materials["paint"], 0.03,
        )
    lip_y = center_y + direction * 0.05
    add_box(name + "Labio", (1.62, 0.12, 0.05), (0.0, lip_y, 0.255), materials["plastic"], 0.01)


def build_headlight(side, materials):
    center_x = side * 0.47
    housing = add_box(
        "Farol", (0.37, 0.05, 0.13), (center_x, 1.945, FRONT_LIGHT_HEIGHT), materials["plastic"], 0.035
    )
    housing.rotation_euler = (FRONT_LIGHT_TILT, 0.0, 0.0)
    lens_rotation = (math.radians(90.0) + FRONT_LIGHT_TILT, 0.0, 0.0)
    for lens_offset in (-0.085, 0.085):
        add_disc(
            "FarolLente", (center_x + lens_offset, 1.974, FRONT_LIGHT_HEIGHT + 0.008), 0.05, 0.012,
            lens_rotation, materials["headlight"],
        )


def build_grille(materials):
    grille_back = add_box(
        "Grade", (0.46, 0.04, 0.11), (0.0, 1.955, FRONT_LIGHT_HEIGHT), materials["plastic"], 0.02
    )
    grille_back.rotation_euler = (FRONT_LIGHT_TILT, 0.0, 0.0)
    for slat_height in (0.02, -0.02):
        slat = add_box(
            "GradeFriso", (0.44, 0.03, 0.012), (0.0, 1.97, FRONT_LIGHT_HEIGHT + slat_height),
            materials["chrome"], 0.0,
        )
        slat.rotation_euler = (FRONT_LIGHT_TILT, 0.0, 0.0)


def build_front(materials):
    build_bumper("ParachoqueDianteiro", 1.93, 1, materials)
    build_grille(materials)
    for side in (-1, 1):
        build_headlight(side, materials)
        add_box("Neblina", (0.14, 0.02, 0.06), (side * 0.62, 2.032, 0.33), materials["headlight"])
    add_box("EntradaDeAr", (0.90, 0.02, 0.06), (0.0, 2.032, 0.33), materials["plastic"], 0.0)
    add_box("PlacaDianteira", (0.40, 0.02, 0.11), (0.0, 2.036, 0.45), materials["plate"], 0.0)


def build_rear(materials):
    build_bumper("ParachoqueTraseiro", -1.93, -1, materials)
    for side in (-1, 1):
        add_box(
            "Lanterna", (0.30, 0.15, 0.19), (side * 0.63, -1.865, 0.86), materials["taillight"], 0.03
        )
        add_box(
            "LanternaFaixa", (0.30, 0.152, 0.10), (side * 0.63, -1.865, 0.715),
            materials["reflector"], 0.03,
        )
    add_box("RefletorTraseiro", (0.10, 0.02, 0.05), (-0.55, -2.032, 0.33), materials["reflector"])
    add_box("PlacaTraseira", (0.40, 0.02, 0.11), (0.0, -2.036, 0.44), materials["plate"], 0.0)
    wiper = add_box("Limpador", (0.42, 0.02, 0.02), (0.05, -1.755, 1.05), materials["plastic"], 0.0)
    wiper.rotation_euler = (math.radians(-55.0), 0.0, 0.0)
    add_disc(
        "Escapamento", (0.42, -2.0, 0.22), 0.035, 0.16, (math.radians(90.0), 0.0, 0.0),
        materials["chrome"],
    )


def build_sides(materials):
    strip_center_y = -0.04
    strip_length = 1.68
    for side in (-1, 1):
        add_box(
            "FrisoProtecao", (0.03, strip_length, 0.07), (side * 0.825, strip_center_y, 0.50),
            materials["paint"], 0.01,
        )
        add_box(
            "FrisoLinha", (0.034, strip_length, 0.012), (side * 0.826, strip_center_y, 0.50),
            materials["plastic"], 0.0,
        )
        add_box("Soleira", (0.03, 1.70, 0.05), (side * 0.81, strip_center_y, 0.235), materials["plastic"])
        add_box("Retrovisor", (0.13, 0.08, 0.10), (side * 0.86, 0.84, 0.93), materials["paint"], 0.03)
        add_box("Macaneta", (0.02, 0.13, 0.03), (side * 0.825, -0.35, 0.80), materials["plastic"], 0.0)


def build_roof_details(materials):
    sunroof_center_y = -0.40
    add_box(
        "TetoSolar", (0.62, 0.62, 0.012), (0.0, sunroof_center_y, roof_line(sunroof_center_y) + 0.006),
        materials["glass"], 0.0,
    )
    add_box(
        "Aerofolio", (1.10, 0.20, 0.04), (0.0, ROOF_REAR_Y - 0.02, roof_line(ROOF_REAR_Y) + 0.01),
        materials["paint"], 0.015,
    )
    brake_light_y = ROOF_REAR_Y - 0.08
    add_box(
        "LuzDeFreio", (0.24, 0.03, 0.03), (0.0, brake_light_y, roof_line(brake_light_y) + 0.005),
        materials["taillight"], 0.0,
    )
    antenna_base_y = -1.30
    antenna_length = 0.55
    antenna_tilt = math.radians(30.0)
    half_length = antenna_length / 2.0
    antenna_center = (
        0.0,
        antenna_base_y - math.sin(antenna_tilt) * half_length,
        roof_line(antenna_base_y) + math.cos(antenna_tilt) * half_length,
    )
    add_disc("Antena", antenna_center, 0.006, antenna_length, (antenna_tilt, 0.0, 0.0), materials["plastic"])


def build_details(materials):
    build_front(materials)
    build_rear(materials)
    build_sides(materials)
    build_roof_details(materials)


def add_subdivision(obj, levels):
    subdivision = obj.modifiers.new("Arredondar", "SUBSURF")
    subdivision.levels = levels
    subdivision.render_levels = levels


def smooth(obj):
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    try:
        with bpy.context.temp_override(object=obj, active_object=obj, selected_objects=[obj]):
            bpy.ops.object.shade_auto_smooth(angle=math.radians(40.0))
    except RuntimeError as error:
        print("suavizacao automatica indisponivel:", error)


def group_into_chassis():
    cutters = bpy.data.collections.get("Cortes")
    loose_parts = [
        obj for obj in bpy.context.scene.objects
        if obj.parent is None and (cutters is None or obj.name not in cutters.objects)
    ]
    chassis = bpy.data.objects.new("Chassis", None)
    bpy.context.collection.objects.link(chassis)
    chassis.location = (0.0, 0.0, WHEEL_RADIUS)
    bpy.context.view_layer.update()
    for part in loose_parts:
        part.parent = chassis
        part.matrix_parent_inverse = chassis.matrix_world.inverted()


def build_car():
    clear_scene()
    materials = make_materials()
    body = build_lower_body(materials)
    add_subdivision(body, 2)
    cut_wheel_arches(body)
    cabin = build_greenhouse(materials)
    cabin_bevel = cabin.modifiers.new("Chanfro", "BEVEL")
    cabin_bevel.width = 0.035
    cabin_bevel.segments = 3
    build_wheel_well_liners(materials)
    smooth(body)
    smooth(cabin)
    build_details(materials)
    group_into_chassis()
    axles = {"F": FRONT_AXLE_Y, "B": REAR_AXLE_Y}
    for axle_letter, axle_y in axles.items():
        build_wheel("Wheel%sL" % axle_letter, (-TRACK_HALF, axle_y, WHEEL_RADIUS), materials, -1)
        build_wheel("Wheel%sR" % axle_letter, (TRACK_HALF, axle_y, WHEEL_RADIUS), materials, 1)


def add_camera(name, location, rotation_degrees, orthographic_scale=None):
    camera_data = bpy.data.cameras.new(name)
    if orthographic_scale is not None:
        camera_data.type = "ORTHO"
        camera_data.ortho_scale = orthographic_scale
    camera = bpy.data.objects.new(name, camera_data)
    camera.location = location
    camera.rotation_euler = [math.radians(angle) for angle in rotation_degrees]
    bpy.context.scene.collection.objects.link(camera)
    return camera


def render_views(output_folder):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_cavity = True
    scene.display.shading.background_type = "VIEWPORT"
    scene.display.shading.background_color = (0.72, 0.72, 0.74)
    scene.render.resolution_x = 900
    scene.render.resolution_y = 500
    views = {
        "frente_reta": add_camera("CamFrenteReta", (0.0, 7.0, 0.8), (90.0, 0.0, 180.0), 2.4),
        "frente": add_camera("CamFrente", (3.0, 5.0, 1.3), (83.0, 0.0, 149.0)),
        "lado": add_camera("CamLado", (-8.0, 0.0, 0.75), (90.0, 0.0, -90.0), 4.6),
        "tras": add_camera("CamTras", (-3.0, -5.2, 1.6), (80.5, 0.0, -30.0)),
        "baixo": add_camera("CamBaixo", (-3.2, 4.6, -0.9), (108.0, 0.0, -145.0)),
    }
    for view_name, camera in views.items():
        scene.camera = camera
        scene.render.filepath = str(Path(output_folder) / ("gol_%s.png" % view_name))
        bpy.ops.render.render(write_still=True)


def export(model_path, blend_path):
    bpy.ops.export_scene.gltf(
        filepath=str(model_path),
        export_format="GLB",
        use_visible=True,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
    )
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))


def main():
    arguments = sys.argv[sys.argv.index("--") + 1 :]
    project_folder = Path(arguments[0])
    render_folder = arguments[1] if len(arguments) > 1 else None
    build_car()
    model_path = project_folder / "contexts" / "vehicles" / "models" / "gol_gti.glb"
    blend_path = project_folder / "tools" / "car" / "gol_gti.blend"
    model_path.parent.mkdir(parents=True, exist_ok=True)
    export(model_path, blend_path)
    if render_folder:
        render_views(render_folder)


main()
