--!nonstrict
-- TriBeamVFX (Earth defenders kit). Tien's Tri-Beam on the signature slot: thumbs and fingers form a triangle, the
-- target is framed through it, and a wide pale-gold pressure beam crushes down into the ground, leaving a deep
-- crater ring rather than a fireball. The beam itself is the shared BeamFX in Tien's colours.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = {
	Core = rgb(255, 255, 225), Glow = rgb(255, 226, 90), Haze = rgb(255, 178, 60), Width = 6.5, Charge = 1.0,
	Duration = 1.0, Spiral = false, ImpactSize = 36, Shake = 4, ChargeAt = "hands", Speed = 520,
}
M.CRATER = { radius = 16, rings = 3, color = rgb(255, 214, 110) }

-- the crater: concentric rings pressed down into the ground and a wide crack, read as weight from above
local function crater(pos: Vector3)
	local f = C.folder("TriBeamCrater", 4)
	local g = E.ground(pos, { f }) or pos
	for i = 1, M.CRATER.rings do
		task.delay((i - 1) * 0.08, function()
			C.Shockwave(f, CFrame.new(g + Vector3.new(0, 0.2, 0)), 2, M.CRATER.radius * (0.6 + 0.4 * i), M.CRATER.color, 0.5)
		end)
	end
	C.GroundCrack(f, g, M.CRATER.radius, 16, M.CRATER.color, 3)
	C.DebrisBurst(f, g, C.q(14), 30, nil, 2.2)
	E.shakeNear(g, 0.7)
end

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	local to = E.targetPos(character, target)
	if not root or not to then return end
	BeamFX.Play(character, to, M.STYLE)
	local travel = (to - root.Position).Magnitude / M.STYLE.Speed
	task.delay(M.STYLE.Charge + travel, crater, to)
end
return M
