import time
exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("start_stop_play",{"is_start":True})); time.sleep(10)
print(call("execute_luau",{"code":'local t={} for _,n in ipairs({"KingKaiPlanet","WhisGround"}) do local a=workspace.WorldOfVoid.Training:FindFirstChild(n) local c={} for _,x in ipairs(a:GetChildren()) do if x:IsA("Model") then c[#c+1]=x.Name end end t[#t+1]=n..": "..table.concat(c,",") end return table.concat(t,"\\n")',"datamodel_type":"Server"}))
out=call("get_console_output",{})
print("\n".join(l for l in out.splitlines() if "Training" in l or "Store" in l or "V12" in l)[-4000:])
print(call("start_stop_play",{"is_start":False}))
p.terminate()
