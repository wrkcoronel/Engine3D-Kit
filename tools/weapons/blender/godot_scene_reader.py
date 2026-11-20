import re
from pathlib import Path

SECTION_PATTERN = re.compile(r"^\[(\w+)(.*)\]$")
ATTRIBUTE_PATTERN = re.compile(r'(\w+)=("[^"]*"|\S+)')
RESOURCE_CALL_PATTERN = re.compile(r'^(ExtResource|SubResource)\("([^"]+)"\)$')
NUMBER_LIST_PATTERN = re.compile(r"^\w+\((.*)\)$")


class GodotNode:
    def __init__(self, name, node_type, parent_path, instance_id):
        self.name = name
        self.node_type = node_type
        self.parent_path = parent_path
        self.instance_id = instance_id
        self.properties = {}

    def path(self):
        if self.parent_path is None:
            return "."
        if self.parent_path == ".":
            return self.name
        return self.parent_path + "/" + self.name


class GodotScene:
    def __init__(self, scene_path):
        self.scene_path = Path(scene_path)
        self.external_resources = {}
        self.sub_resources = {}
        self.nodes = []
        self._read()

    def root(self):
        return self.nodes[0]

    def children_of(self, node):
        node_path = node.path()
        return [child for child in self.nodes if child.parent_path == node_path]

    def _read(self):
        current_properties = None
        for raw_line in self.scene_path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            section = SECTION_PATTERN.match(line)
            if section:
                current_properties = self._start_section(section.group(1), section.group(2))
                continue
            if current_properties is None or " = " not in line:
                continue
            key, value = line.split(" = ", 1)
            current_properties[key] = value

    def _start_section(self, section_kind, attribute_text):
        attributes = dict(
            (key, value.strip('"')) for key, value in ATTRIBUTE_PATTERN.findall(attribute_text)
        )
        if section_kind == "ext_resource":
            self.external_resources[attributes["id"]] = attributes
            return None
        if section_kind == "sub_resource":
            sub_resource = {"type": attributes["type"]}
            self.sub_resources[attributes["id"]] = sub_resource
            return sub_resource
        if section_kind == "node":
            node = GodotNode(
                attributes["name"],
                attributes.get("type", "Node3D"),
                attributes.get("parent"),
                _instance_id(attributes.get("instance")),
            )
            self.nodes.append(node)
            return node.properties
        return None


def _instance_id(instance_text):
    if instance_text is None:
        return None
    reference = RESOURCE_CALL_PATTERN.match(instance_text)
    return reference.group(2)


def resource_reference(value):
    reference = RESOURCE_CALL_PATTERN.match(value)
    if reference is None:
        return None, None
    return reference.group(1), reference.group(2)


def numbers(value):
    inside = NUMBER_LIST_PATTERN.match(value)
    if inside is None:
        return [float(value)]
    return [float(part) for part in inside.group(1).split(",")]


def res_to_file(project_folder, res_path):
    return Path(project_folder) / res_path.replace("res://", "")


def read_material(material_file):
    material = {"type": "StandardMaterial3D", "albedo_color": "Color(0.8, 0.8, 0.8, 1)"}
    material["name"] = material_file.stem
    for raw_line in material_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("[gd_resource"):
            material["type"] = ATTRIBUTE_PATTERN.findall(line)[0][1].strip('"')
        if " = " in line:
            key, value = line.split(" = ", 1)
            material[key] = value
    return material
