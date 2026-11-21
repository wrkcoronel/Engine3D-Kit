extends TestCase

const LONG_EVENT := (
	"[22:10:11.123 |     2.32s] carro    | encostou em Buildings/Building1 "
	+ "| ponto (34.10, 0.81, -20.00) | normal (-0.00, 0.00, 1.00) "
	+ "| forma BoxShape3D tamanho (4.02, 13.74, 0.70) origem (36.00, 6.87, -20.35) "
	+ "rotacao graus (-0.00, 0.00, 0.00) | aresta mais proxima (33.99, 0.00, -20.00)"
)


func test_short_event_is_left_alone() -> void:
	var short_event := "[22:10:11.123 |     2.32s] modo     | agora controlando: carro"
	assert_eq(ConsoleWrap.wrap_event(short_event), short_event, "linha curta nao muda")


func test_long_event_is_split_in_several_lines_within_the_width() -> void:
	var wrapped := ConsoleWrap.wrap_event(LONG_EVENT)
	var lines := wrapped.split("\n")
	assert_true(lines.size() >= 4, "virou varias linhas: %d" % lines.size())
	for line: String in lines:
		assert_true(line.length() <= ConsoleWrap.MAX_WIDTH, "cabe na largura: " + line)


func test_first_line_keeps_the_header_and_first_field() -> void:
	var first_line := ConsoleWrap.wrap_event(LONG_EVENT).split("\n")[0]
	var expected_start := "[22:10:11.123 |     2.32s] carro    | encostou em"
	assert_true(first_line.begins_with(expected_start), "cabecalho")
	assert_true(not first_line.contains("ponto"), "o segundo campo vai para a linha de baixo")


func test_each_field_starts_a_line_with_a_bar_under_the_header_bar() -> void:
	var lines := ConsoleWrap.wrap_event(LONG_EVENT).split("\n")
	var header_bar_column := lines[0].find("| ")
	var header_bar_column_after_clock := lines[0].find("carro    | ") + "carro    ".length()
	assert_true(header_bar_column > 0, "tem barra no cabecalho")
	assert_true(lines[1].strip_edges().begins_with("| ponto"), "campo ponto numa linha")
	assert_eq(
		lines[1].find("| "), header_bar_column_after_clock, "barra alinhada com a do cabecalho"
	)


func test_no_text_is_lost_when_wrapping() -> void:
	var wrapped := ConsoleWrap.wrap_event(LONG_EVENT)
	var fields: Array[String] = [
		"Buildings/Building1",
		"(34.10, 0.81, -20.00)",
		"BoxShape3D",
		"(36.00, 6.87, -20.35)",
		"(33.99, 0.00, -20.00)",
	]
	for field: String in fields:
		assert_true(wrapped.contains(field), "continua la: " + field)


func test_overlong_field_wraps_on_spaces_and_stays_aligned() -> void:
	var lines := ConsoleWrap.wrap_event(LONG_EVENT, 70).split("\n")
	for line: String in lines:
		assert_true(line.length() <= 70, "cabe em 70 colunas: " + line)
	var text_column := lines[0].find("encostou")
	var continuation := ""
	for line: String in lines:
		if line.contains("rotacao"):
			continuation = line
	assert_true(
		continuation.begins_with(" ".repeat(text_column)), "continuacao alinhada com o texto"
	)


func test_wrap_words_never_breaks_inside_a_word() -> void:
	var lines := ConsoleWrap.wrap_words("aaa bbb ccc ddd", 7)
	assert_eq(lines, ["aaa bbb", "ccc ddd"] as Array[String], "quebra nos espacos")
	var long_word := ConsoleWrap.wrap_words("abcdefghijkl x", 5)
	var expected_long: Array[String] = ["abcdefghijkl", "x"]
	assert_eq(long_word, expected_long, "palavra maior que a largura fica inteira")


func test_event_without_a_message_separator_still_wraps() -> void:
	var odd := "texto sem cabecalho " + "palavra ".repeat(30)
	var lines := ConsoleWrap.wrap_event(odd).split("\n")
	assert_true(lines.size() > 1, "quebrou")
	for line: String in lines:
		assert_true(line.length() <= ConsoleWrap.MAX_WIDTH, "cabe")


func test_parenthesised_values_are_never_split() -> void:
	var found := ConsoleWrap.tokens("ponto (1.00, 2.00, 3.00) normal (0.00, 1.00, 0.00)")
	var expected: Array[String] = ["ponto", "(1.00, 2.00, 3.00)", "normal", "(0.00, 1.00, 0.00)"]
	assert_eq(found, expected, "o vetor fica inteiro")
	for width: int in [20, 25, 30, 40]:
		for line: String in ConsoleWrap.wrap_words(
			"a (1.00, 2.00, 3.00) b (4.00, 5.00, 6.00)", width
		):
			var opens := line.count("(")
			var closes := line.count(")")
			assert_eq(opens, closes, "parenteses fechados na mesma linha: " + line)
