--!strict
-- ModuleScript: ReplicatedStorage.Shared.FightAnimator (client)
-- The one owner of a fighter's combat body (fight plan P0). Before this, three systems wrote the same R15 joints
-- every frame (the Animator, CombatInput's PosePlayer clips and AnimeStyle's own pose layer), the local player's
-- moves played twice with two different poses, and remote players saw a different move than the attacker did.
-- Now every combat pose on every character goes through play():
--   * source "local": the local player's own input, played immediately (CombatInput, the stance menu).
--   * source "server": server broadcasts for any character (AnimeStyle). For the local character they are skipped
--     when the same move family was just played locally, so a predicted move is never played twice.
-- One clip runs per character; starting another stops the previous one. Clip markers are cosmetic only
-- (AnimMarkerRouter): move effects come from the server's PlayVFX broadcast (VFXRouter) and hit feedback from the
-- server's Hit event (GameFeel). Hitstop pauses the playing clip through VFXCommon.HitstopHook.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimMarkerRouter = require(script.Parent:WaitForChild("AnimMarkerRouter"))

local PosesFolder = ReplicatedStorage:WaitForChild("Poses", 10)
local function poses(name: string): any
	local m = PosesFolder and PosesFolder:FindFirstChild(name)
	if not m then return nil end
	local ok, res = pcall(require, m)
	return if ok then res else nil
end
local PosePlayer = poses("PosePlayer")
local GokuPoses, VegetaPoses, FriezaPoses, SharedPoses = poses("Goku"), poses("Vegeta"), poses("Frieza"), poses("Shared")

local FightAnimator = {}

local DEDUPE_WINDOW = 0.6 -- seconds: a server echo of a move I just predicted is ignored

type Playing = { handle: any, name: string, family: string, loop: boolean }
local playing: { [Model]: Playing } = {}
local lastLocal: { [Model]: { family: string, t: number } } = {}

local function clipOf(set: any, name: string): any
	if not set then return nil end
	return set[name] or (set.clips and set.clips[name])
end

-- champion id from the player attribute or the character model
function FightAnimator.championId(ch: Model): string?
	local pl = Players:GetPlayerFromCharacter(ch)
	local id = (pl and pl:GetAttribute("Character")) or ch:GetAttribute("Character") or ch:GetAttribute("ChampionModel")
	return if type(id) == "string" and id ~= "" then id else nil
end

local function setFor(id: string?): any
	if id then
		if string.find(id, "vegeta") then return VegetaPoses end
		if string.find(id, "frieza") or string.find(id, "frost") then return FriezaPoses end
		if string.find(id, "goku") then return GokuPoses end
	end
	return SharedPoses
end

-- the character's own clip, else Goku's (signature beams, transforms), else the shared set
function FightAnimator.clip(ch: Model, name: string): any
	return clipOf(setFor(FightAnimator.championId(ch)), name) or clipOf(GokuPoses, name) or clipOf(SharedPoses, name)
end

-- signature beam clips: Vegeta's Galick Gun, Frieza's Death Beam, everyone else the Kamehameha stance
function FightAnimator.beamClips(ch: Model): (string, string)
	local id = FightAnimator.championId(ch) or ""
	if string.find(id, "vegeta") then return "GalickGun_Charge", "GalickGun_Fire" end
	if string.find(id, "frieza") or string.find(id, "frost") then return "DeathBeam_Charge", "DeathBeam_Fire" end
	return "Kamehameha_Charge", "Kamehameha_Fire"
end

export type PlayOpts = {
	source: string?, -- "local" (default) or "server"
	family: string?, -- move family for de-duplication (the server's move kind: "M1", "Heavy", "Dash", ...)
	speed: number?,
	loop: boolean?,
	markers: boolean?, -- cosmetic clip markers (sounds, smears); default true
	name: string?, -- label for a clip passed as a table (current() reports it)
}

-- what: a clip name (resolved per character) or a clip table. Returns the PosePlayer handle, or nil if skipped.
function FightAnimator.play(ch: Model?, what: any, opts: PlayOpts?): any
	if not PosePlayer or not ch or not ch.Parent then return nil end
	local o: PlayOpts = opts or {}
	local name = if type(what) == "string" then what else (o.name or "clip")
	local clip = if type(what) == "string" then FightAnimator.clip(ch, what) else what
	if not clip then return nil end
	local family = o.family or name
	local now = os.clock()
	if o.source == "server" and ch == Players.LocalPlayer.Character then
		local l = lastLocal[ch]
		if l and l.family == family and now - l.t < DEDUPE_WINDOW then return nil end
	end
	local cur = playing[ch]
	if cur and cur.handle and cur.handle.Stop then cur.handle:Stop(0.08) end
	local popts: { [string]: any } = { Speed = o.speed or 1, Loop = o.loop == true, Name = name }
	if o.markers ~= false then popts = AnimMarkerRouter.opts(popts, ch) end
	local entry: Playing
	popts.OnFinished = function()
		if playing[ch] == entry then playing[ch] = nil end
	end
	local handle = PosePlayer.Play(ch, clip, popts)
	entry = { handle = handle, name = name, family = family, loop = o.loop == true }
	playing[ch] = entry
	if o.source ~= "server" then lastLocal[ch] = { family = family, t = now } end
	return handle
end

function FightAnimator.stop(ch: Model?, fade: number?)
	local cur = ch and playing[ch]
	if not cur then return end
	playing[ch :: Model] = nil
	if cur.handle and cur.handle.Stop then cur.handle:Stop(fade or 0.12) end
end

-- name of the clip currently playing on ch (nil when the Animator has the body)
function FightAnimator.current(ch: Model?): string?
	local cur = ch and playing[ch]
	if cur and cur.handle and cur.handle.Playing then return cur.name end
	if ch then playing[ch] = nil end
	return nil
end

-- hitstop holds the playing clip too (VFXCommon.Hitstop only pauses AnimationTracks by itself)
local VFX = ReplicatedStorage:FindFirstChild("VFX")
local common = VFX and VFX:FindFirstChild("VFXCommon")
if common then
	local ok, C = pcall(require, common)
	if ok and type(C) == "table" and type(C.HitstopHook) == "function" then
		C.HitstopHook(function(chars: any, secs: number)
			for _, ch in (if type(chars) == "table" then chars else { chars }) do
				local cur = if typeof(ch) == "Instance" then playing[ch :: Model] else nil
				local h = cur and cur.handle
				if h and h.Playing and (h.Speed or 0) > 0 then
					local sp = h.Speed
					h.Speed = 0
					task.delay(secs, function()
						if h.Speed == 0 then h.Speed = sp end
					end)
				end
			end
		end)
	end
end

return FightAnimator
