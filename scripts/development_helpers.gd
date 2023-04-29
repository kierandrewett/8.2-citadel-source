extends Node

func _input(delta):
	if Input.is_action_just_pressed("dev_reload_map"):
		if !Maps.is_background():
			Maps.load_map(Maps.current_name)
