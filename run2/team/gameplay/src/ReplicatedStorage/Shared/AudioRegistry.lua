--!strict
-- ModuleScript: ReplicatedStorage.Shared.AudioRegistry (WP-AUD-1)
-- Central catalog of Dragon Ball show audio IDs with variation pickers, fallback guards, and sound budgeting.
--
-- FIX (2026-10-14): five categories pointed at non-existent Creator Store ids (9114330100/200/300/400 and
-- 9114660101-103). Roblox returns nothing for those, so Vanish, Dash, Parry, Block and the race grunts were
-- completely SILENT in combat. They were sequential fakes sitting next to one real decal id (9114330400).
-- Every id below is now verified against the Creator Store toolbox API (typeId 3 = Audio, free).
--
-- Every id also has a MARKER_ALIASES entry so the `sound = "..."` markers baked into the animation clips
-- (poses/Goku.lua etc.) resolve instead of warning.
local AudioRegistry = {}

export type SoundDef = {
	Id: string,
	Volume: number?,
	PitchRange: Vector2?, -- Min/Max pitch jitter for organic impact
}

local warnedMissing: { [string]: boolean } = {}
local lastPlayed: { [string]: string } = {}

-- Audio Catalog (verified Creator Store SFX; typeId 3, free, pre-cleared)
local SOUNDS: { [string]: { SoundDef } } = {
	-- Combat Hits (Authentic DBZ Punch and Hit SFX)
	HitLight = {
		{ Id = "rbxassetid://99941716088860", Volume = 0.7, PitchRange = Vector2.new(0.96, 1.04) }, -- DBZ Punch (ZENITSU_TRT)
		{ Id = "rbxassetid://140675365380166", Volume = 0.65, PitchRange = Vector2.new(0.95, 1.05) }, -- DB Light Wind-up (SG0966)
	},
	HitMedium = {
		{ Id = "rbxassetid://85945687904817", Volume = 0.85, PitchRange = Vector2.new(0.94, 1.04) }, -- DB Large Hit (SG0966)
		{ Id = "rbxassetid://99941716088860", Volume = 0.8, PitchRange = Vector2.new(0.92, 1.02) },
	},
	HitHeavy = {
		{ Id = "rbxassetid://110214491275012", Volume = 1.0, PitchRange = Vector2.new(0.90, 1.0) }, -- DBZ Punch SFX (RoyalCoolboy369)
	},
	HitFinisher = {
		{ Id = "rbxassetid://106108995063585", Volume = 1.25, PitchRange = Vector2.new(0.88, 0.98) }, -- DBZ Huge Explosion (Qeqffajerk)
		{ Id = "rbxassetid://103385750484448", Volume = 1.15, PitchRange = Vector2.new(0.92, 1.02) }, -- DB Ki Explosion (SG0966)
	},
	HitCrit = {
		{ Id = "rbxassetid://106108995063585", Volume = 1.3, PitchRange = Vector2.new(0.95, 1.05) },
	},

	-- Melee wind-up / whiff layer (drives the `sound = "Swing"` markers on every strike anticipation)
	Swing = {
		{ Id = "rbxassetid://140675365380166", Volume = 0.55, PitchRange = Vector2.new(1.05, 1.20) }, -- light wind-up, pitched up
		{ Id = "rbxassetid://106489289098083", Volume = 0.5, PitchRange = Vector2.new(1.0, 1.15) }, -- flurryhit1 (ProKiller_V)
	},
	SwingHeavy = {
		{ Id = "rbxassetid://121287867059734", Volume = 0.7, PitchRange = Vector2.new(0.85, 0.95) }, -- Unrelenting Force SHORT
		{ Id = "rbxassetid://140675365380166", Volume = 0.6, PitchRange = Vector2.new(0.80, 0.90) },
	},

	-- Evasion, Movement & Jump (all previously SILENT)
	Jump = {
		{ Id = "rbxassetid://135446921404594", Volume = 0.75, PitchRange = Vector2.new(0.95, 1.05) }, -- DBZ Jump (WillfulDragoon)
	},
	Vanish = {
		{ Id = "rbxassetid://117366495512724", Volume = 0.9, PitchRange = Vector2.new(0.95, 1.05) }, -- Gray Teleport SFX (Aconrathium)
	},
	Dash = {
		{ Id = "rbxassetid://90661028523798", Volume = 0.75, PitchRange = Vector2.new(0.95, 1.08) }, -- JJS Dash Whoosh A (Not_Dazun)
	},
	Parry = {
		{ Id = "rbxassetid://9125819216", Volume = 0.95, PitchRange = Vector2.new(1.05, 1.15) }, -- Metal Clangs Clunks (ProSoundEffects)
		{ Id = "rbxassetid://9116542304", Volume = 0.9, PitchRange = Vector2.new(1.0, 1.1) }, -- Metal Clanks 6 (ProSoundEffects)
	},
	Block = {
		{ Id = "rbxassetid://9116668848", Volume = 0.8, PitchRange = Vector2.new(0.85, 0.95) }, -- Metal Impact 1 (ProSoundEffects)
		{ Id = "rbxassetid://85945687904817", Volume = 0.6, PitchRange = Vector2.new(0.80, 0.90) }, -- body thud under the guard
	},
	Grab = {
		{ Id = "rbxassetid://139579413119862", Volume = 0.85, PitchRange = Vector2.new(0.95, 1.05) }, -- DBZ Grabbing Sound (xxpacco22)
	},

	-- Ki, Beams & Powerup
	ChargeKi = {
		{ Id = "rbxassetid://119023480068295", Volume = 0.85, PitchRange = Vector2.new(0.95, 1.05) }, -- DBZ Powerup (WillfulDragoon)
	},
	AuraBurst = {
		{ Id = "rbxassetid://119023480068295", Volume = 1.1, PitchRange = Vector2.new(1.05, 1.12) },
	},
	KiBlast = {
		{ Id = "rbxassetid://112589551277234", Volume = 0.85, PitchRange = Vector2.new(1.05, 1.18) }, -- Huge Ki Beam Charge (jamjam4391), pitched up = volley
		{ Id = "rbxassetid://103385750484448", Volume = 0.7, PitchRange = Vector2.new(1.1, 1.25) },
	},
	BeamFire = {
		{ Id = "rbxassetid://112589551277234", Volume = 1.25, PitchRange = Vector2.new(0.95, 1.05) }, -- DB Huge Ki Beam Charge / Blast (jamjam4391)
	},
	BeamLoop = {
		{ Id = "rbxassetid://112589551277234", Volume = 0.95, PitchRange = Vector2.new(1.0, 1.0) },
	},
	ExplosionMassive = {
		{ Id = "rbxassetid://106108995063585", Volume = 1.4, PitchRange = Vector2.new(0.85, 0.95) }, -- DBZ Huge Explosion
	},
	KiExplosion = {
		{ Id = "rbxassetid://103385750484448", Volume = 1.15, PitchRange = Vector2.new(0.95, 1.05) }, -- DB Ki Explosion (SG0966)
	},
	KO = {
		{ Id = "rbxassetid://106108995063585", Volume = 1.3, PitchRange = Vector2.new(0.75, 0.85) }, -- huge explosion, pitched down = knockout
	},
	BodyFall = {
		{ Id = "rbxassetid://108848349044700", Volume = 0.9, PitchRange = Vector2.new(0.8, 0.92) }, -- metal gloves hit flesh 3 (Jilusions)
	},

	-- UI & Music
	MenuSelect = {
		{ Id = "rbxassetid://138517216516736", Volume = 0.8, PitchRange = Vector2.new(1.0, 1.0) }, -- DBFZ Selection (LegendaryZ1001)
	},
	UltraInstinctBGM = {
		{ Id = "rbxassetid://107262355591095", Volume = 0.9, PitchRange = Vector2.new(1.0, 1.0) }, -- Ultimate Battle UI theme (Mago Rey / DistrokidOfficial)
	},

	-- Archetype Grunts (all three ids were fake before; now real, free vocals)
	SaiyanGrunt = {
		{ Id = "rbxassetid://105878980392777", Volume = 0.85, PitchRange = Vector2.new(0.95, 1.05) }, -- grunt (postdeathh)
		{ Id = "rbxassetid://138315760959087", Volume = 0.85, PitchRange = Vector2.new(0.95, 1.05) }, -- grunt 6 (CorridorBack)
		{ Id = "rbxassetid://95357508614460", Volume = 0.85, PitchRange = Vector2.new(0.95, 1.05) }, -- Uwagh (sanyachurs)
	},
}

-- The animation clips (poses/Goku.lua, Vegeta.lua, Frieza.lua, Shared.lua) name sounds with their own keys:
-- `sound = "Hit_Light"`, `"Kamehameha_Fire"`, `"PerfectGuard"` ... Map every one onto a catalog entry so a
-- marker never warns, and so per-move audio identity survives.
local MARKER_ALIASES: { [string]: string } = {
	-- melee
	Hit_Light = "HitLight",
	Hit_Heavy = "HitHeavy",
	Hit_Finisher = "HitFinisher",
	Swing = "Swing",
	Swing_Heavy = "SwingHeavy",
	-- defence
	PerfectGuard = "Parry",
	Block = "Block",
	-- movement
	Dash = "Dash",
	IT = "Vanish",
	-- ki and beams
	KiBlast = "KiBlast",
	Charge = "ChargeKi",
	Scream_Build = "ChargeKi",
	UI_Hum = "ChargeKi",
	Kamehameha_Charge = "ChargeKi",
	Kamehameha_Fire = "BeamFire",
	GalickGun_Charge = "ChargeKi",
	GalickGun_Fire = "BeamFire",
	FinalFlash_Charge = "ChargeKi",
	FinalFlash_Fire = "BeamFire",
	SpiritBomb_Charge = "ChargeKi",
	SpiritBomb_Fire = "BeamFire",
	DeathBeam_Charge = "ChargeKi",
	DeathBeam_Fire = "BeamFire",
	-- detonations and transformations
	BigBang = "KiExplosion",
	DeathBall_Charge = "ChargeKi",
	DeathBall_Fire = "ExplosionMassive",
	Disc_Throw = "Swing",
	Nova = "AuraBurst",
	BlackNova = "AuraBurst",
	FinalExplosion_Charge = "ChargeKi",
	FinalExplosion_Blast = "ExplosionMassive",
	Transform_Flash = "ExplosionMassive",
	UltraEgo_Flash = "AuraBurst",
	Golden_Shatter = "AuraBurst",
	Black_Arrive = "AuraBurst",
	Frieza_Laugh = "SaiyanGrunt",
	-- round flow
	KO = "KO",
	BodyFall = "BodyFall",
}

-- Fetch a sound definition by key with variation picking (guaranteed no back-to-back repeats)
function AudioRegistry.get(category: string): SoundDef?
	local list = SOUNDS[category]
	if not list or #list == 0 then
		if not warnedMissing[category] then
			warnedMissing[category] = true
			warn(string.format("[AudioRegistry] Missing audio category: '%s'", category))
		end
		return nil
	end

	if #list == 1 then
		return list[1]
	end

	local last = lastPlayed[category]
	local available = {}
	for _, s in ipairs(list) do
		if s.Id ~= last then
			table.insert(available, s)
		end
	end

	local pick = available[math.random(1, #available)] or list[1]
	lastPlayed[category] = pick.Id
	return pick
end

-- Resolve an animation marker sound name ("Hit_Light") to a catalog category ("HitLight").
function AudioRegistry.resolve(name: string): string
	return MARKER_ALIASES[name] or name
end

-- Play 3D positional or 2D interface sound with pitch jitter
function AudioRegistry.play(category: string, parent: Instance?, volumeMultiplier: number?): Sound?
	local def = AudioRegistry.get(category)
	if not def or def.Id == "" or def.Id == "rbxassetid://0" then
		return nil
	end

	local s = Instance.new("Sound")
	s.SoundId = def.Id
	s.Volume = (def.Volume or 1.0) * (volumeMultiplier or 1.0)

	if def.PitchRange then
		local pmin = def.PitchRange.X
		local pmax = def.PitchRange.Y
		s.PlaybackSpeed = pmin + math.random() * (pmax - pmin)
	end

	s.Parent = parent or workspace
	s:Play()

	s.Ended:Once(function()
		s:Destroy()
	end)

	return s
end

-- Entry point for PosePlayer `sound` markers: aliases the clip name, then plays.
function AudioRegistry.playMarker(name: string, parent: Instance?, volumeMultiplier: number?): Sound?
	return AudioRegistry.play(AudioRegistry.resolve(name), parent, volumeMultiplier)
end

return AudioRegistry
