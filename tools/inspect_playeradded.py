with open('team/gameplay/src/ServerScriptService/Modules/Combat.lua', 'r', encoding='utf-8') as f:
    text = f.read()
import re
for m in re.finditer(r'PlayerAdded', text):
    print(text[m.start()-50:m.end()+250])
    print('---')
