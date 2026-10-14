--!nonstrict
-- GalickGunVFX (Vegeta). Purple variant of KamehamehaVFX (hero_vegeta.md: Color #8A3CFF, Core #F0C8FF).
-- Play(character, target, config?) -- same API/config as KamehamehaVFX; config overrides the preset.
local Kame = require(script.Parent:WaitForChild("KamehamehaVFX"))
local M = {}
M.PRESET = {Color = Color3.fromHex("8A3CFF"), CoreColor = Color3.fromHex("F0C8FF"), ChargeTime = 1.0, BeamWidth = 4.5, BeamSpeed = 450, ArenaRadius = 18, ArenaPower = 120}
function M.Play(character, target, config)
	local c = table.clone(M.PRESET)
	if config then for k, v in pairs(config) do c[k] = v end end
	return Kame.Play(character, target, c)
end
-- v1.1 quality pass: delegate the visible beam to BeamFX (core + glow + spiral, charge sphere, big impact, shake).
-- Legacy implementation kept as M.LegacyPlay.
do
	local BeamFX = require(script.Parent:WaitForChild("BeamFX"))
	M.LegacyPlay = M.Play
	M.Play = function(character, target, config)
		return BeamFX.Play(character, target, "GalickGun", nil)
	end
end
return M
