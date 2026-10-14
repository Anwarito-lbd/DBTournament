exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":'''local m=require(game.ServerScriptService.TrainingAreas) local ok,res=pcall(m.BuildAll) if not ok then return "ERR "..tostring(res) end
local t={} for k,v in pairs(res) do t[#t+1]=k.."="..tostring(v) end
local tr=workspace.WorldOfVoid:FindFirstChild("Training") return table.concat(t,", ").." | children="..(tr and #tr:GetChildren() or -1)'''}))
p.terminate()
