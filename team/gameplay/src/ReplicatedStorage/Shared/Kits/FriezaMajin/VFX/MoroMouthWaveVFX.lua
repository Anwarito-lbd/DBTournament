--!nonstrict
-- MoroMouthWaveVFX (FriezaMajin kit): Moro's signature slot is the Mouth Energy Wave, the blast he used on Buu and
-- on Ultra Instinct Goku. Energy is pulled in from the ground around him first (green motes rising, his own
-- purple glow at the jaw), then the wave leaves his mouth: a ragged purple-green beam with a dark outer haze.
-- Played from the head, not the hands, so it never reads as a Kamehameha.
-- Play(character, target, config?) -- client visual only (VFXRouter passes ArenaDamage = false).
local VFX = game:GetService("ReplicatedStorage"):WaitForChild("VFX")
local C = require(VFX:WaitForChild("VFXCommon"))
local BeamFX = require(VFX:WaitForChild("BeamFX"))
local FX = require(script.Parent:WaitForChild("FriezaMajinFX"))
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local M = {}
M.STYLE = {
	Core = rgb(235, 255, 225), Glow = rgb(170, 90, 255), Haze = rgb(30, 60, 25), Life = rgb(120, 230, 90),
	Width = 4.5, Charge = 0.9, Duration = 1.2, Speed = 380, ImpactSize = 30, Shake = 3.2, Range = 260,
}

local function mouth(character: Model): Vector3
	local head = character:FindFirstChild("Head") :: BasePart?
	local root = C.root(character)
	if head then return head.Position + head.CFrame.LookVector * 0.9 - Vector3.new(0, 0.3, 0) end
	return if root then root.Position + Vector3.new(0, 2, 0) else character:GetPivot().Position
end

function M.Play(character: Model, target: any, _config: any?)
	local s = M.STYLE
	local root = C.root(character)
	if not root then return end
	local goal = FX.target(character, target)
	local f = C.folder("MoroMouthWave", s.Charge + s.Duration + 3)
	-- charge: life energy rises from the ground into the jaw
	local orb = C.part(f, Vector3.one * 0.4, s.Glow, Enum.PartType.Ball, 0.1)
	orb.Position = mouth(character)
	C.light(orb, s.Glow, 8, 3)
	C.tween(orb, s.Charge, { Size = Vector3.one * s.Width * 0.8 })
	for i = 1, 10 do
		task.delay(s.Charge * (i - 1) / 10, function()
			if not orb.Parent then return end
			local a = math.random() * math.pi * 2
			local mote = C.part(f, Vector3.one * 0.35, s.Life, Enum.PartType.Ball, 0.1)
			mote.Position = root.Position + Vector3.new(math.cos(a) * 9, -2.5, math.sin(a) * 9)
			C.tween(mote, 0.35, { Position = orb.Position, Size = Vector3.one * 0.1, Transparency = 0.6 })
			task.delay(0.36, function() mote:Destroy() end)
		end)
	end
	task.delay(s.Charge, function()
		if not character.Parent then
			f:Destroy()
			return
		end
		local origin = mouth(character)
		local dir = C.direction(origin, goal)
		local res = workspace:Raycast(origin, dir * s.Range, C.rayParams({ character, f }))
		local length = if res then (res.Position - origin).Magnitude else s.Range
		local layers = {
			{ C.part(f, Vector3.new(0.1, s.Width * 0.5, s.Width * 0.5), s.Core, Enum.PartType.Cylinder, 0), 0.5 },
			{ C.part(f, Vector3.new(0.1, s.Width, s.Width), s.Glow, Enum.PartType.Cylinder, 0.25), 1 },
			{ C.part(f, Vector3.new(0.1, s.Width * 1.8, s.Width * 1.8), s.Haze, Enum.PartType.Cylinder, 0.6), 1.8 },
		}
		local cur, t0, hit = 0, os.clock(), false
		local conn
		conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
			local el = os.clock() - t0
			if el > s.Duration or not f.Parent then
				conn:Disconnect()
				for _, l in layers do C.tween(l[1], 0.2, { Transparency = 1 }) end
				return
			end
			cur = math.min(length, cur + s.Speed * dt)
			local wobble = 1 + 0.12 * math.sin(el * 40) -- ragged edge, not a clean cylinder
			for _, l in layers do
				local w = s.Width * l[2] * wobble
				l[1].Size = Vector3.new(cur, w, w)
				l[1].CFrame = C.cylinderCF(origin, dir, cur)
			end
			if not hit and cur >= length then
				hit = true
				BeamFX.Impact(origin + dir * length, s.ImpactSize, s.Glow, s.Core, s.Shake, workspace)
			end
		end)
		C.tween(orb, 0.2, { Transparency = 1 })
	end)
end

return M
