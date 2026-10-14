import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Edit"): return call("execute_luau",{"code":code,"datamodel_type":dm})
print(L(open("prep.lua").read()))
for id in ["u7_goku","u7_vegeta","u7_frieza"]:
    mp=L('local s=workspace["Seg_%s"] local m=s:FindFirstChildWhichIsA("MeshPart") return m and m:GetFullName() or "none"'%id).strip()
    r=call("segment_mesh",{"instance_path":mp,"parts":["head","torso","left arm","right arm","legs"]})
    print(id,"seg1",str(r)[:400],flush=True)
print(L('local o={} for _,c in workspace:GetChildren() do if c:IsA("Model") and not c:FindFirstChildOfClass("Humanoid") and c.Name~="Camera" and #c:GetChildren()<12 and c:FindFirstChildWhichIsA("MeshPart") then local n={} for _,x in c:GetChildren() do table.insert(n,x.Name) end table.insert(o,c.Name.." ["..table.concat(n,",").."] "..tostring(c:GetPivot().Position)) end end return table.concat(o,"\\n")'))
p.terminate()
