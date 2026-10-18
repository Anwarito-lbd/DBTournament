--!nonstrict
-- EnergysLastVFX (Earth defenders kit). Shin's Energy's Last on the signature slot: both hands forward charge a purple
-- sphere, released as a straight violet wave. A god's restrained strike: clean edges, no spiral, little debris.
-- Drawn by the shared BeamFX.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local rgb = E.rgb

local M = {}
M.STYLE = {
	Core = rgb(245, 230, 255), Glow = rgb(170, 90, 255), Haze = rgb(110, 40, 220), Width = 5, Charge = 1.0,
	Duration = 1.1, Spiral = false, ImpactSize = 28, Shake = 2.5, ChargeAt = "hands", Speed = 450,
}
function M.Play(character: Model, target: any, _config: any?)
	local to = E.targetPos(character, target)
	if not to then return end
	return BeamFX.Play(character, to, M.STYLE)
end
return M
