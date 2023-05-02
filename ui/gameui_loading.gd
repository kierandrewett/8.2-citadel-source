extends Control

func _ready():
	GameUI.visible = false
	GameUI.set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.visible:
		Sounds.stop_all_sounds()
	
	pass
