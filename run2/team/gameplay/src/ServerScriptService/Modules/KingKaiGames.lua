--!strict
-- ModuleScript: ServerScriptService.Modules.KingKaiGames (WP-TRAIN-2)
-- Implements King Kai training minigames:
-- 1. Bubbles Chase (5 rounds, speed +10% per round, touch within 30s) -> XP + "Monkey Business" title
-- 2. Gregory Hammer (10 bonks in 60s, swing hammer within 8 studs) -> XP + "Cricket Whacker" title
-- Strictly non-P2W (rewards XP and titles only, adhering to D13 and 1.35x cap).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local KingKaiMath = require(Shared:WaitForChild("KingKaiMath"))
local Net = require(script.Parent.Net)
local RateLimit = require(script.Parent.RateLimit)
local PlayerData = require(script.Parent.PlayerData)

local KingKaiGames = {}

local ActionRemote = Net.remote("KingKaiAction")
local UpdateRemote = Net.remote("KingKaiUpdate")

type BubblesSession = {
	player: Player,
	round: number,
	timeLeft: number,
	pos: Vector3,
	targetPos: Vector3,
	center: Vector3,
	active: boolean,
}

type GregorySession = {
	player: Player,
	bonks: number,
	timeLeft: number,
	pos: Vector3,
	center: Vector3,
	active: boolean,
	lastSwing: number,
}

local bubblesSessions: { [Player]: BubblesSession } = {}
local gregorySessions: { [Player]: GregorySession } = {}

local function root(p: Player): BasePart?
	return if p.Character then p.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function randomSurfacePos(center: Vector3, radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local dist = 8 + math.random() * radius
	return center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

function KingKaiGames.startBubbles(p: Player)
	local r = root(p)
	if not r then
		return
	end
	local center = r.Position
	local session: BubblesSession = {
		player = p,
		round = 1,
		timeLeft = KingKaiMath.BUBBLES_ROUND_TIME,
		pos = center + Vector3.new(15, 0, 0),
		targetPos = randomSurfacePos(center, 25),
		center = center,
		active = true,
	}
	bubblesSessions[p] = session

	UpdateRemote:FireClient(p, "StartBubbles", {
		round = 1,
		maxRounds = KingKaiMath.BUBBLES_ROUNDS,
		time = KingKaiMath.BUBBLES_ROUND_TIME,
		speed = KingKaiMath.bubblesSpeed(1),
		pos = session.pos,
	})

	task.spawn(function()
		while session.active and p.Parent do
			task.wait(0.1)
			session.timeLeft -= 0.1
			if session.timeLeft <= 0 then
				-- Round timeout -> end session
				session.active = false
				local reward = KingKaiMath.bubblesReward(session.round - 1)
				if reward.xp > 0 then
					PlayerData.grantReward(p, reward)
				end
				UpdateRemote:FireClient(p, "BubblesFailed", {
					cleared = session.round - 1,
					reward = reward,
				})
				bubblesSessions[p] = nil
				break
			end

			-- Move Bubbles toward target position
			local curSpeed = KingKaiMath.bubblesSpeed(session.round)
			local dir = session.targetPos - session.pos
			local dist = dir.Magnitude
			if dist < 2 then
				session.targetPos = randomSurfacePos(session.center, 25)
			else
				local step = math.min(dist, curSpeed * 0.1)
				session.pos = session.pos + dir.Unit * step
			end

			-- Proximity auto-catch check if player is close
			local pr = root(p)
			if pr and (pr.Position - session.pos).Magnitude <= KingKaiMath.BUBBLES_CATCH_RANGE then
				KingKaiGames.catchBubbles(p)
			end
		end
	end)
end

function KingKaiGames.catchBubbles(p: Player)
	local session = bubblesSessions[p]
	if not session or not session.active then
		return
	end
	local pr = root(p)
	if not pr or (pr.Position - session.pos).Magnitude > KingKaiMath.BUBBLES_CATCH_RANGE + 4 then
		return
	end

	UpdateRemote:FireClient(p, "BubblesCaught", {
		round = session.round,
	})

	if session.round >= KingKaiMath.BUBBLES_ROUNDS then
		session.active = false
		local reward = KingKaiMath.bubblesReward(KingKaiMath.BUBBLES_ROUNDS)
		local ok, why = KingKaiMath.validateReward(reward)
		if ok then
			PlayerData.grantReward(p, reward)
		else
			warn("[KingKaiGames] Invalid reward: " .. tostring(why))
		end
		UpdateRemote:FireClient(p, "BubblesVictory", {
			reward = reward,
		})
		bubblesSessions[p] = nil
	else
		session.round += 1
		session.timeLeft = KingKaiMath.BUBBLES_ROUND_TIME
		session.targetPos = randomSurfacePos(session.center, 25)
		UpdateRemote:FireClient(p, "BubblesRound", {
			round = session.round,
			time = KingKaiMath.BUBBLES_ROUND_TIME,
			speed = KingKaiMath.bubblesSpeed(session.round),
			pos = session.pos,
		})
	end
end

function KingKaiGames.startGregory(p: Player)
	local r = root(p)
	if not r then
		return
	end
	local center = r.Position
	local session: GregorySession = {
		player = p,
		bonks = 0,
		timeLeft = KingKaiMath.GREGORY_TIME,
		pos = center + Vector3.new(6, 4, 6),
		center = center,
		active = true,
		lastSwing = 0,
	}
	gregorySessions[p] = session

	UpdateRemote:FireClient(p, "StartGregory", {
		goal = KingKaiMath.GREGORY_GOAL_BONKS,
		time = KingKaiMath.GREGORY_TIME,
		pos = session.pos,
	})

	task.spawn(function()
		local t0 = os.clock()
		while session.active and p.Parent do
			task.wait(0.1)
			session.timeLeft -= 0.1
			local elapsed = os.clock() - t0

			-- Gregory erratic flight (sine/cosine elevation & wander)
			local angle = elapsed * 1.8
			local height = math.sin(elapsed * 2.5) * 3 + 4
			local radius = 8 + math.cos(elapsed * 1.2) * 5
			session.pos = session.center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)

			UpdateRemote:FireClient(p, "GregoryPos", {
				pos = session.pos,
				timeLeft = math.max(0, math.ceil(session.timeLeft)),
			})

			if session.timeLeft <= 0 then
				session.active = false
				UpdateRemote:FireClient(p, "GregoryFailed", {
					bonks = session.bonks,
					goal = KingKaiMath.GREGORY_GOAL_BONKS,
				})
				gregorySessions[p] = nil
				break
			end
		end
	end)
end

function KingKaiGames.swingHammer(p: Player)
	local session = gregorySessions[p]
	if not session or not session.active then
		return
	end
	local now = os.clock()
	if now - session.lastSwing < KingKaiMath.GREGORY_SWING_COOLDOWN then
		return
	end
	session.lastSwing = now

	local pr = root(p)
	if not pr then
		return
	end

	local dist = (pr.Position - session.pos).Magnitude
	if dist <= KingKaiMath.GREGORY_HIT_RANGE then
		session.bonks += 1
		UpdateRemote:FireClient(p, "GregoryBonk", {
			bonks = session.bonks,
			goal = KingKaiMath.GREGORY_GOAL_BONKS,
			pos = session.pos,
		})

		if session.bonks >= KingKaiMath.GREGORY_GOAL_BONKS then
			session.active = false
			local reward = KingKaiMath.gregoryReward(true)
			if reward then
				local ok, why = KingKaiMath.validateReward(reward)
				if ok then
					PlayerData.grantReward(p, reward)
				else
					warn("[KingKaiGames] Invalid reward: " .. tostring(why))
				end
			end
			UpdateRemote:FireClient(p, "GregoryVictory", {
				reward = reward,
			})
			gregorySessions[p] = nil
		end
	else
		UpdateRemote:FireClient(p, "GregorySwingMiss", {})
	end
end

ActionRemote.OnServerEvent:Connect(function(p, action)
	if type(action) ~= "string" or not RateLimit.allow(p, "kk_action", 4, 1) then
		return
	end
	if action == "Catch" or action == "Grab" then
		KingKaiGames.catchBubbles(p)
	elseif action == "Swing" or action == "Bonk" then
		KingKaiGames.swingHammer(p)
	end
end)

function KingKaiGames.init()
	local TrainingRoomsMod = script.Parent:FindFirstChild("TrainingRooms")
	if TrainingRoomsMod then
		local ok, TrainingRooms = pcall(function()
			return require(TrainingRoomsMod)
		end)
		if ok and type(TrainingRooms) == "table" and TrainingRooms.registerDrill then
			TrainingRooms.registerDrill("CatchBubbles", function(p)
				KingKaiGames.startBubbles(p)
			end)
			TrainingRooms.registerDrill("HitGregory", function(p)
				KingKaiGames.startGregory(p)
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(p)
		bubblesSessions[p] = nil
		gregorySessions[p] = nil
	end)
end

return KingKaiGames
