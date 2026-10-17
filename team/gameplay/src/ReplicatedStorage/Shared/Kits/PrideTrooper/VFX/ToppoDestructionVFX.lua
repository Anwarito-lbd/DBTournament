--!nonstrict
-- ToppoDestructionVFX (Pride Troopers kit, Toppo). A dark violet sphere of destruction energy raised overhead and
-- pushed at the target: the God of Destruction's attack. Thin preset wrapper over DeathBallVFX.
-- Play(character, target, config?) -- same API/config as DeathBallVFX; your config overrides the preset.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local DeathBall = require(VFX:WaitForChild("DeathBallVFX"))
local M = {}
M.PRESET = {
	ChargeTime = 1.2,
	TravelSpeed = 70,
	BallSize = 12,
	Height = 8,
	Color = Color3.fromHex("8B3AFF"),
	CoreColor = Color3.fromHex("1A0A2A"),
	CoronaColor = Color3.fromHex("C08AFF"),
	ImpactSize = 50,
}
function M.Play(character, target, config)
	return DeathBall.Play(character, target, C.merge(M.PRESET, config))
end
return M
