--!strict
-- ModuleScript: ReplicatedStorage.Shared.Races  (pure data + lookups; no Roblox APIs -> unit-testable with the luau CLI)
-- Race = passive traits + base stat multipliers + ki model. All numbers flow through StatResolver
-- (never applied directly), so the 1.35x paid cap, tier compression and Ranked normalization always hold.
-- Spec: TASK_RACES.md, GDD_FULL.md §3. Character select reads Races.describe(charId) for the race badge + traits.
local Races = {}

export type Race = {
	id: string,
	name: string,
	stats: { damage: number, defense: number, speed: number, kiRegen: number },
	ki: "normal" | "infinite", -- Android: infinite ki, never charges
	canTransform: boolean,
	canCharge: boolean,
	traits: { string }, -- trait ids handled by RaceRuntime (server)
	powerUps: { { id: string, level: number } },
	desc: string,
	playable: boolean,
	-- trait tuning
	regenPerSec: number?,
	regenDelay: number?,
	kiCostMult: number?,
	cooldownMult: number?,
	comboPerLink: number?,
	kiBlastTaken: number?,
	knockbackTaken: number?,
	autoDodge: number?,
}

local function R(t: any): Race
	return t :: Race
end

Races.LIST = {
	Saiyan = R({
		id = "Saiyan",
		name = "Saiyan",
		stats = { damage = 1.05, defense = 1, speed = 1, kiRegen = 1 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "Zenkai" },
		playable = true,
		powerUps = { { id = "SpiritBomb", level = 40 } },
		desc = "Zenkai: +2% stats per near-death survival (max +10% per match).",
	}),
	HalfSaiyan = R({
		id = "HalfSaiyan",
		name = "Half-Saiyan",
		stats = { damage = 1, defense = 1, speed = 1, kiRegen = 1.05 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "Zenkai", "HiddenPotential", "BeastRage" },
		playable = true,
		powerUps = { { id = "SpiritBomb", level = 40 } },
		desc = "Hidden potential: rage burst at <25% HP (once per match). Beast meter fills when you or allies are hit.",
	}),
	FriezaRace = R({
		id = "FriezaRace",
		name = "Frieza Race",
		stats = { damage = 1, defense = 1, speed = 1.05, kiRegen = 1.2 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "SpaceBorn" },
		playable = true,
		powerUps = {},
		desc = "Space-born: high ki regen, +0.5 s ring-out low-altitude grace.",
	}),
	Namekian = R({
		id = "Namekian",
		name = "Namekian",
		stats = { damage = 1, defense = 1.05, speed = 1, kiRegen = 1 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "Regeneration", "StretchLimb" },
		playable = true,
		regenPerSec = 0.015,
		regenDelay = 4,
		powerUps = { { id = "GiantForm", level = 40 } },
		desc = "Regeneration: 1.5% max HP/s after 4 s out of combat. Stretch limbs: +2 melee range.",
	}),
	Majin = R({
		id = "Majin",
		name = "Majin",
		stats = { damage = 1, defense = 1.1, speed = 0.95, kiRegen = 1 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "RubberBody", "AbsorbHeal", "Regeneration" },
		playable = true,
		regenPerSec = 0.01,
		regenDelay = 5,
		knockbackTaken = 0.8,
		powerUps = {},
		desc = "Rubber body: -20% knockback taken. Heals 15% HP on a melee KO.",
	}),
	Android = R({
		id = "Android",
		name = "Android",
		stats = { damage = 1.05, defense = 1.05, speed = 1, kiRegen = 1 },
		ki = "infinite",
		canTransform = false,
		canCharge = false,
		traits = { "InfiniteKi" },
		playable = true,
		powerUps = { { id = "Barrier", level = 5 } },
		desc = "Infinite ki (no ki bar) but cannot transform or charge; flat stat upgrades instead.",
	}),
	PrideTrooper = R({
		id = "PrideTrooper",
		name = "Pride Trooper",
		stats = { damage = 1, defense = 1.03, speed = 1, kiRegen = 1 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "Justice" },
		playable = true,
		comboPerLink = 0.11,
		powerUps = { { id = "JusticePose", level = 15 } },
		desc = "Discipline: team combo +11% per link (instead of 10%).",
	}),
	JirenType = R({
		id = "JirenType",
		name = "Jiren-type",
		stats = { damage = 1.1, defense = 1.1, speed = 1, kiRegen = 0.8 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "PowerImpactArmor" },
		playable = true,
		powerUps = {},
		desc = "Raw power: high stats, slow ki regen, armored Power Impact.",
	}),
	Earthling = R({
		id = "Earthling",
		name = "Earthling",
		stats = { damage = 1, defense = 1, speed = 1, kiRegen = 1 },
		ki = "normal",
		canTransform = true,
		canCharge = true,
		traits = { "Technique" },
		playable = true,
		kiCostMult = 0.85,
		cooldownMult = 0.85,
		powerUps = { { id = "KaioKen", level = 5 }, { id = "SolarFlare", level = 8 } },
		desc = "Technique: -15% ki costs and cooldowns; Kaioken access.",
	}),
	Kaioshin = R({
		id = "Kaioshin",
		name = "Kaioshin",
		stats = { damage = 1, defense = 1, speed = 1, kiRegen = 1.1 },
		ki = "normal",
		canTransform = false,
		canCharge = true,
		traits = { "DivineSense" },
		playable = true,
		powerUps = { { id = "KaiKai", level = 60 } },
		desc = "Support: sense power through walls (60 studs), Potara fusion partner.",
	}),
	Angel = R({
		id = "Angel",
		name = "Angel",
		stats = { damage = 0.6, defense = 1, speed = 1.1, kiRegen = 1 },
		ki = "normal",
		canTransform = false,
		canCharge = true,
		traits = { "AutoDodge" },
		playable = true,
		autoDodge = 0.35,
		powerUps = {}, -- Playable angels (Whis, Vados, Marcarita)
		desc = "Autonomous dodge: 35% chance to auto-vanish a non-ultimate hit (8 ki, 1.5 s internal cooldown).",
	}),
	Destroyer = R({
		id = "Destroyer",
		name = "God of Destruction",
		stats = { damage = 1, defense = 1, speed = 1, kiRegen = 1 },
		ki = "normal",
		canTransform = false,
		canCharge = true,
		traits = { "DestroyerAura" },
		playable = true,
		kiBlastTaken = 0.8,
		powerUps = {},
		desc = "Destroyer aura: -20% ki-blast damage taken. Hakai + Sphere of Destruction.",
	}),
}

-- Explicit champion -> race map; unlisted ids fall back by prefix / universe.
Races.CHAMPION = {
	u7_goku = "Saiyan",
	u7_vegeta = "Saiyan",
	u6_cabba = "Saiyan",
	u6_caulifla = "Saiyan",
	u6_kale = "Saiyan",
	u6_kefla = "Saiyan",
	fus_gogeta = "Saiyan",
	fus_vegito = "Saiyan",
	u7_gohan = "HalfSaiyan",
	u7_frieza = "FriezaRace",
	u6_frost = "FriezaRace",
	u7_piccolo = "Namekian",
	u7_android_17 = "Android",
	u7_android_18 = "Android",
	u7_moro = "Majin",
	u7_broly = "Saiyan",
	u7_trunks = "HalfSaiyan",
	u10_goku_black = "Saiyan", -- absorb/regenerating villain: closest kit fit (lore: Galactic Prisoner)
	u11_jiren = "JirenType",
	u7_krillin = "Earthling",
	u7_tien = "Earthling",
	u7_master_roshi = "Earthling",
	div_zeno = "Kaioshin",
	div_grand_priest = "Angel",
	u7_shin = "Kaioshin",
	u10_zamasu = "Kaioshin",
} :: { [string]: string }

function Races.raceOf(charId: string?): string
	if not charId then
		return "Earthling"
	end
	local r = Races.CHAMPION[charId]
	if r then
		return r
	end
	if string.sub(charId, 1, 14) == "div_destroyer_" then
		return "Destroyer"
	end
	if string.sub(charId, 1, 10) == "div_angel_" then
		return "Angel"
	end
	if string.sub(charId, 1, 4) == "u11_" then
		return "PrideTrooper"
	end
	return "Earthling"
end

function Races.get(charId: string?): Race
	return Races.LIST[Races.raceOf(charId)]
end

-- Angels are NPC-only unless features.PLAYABLE_ANGELS (lead decision). Grand Priest shares the Angel race.
function Races.isPlayable(charId: string?, features: { PLAYABLE_ANGELS: boolean? }?): boolean
	if charId and string.sub(charId, 1, 10) == "div_angel_" then
		return features ~= nil and features.PLAYABLE_ANGELS == true
	end
	return true
end

-- Majin heal on KO: fraction of max HP healed by the killer (melee KOs only). Ranked keeps utility at reduced strength.
function Races.koHeal(raceId: string, moveKind: string?, ranked: boolean?, base: number?, rankedMult: number?): number
	if raceId ~= "Majin" or moveKind ~= "melee" then
		return 0
	end
	local h = base or 0.15
	return if ranked then h * (rankedMult or 0.5) else h
end

function Races.hasTrait(charId: string?, trait: string): boolean
	return table.find(Races.get(charId).traits, trait) ~= nil
end

-- For CharacterSelect (owned by another worker): { race, name, desc, traits }
function Races.describe(charId: string?): { race: string, name: string, desc: string, traits: { string } }
	local r = Races.get(charId)
	return { race = r.id, name = r.name, desc = r.desc, traits = r.traits }
end

return Races
