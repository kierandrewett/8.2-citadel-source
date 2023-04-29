extends Control

var was_last_input_esc = false

func _ready():
	get_viewport().connect("size_changed", Callable(self, "on_window_resize"))
	get_viewport().connect("gui_focus_changed", Callable(self, "on_window_focus_changed"))
	Maps.connect("map_changed", Callable(self, "on_map_loaded"))
	
	connect("visibility_changed", Callable(self, "on_visibility_changed"))
	
	self.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func on_window_resize():
	var size = get_viewport_rect().size
	var x = size.x
	var y = size.y
	
	# General grouping
	
	for node in get_tree().get_nodes_in_group("window_xy"):
		node.set_size(Vector2(x, y))

	for node in get_tree().get_nodes_in_group("window_x"):
		node.set_size(Vector2(x, node.get_size().y))

	for node in get_tree().get_nodes_in_group("window_y"):
		node.set_size(Vector2(node.get_size().x, y))

func _physics_process(delta):
	if Input.is_action_just_pressed("gameui_console") and Maps.initted:
		self.get_node("Console").visible = !self.get_node("Console").visible
		if !Maps.is_background() and self.get_node("Console").visible:
			self.visible = true
	
	if Input.is_action_just_pressed("gameui_menu"):
		var menu_visible = !self.visible
		
		if !Maps.is_background():
			self.visible = menu_visible
			if self.get_node("Console").visible:
				Console.close()
		else:
			self.get_node("Console").visible = menu_visible
			
			
	if Input.is_action_just_pressed("noclip"):
		Console.eval("noclip")

func set_visibility(node, state):
	if state:
		node.process_mode = 0
		node.focus_mode = FOCUS_ALL
		node.show()
	else:
		node.process_mode = 4
		node.focus_mode = FOCUS_NONE
		node.hide()
		
func on_map_loaded(map_path):
	# Ensure that all buttons are visible before applying changes
	for btn in get_node("MainMenu/VBoxContainer/VBoxContainer").get_children():
		set_visibility(btn, true)

	# If we are loading a background map, ensure that GameUI is visible initially
	if Maps.is_background():
		self.visible = true
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		set_visibility(get_node("MainMenu/VBoxContainer/VBoxContainer/ResumeGameButton"), false)
		set_visibility(get_node("MainMenu/VBoxContainer/VBoxContainer/SaveGameButton"), false)
	else:
		Console.close()
		self.visible = false
		
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var gameui_loading = get_node("/root/GameUILoading")
	
	create_tween().tween_property(gameui_loading.get_node("LoadingScreen"), "modulate", Color.TRANSPARENT, 2)
	create_tween().tween_property(get_node("MainMenu"), "modulate", Color.WHITE, 2)
	
	await get_tree().create_timer(2).timeout
	
	gameui_loading.visible = false

func on_console_close_requested():
	self.get_node("Console").visible = false

func on_visibility_changed():
	if self.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if !Maps.is_background():
				self.visible = true
