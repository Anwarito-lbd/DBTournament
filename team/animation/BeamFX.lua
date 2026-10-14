--!nonstrict
-- BeamFX (ModuleScript, client) — v1.1 quality pass for energy beams (db-animation contract kept: visual only).
-- BeamFX.Play(character, target: Vector3, style: string|table, cfg?)  styles: Kamehameha, FinalFlash, GalickGun, DeathBeam
-- Sequence: charge sphere at the hands (inward motes, light, rising whine) -> beam (white core + coloured glow +
-- outer haze + rotating double spiral + head bulb) -> impact (flash sphere, fireball, 2 shockwave rings,
-- debris sparks, smoke, light) + distance-scaled camera shake. BeamFX.SpiritBomb(character, target, cfg?).
-- Part budget: ~45 transient parts per beam, all CanCollide/CanQuery/CanTouch = false, auto-cleaned.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BeamFX = {}
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

BeamFX.Styles = {
	Kamehameha = { Core = rgb(240, 255, 255), Glow = rgb(60, 170, 255), Haze = rgb(30, 90, 255), Width = 5, Charge = 1.1,
		Duration = 1.4, Spiral = true, ImpactSize = 34, Shake = 3.5, ChargeAt = "hands", Speed = 420 },
	FinalFlash = { Core = rgb(255, 255, 230), Glow = rgb(255, 225, 60), Haze = rgb(255, 170, 20), Width = 8, Charge = 1.5,
		Duration = 1.6, Spiral = true, ImpactSize = 46, Shake = 5, ChargeAt = "hands", Speed = 380 },
	GalickGun = { Core = rgb(255, 230, 255), Glow = rgb(170, 60, 255), Haze = rgb(110, 20, 200), Width = 5.5, Charge = 1.0,
		Duration = 1.3, Spiral = true, ImpactSize = 34, Shake = 3.5, ChargeAt = "hands", Speed = 420 },
	DeathBeam = { Core = rgb(255, 230, 255), Glow = rgb(255, 60, 200), Haze = rgb(170, 30, 220), Width = 0.8, Charge = 0.25,
		Duration = 0.35, Spiral = false, ImpactSize = 9, Shake = 0.8, ChargeAt = "finger", Speed = 900 },
}

local function part(parent, size, color, shape, transp, mat)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Material = mat or Enum.Material.Neon
	p.Color = color; p.Size = size; p.Transparency = transp or 0
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function tween(i, t, goal, style, dir)
	local tw = TweenService:Create(i, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play(); return tw
end
local function light(parent, color, range, brightness)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = brightness; l.Shadows = false; l.Parent = parent
	return l
end
local function emitter(parent, c1, c2, props)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(c1, c2)
	e.LightEmission = 1; e.LightInfluence = 0
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	for k, v in props do e[k] = v end
	e.Parent = parent
	return e
end

function BeamFX.shake(intensity, duration)
	local cam = workspace.CurrentCamera
	if not cam or not RunService:IsClient() or intensity <= 0 then return end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = os.clock() - t0
		if a > duration then conn:Disconnect() return end
		local k = intensity * (1 - a / duration) ^ 2
		cam.CFrame *= CFrame.new((math.random() - 0.5) * k * 0.15, (math.random() - 0.5) * k * 0.15, 0)
			* CFrame.Angles(math.rad((math.random() - 0.5) * k), math.rad((math.random() - 0.5) * k), 0)
	end)
end
local function shakeAt(pos, intensity, duration)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local d = (cam.CFrame.Position - pos).Magnitude
	BeamFX.shake(intensity * math.clamp(1 - d / 400, 0.15, 1), duration)
end

local function rootOf(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end
local function handsPos(ch, mode)
	local root = rootOf(ch)
	if not root then return nil end
	if mode == "finger" then
		local h = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
		if h then return h.Position + root.CFrame.LookVector * 1.5 end
	end
	return root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 0.5, 0)
end

-- Impact: flash + fireball + double shockwave + sparks + smoke + light + shake
function BeamFX.Impact(pos, size, glow, core, shake, folder)
	folder = folder or workspace
	local f = Instance.new("Folder"); f.Name = "BeamImpact"; f.Parent = folder
	Debris:AddItem(f, 3)
	local flash = part(f, Vector3.one * 2, core, Enum.PartType.Ball, 0)
	flash.Position = pos
	tween(flash, 0.18, { Size = Vector3.one * size * 0.9 })
	task.delay(0.18, function() tween(flash, 0.5, { Size = Vector3.one * size * 1.2, Transparency = 1 }) end)
	local fire = part(f, Vector3.one * 4, glow, Enum.PartType.Ball, 0.2)
	fire.Position = pos
	tween(fire, 0.7, { Size = Vector3.one * size * 1.6, Transparency = 1, Color = Color3.new(1, 1, 1):Lerp(glow, 0.3) }, Enum.EasingStyle.Quart)
	light(flash, glow, size * 3, 12)
	for i, t in { 0.45, 0.8 } do
		local ring = part(f, Vector3.new(0.6, 4, 4), if i == 1 then core else glow, Enum.PartType.Cylinder, 0.1)
		ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		task.delay((i - 1) * 0.08, function()
			tween(ring, t, { Size = Vector3.new(0.2, size * (2 + i), size * (2 + i)), Transparency = 1 }, Enum.EasingStyle.Quart)
		end)
	end
	local a = Instance.new("Attachment"); a.WorldPosition = pos; a.Parent = workspace.Terrain
	Debris:AddItem(a, 3)
	local sparks = emitter(a, core, glow, { Rate = 0, Lifetime = NumberRange.new(0.4, 1.1), Speed = NumberRange.new(40, 110),
		Size = NumberSequence.new(1.6, 0), SpreadAngle = Vector2.new(180, 180), Drag = 3, Acceleration = Vector3.new(0, -40, 0) })
	sparks:Emit(math.floor(40 + size))
	local smoke = emitter(a, rgb(90, 80, 110), rgb(30, 25, 40), { Rate = 0, Lifetime = NumberRange.new(1.2, 2.2),
		Speed = NumberRange.new(8, 25), Size = NumberSequence.new(size * 0.3, size * 0.6), SpreadAngle = Vector2.new(180, 180),
		Drag = 2, LightEmission = 0, RotSpeed = NumberRange.new(-60, 60) })
	smoke.Transparency = NumberSequence.new(0.4, 1)
	smoke:Emit(18)
	shakeAt(pos, shake or 3, 0.7)
end

function BeamFX.Play(character, target, style, cfg)
	local s = if type(style) == "table" then style else (BeamFX.Styles[style or "Kamehameha"] or BeamFX.Styles.Kamehameha)
	if cfg then s = table.clone(s); for k, v in cfg do s[k] = v end end
	local root = rootOf(character)
	if not root or typeof(target) ~= "Vector3" then return end
	local f = Instance.new("Folder"); f.Name = "BeamFX"; f.Parent = workspace
	Debris:AddItem(f, s.Charge + s.Duration + 4)

	-- 1) charge sphere
	local origin = handsPos(character, s.ChargeAt)
	local ball = part(f, Vector3.one * 0.5, s.Core, Enum.PartType.Ball, 0)
	local shell = part(f, Vector3.one * 1, s.Glow, Enum.PartType.Ball, 0.35)
	ball.Position = origin; shell.Position = origin
	local l = light(ball, s.Glow, 6, 3)
	local att = Instance.new("Attachment"); att.Parent = ball
	local motes = emitter(att, s.Core, s.Glow, { Rate = 70, Lifetime = NumberRange.new(0.25, 0.4), Speed = NumberRange.new(-14, -9),
		Size = NumberSequence.new(0.5, 0), SpreadAngle = Vector2.new(180, 180), EmissionDirection = Enum.NormalId.Top })
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local p = handsPos(character, s.ChargeAt)
		if p then origin = p end
		local k = math.clamp((os.clock() - t0) / math.max(0.01, s.Charge), 0, 1)
		local pulse = 1 + math.sin(os.clock() * 30) * 0.08
		ball.Size = Vector3.one * (0.5 + s.Width * 0.7 * k) * pulse
		shell.Size = ball.Size * 1.6
		ball.Position = origin; shell.Position = origin
		l.Range = 6 + 20 * k; l.Brightness = 3 + 6 * k
	end)
	task.wait(s.Charge)
	conn:Disconnect()
	motes.Enabled = false
	if not root.Parent then f:Destroy() return end

	-- 2) beam
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, f }
	local dirV = target - origin
	local dir = if dirV.Magnitude > 0.1 then dirV.Unit else root.CFrame.LookVector
	local maxLen = math.max(10, dirV.Magnitude + 2)
	local hit = workspace:Raycast(origin, dir * maxLen, params)
	local endPos = if hit then hit.Position else origin + dir * maxLen
	local length = (endPos - origin).Magnitude
	local w = s.Width
	local core = part(f, Vector3.new(0.1, w * 0.55, w * 0.55), s.Core, Enum.PartType.Cylinder, 0)
	local glow = part(f, Vector3.new(0.1, w, w), s.Glow, Enum.PartType.Cylinder, 0.25)
	local haze = part(f, Vector3.new(0.1, w * 1.7, w * 1.7), s.Haze, Enum.PartType.Cylinder, 0.72)
	local head = part(f, Vector3.one * w * 1.5, s.Glow, Enum.PartType.Ball, 0.15)
	local headCore = part(f, Vector3.one * w * 1.0, s.Core, Enum.PartType.Ball, 0)
	light(head, s.Glow, 30, 8)
	local spiral = {}
	if s.Spiral then
		for i = 1, 24 do
			local sp = part(f, Vector3.new(w * 0.22, w * 0.22, w * 0.9), if i % 2 == 0 then s.Core else s.Glow, nil, 0.2)
			spiral[i] = sp
		end
	end
	local cur = 0
	local tBeam = os.clock()
	local function place(len)
		local cf = CFrame.lookAt(origin, origin + dir)
		local mid = cf * CFrame.new(0, 0, -len / 2) * CFrame.Angles(0, math.rad(90), 0)
		core.Size = Vector3.new(len, core.Size.Y, core.Size.Z); core.CFrame = mid
		glow.Size = Vector3.new(len, glow.Size.Y, glow.Size.Z); glow.CFrame = mid
		haze.Size = Vector3.new(len, haze.Size.Y, haze.Size.Z); haze.CFrame = mid
		local hp = origin + dir * len
		head.Position = hp; headCore.Position = hp
		if #spiral > 0 then
			local rot = (os.clock() - tBeam) * 12
			for i, sp in spiral do
				local strand = i % 2
				local frac = ((i - strand) / #spiral)
				local along = frac * len
				local a = rot + frac * math.pi * 6 + strand * math.pi
				local off = Vector3.new(math.cos(a), math.sin(a), 0) * w * 0.75
				sp.CFrame = cf * CFrame.new(off) * CFrame.new(0, 0, -along)
				sp.Transparency = if along > len then 1 else 0.2
			end
		end
		local flick = 1 + math.sin(os.clock() * 45) * 0.06
		glow.Size = Vector3.new(len, w * flick, w * flick)
	end
	local impacted = false
	conn = RunService.RenderStepped:Connect(function(dt)
		cur = math.min(length, cur + s.Speed * dt)
		place(math.max(0.5, cur))
		if cur >= length and not impacted then
			impacted = true
			BeamFX.Impact(endPos, s.ImpactSize, s.Glow, s.Core, s.Shake, f.Parent)
		end
	end)
	shakeAt(origin, s.Shake * 0.35, s.Duration)
	task.wait(s.Duration)
	conn:Disconnect()
	if not impacted then BeamFX.Impact(endPos, s.ImpactSize, s.Glow, s.Core, s.Shake, f.Parent) end
	ball:Destroy(); shell:Destroy()
	for _, p in { core, glow, haze, head, headCore } do
		tween(p, 0.35, { Transparency = 1, Size = Vector3.new(p.Size.X, p.Size.Y * 0.2, p.Size.Z * 0.2) })
	end
	for _, sp in spiral do tween(sp, 0.3, { Transparency = 1 }) end
	Debris:AddItem(f, 0.6)
	return endPos
end

-- Spirit Bomb: huge blue-white sphere gathered above the caster (motes stream in), then thrown at target.
function BeamFX.SpiritBomb(character, target, cfg)
	cfg = cfg or {}
	local root = rootOf(character)
	if not root or typeof(target) ~= "Vector3" then return end
	local f = Instance.new("Folder"); f.Name = "SpiritBombFX"; f.Parent = workspace
	local gather = cfg.ChargeTime or 3
	local radius = cfg.Radius or 22
	local core = part(f, Vector3.one, rgb(230, 250, 255), Enum.PartType.Ball, 0)
	local shell = part(f, Vector3.one, rgb(90, 190, 255), Enum.PartType.Ball, 0.35)
	local haze = part(f, Vector3.one, rgb(60, 140, 255), Enum.PartType.Ball, 0.75, Enum.Material.ForceField)
	light(core, rgb(120, 200, 255), 60, 6)
	local att = Instance.new("Attachment"); att.Parent = core
	local motes = emitter(att, rgb(255, 255, 255), rgb(100, 200, 255), { Rate = 120, Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(-60, -40), Size = NumberSequence.new(1.2, 0.2), SpreadAngle = Vector2.new(180, 180) })
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / gather, 0, 1)
		local r = 2 + radius * 2 * k
		local c = root.Position + Vector3.new(0, 14 + r * 0.6, 0)
		core.Size = Vector3.one * r * 0.75; shell.Size = Vector3.one * r; haze.Size = Vector3.one * r * 1.25
		core.Position = c; shell.Position = c; haze.Position = c
	end)
	task.wait(gather)
	conn:Disconnect()
	motes.Enabled = false
	local from = core.Position
	local travel = math.max(0.6, (target - from).Magnitude / 120)
	for _, p in { core, shell, haze } do tween(p, travel, { Position = target }, Enum.EasingStyle.Sine, Enum.EasingDirection.In) end
	task.wait(travel)
	BeamFX.Impact(target, radius * 3, rgb(90, 190, 255), rgb(240, 255, 255), 6, workspace)
	for _, p in { core, shell, haze } do tween(p, 0.6, { Size = p.Size * 1.8, Transparency = 1 }) end
	Debris:AddItem(f, 1)
	return target
end

return BeamFX
