from transformers import AutoTokenizer, AutoModelForMaskedLM, pipeline
import json
from flask_cors import CORS
from flask import Flask, request
from fuzzywuzzy import fuzz
from fuzzywuzzy import process

app = Flask(__name__)
CORS(app)

model_source = "jcblaise/roberta-tagalog-large"

tokenizer = AutoTokenizer.from_pretrained(model_source)

model = AutoModelForMaskedLM.from_pretrained(model_source)

sequence = "ak"

generator = pipeline('fill-mask', model=model, tokenizer=tokenizer)

character_rankings = {}
common_words = []

f = open('server/character_rankings.json')
character_rankings = json.load(f)

f = open('server/common_words.txt')
for i in f.readlines():
    common_words.append(i.rstrip('\n'))

f.close()


def fuzzy_scorer(s1, s2):
    ratio = fuzz.ratio(s1, s2)
    ratio -= (s2.find(s1) * 5)
    return ratio


@app.route("/", methods=['GET', 'POST'])
def recommend():

    _text = ""

    if request.method == 'POST':
        _text = request.json['text']
    else:
        print(request.args)
        _text = request.args.get('text')
        print(_text)

    html = ""
    fuzzyword = ""
    if str(_text) == "None":
        res = generator(' <mask>.')
        print("request: none")
    else:
        res = generator(_text + ' <mask>.')
        fuzzy_character_matching = process.extract(
            _text, common_words, scorer=fuzzy_scorer)
        fuzzyword = fuzzy_character_matching[0]

    string_group = ""

    for i in res:
        string_group += i['token_str']

    next_characters = "".join(set(string_group))
    html += string_group + "<br />"
    html += "".join(set(string_group))

    next_character_rankings = []

    for j in character_rankings:
        if j in next_characters:
            next_character_rankings.append({
                'char': j,
                'weight': character_rankings[j]
            })

    next_character_rankings_sorted = sorted(
        next_character_rankings, key=lambda x: x['weight'], reverse=True)
    word_list = []

    if len(fuzzyword) > 0:
        word_list = [{"sequence": fuzzyword[0], "score": fuzzyword[1]}] + res
    else:
        word_list = res

    jsondump = {
        "wordList": word_list,
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
