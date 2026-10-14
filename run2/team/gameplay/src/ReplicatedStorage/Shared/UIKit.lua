--!strict
-- ModuleScript: ReplicatedStorage.Shared.UIKit  (v1 client UI helpers + placeholder story figures)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIKit = {}

UIKit.GOLD = Color3.fromRGB(255, 200, 60)
UIKit.DARK = Color3.fromRGB(12, 14, 30)

function UIKit.gui(name: string, order: number?): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(name)
	if old then old:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = name; g.ResetOnSpawn = false; g.IgnoreGuiInset = true
	g.DisplayOrder = order or 0
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = pg
	return g
end

function UIKit.frame(parent: Instance, size: UDim2, pos: UDim2, color: Color3?, alpha: number?): Frame
	local f = Instance.new("Frame")
	f.Size = size; f.Position = pos
	f.BackgroundColor3 = color or UIKit.DARK
	f.BackgroundTransparency = alpha or 0.25
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f
	return f
end

function UIKit.label(parent: Instance, text: string, size: UDim2, pos: UDim2, textSize: number?, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size; l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize or 18
	l.TextWrapped = true
	l.TextStrokeTransparency = 0.5
	l.Parent = parent
	return l
end

function UIKit.button(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3?): TextButton
	local b = Instance.new("TextButton")
	b.Size = size; b.Position = pos
	b.BackgroundColor3 = color or Color3.fromRGB(40, 60, 140)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.TextWrapped = true
	b.AutoButtonColor = true
	b.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
	return b
end

-- Bar: returns setter(fraction, text)
function UIKit.bar(parent: Instance, size: UDim2, pos: UDim2, color: Color3, title: string): (number, string?) -> ()
	local bg = UIKit.frame(parent, size, pos, Color3.fromRGB(20, 20, 20), 0.3)
	local fill = UIKit.frame(bg, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), color, 0)
	local l = UIKit.label(bg, title, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 14)
	l.ZIndex = 3
	return function(frac: number, text: string?)
		fill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
		l.Text = if text then title .. "  " .. text else title
	end
end

-- Subtitle box with speaker name. Returns show(speaker, text) and destroy().
local SPEAKER_NAMES = { GrandPriest = "Grand Priest", Zeno = "Zeno", FutureZeno = "Future Zeno", SuperShenron = "Super Shenron",
	Leader = "Champion", Team = "Your Team",
	npc_grand_priest = "Grand Priest", npc_zeno = "Zeno", npc_zeno_future = "Future Zeno", npc_shenron = "Super Shenron", God = "God of Destruction", Bulma = "Bulma", Jiren = "Jiren" }
local SPEAKER_COLORS = { GrandPriest = Color3.fromRGB(120, 200, 255), Zeno = Color3.fromRGB(200, 140, 255),
	FutureZeno = Color3.fromRGB(200, 140, 255), SuperShenron = Color3.fromRGB(255, 90, 90), Leader = UIKit.GOLD,
	npc_grand_priest = Color3.fromRGB(120, 200, 255), npc_zeno = Color3.fromRGB(200, 140, 255), npc_zeno_future = Color3.fromRGB(200, 140, 255), npc_shenron = Color3.fromRGB(255, 90, 90),
	Bulma = Color3.fromRGB(80, 220, 210), Jiren = Color3.fromRGB(255, 70, 60) }
function UIKit.subtitles(parent: Instance)
	local box = UIKit.frame(parent, UDim2.new(0.7, 0, 0, 110), UDim2.new(0.15, 0, 1, -150), Color3.new(0, 0, 0), 0.35)
	local who = UIKit.label(box, "", UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 8), 22, UIKit.GOLD)
	who.TextXAlignment = Enum.TextXAlignment.Left
	local txt = UIKit.label(box, "", UDim2.new(1, -24, 1, -44), UDim2.new(0, 12, 0, 38), 20)
	txt.TextXAlignment = Enum.TextXAlignment.Left; txt.TextYAlignment = Enum.TextYAlignment.Top
	txt.Font = Enum.Font.Gotham
	return function(speaker: string, text: string)
		who.Text = SPEAKER_NAMES[speaker] or speaker
		who.TextColor3 = SPEAKER_COLORS[speaker] or UIKit.GOLD
		txt.Text = text
		txt.MaxVisibleGraphemes = 0
		task.spawn(function()
			local n = utf8.len(text) or #text
			for i = 1, n, 2 do
				if txt.Text ~= text then return end
				txt.MaxVisibleGraphemes = i
				task.wait(0.015)
			end
			txt.MaxVisibleGraphemes = -1
		end)
	end
end

-- ===== Placeholder figures (client-only, anchored, built from parts) =====
local function part(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = m
	return p
end

-- kind: "GrandPriest" | "Zeno" | "FutureZeno". cf = feet position/facing. Returns model; head position in attribute.
function UIKit.figure(kind: string, cf: CFrame, scale: number?): Model
	local s = scale or 1
	local m = Instance.new("Model")
	m.Name = "Story_" .. kind
	local skin, robe, trim
	if kind == "GrandPriest" then
		skin, robe, trim = Color3.fromRGB(120, 170, 230), Color3.fromRGB(30, 40, 120), Color3.fromRGB(240, 240, 255)
	else
		skin, robe, trim = Color3.fromRGB(150, 160, 200), Color3.fromRGB(240, 120, 40), Color3.fromRGB(150, 80, 200)
	end
	local tall = if kind == "GrandPriest" then 1 else 0.6 -- Zeno is small with a big head
	local function at(y: number) return cf * CFrame.new(0, y * s, 0) end
	part(m, "LegL", Vector3.new(0.9, 2 * tall, 0.9) * s, at(1 * tall) * CFrame.new(-0.5 * s, 0, 0), robe)
	part(m, "LegR", Vector3.new(0.9, 2 * tall, 0.9) * s, at(1 * tall) * CFrame.new(0.5 * s, 0, 0), robe)
	local torsoY = 2 * tall + 1.25 * tall
	part(m, "Torso", Vector3.new(2.2, 2.5 * tall, 1.2) * s, at(torsoY), robe)
	part(m, "Trim", Vector3.new(0.5, 2.5 * tall, 1.3) * s, at(torsoY), trim)
	part(m, "ArmL", Vector3.new(0.8, 2.3 * tall, 0.8) * s, at(torsoY) * CFrame.new(-1.5 * s, 0, 0), robe)
	part(m, "ArmR", Vector3.new(0.8, 2.3 * tall, 0.8) * s, at(torsoY) * CFrame.new(1.5 * s, 0, 0), robe)
	local headSize = if kind == "GrandPriest" then 1.6 else 2.4
	local headY = torsoY + 1.25 * tall + headSize / 2
	local head = part(m, "Head", Vector3.new(headSize, headSize, headSize) * s, at(headY), skin, Enum.PartType.Ball)
	-- eyes
	part(m, "EyeL", Vector3.new(0.25, 0.25, 0.1) * s, at(headY) * CFrame.new(-0.3 * s, 0.1 * s, -headSize / 2 * s), Color3.new(0, 0, 0))
	part(m, "EyeR", Vector3.new(0.25, 0.25, 0.1) * s, at(headY) * CFrame.new(0.3 * s, 0.1 * s, -headSize / 2 * s), Color3.new(0, 0, 0))
	if kind == "GrandPriest" then
		part(m, "Hair", Vector3.new(1.7, 0.5, 1.7) * s, at(headY + 0.75), Color3.fromRGB(250, 250, 255))
		part(m, "Mark", Vector3.new(0.3, 0.3, 0.1) * s, at(headY + 0.45) * CFrame.new(0, 0, -0.8 * s), Color3.fromRGB(120, 200, 255), nil, Enum.Material.Neon)
		local halo = part(m, "Halo", Vector3.new(0.3, 3.6, 3.6) * s, at(torsoY) * CFrame.new(0, 0, 1 * s) * CFrame.Angles(0, math.rad(90), 0),
			Color3.fromRGB(120, 200, 255), Enum.PartType.Cylinder, Enum.Material.Neon)
		halo.Transparency = 0.4
	else
		part(m, "Symbol", Vector3.new(0.6, 0.6, 0.1) * s, at(torsoY + 0.3) * CFrame.new(0, 0, -0.65 * s), Color3.fromRGB(255, 220, 60), nil, Enum.Material.Neon)
	end
	m.PrimaryPart = head
	m:SetAttribute("HeadY", headY * s)
	m.Parent = workspace
	return m
end

-- Super Shenron: segmented serpent coiling upward around `center`. Returns model.
function UIKit.shenron(center: Vector3, height: number?): Model
	local m = Instance.new("Model")
	m.Name = "Story_SuperShenron"
	local h = height or 160
	local n = 34
	local prev: Vector3? = nil
	for i = 0, n do
		local t = i / n
		local a = t * math.pi * 4
		local r = 60 * (1 - t * 0.6)
		local pos = center + Vector3.new(math.cos(a) * r, t * h, math.sin(a) * r)
		local seg = part(m, "Seg" .. i, Vector3.one * (9 - t * 3), CFrame.new(pos), Color3.fromRGB(235, 180, 40), Enum.PartType.Ball, Enum.Material.Neon)
		seg.Transparency = 0.1
		if prev then
			part(m, "Spine" .. i, Vector3.new(3, 3, (pos - prev).Magnitude), CFrame.lookAt((pos + prev) / 2, pos), Color3.fromRGB(255, 220, 80), nil, Enum.Material.Neon)
		end
		prev = pos
	end
	local headPos = (prev :: Vector3) + Vector3.new(0, 12, 0)
	local head = part(m, "Head", Vector3.new(16, 12, 22), CFrame.lookAt(headPos, Vector3.new(center.X, headPos.Y, center.Z) + Vector3.new(0, 0, 200)),
		Color3.fromRGB(240, 190, 50), nil, Enum.Material.Neon)
	for _, x in { -5, 5 } do
		part(m, "Eye", Vector3.new(3, 2, 1), head.CFrame * CFrame.new(x, 2, -11), Color3.fromRGB(255, 20, 20), nil, Enum.Material.Neon)
		part(m, "Horn", Vector3.new(1.5, 1.5, 14), head.CFrame * CFrame.new(x, 7, 6) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(255, 220, 120))
	end
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 80, 60); l.Range = 60; l.Brightness = 3; l.Parent = head
	m.PrimaryPart = head
	m.Parent = workspace
	return m
end

function UIKit.tweenCamera(cf: CFrame, t: number)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = cf }):Play()
end

function UIKit.restoreCamera()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
end

return UIKit
