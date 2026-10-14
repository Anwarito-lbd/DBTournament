exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":open("scan.lua",encoding="utf-8").read()}))
print(call("execute_luau",{"code":'local t={} for _,r in ipairs({workspace,game.ServerStorage,game.ReplicatedStorage}) do for _,c in ipairs(r:GetChildren()) do t[#t+1]=c:GetFullName() end end return table.concat(t,", ")'}))
p.terminate()
