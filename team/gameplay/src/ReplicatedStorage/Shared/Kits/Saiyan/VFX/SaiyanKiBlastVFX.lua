--!nonstrict
-- SaiyanKiBlastVFX (Saiyan kit): each Saiyan's plain ki blast in their own colour (Goku sky blue, Vegeta gold,
-- Broly and Kale green, Goku Black rose...). Same cheap projectile as VFXCommon.KiBlast, which this calls.
-- NOTE: VFXRouter currently draws every "KiBlast" with the shared projectile before consulting kits, so this module
-- only plays once the router asks Kits.signature(id, "KiBlast") first (listed in KITS.md "needs server work").
-- Play(character, target, config?) -- client visual only.
local Players = game:GetService("Players")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}

-- Color = glow and trail, Core = bolt centre, Speed in studs/s
M.COLORS = {
	u7_goku = { Color = rgb(120, 200, 255), Core = rgb(255, 255, 255), Speed = 190 },
	u7_vegeta = { Color = rgb(255, 215, 80), Core = rgb(255, 255, 230), Speed = 200 },
	u7_gohan = { Color = rgb(255, 230, 110), Core = rgb(255, 255, 240), Speed = 185 },
	u7_trunks = { Color = rgb(255, 190, 70), Core = rgb(255, 250, 230), Speed = 200 },
	u7_broly = { Color = rgb(80, 255, 110), Core = rgb(225, 255, 225), Speed = 150 },
	u6_cabba = { Color = rgb(150, 120, 255), Core = rgb(240, 235, 255), Speed = 195 },
	u6_caulifla = { Color = rgb(255, 90, 180), Core = rgb(255, 235, 245), Speed = 220 },
	u6_kale = { Color = rgb(110, 255, 100), Core = rgb(230, 255, 220), Speed = 160 },
	u6_kefla = { Color = rgb(190, 255, 70), Core = rgb(250, 255, 220), Speed = 210 },
	u10_goku_black = { Color = rgb(255, 70, 160), Core = rgb(255, 225, 240), Speed = 200 },
}

function M.Play(character: Model, target: any, _config: any?)
	local pl = Players:GetPlayerFromCharacter(character)
	local id = (pl and pl:GetAttribute("Character")) or character:GetAttribute("Character")
		or character:GetAttribute("ChampionModel")
	local c = (type(id) == "string" and M.COLORS[id]) or M.COLORS.u7_goku
	return C.KiBlast(character, {
		Target = if typeof(target) == "Vector3" then target else nil,
		Color = c.Color,
		Core = c.Core,
		Speed = c.Speed,
	})
end

return M
