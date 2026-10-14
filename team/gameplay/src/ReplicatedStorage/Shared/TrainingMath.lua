--!strict
-- ModuleScript: ReplicatedStorage.Shared.TrainingMath  (PURE; tests in gameplay/tests)
-- Gravity Room math shared by TrainingRooms + TrainingBots. cfg = Config.SPAR_BOTS / Config.TRAINING_RUNTIME / steps tables.
local TrainingMath = {}

-- index of the highest step <= g (steps ascending)
function TrainingMath.stepIndex(steps: { number }, g: number): number
	local idx = 1
	for i, v in steps do if g >= v then idx = i end end
	return idx
end

-- extra downward acceleration in g for a gravity multiplier (playable compression)
function TrainingMath.extraG(g: number, perG: number, maxExtra: number): number
	return math.clamp((g - 1) * perG, 0, maxExtra)
end

-- Sparring bot stats at gravity g: hp/damage grow with log10(g); xp per KO scales with the room's XP step multiplier.
function TrainingMath.botStats(cfg: any, g: number, xpMult: number): { hp: number, damage: number, xp: number, zeni: number }
	local l = math.log10(math.max(1, g))
	return {
		hp = math.floor(cfg.baseHp * (1 + cfg.hpPerLog * l)),
		damage = cfg.baseDamage * (1 + cfg.dmgPerLog * l),
		xp = math.floor(cfg.xpPerKO * xpMult),
		zeni = cfg.zeniPerKO,
	}
end

return TrainingMath
