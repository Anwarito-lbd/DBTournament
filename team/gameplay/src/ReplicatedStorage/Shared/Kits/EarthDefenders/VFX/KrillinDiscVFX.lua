--!nonstrict
-- KrillinDiscVFX (Earth defenders kit). Krillin's Destructo Disc on the signature slot: a flat razor disc of golden ki
-- raised overhead and thrown, curving onto the target. The shared DestructoDiscVFX draws it (its defaults are
-- Frieza's pink); this wrapper gives it Krillin's gold and a slightly larger, slower disc he steers in.
-- Play(character, target, config?) -- client visual only (ArenaDamage = false).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local Disc = require(VFX:WaitForChild("DestructoDiscVFX"))

local M = {}
M.CONFIG = {
	Color = Color3.fromRGB(255, 214, 70),
	EdgeColor = Color3.fromRGB(255, 255, 220),
	Size = 5.5,
	Speed = 75,
	Homing = 3.5,
	Split = 1,
	ArenaDamage = false,
}
function M.Play(character: Model, target: any, _config: any?)
	return Disc.Play(character, target, M.CONFIG)
end
return M
