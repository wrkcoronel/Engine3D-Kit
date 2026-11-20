class_name WheelGround
extends RefCounted

const WHEEL_NAMES: Array[String] = [
	"dianteira esq",
	"dianteira dir",
	"traseira esq",
	"traseira dir",
]

var touching := false
var ground_name := "nada"
var point := Vector3.ZERO
var normal := Vector3.UP
var gap := INF


func describe(wheel_index: int) -> String:
	var wheel_name := WHEEL_NAMES[wheel_index]
	if not touching:
		return "roda %s: sem chao embaixo (raio nao achou nada)" % wheel_name
	var where := "ponto " + TelemetryLog.format_vector(point)
	var normal_text := "normal " + TelemetryLog.format_vector(normal)
	var gap_text := "vao ate o chao %.2f m" % gap
	return "roda %s: %s %s %s %s" % [wheel_name, ground_name, where, normal_text, gap_text]
