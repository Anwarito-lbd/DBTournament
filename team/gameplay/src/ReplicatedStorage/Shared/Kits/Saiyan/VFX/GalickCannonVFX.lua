--!nonstrict
-- GalickCannonVFX (Saiyan kit). Cabba's Galick Cannon: Vegeta's purple beam as his student fires it. Faster and thinner than the
-- prince's Galick Gun, cooler violet-blue, no spiral: disciplined and clean rather than overwhelming.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by the
-- shared BeamFX (charge sphere, layered beam, impact, distance-scaled shake).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.STYLE = {
	Core = rgb(235, 228, 255), Glow = rgb(125, 95, 255), Haze = rgb(60, 40, 200), Width = 4, Charge = 0.7,
	Duration = 1.0, Spiral = false, ImpactSize = 26, Shake = 2.6, ChargeAt = "hands", Speed = 520,
}
function M.Play(character: Model, target: any, _config: any?)
	return BeamFX.Play(character, target, M.STYLE)
end
return M
