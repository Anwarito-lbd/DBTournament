import json,sys,time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("start_stop_play",{"is_start":True})); time.sleep(20)
print(call("get_studio_state",{}))
srv='local P=game.Players:GetPlayers(); local o={"players="..#P,"RoundState="..tostring(workspace:GetAttribute("RoundState")),"TimeLeft="..tostring(workspace:GetAttribute("TimeLeft")),"remotes="..#game.ReplicatedStorage:WaitForChild("Remotes",5):GetChildren()}; for _,p in P do local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); table.insert(o,p.Name.." team="..tostring(p.Team).." pos="..tostring(r and r.Position).." attrs="..game:GetService("HttpService"):JSONEncode(p:GetAttributes())) end; return table.concat(o," | ")'
print("SERVER:",call("execute_luau",{"code":srv,"datamodel_type":"Server"}))
cli='local p=game.Players.LocalPlayer; local o={}; for _,g in p.PlayerGui:GetChildren() do table.insert(o,g.Name) end; return "gui="..table.concat(o,",").." vfx="..#game.ReplicatedStorage.VFX:GetChildren()'
print("CLIENT:",call("execute_luau",{"code":cli,"datamodel_type":"Client"}))
print(call("screen_capture",{"camera_position":[0,640,560],"look_at_position":[0,490,0],"capture_id":"Play_Arena"}))
print(call("screen_capture",{"camera_position":[2960,140,90],"look_at_position":[2960,100,0],"capture_id":"Play_Lobby"}))
print(call("get_console_output",{}))
print(call("start_stop_play",{"is_start":False}))
p.terminate()
