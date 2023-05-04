extends Control

func should_show():
	if GameUI.visible:
		return false
		
	var gameui_loading = get_parent().get_node_or_null("GameUILoading")
	var gameui_death = get_parent().get_node_or_null("GameUIDeath")
		
	if gameui_loading:
		return !gameui_loading.visible

	if gameui_death:
		return !gameui_death.visible
		
	return true

func _ready():
	self.visible = should_show()

func _process(delta):
	self.visible = should_show()
