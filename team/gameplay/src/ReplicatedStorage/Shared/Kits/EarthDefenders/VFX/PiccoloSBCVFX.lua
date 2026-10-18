--!nonstrict
-- PiccoloSBCVFX (Earth defenders kit). Piccolo's Special Beam Cannon on the signature-beam slot: two fingers at the
-- forehead gather crackling ki, then a thin straight core with a second beam coiled around it drills through the
-- target. The shared SpecialBeamCannonVFX draws it; this wrapper tunes it to the server's beam timing (its own
-- two-second charge would land after the server has already resolved the hit) and keeps it visual only.
-- Play(character, target, config?) -- client visual only (ArenaDamage = false).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local SBC = require(VFX:WaitForChild("SpecialBeamCannonVFX"))

local M = {}
M.CONFIG = {
	ChargeTime = 1.3, -- still the longest charge on the team: the beam's weakness is the wait
	BeamTime = 0.8,
	CoreWidth = 0.7,
	SpiralRadius = 2.0,
	Color = Color3.fromRGB(255, 232, 120),
	SpiralColor = Color3.fromRGB(240, 110, 230),
	CoreColor = Color3.fromRGB(255, 255, 230),
	ImpactSize = 16,
	ArenaDamage = false,
}
function M.Play(character: Model, target: any, _config: any?)
	return SBC.Play(character, target, M.CONFIG)
end
return M
