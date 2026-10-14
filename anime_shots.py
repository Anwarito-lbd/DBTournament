import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
PRE=sys.argv[1]
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def shot(name, off=(4.5,1.2,-8), look=(0,1.0,0)):
    r=L('local r=game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame local c=r*CFrame.new(%f,%f,%f) local l=r*CFrame.new(%f,%f,%f) return string.format("%%f,%%f,%%f,%%f,%%f,%%f",c.X,c.Y,c.Z,l.X,l.Y,l.Z)'%(off+look))
    v=[float(x) for x in r.strip().split(",")]
    print(name, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":PRE+"_"+name}),flush=True)
def pose(s):
    L('workspace:SetAttribute("AnimePose","") task.wait() workspace:SetAttribute("AnimePose","%s") return 1'%s)
FACE=(0.6,1.8,-3.2); FLOOK=(0,1.6,0)
print(L('workspace:SetAttribute("DevHoldLobby",true) return 1',"Edit"))
print(call("start_stop_play",{"is_start":True})); time.sleep(8)
for cid,seq in [("u7_goku","Kamehameha"),("u7_vegeta","FinalFlash"),("u7_frieza","DeathBeam")]:
    print(L('local p=game.Players:GetPlayers()[1] p:SetAttribute("Character","%s") local A=require(game.ServerScriptService.Modules.AvatarSlots) return tostring(A.apply(p,"%s"))'%(cid,cid),"Server")); time.sleep(3)
    print(L('local c=game.Players:GetPlayers()[1].Character return tostring(c:GetAttribute("ChampionModel")).." skin="..tostring(c:FindFirstChild("ChampionSkin")~=nil)',"Server"))
    shot(cid+"_idle")
    if cid=="u7_goku":
        shot("default_face_neutral",FACE,FLOOK)
    pose(seq); time.sleep(0.5 if seq!="DeathBeam" else 0.3); shot(cid+"_pose_charge")
    if seq!="DeathBeam": time.sleep(1.1); shot(cid+"_pose_fire")
    time.sleep(2)
# faces on default avatar: un-skin by picking a champion without a model
print(L('local p=game.Players:GetPlayers()[1] p:SetAttribute("Character","u6_cabba") return tostring(require(game.ServerScriptService.Modules.AvatarSlots).apply(p,"u6_cabba"))',"Server")); time.sleep(3)
print(L('local c=game.Players:GetPlayers()[1].Character return "skin="..tostring(c:FindFirstChild("ChampionSkin")~=nil).." char="..tostring(game.Players:GetPlayers()[1]:GetAttribute("Character"))',"Server"))
for e in ["Neutral","Angry","Scream"]:
    pose("Expr_"+e); time.sleep(0.6); shot("face_"+e.lower(),FACE,FLOOK)
pose("M1a"); time.sleep(0.08); shot("punch_key")
pose("Heavy"); time.sleep(0.3); shot("heavy_kick_key")
pose("SpeedLines"); time.sleep(0.1); pose("Afterimage"); time.sleep(0.05); shot("speedlines_afterimage",(7,2,-10))
pose("ImpactFrame"); shot("impact_frame")
print(call("get_console_output",{})[-1500:])
print(call("start_stop_play",{"is_start":False})); time.sleep(2)
print(L('workspace:SetAttribute("DevHoldLobby",nil) return 1',"Edit"))
print("DONE")
p.terminate()
