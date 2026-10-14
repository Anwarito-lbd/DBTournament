# v1.2 play-test: banner, store, training camps, animation keyframes, transformation cinematics, beam struggle.
import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def shot(name, off=(5,2.5,-10), look=(0,1.5,0)):
    r=L('local r=game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame local c=r*CFrame.new(%f,%f,%f) local l=r*CFrame.new(%f,%f,%f) return string.format("%%f,%%f,%%f,%%f,%%f,%%f",c.X,c.Y,c.Z,l.X,l.Y,l.Z)'%(off+look))
    v=[float(x) for x in r.strip().split(",")]
    print(name, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":"v12_"+name}),flush=True)
def camshot(name): print(name, call("screen_capture",{"capture_id":"v12_"+name}),flush=True)
def S(code): return L(code,"Server")
phase=sys.argv[1] if len(sys.argv)>1 else "all"
print(call("execute_luau",{"code":'workspace:SetAttribute("DevHoldLobby",true) return 1'}))
print(call("start_stop_play",{"is_start":True})); time.sleep(12)
print("BOOT", S('local t={} t[#t+1]="training="..tostring(workspace.WorldOfVoid:FindFirstChild("Training")~=nil) t[#t+1]="areas="..(workspace.WorldOfVoid:FindFirstChild("Training") and #workspace.WorldOfVoid.Training:GetChildren() or 0) local p=game.Players:GetPlayers()[1] t[#t+1]="zeni="..tostring(p:GetAttribute("Zeni")) t[#t+1]="rs="..tostring(workspace:GetAttribute("RoundState")) return table.concat(t," ")'))
print("BANNER", L('local g=game.Players.LocalPlayer.PlayerGui local out={} for _,d in ipairs(g:GetDescendants()) do if d:IsA("TextLabel") and d.Visible and (d.Text:find("DRAGON") or d.Text:find("TOURNAMENT")) then out[#out+1]=d:GetFullName()..": "..d.Text end end return table.concat(out,"\\n")'))
camshot("01_lobby_banner")
if phase in ("all","store"):
    print("STOREOPEN", L('return game.Players.LocalPlayer.PlayerScripts.StoreUI.StoreTest:Invoke("open","Characters")'))
    time.sleep(0.6); camshot("02_store_characters")
    L('game.Players.LocalPlayer.PlayerScripts.StoreUI.StoreTest:Invoke("open","Cosmetics") return 1'); time.sleep(0.4); camshot("03_store_cosmetics")
    for it in ["Aura_Crimson","Outfit_TurtleGi","XPBoost30","Drink1","Zenkai","SuperSaiyan"]:
        L('game.ReplicatedStorage.Remotes.StoreRequest:FireServer("BuyZeni","%s") return 1'%it); time.sleep(0.7)
        print("BUY",it, L('return game.Players.LocalPlayer.PlayerScripts.StoreUI.StoreTest:Invoke("noop")'))
    L('game.ReplicatedStorage.Remotes.StoreRequest:FireServer("BuyRobux","Drink5") return 1'); time.sleep(0.7)
    print("ROBUX", L('return game.Players.LocalPlayer.PlayerScripts.StoreUI.StoreTest:Invoke("noop")'))
    L('game.ReplicatedStorage.Remotes.StoreRequest:FireServer("BuyZeni","Aura_Crimson") return 1'); time.sleep(0.6)
    print("DUP", L('return game.Players.LocalPlayer.PlayerScripts.StoreUI.StoreTest:Invoke("noop")'))
    print("ATTRS", S('local p=game.Players:GetPlayers()[1] return "zeni="..tostring(p:GetAttribute("Zeni")).." owned="..tostring(p:GetAttribute("StoreOwned")).." aura="..tostring(p:GetAttribute("Aura")).." cos="..tostring(p:GetAttribute("Cosmetic")).." stat="..tostring(p:GetAttribute("StoreStatBoost")).." boostUntil="..tostring(p:GetAttribute("XPBoostUntil")).." drinks="..tostring(p:GetAttribute("EnergyDrinkStock"))'))
    camshot("04_store_boosts_after")
    L('game.Players.LocalPlayer.PlayerScripts.StoreUI.StoreTest:Invoke("close") return 1'); time.sleep(1)
    shot("05_aura_outfit",(3,1.5,-7),(0,0.5,0))
    print("CAP", S('local C=require(game.ReplicatedStorage.Shared.Config) local p=game.Players:GetPlayers()[1] p:SetAttribute("WishStatBoost",1.1) local r=1.3*1.1*(p:GetAttribute("StoreStatBoost") or 1) return "uncapped="..r.." cap="..C.STAT_CAP.." applied="..math.min(r,C.STAT_CAP)'))
if phase in ("all","training"):
    AREAS=["TrainingHub","HyperbolicTimeChamber","GravityRoom","KingKaiPlanet","WhisGround"]
    for i,a in enumerate(AREAS):
        print("TP",a,S('local p=game.Players:GetPlayers()[1] local s=workspace.WorldOfVoid.Training:FindFirstChild("%s") local sp=s and s:FindFirstChild("Spawn_%s",true) if not sp then return "nospawn" end p.Character.HumanoidRootPart.CFrame=CFrame.new(sp.Position+Vector3.new(0,4,0)) return tostring(sp.Position)'%(a,a)))
        time.sleep(4)
        print("AREA",a,S('local p=game.Players:GetPlayers()[1] local h=p.Character.Humanoid return "area="..tostring(p:GetAttribute("TrainingArea")).." xpMult="..tostring(p:GetAttribute("TrainingXPMult")).." walk="..h.WalkSpeed.." xp="..tostring(p:GetAttribute("XP")).." vf="..tostring(p.Character.HumanoidRootPart:FindFirstChild("TrainingGravity")~=nil)'))
        camshot("%02d_area_%s"%(10+i,a))
        if a=="GravityRoom":
            for g in (10,60,100):
                L('game.Players.LocalPlayer.PlayerScripts.TrainingUI.TrainingTest:Invoke("gravity",%d) return 1'%g); time.sleep(2.2)
                print("GRAV",g,S('local p=game.Players:GetPlayers()[1] local f=p.Character.HumanoidRootPart:FindFirstChild("TrainingGravity") return "g="..tostring(p:GetAttribute("TrainingGravity")).." xpMult="..tostring(p:GetAttribute("TrainingXPMult")).." walk="..p.Character.Humanoid.WalkSpeed.." force="..(f and math.floor(f.Force.Y) or 0)'))
            camshot("15_gravity_100x")
        if a=="KingKaiPlanet":
            L('''_G.__ev={} game.ReplicatedStorage.Remotes.DrillUpdate.OnClientEvent:Connect(function(k,d) local s=k for kk,v in pairs(type(d)=="table" and d or {}) do s=s.." "..kk.."="..tostring(v) end table.insert(_G.__ev,s) end) return 1''')
            for run in range(3):
                L('game.ReplicatedStorage.Remotes.StartDrill:FireServer("CatchBubbles") return 1'); time.sleep(1.5)
                if run==0: shot("16_kingkai_bubbles",(6,5,-14),(0,0,0))
                print("CATCH",run,S('''local p=game.Players:GetPlayers()[1] local r=p.Character.HumanoidRootPart local n=0 local t0=os.clock()
while os.clock()-t0<12 do for _,d in ipairs(workspace:GetDescendants()) do if d.Name=="DrillOrb" and (d.Position-Vector3.new(9000,300,0)).Magnitude<200 then r.CFrame=CFrame.new(d.Position) n+=1 task.wait(0.35) end end task.wait(0.2) end return "teleports="..n'''))
                time.sleep(1.5)
                print("EV",L('local t=_G.__ev or {} local s=table.concat(t," | ") _G.__ev={} return s:sub(1,600)'))
            print("KAIOKEN", S('local p=game.Players:GetPlayers()[1] return "unlocks attr="..tostring(p:GetAttribute("Unlocks") or p:GetAttribute("UnlockedForms"))'))
        if a=="WhisGround":
            L('game.ReplicatedStorage.Remotes.StartDrill:FireServer("WhisDodge") return 1'); time.sleep(4)
            shot("17_whis_drill",(8,6,-16),(0,1,0))
            time.sleep(3)
            print("EV",L('local t=_G.__ev or {} local s=table.concat(t," | ") _G.__ev={} return s:sub(-600)'))
if phase in ("all","anim"):
    S('local p=game.Players:GetPlayers()[1] local sp=workspace.WorldOfVoid.Lobby.Spawn_Lobby_02 p.Character.HumanoidRootPart.CFrame=CFrame.new(sp.Position+Vector3.new(0,4,0)) p.Character.HumanoidRootPart.Anchored=true return 1'); time.sleep(2)
    for i,(seq,dt) in enumerate([("Combo1",0.12),("Combo3",0.15),("Combo4",0.22),("Launcher",0.4),("AirCombo",0.5),("KiVolley",0.1),("Guard",0.2),("Dash",0.15),("FlightIdle",0.45),("Hurt1",0.12),("KO",0.5),("Victory",0.4)]):
        L('workspace:SetAttribute("AnimePose","") workspace:SetAttribute("AnimePose","%s") return 1'%seq,"Server"); time.sleep(dt)
        shot("%02d_pose_%s"%(20+i,seq),(6,1.5,-7),(0,0.5,0))
    S('game.Players:GetPlayers()[1].Character.HumanoidRootPart.Anchored=false return 1')
if phase in ("all","vfx"):
    for i,pr in enumerate(["SSJ","SSB","MUI","UltraEgo","GoldenFrieza","FriezaBlack"]):
        L('task.spawn(function() game.Players.LocalPlayer.PlayerScripts.TransformCinematic.CinematicTest:Invoke("%s") end) return 1'%pr); time.sleep(1.05)
        camshot("%02d_cine_%s"%(40+i,pr)); time.sleep(3.2)
    print("STRUGGLE", S('''local p=game.Players:GetPlayers()[1] local r=p.Character.HumanoidRootPart
local T=game.Teams:FindFirstChild("BotTeam") or Instance.new("Team") T.Name="BotTeam" T.Parent=game.Teams
game.ServerStorage.DevHooks.SpawnBot:Invoke(1,T,r.CFrame*CFrame.new(0,0,-30)*CFrame.Angles(0,math.pi,0)) task.wait(1)
local b=workspace.DevBots:GetChildren()[1] b.HumanoidRootPart.Anchored=true
local ev=game.ReplicatedStorage.Remotes.CombatEvent ev:FireAllClients("StruggleStart",{p.UserId,b,4})
for i=1,4 do task.wait(0.4) ev:FireAllClients("StrugglePulse",{p.UserId,b,i*5}) end return "ok"'''))
    shot("50_beam_struggle",(14,6,-8),(0,1,-15))
    S('local p=game.Players:GetPlayers()[1] local b=workspace.DevBots:GetChildren()[1] game.ReplicatedStorage.Remotes.CombatEvent:FireAllClients("StruggleEnd",{p.UserId,b}) return 1'); time.sleep(0.15)
    shot("51_struggle_end",(14,6,-8),(0,1,-15))
out=call("get_console_output",{})
print("CONSOLE_ERRORS"); print("\n".join(l for l in out.splitlines() if ("rror" in l or "nfinite" in l or "attempt" in l) and "WARN" not in l)[-3000:])
print("BOOTLOG", "\n".join(l for l in out.splitlines() if "V12Boot" in l or "Training]" in l)[-800:])
print(call("start_stop_play",{"is_start":False})); time.sleep(2)
print(call("execute_luau",{"code":'workspace:SetAttribute("DevHoldLobby",nil) return 1'}))
print("DONE")
p.terminate()
