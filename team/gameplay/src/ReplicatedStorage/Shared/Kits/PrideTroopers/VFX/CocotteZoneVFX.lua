--!nonstrict
-- CocotteZoneVFX (Pride Troopers kit, Cocotte). Cocotte Zone: a purple dome that seals her in her own dimension, in
-- the kit's `zone` look. It is her Justice Pose (she strikes her pose inside it for the pose time) and her barrier
-- (the server's Barrier kind passes its duration as the number argument). Wrapper over Android17BarrierVFX's dome.
-- Play(character, durationOrNil, config?). Visual only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local Barrier = require(VFX:WaitForChild("Android17BarrierVFX"))
local Config = require(Shared:WaitForChild("Config"))
local FightAnimator = require(Shared:WaitForChild("FightAnimator"))
local Kit = require(script.Parent.Parent)
local RULE = (Config.RACE_POWERUPS and Config.RACE_POWERUPS.JusticePose) or {}
local M = {}
M.PRESET = { Rings = 4, PanelsPerRing = 10 }
function M.Play(character, arg, config)
	local barrier = type(arg) == "number"
	if not barrier then
		FightAnimator.play(character, "JusticePose", { source = "server", family = "JusticePose", markers = false })
	end
	local look = C.merge(M.PRESET, Kit.lookFor(Kit.idOf(character), "zone"))
	look.Duration = if barrier then arg else (RULE.pose or 1)
	return Barrier.Start(character, C.merge(look, config))
end
return M
