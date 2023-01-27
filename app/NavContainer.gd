extends HBoxContainer


## Called when the node enters the scene tree for the first time.
#func _ready():
#	$GridContainer/PreviousButton/TextureButton.connect("pressed", self, "_goto_next_page")
#	$GridContainer/NextButton/TextureButton.connect("pressed", self, "_goto_prev_page")
#	$GridContainer/DeleteButton/TextureButton.connect("pressed", self, "_delete_char")
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
##func _process(delta):
##	pass
#
#func _goto_next_page():
#	var parent_node = get_parent().get_parent().get_parent().get_parent()
#	if parent_node.current_page < 5:
#		parent_node.current_page+=1
#		parent_node.active_button_bottom_index+=1
#	parent_node._populate_character_grid()
#
#func _goto_prev_page():
#	var parent_node = get_parent().get_parent().get_parent().get_parent()
#	if parent_node.current_page >= 0:
#		parent_node.current_page-=1
#		parent_node.active_button_bottom_index-=1
#	parent_node._populate_character_grid()
#
#func _delete_char():
#	pass
	
