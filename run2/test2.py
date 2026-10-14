import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def state(): return L('return tostring(workspace:GetAttribute("RoundState"))..","..tostring(workspace:GetAttribute("TimeLeft"))',"Server")
def shot(cid):
    r=L('local c=workspace.CurrentCamera.CFrame; local p=c.Position; local l=p+c.LookVector*20; return string.format("%f,%f,%f,%f,%f,%f",p.X,p.Y,p.Z,l.X,l.Y,l.Z)')
    try:
        v=[float(x) for x in r.strip().split(",")]
    except Exception: print("camfail",r); return
    print(cid, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":cid}))
def waitfor(s,tmax=90):
    t0=time.time()
    while time.time()-t0<tmax:
        st=state()
        if st.split(",")[0]==s: return True
        time.sleep(0.5)
    print("TIMEOUT waiting",s,state()); return False
T0=time.time()
def log(*a): print("[%5.1f]"%(time.time()-T0),*a, flush=True)
log(call("start_stop_play",{"is_start":True}))
time.sleep(4)
log("state",state())
if waitfor("CharacterSelect"):
    time.sleep(1.5)
    log("pick",L('require(game.ReplicatedStorage.Shared.ClientAPI).pickCharacter("u7_goku") task.wait(0.5) return tostring(game.Players.LocalPlayer:GetAttribute("Character"))'))
    shot("v1_charselect")
if waitfor("Intro"):
    if "--full" in sys.argv:
        time.sleep(6); shot("v1_intro_1")
        time.sleep(7); shot("v1_intro_2")
    else: time.sleep(1)
    log("skip",L('game.ReplicatedStorage.Remotes.IntroSkip:FireServer() return "ok"'))
log("server", L('local o={} for _,m in workspace.DevBots:GetChildren() do table.insert(o,m.Name.."@"..tostring(m:GetPivot().Position).." team="..tostring(m:GetAttribute("Team"))) end return table.concat(o," | ").." player team="..tostring(game.Players:GetPlayers()[1].Team)',"Server"))
if waitfor("InRound",30):
    fighter=r'''
local CA=require(game.ReplicatedStorage.Shared.ClientAPI)
local lp=game.Players.LocalPlayer
_G.autoFight=true
task.spawn(function()
  local lastBeam=0
  while _G.autoFight and workspace:GetAttribute("RoundState")=="InRound" do
    local r=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local best,bd=nil,1e9
    for _,m in workspace.DevBots:GetChildren() do
      local br=m:FindFirstChild("HumanoidRootPart")
      if br and m:GetAttribute("Alive") then local d=(br.Position-r.Position).Magnitude if d<bd then best,bd=br,d end end
    end
    if best and r then
      r.CFrame=CFrame.lookAt(r.Position, Vector3.new(best.Position.X,r.Position.Y,best.Position.Z))
      if os.clock()-lastBeam>10.5 and bd<240 then lastBeam=os.clock(); CA.requestMove("Kamehameha", best.Position)
      elseif bd<8 then CA.requestMove("M1", best.Position) end
    end
    task.wait(0.35)
  end
end)
return "started"'''
    time.sleep(1)
    log("fight",L(fighter))
    time.sleep(0.5)
    # beam shot from side camera
    bp=L('local b=workspace.DevBots:GetChildren()[1] local p=b and b:GetPivot().Position or Vector3.new(-110,500,0) return string.format("%f,%f,%f",p.X,p.Y,p.Z)',"Server")
    try: bx,by,bz=[float(x) for x in bp.split(",")]
    except Exception: bx,by,bz=-110,500,0
    log("beamshot", call("screen_capture",{"camera_position":[bx+25,by+18,bz+45],"look_at_position":[bx+40,by-2,bz],"capture_id":"v1_beam_1"}))
    time.sleep(2)
    shot("v1_hud")
    log("arena", L('local d,det=0,0 for _,c in game:GetService("CollectionService"):GetTagged("RingChunk") do if (c:GetAttribute("Health") or 0) < (c:GetAttribute("MaxHealth") or 0) then d+=1 end if c:GetAttribute("Detached") then det+=1 end end return "damagedChunks="..d.." detached="..det',"Server"))
    time.sleep(9.5)
    log("beamshot2", call("screen_capture",{"camera_position":[60,530,-140],"look_at_position":[0,500,60],"capture_id":"v1_beam_2"}))
    t0=time.time()
    while time.time()-t0<150:
        st=state(); 
        if not st.startswith("InRound"): break
        time.sleep(5)
        log(st, L('local o={} for _,m in workspace.DevBots:GetChildren() do local h=m:FindFirstChildOfClass("Humanoid") table.insert(o,m.Name..":"..math.floor(h and h.Health or -1)..":"..tostring(m:GetAttribute("Alive")).."@"..math.floor(m:GetPivot().Position.Y)) end local h=game.Players:GetPlayers()[1].Character.Humanoid return table.concat(o," | ").." playerHP="..math.floor(h.Health)',"Server"))
if waitfor("Ending",60):
    time.sleep(12)
    log("endcam",L('local c=workspace.CurrentCamera return tostring(c.CameraType).." "..tostring(c.CFrame.Position).." shen="..tostring(workspace:FindFirstChild("Story_SuperShenron"))'))
    shot("v1_ending_shenron")
    time.sleep(9); shot("v1_wish_choice")
    log("wishUI",L('local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild("EndingCutscene") return tostring(g and g:FindFirstChild("WishChoice",true))'))
    log("wish",L('game.ReplicatedStorage.Remotes.WishChoice:FireServer("Power") task.wait(1) return tostring(game.Players.LocalPlayer:GetAttribute("Title"))'))
if waitfor("Results",30):
    time.sleep(1.5); shot("v1_results")
log("console\n"+call("get_console_output",{}))
log(call("start_stop_play",{"is_start":False}))
p.terminate()
