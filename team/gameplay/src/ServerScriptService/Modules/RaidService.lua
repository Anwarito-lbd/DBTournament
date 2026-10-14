--!strict
-- ModuleScript: ServerScriptService.Modules.RaidService  (v8; GDD §7.4; Config.RAIDS / RAID_RUNTIME; math in RaidMath)
-- Lobby queue per raid (RaidJoin(raidId) / RaidLeave()): 4-8 players (DEV Studio: 1). Countdown 20 s once the minimum is
-- reached (starts immediately when full). Start: allocate an instance arena (db-map tag RaidArena, else generated),
-- teleport participants, set attributes InRaid/RaidId (Combat lets them act; targets = bosses only, no PvP), spawn the
-- boss with HP x (1 + 0.6 (n-1)) and damage x (1 + 0.08 (n-1)). Ends on boss defeat (rewards), all participants down /
-- left, or the time limit (fail). Cleanup returns everyone to Spawn_Lobby_01 and frees the arena.
-- Rewards (victory, per participant present): Zeni 300/550/800 by tier x (0.5 + damage share, max 1), XP 250 x tier,
-- first clear of the week (deterministic) + one FREE cosmetic drop with PUBLISHED odds (Config.RAIDS.*.drops, shown via
-- RaidInfo). Quest key "raidClear". Persistence: profile.raids (schema v8).
-- Remotes: RaidJoin(raidId), RaidLeave(), RaidUpdate (s->c), RaidInfo (c->s request; s->c raids + odds).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local RaidMath = require(Shared.RaidMath)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)
local QuestService = require(script.Parent.QuestService)
local Combat = require(script.Parent.Combat)
local BossNPC = require(script.Parent.BossNPC)

local RaidService = {}
local RR = Config.RAID_RUNTIME
local Join = Net.remote("RaidJoin")
local Leave = Net.remote("RaidLeave")
local Update = Net.remote("RaidUpdate")
local Info = Net.remote("RaidInfo")

local queues: { [string]: { Player } } = {}
local countdown: { [string]: number? } = {}
local inRaid: { [Player]: any } = {}

local function DEV(): boolean return Config.DEV_MODE and RunService:IsStudio() end
local function minPlayers(def: any): number return if DEV() then RR.devMinPlayers else def.minPlayers end
local function busy(p: Player): boolean
	return inRaid[p] ~= nil or (workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") == true)
		or p:GetAttribute("InStory") == true
end
local function dequeue(p: Player)
	for id, q in queues do
		local i = table.find(q, p)
		if i then table.remove(q, i); for _, o in q do Update:FireClient(o, { queue = id, size = #q }) end end
	end
end

local function lobbySpawn(): CFrame
	local s = (workspace:FindFirstChild("WorldOfVoid") or workspace):FindFirstChild("Spawn_Lobby_01", true) :: BasePart?
	return if s then s.CFrame + Vector3.new(0, 3, 0) else CFrame.new(0, 105, 0)
end
local function tp(p: Player, cf: CFrame)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if r then r.AssemblyLinearVelocity = Vector3.zero; r.CFrame = cf end
end

local function weekOf(t: number): number return (t // 86400 + 3) // 7 end

local function finish(run: any, victory: boolean)
	if run.done then return end
	run.done = true
	local def = run.def
	local total = 0
	for _, v in run.boss.dmgBy do total += v end
	local week = weekOf(os.time())
	local rng = Random.new()
	for _, p in run.players do
		if not p.Parent then continue end
		if victory and inRaid[p] == run then
			local share = if total > 0 then (run.boss.dmgBy[p] or 0) / total else 0
			local reward: any = { zeni = RaidMath.zeni(def.tier, share), xp = 250 * def.tier }
			local prof = PlayerData.get(p) :: any
			if prof then
				prof.raids.clears = (prof.raids.clears or 0) + 1
				if prof.raids.firstClearWeek[run.id] ~= week then
					prof.raids.firstClearWeek[run.id] = week
					reward.zeni += def.firstClear.zeni
					reward.cosmetic = def.firstClear.cosmetic
				end
			end
			local drop = RaidMath.rollDrop(def.drops, rng:NextNumber())
			PlayerData.grantReward(p, reward)
			if drop then PlayerData.grantReward(p, { cosmetic = drop }) end
			QuestService.track(p, "raidClear", 1)
			Update:FireClient(p, { result = "Victory", raid = run.id, reward = reward, drop = drop })
		else
			Update:FireClient(p, { result = "Defeat", raid = run.id })
		end
	end
	task.delay(if victory then 6 else 3, function()
		for _, p in run.players do
			if inRaid[p] == run then
				inRaid[p] = nil
				p:SetAttribute("InRaid", nil); p:SetAttribute("RaidId", nil); p:SetAttribute("LightingPreset", "Lobby")
				if p.Parent then tp(p, lobbySpawn()) end
			end
		end
		if run.boss.alive then BossNPC.despawn(run.boss) end
		BossNPC.freeArena(run.arena, run.slot)
	end)
end

local function start(id: string)
	local def = Config.RAIDS[id]
	local q = queues[id] or {}
	local players = {}
	for _, p in q do if p.Parent and not busy(p) and #players < def.maxPlayers then table.insert(players, p) end end
	queues[id] = {}
	countdown[id] = nil
	if #players < minPlayers(def) then for _, p in players do Update:FireClient(p, { error = "NotEnoughPlayers" }) end; return end
	local arena, cf, slot, info = BossNPC.allocArena(id)
	local run: any = { id = id, def = def, players = players, arena = arena, slot = slot, t0 = os.clock(), done = false }
	for i, p in players do
		inRaid[p] = run
		p:SetAttribute("InRaid", true); p:SetAttribute("RaidId", id)
		p:SetAttribute("LightingPreset", info.areaId or id) -- db-map preset (BrolyCrater / MoroNamek); client falls back
		Combat.resetPlayer(p)
		local pad = info.spawns[((i - 1) % math.max(1, #info.spawns)) + 1]
		if pad then tp(p, pad) else
			local a = (i / #players) * math.pi * 2
			tp(p, cf * CFrame.new(math.cos(a) * 40, 0, math.sin(a) * 40))
		end
		local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if h then
			h.Health = h.MaxHealth
			h.Died:Once(function() -- down: out of this raid (respawns in the lobby normally)
				if inRaid[p] == run then inRaid[p] = nil; p:SetAttribute("InRaid", nil); p:SetAttribute("RaidId", nil); p:SetAttribute("LightingPreset", "Lobby") end
			end)
		end
		Update:FireClient(p, { started = id, players = #players, timeLimit = def.timeLimit })
	end
	local bossDef = table.clone(def); bossDef.id = id
	run.boss = BossNPC.spawn(bossDef, info.bossCF or (cf * CFrame.new(0, 2, -30)), arena, players, { onDefeated = function() finish(run, true) end })
	task.spawn(function()
		while not run.done do
			task.wait(1)
			local alive = 0
			for _, p in players do if inRaid[p] == run and p.Parent then alive += 1 end end
			if alive == 0 or os.clock() - run.t0 > def.timeLimit then finish(run, false) end
		end
	end)
end

Join.OnServerEvent:Connect(function(p, id)
	if type(id) ~= "string" or not Config.RAIDS[id] or not RateLimit.allow(p, "raid", 1, 2) or busy(p) then return end
	dequeue(p)
	local q = queues[id] or {}
	queues[id] = q
	table.insert(q, p)
	local def = Config.RAIDS[id]
	for _, o in q do Update:FireClient(o, { queue = id, size = #q, min = minPlayers(def), max = def.maxPlayers }) end
	if #q >= def.maxPlayers then start(id)
	elseif #q >= minPlayers(def) and not countdown[id] then
		countdown[id] = os.clock() + RR.lobbyCountdown
		for _, o in q do Update:FireClient(o, { countdown = RR.lobbyCountdown }) end
		task.delay(RR.lobbyCountdown, function() if countdown[id] then start(id) end end)
	end
end)
Leave.OnServerEvent:Connect(function(p) dequeue(p) end)
Info.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "raidinfo", 1, 2) then return end
	local list = {}
	for id, d in Config.RAIDS do
		table.insert(list, { id = id, name = d.name, min = d.minPlayers, max = d.maxPlayers, tier = d.tier, odds = d.drops, firstClear = d.firstClear })
	end
	Info:FireClient(p, list) -- published drop odds
end)

function RaidService.init()
	for id, d in Config.RAIDS do assert(RaidMath.oddsValid(d.drops), "[RaidService] invalid odds for " .. id) end
	BossNPC.setHooks({ attack = Combat.npcHit, takeKi = Combat.takeKi, lastMove = Combat.lastMoveId })
	Players.PlayerRemoving:Connect(function(p) dequeue(p); inRaid[p] = nil end)
	-- v8b: db-map RaidFallZone (attr RaidId): falling off a raid map returns you to a RaidSpawn pad (no KO)
	local CollectionService = game:GetService("CollectionService")
	local function hookFall(z: Instance)
		if not z:IsA("BasePart") then return end
		z.Touched:Connect(function(hit)
			local p = Players:GetPlayerFromCharacter(hit.Parent)
			if not p or not inRaid[p] then return end
			for _, s in CollectionService:GetTagged("RaidSpawn") do
				if s:IsA("BasePart") and s:GetAttribute("RaidId") == z:GetAttribute("RaidId") then tp(p, s.CFrame + Vector3.new(0, 3, 0)); return end
			end
		end)
	end
	for _, z in CollectionService:GetTagged("RaidFallZone") do hookFall(z) end
	CollectionService:GetInstanceAddedSignal("RaidFallZone"):Connect(hookFall)
	task.spawn(function() while true do task.wait(RR.tick); BossNPC.tick() end end)
end
function RaidService.isInRaid(p: Player): boolean return inRaid[p] ~= nil end

return RaidService
