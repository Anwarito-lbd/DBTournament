--!nonstrict
-- TransformationVFX (ModuleScript, client). Requires sibling VFXCommon.
-- v5: config.KeepAura = true keeps a layered C.AuraEmitter running after the flash (handle.Aura; call handle.Aura:Destroy() on revert).
-- API:
--   TransformationVFX.Play(character, formNameOrConfig, overrides?)  -- one-shot full sequence
--   local h = TransformationVFX.Start(character, form, overrides?)    -- hold-to-charge
--   h:Stop(transform: boolean)  -- true = finish with flash/transform, false = cancel
--   TransformationVFX.Presets  -- table of forms
-- Server replication: server validates level/ki, then PlayVFX:FireAllClients("Transform", char, formName).
local RunService = game:GetService("RunService")
local C = require(script.Parent:WaitForChild("VFXCommon"))

local T = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local BASE = {
	Name = "Form", Aura = rgb(255, 216, 74), Core = rgb(255, 255, 220), Sparks = false,
	ChargeTime = 2.5, BasePower = 10000, FinalPower = 500000, Multiplier = 1.15,
	Cracks = 10, Rocks = 12, ShakeMax = 2.5, AuraSize = 1,
	ScreamSoundId = "", ChargeLoopSoundId = "", FlashSoundId = "", ParticleTexture = "",
	OnScream = nil, OnCameraShake = nil, OnTransformed = nil, ShowPowerLevel = true,
}
T.Presets = {
	SSJ = {Name = "Super Saiyan", Aura = rgb(255, 216, 74), Multiplier = 1.15, FinalPower = 150000000},
	SSJ2 = {Name = "Super Saiyan 2", Aura = rgb(255, 225, 90), Sparks = true, Multiplier = 1.25, FinalPower = 300000000},
	SSJ3 = {Name = "Super Saiyan 3", Aura = rgb(255, 200, 40), Sparks = true, ChargeTime = 4, ShakeMax = 3.5, Rocks = 20, Multiplier = 1.35, FinalPower = 1200000000},
	SSG = {Name = "Super Saiyan God", Aura = rgb(255, 74, 58), Core = rgb(255, 180, 120), Multiplier = 1.45, FinalPower = 5e9},
	SSB = {Name = "Super Saiyan Blue", Aura = rgb(58, 215, 255), Core = rgb(200, 245, 255), Multiplier = 1.6, FinalPower = 2e10},
	UISign = {Name = "Ultra Instinct Sign", Aura = rgb(221, 230, 255), Core = rgb(140, 160, 255), Cracks = 4, ShakeMax = 1.5, Multiplier = 1.75, FinalPower = 6e10},
	MUI = {Name = "Mastered Ultra Instinct", Aura = rgb(240, 245, 255), Core = rgb(255, 255, 255), AuraSize = 1.3, ChargeTime = 3, Multiplier = 2.0, FinalPower = 1e11},
	GoldenFrieza = {Name = "Golden Frieza", Aura = rgb(255, 196, 0), Core = rgb(255, 240, 160), Multiplier = 1.5, FinalPower = 1.5e10},
	KeflaSSJ2 = {Name = "Kefla SSJ2", Aura = rgb(200, 255, 58), Core = rgb(255, 255, 180), Sparks = true, Multiplier = 1.4, FinalPower = 4e9},
	JirenFullPower = {Name = "Jiren Full Power", Aura = rgb(255, 59, 59), Core = rgb(255, 170, 120), Rocks = 24, ShakeMax = 4, Multiplier = 1.6, FinalPower = 1.5e11},
	ToppoGoD = {Name = "God of Destruction", Aura = rgb(139, 58, 255), Core = rgb(40, 20, 60), AuraSize = 1.4, Multiplier = 1.65, FinalPower = 9e10},
	CauliflaSSJ = {Name = "Caulifla SSJ", Aura = rgb(255, 210, 60), Multiplier = 1.2, FinalPower = 2e8},
	UltraEgo = {Name = "Ultra Ego", Aura = rgb(154, 74, 255), Core = rgb(255, 120, 200), AuraSize = 1.3, Rocks = 18, ShakeMax = 3.5, Multiplier = 1.8, FinalPower = 1e11},
	GohanUltimate = {Name = "Ultimate Gohan", Aura = rgb(255, 255, 255), Core = rgb(220, 230, 255), Cracks = 8, Multiplier = 1.5, FinalPower = 4e10},
	KeflaPotara = {Name = "Kefla (Potara Fusion)", Aura = rgb(200, 255, 58), Core = rgb(255, 255, 200), Sparks = true, ChargeTime = 3.2, Rocks = 22, ShakeMax = 3.5, Multiplier = 1.45, FinalPower = 6e9},
	KaleBerserk = {Name = "Kale Berserk", Aura = rgb(120, 255, 90), Core = rgb(230, 255, 200), AuraSize = 1.6, Rocks = 26, ShakeMax = 4, ChargeTime = 3, Multiplier = 1.55, FinalPower = 3e9},
}

-- Alignment with db-gameplay Config.FORMS ids (ReplicatedStorage/Shared/Config.lua).
-- Config.FORMS: Base, KaioKen, FullPower, SuperSaiyan, SuperSaiyan2, SuperSaiyan3, Ultimate, Golden,
-- SuperSaiyanGod, SuperSaiyanBlue, Legendary, UltraInstinct. Extra VFX-only presets (MUI, UltraEgo, Beast, ...) are
-- proposals not yet in Config. FullPower is per-character (see FULLPOWER_BY_CHAR).
T.Presets.KaioKen = {Name = "Kaio-ken", Aura = rgb(255, 40, 40), Core = rgb(255, 160, 160), Cracks = 6, Multiplier = 1.5, FinalPower = 5e7}
T.Presets.FullPower = {Name = "Full Power", Aura = rgb(255, 255, 255), Core = rgb(255, 255, 255), Multiplier = 1.75, FinalPower = 1e8}
T.Presets.Legendary = {Name = "Legendary Super Saiyan", Aura = rgb(120, 255, 90), Core = rgb(230, 255, 200), AuraSize = 1.6, Rocks = 26, ShakeMax = 4, ChargeTime = 3, Multiplier = 4.5, FinalPower = 3e9}
T.FORM_ID_MAP = {
	SuperSaiyan = "SSJ", SuperSaiyan2 = "SSJ2", SuperSaiyan3 = "SSJ3", SuperSaiyanGod = "SSG",
	SuperSaiyanBlue = "SSB", UltraInstinct = "MUI", UltraInstinctSign = "UISign", UISign = "UISign",
	SuperSaiyanBlueEvolved = "SSBEvolved", UltraEgo = "UltraEgo", KeflaPotara = "KeflaPotara", MUI = "MUI",
	SSBEvolved = "SSBEvolved", BeastGohan = "BeastGohan", FriezaBlack = "FriezaBlack", MoroAwakened = "MoroAwakened", Ultimate = "GohanUltimate", Golden = "GoldenFrieza",
	KaioKen = "KaioKen", FullPower = "FullPower", Legendary = "Legendary",
}
T.FULLPOWER_BY_CHAR = {
	u11_jiren = "JirenFullPower", u11_toppo = "ToppoGoD", u7_frieza = "FriezaFullPower",
}
T.Presets.SSBEvolved = {Name = "Super Saiyan Blue Evolved", Aura = rgb(42, 85, 232), Core = rgb(159, 184, 255), Sparks = true, Rocks = 18, ShakeMax = 3.5, ChargeTime = 3.5, Multiplier = 1.7, FinalPower = 3e10}
T.Presets.FriezaFullPower = {Name = "Full Power", Aura = rgb(199, 125, 255), Core = rgb(255, 210, 255), Cracks = 8, Multiplier = 1.75, FinalPower = 1.2e10}
-- Active per roblox lead (override): BeastGohan, FriezaBlack, plus Moro.
T.Presets.BeastGohan = {Name = "Beast", Aura = rgb(255, 60, 70), Core = rgb(255, 255, 255), Sparks = true, ChargeTime = 3.5, ShakeMax = 3.5, Rocks = 20, AuraSize = 1.2, Multiplier = 1.8, FinalPower = 1.2e11}
T.Presets.FriezaBlack = {Name = "Black Frieza", Aura = rgb(150, 40, 110), Core = rgb(20, 10, 25), AuraSize = 1.3, Cracks = 14, ShakeMax = 4, ChargeTime = 2, Multiplier = 1.9, FinalPower = 2e11}
T.Presets.MoroAwakened = {Name = "Moro (Awakened)", Aura = rgb(120, 230, 90), Core = rgb(40, 60, 30), AuraSize = 1.3, Rocks = 22, ShakeMax = 3.5, ChargeTime = 3, Multiplier = 1.7, FinalPower = 5e10}

-- Ultra Ego damage growth: call on the client whenever the UE fighter takes damage (server replicates hp).
-- Returns a controller; aura grows with total damage fraction (0..1), purple pulse on each hit.
-- Usage: local ue = TransformationVFX.UltraEgoGrowth(char, {OnDamageGrow = function(frac) ... end}); ue:Damaged(amount, maxHp); ue:Stop()
function T.UltraEgoGrowth(character, opts)
	opts = opts or {}
	local root = C.root(character)
	local g = {Taken = 0}
	if not root then function g:Damaged() end; function g:Stop() end; return g end
	local p = T.Presets.UltraEgo
	local att = Instance.new("Attachment"); att.Name = "UltraEgoAura"; att.Parent = root
	local em = C.emitter(att, p.Core, p.Aura, {Rate = 25, Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(5, 10),
		Size = NumberSequence.new(1.5, 0), Acceleration = Vector3.new(0, 22, 0), LockedToPart = true,
		Shape = Enum.ParticleEmitterShape.Cylinder})
	local light = C.light(root, p.Aura, 10, 2)
	function g:Damaged(amount, maxHp)
		g.Taken += amount
		local frac = math.clamp(g.Taken / (maxHp or 1000), 0, 1)
		em.Rate = 25 + 150 * frac
		em.Size = NumberSequence.new(1.5 + 2.5 * frac, 0)
		light.Range, light.Brightness = 10 + 20 * frac, 2 + 5 * frac
		local pulse = C.part(workspace, Vector3.one * 4, p.Aura, Enum.PartType.Ball, 0.4)
		pulse.Position = root.Position
		C.tween(pulse, 0.35, {Size = Vector3.one * (10 + 15 * frac), Transparency = 1})
		game:GetService("Debris"):AddItem(pulse, 0.4)
		if opts.OnDamageGrow then task.spawn(opts.OnDamageGrow, frac, g.Taken) end
		return frac
	end
	function g:Stop() att:Destroy(); light:Destroy() end
	return g
end

-- Resolve a Config form id (+ optional character id) to a preset name.
function T.ResolveFormId(formId, charId)
	if formId == "FullPower" and charId and T.FULLPOWER_BY_CHAR[charId] then return T.FULLPOWER_BY_CHAR[charId] end
	return T.FORM_ID_MAP[formId] or formId
end

local function fmt(n)
	n = math.floor(n)
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function resolve(form, overrides)
	local preset = form
	if typeof(form) == "string" then preset = T.Presets[form] or T.Presets[T.ResolveFormId(form)] or {} end
	return C.merge(C.merge(BASE, preset), overrides)
end

function T.Start(character, form, overrides)
	local cfg = resolve(form, overrides)
	local root = C.root(character)
	local handle = {Active = false}
	if not root then function handle:Stop() end return handle end
	handle.Active = true
	local folder = C.folder("TransformVFX", 60)
	local shakeFn = cfg.OnCameraShake or C.shake
	local groundY = root.Position.Y - 3
	local params = C.rayParams({character, folder})
	local down = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), params)
	if down then groundY = down.Position.Y end
	local center = Vector3.new(root.Position.X, groundY, root.Position.Z)

	-- audio / scream hooks
	if cfg.OnScream then task.spawn(cfg.OnScream, character, cfg) end
	-- v5: quality-bar aura key (layered AuraEmitter used after the flash)
	local auraKey = typeof(form) == "string" and T.ResolveFormId(form) or (cfg.Name or "Custom")
	if not C.AURAS[auraKey] then
		C.AURAS[auraKey] = {Primary = cfg.Aura:ToHex(), Secondary = cfg.Core:ToHex(), Core = "FFFFFF", Rate = 45, Sparks = cfg.Sparks}
	end
	C.FOVPunch(-4) -- scream anticipation: slow zoom-in
	C.sound(cfg.ScreamSoundId, root)
	local loop
	if cfg.ChargeLoopSoundId ~= "" then
		loop = Instance.new("Sound"); loop.SoundId = cfg.ChargeLoopSoundId; loop.Looped = true; loop.Parent = root; loop:Play()
	end

	-- aura: emitters on root attachment + shell ball
	local att = Instance.new("Attachment"); att.Parent = root
	local aura = C.emitter(att, cfg.Core, cfg.Aura, {
		Rate = 40, Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(6, 12),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5 * cfg.AuraSize), NumberSequenceKeypoint.new(1, 0)}),
		Acceleration = Vector3.new(0, 25, 0), SpreadAngle = Vector2.new(25, 25),
		Shape = Enum.ParticleEmitterShape.Cylinder, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		LockedToPart = true,
	}, cfg.ParticleTexture)
	local sparks
	if cfg.Sparks then
		sparks = C.emitter(att, rgb(220, 240, 255), rgb(120, 200, 255), {
			Rate = 15, Lifetime = NumberRange.new(0.05, 0.12), Speed = NumberRange.new(0, 2),
			Size = NumberSequence.new(0.15), Squash = NumberSequence.new(3), SpreadAngle = Vector2.new(180, 180),
			LockedToPart = true,
		})
	end
	local shell = C.part(folder, Vector3.new(5, 7, 5) * cfg.AuraSize, cfg.Aura, Enum.PartType.Ball, 0.85)
	local light = C.light(root, cfg.Aura, 8, 2)

	-- ground cracks: thin dark parts radiating outward
	local cracks = {}
	for i = 1, cfg.Cracks do
		local ang = (i / cfg.Cracks) * math.pi * 2 + math.random() * 0.4
		local d = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local cr = C.part(folder, Vector3.new(0.4, 0.1, 0.2), rgb(25, 20, 18), nil, 0)
		cr.Material = Enum.Material.Slate
		cr.CFrame = CFrame.lookAt(center + d * 1.5 + Vector3.new(0, 0.05, 0), center + d * 3 + Vector3.new(0, 0.05, 0))
		cracks[i] = {part = cr, dir = d, len = 4 + math.random() * 8}
	end

	-- rocks
	local rocks = {}
	for i = 1, cfg.Rocks do
		local s = 0.5 + math.random() * 1.5
		local r = C.part(folder, Vector3.new(s, s * 0.8, s * 1.1), rgb(110, 95, 80), nil, 0)
		r.Material = Enum.Material.Rock
		local ang = math.random() * math.pi * 2
		local rad = 5 + math.random() * 7
		r.Position = center + Vector3.new(math.cos(ang) * rad, -s, math.sin(ang) * rad)
		rocks[i] = {part = r, ang = ang, rad = rad, h = 2 + math.random() * 8, spd = 0.3 + math.random() * 0.6, rot = Vector3.new(math.random(), math.random(), math.random())}
	end

	-- power level billboard
	local bb, label
	if cfg.ShowPowerLevel then
		bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(260, 60); bb.StudsOffset = Vector3.new(0, 4.5, 0); bb.AlwaysOnTop = true
		bb.Adornee = character:FindFirstChild("Head") or root
		label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack; label.TextScaled = true
		label.TextColor3 = cfg.Aura; label.TextStrokeTransparency = 0
		label.Text = "PL " .. fmt(cfg.BasePower)
		label.Parent = bb
		bb.Parent = folder
	end

	local t0 = os.clock()
	local conn
	local function progress()
		return math.clamp((os.clock() - t0) / cfg.ChargeTime, 0, 1)
	end
	local lastShake = 0
	conn = RunService.Heartbeat:Connect(function()
		if not root.Parent then handle:Stop(false) return end
		local a = progress()
		local eased = 1 - (1 - a) ^ 3
		local now = os.clock()
		center = Vector3.new(root.Position.X, center.Y, root.Position.Z)
		shell.Position = root.Position
		shell.Size = Vector3.new(5, 7, 5) * cfg.AuraSize * (1 + 0.5 * eased) * (1 + 0.04 * math.sin(now * 30))
		aura.Rate = 40 + 160 * eased
		light.Range, light.Brightness = 8 + 16 * eased, 2 + 5 * eased
		for _, c in ipairs(cracks) do
			local len = 0.4 + c.len * eased
			local start = center + c.dir * 1.5 + Vector3.new(0, 0.05, 0)
			c.part.Size = Vector3.new(0.3 + 0.3 * eased, 0.1, len)
			c.part.CFrame = CFrame.lookAt(start, start + c.dir) * CFrame.new(0, 0, -len / 2)
		end
		for _, r in ipairs(rocks) do
			r.ang += r.spd * 0.02 * (1 + eased * 2)
			local y = center.Y + r.h * eased + math.sin(now * 2 + r.ang) * 0.5
			r.part.CFrame = CFrame.new(center.X + math.cos(r.ang) * r.rad, y, center.Z + math.sin(r.ang) * r.rad)
				* CFrame.Angles(now * r.rot.X, now * r.rot.Y, now * r.rot.Z)
		end
		if label then label.Text = "PL " .. fmt(cfg.BasePower + (cfg.FinalPower * 0.8 - cfg.BasePower) * eased) end
		if now - lastShake > 0.25 then
			lastShake = now
			shakeFn(0.3 + cfg.ShakeMax * 0.6 * eased, 0.3)
		end
	end)

	function handle:Stop(transform)
		if not handle.Active then return end
		handle.Active = false
		if conn then conn:Disconnect() end
		if loop then loop:Destroy() end
		local ok = transform ~= false and progress() >= 0.35
		if ok then
			C.sound(cfg.FlashSoundId, root)
			-- quality bar flash: 3-frame inverted impact frame, FOV +14, double shockwave, cracks, debris, speed lines
			C.ImpactFrame("invert", 3, {character})
			C.FOVPunch(14)
			C.SpeedLines(0.45, cfg.Aura, 44)
			C.Shockwave(folder, CFrame.new(center + Vector3.new(0, 0.4, 0)), 3, 70, cfg.Aura, 0.6, 0.6)
			C.GroundCrack(folder, center, 14, cfg.Cracks, cfg.Aura, 4)
			C.DebrisBurst(workspace, center, 14, 60, nil, 2.5)
			handle.Aura = C.AuraEmitter(character, auraKey, {Scale = cfg.AuraSize, Intensity = 1.6})
			handle.Aura:Burst(30)
			task.delay(0.6, function() if handle.Aura then handle.Aura:SetIntensity(1) end end)
			if not cfg.KeepAura then task.delay(2.5, function() if handle.Aura then handle.Aura:Destroy(); handle.Aura = nil end end) end
			shakeFn(cfg.ShakeMax * 1.5, 0.6)
			local flash = C.part(folder, Vector3.one * 3, cfg.Core, Enum.PartType.Ball)
			flash.Position = root.Position
			C.light(flash, cfg.Aura, 60, 15)
			C.tween(flash, 0.5, {Size = Vector3.one * 40, Transparency = 1, Color = cfg.Aura})
			local ring = C.part(folder, Vector3.new(0.3, 2, 2), cfg.Aura, Enum.PartType.Cylinder, 0.2)
			ring.CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
			C.tween(ring, 0.6, {Size = Vector3.new(0.2, 60, 60), Transparency = 1})
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Brightness, cc.TintColor = 0.6, cfg.Aura
			cc.Parent = workspace.CurrentCamera or game:GetService("Lighting")
			C.tween(cc, 0.6, {Brightness = 0, TintColor = Color3.new(1, 1, 1)})
			game:GetService("Debris"):AddItem(cc, 0.7)
			for _, r in ipairs(rocks) do
				local out = (r.part.Position - center).Unit * 30 + Vector3.new(0, 10, 0)
				C.tween(r.part, 0.6, {Position = r.part.Position + out, Transparency = 1})
			end
			if label then
				label.Text = "PL " .. fmt(cfg.FinalPower)
				local nm = label:Clone(); nm.Text = cfg.Name:upper(); nm.Size = UDim2.fromScale(1, 0.5); nm.Position = UDim2.fromScale(0, -0.5); nm.Parent = bb
			end
			if cfg.OnTransformed then task.spawn(cfg.OnTransformed, character, cfg) end
			-- keep a settled idle aura briefly (gameplay code may keep its own persistent aura)
			aura.Rate = 30
			task.delay(2, function() aura.Enabled = false; if sparks then sparks.Enabled = false end end)
		else
			aura.Enabled = false
			if sparks then sparks.Enabled = false end
			for _, r in ipairs(rocks) do C.tween(r.part, 0.5, {Position = r.part.Position - Vector3.new(0, 10, 0), Transparency = 1}) end
		end
		C.tween(shell, 0.4, {Transparency = 1})
		C.tween(light, 0.8, {Brightness = 0})
		for _, c in ipairs(cracks) do C.tween(c.part, 2.5, {Transparency = 1}, Enum.EasingStyle.Linear) end
		task.delay(3, function()
			att:Destroy(); light:Destroy(); folder:Destroy()
		end)
		return ok
	end
	return handle
end

function T.Play(character, form, overrides)
	local cfg = resolve(form, overrides)
	local h = T.Start(character, form, overrides)
	task.delay(cfg.ChargeTime, function() h:Stop(true) end)
	return h
end

return T
