--!strict
-- ModuleScript: ReplicatedStorage.Shared.KingKaiMath (Pure math and reward rules for King Kai training minigames)
-- Rules: Bubbles speed +10% per round (5 rounds). Gregory: 10 bonks in 60s. Rewards: XP + title only (1.35x cap safe).
local KingKaiMath = {}

KingKaiMath.BUBBLES_BASE_SPEED = 14.0
KingKaiMath.BUBBLES_SPEED_MULTIPLIER = 1.10
KingKaiMath.BUBBLES_ROUNDS = 5
KingKaiMath.BUBBLES_ROUND_TIME = 30
KingKaiMath.BUBBLES_CATCH_RANGE = 6.0
KingKaiMath.BUBBLES_XP_PER_ROUND = 500
KingKaiMath.BUBBLES_TITLE = "Monkey Business"

KingKaiMath.GREGORY_TIME = 60
KingKaiMath.GREGORY_GOAL_BONKS = 10
KingKaiMath.GREGORY_HIT_RANGE = 8.0
KingKaiMath.GREGORY_XP = 3000
KingKaiMath.GREGORY_TITLE = "Cricket Whacker"
KingKaiMath.GREGORY_SWING_COOLDOWN = 0.5

function KingKaiMath.bubblesSpeed(round: number): number
	local r = math.clamp(math.floor(round), 1, KingKaiMath.BUBBLES_ROUNDS)
	return KingKaiMath.BUBBLES_BASE_SPEED * (KingKaiMath.BUBBLES_SPEED_MULTIPLIER ^ (r - 1))
end

function KingKaiMath.bubblesReward(roundsCleared: number): { xp: number, title: string? }
	local r = math.clamp(math.floor(roundsCleared), 0, KingKaiMath.BUBBLES_ROUNDS)
	local xp = r * KingKaiMath.BUBBLES_XP_PER_ROUND
	local title = if r >= KingKaiMath.BUBBLES_ROUNDS then KingKaiMath.BUBBLES_TITLE else nil
	return { xp = xp, title = title }
end

function KingKaiMath.checkGregoryVictory(bonks: number, elapsed: number): boolean
	return bonks >= KingKaiMath.GREGORY_GOAL_BONKS and elapsed <= KingKaiMath.GREGORY_TIME
end

function KingKaiMath.gregoryReward(won: boolean): { xp: number, title: string? }?
	if not won then
		return nil
	end
	return { xp = KingKaiMath.GREGORY_XP, title = KingKaiMath.GREGORY_TITLE }
end

local FORBIDDEN_KEYS = {
	"damage",
	"defense",
	"hp",
	"statBoost",
	"powerLevel",
	"ki",
	"statMultiplier",
	"plMultiplier",
	"attackBoost",
	"defenseBoost",
}

function KingKaiMath.validateReward(reward: any): (boolean, string?)
	if type(reward) ~= "table" then
		return false, "Reward must be a table"
	end
	for _, k in FORBIDDEN_KEYS do
		if reward[k] ~= nil then
			return false, "P2W violation: reward cannot alter stats (" .. k .. ")"
		end
	end
	return true, nil
end

return KingKaiMath
