# v1.3 play-test. phase "top": 8-fighter ToP (me + 7 bots in 4 universes) | phase "lobby": radar, Shenron, raid, story, gravity XP
import json,sys,time,os
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def S(code): return L(code,"Server")
def E(code): return call("execute_luau",{"code":code})
def cam(name, pos=None, look=None):
    a={"capture_id":"v13_"+name}
    if pos: a["camera_position"]=list(pos); a["look_at_position"]=list(look)
    print(name, call("screen_capture",a),flush=True)
def rel(name, off, look=(0,1.5,0)):
    r=L('local r=game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame local c=r*CFrame.new(%f,%f,%f) local l=r*CFrame.new(%f,%f,%f) return string.format("%%f,%%f,%%f,%%f,%%f,%%f",c.X,c.Y,c.Z,l.X,l.Y,l.Z)'%(tuple(off)+tuple(look)))
    try: v=[float(x) for x in r.strip().split(",")]; cam(name,v[:3],v[3:])
    except Exception: print(name,"relshot failed",r[:200])
def vec(s):
    try: return [float(x) for x in s.strip().split(",")]
    except Exception: return None
phase=sys.argv[1]
H=open(r"v13\V13TestHooks.server.lua",encoding="utf-8").read()
def lstr(s): return "[==========["+s+"]==========]"
print("HOOKS",E('local h=game.ServerScriptService:FindFirstChild("V13TestHooks") if h then h:Destroy() end local s=Instance.new("Script") s.Name="V13TestHooks" s.Source=%s s.Parent=game.ServerScriptService return "ok"'%lstr(H)))
if phase=="top":
    print("PATCH",E(open(r"v13\patch13.lua",encoding="utf-8").read().replace('local h = game.ServerScriptService:FindFirstChild("V13TestHooks") if h then h:Destroy() end','')))
    E('workspace:SetAttribute("DevHoldLobby",nil) return 1')
else:
    E('workspace:SetAttribute("DevHoldLobby",true) return 1')
print(call("start_stop_play",{"is_start":True})); time.sleep(10)
H1=lambda c,*a: S('return game.ServerStorage.DevHooks.V13:Invoke(%s)'%",".join([json.dumps(c)]+[str(x) for x in a]))
print("PROFILE", H1("profile",80,32))
if phase=="top":
    L('require(game.ReplicatedStorage.Shared.ClientAPI).pickCharacter("u7_goku") return 1')
    t0=time.time(); st=""
    while time.time()-t0<90:
        st=S('return tostring(workspace:GetAttribute("RoundState"))')
        if "Intro" in st or "InRound" in st or "Countdown" in st: break
        time.sleep(1)
    print("STATE",st)
    for k in range(20):
        L('game.ReplicatedStorage.Remotes.IntroSkip:FireServer() return 1'); time.sleep(1)
        st=S('return tostring(workspace:GetAttribute("RoundState"))')
        if "InRound" in st: break
    print("STATE2",st)
    tr=time.time()
    print("ROSTER",S('''local t={} for _,tm in ipairs(game.Teams:GetTeams()) do local n=#tm:GetPlayers() local b=0 for _,m in ipairs(workspace.DevBots:GetChildren()) do if m:GetAttribute("Team")==tm.Name and m:GetAttribute("Alive") then b+=1 end end t[#t+1]=tm.Name.."(U"..tostring(tm:GetAttribute("Universe"))..") players="..n.." bots="..b end
local npc={} for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and (d.Name:find("Bulma") or d.Name:find("Zeno") or d.Name:find("Priest")) then npc[#npc+1]=d:GetFullName() end end
return table.concat(t,"; ").." | clock="..tostring(workspace:GetAttribute("ShowClock")).." | npcs="..table.concat(npc,", "):sub(1,600)'''))
    print("HUDCLOCK",L('local o={} for _,d in ipairs(game.Players.LocalPlayer.PlayerGui:GetDescendants()) do if d:IsA("TextLabel") and d.Visible and d.Text:match("%d+:%d%d") then o[#o+1]=d.Text end end return table.concat(o," | ")'))
    cam("01_top_hud_clock")
    # universe stands + Zeno box + Bulma
    v=vec(S('local a=workspace.WorldOfVoid.Arena local s=a.Stands:GetChildren()[1] local bp=s:FindFirstChildWhichIsA("BasePart",true) local p=bp.Position return string.format("%f,%f,%f",p.X,p.Y,p.Z)'))
    if v: cam("02_universe_stands",(v[0]*0.35,v[1]+40,v[2]*0.35+60),(v[0],v[1],v[2]))
    v=vec(S('local z=workspace.WorldOfVoid.Arena:FindFirstChild("ZenoBox",true) local p=z:FindFirstChildWhichIsA("BasePart",true).Position return string.format("%f,%f,%f",p.X,p.Y,p.Z)'))
    if v: cam("03_zeno_box",(v[0],v[1]+5,v[2]+70),(v[0],v[1],v[2]))
    v=vec(S('for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d.Name:find("Bulma") then local p=d:GetPivot().Position return string.format("%f,%f,%f",p.X,p.Y,p.Z) end end return ""'))
    if v: cam("04_bulma",(v[0]*0.9,v[1]+4,v[2]*0.9),(v[0],v[1]+2,v[2]))
    else: print("BULMA not found")
    # SSJ4
    print("FORMS",S('local p=game.Players:GetPlayers()[1] return "char="..tostring(p:GetAttribute("Character")).." form="..tostring(p:GetAttribute("Form")).." alive="..tostring(p:GetAttribute("Alive"))'))
    L('require(game.ReplicatedStorage.Shared.ClientAPI).transform("SuperSaiyan4") return 1'); time.sleep(1.1)
    cam("05_ssj4_transform"); time.sleep(2.5); rel("06_ssj4_after",(4,2,-8))
    print("FORM_AFTER",S('local p=game.Players:GetPlayers()[1] return "form="..tostring(p:GetAttribute("Form")).." PL="..tostring(p:GetAttribute("PowerLevel"))'))
    # erasure of the smallest bot universe (U of last team)
    er=S('''local tgt=nil for _,tm in ipairs(game.Teams:GetTeams()) do local b=0 local hasP=#tm:GetPlayers()>0 for _,m in ipairs(workspace.DevBots:GetChildren()) do if m:GetAttribute("Team")==tm.Name and m:GetAttribute("Alive") then b+=1 end end if not hasP and b>0 and b<=2 then tgt=tm end end
if not tgt then return "none" end local n=0 for _,m in ipairs(workspace.DevBots:GetChildren()) do if m:GetAttribute("Team")==tgt.Name then local h=m:FindFirstChildOfClass("Humanoid") if h then h.Health=0 n+=1 end end end
local st=nil for _,s in ipairs(workspace.WorldOfVoid.Arena.Stands:GetChildren()) do if s.Name:match("U0*"..tostring(tgt:GetAttribute("Universe")).."$") then st=s end end
local bp=st and st:FindFirstChildWhichIsA("BasePart",true) local p=bp and bp.Position or Vector3.new(0,560,0) return tgt.Name.." killed="..n.." @"..string.format("%f,%f,%f",p.X,p.Y,p.Z)''')
    print("ERASE",er)
    try: v=vec(er.split("@")[1])
    except Exception: v=None
    for i,dt in enumerate((1.0,1.5,2.0)):
        time.sleep(dt)
        if v: cam("07_erasure_%d"%i,(v[0]*0.5,v[1]+25,v[2]*0.5),(v[0],v[1],v[2]))
        else: cam("07_erasure_%d"%i)
    cam("07_erasure_player_view")
    print("ELIM",S('local o={} for _,tm in ipairs(game.Teams:GetTeams()) do o[#o+1]=tm.Name..":"..tostring(tm:GetAttribute("Erased")) end return table.concat(o,", ").." clock="..tostring(workspace:GetAttribute("ShowClock"))'))
    # ring-out on a detached chunk: blast the ring under me (real ArenaDamage), then stand on what detached
    L('_G.__el={} game.ReplicatedStorage.Remotes.PlayerEliminated.OnClientEvent:Connect(function(v,k,why) table.insert(_G.__el,tostring(v).."/"..tostring(why)) end) return 1')
    print("FLOOR",S('local p=game.Players:GetPlayers()[1] local r=p.Character.HumanoidRootPart local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character} local h=workspace:Raycast(r.Position,Vector3.new(0,-20,0),rp) return h and (h.Instance:GetFullName().." stage="..tostring(h.Instance:GetAttribute("DamageStage"))) or "nofloor"'))
    for k in range(4): print("DMG",H1("damage",'game.Players:GetPlayers()[1].Character.HumanoidRootPart.Position-Vector3.new(0,3,0)',30,400)); time.sleep(0.5)
    det=S('''local p=game.Players:GetPlayers()[1] local r=p.Character.HumanoidRootPart local best,bd=nil,1e9
for _,d in ipairs(workspace.WorldOfVoid.Arena:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("Detached")==true then local dd=(d.Position-r.Position).Magnitude if dd<bd then best,bd=d,dd end end end
if not best then return "nodetached" end r.CFrame=CFrame.new(best.Position+Vector3.new(0,best.Size.Y/2+3,0)) return "on "..best.Name.." stage="..tostring(best:GetAttribute("DamageStage"))''')
    print("DETACHED",det); time.sleep(0.4); rel("10_detached_chunk",(6,3,-10)); time.sleep(1.5)
    print("ELIMEV",L('return table.concat(_G.__el or {}," ; ")'))
    print("RINGOUT",S('local p=game.Players:GetPlayers()[1] return "alive="..tostring(p:GetAttribute("Alive")).." spectating="..tostring(p:GetAttribute("Spectating"))'))
    cam("11_ringout_after")
    # Jiren survival event at ROUND_MAX*0.5 = 75 s (warn 5 s before)
    while time.time()-tr<66: time.sleep(1)
    print("ME",S('local p=game.Players:GetPlayers()[1] return "alive="..tostring(p:GetAttribute("Alive"))'))
    for k in range(25):
        j=S('local j=workspace.WorldOfVoid:FindFirstChild("Jiren") return tostring(j~=nil)')
        if "true" in j: break
        time.sleep(0.5)
    print("JIREN",j, time.time()-tr)
    for i in range(4):
        cam("08_jiren_entrance_%d"%i); time.sleep(1.2)
    v=vec(S('local j=workspace.WorldOfVoid:FindFirstChild("Jiren") if not j then return "" end local p=j:GetPivot().Position return string.format("%f,%f,%f",p.X,p.Y,p.Z)'))
    if v: cam("09_jiren_model",(v[0]+10,v[1]+4,v[2]+14),(v[0],v[1]+2,v[2]))
elif phase=="lobby":
    # Dragon Radar + collect all 7 + Shenron wish UI
    L('_G.__db=nil game.ReplicatedStorage.Remotes.DragonBallState.OnClientEvent:Connect(function(s) if s.balls then _G.__db=s end _G.__dberr=s.error end) game.ReplicatedStorage.Remotes.DragonBallState:FireServer() return 1')
    L('require(game.ReplicatedStorage.Shared.ClientAPI).collectDragonBall(99) return 1'); time.sleep(1.5)
    print("RADAR",L('local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild("DragonRadarUI") if not g then return "no gui" end local n=0 for _,d in ipairs(g:GetDescendants()) do if d:IsA("Frame") and d.Name=="Panel" then d.Visible=true end end for _,d in ipairs(g:GetDescendants()) do if d:IsA("GuiObject") and d.Visible then n+=1 end end local s=_G.__db return "visible="..n.." balls="..tostring(s and #s.balls).." err="..tostring(_G.__dberr)'))
    L('local g=game.Players.LocalPlayer.PlayerGui.DragonRadarUI for _,d in ipairs(g:GetChildren()) do if d:IsA("GuiObject") then d.Visible=true end end return 1')
    time.sleep(0.5); cam("20_dragon_radar")
    for i in range(1,8):
        r=L('local s=_G.__db if not s then return "nostate" end local b=s.balls[%d] game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame=CFrame.new(b.pos+Vector3.new(0,2,0)) task.wait(0.4) require(game.ReplicatedStorage.Shared.ClientAPI).collectDragonBall(%d) task.wait(1.7) return tostring(b.pos).." have="..tostring(_G.__db.balls[%d].have).." err="..tostring(_G.__dberr)'%(i,i,i))
        print("BALL",i,r)
        if i==1: rel("21_dragon_ball",(5,3,-9),(0,0,-2))
    print("COUNT",S('return tostring(game.Players:GetPlayers()[1]:GetAttribute("DragonBalls"))'))
    L('require(game.ReplicatedStorage.Shared.ClientAPI).summonShenron() return 1'); time.sleep(4)
    cam("22_shenron_summon"); time.sleep(3)
    print("WISHUI",L('local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild("ShenronWishUI") local o={} if g then for _,d in ipairs(g:GetDescendants()) do if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible and #d.Text>0 then o[#o+1]=d.Text end end end return table.concat(o," | "):sub(1,500)'))
    cam("23_shenron_wish_ui")
    L('for _,g in ipairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do if g.Name=="ShenronWishUI" or g.Name=="DragonRadarUI" then for _,d in ipairs(g:GetChildren()) do if d:IsA("GuiObject") and d.Name~="ToggleButton" then end end end end return 1')
    # Gravity Room XP check (TrainingRooms owner)
    S('local p=game.Players:GetPlayers()[1] local sp=workspace.WorldOfVoid.Training.GravityRoom:FindFirstChild("Spawn_GravityRoom",true) p.Character.HumanoidRootPart.CFrame=CFrame.new(sp.Position+Vector3.new(0,4,0)) return 1'); time.sleep(3)
    for g in (1,100):
        L('game.ReplicatedStorage.Remotes.SetGravity:FireServer(%d) return 1'%g); time.sleep(1.5)
        a=H1("xp"); time.sleep(30); b=H1("xp")
        print("GRAVXP g=%d"%g, a, "->", b, S('local p=game.Players:GetPlayers()[1] return "attrG="..tostring(p:GetAttribute("TrainingGravity")).." mult="..tostring(p:GetAttribute("TrainingXPMult")).." area="..tostring(p:GetAttribute("TrainingArea")).." walk="..p.Character.Humanoid.WalkSpeed'))
    cam("24_gravity_room_100")
    # Story mission 1
    L('_G.__st={} game.ReplicatedStorage.Remotes.StoryUpdate.OnClientEvent:Connect(function(d) local s="" if type(d)=="table" then for k,v in pairs(d) do s=s..k.."="..tostring(v).." " end end table.insert(_G.__st,s) end) return 1')
    S('local p=game.Players:GetPlayers()[1] local sp=workspace.WorldOfVoid.Lobby.Spawn_Lobby_02 p.Character.HumanoidRootPart.CFrame=CFrame.new(sp.Position+Vector3.new(0,4,0)) return 1'); time.sleep(2)
    L('require(game.ReplicatedStorage.Shared.ClientAPI).startStory(1) return 1'); time.sleep(5)
    print("STORY",L('return table.concat(_G.__st or {}," || "):sub(1,600)'))
    cam("25_story_mission"); time.sleep(4); cam("26_story_mission_b")
    print("STORYBOSS",S('local o={} for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("BossId") then o[#o+1]=d:GetFullName() end end return table.concat(o,", ")'))
    # Raid (Broly)
    L('_G.__rd={} game.ReplicatedStorage.Remotes.RaidUpdate.OnClientEvent:Connect(function(d) local s="" if type(d)=="table" then for k,v in pairs(d) do s=s..k.."="..tostring(v).." " end end table.insert(_G.__rd,s) end) return 1')
    L('require(game.ReplicatedStorage.Shared.ClientAPI).requestRaidInfo() local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild("RaidLobbyUI") if g then for _,d in ipairs(g:GetChildren()) do if d:IsA("GuiObject") then d.Visible=true end end end return 1')
    time.sleep(1); cam("27_raid_lobby_ui")
    L('require(game.ReplicatedStorage.Shared.ClientAPI).joinRaid("Broly") return 1')
    for k in range(40):
        time.sleep(1)
        ir=S('local p=game.Players:GetPlayers()[1] return tostring(p:GetAttribute("InRaid"))..","..tostring(p.Character.HumanoidRootPart.Position)')
        if ir.startswith("true"): break
    print("INRAID",ir, L('return table.concat(_G.__rd or {}," || "):sub(-500)'))
    time.sleep(3); cam("28_raid_broly"); time.sleep(4); cam("29_raid_broly_b")
    v=vec(S('for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("BossId") then local p=d:GetPivot().Position return string.format("%f,%f,%f",p.X,p.Y,p.Z) end end return ""'))
    if v: cam("30_raid_boss",(v[0]+16,v[1]+6,v[2]+16),(v[0],v[1]+3,v[2]))
out=call("get_console_output",{})
lines=[l for l in out.splitlines() if ("rror" in l or "attempt" in l or "nfinite" in l or "failed" in l) ]
print("CONSOLE_ERRORS"); print("\n".join(lines)[-5000:])
open("v13_console_%s.txt"%phase,"w",encoding="utf-8").write(out)
print(call("start_stop_play",{"is_start":False})); time.sleep(2)
E('workspace:SetAttribute("DevHoldLobby",nil) local h=game.ServerScriptService:FindFirstChild("V13TestHooks") if h then h:Destroy() end return 1')
print("DONE")
p.terminate()
