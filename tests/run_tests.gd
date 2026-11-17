extends SceneTree

const TESTS_DIR := "res://tests/"


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	var total_tests := 0
	var total_checks := 0
	var failed_tests: Array[String] = []

	for file_name in _suite_files():
		var script := load(TESTS_DIR + file_name) as GDScript
		for method in script.get_script_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_"):
				continue

			var suite := script.new() as TestCase
			suite.tree = self
			await suite.call(method_name)
			suite.cleanup()

			if suite.checks == 0:
				suite.failures.append("nenhuma verificacao rodou: o teste quebrou ou esta vazio")

			var label := "%s::%s" % [file_name, method_name]
			total_tests += 1
			total_checks += suite.checks
			if suite.failures.is_empty():
				print("PASS  ", label)
			else:
				failed_tests.append(label)
				print("FAIL  ", label)
				for failure in suite.failures:
					print("        - ", failure)

	print("")
	print(
		"%d testes, %d verificacoes, %d falharam" % [total_tests, total_checks, failed_tests.size()]
	)
	quit(1 if not failed_tests.is_empty() else 0)


func _suite_files() -> PackedStringArray:
	var suites := PackedStringArray()
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		var is_test_file := file_name.begins_with("test_") and file_name.ends_with(".gd")
		if is_test_file and file_name != "test_case.gd":
			suites.append(file_name)
	return suites
