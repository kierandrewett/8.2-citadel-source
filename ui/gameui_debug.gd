extends Control

var player_information = null
var lines = []

func _ready():
	player_information = get_node("/root/GameUIDebug/MarginContainer/PlayerInformation")

func _process(delta):
	lines = []
	
	if Globals.cl_showfps == 1:
		lines.append("%s fps on %s" % [str(Engine.get_frames_per_second()), Maps.current_scene.scene_file_path])
		
	if Globals.cl_showpos == 1:
		var player = Maps.current_scene.get_node("Player")
		
		lines.append("name: %s" % ["Player"])
		lines.append("pos: %s" % ["%s %s %s" % ["%.2f" % player.position.x, "%.2f" % player.position.y, "%.2f" % player.position.z] if player else ""])
		lines.append("vel: %s" % ["%.2f" % (player.speed) if player else 0.0])
	
	player_information.text = "\n".join(lines)
