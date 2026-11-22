class_name GpuLoadSample
extends RefCounted

const NAME_COLUMN := "Name"
const TIME_COLUMN := "Timestamp_Sys100NS"
const USAGE_COLUMN := "UtilizationPercentage"
const ENGINE_PATTERN := "phys_[0-9]+_eng_[0-9]+_engtype_[A-Za-z0-9_]+"
const TYPE_PREFIX := "engtype_"

var timestamp := 0.0
var usage_by_instance := {}


static func parse(command_output: String) -> GpuLoadSample:
	var sample := GpuLoadSample.new()
	var table := _parse_csv(command_output)
	if table.is_empty():
		return sample
	var header := table[0]
	var name_column := header.find(NAME_COLUMN)
	var time_column := header.find(TIME_COLUMN)
	var usage_column := header.find(USAGE_COLUMN)
	if name_column == -1 or time_column == -1 or usage_column == -1:
		return sample
	var last_needed_column := maxi(name_column, maxi(time_column, usage_column))
	for row_index: int in range(1, table.size()):
		var row := table[row_index]
		if row.size() <= last_needed_column:
			continue
		sample.timestamp = maxf(sample.timestamp, row[time_column].to_float())
		sample.usage_by_instance[row[name_column]] = row[usage_column].to_float()
	return sample


static func engine_percentages(previous: GpuLoadSample, current: GpuLoadSample) -> Dictionary:
	var percent_by_engine := {}
	if not previous.is_valid() or not current.is_valid():
		return percent_by_engine
	var elapsed := current.timestamp - previous.timestamp
	if elapsed <= 0.0:
		return percent_by_engine
	var engine_pattern := RegEx.create_from_string(ENGINE_PATTERN)
	for instance_name: String in current.usage_by_instance:
		if not previous.usage_by_instance.has(instance_name):
			continue
		var engine_match := engine_pattern.search(instance_name)
		if engine_match == null:
			continue
		var busy_time := float(current.usage_by_instance[instance_name])
		busy_time -= float(previous.usage_by_instance[instance_name])
		var engine := engine_match.get_string()
		percent_by_engine[engine] = (
			float(percent_by_engine.get(engine, 0.0)) + busy_time / elapsed * 100.0
		)
	return percent_by_engine


static func busiest_percent(percent_by_engine: Dictionary) -> int:
	if percent_by_engine.is_empty():
		return SystemLoadReader.UNKNOWN
	var busiest := 0.0
	for engine_percent: float in percent_by_engine.values():
		busiest = maxf(busiest, engine_percent)
	return clampi(roundi(busiest), 0, 100)


static func percent_for_type(percent_by_engine: Dictionary, engine_type: String) -> int:
	if percent_by_engine.is_empty():
		return SystemLoadReader.UNKNOWN
	var busiest := 0.0
	for engine: String in percent_by_engine:
		if engine.ends_with(TYPE_PREFIX + engine_type):
			busiest = maxf(busiest, float(percent_by_engine[engine]))
	return clampi(roundi(busiest), 0, 100)


static func busiest_engine_percent(previous: GpuLoadSample, current: GpuLoadSample) -> int:
	return busiest_percent(engine_percentages(previous, current))


static func _parse_csv(command_output: String) -> Array[PackedStringArray]:
	var table: Array[PackedStringArray] = []
	var normalized := command_output.replace("\r", "\n")
	for line: String in normalized.split("\n"):
		var cleaned_line := line.strip_edges()
		if cleaned_line.is_empty():
			continue
		table.append(cleaned_line.split(","))
	return table


func is_valid() -> bool:
	return timestamp > 0.0 and not usage_by_instance.is_empty()
