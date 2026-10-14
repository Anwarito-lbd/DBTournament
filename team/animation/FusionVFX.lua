--!nonstrict
-- FusionVFX (client). Requires sibling VFXCommon.
--   FusionVFX.Dance(charA, charB, config?)   -- Fusion Dance: 3 synced mirrored poses, fingertip light beam, flash, reveal
--   FusionVFX.Potara(charA, charB, config?)  -- Potara: earrings glow, both pulled together, flash, reveal
-- config.OnFused(charA, charB, centerCFrame) -> Model? : spawn/return the fused model (gameplay; server should own spawning).
-- config.OnPose(index, charA, charB): hook to play dance AnimationTracks ("Fusion_Pose1..3") instead of procedural tweens.
-- Procedural poses only move the HumanoidRootPart CFrame locally when config.MoveCharacters = true (default false: visual markers only).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	Color = Color3.fromRGB(255, 240, 150), CoreColor = Color3.fromRGB(255, 255, 255), PotaraColor = Color3.fromRGB(255, 220, 60),
	PoseTime = 0.6, Spacing = 8, MoveCharacters = false, FlashSize = 50,
	PoseSoundId = "", FlashSoundId = "", OnPose = nil, OnFused = nil, OnCameraShake = nil, ParticleTexture = "",
}

local function flashAndReveal(c, f, charA, charB, center)
	local shake = c.OnCameraShake or C.shake
	C.sound(c.FlashSoundId, f)
	shake(2.5, 0.8)
	local flash = C.part(f, Vector3.one * 2, c.CoreColor, Enum.PartType.Ball)
	flash.Position = center
	C.light(flash, c.Color, 80, 20)
	C.tween(flash, 0.7, {Size = Vector3.one * c.FlashSize, Transparency = 1, Color = c.Color})
	local pillar = C.part(f, Vector3.new(200, 6, 6), c.Color, Enum.PartType.Cylinder, 0.2)
	pillar.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	C.tween(pillar, 1.2, {Size = Vector3.new(200, 30, 30), Transparency = 1})
	local a = C.worldAttachment(center)
	C.emitter(a, c.CoreColor, c.Color, {Rate = 0, Lifetime = NumberRange.new(0.6, 1.4), Speed = NumberRange.new(20, 50),
		Size = NumberSequence.new(1.5, 0), SpreadAngle = Vector2.new(180, 180), Drag = 3}, c.ParticleTexture):Emit(120)
	game:GetService("Debris"):AddItem(a, 2)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.8
	cc.Parent = game:GetService("Lighting")
	C.tween(cc, 1, {Brightness = 0})
	game:GetService("Debris"):AddItem(cc, 1.1)
	local fused
	if c.OnFused then
		local ok, res = pcall(c.OnFused, charA, charB, CFrame.new(center))
		if ok then fused = res else warn("OnFused error:", res) end
	end
	return fused
end

function M.Dance(charA, charB, config)
	local c = C.merge(DEFAULTS, config)
	local ra, rb = C.root(charA), C.root(charB)
	if not ra or not rb then return end
	local f = C.folder("FusionDanceVFX", 12)
	task.spawn(function()
		local center = (ra.Position + rb.Position) / 2
		local axis = (rb.Position - ra.Position) * Vector3.new(1, 0, 1)
		axis = axis.Magnitude > 0.1 and axis.Unit or Vector3.xAxis
		-- mirrored marker ghosts (always shown); optional real character moves
		local function ghostPose(root, side, step)
			local g = C.part(f, Vector3.new(2, 5, 1), c.Color, nil, 0.6)
			local base = center - axis * side * (c.Spacing / 2 - step * 1.2)
			g.CFrame = CFrame.lookAt(base, base + axis * side) * CFrame.Angles(0, 0, math.rad(side * (step == 2 and 40 or 0)))
			C.tween(g, c.PoseTime, {Transparency = 1})
			if c.MoveCharacters then
				C.tween(root, c.PoseTime * 0.6, {CFrame = CFrame.lookAt(base, base + axis * side)})
			end
		end
		for step = 1, 3 do
			C.sound(c.PoseSoundId, ra)
			if c.OnPose then pcall(c.OnPose, step, charA, charB) end
			ghostPose(ra, 1, step)
			ghostPose(rb, -1, step)
			-- "Fu" / "sion" / "Ha!" glow pulse
			local pulse = C.part(f, Vector3.one, c.Color, Enum.PartType.Ball, 0.4)
			pulse.Position = center + Vector3.new(0, 2, 0)
			C.tween(pulse, c.PoseTime, {Size = Vector3.one * (4 + step * 3), Transparency = 1})
			task.wait(c.PoseTime)
		end
		-- fingertip beam
		local la = C.limb(charA, {"RightHand", "Right Arm"})
		local lb = C.limb(charB, {"LeftHand", "Left Arm"})
		local beam = C.part(f, Vector3.new(0.1, 0.4, 0.4), c.CoreColor, Enum.PartType.Cylinder)
		local t0 = os.clock()
		while os.clock() - t0 < 0.6 do
			local p1, p2 = la.Position, lb.Position
			local len = (p2 - p1).Magnitude
			beam.CFrame = C.cylinderCF(p1, (p2 - p1).Unit, len)
			local w = 0.4 + (os.clock() - t0) * 3
			beam.Size = Vector3.new(len, w, w)
			RunService.Heartbeat:Wait()
		end
		beam:Destroy()
		flashAndReveal(c, f, charA, charB, (la.Position + lb.Position) / 2)
		task.wait(2)
		f:Destroy()
	end)
	return f
end

function M.Potara(charA, charB, config)
	local c = C.merge(DEFAULTS, config)
	local ra, rb = C.root(charA), C.root(charB)
	if not ra or not rb then return end
	local f = C.folder("PotaraVFX", 12)
	task.spawn(function()
		local heads = {C.limb(charA, {"Head"}), C.limb(charB, {"Head"})}
		local rings = {}
		for i, h in ipairs(heads) do
			local e = C.part(f, Vector3.one * 0.4, c.PotaraColor, Enum.PartType.Ball)
			C.light(e, c.PotaraColor, 6, 3)
			rings[i] = {e = e, h = h}
		end
		local t0 = os.clock()
		while os.clock() - t0 < 1 do
			for _, r in ipairs(rings) do
				r.e.Position = r.h.Position + r.h.CFrame.RightVector * 0.9 - Vector3.new(0, 0.3, 0)
				r.e.Size = Vector3.one * (0.4 + (os.clock() - t0) * 0.8)
			end
			RunService.Heartbeat:Wait()
		end
		-- pull together: streaks from each toward center
		local center = (ra.Position + rb.Position) / 2
		for _, r in ipairs({ra, rb}) do
			local streak = C.part(f, Vector3.new(0.1, 1.5, 1.5), c.PotaraColor, Enum.PartType.Cylinder, 0.3)
			local d = (center - r.Position)
			streak.CFrame = C.cylinderCF(r.Position, d.Unit, d.Magnitude)
			streak.Size = Vector3.new(d.Magnitude, 1.5, 1.5)
			C.tween(streak, 0.5, {Transparency = 1, Size = Vector3.new(0.5, 3, 3), CFrame = CFrame.new(center)})
			if c.MoveCharacters then C.tween(r, 0.5, {CFrame = CFrame.new(center)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
		end
		for _, r in ipairs(rings) do C.tween(r.e, 0.5, {Position = center}) end
		task.wait(0.5)
		flashAndReveal(c, f, charA, charB, center)
		task.wait(2)
		f:Destroy()
	end)
	return f
end
return M
