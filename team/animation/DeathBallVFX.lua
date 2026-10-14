--!nonstrict
-- DeathBallVFX (Frieza). Play(character, target, config?). Requires sibling VFXCommon.
-- One-finger raised charge: small orb above finger swells into a huge red-orange sun with corona -> slow push toward target -> planet-scale impact.
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	ChargeTime = 2.2, TravelSpeed = 45, MaxRange = 250, BallSize = 16, Height = 12,
	Color = Color3.fromRGB(255, 80, 40), CoreColor = Color3.fromRGB(255, 200, 120), CoronaColor = Color3.fromRGB(255, 140, 60),
	ImpactSize = 60, ChargeSoundId = "", FireSoundId = "", ImpactSoundId = "", ParticleTexture = "",
	OnHit = nil, OnCameraShake = nil,
}
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("DeathBallVFX", c.ChargeTime + c.MaxRange / c.TravelSpeed + 6)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		C.sound(c.ChargeSoundId, root)
		local finger = C.limb(character, {"RightHand", "Right Arm"})
		local ball = C.part(f, Vector3.one * 0.4, c.Color, Enum.PartType.Ball, 0)
		local inner = C.part(f, Vector3.one * 0.2, c.CoreColor, Enum.PartType.Ball, 0)
		local corona = C.part(f, Vector3.one * 0.6, c.CoronaColor, Enum.PartType.Ball, 0.7)
		local a = Instance.new("Attachment"); a.Parent = ball
		local em = C.emitter(a, c.CoreColor, c.Color, {Rate = 30, Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(1, 3),
			Size = NumberSequence.new(1, 0), Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface}, c.ParticleTexture)
		local lt = C.light(ball, c.Color, 10, 3)
		C.FOVPunch(-6) -- slow zoom-in on the growing sun (anticipation)
		local t0 = os.clock()
		local pos = finger.Position
		while os.clock() - t0 < c.ChargeTime and character.Parent do
			local k = (os.clock() - t0) / c.ChargeTime
			local e = k * k
			local s = 0.4 + e * c.BallSize
			pos = finger.Position + Vector3.new(0, 1 + e * c.Height, 0)
			ball.Position, inner.Position, corona.Position = pos, pos, pos
			ball.Size = Vector3.one * s
			inner.Size = Vector3.one * s * 1.02 -- slightly larger + transparent swirl look
			inner.Transparency = 0.6
			corona.Size = Vector3.one * s * (1.3 + 0.05 * math.sin(os.clock() * 20))
			lt.Range, lt.Brightness = 10 + e * 50, 3 + e * 6
			em.Rate = 30 + e * 120
			em.Size = NumberSequence.new(1 + e * 4, 0)
			if math.random() < 0.08 then shake(0.3 + e * 1.5, 0.2) end
			RunService.Heartbeat:Wait()
		end
		C.sound(c.FireSoundId, root)
		C.ImpactFrame("black", 1)
		C.FOVPunch(6)
		local params = C.rayParams({character, f})
		local d = C.direction(pos, target)
		local travelled = 0
		local hitPos
		while travelled < c.MaxRange do
			local dt = RunService.Heartbeat:Wait()
			local step = c.TravelSpeed * dt
			local res = workspace:Spherecast(pos, c.BallSize * 0.45, d * step, params)
			if res then hitPos = res.Position; if c.OnHit then c.OnHit(res.Position, res.Instance) end break end
			pos += d * step
			travelled += step
			ball.Position, inner.Position, corona.Position = pos, pos, pos
			ball.CFrame *= CFrame.Angles(0, dt * 2, 0)
			corona.Size = Vector3.one * c.BallSize * (1.3 + 0.06 * math.sin(os.clock() * 20))
		end
		hitPos = hitPos or pos
		C.sound(c.ImpactSoundId, root)
		for _, p in ipairs({ball, inner, corona}) do C.tween(p, 0.6, {Size = p.Size * 1.8, Transparency = 1}) end
		C.arenaDamage(c, hitPos, 30, 180)
		C.explosion(f, hitPos, c.ImpactSize, c.Color, c.CoreColor, c.ParticleTexture, shake)
		local dome = C.part(f, Vector3.one * c.ImpactSize, c.CoronaColor, Enum.PartType.Ball, 0.5)
		dome.Position = hitPos
		C.tween(dome, 2, {Size = Vector3.one * c.ImpactSize * 2.2, Transparency = 1})
		shake(4, 1.2)
		task.wait(2.2)
		f:Destroy()
	end)
	return f
end
return M
