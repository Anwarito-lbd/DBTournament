local Q = require("./_lib/Quests")
local passed, failed = 0, 0
local function test(n, f) local ok, e = pcall(f); if ok then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end
local function eq(a, b) if a ~= b then error("expected " .. tostring(b) .. " got " .. tostring(a), 2) end end
local T = 1760000000
test("refresh deterministic + distinct", function()
	local a, b = Q.new(), Q.new()
	Q.refresh(a, 42, T); Q.refresh(b, 42, T)
	eq(#a.daily, 3); eq(#a.weekly, 3)
	for i = 1, 3 do eq(a.daily[i].id, b.daily[i].id) end
	eq(a.daily[1].id ~= a.daily[2].id and a.daily[2].id ~= a.daily[3].id and a.daily[1].id ~= a.daily[3].id, true)
	eq(Q.refresh(a, 42, T + 10), false)
	eq(Q.refresh(a, 42, T + 86400), true)
end)
test("track, claim once", function()
	local s = Q.new(); Q.refresh(s, 7, T)
	local d = Q.def(s.daily[1].id)
	eq((Q.claim(s, "daily", 1)), nil)
	local done = Q.track(s, d.key, d.goal + 5)
	eq(#done >= 1, true); eq(s.daily[1].prog, d.goal)
	local r = Q.claim(s, "daily", 1); eq(r.id, d.id)
	local r2, why = Q.claim(s, "daily", 1); eq(r2, nil); eq(why, "AlreadyClaimed")
	eq(select(2, Q.claim(s, "monthly", 1)), "BadScope")
end)
test("reroll 1/day", function()
	local s = Q.new(); Q.refresh(s, 9, T)
	local old = s.daily[2].id
	eq((Q.reroll(s, 2, 9, T)), true); eq(s.daily[2].id ~= old, true); eq(s.daily[2].prog, 0)
	eq(select(2, Q.reroll(s, 1, 9, T)), "NoRerollsLeft")
	Q.refresh(s, 9, T + 86400); eq((Q.reroll(s, 1, 9, T + 86400)), true)
end)
test("weekly resets on week boundary only", function()
	local s = Q.new(); Q.refresh(s, 3, T); local w = s.week
	Q.refresh(s, 3, T + 86400); local same = Q.weekOf(T + 86400) == w
	eq(s.week == w, same)
end)
print(("%d passed, %d failed"):format(passed, failed)); if failed > 0 then error("tests failed") end
