import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def state(): return L('return tostring(workspace:GetAttribute("RoundState"))',"Server")
def shot(cid):
    r=L('local c=workspace.CurrentCamera.CFrame local p=c.Position local l=p+c.LookVector*20 return string.format("%f,%f,%f,%f,%f,%f",p.X,p.Y,p.Z,l.X,l.Y,l.Z)')
    v=[float(x) for x in r.strip().split(",")]
    print(cid, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":cid}), flush=True)
ARENA='''local a=workspace.WorldOfVoid.Arena local p=game.Players:GetPlayers()[1] local r=p.Character.HumanoidRootPart.Position local best,bd=nil,1e9 for _,s in a.Spawns:GetChildren() do local d=(s.Position-r).Magnitude if d<bd then best,bd=s,d end end return string.format("R=%s T=%s P=%s nearestPad=%s team=%s dist=%.1f",tostring(a:GetAttribute("Radius")),tostring(a:GetAttribute("TeamCount")),tostring(a:GetAttribute("PlayerCount")),best and best.Name or "-",best and tostring(best:GetAttribute("Team")) or "-",bd)'''
print(call("start_stop_play",{"is_start":True}))
t0=time.time()
while time.time()-t0<60 and state()!="Intro": time.sleep(0.3)
ti=time.time()
print("arena@intro",L(ARENA,"Server"))
for t,n in [(3,"intro_01_void"),(11,"intro_02_crane"),(19,"intro_03_priest"),(30,"intro_04_zenos_guards"),(34,"intro_05_zeno"),(42,"intro_07_ringglow"),(73,"intro_11_stands"),(92,"intro_13_countdown")]:
    while time.time()-ti<t: time.sleep(0.2)
    if state()!="Intro": print("left intro at",time.time()-ti); break
    shot("v2_"+n)
    if n=="intro_04_zenos_guards": print("actors",L('local o={} for _,c in workspace:GetChildren() do if c.Name:sub(1,6)=="Story_" then table.insert(o,c.Name) end end return table.concat(o,",")'))
while time.time()-t0<220 and state()!="InRound": time.sleep(0.5)
time.sleep(2)
print("arena@round",L(ARENA,"Server"))
print(L('local n=0 for _,m in workspace:GetDescendants() do if m:IsA("Humanoid") and not game.Players:GetPlayerFromCharacter(m.Parent) and m.Parent:GetAttribute("IsBot") then m.Health=0 n+=1 end end return "killed bots "..n',"Server"))
while time.time()-t0<280 and state()!="Ending": time.sleep(0.3)
te=time.time(); print("state",state())
for t,n in [(2,"end_01_winners"),(13,"end_04_balls_gather"),(21,"end_05_stage_flare"),(29,"end_06_shenron_reveal"),(35,"end_07_shenron_low"),(41,"end_08_wishchoice")]:
    while time.time()-te<t: time.sleep(0.2)
    if state()!="Ending": print("left ending",time.time()-te); break
    shot("v2_"+n)
print(L('game.ReplicatedStorage.Remotes.WishChoice:FireServer("Power") return "wished"'))
time.sleep(8); shot("v2_end_09_outro")
print(call("get_console_output",{})[-2500:])
print(call("start_stop_play",{"is_start":False}))
p.terminate()
