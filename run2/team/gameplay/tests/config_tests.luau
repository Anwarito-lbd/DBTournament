-- Config consistency checks (Config.lua is pure Luau).
local ok, Config = pcall(require, "./_lib/Config")
if not ok then print("SKIP config_tests (Config needs Roblox APIs): " .. tostring(Config)); return end
local Races = require("./_lib/Races")
local Modifiers = require("./_lib/Modifiers")
local passed, failed = 0, 0
local function test(n, f) local o, e = pcall(f); if o then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end
local function near(a, b) if math.abs(a - b) > 1e-6 then error(("expected %s got %s"):format(b, a), 2) end end
test("spirit bomb GDD numbers", function()
	local C = Config.SPIRIT_BOMB
	local function size(ki) return math.min(C.maxRadius, C.baseRadius + C.radiusPerKi * ki), math.min(C.maxDamage, C.baseDamage + C.damagePerKi * ki) end
	local r, d = size(40); near(r, 20); near(d, 64)
	r, d = size(40 + 4 * 5 * 6); near(r, 30); near(d, 100) -- 4 donors x 5 ki/s x 6 s
end)
test("moves exist + kinds", function()
	assert(Config.MOVES.Hakai.kind == "hakai" and Config.MOVES.Hakai.executeBelow == 0.15)
	assert(Config.MOVES.SpiritBomb.kind == "spiritbomb")
	assert(Config.MOVES.DestructionSphere.kind == "ray")
end)
test("modifier unlock ids are real", function()
	local known = {}
	for _, u in Config.UNLOCKS do known[u.id] = true end
	for _, id in { "Hakai", "DestructionSphere", "GodAura" } do known[id] = true end -- BeerusCamp grants
	for id, m in Modifiers.LIST do if m.unlock then assert(known[m.unlock], id .. " unlock " .. m.unlock) end end
end)
test("every roster champion has a race", function()
	for id in Config.CHAR_BY_ID do assert(Races.LIST[Races.raceOf(id)], id) end
end)
test("beerus chain", function()
	local s = Config.BEERUS.steps; assert(#s == 5 and s[4].auto and s[5].reward.early.id == "UltraEgo" and s[5].reward.early.level == 85)
end)
test("tier deflect keys valid", function() for k in Config.SPIRIT_BOMB.deflectTiers do assert(Config.TIER_RULES[k], k) end end)
print(("%d passed, %d failed"):format(passed, failed)); if failed > 0 then error("tests failed") end
