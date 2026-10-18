--!nonstrict
-- JusticeSpinVFX (Pride Troopers kit, Zoiray and Tupper). A spinning whirlwind: stacked rings whip around the fighter
-- for the spin's duration in the kit's `spin` look (Zoiray's pale-red Justice Spin; Tupper's stone wheel with a
-- burning core that throws debris). Play(character, _target, config?). Visual only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C = require(ReplicatedStorage:WaitForChild("VFX"):WaitForChild("VFXCommon"))
local Kit = require(script.Parent.Parent)
local M = {}
M.STEP = 0.08 -- seconds between rings
function M.Play(character, _target, config)
	local c = C.merge(Kit.lookFor(Kit.idOf(character), "spin"), config)
	if not C.root(character) then
		return
	end
	local f = C.folder("JusticeSpinVFX", c.Duration + 1)
	task.spawn(function()
		local t0 = os.clock()
		local i = 0
		while os.clock() - t0 < c.Duration do
			local r = C.root(character)
			if not r then
				break
			end
			i += 1
			local tilt = CFrame.Angles(math.rad(if i % 2 == 0 then 12 else -12), math.rad(i * 37), 0)
			C.Shockwave(f, CFrame.new(r.Position) * tilt, 3, c.Radius * 2, c.Color, 0.25, 0.25)
			if i % 3 == 0 then
				C.Shockwave(f, CFrame.new(r.Position), 1, c.Radius, c.CoreColor, 0.2, 0.15)
			end
			task.wait(M.STEP)
		end
		local r = C.root(character)
		if r and c.Debris then
			C.DebrisBurst(f, r.Position - Vector3.new(0, 3, 0), 10, 30, c.Color, 2)
		end
	end)
end
return M
