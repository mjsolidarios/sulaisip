extends NinePatchRect


@export var active_texture: Texture2D
@export var inactive_texture: Texture2D
@export var is_active: bool


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:
		self.texture = active_texture
	else:
		self.texture = inactive_texture
