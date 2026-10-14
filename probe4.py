exec(open("install.py",encoding="utf-8").read().split('T=r"team"')[0])
print(call("execute_luau",{"code":'''local out={}
local function f(x) local ok,s=pcall(function() return x.Source end) return ok and s or "" end
local pd=game.ServerScriptService.Modules:FindFirstChild("PlayerData")
out[#out+1]="PD len="..#f(pd).." tutorial="..tostring(f(pd):find("utorial")~=nil).." consumeDrink="..tostring(f(pd):find("consumeDrink")~=nil)
for _,d in ipairs(game:GetDescendants()) do if d:IsA("LuaSourceContainer") and (d.Name:find("Tutorial") or d.Name:find("Mobile") or d.Name:find("CharacterSelect")) then out[#out+1]=d:GetFullName().." "..#f(d) end end
return table.concat(out,"\\n")'''}))
p.terminate()
