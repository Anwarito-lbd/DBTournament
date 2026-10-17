--!nonstrict
-- GiganticRoarVFX (Saiyan kit). Broly's Gigantic Roar: the widest, slowest beam in the kit, bright green on a pale core. Long
-- charge, long duration, the biggest impact; it should look like a force of nature, not a technique.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by the
-- shared BeamFX (charge sphere, layered beam, impact, distance-scaled shake).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.STYLE = {
	Core = rgb(230, 255, 230), Glow = rgb(60, 255, 110), Haze = rgb(20, 160, 60), Width = 10, Charge = 1.3,
	Duration = 1.8, Spiral = true, ImpactSize = 52, Shake = 5.5, ChargeAt = "hands", Speed = 340,
}
function M.Play(character: Model, target: any, _config: any?)
	return BeamFX.Play(character, target, M.STYLE)
end
return M
