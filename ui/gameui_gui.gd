extends Control

func _ready():
	self.visible = !GameUI.visible && get_parent().get_node_or_null("GameUILoading") and !get_parent().get_node_or_null("GameUILoading").visible

func _process(delta):
	self.visible = !GameUI.visible && get_parent().get_node_or_null("GameUILoading") and !get_parent().get_node_or_null("GameUILoading").visible
