--!nonstrict
-- BeamStruggleVFX (client). Requires sibling VFXCommon.
--   local s = BeamStruggleVFX.Start(charA, charB, config?)
--   s:SetProgress(p)   -- p in [-1, 1]: -1 = clash point at A (A losing), +1 = at B (B losing). Server-authoritative value, replicate it.
--   s:Push(side, amount) -- local nudge helper: side "A" pushes toward B (+), "B" toward A (-)
--   s:End(winner)      -- "A" | "B" | nil (tie: double explosion). Winner's beam sweeps through.
-- Gameplay (mashing, ki spend, timeout) lives on the server (see movesets_v2.md "Beam Struggle").
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))
local M = {}
local DEFAULTS = {
	ColorA = Color3.fromRGB(80, 170, 255), ColorB = Color3.fromRGB(255, 60, 60), CoreColor = Color3.fromRGB(255, 255, 255),
	Width = 5, OrbSize = 9, ImpactSize = 45, ClashSoundId = "", ImpactSoundId = "", ParticleTexture = "",
	OnCameraShake = nil, OnHit = nil,
}
function M.Start(charA, charB, config)
	local c = C.merge(DEFAULTS, config)
	local s = {Progress = 0, _target = 0, Active = true}
	local ra, rb = C.root(charA), C.root(charB)
	if not ra or not rb then s.Active = false; function s:SetProgress() end; function s:Push() end; function s:End() end; return s end
	local f = C.folder("BeamStruggleVFX", 60)
	local shake = c.OnCameraShake or C.shake
	C.sound(c.ClashSoundId, ra)
	local beamA = C.part(f, Vector3.new(1, c.Width, c.Width), c.ColorA, Enum.PartType.Cylinder, 0.15)
	local beamB = C.part(f, Vector3.new(1, c.Width, c.Width), c.ColorB, Enum.PartType.Cylinder, 0.15)
	local coreA = C.part(f, Vector3.new(1, c.Width * 0.45, c.Width * 0.45), c.CoreColor, Enum.PartType.Cylinder)
	local coreB = C.part(f, Vector3.new(1, c.Width * 0.45, c.Width * 0.45), c.CoreColor, Enum.PartType.Cylinder)
	local orb = C.part(f, Vector3.one * c.OrbSize, c.CoreColor, Enum.PartType.Ball, 0.05)
	local orbShell = C.part(f, Vector3.one * c.OrbSize * 1.4, c.ColorA, Enum.PartType.Ball, 0.6)
	local light = C.light(orb, c.CoreColor, 50, 8)
	local att = Instance.new("Attachment"); att.Parent = orb
	local sparks = C.emitter(att, c.CoreColor, c.ColorA, {Rate = 120, Lifetime = NumberRange.new(0.15, 0.4), Speed = NumberRange.new(30, 60),
		Size = NumberSequence.new(0.3, 0), Squash = NumberSequence.new(3), SpreadAngle = Vector2.new(180, 180), Drag = 2})
	local debrisRing = C.part(f, Vector3.new(0.2, c.OrbSize * 2, c.OrbSize * 2), c.CoreColor, Enum.PartType.Cylinder, 0.7)
	local lastShake, lastRing = 0, 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not (ra.Parent and rb.Parent) then return end
		s.Progress += (s._target - s.Progress) * math.min(1, dt * 6)
		local a, b = C.hands(charA), C.hands(charB)
		local mid = a:Lerp(b, 0.5 + 0.45 * s.Progress)
		local now = os.clock()
		local function setBeam(p, core, from)
			local d = mid - from
			local cf = C.cylinderCF(from, d.Unit, d.Magnitude)
			local w = c.Width * (1 + 0.08 * math.sin(now * 55))
			p.CFrame, core.CFrame = cf, cf
			p.Size = Vector3.new(d.Magnitude, w, w)
			core.Size = Vector3.new(d.Magnitude, w * 0.45, w * 0.45)
		end
		setBeam(beamA, coreA, a)
		setBeam(beamB, coreB, b)
		local wob = 1 + 0.15 * math.sin(now * 30)
		orb.Position, orbShell.Position = mid, mid
		orb.Size = Vector3.one * c.OrbSize * wob
		orbShell.Size = Vector3.one * c.OrbSize * 1.4 * (2 - wob)
		orbShell.Color = c.ColorA:Lerp(c.ColorB, (s.Progress + 1) / 2)
		sparks.Color = ColorSequence.new(c.CoreColor, orbShell.Color)
		debrisRing.CFrame = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
		if now - lastRing > 0.35 then
			lastRing = now
			C.Shockwave(f, debrisRing.CFrame * CFrame.Angles(0, 0, math.rad(-90)), c.OrbSize, c.OrbSize * 4, orbShell.Color, 0.4, 0.2)
			if math.random() < 0.3 then C.DebrisBurst(workspace, mid - Vector3.new(0, 4, 0), 2, 35, nil, 1.5) end
		end
		if now - lastShake > 0.3 then lastShake = now; shake(0.8 + math.abs(s.Progress), 0.3) end
		light.Brightness = 6 + 4 * math.abs(math.sin(now * 20))
	end)
	function s:SetProgress(p) s._target = math.clamp(p, -1, 1) end
	function s:Push(side, amount) s:SetProgress(s._target + (side == "A" and 1 or -1) * (amount or 0.05)) end
	function s:End(winner)
		if not s.Active then return end
		s.Active = false
		conn:Disconnect()
		sparks.Enabled = false
		C.sound(c.ImpactSoundId, ra)
		C.ImpactFrame("invert", 3, {charA, charB})
		C.FOVPunch(12)
		local mid = orb.Position
		if winner == "A" or winner == "B" then
			local loser = winner == "A" and rb or ra
			local beam, core = winner == "A" and beamA or beamB, winner == "A" and coreA or coreB
			local from = winner == "A" and C.hands(charA) or C.hands(charB)
			local d = loser.Position - from
			C.tween(beam, 0.25, {Size = Vector3.new(d.Magnitude + 10, c.Width * 1.5, c.Width * 1.5), CFrame = C.cylinderCF(from, d.Unit, d.Magnitude + 10)})
			C.tween(core, 0.25, {Size = Vector3.new(d.Magnitude + 10, c.Width * 0.7, c.Width * 0.7), CFrame = C.cylinderCF(from, d.Unit, d.Magnitude + 10)})
			local other = winner == "A" and {beamB, coreB} or {beamA, coreA}
			for _, p in ipairs(other) do C.tween(p, 0.2, {Transparency = 1}) end
			C.tween(orb, 0.25, {Position = loser.Position})
			task.delay(0.3, function()
				C.arenaDamage(c, loser.Position, 20, 140)
				C.explosion(f, loser.Position, c.ImpactSize, winner == "A" and c.ColorA or c.ColorB, c.CoreColor, c.ParticleTexture, shake)
				if c.OnHit then c.OnHit(loser.Position, loser) end
			end)
		else
			C.arenaDamage(c, mid, 25, 160)
			C.explosion(f, mid, c.ImpactSize * 1.3, c.ColorA:Lerp(c.ColorB, 0.5), c.CoreColor, c.ParticleTexture, shake)
		end
		task.delay(0.4, function()
			for _, p in ipairs(f:GetChildren()) do if p:IsA("BasePart") then C.tween(p, 0.3, {Transparency = 1}) end end
		end)
		task.delay(2, function() f:Destroy() end)
	end
	return s
end
return M
