import json,subprocess,sys,os,time,re
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
def call(name,args):
    args=dict(args); args.setdefault('studio_id','d783750c-1f37-4381-9f4d-f9dba1040113')
    if name in ('execute_luau','multi_edit','inspect_instance'): args.setdefault('datamodel_type','Edit')
    r=rpc("tools/call",{"name":name,"arguments":args})
    out=[]
    for c in r.get("result",{}).get("content",[]):
        if c.get("type")=="image":
            import base64; fn=args.get("capture_id","shot")+".png"; open(fn,"wb").write(base64.b64decode(c["data"])); out.append("IMG "+fn)
        else: out.append(c.get("text",str(c)))
    if "error" in r: out.append("ERR "+json.dumps(r["error"]))
    return "\n".join(out)
rpc("initialize",{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"roblox-bot","version":"1"}})
rpc("notifications/initialized",{},True); time.sleep(6)
T=r"team"
G=T+r"\gameplay\src"
items=[]  # (pathlist, class, file)
def add(path,cls,f): items.append((path,cls,f))
for f in os.listdir(G+r"\ReplicatedStorage\Shared"): add(["ReplicatedStorage","Shared",f[:-4]],"ModuleScript",G+r"\ReplicatedStorage\Shared\\"+f)
for f in os.listdir(G+r"\ServerScriptService\Modules"): add(["ServerScriptService","Modules",f[:-4]],"ModuleScript",G+r"\ServerScriptService\Modules\\"+f)
add(["ServerScriptService","RoundManager"],"Script",G+r"\ServerScriptService\RoundManager.server.lua")
for f in os.listdir(G+r"\StarterPlayer\StarterPlayerScripts"): add(["StarterPlayer","StarterPlayerScripts",f.replace(".client.lua","")],"LocalScript",G+r"\StarterPlayer\StarterPlayerScripts\\"+f)
for f in os.listdir(T+r"\animation"):
    if f.endswith(".lua") and not f.endswith(".client.lua"): add(["ReplicatedStorage","VFX",f[:-4]],"ModuleScript",T+r"\animation\\"+f)
if "--test" in sys.argv: add(["StarterPlayer","StarterPlayerScripts","KamehamehaTest"],"LocalScript",T+r"\animation\KamehamehaTest.client.lua")
add(["ReplicatedStorage","StoryDialogue"],"ModuleScript",T+r"\StoryDialogue.lua")
def lstr(s):
    n=1
    while ("]"+"="*n+"]") in s: n+=1
    return "["+"="*n+"["+s+"]"+"="*n+"]"
only=[a for a in sys.argv[1:] if not a.startswith("--")]
for path,cls,f in items:
    if only and path[-1] not in only: continue
    src=open(f,encoding="utf-8").read()
    code="local parent=game:GetService(%s)\n"%json.dumps(path[0])
    for seg in path[1:-1]:
        code+='local c=parent:FindFirstChild(%s); if not c then c=Instance.new("Folder"); c.Name=%s; c.Parent=parent end; parent=c\n'%(json.dumps(seg),json.dumps(seg))
    code+='local old=parent:FindFirstChild(%s); if old then old:Destroy() end\nlocal s=Instance.new("%s"); s.Name=%s; s.Source=%s; s.Parent=parent\nreturn s:GetFullName()'%(json.dumps(path[-1]),cls,json.dumps(path[-1]),lstr("\n"+src))
    print(path, call("execute_luau",{"code":code})[:300])
p.terminate()
