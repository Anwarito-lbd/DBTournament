exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":open("audit.lua",encoding="utf-8").read()}))
print(call("execute_luau",{"code":open("scan.lua",encoding="utf-8").read()}))
p.terminate()
