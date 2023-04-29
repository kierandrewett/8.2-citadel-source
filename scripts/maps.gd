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

	var map_path = name
	
	if !map_path.begins_with("res://"):
		map_path = "res://maps/%s" % [name]

	if map_path == ProjectSettings.get_setting("application/run/main_scene"):
		Console.log("Illegal map load from '%s'." % [name])
		return false

	if ResourceLoader.exists(map_path):
		Console.close()
		
		var scene_to_dispose = current_scene

		var loading_instance

		if get_parent().get_node("/root/GameUILoading"):
			loading_instance = get_parent().get_node("/root/GameUILoading")
		else:
			var loading_resource = ResourceLoader.load("res://ui/gameui_loading.tscn")
			loading_instance = loading_resource.instantiate()
				
			get_parent().add_child(loading_instance)
		
		loading_instance.visible = true
		loading_instance.get_node("LoadingScreen").modulate.a = 1
		loading_instance.get_node("LoadingScreen/LoadingText").visible = true
		
		for i in range(0, 2):
			await get_tree().process_frame
		
		var box = loading_instance.get_node("LoadingScreen/LoadingText/BoxContainer")
		var rect = loading_instance.get_node("LoadingScreen/ColorRect")
		
		if Maps.current_name == ProjectSettings.get_setting("application/run/main_scene"):
			box.set_h_size_flags(box.SIZE_SHRINK_END)
			box.set_v_size_flags(box.SIZE_SHRINK_END)
			rect.visible = true
		else:
			box.set_h_size_flags(box.SIZE_SHRINK_CENTER)
			box.set_v_size_flags(box.SIZE_SHRINK_CENTER)
			rect.visible = false
			GameUI.visible = false
		
		for i in range(0, 2):
			await get_tree().process_frame

		var map_resource = ResourceLoader.load(map_path)
		
		current_scene = map_resource.instantiate()
		if scene_to_dispose != null:
			scene_to_dispose.queue_free()
		
		get_parent().add_child(current_scene)
		
		get_tree().current_scene = current_scene

		current_name = map_path
		
		map_changed.emit(map_path)
		initted = true
		Console.log("maps: loaded %s in %sms" % [name, Time.get_ticks_msec() - start_ms])
	
		loading_instance.get_node("LoadingScreen/LoadingText").visible = false
	
		return true
	else:
		Console.log("No map found by name '%s'" % [name])
		return false
