--!nonstrict
-- MoroPlanetDrainVFX (Moro ultimate-lite AoE). Moro plants a palm on the ground: a green rune ring expands to Radius,
-- energy streams rise from the arena (and from enemies inside, config.Victims) into Moro, ground darkens, final pulse.
-- Play(moro, config?) ; config.OnPulse(center, radius) fires each drain tick (server applies drain).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromRGB(120, 230, 90), DarkColor = Color3.fromRGB(25, 35, 20), Radius = 30, Duration = 3,
	Pulses = 3, Victims = nil, SoundId = "", OnPulse = nil, OnCameraShake = nil, ArenaRadius = 30, ArenaPower = 35}
function M.Play(moro, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(moro); if not root then return end
	local f = C.folder("MoroPlanetDrainVFX", c.Duration + 3)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.SoundId, root)
		local res = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), C.rayParams({moro, f}))
		local center = res and res.Position or (root.Position - Vector3.new(0, 3, 0))
		local ring = C.part(f, Vector3.new(0.2, 2, 2), c.Color, Enum.PartType.Cylinder, 0.3)
		ring.CFrame = CFrame.new(center + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		C.tween(ring, 0.6, {Size = Vector3.new(0.2, c.Radius * 2, c.Radius * 2)})
		local dark = C.part(f, Vector3.new(0.1, 2, 2), c.DarkColor, Enum.PartType.Cylinder, 0.6)
		dark.Material = Enum.Material.SmoothPlastic
		dark.CFrame = ring.CFrame
		C.tween(dark, c.Duration, {Size = Vector3.new(0.1, c.Radius * 2, c.Radius * 2), Transparency = 0.3}, Enum.EasingStyle.Linear)
		-- rising motes over the area
		local a = Instance.new("Attachment"); a.Parent = ring
		local motes = C.emitter(a, c.Color, c.DarkColor, {Rate = 0, Lifetime = NumberRange.new(1, 1.5), Speed = NumberRange.new(4, 8),
			Size = NumberSequence.new(0.5, 0), Shape = Enum.ParticleEmitterShape.Cylinder, EmissionDirection = Enum.NormalId.Right})
		local mote = C.light(root, c.Color, 8, 1)
		local streams = {}
		for _, v in ipairs(c.Victims or {}) do
			local vr = C.root(v)
			if vr then table.insert(streams, {r = vr, p = C.part(f, Vector3.new(0.1, 0.5, 0.5), c.Color, Enum.PartType.Cylinder, 0.3)}) end
		end
		local t0, nextPulse, pulses = os.clock(), 0, 0
		task.wait(0.6)
		motes.Rate = 120
		while os.clock() - t0 < c.Duration do
			RunService.Heartbeat:Wait()
			local k = (os.clock() - t0) / c.Duration
			mote.Range, mote.Brightness = 8 + 16 * k, 1 + 5 * k
			for _, s in ipairs(streams) do
				if s.r.Parent then
					local d = root.Position - s.r.Position
					s.p.CFrame = C.cylinderCF(s.r.Position, d.Unit, d.Magnitude)
					s.p.Size = Vector3.new(d.Magnitude, 0.5 + 0.2 * math.sin(os.clock() * 20), 0.5)
				end
			end
			if os.clock() - t0 >= nextPulse and pulses < c.Pulses then
				pulses += 1
				nextPulse = (c.Duration / c.Pulses) * pulses
				local p = C.part(f, Vector3.new(0.3, c.Radius * 2, c.Radius * 2), c.Color, Enum.PartType.Cylinder, 0.2)
				p.CFrame = ring.CFrame
				C.tween(p, 0.5, {Size = Vector3.new(0.1, 1, 1), Transparency = 1}) -- inward pulse (draining)
				shake(1, 0.3)
				if c.OnPulse then task.spawn(c.OnPulse, center, c.Radius) end
				C.arenaDamage(c, center, c.ArenaRadius, c.ArenaPower)
			end
		end
		motes.Enabled = false
		for _, s in ipairs(streams) do C.tween(s.p, 0.3, {Transparency = 1}) end
		C.tween(ring, 0.5, {Transparency = 1}); C.tween(dark, 1.5, {Transparency = 1})
		local burst = C.part(f, Vector3.one * 3, c.Color, Enum.PartType.Ball, 0.2)
		burst.Position = root.Position
		C.tween(burst, 0.5, {Size = Vector3.one * 20, Transparency = 1})
		task.wait(1.6)
		mote:Destroy()
		f:Destroy()
	end)
	return f
end
return M
