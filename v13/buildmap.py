exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":'''local A=require(game.ServerScriptService.Arena) local ok1,e1=pcall(A.BuildLobby,true)
local T=require(game.ServerScriptService.TrainingAreas) local ok2,res=pcall(T.BuildAll)
local t={} if ok2 then for k,v in pairs(res) do t[#t+1]=k.."="..tostring(v) end end
local ok3,e3=pcall(A.Resize,4,8) 
return "lobby="..tostring(ok1).." "..tostring(e1).." | training="..tostring(ok2).." "..(ok2 and table.concat(t,",") or tostring(res)).." | arena="..tostring(ok3).." "..tostring(ok3 and "" or e3)'''}))
p.terminate()
