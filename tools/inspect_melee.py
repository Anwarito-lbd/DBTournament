with open('team/gameplay/src/ServerScriptService/Modules/Combat.lua', 'r', encoding='utf-8') as f:
    text = f.read()
idx = text.find('local toTarget = targetPos - root.Position')
print(repr(text[idx-40:idx+250]))
