import os
for root, dirs, files in os.walk('team'):
    for f in files:
        if f.endswith('.server.lua') or f.endswith('.lua'):
            p = os.path.join(root, f)
            with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                t = fp.read()
                if 'require(' in t and 'Combat)' in t:
                    print(f'{p}: requires Combat')
