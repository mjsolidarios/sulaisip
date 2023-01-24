extends Control

var file = File.new()
var data
var character_frequency_data:Dictionary
var CharacterButton = preload("res://components/CharacterButton.tscn")

func _ready():
	file.open("res://data/character_rankings.json", File.READ)
	character_frequency_data = parse_json(file.get_as_text())
	
	for i in character_frequency_data.keys().slice(0,5):
		var button = CharacterButton.instance()
		button.text = i
		button.rect_size = Vector2(90,80)
		button.get_node("TextureButton").connect("pressed", self, "_add_text_to_input", [i])
		$VBoxContainer/HBoxContainer/GridContainer.add_child(button)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _add_text_to_input(var character):
	$VBoxContainer/TextEdit.text += character
	_predict_next_character()

func _predict_next_character(text_fill:=""):
	var current_text = $VBoxContainer/TextEdit.text
	if text_fill.length() > 0:
		$VBoxContainer/TextEdit.text = current_text+text_fill+" "
	var url = "http://127.0.0.1:5000"
	var headers = ["Content-Type: application/json"]
	var use_ssl=true
	
	var query := { "text": $VBoxContainer/TextEdit.text }
	
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
	var TextSuggestionsChildren = $VBoxContainer/TextSuggestions.get_children()
	for i in TextSuggestionsChildren:
		$VBoxContainer/TextSuggestions.remove_child(i)
		
	for i in json.result['wordList']:
		var button = CharacterButton.instance()
		var TrimmedText = i['sequence'].replace(".", "").split(' ')[-1]
		button.text = TrimmedText
		button.get_node("TextureButton").connect("pressed", self, "_predict_next_character", [i['token_str']])
		
		$VBoxContainer/TextSuggestions.add_child(button)
		
func _on_Button_pressed():
	_predict_next_character()


func _on_Buttontest_pressed():
	$VBoxContainer/GridContainer.get_child(1).state = 'pressed'
