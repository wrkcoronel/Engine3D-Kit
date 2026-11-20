import json

import bpy
from mathutils import Matrix

ROOT_PATH = "."
ROOT_BONE = "Raiz"
SKELETON_NAME = "Esqueleto"
BONE_LENGTH = 0.02
VISIBLE_INDEX = 12
HIDDEN_SCALE = 0.0001
FIRST_FRAME = 1
FIRST_ANIMATION = "tiro"


def godot_axes_matrix(values):
    columns = [values[0:3], values[3:6], values[6:9]]
    origin = values[9:12]
    matrix = Matrix.Identity(4)
    for column_index in range(3):
        for row_index in range(3):
            matrix[row_index][column_index] = columns[column_index][row_index]
        matrix[column_index][3] = origin[column_index]
    return matrix


def bone_name(godot_path):
    if godot_path == ROOT_PATH:
        return ROOT_BONE
    return godot_path


def path_chain(godot_path):
    if godot_path == ROOT_PATH:
        return [ROOT_PATH]
    parts = godot_path.split("/")
    chain = [ROOT_PATH]
    for part_count in range(1, len(parts) + 1):
        chain.append("/".join(parts[:part_count]))
    return chain


class WeaponSkeleton:
    def __init__(self, collection, to_blender):
        self.collection = collection
        self.to_blender = to_blender
        self.objects_by_path = {}
        self.rest_locals = {}
        for blender_object in collection.all_objects:
            godot_path = blender_object.get("godot_path")
            if godot_path is not None:
                self.objects_by_path[godot_path] = blender_object
                self.rest_locals[godot_path] = blender_object.matrix_basis.copy()
        self.armature_object = None
        self.animated_paths = []

    def add_animations(self, recording):
        bpy.context.scene.render.fps = recording["fps"]
        self.animated_paths = self._animated_paths(recording)
        self._build_armature()
        self._attach_parts_to_bones()
        actions = [self._add_action(animation) for animation in recording["animations"]]
        self._show_action(actions)

    def _animated_paths(self, recording):
        first_frame = recording["animations"][0]["frames"][0]
        return [path for path in first_frame.keys() if path in self.objects_by_path]

    def _rest_matrix(self, godot_path):
        return self._space_matrix(godot_path, {})

    def _space_matrix(self, godot_path, frame_states):
        matrix = Matrix.Identity(4)
        for link_path in path_chain(godot_path):
            matrix = matrix @ self._local_matrix(link_path, frame_states)
        return matrix

    def _local_matrix(self, godot_path, frame_states):
        state = frame_states.get(godot_path)
        if state is None:
            return self.rest_locals[godot_path]
        return self.to_blender(godot_axes_matrix(state))

    def _build_armature(self):
        armature_data = bpy.data.armatures.new(SKELETON_NAME)
        self.armature_object = bpy.data.objects.new(SKELETON_NAME, armature_data)
        self.collection.objects.link(self.armature_object)
        bpy.context.view_layer.objects.active = self.armature_object
        self.armature_object.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        for godot_path in self.animated_paths:
            edit_bone = armature_data.edit_bones.new(bone_name(godot_path))
            edit_bone.head = (0.0, 0.0, 0.0)
            edit_bone.tail = (0.0, BONE_LENGTH, 0.0)
            edit_bone.matrix = without_scale(self._rest_matrix(godot_path))
        bpy.ops.object.mode_set(mode="OBJECT")

    def _attach_parts_to_bones(self):
        bpy.context.view_layer.update()
        for godot_path in self.animated_paths:
            part = self.objects_by_path[godot_path]
            rest_world = self._rest_matrix(godot_path)
            part.parent = self.armature_object
            part.parent_type = "BONE"
            part.parent_bone = bone_name(godot_path)
            part.matrix_parent_inverse = Matrix.Identity(4)
            bpy.context.view_layer.update()
            part.matrix_world = rest_world
            part.hide_set(False)
            part.hide_render = False

    def _add_action(self, animation):
        action = bpy.data.actions.new(animation["name"])
        action.use_fake_user = True
        self.armature_object.animation_data_create()
        self.armature_object.animation_data.action = action
        frame = FIRST_FRAME
        for frame_states in animation["frames"]:
            for godot_path in self.animated_paths:
                self._key_bone(godot_path, frame_states, frame)
            frame += 1
        action.use_frame_range = True
        action.frame_start = FIRST_FRAME
        action.frame_end = frame - 1
        return action

    def _key_bone(self, godot_path, frame_states, frame):
        rest_world = self._rest_matrix(godot_path)
        rest_bone = without_scale(rest_world)
        moved_world = self._space_matrix(godot_path, frame_states)
        change = moved_world @ rest_world.inverted()
        bone_basis = rest_bone.inverted() @ change @ rest_bone
        if not self._is_visible(godot_path, frame_states):
            bone_basis = bone_basis @ Matrix.Scale(HIDDEN_SCALE, 4)
        pose_bone = self.armature_object.pose.bones[bone_name(godot_path)]
        location, rotation, scale = bone_basis.decompose()
        rotation.make_compatible(pose_bone.rotation_quaternion)
        pose_bone.location = location
        pose_bone.rotation_quaternion = rotation
        pose_bone.scale = scale
        for property_name in ("location", "rotation_quaternion", "scale"):
            pose_bone.keyframe_insert(property_name, frame=frame)

    def _is_visible(self, godot_path, frame_states):
        for link_path in path_chain(godot_path):
            state = frame_states.get(link_path)
            if state is not None and state[VISIBLE_INDEX] < 0.5:
                return False
        return True

    def _show_action(self, actions):
        shown = actions[0]
        for action in actions:
            if action.name == FIRST_ANIMATION:
                shown = action
        self.armature_object.animation_data.action = shown
        scene = bpy.context.scene
        scene.frame_start = int(shown.frame_start)
        scene.frame_end = int(shown.frame_end)
        scene.frame_set(FIRST_FRAME)


def without_scale(matrix):
    location, rotation, _scale = matrix.decompose()
    return Matrix.LocRotScale(location, rotation, None)


def add_animations(animations_path, collection, to_blender):
    recording = json.loads(animations_path.read_text(encoding="utf-8"))
    WeaponSkeleton(collection, to_blender).add_animations(recording)
