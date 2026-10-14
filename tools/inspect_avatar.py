with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'r', encoding='utf-8') as f:
    text = f.read()
idx = text.find('function AvatarSlots.applyForm')
print(text[idx:])
