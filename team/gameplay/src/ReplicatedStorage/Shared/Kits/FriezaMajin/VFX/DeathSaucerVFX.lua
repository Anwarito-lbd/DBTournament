--!nonstrict
-- DeathSaucerVFX (FriezaMajin kit): Frieza's Death Saucer, his faster copy of the Destructo Disc: a pink saw disc
-- with a gold edge that bends toward the target. Golden Frieza throws two that fan out; Black Frieza's disc is
-- crimson on black. Drawn by the shared DestructoDiscVFX.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local Disc = require(VFX:WaitForChild("DestructoDiscVFX"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.FORMS = {
	Base = { Color = rgb(255, 150, 225), EdgeColor = rgb(255, 240, 128), Speed = 95, Split = 1 },
	Golden = { Color = rgb(255, 215, 90), EdgeColor = rgb(255, 255, 230), Speed = 105, Split = 2 },
	FriezaBlack = { Color = rgb(40, 10, 30), EdgeColor = rgb(220, 40, 100), Speed = 115, Split = 1 },
}

function M.Play(character: Model, target: any, _config: any?)
	local c = table.clone(M.FORMS[FX.form(character) or "Base"] or M.FORMS.Base)
	c.ArenaDamage = false
	return Disc.Play(character, FX.target(character, target), c)
end

return M
