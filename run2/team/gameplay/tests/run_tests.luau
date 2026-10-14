-- Plain Luau tests for Races / Modifiers / StatResolver.  Run:  luau gameplay/tests/run_tests.luau
-- (copies of the Shared modules are resolved via ./ relative requires from tests/_lib, see run.sh)
local Races = require("./_lib/Races")
local Modifiers = require("./_lib/Modifiers")
local SR = require("./_lib/StatResolver")

local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then passed += 1 else failed += 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end
local function near(a, b, msg) if math.abs(a - b) > 1e-6 then error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end
local function has(t, v) return table.find(t, v) ~= nil end

-- Races
test("race map", function()
	eq(Races.raceOf("u7_goku"), "Saiyan"); eq(Races.raceOf("u7_gohan"), "HalfSaiyan")
	eq(Races.raceOf("u11_toppo"), "PrideTrooper"); eq(Races.raceOf("u11_jiren"), "JirenType")
	eq(Races.raceOf("div_destroyer_beerus"), "Destroyer"); eq(Races.raceOf("div_angel_whis"), "Angel")
	eq(Races.raceOf("u2_ribrianne"), "Earthling"); eq(Races.raceOf(nil), "Earthling")
	eq(Races.get("u7_android_17").ki, "infinite"); eq(Races.get("u7_android_17").canTransform, false)
end)
test("angel race keeps autoDodge + powerUps table", function() assert(Races.LIST.Angel.autoDodge == 0.35); for id, r in Races.LIST do assert(type(r.powerUps) == "table", id) end end)
test("describe", function() eq(Races.describe("u7_piccolo").race, "Namekian") end)

-- Modifier stacking
test("kaioken on base & blue only", function()
	assert(Modifiers.canStack("Kaioken_x10", "SuperSaiyanBlue", "Saiyan", {}))
	assert(Modifiers.canStack("Kaioken_x2", "Base", "Saiyan", {}))
	local ok, why = Modifiers.canStack("Kaioken_x2", "SuperSaiyan", "Saiyan", {}); eq(ok, false); eq(why, "FormNotAllowed")
	eq((Modifiers.canStack("Kaioken_x2", "MUI", "Saiyan", {})), false)
	eq((Modifiers.canStack("Kaioken_x2", "Base", "Android", {})), false)
end)
test("one kaioken level at a time", function()
	local ok, why = Modifiers.canStack("Kaioken_x3", "Base", "Saiyan", { "Kaioken_x2" }); eq(ok, false); eq(why, "GroupConflict")
	eq((Modifiers.canStack("Kaioken_x2", "Base", "Saiyan", { "Kaioken_x2" })), false)
end)
test("ultra ego only in form; beast only half-saiyan", function()
	eq((Modifiers.canStack("UltraEgoGrowth", "SuperSaiyanBlue", "Saiyan", {})), false)
	assert(Modifiers.canStack("UltraEgoGrowth", "UltraEgo", "Saiyan", {}))
	eq((Modifiers.canStack("BeastRelease", "Base", "Saiyan", {})), false)
	assert(Modifiers.canStack("BeastRelease", "Base", "HalfSaiyan", {}))
end)
test("prune on form change", function()
	local k = Modifiers.prune("SuperSaiyan", "Saiyan", { "Kaioken_x10", "Zenkai" })
	eq(#k, 1); eq(k[1], "Zenkai")
end)

-- Resolver
test("rule1 multiplicative", function()
	local r = SR.resolve({ race = "Saiyan", formMult = 4.5, mods = { { id = "Kaioken_x10" } } })
	near(r.combat.damage, 1.05 * 1.15); near(r.total.damage, 1.05 * 1.15 * 4.5)
	near(r.kiDrainPerSec, 4); near(r.hpDrainPerSec, 0.01)
end)
test("rule2 paid cap 1.35 regardless of stacking", function()
	local r = SR.resolve({ race = "Earthling", formMult = 1, paid = 1.3, mods = { { id = "EnergyDrink" } } })
	near(r.paid, 1.35); assert(has(r.clamped, "paid")); near(r.total.damage, 1.35)
	near(r.combat.damage, 1) -- paid never enters combat mult (it's in Power Level)
	local r2 = SR.resolve({ race = "Earthling", paid = 0.5 }); near(r2.paid, 1)
end)
test("rule3 ranked normalizes", function()
	local r = SR.resolve({ race = "JirenType", formMult = 6, paid = 1.35, ranked = true,
		mods = { { id = "Kaioken_x20" }, { id = "EnergyDrink" }, { id = "Zenkai", stacks = 5 } } })
	near(r.total.damage, 1); near(r.combat.damage, 1); near(r.combat.defense, 1); near(r.paid, 1)
	near(r.kiDrainPerSec, 6 + 0) -- utility/costs still apply
end)
test("rule4 hard caps", function()
	local r = SR.resolve({ race = "JirenType", formMult = 6, mods = { { id = "Kaioken_x20" }, { id = "Zenkai", stacks = 5 }, { id = "RageBurst" } } })
	near(r.combat.damage, 1.6); assert(has(r.clamped, "combat.damage"))
	local t = SR.resolve({ race = "Saiyan", formMult = 20 }); near(t.total.damage, 8); assert(has(t.clamped, "total.damage"))
end)
test("zenkai cap +10%", function()
	local r = SR.resolve({ race = "Earthling", mods = { { id = "Zenkai", stacks = 9 } } }); near(r.combat.damage, 1.10)
end)
test("ultra ego growth", function()
	local f = function(lost) return SR.resolve({ race = "Earthling", mods = { { id = "UltraEgoGrowth" } }, hpLostFrac = lost }) end
	near(f(0).combat.damage, 1); near(f(0.2).combat.damage, 1.10); near(f(1).combat.damage, 1.40); near(f(0.5).combat.defense, 0.85)
end)
test("god aura ki gate", function()
	near(SR.resolve({ race = "Earthling", mods = { { id = "GodAura" } }, kiFrac = 0.8 }).combat.defense, 1.05)
	near(SR.resolve({ race = "Earthling", mods = { { id = "GodAura" } }, kiFrac = 0.3 }).combat.defense, 1)
end)
test("android infinite ki no drain", function()
	local r = SR.resolve({ charId = "u7_android_18", mods = { { id = "Kaioken_x2" } } })
	eq(r.infiniteKi, true); near(r.kiDrainPerSec, 0)
end)
test("combat ratio compression", function()
	local a = SR.resolve({ race = "Saiyan", mods = { { id = "Kaioken_x20" } } })
	local v = SR.resolve({ race = "Earthling", mods = { { id = "UltraEgoGrowth" } } })
	near(SR.combatRatio(1.73, a, v, 1.35), 1.35); near(SR.combatRatio(0.1, nil, nil, 1.35), 1 / 1.35)
	near(SR.combatRatio(1, nil, nil, 1.35), 1)
end)

print(("%d passed, %d failed"):format(passed, failed))
if failed > 0 then error("tests failed") end
