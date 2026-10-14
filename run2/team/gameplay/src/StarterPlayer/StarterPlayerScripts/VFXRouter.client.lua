--!strict
-- LocalScript: plays server-broadcast VFX using db-animation modules in ReplicatedStorage.VFX.
-- Visual only: always passes { ArenaDamage = false } (db-animation/db-map contract; server already called DamageAt).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ClientAPI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientAPI"))
local VFX = ReplicatedStorage:WaitForChild("VFX", 10)

-- Initialize WP22 VFX LOD Manager if available
task.spawn(function()
	if VFX then
		local lodMod = VFX:WaitForChild("VFXLODManager", 5)
		if lodMod and lodMod:IsA("ModuleScript") then
			local ok, lod = pcall(require, lodMod)
			if ok and typeof(lod) == "table" and typeof(lod.Init) == "function" then
				lod.Init()
			end
		end
	end
end)

-- Every kind the server can broadcast, mapped to the db-animation module that renders it.
-- Previously only 15 kinds were covered, so the Vegeta sparring bot's "GalickGun" beam, plus the
-- Death Beam / Death Ball / Final Flash / Big Bang / Nova / Special Beam Cannon families, rendered nothing.
local MODULES: { [string]: string } = {
	-- core beams (Kamehameha is re-pointed per champion below)
	Kamehameha = "KamehamehaVFX",
	GalickGun = "GalickGunVFX",
	FinalFlash = "FinalFlashVFX",
	SpecialBeamCannon = "SpecialBeamCannonVFX",
	BeastSBC = "BeastSBCVFX",
	-- Frieza / destroyer projectiles
	DeathBeam = "DeathBeamVFX",
	DeathBall = "DeathBallVFX",
	DestructionSphere = "DeathBallVFX",
	DestructoDisc = "DestructoDiscVFX",
	NovaStrike = "NovaStrikeVFX",
	BlackNova = "BlackFriezaVFX",
	BigBangAttack = "BigBangAttackVFX",
	PowerImpact = "PowerImpactVFX",
	JusticePose = "PowerImpactVFX",
	-- transformations and self-blasts
	Transform = "TransformationVFX",
	FinalExplosion = "FinalExplosionVFX",
	Erase = "FinalExplosionVFX",
	EraseWarning = "FinalExplosionVFX",
	Kaioken = "KaiokenVFX",
	-- divine
	Hakai = "HakaiVFX",
	HakaiWindup = "HakaiVFX",
	HakaiFail = "HakaiVFX",
	Barrier = "Android17BarrierVFX",
	AngelicBarrier = "Android17BarrierVFX",
	-- utility / movement
	Absorb = "MoroAbsorbVFX",
	MoroPlanetDrain = "MoroPlanetDrainVFX",
	SolarFlare = "SolarFlareVFX",
	SpiritBomb = "SpiritBombVFX",
	SpiritBombCharge = "SpiritBombVFX",
	SpiritBombThrow = "SpiritBombVFX",
	SpiritBombDetonate = "SpiritBombVFX",
	InstantTransmission = "InstantTransmissionVFX",
	KaiKai = "InstantTransmissionVFX",
	StaffWarp = "InstantTransmissionVFX",
	-- rushes, struggles and team play
	MUIRush = "MUIRushVFX",
	TimeSkip = "TimeSkipVFX",
	BeamStruggle = "BeamStruggleVFX",
	Fusion = "FusionVFX",
	TeamCombo = "TeamComboVFX",
	MergedBeam = "TeamComboVFX",
	SyncRush = "TeamComboVFX",
	EnergyGift = "TeamComboVFX",
}

-- Champion-specific override for the generic "Kamehameha" slot: each hero's signature ranged move.
local SIGNATURE_OVERRIDE: { [string]: { [string]: string } } = {
	u7_vegeta = { Kamehameha = "FinalFlashVFX" },
	u7_frieza = { Kamehameha = "DeathBeamVFX" },
	u6_frost = { Kamehameha = "DeathBeamVFX" },
	u6_hit = { Kamehameha = "TimeSkipVFX" },
	u11_jiren = { Kamehameha = "PowerImpactVFX" },
}

local cache: { [string]: any } = {}
local function mod(name: string)
	if not VFX then
		return nil
	end
	if cache[name] == nil then
		local m = VFX:FindFirstChild(name)
		local ok, res = pcall(function()
			return m and require(m)
		end)
		cache[name] = (ok and res) or false
	end
	return cache[name] or nil
end

ClientAPI.onPlayVFX:Connect(function(kind: string, character: Model, arg: any)
	if not character or not character.Parent then
		return
	end
	local modName = MODULES[kind]
	-- Signature ranged move per champion, covering both the generic "Kamehameha" slot and the
	-- "GalickGun" kind that TrainingBots broadcasts for the Vegeta sparring partner.
	local pl = Players:GetPlayerFromCharacter(character)
	local id = (pl and pl:GetAttribute("Character"))
		or character:GetAttribute("Character")
		or character:GetAttribute("ChampionModel")
	local override = id and SIGNATURE_OVERRIDE[id]
	if override and override[kind] then
		modName = override[kind]
	end
	local m = modName and mod(modName)
	if not m then
		return
	end
	if kind == "FinalExplosion" then
		-- OnDetonate intentionally nil: the SERVER applies damage + self-KO (anti-exploit)
		pcall(m.Play, character, { ArenaDamage = false, OnDetonate = nil })
	elseif kind == "Erase" then
		pcall(
			m.Play,
			character,
			{ ArenaDamage = false, OnDetonate = nil, Color = Color3.new(1, 1, 1), Radius = 25, ChargeTime = 0.3 }
		)
	elseif kind == "Kaioken" then
		pcall(m.Play, character, { ArenaDamage = false, Multiplier = typeof(arg) == "number" and arg or 1 })
	elseif kind == "SolarFlare" then
		pcall(m.Play, character, { ArenaDamage = false })
	else
		pcall(m.Play, character, arg, { ArenaDamage = false })
	end
end)
