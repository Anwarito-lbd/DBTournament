--!nonstrict
-- JusticeBlastVFX (Pride Troopers kit). The troopers' default signature shot: a compact sphere, quick charge, fast
-- travel, in the kit's `blast` colours (justice red; Cocotte's swirling Ki Bomb is violet). Thin preset wrapper over
-- DeathBallVFX, like Jiren's PowerImpactVFX but smaller and quicker.
-- Play(character, target, config?) -- same API/config as DeathBallVFX; your config overrides the preset.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local DeathBall = require(VFX:WaitForChild("DeathBallVFX"))
local Kit = require(script.Parent.Parent)
local M = {}
M.PRESET = { ChargeTime = 0.45, TravelSpeed = 150, BallSize = 5, Height = 1, ImpactSize = 28 }
function M.Play(character, target, config)
	local look = Kit.lookFor(Kit.idOf(character), "blast")
	return DeathBall.Play(character, target, C.merge(C.merge(M.PRESET, look), config))
end
return M
