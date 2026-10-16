-- v10 Legendary Episodes: StoryEpisodes data + EpisodeLogic state machine (run via run.sh)
local EL = require("./_lib/EpisodeLogic")
local SE = require("./_lib/StoryEpisodes")
local passed, failed = 0, 0
local function test(n, f) local o, e = pcall(f); if o then passed += 1 else failed += 1; print("FAIL " .. n .. ": " .. tostring(e)) end end
local function eq(a, b) if a ~= b then error(("expected %s got %s"):format(tostring(b), tostring(a)), 2) end end
local function ok(c, m) if not c then error(m or "assertion failed", 2) end end

local list, errs = EL.normalize(SE.LIST)
local def = list[1]

test("episode data validates with no skipped entries", function()
	for _, e in errs do print("SKIP " .. e) end
	eq(#errs, 0)
	eq(#list, #SE.LIST)
	eq(def.id, "saiyan_arrival_01")
end)

test("every cinematic beat names a shot and has a duration", function()
	for _, a in def.acts do
		if a.kind == "cinematic" then
			ok(type(a.maxSeconds) == "number", a.id .. " needs maxSeconds")
			for _, b in a.beats do
				ok(type(b.cam) == "string", a.id .. " beat without cam")
				ok(type(b.duration) == "number" and b.duration > 0, a.id .. " beat without duration")
			end
		end
	end
end)

test("act order: train before boss, clash before hold, finisher last fight", function()
	local idx = {}
	for i, a in def.acts do idx[a.id] = i end
	ok(idx.training < idx.phase1 and idx.phase1 < idx.clash and idx.clash < idx.phase2 and idx.phase2 < idx.hold and idx.hold < idx.finisher)
	eq(def.acts[#def.acts].kind, "cinematic")
end)

test("normalize rejects bad episodes without crashing", function()
	local l, e = EL.normalize({
		{ id = "a", title = "A", lead = "u7_goku", acts = { { kind = "nope" } } },
		{ id = "b", title = "B", lead = "u7_goku", acts = { { kind = "boss" } } }, -- boss act, no boss def
		{ id = "c", title = "C", lead = "u7_goku", acts = { { kind = "cinematic", beats = {} } }, rewards = { xp = 1e9 } },
		{ id = "c", title = "C2", lead = "u7_goku", acts = { { kind = "cinematic", beats = {} } } },
		"junk",
	})
	eq(#l, 1); eq(l[1].id, "c"); eq(l[1].rewards.xp, 5000); eq(#e, 4)
	local l2, e2 = EL.normalize(nil)
	eq(#l2, 0); eq(#e2, 1)
end)

test("sequential unlock", function()
	local two = { { id = "e1" }, { id = "e2" } }
	eq(EL.unlocked(two, "e1", nil), true)
	eq(EL.unlocked(two, "e2", {}), false)
	eq(EL.unlocked(two, "e2", { e1 = { cleared = true } }), true)
	eq(EL.unlocked(two, "missing", {}), false)
end)

test("training objectives complete only from matching signals", function()
	local run = EL.newRun(def, true)
	EL.advance(run, def) -- intro -> training
	eq(def.acts[run.act].kind, "train")
	eq(EL.onSignal(run, def, "storyHit"), false)
	eq(EL.onSignal(run, def, "storyHit"), false)
	eq(EL.onSignal(run, def, "storyHit"), false) -- capped at count, still needs parry + vanish
	eq(run.progress.strike, 2)
	eq(EL.onSignal(run, def, "bogus"), false)
	eq(EL.onSignal(run, def, "parry"), false)
	eq(EL.onSignal(run, def, "vanish"), true)
end)

test("signals outside a train act are ignored", function()
	local run = EL.newRun(def, true) -- act 1 = cinematic
	eq(EL.onSignal(run, def, "storyHit"), false)
	eq(run.progress.strike, nil)
end)

test("checkpoints: KO resumes at the last checkpoint act", function()
	local run = EL.newRun(def, true)
	while def.acts[run.act].id ~= "phase1" do EL.advance(run, def) end
	local cp = run.checkpoint
	eq(def.acts[cp].id, "phase1")
	EL.advance(run, def) -- clashIntro (no checkpoint)
	eq(EL.onDeath(run), cp)
	eq(run.deaths, 1)
	while def.acts[run.act].id ~= "phase2" do EL.advance(run, def) end
	eq(def.acts[run.checkpoint].id, "clash")
	eq(def.acts[EL.onDeath(run)].id, "clash")
end)

test("advance runs off the end and returns nil", function()
	local run = EL.newRun(def, true)
	local n = 1
	while EL.advance(run, def) do n += 1 end
	eq(n, #def.acts)
end)

test("skip only after first clear, only cinematics", function()
	local fresh, veteran = EL.newRun(def, true), EL.newRun(def, false)
	eq(EL.canSkip(fresh, def.acts[1]), false)
	eq(EL.canSkip(veteran, def.acts[1]), true)
	eq(EL.canSkip(veteran, def.acts[2]), false) -- training is gameplay
end)

test("rewards: full first clear, fraction on replay, nothing otherwise", function()
	local r, first = EL.finish(EL.newRun(def, true), def, "clear")
	ok(r ~= nil and first)
	eq((r :: any).xp, def.rewards.xp); eq((r :: any).title, def.rewards.title)
	local r2, first2 = EL.finish(EL.newRun(def, false), def, "clear")
	eq(first2, false); eq((r2 :: any).xp, math.floor(def.rewards.xp * def.replayFraction)); eq((r2 :: any).title, nil)
	for _, res in { "quit", "disconnect", "failed" } do
		local x = EL.finish(EL.newRun(def, true), def, res)
		eq(x, nil)
	end
end)

test("100 repeated finish events grant exactly once", function()
	local run = EL.newRun(def, true)
	local grants = 0
	for _ = 1, 100 do
		local r = EL.finish(run, def, "clear")
		if r then grants += 1 end
	end
	eq(grants, 1)
	eq(EL.finish(run, def, "quit"), nil) -- a later quit can't overwrite a clear
	eq(run.result, "clear")
end)

test("recordClear counts clears and keeps the best time", function()
	local rec = EL.recordClear(nil, 300)
	eq(rec.cleared, true); eq(rec.clears, 1); eq(rec.bestTime, 300)
	rec = EL.recordClear(rec, 420); eq(rec.clears, 2); eq(rec.bestTime, 300)
	rec = EL.recordClear(rec, 250.27); eq(rec.bestTime, 250.2)
end)

test("struggle outcomes", function()
	local c = { winScore = 30, maxTime = 6 }
	eq(EL.struggleOutcome("clash", 30, 1, c), "win")
	eq(EL.struggleOutcome("clash", -30, 1, c), "lose")
	eq(EL.struggleOutcome("clash", 5, 2, c), nil)
	eq(EL.struggleOutcome("clash", 5, 6, c), "win")
	eq(EL.struggleOutcome("clash", 0, 6, c), "lose")
	eq(EL.struggleOutcome("hold", 50, 2, c), nil) -- hold never ends early on a high score
	eq(EL.struggleOutcome("hold", 1, 6, c), "win")
	eq(EL.struggleOutcome("hold", -30, 3, c), "lose")
end)

test("boss def matches the BossNPC def contract", function()
	local b = def.boss
	ok(type(b.hp) == "number" and b.hp > 0)
	ok(type(b.melee) == "table" and type(b.melee.cd) == "number")
	for name, sp in b.specials do ok(type(sp.cd) == "number", name .. " needs cd") end
end)

print(("%d passed, %d failed"):format(passed, failed))
if failed > 0 then error("tests failed") end
