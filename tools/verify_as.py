with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i in range(56, 85):
    print(f'{i+1}: {repr(lines[i])}')
