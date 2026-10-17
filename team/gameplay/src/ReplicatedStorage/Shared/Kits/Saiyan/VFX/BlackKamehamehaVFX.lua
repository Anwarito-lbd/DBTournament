--!nonstrict
-- BlackKamehamehaVFX (Saiyan kit). Goku Black's Black Kamehameha: Goku's own beam turned against him. Same cupped-hands shape and
-- timing as the Kamehameha, but a rose glow over a near-black haze, with a pink-white core.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by the
-- shared BeamFX (charge sphere, layered beam, impact, distance-scaled shake).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.STYLE = {
	Core = rgb(255, 225, 240), Glow = rgb(255, 70, 160), Haze = rgb(60, 10, 50), Width = 5.5, Charge = 1.0,
	Duration = 1.4, Spiral = true, ImpactSize = 36, Shake = 3.8, ChargeAt = "hands", Speed = 430,
}
function M.Play(character: Model, target: any, _config: any?)
	return BeamFX.Play(character, target, M.STYLE)
end
return M
