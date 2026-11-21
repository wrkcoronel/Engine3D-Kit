class_name GrassClearing
extends RefCounted

const WORLD_TO_LOCAL := "vehicle_world_to_local"
const HALF_SIZE := "vehicle_half_size"
const ACTIVE := "vehicle_active"


static func follow(
	material: ShaderMaterial, vehicle_transform: Transform3D, half_size: Vector2
) -> void:
	material.set_shader_parameter(WORLD_TO_LOCAL, vehicle_transform.affine_inverse())
	material.set_shader_parameter(HALF_SIZE, half_size)
	material.set_shader_parameter(ACTIVE, 1.0)


static func release(material: ShaderMaterial) -> void:
	material.set_shader_parameter(ACTIVE, 0.0)
