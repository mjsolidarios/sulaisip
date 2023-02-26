extends Control

# Tagalog to type: Ang bawat rumehistrong kalahok sa patimpalak ay nagantimpalaan
# Conversational: Oo, Hindi, Kamusta, Ayos, Paumanhin, Salamat, Sige, Meron, Wala, Pakiusap

var file = File.new()
var data
var character_frequency_data:Dictionary
var CharacterButton = preload("res://components/CharacterButton.tscn")
export var nlp_server_url = ""
var headers = ["Content-Type: application/json"]
var use_ssl=true
var query := {}
var current_page = 0
var next_characters:String = ""
var thread

export var websocket_url = "ws://127.0.0.1:1880/data"
var _wsclient = WebSocketClient.new()
export var icon_del: Texture
export var icon_prev: Texture
export var icon_next: Texture

export(String, "top", "bottom") var active_group
export var active_button_top_index = 0
export var active_button_bottom_grid_index = 0


onready var text_suggestions_node = get_node("HBoxContainer/VBoxContainer/NinePatchRect/MarginContainer/TextSuggestions")
onready var button_keys_node = get_node("HBoxContainer/VBoxContainer/NinePatchRect2/MarginContainer/HBoxContainer")
onready var button_char_keys_node = get_node("HBoxContainer/VBoxContainer/NinePatchRect2/MarginContainer/HBoxContainer/GridContainer")
onready var char_grid = button_char_keys_node

var timer_started = false
var timer_pressed_started = false
var active_direction = "right"

var gyro = Vector3(0,0,0)
var acce = Vector3(0,0,0)
var mag = Vector3(0,0,0)
var grav = Vector3(0,-1,0)

var last_rotation = 0

func _array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		s += String(i)
	return s

func _create_instanced_button(text:String):
	var button = CharacterButton.instance()
	button.text = text
	button.rect_size = Vector2(90,80)
	button.get_node("TextureButton").connect("pressed", self, "_add_text_to_input", [text])
	char_grid.add_child(button)

func _goto_next_page():
	if current_page < 5:
		current_page+=1
	_populate_character_grid()

func _goto_prev_page():
	if current_page >= 0:
		current_page-=1
	_populate_character_grid()

func _moveto_next_button():
	if active_direction=="left":
		if active_group == "top":
			active_button_top_index -= 1
		else:
			active_button_bottom_grid_index -= 1
	if active_direction=="right":
		if active_group == "top":
			active_button_top_index += 1
		else:
			active_button_bottom_grid_index += 1
	if active_direction=="neutral":
		pass

	# Reset

	if active_button_top_index > 4:
		active_button_top_index = 0
	if active_button_bottom_grid_index > 7:
		active_button_bottom_grid_index = 0

	# print(active_button_top_index, ",", active_button_bottom_grid_index)


func _del_char():
	var text = $HBoxContainer/VBoxContainer/TextEdit.text
	if text.length() > 0:
		$HBoxContainer/VBoxContainer/TextEdit.text = text.substr(0, text.length() - 1)
	_predict_next_character()

func _create_control_button(_type):
	var button = CharacterButton.instance()
	button.text = ""
	button.rect_size = Vector2(90,80)
	if _type == "next":
		button.texture_icon = icon_next
		button.get_node("TextureButton").connect("pressed", self, "_goto_next_page")
	if _type == "prev":
		button.texture_icon = icon_prev
		button.get_node("TextureButton").connect("pressed", self, "_goto_prev_page")
	if _type == "del":
		button.texture_icon = icon_del
		button.get_node("TextureButton").connect("pressed", self, "_del_char")
	char_grid.add_child(button)

func _populate_character_grid():

	# clear node
	var children = char_grid.get_children()
	for i in children:
		char_grid.remove_child(i)

	var character_bucket = ""
	var all_characters_string = _array_to_string(character_frequency_data.keys())

	for i in all_characters_string:
		if i in next_characters:
			all_characters_string = all_characters_string.replace(i, "")

	character_bucket = (next_characters+all_characters_string).replace(" ", "").to_lower()

	if current_page <= 0:
		_create_control_button("prev")
		for i in character_bucket.substr(0, 5):
#			print("p1:"+character_bucket.substr(0, 5))
			_create_instanced_button(i)
		_create_control_button("next")
		_create_control_button("del")
	if current_page == 1:
		_create_control_button("prev")
		for i in character_bucket.substr(5, 5):
#			print("p2:"+character_bucket.substr(5, 5))
			_create_instanced_button(i)
		_create_control_button("next")
		_create_control_button("del")
	if current_page == 2:
		_create_control_button("prev")
		for i in character_bucket.substr(10, 5):
#			print("p3:"+character_bucket.substr(10, 5))
			_create_instanced_button(i)
		_create_control_button("next")
		_create_control_button("del")
	if current_page == 3:
		_create_control_button("prev")
		for i in character_bucket.substr(15, 5):
#			print("p4:"+character_bucket.substr(15, 5))
			_create_instanced_button(i)
		_create_control_button("next")
		_create_control_button("del")
	if current_page >= 4:
		_create_control_button("prev")
		for i in character_bucket.substr(20, 5):
#			print("p5:"+character_bucket.substr(20, 5))
			_create_instanced_button(i)
		_create_control_button("next")
		_create_control_button("del")

func _python_server():
	OS.execute("run_server.bat", [], false)

func _ready():

	thread = Thread.new()
	thread.start(self, "_python_server")

	_wsclient.connect("connection_closed", self, "_wsclosed")
	_wsclient.connect("connection_error", self, "_wserror")
	_wsclient.connect("connection_established", self, "_wsconnected")
	_wsclient.connect("data_received", self, "_wsondata")

	var err = _wsclient.connect_to_url(websocket_url)

	if err != OK:
		print("Unable to connect.")
		set_process(false)


	file.open("res://data/character_rankings.json", File.READ)
	character_frequency_data = parse_json(file.get_as_text())
	$HBoxContainer/VBoxContainer/TextEdit.text = " "
	_predict_next_character()
	print(_wsclient)
	# websocket

func _exit_tree():
	thread.wait_to_finish()

func calc_north(p_grav, p_mag):
	# Always use normalized vectors!
	p_grav = p_grav.normalized()

	# Calculate east (or is it west) by getting our cross product.
	# The cross product of two normalized vectors returns a vector that
	# is perpendicular to our two vectors
	var east = p_grav.cross(p_mag.normalized()).normalized()

	# Cross again to get our horizon aligned north
	return east.cross(p_grav).normalized()

func orientate_by_mag_and_grav(p_mag, p_grav):
	var rotate = Basis()

	# as always, normalize!
	p_mag = p_mag.normalized()

	# gravity points down, so - gravity points up!
	rotate.y = -p_grav.normalized()

	# Cross products with our magnetic north gives an aligned east (or west, I always forget)
	rotate.x = rotate.y.cross(p_mag)

	# And cross product again and we get our aligned north completing our matrix
	rotate.z = rotate.x.cross(rotate.y)

	return rotate

func rotate_by_gyro(p_gyro, p_basis, p_delta):
	var rotate = Basis()

	rotate = rotate.rotated(p_basis.x, -p_gyro.x * p_delta)
	rotate = rotate.rotated(p_basis.y, -p_gyro.y * p_delta)
	rotate = rotate.rotated(p_basis.z, -p_gyro.z * p_delta)

	return rotate * p_basis

func drift_correction(p_basis, p_grav):
	# as always, make sure our vector is normalized but also invert as our gravity points down
	var real_up = -p_grav.normalized()

	# start by calculating the dot product, this gives us the cosine angle between our two vectors
	var dot = p_basis.y.dot(real_up)

	# if our dot is 1.0 we're good
	if (dot < 1.0):
		# the cross between our two vectors gives us a vector perpendicular to our two vectors
		var axis = p_basis.y.cross(real_up).normalized()
		var correction = Basis(axis, acos(dot))
		p_basis = correction * p_basis

	return p_basis

func _input(event):
	pass

func get_basis_for_arrow(p_vector):
	var rotate = Basis()

	# as our arrow points up, Y = our direction vector
	rotate.y = p_vector.normalized()

	# get an arbitrary vector we can use to calculate our other two vectors
	var v = Vector3(1.0, 0.0, 0.0)
	if abs(v.dot(rotate.y)) > 0.9:
		v = Vector3(0.0, 1.0, 0.0)

	# use our vector to get a vector perpendicular to our two vectors
	rotate.x = rotate.y.cross(v).normalized()

	# and the cross product again gives us our final vector perpendicular to our previous two vectors
	rotate.z = rotate.x.cross(rotate.y).normalized()

	return rotate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active_group == "top":
		$HBoxContainer/VBoxContainer/NinePatchRect.is_active = true
		$HBoxContainer/VBoxContainer/NinePatchRect2.is_active = false
	else:
		$HBoxContainer/VBoxContainer/NinePatchRect.is_active = false
		$HBoxContainer/VBoxContainer/NinePatchRect2.is_active = true

	var children_top_count = text_suggestions_node.get_child_count()
	var children_bottom_count = button_keys_node.get_child_count()
	var children_bottom_grid_count = button_char_keys_node.get_child_count()

	if children_top_count > 0:
		for i in text_suggestions_node.get_children():
			if  i.get_index() == active_button_top_index:
				i.state="hover"
			else:
				i.state="normal"

	if children_bottom_grid_count > 0:
		for i in button_char_keys_node.get_children():
			if  i.get_index() == active_button_bottom_grid_index:
				i.state="hover"
			else:
				i.state="normal"

	_wsclient.poll()

# Update our arrow showing gravity
	get_node("HBoxContainer/Panel/ViewportContainer/Viewport/Spatial/Arrows/AccelerometerArrow").transform.basis = get_basis_for_arrow(acce)

	# Update our arrow showing our magnetometer
	# Note that in absense of other strong magnetic forces this will point to magnetic north, which is not horizontal thanks to the earth being, uhm, round
	get_node("HBoxContainer/Panel/ViewportContainer/Viewport/Spatial/Arrows/MagnetoArrow").transform.basis = get_basis_for_arrow(mag)

	# Calculate our north vector and show that
	var north = calc_north(acce,mag)
	get_node("HBoxContainer/Panel/ViewportContainer/Viewport/Spatial/Arrows/NorthArrow").transform.basis = get_basis_for_arrow(north)


	if mag.length() < 0.1:
		mag = Vector3(1.0, 0.0, 0.0)

	if acce.length() < 0.1:
		acce = Vector3(0.0, -1.0, 0.0)

	var mesh = $HBoxContainer/Panel/ViewportContainer/Viewport/Spatial/MeshInstance
	var new_basis = rotate_by_gyro(gyro, mesh.transform.basis, delta).orthonormalized()
	mesh.transform.basis = drift_correction(new_basis, acce)

	var mesh2 = $HBoxContainer/Panel/ViewportContainer/Viewport/Spatial/MeshInstance2
	mesh2.transform.basis = orientate_by_mag_and_grav(mag, acce).orthonormalized()

func _wsconnected(proto = ""):
	print("Connected with protocol: ", proto)

func _wsclosed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _wserror(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _wsondata():

	var data = _wsclient.get_peer(1).get_packet().get_string_from_utf8()
	var parsed_data = parse_json(data)
#	var parsed_data = data.replace("[", "").replace("]", "").split(",")

	var blink = parsed_data.blink
	var left = 0
	var right = 0
	var push = 0
	if parsed_data.has("aL"):
		left = parsed_data.aL
	if parsed_data.has("aR"):
		right = parsed_data.aR
	if parsed_data.has("push"):
		right = parsed_data.push
	var gX = parsed_data.gX
	var gY = parsed_data.gY
	var gZ = parsed_data.gZ
	var aX = parsed_data.aX
	var aY = parsed_data.aY
	var aZ = parsed_data.aZ
	var mX = parsed_data.mX
	var mY = parsed_data.mY
	var mZ = parsed_data.mZ

	var yaw = 0.0

	gyro = Vector3(gX, gY, gZ)
	acce = Vector3(aX, aY, aZ)
	mag = Vector3(mX, mY, mZ)

	# print("left: "+str(left),"|","right: "+str(right))

#	if left > 0.8:
#		active_direction = "left"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true
#	if right > 0.8:
#		active_direction = "right"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true

	# print("left: "+str(left)+"|"+"right: "+str(right))

	if push > 0:
		if !timer_pressed_started:
			$TimerPressButton.start()
			timer_pressed_started = true
		# blink = 0

	# var pitch = abs(atan2(-aY, aZ) * 180 / PI )
	var rollupdown = abs(atan2(-aY, aZ) * 180 / PI)
#	var rotation = stepify(abs(gZ), 0.01)

	var roll = atan2(-gY, -gZ)
	var pitch = atan2(gX, -gZ)
	yaw = yaw * 0.98 + roll * 0.02

	if yaw > 180:
		yaw -= 360
	elif yaw < -180:
		yaw += 360
	
	yaw = round(yaw*1000)

	#print(yaw)
	# print(mZ, aZ, gZ)

	if rollupdown > 100:
		active_group = "bottom"
	else:
		active_group = "top"

	#var current_rotation = $HBoxContainer/Panel/ViewportContainer/Viewport/Spatial/MeshInstance.get_rotation_degrees().x

	var threshhold = 1
	var base_rot = 5
	var last_rotation = 0
	
	var current_rotation = yaw
	
	if current_rotation > last_rotation + threshhold:
		active_direction = "right"
	elif current_rotation < last_rotation - threshhold:
		active_direction = "left"
	else:
		active_direction = "neutral"
	last_rotation = current_rotation + threshhold
	
	if !(current_rotation + threshhold == last_rotation + threshhold):
		if !timer_started:
			$Timer.start()
			timer_started = true	
#	if yaw <= base_rot - threshhold:
#		active_direction = "left"
#	elif yaw >= base_rot + threshhold:
#		active_direction = "right"
#	else:
#		active_direction = "neutral"
		
	print(active_direction, yaw)
	

	
	if active_button_top_index >= 4:
		active_button_top_index = 0
	if active_button_top_index < 0:
		active_button_top_index = 0
	if active_button_bottom_grid_index >= 7:
		active_button_bottom_grid_index = 0
	if active_button_bottom_grid_index < 0:
		active_button_bottom_grid_index = 0
		
	# print(active_button_top_index, ",", active_button_bottom_grid_index)


#	if yaw > base_rot and yaw < base_rot + threshhold:
#		active_direction = "neutral"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true
#	if yaw < base_rot:
#		active_direction = "left"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true
#	if yaw > base_rot + threshhold:
#		active_direction = "right"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true


	# print(rotation)
#	if current_rotation > last_rotation + threshhold:
#		active_direction = "right"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true
#	elif current_rotation < last_rotation + threshhold:
#		active_direction = "left"
#		if !timer_started:
#			$Timer.start()
#			timer_started = true
#	last_rotation = current_rotation

func _add_text_to_input(var character):
	$HBoxContainer/VBoxContainer/TextEdit.text += character
	_predict_next_character()

func _predict_next_character(text_fill:=""):
	var current_text = $HBoxContainer/VBoxContainer/TextEdit.text
	if text_fill.length() > 0:
		$HBoxContainer/VBoxContainer/TextEdit.text = current_text+text_fill+" "

	if $HBoxContainer/VBoxContainer/TextEdit.text.length() > 0:
		query = { "text": $HBoxContainer/VBoxContainer/TextEdit.text }
	else:
		query = { "text": "" }

	if current_text.length()>0:
		$HTTPRequest.request(nlp_server_url, headers, use_ssl, HTTPClient.METHOD_POST, to_json(query))
	else:
		$HTTPRequest.request(nlp_server_url)
	current_page = 0

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())

	# clear node
	var children = text_suggestions_node.get_children()
	for i in children:
		text_suggestions_node.remove_child(i)
	
	if $HBoxContainer/VBoxContainer/TextEdit.text.length() != 0:
		next_characters = json.result['nextCharacters']

	if $HBoxContainer/VBoxContainer/TextEdit.text.length() != 0:
		for i in json.result['wordList']:
			var button = CharacterButton.instance()
			var TrimmedText = i['sequence'].replace(".", "").split(' ')[-1]
			button.text = TrimmedText.to_lower()
			button.get_node("TextureButton").connect("pressed", self, "_predict_next_character", [i['token_str']])

			text_suggestions_node.add_child(button)

	_populate_character_grid()

func _on_Button_pressed():
	_predict_next_character()

func _press_active_button():
	if active_group == "top":
		for i in text_suggestions_node.get_children():
			if i.state == "hover":
				# print(i.get_node("TextureButton/Label").text)
				i.state = "pressed"
				i.get_node("TextureButton").emit_signal("pressed")
	else:
		for i in button_char_keys_node.get_children():
			if i.state == "hover":
				i.state = "pressed"
				# print(i.get_node("TextureButton/Label").text)
				i.get_node("TextureButton").emit_signal("pressed")

func _on_Buttontest_pressed():
	_press_active_button()

func _on_Timer_timeout():
	timer_started = false
	print("Move started"+active_direction)
	_moveto_next_button()
	# print("Cycle complete")


func _on_TimerPressButton_timeout():
	timer_pressed_started = false
	_press_active_button()


func _on_TextEdit_text_changed():
	_predict_next_character()
