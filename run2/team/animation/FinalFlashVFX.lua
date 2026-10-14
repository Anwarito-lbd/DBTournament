--!nonstrict
-- FinalFlashVFX (Vegeta). Play(character, targetPosOrDirOrPart, config?). Client visual; requires sibling VFXCommon.
-- Phases: arms-spread charge (two yellow orbs at hands merging forward) -> huge wide beam with spiraling outer layer -> massive impact.
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	ChargeTime = 1.6, BeamTime = 1.8, BeamSpeed = 450, MaxRange = 400, BeamWidth = 9,
	Color = Color3.fromRGB(255, 230, 70), CoreColor = Color3.fromRGB(255, 255, 230), ImpactSize = 40,
	ChargeSoundId = "", FireSoundId = "", ImpactSoundId = "", ParticleTexture = "",
	OnHit = nil, OnCameraShake = nil,
}
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("FinalFlashVFX", c.ChargeTime + c.BeamTime + 6)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.ChargeSoundId, root)
		local l = C.limb(character, {"LeftHand", "Left Arm"})
		local r = C.limb(character, {"RightHand", "Right Arm"})
		local orbs = {}
		for i, limb in ipairs({l, r}) do
			local o = C.part(f, Vector3.one * 0.5, c.Color, Enum.PartType.Ball, 0.1)
			local a = Instance.new("Attachment"); a.Parent = o
			C.emitter(a, c.CoreColor, c.Color, {Rate = 50, Lifetime = NumberRange.new(0.2, 0.4), Speed = NumberRange.new(-10, -6),
				Size = NumberSequence.new(0.5, 0), Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface}, c.ParticleTexture)
			C.light(o, c.Color, 10, 3)
			orbs[i] = {o = o, limb = limb}
		end
		local t0 = os.clock()
		while os.clock() - t0 < c.ChargeTime and character.Parent do
			local a = (os.clock() - t0) / c.ChargeTime
			for _, ob in ipairs(orbs) do
				local p = ob.limb.Position
				-- second half: orbs converge to front of chest
				local front = root.Position + root.CFrame.LookVector * 2.5 + Vector3.new(0, 1, 0)
				local k = math.clamp((a - 0.5) * 2, 0, 1)
				ob.o.Position = p:Lerp(front, k)
				ob.o.Size = Vector3.one * (0.5 + a * 2.5) * (1 + 0.1 * math.sin(os.clock() * 45))
			end
			if math.random() < 0.1 then shake(0.4 + a, 0.15) end
			RunService.Heartbeat:Wait()
		end
		if not character.Parent then f:Destroy() return end
		C.sound(c.FireSoundId, root)
		shake(2, c.BeamTime)
		-- quality bar: Final Flash release = 2 white impact frames, FOV +14 punch, speed lines 30f, muzzle shockwave
		C.ImpactFrame("white", 2)
		C.FOVPunch(14)
		C.SpeedLines(0.5, c.CoreColor, 50)
		C.Shockwave(f, root.CFrame * CFrame.new(0, 1, -3) * CFrame.Angles(0, math.rad(90), 0), 2, c.BeamWidth * 4, c.Color, 0.35)
		local params = C.rayParams({character, f})
		local outer = C.part(f, Vector3.new(0.1, c.BeamWidth, c.BeamWidth), c.Color, Enum.PartType.Cylinder, 0.35)
		local mid = C.part(f, Vector3.new(0.1, c.BeamWidth * 0.7, c.BeamWidth * 0.7), c.Color, Enum.PartType.Cylinder, 0.1)
		local core = C.part(f, Vector3.new(0.1, c.BeamWidth * 0.4, c.BeamWidth * 0.4), c.CoreColor, Enum.PartType.Cylinder)
		local bc = C.BeamCore(f, {Width = c.BeamWidth, Core = c.CoreColor, Inner = c.Color, Outer = c.Color})
		mid.Transparency, core.Transparency = 1, 1
		local muzzle = C.part(f, Vector3.one * c.BeamWidth * 1.3, c.CoreColor, Enum.PartType.Ball, 0.2)
		local tip = C.part(f, Vector3.one * c.BeamWidth * 1.5, c.Color, Enum.PartType.Ball, 0.3)
		C.light(tip, c.Color, 40, 8)
		local ta = Instance.new("Attachment"); ta.Parent = tip
		C.emitter(ta, c.CoreColor, c.Color, {Rate = 120, Lifetime = NumberRange.new(0.2, 0.5), Speed = NumberRange.new(20, 40),
			Size = NumberSequence.new(2.5, 0), SpreadAngle = Vector2.new(180, 180)}, c.ParticleTexture)
		local length, hit = 0, false
		local t1 = os.clock()
		local origin, d = root.Position, root.CFrame.LookVector
		while os.clock() - t1 < c.BeamTime and character.Parent do
			local dt = RunService.Heartbeat:Wait()
			origin = root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
			d = C.direction(origin, target)
			if not hit then length = math.min(length + c.BeamSpeed * dt, c.MaxRange) end
			local res = workspace:Raycast(origin, d * length, params)
			if res then
				length = (res.Position - origin).Magnitude
				if not hit then hit = true; if c.OnHit then c.OnHit(res.Position, res.Instance) end end
			end
			local now = os.clock()
			local cf = C.cylinderCF(origin, d, length)
			outer.CFrame = cf * CFrame.Angles(now * 8, 0, 0)
			mid.CFrame, core.CFrame = cf, cf
			local p = 1 + 0.07 * math.sin(now * 60)
			outer.Size = Vector3.new(length, c.BeamWidth * p, c.BeamWidth * p)
			mid.Size = Vector3.new(length, c.BeamWidth * 0.7, c.BeamWidth * 0.7)
			core.Size = Vector3.new(length, c.BeamWidth * 0.4 * p, c.BeamWidth * 0.4 * p)
			bc:Update(origin, d, length, now)
			muzzle.Position = origin
			tip.Position = origin + d * length
		end
		local endPos = tip.Position
		bc:Fade(0.3)
		for _, p in ipairs({outer, mid, core, muzzle, tip}) do C.tween(p, 0.3, {Transparency = 1}) end
		for _, ob in ipairs(orbs) do ob.o:Destroy() end
		C.sound(c.ImpactSoundId, root)
		C.arenaDamage(c, endPos, 22, 150)
		C.explosion(f, endPos, c.ImpactSize, c.Color, c.CoreColor, c.ParticleTexture, shake)
		task.wait(1.2)
		f:Destroy()
	end)
	return f
end
-- v1.1 quality pass: delegate the visible beam to BeamFX (core + glow + spiral, charge sphere, big impact, shake).
-- Legacy implementation kept as M.LegacyPlay.
do
	local BeamFX = require(script.Parent:WaitForChild("BeamFX"))
	M.LegacyPlay = M.Play
	M.Play = function(character, target, config)
		return BeamFX.Play(character, target, "FinalFlash", nil)
	end
end
return M
