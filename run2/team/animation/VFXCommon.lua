--!nonstrict
-- VFXCommon (ModuleScript) - shared helpers for all VFX modules. Place all VFX modules in the same Folder.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local C = {}

function C.merge(defaults, cfg)
	local out = table.clone(defaults)
	if cfg then
		for k, v in pairs(cfg) do
			out[k] = v
		end
	end
	return out
end

function C.folder(name, life)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = workspace
	Debris:AddItem(f, life or 15)
	return f
end

function C.part(parent, size, color, shape, transparency)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Color, p.Size = color, size
	p.Transparency = transparency or 0
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

function C.tween(i, t, goal, style, dir)
	local tw =
		TweenService:Create(i, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

function C.sound(id, parent, volume)
	if not id or id == "" then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 1
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 10)
	return s
end

function C.light(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = color, range, brightness
	l.Parent = parent
	return l
end

function C.emitter(parent, c1, c2, props, texture)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(c1, c2)
	e.LightEmission = 1
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	if texture and texture ~= "" then
		e.Texture = texture
	end
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = parent
	return e
end

function C.worldAttachment(pos)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	return a
end

function C.root(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

function C.limb(character, names)
	for _, n in ipairs(names) do
		local p = character:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return C.root(character)
end

function C.hands(character)
	local l = C.limb(character, { "LeftHand", "Left Arm" })
	local r = C.limb(character, { "RightHand", "Right Arm" })
	if l and r then
		return (l.Position + r.Position) / 2
	end
	local root = C.root(character)
	return root and root.Position or Vector3.zero
end

function C.direction(origin, target)
	if typeof(target) == "Instance" then
		return (target.Position - origin).Unit
	end
	if target.Magnitude <= 1.01 then
		return target.Unit
	end
	return (target - origin).Unit
end

function C.rayParams(exclude)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = exclude
	return p
end

-- Legacy shake (replaced by spring C.CameraShake below; kept as C.legacyShake).
function C.legacyShake(intensity, duration)
	local cam = workspace.CurrentCamera
	if not cam or not RunService:IsClient() then
		return
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = os.clock() - t0
		if a > duration then
			conn:Disconnect()
			return
		end
		local k = intensity * (1 - a / duration)
		cam.CFrame *= CFrame.Angles(math.rad((math.random() - 0.5) * k), math.rad((math.random() - 0.5) * k), 0)
	end)
end

-- Cylinder spanning origin -> origin + dir*length
function C.cylinderCF(origin, dir, length)
	return CFrame.lookAt(origin, origin + dir) * CFrame.new(0, 0, -length / 2) * CFrame.Angles(0, math.rad(90), 0)
end

-- Explosion: sphere + ring + burst + flash
function C.explosion(parent, pos, size, color, core, texture, shakeFn)
	local boom = C.part(parent, Vector3.one * 2, core, Enum.PartType.Ball)
	boom.Position = pos
	C.tween(boom, 0.45, { Size = Vector3.one * size, Transparency = 1, Color = color })
	C.light(boom, color, size * 2, 10)
	local ring = C.part(parent, Vector3.new(0.4, 2, 2), color, Enum.PartType.Cylinder, 0.2)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	C.tween(ring, 0.55, { Size = Vector3.new(0.2, size * 2, size * 2), Transparency = 1 })
	local a = C.worldAttachment(pos)
	local e = C.emitter(a, core, color, {
		Rate = 0,
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(30, 60),
		Size = NumberSequence.new(2, 0),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 4,
	}, texture)
	e:Emit(C.q and C.q(60) or 60)
	Debris:AddItem(a, 1.5)
	if C.Impact then
		C.Impact(parent, pos, size, color, core, size >= 40 and "Ultimate" or size >= 20 and "Heavy" or "Medium")
		if shakeFn and shakeFn ~= C.shake and shakeFn ~= C.CameraShake then
			shakeFn(3, 0.5)
		end
	elseif shakeFn then
		shakeFn(3, 0.5)
	end
end

-- db-map integration: ArenaDamage.DamageAt(pos, radius, power).
-- Verified against team/map/ArenaDamage.lua + layout_spec.md: ModuleScript ServerScriptService.ArenaDamage,
-- DamageAt(pos: Vector3, radius: number (clamped 1-60), power: number): number (chunks hit), SERVER-ONLY (asserts IsServer).
-- So on clients this hook is a no-op (unless OnArenaDamage is supplied); the server calls it in the RemoteEvent flow.
-- Config keys: ArenaDamage (default: false on client, true on server), ArenaDamagePath ({"ServerScriptService","ArenaDamage"}),
-- ArenaRadius, ArenaPower, OnArenaDamage(pos, radius, power) override hook.
-- IMPORTANT: terrain/arena destruction should be authoritative on the SERVER. In the RemoteEvent flow the server calls
-- VFXCommon.arenaDamage (or ArenaDamage.DamageAt) itself when it resolves the hit; clients pass ArenaDamage=false
-- or leave it default: on a client this only damages locally if the ArenaDamage module allows it.
local arenaCache
function C.getArenaDamage(path)
	if arenaCache ~= nil then
		return arenaCache or nil
	end
	path = path or { "ServerScriptService", "ArenaDamage" }
	local ok, mod = pcall(function()
		local node = game:GetService(path[1])
		for i = 2, #path do
			node = node and node:FindFirstChild(path[i])
		end
		return node and node:IsA("ModuleScript") and require(node) or nil
	end)
	arenaCache = (ok and mod) or false
	return arenaCache or nil
end
function C.arenaDamage(cfg, pos, radius, power)
	-- Default: disabled on clients, enabled on server. Clients should pass ArenaDamage=false explicitly.
	local enabled = cfg.ArenaDamage
	if enabled == nil then
		enabled = RunService:IsServer()
	end
	if not enabled then
		return
	end
	radius, power = cfg.ArenaRadius or radius, cfg.ArenaPower or power
	if cfg.OnArenaDamage then
		task.spawn(cfg.OnArenaDamage, pos, radius, power)
		return
	end
	if not RunService:IsServer() then
		return
	end
	local mod = C.getArenaDamage(cfg.ArenaDamagePath)
	if mod and mod.DamageAt then
		local ok, err = pcall(mod.DamageAt, pos, radius, power)
		if not ok then
			warn("ArenaDamage.DamageAt failed:", err)
		end
	end
end

--==================================================================================================
-- v5 HIGH-QUALITY PRIMITIVES (see VFX_QUALITY_BAR.md). All client-only visuals; safe no-ops on server.
--==================================================================================================
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")

-- Performance budget ------------------------------------------------------------------------------
-- Quality: 3 = high (PC), 2 = medium, 1 = low (mobile default). Scale multiplies particle counts/rates.
C.Quality = {
	Level = 3,
	Scale = 1,
	MaxParticles = 1500,
	MaxDebris = 40,
	MaxAfterimages = 24,
	ImpactFrames = true,
	SpeedLines = true,
}
local QUALITY_TABLE = {
	[1] = {
		Scale = 0.35,
		MaxParticles = 400,
		MaxDebris = 10,
		MaxAfterimages = 6,
		ImpactFrames = true,
		SpeedLines = false,
	},
	[2] = {
		Scale = 0.65,
		MaxParticles = 900,
		MaxDebris = 24,
		MaxAfterimages = 14,
		ImpactFrames = true,
		SpeedLines = true,
	},
	[3] = {
		Scale = 1.0,
		MaxParticles = 1500,
		MaxDebris = 40,
		MaxAfterimages = 24,
		ImpactFrames = true,
		SpeedLines = true,
	},
}
function C.SetQuality(level)
	level = math.clamp(level, 1, 3)
	C.Quality.Level = level
	for k, v in pairs(QUALITY_TABLE[level]) do
		C.Quality[k] = v
	end
end
-- Auto: touch-only devices start at medium-low; players can override via settings UI calling SetQuality.
if RunService:IsClient() then
	local ok, touch = pcall(function()
		return UIS.TouchEnabled and not UIS.KeyboardEnabled
	end)
	C.SetQuality((ok and touch) and 1 or 3)
end
function C.q(n)
	return math.max(1, math.floor(n * C.Quality.Scale + 0.5))
end
local liveDebris, liveAfter = 0, 0

local function playerGui()
	local lp = Players.LocalPlayer
	return lp and lp:FindFirstChildOfClass("PlayerGui")
end

-- ImpactFrame -------------------------------------------------------------------------------------
-- Full-screen flash for `frames` (1-3 @60fps). mode: "white" | "black" | "invert" (black screen + white silhouettes
-- of `subjects` via Highlight, then white screen + black silhouettes) - the anime "impact frame".
local lastImpactFrame = 0
function C.ImpactFrame(mode, frames, subjects)
	if not RunService:IsClient() or not C.Quality.ImpactFrames then
		return
	end
	if os.clock() - lastImpactFrame < 0.25 then
		return
	end -- anti-strobe
	lastImpactFrame = os.clock()
	local pg = playerGui()
	if not pg then
		return
	end
	frames = frames or 2
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.DisplayOrder, gui.ResetOnSpawn = "ImpactFrame", true, 1000, false
	local fr = Instance.new("Frame")
	fr.Size, fr.BorderSizePixel = UDim2.fromScale(1, 1), 0
	fr.BackgroundColor3 = mode == "white" and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	fr.BackgroundTransparency = mode == "invert" and 0 or 0.05
	fr.Parent = gui
	local hls = {}
	if mode == "invert" and subjects then
		-- Highlights render above ScreenGui? No: Highlights are 3D. So we use a semi-opaque frame and AlwaysOnTop highlights.
		fr.BackgroundTransparency = 0.12
		for _, m in ipairs(subjects) do
			local h = Instance.new("Highlight")
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.FillColor, h.FillTransparency, h.OutlineColor, h.OutlineTransparency =
				Color3.new(1, 1, 1), 0, Color3.new(1, 1, 1), 0
			h.Parent = m
			table.insert(hls, h)
		end
	end
	gui.Parent = pg
	task.spawn(function()
		for i = 1, frames do
			RunService.RenderStepped:Wait()
		end
		if mode == "invert" then
			fr.BackgroundColor3 = Color3.new(1, 1, 1)
			for _, h in ipairs(hls) do
				h.FillColor, h.OutlineColor = Color3.new(0, 0, 0), Color3.new(0, 0, 0)
			end
			RunService.RenderStepped:Wait()
		end
		gui:Destroy()
		for _, h in ipairs(hls) do
			h:Destroy()
		end
	end)
end

-- Hitstop -----------------------------------------------------------------------------------------
-- Freezes AnimationTracks on given characters for `frames` @60fps, then restores speeds.
-- C.HitstopHook(fn) lets gameplay add its own freeze (e.g. pause velocity) - fn(characters, seconds).
local hitstopHooks = {}
function C.HitstopHook(fn)
	table.insert(hitstopHooks, fn)
end
C.HITSTOP = { Light = 3, Medium = 5, Heavy = 8, Finisher = 12, Ultimate = 16 }
function C.Hitstop(characters, frames)
	frames = typeof(frames) == "string" and C.HITSTOP[frames] or frames or 5
	local secs = frames / 60
	for _, fn in ipairs(hitstopHooks) do
		task.spawn(fn, characters, secs)
	end
	local saved = {}
	for _, ch in ipairs(characters) do
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local an = hum and hum:FindFirstChildOfClass("Animator")
		if an then
			for _, tr in ipairs(an:GetPlayingAnimationTracks()) do
				table.insert(saved, { tr, tr.Speed })
				tr:AdjustSpeed(0)
			end
		end
	end
	task.delay(secs, function()
		for _, s in ipairs(saved) do
			if s[1].IsPlaying then
				s[1]:AdjustSpeed(s[2])
			end
		end
	end)
	return secs
end

-- Spring camera shake + FOV punch (client) -------------------------------------------------------
-- One shared RenderStepped binding; impulses add trauma. Shake uses trauma^2 * maxAngle with noise.
local cam = { trauma = 0, fovOffset = 0, fovVel = 0, bound = false, baseFov = nil }
local function bindCamera()
	if cam.bound or not RunService:IsClient() then
		return
	end
	cam.bound = true
	local seed = math.random() * 1000
	RunService:BindToRenderStep("DBZ_VFXCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local cc = workspace.CurrentCamera
		if not cc then
			return
		end
		-- FOV spring (critically-damped-ish): k=180, d=18
		local k, d = 180, 18
		local acc = -k * cam.fovOffset - d * cam.fovVel
		cam.fovVel += acc * dt
		cam.fovOffset += cam.fovVel * dt
		if math.abs(cam.fovOffset) > 0.01 or math.abs(cam.fovVel) > 0.01 then
			cam.baseFov = cam.baseFov or cc.FieldOfView
			cc.FieldOfView = cam.baseFov + cam.fovOffset
		elseif cam.baseFov then
			cc.FieldOfView = cam.baseFov
			cam.baseFov = nil
		end
		if cam.trauma > 0 then
			local t = os.clock() * 25
			local amt = cam.trauma * cam.trauma
			local maxDeg = 4
			cc.CFrame *= CFrame.Angles(
				math.rad(maxDeg * amt * math.noise(seed, t)),
				math.rad(maxDeg * amt * math.noise(seed + 1, t)),
				math.rad(maxDeg * 0.5 * amt * math.noise(seed + 2, t))
			)
			cam.trauma = math.max(0, cam.trauma - dt * 1.6)
		end
	end)
end
-- intensity 0..1+ (old API passed 0.3..5; normalized /5 when > 1), duration accepted for compatibility.
function C.CameraShake(intensity, duration)
	if not RunService:IsClient() then
		return
	end
	bindCamera()
	local t = intensity > 1 and intensity / 5 or intensity
	if duration and duration > 0.6 then
		t *= 1.15
	end
	cam.trauma = math.clamp(cam.trauma + t, 0, 1)
end
-- amount in degrees (+ widens = punch out, - narrows = zoom in). Spring returns to base.
function C.FOVPunch(amount)
	if not RunService:IsClient() then
		return
	end
	bindCamera()
	cam.fovVel += (amount or 8) * 12
end
-- Back-compat: old C.shake(intensity, duration) now routes to the spring shake.
C.shake = C.CameraShake

-- Speed lines (radial ScreenGui) -----------------------------------------------------------------
function C.SpeedLines(duration, color, count)
	if not RunService:IsClient() or not C.Quality.SpeedLines then
		return
	end
	local pg = playerGui()
	if not pg then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.DisplayOrder, gui.ResetOnSpawn = "SpeedLines", true, 900, false
	gui.Parent = pg
	count = C.q(count or 40)
	color = color or Color3.new(1, 1, 1)
	local lines = {}
	for i = 1, count do
		local l = Instance.new("Frame")
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, 0.5)
		l.BorderSizePixel = 0
		l.BackgroundColor3 = color
		l.Rotation = (i / count) * 360 + math.random() * 6
		l.Parent = gui
		lines[i] = { f = l, inner = 0.18 + math.random() * 0.12, w = 1 + math.random() * 3 }
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = (os.clock() - t0) / duration
		if a >= 1 then
			conn:Disconnect()
			gui:Destroy()
			return
		end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local R = vp.Magnitude * 0.6
		for _, l in ipairs(lines) do
			local flick = math.random() < 0.3
			l.f.Visible = not flick
			l.f.Size = UDim2.fromOffset(R * (1 - l.inner), l.w)
			-- offset each line from the center along its rotation
			local ang = math.rad(l.f.Rotation)
			local off = R * (l.inner + (1 - l.inner) / 2) -- Rotation pivots on the frame center
			l.f.Position = UDim2.new(0.5, math.cos(ang) * off, 0.5, math.sin(ang) * off)
			l.f.BackgroundTransparency = 0.25 + 0.75 * a
		end
	end)
end

-- Shockwave ring (horizontal or oriented) --------------------------------------------------------
function C.Shockwave(parent, cf, startSize, endSize, color, time, thickness)
	local r = C.part(parent, Vector3.new(thickness or 0.4, startSize, startSize), color, Enum.PartType.Cylinder, 0.1)
	r.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	C.tween(r, time or 0.45, { Size = Vector3.new(0.05, endSize, endSize), Transparency = 1 }, Enum.EasingStyle.Quart)
	-- secondary thin ring for layered read
	local r2 = C.part(
		parent,
		Vector3.new(0.15, startSize * 0.8, startSize * 0.8),
		Color3.new(1, 1, 1),
		Enum.PartType.Cylinder,
		0.3
	)
	r2.CFrame = r.CFrame
	C.tween(
		r2,
		(time or 0.45) * 0.7,
		{ Size = Vector3.new(0.02, endSize * 0.8, endSize * 0.8), Transparency = 1 },
		Enum.EasingStyle.Quart
	)
	Debris:AddItem(r, (time or 0.45) + 0.1)
	Debris:AddItem(r2, (time or 0.45) + 0.1)
	return r
end

-- Ground cracks (radial neon-edged slate strips) ------------------------------------------------
function C.GroundCrack(parent, center, radius, count, color, life)
	count = C.q(count or 10)
	local list = {}
	for i = 1, count do
		local ang = (i / count) * math.pi * 2 + math.random() * 0.5
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local len = radius * (0.5 + math.random() * 0.5)
		local cr = C.part(parent, Vector3.new(0.35, 0.12, 0.1), Color3.fromRGB(28, 22, 20), nil, 0)
		cr.Material = Enum.Material.Slate
		local glow = C.part(parent, Vector3.new(0.12, 0.13, 0.1), color or Color3.fromHex("FFC86E"), nil, 0.2)
		local base = center + Vector3.new(0, 0.06, 0)
		local function set(l)
			local cf = CFrame.lookAt(base + dir * 1.2, base + dir * 2) * CFrame.new(0, 0, -l / 2)
			cr.CFrame, glow.CFrame = cf, cf * CFrame.new(0, 0.01, 0)
			cr.Size = Vector3.new(0.35, 0.12, l)
			glow.Size = Vector3.new(0.12, 0.13, l)
		end
		set(0.2)
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.12 do
				set(0.2 + len * (os.clock() - t0) / 0.12)
				task.wait()
			end
			set(len)
			C.tween(glow, 0.8, { Transparency = 1 })
			task.wait((life or 3) - 0.8)
			C.tween(cr, 0.8, { Transparency = 1 })
		end)
		Debris:AddItem(cr, (life or 3) + 0.2)
		Debris:AddItem(glow, (life or 3) + 0.2)
		table.insert(list, cr)
	end
	return list
end

-- Debris chunks with physics + cleanup ------------------------------------------------------------
function C.DebrisBurst(parent, pos, count, power, color, life)
	count = math.min(C.q(count or 10), C.Quality.MaxDebris - liveDebris)
	for _ = 1, count do
		liveDebris += 1
		local s = 0.4 + math.random() * 1.3
		local p = Instance.new("Part")
		p.Size = Vector3.new(s, s * 0.7, s * 0.9)
		p.Material = Enum.Material.Rock
		p.Color = color or Color3.fromRGB(105, 92, 80)
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false
		p.CollisionGroup = "Default"
		p.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		p.AssemblyLinearVelocity = Vector3.new(math.random() - 0.5, 0.8 + math.random() * 0.6, math.random() - 0.5).Unit
			* (power or 50)
			* (0.6 + math.random() * 0.6)
		p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		p.Parent = parent
		task.delay((life or 2.5) - 0.5, function()
			if p.Parent then
				C.tween(p, 0.5, { Transparency = 1, Size = p.Size * 0.4 })
			end
		end)
		task.delay(life or 2.5, function()
			liveDebris -= 1
			p:Destroy()
		end)
	end
end

-- Afterimage (character clone, transparent fade) ------------------------------------------------
function C.Afterimage(character, color, life, startTransparency)
	if liveAfter >= C.Quality.MaxAfterimages then
		return
	end
	local root = C.root(character)
	if not root then
		return
	end
	liveAfter += 1
	local folder = Instance.new("Folder")
	folder.Name = "Afterimage"
	folder.Parent = workspace
	for _, bp in ipairs(character:GetDescendants()) do
		if bp:IsA("BasePart") and bp ~= root and bp.Transparency < 1 then
			local g = bp:Clone()
			for _, ch in ipairs(g:GetChildren()) do
				if not ch:IsA("SpecialMesh") and not ch:IsA("DataModelMesh") then
					ch:Destroy()
				end
			end
			g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = true, false, false, false, false
			g.Material = Enum.Material.Neon
			if g:IsA("MeshPart") then
				g.TextureID = ""
			end
			g.Color = color or Color3.fromRGB(220, 230, 255)
			g.Transparency = startTransparency or 0.35
			g.CFrame = bp.CFrame
			g.Parent = folder
			C.tween(g, life or 0.35, { Transparency = 1 })
		end
	end
	task.delay((life or 0.35) + 0.05, function()
		liveAfter -= 1
		folder:Destroy()
	end)
end

-- AuraEmitter(formId): layered aura (flame body, wisps, core glow, sparks, light) with flicker -----
C.AURAS = {
	SSJ = { Primary = "FFD84A", Secondary = "FFF3B0", Core = "FFFFFF", Rate = 45, Sparks = false },
	SSJ2 = {
		Primary = "FFE15A",
		Secondary = "FFF6C0",
		Core = "FFFFFF",
		Rate = 55,
		Sparks = true,
		SparkColor = "BFE6FF",
	},
	SSJ3 = {
		Primary = "FFC828",
		Secondary = "FFE88A",
		Core = "FFFFFF",
		Rate = 65,
		Sparks = true,
		SparkColor = "BFE6FF",
	},
	SSG = { Primary = "FF4A3A", Secondary = "FF9A6A", Core = "FFE0C8", Rate = 35, Sparks = false },
	SSB = { Primary = "3AD7FF", Secondary = "9FEFFF", Core = "FFFFFF", Rate = 45, Sparks = true, SparkColor = "E0FAFF" },
	SSBEvolved = {
		Primary = "2A55E8",
		Secondary = "6F8CFF",
		Core = "D8E2FF",
		Rate = 60,
		Sparks = true,
		SparkColor = "9FB8FF",
	},
	UISign = { Primary = "C8D2FF", Secondary = "8C9CFF", Core = "FFFFFF", Rate = 30, Sparks = false, Shimmer = true },
	MUI = { Primary = "E8EEFF", Secondary = "B8C4FF", Core = "FFFFFF", Rate = 35, Sparks = false, Shimmer = true },
	UltraEgo = {
		Primary = "9A4AFF",
		Secondary = "FF78C8",
		Core = "2A0A3A",
		Rate = 50,
		Sparks = true,
		SparkColor = "FF78C8",
	},
	BeastGohan = {
		Primary = "FF3C46",
		Secondary = "FFFFFF",
		Core = "FFFFFF",
		Rate = 55,
		Sparks = true,
		SparkColor = "FF9AA0",
	},
	GoldenFrieza = { Primary = "FFC400", Secondary = "FFF0A0", Core = "FFFFFF", Rate = 40, Sparks = false },
	FriezaBlack = {
		Primary = "96286E",
		Secondary = "FF3C78",
		Core = "140A19",
		Rate = 45,
		Sparks = true,
		SparkColor = "FF3C78",
	},
	FriezaFullPower = { Primary = "C77DFF", Secondary = "FFB0F0", Core = "FFFFFF", Rate = 30, Sparks = false },
	KaioKen = { Primary = "FF2828", Secondary = "FF9090", Core = "FFFFFF", Rate = 50, Sparks = false },
	JirenFullPower = { Primary = "FF3B3B", Secondary = "FFAA78", Core = "FFFFFF", Rate = 55, Sparks = false },
	ToppoGoD = { Primary = "8B3AFF", Secondary = "C08AFF", Core = "1A0A2A", Rate = 45, Sparks = false },
	Default = { Primary = "FFFFFF", Secondary = "DDDDDD", Core = "FFFFFF", Rate = 35, Sparks = false },
}
function C.AuraEmitter(character, formId, opts)
	opts = opts or {}
	local root = C.root(character)
	local h = {}
	if not root then
		function h:SetIntensity() end
		function h:Destroy() end
		return h
	end
	local spec = C.AURAS[formId] or C.AURAS.Default
	local P, S, K = Color3.fromHex(spec.Primary), Color3.fromHex(spec.Secondary), Color3.fromHex(spec.Core)
	local scale = opts.Scale or 1
	local att = Instance.new("Attachment")
	att.Name = "Aura_" .. tostring(formId)
	att.Position = Vector3.new(0, -1.5, 0)
	att.Parent = root
	-- layer 1: flame body (spec in VFX_QUALITY_BAR.md "Aura")
	local body = C.emitter(att, S, P, {
		Rate = C.q(spec.Rate),
		Lifetime = NumberRange.new(0.35, 0.6),
		Speed = NumberRange.new(2, 5),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.8 * scale),
			NumberSequenceKeypoint.new(0.5, 2.4 * scale),
			NumberSequenceKeypoint.new(1, 0.4 * scale),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Acceleration = Vector3.new(0, 28, 0),
		Drag = 2,
		SpreadAngle = Vector2.new(12, 12),
		Shape = Enum.ParticleEmitterShape.Cylinder,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		LockedToPart = true,
		ZOffset = -1,
	})
	-- layer 2: thin upward wisps
	local wisps = C.emitter(att, K, P, {
		Rate = C.q(spec.Rate * 0.6),
		Lifetime = NumberRange.new(0.25, 0.4),
		Speed = NumberRange.new(10, 16),
		Size = NumberSequence.new(0.25 * scale, 0),
		Squash = NumberSequence.new(-2.5),
		Acceleration = Vector3.new(0, 40, 0),
		SpreadAngle = Vector2.new(8, 8),
		LockedToPart = true,
	})
	local layers = { body, wisps }
	if spec.Sparks then
		local sp =
			C.emitter(att, Color3.fromHex(spec.SparkColor or "FFFFFF"), Color3.fromHex(spec.SparkColor or "FFFFFF"), {
				Rate = C.q(18),
				Lifetime = NumberRange.new(0.06, 0.12),
				Speed = NumberRange.new(0, 1),
				Size = NumberSequence.new(0.18),
				Squash = NumberSequence.new(4),
				SpreadAngle = Vector2.new(180, 180),
				Rotation = NumberRange.new(0, 360),
				LockedToPart = true,
			})
		sp.Transparency = NumberSequence.new(0)
		table.insert(layers, sp)
	end
	if spec.Shimmer then
		local sh = C.emitter(att, Color3.new(1, 1, 1), P, {
			Rate = C.q(25),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(0.5, 1.5),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(1, 0),
			}),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 4, 0),
			LockedToPart = true,
		})
		table.insert(layers, sh)
	end
	local light = C.light(root, P, 10 * scale, 1.5)
	local intensity = opts.Intensity or 1
	local base = {}
	for i, e in ipairs(layers) do
		base[i] = e.Rate
	end
	local conn = RunService.Heartbeat:Connect(function()
		local flick = 0.85 + 0.3 * math.noise(os.clock() * 6, 0.5)
		light.Brightness = 1.5 * intensity * flick
		light.Range = 10 * scale * (0.9 + 0.2 * flick) * math.max(0.5, intensity)
	end)
	function h:SetIntensity(x)
		intensity = x
		for i, e in ipairs(layers) do
			e.Rate = base[i] * x
		end
	end
	function h:Burst(n)
		for _, e in ipairs(layers) do
			e:Emit(C.q(n or 20))
		end
	end
	function h:Destroy()
		conn:Disconnect()
		for _, e in ipairs(layers) do
			e.Enabled = false
		end
		task.delay(0.7, function()
			att:Destroy()
			light:Destroy()
		end)
	end
	h:SetIntensity(intensity)
	return h
end

-- BeamCore: layered beam (core / inner / outer / heat-haze) with per-frame update -----------------
-- local b = C.BeamCore(parent, {Width, Core, Inner, Outer}); b:Update(origin, dir, length, t); b:Fade(time)
function C.BeamCore(parent, o)
	local w = o.Width or 4
	local b = {}
	b.outer = C.part(parent, Vector3.new(0.1, w * 1.35, w * 1.35), o.Outer, Enum.PartType.Cylinder, 0.55)
	b.inner = C.part(parent, Vector3.new(0.1, w, w), o.Inner, Enum.PartType.Cylinder, 0.15)
	b.core =
		C.part(parent, Vector3.new(0.1, w * 0.45, w * 0.45), o.Core or Color3.new(1, 1, 1), Enum.PartType.Cylinder, 0)
	-- heat haze: Glass material slightly larger than outer distorts background
	if C.Quality.Level >= 2 then
		b.haze = C.part(parent, Vector3.new(0.1, w * 1.7, w * 1.7), Color3.new(1, 1, 1), Enum.PartType.Cylinder, 0.85)
		b.haze.Material = Enum.Material.Glass
	end
	b.rings = {}
	function b:Update(origin, dir, length, t)
		t = t or os.clock()
		local cf = C.cylinderCF(origin, dir, length)
		local p1 = 1 + 0.06 * math.sin(t * 55)
		local p2 = 1 + 0.1 * math.sin(t * 31 + 1)
		b.core.CFrame, b.inner.CFrame = cf, cf
		b.outer.CFrame = cf * CFrame.Angles(t * 6, 0, 0)
		b.core.Size = Vector3.new(length, w * 0.45 * p1, w * 0.45 * p1)
		b.inner.Size = Vector3.new(length, w * p1, w * p1)
		b.outer.Size = Vector3.new(length, w * 1.35 * p2, w * 1.35 * p2)
		if b.haze then
			b.haze.CFrame = cf
			b.haze.Size = Vector3.new(length, w * 1.7, w * 1.7)
		end
		-- spiral rings every 6 studs, scrolling forward
		local want = math.min(C.q(math.floor(length / 6)), 40)
		while #b.rings < want do
			table.insert(
				b.rings,
				C.part(parent, Vector3.new(0.3, w * 1.5, w * 1.5), o.Outer, Enum.PartType.Cylinder, 0.6)
			)
		end
		for i, r in ipairs(b.rings) do
			if i > want then
				r.Transparency = 1
			else
				local d = ((i - 1) * 6 + (t * 60) % 6)
				r.Transparency = 0.6
				r.CFrame = CFrame.lookAt(origin + dir * d, origin + dir * (d + 1)) * CFrame.Angles(0, math.rad(90), 0)
			end
		end
	end
	function b:Fade(time)
		for _, p in ipairs({ b.core, b.inner, b.outer, b.haze }) do
			if p then
				C.tween(
					p,
					time or 0.25,
					{ Transparency = 1, Size = Vector3.new(p.Size.X, p.Size.Y * 0.2, p.Size.Z * 0.2) }
				)
			end
		end
		for _, r in ipairs(b.rings) do
			C.tween(r, time or 0.25, { Transparency = 1 })
		end
	end
	return b
end

-- Big impact package used by all modules (upgraded explosion) -----------------------------------
-- tier: "Light" | "Medium" | "Heavy" | "Ultimate"
C.IMPACT_TIERS = {
	Light = { Frames = 0, Shake = 0.25, Fov = 2, Debris = 0, Cracks = 0 },
	Medium = { Frames = 1, Shake = 0.45, Fov = 5, Debris = 6, Cracks = 6 },
	Heavy = { Frames = 2, Shake = 0.7, Fov = 8, Debris = 12, Cracks = 10 },
	Ultimate = { Frames = 3, Shake = 1.0, Fov = 12, Debris = 20, Cracks = 14 },
}
function C.Impact(parent, pos, size, color, core, tier, opts)
	opts = opts or {}
	local T = C.IMPACT_TIERS[tier or "Heavy"]
	if T.Frames > 0 then
		C.ImpactFrame(opts.FrameMode or "invert", T.Frames, opts.Subjects)
	end
	C.CameraShake(T.Shake, 0.5)
	C.FOVPunch(T.Fov)
	C.Shockwave(parent, CFrame.new(pos), 2, size * 2, color, 0.45)
	if T.Cracks > 0 or T.Debris > 0 then
		local res = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -15, 0), C.rayParams({ parent }))
		if res then
			if T.Cracks > 0 then
				C.GroundCrack(parent, res.Position, size * 0.6, T.Cracks, color, 3)
			end
			if T.Debris > 0 then
				C.DebrisBurst(workspace, res.Position, T.Debris, 40 + size, nil, 2.5)
			end
		end
	end
end

-- KiBlast: one fast ki bolt fired from the hands ------------------------------------------------
-- MISSING FUNCTION FIX (2026-10-14): the pose clips call `VFXCommon.KiBlast` 18 times (KiVolley
-- t = 6/14/22/30/38/46 on Goku, Vegeta, Frieza and Shared), but VFXCommon never defined it, so every
-- ki volley marker was a nil lookup. Kept deliberately cheap - one folder, two parts, one trail, one
-- light, one muzzle emitter - because a volley fires it six times in under a second.
-- opts: {Speed, Range, Color, Core, Target, Direction}
function C.KiBlast(character, opts)
	opts = opts or {}
	if not character or not character.Parent then
		return nil
	end
	local root = C.root(character)
	if not root then
		return nil
	end
	local color = opts.Color or Color3.fromRGB(140, 220, 255)
	local core = opts.Core or Color3.new(1, 1, 1)
	local origin = C.hands(character)
	local dir = opts.Direction
	if not dir then
		local target = opts.Target
		dir = target and C.direction(origin, target) or root.CFrame.LookVector
	end
	local speed = opts.Speed or 180
	local range = opts.Range or 120
	local life = range / speed
	local f = C.folder("KiBlast", life + 1)

	local bolt = C.part(f, Vector3.one * 1.5, core, Enum.PartType.Ball, 0)
	bolt.CFrame = CFrame.new(origin)
	local shell = C.part(f, Vector3.one * 2.4, color, Enum.PartType.Ball, 0.55)
	shell.CFrame = bolt.CFrame
	local att = Instance.new("Attachment")
	att.Parent = bolt
	local tr = Instance.new("Trail")
	tr.Attachment0 = att
	tr.Lifetime = 0.22
	tr.Color = ColorSequence.new(color, core)
	tr.Transparency = NumberSequence.new(0.15, 1)
	tr.Parent = bolt
	C.light(bolt, color, 9, 2)
	local muzzle = C.emitter(att, core, color, {
		Rate = 0,
		Speed = NumberRange.new(6, 14),
		Lifetime = NumberRange.new(0.1, 0.2),
		Size = NumberSequence.new(0.9, 0),
		SpreadAngle = Vector2.new(40, 40),
	})
	muzzle:Emit(C.q(8))
	C.tween(shell, life, { Size = Vector3.one * 3.4, Transparency = 0.85 })

	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not bolt.Parent then
			conn:Disconnect()
			return
		end
		local a = os.clock() - t0
		if a >= life then
			conn:Disconnect()
			C.tween(bolt, 0.12, { Size = Vector3.zero, Transparency = 1 })
			C.tween(shell, 0.12, { Transparency = 1 })
			return
		end
		local pos = origin + dir * (speed * a)
		bolt.CFrame = CFrame.new(pos)
		shell.CFrame = bolt.CFrame
		local hit = workspace:Raycast(pos, dir * (speed * 0.05), C.rayParams({ f, character }))
		if hit then
			conn:Disconnect()
			C.Shockwave(f, CFrame.new(hit.Position), 0.6, 4, color, 0.22)
			muzzle:Emit(C.q(10))
			C.tween(bolt, 0.12, { Size = Vector3.one * 4, Transparency = 1 })
			C.tween(shell, 0.12, { Size = Vector3.one * 6, Transparency = 1 })
			task.delay(0.25, function()
				f:Destroy()
			end)
		end
	end)
	return f
end

return C
