import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
ids=sys.argv[1:]
for i,id in enumerate(ids):
    code='''local id="%s" local lib=game.ReplicatedStorage.CharacterModels local src=lib:FindFirstChild(id) if not src then return "missing" end
local sc=workspace:FindFirstChild("ModelShowcase") or Instance.new("Model",workspace) sc.Name="ModelShowcase" sc:ClearAllChildren()
local floor=Instance.new("Part",sc) floor.Anchored=true floor.Size=Vector3.new(80,1,80) floor.CFrame=CFrame.new(0,1499.5,0) floor.Color=Color3.fromRGB(60,55,80) floor.Material=Enum.Material.Slate
local m=src:Clone() for _,d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored=true end end m.Parent=sc
local cf,size=m:GetBoundingBox() m:PivotTo(m:GetPivot()+(Vector3.new(0,1500+size.Y/2,0)-cf.Position))
local l=Instance.new("PointLight",floor) l.Range=60 l.Brightness=3
local cf2,s2=m:GetBoundingBox() local h=math.max(s2.Y,s2.X) local d=h*1.6+2
local cam=cf2.Position+Vector3.new(d*0.35,h*0.1,d) local l2=Instance.new("Part",sc) l2.Anchored=true l2.Transparency=1 l2.CanCollide=false l2.Position=cam local pl=Instance.new("PointLight",l2) pl.Range=d*2 pl.Brightness=4
return string.format("%%f,%%f,%%f,%%f,%%f,%%f",cam.X,cam.Y,cam.Z,cf2.Position.X,cf2.Position.Y,cf2.Position.Z)'''%id
    r=call("execute_luau",{"code":code,"datamodel_type":"Edit"})
    print(id,r,flush=True)
    if "missing" in r: continue
    v=[float(x) for x in r.strip().split(",")]
    time.sleep(2)
    print(call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":"model_"+id}),flush=True)
call("execute_luau",{"code":'local s=workspace:FindFirstChild("ModelShowcase") if s then s:Destroy() end return 1',"datamodel_type":"Edit"})
p.terminate()
