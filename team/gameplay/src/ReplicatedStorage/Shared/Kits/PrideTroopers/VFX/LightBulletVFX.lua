--!nonstrict
-- LightBulletVFX (Pride Troopers kit, Dyspo). Light Bullet: a burst of afterimage strikes around the target, faster
-- and fewer than Goku's rush, in the kit's `rush` look. Wrapper over MUIRushVFX.
-- Play(character, target, config?). Visual only (movement and damage are the server's).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VFX = ReplicatedStorage:WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local Rush = require(VFX:WaitForChild("MUIRushVFX"))
local Kit = require(script.Parent.Parent)
local M = {}
function M.Play(character, target, config)
	return Rush.Play(character, target, C.merge(Kit.lookFor(Kit.idOf(character), "rush"), config))
end
return M
