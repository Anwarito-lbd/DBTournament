--!nonstrict
-- DeathBeamVFX (Frieza). Thin pink-purple needle beam, near-instant, tiny piercing impact + spark.
-- Play(character, target, config?) ; Rapid(character, target, count, config?) alternates fingers.
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {Color = Color3.fromHex("FF4FD8"), CoreColor = Color3.new(1, 1, 1), Width = 0.35, Range = 300, Travel = 0.1,
	SoundId = "", OnHit = nil, Hand = "Right"}
function M.Play(character, target, config)
	local c = C.merge(DEFAULTS, config)
	local root = C.root(character); if not root then return end
	local f = C.folder("DeathBeamVFX", 2)
	local hand = C.limb(character, c.Hand == "Left" and {"LeftHand", "Left Arm"} or {"RightHand", "Right Arm"})
	local origin = hand.Position
	local d = C.direction(origin, target)
	local res = workspace:Raycast(origin, d * c.Range, C.rayParams({character, f}))
	local endPos = res and res.Position or origin + d * c.Range
	local len = (endPos - origin).Magnitude
	C.sound(c.SoundId, root)
	local outer = C.part(f, Vector3.new(0.1, c.Width, c.Width), c.Color, Enum.PartType.Cylinder, 0.2)
	local core = C.part(f, Vector3.new(0.1, c.Width * 0.4, c.Width * 0.4), c.CoreColor, Enum.PartType.Cylinder)
	local function set(l)
		local cf = C.cylinderCF(origin, d, l)
		outer.CFrame, core.CFrame = cf, cf
		outer.Size = Vector3.new(l, c.Width, c.Width)
		core.Size = Vector3.new(l, c.Width * 0.4, c.Width * 0.4)
	end
	local muzzle = C.part(f, Vector3.one * 0.6, c.Color, Enum.PartType.Ball)
	muzzle.Position = origin
	C.light(muzzle, c.Color, 6, 3)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < c.Travel do set(math.max(0.1, len * (os.clock() - t0) / c.Travel)); task.wait() end
		set(len)
		if res then
			if c.OnHit then c.OnHit(endPos, res.Instance) end
			local sa = C.worldAttachment(endPos)
			C.emitter(sa, c.CoreColor, c.Color, {Rate = 0, Lifetime = NumberRange.new(0.1, 0.25), Speed = NumberRange.new(10, 20),
				Size = NumberSequence.new(0.2, 0), Squash = NumberSequence.new(3), SpreadAngle = Vector2.new(60, 60)}):Emit(15)
			game:GetService("Debris"):AddItem(sa, 0.5)
			C.Shockwave(f, CFrame.lookAt(endPos, endPos + d) * CFrame.Angles(0, math.rad(90), 0), 0.3, 3, c.Color, 0.18, 0.1)
			C.CameraShake(0.12)
			local hole = C.part(f, Vector3.one * 0.5, c.CoreColor, Enum.PartType.Ball)
			hole.Position = endPos
			C.tween(hole, 0.2, {Size = Vector3.one * 1.5, Transparency = 1})
		end
		for _, p in ipairs({outer, core, muzzle}) do C.tween(p, 0.15, {Transparency = 1}) end
	end)
	return f
end
function M.Rapid(character, target, count, config)
	task.spawn(function()
		for i = 1, count or 5 do
			local c = C.merge(config or {}, {Hand = (i % 2 == 0) and "Left" or "Right"})
			M.Play(character, target, c)
			task.wait(0.09)
		end
	end)
end
-- v1.1 quality pass: delegate the visible beam to BeamFX (core + glow + spiral, charge sphere, big impact, shake).
-- Legacy implementation kept as M.LegacyPlay.
do
	local BeamFX = require(script.Parent:WaitForChild("BeamFX"))
	M.LegacyPlay = M.Play
	M.Play = function(character, target, config)
		return BeamFX.Play(character, target, "DeathBeam", nil)
	end
end
return M
