--!strict
-- ModuleScript: ServerScriptService.Modules.DivineFavorService
-- Operant conditioning runtime implementing the Variable-Ratio (VR-4) schedule.
-- Broadcasts unpredictable "Divine Favor" / "Zeno's Lucky Burst" celebrations at match end.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local VariableRatio = require(Shared:WaitForChild("VariableRatio"))
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)

local DivineFavorService = {}

local FavorRemote = Net.remote("DivineFavorEvent")
local RoundEnded = Net.hook("RoundEnded")

type PlayerStreak = {
	matchesWithoutDrop: number,
	totalMatches: number,
}

local streaks: { [number]: PlayerStreak } = {}

local function getStreak(userId: number): PlayerStreak
	local s = streaks[userId]
	if not s then
		s = { matchesWithoutDrop = 0, totalMatches = 0 }
		streaks[userId] = s
	end
	return s
end

-- Evaluates match completion for a player and triggers the VR roll
function DivineFavorService.onMatchCompleted(p: Player)
	local s = getStreak(p.UserId)
	s.totalMatches += 1

	local triggered = VariableRatio.shouldTrigger(s.matchesWithoutDrop)
	if triggered then
		s.matchesWithoutDrop = 0
		local reward = VariableRatio.rollReward()

		-- Validate non-P2W safety
		local ok, why = VariableRatio.validateReward(reward)
		if ok then
			PlayerData.grantReward(p, reward)
		else
			warn("[DivineFavorService] Rejected invalid reward: " .. tostring(why))
		end

		-- Check for Near-Miss framing on player level
		local prof = PlayerData.get(p) :: any
		local nearMiss, nextForm, pctLeft = false, nil, 0
		if prof then
			local xp = prof.xp or 0
			local lvl = prof.level or 1
			local SharedConfig = require(Shared.Config)
			local xpNext = SharedConfig.xpToNext(lvl)
			nearMiss, nextForm, pctLeft = VariableRatio.checkNearMiss(xp, xpNext, lvl)
		end

		-- Broadcast celebration event to player
		FavorRemote:FireClient(p, {
			reward = reward,
			nearMiss = nearMiss,
			nextForm = nextForm,
			percentLeft = pctLeft,
			matchesPlayed = s.totalMatches,
		})
	else
		s.matchesWithoutDrop += 1
	end
end

function DivineFavorService.init()
	Players.PlayerRemoving:Connect(function(p)
		streaks[p.UserId] = nil
	end)

	-- Automatically evaluate all participants on match end
	RoundEnded.Event:Connect(function()
		for _, p in Players:GetPlayers() do
			task.spawn(function()
				DivineFavorService.onMatchCompleted(p)
			end)
		end
	end)
end

return DivineFavorService
