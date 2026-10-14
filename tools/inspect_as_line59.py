with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i in range(max(0, 50), min(len(lines), 75)):
    print(f'{i+1}: {repr(lines[i])}')
