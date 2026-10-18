--!nonstrict
-- MaxKamehamehaVFX (Earth defenders kit). Master Roshi's MAX Power Kamehameha, the original Kamehameha at full output:
-- his body swells to Max Power (a ring blown off his feet as the muscles bulk), the cupped hands draw back, and a
-- wider, heavier blue wave than any student's leaves. Drawn by the shared BeamFX.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = {
	Core = rgb(235, 250, 255), Glow = rgb(70, 160, 255), Haze = rgb(30, 80, 230), Width = 8, Charge = 1.2,
	Duration = 1.5, Spiral = true, ImpactSize = 44, Shake = 4.5, ChargeAt = "hands", Speed = 380,
}

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	local to = E.targetPos(character, target)
	if not root or not to then return end
	-- the bulk-up: one ring off the ground and a puff of debris as Max Power arrives
	local f = C.folder("MaxPowerBulk", 3)
	local g = E.ground(root.Position, { character, f }) or (root.Position - Vector3.new(0, 3, 0))
	C.Shockwave(f, CFrame.new(g), 2, 22, M.STYLE.Glow, 0.5)
	C.DebrisBurst(f, g, C.q(8), 24, nil, 1.8)
	E.shakeNear(g, 0.35)
	BeamFX.Play(character, to, M.STYLE)
end
return M
