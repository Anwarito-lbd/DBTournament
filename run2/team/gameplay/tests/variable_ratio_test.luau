local VR = require("./_lib/VariableRatio")
local passed, failed = 0, 0
local function test(n, f)
	local ok, e = pcall(f)
	if ok then
		passed += 1
	else
		failed += 1
		print("FAIL " .. n .. ": " .. tostring(e))
	end
end
local function eq(a, b)
	if a ~= b then
		error("expected " .. tostring(b) .. " got " .. tostring(a), 2)
	end
end

test("pity limit guarantees trigger at 6 matches", function()
	eq(VR.shouldTrigger(5, 0.99), false)
	eq(VR.shouldTrigger(6, 0.99), true)
	eq(VR.shouldTrigger(10, 0.99), true)
end)

test("variable ratio triggers dynamically with random roll", function()
	eq(VR.shouldTrigger(0, 0.10), true)
	eq(VR.shouldTrigger(0, 0.35), false)
	eq(VR.shouldTrigger(3, 0.30), true) -- Dynamic bump at 3 misses
end)

test("reward rolls give valid tiers and non-P2W payloads", function()
	local common = VR.rollReward(0.30)
	eq(common.tier, "Common")
	local ok1, _ = VR.validateReward(common)
	eq(ok1, true)

	local uncommon = VR.rollReward(0.70)
	eq(uncommon.tier, "Uncommon")
	local ok2, _ = VR.validateReward(uncommon)
	eq(ok2, true)

	local jackpot = VR.rollReward(0.99)
	eq(jackpot.tier, "Jackpot")
	eq(jackpot.title, "Omni-Blessed")
	local ok3, _ = VR.validateReward(jackpot)
	eq(ok3, true)
end)

test("near miss triggers when under 18% remaining", function()
	local isNear1, form1, _ = VR.checkNearMiss(850, 1000, 14) -- 15% left, Lv14 -> Lv15 unlocks Super Saiyan!
	eq(isNear1, true)
	eq(form1, "Super Saiyan")

	local isNear2, _, _ = VR.checkNearMiss(500, 1000, 14) -- 50% left -> no near miss
	eq(isNear2, false)
end)

test("reward validator rejects stat boosting payloads", function()
	local bad = { tier = "Jackpot", damage = 1.5, powerLevel = 9999 }
	local ok, why = VR.validateReward(bad)
	eq(ok, false)
	eq(type(why), "string")
end)

print(string.format("VARIABLE-RATIO TESTS: %d passed, %d failed", passed, failed))
if failed > 0 then
	error("VariableRatio tests failed")
end
