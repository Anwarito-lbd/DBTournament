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
--   PosePlayer.Play(char, clip, R.opts({ Speed = 1.25 }, char))
-- R.opts returns {Registry = ..., OnMarker = ...} which PosePlayer consumes. FightAnimator is the only caller.
--
-- COSMETIC ONLY (fight plan P0): markers give a clip its sounds, smears, speed lines and charge/transform
-- flourishes. They never do the move or the hit: move effects (beams, ki blasts, teleports) come from the server's
-- PlayVFX broadcast through VFXRouter, and hit feedback (hitstop, impact frames, shakes, bursts) from the server's Hit
-- event through GameFeel, so it fires once and only when a hit actually lands. Hence no Hitstop/KiBlast/module
-- markers here, and impact-style markers are skipped on contact frames (keyframes carrying `hit`).
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

-- contact frames carry `hit`; their feedback belongs to GameFeel's confirmed-hit path
local function onContact(mk: any): boolean
	return type(mk) == "table" and mk.hit ~= nil
end

PRIMITIVES["VFXCommon.CameraShake"] = function(character, args, mk)
	if onContact(mk) then
		return
	end
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

PRIMITIVES["VFXCommon.FOVPunch"] = function(character, args, mk)
	if onContact(mk) then
		return
	end
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

PRIMITIVES["VFXCommon.ImpactFrame"] = function(character, args, mk)
	if onContact(mk) then
		return
	end
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

PRIMITIVES["VFXCommon.Shockwave"] = function(character, _args, mk)
	if onContact(mk) then
		return
	end
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

PRIMITIVES["VFXCommon.DebrisBurst"] = function(character, _args, mk)
	if onContact(mk) then
		return
	end
	local C = vfxCommon()
	if not C then
		return
	end
	C.DebrisBurst(fxFolder(), groundPos(character), 6, 26, nil, 2)
end

PRIMITIVES["VFXCommon.GroundCrack"] = function(character, _args, mk)
	if onContact(mk) then
		return
	end
	local C = vfxCommon()
	if not C then
		return
	end
	C.GroundCrack(fxFolder(), groundPos(character), 6, 8, formColor(C, character), 3)
end

PRIMITIVES["VFXCommon.Impact"] = function(character, args, mk)
	if onContact(mk) then
		return
	end
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

function AnimMarkerRouter.registry(): { [string]: any }
	return registry
end

-- PosePlayer's OnMarker signature is (mk, kf, clipName) and does not pass the character, so each Play gets its own
-- OnMarker closed over the character it animates (several characters animate at once).
function AnimMarkerRouter.opts(extra: { [string]: any }?, character: any): { [string]: any }
	local out: { [string]: any } = if extra then table.clone(extra) else {}
	out.Registry = registry
	out.OnMarker = function(mk: any)
		if mk and mk.sound then
			AudioRegistry.playMarker(mk.sound, character or Workspace, 1.0)
		end
	end
	return out
end

return AnimMarkerRouter
