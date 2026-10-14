--!nonstrict
-- ModuleScript: ReplicatedStorage.Shared.AnimMarkerRouter
--
-- WHY THIS EXISTS
-- poses/*.lua carry `markers = {vfx = "Module.Fn:arg;...", sound = "Name"}` on 521 keyframes. PosePlayer only
-- forwards those to opts.Registry / opts.OnMarker. CombatInput called Play(ch, clip, {Speed = ...}) with
-- NEITHER, so every marker in all 99 clips was discarded: no strike afterimages, no pose-driven impact
-- frames, no per-move beam VFX (KamehamehaVFX / DeathBeamVFX / GalickGunVFX / MUIRushVFX / ...), and no
-- swing/hit/beam sounds from the animation track. team/animation/README.md line 71 documents the intended
-- Registry usage; this module is the missing implementation of it (POLISH_BIBLE §141 calls it AnimMarkerRouter).
--
-- CONTRACT
--   local R = require(Shared.AnimMarkerRouter)
--   PosePlayer.Play(char, clip, R.opts({ Speed = 1.25 }))
-- R.opts returns {Registry = ..., OnMarker = ...} which PosePlayer consumes.
--
-- Everything is pcall-guarded and quality-gated: a bad marker can never break combat.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local AudioRegistry = require(script.Parent:WaitForChild("AudioRegistry"))

local VFX_FOLDER_NAME = "VFX"
local FX_FOLDER_NAME = "AnimMarkerFX"

local AnimMarkerRouter = {}

-- ---------------------------------------------------------------------------------------------------------
-- module cache
-- ---------------------------------------------------------------------------------------------------------
local moduleCache: { [string]: any } = {}

local function vfxFolder(): Instance?
	return ReplicatedStorage:FindFirstChild(VFX_FOLDER_NAME)
end

local function getModule(name: string): any
	if moduleCache[name] ~= nil then
		return moduleCache[name] or nil
	end
	local folder = vfxFolder()
	local inst = folder and folder:FindFirstChild(name)
	if not inst or not inst:IsA("ModuleScript") then
		moduleCache[name] = false
		return nil
	end
	local ok, res = pcall(require, inst)
	moduleCache[name] = (ok and res) or false
	if not ok then
		warn(string.format("[AnimMarkerRouter] require(%s) failed: %s", name, tostring(res)))
	end
	return moduleCache[name] or nil
end

-- ---------------------------------------------------------------------------------------------------------
-- scene helpers
-- ---------------------------------------------------------------------------------------------------------
local function rootOf(character: any): BasePart?
	if typeof(character) ~= "Instance" then
		return nil
	end
	local m = character :: Model
	if not m.Parent then
		return nil
	end
	return (
		m:FindFirstChild("HumanoidRootPart")
		or m:FindFirstChild("UpperTorso")
		or m:FindFirstChild("Torso")
	) :: BasePart?
end

local function fxFolder(): Instance
	local f = Workspace:FindFirstChild(FX_FOLDER_NAME)
	if not f then
		f = Instance.new("Folder")
		f.Name = FX_FOLDER_NAME
		f.Parent = Workspace
	end
	return f
end

-- Aim point in front of the character; used when a marker asks for a positional effect.
local function aimPoint(character: any, distance: number?): Vector3
	local root = rootOf(character)
	if not root then
		return Vector3.zero
	end
	return root.Position + root.CFrame.LookVector * (distance or 60)
end

local function groundPos(character: any): Vector3
	local root = rootOf(character)
	if not root then
		return Vector3.zero
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, fxFolder() }
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -12, 0), params)
	return if hit then hit.Position else root.Position - Vector3.new(0, 3, 0)
end

-- Active form id for the character (falls back to Base), used for aura tints.
local function formIdOf(character: any): string
	if typeof(character) == "Instance" then
		local pl = Players:GetPlayerFromCharacter(character :: Model)
		local f = (pl and pl:GetAttribute("Form")) or (character :: Instance):GetAttribute("Form")
		if type(f) == "string" and f ~= "" then
			return f
		end
	end
	return "Base"
end

local function formColor(C: any, character: any): Color3
	-- VFXCommon.AURAS stores hex strings ("FFD84A"), not Color3 values.
	local id = formIdOf(character)
	local auras = C and C.AURAS
	local entry = auras and (auras[id] or auras.Default)
	if typeof(entry) == "table" and type(entry.Primary) == "string" then
		local ok, col = pcall(Color3.fromHex, entry.Primary)
		if ok then
			return col
		end
	end
	return Color3.fromRGB(255, 240, 190)
end

-- "invert:2" -> {"invert", "2"}
local function splitArgs(arg: string?): { string }
	local out = {}
	if not arg or arg == "" then
		return out
	end
	for piece in string.gmatch(arg, "[^:]+") do
		table.insert(out, piece)
	end
	return out
end

local function num(v: string?, default: number): number
	local n = tonumber(v)
	return n or default
end

local function vfxCommon(): any
	return getModule("VFXCommon")
end

-- ---------------------------------------------------------------------------------------------------------
-- per-primitive argument interpretation
-- ---------------------------------------------------------------------------------------------------------
-- The marker syntax only ever carries a bare ":arg" suffix, so each primitive documents how it reads it.
local PRIMITIVES: { [string]: (character: any, args: { string }, mk: any) -> () } = {}

PRIMITIVES["VFXCommon.Afterimage"] = function(character, args)
	local C = vfxCommon()
	if not C then
		return
	end
	C.Afterimage(character, formColor(C, character), num(args[1], 0.4), 0.35)
end

PRIMITIVES["VFXCommon.CameraShake"] = function(character, args)
	local C = vfxCommon()
	if not C then
		return
	end
	if typeof(character) ~= "Instance" then
		return
	end
	local pl = Players:GetPlayerFromCharacter(character :: Model)
	-- Only shake my own camera for my own moves; remote shakes come from GameFeel's combat events.
	if pl and pl ~= Players.LocalPlayer then
		return
	end
	C.CameraShake(num(args[1], 0.2), 0.4)
end

PRIMITIVES["VFXCommon.FOVPunch"] = function(character, args)
	local C = vfxCommon()
	if not C then
		return
	end
	if typeof(character) == "Instance" then
		local pl = Players:GetPlayerFromCharacter(character :: Model)
		if pl and pl ~= Players.LocalPlayer then
			return
		end
	end
	C.FOVPunch(num(args[1], 4))
end

PRIMITIVES["VFXCommon.SpeedLines"] = function(character, args)
	local C = vfxCommon()
	if not C then
		return
	end
	if typeof(character) == "Instance" then
		local pl = Players:GetPlayerFromCharacter(character :: Model)
		if pl and pl ~= Players.LocalPlayer then
			return
		end
	end
	C.SpeedLines(num(args[1], 0.3), Color3.new(1, 1, 1))
end

-- VFXCommon.Hitstop has no internal rate limit, and GameFeel.client.lua also applies hitstop from the
-- server's Hit event. Whichever lands second would stack on top of the first, so gate the marker path.
local lastHitstopAt = 0

PRIMITIVES["VFXCommon.Hitstop"] = function(character, args, mk)
	local C = vfxCommon()
	if not C then
		return
	end
	local now = os.clock()
	if now - lastHitstopAt < 0.12 then
		return
	end
	lastHitstopAt = now
	-- The animation track is the authority for hitstop timing (VFX_QUALITY_BAR §2).
	local tier = args[1]
	if not tier and typeof(mk.hit) == "table" then
		tier = mk.hit.hitstop or mk.hit.tier
	end
	local subject = character
	if typeof(character) == "Instance" then
		subject = { character }
		local pl = Players:GetPlayerFromCharacter(character :: Model)
		local otherId = pl and pl:GetAttribute("LockTargetId")
		if otherId then
			local otherPl = Players:GetPlayerByUserId(otherId)
			if otherPl and otherPl.Character then
				table.insert(subject, otherPl.Character)
			end
		end
	end
	C.Hitstop(subject, tier or "Light")
end

PRIMITIVES["VFXCommon.ImpactFrame"] = function(character, args)
	local C = vfxCommon()
	if not C then
		return
	end
	-- "invert:2" -> mode + frames
	local mode = args[1] or "invert"
	local frames = num(args[2], if mode == "invert" then 2 else 1)
	local subjects = if typeof(character) == "Instance" then { character } else nil
	C.ImpactFrame(mode, frames, subjects)
end

PRIMITIVES["VFXCommon.Shockwave"] = function(character)
	local C = vfxCommon()
	if not C then
		return
	end
	local root = rootOf(character)
	if not root then
		return
	end
	C.Shockwave(fxFolder(), CFrame.new(root.Position), 1, 6, formColor(C, character), 0.3)
end

PRIMITIVES["VFXCommon.DebrisBurst"] = function(character)
	local C = vfxCommon()
	if not C then
		return
	end
	C.DebrisBurst(fxFolder(), groundPos(character), 6, 26, nil, 2)
end

PRIMITIVES["VFXCommon.GroundCrack"] = function(character)
	local C = vfxCommon()
	if not C then
		return
	end
	C.GroundCrack(fxFolder(), groundPos(character), 6, 8, formColor(C, character), 3)
end

PRIMITIVES["VFXCommon.Impact"] = function(character, args)
	local C = vfxCommon()
	if not C then
		return
	end
	-- "Ultimate" -> tier; big finishing detonation at the character
	local root = rootOf(character)
	if not root then
		return
	end
	C.Impact(fxFolder(), root.Position, 10, formColor(C, character), nil, args[1] or "Heavy", {})
end

PRIMITIVES["VFXCommon.KiBlast"] = function(character)
	local C = vfxCommon()
	if not C then
		return
	end
	if typeof(C.KiBlast) == "function" then
		C.KiBlast(character)
	end
end

-- ---------------------------------------------------------------------------------------------------------
-- module calls: "KamehamehaVFX.Play:fire"
-- ---------------------------------------------------------------------------------------------------------
-- Phases that mean "this marker is the release, play the whole move now". Charge/hold phases are skipped so
-- the move does not render twice, because each module's Play() already runs its own charge -> fire sequence.
local RELEASE_PHASES: { [string]: boolean } = {
	fire = true,
	throw = true,
	strike = true,
	final = true,
	appear = true,
	blast = true,
	[""] = true,
}

local transformationHandles: { [any]: any } = {}

local function callModule(character, fnPath: string, arg: string?): boolean
	local dot = string.find(fnPath, ".", 1, true)
	if not dot then
		return false
	end
	local modName = string.sub(fnPath, 1, dot - 1)
	local fnName = string.sub(fnPath, dot + 1)
	local M = getModule(modName)
	if not M then
		return false
	end

	-- TransformationVFX is stateful: Start returns a handle that must later be stopped.
	if modName == "TransformationVFX" then
		if fnName == "Start" and typeof(M.Start) == "function" then
			local handle = M.Start(character, formIdOf(character), {})
			transformationHandles[character] = handle
			return true
		elseif fnName == "Stop" then
			local handle = transformationHandles[character]
			transformationHandles[character] = nil
			local finish = (arg ~= "false")
			if handle and typeof(handle.Stop) == "function" then
				handle:Stop(finish)
			elseif typeof(M.Play) == "function" then
				-- No matching Start (e.g. server-driven transform): fall back to the one-shot.
				pcall(M.Play, character, formIdOf(character), { ArenaDamage = false })
			end
			return true
		end
	end

	local fn = M[fnName]
	if typeof(fn) ~= "function" then
		return false
	end

	-- Phase gate for .Play
	if fnName == "Play" then
		local phase = arg or ""
		if not RELEASE_PHASES[phase] then
			return true -- recognised charge/hold marker: handled by the release call
		end
	end

	local target = aimPoint(character, 150)
	local ok, err = pcall(fn, character, target, { ArenaDamage = false, Phase = arg })
	if not ok then
		warn(string.format("[AnimMarkerRouter] %s failed: %s", fnPath, tostring(err)))
	end
	return true
end

-- ---------------------------------------------------------------------------------------------------------
-- public API
-- ---------------------------------------------------------------------------------------------------------
local registry: { [string]: any } = {}

for name, handler in pairs(PRIMITIVES) do
	-- PosePlayer invokes a registry entry as fn(character, argString, marker), so primitive handlers get
	-- the raw ":a:b" suffix split into an argument list first.
	registry[name] = function(character, arg, mk)
		handler(character, splitArgs(arg), mk)
	end
end

-- Registry entries for module functions are created lazily by the vfx dispatcher below; PosePlayer looks the
-- exact "Module.Function" string up in the table, so seed the ones the clips actually reference.
local MODULE_MARKERS = {
	"KamehamehaVFX.Play",
	"SpiritBombVFX.Play",
	"DeathBallVFX.Play",
	"DeathBeamVFX.Play",
	"FinalFlashVFX.Play",
	"GalickGunVFX.Play",
	"BigBangAttackVFX.Play",
	"DestructoDiscVFX.Play",
	"NovaStrikeVFX.Play",
	"BlackFriezaVFX.Play",
	"FinalExplosionVFX.Play",
	"MUIRushVFX.Play",
	"TransformationVFX.Start",
	"TransformationVFX.Stop",
	"InstantTransmissionVFX.Vanish",
	"InstantTransmissionVFX.Appear",
}

for _, path in ipairs(MODULE_MARKERS) do
	registry[path] = function(character, arg)
		callModule(character, path, arg)
	end
end

function AnimMarkerRouter.registry(): { [string]: any }
	return registry
end

-- PosePlayer's OnMarker signature is (mk, kf, clipName) and it deliberately does NOT pass the character, so the
-- emitter is bound once per Play call via AnimMarkerRouter.bind(character) -> AnimMarkerRouter.opts{...}.
-- Clips are played locally for one character at a time (CombatInput/CombatActionUI), so a single binding is
-- sufficient and avoids threading the character through the marker layer.
local boundCharacter: any = nil

function AnimMarkerRouter.bind(character: any)
	boundCharacter = character
end

function AnimMarkerRouter.opts(extra: { [string]: any }?): { [string]: any }
	local out: { [string]: any } = if extra then table.clone(extra) else {}
	out.Registry = registry
	out.OnMarker = function(mk: any)
		if mk and mk.sound then
			AudioRegistry.playMarker(mk.sound, boundCharacter or Workspace, 1.0)
		end
	end
	return out
end

return AnimMarkerRouter
