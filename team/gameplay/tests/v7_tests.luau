local Races = require("./_lib/Races")
local SR = require("./_lib/StatResolver")
local TM = require("./_lib/TrainingMath")
local Config = require("./_lib/Config")
local passed, failed = 0, 0
local function test(n, f) local o, e = pcall(f); if o then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end
local function near(a, b) if math.abs(a - b) > 1e-6 then error(("expected %s got %s"):format(b, a), 2) end end
local function eq(a, b) if a ~= b then error(("expected %s got %s"):format(tostring(b), tostring(a)), 2) end end
test("angels NPC-only by flag", function()
	eq(Config.FEATURES.PLAYABLE_ANGELS, false)
	eq(Races.isPlayable("div_angel_whis", Config.FEATURES), false)
	eq(Races.isPlayable("div_angel_whis", { PLAYABLE_ANGELS = true }), true)
	eq(Races.isPlayable("div_grand_priest", Config.FEATURES), true)
	eq(Races.isPlayable("div_destroyer_beerus", Config.FEATURES), true)
	eq(Races.isPlayable("u7_goku", nil), true)
end)
test("majin KO heal", function()
	near(Races.koHeal("Majin", "melee", false, 0.15, 0.5), 0.15)
	near(Races.koHeal("Majin", "melee", true, 0.15, 0.5), 0.075)
	near(Races.koHeal("Majin", "ray", false), 0); near(Races.koHeal("Saiyan", "melee", false), 0)
	eq(Races.raceOf("u7_moro"), "Majin")
end)
test("justice buff through resolver", function()
	near(SR.resolve({ race = "Earthling", mods = { { id = "JusticeBuff" } } }).combat.damage, 1.05)
	near(SR.resolve({ race = "Earthling", mods = { { id = "JusticeBuff" } }, ranked = true }).combat.damage, 1)
	near(SR.combatRatio(1.4, SR.resolve({ race = "JirenType", mods = { { id = "JusticeBuff" } } }), nil, 1.35), 1.35)
end)
test("training math", function()
	local steps = Config.TRAINING.GravityRoom.steps
	eq(TM.stepIndex(steps, 1), 1); eq(TM.stepIndex(steps, 299), 5); eq(TM.stepIndex(steps, 500), 7)
	near(TM.extraG(1, 0.12, 1.5), 0); near(TM.extraG(10, 0.12, 1.5), 1.08); near(TM.extraG(500, 0.12, 1.5), 1.5)
	local a, b = TM.botStats(Config.SPAR_BOTS, 1, 1), TM.botStats(Config.SPAR_BOTS, 100, 1.6)
	eq(a.hp, 150); eq(b.hp, 450); near(b.damage, 8); eq(b.xp, 64)
end)
test("power-up moves gated by race + unlock levels", function()
	for _, id in { "Barrier", "JusticePose", "SolarFlare", "KaiKai" } do
		local mv = Config.MOVES[id]; assert(mv and mv.races and mv.unlock == id and mv.ki > 0 and mv.cooldown > 0, id)
		local found = false
		for _, u in Config.UNLOCKS do if u.id == id then found = true end end
		assert(found, id .. " not in UNLOCKS")
	end
end)
test("UI sign rule", function()
	eq(Config.UI_SIGN_RULE.earlyLevel, 70); eq(Config.UI_SIGN_RULE.whisStages, 10)
	eq(Config.TRAINING_RUNTIME.drills.WhisDodge.stages, 10)
	eq(Config.TRAINING_RUNTIME.drills.WhisDodge.pathReward.early.level, 70)
	eq(Config.TRAINING_RUNTIME.owner, "TrainingRooms")
end)
print(("%d passed, %d failed"):format(passed, failed)); if failed > 0 then error("tests failed") end
