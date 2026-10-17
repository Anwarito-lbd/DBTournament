--!nonstrict
-- DragonFistVFX (Saiyan kit, Goku's DragonFist kit move): Goku drives through the target with one fist and the
-- energy coils up off the impact like a golden dragon. Built from VFXCommon primitives: a lunge streak of
-- afterimages, a gold impact, then a rising helix of glowing beads that fades out above the hit point.
-- Play(character, target, config?) -- client visual only; never deals damage.
local RunService = game:GetService("RunService")
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))

local M = {}
M.GOLD = Color3.fromRGB(255, 200, 60)
M.CORE = Color3.fromRGB(255, 250, 220)
M.BEADS = 26 -- helix segments
M.RISE = 26 -- studs the coil climbs
M.TIME = 0.9 -- seconds for the coil to climb

function M.Play(character: Model, target: any, _config: any?)
	local root = C.root(character)
	if not root then return end
	local pos = if typeof(target) == "Vector3" then target else root.Position + root.CFrame.LookVector * 6
	local f = C.folder("DragonFist", M.TIME + 2)
	C.Afterimage(character, M.GOLD, 0.35, 0.3)
	task.delay(0.05, function() C.Afterimage(character, M.CORE, 0.3, 0.5) end)
	C.Shockwave(f, CFrame.lookAt(pos, pos + root.CFrame.LookVector) * CFrame.Angles(math.rad(90), 0, 0), 1, 14,
		M.CORE, 0.3, 0.3)
	C.Shockwave(f, CFrame.new(pos), 2, 22, M.GOLD, 0.45)
	local flash = C.part(f, Vector3.one * 3, M.CORE, Enum.PartType.Ball, 0.2)
	flash.Position = pos
	C.light(flash, M.GOLD, 18, 4)
	C.tween(flash, 0.4, { Transparency = 1, Size = Vector3.one * 9 })
	-- the coil: beads placed along a helix that climbs from the hit point, each fading as it is passed
	local beads = {}
	for i = 1, C.q(M.BEADS) do
		local b = C.part(f, Vector3.one * (1.6 - i * 0.03), if i % 3 == 0 then M.CORE else M.GOLD, Enum.PartType.Ball, 1)
		beads[i] = b
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / M.TIME, 0, 1)
		for i, b in beads do
			local u = i / #beads
			if u <= k then
				local a = u * math.pi * 5
				local r = 4 * (1 - u * 0.6)
				b.Position = pos + Vector3.new(math.cos(a) * r, u * M.RISE, math.sin(a) * r)
				b.Transparency = 0.1 + 0.9 * math.clamp((k - u) * 2.5, 0, 1)
			end
		end
		if k >= 1 then
			conn:Disconnect()
			for _, b in beads do C.tween(b, 0.3, { Transparency = 1 }) end
		end
	end)
end

return M
