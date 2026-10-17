--!nonstrict
-- CrushCannonVFX (Saiyan kit). Caulifla's Crush Cannon: an impatient one-armed blast. Almost no charge, short and wide, hot pink
-- glow over a white core, the fastest beam in the Saiyan kit.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by the
-- shared BeamFX (charge sphere, layered beam, impact, distance-scaled shake).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.STYLE = {
	Core = rgb(255, 240, 250), Glow = rgb(255, 70, 170), Haze = rgb(200, 30, 120), Width = 6, Charge = 0.35,
	Duration = 0.7, Spiral = false, ImpactSize = 30, Shake = 3.2, ChargeAt = "hands", Speed = 620,
}
function M.Play(character: Model, target: any, _config: any?)
	return BeamFX.Play(character, target, M.STYLE)
end
return M
