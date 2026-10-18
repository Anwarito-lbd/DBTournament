--!nonstrict
-- LightGrenadeVFX (Earth defenders kit). Piccolo's Light Grenade, a variation of his Explosive Demon Wave: both hands
-- pressed together in front of him gather a yellow sphere, the hands push forward and the sphere flies straight and
-- heavy into a wide yellow explosion.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(255, 220, 60), core = rgb(255, 255, 215), charge = 0.45, size = 2.6, speed = 160, blast = 22 }

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	local to = E.targetPos(character, target)
	if not root or not to then return end
	local s = M.STYLE
	local f = C.folder("LightGrenadeVFX", s.charge + 4)
	task.spawn(function()
		-- gather: a small sphere swelling between the palms, motes drawn inward
		local hands = C.hands(character) + root.CFrame.LookVector * 1.5
		local orb = C.part(f, Vector3.one * 0.4, s.core, Enum.PartType.Ball)
		orb.Position = hands
		local glow = C.part(f, Vector3.one * 0.8, s.color, Enum.PartType.Ball, 0.45)
		glow.Position = hands
		C.light(orb, s.color, 10, 3)
		local a = Instance.new("Attachment")
		a.Parent = orb
		local motes = C.emitter(a, s.core, s.color, { Rate = 50, Lifetime = NumberRange.new(0.2, 0.3),
			Speed = NumberRange.new(-12, -8), Size = NumberSequence.new(0.4, 0), SpreadAngle = Vector2.new(180, 180) })
		C.tween(orb, s.charge, { Size = Vector3.one * s.size })
		C.tween(glow, s.charge, { Size = Vector3.one * s.size * 1.7 })
		task.wait(s.charge)
		motes.Enabled = false
		local from = orb.Position
		orb:Destroy()
		glow:Destroy()
		E.orb(f, from, to, { size = s.size, color = s.color, core = s.core, speed = s.speed }, function(p)
			E.burst(f, p, s.blast, s.color, s.core, 9, 0.6)
		end)
	end)
end
return M
