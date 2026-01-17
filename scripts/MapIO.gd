extends Node
class_name MapIO

const MAP_DIR := "user://maps"

static func list_maps() -> Array[String]:
	var names: Array[String] = []
	if not DirAccess.dir_exists_absolute(MAP_DIR):
		return names
	var dir := DirAccess.open(MAP_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".json"):
			names.append(entry.trim_suffix(".json"))
		entry = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names

static func save_map(name: String, data: Dictionary) -> bool:
	if name.strip_edges() == "":
		return false
	if not DirAccess.dir_exists_absolute(MAP_DIR):
		var dir := DirAccess.open("user://")
		if dir == null:
			return false
		var err := dir.make_dir("maps")
		if err != OK:
			return false
	var path := _map_path(name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var json := JSON.stringify(data, "\t")
	file.store_string(json)
	file.close()
	return true

static func load_map(name: String) -> Dictionary:
	var path := _map_path(name)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func _map_path(name: String) -> String:
	var sanitized := name.strip_edges()
	return "%s/%s.json" % [MAP_DIR, sanitized]
