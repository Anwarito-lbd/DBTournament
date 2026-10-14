import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Edit"): return call("execute_luau",{"code":code,"datamodel_type":dm})
for id in ["u7_goku","u7_vegeta","u7_frieza"]:
    r=call("segment_mesh",{"instance_path":"Workspace.Seg_%s.body_geom.legs"%id,"parts":["left leg","right leg"]})
    print(id,"legs",str(r)[:200],flush=True)
print(L(open("insp.lua").read()),flush=True)
print(L(open("assemble.lua").read()),flush=True)
p.terminate()
