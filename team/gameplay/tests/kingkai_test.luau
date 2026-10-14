local KK = require("./_lib/KingKaiMath")
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

test("bubbles speed progression is +10% per round", function()
	local s1 = KK.bubblesSpeed(1)
	local s2 = KK.bubblesSpeed(2)
	local s3 = KK.bubblesSpeed(3)
	local s4 = KK.bubblesSpeed(4)
	local s5 = KK.bubblesSpeed(5)

	eq(s1, 14.0)
	eq(math.abs(s2 - (14.0 * 1.10)) < 1e-4, true)
	eq(math.abs(s3 - (14.0 * 1.21)) < 1e-4, true)
	eq(math.abs(s4 - (14.0 * 1.331)) < 1e-4, true)
	eq(math.abs(s5 - (14.0 * 1.4641)) < 1e-4, true)
	eq(s5 <= 22.0, true) -- Within 14-22 st/s specification
end)

test("bubbles rewards are XP and title only", function()
	local r3 = KK.bubblesReward(3)
	eq(r3.xp, 1500)
	eq(r3.title, nil)
	local ok3, _ = KK.validateReward(r3)
	eq(ok3, true)

	local r5 = KK.bubblesReward(5)
	eq(r5.xp, 2500)
	eq(r5.title, "Monkey Business")
	local ok5, _ = KK.validateReward(r5)
	eq(ok5, true)
end)

test("gregory 10 bonks in 60s passes", function()
	eq(KK.checkGregoryVictory(10, 55), true)
	eq(KK.checkGregoryVictory(10, 60), true)
	eq(KK.checkGregoryVictory(12, 45), true)
end)

test("gregory under 10 bonks or timeout fails", function()
	eq(KK.checkGregoryVictory(9, 59), false)
	eq(KK.checkGregoryVictory(10, 60.1), false)
	eq(KK.checkGregoryVictory(0, 10), false)
end)

test("gregory reward is strictly XP and title only", function()
	local failReward = KK.gregoryReward(false)
	eq(failReward, nil)

	local winReward = KK.gregoryReward(true)
	eq(winReward ~= nil, true)
	if winReward then
		eq(winReward.xp, 3000)
		eq(winReward.title, "Cricket Whacker")
		local ok, _ = KK.validateReward(winReward)
		eq(ok, true)
	end
end)

test("reward validator rejects stat boosting items", function()
	local bad1 = { xp = 1000, damage = 1.2 }
	local ok1, why1 = KK.validateReward(bad1)
	eq(ok1, false)
	eq(type(why1), "string")

	local bad2 = { xp = 1000, statBoost = 5 }
	local ok2, _ = KK.validateReward(bad2)
	eq(ok2, false)
end)

print(string.format("KING KAI TESTS: %d passed, %d failed", passed, failed))
if failed > 0 then
	error("King Kai tests failed")
end
