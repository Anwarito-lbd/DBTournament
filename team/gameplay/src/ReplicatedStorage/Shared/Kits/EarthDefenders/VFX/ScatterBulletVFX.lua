--!nonstrict
-- ScatterBulletVFX (Earth defenders kit). Krillin's Scattering Bullet: one ki sphere lobbed high over the target that
-- bursts into a ring of small bolts raining down around it. Krillin wins by cleverness, not size.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(255, 200, 80), core = rgb(255, 250, 225), bolts = 8, spread = 9, lift = 14 }

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	local to = E.targetPos(character, target)
	if not root or not to then return end
	local s = M.STYLE
	local f = C.folder("ScatterBulletVFX", 5)
	local apex = to + Vector3.new(0, s.lift, 0)
	E.orb(f, C.hands(character), apex, { size = 1.8, color = s.color, core = s.core, speed = 120, arc = 6 }, function(p)
		E.burst(f, p, 7, s.color, s.core, 0, 0.15)
		for i = 1, C.q(s.bolts) do
			local ang = (i / s.bolts) * math.pi * 2
			local land = to + Vector3.new(math.cos(ang) * s.spread * math.random(5, 10) / 10, 0,
				math.sin(ang) * s.spread * math.random(5, 10) / 10)
			task.delay(i * 0.04, function()
				E.orb(f, p, land, { size = 0.9, color = s.color, core = s.core, speed = 110 }, function(q)
					E.burst(f, q, 6, s.color, s.core, 2, 0.12)
				end)
			end)
		end
	end)
end
return M
