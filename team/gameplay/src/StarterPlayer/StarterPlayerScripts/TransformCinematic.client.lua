-- LocalScript (v1.2): per-form transformation cinematics + beam-struggle polish + louder arena destruction feedback.
-- Built on db-animation VFXCommon (AuraEmitter / Shockwave / GroundCrack / DebrisBurst / ImpactFrame / CameraShake / FOVPunch).
-- Cinematic runs for YOUR transformation (full camera) and as a lighter world-only version for others within 120 studs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ClientAPI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientAPI"))
local VFX = ReplicatedStorage:WaitForChild("VFX", 10)
local C = VFX and require(VFX:WaitForChild("VFXCommon"))
if not C then warn("[TransformCinematic] VFXCommon missing"); return end
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local hex = Color3.fromHex

-- style per preset: title, colours, beats
local STYLE = {
	SSJ = { title = "SUPER SAIYAN", color = hex("FFD84A"), flash = hex("FFF6C0"), lightning = true, crack = true, orbit = 1, dur = 2.4 },
	SSJ2 = { title = "SUPER SAIYAN 2", color = hex("FFE15A"), flash = hex("FFF6C0"), lightning = true, crack = true, orbit = 1, dur = 2.4 },
	SSJ3 = { title = "SUPER SAIYAN 3", color = hex("FFC828"), flash = hex("FFF6C0"), lightning = true, crack = true, orbit = 1.2, dur = 2.8 },
	SSB = { title = "SUPER SAIYAN BLUE", color = hex("3AD7FF"), flash = hex("E0FBFF"), calmRings = true, orbit = 0.7, dur = 2.4 },
	SSBEvolved = { title = "SUPER SAIYAN BLUE EVOLVED", color = hex("2A55E8"), flash = hex("D8E2FF"), calmRings = true, lightning = true, orbit = 0.8, dur = 2.6 },
	UISign = { title = "ULTRA INSTINCT -SIGN-", color = hex("C8D2FF"), flash = hex("FFFFFF"), wisps = true, slowmo = true, orbit = 0.5, dur = 2.8 },
	MUI = { title = "ULTRA INSTINCT", color = hex("E8EEFF"), flash = hex("FFFFFF"), wisps = true, slowmo = true, orbit = 0.5, dur = 3.0 },
	UltraEgo = { title = "ULTRA EGO", color = hex("9A4AFF"), flash = hex("FF78C8"), dark = true, crack = true, orbit = 1.1, dur = 2.8 },
	GoldenFrieza = { title = "GOLDEN FRIEZA", color = hex("FFC400"), flash = hex("FFF0A0"), shell = hex("FFC400"), orbit = 0.9, dur = 2.8 },
	FriezaBlack = { title = "BLACK FRIEZA", color = hex("96286E"), flash = hex("FF3C78"), shell = hex("140A19"), dark = true, orbit = 0.9, dur = 3.0 },
}
local gui = Instance.new("ScreenGui"); gui.Name = "TransformCinematic"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false; gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")
local function bar(top: boolean): Frame
	local f = Instance.new("Frame"); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0; f.Size = UDim2.new(1, 0, 0, 0)
	f.AnchorPoint = Vector2.new(0, if top then 0 else 1); f.Position = UDim2.new(0, 0, if top then 0 else 1, 0); f.Parent = gui; return f
end
local topBar, botBar = bar(true), bar(false)
local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1; title.Size = UDim2.new(1, 0, 0, 90); title.Position = UDim2.new(0, 0, 0.72, 0)
title.Font = Enum.Font.GothamBlack; title.TextScaled = true; title.TextTransparency = 1; title.TextStrokeTransparency = 1; title.Parent = gui
local flashF = Instance.new("Frame"); flashF.Size = UDim2.fromScale(1, 1); flashF.BorderSizePixel = 0; flashF.BackgroundTransparency = 1; flashF.Parent = gui

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props); tw:Play(); return tw
end
local function rootOf(ch: Model): BasePart? return ch:FindFirstChild("HumanoidRootPart") :: BasePart? end
local fx = workspace:FindFirstChild("ClientFX") or Instance.new("Folder"); fx.Name = "ClientFX"; fx.Parent = workspace

local busy = false
local function cinematic(ch: Model, preset: string)
	local st = STYLE[preset]; if not st then return end
	local r = rootOf(ch); if not r then return end
	local mine = ch == player.Character
	if not mine and (camera.CFrame.Position - r.Position).Magnitude > 120 then return end
	local aura = C.AuraEmitter(ch, preset, { Scale = 1.3 })
	local t0 = os.clock()
	local ground = r.Position - Vector3.new(0, 3, 0)
	-- beat 1 (0-0.9s): charge - letterbox, darken, debris lift, ground crack
	local savedBright = Lighting.Brightness
	if mine then
		busy = true
		tween(topBar, 0.25, { Size = UDim2.new(1, 0, 0.11, 0) }); tween(botBar, 0.25, { Size = UDim2.new(1, 0, 0.11, 0) })
		if st.dark then tween(Lighting, 0.4, { Brightness = savedBright * 0.35 }) end
	end
	if st.crack then C.GroundCrack(fx, ground, 14, 14, st.color, 3) end
	C.DebrisBurst(fx, ground, 10, 22, Color3.fromRGB(120, 110, 100), 2.2)
	local shell: Part? = nil
	if st.shell then -- Golden / Black Frieza: cocoon shell that cracks open
		local s = Instance.new("Part"); s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(3, 3, 3); s.Anchored = true; s.CanCollide = false; s.CanQuery = false
		s.Material = Enum.Material.Neon; s.Color = st.shell; s.Transparency = 0.15; s.CFrame = r.CFrame; s.Parent = fx; shell = s
		tween(s, 0.8, { Size = Vector3.new(9, 9, 9) }, Enum.EasingStyle.Back)
	end
	local orbitConn: RBXScriptConnection? = nil
	if mine then
		camera.CameraType = Enum.CameraType.Scriptable
		orbitConn = RunService.RenderStepped:Connect(function()
			local el = os.clock() - t0
			local rr = rootOf(ch); if not rr then return end
			local k = math.clamp(el / st.dur, 0, 1)
			local ang = math.rad(-40 + 140 * k * st.orbit)
			local dist = 14 - 6 * math.sin(k * math.pi) -- push in then pull back
			local h = 2 + 3 * (1 - k)
			local pos = rr.Position + Vector3.new(math.sin(ang) * dist, h, -math.cos(ang) * dist)
			local look = (rr.CFrame * CFrame.new(0, 0.5, 0)).Position
			camera.CFrame = CFrame.lookAt(pos, look)
		end)
		if st.slowmo then C.FOVPunch(-12) end
	end
	-- pulses during charge
	for i = 1, 3 do
		task.delay(0.25 * i, function()
			local rr = rootOf(ch); if not rr then return end
			C.Shockwave(fx, CFrame.new(rr.Position - Vector3.new(0, 2.8, 0)), 2, 10 + i * 4, st.color, 0.45, 0.3)
			if st.calmRings then C.Shockwave(fx, CFrame.new(rr.Position), 1, 8 + i * 2, st.color, 0.6, 0.15) end
			if mine then C.CameraShake(0.15 + 0.1 * i, 0.25) end
			aura:SetIntensity(0.5 + 0.25 * i)
		end)
	end
	if st.lightning then
		for i = 1, 6 do
			task.delay(0.12 * i, function()
				local rr = rootOf(ch); if not rr then return end
				local a = Instance.new("Part"); a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.Material = Enum.Material.Neon
				a.Color = Color3.fromRGB(190, 230, 255); a.Size = Vector3.new(0.15, 0.15, math.random(3, 6))
				a.CFrame = CFrame.new(rr.Position + Vector3.new(math.random(-2, 2), math.random(-2, 3), math.random(-2, 2))) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				a.Parent = fx; game:GetService("Debris"):AddItem(a, 0.08)
			end)
		end
	end
	if st.wisps then
		local att = Instance.new("Attachment"); att.Parent = r
		local w = Instance.new("ParticleEmitter"); w.Color = ColorSequence.new(st.color); w.LightEmission = 1; w.Size = NumberSequence.new(0.5, 0)
		w.Lifetime = NumberRange.new(1, 1.8); w.Rate = 60; w.Speed = NumberRange.new(2, 5); w.SpreadAngle = Vector2.new(180, 180); w.Parent = att
		task.delay(st.dur + 0.5, function() att:Destroy() end)
	end
	-- beat 2 (~0.9s): reveal - flash, shockwave, impact frame, title card
	task.delay(0.9, function()
		local rr = rootOf(ch)
		if shell then tween(shell, 0.25, { Size = Vector3.new(20, 20, 20), Transparency = 1 }); game:GetService("Debris"):AddItem(shell, 0.4) end
		if rr then
			C.Shockwave(fx, CFrame.new(rr.Position - Vector3.new(0, 2.8, 0)), 4, 46, st.flash, 0.7, 0.6)
			C.Shockwave(fx, CFrame.new(rr.Position) * CFrame.Angles(math.rad(90), 0, 0), 2, 30, st.color, 0.6, 0.3)
			C.DebrisBurst(fx, rr.Position - Vector3.new(0, 3, 0), 16, 40, Color3.fromRGB(130, 120, 110), 2.5)
		end
		aura:SetIntensity(1.4)
		if mine then
			C.ImpactFrame(if st.dark then "black" else "invert", 3, { ch })
			C.CameraShake(1.2, 0.5); C.FOVPunch(if st.slowmo then 6 else 14)
			C.SpeedLines(0.8, st.color, 40)
			flashF.BackgroundColor3 = st.flash; flashF.BackgroundTransparency = 0.1; tween(flashF, 0.5, { BackgroundTransparency = 1 })
			title.Text = st.title; title.TextColor3 = st.color; title.TextStrokeColor3 = Color3.new(0, 0, 0)
			title.TextTransparency = 0; title.TextStrokeTransparency = 0; title.Size = UDim2.new(1, 0, 0, 130)
			tween(title, 0.35, { Size = UDim2.new(1, 0, 0, 90) }, Enum.EasingStyle.Back)
		end
	end)
	-- beat 3: settle and hand the camera back
	task.delay(st.dur, function()
		aura:SetIntensity(0.8)
		task.delay(1.2, function() aura:Destroy() end)
		if mine then
			if orbitConn then orbitConn:Disconnect() end
			camera.CameraType = Enum.CameraType.Custom
			tween(title, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 })
			tween(topBar, 0.3, { Size = UDim2.new(1, 0, 0, 0) }); tween(botBar, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
			if st.dark then tween(Lighting, 0.4, { Brightness = savedBright }) end
			busy = false
		end
	end)
end
ClientAPI.onPlayVFX:Connect(function(kind, ch, arg)
	if kind == "Transform" and typeof(ch) == "Instance" and ch:IsA("Model") and type(arg) == "string" then
		if ch == player.Character and busy then return end
		cinematic(ch, arg)
	end
end)

-- ===== beam struggle polish =====
local function charByUser(uid: any): Model?
	if typeof(uid) == "Instance" then return uid :: Model end
	local p = type(uid) == "number" and Players:GetPlayerByUserId(uid); return p and p.Character
end
local clash: { orb: Part, ring: Part, conn: RBXScriptConnection, a: Model, b: Model, score: number }? = nil
local function endClash()
	if not clash then return end
	clash.conn:Disconnect(); clash.orb:Destroy(); clash.ring:Destroy(); clash = nil
end
ClientAPI.onCombatEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	if kind == "StruggleStart" then
		endClash()
		local a, b = charByUser(data[1]), charByUser(data[2])
		local ra, rb = a and rootOf(a), b and rootOf(b)
		if not ra or not rb then return end
		local orb = Instance.new("Part"); orb.Shape = Enum.PartType.Ball; orb.Anchored = true; orb.CanCollide = false; orb.CanQuery = false
		orb.Material = Enum.Material.Neon; orb.Color = Color3.fromRGB(255, 250, 230); orb.Size = Vector3.new(5, 5, 5); orb.Parent = fx
		local ring = Instance.new("Part"); ring.Shape = Enum.PartType.Cylinder; ring.Anchored = true; ring.CanCollide = false; ring.CanQuery = false
		ring.Material = Enum.Material.ForceField; ring.Color = Color3.fromRGB(255, 220, 120); ring.Size = Vector3.new(0.4, 12, 12); ring.Parent = fx
		local l = Instance.new("PointLight"); l.Range = 40; l.Brightness = 6; l.Color = Color3.fromRGB(255, 230, 180); l.Parent = orb
		local sp = Instance.new("ParticleEmitter"); sp.Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(120, 200, 255)); sp.LightEmission = 1
		sp.Size = NumberSequence.new(0.6, 0); sp.Lifetime = NumberRange.new(0.2, 0.5); sp.Rate = 120; sp.Speed = NumberRange.new(20, 40); sp.SpreadAngle = Vector2.new(180, 180); sp.Parent = orb
		local c = { orb = orb, ring = ring, a = a :: Model, b = b :: Model, score = 0, conn = (nil :: any) }
		c.conn = RunService.RenderStepped:Connect(function()
			local pa, pb = rootOf(c.a), rootOf(c.b)
			if not pa or not pb then return end
			local k = 0.5 + math.clamp(c.score, -1, 1) * 0.35 -- score>0 pushes toward b
			local pos = pa.Position:Lerp(pb.Position, k)
			local pulse = 1 + math.sin(os.clock() * 25) * 0.12
			orb.Size = Vector3.one * 5 * pulse; orb.CFrame = CFrame.new(pos)
			ring.CFrame = CFrame.lookAt(pos, pb.Position) * CFrame.Angles(0, math.rad(90), 0)
			ring.Size = Vector3.new(0.4, 12 * pulse, 12 * pulse)
		end)
		clash = c :: any
		local mine = a == player.Character or b == player.Character
		if mine then C.ImpactFrame("invert", 2, { a, b }); C.CameraShake(0.8, 0.4); C.SpeedLines(1.2) end
	elseif kind == "StrugglePulse" and clash then
		clash.score = (tonumber(data[3]) or 0) / 30 -- Config.COMBAT Struggle.winScore
		C.Shockwave(fx, clash.orb.CFrame, 3, 16, Color3.fromRGB(255, 240, 200), 0.3, 0.2)
		if clash.a == player.Character or clash.b == player.Character then C.CameraShake(0.35, 0.15) end
	elseif kind == "StruggleEnd" then
		if clash then
			local pos = clash.orb.Position
			C.Shockwave(fx, CFrame.new(pos), 4, 60, Color3.fromRGB(255, 250, 230), 0.8, 0.8)
			C.DebrisBurst(fx, pos, 20, 50, Color3.fromRGB(140, 130, 120), 2.5)
			C.ImpactFrame("invert", 3, nil); C.CameraShake(1.5, 0.6)
		end
		endClash()
	elseif kind == "Hit" and (data[5] or (tonumber(data[3]) or 0) >= 18) then
		-- arena destruction readability: crater ring + dust plume under heavy / KO hits
		local v = charByUser(data[1]); local rv = v and rootOf(v)
		if rv then
			local g = rv.Position - Vector3.new(0, 3, 0)
			C.GroundCrack(fx, g, if data[5] then 12 else 7, if data[5] then 12 else 7, Color3.fromRGB(60, 50, 45), 4)
			C.DebrisBurst(fx, g, if data[5] then 14 else 7, 30, Color3.fromRGB(150, 135, 120), 2.5)
		end
	end
end)

-- dev hook
local bf = Instance.new("BindableFunction"); bf.Name = "CinematicTest"; bf.Parent = script
bf.OnInvoke = function(preset) if player.Character then cinematic(player.Character, preset) end; return true end
