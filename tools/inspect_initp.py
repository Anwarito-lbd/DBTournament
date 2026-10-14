with open('team/gameplay/src/ServerScriptService/Modules/Combat.lua', 'r', encoding='utf-8') as f:
    text = f.read()
idx = text.find('local function initPlayer')
print(text[idx:idx+400])
