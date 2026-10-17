--!strict
-- ModuleScript: ReplicatedStorage.Shared.ScreenManager  (v11 UI foundation, client only; see team/UI_AUDIT_V11.md)
-- Owns WHAT may be on screen and WHERE, so screens stop drawing over each other:
--   layers  HUD (10) < Panel (20) < Modal (30) < Cinematic (40) < System (50): one ScreenGui each, created here.
--   zones   nine reserved HUD regions (ally, context, system, rail, tracker, center, vitals, skills, help). A script asks
--           for a zone and parents into it; zones stack their children with a UIListLayout, so two screens sharing a
--           zone line up instead of overlapping. Scripts never set their own screen position.
--   callouts the loud Bangers moments (BLOCK!, PARRY!, K.O.) play one at a time in the centre band.
--   text    labels made with UIStyle.text carry a TextRole; they are resized together when the viewport changes.
--   cinematics while the player's InCinematic attribute is set (CutsceneDirector), the HUD layer hides itself.
-- Screens not migrated yet keep their own ScreenGuis; they move onto these layers screen by screen.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local S = require(script.Parent:WaitForChild("UIStyle"))

local SM = {}
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local ORDER = { HUD = 10, Panel = 20, Modal = 30, Cinematic = 40, System = 50 }
local layers: { [string]: ScreenGui } = {}

-- zone rectangles as screen fractions: { anchorX, anchorY, posX, posY, width, height, list alignment }
local ZONES: { [string]: { any } } = {
	ally = { 0, 0, 0.012, 0.03, 0.24, 0.16, "Left", "Top" },
	context = { 0.5, 0, 0.5, 0.02, 0.46, 0.2, "Center", "Top" },
	system = { 1, 0, 0.988, 0.03, 0.24, 0.24, "Right", "Top" },
	rail = { 0, 0.5, 0.012, 0.48, 0.16, 0.42, "Left", "Center" },
	tracker = { 1, 0, 0.988, 0.28, 0.22, 0.4, "Right", "Top" },
	center = { 0.5, 0.5, 0.5, 0.42, 0.5, 0.3, "Center", "Center" },
	vitals = { 0, 1, 0.012, 0.975, 0.26, 0.26, "Left", "Bottom" },
	skills = { 0.5, 1, 0.5, 0.975, 0.46, 0.2, "Center", "Bottom" },
	struggle = { 0.5, 1, 0.5, 0.735, 0.6, 0.22, "Center", "Bottom" }, -- clash / hold meters, clear of the skill bar
	help = { 1, 1, 0.988, 0.975, 0.22, 0.16, "Right", "Bottom" },
}
local zones: { [string]: Frame } = {}

local function computeScale(): number
	local cam = workspace.CurrentCamera
	local v = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	if S.MOBILE then
		return math.clamp(v.Y / 420, 0.8, 1.1) -- phones lay out in points; ~1.0 on a typical landscape phone
	end
	return math.clamp(v.Y / 1080, 0.85, 1.6)
end

local function rescale(root: Instance)
	for _, d in root:GetDescendants() do
		local role = d:GetAttribute("TextRole")
		if role and (d:IsA("TextLabel") or d:IsA("TextButton")) then
			(d :: any).TextSize = S.px(role :: string)
		end
	end
end

function SM.layer(name: string): ScreenGui
	local g = layers[name]
	if g and g.Parent then return g end
	local old = pg:FindFirstChild("Layer_" .. name)
	if old then old:Destroy() end
	local ng = Instance.new("ScreenGui")
	ng.Name = "Layer_" .. name
	ng.ResetOnSpawn = false
	ng.IgnoreGuiInset = true
	ng.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- keep clear of notches and Roblox's top bar
	ng.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ng.DisplayOrder = (ORDER :: any)[name] or 20
	ng.Parent = pg
	layers[name] = ng
	return ng
end

function SM.zone(name: string): Frame
	local z = zones[name]
	if z and z.Parent then return z end
	local spec = (ZONES :: any)[name]
	assert(spec, "unknown zone " .. name)
	local f = Instance.new("Frame")
	f.Name = "Zone_" .. name
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(spec[1], spec[2])
	f.Position = UDim2.fromScale(spec[3], spec[4])
	f.Size = UDim2.fromScale(spec[5], spec[6])
	f.Parent = SM.layer("HUD")
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, 8)
	l.HorizontalAlignment = (Enum.HorizontalAlignment :: any)[spec[7]]
	l.VerticalAlignment = (Enum.VerticalAlignment :: any)[spec[8]]
	l.Parent = f
	zones[name] = f
	return f
end

-- ===== HUD visibility: reasons stack ("cinematic", "modal", ...) =====
local hideReasons: { [string]: any } = {}
local function applyHud()
	local hidden = next(hideReasons) ~= nil
	local hud = layers.HUD
	if hud then hud.Enabled = not hidden end
end
function SM.hideHud(reason: string, on: boolean)
	hideReasons[reason] = if on then true else nil
	applyHud()
end
player:GetAttributeChangedSignal("InCinematic"):Connect(function()
	SM.hideHud("cinematic", player:GetAttribute("InCinematic") == true)
end)

-- round cutscenes (Grand Priest intro, Shenron ending, character select) own the screen for round players
local function roundCutscene(): boolean
	local s = workspace:GetAttribute("RoundState")
	return player:GetAttribute("InRaid") ~= true and (s == "Intro" or s == "Ending" or s == "CharacterSelect")
end
local function syncRound() SM.hideHud("round", roundCutscene()) end
workspace:GetAttributeChangedSignal("RoundState"):Connect(syncRound)
player:GetAttributeChangedSignal("InRaid"):Connect(syncRound)
syncRound()

-- lobby-only UI (menu rail, quest tracker): hidden in the tutorial, in raids/episodes and while fighting in a round
function SM.lobbyHidden(): boolean
	if player:GetAttribute("InTutorial") == true or player:GetAttribute("InRaid") == true then return true end
	return workspace:GetAttribute("RoundState") == "InRound" and player:GetAttribute("Alive") == true
end
local lobbyWatch: { GuiObject } = {}
local function syncLobby()
	local hide = SM.lobbyHidden()
	for _, g in lobbyWatch do g.Visible = not hide and g:GetAttribute("Wanted") ~= false end
end
function SM.lobbyOnly(g: GuiObject)
	table.insert(lobbyWatch, g)
	g.Visible = not SM.lobbyHidden() and g:GetAttribute("Wanted") ~= false
end
function SM.setWanted(g: GuiObject, on: boolean) -- player toggles (J for quests) combine with the lobby rule
	g:SetAttribute("Wanted", on)
	syncLobby()
end
for _, a in { "InTutorial", "InRaid", "Alive" } do player:GetAttributeChangedSignal(a):Connect(syncLobby) end
workspace:GetAttributeChangedSignal("RoundState"):Connect(syncLobby)

-- ===== menu rail: one column of navigation, each item opens one panel =====
local railFrame: Frame? = nil
local railItems: { [string]: any } = {}
local function rail(): Frame
	if railFrame and railFrame.Parent then return railFrame end
	local f = Instance.new("Frame")
	f.Name = "MenuRail"; f.BackgroundTransparency = 1; f.AutomaticSize = Enum.AutomaticSize.XY; f.Size = UDim2.new()
	f.Parent = SM.zone("rail")
	S.stack(f, "Y", 6)
	SM.lobbyOnly(f)
	railFrame = f
	return f
end
-- opts: label, key ("" for none), order, quiet (dimmer, for Credits), onClick
function SM.railItem(opts: any): any
	local old = railItems[opts.label]
	if old then old.button:Destroy() end
	local b = Instance.new("TextButton")
	b.Name = "Rail_" .. opts.label
	b.Text = ""
	b.AutoButtonColor = false
	b.BackgroundColor3 = S.C.panel
	b.BackgroundTransparency = if opts.quiet then 0.45 else S.PANEL_ALPHA
	b.BorderSizePixel = 0
	b.Size = UDim2.new(0, math.floor(190 * S.textScale()), 0, 0)
	b.AutomaticSize = Enum.AutomaticSize.Y
	b.LayoutOrder = opts.order or 10
	b.Parent = rail()
	S.corner(b, 8)
	local st = S.stroke(b, S.C.stroke, 1)
	st.Transparency = 0.2
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 14), UDim.new(0, 10)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	p.Parent = b
	local l = S.text(b, "body", opts.label, { font = S.F.bold, color = if opts.quiet then S.C.muted else S.C.text })
	l.Name = "Label"
	local k = S.keyBadge(b, opts.key or "")
	k.AnchorPoint = Vector2.new(1, 0.5); k.Position = UDim2.new(1, 0, 0.5, 0)
	local edge = Instance.new("Frame") -- lit when its panel is open
	edge.Name = "Open"; edge.BackgroundColor3 = S.C.orange; edge.BorderSizePixel = 0; edge.Size = UDim2.new(0, 4, 1, -10)
	edge.Position = UDim2.new(0, -12, 0, 5); edge.Visible = false; edge.Parent = b
	S.corner(edge, 2)
	b.MouseEnter:Connect(function() st.Color = S.C.gold end)
	b.MouseLeave:Connect(function() st.Color = S.C.stroke end)
	if opts.onClick then b.Activated:Connect(opts.onClick) end
	local item = {
		button = b, key = opts.key or "",
		setOpen = function(on: boolean) edge.Visible = on; l.TextColor3 = if on then S.C.gold elseif opts.quiet then S.C.muted else S.C.text end,
		setKey = function(key: string) k.Text = key; k.Visible = key ~= "" and S.device() == "Keyboard" end,
	}
	railItems[opts.label] = item
	k.Visible = item.key ~= "" and S.device() == "Keyboard"
	return item
end
S.deviceChanged:Connect(function(d)
	for _, it in railItems do
		local k = it.button:FindFirstChild("Key") :: TextLabel?
		if k then k.Visible = it.key ~= "" and d == "Keyboard" end
	end
end)

-- true while a modal or a cinematic owns the screen: celebrations and pop-ups wait for it
function SM.busy(): boolean
	local m: ScreenGui? = layers.Modal
	if m and #m:GetChildren() > 0 then return true end
	return player:GetAttribute("InCinematic") == true
end
-- yields until the screen is free (or `timeout` seconds pass)
function SM.waitUntilFree(timeout: number?)
	local t0 = os.clock()
	while SM.busy() and os.clock() - t0 < (timeout or 10) do task.wait(0.2) end
end

-- ===== callouts: one at a time, centre band =====
local queue: { any } = {}
local playing = false
local function reduceMotion(): boolean return player:GetAttribute("ReduceMotion") == true end

local function playNext()
	if playing then return end
	local item = table.remove(queue, 1)
	if not item then return end
	playing = true
	local holder = Instance.new("Frame")
	holder.Name = "Callout"
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.XY
	holder.Size = UDim2.new()
	holder.LayoutOrder = -100
	holder.Parent = SM.zone("center")
	S.stack(holder, "Y", 4, "Center")
	local big = S.text(holder, "callout", item.text, { color = Color3.new(1, 1, 1), align = "Center" })
	big.TextSize = math.floor(S.px("callout") * (item.scale or 1) + 0.5)
	big.Rotation = if reduceMotion() then 0 else -4
	local g = Instance.new("UIGradient") -- Bangers fill: light gold to orange, the signature treatment
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, item.top or S.C.goldLight),
		ColorSequenceKeypoint.new(0.5, item.mid or S.C.gold),
		ColorSequenceKeypoint.new(1, item.bottom or S.C.orange),
	})
	g.Rotation = 90
	g.Parent = big
	local st = Instance.new("UIStroke")
	st.Color = S.C.ink
	st.Thickness = math.max(3, math.floor(big.TextSize / 18))
	st.Parent = big
	if item.sub and item.sub ~= "" then
		local sub = S.plate(holder, { auto = "XY", alpha = 0.2, color = S.C.ink, pad = 6 })
		sub.LayoutOrder = 2
		S.stack(sub, "X", 6)
		local t = S.text(sub, "lead", item.sub, {})
		t.LayoutOrder = 1
		if item.key and item.key ~= "" then S.keyBadge(sub, item.key).LayoutOrder = 2 end
	end
	local sc = Instance.new("UIScale")
	sc.Parent = holder
	if not reduceMotion() then
		sc.Scale = 1.6
		TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	task.delay(item.duration or 0.9, function()
		TweenService:Create(big, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(0.15), { Transparency = 1 }):Play()
		task.wait(0.16)
		holder:Destroy()
		playing = false
		playNext()
	end)
end

-- text: the callout (keep it 1-3 words); opts: sub (one plain line), key (badge after sub), duration, scale,
-- top/mid/bottom (gradient colours), replace (drop queued callouts first, for urgent prompts like BLOCK!)
function SM.callout(text: string, opts: any?)
	local o = table.clone(opts or {})
	o.text = text
	if o.replace then table.clear(queue) end
	if #queue >= 3 then table.remove(queue, 1) end -- never let a backlog replay stale moments
	table.insert(queue, o)
	playNext()
end

-- ===== viewport scale =====
local function refreshScale()
	local s = computeScale()
	if math.abs(s - S.textScale()) < 0.01 then return end
	S.setTextScale(s)
	for _, g in layers do rescale(g) end
end
S.setTextScale(computeScale())
local function hookCamera()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale) end
	refreshScale()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)
hookCamera()

return SM
