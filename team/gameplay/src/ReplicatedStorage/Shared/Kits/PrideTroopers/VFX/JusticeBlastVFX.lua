--!nonstrict
-- JusticeBlastVFX (Pride Troopers kit). The troopers' signature ki shot: a compact red-and-white sphere, quick charge,
-- fast travel. Thin preset wrapper over DeathBallVFX, like Jiren's PowerImpactVFX but smaller and quicker.
-- Play(character, target, config?) -- same API/config as DeathBallVFX; your config overrides the preset.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local DeathBall = require(VFX:WaitForChild("DeathBallVFX"))
local M = {}
M.PRESET = {
	ChargeTime = 0.45,
	TravelSpeed = 150,
	BallSize = 5,
	Height = 1,
	Color = Color3.fromRGB(235, 60, 60),
	CoreColor = Color3.fromRGB(255, 245, 240),
	CoronaColor = Color3.fromRGB(255, 130, 120),
	ImpactSize = 28,
}
function M.Play(character, target, config)
	return DeathBall.Play(character, target, C.merge(M.PRESET, config))
end
return M
