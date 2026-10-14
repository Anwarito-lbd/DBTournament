--!nonstrict
-- BigBangAttackVFX (Vegeta). Single-palm blue-white orb, short pause, fast large sphere -> huge spherical explosion.
-- Wrapper over DeathBallVFX (sphere + travel). Play(character, target, config?).
local C = require(script.Parent:WaitForChild("VFXCommon"))
local DeathBall = require(script.Parent:WaitForChild("DeathBallVFX"))
local M = {}
M.PRESET = {ChargeTime = 0.6, TravelSpeed = 160, BallSize = 6, Height = 0.5, ImpactSize = 45,
	Color = Color3.fromHex("9FD8FF"), CoreColor = Color3.fromRGB(255, 255, 255), CoronaColor = Color3.fromHex("CDEBFF")}
function M.Play(character, target, config) return DeathBall.Play(character, target, C.merge(M.PRESET, config)) end
return M
