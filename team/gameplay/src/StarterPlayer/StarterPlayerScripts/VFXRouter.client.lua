--!strict
-- LocalScript: plays server-broadcast VFX using db-animation modules in ReplicatedStorage.VFX.
-- Visual only: always passes { ArenaDamage = false } (db-animation/db-map contract; server already called DamageAt).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ClientAPI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientAPI"))
local Kits = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Kits")) -- per-character identity
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

-- Effects never break combat (pcall), but in Studio a failing effect is reported instead of silently showing nothing.
local IS_STUDIO = RunService:IsStudio()
local reported: { [string]: boolean } = {}
local function run(label: string, fn: any, ...: any)
	local ok, err = pcall(fn, ...)
	if not ok and IS_STUDIO and not reported[label] then
		reported[label] = true
		warn(string.format("[VFXRouter] %s failed: %s", label, tostring(err)))
	end
end

local cache: { [string]: any } = {}
local function mod(name: string)
	if not VFX then
		return nil
	end
	if cache[name] == nil then
		local m = VFX:FindFirstChild(name) or Kits.findModule(name) -- kits may ship their own effects
		local ok, res = pcall(function()
			return m and require(m)
		end)
		if IS_STUDIO and not m then
			warn("[VFXRouter] missing VFX module " .. name)
		elseif IS_STUDIO and not ok then
			warn(string.format("[VFXRouter] require(%s) failed: %s", name, tostring(res)))
		end
		cache[name] = (ok and res) or false
	end
	return cache[name] or nil
end

ClientAPI.onPlayVFX:Connect(function(kind: string, character: Model, arg: any)
	if not character or not character.Parent then
		return
	end
	-- v10: plain ki blasts (players' KiBlast move, story boss volleys, ally chip shots) use the shared projectile
	if kind == "KiBlast" then
		local c = mod("VFXCommon")
		if c and c.KiBlast then
			run("KiBlast", c.KiBlast, character, { Target = if typeof(arg) == "Vector3" then arg else nil })
		end
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
	modName = (if type(id) == "string" then Kits.signature(id, kind) else nil) or modName
	-- the character's own camera on their move (local player only): push-in and shake
	local cam = if type(id) == "string" and character == Players.LocalPlayer.Character then Kits.camera(id, kind) else nil
	if cam then
		local c = mod("VFXCommon")
		if c then
			if cam.zoom then run("camera zoom", c.FOVPunch, cam.zoom) end
			if cam.shake then run("camera shake", c.CameraShake, cam.shake, 0.4) end
		end
	end
	local m = modName and mod(modName)
	if not m then
		return
	end
	if kind == "FinalExplosion" then
		-- OnDetonate intentionally nil: the SERVER applies damage + self-KO (anti-exploit)
		run(kind, m.Play, character, { ArenaDamage = false, OnDetonate = nil })
	elseif kind == "Erase" then
		run(
			kind,
			m.Play,
			character,
			{ ArenaDamage = false, OnDetonate = nil, Color = Color3.new(1, 1, 1), Radius = 25, ChargeTime = 0.3 }
		)
	elseif kind == "Kaioken" then
		run(kind, m.Play, character, { ArenaDamage = false, Multiplier = typeof(arg) == "number" and arg or 1 })
	elseif kind == "SolarFlare" then
		run(kind, m.Play, character, { ArenaDamage = false })
	else
		run(kind .. " (" .. tostring(modName) .. ")", m.Play, character, arg, { ArenaDamage = false })
	end
end)
