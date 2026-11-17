extends SceneTree

const TESTS_DIR := "res://tests/"


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	await process_frame
	var total_tests := 0
	var total_checks := 0
	var failed_tests: Array[String] = []

	for file_name in _suite_files():
		var script := load(TESTS_DIR + file_name) as GDScript
		if script == null or not script.can_instantiate():
			total_tests += 1
			failed_tests.append(file_name)
			print("FAIL  ", file_name)
			print("        - o arquivo de teste nao compilou")
			continue
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
	if total_tests == 0:
		print("nenhum teste encontrado em %s" % TESTS_DIR)
		quit(1)
		return
	quit(1 if not failed_tests.is_empty() else 0)


func _accepts_suite(relative_path: String) -> bool:
	return not relative_path.contains("/scenarios/")


func _suite_files() -> Array[String]:
	var suites: Array[String] = []
	_collect_suites("", suites)
	return suites


func _collect_suites(relative_folder: String, suites: Array[String]) -> void:
	var folder := TESTS_DIR + relative_folder
	for file_name: String in DirAccess.get_files_at(folder):
		var is_test_file := file_name.begins_with("test_") and file_name.ends_with(".gd")
		var is_base_class := file_name == "test_case.gd"
		var relative_path := relative_folder + file_name
		if is_test_file and not is_base_class and _accepts_suite(relative_path):
			suites.append(relative_path)
	for folder_name: String in DirAccess.get_directories_at(folder):
		_collect_suites(relative_folder + folder_name + "/", suites)
