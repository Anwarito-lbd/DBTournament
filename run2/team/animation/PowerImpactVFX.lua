--!nonstrict
-- PowerImpactVFX (Jiren). Thin preset wrapper over DeathBallVFX: red energy sphere, faster travel, heavier impact.
-- Play(character, target, config?) -- same API/config as DeathBallVFX; your config overrides the preset.
local C = require(script.Parent:WaitForChild("VFXCommon"))
local DeathBall = require(script.Parent:WaitForChild("DeathBallVFX"))
local M = {}
M.PRESET = {
	ChargeTime = 1.0, TravelSpeed = 90, BallSize = 10, Height = 4,
	Color = Color3.fromRGB(255, 40, 40), CoreColor = Color3.fromRGB(255, 190, 170), CoronaColor = Color3.fromRGB(255, 90, 60),
	ImpactSize = 40,
}
function M.Play(character, target, config)
	return DeathBall.Play(character, target, C.merge(M.PRESET, config))
end
return M
