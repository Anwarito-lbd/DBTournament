import sys
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
q=sys.argv[1]
print(call("execute_luau",{"code":'local t={} for _,d in ipairs(game:GetDescendants()) do local ok,src=pcall(function() return d:IsA("LuaSourceContainer") and d.Source end) if ok and src and src:find(%r,1,true) then t[#t+1]=d:GetFullName() end end return table.concat(t,"\\n")'%q}))
print(call("execute_luau",{"code":'local t={} for _,d in ipairs(game.StarterPlayer.StarterPlayerScripts:GetChildren()) do t[#t+1]=d.Name end for _,d in ipairs(game.ServerScriptService:GetChildren()) do t[#t+1]="SSS."..d.Name end for _,d in ipairs(game.StarterGui:GetChildren()) do t[#t+1]="SG."..d.Name end return table.concat(t,", ")'}))
p.terminate()
