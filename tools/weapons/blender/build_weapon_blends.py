import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

sys.path.append(str(Path(__file__).resolve().parent))

from godot_scene_reader import GodotScene, numbers, read_material, res_to_file, resource_reference
from weapon_animation_keys import add_animations, godot_axes_matrix

WEAPON_SCENES = {
    "pistol_1911": "contexts/weapons/models/pistol_1911/pistol_1911.tscn",
    "boito_pump": "contexts/weapons/models/boito_pump/boito_pump.tscn",
    "carbine_22": "contexts/weapons/models/carbine_22/carbine_22.tscn",
    "hunting_rifle": "contexts/weapons/models/hunting_rifle/hunting_rifle.tscn",
}
GODOT_TO_BLENDER = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
BLENDER_TO_GODOT = GODOT_TO_BLENDER.inverted()
NODES_WITHOUT_SPACE = {"SubViewport", "AudioStreamPlayer", "Node"}
EMPTY_LOOK = {"Marker3D": "ARROWS", "Node3D": "PLAIN_AXES", "Camera3D": "CONE"}
FALLBACK_COLOR = (0.8, 0.8, 0.8, 1.0)


class WeaponBlendBuilder:
    def __init__(self, project_folder):
        self.project_folder = Path(project_folder)
        self.imported_meshes = {}
        self.materials = {}
        self.scenes = {}
        self.hidden_objects = []

    def build(self, weapon_name, scene_res_path):
        clear_file()
        self.imported_meshes.clear()
        self.materials.clear()
        collection = bpy.data.collections.new(weapon_name)
        bpy.context.scene.collection.children.link(collection)
        scene = self._scene(self.project_folder / scene_res_path)
        self.hidden_objects = []
        root_object = self._build_node(scene, scene.root(), None, collection, {}, ".")
        root_object["godot_scene"] = scene_res_path
        bpy.context.view_layer.update()
        for hidden_object in self.hidden_objects:
            hidden_object.hide_set(True)
            hidden_object.hide_render = True
        return collection

    def _scene(self, scene_file):
        key = str(scene_file)
        if key not in self.scenes:
            self.scenes[key] = GodotScene(scene_file)
        return self.scenes[key]

    def _build_node(self, scene, node, parent_object, collection, overrides, godot_path):
        properties = dict(node.properties)
        properties.update(overrides)
        if node.node_type in NODES_WITHOUT_SPACE:
            return None
        blender_object = self._object_for(scene, node, properties)
        collection.objects.link(blender_object)
        blender_object.parent = parent_object
        blender_object.matrix_parent_inverse = Matrix.Identity(4)
        blender_object.matrix_basis = to_blender(godot_local_matrix(properties))
        remember_godot_details(blender_object, node, properties)
        blender_object["godot_path"] = godot_path
        for child in scene.children_of(node):
            child_path = child_godot_path(godot_path, child.name)
            self._build_child(scene, child, blender_object, collection, child_path)
        if properties.get("visible") == "false":
            self.hidden_objects.append(blender_object)
        return blender_object

    def _build_child(self, scene, child, parent_object, collection, child_path):
        if child.instance_id is None:
            self._build_node(scene, child, parent_object, collection, {}, child_path)
            return
        instance_res = scene.external_resources[child.instance_id]["path"]
        instance_scene = self._scene(res_to_file(self.project_folder, instance_res))
        instance_root = instance_scene.root()
        instance_root_name = instance_root.name
        instance_root.name = child.name
        built = self._build_node(
            instance_scene, instance_root, parent_object, collection, child.properties, child_path
        )
        instance_root.name = instance_root_name
        built["godot_instance"] = instance_res

    def _object_for(self, scene, node, properties):
        if "mesh" in properties:
            mesh_data, mesh_source = self._mesh(scene, properties["mesh"])
            blender_object = bpy.data.objects.new(node.name, mesh_data)
            blender_object[mesh_source[0]] = mesh_source[1]
            self._assign_material(scene, blender_object, properties)
            return blender_object
        if node.node_type == "OmniLight3D":
            light = bpy.data.lights.new(node.name, "POINT")
            light.energy = float(properties.get("light_energy", "1")) * 10.0
            return bpy.data.objects.new(node.name, light)
        blender_object = bpy.data.objects.new(node.name, None)
        blender_object.empty_display_type = EMPTY_LOOK.get(node.node_type, "PLAIN_AXES")
        blender_object.empty_display_size = 0.02
        return blender_object

    def _mesh(self, scene, mesh_value):
        kind, resource_id = resource_reference(mesh_value)
        if kind == "ExtResource":
            mesh_res = scene.external_resources[resource_id]["path"]
            return self._imported_mesh(mesh_res), ("godot_mesh", mesh_res)
        description = scene.sub_resources[resource_id]
        return primitive_mesh(resource_id, description), ("godot_primitive", description["type"])

    def _imported_mesh(self, mesh_res):
        if mesh_res in self.imported_meshes:
            return self.imported_meshes[mesh_res]
        mesh_file = res_to_file(self.project_folder, mesh_res)
        before = set(bpy.data.objects)
        bpy.ops.wm.obj_import(filepath=str(mesh_file), forward_axis="Y", up_axis="Z")
        imported = [obj for obj in bpy.data.objects if obj not in before]
        mesh_data = imported[0].data
        mesh_data.name = mesh_file.stem
        mesh_data.transform(GODOT_TO_BLENDER)
        for temporary_object in imported:
            bpy.data.objects.remove(temporary_object)
        mesh_data.materials.clear()
        self.imported_meshes[mesh_res] = mesh_data
        return mesh_data

    def _assign_material(self, scene, blender_object, properties):
        material_value = properties.get("material_override")
        if material_value is None:
            material_value = properties.get("surface_material_override/0")
        if material_value is None:
            return
        kind, resource_id = resource_reference(material_value)
        if kind != "ExtResource":
            return
        material_res = scene.external_resources[resource_id]["path"]
        if len(blender_object.data.materials) == 0:
            blender_object.data.materials.append(None)
        blender_object.material_slots[0].link = "OBJECT"
        blender_object.material_slots[0].material = self._material(material_res)
        blender_object["godot_material"] = material_res

    def _material(self, material_res):
        if material_res in self.materials:
            return self.materials[material_res]
        description = read_material(res_to_file(self.project_folder, material_res))
        material = bpy.data.materials.new(description["name"])
        material.use_nodes = True
        shader = material.node_tree.nodes.get("Principled BSDF")
        color = color_from(description.get("albedo_color"))
        shader.inputs["Base Color"].default_value = color
        shader.inputs["Metallic"].default_value = float(description.get("metallic", "0"))
        shader.inputs["Roughness"].default_value = float(description.get("roughness", "1"))
        material.diffuse_color = color
        self.materials[material_res] = material
        return material


def clear_file():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def godot_local_matrix(properties):
    if "transform" in properties:
        return godot_axes_matrix(numbers(properties["transform"]))
    position = Vector(numbers(properties.get("position", "Vector3(0, 0, 0)")))
    rotation = numbers(properties.get("rotation", "Vector3(0, 0, 0)"))
    scale = numbers(properties.get("scale", "Vector3(1, 1, 1)"))
    turn = Euler(rotation, "YXZ").to_matrix().to_4x4()
    stretch = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    return Matrix.Translation(position) @ turn @ stretch


def child_godot_path(parent_path, child_name):
    if parent_path == ".":
        return child_name
    return parent_path + "/" + child_name


def to_blender(godot_matrix):
    return GODOT_TO_BLENDER @ godot_matrix @ BLENDER_TO_GODOT


def remember_godot_details(blender_object, node, properties):
    blender_object["godot_type"] = node.node_type
    for key, value in properties.items():
        if key.startswith("metadata/"):
            blender_object["godot_" + key.replace("/", "_")] = value


def color_from(color_text):
    if color_text is None:
        return FALLBACK_COLOR
    values = numbers(color_text)
    if len(values) == 3:
        values.append(1.0)
    return tuple(values)


def primitive_mesh(name, description):
    mesh_data = bpy.data.meshes.new(name)
    shape = bmesh.new()
    primitive_type = description["type"]
    if primitive_type == "CylinderMesh":
        add_cylinder(shape, description)
    elif primitive_type == "SphereMesh":
        add_sphere(shape, description)
    elif primitive_type == "BoxMesh":
        add_box(shape, description)
    shape.to_mesh(mesh_data)
    shape.free()
    return mesh_data


def add_cylinder(shape, description):
    bmesh.ops.create_cone(
        shape,
        cap_ends=True,
        segments=int(float(description.get("radial_segments", "64"))),
        radius1=float(description.get("bottom_radius", "0.5")),
        radius2=float(description.get("top_radius", "0.5")),
        depth=float(description.get("height", "2")),
    )


def add_sphere(shape, description):
    radius = float(description.get("radius", "0.5"))
    height = float(description.get("height", "1"))
    bmesh.ops.create_uvsphere(shape, u_segments=32, v_segments=16, radius=radius)
    squash = height / (2.0 * radius)
    bmesh.ops.scale(shape, vec=Vector((1.0, 1.0, squash)), verts=shape.verts)


def add_box(shape, description):
    size = numbers(description.get("size", "Vector3(1, 1, 1)"))
    bmesh.ops.create_cube(shape, size=1.0)
    blender_size = Vector((size[0], size[2], size[1]))
    bmesh.ops.scale(shape, vec=blender_size, verts=shape.verts)


def main():
    arguments = sys.argv[sys.argv.index("--") + 1 :]
    project_folder = Path(arguments[0])
    weapons_tools = project_folder / "tools" / "weapons"
    output_folder = weapons_tools / "blends"
    animations_folder = weapons_tools / "animations"
    output_folder.mkdir(parents=True, exist_ok=True)
    builder = WeaponBlendBuilder(project_folder)
    for weapon_name, scene_res_path in WEAPON_SCENES.items():
        collection = builder.build(weapon_name, scene_res_path)
        animations_path = animations_folder / (weapon_name + "_animations.json")
        if animations_path.exists():
            add_animations(animations_path, collection, to_blender)
        blend_path = output_folder / (weapon_name + ".blend")
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
        print("arma convertida:", blend_path, len(bpy.data.objects), "objetos")


main()
