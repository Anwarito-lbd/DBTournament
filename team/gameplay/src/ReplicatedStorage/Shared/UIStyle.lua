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
		if lp:GetAttribute("InRaid") == true then -- v11: raids and story episodes own the screen
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
		lp:GetAttributeChangedSignal("InRaid"):Connect(applyFocus)
		applyFocus()
	end
	return set
end

-- ===================================================================================================================
-- v11 kit (UI_AUDIT_V11 / POLISH_BIBLE §2.5): the ONE token set and component library for new and rebuilt screens.
-- The v8 helpers above stay for screens not migrated yet; UIKit is legacy. Rules: text never auto-scales (fixed
-- sizes per role, scaled once per viewport by ScreenManager), positions come from ScreenManager zones, colours only
-- from S.C, fonts only from S.F, and the loud Bangers callout is reserved for big moments.
-- ===================================================================================================================
local function rgb(hex: number): Color3
	return Color3.fromRGB(bit32.rshift(hex, 16), bit32.band(bit32.rshift(hex, 8), 255), bit32.band(hex, 255))
end
S.C = {
	ink = rgb(0x0B0F1A), panel = rgb(0x141B2D), stroke = rgb(0x2B3A5C),
	orange = rgb(0xFF8A00), orangeDeep = rgb(0xA65500), gold = rgb(0xFFC93C), goldLight = rgb(0xFFE27A), blue = rgb(0x1E6FD9),
	ki = rgb(0x3FB6FF), ki2 = rgb(0xBDEBFF), hp = rgb(0x3DDC84), hpMid = rgb(0xFFD23F), danger = rgb(0xFF3B30),
	boss = rgb(0xB3122B), rare = rgb(0xA64DFF), rareLight = rgb(0xD6B8FF), scouter = rgb(0x7CFF6B),
	text = rgb(0xF5F7FF), muted = rgb(0x9AA6C4),
}
S.F = { display = Enum.Font.FredokaOne, impact = Enum.Font.Bangers, body = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold, data = Enum.Font.RobotoMono }
-- text sizes in px at 1080p on PC (phones use points at ~1.0); ScreenManager multiplies by S.textScale()
S.SIZE = { caption = 15, label = 16, body = 19, lead = 23, title = 32, h1 = 42, display = 56, callout = 112 }
S.PANEL_ALPHA = 0.15

local textScale = 1
function S.textScale(): number return textScale end
function S.setTextScale(v: number) textScale = v end
function S.px(role: string): number
	return math.floor(((S.SIZE :: any)[role] or S.SIZE.body) * textScale + 0.5)
end

-- the device the player is using right now (last input), not "a gamepad is plugged in"
local deviceChanged = Instance.new("BindableEvent")
S.deviceChanged = deviceChanged.Event
local function classify(t: Enum.UserInputType): string?
	if t == Enum.UserInputType.Touch then return "Touch" end
	if t.Name:sub(1, 7) == "Gamepad" then return "Gamepad" end
	if t == Enum.UserInputType.Keyboard or t.Name:sub(1, 5) == "Mouse" then return "Keyboard" end
	return nil
end
local device = classify(UserInputService:GetLastInputType()) or (if S.MOBILE then "Touch" else "Keyboard")
UserInputService.LastInputTypeChanged:Connect(function(t)
	local d = classify(t)
	if d and d ~= device then
		device = d
		deviceChanged:Fire(d)
	end
end)
function S.device(): string return device end

-- key hint per action and device ("" = no badge: the on-screen button is the hint)
local KEYS = {
	Keyboard = { block = "F", dash = "Q", vanish = "E", breaker = "R", mash = "V", heavy = "G", ki = "1", beam = "2", menu = "M", quests = "J", controls = "H", close = "Esc" },
	Gamepad = { close = "B" },
	Touch = {},
}
function S.keyFor(action: string): string
	return ((KEYS :: any)[device] or {})[action] or ""
end

-- fixed-size text; role picks font + size. opts: color, font, align ("Left"|"Center"|"Right"), wrap, auto ("X"|"Y"|"XY")
function S.text(parent: Instance, role: string, text: string, opts: any?): TextLabel
	local o = opts or {}
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.RichText = o.rich == true
	l.TextColor3 = o.color or S.C.text
	l.Font = o.font or (if role == "callout" then S.F.impact elseif role == "title" or role == "h1" or role == "display" or role == "lead" then S.F.display else S.F.body)
	l.TextSize = S.px(role)
	l.TextScaled = false
	l.TextWrapped = o.wrap == true
	l.TextXAlignment = (Enum.TextXAlignment :: any)[o.align or "Left"]
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Size = o.size or UDim2.new(0, 0, 0, 0)
	if o.auto ~= false then l.AutomaticSize = (Enum.AutomaticSize :: any)[o.auto or "XY"] end
	l:SetAttribute("TextRole", role) -- ScreenManager rescales every tagged label when the viewport changes
	l.Parent = parent
	return l
end

-- panel surface: ink/panel fill at the spec transparency, 1 px stroke, 8 px corners; opts.edge = Ki-edge colour strip
function S.plate(parent: Instance, opts: any?): Frame
	local o = opts or {}
	local f = Instance.new("Frame")
	f.BackgroundColor3 = o.color or S.C.panel
	f.BackgroundTransparency = o.alpha or S.PANEL_ALPHA
	f.BorderSizePixel = 0
	f.Size = o.size or UDim2.new()
	if o.auto then f.AutomaticSize = (Enum.AutomaticSize :: any)[o.auto] end
	f.Parent = parent
	corner(f, o.radius or 8)
	local st = stroke(f, S.C.stroke, 1)
	st.Transparency = 0.2
	if o.edge then -- Ki-edge drawn by a hard gradient stop, so it never takes a slot in the plate's own layout
		local base = f.BackgroundColor3
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Name = "Edge"
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, o.edge), ColorSequenceKeypoint.new(0.014, o.edge),
			ColorSequenceKeypoint.new(0.0141, base), ColorSequenceKeypoint.new(1, base),
		})
		g.Parent = f
	end
	if o.pad ~= false then
		local p = Instance.new("UIPadding")
		local v = o.pad or 12
		p.PaddingTop, p.PaddingBottom = UDim.new(0, v - 2), UDim.new(0, v - 2)
		p.PaddingLeft, p.PaddingRight = UDim.new(0, v + (if o.edge then 4 else 0)), UDim.new(0, v)
		p.Parent = f
	end
	return f
end

-- vertical/horizontal stack helper
function S.stack(parent: Instance, dir: string?, gap: number?, align: string?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.FillDirection = if dir == "X" then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	l.Padding = UDim.new(0, gap or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	if align then l.HorizontalAlignment = (Enum.HorizontalAlignment :: any)[align] end
	l.Parent = parent
	return l
end

-- key badge: gold chip with the key in mono ("" hides it)
function S.keyBadge(parent: Instance, key: string): TextLabel
	local k = S.text(parent, "caption", key, { font = S.F.data, color = S.C.ink })
	k.Name = "Key"
	k.BackgroundColor3 = S.C.gold
	k.BackgroundTransparency = 0
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 5), UDim.new(0, 5)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, 1), UDim.new(0, 1)
	p.Parent = k
	corner(k, 4)
	k.Visible = key ~= ""
	return k
end

-- chip: small rounded label with an optional key badge (quiet secondary info and actions)
function S.chip(parent: Instance, text: string, key: string?, onClick: (() -> ())?): TextButton
	local b = Instance.new("TextButton")
	b.Text = ""
	b.AutoButtonColor = false
	b.BackgroundColor3 = S.C.panel
	b.BackgroundTransparency = S.PANEL_ALPHA
	b.BorderSizePixel = 0
	b.AutomaticSize = Enum.AutomaticSize.XY
	b.Size = UDim2.new()
	b.Parent = parent
	corner(b, 6)
	local st = stroke(b, S.C.stroke, 1)
	st.Transparency = 0.2
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	p.Parent = b
	S.stack(b, "X", 6)
	local l = S.text(b, "label", text, { font = S.F.bold })
	l.Name = "Label"
	l.LayoutOrder = 1
	if key then S.keyBadge(b, key).LayoutOrder = 2 end
	if onClick then
		b.Activated:Connect(onClick)
		b.MouseEnter:Connect(function() st.Color = S.C.gold end)
		b.MouseLeave:Connect(function() st.Color = S.C.stroke end)
	else
		b.Active = false
	end
	return b
end

-- action button: kind "primary" (orange, one per screen) | "secondary" (blue outline) | "quiet"
function S.action(parent: Instance, text: string, kind: string?, onClick: (() -> ())?): TextButton
	local k = kind or "secondary"
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = S.F.display
	b.TextSize = S.px("lead")
	b:SetAttribute("TextRole", "lead")
	b.AutoButtonColor = false
	b.AutomaticSize = Enum.AutomaticSize.XY
	b.Size = UDim2.new()
	b.BorderSizePixel = 0
	b.TextColor3 = if k == "primary" then S.C.ink else S.C.text
	b.BackgroundColor3 = if k == "primary" then S.C.orange elseif k == "secondary" then S.C.blue else S.C.panel
	b.BackgroundTransparency = if k == "primary" then 0 elseif k == "secondary" then 0.8 else 1
	b.Parent = parent
	corner(b, 8)
	local st = stroke(b, if k == "primary" then rgb(0xFFB357) elseif k == "secondary" then S.C.blue else S.C.stroke, 1)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 24), UDim.new(0, 24)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, 9), UDim.new(0, 9)
	p.Parent = b
	local sc = Instance.new("UIScale")
	sc.Parent = b
	local quick = TweenInfo.new(0.08, Enum.EasingStyle.Quad)
	b.MouseEnter:Connect(function() TweenService:Create(sc, quick, { Scale = 1.05 }):Play(); st.Color = S.C.gold end)
	b.MouseLeave:Connect(function() TweenService:Create(sc, quick, { Scale = 1 }):Play() end)
	b.MouseButton1Down:Connect(function() TweenService:Create(sc, quick, { Scale = 0.95 }):Play() end)
	b.MouseButton1Up:Connect(function() TweenService:Create(sc, quick, { Scale = 1.05 }):Play() end)
	b.SelectionGained:Connect(function() st.Color = S.C.gold; st.Thickness = 2 end) -- gamepad focus
	b.SelectionLost:Connect(function() st.Thickness = 1 end)
	if onClick then b.Activated:Connect(onClick) end
	return b
end

-- meter: rounded track + fill; returns (track, set(fraction 0..1)). opts: color | gradient {a,b}, height, segments, trail
function S.meter(parent: Instance, opts: any?): (Frame, (number) -> ())
	local o = opts or {}
	local track = Instance.new("Frame")
	track.Name = "Meter"
	track.Size = o.size or UDim2.new(1, 0, 0, o.height or 14)
	track.BackgroundColor3 = S.C.ink
	track.BackgroundTransparency = 0.1
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = parent
	corner(track, o.radius or 4)
	local st = stroke(track, Color3.new(1, 1, 1), 1)
	st.Transparency = 0.88
	local trail: Frame? = nil
	if o.trail then -- white "recent damage" ghost that catches up
		local t = Instance.new("Frame")
		t.Name = "Trail"
		t.BackgroundColor3 = Color3.new(1, 1, 1)
		t.BackgroundTransparency = 0.35
		t.BorderSizePixel = 0
		t.Size = UDim2.fromScale(1, 1)
		t.Parent = track
		corner(t, o.radius or 4)
		trail = t
	end
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = o.color or Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = track
	corner(fill, o.radius or 4)
	if o.gradient then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(o.gradient[1], o.gradient[2])
		g.Parent = fill
	end
	if o.segments then -- Ki reads as 5 cells
		for i = 1, o.segments - 1 do
			local d = Instance.new("Frame")
			d.BackgroundColor3 = S.C.ink
			d.BorderSizePixel = 0
			d.Size = UDim2.new(0, 2, 1, 0)
			d.Position = UDim2.new(i / o.segments, -1, 0, 0)
			d.ZIndex = 3
			d.Parent = track
		end
	end
	local last = 1
	local function set(f: number)
		f = math.clamp(f, 0, 1)
		fill.Size = UDim2.fromScale(f, 1)
		if trail then
			if f < last then
				task.delay(0.35, function() TweenService:Create(trail, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(f, 1) }):Play() end)
			else
				trail.Size = UDim2.fromScale(f, 1)
			end
		end
		last = f
	end
	return track, set
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
