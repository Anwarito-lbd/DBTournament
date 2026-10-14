import json,sys
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
for t in rpc("tools/list",{})["result"]["tools"]:
    if t["name"] in ("segment_mesh",) or "rig" in t["name"].lower() or "avatar" in t["name"].lower() or "anim" in t["name"].lower():
        print(t["name"], t.get("description","")[:1500]); print(json.dumps(t["inputSchema"],indent=0)[:4000]); print("====")
p.terminate()
