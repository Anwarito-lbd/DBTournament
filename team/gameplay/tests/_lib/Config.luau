--!strict
-- Shared tunables for Dragon Block Z (mode: Tournament of Power) (ModuleScript: ReplicatedStorage.Shared.Config)
local Config = {}

Config.GAME_NAME = "Dragon Block Z"
Config.MODE_NAME = "Tournament of Power"

Config.MIN_PLAYERS = 2
Config.MAX_PLAYERS = 40 -- must ALSO be set in Studio: Game Settings > Places > Max Players (not scriptable)
Config.MAX_TEAM_SIZE = 5 -- 8 teams x 5 = 40
-- v1 dev mode (Studio only): solo play test with training bots, all unlocks, shorter timers.
Config.DEV_MODE = true
Config.DEV_BOTS = 2 -- 1..3 bots on an enemy universe when only one player is present
Config.DEV_BOT_HP = 100
Config.INTRO_MAX = 110 -- seconds; server waits for all players to skip or this cap
-- PACING FIX (2026-10-14): the full intro replayed EVERY round at 110 s. Repeat rounds now use this instead,
-- so only a player who has not yet seen the story beat has to sit through the long version.
Config.INTRO_MAX_REPEAT = 12
Config.ENDING_MAX = 70 -- seconds for ending cutscene + wish choice
-- Super Dragon Ball wishes (StoryDialogue.Wishes). Rewards are server-applied; values are v1 placeholders.
Config.WISHES = {
	Power = { title = "Multiverse Champion", aura = "ChampionGold", zeni = 1000 }, -- v8: Super Shenron = cosmetic/Zeni only (stat boost removed)
	Restoration = { title = "Savior of the Multiverse", serverZeni = 500, cosmetic = "Halo" },
}
Config.MIN_TEAMS, Config.MAX_TEAMS = 2, 8
Config.TARGET_TEAM_SIZE = 3 -- teams = min(n, clamp(floor(n/3), 2, 8)); teams are named Universe 1..N
Config.MAX_PARTY = 6

Config.INTERMISSION = 20
Config.CHARACTER_SELECT = 12
Config.COUNTDOWN = 5
Config.ROUND_MAX = 300
Config.RESULTS = 8
Config.RING_OUT_Y = -50

Config.XP_PER_MINUTE = 10
Config.XP_WIN = 100
Config.XP_KO = 15
Config.XP_SURVIVAL_PER_RANK = 5
Config.MAX_LEVEL = 500 -- v5 (Dragon Block Z): levels 1-500; forms still unlock <= 100

-- v5 curve: fast early (SSJ @ Lv15 ~ 3.1k XP total), Lv100 ~ 217k, then linear-ish to Lv500 ~ 2.9M.
function Config.xpToNext(level: number): number
	if level <= 100 then
		return math.floor(60 + 10 * level ^ 1.35)
	end
	return math.floor(60 + 10 * 100 ^ 1.35) + 8 * (level - 100)
end
Config.XP_PARTICIPATION = 50 -- every finished match, win or lose (no XP loss on death)

-- Power Level = floor((base + level * POWER_PER_LEVEL) * formMult * (1 + charge))
Config.POWER_PER_LEVEL = 50
Config.KI_CHARGE_RATE = 0.10 -- charge gained per second while charging
Config.KI_CHARGE_CAP = 0.50 -- max +50%
Config.KI_DECAY_RATE = 0.05 -- per second when not charging
Config.KI_MAX_CHARGE_SPEED = 2 -- studs/s; moving faster cancels charging
Config.TRANSFORM_COOLDOWN = 3

-- Transformations: mult = Power Level multiplier, level = unlock level
Config.FORMS = {
	Base = { mult = 1, level = 1 },
	KaioKen = { mult = 1.5, level = 5 },
	FullPower = { mult = 1.75, level = 10 },
	SuperSaiyan = { mult = 2, level = 15 },
	SuperSaiyan2 = { mult = 2.5, level = 30 },
	SuperSaiyan3 = { mult = 3, level = 40 },
	Ultimate = { mult = 3.5, level = 45 },
	Golden = { mult = 4, level = 55 },
	SuperSaiyanGod = { mult = 3.5, level = 60 },
	SuperSaiyanBlue = { mult = 4.5, level = 75 },
	Legendary = { mult = 4.5, level = 75 },
	UltraInstinctSign = { mult = 5, level = 85 }, -- distinct from MUI (VFX preset UISign)
	SuperSaiyan4 = { mult = 5, level = 80, story = 32 }, -- Daima/GT red-fur SSJ4: Lv80 + story mission 32 "Mini Mayhem" (D24 gate; below MUI/UE)
	SSBEvolved = { mult = 5.5, level = 90 }, -- Vegeta Super Saiyan Blue Evolved
	MoroAwakened = { mult = 5.5, level = 95 },
	BeastGohan = { mult = 6, level = 95 },
	FriezaBlack = { mult = 6, level = 95 },
	MUI = { mult = 6, level = 100 }, -- Mastered Ultra Instinct (was UltraInstinct; same canonical numbers)
	UltraEgo = { mult = 5.5, level = 100 },
	KeflaPotara = { mult = 2.5, level = 35 }, -- Kefla's fused power-up (db-animation preset KeflaPotara)
}

-- Form id -> db-animation TransformationVFX preset name (animation/TransformationVFX.lua Presets).
-- nil = no preset yet (client falls back to generic aura). Per-character overrides below.
Config.FORM_VFX = {
	SuperSaiyan = "SSJ",
	SuperSaiyan2 = "SSJ2",
	SuperSaiyan3 = "SSJ3",
	SuperSaiyanGod = "SSG",
	SuperSaiyanBlue = "SSB",
	SuperSaiyan4 = "SSJ4",
	UltraInstinctSign = "UISign",
	MUI = "MUI",
	UltraEgo = "UltraEgo",
	KeflaPotara = "KeflaPotara",
	BeastGohan = "BeastGohan",
	SSBEvolved = "SSBEvolved",
	FriezaBlack = "FriezaBlack",
	MoroAwakened = "MoroAwakened", -- preset = form id (animation/movesets_v4.md)
	Ultimate = "GohanUltimate",
	Golden = "GoldenFrieza",
}
Config.FORM_VFX_OVERRIDES = {
	u11_jiren = { FullPower = "JirenFullPower" },
	u11_toppo = { FullPower = "ToppoGoD" },
	u7_frieza = { FullPower = "FriezaFullPower" },
	u6_caulifla = { SuperSaiyan = "CauliflaSSJ" },
	u6_kale = { Legendary = "KaleBerserk" },
	u6_kefla = { SuperSaiyan2 = "KeflaSSJ2", Fuse = "KeflaPotara" },
}
function Config.vfxFor(charId: string?, formId: string): string?
	local o = charId and Config.FORM_VFX_OVERRIDES[charId]
	return (o and o[formId]) or Config.FORM_VFX[formId]
end

Config.POWERUPS = {
	{ level = 3, id = "KiBlast" },
	{ level = 10, id = "SignatureBeam" },
	{ level = 25, id = "InstantTransmission" },
	{ level = 35, id = "Potara" }, -- earrings: required for Potara fusion
	{ level = 40, id = "SpiritBomb" }, -- team-charged Spirit Bomb (Saiyan / Half-Saiyan race power-up; Goku always)
	{ level = 40, id = "GiantForm" }, -- Namekian race power-up
	{ level = 5, id = "Barrier" }, -- Android race power-up
	{ level = 8, id = "SolarFlare" }, -- Earthling race power-up
	{ level = 15, id = "JusticePose" }, -- Pride Trooper race power-up
	{ level = 60, id = "KaiKai" }, -- Kaioshin race power-up
}

-- Show-accurate DBS Tournament of Power rosters. Stable IDs "u<universe>_<name>".
-- NOTE: names/IDs must be coordinated with db-animation (rigs/anim sets keyed by id).
type Char = { id: string, name: string, base: number, level: number, forms: { string } }
local function c(id: string, name: string, base: number, level: number, forms: { string }?): Char
	return { id = id, name = name, base = base, level = level, forms = forms or { "FullPower" } }
end
local SAIYAN = {
	"KaioKen",
	"SuperSaiyan",
	"SuperSaiyan2",
	"SuperSaiyan3",
	"SuperSaiyanGod",
	"SuperSaiyanBlue",
	"SuperSaiyan4",
	"UltraInstinctSign",
	"MUI",
}

-- Lore only: champion.universe is flavour. Teams are numbered Universe 1..N (see TeamAssignment).
Config.ROSTER = {
	[7] = {
		c("u7_goku", "Goku", 1000, 1, SAIYAN),
		c("u7_vegeta", "Vegeta", 1000, 1, {
			"SuperSaiyan",
			"SuperSaiyan2",
			"SuperSaiyanGod",
			"SuperSaiyanBlue",
			"SuperSaiyan4",
			"SSBEvolved",
			"UltraEgo",
		}),
		c("u7_gohan", "Gohan", 950, 1, { "SuperSaiyan", "SuperSaiyan2", "Ultimate", "BeastGohan" }),
		c("u7_piccolo", "Piccolo", 850, 1),
		c("u7_android_17", "Android 17", 900, 5),
		c("u7_android_18", "Android 18", 850, 5),
		c("u7_krillin", "Krillin", 700, 8),
		c("u7_tien", "Tien", 700, 8),
		c("u7_master_roshi", "Master Roshi", 650, 12),
		c("u7_shin", "Shin", 760, 20), -- v8: Supreme Kai (Kaioshin race; Kai Kai in kit). db-animation rig pending
		c("u7_frieza", "Frieza", 1000, 20, { "FullPower", "Golden", "FriezaBlack" }),
		-- Bonus champion (Moro arc, guest). Primary ID u7_moro (db-animation movesets_v4); alias bonus_moro.
		c("u7_moro", "Moro", 1100, 90, { "MoroAwakened" }),
		c("u7_broly", "Broly", 1150, 40, { "FullPower" }),
		c("u7_trunks", "Future Trunks", 950, 15, { "SuperSaiyan", "SuperSaiyan2" }),
	},
	[11] = {
		c("u11_jiren", "Jiren", 1200, 50, { "FullPower" }),
		c("u11_toppo", "Toppo", 1000, 20, { "FullPower" }),
		c("u11_dyspo", "Dyspo", 950, 10),
		c("u11_kahseral", "Kahseral", 800, 1),
		c("u11_cocotte", "Cocotte", 800, 1),
		c("u11_kunshi", "Kunshi", 750, 1),
		c("u11_vuon", "Vuon", 700, 5),
		c("u11_zoiray", "Zoiray", 700, 5),
		c("u11_tupper", "Tupper", 700, 5),
	},
	[6] = {
		c("u6_hit", "Hit", 1050, 15),
		c("u6_cabba", "Cabba", 850, 1, { "SuperSaiyan", "SuperSaiyan2" }),
		c("u6_caulifla", "Caulifla", 900, 1, { "SuperSaiyan", "SuperSaiyan2" }),
		c("u6_kale", "Kale", 900, 1, { "SuperSaiyan", "Legendary" }),
		c("u6_frost", "Frost", 850, 8, { "FullPower" }),
		c("u6_botamo", "Botamo", 650, 5),
		c("u6_magetta", "Magetta", 700, 5),
		c("u6_saonel", "Saonel", 750, 10),
		c("u6_pirina", "Pirina", 750, 10),
		c("u6_kefla", "Kefla", 1900, 35, { "KeflaPotara", "SuperSaiyan", "SuperSaiyan2" }), -- also via Potara (Caulifla+Kale)
	},
	[2] = {
		c("u2_ribrianne", "Ribrianne", 900, 1),
		c("u2_rozie", "Rozie", 800, 1),
		c("u2_kakunsa", "Kakunsa", 750, 1),
		c("u2_vikal", "Vikal", 700, 5),
		c("u2_hermila", "Hermila", 700, 5),
		c("u2_jimeze", "Jimeze", 750, 8),
		c("u2_zircor", "Zircor", 750, 8),
		c("u2_prum", "Prum", 650, 5),
	},
	[3] = {
		c("u3_anilaza", "Anilaza", 1050, 25),
		c("u3_paparoni", "Paparoni", 800, 1),
		c("u3_koitsukai", "Koitsukai", 750, 1),
		c("u3_panchia", "Panchia", 750, 1),
		c("u3_bollarator", "Bollarator", 750, 5),
		c("u3_katopesla", "Katopesla", 800, 5),
		c("u3_maji_kayo", "Maji Kayo", 700, 8),
		c("u3_viara", "Viara", 750, 8),
		c("u3_nigrisshi", "Nigrisshi", 700, 8),
		c("u3_narirama", "Narirama", 700, 10),
	},
	[4] = {
		c("u4_ganos", "Ganos", 850, 1),
		c("u4_shantza", "Shantza", 750, 1),
		c("u4_caway", "Caway", 750, 1),
		c("u4_majora", "Majora", 750, 5),
		c("u4_damom", "Damom", 750, 5),
		c("u4_gamisaras", "Gamisaras", 700, 5),
		c("u4_monna", "Monna", 700, 8),
		c("u4_nink", "Nink", 700, 8),
	},
	[9] = {
		c("u9_bergamo", "Bergamo", 850, 1),
		c("u9_lavenda", "Lavenda", 800, 1),
		c("u9_basil", "Basil", 800, 1),
		c("u9_hop", "Hop", 700, 5),
		c("u9_sorrel", "Sorrel", 700, 5),
		c("u9_oregano", "Oregano", 700, 5),
		c("u9_roselle", "Roselle", 700, 8),
		c("u9_comfrey", "Comfrey", 700, 8),
	},
	[10] = {
		c("u10_obuni", "Obuni", 900, 5),
		c("u10_rubalt", "Rubalt", 800, 1),
		c("u10_jilcol", "Jilcol", 750, 1),
		c("u10_murisam", "Murisam", 750, 1),
		c("u10_napapa", "Napapa", 750, 5),
		c("u10_jium", "Jium", 700, 5),
		c("u10_lilibeu", "Lilibeu", 700, 8),
		c("u10_zamasu", "Zamasu", 880, 60), -- v8: Kaioshin apprentice (Kai Kai in kit). db-animation rig pending
		c("u10_goku_black", "Goku Black", 1050, 35, { "FullPower" }),
	},
}

-- ===== Divine tiers (v3) =====
-- Unlocked by prestige (or max level for GoDs). Guest picks: allowed for any universe, capped per match.
-- tier order: GoD < Angel < GrandPriest < Zeno. Zeno is event-only.
Config.MAX_PRESTIGE = 10
Config.PRESTIGE_XP_BONUS = 0.05 -- +5% XP per prestige
Config.DIVINE_TIERS = {
	GoD = { req = { level = 250, prestige = 1 }, base = 2000, perMatch = 2, eventOnly = false },
	Angel = { req = { level = 350, prestige = 3 }, base = 2400, perMatch = 1, eventOnly = false },
	GrandPriest = { req = { level = 450, prestige = 5 }, base = 2800, perMatch = 1, eventOnly = true },
	Zeno = { req = { level = 500, prestige = 10 }, base = 3200, perMatch = 1, eventOnly = true },
}
Config.DIVINE_TOTAL_PER_MATCH = 3 -- across all tiers in non-event matches
Config.DIVINE_PER_TEAM = 1
local function d(id: string, name: string, tier: string, home: number)
	return { id = id, name = name, tier = tier, home = home }
end
Config.DIVINE = {
	d("div_destroyer_beerus", "Beerus", "GoD", 7),
	d("div_destroyer_belmod", "Belmod", "GoD", 11),
	d("div_destroyer_champa", "Champa", "GoD", 6),
	d("div_destroyer_quitela", "Quitela", "GoD", 4),
	d("div_destroyer_sidra", "Sidra", "GoD", 9),
	d("div_destroyer_rumsshi", "Rumsshi", "GoD", 10),
	d("div_destroyer_iwne", "Iwne", "GoD", 8),
	d("div_destroyer_heles", "Heles", "GoD", 2),
	d("div_destroyer_mosco", "Mosco", "GoD", 3),
	d("div_destroyer_liquiir", "Liquiir", "GoD", 8),
	d("div_destroyer_arak", "Arak", "GoD", 12),
	d("div_destroyer_giin", "Giin", "GoD", 1),
	d("div_angel_whis", "Whis", "Angel", 7),
	d("div_angel_vados", "Vados", "Angel", 6),
	d("div_angel_marcarita", "Marcarita", "Angel", 11),
	d("div_angel_cognac", "Cognac", "Angel", 4),
	d("div_angel_cukatail", "Cukatail", "Angel", 9),
	d("div_angel_kusu", "Kusu", "Angel", 10),
	d("div_angel_sour", "Sour", "Angel", 2),
	d("div_angel_campari", "Campari", "Angel", 3),
	d("div_angel_martinu", "Martinu", "Angel", 1),
	d("div_angel_mojito", "Mojito", "Angel", 12),
	d("div_angel_korn", "Korn", "Angel", 8),
	d("div_grand_priest", "Grand Priest", "GrandPriest", 0),
	d("div_zeno", "Zeno", "Zeno", 0),
}

-- ===== Fusion (v3) =====
Config.FUSION = {
	DanceChannel = 3,
	DanceRange = 12,
	DanceDuration = 60,
	PotaraChannel = 1.5,
	PotaraRange = 10,
	PotaraDuration = 90, -- matches db-animation Kefla spec
	RequestTTL = 5,
	FailCooldown = 10,
	HealthBonus = 0.3, -- fused HP = avg(HP) * 1.3
}
Config.FUSIONS = { -- unordered pair -> result per method
	{ a = "u7_goku", b = "u7_vegeta", Dance = "fus_gogeta", Potara = "fus_vegito" },
	{ a = "u6_caulifla", b = "u6_kale", Potara = "u6_kefla" },
}
Config.FUSED = {
	c("fus_gogeta", "Gogeta", 2600, 1, { "SuperSaiyan", "SuperSaiyanBlue" }),
	c("fus_vegito", "Vegito", 2600, 1, { "SuperSaiyan", "SuperSaiyanBlue" }),
}

-- ===== v4 BALANCE MODEL (design change: universes are numbered teams; any player may pick any unlocked champion) =====
-- Champion tier from base power (divine tiers keep their own). Tier drives counterplay and team budget,
-- while ALL stat differences in combat are compressed to at most STAT_CAP (1.35x) either way.
Config.STAT_CAP = 1.35
Config.STAT_EXPONENT = 0.25 -- damage ratio = clamp((PL_att / PL_vic)^0.25, 1/1.35, 1.35)
function Config.tierOf(ch: any): string
	if ch.tier then
		return ch.tier
	end -- GoD / Angel / GrandPriest / Zeno
	if ch.base >= 1000 then
		return "S"
	elseif ch.base >= 850 then
		return "A"
	elseif ch.base >= 750 then
		return "B"
	end
	return "C"
end
-- Counterplay: stronger = bigger hurtbox, slower ki regen, longer recovery. cost = team budget points.
Config.TIER_RULES = {
	C = { hurtbox = 1.00, kiRegen = 1.00, recovery = 1.00, cost = 1 },
	B = { hurtbox = 1.05, kiRegen = 0.95, recovery = 1.05, cost = 2 },
	A = { hurtbox = 1.10, kiRegen = 0.90, recovery = 1.10, cost = 3 },
	S = { hurtbox = 1.20, kiRegen = 0.85, recovery = 1.15, cost = 4 },
	GoD = { hurtbox = 1.30, kiRegen = 0.75, recovery = 1.25, cost = 6 },
	Angel = { hurtbox = 1.30, kiRegen = 0.75, recovery = 1.25, cost = 7 },
	GrandPriest = { hurtbox = 1.35, kiRegen = 0.70, recovery = 1.30, cost = 9 },
	Zeno = { hurtbox = 1.40, kiRegen = 0.70, recovery = 1.30, cost = 10 },
}
-- Team power budget: sum(cost of picks) <= 3 * teamSize + 1 (average A-tier). Divine picks outside event mode
-- must fit the budget AND the divine caps.
Config.BUDGET_PER_PLAYER = 3
Config.BUDGET_BONUS = 1
Config.ONE_PER_TEAM = true -- duplicates allowed across teams, never within a team
Config.DEFAULT_PICKS = {
	"u7_goku",
	"u7_vegeta",
	"u7_piccolo",
	"u7_gohan",
	"u6_cabba",
	"u6_caulifla",
	"u6_kale",
	"u11_kahseral",
	"u11_cocotte",
	"u2_ribrianne",
	"u4_ganos",
	"u9_bergamo",
	"u10_rubalt",
	"u3_paparoni",
}

-- Ki pool (spent by skill actions/moves). Separate from ki CHARGE (Power Level boost).
Config.KI = { max = 100, regen = 8, chargingRegenMult = 3, parryGain = 10 }

-- Skill expression (all server-validated in Modules/Combat)
Config.SKILL = {
	HurtRadius = 2, -- base hurt radius (studs), x tier hurtbox
	ParryWindow = 0.20, -- block pressed <= 0.20 s before hit = perfect block (incl. ~80 ms latency allowance)
	ParryStun = 0.8, -- attacker stunned
	BlockChip = 0.15, -- normal block takes 15% damage, no knockback
	BlockFacingDot = 0.2,
	GuardMax = 100,
	GuardRegen = 20,
	GuardBreakStun = 1.2,
	GuardBreakDamageMult = 0.5,
	Hitstun = 0.35,
	DashCooldown = 0.8,
	DashSpeed = 70,
	DashCancelKi = 15,
	VanishKi = 25,
	VanishCooldown = 3,
	VanishIFrames = 0.35,
	VanishDistance = 12,
	BreakerKi = 50,
	BreakerCooldown = 8,
	BreakerIFrames = 0.4,
	BreakerPush = 50,
	BreakerRadius = 10,
	KnockbackGrowth = 1.5, -- kb = move.kb * (1 + 1.5 * missingHP%) * sqrt(ratio)
	-- fight-research design gaps (FIGHT_RESEARCH.md section 4; rules in Shared/FightRules)
	M1ChainWindow = 1.25, -- seconds between M1 presses for the server to keep counting the 4-hit chain
	Finisher = { -- the 4th M1 of a chain: neutral blow-away, launch (jump held, grounded) or spike (airborne)
		blow = { damageMult = 1.2, kb = 55, knockdown = 2.0, recovery = 0.3 },
		launch = { damageMult = 1.1, kb = 10, up = 75, hitstun = 0.9, recovery = 0.2 },
		spike = { damageMult = 1.25, kb = 6, down = 60, knockdown = 1.6, crackRadius = 9, crackPower = 60, recovery = 0.3 },
	},
	GetUpImmunity = 0.5, -- after a knockdown: no knockback / stun extension for this long (no loops)
	KiBurstWindow = 4, -- a parry primes a Ki Burst: the next landed hit within this time is critical
	KiBurstMult = 2,
	VanishCounterIFrames = 0.4, -- parrying again while primed: vanish behind the attacker
	TeamBurst = { window = 3, attackers = 2, radius = 18, push = 70, iframes = 0.6, cooldown = 30 },
	Struggle = {
		window = 0.2,
		maxTime = 4,
		winScore = 30,
		pulse = 0.5,
		timingTol = 0.12,
		timingWeight = 3,
		winBonus = 1.25,
		tieScore = 3,
		tieDamage = 15,
		maxInputsPerSec = 15,
	},
}

-- Moves. kind: melee | ray. arenaRadius/arenaPower per db-map (KiBlast r6/p25, Kamehameha r18/p120).
Config.MOVES = {
	M1 = {
		kind = "melee",
		cooldown = 0.3,
		range = 7,
		damage = 5,
		ki = 0,
		recovery = 0.10,
		kb = 8,
		guardDamage = 8,
		hitstun = 0.35,
		parryable = true,
	},
	Heavy = {
		kind = "melee",
		cooldown = 4,
		range = 7,
		damage = 10,
		ki = 10,
		recovery = 0.45,
		kb = 40,
		guardDamage = 100,
		guardBreak = true,
		hitstun = 0.6,
		parryable = true,
	},
	KiBlast = {
		kind = "ray",
		unlock = "KiBlast",
		cooldown = 1.5,
		range = 150,
		width = 3.5,
		damage = 4,
		ki = 5,
		recovery = 0.15,
		kb = 12,
		guardDamage = 10,
		hitstun = 0.2,
		parryable = true,
		arenaRadius = 6,
		arenaPower = 25,
	},
	Kamehameha = {
		kind = "ray",
		unlock = "SignatureBeam",
		cooldown = 10,
		range = 250,
		width = 8.0,
		damage = 28,
		ki = 30,
		recovery = 0.6,
		kb = 70,
		guardDamage = 50,
		hitstun = 0.5,
		parryable = false,
		beam = true,
		arenaRadius = 18,
		arenaPower = 120,
	},
	-- Moro kit (champion u7_moro only)
	Absorb = {
		kind = "melee",
		champion = "u7_moro",
		cooldown = 6,
		range = 9,
		damage = 6,
		ki = 0,
		recovery = 0.4,
		kb = 5,
		guardDamage = 20,
		hitstun = 0.5,
		parryable = true,
		absorb = true,
	},
	-- Vegeta ultimate: only at <= 25% HP, once per round; 2 s armored charge (server timer), then AoE + self-KO.
	FinalExplosion = {
		kind = "selfblast",
		champion = "u7_vegeta",
		cooldown = 0,
		range = 0,
		ki = 50,
		recovery = 0,
		charge = 2,
		hpThreshold = 0.25,
		radius = 35,
		damage = 80,
		kb = 90,
		guardDamage = 100,
		guardBreak = true,
		hitstun = 0.6,
		parryable = false,
		arenaRadius = 35,
		arenaPower = 220,
	},
	-- Zeno: Erase. EventMode only, ONCE PER MATCH (server-enforced), 8 s warning, erases one random enemy.
	Erase = { kind = "erase", champion = "div_zeno", cooldown = 0, range = 0, ki = 0, recovery = 0, warning = 8 },
	Copy = { kind = "copy", champion = "u7_moro", cooldown = 12, range = 60, ki = 20, recovery = 0.3 },
	-- v6 Destroyer path (BeerusCamp unlocks; div_destroyer_* champions have them natively via freeForPrefix)
	DestructionSphere = {
		kind = "ray",
		unlock = "DestructionSphere",
		freeForPrefix = "div_destroyer_",
		cooldown = 10,
		range = 120,
		width = 4,
		damage = 40,
		ki = 35,
		recovery = 0.5,
		kb = 50,
		guardDamage = 60,
		hitstun = 0.5,
		parryable = false,
		arenaRadius = 14,
		arenaPower = 100,
	},
	-- Angel signatures (Whis, Vados, Marcarita, etc.)
	TemporalRewind = {
		kind = "rewind",
		freeForPrefix = "div_angel_",
		cooldown = 35,
		range = 0,
		ki = 40,
		recovery = 0.2,
		rewindSeconds = 3,
	},
	AngelicBarrier = {
		kind = "barrier",
		freeForPrefix = "div_angel_",
		cooldown = 20,
		range = 0,
		ki = 35,
		duration = 3,
		kbImmune = true,
	},
	StaffWarp = {
		kind = "melee",
		freeForPrefix = "div_angel_",
		cooldown = 8,
		range = 14,
		damage = 12,
		ki = 15,
		recovery = 0.2,
		hitstun = 0.5,
		parryable = true,
	},
	Hakai = {
		kind = "hakai",
		unlock = "Hakai",
		freeForPrefix = "div_destroyer_",
		cooldown = 45,
		range = 40,
		ki = 60,
		recovery = 0.6,
		windup = 1,
		executeBelow = 0.15,
		pvpDamage = 20,
		bossDamage = 70,
		kb = 0,
		guardDamage = 0,
		hitstun = 0.4,
		parryable = false,
	},
	-- v7 race power-ups (RacePowerUps.lua); gated by unlock + race
	Barrier = {
		kind = "barrier",
		unlock = "Barrier",
		races = { "Android" },
		cooldown = 15,
		range = 0,
		ki = 30,
		recovery = 0,
	},
	JusticePose = {
		kind = "justice",
		unlock = "JusticePose",
		races = { "PrideTrooper", "JirenType" },
		cooldown = 30,
		range = 0,
		ki = 25,
		recovery = 0,
	},
	SolarFlare = {
		kind = "solarflare",
		unlock = "SolarFlare",
		races = { "Earthling" },
		cooldown = 20,
		range = 0,
		ki = 20,
		recovery = 0.3,
	},
	KaiKai = {
		kind = "kaikai",
		unlock = "KaiKai",
		races = { "Kaioshin" },
		freeForIds = { "u7_shin", "u10_zamasu" },
		cooldown = 25,
		range = 150,
		ki = 30,
		recovery = 0.2,
	},
	-- Team Spirit Bomb (handled by SpiritBomb.lua): numbers in Config.SPIRIT_BOMB
	SpiritBomb = {
		kind = "spiritbomb",
		unlock = "SpiritBomb",
		freeForPrefix = "u7_goku",
		races = { "Saiyan", "HalfSaiyan" },
		cooldown = 60,
		range = 200,
		ki = 40,
		recovery = 0.8,
	},
}
-- Character kits (Shared/Kits) may add moves of existing kinds; they never replace a core move. Guarded so the
-- plain-Luau tests (no `script`) still load Config.
do
	local ok, Kits = pcall(function()
		local k = script.Parent:FindFirstChild("Kits")
		return k and require(k)
	end)
	if ok and Kits and Kits.moves and Config.MOVES then
		for id, mv in Kits.moves() do
			if Config.MOVES[id] == nil then Config.MOVES[id] = mv end
		end
	end
end

-- Moro absorption: drains up to 20 ki from the target; Moro gains +5% PL per hit, capped +25%, 15 s.
-- Copy: repeats the target's last used move (not Absorb/Copy) at 70% damage/knockback/arena power, ignoring unlocks.
Config.MORO = { drainKi = 20, plPerHit = 0.05, plCap = 0.25, plDuration = 15, copyPower = 0.7, copyMemory = 10 }
Config.MAX_ORIGIN_OFFSET = 8
Config.NON_COMBAT = { div_zeno = true } -- cannot deal/receive damage; only Erase (db-animation: Zeno M1 = wave)
Config.ALIASES = { bonus_moro = "u7_moro", UISign = "UltraInstinctSign", UltraInstinct = "MUI" }
Config.COMBO = { window = 1.5, perLink = 0.10, maxLinks = 5, xpPerLink = 3 }
Config.LAST_GIFT = { window = 2, range = 40, boost = 0.25, chargeShare = 0.5, maxBoost = 0.5, duration = 20 }
Config.RINGOUT = { lowY = 480, lowGrace = 1 } -- overridden by Zone_RingBounds attributes when present

Config.CHAR_BY_ID = {} :: { [string]: Char & { universe: number } }
for u, list in Config.ROSTER do
	for _, ch in list do
		(ch :: any).universe = u
		Config.CHAR_BY_ID[ch.id] = ch :: any
	end
end

for _, dv in Config.DIVINE do
	local t = Config.DIVINE_TIERS[dv.tier]
	local ch = c(dv.id, dv.name, t.base, Config.MAX_LEVEL, {}) :: any
	ch.universe = 0
	ch.tier = dv.tier
	ch.home = dv.home
	Config.CHAR_BY_ID[dv.id] = ch
end
for _, ch in Config.FUSED do
	(ch :: any).universe = -1
	(ch :: any).fused = true
	Config.CHAR_BY_ID[ch.id] = ch :: any
end
function Config.fusionFor(x: string, y: string, method: string): string?
	for _, f in Config.FUSIONS do
		if (f.a == x and f.b == y) or (f.a == y and f.b == x) then
			return (f :: any)[method]
		end
	end
	return nil
end

-- Unified unlock table (characters + transformations + power-ups), built from the above.
Config.UNLOCKS = {} :: { { level: number, kind: string, id: string } }
for _, list in Config.ROSTER do
	for _, ch in list do
		table.insert(Config.UNLOCKS, { level = ch.level, kind = "Character", id = ch.id })
	end
end
for id, f in Config.FORMS do
	if (f :: any).story then
		continue
	end -- story-gated (SSJ4): granted live by PlayerData.hasUnlock, not by level alone
	table.insert(Config.UNLOCKS, { level = f.level, kind = "Transformation", id = id })
end
for _, p in Config.POWERUPS do
	table.insert(Config.UNLOCKS, { level = p.level, kind = "PowerUp", id = p.id })
end
table.sort(Config.UNLOCKS, function(a, b)
	return if a.level == b.level then a.id < b.id else a.level < b.level
end)

Config.GAMEPASSES = {
	DoubleXP = { id = 0, xpMult = 2 },
	VIP = { id = 0, xpMult = 1.25 },
	EarlySuperSaiyan = { id = 0, unlock = "SuperSaiyan" },
	EarlyBlue = { id = 0, unlock = "SuperSaiyanBlue" },
	EarlyJiren = { id = 0, unlock = "u11_jiren" },
	PotaraEarrings = { id = 0, unlock = "Potara" },
	-- v1.2 store passes (PLACEHOLDER ids: create on the Creator Dashboard, then paste)
	AuraPack = { id = 0, aura = "Aura_Crimson" },
	OutfitPack = { id = 0, cosmetic = "Outfit_Gogeta" },
	ZenkaiPass = { id = 0, statMult = 1.05 },
}

Config.PRODUCTS = {
	XPBoost30 = { id = 0, boostMinutes = 30 },
	XPPack500 = { id = 0, xp = 500 },
	SenzuBean = { id = 0, senzu = 1 },
	EnergyDrink3 = { id = 0, drinks = 3 }, -- 49 R$ (MONETIZATION.md)
	-- v1.2 store products (PLACEHOLDER ids; create on the Creator Dashboard)
	XPBoost120 = { id = 0, boostMinutes = 120 },
	Drink5 = { id = 0, drinks = 5 },
}

-- ===== Paid power cap (v5) =====
-- Total stat multiplier from PAID sources (early-unlocked champion/form above the player's earned best,
-- purchased energy-drink boost) is clamped to PAID_STAT_CAP. Applied in Combatant.powerLevel.
Config.PAID_STAT_CAP = 1.35

-- ===== Ranked (v5): skill only. workspace attribute "Ranked" = true. =====
-- Every fighter uses the same Power Level, C-tier counterplay rules, stat ratio 1; no consumables,
-- no Senzu, no divine picks, no paid effects. Cosmetics only differ.
Config.RANKED = { power = 3500, allowDivine = false, allowItems = false, allowSenzu = false }

-- ===== Dragon Block Z Energy Drink (original brand; no official DBZ logo) =====
-- Lighter Senzu: +40% ki, +10% Power Level for 8 s (counts as PAID inside PAID_STAT_CAP), +30% speed 5 s.
-- Max 1 per match, disabled in Ranked. Sources: product EnergyDrink3, daily reward, quests, VIP daily.
Config.ENERGY_DRINK =
	{ kiFrac = 0.4, powerBoost = 0.10, powerTime = 8, speedMult = 1.3, speedTime = 5, maxPerMatch = 1 }

-- ===== Daily login rewards (7-day streak; resets if a day is missed) =====
Config.DAILY_REWARDS = {
	{ zeni = 100 },
	{ zeni = 150 },
	{ drinks = 1 },
	{ zeni = 250 },
	{ xp = 500 },
	{ zeni = 400 },
	{ drinks = 2, senzu = 1, cosmetic = "Aura_Streak7" },
}

-- ===== Solo Training (spec; rooms built by db-map in map/training, NPC lines by db-story) =====
-- Server implementation pending (v1.2). Gains feed normal progression (XP); no stat grants outside the model.
Config.TRAINING = { -- numbers mirror db-map training_spec.md v1.2 attributes (map attributes win at runtime)
	HyperbolicTimeChamber = {
		trainer = "div_angel_whis",
		xpMult = 4,
		gravity = 10,
		maxStaySeconds = 600,
		drills = { "Movement", "M1Combo", "PerfectBlock", "Vanish", "BeamStruggle" },
		sparring = true,
	},
	GravityRoom = {
		steps = { 1, 10, 50, 100, 150, 300, 500 },
		xpMultAtStep = { 1, 1.2, 1.4, 1.6, 1.8, 2.2, 2.5 },
		moveSpeedAtStep = { 1, 0.9, 0.8, 0.7, 0.6, 0.45, 0.35 },
	},
	KingKaiPlanet = {
		xpMult = 2,
		gravity = 10,
		minigames = { "CatchBubbles", "HitGregory" },
		unlock = "KaioKen",
		clearsToUnlock = 3,
	},
	WhisGround = {
		xpMult = 3,
		gravity = 1.5,
		trainers = { "div_angel_whis", "div_destroyer_beerus" },
		paths = { UltraInstinct = "div_angel_whis", Hakai_UltraEgo = "div_destroyer_beerus" },
	},
	baseXpPerMin = 10, -- x area multiplier; solo gains never grant stats beyond the normal level curve
}

-- ===== v6: races / modifiers / stacking (Races.lua, Modifiers.lua, StatResolver.lua) =====
Config.MAX_STAT_MULT = 8 -- hard cap on total (display) multiplier; clamps logged in DEV_MODE
Config.MAX_COMBAT_MULT = 1.6 -- race x modifiers x buffs before combat compression (STAT_CAP 1.35 still applies after)
Config.ZENKAI = { nearDeath = 0.15, surviveSeconds = 3, maxStacks = 5 } -- +2%/stack via Modifiers.Zenkai
Config.RAGE = { hpBelow = 0.25 } -- Half-Saiyan hidden potential (once per match)
Config.BEAST = { allyRange = 40, decayPerSec = 2, outOfCombat = 5 } -- meter +1 per 1% HP lost by self/ally in range
Config.ANGEL_DODGE = { ki = 8, icd = 1.5 }

-- ===== v6: Team Spirit Bomb (GDD §6.6) =====
Config.SPIRIT_BOMB = {
	channel = 6,
	moveMult = 0.3,
	donorRange = 60,
	donorKiPerSec = 5,
	maxDonors = 4,
	baseRadius = 6,
	radiusPerKi = 0.35,
	maxRadius = 30,
	baseDamage = 40,
	damagePerKi = 0.6,
	maxDamage = 100,
	speed = 40,
	maxTravel = 200,
	arenaBase = 150,
	kb = 80,
	deflectTiers = { S = true, GoD = true, Angel = true, GrandPriest = true, Zeno = true },
	deflectPower = 0.5,
}

-- ===== v6: Beerus camp quest chain (TASK_BEERUS.md) =====
Config.BEERUS = {
	steps = {
		{
			id = "Sparring",
			drill = "BeerusDodge",
			seconds = 60,
			orbSpeed = 28,
			orbEvery = 1.2,
			reward = { xp = 1500, zeni = 300 },
		},
		{
			id = "DestructionEnergy",
			drill = "OrbCollect",
			orbs = 6,
			seconds = 60,
			reward = { unlock = "DestructionSphere", xp = 2000 },
		},
		{
			id = "Hakai",
			drill = "HakaiTrial",
			targets = 5,
			hold = 1,
			seconds = 40,
			reward = { unlock = "Hakai", xp = 3000 },
		},
		{ id = "GodAura", auto = true, reward = { unlock = "GodAura" } },
		{
			id = "UltraEgo",
			drill = "EgoEndure",
			seconds = 45,
			orbSpeed = 34,
			orbEvery = 0.8,
			requires = { race = "Saiyan", unlock = "SuperSaiyanBlue" },
			reward = { early = { id = "UltraEgo", level = 85 }, xp = 5000 },
		},
	},
	destroyerCandidateTitle = "Destroyer Candidate", -- Pride Trooper race finishing step 3
}

-- ===== v6: Training room runtime (TrainingRooms.lua; map attributes win at runtime) =====
Config.TRAINING_RUNTIME = {
	-- Which module owns portals/zones/gravity/XP ticks. "Training" = v1.2 Training.lua (booted by V12Boot) -> TrainingRooms then
	-- only runs drills, Beerus camp and quest tracking (no double teleports/XP). Set "TrainingRooms" to use TrainingRooms' loop.
	owner = "TrainingRooms",
	tick = 0.5,
	xpEvery = 10,
	teleportDebounce = 2,
	consoleRange = 15,
	gravityExtraPerG = 0.12,
	gravityExtraMax = 1.5, -- extra downward accel in g (playable: 10G ~ +1.08 g, capped +1.5 g)
	htcFreeVisitsPerDay = 3,
	htcExtraVisitZeni = 200,
	gravityQuest = { step = 300, seconds = 120 },
	drills = {
		WhisDodge = {
			area = "WhisGround",
			stages = 10,
			seconds = 30,
			orbSpeed0 = 18,
			orbSpeedPer = 2,
			orbEvery0 = 1.5,
			orbEveryPer = -0.08,
			reward = { xp = 400, zeni = 60 },
			pathReward = { early = { id = "UltraInstinctSign", level = 70 } },
		},
		CatchBubbles = { area = "KingKaiPlanet", catches = 3, seconds = 60, reward = { xp = 300 } },
		HitGregory = { area = "KingKaiPlanet", catches = 3, seconds = 45, reward = { xp = 300 } },
		HTCEndure = { area = "HyperbolicTimeChamber", seconds = 120, reward = { xp = 600, zeni = 80 } },
	},
	kingKaiClearsToUnlock = 3,
	kingKaiUnlock = "KaioKen",
	kingKaiEarlyLevel = 1,
}

-- ===== v7 feature flags (lead decisions 2026-10-13) =====
Config.FEATURES = {
	PLAYABLE_ANGELS = true, -- Angels are fully playable in ToP and non-Ranked matches! -- Angels are NPC-only at launch (trainers/bosses). div_angel_* ids kept for db-animation NPCs.
}
-- Ultra Instinct Sign: Lv85 normally; Lv70 after all 10 Whis stages. No other path (store/pass/old Training.lua) grants it earlier.
Config.UI_SIGN_RULE = { id = "UltraInstinctSign", earlyLevel = 70, whisStages = 10 }

-- ===== v7 race power-ups (RacePowerUps.lua). Utility; any stat buff goes through StatResolver (1.35x + Ranked = 1). =====
Config.RACE_POWERUPS = {
	Barrier = { duration = 2, kbImmune = true },
	JusticePose = { pose = 1, radius = 30, buff = "JusticeBuff", buffTime = 5 },
	SolarFlare = { radius = 25, facingDot = 0.3, blind = 1.5 },
	KaiKai = { allyRange = 150, pointRange = 80, iframes = 0.3 },
	MajinKOHeal = 0.15, -- Majin: heal 15% max HP on a melee KO (Ranked: 50% strength)
	rankedUtility = 0.5,
}

-- ===== v7 Gravity Room sparring bots (TrainingBots.lua) =====
Config.SPAR_BOTS = {
	max = 4,
	respawn = 5,
	despawnEmpty = 10,
	baseHp = 150,
	hpPerLog = 1.0,
	baseDamage = 4,
	dmgPerLog = 0.5,
	walkSpeed = 13,
	attackRange = 6,
	attackCd = 1.2,
	aggroRange = 60,
	xpPerKO = 40,
	zeniPerKO = 5,
	drillEvery = 5,
}

-- ===== v8: Dragon Ball hunt (DragonBallService; pure rules in DragonBalls.lua) =====
Config.DRAGON_BALLS = {
	anchorTag = "DragonBallSpawn", -- db-map may tag BaseParts; else fallback anchors below (training areas, training_spec v1.2)
	fallbackAnchors = {
		{ x = 2700, y = 101, z = 0 },
		{ x = 2650, y = 101, z = 60 },
		{ x = 2760, y = 101, z = -50 },
		{ x = 3000, y = 101, z = 270 },
		{ x = 6000, y = 101, z = 0 },
		{ x = 6000, y = 101, z = 3000 },
		{ x = 9000, y = 361, z = 0 },
		{ x = 9000, y = 101, z = 3000 },
		{ x = 9100, y = 101, z = 3100 },
		{ x = 8900, y = 101, z = 2900 },
	},
	radarStep = 0.5, -- client radar refresh (s)
}

-- ===== v8: Ranked queue (RankedService; pure Elo in Elo.lua) =====
Config.RANKED_QUEUE = {
	formats = { ["1v1"] = { teamSize = 1 }, ["3v3"] = { teamSize = 3 } },
	minLevel = 15,
	tick = 2,
	maxWait = 300,
	leaderboardStore = "DBZ_RankedElo", -- OrderedDataStore name; key = season suffix "_S<season>"
	leaderboardSize = 100,
	leaderboardRefresh = 120,
}

-- ===== v8: Raids (RaidService + BossNPC; pure scaling in RaidMath.lua). Free drops with PUBLISHED odds (shown in UI). =====
Config.RAIDS = {
	Broly = {
		name = "Legendary Broly",
		animId = "boss_broly",
		hp = 6000,
		minPlayers = 4,
		maxPlayers = 8,
		tier = 3,
		timeLimit = 600,
		walkSpeed = 18,
		phases = { 0.66, 0.33 }, -- rage phases (GDD)
		phaseMods = {
			{ dmg = 1, speed = 1, cdMult = 1 },
			{ dmg = 1.25, speed = 1.15, cdMult = 0.85 },
			{ dmg = 1.5, speed = 1.3, cdMult = 0.7 },
		},
		melee = { damage = 12, range = 8, cd = 1.6, kb = 60 },
		specials = {
			EraserCannon = { cd = 9, windup = 1, radius = 14, damage = 30, arenaRadius = 14, arenaPower = 120 },
			Stomp = { cd = 6, windup = 0.6, radius = 18, damage = 18, arenaRadius = 18, arenaPower = 80 },
		},
		drops = { { id = "Aura_Legendary", p = 0.08 }, { id = "Title_LegendarySurvivor", p = 0.15 } },
		firstClear = { zeni = 1000, cosmetic = "Banner_Broly" },
	},
	Moro = {
		name = "Moro",
		animId = "u7_moro",
		hp = 5000,
		minPlayers = 4,
		maxPlayers = 8,
		tier = 2,
		timeLimit = 600,
		walkSpeed = 16,
		phases = { 0.5 },
		phaseMods = { { dmg = 1, speed = 1, cdMult = 1 }, { dmg = 1.3, speed = 1.1, cdMult = 0.8 } },
		melee = { damage = 10, range = 9, cd = 1.5, kb = 40 },
		specials = {
			Absorb = { cd = 8, range = 30, ki = 20, heal = 0.03 },
			Copy = { cd = 10, power = 0.7 },
			PlanetDrain = {
				cd = 14,
				windup = 1,
				radius = 30,
				pulses = 3,
				damage = 10,
				arenaRadius = 20,
				arenaPower = 60,
			},
		},
		drops = { { id = "Aura_Galactic", p = 0.08 }, { id = "Title_PlanetEater", p = 0.15 } },
		firstClear = { zeni = 800, cosmetic = "Banner_Moro" },
	},
}
Config.RAID_RUNTIME = {
	lobbyCountdown = 20,
	arenaOrigin = { x = 0, y = 100, z = 12000 },
	arenaSpacing = 800,
	arenaSize = 220,
	tick = 0.2,
	devMinPlayers = 1,
}

-- ===== v8: Story missions (StoryMissionService; data from db-story gameplay/StoryMissions.lua) =====
Config.STORY =
	{ bossBaseHp = 400, hpPerMission = 60, bossDamage = 8, dmgPerMission = 0.4, timeLimit = 300, sequential = true }

Config.QUEUE_MODES = { Party = true, Random = true }
Config.EVENT_MODE = false -- workspace attribute "EventMode" (set by live-ops/admin) enables Grand Priest & Zeno, lifts total divine cap

return Config
