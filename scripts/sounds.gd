extends Node

var sounds_playing = {}

func play_sound(path, node = get_parent(), volume = Globals.volume, pitch = 1) -> AudioStreamPlayer:
	var resource = ResourceLoader.load(path)
	
	var player = AudioStreamPlayer.new()
	node.add_child(player)
	
	player.set_stream(resource)
	player.volume_db = volume
	player.pitch_scale = pitch

	player.play()

	sounds_playing[player.get_instance_id()] = player

	player.finished.connect(func ():
		player.queue_free()
		if sounds_playing.has(player.get_instance_id()):
			sounds_playing.erase(player.get_instance_id())
	)
	return player

func stop_all_sounds():
	for key in sounds_playing.keys():
		sounds_playing[key].stop()
		sounds_playing[key].queue_free()
		sounds_playing.erase(key)
