exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":'''local t={} for _,d in ipairs(workspace:GetDescendants()) do if d:IsA("SpawnLocation") then t[#t+1]=d:GetFullName().." @"..tostring(d.Position).." en="..tostring(d.Enabled) end end
local w=workspace.WorldOfVoid local c={} for _,x in ipairs(w:GetChildren()) do local ok,cf,sz=pcall(function() if x:IsA("Model") then return x:GetBoundingBox() end return x.CFrame,x.Size end) c[#c+1]=x.Name..(ok and (" @"..tostring(cf.Position).." sz="..tostring(sz)) or "") end
return table.concat(t,"\\n").."\\n--\\n"..table.concat(c,"\\n")'''}))
print(call("execute_luau",{"code":'local s=game.ServerScriptService.Modules.PlayerData.Source local a=s:find("ProcessReceipt") local b=s:find("zeni") return tostring(a).." "..tostring(b).." "..#s'}))
print(call("execute_luau",{"code":'local s=game.ServerScriptService.RoundManager.Source local t={} for l in s:gmatch("[^\\n]*[Ll]obby[^\\n]*") do t[#t+1]=l:sub(1,160) if #t>14 then break end end return table.concat(t,"\\n")'}))
p.terminate()
