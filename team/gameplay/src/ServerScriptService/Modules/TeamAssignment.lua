--!strict
-- ModuleScript: ServerScriptService.Modules.TeamAssignment
-- Universes: numbered teams "Universe 1..N", 2..8 teams by player count (fewer universes when few players).
-- Balance by Power Level; parties stay together, oversized parties are split into near-equal chunks.
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local TeamAssignment = {}

local COLORS = { -- Universe 1..8 (numbered teams; champion universes are lore only)
	BrickColor.new("Bright red"), BrickColor.new("Bright blue"), BrickColor.new("Lime green"), BrickColor.new("Bright yellow"),
	BrickColor.new("Bright violet"), BrickColor.new("Bright orange"), BrickColor.new("Cyan"), BrickColor.new("Hot pink"),
}

local lobbyTeam: Team? = nil
local universes: { Team } = {}

-- v8: delegates to the pure, tested ToPLogic (2..40 players -> 2..8 universes of <= 5)
local ToPLogic = require(game:GetService("ReplicatedStorage").Shared.ToPLogic)
function TeamAssignment.teamCount(n: number): number return ToPLogic.teamCount(n, Config) end
function TeamAssignment.teamCap(n: number): number return ToPLogic.teamCap(n, Config) end

function TeamAssignment.getLobby(): Team
	if not lobbyTeam then
		local t = Instance.new("Team")
		t.Name = "Lobby"
		t.TeamColor = BrickColor.new("Medium stone grey")
		t.AutoAssignable = true
		t.Parent = Teams
		lobbyTeam = t
	end
	return lobbyTeam :: Team
end

function TeamAssignment.clear()
	for _, t in universes do t:Destroy() end
	table.clear(universes)
	for _, p in Players:GetPlayers() do p.Team = TeamAssignment.getLobby() end
end

-- Split a group larger than cap into ceil(size/cap) near-equal chunks, snake-distributing by power
-- so each chunk keeps a mix of strong and weak friends.
local function splitGroup(g: { Player }, cap: number, powerOf: (Player) -> number): { { Player } }
	if #g <= cap then return { g } end
	local k = math.ceil(#g / cap)
	local sorted = table.clone(g)
	table.sort(sorted, function(a, b) return powerOf(a) > powerOf(b) end)
	local chunks = {}
	for i = 1, k do chunks[i] = {} end
	for i, p in sorted do
		local round = (i - 1) // k
		local idx = (i - 1) % k + 1
		if round % 2 == 1 then idx = k - idx + 1 end
		table.insert(chunks[idx], p)
	end
	return chunks
end

-- Arena v3: renumber display universes (team index order unchanged) so U7 = largest human team.
local function renumber(list: { Team }, humans: { number })
	local nums = ToPLogic.universeNumbers(humans)
	for i, t in list do
		local u = nums[i]
		t.Name = "Universe " .. u
		t.TeamColor = COLORS[u] or COLORS[((u - 1) % #COLORS) + 1]
		t:SetAttribute("Universe", u)
	end
end

-- groups: from Party.groupsFor (solo players are 1-element groups). Returns universe Teams.
function TeamAssignment.assign(groups: { { Player } }, powerOf: (Player) -> number): { Team }
	TeamAssignment.clear()
	local n = 0
	for _, g in groups do n += #g end
	local count = TeamAssignment.teamCount(n)
	local cap = TeamAssignment.teamCap(n)
	for i = 1, count do
		local u = i
		local t = Instance.new("Team")
		t.Name = "Universe " .. u
		t.TeamColor = COLORS[u]
		t.AutoAssignable = false
		t:SetAttribute("UniverseIndex", i)
		t:SetAttribute("Universe", u)
		t.Parent = Teams
		universes[i] = t
	end
	if count == 0 then return universes end

	-- chunk oversized parties, shuffle for tie variety, then place biggest/strongest first
	local units: { { members: { Player }, power: number } } = {}
	local rng = Random.new()
	for _, g in groups do
		for _, chunk in splitGroup(g, cap, powerOf) do
			local pw = 0
			for _, p in chunk do pw += powerOf(p) end
			table.insert(units, { members = chunk, power = pw })
		end
	end
	for i = #units, 2, -1 do
		local j = rng:NextInteger(1, i)
		units[i], units[j] = units[j], units[i]
	end
	table.sort(units, function(a, b)
		if #a.members ~= #b.members then return #a.members > #b.members end
		return a.power > b.power
	end)

	local size, power = table.create(count, 0), table.create(count, 0)
	local function place(p: Player, idx: number)
		p.Team = universes[idx]
		size[idx] += 1
		power[idx] += powerOf(p)
	end
	local function weakestWithRoom(need: number): number?
		local best: number? = nil
		for i = 1, count do
			if size[i] + need <= cap and (best == nil or power[i] < power[best :: number]
				or (power[i] == power[best :: number] and size[i] < size[best :: number])) then
				best = i
			end
		end
		return best
	end
	for _, u in units do
		local idx = weakestWithRoom(#u.members)
		if idx then
			for _, p in u.members do place(p, idx) end
		else -- bin packing failed: place members individually (rare)
			for _, p in u.members do place(p, weakestWithRoom(1) or 1) end
		end
	end
	renumber(universes, size)
	return universes
end

-- v1 dev mode: solo player -> Universe 1 (player) vs Universe 2 (training bots).
function TeamAssignment.assignDev(players: { Player }): { Team }
	TeamAssignment.clear()
	for i = 1, 2 do
		local t = Instance.new("Team")
		t.Name = "Universe " .. i
		t.TeamColor = COLORS[i]
		t.AutoAssignable = false
		t:SetAttribute("UniverseIndex", i)
		t:SetAttribute("Universe", i)
		t.Parent = Teams
		universes[i] = t
	end
	for _, p in players do p.Team = universes[1] end
	renumber(universes, { #players, 0 })
	return universes
end

function TeamAssignment.getUniverses(): { Team }
	return universes
end

function TeamAssignment.universeOf(p: Player): number?
	local t = p.Team
	return if t and t ~= lobbyTeam then t:GetAttribute("Universe") :: number? else nil
end

function TeamAssignment.onJoinMidRound(p: Player)
	p.Team = TeamAssignment.getLobby()
	p:SetAttribute("Spectating", true)
end

return TeamAssignment
