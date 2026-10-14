--!strict
-- ModuleScript: ReplicatedStorage.Shared.VariableRatio
-- Operant conditioning engine: Variable-Ratio (VR-4) schedule with dynamic pity,
-- sensory reward tiering, and Near-Miss psychological framing.
-- Strictly non-P2W (rewards are Zeni, XP, cosmetics, and titles only).
local VariableRatio = {}

VariableRatio.BASE_CHANCE = 0.22 -- 22% baseline (~1 in 4.5)
VariableRatio.PITY_LIMIT = 6 -- Guaranteed trigger if 6 matches with no drop
VariableRatio.NEAR_MISS_THRESHOLD = 0.18 -- 18% or less XP remaining triggers near-miss hook

export type DivineReward = {
	tier: "Common" | "Uncommon" | "Rare" | "Jackpot",
	name: string,
	zeni: number?,
	xp: number?,
	title: string?,
	aura: string?,
	multiplier: number?,
}

local UNLOCK_MILESTONES = {
	{ level = 5, form = "Kaioken" },
	{ level = 15, form = "Super Saiyan" },
	{ level = 30, form = "Super Saiyan 2" },
	{ level = 40, form = "Super Saiyan 3" },
	{ level = 60, form = "Super Saiyan God" },
	{ level = 75, form = "Super Saiyan Blue" },
	{ level = 85, form = "Ultra Instinct Sign" },
	{ level = 100, form = "Mastered Ultra Instinct" },
}

-- Computes whether Divine Favor triggers on this match
function VariableRatio.shouldTrigger(matchesWithoutDrop: number, randomSeed: number?): boolean
	if matchesWithoutDrop >= VariableRatio.PITY_LIMIT then
		return true
	end
	-- Dynamic scaling: slightly increases odds as streak grows without drop
	local dynamicChance = VariableRatio.BASE_CHANCE + (matchesWithoutDrop * 0.04)
	local roll = randomSeed or math.random()
	return roll < dynamicChance
end

-- Rolls a variable-ratio reward
function VariableRatio.rollReward(randomSeed: number?): DivineReward
	local roll = randomSeed or math.random()

	if roll < 0.60 then
		-- Common (60%): Lucky Zeni Surge (1.5x - 2.5x base Zeni)
		local bonusZeni = math.random(500, 1500)
		return {
			tier = "Common",
			name = "Zeni Surge!",
			zeni = bonusZeni,
			multiplier = 1.5 + (math.random(0, 10) * 0.1),
		}
	elseif roll < 0.85 then
		-- Uncommon (25%): Whis's Insight (Bonus XP Burst)
		local bonusXp = math.random(600, 1800)
		return {
			tier = "Uncommon",
			name = "Whis's Insight",
			xp = bonusXp,
		}
	elseif roll < 0.97 then
		-- Rare (12%): Mystery Capsule / Title Drop
		local titles = { "Arena Veteran", "Ki Prodigy", "Void Breaker" }
		local title = titles[math.random(1, #titles)]
		return {
			tier = "Rare",
			name = "Capsule Corp Mystery Drop",
			zeni = 2000,
			title = title,
		}
	else
		-- Jackpot (3%): Zeno's Divine Smile
		return {
			tier = "Jackpot",
			name = "ZENO'S DIVINE BLESSING!",
			zeni = 5000,
			xp = 3500,
			title = "Omni-Blessed",
			aura = "Aura_ZenoSparkle",
		}
	end
end

-- Near-Miss Analyzer: Computes if player is within 1 battle of next milestone
function VariableRatio.checkNearMiss(currentXp: number, xpToNext: number, currentLevel: number): (boolean, string?, number)
	if xpToNext <= 0 then
		return false, nil, 0
	end
	local percentRemaining = (xpToNext - currentXp) / xpToNext
	if percentRemaining <= VariableRatio.NEAR_MISS_THRESHOLD and percentRemaining > 0 then
		-- Look for nearest form unlock
		local targetForm: string? = nil
		for _, m in UNLOCK_MILESTONES do
			if m.level > currentLevel then
				if m.level == currentLevel + 1 then
					targetForm = m.form
				end
				break
			end
		end
		return true, targetForm, percentRemaining
	end
	return false, nil, percentRemaining
end

-- Strict Non-P2W validator (ensures rewards never give stat bonuses or infinite multipliers)
local FORBIDDEN_KEYS = {
	"damage", "defense", "hp", "statBoost", "powerLevel", "ki",
	"statMultiplier", "plMultiplier", "attackBoost", "defenseBoost",
}

function VariableRatio.validateReward(reward: any): (boolean, string?)
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

return VariableRatio
