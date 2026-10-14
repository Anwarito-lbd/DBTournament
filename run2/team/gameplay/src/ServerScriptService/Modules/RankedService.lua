--!strict
-- ModuleScript: ServerScriptService.Modules.RankedService  (v8; GDD §7.2; pure math in Shared/Elo.lua)
-- Lobby servers: queue (RankedQueue(format) / RankedLeave()) for "1v1" / "3v3", Lv15+, solo queue, not in a match.
--   Matchmaking every 2 s: oldest waiting player anchors a window of +-100 Elo widening +50 / 10 s (max +-400);
--   teams balanced by snake draft on Elo; then TeleportService:ReserveServer + TeleportAsync with TeleportData
--   { mode = "Ranked", format, season, teams = { {userId...}, {userId...} } }.
--   NOTE: the queue is per lobby server (no cross-server MemoryStore queue yet -- see SPEC open issues).
-- Ranked servers: TeleportData sets workspace attributes Ranked=true (StatResolver/Combat normalize: PL 3500, ratio 1,
--   no items/Senzu/divine), RankedFormat, RankedSeason; RoundManager uses RankedService.groups() for team assignment.
--   On RoundEnded: Elo update (team-average E, per-player K 32 provisional (<20 games) else 20), wins/losses, peak,
--   persisted in profile.ranked (schema v8) + OrderedDataStore "<store>_S<season>" (leaderboard). Leaving mid-match = loss.
-- Seasons: 8 weeks (Elo.season). New season: soft reset toward 1000 (proposal). Decay: Config-driven, OFF (GDD silent).
-- Remotes: RankedQueue(format), RankedLeave(), RankedUpdate (s->c), RankedLeaderboard (c->s request, s->c list).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Elo = require(Shared.Elo)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)

local RankedService = {}
local RQ = Config.RANKED_QUEUE
local QueueRemote = Net.remote("RankedQueue")
local LeaveRemote = Net.remote("RankedLeave")
local Update = Net.remote("RankedUpdate")
local Board = Net.remote("RankedLeaderboard")
local RoundEnded = Net.hook("RoundEnded")

type Entry = { p: Player, format: string, since: number, elo: number }
local queue: { Entry } = {}
local isRankedServer = false
local rankedTeams: { { number } } = {}
local resolved: { [number]: boolean } = {} -- userId -> Elo already applied this match
local leaderboard: { { userId: number, elo: number } } = {}
local positions: { [number]: number } = {}

local function season(): number
	return Elo.season(os.time())
end
local function store(): any?
	local ok, ds = pcall(function()
		return DataStoreService:GetOrderedDataStore(RQ.leaderboardStore .. "_S" .. season())
	end)
	return if ok then ds else nil
end

local function ranked(p: Player): any?
	local prof = PlayerData.get(p) :: any
	if not prof then
		return nil
	end
	local r = prof.ranked
	local s = season()
	if r.season ~= s then -- season rollover (soft reset) + decay
		if r.season ~= 0 then
			r.elo = Elo.seasonReset(r.elo)
			r.peak = r.elo
			r.wins = 0
			r.losses = 0
		end
		r.season = s
	end
	if r.lastPlayed and r.lastPlayed > 0 then
		r.elo = Elo.decay(r.elo, (os.time() - r.lastPlayed) // 86400)
	end
	return r
end

local function publish(p: Player)
	local r = ranked(p)
	if not r then
		return
	end
	p:SetAttribute("RankedElo", r.elo)
	p:SetAttribute("RankedRank", Elo.rank(r.elo, positions[p.UserId]))
	p:SetAttribute("RankedSeason", r.season)
	p:SetAttribute("RankedGames", r.games)
	Update:FireClient(p, {
		elo = r.elo,
		rank = Elo.rank(r.elo, positions[p.UserId]),
		games = r.games,
		wins = r.wins,
		losses = r.losses,
		peak = r.peak,
		season = r.season,
		provisional = r.games < Elo.PROVISIONAL_GAMES,
		queued = (function()
			for _, e in queue do
				if e.p == p then
					return e.format
				end
			end
			return nil
		end)(),
	})
end
RankedService.publish = publish

local function dequeue(p: Player)
	for i = #queue, 1, -1 do
		if queue[i].p == p then
			table.remove(queue, i)
		end
	end
end

QueueRemote.OnServerEvent:Connect(function(p, format)
	if type(format) ~= "string" or not RQ.formats[format] or not RateLimit.allow(p, "rq", 1, 2) then
		return
	end
	if isRankedServer or PlayerData.getLevel(p) < RQ.minLevel then
		Update:FireClient(p, { error = "Requires Lv" .. RQ.minLevel })
		return
	end
	if workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") == true then
		return
	end
	local r = ranked(p)
	if not r then
		return
	end
	dequeue(p)
	table.insert(queue, { p = p, format = format, since = os.clock(), elo = r.elo })
	publish(p)
end)
LeaveRemote.OnServerEvent:Connect(function(p)
	dequeue(p)
	publish(p)
end)
Board.OnServerEvent:Connect(function(p)
	if RateLimit.allow(p, "rboard", 1, 2) then
		Board:FireClient(p, leaderboard)
	end
end)

-- snake draft: sorted by elo desc -> A B B A A B ...
function RankedService.split(entries: { Entry }, teamSize: number): ({ Entry }, { Entry })
	table.sort(entries, function(a, b)
		return a.elo > b.elo
	end)
	local a, b = {}, {}
	for i, e in entries do
		local pick = ((i - 1) % 4 == 0 or (i - 1) % 4 == 3)
		if #a < teamSize and (pick or #b >= teamSize) then
			table.insert(a, e)
		else
			table.insert(b, e)
		end
	end
	return a, b
end

local function launch(format: string, a: { Entry }, b: { Entry })
	local ids = function(t: { Entry })
		local o = {}
		for _, e in t do
			table.insert(o, e.p.UserId)
		end
		return o
	end
	local data = { mode = "Ranked", format = format, season = season(), teams = { ids(a), ids(b) } }
	local players = {}
	for _, e in a do
		table.insert(players, e.p)
		dequeue(e.p)
	end
	for _, e in b do
		table.insert(players, e.p)
		dequeue(e.p)
	end
	for _, p in players do
		Update:FireClient(p, { matchFound = format })
	end
	if RunService:IsStudio() then
		warn("[RankedService] Studio: teleport skipped. Match would be " .. format)
		return
	end
	task.spawn(function()
		local ok, code = pcall(function()
			return TeleportService:ReserveServer(game.PlaceId)
		end)
		if not ok then
			warn("[RankedService] ReserveServer failed: " .. tostring(code))
			return
		end
		local opts = Instance.new("TeleportOptions")
		opts.ReservedServerAccessCode = code :: string
		opts:SetTeleportData(data)
		local ok2, err = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, players, opts)
		end)
		if not ok2 then
			warn("[RankedService] TeleportAsync failed: " .. tostring(err))
		end
	end)
end

local function matchmake()
	for format, f in RQ.formats do
		local need = f.teamSize * 2
		local pool = {}
		for _, e in queue do
			if e.format == format and e.p.Parent then
				table.insert(pool, e)
			end
		end
		table.sort(pool, function(x, y)
			return x.since < y.since
		end)
		local used: { [Entry]: boolean } = {}
		for _, anchor in pool do
			if used[anchor] then
				continue
			end
			local w = Elo.window(os.clock() - anchor.since)
			local group = { anchor }
			for _, e in pool do
				if #group >= need then
					break
				end
				if e ~= anchor and not used[e] and math.abs(e.elo - anchor.elo) <= w then
					table.insert(group, e)
				end
			end
			if #group == need then
				for _, e in group do
					used[e] = true
				end
				local a, b = RankedService.split(group, f.teamSize)
				launch(format, a, b)
			end
		end
	end
	for i = #queue, 1, -1 do -- timeouts
		if os.clock() - queue[i].since > RQ.maxWait then
			local p = queue[i].p
			table.remove(queue, i)
			Update:FireClient(p, { error = "QueueTimeout" })
		end
	end
end

-- ===== ranked server side =====
function RankedService.isRankedServer(): boolean
	return isRankedServer
end
-- Groups for TeamAssignment.assign (each group = one ranked team)
function RankedService.groups(roster: { Player }): { { Player } }
	local groups = {}
	for ti, ids in rankedTeams do
		groups[ti] = {}
		for _, p in roster do
			if table.find(ids, p.UserId) then
				table.insert(groups[ti], p)
			end
		end
	end
	return groups
end

-- Players a ranked server waits for (all teleported players; 90 s after the first join, whoever arrived)
local firstJoin = 0
function RankedService.expectedPlayers(): number
	local n = 0
	for _, t in rankedTeams do
		n += #t
	end
	if firstJoin > 0 and os.clock() - firstJoin > 90 then
		return math.min(n, 2)
	end
	return n
end

local function teamIndexOf(userId: number): number?
	for i, ids in rankedTeams do
		if table.find(ids, userId) then
			return i
		end
	end
	return nil
end

-- scoreByTeam: { [teamIndex] = 1 | 0 | 0.5 }
local function applyResults(scoreA: number, only: Player?)
	local A, B = {}, {}
	local rec = {}
	for _, p in Players:GetPlayers() do
		local ti = teamIndexOf(p.UserId)
		local r = ti and ranked(p)
		if r then
			local e = { elo = r.elo, games = r.games }
			if ti == 1 then
				table.insert(A, e)
			else
				table.insert(B, e)
			end
			rec[p] = { ti = ti, idx = if ti == 1 then #A else #B, r = r }
		end
	end
	if #A == 0 or #B == 0 then
		return
	end
	local da, db = Elo.update(A, B, scoreA)
	for p, x in rec do
		if resolved[p.UserId] or (only and p ~= only) then
			continue
		end
		resolved[p.UserId] = true
		local d = if x.ti == 1 then da[x.idx] else db[x.idx]
		local score = if x.ti == 1 then scoreA else 1 - scoreA
		local r = x.r
		r.elo = Elo.apply(r.elo, d)
		r.games += 1
		r.lastPlayed = os.time()
		r.peak = math.max(r.peak, r.elo)
		if score == 1 then
			r.wins += 1
		elseif score == 0 then
			r.losses += 1
		end
		publish(p)
		Update:FireClient(p, { result = score, delta = d, elo = r.elo })
		PlayerData.saveSoon(p)
		local ds = store()
		if ds then
			task.spawn(function()
				pcall(function()
					ds:SetAsync(tostring(p.UserId), r.elo)
				end)
			end)
		end
	end
end

local function refreshBoard()
	local ds = store()
	if not ds then
		return
	end
	local ok, pages = pcall(function()
		return ds:GetSortedAsync(false, RQ.leaderboardSize)
	end)
	if not ok then
		return
	end
	local list, pos = {}, {}
	for i, item in (pages :: any):GetCurrentPage() do
		local uid = tonumber(item.key) or 0
		table.insert(list, { userId = uid, elo = item.value })
		pos[uid] = i
	end
	leaderboard, positions = list, pos
	for _, p in Players:GetPlayers() do
		publish(p)
	end
end

function RankedService.init()
	local function onJoin(p: Player)
		if not isRankedServer then
			local ok, jd = pcall(function()
				return p:GetJoinData()
			end)
			local td = ok and jd and (jd :: any).TeleportData
			if type(td) == "table" and td.mode == "Ranked" and type(td.teams) == "table" then
				isRankedServer = true
				firstJoin = os.clock()
				rankedTeams = td.teams
				workspace:SetAttribute("Ranked", true)
				workspace:SetAttribute("RankedFormat", td.format)
				workspace:SetAttribute("RankedSeason", td.season)
			end
		end
		task.spawn(function()
			local t = os.clock()
			while p.Parent and not p:GetAttribute("DataLoaded") and os.clock() - t < 60 do
				task.wait(0.5)
			end
			if p.Parent then
				publish(p)
			end
		end)
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		onJoin(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		dequeue(p)
		-- ranked leaver mid-match: counts as a loss for the leaver only (applied before PlayerData's save on leave)
		if isRankedServer and workspace:GetAttribute("RoundState") == "InRound" and not resolved[p.UserId] then
			local ti = teamIndexOf(p.UserId)
			if ti then
				applyResults(if ti == 1 then 0 else 1, p)
			end
		end
	end)
	RoundEnded.Event:Connect(function(winner: Team?)
		if not isRankedServer then
			return
		end
		local score = 0.5
		if winner then
			for _, p in winner:GetPlayers() do
				local ti = teamIndexOf(p.UserId)
				if ti then
					score = if ti == 1 then 1 else 0
					break
				end
			end
		end
		applyResults(score, nil)
		-- one ranked match per reserved server: send everyone back to a public lobby server
		task.delay(15, function()
			if RunService:IsStudio() then
				return
			end
			local list = Players:GetPlayers()
			if #list > 0 then
				pcall(function()
					TeleportService:TeleportAsync(game.PlaceId, list)
				end)
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(RQ.tick)
			if not isRankedServer then
				matchmake()
			end
		end
	end)
	task.spawn(function()
		while true do
			refreshBoard()
			task.wait(RQ.leaderboardRefresh)
		end
	end)
end

return RankedService
