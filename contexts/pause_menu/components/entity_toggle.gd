class_name EntityToggle
extends RefCounted

const ENTITIES_GROUP := "entities"


static func set_enabled(tree: SceneTree, enabled: bool) -> void:
	if tree == null:
		return
	var entities := tree.get_nodes_in_group(ENTITIES_GROUP)
	for node: Node in entities:
		if node.has_method("set_entity_enabled"):
			node.call("set_entity_enabled", enabled)


static func is_enabled(tree: SceneTree) -> bool:
	if tree == null:
		return false
	var entities := tree.get_nodes_in_group(ENTITIES_GROUP)
	for node: Node in entities:
		if node.has_method("is_entity_enabled"):
			var enabled: bool = node.call("is_entity_enabled")
			return enabled
	return false


static func has_entity(tree: SceneTree) -> bool:
	if tree == null:
		return false
	return not tree.get_nodes_in_group(ENTITIES_GROUP).is_empty()
