import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(code,dm="Client"): return call("execute_luau",{"code":code,"datamodel_type":dm})
print(L('workspace:SetAttribute("DevHoldLobby",true) return 1',"Edit"))
print(call("start_stop_play",{"is_start":True})); time.sleep(10)
Q='''local P=game.Players.LocalPlayer local c=P.Character local hrp=c and c:FindFirstChild("HumanoidRootPart")
local cam=workspace.CurrentCamera local L=game.Lighting
local n=0 for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end
local atm=L:FindFirstChildOfClass("Atmosphere")
return string.format("hrp=%s camCF=%s camType=%s subj=%s parts=%d stream=%s fogEnd=%s bright=%s clock=%s exp=%s atmDensity=%s ws=%s gui=%s",
 tostring(hrp and hrp.Position), tostring(cam.CFrame.Position), tostring(cam.CameraType), tostring(cam.CameraSubject and cam.CameraSubject:GetFullName()), n,
 tostring(workspace.StreamingEnabled), tostring(L.FogEnd), tostring(L.Brightness), tostring(L.ClockTime), tostring(L.ExposureCompensation), tostring(atm and atm.Density), table.concat((function() local t={} for _,x in ipairs(workspace:GetChildren()) do t[#t+1]=x.Name end return t end)(),","),
 table.concat((function() local t={} for _,x in ipairs(P.PlayerGui:GetChildren()) do if x:IsA("ScreenGui") and x.Enabled then t[#t+1]=x.Name end end return t end)(),","))'''
print("CLIENT", L(Q))
print("SERVER", L('local n=0 for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") then n+=1 end end local p=game.Players:GetPlayers()[1] return "parts="..n.." hrp="..tostring(p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Position)',"Server"))
print("GUIS", L('''local P=game.Players.LocalPlayer local t={} for _,g in ipairs(P.PlayerGui:GetDescendants()) do if g:IsA("GuiObject") and g.Visible and g.AbsoluteSize.X>600 and g.AbsoluteSize.Y>400 then local vis=true local a=g while a and a:IsA("GuiObject") do if not a.Visible then vis=false end a=a.Parent end if vis then t[#t+1]=g:GetFullName().." bgT="..tostring(g.BackgroundTransparency).." col="..tostring(g.BackgroundColor3).." z="..g.ZIndex end end end return table.concat(t," | ")'''))
print(call("screen_capture",{"capture_id":"probe_default"}))
print("HIDE", L('for _,g in ipairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") then g.Enabled=false end end return 1'))
print(call("screen_capture",{"capture_id":"probe_nogui"}))
print(call("get_console_output",{})[-2500:])
print(call("start_stop_play",{"is_start":False})); time.sleep(2)
print(L('workspace:SetAttribute("DevHoldLobby",nil) return 1',"Edit"))
p.terminate()
