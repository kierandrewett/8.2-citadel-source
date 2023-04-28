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

func load_map(name):
	call_deferred("_deferred_load_map", name)

func _deferred_load_map(name):
	var start_ms = Time.get_ticks_msec()
	
	if current_scene:
		current_scene.free()

	if !name.ends_with(".tscn"):
		name = name + ".tscn"

	var map_path = "res://maps/%s" % [name]

	var map_resource = ResourceLoader.load(map_path)
	var current_scene = map_resource.instantiate()

	get_parent().add_child(current_scene)
	
	get_tree().current_scene = current_scene

	current_name = map_path
	
	map_changed.emit(map_path)
	initted = true
	Console.log("maps: loaded %s in %sms" % [name, Time.get_ticks_msec() - start_ms])
