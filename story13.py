import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
def L(c,dm="Client"): return call("execute_luau",{"code":c,"datamodel_type":dm})
E=lambda c: call("execute_luau",{"code":c})
E('workspace:SetAttribute("DevHoldLobby",true) return 1')
print(call("start_stop_play",{"is_start":True})); time.sleep(10)
L('_G.__s={} game.ReplicatedStorage.Remotes.StoryUpdate.OnClientEvent:Connect(function(t) table.insert(_G.__s, string.format("%.1f %s %s",os.clock(),tostring(t.result),tostring(t.started))) end) game.ReplicatedStorage.Remotes.StoryStart:FireServer(1) return 1')
log=[]
for i in range(14):
    log.append(L('''local o={} local p=game.Players:GetPlayers()[1] local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid") local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
o[#o+1]="P hp="..tostring(h and h.Health).." y="..tostring(r and math.floor(r.Position.Y))
for _,m in ipairs(workspace:GetDescendants()) do if m:IsA("Humanoid") and m.Parent~=p.Character and string.find(m.Parent.Name,"Raditz") then local pr=m.Parent.PrimaryPart o[#o+1]=m.Parent:GetFullName().." hp="..m.Health.." y="..tostring(pr and math.floor(pr.Position.Y)).." st="..tostring(m:GetState()) end end
return table.concat(o," | ")''',"Server")); time.sleep(0.5)
for x in log: print(x)
print("UPD",L('return table.concat(_G.__s," ; ")'))
print("CON",call("get_console_output",{})[-3000:])
print(call("start_stop_play",{"is_start":False}))
