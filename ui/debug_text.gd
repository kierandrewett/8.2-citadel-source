extends Label

func render(node):
	var godot_version = Engine.get_version_info()
	var semver = "%s.%s.%s" % [godot_version.major, godot_version.minor, godot_version.patch]
	
	var scene_name = "<none>"
	
	if Maps.current_name.length():
		if Maps.current_name.begins_with("res://maps/"):
			scene_name = Maps.current_name.split("maps/")[1].replace(".tscn", "")
		elif Maps.current_name.begins_with("res://"):
			scene_name = Maps.current_name.split("res://")[1].replace(".tscn", "")
		else:
			scene_name = Maps.current_name.replace(".tscn", "")
	
	set_text("Godot Engine %s (build %s)\nMap '%s'" % [semver, godot_version.hex, scene_name])

func _ready():
	render(0)

func _process(delta):
	render(0)
