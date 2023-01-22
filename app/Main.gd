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

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _add_text_to_input(var character):
	$VBoxContainer/TextEdit.text += character
	_predict_next_character()

func _predict_next_character():
	var current_text = $VBoxContainer/TextEdit.text
#	print(current_text)
	var url = "http://127.0.0.1:5000"
	var headers = ["Content-Type: application/json"]
	var use_ssl=true
	
	var query := { "text": current_text }
	
	if current_text.length()>0:
		# print("current_text.length(): "+str(current_text.length()))
		# print(query)
		$HTTPRequest.request(url, headers, false, HTTPClient.METHOD_POST, to_json(query))
	else:
		$HTTPRequest.request(url)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print(result)
	var json = JSON.parse(body.get_string_from_utf8())	
	print(json.result['nextCharacters'])
	print(json.result['stringGroup'])
	print(json.result['wordList'])


func _on_Button_pressed():
	_predict_next_character()
