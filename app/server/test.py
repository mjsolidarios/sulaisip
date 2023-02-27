# from fuzzywuzzy import fuzz
# from fuzzywuzzy import process
# f = open('server/tagalog_dict.txt')
#
# wordlist = []
#
# for i in f.readlines():
#     wordlist.append(i.rstrip('\n'))
#
# print(process.extract("zin", wordlist)[0][0])
# print([0]+[0,2])

from flask import Flask

app = Flask(__name__)


@app.route('/')
def hello_name():
    return 'Hello!'


if __name__ == '__main__':
    app.run()
