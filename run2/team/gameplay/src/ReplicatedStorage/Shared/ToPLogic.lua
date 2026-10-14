--!strict
-- ModuleScript: ReplicatedStorage.Shared.ToPLogic  (PURE Tournament of Power rules; tests in gameplay/tests/top_tests.luau)
local ToPLogic = {}

ToPLogic.SHOW_SECONDS = 48 * 60 -- the anime's 48-minute tournament
-- Show clock: real elapsed seconds compressed onto 48:00 (e.g. ROUND_MAX 300 s -> 9.6 show-seconds per real second).
function ToPLogic.showRemaining(elapsed: number, roundMax: number): number
	if roundMax <= 0 then return 0 end
	return math.max(0, math.floor(ToPLogic.SHOW_SECONDS * (1 - math.clamp(elapsed / roundMax, 0, 1)) + 0.5))
end
function ToPLogic.formatClock(s: number): string return ("%02d:%02d"):format(s // 60, s % 60) end

-- Universes for n players (mirrors TeamAssignment; Config: TARGET_TEAM_SIZE 3, MAX_TEAM_SIZE 5, MIN/MAX_TEAMS 2/8)
function ToPLogic.teamCount(n: number, cfg: any): number
	if n < 2 then return 0 end
	local t = math.floor(n / cfg.TARGET_TEAM_SIZE)
	t = math.max(t, math.ceil(n / cfg.MAX_TEAM_SIZE))
	t = math.clamp(t, cfg.MIN_TEAMS, cfg.MAX_TEAMS)
	return math.min(t, n)
end
function ToPLogic.teamCap(n: number, cfg: any): number
	local k = ToPLogic.teamCount(n, cfg)
	return if k == 0 then 0 else math.min(math.ceil(n / k), cfg.MAX_TEAM_SIZE)
end

-- Comeback ("Last Stand"): a universe that started with >= 2 fighters and is down to 1. Off in Ranked.
-- Returned id is a PAID-BUCKET modifier, so StatResolver caps it together with paid boosts at 1.35x (and Ranked = 1).
ToPLogic.COMEBACK = { modId = "LastStand", minStart = 2 }
function ToPLogic.comeback(startSize: number, aliveCount: number, ranked: boolean): string?
	if ranked or startSize < ToPLogic.COMEBACK.minStart or aliveCount ~= 1 then return nil end
	return ToPLogic.COMEBACK.modId
end

-- Erasure / win detection. counts: { [teamName] = alive fighters (players + bots) }
function ToPLogic.wiped(count: number?): boolean return (count or 0) <= 0 end
-- returns winnerName?, isOver. Over when <= 1 team left or timeUp; time-up winner = most alive (tie -> draw = nil).
function ToPLogic.resolve(counts: { [string]: number }, timeUp: boolean): (string?, boolean)
	local left, best, bestN, tie = 0, nil, -1, false
	for name, n in counts do
		if n > 0 then
			left += 1
			if n > bestN then best, bestN, tie = name, n, false elseif n == bestN then tie = true end
		end
	end
	if left <= 1 then return best, true end
	if not timeUp then return nil, false end
	return if tie then nil else best, true
end

-- Universe Survival event: a Jiren-like heavy hitter enters at 50% of the round (server-side trigger).
ToPLogic.EVENT = { at = 0.5, minPlayers = 4, minTeams = 2, baseHp = 2500, hpPerPlayer = 150, dmgPerPlayer = 0.015, dmgCap = 1.5,
	winnerZeni = 150, winnerXp = 200 }
function ToPLogic.eventTime(roundMax: number): number return math.floor(roundMax * ToPLogic.EVENT.at) end
function ToPLogic.eventShould(alivePlayers: number, aliveTeams: number, dev: boolean): boolean
	return aliveTeams >= ToPLogic.EVENT.minTeams and (dev or alivePlayers >= ToPLogic.EVENT.minPlayers)
end
function ToPLogic.eventScale(players: number): (number, number)
	local E = ToPLogic.EVENT
	return E.baseHp + E.hpPerPlayer * math.max(1, players), math.min(E.dmgCap, 1 + E.dmgPerPlayer * math.max(0, players - 1))
end

-- Super Shenron ending: cosmetic / title / Zeni only (validated like Dragon Ball wishes)
function ToPLogic.endingRewardOk(w: any): boolean
	if type(w) ~= "table" then return false end
	for _, k in { "statBoost", "stat", "mult", "xp", "level", "unlock", "form", "damage", "defense", "power" } do
		if w[k] ~= nil then return false end
	end
	return true
end

-- Arena v3: display universe numbers per team index. humans[i] = human count of team i.
-- U7 (Bulma's cheer spot) goes to the largest human team (first on tie); others take 1..6,8.. in order.
function ToPLogic.universeNumbers(humans: { number }): { number }
	local out, best = {}, nil
	for i, h in humans do if h > 0 and (best == nil or h > humans[best]) then best = i end end
	local pool, k = {}, 0
	for n = 1, 12 do if n ~= 7 or best == nil then table.insert(pool, n) end end
	for i = 1, #humans do
		if i == best then out[i] = 7 else k += 1; out[i] = pool[k] end
	end
	return out
end

-- Arena v3: chunk DamageStage 0 Intact,1 Cracked,2 Cratered,3 Detached. Only Detached ends footing.
-- Stages 1-2 are cosmetic by design (no hidden movement penalties; see SPEC).
function ToPLogic.chunkRingOut(stage: number?, detached: boolean?): boolean
	return detached == true or (stage or 0) >= 3
end

-- ===== v9 alpha edge cases (MASTER_PLAN §3 D17-D21, §10.1) =====
-- D17 timeout: most survivors, then highest summed remaining HP fraction, else a draw between the tied teams.
-- stats[name] = { n = alive fighters, hp = sum of HP fractions }. Returns winner?, tiedNames (draw when winner nil).
function ToPLogic.resolveTimeout(stats: { [string]: { n: number, hp: number } }): (string?, { string })
	local best: { string } = {}
	local bn, bh = 0, -1
	for name, v in stats do
		if v.n > 0 then
			if v.n > bn or (v.n == bn and v.hp > bh + 1e-6) then best, bn, bh = { name }, v.n, v.hp
			elseif v.n == bn and math.abs(v.hp - bh) <= 1e-6 then table.insert(best, name) end
		end
	end
	table.sort(best)
	if #best == 1 then return best[1], best end
	return nil, best
end
ToPLogic.DRAW_XP_MULT = 0.5 -- D17: tied teams each get win XP x0.5

-- §10.1 AFK: 30 s without input in a fight -> spectate; 90 s idle in the lobby -> not queued. Bots never AFK.
ToPLogic.AFK = { fight = 30, lobby = 90 }
function ToPLogic.isAfk(lastActive: number, now: number, where: "fight" | "lobby", isBot: boolean?): boolean
	if isBot then return false end
	return now - lastActive >= ToPLogic.AFK[where]
end

-- D19: 2-3 humans -> fill with bots up to 4 fighters, smallest team first (ties: lower index). Ranked never fills.
ToPLogic.BOT_FILL_TO, ToPLogic.BOT_XP_MULT = 4, 0.5
function ToPLogic.botFill(sizes: { number }, ranked: boolean?): { number }
	local out, total = table.create(#sizes, 0), 0
	for _, n in sizes do total += n end
	if ranked or total < 2 or total >= ToPLogic.BOT_FILL_TO or #sizes < 2 then return out end
	for _ = 1, ToPLogic.BOT_FILL_TO - total do
		local bi = 1
		for i = 2, #sizes do if sizes[i] + out[i] < sizes[bi] + out[bi] then bi = i end end
		out[bi] += 1
	end
	return out
end

-- D18: a struggle is 1v1 plus at most one joining beam (3 beams). The joiner adds input weight x0.5 to the side it supports.
ToPLogic.STRUGGLE_MAX_BEAMS, ToPLogic.STRUGGLE_JOIN_WEIGHT = 3, 0.5
function ToPLogic.struggleCanJoin(beams: number): boolean return beams >= 2 and beams < ToPLogic.STRUGGLE_MAX_BEAMS end

-- D20: fused body KO / ring-out eliminates both, no gift; a disconnect defuses instead (survivor keeps HP%).
function ToPLogic.fusedOutcome(reason: string): "BothOut" | "Defuse"
	return if reason == "Leave" then "Defuse" else "BothOut"
end
function ToPLogic.giftAllowed(reason: string, wasFused: boolean): boolean
	return not wasFused and (reason == "KO" or reason == "RingOut")
end

-- D21 / X = Transform: next form in the ladder that is unlocked; after the highest unlocked form, back to Base.
function ToPLogic.nextForm(ladder: { string }, current: string, unlocked: (string) -> boolean): string
	local start = table.find(ladder, current) or 0
	for i = start + 1, #ladder do if unlocked(ladder[i]) then return ladder[i] end end
	return "Base"
end

-- D24 story-gated form (SSJ4): real only when the mission is cleared AND the level is met (prestige counts as met).
function ToPLogic.storyFormOk(f: { level: number, story: number? }, level: number, prestige: number, done: { [string]: boolean }?): boolean
	if (prestige or 0) <= 0 and level < f.level then return false end
	return f.story == nil or (done ~= nil and done[tostring(f.story)] == true)
end

return ToPLogic
