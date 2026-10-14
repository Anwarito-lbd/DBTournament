import json,sys
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
for t in rpc("tools/list",{})["result"]["tools"]:
    if t["name"] in ("generate_mesh","generate_texture","wait_job_finished"):
        print(t["name"], t.get("description","")[:1500]); print(json.dumps(t["inputSchema"],indent=0)[:4000]); print("====")
p.terminate()
