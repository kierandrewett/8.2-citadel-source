extends Control

var was_last_input_esc = false

func _ready():
	get_viewport().connect("size_changed", Callable(self, "on_window_resize"))
	Maps.connect("map_changed", Callable(self, "on_map_loaded"))
	
	self.visible = false

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
	
	if Input.is_action_just_pressed("gameui_menu") and !Maps.is_background():
		self.visible = !self.visible
		self.get_node("Console").visible = self.visible

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
		
		set_visibility(get_node("MainMenu/VBoxContainer/VBoxContainer/ResumeGameButton"), false)
		set_visibility(get_node("MainMenu/VBoxContainer/VBoxContainer/SaveGameButton"), false)
	else:
		self.visible = false

func on_console_close_requested():
	self.get_node("Console").visible = false
