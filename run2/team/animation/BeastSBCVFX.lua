--!nonstrict
-- BeastSBCVFX (Beast Gohan signature: red-tinted Special Beam Cannon, faster charge, thicker spiral).
local C = require(script.Parent:WaitForChild("VFXCommon"))
local SBC = require(script.Parent:WaitForChild("SpecialBeamCannonVFX"))
local M = {}
M.PRESET = {ChargeTime = 1.2, BeamSpeed = 900, CoreWidth = 1.2, SpiralRadius = 2.8, SpiralSegments = 90, ImpactSize = 22,
	Color = Color3.fromRGB(255, 70, 80), SpiralColor = Color3.fromRGB(255, 30, 50), CoreColor = Color3.fromRGB(255, 255, 255)}
function M.Play(character, target, config) return SBC.Play(character, target, C.merge(M.PRESET, config)) end
return M
