--!strict
-- ModuleScript: ServerScriptService.Modules.Party
-- Queue modes (Party / Random) + party invites. Client -> server via Remotes.QueueRequest(action, arg).
-- Actions: "SetMode"(mode), "Invite"(userId), "Accept"(leaderUserId), "Decline"(leaderUserId), "Leave"(), "Kick"(userId)
-- Server -> client via Remotes.QueueState(state) and Remotes.PartyInvite(fromUserId, fromName).
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)

local Party = {}

local QueueRequest = Net.remote("QueueRequest")
local QueueState = Net.remote("QueueState")
local PartyInvite = Net.remote("PartyInvite")

type PartyT = { leader: Player, members: { Player } }
local partyOf: { [Player]: PartyT } = {}
local modeOf: { [Player]: string } = {}
local invites: { [Player]: { [number]: number } } = {} -- invitee -> leaderUserId -> expiry (os.clock)
local INVITE_TTL = 60


local function publish(p: Player)
	local party = partyOf[p]
	local ids = {}
	if party then for _, m in party.members do table.insert(ids, m.UserId) end end
	p:SetAttribute("QueueMode", modeOf[p] or "Random")
	p:SetAttribute("PartyLeader", if party then party.leader.UserId else 0)
	QueueState:FireClient(p, {
		mode = modeOf[p] or "Random",
		leader = if party then party.leader.UserId else nil,
		members = ids,
	})
end

local function publishParty(party: PartyT)
	for _, m in party.members do publish(m) end
end

local function leave(p: Player)
	local party = partyOf[p]
	if not party then return end
	partyOf[p] = nil
	local i = table.find(party.members, p)
	if i then table.remove(party.members, i) end
	if #party.members <= 1 then
		for _, m in party.members do partyOf[m] = nil; publish(m) end
	else
		if party.leader == p then party.leader = party.members[1] end
		publishParty(party)
	end
	if p.Parent then publish(p) end
end

local function join(p: Player, party: PartyT): boolean
	if partyOf[p] == party then return true end
	if #party.members >= Config.MAX_PARTY then return false end
	leave(p)
	table.insert(party.members, p)
	partyOf[p] = party
	publishParty(party)
	return true
end

local function ensureParty(leader: Player): PartyT
	local party = partyOf[leader]
	if party then return party end
	local np: PartyT = { leader = leader, members = { leader } }
	partyOf[leader] = np
	return np
end

local handlers: { [string]: (Player, any) -> () } = {
	SetMode = function(p, mode)
		if type(mode) ~= "string" or not Config.QUEUE_MODES[mode] then return end
		modeOf[p] = mode
		publish(p)
	end,
	Invite = function(p, userId)
		if type(userId) ~= "number" then return end
		local target = Players:GetPlayerByUserId(userId)
		if not target or target == p then return end
		local party = partyOf[p]
		if party and party.leader ~= p then return end -- only leader invites
		if party and #party.members >= Config.MAX_PARTY then return end
		local inv = invites[target] or {}
		invites[target] = inv
		inv[p.UserId] = os.clock() + INVITE_TTL
		PartyInvite:FireClient(target, p.UserId, p.DisplayName)
	end,
	Accept = function(p, leaderId)
		if type(leaderId) ~= "number" then return end
		local inv = invites[p]
		local exp = inv and inv[leaderId]
		if not exp or exp < os.clock() then return end
		(inv :: any)[leaderId] = nil
		local leader = Players:GetPlayerByUserId(leaderId)
		if not leader then return end
		local lp = partyOf[leader]
		if lp and lp.leader ~= leader then return end -- leader lost leadership
		local party = ensureParty(leader)
		if join(p, party) then
			modeOf[p] = "Party"; modeOf[leader] = "Party"
			publishParty(party)
		end
	end,
	Decline = function(p, leaderId)
		if type(leaderId) == "number" and invites[p] then invites[p][leaderId] = nil end
	end,
	Leave = function(p) leave(p) end,
	Kick = function(p, userId)
		local party = partyOf[p]
		if not party or party.leader ~= p or type(userId) ~= "number" then return end
		local t = Players:GetPlayerByUserId(userId)
		if t and t ~= p and partyOf[t] == party then leave(t) end
	end,
}

QueueRequest.OnServerEvent:Connect(function(p, action, arg)
	if type(action) ~= "string" or not RateLimit.allow(p, "queue", 2, 5) then return end
	local h = handlers[action]
	if h then h(p, arg) end
end)

-- Auto-party from teleport group join data (e.g. TeleportService party teleports / lobby place).
local function fromJoinData(p: Player)
	local ok, jd = pcall(function() return p:GetJoinData() end)
	if not ok or type(jd) ~= "table" then return end
	local members = jd.Members
	if type(members) ~= "table" then return end
	for _, uid in members do
		local other = type(uid) == "number" and Players:GetPlayerByUserId(uid)
		if other and other ~= p then
			local party = ensureParty(partyOf[other] and partyOf[other].leader or other)
			if join(p, party) then modeOf[p] = "Party"; modeOf[party.leader] = "Party" end
			return
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	modeOf[p] = "Random"
	fromJoinData(p)
	publish(p)
end)
Players.PlayerRemoving:Connect(function(p)
	leave(p); modeOf[p] = nil; invites[p] = nil
end)

-- Matchmaking groups for a roster. Party-mode parties stay together (only members in the roster);
-- Random-mode players are solo groups. A member is grouped with its party only if the leader is in Party mode.
function Party.groupsFor(roster: { Player }): { { Player } }
	local inRoster: { [Player]: boolean } = {}
	for _, p in roster do inRoster[p] = true end
	local seen: { [Player]: boolean } = {}
	local groups = {}
	for _, p in roster do
		if not seen[p] then
			local party = partyOf[p]
			if party and modeOf[party.leader] == "Party" then
				local g = {}
				for _, m in party.members do
					if inRoster[m] and not seen[m] then seen[m] = true; table.insert(g, m) end
				end
				table.insert(groups, g)
			else
				seen[p] = true
				table.insert(groups, { p })
			end
		end
	end
	return groups
end

function Party.getMode(p: Player): string return modeOf[p] or "Random" end

return Party
