extends VideoStreamPlayer

var backgrounds = ["background01", "background02", "background03"]

var loaded = false

var intro = null
var gameui = null

func _ready():
	intro = get_parent().get_node("/root/Intro")
	gameui = get_parent().get_node("/root/GameUI")
	
	intro.get_node("LoadingScreen").visible = false
	gameui.get_node("MainMenu").modulate.a = 0
	
	print("init: starting intro playback")
	await get_tree().create_timer(1.0).timeout
	play()
	
func _input(event):
	if loaded:
		return
	
	if  (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		print("init: user gesture received aborting intro")
		load_main_scene()
	
func load_main_scene():
	if loaded:
		return
	
	loaded = true
	
	print("init: loading main scene")
	
	intro.get_node("IntroMovie").visible = false
	intro.get_node("LoadingScreen").visible = true
	
	var bg = backgrounds[randi() % backgrounds.size()]
	
	Maps.load_map(bg)
	
	await get_tree().create_timer(1.5).timeout
	
	intro.get_node("LoadingScreen").get_node("LoadingText").modulate.a = 0
	
	intro.create_tween().tween_property(gameui.get_node("MainMenu"), "modulate", Color.WHITE, 2)
	intro.create_tween().tween_property(intro.get_node("LoadingScreen").get_node("ColorRect"), "modulate", Color.TRANSPARENT, 2)

	await get_tree().create_timer(2).timeout
	
	print("init: unloading loading screen")
	intro.get_node("LoadingScreen").visible = false
	
func _finished():
	await get_tree().create_timer(0.5).timeout
	load_main_scene()
