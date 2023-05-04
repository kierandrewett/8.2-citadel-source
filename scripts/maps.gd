extends Node

var current_name = ""
var current_scene = null

var initted = false
var loaded_map = false
var loading = false

var player_id: int

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

func dump_map_to_root(map, node = get_parent()):
	var resource = ResourceLoader.load(map)
	var instance = resource.instantiate()
		
	node.add_child(instance)
	
	return instance

func init_player(node):
	var player = dump_map_to_root("res://models/player.tscn", node)
	player_id = player.get_instance_id()
	return player

func load_map(name):
	if loading:
		return false
	loading = true
	
	var start_ms = Time.get_ticks_msec()

	if !name.ends_with(".tscn"):
		name = name + ".tscn"

	var map_path = name
	
	if !map_path.begins_with("res://"):
		map_path = "res://maps/%s" % [name]

	if map_path == ProjectSettings.get_setting("application/run/main_scene"):
		Console.log("Illegal map load from '%s'." % [name])
		loading = false
		return false

	if ResourceLoader.exists(map_path):
		loaded_map = false
		
		Console.close()
		
		var scene_to_dispose = current_scene

		var loading_instance

		if get_parent().get_node("/root/GameUILoading"):
			loading_instance = get_parent().get_node("/root/GameUILoading")
		else:
			loading_instance = dump_map_to_root("res://ui/gameui_loading.tscn")
		
		loading_instance.visible = true
		loading_instance.get_node("LoadingScreen").modulate.a = 1
		loading_instance.get_node("LoadingScreen/LoadingText").visible = true
		
		for i in range(0, 2):
			await get_tree().process_frame
		
		var box = loading_instance.get_node("LoadingScreen/LoadingText/BoxContainer")
		var rect = loading_instance.get_node("LoadingScreen/ColorRect")
		
		GameUI.visible = false
		
		if Maps.current_name == ProjectSettings.get_setting("application/run/main_scene") or Maps.is_background():
			box.set_h_size_flags(box.SIZE_SHRINK_END)
			box.set_v_size_flags(box.SIZE_SHRINK_END)
			rect.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			loading_instance.get_node("LoadingScreen").mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			box.set_h_size_flags(box.SIZE_SHRINK_CENTER)
			box.set_v_size_flags(box.SIZE_SHRINK_CENTER)
			rect.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			loading_instance.get_node("LoadingScreen").mouse_filter = Control.MOUSE_FILTER_PASS
		
		for i in range(0, 2):
			await get_tree().process_frame
			await get_tree().create_timer(1).timeout	

		var map_resource = ResourceLoader.load(map_path)
	
		current_scene = map_resource.instantiate()
		if scene_to_dispose != null:
			get_parent().remove_child(scene_to_dispose)
			scene_to_dispose.queue_free()
		
		if get_parent().get_node_or_null("/root/GameUIDeath"):
			get_parent().get_node_or_null("/root/GameUIDeath").queue_free()

		get_parent().add_child(current_scene)
				
		get_tree().current_scene = current_scene

		# Only create the player in playable maps
		if current_scene.get_node("Map") and current_scene.get_node("Entities"):
			var player = current_scene.get_node("Player")
		
			if player:
				player.queue_free()
				await get_tree().process_frame
				await get_tree().process_frame

			player = self.init_player(current_scene.get_node("Entities"))
			if player != null and "setpos" in player:
				for i in range(0, 10):
					await get_tree().process_frame
				player.setpos(0, 1, 0)
		else:
			Console.log("maps: skipping player creation, no playable world area!")

		current_name = map_path
			
		map_changed.emit(map_path)
		initted = true
		loaded_map = true
		loading = false
		Console.log("maps: loaded %s in %sms" % [name, Time.get_ticks_msec() - start_ms])
	
		loading_instance.get_node("LoadingScreen/LoadingText").visible = false

		return true
	else:
		Console.log("No map found by name '%s'" % [name])
		loading = false
		return false

