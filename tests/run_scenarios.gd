extends "res://tests/run_tests.gd"


func _accepts_suite(relative_path: String) -> bool:
	return relative_path.contains("/scenarios/")
