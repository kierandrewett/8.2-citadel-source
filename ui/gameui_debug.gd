extends Control

var player_information = null
var lines = []

func _ready():
	player_information = get_node("/root/GameUIDebug/MarginContainer/PlayerInformation")

func _process(delta):
	lines = []

	if Globals.cl_showfps == 1:
		lines.append("%s fps on %s" % [str(Engine.get_frames_per_second()), Maps.current_scene.scene_file_path])
		
	if Globals.cl_showpos == 1 and Maps.loaded_map:
		var player = instance_from_id(Maps.player_id)

		print(player.velocity)

		if player != null:
			lines.append("name: %s" % ["Player"])
			lines.append("pos: %s" % ["%s %s %s" % ["%.2f" % player.global_position.x, "%.2f" % player.global_position.y, "%.2f" % player.global_position.z] if player else ""])
			lines.append("vel: %s" % ["%.2f" % (player.current_accel) if player and player.current_accel else 0.0])
	
	player_information.text = "\n".join(lines)
