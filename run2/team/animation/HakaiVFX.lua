--!strict
-- HakaiVFX: God of Destruction erasure / void disintegration.
-- Play(character, target, config?). Requires sibling VFXCommon.
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))

local M = {}

local DEFAULTS = {
	ChargeTime = 1.2,
	Range = 80,
	SphereSize = 6,
	Color = Color3.fromRGB(150, 30, 220),
	CoreColor = Color3.fromRGB(20, 5, 35),
	AuraColor = Color3.fromRGB(210, 80, 255),
	ChargeSoundId = "",
	FireSoundId = "",
	ImpactSoundId = "",
	ParticleTexture = "",
	OnHit = nil,
	OnCameraShake = nil,
	ArenaDamage = false,
}

function M.Play(character: Model, target: (Instance | Vector3)?, config: { [string]: any }?)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character)
	if not root then
		return
	end

	local f = C.folder("HakaiVFX", c.ChargeTime + 8)
	local shake = c.OnCameraShake or C.shake

	task.spawn(function()
		C.sound(c.ChargeSoundId, root)
		local hand = C.limb(character, { "RightHand", "Right Arm" })

		-- Palm sphere
		local sphere = C.part(f, Vector3.one * 0.4, c.Color, Enum.PartType.Ball, 0)
		local core = C.part(f, Vector3.one * 0.2, c.CoreColor, Enum.PartType.Ball, 0)
		local a = Instance.new("Attachment")
		a.Parent = sphere

		-- Inward suction / void motes
		local em = C.emitter(a, c.Color, c.AuraColor, {
			Rate = C.q(45),
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(-8, -3),
			Size = NumberSequence.new(1.2, 0),
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			Drag = 1,
		}, c.ParticleTexture)

		local lt = C.light(sphere, c.AuraColor, 12, 4)
		C.FOVPunch(-4)

		local t0 = os.clock()
		while os.clock() - t0 < c.ChargeTime and character.Parent do
			local k = (os.clock() - t0) / c.ChargeTime
			local e = k * k
			local s = 0.4 + e * c.SphereSize
			local p = hand and hand.Position or (root.Position + Vector3.new(0, 1.5, -2))

			sphere.Position = p
			core.Position = p
			sphere.Size = Vector3.one * s
			core.Size = Vector3.one * (s * 0.6)

			lt.Range = 10 + e * 30
			lt.Brightness = 3 + e * 5
			em.Rate = C.q(45 + e * 100)

			if math.random() < 0.12 then
				shake(0.4 + e * 1.8, 0.15)
			end
			RunService.Heartbeat:Wait()
		end

		C.sound(c.FireSoundId, root)
		C.ImpactFrame("invert", 2, { character })
		C.FOVPunch(8)

		-- Resolve target pos
		local targetPos: Vector3
		local targetInst: Instance? = nil
		if typeof(target) == "Instance" then
			targetInst = target
			targetPos = target:IsA("Model")
					and (C.root(target) and C.root(target).Position or target:GetPivot().Position)
				or (target:IsA("BasePart") and target.Position or root.Position + root.CFrame.LookVector * 20)
		elseif typeof(target) == "Vector3" then
			targetPos = target
		else
			targetPos = root.Position + root.CFrame.LookVector * 25
		end

		-- Void beam strike / flash to target
		local origin = sphere.Position
		local dir = (targetPos - origin).Unit
		local dist = math.min((targetPos - origin).Magnitude, c.Range)
		local strikePos = origin + dir * dist

		C.tween(sphere, 0.3, { Size = Vector3.one * (c.SphereSize * 2), Transparency = 1 })
		C.tween(core, 0.3, { Size = Vector3.one * (c.SphereSize * 1.5), Transparency = 1 })

		-- Target erasure / disintegration VFX
		C.sound(c.ImpactSoundId, root)
		shake(2.5, 0.6)

		-- Dual shockwave
		if C.Shockwave then
			C.Shockwave(f, CFrame.new(strikePos), 2, 28, c.Color, 0.45, 0.4)
			C.Shockwave(f, CFrame.new(strikePos), 1, 18, c.CoreColor, 0.35, 0.3)
		end

		-- Purple disintegration aura & ground fissures
		if C.GroundCrack then
			C.GroundCrack(f, strikePos, 16, 10, c.AuraColor, 3.5)
		end
		if C.DebrisBurst then
			C.DebrisBurst(f, strikePos, C.q(25), 45, c.CoreColor, 2.5)
		end

		-- Disintegration particles at impact point
		local hitAtt = C.worldAttachment(strikePos)
		local hitEm = C.emitter(hitAtt, c.AuraColor, c.CoreColor, {
			Rate = 0,
			Lifetime = NumberRange.new(0.6, 1.4),
			Speed = NumberRange.new(10, 35),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2),
				NumberSequenceKeypoint.new(0.5, 1.2),
				NumberSequenceKeypoint.new(1, 0),
			}),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 2,
		}, c.ParticleTexture)
		hitEm:Emit(C.q(80))

		if targetInst and targetInst:IsA("Model") then
			C.Hitstop({ character, targetInst }, "Ultimate")
		end

		if c.OnHit then
			c.OnHit(strikePos, targetInst)
		end
	end)
end

return M
