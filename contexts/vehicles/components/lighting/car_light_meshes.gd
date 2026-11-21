class_name CarLightMeshes
extends RefCounted


static func find_by_names(root: Node, mesh_names: Array[String]) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	_collect(root, mesh_names, found)
	return found


static func own_materials(meshes: Array[MeshInstance3D]) -> Array[StandardMaterial3D]:
	var materials: Array[StandardMaterial3D] = []
	for mesh: MeshInstance3D in meshes:
		var shared_material := mesh.get_active_material(0) as StandardMaterial3D
		if shared_material == null:
			continue
		var own_material := shared_material.duplicate() as StandardMaterial3D
		mesh.set_surface_override_material(0, own_material)
		materials.append(own_material)
	return materials


static func _collect(node: Node, mesh_names: Array[String], found: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and mesh_names.has(String(mesh.name)):
			found.append(mesh)
		_collect(child, mesh_names, found)
