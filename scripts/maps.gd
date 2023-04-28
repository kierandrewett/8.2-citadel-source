extends Node

var current_name = ""
var current_scene = null

var initted = false

signal map_changed(map_path)

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	current_name = current_scene.scene_file_path

func is_background():
	return Maps.current_name.begins_with("res://maps/background")

func get_maps():
	var files = []
	var dir = DirAccess.open("res://maps/")
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".tscn"):
			files.append(file.split(".")[0])
	return files

func load_map(name):
	return call_deferred("_deferred_load_map", name)

func _deferred_load_map(name):
	var start_ms = Time.get_ticks_msec()

	if !name.ends_with(".tscn"):
		name = name + ".tscn"

	var map_path = "res://maps/%s" % [name]

	if map_path == ProjectSettings.get_setting("application/run/main_scene"):
		Console.log("Illegal map load from '%s'." % [name])
		return false

	if ResourceLoader.exists(map_path):
		if current_scene and ProjectSettings.get_setting("application/run/main_scene") != current_name:
			current_scene.queue_free()

		var map_resource = ResourceLoader.load(map_path)
		current_scene = map_resource.instantiate()
			
		get_parent().add_child(current_scene)
		
		get_tree().current_scene = current_scene

		current_name = map_path
		
		map_changed.emit(map_path)
		initted = true
		Console.log("maps: loaded %s in %sms" % [name, Time.get_ticks_msec() - start_ms])
	
		return true
	else:
		Console.log("No map found by name '%s'" % [name])
		return false
