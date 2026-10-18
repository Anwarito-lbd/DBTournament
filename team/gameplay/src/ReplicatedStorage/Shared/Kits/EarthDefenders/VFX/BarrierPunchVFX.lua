--!nonstrict
-- BarrierPunchVFX (Earth defenders kit). Android 17's barrier-wrapped strike: a fist sheathed in a tight Android
-- Barrier shell, which flares and pops on contact and throws a teal ring off the hit.
-- Play(character, target, config?) -- client visual only; target is the server's hit position.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(70, 230, 190), core = rgb(220, 255, 245), shell = 3.2, ring = 16 }

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local s = M.STYLE
	local pos = if typeof(target) == "Vector3" then target else root.Position + root.CFrame.LookVector * 4
	local f = C.folder("BarrierPunchVFX", 2)
	local shell = C.part(f, Vector3.one * s.shell, s.color, Enum.PartType.Ball, 0.5)
	shell.Material = Enum.Material.ForceField
	shell.Position = pos
	C.tween(shell, 0.25, { Size = Vector3.one * s.shell * 2.4, Transparency = 1 })
	C.Shockwave(f, CFrame.lookAt(pos, pos + root.CFrame.LookVector) * CFrame.Angles(math.rad(90), 0, 0), 2, s.ring,
		s.color, 0.35)
	E.burst(f, pos, 8, s.color, s.core, 0, 0.3)
end
return M
