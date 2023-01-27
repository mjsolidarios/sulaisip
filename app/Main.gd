extends Control

var file = File.new()
var data
var character_frequency_data:Dictionary
var CharacterButton = preload("res://components/CharacterButton.tscn")
var url = "http://127.0.0.1:5000"
var headers = ["Content-Type: application/json"]
var use_ssl=true
var query := {}
var current_page = 0
var next_characters:String = ""

export var websocket_url = "ws://127.0.0.1:1880"
var _wsclient = WebSocketClient.new()

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
	$VBoxContainer/HBoxContainer/GridContainer.add_child(button)

func _populate_character_grid():
	
	# clear node
	var children = $VBoxContainer/HBoxContainer/GridContainer.get_children()
	for i in children:
		$VBoxContainer/HBoxContainer/GridContainer.remove_child(i)
	
	var character_bucket = ""
	var all_characters_string = _array_to_string(character_frequency_data.keys())
	
	for i in all_characters_string:
		if i in next_characters:
			all_characters_string = all_characters_string.replace(i, "")
	
	character_bucket = (next_characters+all_characters_string).replace(" ", "").to_lower()
	
	# pagination
	print(character_bucket)
	print(next_characters)
	
	if current_page == 0:
		for i in character_bucket.substr(0, 5):
			print("p1:"+character_bucket.substr(0, 5))
			_create_instanced_button(i)
	if current_page == 1:
		for i in character_bucket.substr(6, 5):
			print("p2:"+character_bucket.substr(6, 5))
			_create_instanced_button(i)
	if current_page == 2:
		for i in character_bucket.substr(12, 5):
			print("p3:"+character_bucket.substr(12, 5))
			_create_instanced_button(i)
	if current_page == 3:
		for i in character_bucket.substr(18, 5):
			print("p4:"+character_bucket.substr(18, 5))
			_create_instanced_button(i)
	if current_page == 4:
		for i in character_bucket.substr(24, 5):
			print("p5:"+character_bucket.substr(24, 5))
			_create_instanced_button(i)
	
func _ready():
	file.open("res://data/character_rankings.json", File.READ)
	character_frequency_data = parse_json(file.get_as_text())
	$VBoxContainer/TextEdit.text = " "
	_predict_next_character()
	
	# websocket
	_wsclient.connect("connection_closed", self, "_wsclosed")
	_wsclient.connect("connection_error", self, "_wserror")
	_wsclient.connect("connection_established", self, "_wsconnected")
	_wsclient.connect("data_received", self, "_wson_data")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_page == 0:
		$VBoxContainer/HBoxContainer/PreviousButton.state = "disabled"
	else:
		$VBoxContainer/HBoxContainer/PreviousButton.state = "normal"
	
	if current_page == 4:
		$VBoxContainer/HBoxContainer/NextButton.state = "disabled"
	else:
		$VBoxContainer/HBoxContainer/NextButton.state = "normal"
	
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
	print("Got data from server: ", _wsclient.get_peer(1).get_packet().get_string_from_utf8())

	
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
		$HTTPRequest.request(url, headers, use_ssl, HTTPClient.METHOD_POST, to_json(query))
	else:
		$HTTPRequest.request(url)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())	
#	print(json.result['nextCharacters'])
#	print(json.result['stringGroup'])
#	print(json.result['wordList'])
	
	# clear node
	var children = $VBoxContainer/TextSuggestions.get_children()
	for i in children:
		$VBoxContainer/TextSuggestions.remove_child(i)
	
	next_characters = json.result['nextCharacters']

	for i in json.result['wordList']:
		var button = CharacterButton.instance()
		var TrimmedText = i['sequence'].replace(".", "").split(' ')[-1]
		button.text = TrimmedText.to_lower()
		button.get_node("TextureButton").connect("pressed", self, "_predict_next_character", [i['token_str']])
		
		$VBoxContainer/TextSuggestions.add_child(button)
	
	_populate_character_grid()

func _on_Button_pressed():
	_predict_next_character()


func _on_Buttontest_pressed():
	$VBoxContainer/GridContainer.get_child(1).state = 'pressed'
