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
    args=dict(args); args.setdefault('studio_id',SID) if SID else None
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
SID=None
for _k in range(60):
    try:
        _r=rpc("tools/call",{"name":"list_roblox_studios","arguments":{}})
        _t="".join(c.get("text","") for c in _r.get("result",{}).get("content",[]))
        _ids=re.findall(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',_t)
        if _ids:
            _m=[i for i in _ids if "Place1" in _t[max(0,_t.find(i)-300):_t.find(i)+300]]
            SID=(_m or _ids)[0]; print("STUDIO",SID,flush=True); break
    except Exception as _e: print("wait",_e)
    time.sleep(5)

import os
T=r"team"
PROTECT=("CharacterSelectUI","MobileControls","Tutorial")
proj=json.load(open(T+r"\default.project.json",encoding="utf-8"))
items=[]
def cls_of(f):
    if f.endswith(".server.lua"): return "Script", f[:-11]
    if f.endswith(".client.lua"): return "LocalScript", f[:-11]
    if f.endswith(".lua"): return "ModuleScript", f[:-4]
    return None, None
def walk(node, path):
    p=node.get("$path")
    if p:
        fp=os.path.join(T,p.replace("/","\\"))
        if os.path.isdir(fp):
            for f in sorted(os.listdir(fp)):
                c,n=cls_of(f)
                if c and n not in node: items.append((path+[n],c,os.path.join(fp,f)))
        else:
            c,n=cls_of(fp); items.append((path,c,fp))
    for k,v in node.items():
        if not k.startswith("$") and isinstance(v,dict): walk(v, path+[k])
for svc,v in proj["tree"].items():
    if not svc.startswith("$"): walk(v,[svc])
def lstr(s):
    n=1
    while ("]"+"="*n+"]") in s: n+=1
    return "["+"="*n+"["+s+"]"+"="*n+"]"
only=[a for a in sys.argv[1:] if not a.startswith("--")]
ok=0
for path,cls,f in items:
    if only and path[-1] not in only: continue
    if any(k in path[-1] for k in PROTECT): print("SKIP (protected)",path[-1]); continue
    src=open(f,encoding="utf-8").read()
    code="local parent=game:GetService(%s)\n"%json.dumps(path[0])
    for seg in path[1:-1]:
        code+='local c=parent:FindFirstChild(%s); if not c then c=Instance.new("Folder"); c.Name=%s; c.Parent=parent end; parent=c\n'%(json.dumps(seg),json.dumps(seg))
    code+='local old=parent:FindFirstChild(%s); local kids={} if old then for _,k in ipairs(old:GetChildren()) do if k:IsA("LuaSourceContainer") then k.Parent=nil table.insert(kids,k) end end old:Destroy() end\nlocal s=Instance.new("%s"); s.Name=%s; s.Source=%s; s.Parent=parent for _,k in ipairs(kids) do k.Parent=s end\nreturn s:GetFullName()'%(json.dumps(path[-1]),cls,json.dumps(path[-1]),lstr("\n"+src))
    r=call("execute_luau",{"code":code})
    if "rror" in r: print("FAIL",path,r[:300])
    else: ok+=1
print("installed",ok,"of",len(items))
p.terminate()
