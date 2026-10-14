import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Edit"): return call("execute_luau",{"code":code,"datamodel_type":dm})
for id in ["u7_goku","u7_vegeta","u7_frieza"]:
    has=L('local s=workspace["Seg_%s"] for _,k in s:GetDescendants() do if k:IsA("MeshPart") and k.Name=="left leg" then return "yes" end end return "no"'%id).strip()
    if has=="yes": print(id,"already split",flush=True); continue
    path=L('local s=workspace["Seg_%s"] for _,k in s:GetDescendants() do if k:IsA("MeshPart") and k.Name=="LegsSeg" then return k:GetFullName() end end return "none"'%id).strip()
    r=call("segment_mesh",{"instance_path":path,"parts":["left leg","right leg"]})
    print(id,"legs",str(r)[:200],flush=True)
print(L(open("insp.lua").read()),flush=True)
print(L(open("assemble.lua").read().replace('legs = "LowerTorso"','LegsSeg = "LowerTorso"')),flush=True)
print("DONE")
p.terminate()
