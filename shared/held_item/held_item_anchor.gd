class_name HeldItemAnchor
extends Node

const GROUP := "held_item_anchor"

var has_item := false
var aim_amount := 0.0
var scoped := false
var item_transform := Transform3D.IDENTITY
var muzzle_position := Vector3.ZERO
var sprint_amount := 0.0


static func find(tree: SceneTree) -> HeldItemAnchor:
	return tree.get_first_node_in_group(GROUP) as HeldItemAnchor


func _enter_tree() -> void:
	add_to_group(GROUP)
