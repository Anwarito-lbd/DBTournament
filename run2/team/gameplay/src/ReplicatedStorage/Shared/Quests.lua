--!strict
-- ModuleScript: ReplicatedStorage.Shared.Quests  (PURE quest definitions + state logic; tests in gameplay/tests)
-- 3 daily + 3 weekly quests from King Kai's board, rolled deterministically per (userId, day/week).
-- 1 free reroll per day. Progress keys are emitted by the server (QuestService.track). GDD_FULL §8.5.
local Quests = {}

export type Def = { id: string, key: string, goal: number, zeni: number, xp: number?, drinks: number?, passXp: number, text: string }
export type Slot = { id: string, prog: number, claimed: boolean }
export type State = { day: number, daily: { Slot }, week: number, weekly: { Slot }, rerollDay: number }

Quests.DAILY_COUNT, Quests.WEEKLY_COUNT, Quests.FREE_REROLLS_PER_DAY = 3, 3, 1

Quests.DAILY = {
	{ id = "d_struggle", key = "struggleWin", goal = 1, zeni = 150, passXp = 300, text = "Win a beam struggle" },
	{ id = "d_parry", key = "parry", goal = 3, zeni = 100, passXp = 300, text = "Land 3 perfect guards" },
	{ id = "d_gift", key = "gift", goal = 1, zeni = 100, passXp = 300, text = "Give your last energy to a teammate" },
	{ id = "d_matches", key = "match", goal = 3, zeni = 150, xp = 200, passXp = 300, text = "Play 3 Tournament matches" },
	{ id = "d_kos", key = "ko", goal = 5, zeni = 150, passXp = 300, text = "Knock out 5 fighters" },
	{ id = "d_combo", key = "teamCombo", goal = 5, zeni = 100, passXp = 300, text = "Link 5 team combos" },
	{ id = "d_train", key = "trainMinutes", goal = 10, zeni = 120, passXp = 300, text = "Train 10 minutes in any training area" },
	{ id = "d_drink", key = "transform", goal = 3, zeni = 100, drinks = 1, passXp = 300, text = "Transform 3 times" },
} :: { Def }

Quests.WEEKLY = {
	{ id = "w_wins", key = "win", goal = 5, zeni = 600, passXp = 1000, text = "Win 5 Tournament of Power matches" },
	{ id = "w_gravity", key = "gravity300", goal = 1, zeni = 600, passXp = 1000, text = "Finish a 300G Gravity Room session" },
	{ id = "w_ringout", key = "ringout", goal = 10, zeni = 600, passXp = 1000, text = "Ring out 10 enemies" },
	{ id = "w_drills", key = "drill", goal = 10, zeni = 600, drinks = 2, passXp = 1000, text = "Clear 10 training drills" },
	{ id = "w_spiritbomb", key = "spiritBombDonate", goal = 3, zeni = 600, passXp = 1000, text = "Give ki to 3 Spirit Bombs" },
} :: { Def }

local BY_ID: { [string]: Def } = {}
for _, d in Quests.DAILY do BY_ID[d.id] = d end
for _, d in Quests.WEEKLY do BY_ID[d.id] = d end
function Quests.def(id: string): Def? return BY_ID[id] end

function Quests.dayOf(t: number): number return t // 86400 end
function Quests.weekOf(t: number): number return (t // 86400 + 3) // 7 end -- weeks start Monday 00:00 UTC

-- Deterministic pick of n distinct defs (LCG on seed) -- same result on every server.
local function pick(pool: { Def }, n: number, seed: number, exclude: { [string]: boolean }?): { Slot }
	local idx = {}
	for i, d in pool do if not (exclude and exclude[d.id]) then table.insert(idx, i) end end
	local x = seed % 2147483647
	local out = {}
	for _ = 1, math.min(n, #idx) do
		x = (x * 48271) % 2147483647
		local k = (x % #idx) + 1
		table.insert(out, { id = pool[idx[k]].id, prog = 0, claimed = false })
		table.remove(idx, k)
	end
	return out
end

function Quests.new(): State return { day = -1, daily = {}, week = -1, weekly = {}, rerollDay = -1 } end

-- Roll over day/week if needed. Returns true when anything changed.
function Quests.refresh(s: State, userId: number, now: number): boolean
	local changed = false
	local d, w = Quests.dayOf(now), Quests.weekOf(now)
	if s.day ~= d then s.day = d; s.daily = pick(Quests.DAILY, Quests.DAILY_COUNT, userId * 31 + d); changed = true end
	if s.week ~= w then s.week = w; s.weekly = pick(Quests.WEEKLY, Quests.WEEKLY_COUNT, userId * 17 + w * 7919); changed = true end
	return changed
end

-- Add progress for an event key; returns list of slots that just completed.
function Quests.track(s: State, key: string, n: number): { Slot }
	local done = {}
	if n <= 0 then return done end
	for _, list in { s.daily, s.weekly } do
		for _, slot in list do
			local d = BY_ID[slot.id]
			if d and d.key == key and not slot.claimed and slot.prog < d.goal then
				slot.prog = math.min(d.goal, slot.prog + n)
				if slot.prog >= d.goal then table.insert(done, slot) end
			end
		end
	end
	return done
end

-- Claim: scope "daily"|"weekly", index 1..3. Returns the Def (reward) or nil, reason.
function Quests.claim(s: State, scope: string, index: number): (Def?, string?)
	local list = if scope == "daily" then s.daily elseif scope == "weekly" then s.weekly else nil
	if not list then return nil, "BadScope" end
	local slot = list[index]
	if not slot then return nil, "BadIndex" end
	local d = BY_ID[slot.id]
	if not d then return nil, "Unknown" end
	if slot.claimed then return nil, "AlreadyClaimed" end
	if slot.prog < d.goal then return nil, "NotComplete" end
	slot.claimed = true
	return d, nil
end

-- Free daily reroll of an unclaimed, incomplete daily slot.
function Quests.reroll(s: State, index: number, userId: number, now: number): (boolean, string?)
	local d = Quests.dayOf(now)
	if s.rerollDay == d then return false, "NoRerollsLeft" end
	local slot = s.daily[index]
	if not slot or slot.claimed then return false, "BadIndex" end
	local ex = {}
	for _, sl in s.daily do ex[sl.id] = true end
	local new = pick(Quests.DAILY, 1, userId * 131 + d * 7 + index, ex)[1]
	if not new then return false, "PoolEmpty" end
	s.daily[index] = new
	s.rerollDay = d
	return true, nil
end

return Quests
