--!nonstrict
-- DimensionWallVFX (Pride Troopers kit, Cocotte). Her Justice Pose: a pale-blue dimension wall closes around her for
-- the length of the pose, then fades. Visual only (the Justice Buff is the server's). Wrapper over the
-- Android17BarrierVFX dome. Play(character, _target, config?).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local Barrier = require(VFX:WaitForChild("Android17BarrierVFX"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RULE = (Config.RACE_POWERUPS and Config.RACE_POWERUPS.JusticePose) or {}
local M = {}
M.PRESET = {
	Radius = 6,
	Color = Color3.fromRGB(150, 220, 255),
	EdgeColor = Color3.fromRGB(235, 250, 255),
	Duration = RULE.pose or 1,
	Rings = 4,
	PanelsPerRing = 10,
}
function M.Play(character, _target, config)
	return Barrier.Start(character, C.merge(M.PRESET, config))
end
return M
