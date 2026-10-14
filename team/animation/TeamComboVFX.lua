--!nonstrict
-- TeamComboVFX (client). Requires sibling VFXCommon.
--   TeamComboVFX.MergedBeam({char1, char2, char3?}, target, config?) -- each fires a beam that converges into one giant beam
--   TeamComboVFX.SyncRush({chars}, targetCharacterOrPos, config?)   -- teammates take turns dashing through target (afterimage streaks)
--   TeamComboVFX.EnergyGift(giver, receiver, config?)               -- Last Energy Gift: light stream from dying giver to teammate, boosts aura
-- Merged beam impact calls ArenaDamage (server only; see VFXCommon).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	Colors = {Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 220, 70), Color3.fromRGB(255, 90, 230)},
	CoreColor = Color3.fromRGB(255, 255, 255), MergeDistance = 14, BeamTime = 1.6, BeamSpeed = 400, MaxRange = 400,
	Width = 3, MergedWidth = 10, ImpactSize = 45, RushHits = 6, GiftTime = 2.5, GiftColor = Color3.fromRGB(255, 240, 180),
	FireSoundId = "", ImpactSoundId = "", GiftSoundId = "", ParticleTexture = "",
	OnHit = nil, OnCameraShake = nil, OnGiftComplete = nil,
}

function M.MergedBeam(chars, target, config)
	local c = C.merge(DEFAULTS, config)
	local f = C.folder("TeamBeamVFX", c.BeamTime + 5)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		local roots = {}
		for _, ch in ipairs(chars) do local r = C.root(ch); if r then table.insert(roots, {ch = ch, r = r}) end end
		if #roots == 0 then f:Destroy() return end
		C.sound(c.FireSoundId, roots[1].r)
		shake(2, c.BeamTime)
		local avg = Vector3.zero
		for _, r in ipairs(roots) do avg += r.r.Position end
		avg /= #roots
		local tpos = typeof(target) == "Vector3" and target.Magnitude > 1.01 and target or (avg + C.direction(avg, target) * 100)
		local mainDir = (tpos - avg).Unit
		local mergePt = avg + mainDir * c.MergeDistance
		local feeders = {}
		for i, r in ipairs(roots) do
			feeders[i] = C.part(f, Vector3.new(0.1, c.Width, c.Width), c.Colors[(i - 1) % #c.Colors + 1], Enum.PartType.Cylinder, 0.15)
		end
		local main = C.part(f, Vector3.new(0.1, c.MergedWidth, c.MergedWidth), c.CoreColor, Enum.PartType.Cylinder, 0.1)
		local shell = C.part(f, Vector3.new(0.1, c.MergedWidth * 1.4, c.MergedWidth * 1.4), c.Colors[1], Enum.PartType.Cylinder, 0.5)
		local orb = C.part(f, Vector3.one * c.MergedWidth * 1.3, c.CoreColor, Enum.PartType.Ball, 0.2)
		orb.Position = mergePt
		C.light(orb, c.Colors[1], 40, 8)
		local params = C.rayParams({f, table.unpack(chars)})
		local length, hit, tip = 0, false, mergePt
		local t0 = os.clock()
		while os.clock() - t0 < c.BeamTime do
			local dt = RunService.Heartbeat:Wait()
			for i, r in ipairs(roots) do
				local o = C.hands(r.ch)
				local d = mergePt - o
				feeders[i].CFrame = C.cylinderCF(o, d.Unit, d.Magnitude)
				feeders[i].Size = Vector3.new(d.Magnitude, c.Width, c.Width)
			end
			if not hit then length = math.min(length + c.BeamSpeed * dt, c.MaxRange) end
			local res = workspace:Raycast(mergePt, mainDir * length, params)
			if res and not hit then
				hit = true; length = (res.Position - mergePt).Magnitude
				if c.OnHit then c.OnHit(res.Position, res.Instance) end
			end
			local p = 1 + 0.08 * math.sin(os.clock() * 50)
			local cf = C.cylinderCF(mergePt, mainDir, length)
			main.CFrame, shell.CFrame = cf, cf * CFrame.Angles(os.clock() * 6, 0, 0)
			main.Size = Vector3.new(length, c.MergedWidth * p, c.MergedWidth * p)
			shell.Size = Vector3.new(length, c.MergedWidth * 1.4, c.MergedWidth * 1.4)
			shell.Color = c.Colors[math.floor(os.clock() * 8) % #roots + 1]
			tip = mergePt + mainDir * length
		end
		for _, p in ipairs(f:GetChildren()) do if p:IsA("BasePart") then C.tween(p, 0.3, {Transparency = 1}) end end
		C.sound(c.ImpactSoundId, roots[1].r)
		C.arenaDamage(c, tip, 30, 200)
		C.explosion(f, tip, c.ImpactSize, c.Colors[1], c.CoreColor, c.ParticleTexture, shake)
		task.wait(1.2)
		f:Destroy()
	end)
	return f
end

function M.SyncRush(chars, target, config)
	local c = C.merge(DEFAULTS, config)
	local f = C.folder("SyncRushVFX", 8)
	local shake = c.OnCameraShake or C.shake
	task.spawn(function()
		local function tpos()
			if typeof(target) == "Instance" then return target:IsA("Model") and target:GetPivot().Position or target.Position end
			return target
		end
		for i = 1, c.RushHits do
			local ch = chars[(i - 1) % #chars + 1]
			local col = c.Colors[(i - 1) % #c.Colors + 1]
			local p = tpos()
			local ang = math.random() * math.pi * 2
			local from = p + Vector3.new(math.cos(ang) * 15, math.random() * 6, math.sin(ang) * 15)
			local to = p - (from - p)
			local streak = C.part(f, Vector3.new(0.1, 1.2, 1.2), col, Enum.PartType.Cylinder, 0.2)
			streak.CFrame = C.cylinderCF(from, (to - from).Unit, (to - from).Magnitude)
			streak.Size = Vector3.new((to - from).Magnitude, 1.2, 1.2)
			C.tween(streak, 0.25, {Transparency = 1, Size = Vector3.new((to - from).Magnitude, 0.1, 0.1)})
			local hitFx = C.part(f, Vector3.one, c.CoreColor, Enum.PartType.Ball)
			hitFx.Position = p
			C.tween(hitFx, 0.15, {Size = Vector3.one * 6, Transparency = 1, Color = col})
			if c.OnHit then c.OnHit(p, ch and C.root(ch)) end
			shake(1, 0.12)
			task.wait(0.14)
		end
		C.explosion(f, tpos(), 20, c.Colors[1], c.CoreColor, c.ParticleTexture, shake)
		task.wait(1)
		f:Destroy()
	end)
	return f
end

function M.EnergyGift(giver, receiver, config)
	local c = C.merge(DEFAULTS, config)
	local rg, rr = C.root(giver), C.root(receiver)
	if not rg or not rr then return end
	local f = C.folder("EnergyGiftVFX", c.GiftTime + 5)
	task.spawn(function()
		C.sound(c.GiftSoundId, rr)
		local stream = C.part(f, Vector3.new(0.1, 0.8, 0.8), c.GiftColor, Enum.PartType.Cylinder, 0.3)
		local orbs = {}
		for i = 1, 14 do orbs[i] = C.part(f, Vector3.one * 0.6, c.CoreColor, Enum.PartType.Ball, 0.1) end
		local ra = Instance.new("Attachment"); ra.Parent = rr
		local aura = C.emitter(ra, c.CoreColor, c.GiftColor, {Rate = 10, Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(4, 8),
			Size = NumberSequence.new(1.5, 0), Acceleration = Vector3.new(0, 20, 0), LockedToPart = true}, c.ParticleTexture)
		local lt = C.light(rr, c.GiftColor, 6, 1)
		local fade = Instance.new("Highlight")
		fade.FillColor, fade.FillTransparency, fade.OutlineTransparency = Color3.new(0, 0, 0), 1, 1
		fade.Parent = giver
		local t0 = os.clock()
		while os.clock() - t0 < c.GiftTime and rg.Parent and rr.Parent do
			local k = (os.clock() - t0) / c.GiftTime
			local a, b = rg.Position, rr.Position
			local d = b - a
			stream.CFrame = C.cylinderCF(a, d.Unit, d.Magnitude)
			stream.Size = Vector3.new(d.Magnitude, 0.8 + math.sin(os.clock() * 20) * 0.2, 0.8)
			for i, o in ipairs(orbs) do
				local u = ((os.clock() * 0.8) + i / #orbs) % 1
				o.Position = a:Lerp(b, u) + Vector3.new(0, math.sin(u * math.pi) * 2, 0)
			end
			aura.Rate = 10 + 140 * k
			lt.Range, lt.Brightness = 6 + 16 * k, 1 + 5 * k
			fade.FillTransparency = 1 - 0.6 * k -- giver dims (dying)
			RunService.Heartbeat:Wait()
		end
		stream:Destroy()
		for _, o in ipairs(orbs) do o:Destroy() end
		local burst = C.part(f, Vector3.one * 3, c.CoreColor, Enum.PartType.Ball)
		burst.Position = rr.Position
		C.tween(burst, 0.5, {Size = Vector3.one * 25, Transparency = 1, Color = c.GiftColor});
		(c.OnCameraShake or C.shake)(1.5, 0.4)
		if c.OnGiftComplete then task.spawn(c.OnGiftComplete, giver, receiver) end
		task.wait(2.5)
		aura.Enabled = false
		task.wait(1)
		ra:Destroy(); lt:Destroy(); fade:Destroy(); f:Destroy()
	end)
	return f
end
return M
