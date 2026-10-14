local out={}
local ok,s=pcall(function() return game:GetService("StudioTestService") end)
table.insert(out,"STS="..tostring(ok and s))
for _,m in {"ExecutePlayModeAsync","ExecuteRunModeAsync","EndTest","GetTestArgs","ExecuteMultiplayerAsync","StartMultiplayerTest"} do
 local ok2,v=pcall(function() return s[m] end) table.insert(out,m.."="..tostring(ok2 and v~=nil))
end
local ok3,ts=pcall(function() return game:GetService("TestService") end)
table.insert(out,"TestService.NumberOfPlayers="..tostring(ok3 and ts.NumberOfPlayers))
return table.concat(out,", ")
