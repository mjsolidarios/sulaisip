extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	$NextButton/TextureButton.connect("pressed", self, "_goto_next_page")
	$PreviousButton/TextureButton.connect("pressed", self, "_goto_prev_page")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _goto_next_page():
	var parent_node = get_parent().get_parent().get_parent().get_parent()
	if parent_node.current_page < 5:
		parent_node.current_page+=1
	parent_node._populate_character_grid()

func _goto_prev_page():
	var parent_node = get_parent().get_parent().get_parent().get_parent()
	if parent_node.current_page >= 0:
		parent_node.current_page-=1
	parent_node._populate_character_grid()
