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
print("LOCK", L('local f=game.Players.LocalPlayer.PlayerScripts:WaitForChild("GameFeel"):WaitForChild("GameFeelToggleLock") local n=f:Invoke() return tostring(n)'))
print("MOVE", L('''local p=game.Players:GetPlayers()[1] local b for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("IsBot") then b=d end end
local br=b.HumanoidRootPart br.Anchored=true p.Character.HumanoidRootPart.CFrame=CFrame.lookAt(br.Position+br.CFrame.LookVector*4, br.Position) return "dist="..(p.Character.HumanoidRootPart.Position-br.Position).Magnitude''',"Server"))
print("STATE", L('local p=game.Players:GetPlayers()[1] local DB=require(game.ServerScriptService.Modules.DevBots) local b=workspace.DevBots:GetChildren()[1] local m,pos=DB.hitScan(p,require(game.ReplicatedStorage.Shared.Config).MOVES.M1,b.HumanoidRootPart.Position) return "rs="..tostring(workspace:GetAttribute("RoundState")).." alive="..tostring(p:GetAttribute("Alive")).." scan="..tostring(m).." hp="..p.Character.Humanoid.Health',"Server"))
L('workspace:SetAttribute("RoundState","InRound") game.Players:GetPlayers()[1]:SetAttribute("Alive",true) return 1',"Server")
time.sleep(0.2)
# 4) hits on the bot (M1 x3 + heavy)
for i,m in enumerate(["M1","M1","M1","Heavy"]):
    L('workspace:SetAttribute("RoundState","InRound") return 1',"Server")
    L('local t=(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,-6)).Position for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("IsBot") and d:FindFirstChild("HumanoidRootPart") then t=d.HumanoidRootPart.Position end end game.ReplicatedStorage.Remotes.RequestMove:FireServer("%s",t) return 1'%m)
    time.sleep(0.07 if m=="Heavy" else 0.45)
    camshot("hit_%d_%s"%(i,m.lower()))
time.sleep(1)
print("BOTHP", L('workspace.DevBots:GetChildren()[1].HumanoidRootPart.Anchored=false local t={} for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("IsBot") then t[#t+1]=d.Name..":"..math.floor(d.Humanoid.Health) end end return table.concat(t,",")',"Server"))
print(call("get_console_output",{})[-2500:])
print(call("start_stop_play",{"is_start":False})); time.sleep(2)
print(call("execute_luau",{"code":'workspace:SetAttribute("DevHoldLobby",nil) return 1'}))
print("DONE")
p.terminate()
