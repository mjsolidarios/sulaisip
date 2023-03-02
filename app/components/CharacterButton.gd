extends Control


@export var state: String # (String, "normal", "hover", "pressed", "disabled")
@export var texture_normal: Texture2D
@export var texture_hover: Texture2D
@export var texture_pressed: Texture2D
@export var text:String
@export var texture_icon: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureButton.texture_normal = texture_normal
	$TextureButton/Label.text = text
	$TextureRect.texture = texture_icon

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == "normal":
		$TextureButton.texture_normal = texture_normal
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(1,1,1)
		if self.get_node_or_null("TextureRect") != null:
			self.get_node("TextureRect").modulate = Color(1,1,1)
	if state == "hover":
		$TextureButton.texture_normal = texture_hover
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(1,1,1)
		if self.get_node_or_null("TextureRect") != null:
			self.get_node("TextureRect").modulate = Color(1,1,1)
	if state == "pressed":
		$TextureButton.texture_normal = texture_pressed
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(1,1,1)
		if self.get_node_or_null("TextureRect") != null:
			self.get_node("TextureRect").modulate = Color(1,1,1)
	if state == "disabled":
		$TextureButton.disabled = false
		$TextureButton.modulate = Color(0,0,0,0.1)
		if self.get_node_or_null("TextureRect") != null:
			self.get_node("TextureRect").modulate = Color(0,0,0,0.1)
