with open('team/gameplay/src/StarterPlayer/StarterPlayerScripts/GameFeel.client.lua', 'r', encoding='utf-8') as f:
    text = f.read()
idx = text.find('-- ===== lock-on =====')
if idx != -1:
    print(text[idx:])
