class_name GrassChunk
extends Node3D

var cell := Vector2i.ZERO
var level := GrassStreamer.NEAR_LEVEL


func plant(clump_mesh: ArrayMesh, transforms: Array[Transform3D], material: ShaderMaterial) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = clump_mesh
	multimesh.instance_count = transforms.size()
	for instance_index: int in transforms.size():
		multimesh.set_instance_transform(instance_index, transforms[instance_index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.extra_cull_margin = 1.0
	add_child(instance)


func clump_count() -> int:
	var total := 0
	for child: Node in get_children():
		var instance := child as MultiMeshInstance3D
		if instance != null:
			total += instance.multimesh.instance_count
	return total
