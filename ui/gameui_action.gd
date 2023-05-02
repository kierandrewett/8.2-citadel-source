extends MarginContainer

var gameui = null

func _ready():
	gameui = get_parent().get_node("/root/GameUI")

func on_button_click(action):
	Console.log(action)
	
	var played_sound = Sounds.play_sound("res://resources/sounds/ui/buttonclick.wav")
	
	if action == "gameui_resume":
		gameui.visible = false
	
	if action == "gameui_new_game":
		Maps.load_map("d1_test")
	
	if action == "gameui_console":
		Console.open()	
		
	if action == "gameui_quit":
		played_sound.finished.connect(func ():
			get_tree().quit()	
		)

func on_button_mouse_over():
	Sounds.play_sound("res://resources/sounds/ui/buttonmouseover.wav")
