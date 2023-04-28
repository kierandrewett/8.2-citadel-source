extends MarginContainer

var gameui = null

func _ready():
	gameui = get_parent().get_node("/root/GameUI")

func on_button_click(action):
	Console.log(action)
	
	if action == "gameui_resume":
		gameui.visible = false
	
	if action == "gameui_console":
		Console.open()
	
	if action == "gameui_quit":
		get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
