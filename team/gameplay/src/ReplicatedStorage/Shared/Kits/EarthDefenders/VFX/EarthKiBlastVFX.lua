--!nonstrict
-- EarthKiBlastVFX (Earth defenders kit): each fighter's plain ki blast in their own colour, on the shared VFXCommon
-- projectile. Ready for the "KiBlast" kind; VFXRouter does not ask kits for that kind yet (KITS.md, needs server
-- work), so until then everyone fires the default blue bolt.
-- Play(character, target, config?) -- client visual only.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLES = {
	u7_piccolo = { Color = rgb(255, 225, 90), Core = rgb(255, 255, 225) }, -- the yellow of his Demon Wave family
	u7_android_17 = { Color = rgb(70, 230, 190), Core = rgb(225, 255, 245) },
	u7_android_18 = { Color = rgb(255, 120, 200), Core = rgb(255, 240, 250) },
	u7_krillin = { Color = rgb(255, 210, 90), Core = rgb(255, 250, 230) },
	u7_tien = { Color = rgb(255, 232, 130), Core = rgb(255, 255, 235) },
	u7_master_roshi = { Color = rgb(110, 190, 255), Core = rgb(235, 248, 255) },
	u7_shin = { Color = rgb(195, 150, 255), Core = rgb(250, 240, 255) },
}

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLES[E.championId(character) or ""] or {}
	return C.KiBlast(character, { Target = if typeof(target) == "Vector3" then target else nil, Color = s.Color,
		Core = s.Core })
end
return M
