extends Control

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


onready var text_suggestions_node = get_node("VBoxContainer/NinePatchRect/MarginContainer/TextSuggestions")
onready var button_keys_node = get_node("VBoxContainer/NinePatchRect2/MarginContainer/HBoxContainer")
onready var button_char_keys_node = get_node("VBoxContainer/NinePatchRect2/MarginContainer/HBoxContainer/GridContainer")
onready var char_grid = button_char_keys_node

var timer_started = false
var timer_pressed_started = false
var active_direction = "right"

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
	else:
		if active_group == "top":
			active_button_top_index += 1
		else:
			active_button_bottom_grid_index += 1
			
	if active_button_top_index > 4:
		active_button_top_index = 0
	if active_button_bottom_grid_index > 7:
		active_button_bottom_grid_index = 0
		
	# print(active_button_top_index, ",", active_button_bottom_grid_index)
	

func _del_char():
	var text = $VBoxContainer/TextEdit.text
	if text.length() > 0:
		$VBoxContainer/TextEdit.text = text.substr(0, text.length() - 1)
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
	
	# pagination
	# print(character_bucket)
	# print(next_characters)
	
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
	$VBoxContainer/TextEdit.text = " "
	_predict_next_character()
	print(_wsclient)
	# websocket
	
func _exit_tree():
	thread.wait_to_finish()
	
func _input(event):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active_group == "top":
		$VBoxContainer/NinePatchRect.is_active = true
		$VBoxContainer/NinePatchRect2.is_active = false
	else:
		$VBoxContainer/NinePatchRect.is_active = false
		$VBoxContainer/NinePatchRect2.is_active = true
	
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

func _wsconnected(proto = ""):
	print("Connected with protocol: ", proto)

func _wsclosed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)
	
func _wserror(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)

func _wsondata():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	
	var data = _wsclient.get_peer(1).get_packet().get_string_from_utf8()
	var parsed_data = data.replace("[", "").replace("]", "").split(",")
#	var neutral = parsed_data[0].to_int()
#	var smile = parsed_data[1].to_int()
#	var left = parsed_data[2].to_int()
#	var right = parsed_data[3].to_int()
#	var push = parsed_data[4].to_int()
#	var pull = parsed_data[5].to_int()

	var blink = parsed_data[0].to_float()
	var left = parsed_data[1].to_float()
	var right = parsed_data[2].to_float()
	var aX = abs(parsed_data[3].to_float())
	var aY = abs(parsed_data[4].to_float())
	var aZ = abs(parsed_data[5].to_float())
	
	print("left: "+str(left),"|","right: "+str(right)) 

#	if !timer_started:
#		$Timer.start()
#		timer_started = true
	
#	if (left != 0 and !(left > 100)):
#		print("left: "+str(left)) # move_right
#		active_direction = "right"
#		if !timer_started:
#			$Timer.start()
#	if (right != 0 and !(right > 100)):
#		#print("right: "+str(right)) # move_left
#		active_direction = "left"
#		if !timer_started:
#			$Timer.start()
	if left > 0:
		active_direction = "left"
		if !timer_started:
			$Timer.start()
			timer_started = true
	if right > 0:
		active_direction = "right"
		if !timer_started:
			$Timer.start()
			timer_started = true
		
	if blink != 0 and blink == 100:
		if !timer_pressed_started:
			$TimerPressButton.start()
			timer_pressed_started = true
		blink = 0
	
	var pitch = abs(atan2(-aX, aZ) * 180 / PI )
	var roll = abs(atan2(-aY, aZ) * 180 / PI)
	var pitch_to_rad = deg2rad(pitch)
	var roll_to_rad = deg2rad(roll)
	# print("pitch:"+str(pitch), " | roll:"+str(roll))
	
#	if pitch < 50 and pitch > 30:
#		active_group = "top"
#	if pitch > 70:
#		active_group = "bottom"
	if roll > 20 and roll != 90:
		#print(roll_to_rad)
		if roll_to_rad > 1:
			active_group = "top"
		else:
			active_group = "bottom"
	
	
	# print(smile,",", left,",", right,",", push,",", pull)
	
func _add_text_to_input(var character):
	$VBoxContainer/TextEdit.text += character
	_predict_next_character()

func _predict_next_character(text_fill:=""):
	var current_text = $VBoxContainer/TextEdit.text
	if text_fill.length() > 0:
		$VBoxContainer/TextEdit.text = current_text+text_fill+" "
	
	if $VBoxContainer/TextEdit.text.length() > 0:
		query = { "text": $VBoxContainer/TextEdit.text }
	else:
		query = { "text": "" }
	
	if current_text.length()>0:
		$HTTPRequest.request(nlp_server_url, headers, use_ssl, HTTPClient.METHOD_POST, to_json(query))
	else:
		$HTTPRequest.request(nlp_server_url)
	current_page = 0

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())	
#	print(json.result['nextCharacters'])
#	print(json.result['stringGroup'])
#	print(json.result['wordList'])
	
	# clear node
	var children = text_suggestions_node.get_children()
	for i in children:
		text_suggestions_node.remove_child(i)
	
	next_characters = json.result['nextCharacters']

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
	if active_button_top_index > 4:
		active_button_top_index = 0
	if active_button_bottom_grid_index > 7:
		active_button_bottom_grid_index = 0
	# print(active_button_top_index, ",", active_button_bottom_grid_index)

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
