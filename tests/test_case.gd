class_name TestCase
extends RefCounted

var tree: SceneTree
var failures: Array[String] = []
var checks := 0

var _spawned: Array[Node] = []


func assert_true(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s (esperado %s, veio %s)" % [message, expected, actual])


func assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	checks += 1
	if absf(actual - expected) > tolerance:
		failures.append("%s (esperado %s, veio %s)" % [message, expected, actual])


func spawn(node: Node) -> void:
	tree.root.add_child(node)
	_spawned.append(node)


func cleanup() -> void:
	for node in _spawned:
		node.free()
	_spawned.clear()
