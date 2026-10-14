with open('team/gameplay/src/StarterPlayer/StarterPlayerScripts/GameFeel.client.lua', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('-- ===== lock-on =====')
if idx != -1:
    text = text[:idx]
    with open('team/gameplay/src/StarterPlayer/StarterPlayerScripts/GameFeel.client.lua', 'w', encoding='utf-8') as f:
        f.write(text)
    print('Removed redundant lock-on from GameFeel.client.lua!')
