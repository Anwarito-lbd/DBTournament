import json,re
ok=[];bad=[]
for l in open("sketchfab_out/pipeline_log.jsonl",encoding="utf-8"):
    s=l
    m=re.search(r'RESULT:(\{.*?\})(\\n|")',s.replace('\\"','"').replace('\\\\','\\'))
    if m:
        try: ok.append(json.loads(m.group(1)))
        except Exception as e: bad.append(s[:150])
    else:
        bad.append(s[:300])
json.dump(ok,open("sketchfab_out/summary.json","w"),indent=0)
print(len(ok),"ok",len(bad),"bad")
for b in bad: print("BAD",b[-300:])
