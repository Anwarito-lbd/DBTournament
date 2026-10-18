--!nonstrict
-- EarthHeavyVFX (Earth defenders kit): the contact flourish on each fighter's Heavy (guard-break) strike. VFXRouter
-- plays it for the "Heavy" move kind with the server's hit position. One module, one look per fighter (STYLES), so a
-- Tien chop and a Shin palm read differently at a glance. World effects only: the striker's own camera kick comes
-- from the kit's cameras.Heavy, other clients get a distance-scaled shake.
-- Play(character, target, config?) -- client visual only; never deals damage.
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}

-- color/core: burst colours; size: reach (studs); rings: extra rings; crack: ground crack radius (0 = none);
-- debris: rock count; afterimage: smear colour (nil = none); shell: a barrier flare instead of a plain flash
M.STYLES = {
	-- Piccolo: a heavy forearm with weighted-cape weight behind it: pale green ring, a short crack
	u7_piccolo = { color = rgb(190, 255, 170), core = rgb(245, 255, 240), size = 14, rings = 1, crack = 6, debris = 6 },
	-- Android 17: the barrier wrapped around the blow
	u7_android_17 = { color = rgb(70, 230, 190), core = rgb(220, 255, 245), size = 13, rings = 1, crack = 0, debris = 3,
		shell = true },
	-- Android 18: a clean kick, pink double ring and an afterimage, nothing wasted
	u7_android_18 = { color = rgb(255, 120, 200), core = rgb(255, 240, 250), size = 12, rings = 2, crack = 0, debris = 2,
		afterimage = rgb(255, 180, 225) },
	-- Krillin: small and quick, a gold ring
	u7_krillin = { color = rgb(255, 214, 90), core = rgb(255, 250, 225), size = 10, rings = 1, crack = 0, debris = 3,
		afterimage = rgb(255, 230, 160) },
	-- Tien: raw strength, the biggest crack on the team
	u7_tien = { color = rgb(255, 228, 140), core = rgb(255, 255, 235), size = 16, rings = 2, crack = 10, debris = 12 },
	-- Master Roshi: an old master's open palm, a pale-blue ring and a gust, no wasted destruction
	u7_master_roshi = { color = rgb(150, 205, 255), core = rgb(235, 248, 255), size = 15, rings = 2, crack = 4,
		debris = 5 },
	-- Shin: a god's palm, a lavender ripple, never a crack
	u7_shin = { color = rgb(200, 160, 255), core = rgb(250, 240, 255), size = 12, rings = 2, crack = 0, debris = 0 },
}
M.DEFAULT = { color = rgb(255, 235, 170), core = rgb(255, 255, 255), size = 12, rings = 1, crack = 0, debris = 4 }

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local s = M.STYLES[E.championId(character) or ""] or M.DEFAULT
	local pos = if typeof(target) == "Vector3" then target else root.Position + root.CFrame.LookVector * 4
	local f = C.folder("EarthHeavyVFX", 3)
	if s.afterimage then C.Afterimage(character, s.afterimage, 0.35, 0.4) end
	if s.shell then
		local shell = C.part(f, Vector3.one * 3, s.color, Enum.PartType.Ball, 0.45)
		shell.Material = Enum.Material.ForceField
		shell.Position = pos
		C.tween(shell, 0.3, { Size = Vector3.one * s.size * 0.8, Transparency = 1 })
	end
	E.burst(f, pos, s.size * 0.6, s.color, s.core, s.crack, 0.3 + s.size / 60)
	for i = 1, s.rings do
		task.delay(i * 0.07, function()
			C.Shockwave(f, CFrame.new(pos), 2, s.size * (1 + 0.4 * i), if i % 2 == 0 then s.core else s.color, 0.4)
		end)
	end
	if s.debris > 0 then
		local g = E.ground(pos, { character, f })
		if g then C.DebrisBurst(f, g, C.q(s.debris), 20 + s.size, nil, 1.8) end
	end
end
return M
