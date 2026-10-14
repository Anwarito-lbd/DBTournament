with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'r', encoding='utf-8') as f:
    text = f.read()

import re
# Replace all unquoted rbxassetid://... with "rbxassetid://..."
text = re.sub(r'(?<!")rbxassetid://(\d+)(?!")', r'"rbxassetid://\1"', text)

with open('team/gameplay/src/ServerScriptService/Modules/AvatarSlots.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print('Fixed unquoted rbxassetid strings in AvatarSlots.lua!')
