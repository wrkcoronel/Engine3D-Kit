class_name RenderTimeReader
extends RefCounted

const SMOOTHING := 0.1

var gpu_milliseconds := 0.0

var _viewport_rid := RID()


func start(viewport: Viewport) -> void:
	_viewport_rid = viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport_rid, true)


func stop() -> void:
	if _viewport_rid.is_valid():
		RenderingServer.viewport_set_measure_render_time(_viewport_rid, false)


func update() -> void:
	if not _viewport_rid.is_valid():
		return
	var measured := RenderingServer.viewport_get_measured_render_time_gpu(_viewport_rid)
	gpu_milliseconds = smoothed(gpu_milliseconds, measured)


static func smoothed(current: float, measured: float) -> float:
	return lerpf(current, measured, SMOOTHING)
