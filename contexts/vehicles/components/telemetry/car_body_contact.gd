class_name CarBodyContact
extends RefCounted

var collider: Node
var shape_node: CollisionShape3D
var point := Vector3.ZERO
var normal := Vector3.UP


static func list_from(state: PhysicsDirectBodyState3D) -> Array[CarBodyContact]:
	var contacts: Array[CarBodyContact] = []
	for index: int in state.get_contact_count():
		contacts.append(_contact_at(state, index))
	return contacts


static func _contact_at(state: PhysicsDirectBodyState3D, index: int) -> CarBodyContact:
	var contact := CarBodyContact.new()
	contact.collider = state.get_contact_collider_object(index) as Node
	contact.point = state.get_contact_collider_position(index)
	contact.normal = state.get_contact_local_normal(index)
	var shape_index := state.get_contact_collider_shape(index)
	contact.shape_node = _shape_node_of(contact.collider, shape_index)
	return contact


static func _shape_node_of(contact_collider: Node, shape_index: int) -> CollisionShape3D:
	var collision_object := contact_collider as CollisionObject3D
	if collision_object == null:
		return null
	var owner_id := collision_object.shape_find_owner(shape_index)
	return collision_object.shape_owner_get_owner(owner_id) as CollisionShape3D
