--!nonstrict
-- NeoTriBeamVFX (Earth defenders kit). Tien's Neo Tri-Beam: the triangle held, then short Tri-Beams fired one after
-- another, each a little dimmer, as the technique spends his own strength (see KITS.md for the server-side cost).
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local rgb = E.rgb

local M = {}
M.PULSES = 3
M.GAP = 0.28
M.STYLE = {
	Core = rgb(255, 255, 225), Glow = rgb(255, 226, 90), Haze = rgb(255, 178, 60), Width = 4, Charge = 0.15,
	Duration = 0.22, Spiral = false, ImpactSize = 18, Shake = 1.5, ChargeAt = "hands", Speed = 900,
}

function M.Play(character: Model, target: any, _config: any?)
	local to = E.targetPos(character, target)
	if not to then return end
	for i = 1, M.PULSES do
		task.delay((i - 1) * M.GAP, function()
			if not character.Parent then return end
			local fade = 1 - (i - 1) * 0.15
			BeamFX.Play(character, to, M.STYLE, { Width = M.STYLE.Width * fade, ImpactSize = M.STYLE.ImpactSize * fade })
		end)
	end
end
return M
