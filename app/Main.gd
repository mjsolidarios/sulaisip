extends Control

var file = File.new()
var data
var character_frequency_data:Dictionary

func _ready():
	file.open("res://data/character_rankings.json", File.READ)
	character_frequency_data = parse_json(file.get_as_text())
	
	for i in character_frequency_data.keys():
		var button = Button.new()
		button.text = i
		button.connect("pressed", self, "_add_text_to_input", [i])
		$VBoxContainer/GridContainer.add_child(button)
	
	$VBoxContainer/Button.emit_signal("gui_input")

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
		var TextButton = Button.new()
		var TrimmedText = i['sequence'].replace(".", "")
		TextButton.text = TrimmedText
		TextButton.connect("pressed", self, "_predict_next_character", [i['token_str']])
		$VBoxContainer/TextSuggestions.add_child(TextButton)
		
func _on_Button_pressed():
	_predict_next_character()
