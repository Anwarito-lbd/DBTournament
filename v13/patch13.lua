-- TEMP harness patches (Edit mode): 4 universes in dev solo, 7 bots spread over U2..U4, ROUND_MAX 150 (Jiren at 75 s).
local function sub(inst, a, b)
	local s = inst.Source; local i = s:find(a, 1, true)
	if not i then return inst.Name .. ": NOT FOUND " .. a:sub(1, 40) end
	inst.Source = s:sub(1, i - 1) .. b .. s:sub(i + #a); return inst.Name .. ": ok"
end
local out = {}
local cfg = game.ReplicatedStorage.Shared.Config
out[#out+1] = sub(cfg, "Config.ROUND_MAX = 300", "Config.ROUND_MAX = 150")
local ta = game.ServerScriptService.Modules.TeamAssignment
out[#out+1] = sub(ta, "for i = 1, 2 do\n\t\tlocal t = Instance.new(\"Team\")", "for i = 1, 4 do\n\t\tlocal t = Instance.new(\"Team\")")
out[#out+1] = sub(ta, "renumber(universes, { #players, 0 })", "renumber(universes, { #players, 0, 0, 0 })")
local rm = game.ServerScriptService.RoundManager
out[#out+1] = sub(rm, "if sp then DevBots.spawn(Config.DEV_BOTS, universes[2], sp.CFrame) end",
	"DevBots.clear() for ui = 2, #universes do local s2 = Arena.spawnFor(\"Arena\", universes[ui]:GetAttribute(\"Universe\") :: number?) or sp if s2 then DevBots.spawn(if ui == 2 then 3 else 2, universes[ui], s2.CFrame, true) end end")
out[#out+1] = sub(rm, "if sp then DevBots.placeAll(sp.CFrame) end", "-- (test harness: bots stay on their own universe spawns)")
local h = game.ServerScriptService:FindFirstChild("V13TestHooks") if h then h:Destroy() end
return table.concat(out, "\n")
