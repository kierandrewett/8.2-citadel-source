extends Control

func _ready():
	get_viewport().connect("size_changed", Callable(self, "on_window_resize"))

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
