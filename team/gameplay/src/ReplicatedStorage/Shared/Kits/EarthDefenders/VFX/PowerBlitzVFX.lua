--!nonstrict
-- PowerBlitzVFX (Earth defenders kit). Android 18's Power Blitz on the signature slot: one hand drawn back charges a
-- swirling pink-and-blue sphere, then a narrow, fast beam is thrown from that hand. Quick and unbothered: no long
-- charge, because her ki never runs out. Drawn by the shared BeamFX from the right hand.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local rgb = E.rgb

local M = {}
M.STYLE = {
	Core = rgb(255, 240, 250), Glow = rgb(255, 110, 200), Haze = rgb(90, 160, 255), Width = 3.5, Charge = 0.6,
	Duration = 0.9, Spiral = true, ImpactSize = 24, Shake = 2.5, ChargeAt = "finger", Speed = 620,
}
function M.Play(character: Model, target: any, _config: any?)
	local to = E.targetPos(character, target)
	if not to then return end
	return BeamFX.Play(character, to, M.STYLE)
end
return M
