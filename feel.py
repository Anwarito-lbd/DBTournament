# v1.1 play-test: power-up stages, energy drink, vanish, lock-on, hit feedback vs a dev bot.
import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
def shot(name, off=(5,2.5,-10), look=(0,1.5,0)):
    r=L('local r=game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame local c=r*CFrame.new(%f,%f,%f) local l=r*CFrame.new(%f,%f,%f) return string.format("%%f,%%f,%%f,%%f,%%f,%%f",c.X,c.Y,c.Z,l.X,l.Y,l.Z)'%(off+look))
    v=[float(x) for x in r.strip().split(",")]
    print(name, call("screen_capture",{"camera_position":v[:3],"look_at_position":v[3:],"capture_id":"v11_"+name}),flush=True)
def camshot(name):
    print(name, call("screen_capture",{"capture_id":"v11_"+name}),flush=True)
print(call("execute_luau",{"code":'workspace:SetAttribute("DevHoldLobby",true) return 1'}))
print(call("start_stop_play",{"is_start":True})); time.sleep(10)
print("SRC", L('return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild("PowerUpGui")~=nil).." remote="..tostring(game.ReplicatedStorage.Remotes:FindFirstChild("UseItem")~=nil)'))
# force an in-round state for local testing: pick goku, mark alive, RoundState InRound, spawn a dev bot in front
print("SETUP", L('''local p=game.Players:GetPlayers()[1]
p:SetAttribute("Character","u7_goku") pcall(function() require(game.ServerScriptService.Modules.AvatarSlots).apply(p,"u7_goku") end)
task.wait(2)
workspace:SetAttribute("RoundState","InRound") p:SetAttribute("Alive",true)
local r=p.Character.HumanoidRootPart
local T=game.Teams:FindFirstChild("BotTeam") or Instance.new("Team") T.Name="BotTeam" T.Parent=game.Teams
game.ServerStorage.DevHooks.SpawnBot:Invoke(1,T,r.CFrame*CFrame.new(0,-5,-9)*CFrame.Angles(0,math.pi,0))
local n=0 for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("IsBot") then n+=1 end end
return "bots="..n.." team="..tostring(p.Team)''',"Server"))
time.sleep(1)
# 1) power-up: hold charge via remote
L('game.ReplicatedStorage.Remotes.KiCharge:FireServer(true) return 1')
for i,t in enumerate([1.2,2.0,2.0]):
    time.sleep(t)
    print("PL", L('local p=game.Players.LocalPlayer return tostring(p:GetAttribute("KiCharge")).." PL="..tostring(p:GetAttribute("PowerLevel")).." stage="..p.PlayerGui.PowerUpGui.StageLabel.Text.." vis="..tostring(p.PlayerGui.PowerUpGui.PowerReadout.Visible)'))
    camshot("powerup_%d"%(i+1))
L('game.ReplicatedStorage.Remotes.KiCharge:FireServer(false) return 1'); time.sleep(1)
# 2) energy drink
print("KI before", L('return tostring(game.Players.LocalPlayer:GetAttribute("Ki"))'))
L('game.ReplicatedStorage.Remotes.Vanish:FireServer(Vector3.new(1,0,0)) return 1'); time.sleep(0.6)
print("KI after vanish", L('return tostring(game.Players.LocalPlayer:GetAttribute("Ki"))'))
L('game.ReplicatedStorage.Remotes.UseItem:FireServer("EnergyDrink") return 1'); time.sleep(0.15); camshot("energy_drink")
print("DRINK", L('local p=game.Players.LocalPlayer return "ki="..tostring(p:GetAttribute("Ki")).." left="..tostring(p:GetAttribute("EnergyDrinks")).." ws="..p.Character.Humanoid.WalkSpeed'))
L('game.ReplicatedStorage.Remotes.UseItem:FireServer("EnergyDrink") return 1'); time.sleep(0.3)
print("DRINK2 (should stay)", L('return tostring(game.Players.LocalPlayer:GetAttribute("EnergyDrinks"))'))
time.sleep(1)
L('game.ReplicatedStorage.Remotes.Vanish:FireServer(Vector3.new(0,0,1)) return 1'); time.sleep(0.08); camshot("vanish")
time.sleep(2)
# 3) lock-on: synthesize via the same function path (press L is not injectable): call through a keypress-free path
print("LOCK", L('local f=game.Players.LocalPlayer.PlayerScripts:WaitForChild("GameFeel"):WaitForChild("GameFeelToggleLock") local n=f:Invoke() task.wait(0.3) return "locked="..tostring(n).." path="..tostring(game.Players.LocalPlayer:GetAttribute("LockTargetName"))'))
time.sleep(0.8); camshot("lockon")
# 4) hits on the bot (M1 x3 + heavy)
for i,m in enumerate(["M1","M1","M1","Heavy"]):
    L('local t=(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,-6)).Position for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("IsBot") and d:FindFirstChild("HumanoidRootPart") then t=d.HumanoidRootPart.Position end end game.ReplicatedStorage.Remotes.RequestMove:FireServer("%s",t) return 1'%m)
    time.sleep(0.06 if m=="Heavy" else 0.35)
    if m=="Heavy": camshot("heavy_hit")
time.sleep(1)
print("BOTHP", L('local t={} for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("IsBot") then t[#t+1]=d.Name..":"..math.floor(d.Humanoid.Health) end end return table.concat(t,",")',"Server"))
print(call("get_console_output",{})[-2500:])
print(call("start_stop_play",{"is_start":False})); time.sleep(2)
print(call("execute_luau",{"code":'workspace:SetAttribute("DevHoldLobby",nil) return 1'}))
print("DONE")
p.terminate()
