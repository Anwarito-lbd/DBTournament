--!strict
-- ModuleScript: ServerScriptService.Modules.DragonBallService  (v8; GDD §8.7; rules in Shared/DragonBalls.lua)
-- Each player hunts their own 7 balls per week (reset Monday 00:00 UTC). Positions are server-authoritative and seeded
-- (userId, week) from db-map anchors tagged DragonBallSpawn (fallback: Config.DRAGON_BALLS.fallbackAnchors).
-- The server sends ONLY that player their ball positions (client renders them + the Dragon Radar); collecting is validated
-- server-side (distance to the server position <= 8 studs, 1.5 s min interval, not in a match, not already held).
-- 7 balls -> SummonShenron (once per week, outside matches) -> 60 s to pick ONE wish: cosmetic / title / Zeni only
-- (DragonBalls.validateWish rejects anything with stat/xp/unlock effects -> the 1.35x cap can't be exceeded).
-- Persistence: profile.dragonBalls (schema v8). Remotes: DragonBallState (s->c), CollectDragonBall(i), SummonShenron(),
-- ShenronWish(wishId, choice?).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local DragonBalls = require(Shared.DragonBalls)
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)

local DragonBallService = {}
local StateRemote = Net.remote("DragonBallState")
local Collect = Net.remote("CollectDragonBall")
local Summon = Net.remote("SummonShenron")
local Wish = Net.remote("ShenronWish")
local pendingWish: { [Player]: number } = {} -- player -> deadline (os.clock)

local function anchors(): { any }
	local list = {}
	-- v8b: db-map DBSpawn_NN parts (WorldOfVoid.DragonBallSpawns, tag DragonBallSpawn, attrs AreaId + Index).
	-- Tag first; else any BasePart named DBSpawn_* under WorldOfVoid; else Config fallback anchors.
	local parts: { BasePart } = {}
	for _, x in CollectionService:GetTagged(Config.DRAGON_BALLS.anchorTag) do
		if x:IsA("BasePart") then
			table.insert(parts, x)
		end
	end
	if #parts < DragonBalls.COUNT then
		parts = {}
		local w = workspace:FindFirstChild("WorldOfVoid")
		if w then
			for _, x in w:GetDescendants() do
				if x:IsA("BasePart") and string.sub(x.Name, 1, 8) == "DBSpawn_" then
					table.insert(parts, x)
				end
			end
		end
	end
	if #parts < DragonBalls.COUNT then
		return Config.DRAGON_BALLS.fallbackAnchors
	end
	table.sort(parts, function(a, b) -- stable order for seeding: Index attr, then name
		local ia, ib = a:GetAttribute("Index") or 0, b:GetAttribute("Index") or 0
		return if ia == ib then a.Name < b.Name else ia < ib
	end)
	for _, x in parts do
		table.insert(list, { x = x.Position.X, y = x.Position.Y - 3, z = x.Position.Z })
	end -- positions() adds +3
	return list
end

local function state(p: Player): any?
	local prof = PlayerData.get(p) :: any
	if not prof then
		return nil
	end
	if type(prof.dragonBalls) ~= "table" then
		prof.dragonBalls = DragonBalls.new()
	end
	DragonBalls.refresh(prof.dragonBalls, os.time())
	return prof.dragonBalls
end

local function positions(p: Player, s: any): { any }
	return DragonBalls.positions(p.UserId, s.week, anchors())
end

local function push(p: Player)
	local s = state(p)
	if not s then
		return
	end
	local pos = positions(p, s)
	local balls = {}
	for i, v in pos do
		balls[i] = { i = i, pos = Vector3.new(v.x, v.y, v.z), have = s.have[i] == true }
	end
	p:SetAttribute("DragonBalls", DragonBalls.count(s))
	StateRemote:FireClient(p, {
		week = s.week,
		balls = balls,
		summoned = s.summoned,
		wishes = DragonBalls.WISHES,
		rotation = DragonBalls.rotation(s.week),
	})
end
DragonBallService.push = push

local function inMatch(p: Player): boolean
	return workspace:GetAttribute("RoundState") == "InRound" and p:GetAttribute("Alive") == true
end

Collect.OnServerEvent:Connect(function(p, i)
	if type(i) ~= "number" or not RateLimit.allow(p, "dball", 2, 3) or inMatch(p) then
		return
	end
	local s = state(p)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not s or not r then
		return
	end
	local v = positions(p, s)[i]
	if not v then
		return
	end
	local dist = (r.Position - Vector3.new(v.x, v.y, v.z)).Magnitude
	local ok, why = DragonBalls.collect(s, i, dist, os.clock())
	if ok then
		PlayerData.saveSoon(p)
	else
		StateRemote:FireClient(p, { error = why })
	end
	push(p)
end)

Summon.OnServerEvent:Connect(function(p)
	if not RateLimit.allow(p, "shenron", 1, 1) or inMatch(p) then
		return
	end
	local s = state(p)
	if not s then
		return
	end
	local ok, why = DragonBalls.canSummon(s)
	if not ok then
		StateRemote:FireClient(p, { error = why })
		return
	end
	s.summoned = true -- balls turn to stone now (consumed even if the player leaves without wishing -> no dupes)
	s.wishPending = true -- persisted: if the player leaves, the wish is re-offered on next join
	PlayerData.saveSoon(p)
	DragonBallService.openWish(p, s)
end)

function DragonBallService.openWish(p: Player, s: any)
	pendingWish[p] = os.clock() + DragonBalls.WISH_WINDOW
	Wish:FireClient(
		p,
		{ wishes = DragonBalls.WISHES, rotation = DragonBalls.rotation(s.week), seconds = DragonBalls.WISH_WINDOW }
	)
	push(p)
	task.delay(DragonBalls.WISH_WINDOW, function()
		if pendingWish[p] and p.Parent then -- timeout: default wish = Zeni (never lose the reward)
			pendingWish[p] = nil
			s.wishPending = false
			PlayerData.grantReward(p, (DragonBalls.resolve("Zeni", nil, s.week)))
			Wish:FireClient(p, { granted = "Zeni", timeout = true })
		end
	end)
end

Wish.OnServerEvent:Connect(function(p, wishId, choice)
	if type(wishId) ~= "string" or (choice ~= nil and type(choice) ~= "string") then
		return
	end
	if not RateLimit.allow(p, "wish", 1, 2) then
		return
	end
	local deadline = pendingWish[p]
	if not deadline or os.clock() > deadline then
		return
	end
	local s = state(p)
	if not s then
		return
	end
	local reward, why = DragonBalls.resolve(wishId, choice, s.week)
	if not reward then
		Wish:FireClient(p, { error = why })
		return
	end
	pendingWish[p] = nil
	s.wishPending = false
	PlayerData.grantReward(p, reward) -- cosmetic / title / zeni only; saves
	Wish:FireClient(p, { granted = wishId, choice = choice })
end)

function DragonBallService.init()
	-- lint: refuse to run with an invalid wish table (e.g. someone adds a stat wish)
	for _, w in DragonBalls.WISHES do
		local ok, why = DragonBalls.validateWish(w)
		assert(ok, "[DragonBallService] invalid wish " .. tostring(w.id) .. ": " .. tostring(why))
	end
	local function ready(p: Player)
		task.spawn(function()
			local t = os.clock()
			while p.Parent and not p:GetAttribute("DataLoaded") and os.clock() - t < 60 do
				task.wait(0.5)
			end
			if p.Parent then
				push(p)
				local s = state(p)
				if s and s.wishPending and not pendingWish[p] then
					DragonBallService.openWish(p, s)
				end
			end
		end)
	end
	Players.PlayerAdded:Connect(ready)
	for _, p in Players:GetPlayers() do
		ready(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		pendingWish[p] = nil
	end)
	task.spawn(function() -- weekly reset for long sessions
		while true do
			task.wait(300)
			for _, p in Players:GetPlayers() do
				local s = state(p)
				if s then
					push(p)
				end
			end
		end
	end)
end

return DragonBallService
