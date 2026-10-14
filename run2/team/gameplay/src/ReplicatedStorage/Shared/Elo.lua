--!strict
-- ModuleScript: ReplicatedStorage.Shared.Elo  (PURE; GDD §7.2; tests in gameplay/tests)
-- Start 1000. K = 32 for the first 20 (provisional) games, then 20. E = 1/(1+10^((Rb-Ra)/400)).
-- Team matches: each player uses the TEAM-AVERAGE rating for E; each player's own K (provisional players move faster).
-- Ranks: Earthling <1000, Saiyan 1000-1199, Elite 1200-1399, God 1400-1599, Angel 1600-1799, Grand Priest 1800+ AND top 100
-- (else shown as Angel). Seasons: 8 weeks from SEASON_EPOCH. Decay: GDD silent -> config-driven, OFF by default.
local Elo = {}

Elo.START, Elo.K_PROVISIONAL, Elo.K, Elo.PROVISIONAL_GAMES = 1000, 32, 20, 20
Elo.SEASON_WEEKS = 8
Elo.SEASON_EPOCH = 1767571200 -- 2026-01-05 00:00 UTC (Monday) -> season 1
Elo.FLOOR = 100
Elo.RANKS = {
	{ id = "Earthling", min = -math.huge },
	{ id = "Saiyan", min = 1000 },
	{ id = "Elite", min = 1200 },
	{ id = "God", min = 1400 },
	{ id = "Angel", min = 1600 },
	{ id = "GrandPriest", min = 1800 },
}
Elo.GP_TOP = 100
Elo.DECAY = { enabled = false, graceDays = 14, perDay = 5, floor = 1200 } -- PROPOSAL (needs lead approval)

function Elo.expected(ra: number, rb: number): number
	return 1 / (1 + 10 ^ ((rb - ra) / 400))
end
function Elo.k(games: number): number
	return if games < Elo.PROVISIONAL_GAMES then Elo.K_PROVISIONAL else Elo.K
end

local function avg(t: { number }): number
	local s = 0
	for _, v in t do
		s += v
	end
	return if #t > 0 then s / #t else Elo.START
end

-- teamA/teamB: arrays of { elo, games }. scoreA: 1 win, 0 loss, 0.5 draw. Returns deltas (rounded) for A and B.
function Elo.update(
	teamA: { { elo: number, games: number } },
	teamB: { { elo: number, games: number } },
	scoreA: number
): ({ number }, { number })
	local ea, eb = {}, {}
	for _, p in teamA do
		table.insert(ea, p.elo)
	end
	for _, p in teamB do
		table.insert(eb, p.elo)
	end
	local ra, rb = avg(ea), avg(eb)
	local expA = Elo.expected(ra, rb)
	local da, db = {}, {}
	for _, p in teamA do
		table.insert(da, math.floor(Elo.k(p.games) * (scoreA - expA) + 0.5))
	end
	for _, p in teamB do
		table.insert(db, math.floor(Elo.k(p.games) * ((1 - scoreA) - (1 - expA)) + 0.5))
	end
	return da, db
end

function Elo.apply(elo: number, delta: number): number
	return math.max(Elo.FLOOR, elo + delta)
end

-- position: leaderboard position (1-based) or nil if unknown
function Elo.rank(elo: number, position: number?): string
	local id = "Earthling"
	for _, r in Elo.RANKS do
		if elo >= r.min then
			id = r.id
		end
	end
	if id == "GrandPriest" and not (position and position <= Elo.GP_TOP) then
		id = "Angel"
	end
	return id
end

function Elo.season(now: number): number
	return math.max(1, (now - Elo.SEASON_EPOCH) // (Elo.SEASON_WEEKS * 7 * 86400) + 1)
end

-- Soft reset at a new season: pull toward 1000 by half (proposal; needs approval)
function Elo.seasonReset(elo: number): number
	return math.floor(Elo.START + (elo - Elo.START) * 0.5 + 0.5)
end

function Elo.decay(elo: number, daysIdle: number, cfg: any?): number
	local c = cfg or Elo.DECAY
	if not c.enabled or elo <= c.floor or daysIdle <= c.graceDays then
		return elo
	end
	return math.max(c.floor, elo - (daysIdle - c.graceDays) * c.perDay)
end

-- Matchmaking window: +-100, widening +50 every 10 s, max +-400
function Elo.window(waitSeconds: number): number
	return math.min(400, 100 + 50 * (waitSeconds // 10))
end

return Elo
