--!nonstrict
-- SpiritBombVFX (Goku). Arms up; pale blue-white motes stream in from all directions while a sphere grows 5->40 studs above,
-- then slow drift and massive flash/dome. Built on DeathBallVFX plus an inward mote field during charge.
-- Play(character, target, config?). config.ChargeTime controls hold length; config.U7Tint=true adds purple outer tint.
local C = require(script.Parent:WaitForChild("VFXCommon"))
local DeathBall = require(script.Parent:WaitForChild("DeathBallVFX"))
local M = {}
M.PRESET = {ChargeTime = 4, TravelSpeed = 28, BallSize = 40, Height = 30, ImpactSize = 90,
	Color = Color3.fromHex("BFE9FF"), CoreColor = Color3.fromRGB(255, 255, 255), CoronaColor = Color3.fromHex("7FD4FF")}
function M.Play(character, target, config)
	local c = C.merge(M.PRESET, config)
	if c.U7Tint then c.CoronaColor = Color3.fromRGB(170, 120, 255) end
	local root = C.root(character)
	if root then
		-- mote field: emitter on a large invisible shell around the player streaming inward toward the bomb
		local f = C.folder("SpiritBombMotes", c.ChargeTime + 2)
		local shell = C.part(f, Vector3.one * 2, c.Color, Enum.PartType.Ball, 1)
		shell.Position = root.Position + Vector3.new(0, c.Height, 0)
		local a = Instance.new("Attachment"); a.Parent = shell
		local em = C.emitter(a, c.CoreColor, c.Color, {Rate = 120, Lifetime = NumberRange.new(1, 1.4), Speed = NumberRange.new(-60, -45),
			Size = NumberSequence.new(0.6, 0.2), Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface})
		shell.Size = Vector3.one * 120
		task.delay(c.ChargeTime, function() em.Enabled = false end)
	end
	return DeathBall.Play(character, target, c)
end
-- v1.1 quality pass: BeamFX.SpiritBomb (gathered motes, layered sphere, huge impact). Legacy kept as M.LegacyPlay.
do
	local BeamFX = require(script.Parent:WaitForChild("BeamFX"))
	M.LegacyPlay = M.Play
	M.Play = function(character, target, config)
		return BeamFX.SpiritBomb(character, target, config)
	end
end
return M
