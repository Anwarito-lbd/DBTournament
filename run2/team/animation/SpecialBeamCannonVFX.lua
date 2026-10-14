--!nonstrict
-- SpecialBeamCannonVFX (Piccolo, Makankosappo). Play(character, target, config?). Requires sibling VFXCommon.
-- Two-finger forehead charge with crackling sparks -> thin piercing core beam + helical spiral of segments -> pierce impact.
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	ChargeTime = 2.0, BeamTime = 0.9, BeamSpeed = 700, MaxRange = 350, CoreWidth = 0.8,
	SpiralRadius = 2.2, SpiralTurnsPerStud = 0.12, SpiralSegments = 70,
	Color = Color3.fromRGB(255, 230, 120), SpiralColor = Color3.fromRGB(255, 120, 230), CoreColor = Color3.fromRGB(255, 255, 230),
	Pierce = true, ImpactSize = 14, ChargeSoundId = "", FireSoundId = "", ImpactSoundId = "", ParticleTexture = "",
	OnHit = nil, OnCameraShake = nil,
}
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("SBCVFX", c.ChargeTime + c.BeamTime + 6)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.ChargeSoundId, root)
		local head = C.limb(character, {"Head"})
		local orb = C.part(f, Vector3.one * 0.3, c.CoreColor, Enum.PartType.Ball)
		local a = Instance.new("Attachment"); a.Parent = orb
		local spark = C.emitter(a, c.CoreColor, c.Color, {Rate = 40, Lifetime = NumberRange.new(0.05, 0.12), Speed = NumberRange.new(4, 8),
			Size = NumberSequence.new(0.12), Squash = NumberSequence.new(4), SpreadAngle = Vector2.new(180, 180)})
		local lt = C.light(orb, c.Color, 6, 2)
		local t0 = os.clock()
		while os.clock() - t0 < c.ChargeTime and character.Parent do
			local k = (os.clock() - t0) / c.ChargeTime
			orb.Position = head.Position + head.CFrame.LookVector * 0.9 + head.CFrame.UpVector * 0.5
			orb.Size = Vector3.one * (0.3 + k * 0.9) * (1 + 0.25 * math.sin(os.clock() * 70))
			spark.Rate = 40 + k * 150
			lt.Range = 6 + k * 8
			RunService.Heartbeat:Wait()
		end
		if not character.Parent then f:Destroy() return end
		C.sound(c.FireSoundId, root)
		shake(1.2, 0.3)
		local params = C.rayParams({character, f})
		local core = C.part(f, Vector3.new(0.1, c.CoreWidth, c.CoreWidth), c.CoreColor, Enum.PartType.Cylinder)
		local segs = {}
		for i = 1, c.SpiralSegments do
			segs[i] = C.part(f, Vector3.new(0.5, 0.5, 1.6), c.SpiralColor, Enum.PartType.Ball, 0.15)
		end
		local origin = orb.Position
		local d = C.direction(origin, target)
		local length, hitPos = 0, nil
		local t1 = os.clock()
		while os.clock() - t1 < c.BeamTime do
			local dt = RunService.Heartbeat:Wait()
			length = math.min(length + c.BeamSpeed * dt, hitPos and (hitPos - origin).Magnitude or c.MaxRange)
			if not hitPos then
				local res = workspace:Raycast(origin, d * length, params)
				if res then
					if c.OnHit then c.OnHit(res.Position, res.Instance) end
					if c.Pierce then
						local burst = C.worldAttachment(res.Position)
						C.emitter(burst, c.CoreColor, c.SpiralColor, {Rate = 0, Lifetime = NumberRange.new(0.2, 0.4), Speed = NumberRange.new(15, 30),
							Size = NumberSequence.new(0.6, 0), SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Front}):Emit(25)
						game:GetService("Debris"):AddItem(burst, 1)
						params.FilterDescendantsInstances = {character, f, res.Instance.Parent}
					else
						hitPos = res.Position
					end
				end
			end
			core.CFrame = C.cylinderCF(origin, d, length)
			core.Size = Vector3.new(length, c.CoreWidth, c.CoreWidth)
			local basis = CFrame.lookAt(origin, origin + d)
			local now = os.clock()
			for i, s in ipairs(segs) do
				local dist = (i / #segs) * length
				local ang = dist * c.SpiralTurnsPerStud * math.pi * 2 - now * 25
				local off = basis.RightVector * math.cos(ang) * c.SpiralRadius + basis.UpVector * math.sin(ang) * c.SpiralRadius
				s.CFrame = CFrame.lookAt(origin + d * dist + off, origin + d * (dist + 1) + off)
			end
		end
		C.tween(core, 0.25, {Transparency = 1})
		for _, s in ipairs(segs) do C.tween(s, 0.3, {Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.5)}) end
		orb:Destroy()
		C.sound(c.ImpactSoundId, root)
		C.arenaDamage(c, origin + d * length, 6, 60)
		C.explosion(f, origin + d * length, c.ImpactSize, c.SpiralColor, c.CoreColor, c.ParticleTexture, shake)
		task.wait(1)
		f:Destroy()
	end)
	return f
end
return M
