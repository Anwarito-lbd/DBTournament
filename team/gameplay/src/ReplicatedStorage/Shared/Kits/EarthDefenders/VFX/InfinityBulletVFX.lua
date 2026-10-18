--!nonstrict
-- InfinityBulletVFX (Earth defenders kit). Android 18's Infinity Bullet, the rapid-fire form of her Power Blitz: an
-- unbroken stream of pink ki bolts from alternating hands, each popping on the target. The point is volume, which an
-- infinite-energy android can afford.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(255, 110, 200), core = rgb(255, 240, 250), bolts = 10, gap = 0.06, speed = 220, jitter = 2.5 }

function M.Play(character: Model, target: any, _config: any?)
	local to = E.targetPos(character, target)
	if not to then return end
	local s = M.STYLE
	local f = C.folder("InfinityBulletVFX", s.bolts * s.gap + 3)
	for i = 1, C.q(s.bolts) do
		task.delay((i - 1) * s.gap, function()
			if not character.Parent then return end
			local aim = to + Vector3.new(math.random(-10, 10), math.random(-6, 10), math.random(-10, 10)) / 10 * s.jitter
			C.KiBlast(character, { Target = aim, Color = s.color, Core = s.core, Speed = s.speed })
			local root = C.root(character)
			local travel = if root then (aim - root.Position).Magnitude / s.speed else 0.2
			task.delay(travel, function()
				E.burst(f, aim, 5, s.color, s.core, 0, 0.08)
			end)
		end)
	end
end
return M
