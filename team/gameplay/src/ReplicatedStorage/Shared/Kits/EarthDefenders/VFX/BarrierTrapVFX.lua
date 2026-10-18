--!nonstrict
-- BarrierTrapVFX (Earth defenders kit). Android 17's signature on the beam slot, from his Tournament of Power tricks
-- with the Android Barrier: a teal ki shot lands, a small barrier closes around the target for a beat, then bursts
-- inward-out. A ranger's trap, not a cannon.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(70, 230, 190), core = rgb(220, 255, 245), radius = 5.5, hold = 0.35, blast = 18 }

function M.Play(character: Model, target: any, _config: any?)
	local to = E.targetPos(character, target)
	if not to then return end
	local s = M.STYLE
	local f = C.folder("BarrierTrapVFX", s.hold + 4)
	E.orb(f, C.hands(character), to, { size = 1.2, color = s.color, core = s.core, speed = 260 }, function(p)
		-- the cage: a force-field sphere snapping shut around the hit, with an edge ring
		local cage = C.part(f, Vector3.one * s.radius * 3, s.color, Enum.PartType.Ball, 0.85)
		cage.Material = Enum.Material.ForceField
		cage.Position = p
		C.tween(cage, 0.15, { Size = Vector3.one * s.radius * 2, Transparency = 0.6 })
		C.Shockwave(f, CFrame.new(p), s.radius * 3, s.radius * 2, s.core, 0.15)
		task.delay(s.hold, function()
			cage:Destroy()
			E.burst(f, p, s.blast, s.color, s.core, 6, 0.5)
		end)
	end)
end
return M
