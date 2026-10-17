--!nonstrict
-- EraserCannonVFX (Saiyan kit). Kale's Eraser Cannon: a green sphere pushed from one palm. Shorter charge than Frieza's Death
-- Ball, faster travel, wide green explosion dome.
-- Play(character, target, config?) -- client visual only; drawn by the shared DeathBallVFX (sphere + travel +
-- impact). ArenaDamage stays false whatever the caller passes.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local DeathBall = require(VFX:WaitForChild("DeathBallVFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.PRESET = {
	ChargeTime = 0.9, TravelSpeed = 120, BallSize = 8, Height = 1, ImpactSize = 50,
	Color = rgb(90, 255, 90), CoreColor = rgb(230, 255, 220), CoronaColor = rgb(160, 255, 120),
}
function M.Play(character: Model, target: any, config: any?)
	local c = C.merge(M.PRESET, config)
	c.ArenaDamage = false
	return DeathBall.Play(character, target, c)
end
return M
