import json,subprocess,sys
EXE=r"C:\Users\issao\AppData\Local\Roblox\Versions\version-9b554450a0fc4e65\StudioMCP.exe"
p=subprocess.Popen([EXE],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True,encoding="utf-8")
i=0
def rpc(m,params=None,notify=False):
    global i
    msg={"jsonrpc":"2.0","method":m}
    if params is not None: msg["params"]=params
    if not notify: i+=1; msg["id"]=i
    p.stdin.write(json.dumps(msg)+"\n"); p.stdin.flush()
    if notify: return None
    while True:
        r=json.loads(p.stdout.readline())
        if r.get("id")==i: return r
rpc("initialize",{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"roblox-bot","version":"1"}})
rpc("notifications/initialized",{},True)
import time; time.sleep(6)
if sys.argv[1]=="list":
    for t in rpc("tools/list",{})["result"]["tools"]: print(t["name"],"|",json.dumps(t.get("inputSchema",{}).get("properties",{}))[:300])
else:
    args=json.load(open(sys.argv[2],encoding="utf-8"))
    r=rpc("tools/call",{"name":sys.argv[1],"arguments":args})
import base64
for c in r.get("result",{}).get("content",[]):
    if c.get("type")=="image": open(sys.argv[1]+".png","wb").write(base64.b64decode(c["data"])); print("IMG_SAVED")
    else: print(str(c)[:3000])
p.terminate()


