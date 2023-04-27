extends Label

func render(node):
	var godot_version = Engine.get_version_info()
	var semver = "%s.%s.%s" % [godot_version.major, godot_version.minor, godot_version.patch]
	
	var scene_path = get_tree().current_scene.scene_file_path
	var scene_name = scene_path.split("maps/")[1].replace(".tscn", "")
	
	set_text("Godot Engine %s (build %s)\nMap '%s'" % [semver, godot_version.hex, scene_name])

func _ready():
	render(0)

func _process(delta):
	render(0)
