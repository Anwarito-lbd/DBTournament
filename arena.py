import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Server"): return call("execute_luau",{"code":code,"datamodel_type":dm})
print(L(open("ren.lua").read(),"Edit"))
print(L('workspace:SetAttribute("DevHoldLobby",true) return 1',"Edit"))
print(call("start_stop_play",{"is_start":True})); time.sleep(6)
for T,P in [(2,3),(4,8)]:
    print(L('''local A=require(game.ServerScriptService.Modules.Arena) local ok=A.resize(%d,%d)
local a=workspace.WorldOfVoid.Arena local sp=0 local teams={} for _,s in a.Spawns:GetChildren() do sp+=1 teams[s:GetAttribute("Team")]=(teams[s:GetAttribute("Team")] or 0)+1 end
local t={} for k,v in teams do table.insert(t,k.."="..v) end
local b=a.Zones.Zone_RingBounds local dec=#workspace.WorldOfVoid.Decor:GetDescendants()
return string.format("resize ok=%%s T=%%s P=%%s R=%%s bands=%%s chunks=%%d stands=%%d spawns=%%d teams[%%s] boundsR=%%s ring=%%s decor=%%d first=%%s",tostring(ok),tostring(a:GetAttribute("TeamCount")),tostring(a:GetAttribute("PlayerCount")),tostring(a:GetAttribute("Radius")),tostring(a:GetAttribute("Bands")),#a.Ring.Chunks:GetChildren(),#a.Stands:GetChildren(),sp,table.concat(t,","),tostring(b:GetAttribute("Radius")),tostring(b:GetAttribute("RingRadius")),dec,a.Spawns:GetChildren()[1].Name)'''%(T,P)),flush=True)
    r=float(L('return workspace.WorldOfVoid.Arena:GetAttribute("Radius")'))
    time.sleep(2)
    print(call("screen_capture",{"camera_position":[r*1.2,500+r*1.6,r*1.9],"look_at_position":[0,500,0],"capture_id":"v2_arena_T%d_P%d"%(T,P)}),flush=True)
print(L('local AD=require(game.ServerScriptService.ArenaDamage) AD.Init() local n=AD.DamageAt(Vector3.new(0,500,0),18,400) return "damage chunks hit="..tostring(n)'))
print(call("get_console_output",{})[-1500:])
print(call("start_stop_play",{"is_start":False}))
time.sleep(2)
print(L('workspace:SetAttribute("DevHoldLobby",nil) return 1',"Edit"))
p.terminate()
