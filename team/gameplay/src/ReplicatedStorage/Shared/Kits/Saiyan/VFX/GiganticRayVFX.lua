--!nonstrict
-- GiganticRayVFX (Saiyan kit). Kefla's Gigantic Ray: a wide yellow-green ray from both palms, Caulifla's speed with Kale's
-- size. Spiralled, thick, and a big impact.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by the
-- shared BeamFX (charge sphere, layered beam, impact, distance-scaled shake).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.STYLE = {
	Core = rgb(245, 255, 220), Glow = rgb(170, 255, 60), Haze = rgb(80, 200, 40), Width = 7, Charge = 0.9,
	Duration = 1.4, Spiral = true, ImpactSize = 40, Shake = 4.2, ChargeAt = "hands", Speed = 460,
}
function M.Play(character: Model, target: any, _config: any?)
	return BeamFX.Play(character, target, M.STYLE)
end
return M
