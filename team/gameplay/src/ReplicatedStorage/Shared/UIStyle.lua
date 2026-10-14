--!strict
-- ModuleScript: ReplicatedStorage.Shared.UIStyle  (v8 shared anime-style UI kit for the new db-gameplay panels)
-- Matches the existing HUD/UIKit look: GothamBold/GothamBlack, navy panels (12,14,30) at 0.15-0.25, gold accent (255,200,60),
-- 8 px corners, black text strokes, gold UIStroke + vertical UIGradient, quick Quad/Back tweens. Scale-based sizing with
-- UISizeConstraint (works on phones), touch toggle buttons, keyboard toggle keys, and remote checks that never hang.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local S = {}

S.GOLD = Color3.fromRGB(255, 200, 60)
S.DARK = Color3.fromRGB(12, 14, 30)
S.PANEL = Color3.fromRGB(22, 26, 52)
S.CARD = Color3.fromRGB(28, 32, 58)
S.BLUE = Color3.fromRGB(40, 60, 140)
S.GREEN = Color3.fromRGB(60, 170, 90)
S.RED = Color3.fromRGB(220, 70, 70)
S.MUTED = Color3.fromRGB(150, 160, 190)
S.FONT, S.FONT_TITLE, S.FONT_BODY = Enum.Font.GothamBold, Enum.Font.GothamBlack, Enum.Font.Gotham
S.FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
S.POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
S.MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function corner(p: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
end
local function stroke(p: Instance, color: Color3?, th: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or S.GOLD
	s.Thickness = th or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function gradient(p: Instance, a: Color3, b: Color3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = 90
	g.Parent = p
end
S.corner, S.stroke, S.gradient = corner, stroke, gradient

function S.gui(name: string, order: number?): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = order or 20
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = pg
	return g
end

-- Centered panel sized by scale (w,h in 0..1), clamped in pixels for big screens
function S.panel(parent: Instance, w: number, h: number, maxW: number?, maxH: number?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(
		if S.MOBILE then math.min(0.96, w * 1.35) else w,
		if S.MOBILE then math.min(0.92, h * 1.2) else h
	)
	f.BackgroundColor3 = S.DARK
	f.BackgroundTransparency = 0.12
	f.BorderSizePixel = 0
	f.Parent = parent
	corner(f, 12)
	stroke(f, S.GOLD, 2)
	gradient(f, Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 160, 200))
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(maxW or 720, maxH or 560)
	c.Parent = f
	return f
end

function S.label(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3?, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or S.FONT
	l.TextScaled = true
	l.TextWrapped = true
	l.TextStrokeTransparency = 0.4
	l.Parent = parent
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 22
	c.MinTextSize = 9
	c.Parent = l
	return l
end

function S.title(parent: Instance, text: string): TextLabel
	local t = S.label(parent, text, UDim2.new(1, -90, 0.11, 0), UDim2.new(0, 16, 0, 6), S.GOLD, S.FONT_TITLE)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextStrokeTransparency = 0
	gradient(t, Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 150, 30));
	(t:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint).MaxTextSize = 30
	return t
end

function S.button(
	parent: Instance,
	text: string,
	size: UDim2,
	pos: UDim2,
	color: Color3?,
	onClick: (() -> ())?
): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color or S.BLUE
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = S.FONT
	b.TextScaled = true
	b.TextStrokeTransparency = 0.5
	b.Parent = parent
	corner(b)
	local st = stroke(b, Color3.new(0, 0, 0), 1.5)
	st.Transparency = 0.4
	gradient(b, Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 190))
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 20
	c.MinTextSize = 10
	c.Parent = b
	b.MouseEnter:Connect(function()
		TweenService:Create(st, S.FAST, { Color = S.GOLD, Transparency = 0 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(st, S.FAST, { Color = Color3.new(0, 0, 0), Transparency = 0.4 }):Play()
	end)
	if onClick then
		b.Activated:Connect(onClick)
	end -- Activated = mouse + touch + gamepad
	return b
end

function S.close(panel: Frame, onClose: () -> ())
	S.button(panel, "X", UDim2.new(0, 40, 0, 40), UDim2.new(1, -48, 0, 8), S.RED, onClose)
end

function S.list(parent: Instance, size: UDim2, pos: UDim2): ScrollingFrame
	local sf = Instance.new("ScrollingFrame")
	sf.Size = size
	sf.Position = pos
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = if S.MOBILE then 10 else 6
	sf.ScrollBarImageColor3 = S.GOLD
	sf.CanvasSize = UDim2.new()
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Parent = parent
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = sf
	return sf
end

function S.card(parent: Instance, height: number, order: number?): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -12, 0, height)
	f.BackgroundColor3 = S.CARD
	f.BorderSizePixel = 0
	f.LayoutOrder = order or 0
	f.Parent = parent
	corner(f)
	local st = stroke(f, S.GOLD, 1)
	st.Transparency = 0.6
	return f
end

function S.clear(f: Instance)
	for _, c in f:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- open/close with a pop tween; returns setter. Adds toggle key + an on-screen touch button (slot = vertical index).
function S.toggle(
	gui: ScreenGui,
	panel: Frame,
	key: Enum.KeyCode,
	short: string,
	slot: number,
	onOpen: (() -> ())?
): (boolean?) -> ()
	panel.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local open = false
	-- FTUE FOCUS MODE (2026-10-14): this is the single chokepoint for every left-edge nav panel (Radar / Wish /
	-- Ranked / Raids / Story / Store), so one guard here clears all of them. During the Whis tutorial they were
	-- stacked down the side of the screen in the very first thing a new player sees.
	local lp = Players.LocalPlayer
	local function focusHidden(): boolean
		if lp == nil then
			return false
		end
		-- CharacterSelect draws a full-screen character grid; the Store/Credits/nav buttons were overlapping it.
		local s = workspace:GetAttribute("RoundState")
		if s == "CharacterSelect" or s == "Intro" or s == "Ending" then
			return true
		end
		return lp:GetAttribute("InTutorial") == true
	end
	local function set(v: boolean?)
		open = if v == nil then not open else v
		if open and focusHidden() then
			open = false
			return
		end
		if open then
			panel.Visible = true
			scale.Scale = 0.85
			TweenService:Create(scale, S.POP, { Scale = 1 }):Play()
			if onOpen then
				task.spawn(onOpen)
			end
		else
			panel.Visible = false
		end
	end
	UserInputService.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == key then
			set()
		end
	end)
	local b = S.button(
		gui,
		short .. (if S.MOBILE then "" else (" [" .. key.Name .. "]")),
		UDim2.fromScale(0.09, 0.05),
		UDim2.new(0.005, 0, 0.30 + slot * 0.06, 0),
		S.PANEL,
		function()
			set()
		end
	)
	local c = Instance.new("UISizeConstraint")
	c.MinSize = Vector2.new(70, 36)
	c.MaxSize = Vector2.new(150, 44)
	c.Parent = b
	if lp then
		local function applyFocus()
			local hide = focusHidden()
			b.Visible = not hide
			if hide and open then
				set(false)
			end
		end
		lp:GetAttributeChangedSignal("InTutorial"):Connect(applyFocus)
		applyFocus()
	end
	return set
end

-- true if every remote exists (waits up to `timeout` total); never yields forever
function S.remotes(names: { string }, timeout: number?): boolean
	local folder = ReplicatedStorage:WaitForChild("Remotes", timeout or 10)
	if not folder then
		return false
	end
	for _, n in names do
		if not folder:WaitForChild(n, timeout or 10) then
			warn("[UI] missing remote " .. n)
			return false
		end
	end
	return true
end

function S.toast(gui: ScreenGui, text: string, color: Color3?)
	local t = S.label(gui, text, UDim2.fromScale(0.5, 0.05), UDim2.fromScale(0.25, 0.14), color or S.GOLD, S.FONT_TITLE)
	t.TextStrokeTransparency = 0
	task.delay(2.5, function()
		TweenService:Create(t, S.FAST, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.3)
		t:Destroy()
	end)
end

return S
