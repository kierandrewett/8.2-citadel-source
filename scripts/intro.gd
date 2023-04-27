extends VideoStreamPlayer

var backgrounds = ["background01"]

var loaded = false

func _ready():
	get_tree().current_scene.get_node("LoadingScreen").visible = false
	
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
	
	get_tree().current_scene.get_node("IntroMovie").visible = false
	get_tree().current_scene.get_node("LoadingScreen").visible = true
	
	var bg = backgrounds[randi() % backgrounds.size()]
	
	var background_scene_res = ResourceLoader.load("res://maps/%s.tscn" % [bg])
	var background_scene = background_scene_res.instantiate()

	get_parent().add_child(background_scene)
	
	await get_tree().create_timer(1.5).timeout
	
	var tween = get_tree().create_tween()
	var loading_color_rect = get_tree().current_scene.get_node("LoadingScreen").get_node("ColorRect")
	
	get_tree().current_scene.get_node("LoadingScreen").get_node("LoadingText").modulate.a = 0
	tween.tween_property(loading_color_rect, "modulate", Color.TRANSPARENT, 2)

	await get_tree().create_timer(2).timeout
	
	print("init: unloading loading screen")
	get_tree().current_scene.get_node("LoadingScreen").visible = false
	
func _finished():
	await get_tree().create_timer(0.5).timeout
	load_main_scene()
