extends VideoStreamPlayer

var backgrounds = ["background01", "background02", "background03"]

var loaded = false

var intro = null
var gameui = null

func _ready():
	intro = get_parent().get_node("/root/Intro")
	gameui = get_parent().get_node("/root/GameUI")
	
	gameui.get_node("MainMenu").modulate.a = 0
	
	Console.log("init: starting intro playback")
	await get_tree().create_timer(1.0).timeout
	play()
	
func _input(event):
	if loaded:
		return
	
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		Console.log("init: user gesture received aborting intro")
		load_main_scene()
	
func load_main_scene():
	if loaded:
		return
	
	loaded = true
	
	Console.log("init: loading main scene")
	
	intro.get_node("IntroMovie").visible = false

	var bg = backgrounds[randi() % backgrounds.size()]
	
	Maps.load_map(bg)
	
func _finished():
	await get_tree().create_timer(0.5).timeout
	load_main_scene()
