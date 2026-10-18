--!nonstrict
-- KiaiEyeBlastVFX (Earth defenders kit). Shin's Invisible Eye Blast, a Kiai fired from the eyes: nothing visible
-- leaves him except a brief flare at the eyes, then rings of displaced air race to the target and burst there.
-- Play(character, target, config?) -- client visual only; the server already resolved the hit.
local RunService = game:GetService("RunService")
local E = require(script.Parent:WaitForChild("EarthFX"))
local C = E.C
local rgb = E.rgb

local M = {}
M.STYLE = { color = rgb(230, 220, 255), rings = 4, speed = 300, size = 6 }

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	local to = E.targetPos(character, target)
	if not root or not to then return end
	local s = M.STYLE
	local head = C.limb(character, { "Head" })
	local from = head.Position + root.CFrame.LookVector * 1
	local dir = C.direction(from, to)
	local dist = (to - from).Magnitude
	local f = C.folder("KiaiEyeBlastVFX", dist / s.speed + 2)
	local flare = C.part(f, Vector3.new(1.4, 0.3, 0.3), s.color, nil, 0.2)
	flare.CFrame = CFrame.lookAt(from, from + dir)
	C.tween(flare, 0.2, { Transparency = 1, Size = Vector3.new(2.4, 0.05, 0.05) })
	for i = 1, s.rings do
		task.delay((i - 1) * 0.05, function()
			-- a near-invisible ring flying down the line: the air itself moving
			local ring = C.part(f, Vector3.new(0.2, s.size * 0.4, s.size * 0.4), s.color, Enum.PartType.Cylinder, 0.8)
			local t0, life = os.clock(), dist / s.speed
			while true do
				local k = math.min(1, (os.clock() - t0) / life)
				local p = from + dir * dist * k
				ring.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, math.rad(90), 0)
				ring.Size = Vector3.new(0.2, s.size * (0.4 + k), s.size * (0.4 + k))
				if k >= 1 then break end
				RunService.Heartbeat:Wait()
			end
			ring:Destroy()
		end)
	end
	task.delay(dist / s.speed, function()
		C.Shockwave(f, CFrame.lookAt(to, to + dir) * CFrame.Angles(math.rad(90), 0, 0), 2, s.size * 3, s.color, 0.35)
		E.shakeNear(to, 0.35)
	end)
end
return M
