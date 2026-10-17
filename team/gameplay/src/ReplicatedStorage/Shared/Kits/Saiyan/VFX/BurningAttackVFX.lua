--!nonstrict
-- BurningAttackVFX (Saiyan kit). Future Trunks' Burning Attack: after the run of hand signs, a small fast orange-gold sphere
-- from the palm diamond and a sharp explosion. Small and quick next to Kale's or Broly's spheres.
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
	ChargeTime = 0.5, TravelSpeed = 210, BallSize = 4.5, Height = 0.5, ImpactSize = 40,
	Color = rgb(255, 180, 50), CoreColor = rgb(255, 255, 230), CoronaColor = rgb(255, 225, 140),
}
function M.Play(character: Model, target: any, config: any?)
	local c = C.merge(M.PRESET, config)
	c.ArenaDamage = false
	return DeathBall.Play(character, target, c)
end
return M
