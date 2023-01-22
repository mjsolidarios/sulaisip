import json
from flask_cors import CORS
from flask import Flask, request

app = Flask(__name__)
CORS(app)

from transformers import AutoTokenizer, AutoModelForMaskedLM, pipeline

model_source = "jcblaise/roberta-tagalog-large"

tokenizer = AutoTokenizer.from_pretrained(model_source)

model = AutoModelForMaskedLM.from_pretrained(model_source)

sequence = "ak"

generator = pipeline('fill-mask', model=model, tokenizer=tokenizer)

character_rankings = {}

f = open('character_rankings.json')
character_rankings = json.load(f)
f.close()


@app.route("/",  methods=['GET', 'POST'])
def recommend():
    if request.method == 'POST':
      _text = request.form['text']
    else:
      _text = request.args.get('text')

    html = ""
    if str(_text) == "None":
        res = generator(' <mask>.')
        print("request: none")
    else:
        res = generator(_text + ' <mask>.')
        print("request:"+_text)
    string_group = ""

    for i in res:
        string_group += i['token_str']
    next_characters = "".join(set(string_group))
    html += string_group + "<br />"
    html += "".join(set(string_group))

    next_character_rankings = []

    for i in character_rankings:
        if i in next_characters:
            next_character_rankings.append({
                'char': i,
                'weight': character_rankings[i]
            })

    next_character_rankings_sorted = sorted(next_character_rankings, key=lambda x: x['weight'], reverse=True)

    jsondump = {
        "wordList": res,
        "stringGroup": string_group,
        "nextCharacters": next_characters,
        "nextCharactersRanked": next_character_rankings_sorted
    }

    response = app.response_class(
        response=json.dumps(jsondump),
        status=200,
        mimetype='application/json'
    )

    return response
