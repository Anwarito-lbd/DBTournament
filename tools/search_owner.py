import os
for root, dirs, files in os.walk('.'):
    for f in files:
        if f.endswith('.lua'):
            p = os.path.join(root, f)
            with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                for i, l in enumerate(fp):
                    if '.owner' in l or '["owner"]' in l or '[\'owner\']' in l:
                        print(f'{p}:{i+1}: {l.strip()}')
