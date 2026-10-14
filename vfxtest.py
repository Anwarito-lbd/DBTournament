import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def shot(cid,back=14,up=5):
    r=L('local c=workspace.CurrentCamera.CFrame local p=c.Position local l=p+c.LookVector*20 return string.format("%f,%f,%f,%f,%f,%f",p.X,p.Y,p.Z,l.X,l.Y,l.Z)')
    v=[float(x) for x in r.strip().split(",")]
    print(cid, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":cid}), flush=True)
print(L('workspace:SetAttribute("DevHoldLobby",true) return "hold"',"Edit")); print(call("start_stop_play",{"is_start":True})); time.sleep(7)
print(L('local r=game.Players.LocalPlayer.Character.HumanoidRootPart r.CFrame=CFrame.lookAt(Vector3.new(60,505,90),Vector3.new(-40,505,-60)) return "tp"')); time.sleep(2)
pre='local lp=game.Players.LocalPlayer local ch=lp.Character local r=ch.HumanoidRootPart local V=game.ReplicatedStorage.VFX local tgt=r.Position+r.CFrame.LookVector*120+Vector3.new(0,-3,0) '
for mod,wait in [("KamehamehaVFX",1.6),("FinalFlashVFX",1.9),("GalickGunVFX",1.4),("DeathBeamVFX",0.33),("SpiritBombVFX",2.8)]:
    print(L(pre+'task.spawn(function() require(V.%s).Play(ch,tgt) end) return "go"'%mod))
    time.sleep(wait); shot("v11_"+mod)
    time.sleep(4)
for form in ["SuperSaiyan","SuperSaiyanBlue","MUI"]:
    print(L('game.Players.LocalPlayer:SetAttribute("Form","%s") return "ok"'%form)); time.sleep(1.2); shot("v11_aura_"+form)
print(L('game.Players.LocalPlayer:SetAttribute("Form","Base") return "ok"'))
print(call("get_console_output",{}))
print(call("start_stop_play",{"is_start":False}))
time.sleep(2)
print(L('workspace:SetAttribute("DevHoldLobby",nil) return "unhold"',"Edit"))
p.terminate()
