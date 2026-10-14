with open('team/gameplay/src/ReplicatedStorage/Shared/Config.lua', 'r', encoding='utf-8') as f:
    text = f.read()
idx = text.find('TRAINING_RUNTIME')
print('idx:', idx)
if idx != -1:
    print(text[idx-50:idx+200])
