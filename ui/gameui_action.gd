extends MarginContainer

func on_button_click(action):
	print(action)
	
	if action == "gameui_quit":
		get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
