extends Control


export(String, "normal", "hover", "pressed", "disabled") var state
export var texture_normal: Texture
export var texture_hover: Texture
export var texture_pressed: Texture
export var text:String

# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureButton.texture_normal = texture_normal
	$TextureButton/Label.text = text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == "normal":
		$TextureButton.texture_normal = texture_normal
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(1,1,1)
	if state == "hover":
		$TextureButton.texture_normal = texture_hover
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(1,1,1)
	if state == "pressed":
		$TextureButton.texture_normal = texture_pressed
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(1,1,1)
	if state == "disabled":
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(0,0,0,0.1)
