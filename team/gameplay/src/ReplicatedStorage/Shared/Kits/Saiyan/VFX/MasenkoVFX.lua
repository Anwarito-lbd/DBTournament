--!nonstrict
-- MasenkoVFX (Saiyan kit). Gohan's Masenko: a gold-yellow beam thrown from both palms over the head. Quick to charge (he was
-- taught to strike first), narrower than a Kamehameha, bright yellow core with an orange haze.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false); drawn by the
-- shared BeamFX (charge sphere, layered beam, impact, distance-scaled shake).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local M = {}
M.STYLE = {
	Core = rgb(255, 255, 225), Glow = rgb(255, 214, 60), Haze = rgb(255, 140, 30), Width = 4.5, Charge = 0.8,
	Duration = 1.1, Spiral = false, ImpactSize = 30, Shake = 3, ChargeAt = "hands", Speed = 480,
}
function M.Play(character: Model, target: any, _config: any?)
	return BeamFX.Play(character, target, M.STYLE)
end
return M
