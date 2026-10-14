local RM = require("./_lib/ReplayMath")
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

test("ring buffer caps at maxSize and overwrites oldest", function()
	local buf = RM.newRingBuffer(5)
	eq(buf.count, 0)

	for i = 1, 5 do
		RM.pushFrame(buf, { t = i, x = i * 10, y = 0, z = 0 })
	end
	eq(buf.count, 5)

	local frames1 = RM.getFrames(buf)
	eq(#frames1, 5)
	eq(frames1[1].t, 1)
	eq(frames1[5].t, 5)

	-- Push 2 more frames (should overwrite t=1 and t=2)
	RM.pushFrame(buf, { t = 6, x = 60, y = 0, z = 0 })
	RM.pushFrame(buf, { t = 7, x = 70, y = 0, z = 0 })
	eq(buf.count, 5)

	local frames2 = RM.getFrames(buf)
	eq(#frames2, 5)
	eq(frames2[1].t, 3)
	eq(frames2[2].t, 4)
	eq(frames2[3].t, 5)
	eq(frames2[4].t, 6)
	eq(frames2[5].t, 7)
end)

test("findBestMoment identifies the 8-second max-damage window", function()
	local events = {
		{ t = 1.0, attacker = "Goku", victim = "Jiren", damage = 50, combo = 3 },
		{ t = 3.0, attacker = "Goku", victim = "Jiren", damage = 80, combo = 5 },
		-- High burst window at t=15
		{ t = 15.0, attacker = "Vegeta", victim = "Toppo", damage = 200, combo = 8 },
		{ t = 16.5, attacker = "Vegeta", victim = "Toppo", damage = 350, combo = 15 },
		{ t = 18.0, attacker = "Vegeta", victim = "Toppo", damage = 400, combo = 22 },
		-- Later minor hits at t=28
		{ t = 28.0, attacker = "Frieza", victim = "Dyspo", damage = 90, combo = 4 },
	}

	local best = RM.findBestMoment(events, 8)
	eq(best ~= nil, true)
	if best then
		eq(best.startTime, 15.0)
		eq(best.endTime, 23.0)
		eq(best.totalDamage, 950) -- 200 + 350 + 400
		eq(best.maxCombo, 22)
		eq(best.attacker, "Vegeta")
		eq(best.victim, "Toppo")
	end
end)

test("memory estimate for 40 players at 300 frames is <= 2 MB", function()
	local bytes = RM.estimateMemoryBytes(40, 300)
	local mb = bytes / (1024 * 1024)
	eq(mb <= 2.0, true)
	eq(mb < 1.2, true) -- ~0.91 MB
end)

print(string.format("REPLAY TESTS: %d passed, %d failed", passed, failed))
if failed > 0 then
	error("Replay tests failed")
end
