import sys
from pathlib import Path

import bpy
from mathutils import Matrix

GODOT_TO_BLENDER = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
BLENDER_TO_GODOT = GODOT_TO_BLENDER.inverted()


def mesh_objects_by_file():
    by_file = {}
    for blender_object in bpy.data.objects:
        mesh_res = blender_object.get("godot_mesh")
        if mesh_res is None:
            continue
        if mesh_res not in by_file:
            by_file[mesh_res] = blender_object
    return by_file


def export_local_mesh(blender_object, target_file):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = blender_object.evaluated_get(depsgraph)
    local_mesh = bpy.data.meshes.new_from_object(evaluated)
    local_mesh.materials.clear()
    local_mesh.transform(BLENDER_TO_GODOT)
    temporary_object = bpy.data.objects.new(target_file.stem, local_mesh)
    bpy.context.scene.collection.objects.link(temporary_object)
    temporary_object.matrix_world = Matrix.Identity(4)
    bpy.ops.object.select_all(action="DESELECT")
    temporary_object.select_set(True)
    bpy.context.view_layer.objects.active = temporary_object
    target_file.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.obj_export(
        filepath=str(target_file),
        export_selected_objects=True,
        forward_axis="Y",
        up_axis="Z",
        export_materials=False,
        export_uv=True,
        export_normals=True,
        apply_modifiers=True,
    )
    bpy.data.objects.remove(temporary_object)
    bpy.data.meshes.remove(local_mesh)


def main():
    arguments = sys.argv[sys.argv.index("--") + 1 :]
    project_folder = Path(arguments[0])
    output_folder = project_folder
    if len(arguments) > 1:
        output_folder = Path(arguments[1])
    for mesh_res, blender_object in mesh_objects_by_file().items():
        target_file = output_folder / mesh_res.replace("res://", "")
        export_local_mesh(blender_object, target_file)
        print("malha exportada:", target_file)


main()
